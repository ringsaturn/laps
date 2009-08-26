SUBROUTINE BUFR_PROFLR(NUMPROFLR,NUMLEVELS,STATIONID,I4OBSTIME, &
                        LATITUDES,LONGITUDE,ELEVATION,OBSVNTYPE, &
                        MAXPROFLR,HEIGHTOBS,UUWINDOBS,VVWINDOBS, &
                        WNDRMSERR,PRSSFCOBS,TMPSFCOBS,REHSFCOBS, &
                        UWDSFCOBS,VWDSFCOBS)

!==============================================================================
!doc  THIS ROUTINE CONVERTS LAPS PROFILER DATA INTO PREPBUFR FORMAT.
!doc
!doc  HISTORY:
!doc	CREATION:	YUANFU XIE/SHIOW-MING DENG	JUN 2007
!==============================================================================

  USE LAPS_PARAMS

  IMPLICIT NONE

  CHARACTER, INTENT(IN) :: STATIONID(*)*5		! STATION ID
  CHARACTER, INTENT(IN) :: OBSVNTYPE(*)*8		! OBS TYPE
  INTEGER,   INTENT(IN) :: NUMPROFLR,NUMLEVELS(*)	! NUMBER OF PROFILERS/LEVELS
  INTEGER,   INTENT(IN) :: MAXPROFLR			! MAXIMUM NUMBER PROFILRS
                                                	! INSTEAD OF MAXNUM_PROFLRS
                                                	! AVOID CONFUSION ON MEMORY.
  INTEGER,   INTENT(IN) :: I4OBSTIME(*)			! I4 OBS TIMES

  ! OBSERVATIONS:
  REAL,      INTENT(IN) :: LATITUDES(*),LONGITUDE(*),ELEVATION(*)
  REAL,      INTENT(IN) :: HEIGHTOBS(MAXPROFLR,*), &	! UPAIR (M)
                           UUWINDOBS(MAXPROFLR,*), &	! UPAIR (M/S)
                           VVWINDOBS(MAXPROFLR,*), &	! UPAIR (M/S)
                           WNDRMSERR(MAXPROFLR,*)	! WIND RMS ERROR (M/S)
  REAL,      INTENT(IN) :: PRSSFCOBS(*),TMPSFCOBS(*), &	! SURFACE
                           REHSFCOBS(*), &		! SURFACE
                           UWDSFCOBS(*),VWDSFCOBS(*)	! SURFACE

  ! LOCAL VARIABLES:
  CHARACTER :: STTNID*8,SUBSET*8
  INTEGER   :: I,J,K,INDATE,ZEROCH,STATUS
  REAL      :: RI,RJ,RK,DI,SP,HEIGHT_TO_PRESSURE	! OBS GRIDPOINT LOCATIOIN
  REAL      :: MAKE_SSH					! LAPS ROUTINE FROM RH TO SH
  REAL*8    :: HEADER(HEADER_NUMITEM),OBSDAT(OBSDAT_NUMITEM,225)
  REAL*8    :: OBSERR(OBSERR_NUMITEM,225),OBSQMS(OBSQMS_NUMITEM,225)
  EQUIVALENCE(STTNID,HEADER(1))

  PRINT*,'Number of Pofilers: ',NUMPROFLR,NUMLEVELS(1:NUMPROFLR)

  ! OBS DATE: YEAR/MONTH/DAY
  ZEROCH = ICHAR('0')
  INDATE = YYYYMM_DDHHMIN(1)*1000000+YYYYMM_DDHHMIN(2)*10000+ &
           YYYYMM_DDHHMIN(3)*100+YYYYMM_DDHHMIN(4)

  ! WRITE DATA:
  DO I=1,NUMPROFLR

    ! STATION ID:
    STTNID = STATIONID(I)

    ! DATA TYPE:
    IF (OBSVNTYPE(I) .EQ. 'PROFILER') THEN
      SUBSET = 'PROFLR'
      HEADER(2) = 223		! PROFILER CODE
      HEADER(3) = 71		! INPUT REPORT TYPE
    ELSE IF (OBSVNTYPE(I) .EQ. 'VAD') THEN
      SUBSET = 'VADWND'
      HEADER(2) = 224		! PROFILER CODE
      HEADER(3) = 72		! INPUT REPORT TYPE
    ELSE
      PRINT*,'BUFR_PROFLR: ERROR: Unknown profiler data type!'
      STOP
    ENDIF

    ! TIME:
    IF (ABS(I4OBSTIME(I)-SYSTEM_IN4TIME) .GT. LENGTH_ANATIME) CYCLE	! OUT OF TIME

    ! LAPS cycle time:
    HEADER(4) = YYYYMM_DDHHMIN(4)
    ! DHR: obs time different from the cycle time:
    HEADER(5) = (I4OBSTIME(I)-SYSTEM_IN4TIME)/3600.0

    ! LAT/LON/ELEVATION:
    HEADER(6) = LATITUDES(I)
    HEADER(7) = LONGITUDE(I)
    HEADER(8) = ELEVATION(I)

    ! IGNORE OBS OUTSIDE THE ANALYSIS DOMAIN:
    CALL LATLON_TO_RLAPSGRID(LATITUDES(I),LONGITUDE(I), &
                              DOMAIN_LATITDE,DOMAIN_LONGITD, &
                              NUMBER_GRIDPTS(1),NUMBER_GRIDPTS(2), &
                              RI,RJ,STATUS)
    IF (RI .LT. 1 .OR. RI .GT. NUMBER_GRIDPTS(1) .OR. &
        RJ .LT. 1 .OR. RJ .GT. NUMBER_GRIDPTS(2)) CYCLE

    HEADER(9) = 99			! INSTRUMENT TYPE: COMMON CODE TABLE C-2
    HEADER(10) = I			! REPORT SEQUENCE NUMBER
    HEADER(11) = 0			! MPI PROCESS NUMBER

    ! UPAIR OBSERVATIONS:
    ! MISSING DATA CONVERSION:
    OBSDAT = MISSNG_PREBUFR
    OBSERR = MISSNG_PREBUFR
    OBSQMS = MISSNG_PREBUFR

    DO J=1,NUMLEVELS(I)
      IF (HEIGHTOBS(I,J) .NE. RVALUE_MISSING .AND. &
          (UUWINDOBS(I,J) .NE. RVALUE_MISSING) .AND. &
          (VVWINDOBS(I,J) .NE. RVALUE_MISSING)) THEN

        OBSDAT(1,J) = HEIGHTOBS(I,J)
        OBSDAT(4,J) = UUWINDOBS(I,J)
        OBSDAT(5,J) = VVWINDOBS(I,J)
        ! ASSUMING 1 M/S ERROR AS DEFAULT:
        OBSERR(4,J) = 1.0
        IF (WNDRMSERR(I,J) .NE. RVALUE_MISSING) &
          OBSERR(4,J) = WNDRMSERR(I,J)

        ! SAVE DATA INTO PRG:
        RK = HEIGHT_TO_PRESSURE(HEIGHTOBS(I,J),HEIGHT_GRID3DM,PRESSR_GRID1DM, &
                       NUMBER_GRIDPTS(1),NUMBER_GRIDPTS(2),NUMBER_GRIDPTS(3), &
                       NINT(RI),NINT(RJ))

        ! FIND THE GRID LEVEL FOR THIS PRESSURE VALUE:
        DO K=1,NUMBER_GRIDPTS(3)
          IF (RK .GE. PRESSR_GRID1DM(K)) EXIT
        ENDDO
        IF (K .GT. NUMBER_GRIDPTS(3)) THEN
          RK = NUMBER_GRIDPTS(3)+1			! OUT OF HEIGHT
        ELSEIF (K .LE. 1) THEN
          RK = 1
          IF (RK .GT. PRESSR_GRID1DM(1)) RK = 0	! OUT OF HEIGHT
        ELSE
          RK = K-(RK-PRESSR_GRID1DM(K))/(PRESSR_GRID1DM(K-1)-PRESSR_GRID1DM(K))
        ENDIF

        ! CONVERT TO DI AND SP:
        CALL UV_TO_DISP(UUWINDOBS(I,J),VVWINDOBS(I,J),DI,SP)

        WRITE(PRGOUT_CHANNEL,11) RI,RJ,RK,DI,SP,OBSVNTYPE(I)
