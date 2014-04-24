MODULE READ_BACKGRD
!*************************************************
! READ IN BACKGROUND INFORMATIONS
! HISTORY: JANUARY 2008, DIVORCED FROM INPUT_BG_OBS MODULE by ZHONGJIE HE.
!*************************************************

  USE PRMTRS_STMAS
  USE DRAWCOUNTOUR ,  ONLY : DRCONTOUR, DRCONTOUR_2D

  PUBLIC    TPG, BK0, C00, D00, X00, Y00, T00, P00, Z00, DX0, DY0, DZ0, DT0, HEIGHTU, HEIGHTL
  PUBLIC    RDLAPSBKG, RDBCKGRND, ALLOCTBKG, DEALCTBKG, RDBKGTEST

  REAL                  :: DX0,DY0
  REAL     ,ALLOCATABLE :: X00(:,:),Y00(:,:),T00(:),P00(:),Z00(:), DZ0(:,:,:)
  REAL     ,ALLOCATABLE :: TPG(:,:),BK0(:,:,:,:,:),C00(:,:),D00(:,:)
  REAL     ,ALLOCATABLE :: HEIGHTU(:,:),HEIGHTL(:,:)

! ===========ADDED BY ZHONGJIE HE JUST FOR DRAW PICTURES.
  PUBLIC    ORI_LON, ORI_LAT, END_LON, END_LAT
  REAL                  :: ORI_LON, ORI_LAT, END_LON, END_LAT
! =======================================================

!***************************************************
!!COMMENT:
!   THIS MODULE IS MAINLY USED BY THE MODULE OF INPUT_BG_OBS, THE AIM IS TO READ BACKGROUND INFORMATIONS FROM MODELS OR SOME INITIAL FIELDS.
!   SUBROUTINES:
!      ALLOCTBKG: MEMORY ALLOCATE FOR X00, Y00, P00, Z00, TPG, BK0, C00, D00.
!      DEALCTBKG: MEMORY DEALLOCATE FOR X00, Y00, P00, Z00, TPG, BK0, C00, D00. 
!      RDLAPSBKG: READ IN BACKGROUND FROM LAPS SYSTEM.
!      RDBCKGRND: READ IN BACKGROUND FROM DATA FILES OF 'FORT.11'.
!      RDBKGTEST: JUST A TEMPORARY SUBROUTINE TO CONSTRUCTION A BACKGROUND FOR A TEST CASE.
!   ARRAYS:
!      TPG: TOPOGRAPHY
!      BK0: BACKGROUND FIELDS ON THE ORIGINAL GRID POINTS (SUCH AS MODELS OR LAPS SYSTEMS).
!      C00: CORIOLIS FORCE ON THE ORIGINAL GIRD.
!      D00: ROTATE ANGLE'S OF THE COORDINATE TO THE EAST-NORTH COORDINATE. (GUESSED BY ZHONGJIE HE)
!      X00: LONGITUDE OF THE ORIGINAL GRID POINTS.
!      Y00: LATITUDE OF THE ORIGINAL GRID POINTS.
!      P00: PRESURES AT EACH LEVEL
!      Z00: HEIGHT OF EACH LEVEL
!      DX0: GRID SPACING IN X DIRECTION, UNIT IS METER 
!      DY0: GRID SPACING IN Y DIRECTION, UNIT IS METER
!   VARIABLES:
!      ORI_LON: LONGITUDE OF THE EAST BOUNDARY OF THE AREA
!      ORI_LAT: LATITUDE OF THE SOUTH BOUNDARY OF THE AREA
!      END_LON: LONGITUDE OF THE WEST BOUNDARY OF THE AREA
!      END_LAT: LATITUDE OF THE NORTH BOUNDARY OF TEH AREA
CONTAINS

SUBROUTINE ALLOCTBKG
!*************************************************
! MEMORY ALLOCATE FOR X00, Y00, P00, Z00, TPG, BK0, C00, D00
! HISTORY: SEPTEMBER 2007, CODED by WEI LI.
!          OCTOBER   2007, by YUANFU XIE (USE LAPS)
!          JANUARY   2008, DIVORCED FROME MEMORYALC SUBROUTINE BY ZHONGJIE HE
!*************************************************
  IMPLICIT NONE
