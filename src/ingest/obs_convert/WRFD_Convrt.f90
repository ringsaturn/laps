SUBROUTINE WRFD_PROFLR(NUMPRFLS,NUMLEVEL,STTNAMES,OBSTIMES,OBSVNLAT,OBSVNLON, &
                       OBSVNELV,REPORTYP,MAXPRFLR,HEIGHTOB,UWINDOBS,VWINDOBS,PSSFCOBS, &
                       TMPSFCOB,RHSFCOBS,USFCOBSV,VSFCOBSV)

!==============================================================================
!doc  THIS ROUTINE CONVERTS PROFILER DATA INTO WRF DATA FORMAT.
!doc
!doc  HISTORY:
!doc	CREATION:	YUANFU XIE	JUN 2007
!==============================================================================

  USE LAPS_PARAMS

  IMPLICIT NONE

  CHARACTER,INTENT(IN) :: REPORTYP(*)*8,STTNAMES(*)*5
  INTEGER,  INTENT(IN) :: NUMPRFLS,NUMLEVEL(*)
  INTEGER,  INTENT(IN) :: OBSTIMES(MAXPRFLR),MAXPRFLR
  REAL,     INTENT(IN) :: OBSVNLAT(MAXPRFLR), &
                          OBSVNLON(MAXPRFLR), &
                          OBSVNELV(MAXPRFLR)
  REAL                 :: PSSFCOBS(*),TMPSFCOB(*), &
                          RHSFCOBS(*),USFCOBSV(*),VSFCOBSV(*)
  REAL                 :: HEIGHTOB(MAXPRFLR,*), &
                          UWINDOBS(MAXPRFLR,*), &
                          VWINDOBS(MAXPRFLR,*)

  ! LOCAL VARIABLES:
  CHARACTER :: OBTIME*14,VARCH1*40,VARCH2*40
  INTEGER   :: I,J,STATUS
  REAL,PARAMETER :: MISSNG=-888888.000

  ! WRITE OUT EACH SURFACE STATION:
  DO I=1,NUMPRFLS
    OBTIME = NUMBER_ASCTIME
    CALL MAKE_FNAM_LP(OBSTIMES(I),VARCH1,STATUS)
    WRITE(OBTIME(9:14),2) VARCH1(6:9),'00'
2   FORMAT(A4,A2)
    IF (OBTIME(9:9) .EQ. ' ') OBTIME(9:9) = '0'

    ! WRITE OBS TIME:
    WRITE(OUTPUT_CHANNEL,101) OBTIME

    ! WRITE LAT/LON:
    WRITE(OUTPUT_CHANNEL,102) OBSVNLAT(I),OBSVNLON(I)

    ! WRITE STATION NAME AND DATA NAME:
    VARCH1 = '                                         '
    VARCH1(1:20) = STTNAMES(I)
    WRITE(OUTPUT_CHANNEL,1021) VARCH1,'PROFILER DATA FROM LAPS DATA INGEST'

    ! WRITE ELEVATION ETC:
    VARCH1 = '                                         '
    VARCH2 = '                                         '
    VARCH1 = REPORTYP(I)
    WRITE(OUTPUT_CHANNEL,103) VARCH1,VARCH2,OBSVNELV(I),.TRUE.,.FALSE.,NUMLEVEL(I)

    ! WRITE DATA AT ALL LEVELS:
    DO J=1,NUMLEVEL(I)
      IF ((PSSFCOBS(I) .EQ. RVALUE_MISSING) .OR. &
          (PSSFCOBS(I) .EQ. SFCOBS_INVALID) .OR. J .GT. 1) PSSFCOBS(I) = MISSNG
      IF (HEIGHTOB(I,J) .EQ. RVALUE_MISSING) HEIGHTOB(I,J) = MISSNG
      IF ((TMPSFCOB(I) .EQ. RVALUE_MISSING) .OR. &
          (TMPSFCOB(I) .EQ. SFCOBS_INVALID) .OR. J .GT. 1) TMPSFCOB(I) = MISSNG
      IF (UWINDOBS(I,J) .EQ. RVALUE_MISSING) UWINDOBS(I,J) = MISSNG
      IF (VWINDOBS(I,J) .EQ. RVALUE_MISSING) VWINDOBS(I,J) = MISSNG
      IF ((RHSFCOBS(I) .EQ. RVALUE_MISSING) .OR. &
          (RHSFCOBS(I) .EQ. SFCOBS_INVALID) .OR. J .GT. 1) RHSFCOBS(I) = MISSNG

      WRITE(OUTPUT_CHANNEL,104) PSSFCOBS(I),	0.0, &
                                HEIGHTOB(I,J),  0.0, &
                                TMPSFCOB(I),    0.0, &
                                UWINDOBS(I,J),  0.0, &
                                VWINDOBS(I,J),  0.0, &
                                RHSFCOBS(I),    0.0
    ENDDO

  ENDDO

  ! WRF DATA FORMATS:
  INCLUDE 'WRFD_Format.inc'