11	FORMAT(3f8.1,2f10.3,3x,a8)

      ENDIF
    ENDDO
    OBSERR(1,1:NUMLEVELS(I)) = 10.0	! ASSUME 10 METER ERROR FOR HEIGHT
    OBSQMS(1,1:NUMLEVELS(I)) = 0	! QUALITY MARK - BUFR CODE TABLE: 
    OBSQMS(4,1:NUMLEVELS(I)) = 0	! 0 always assimilated

    ! WRITE TO BUFR FILE:
    CALL OPENMB(OUTPUT_CHANNEL,SUBSET,INDATE)
    CALL UFBINT(OUTPUT_CHANNEL,HEADER,HEADER_NUMITEM,1,STATUS,HEADER_PREBUFR)
    CALL UFBINT(OUTPUT_CHANNEL,OBSDAT,OBSDAT_NUMITEM, &
                 NUMLEVELS(I),STATUS,OBSDAT_PREBUFR)
    CALL UFBINT(OUTPUT_CHANNEL,OBSERR,OBSERR_NUMITEM, &
                 NUMLEVELS(I),STATUS,OBSERR_PREBUFR)
    CALL UFBINT(OUTPUT_CHANNEL,OBSQMS,OBSQMS_NUMITEM, &
                 NUMLEVELS(I),STATUS,OBSQMS_PREBUFR)
    CALL WRITSB(OUTPUT_CHANNEL)

    ! WRITE SURFACE DATA: FUTURE DEVELOPMENT DEBUG NEEDED
    ! SFCDAT(1) = PRSSFCOBS(I)
    ! SFCDAT(2) = MISSNG_PREBUFR
    ! SFCDAT(3) = TMPSFCOBS(I)
    ! SFCDAT(4) = MISSNG_PREBUFR
    ! USE -132 AS TEMP_REFERENCE:
    ! TEMPERATURE >= TEMP_REFERENCE: RH IS WATER RH;
    ! TEMPERATURE <  TEMP_REFERENCE: RH IS ICE RH;
    ! ASSUME THE SURFACE OBS OF RH IS WATER RH HERE:
    ! SFCDAT(5) = MAKE_SSH(PRSSFCOBS(I),TMPSFCOBS(I),REHSFCOBS(I)/100.0,&
    !              TEMPTR_REFEREN)*0.001 ! KG/KG
    ! CALL OPENMB(OUTPUT_CHANNEL,'ADPSFC',INDATE)
    ! HEADER IS NEEDED TO REFLECT THE OBSERVATION CODE!!!
    ! CALL UFBINT(OUTPUT_CHANNEL,HEADER,HEADER_NUMITEM,1,1,HEADER_PREBUFR)
    ! CALL UFBINT(OUTPUT_CHANNEL,SFCDAT,SURFAC_NUMITEM,1,1,SURFAC_PREBUFR)
    ! CALL UFBINT(OUTPUT_CHANNEL,SFCQMS,SFCQMS_NUMITEM,1,1,SURFAC_PREBUFR)
    ! CALL WRITSB(OUTPUT_CHANNEL)

  ENDDO

END SUBROUTINE BUFR_PROFLR

SUBROUTINE BUFR_RASS(NUMPROFLR,NUMLEVELS,STATIONID,I4OBSTIME, &
                        LATITUDES,LONGITUDE,ELEVATION,OBSVNTYPE, &
                        MAXPROFLR,HEIGHTOBS,TEMPTROBS,TEMPTRERR)