! --------------------
  INTEGER  :: ER
! --------------------
  ALLOCATE(BK0(FCSTGRD(1),FCSTGRD(2),FCSTGRD(3),FCSTGRD(4),NUMSTAT+3),STAT=ER)
  IF(ER.NE.0)STOP 'BK0 ALLOCATE WRONG'
  ALLOCATE(X00(FCSTGRD(1),FCSTGRD(2)),STAT=ER)
  IF(ER.NE.0)STOP 'X00 ALLOCATE WRONG'
  ALLOCATE(Y00(FCSTGRD(1),FCSTGRD(2)),STAT=ER)
  IF(ER.NE.0)STOP 'Y00 ALLOCATE WRONG'
  ALLOCATE(TPG(FCSTGRD(1),FCSTGRD(2)),STAT=ER)
  IF(ER.NE.0)STOP 'TPG ALLOCATE WRONG'
  ALLOCATE(C00(FCSTGRD(1),FCSTGRD(2)),STAT=ER)
  IF(ER.NE.0)STOP 'C00 ALLOCATE WRONG'
  ALLOCATE(D00(FCSTGRD(1),FCSTGRD(2)),STAT=ER)
  IF(ER.NE.0)STOP 'D00 ALLOCATE WRONG'
  ALLOCATE(P00(FCSTGRD(3)),STAT=ER)
  IF(ER.NE.0)STOP 'P00 ALLOCATE WRONG'
  ALLOCATE(Z00(FCSTGRD(3)),STAT=ER)
  IF(ER.NE.0)STOP 'Z00 ALLOCATE WRONG'
  ALLOCATE(DZ0(FCSTGRD(1),FCSTGRD(2),FCSTGRD(3)),STAT=ER)
  IF(ER.NE.0)STOP 'DZ0 ALLOCATE WRONG'
  ALLOCATE(HEIGHTU(FCSTGRD(1),FCSTGRD(2)),STAT=ER)
  IF(ER.NE.0)STOP 'HEIGHTU ALLOCATE WRONG'
  ALLOCATE(HEIGHTL(FCSTGRD(1),FCSTGRD(2)),STAT=ER)
  IF(ER.NE.0)STOP 'HEIGHTL ALLOCATE WRONG'
  ALLOCATE(T00(FCSTGRD(4)),STAT=ER)
  IF(ER.NE.0)STOP 'T00 ALLOCATE WRONG'

  ! ALLOCATE SPACE FOR LAPS LAT/LON/TOPOGRAPHY GRIDS (YUANFU):
  ALLOCATE(LATITUDE(FCSTGRD(1),FCSTGRD(2)),LONGITUD(FCSTGRD(1),FCSTGRD(2)), &
             TOPOGRPH(FCSTGRD(1),FCSTGRD(2)),STAT=ER)
  IF (ER.NE.0) THEN
    PRINT*,'ALLOCTBKG: cannot allocate memory for laps lat/lon/topography'
    STOP
  ENDIF

  RETURN
END SUBROUTINE ALLOCTBKG

SUBROUTINE DEALCTBKG
!*************************************************
! MEMORY DEALLOCATE FOR X00, Y00, P00, Z00, TPG, BK0, C00, D00
! HISTORY: SEPTEMBER 2007, CODED by WEI LI.
!          OCTOBER   2007, by YUANFU XIE (USE LAPS)
!          JANUARY   2008, SEPARATED FROME MEMORYALC SUBROUTINE BY ZHONGJIE HE
!*************************************************
  IMPLICIT NONE
! --------------------
  ! DEALLOCATE(BK0)		FOR KEEPING THE BACKGROUND TO THE END BY YUANFU
  DEALLOCATE(X00)
  DEALLOCATE(Y00)
  DEALLOCATE(TPG)
  DEALLOCATE(C00)
  DEALLOCATE(D00)
  DEALLOCATE(P00)
  DEALLOCATE(Z00)
  DEALLOCATE(DZ0)
  DEALLOCATE(HEIGHTU)
  DEALLOCATE(HEIGHTL)
  DEALLOCATE(T00)

  ! DEALLOCATE LAPS VARIABLES:
  IF (IF_TEST .NE. 0) DEALLOCATE(LATITUDE, LONGITUD, TOPOGRPH)

  RETURN