END SUBROUTINE WRFD_PROFLR

SUBROUTINE WRFD_SONDES(NUMPRFLS,NUMLEVEL,STTNAMES,OBSTIMES,OBSVNLAT,OBSVNLON, &
                       OBSVNELV,REPORTYP,HEIGHTOB,PRESSOBS,TEMPTOBS,DEWTDOBS, &
                       UWINDOBS,VWINDOBS)

!==============================================================================
!doc  THIS ROUTINE CONVERTS SONDE DATA INTO WRF DATA FORMAT.
!doc
!doc  HISTORY:
!doc	CREATION:	YUANFU XIE	JUN 2007
!==============================================================================

  USE LAPS_PARAMS
  
  IMPLICIT NONE

  CHARACTER,INTENT(IN) :: REPORTYP(*)*8,STTNAMES(*)*5
  INTEGER,  INTENT(IN) :: NUMPRFLS,NUMLEVEL(*)
  INTEGER,  INTENT(IN) :: OBSTIMES(MAXNUM_PROFLRS,*)
  REAL,     INTENT(IN) :: OBSVNLAT(MAXNUM_PROFLRS,*), &
                          OBSVNLON(MAXNUM_PROFLRS,*), &
                          HEIGHTOB(MAXNUM_PROFLRS,*), &
                          OBSVNELV(MAXNUM_PROFLRS)
  REAL                 :: PRESSOBS(MAXNUM_PROFLRS,*), &
                          TEMPTOBS(MAXNUM_PROFLRS,*), &
                          DEWTDOBS(MAXNUM_PROFLRS,*), &
                          UWINDOBS(MAXNUM_PROFLRS,*), &
                          VWINDOBS(MAXNUM_PROFLRS,*)

  ! LOCAL VARIABLES:
  CHARACTER :: OBTIME*14,VARCH1*40,VARCH2*40
  INTEGER   :: I,J,STATUS
  REAL      :: HUMIDITY
  REAL,PARAMETER :: MISSNG=-888888.000

  ! WRITE OUT EACH SURFACE STATION:
  DO I=1,NUMPRFLS
    DO J=1,NUMLEVEL(I)

      OBTIME = NUMBER_ASCTIME
      CALL MAKE_FNAM_LP(OBSTIMES(I,J),VARCH1,STATUS)
      WRITE(OBTIME(9:14),2) VARCH1(6:9),'00'