!==============================================================================
!doc  THIS ROUTINE CONVERTS LAPS PROFILER DATA INTO PREPBUFR FORMAT.
!doc
!doc  HISTORY:
!doc	CREATION:	YUANFU XIE/SHIOW-MING DENG	JUN 2007
!==============================================================================

  USE LAPS_PARAMS

  IMPLICIT NONE

  CHARACTER, INTENT(IN) :: STATIONID(*)*5		! STATION ID
  CHARACTER, INTENT(IN) :: OBSVNTYPE(*)*8		! OBS TYPE
  INTEGER,   INTENT(IN) :: NUMPROFLR,NUMLEVELS(*)	! NUMBER OF PROFILERS/LEVELS
  INTEGER,   INTENT(IN) :: MAXPROFLR			! MAXIMUM NUMBER PROFILRS
                                                	! INSTEAD OF MAXNUM_PROFLRS
                                                	! AVOID CONFUSION ON MEMORY.
  INTEGER,   INTENT(IN) :: I4OBSTIME(*)			! I4 OBS TIMES

  ! OBSERVATIONS:
  REAL,      INTENT(IN) :: LATITUDES(*),LONGITUDE(*),ELEVATION(*)
  REAL,      INTENT(IN) :: HEIGHTOBS(MAXPROFLR,*), &	! UPAIR (M)
                           TEMPTROBS(MAXPROFLR,*), &	! UPAIR (C)
                           TEMPTRERR(MAXPROFLR)		! TEMPERATURE ERROR (C)

  ! LOCAL VARIABLES:
  CHARACTER :: STTNID*8,SUBSET*8
  INTEGER   :: I,J,K,INDATE,ZEROCH,STATUS
  REAL      :: RI,RJ,RK,DI,SP,HEIGHT_TO_PRESSURE	! OBS GRIDPOINT LOCATIOIN
  REAL      :: MAKE_SSH					! LAPS ROUTINE FROM RH TO SH
  REAL*8    :: HEADER(HEADER_NUMITEM),OBSDAT(OBSDAT_NUMITEM,225)
  REAL*8    :: OBSERR(OBSERR_NUMITEM,225),OBSQMS(OBSQMS_NUMITEM,225)
  EQUIVALENCE(STTNID,HEADER(1))

  PRINT*,'Number of Pofilers: ',NUMPROFLR,NUMLEVELS(1:NUMPROFLR)

  ! OBS DATE: YEAR/MONTH/DAY
  ZEROCH = ICHAR('0')
  INDATE = YYYYMM_DDHHMIN(1)*1000000+YYYYMM_DDHHMIN(2)*10000+ &
           YYYYMM_DDHHMIN(3)*100+YYYYMM_DDHHMIN(4)

  ! WRITE DATA:
  DO I=1,NUMPROFLR

    ! STATION ID:
    STTNID = STATIONID(I)

    ! DATA TYPE:
    SUBSET = 'PROFLR'
    HEADER(2) = 126		! PROFILER CODE
    HEADER(3) = 77		! INPUT REPORT TYPE

    ! TIME:
    IF (ABS(I4OBSTIME(I)-SYSTEM_IN4TIME) .GT. LENGTH_ANATIME) CYCLE	! OUT OF TIME

    ! LAPS cycle time:
    HEADER(4) = YYYYMM_DDHHMIN(4)
    ! DHR: obs time different from the cycle time:
    HEADER(5) = (I4OBSTIME(I)-SYSTEM_IN4TIME)/3600.0

    ! LAT/LON/ELEVATION:
    HEADER(6) = LATITUDES(I)
    HEADER(7) = LONGITUDE(I)
    HEADER(8) = ELEVATION(I)

    ! IGNORE OBS OUTSIDE THE ANALYSIS DOMAIN:
    CALL LATLON_TO_RLAPSGRID(LATITUDES(I),LONGITUDE(I), &
                              DOMAIN_LATITDE,DOMAIN_LONGITD, &
                              NUMBER_GRIDPTS(1),NUMBER_GRIDPTS(2), &
                              RI,RJ,STATUS)
    IF (RI .LT. 1 .OR. RI .GT. NUMBER_GRIDPTS(1) .OR. &
        RJ .LT. 1 .OR. RJ .GT. NUMBER_GRIDPTS(2)) CYCLE

    HEADER(9) = 99			! INSTRUMENT TYPE: COMMON CODE TABLE C-2
    HEADER(10) = I			! REPORT SEQUENCE NUMBER
    HEADER(11) = 0			! MPI PROCESS NUMBER

    ! UPAIR OBSERVATIONS:
    ! MISSING DATA CONVERSION:
    OBSDAT = MISSNG_PREBUFR
    OBSERR = MISSNG_PREBUFR
    OBSQMS = MISSNG_PREBUFR

    DO J=1,NUMLEVELS(I)
      IF (HEIGHTOBS(I,J) .NE. RVALUE_MISSING .AND. &
          (TEMPTROBS(I,J) .NE. RVALUE_MISSING) ) THEN

        OBSDAT(1,J) = HEIGHTOBS(I,J)
        OBSDAT(3,J) = TEMPTROBS(I,J)
        ! ASSUMING 1 DEGREE ERROR AS DEFAULT:
        OBSERR(3,J) = 1.0
        IF (TEMPTRERR(I) .NE. RVALUE_MISSING) &
          OBSERR(3,J) = TEMPTRERR(I)

        ! SAVE DATA INTO TMG:
        RK = HEIGHT_TO_PRESSURE(HEIGHTOBS(I,J),HEIGHT_GRID3DM,PRESSR_GRID1DM, &
                       NUMBER_GRIDPTS(1),NUMBER_GRIDPTS(2),NUMBER_GRIDPTS(3), &
                       NINT(RI),NINT(RJ))
        ! FIND THE GRID LEVEL FOR THIS PRESSURE VALUE:
        DO K=1,NUMBER_GRIDPTS(3)
          IF (RK .GE. PRESSR_GRID1DM(K)) EXIT
        ENDDO
        IF (K .GT. NUMBER_GRIDPTS(3)) THEN
          RK = NUMBER_GRIDPTS(3)+1			! OUT OF HEIGHT
        ELSEIF (K .LE. 1) THEN
          RK = 1
          IF (RK .GT. PRESSR_GRID1DM(1)) RK = 0	! OUT OF HEIGHT
        ELSE
          RK = K-(RK-PRESSR_GRID1DM(K))/(PRESSR_GRID1DM(K-1)-PRESSR_GRID1DM(K))
        ENDIF

        WRITE(TMGOUT_CHANNEL,11) RI,RJ,RK,TEMPTROBS(I,J)+237.15,OBSVNTYPE(I)
11	FORMAT(3f10.4,f10.3,3x,a8)

      ENDIF
    ENDDO
    OBSERR(1,1:NUMLEVELS(I)) = 10.0	! ASSUME 10 METER ERROR FOR HEIGHT
    OBSQMS(1,1:NUMLEVELS(I)) = 0	! QUALITY MARK - BUFR CODE TABLE: 
    OBSQMS(4,1:NUMLEVELS(I)) = 0	! 0 always assimilated

    ! WRITE TO BUFR FILE:
    CALL OPENMB(OUTPUT_CHANNEL,SUBSET,INDATE)
    CALL UFBINT(OUTPUT_CHANNEL,HEADER,HEADER_NUMITEM,1,STATUS,HEADER_PREBUFR)
    CALL UFBINT(OUTPUT_CHANNEL,OBSDAT,OBSDAT_NUMITEM, &
                 NUMLEVELS(I),STATUS,OBSDAT_PREBUFR)
    CALL UFBINT(OUTPUT_CHANNEL,OBSERR,OBSERR_NUMITEM, &
                 NUMLEVELS(I),STATUS,OBSERR_PREBUFR)
    CALL UFBINT(OUTPUT_CHANNEL,OBSQMS,OBSQMS_NUMITEM, &
                 NUMLEVELS(I),STATUS,OBSQMS_PREBUFR)
    CALL WRITSB(OUTPUT_CHANNEL)

    ! WRITE SURFACE DATA: FUTURE DEVELOPMENT DEBUG NEEDED
    ! SFCDAT(1) = PRSSFCOBS(I)
    ! SFCDAT(2) = MISSNG_PREBUFR
    ! SFCDAT(3) = TMPSFCOBS(I)
    ! SFCDAT(4) = MISSNG_PREBUFR
    ! USE -132 AS TEMP_REFERENCE:
    ! TEMPERATURE >= TEMP_REFERENCE: RH IS WATER RH;
    ! TEMPERATURE <  TEMP_REFERENCE: RH IS ICE RH;
    ! ASSUME THE SURFACE OBS OF RH IS WATER RH HERE:
    ! SFCDAT(5) = MAKE_SSH(PRSSFCOBS(I),TMPSFCOBS(I),REHSFCOBS(I)/100.0,&
    !              TEMPTR_REFEREN)*0.001 ! KG/KG
    ! CALL OPENMB(OUTPUT_CHANNEL,'ADPSFC',INDATE)
    ! HEADER IS NEEDED TO REFLECT THE OBSERVATION CODE!!!
    ! CALL UFBINT(OUTPUT_CHANNEL,HEADER,HEADER_NUMITEM,1,1,HEADER_PREBUFR)
    ! CALL UFBINT(OUTPUT_CHANNEL,SFCDAT,SURFAC_NUMITEM,1,1,SURFAC_PREBUFR)
    ! CALL UFBINT(OUTPUT_CHANNEL,SFCQMS,SFCQMS_NUMITEM,1,1,SURFAC_PREBUFR)
    ! CALL WRITSB(OUTPUT_CHANNEL)

  ENDDO

END SUBROUTINE BUFR_RASS

SUBROUTINE BUFR_SONDES(NUMSONDES,NUMLEVELS,STATIONID,I4OBSTIME, &
                         LATITUDES,LONGITUDE,ELEVATION,OBSVNTYPE,HEIGHTOBS, &
                         PRESSROBS,TEMPTROBS,DEWPNTOBS,UUWINDOBS,VVWINDOBS)