END SUBROUTINE DEALCTBKG

SUBROUTINE RDLAPSBKG
!*************************************************
! READ IN BACKGROUND FROM LAPS SYSTEM
! HISTORY: SEPTEMBER 2007, CODED by WEI LI.
!          OCTOBER   2007, by YUANFU XIE (USE LAPS)
!
!          MODIFIED DEC. 2013 BY YUANFU READING IN
!          SURFACE PRESSURE.
!*************************************************
  IMPLICIT NONE
! --------------------
  INTEGER  :: I,J,K,T,LN
  CHARACTER(LEN=256) :: DR
  CHARACTER*4  :: LVL_COORD
  CHARACTER*10 :: UNIT
  CHARACTER*125 :: COMMENT
  REAL  :: OX,OY,EX,EY

  CHARACTER*4  :: VN            ! VARNAME ADDED BY YUANFU
  CHARACTER*9  :: TM            ! ASCII TIME ADDED BY YUANFU
  INTEGER      :: ST            ! STATUS OF LAPS CALLS ADDED BY YUANFU
  INTEGER*4    :: I4            ! SYSTEM I4 TIME ADDED BY YUANFU
  REAL         :: P1(FCSTGRD(3)),DS(2)
  REAL :: D2R

  ! Include a statement function for converting sh to 'rh' = sh/s2r(p) by Yuanfu Xie:
  include 'sh2rh.inc'

  D2R = 3.14159/180.0