2     FORMAT(A4,A2)
      IF (OBTIME(9:9) .EQ. ' ') OBTIME(9:9) = '0'

      ! WRITE OBS TIME:
      WRITE(OUTPUT_CHANNEL,101) OBTIME

      ! WRITE LAT/LON:
      WRITE(OUTPUT_CHANNEL,102) OBSVNLAT(I,J),OBSVNLON(I,J)

      ! WRITE STATION NAME AND DATA NAME:
      VARCH1 = '                                         '
      VARCH2 = '                                         '
      VARCH1(1:20) = STTNAMES(I)
      WRITE(OUTPUT_CHANNEL,1021) VARCH1,'SONDE DATA FROM LAPS DATA INGEST'

      ! WRITE ELEVATION ETC:
      VARCH1 = '                                         '
      VARCH2 = '                                         '
      VARCH1 = REPORTYP(I)
      WRITE(OUTPUT_CHANNEL,103) VARCH1,VARCH2,HEIGHTOB(I,J),.TRUE.,.FALSE.,1

      ! CONVERT LAPS MISSING TO WRF MISSING:
      IF (PRESSOBS(I,J) .EQ. RVALUE_MISSING) THEN
        PRESSOBS(I,J) = MISSNG
      ELSE
        PRESSOBS(I,J) = PRESSOBS(I,J)*100.0	! PASCALS
      ENDIF
      IF (TEMPTOBS(I,J) .EQ. RVALUE_MISSING) THEN
        TEMPTOBS(I,J) = MISSNG
      ELSE
        IF (DEWTDOBS(I,J) .EQ. RVALUE_MISSING) THEN
          DEWTDOBS(I,J) = MISSNG
        ELSE
          ! SAVE RH IN DEWTDOBS:
          DEWTDOBS(I,J) = HUMIDITY(TEMPTOBS(I,J),DEWTDOBS(I,J))
        ENDIF
        TEMPTOBS(I,J) = (TEMPTOBS(I,J) - 32.0)*5.0/9.0+ABSOLU_TMPZERO
      ENDIF
      IF (UWINDOBS(I,J) .EQ. RVALUE_MISSING) THEN
        UWINDOBS(I,J) = MISSNG
      ENDIF
      IF (VWINDOBS(I,J) .EQ. RVALUE_MISSING) THEN
        VWINDOBS(I,J) = MISSNG
      ENDIF

      ! WRITE OBS:
      WRITE(OUTPUT_CHANNEL,104) PRESSOBS(I,J),	0.0, &
                                HEIGHTOB(I,J),  0.0, &
                                TEMPTOBS(I,J),  0.0, &
                                UWINDOBS(I,J),  0.0, &
                                VWINDOBS(I,J),  0.0, &
                                DEWTDOBS(I,J),  0.0

    ENDDO

  ENDDO

  ! WRF DATA FORMATS:
  INCLUDE 'WRFD_Format.inc'

END SUBROUTINE WRFD_SONDES

SUBROUTINE WRFD_SFCOBS(NUMBROBS,OBSTIMES,OBSVNLAT,OBSVNLON, &
                       STTNAMES,REPORTYP,PRVDNAME,OBSVNELV,MSLPRESS,MSLPSERR, &
                       REFPRESS,REFPSERR,TEMPTOBS,TMPERROR,WINDINUV,UVWNDERR, &
                       OBSVNRHS,ERRORRHS,SFCPRESS,PRECIPTN,ERRPRECP)

!==============================================================================
!doc  THIS ROUTINE CONVERTS SURFACE OBS INTO WRF DATA FORMAT.
!doc
!doc  HISTORY:
!doc	CREATION:	YUANFU XIE	JUN 2007
!==============================================================================

  USE LAPS_PARAMS

  IMPLICIT NONE

  CHARACTER, INTENT(IN) :: STTNAMES(*)*20, &
                           REPORTYP(*)*6,PRVDNAME(*)*11
  INTEGER,   INTENT(IN) :: NUMBROBS
  INTEGER*4, INTENT(IN) :: OBSTIMES(*)
  REAL*4                :: OBSVNLAT(*),OBSVNLON(*),OBSVNELV(*), &
                           MSLPRESS(*),MSLPSERR(*), &
                           REFPRESS(*),REFPSERR(*), &
                           TEMPTOBS(*),TMPERROR(*), &
                           WINDINUV(2,*),UVWNDERR(2,*), &
                           OBSVNRHS(*),ERRORRHS(*), &
                           SFCPRESS(*),PRECIPTN(*),ERRPRECP(*)

  ! LOCAL VARIABLES:
  CHARACTER :: OBTIME*14,VARCH1*40,VARCH2*40
  INTEGER   :: I,STATUS
  REAL      :: PRSERR(2)
  REAL,PARAMETER :: MISSNG=-888888.000

  VARCH1 = '                                         '
  VARCH2 = '                                         '

  ! WRITE OUT EACH SURFACE STATION:
  DO I=1,NUMBROBS
    OBTIME = NUMBER_ASCTIME
    WRITE(OBTIME(9:14),2) OBSTIMES(I),'00'