!==============================================================================
!doc  THIS ROUTINE CONVERTS LAPS SONDE DATA INTO PREPBUFR FORMAT.
!doc
!doc  HISTORY:
!doc	CREATION:	YUANFU XIE/SHIOW-MING DENG	JUN 2007
!==============================================================================

  USE LAPS_PARAMS

  IMPLICIT NONE

  CHARACTER, INTENT(IN) :: STATIONID(*)*5		! STATION ID
  CHARACTER, INTENT(IN) :: OBSVNTYPE(*)*8		! OBS TYPE
  INTEGER,   INTENT(IN) :: NUMSONDES, &                 ! NUMBER OF PROFILERS
                           NUMLEVELS(*)			! NUMBER OF LEVELS
  INTEGER,   INTENT(IN) :: I4OBSTIME(*)			! I4 OBS TIMES

  ! OBSERVATIONS:
  REAL,      INTENT(IN) :: LATITUDES(*),LONGITUDE(*),ELEVATION(*)
  REAL            :: HEIGHTOBS(MAXNUM_SONDES,*), &	! UPAIR (M)
                           PRESSROBS(MAXNUM_SONDES,*), &	! UPAIR (MB)
                           TEMPTROBS(MAXNUM_SONDES,*), &	! UPAIR (C)
                           DEWPNTOBS(MAXNUM_SONDES,*), &	! UPAIR (C)
                           UUWINDOBS(MAXNUM_SONDES,*), &	! UPAIR (M/S)
                           VVWINDOBS(MAXNUM_SONDES,*)		! UPAIR (M/S)

  ! LOCAL VARIABLES:
  CHARACTER :: STTNID*8,SUBSET*8
  INTEGER   :: I,J,K,INDATE,ZEROCH,STATUS
  REAL      :: SSH2,RI,RJ,RK,DI,SP,P,HEIGHT_TO_PRESSURE	! LAPS FUNCTION FOR SPECIFIC HUMIDITY
  REAL*8    :: HEADER(HEADER_NUMITEM),OBSDAT(OBSDAT_NUMITEM,225)
  REAL*8    :: OBSERR(OBSERR_NUMITEM,225),OBSQMS(OBSQMS_NUMITEM,225)
  EQUIVALENCE(STTNID,HEADER(1))

  PRINT*,'Number of sondes: ',NUMSONDES,NUMLEVELS(1:NUMSONDES)

  ! OBS DATE: YEAR/MONTH/DAY
  ZEROCH = ICHAR('0')
  INDATE = YYYYMM_DDHHMIN(1)*1000000+YYYYMM_DDHHMIN(2)*10000+ &
           YYYYMM_DDHHMIN(3)*100+YYYYMM_DDHHMIN(4)

  ! WRITE DATA:
  DO I=1,NUMSONDES

    ! NO VALID LEVEL DATA:
    IF (NUMLEVELS(I) .LE. 0) CYCLE

    ! STATION ID:
    STTNID = STATIONID(I)

    ! DATA TYPE:
    SUBSET = 'ADPUPA'
    SELECT CASE (OBSVNTYPE(I))
    CASE ('RADIOMTR')
      HEADER(2) = 120		! PREPBUFR REPORT TYPE: TABLE 2
      HEADER(3) = 11		! INPUT REPORT TYPE: TABLE 6
      OBSERR(1,1:NUMLEVELS(I)) = 0.0	! ZERO ERROR FOR HEIGHT
      OBSERR(3,1:NUMLEVELS(I)) = 2.0	! ASSUME 2 DEG ERROR
      OBSERR(4,1:NUMLEVELS(I)) = 0.5	! ASSUME 0.5 M/S ERROR
      OBSERR(6,1:NUMLEVELS(I)) = 2.0	! ASSUME 2 MM ERROR
    CASE ('RAOB')
      HEADER(2) = 120           ! PREPBUFR REPORT TYPE: TABLE 2
      HEADER(3) = 11            ! INPUT REPORT TYPE: TABLE 6
      OBSERR(1,1:NUMLEVELS(I)) = 0.0    ! ZERO ERROR FOR HEIGHT
      OBSERR(3,1:NUMLEVELS(I)) = 2.0    ! ASSUME 2 DEG ERROR
      OBSERR(4,1:NUMLEVELS(I)) = 0.5    ! ASSUME 0.5 M/S ERROR
      OBSERR(6,1:NUMLEVELS(I)) = 2.0    ! ASSUME 2 MM ERROR

      ! Test setting RAOB height obs off:
      HEIGHTOBS(I,2:NUMLEVELS(I)) = RVALUE_MISSING	! ASSUME NO ACTUAL HEIGHT OBS ABOVE GROUND
    CASE ('POESSND')
      HEADER(2) = 257		! PREPBUFR REPORT TYPE: TABLE 2
      HEADER(3) = 63		! INPUT REPORT TYPE: TABLE 6: SATELLITE-DERIVED WIND
      OBSERR(1,1:NUMLEVELS(I)) = 0.0	! ZERO ERROR FOR HEIGHT
      OBSERR(3,1:NUMLEVELS(I)) = 2.0	! ASSUME 2 DEG ERROR
      OBSERR(4,1:NUMLEVELS(I)) = 1.0	! 2 M/S ERROR ASSUMED FOR SATWIND
      OBSERR(6,1:NUMLEVELS(I)) = 2.0	! ASSUME 2 MM ERROR
    CASE ('GOES11','GOES12')
      HEADER(2) = 151		! PREPBUFR REPORT TYPE: TABLE 2
      HEADER(3) = 63		! INPUT REPORT TYPE: TABLE 6: SATELLITE-DERIVED WIND
      OBSERR(1,1:NUMLEVELS(I)) = 0.0	! ZERO ERROR FOR HEIGHT
      OBSERR(3,1:NUMLEVELS(I)) = 2.0	! ASSUME 2 DEG ERROR
      OBSERR(4,1:NUMLEVELS(I)) = 1.0	! 2 M/S ERROR ASSUMED FOR SATWIND
      OBSERR(6,1:NUMLEVELS(I)) = 2.0	! ASSUME 2 MM ERROR
    CASE ('DROPSND')
      HEADER(2) = 132           ! PREPBUFR REPORT TYPE: TABLE 2
      HEADER(3) = 31            ! INPUT REPORT TYPE: TABLE 6: DROPSONDE
      OBSERR(1,1:NUMLEVELS(I)) = 0.0    ! ZERO ERROR FOR HEIGHT
      OBSERR(3,1:NUMLEVELS(I)) = 2.0    ! ASSUME 2 DEG ERROR
      OBSERR(4,1:NUMLEVELS(I)) = 1.0    ! 2 M/S ERROR ASSUMED FOR SATWIND
      OBSERR(6,1:NUMLEVELS(I)) = 2.0    ! ASSUME 2 MM ERROR
    CASE DEFAULT
      PRINT*,'BUFR_SONDES: UNKNOWN OBSERVATION DATA TYPE! ',OBSVNTYPE(I),I
      STOP
    END SELECT

    ! TIME:
    IF (ABS(I4OBSTIME(I)-SYSTEM_IN4TIME) .GT. LENGTH_ANATIME) CYCLE	! OUT OF TIME

    HEADER(4) = YYYYMM_DDHHMIN(4)
    HEADER(5) = (I4OBSTIME(I)-SYSTEM_IN4TIME)/3600.0

    ! LAT/LON/ELEVATION:
    HEADER(6) = LATITUDES(I)
    HEADER(7) = LONGITUDE(I)
    HEADER(8) = ELEVATION(I)

    ! IGNORE OBS OUTSIDE THE ANALYSIS DOMAIN:
    CALL LATLON_TO_RLAPSGRID(LATITUDES(I),LONGITUDE(I), &
                              DOMAIN_LATITDE,DOMAIN_LONGITD, &
                              NUMBER_GRIDPTS(1),NUMBER_GRIDPTS(2), &
                              RI,RJ,STATUS)
    IF (RI .LT. 1 .OR. RI .GT. NUMBER_GRIDPTS(1) .OR. &
        RJ .LT. 1 .OR. RJ .GT. NUMBER_GRIDPTS(2)) CYCLE

    HEADER(9) = 90			! INSTRUMENT TYPE: COMMON CODE TABLE C-2
    HEADER(10) = I			! REPORT SEQUENCE NUMBER
    HEADER(11) = 0			! MPI PROCESS NUMBER

    ! UPAIR OBSERVATIONS:
    ! MISSING DATA CONVERSION:
    OBSDAT = MISSNG_PREBUFR
    OBSQMS = MISSNG_PREBUFR
    DO J=1,NUMLEVELS(I)

      ! NO HEIGHT OR PRESSURE INFO:
      P = PRESSROBS(I,J)*100	! PASCAL WHEN FINDING GRID LEVEL
      IF (HEIGHTOBS(I,J) .GE. RVALUE_MISSING .AND. &
           PRESSROBS(I,J) .GE. RVALUE_MISSING) CYCLE	! INVALID DATA

      IF (HEIGHTOBS(I,J) .NE. RVALUE_MISSING) THEN
	OBSDAT(1,J) = HEIGHTOBS(I,J)
        ! WHEN PRESSURE IS MISSING, USE HEIGHT TO CONVERT PRESSURE
        IF (P .GE. RVALUE_MISSING) &
          P = HEIGHT_TO_PRESSURE(HEIGHTOBS(I,J),HEIGHT_GRID3DM, &
                         PRESSR_GRID1DM,NUMBER_GRIDPTS(1),NUMBER_GRIDPTS(2), &
                         NUMBER_GRIDPTS(3),NINT(RI),NINT(RJ))
        OBSERR(1,J) = 10.0	! 10 METER ERROR FOR HEIGHT OBS
      ENDIF

      ! FIND THE GRID LEVEL FOR THIS PRESSURE VALUE:
      DO K=1,NUMBER_GRIDPTS(3)
        IF (P .GE. PRESSR_GRID1DM(K)) EXIT
      ENDDO
      IF (K .GT. NUMBER_GRIDPTS(3)) THEN
        RK = NUMBER_GRIDPTS(3)+1		! OUT OF HEIGHT
      ELSEIF (K .LE. 1) THEN
        RK = 1
        IF (P .GT. PRESSR_GRID1DM(1)) RK = 0	! OUT OF HEIGHT
      ELSE
        RK = K-(P-PRESSR_GRID1DM(K))/(PRESSR_GRID1DM(K-1)-PRESSR_GRID1DM(K))
      ENDIF

      ! OTHER OBS:
      OBSDAT(2,J) = P/100.0	! BUFR PRESSURE IN MB
      OBSERR(2,J) = 10.0

      IF (TEMPTROBS(I,J) .NE. RVALUE_MISSING) THEN
	OBSDAT(3,J) = TEMPTROBS(I,J)
	OBSERR(3,J) = 1.0	! 1 DEGREE ERROR FOR TEMPERATURE

        ! SAVE TEMPERATURE DATA INTO TMG FILE:
        WRITE(TMGOUT_CHANNEL,11) RI,RJ,RK,TEMPTROBS(I,J)+273.15,OBSVNTYPE(I)