!        'LA' AND 'LO' ARE RESPECTIVELY THE LATITUDE AND LONGITUDE OF EACH GRIDPOINT
!        'P1' IS THE PRESSURE OF EACH LEVEL
! --------------------

  IF(IFPCDNT.NE.1) THEN              !   BY ZHONGJIEHE
    PRINT*, 'ERROR! LAPS IS PRESSURE COORDINATE! PLEASE SET IFPCDNT TO 1!'
    STOP
  ENDIF                              !   END OF MODIFIED BY ZHONGJIE HE

  ! LAPS CYCLE/SYSTEM TIMES:
  ! CALL GET_SYSTIME(ITIME2(2),TM,ST)	! MOVE TO LAPS_CONFIG
  ! CALL GET_LAPS_CYCLE_TIME(ICYCLE,ST)! MOVE TO LAPS_CONFIG

  ! STMAS TIME WINDOW TEMPORARILY USES (-0.5CYCLE, 0.5*CYCLE):
  !ITIME2(1) = ITIME2(2)-(FCSTGRD(4)-1)*ICYCLE
  ITIME2(1) = LAPSI4T-ICYCLE/2
  ITIME2(2) = LAPSI4T+ICYCLE/2

  ! USE LAPS INGEST TO READ BACKGROUND FIELDS: ADDED BY YUANFU

  ! CURRENTLY ONLY WORKING FOR FCSTGRD(4)=3:
  IF (FCSTGRD(4) .NE. 3) THEN
    PRINT*,'Currently, STMAS 3D has been tested only for 3 time frames!'
    PRINT*,'Change the RDLAPSBKG code for an analysis with different time frames!'
    STOP
  ENDIF

  ! BACKGROUND TIME:
  DO T=1,FCSTGRD(4)
    T00(T) = (T-1)/FLOAT(FCSTGRD(4)-1)*(ITIME2(2)-ITIME2(1))
  ENDDO

  ! PRESSURE LEVELS:
  CALL GET_PRES_1D(I4,FCSTGRD(3),P1,ST)

  DO T=1,2			! READ IN PREVIOUS TWO TIME FRAMES
    ! SYSTEM TIME:
    I4 = LAPSI4T+(T-2)*ICYCLE	! USE HALF LAPS TIME FRAMES BY YUANFU

    ! HEIGHT FIELD:
    VN = 'HT'
    CALL GET_MODELFG_3D(I4,VN,FCSTGRD(1),FCSTGRD(2),FCSTGRD(3),BK0(1,1,1,T,PRESSURE),ST)
    IF (ST .NE. 1) THEN
      PRINT*,'RDLAPSBKG: No HT background available at time frame: ',T
      STOP
    ENDIF
    ! TEMPERATURE FIELD:
    VN = 'T3'
    CALL GET_MODELFG_3D(I4,VN,FCSTGRD(1),FCSTGRD(2),FCSTGRD(3),BK0(1,1,1,T,TEMPRTUR),ST)
    IF (ST .NE. 1) THEN
      PRINT*,'RDLAPSBKG: No T3 background available at time frame: ',T
      STOP
    ENDIF
    ! WIND U:
    VN = 'U3'
    CALL GET_MODELFG_3D(I4,VN,FCSTGRD(1),FCSTGRD(2),FCSTGRD(3),BK0(1,1,1,T,U_CMPNNT),ST)
    IF (ST .NE. 1) THEN
      PRINT*,'RDLAPSBKG: No U3 background available at time frame: ',T
      STOP
    ENDIF
    ! WIND V:
    VN = 'V3'
    CALL GET_MODELFG_3D(I4,VN,FCSTGRD(1),FCSTGRD(2),FCSTGRD(3),BK0(1,1,1,T,V_CMPNNT),ST)
    IF (ST .NE. 1) THEN
      PRINT*,'RDLAPSBKG: No V3 background available at time frame: ',T
      STOP
    ENDIF
    ! SPECIFIC HUMIDITY:
    VN = 'SH'
    CALL GET_MODELFG_3D(I4,VN,FCSTGRD(1),FCSTGRD(2),FCSTGRD(3),BK0(1,1,1,T,HUMIDITY),ST)
    IF (ST .NE. 1) THEN
      PRINT*,'RDLAPSBKG: No SH background available at time frame: ',T
      IF (NUMSTAT .GT. 4) STOP
    ENDIF
    print*,'Minvalue of LAPS SH: ', &
      minval(BK0(1:FCSTGRD(1),1:FCSTGRD(2),1:FCSTGRD(3),T,HUMIDITY))

    ! Convert SH to 'RH' = SH/s2r(p) by Yuanfu Xie:
    DO I=1,FCSTGRD(1)
    DO J=1,FCSTGRD(2)
    DO K=1,FCSTGRD(3)
      BK0(I,J,K,T,HUMIDITY) = BK0(I,J,K,T,HUMIDITY)*1000.0/s2r(P1(K)/100.0) ! LGA HUMIDITY: KG/KG
    ENDDO
    ENDDO
    ENDDO

    ! SURFACE PRESSURE:
    IF (T .EQ. 2) THEN
      VN = 'PS'
      CALL GET_DIRECTORY('lsx',DR,LN)
      CALL READ_LAPS(I4,I4,DR,'lsx',FCSTGRD(1),FCSTGRD(2),1,1,VN,0, &
                     LVL_COORD,UNIT,COMMENT,P_SFC_F,ST)
    ENDIF
  ENDDO

  ! INTERPOLATE THE BACKGROUND AT PREVIOUS AND AFTER TIME FRAMES:
  ! INTERPOLATION:	PREVIOUS TIME FRAME
  DO I=1,FCSTGRD(1)
  DO J=1,FCSTGRD(2)
  DO K=1,FCSTGRD(3)
    BK0(I,J,K,1,PRESSURE)=0.5*(BK0(I,J,K,1,PRESSURE)+BK0(I,J,K,2,PRESSURE))
    BK0(I,J,K,1,TEMPRTUR)=0.5*(BK0(I,J,K,1,TEMPRTUR)+BK0(I,J,K,2,TEMPRTUR))
    BK0(I,J,K,1,U_CMPNNT)=0.5*(BK0(I,J,K,1,U_CMPNNT)+BK0(I,J,K,2,U_CMPNNT))
    BK0(I,J,K,1,V_CMPNNT)=0.5*(BK0(I,J,K,1,V_CMPNNT)+BK0(I,J,K,2,V_CMPNNT))
    BK0(I,J,K,1,HUMIDITY)=0.5*(BK0(I,J,K,1,HUMIDITY)+BK0(I,J,K,2,HUMIDITY))
  ENDDO
  ENDDO
  ENDDO
  ! EXTRAPOLATION: AFTER TIME FRAME
  DO I=1,FCSTGRD(1)
  DO J=1,FCSTGRD(2)
  DO K=1,FCSTGRD(3)
    BK0(I,J,K,3,PRESSURE)=1.5*BK0(I,J,K,2,PRESSURE)-0.5*BK0(I,J,K,1,PRESSURE)
    BK0(I,J,K,3,TEMPRTUR)=1.5*BK0(I,J,K,2,TEMPRTUR)-0.5*BK0(I,J,K,1,TEMPRTUR)
    BK0(I,J,K,3,U_CMPNNT)=1.5*BK0(I,J,K,2,U_CMPNNT)-0.5*BK0(I,J,K,1,U_CMPNNT)
    BK0(I,J,K,3,V_CMPNNT)=1.5*BK0(I,J,K,2,V_CMPNNT)-0.5*BK0(I,J,K,1,V_CMPNNT)
    BK0(I,J,K,3,HUMIDITY)=amax1(0.0,1.5*BK0(I,J,K,2,HUMIDITY)-0.5*BK0(I,J,K,1,HUMIDITY))
  ENDDO
  ENDDO
  ENDDO

  ! GRID SPACING:
  CALL GET_GRID_SPACING_ACTUAL(LATITUDE((FCSTGRD(1)-1)/2+1,(FCSTGRD(2)-1)/2+1), &
                               LONGITUD((FCSTGRD(1)-1)/2+1,(FCSTGRD(2)-1)/2+1),DS,ST)

  DX0=DS(1)
  DY0=DX0 !DS(2)

  ! CONVERT TO REAL 8:
  Y00 = LATITUDE
  X00 = LONGITUD
  TPG = TOPOGRPH
  P00 = P1

  ! END OF YUANFU'S MODIFICATION

  DO J=1,FCSTGRD(2)
  DO I=1,FCSTGRD(1)
    D00(I,J)=0.0D0
    C00(I,J)=2.0*7.29E-5*SIN(D2R*Y00(I,J))
  ENDDO
  ENDDO

  ! MODIFIED BY YUANFU FOR CHECKING IF RAIN AND SNOW IS ANALYZED:
  IF (NUMSTAT .GT. 5) THEN
  DO T=1,FCSTGRD(4)
  DO K=1,FCSTGRD(3)
  DO J=1,FCSTGRD(2)
  DO I=1,FCSTGRD(1)
    !added by shuyuan for ref  20100811
    BK0(I,J,K,T,ROUR_CMPNNT) =0.0
    BK0(I,J,K,T,ROUS_CMPNNT) =0.0

  ENDDO
  ENDDO
  ENDDO
  ENDDO
  ENDIF