2   FORMAT(I4,A2)
    IF (OBTIME(9:9) .EQ. ' ') OBTIME(9:9) = '0'

    ! WRITE OBS TIME:
    WRITE(OUTPUT_CHANNEL,101) OBTIME

    ! WRITE LAT/LON:
    WRITE(OUTPUT_CHANNEL,102) OBSVNLAT(I),OBSVNLON(I)

    ! WRITE STATION NAME AND DATA NAME:
    VARCH1(1:20) = STTNAMES(I)
    WRITE(OUTPUT_CHANNEL,1021) VARCH1,'ALL-SFC FROM LAPS DATA INGEST'

    ! WRITE ELEVATION ETC:
    VARCH1 = '                                         '
    VARCH2 = '                                         '
    VARCH1 = REPORTYP(I)
    WRITE(OUTPUT_CHANNEL,103) VARCH1,VARCH2,OBSVNELV(I),.FALSE.,.FALSE.,1

    ! CONVERT LAPS MISSING TO WRF MISSING:
    IF ((MSLPRESS(I) .EQ. RVALUE_MISSING) .OR. &
        (MSLPRESS(I) .EQ. SFCOBS_INVALID)) THEN
      MSLPRESS(I) = MISSNG
      PRSERR(1) = MISSNG
    ELSE
      MSLPRESS(I) = MSLPRESS(I)*100.0		! TO PASCALS
      PRSERR(1) = MSLPSERR(I)*100.0		! TO PASCALS
    ENDIF
    IF ((REFPRESS(I) .EQ. RVALUE_MISSING) .OR. &
        (REFPRESS(I) .EQ. SFCOBS_INVALID)) THEN
      REFPRESS(I) = MISSNG
      PRSERR(2) = MISSNG
    ELSE
      REFPRESS(I) = REFPRESS(I)*100.0		! TO PASCALS
      PRSERR(2) = REFPSERR(I)*100.0		! TO PASCALS
    ENDIF
    IF ((TEMPTOBS(I) .EQ. RVALUE_MISSING) .OR. &
        (TEMPTOBS(I) .EQ. SFCOBS_INVALID)) THEN
      TEMPTOBS(I) = MISSNG
      TMPERROR(I) = MISSNG
    ELSE
      TEMPTOBS(I) = (TEMPTOBS(I) - 32.0)*5.0/9.0+ABSOLU_TMPZERO
      TMPERROR(I) = TMPERROR(I)*5.0/9.0
    ENDIF
    IF ((WINDINUV(1,I) .EQ. RVALUE_MISSING) .OR. &
        (WINDINUV(1,I) .EQ. SFCOBS_INVALID)) THEN
      WINDINUV(1,I) = MISSNG
      UVWNDERR(1,I) = MISSNG
    ENDIF
    IF ((WINDINUV(2,I) .EQ. RVALUE_MISSING) .OR. &
        (WINDINUV(2,I) .EQ. SFCOBS_INVALID)) THEN
      WINDINUV(2,I) = MISSNG
      UVWNDERR(2,I) = MISSNG
    ENDIF
    IF ((OBSVNRHS(I) .EQ. RVALUE_MISSING) .OR. &
        (OBSVNRHS(I) .EQ. SFCOBS_INVALID)) THEN
      OBSVNRHS(I) = MISSNG
      ERRORRHS(I) = MISSNG
    ENDIF
    IF ((SFCPRESS(I) .EQ. RVALUE_MISSING) .OR. &
        (SFCPRESS(I) .EQ. SFCOBS_INVALID)) THEN
      SFCPRESS(I) = MISSNG
      MSLPSERR(I) = MISSNG
    ENDIF
    IF ((PRECIPTN(I) .EQ. RVALUE_MISSING) .OR. &
        (PRECIPTN(I) .EQ. SFCOBS_INVALID)) THEN
      PRECIPTN(I) = MISSNG
      ERRPRECP(I) = MISSNG
    ENDIF

    ! WRITE OBS:
    WRITE(OUTPUT_CHANNEL,105) MSLPRESS(I),	PRSERR(1), &
                              REFPRESS(I),	PRSERR(2), &
                              MISSNG,		MISSNG, &
                              TEMPTOBS(I),	TMPERROR(I), &
                              WINDINUV(1,I),	UVWNDERR(1,I), &
                              WINDINUV(2,I),	UVWNDERR(2,I), &
                              OBSVNRHS(I),	ERRORRHS(I), &
                              SFCPRESS(I),	MSLPSERR(I), &
                              PRECIPTN(I),	ERRPRECP(I)
  ENDDO

  ! WRF DATA FORMATS:
  INCLUDE 'WRFD_Format.inc'

END SUBROUTINE WRFD_SFCOBS

SUBROUTINE WRFD_CDWACA(NUMBEROB,OBSARRAY,OBSI4DAT)
  PRINT*,'PLEASE COMPLETE THIS ROUTINE!'
  STOP
END SUBROUTINE WRFD_CDWACA