11      FORMAT(3f10.4,f10.3,3x,a8)
      ENDIF
      IF (UUWINDOBS(I,J) .NE. RVALUE_MISSING .AND. &
           VVWINDOBS(I,J) .NE. RVALUE_MISSING) THEN
        OBSDAT(4,J) = UUWINDOBS(I,J)
        OBSDAT(5,J) = VVWINDOBS(I,J)
        OBSERR(4,J) = 0.1

        ! SAVE WIND OBS INTO PRG FILE:
        CALL UV_TO_DISP(UUWINDOBS(I,J),VVWINDOBS(I,J),DI,SP)

        WRITE(PRGOUT_CHANNEL,12) RI,RJ,RK,DI,SP,OBSVNTYPE(I)
12	FORMAT(3f8.1,2f10.3,3x,a8)
      ENDIF

      ! SPECIFIC HUMIDITY:
      IF ((DEWPNTOBS(I,J) .NE. RVALUE_MISSING) .AND. &
          (TEMPTROBS(I,J) .NE. RVALUE_MISSING) .AND. &
           DEWPNTOBS(I,J) .LE. TEMPTROBS(I,J)) THEN
        OBSDAT(6,J) = SSH2(P/100.0,TEMPTROBS(I,J), &
                          DEWPNTOBS(I,J),TEMPTR_REFEREN)*1000.0 !MG/KG
        OBSERR(5,J) = 1.0	! ASSUME 1MG/KG ERROR BY YUANFU
      ENDIF
    ENDDO
    OBSQMS(1:6,1:NUMLEVELS(I)) = 1	! QUALITY MARK - BUFR CODE TABLE: 
					! GOOD ASSUMED.

    ! WRITE TO BUFR FILE:
    CALL OPENMB(OUTPUT_CHANNEL,SUBSET,INDATE)
    CALL UFBINT(OUTPUT_CHANNEL,HEADER,HEADER_NUMITEM,1,STATUS,HEADER_PREBUFR)
    CALL UFBINT(OUTPUT_CHANNEL,OBSDAT,OBSDAT_NUMITEM, &
                 NUMLEVELS(I),STATUS,OBSDAT_PREBUFR)
    CALL UFBINT(OUTPUT_CHANNEL,OBSERR,OBSERR_NUMITEM, &
                 NUMLEVELS(I),STATUS,OBSERR_PREBUFR)
    CALL UFBINT(OUTPUT_CHANNEL,OBSQMS,OBSQMS_NUMITEM, &
                 NUMLEVELS(I),STATUS,OBSQMS_PREBUFR)
    CALL WRITSB(OUTPUT_CHANNEL)

  ENDDO

END SUBROUTINE BUFR_SONDES

SUBROUTINE BUFR_SFCOBS(NUMBEROBS,HHMINTIME,LATITUDES,LONGITUDE,STATIONID, &
                         OBSVNTYPE,PROVIDERS,ELEVATION,MSLPRSOBS,MSLPRSERR, &
                         STNPRSOBS,STNPRSERR,TEMPTROBS,TEMPTRERR,WIND2DOBS, &
                         WIND2DERR,RELHUMOBS,RELHUMERR,SFCPRSOBS,PRECP1OBS, &
                         PRECP1ERR)