!===============
  DO K=1,FCSTGRD(3)
    Z_FCSTGD(K)=P00(K)
  ENDDO
  ! ADDED BY YUANFU FOR CHECKING IF VERTICAL GRID IS UNIFORM:
  UNIFORM = 1    ! DEFAULT UNIFORM
  DO K=2,FCSTGRD(3)-1
    ! NOTE: PRESSURE COORDINATE IS IN PASCAL AND 1 PASCAL IS USED AS A THRESHOLD:
    IF (ABS(Z_FCSTGD(K)-Z_FCSTGD(K+1)-Z_FCSTGD(1)+Z_FCSTGD(2)) .GE. 1.0) UNIFORM = 0
  ENDDO
!===============
  OX=X00(1,1)
  EX=X00(FCSTGRD(1),FCSTGRD(2))
  OY=Y00(1,1)
  EY=Y00(FCSTGRD(1),FCSTGRD(2))

  ORI_LON=OX
  ORI_LAT=OY
  END_LON=EX
  END_LAT=EY

  RETURN
END SUBROUTINE RDLAPSBKG


SUBROUTINE RDBKGTEST
!*************************************************
! READ IN TEST DATA OF BACKGROUND
! HISTORY: FEBRUARY 2008, CODED by ZHONGJIE HE.
!*************************************************
  IMPLICIT NONE

  ! REMOVED AS IT IS NOT USED.

END SUBROUTINE RDBKGTEST


END MODULE READ_BACKGRD