!==============================================================================
!doc  THIS ROUTINE CONVERTS LAPS SONDE DATA INTO PREPBUFR FORMAT.
!doc
!doc  HISTORY:
!doc	CREATION:	YUANFU XIE/SHIOW-MING DENG	JUN 2007
!==============================================================================

  USE LAPS_PARAMS

  IMPLICIT NONE

  CHARACTER, INTENT(IN) :: STATIONID(*)*20		! STATION ID
  CHARACTER, INTENT(IN) :: PROVIDERS(*)*11		! PROVIDER'S NAME
  CHARACTER, INTENT(IN) :: OBSVNTYPE(*)*6		! OBS TYPE
  INTEGER,   INTENT(IN) :: NUMBEROBS                    ! NUMBER OF PROFILERS
  INTEGER,   INTENT(IN) :: HHMINTIME(*)			! I4 OBS TIMES

  ! OBSERVATIONS:
  REAL,      INTENT(IN) :: LATITUDES(*),LONGITUDE(*),ELEVATION(*)
  ! PRESSURE IN MB, TEMP IN C, WIND IN M/S
  REAL,      INTENT(IN) :: MSLPRSOBS(*), &		! MEAN SEA LEVEL PRESSURE
                           MSLPRSERR(*), &		! ERROR
                           STNPRSOBS(*), &		! STATION PRESSURE
                           STNPRSERR(*), &		! STATION PRESSURE ERROR
                           TEMPTROBS(*), &		! TEMPERATURE
                           TEMPTRERR(*), &		! TEMPERATURE ERROR
                           WIND2DOBS(2,*), &  		! 2D WIND OBS
                           WIND2DERR(2,*), &  		! 2D WINDOBS ERRKR
                           RELHUMOBS(*), &  		! RELATIVE HUMIDITY
                           RELHUMERR(*), &  		! HUMIDITY ERROR
                           SFCPRSOBS(*), &     		! SURFACE PRESSURE
                           PRECP1OBS(*), &   		! PRECIPITATION
                           PRECP1ERR(*)			! PRECIPITATION ERROR

  ! LOCAL VARIABLES:
  CHARACTER :: STTNID*8,SUBSET*8
  INTEGER   :: I,K,INDATE,ZEROCH,STATUS
  INTEGER   :: I4TIME
  REAL      :: MAKE_SSH		! LAPS FUNCTION FOR SPECIFIC HUMIDITY FROM RH
  REAL      :: RI,RJ,RK,DI,SP,HEIGHT_TO_PRESSURE
  REAL*8    :: HEADER(HEADER_NUMITEM),OBSDAT(OBSDAT_NUMITEM)
  REAL*8    :: OBSERR(OBSERR_NUMITEM),OBSQMS(OBSQMS_NUMITEM)
  EQUIVALENCE(STTNID,HEADER(1))

  PRINT*,'Number of surface obs: ',NUMBEROBS

  ! OBS DATE: YEAR/MONTH/DAY
  ZEROCH = ICHAR('0')
  INDATE = YYYYMM_DDHHMIN(1)*1000000+YYYYMM_DDHHMIN(2)*10000+ &
           YYYYMM_DDHHMIN(3)*100+YYYYMM_DDHHMIN(4)

  ! WRITE DATA:
  DO I=1,NUMBEROBS

    ! STATION ID:
    STTNID = STATIONID(I)

    ! DATA TYPE:
    SUBSET = 'ADPSFC'
    SELECT CASE (OBSVNTYPE(I))
    CASE ('MARTIM','SYNOP')	! MARINE AND SYNOP
      HEADER(2) = 281		! BUFR REPORT TYPE:  TABLE 2
      HEADER(3) = 511		! INPUT REPORT TYPE: TABLE 6
    CASE ('METAR','SPECI','LDAD') ! SPECI: SPECIAL METAR DATA
      HEADER(2) = 181		! BUFR REPORT TYPE:  TABLE 2
      HEADER(3) = 512		! INPUT REPORT TYPE: TABLE 6
    CASE ('DROPSN')
      HEADER(2) = 132           ! PREPBUFR REPORT TYPE: TABLE 2
      HEADER(3) = 31            ! INPUT REPORT TYPE: TABLE 6: DROPSONDE
    CASE DEFAULT
      PRINT*,'BUFR_SFCOBS: UNKOWN OBSERVATION DATA TYPE! ',OBSVNTYPE(I),' SKIP ',I
      CYCLE
      ! CLOSE(OUTPUT_CHANNEL)
      ! STOP
    END SELECT

    ! TIME:
    CALL GET_SFC_OBTIME(HHMINTIME(I),SYSTEM_IN4TIME,I4TIME,STATUS)
    IF (ABS(I4TIME-SYSTEM_IN4TIME) .GT. LENGTH_ANATIME) CYCLE	! OUT OF TIME

    HEADER(4) = YYYYMM_DDHHMIN(4)
    HEADER(5) = (I4TIME-SYSTEM_IN4TIME)/3600.0

    ! LAT/LON/ELEVATION:
    HEADER(6) = LATITUDES(I)
    HEADER(7) = LONGITUDE(I)
    HEADER(8) = ELEVATION(I)

    ! IGNORE OBS OUTSIDE THE ANALYSIS DOMAIN:
    CALL LATLON_TO_RLAPSGRID(LATITUDES(I),LONGITUDE(I), &
                              DOMAIN_LATITDE,DOMAIN_LONGITD, &
                              NUMBER_GRIDPTS(1),NUMBER_GRIDPTS(2), &
                              RI,RJ,STATUS)
    IF (RI .LT. 1 .OR. RI .GT. NUMBER_GRIDPTS(1) .OR. &
        RJ .LT. 1 .OR. RJ .GT. NUMBER_GRIDPTS(2)) CYCLE

    HEADER(9) = 90			! INSTRUMENT TYPE: COMMON CODE TABLE C-2
    HEADER(10) = I			! REPORT SEQUENCE NUMBER
    HEADER(11) = 0			! MPI PROCESS NUMBER

    ! UPAIR OBSERVATIONS:
    ! MISSING DATA CONVERSION:
    OBSDAT = MISSNG_PREBUFR
    OBSERR = MISSNG_PREBUFR
    OBSQMS = MISSNG_PREBUFR

    ! SURFACE OBS: ZOB IS THE ELEVATION HEIGHT:
    OBSDAT(1) = ELEVATION(I)
    OBSERR(1) = 10.0		! 10 METER ERROR ASSUMED

    ! GET PRESSURE FROM HEIGHT FIRST:
    RK = HEIGHT_TO_PRESSURE(ELEVATION(I),HEIGHT_GRID3DM, &
                         PRESSR_GRID1DM,NUMBER_GRIDPTS(1),NUMBER_GRIDPTS(2), &
                         NUMBER_GRIDPTS(3),NINT(RI),NINT(RJ))

    ! SURFACE PRESSURE:
    IF ((STNPRSOBS(I) .NE. RVALUE_MISSING) .AND. &
        (STNPRSOBS(I) .NE. SFCOBS_INVALID)) THEN
      OBSDAT(2) = STNPRSOBS(I)
      RK = STNPRSOBS(I)*100	! USE PASCAL TO FIND GRID LEVEL
    ENDIF

    ! FIND THE GRID LEVEL FOR THIS PRESSURE VALUE:
    DO K=1,NUMBER_GRIDPTS(3)
      IF (RK .GE. PRESSR_GRID1DM(K)) EXIT
    ENDDO
    IF (K .GT. NUMBER_GRIDPTS(3)) THEN
      RK = NUMBER_GRIDPTS(3)+1			! OUT OF HEIGHT
    ELSEIF (K .LE. 1) THEN
      RK = 1
      IF (RK .GT. PRESSR_GRID1DM(1)) RK = 0	! OUT OF HEIGHT
    ELSE
      RK = K-(RK-PRESSR_GRID1DM(K))/(PRESSR_GRID1DM(K-1)-PRESSR_GRID1DM(K))
    ENDIF

    ! OTHER PRESSURE OBS:
    IF ((MSLPRSOBS(I) .NE. RVALUE_MISSING) .AND. &
        (MSLPRSOBS(I) .NE. SFCOBS_INVALID)) OBSDAT(7) = MSLPRSOBS(I)
    IF ((SFCPRSOBS(I) .NE. RVALUE_MISSING) .AND. &
        (SFCPRSOBS(I) .NE. SFCOBS_INVALID)) OBSDAT(8) = SFCPRSOBS(I)

    ! TEMPERATURE OBS:
    IF ((TEMPTROBS(I) .NE. RVALUE_MISSING) .AND. &
        (TEMPTROBS(I) .NE. SFCOBS_INVALID)) THEN
	OBSDAT(3) = TEMPTROBS(I)

        ! TEMP ERROR:
        OBSERR(3) = 1.0		! ASSUME 1 DEGREE DEFAULT ERROR
        IF ((TEMPTRERR(I) .NE. RVALUE_MISSING) .AND. &
            (TEMPTRERR(I) .NE. SFCOBS_INVALID)) OBSERR(3) = TEMPTRERR(I)

        ! SAVE TEMPERATURE INTO TMG FILE:
        WRITE(TMGOUT_CHANNEL,11) RI,RJ,RK,OBSDAT(3)+273.15,OBSVNTYPE(I)
11	FORMAT(3f10.4,f10.3,3x,a8)
    ENDIF

    ! WIND OBS:
    IF ((WIND2DOBS(1,I) .NE. RVALUE_MISSING) .AND. &
         (WIND2DOBS(1,I) .NE. SFCOBS_INVALID) .AND. &
         (WIND2DOBS(2,I) .NE. RVALUE_MISSING) .AND. &
         (WIND2DOBS(2,I) .NE. SFCOBS_INVALID)) THEN
      OBSDAT(4) = WIND2DOBS(1,I)
      OBSDAT(5) = WIND2DOBS(2,I)

      ! SAVE WIND OBS INTO PRG FILE:
       CALL UV_TO_DISP(WIND2DOBS(1,I),WIND2DOBS(2,I),DI,SP)

       WRITE(PRGOUT_CHANNEL,12) RI,RJ,RK,DI,SP,OBSVNTYPE(I)
12     FORMAT(3f8.1,2f10.3,3x,a8)
    ENDIF

    OBSERR(4) = 0.1	! ASSUME 0.1 M/S WIND ERROR AS DEFAULT
    IF ((WIND2DERR(1,I) .NE. RVALUE_MISSING) .AND. &
        (WIND2DERR(1,I) .NE. SFCOBS_INVALID) .AND. &
        (WIND2DERR(2,I) .NE. RVALUE_MISSING) .AND. &
        (WIND2DERR(2,I) .NE. SFCOBS_INVALID)) &
	OBSERR(4) = SQRT(WIND2DERR(1,I)**2+WIND2DERR(2,I)**2)
    ! SPECIFIC HUMIDITY:
    IF ((SFCPRSOBS(I) .NE. RVALUE_MISSING) .AND. &
        (SFCPRSOBS(I) .NE. SFCOBS_INVALID) .AND. &
        (TEMPTROBS(I) .NE. RVALUE_MISSING) .AND. &
        (TEMPTROBS(I) .NE. SFCOBS_INVALID) .AND. &
        (RELHUMOBS(I) .NE. RVALUE_MISSING) .AND. &
        (RELHUMOBS(I) .NE. SFCOBS_INVALID)) THEN
      OBSDAT(6) = MAKE_SSH(SFCPRSOBS(I),OBSDAT(3),RELHUMOBS(I)/100.0,&
                           TEMPTR_REFEREN)*1000.0 ! MG/KG
      OBSERR(5) = 1.0	! ASSUME 1MG/KG ERROR BY YUANFU
      !IF ((STNPRSERR(I) .NE. RVALUE_MISSING) .AND. &
      !  (STNPRSERR(I) .NE. SFCOBS_INVALID) .AND. &
      !  (TEMPTRERR(I) .NE. RVALUE_MISSING) .AND. &
      !  (TEMPTRERR(I) .NE. SFCOBS_INVALID) .AND. &
      !  (RELHUMERR(I) .NE. RVALUE_MISSING) .AND. &
      !  (RELHUMERR(I) .NE. SFCOBS_INVALID)) &
      !OBSERR(5) = MAKE_SSH(STNPRSERR(I),OBSERR(3),RELHUMERR(I)/100.0,&
      !                     TEMPTR_REFEREN)*1000.0 ! MG/KG
    ENDIF
    IF ((PRECP1OBS(I) .NE. RVALUE_MISSING) .AND. &
        (PRECP1OBS(I) .NE. SFCOBS_INVALID)) OBSDAT(9) = PRECP1OBS(I)*INCHES_CONV2MM
    IF ((PRECP1ERR(I) .NE. RVALUE_MISSING) .AND. &
        (PRECP1ERR(I) .NE. SFCOBS_INVALID)) OBSERR(6) = PRECP1ERR(I)
    OBSQMS(1:5) = 0	! QUALITY MARK - BUFR CODE TABLE: 
			! 0 always assimilated.

    ! WRITE TO BUFR FILE:
    CALL OPENMB(OUTPUT_CHANNEL,SUBSET,INDATE)
    CALL UFBINT(OUTPUT_CHANNEL,HEADER,HEADER_NUMITEM,1,STATUS,HEADER_PREBUFR)
    CALL UFBINT(OUTPUT_CHANNEL,OBSDAT,OBSDAT_NUMITEM,1,STATUS,OBSDAT_PREBUFR)
    CALL UFBINT(OUTPUT_CHANNEL,OBSERR,OBSERR_NUMITEM,1,STATUS,OBSERR_PREBUFR)
    CALL UFBINT(OUTPUT_CHANNEL,OBSQMS,OBSQMS_NUMITEM,1,STATUS,OBSQMS_PREBUFR)
    CALL WRITSB(OUTPUT_CHANNEL)

  ENDDO

END SUBROUTINE BUFR_SFCOBS

SUBROUTINE BUFR_CDWACA(NUMBEROBS,OBSVARRAY,OBI4ARRAY)

!==============================================================================
!doc  THIS ROUTINE CONVERTS LAPS CLOUD DRIFT WIND AND ACARS DATA INTO PREPBUFR
!doc  FORMAT.
!doc
!doc  HISTORY:
!doc	CREATION:	YUANFU XIE/SHIOW-MING DENG	JUN 2007
!==============================================================================

  USE LAPS_PARAMS

  IMPLICIT NONE

  INTEGER, INTENT(IN) :: NUMBEROBS,OBI4ARRAY(3,*)
  REAL*8,  INTENT(IN) :: OBSVARRAY(7,*)

  ! LOCAL VARIABLES:
  CHARACTER :: STTNID*8,SUBSET*8,PIGNAME*8
  INTEGER   :: I,K,INDATE,ZEROCH,STATUS
  REAL      :: RI,RJ,RK,U,V,DI,SP,HEIGHT_TO_PRESSURE
  REAL*8    :: HEADER(HEADER_NUMITEM),OBSDAT(OBSDAT_NUMITEM)
  REAL*8    :: OBSERR(OBSERR_NUMITEM),OBSQMS(OBSQMS_NUMITEM)
  EQUIVALENCE(STTNID,HEADER(1))

  PRINT*,'Number of cloud drift wind and ACAR obs: ',NUMBEROBS

  ! OBS DATE: YEAR/MONTH/DAY
  ZEROCH = ICHAR('0')
  INDATE = YYYYMM_DDHHMIN(1)*1000000+YYYYMM_DDHHMIN(2)*10000+ &
           YYYYMM_DDHHMIN(3)*100+YYYYMM_DDHHMIN(4)

  ! WRITE DATA:
  DO I=1,NUMBEROBS

    HEADER(2:3) = OBI4ARRAY(1:2,I)	! CODE AND REPORT TYPE
    SELECT CASE (OBI4ARRAY(2,I))
    CASE (241)
      ! STATION ID:
      STTNID = 'CDW'
      PIGNAME = 'cdw'
      ! DATA TYPE:
      SUBSET = 'SATWND'
    CASE (130,230)
      ! STATION ID:
      STTNID = 'ACAR'
      PIGNAME = 'pin'
      ! DATA TYPE:
      SUBSET = 'AIRCAR'
    CASE DEFAULT
      PRINT*,'BUFR_CDWACA: UNKNOWN OBSERVATION DATA TYPE! ',OBI4ARRAY(2,I)
      STOP
    END SELECT

    ! TIME:
    IF (ABS(OBI4ARRAY(3,I)-SYSTEM_IN4TIME) .GT. LENGTH_ANATIME) CYCLE	! OUT OF TIME

    HEADER(4) = YYYYMM_DDHHMIN(4)
    HEADER(5) = (OBI4ARRAY(3,I)-SYSTEM_IN4TIME)/3600.0

    ! LAT/LON/ELEVATION:
    HEADER(6) = OBSVARRAY(1,I)
    HEADER(7) = OBSVARRAY(2,I)
    HEADER(8) = OBSVARRAY(3,I)

    ! IGNORE OBS OUTSIDE THE ANALYSIS DOMAIN:
    DI = OBSVARRAY(1,I)		! FROM REAL*8 TO REAL
    SP = OBSVARRAY(2,I)
    CALL LATLON_TO_RLAPSGRID(DI,SP, &
                              DOMAIN_LATITDE,DOMAIN_LONGITD, &
                              NUMBER_GRIDPTS(1),NUMBER_GRIDPTS(2), &
                              RI,RJ,STATUS)
    IF (RI .LT. 1 .OR. RI .GT. NUMBER_GRIDPTS(1) .OR. &
        RJ .LT. 1 .OR. RJ .GT. NUMBER_GRIDPTS(2)) CYCLE

    HEADER(9) = 90			! INSTRUMENT TYPE: COMMON CODE TABLE C-2
					! CANNOT FIND CODE TABLE FOR ACARS INSTRUMENT
    HEADER(10) = I			! REPORT SEQUENCE NUMBER
    HEADER(11) = 0			! MPI PROCESS NUMBER

    ! UPAIR OBSERVATIONS:
    ! MISSING DATA CONVERSION:
    OBSDAT = MISSNG_PREBUFR
    OBSERR = MISSNG_PREBUFR
    OBSQMS = MISSNG_PREBUFR

    ! HEIGHT OBS:
    IF (OBSVARRAY(3,I) .NE. RVALUE_MISSING) THEN
      OBSDAT(1) = OBSVARRAY(3,I)	! HEIGHT
      ! GET PRESSURE FROM HEIGHT FIRST:
      DI = OBSVARRAY(3,I)		! REAL*8 TO REAL
      RK = HEIGHT_TO_PRESSURE(DI,HEIGHT_GRID3DM, &
                         PRESSR_GRID1DM,NUMBER_GRIDPTS(1),NUMBER_GRIDPTS(2), &
                         NUMBER_GRIDPTS(3),NINT(RI),NINT(RJ))
    ENDIF

    ! PRESSURE OBS:
    IF (OBSVARRAY(4,I) .NE. RVALUE_MISSING) THEN
      OBSDAT(2) = OBSVARRAY(4,I)	! PRESSURE IN MB
      RK = OBSVARRAY(4,I)*100.0		! PASCAL
    ENDIF
    ! FIND THE GRID LEVEL FOR THIS PRESSURE VALUE:
    DO K=1,NUMBER_GRIDPTS(3)
      IF (RK .GE. PRESSR_GRID1DM(K)) EXIT
    ENDDO
    IF (K .GT. NUMBER_GRIDPTS(3)) THEN
      RK = NUMBER_GRIDPTS(3)+1			! OUT OF HEIGHT
    ELSEIF (K .LE. 1) THEN
      RK = 1
      IF (RK .GT. PRESSR_GRID1DM(1)) RK = 0	! OUT OF HEIGHT
    ELSE
      RK = K-(RK-PRESSR_GRID1DM(K))/(PRESSR_GRID1DM(K-1)-PRESSR_GRID1DM(K))
    ENDIF

    ! TEMPERATURE OBS:
    IF (OBSVARRAY(7,I) .NE. RVALUE_MISSING) THEN
      OBSDAT(3) = OBSVARRAY(7,I)	! LAPS_Ingest(C) uses READ_ACARS_OB (F)

      ! SAVE TEMPERATURE OBS INTO TMG FILE:
      WRITE(TMGOUT_CHANNEL,11) RI,RJ,RK,OBSVARRAY(7,I)+273.15,STTNID
11    FORMAT(3f10.4,f10.3,3x,a8)
    ENDIF

    ! WIND OBS:
    IF (OBSVARRAY(5,I) .NE. RVALUE_MISSING .AND. &
         OBSVARRAY(6,I) .NE. RVALUE_MISSING) THEN
      OBSDAT(4) = OBSVARRAY(5,I)	! U
      OBSDAT(5) = OBSVARRAY(6,I)	! V

      ! SAVE WIND OBS INTO PRG FILE:
      U = OBSVARRAY(5,I)	! CONVERT TO REAL FROM REAL*8
      V = OBSVARRAY(6,I)
      CALL UV_TO_DISP(U,V,DI,SP)

      WRITE(PIGOUT_CHANNEL,12) RI,RJ,RK,DI,SP,PIGNAME(1:3)
12    FORMAT(1x,3f8.1,2f8.1,x,a3)
    ENDIF

    OBSERR(1) = 0.0	! ZERO ERROR FOR HEIGHT
    OBSERR(3) = 0.0	! ASSUME 0 DEG ERROR
    OBSERR(4) = 0.0	! ASSUME 0 M/S ERROR
    OBSQMS(1:6) = 1	! QUALITY MARK - BUFR CODE TABLE: 
					! GOOD ASSUMED.

    ! WRITE TO BUFR FILE:
    CALL OPENMB(OUTPUT_CHANNEL,SUBSET,INDATE)
    CALL UFBINT(OUTPUT_CHANNEL,HEADER,HEADER_NUMITEM,1,STATUS,HEADER_PREBUFR)
    CALL UFBINT(OUTPUT_CHANNEL,OBSDAT,OBSDAT_NUMITEM,1,STATUS,OBSDAT_PREBUFR)
    CALL UFBINT(OUTPUT_CHANNEL,OBSERR,OBSERR_NUMITEM,1,STATUS,OBSERR_PREBUFR)
    CALL UFBINT(OUTPUT_CHANNEL,OBSQMS,OBSQMS_NUMITEM,1,STATUS,OBSQMS_PREBUFR)
    CALL WRITSB(OUTPUT_CHANNEL)
  ENDDO

END SUBROUTINE BUFR_CDWACA
