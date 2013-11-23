MODULE STMAS4D_CORE

  USE PRMTRS_STMAS
  USE GENERALTOOLS
  USE PREP_STMAS4D
  USE POST_STMAS4D
  USE COSTFUN_GRAD
  USE WCOMPT_GRADT,  ONLY : WCOMPGERNL

CONTAINS

SUBROUTINE MGANALYSS0
!*************************************************
! MULTI-GRID ANALYSIS
! HISTORY: AUGUST 2007, CODED by WEI LI.
!*************************************************
  IMPLICIT NONE
! --------------------
  INTEGER  :: N
! --------------------
  PRINT*,'PREPROCSS'
  CALL PREPROCSS
  N=0
  GRDLEVL=0
  DO WHILE(.TRUE.)
    N=N+1
    GRDLEVL=GRDLEVL+1
    PRINT*,'NUMBER',GRDLEVL,'LEVEL GRID IS IN PROCESSING'
    CALL RDINITBGD
    PRINT*,'PHYSCPSTN'
    CALL PHYSCPSTN
    PRINT*,'GETCOEFFT'
    CALL GETCOEFFT
    IF(NUMVARS.EQ.0)EXIT
    PRINT*,'MINIMIZER'
    CALL MINIMIZER_XIE
    IF(GRDLEVL.EQ.FNSTGRD)EXIT
    IF(GRDLEVL.LE.4.OR.(N.GE.9.AND.GRDLEVL.GE.5))THEN
      PRINT*,'COAS2FINE'
      CALL COAS2FINE_XIE	! USE XIE'S AS THE OLD HAS ERROR
    ELSE
      GRDLEVL=GRDLEVL-2
      PRINT*,'FINE2COAS'
      CALL FINE2COAS_XIE	! USE XIE'S AS THE OLD HAS ERROR
    ENDIF

  ENDDO
  PRINT*,'PSTPROCSS'
  CALL PSTPROCSS
  RETURN
END SUBROUTINE MGANALYSS0

SUBROUTINE MGANALYSS
!*************************************************
! MULTI-GRID ANALYSIS
! HISTORY: AUGUST 2007, CODED by WEI LI.
!*************************************************
  IMPLICIT NONE
!------------------------
  INTEGER       :: IT,FW
!                  FW=1: FROM COARSE GRID TO FINE GRID
!                  FW=0: FROM FINE GRID TO COARSE GRID
   INTEGER  :: I,J,K,T,S
 
  INTEGER  ::NUM,NO,N,O   !shuyuan 20100901
  INTEGER  :: NP(MAXDIMS)  !shuyuan 
!------------------------

  PRINT*,'PREPROCSS'
  CALL PREPROCSS

  GRDLEVL=0
  IT=0
  FW=1
  NUM=0
    DO WHILE(.TRUE.)

      GRDLEVL=GRDLEVL+1
      PRINT*,'NUMBER',GRDLEVL,'LEVEL GRID IS IN PROCESSING'
      CALL RDINITBGD
      PRINT*,'PHYSCPSTN'
      CALL PHYSCPSTN
      PRINT*,'GETCOEFFT'
      CALL GETCOEFFT

      IF(NUMVARS.EQ.0)EXIT

      PRINT*,'MINIMIZER'
      CALL MINIMIZER_XIE
      IF(GRDLEVL.EQ.FNSTGRD .AND. IT.EQ.ITREPET)EXIT

      IF(IFREPET.EQ.0) THEN
        PRINT*,'COAS2FINE'
        CALL COAS2FINE_XIE		! USE XIE'S AS THE OLD HAS ERROR
      ELSE
        IF(GRDLEVL.EQ.FNSTGRD) FW=0
        IF(GRDLEVL.EQ.1) THEN
          FW=1
          IT=IT+1
        ENDIF
        IF(FW.EQ.1) THEN
          PRINT*,'COAS2FINE'
          CALL COAS2FINE_XIE		! USE XIE'S AS THE OLD HAS ERROR
        ELSE
          GRDLEVL=GRDLEVL-2
          PRINT*,'FINE2COAS'
          CALL FINE2COAS_XIE		! USE XIE'S AS THE OLD HAS ERROR
        ENDIF
      ENDIF

    ENDDO
!   CALL GETW
  PRINT*,'PSTPROCSS'
  CALL PSTPROCSS
  RETURN
END SUBROUTINE MGANALYSS

SUBROUTINE TMPMEMALC
!*************************************************
! MEMORY ALLOCATE FOR TMP ARRAY
! HISTORY: AUGUST 2007, CODED by WEI LI.
!*************************************************
  IMPLICIT NONE
! --------------------
  INTEGER  :: I,J,K,T,S,ER
! --------------------
  ALLOCATE(TMPANALS(NTMPGRD(1),NTMPGRD(2),NTMPGRD(3),NTMPGRD(4),NUMSTAT),STAT=ER)
  IF(ER.NE.0)STOP 'TMPANALS ALLOCATE WRONG'
  DO T=1,NTMPGRD(4)
  DO K=1,NTMPGRD(3)
  DO J=1,NTMPGRD(2)
  DO I=1,NTMPGRD(1)
    DO S=1,NUMSTAT
      TMPANALS(I,J,K,T,S)=GRDANALS(I,J,K,T,S)
    ENDDO
  ENDDO
  ENDDO
  ENDDO
  ENDDO
  RETURN
END SUBROUTINE TMPMEMALC

SUBROUTINE TMPMEMRLS
!*************************************************
! MEMORY RELEASE FOR TMP ARRAY
! HISTORY: AUGUST 2007, CODED by WEI LI.
!*************************************************
  IMPLICIT NONE
  DEALLOCATE(TMPANALS)
  RETURN
END SUBROUTINE TMPMEMRLS

SUBROUTINE GETCOEFFT
!*************************************************
! GET GRID POINT COEFFICENT FOR EVERY OBSERVATION
! HISTORY: AUGUST 2007, CODED by WEI LI.
!*************************************************
  IMPLICIT NONE
! --------------------
  INTEGER  :: I,J,K,T,O,M,N,UV,RR
  INTEGER  :: LM(MAXDIMS)
  INTEGER  :: NP(MAXDIMS),NN(MAXDIMS)
  REAL     :: AC(NUMDIMS,NGPTOBS),OC(NUMDIMS),CO(NGPTOBS)
! --------------------
! GET INTERPOLATION COEFFICENT
  UV=0
  RR=0
  IF(NALLOBS.EQ.0) RETURN
  DO O=1,NALLOBS
    DO N=1,MAXDIMS
      NP(N)=1
    ENDDO
    DO N=1,NUMDIMS
      NP(N)=INT((OBSPOSTN(N,O)-ORIPSTN(N))/GRDSPAC(N))+1
      IF(NP(N).EQ.NUMGRID(N).AND.NUMGRID(N).NE.1)NP(N)=NUMGRID(N)-1
      IF(NUMGRID(N).EQ.1)NP(N)=1
    ENDDO
    DO N=1,MAXDIMS
      OBSIDXPC(N,O)=NP(N)
    ENDDO
    M=0
!====================================================
!    DO T=NP(4),MIN0(NP(4)+1,NUMGRID(4))
!    DO K=NP(3),MIN0(NP(3)+1,NUMGRID(3))
!    DO J=NP(2),MIN0(NP(2)+1,NUMGRID(2))
!    DO I=NP(1),MIN0(NP(1)+1,NUMGRID(1))
!      NN(1)=I
!      NN(2)=J
!      NN(3)=K
!      NN(4)=T
!      M=M+1
!      DO N=1,NUMDIMS
!        AC(N,M)=NN(N)*1.0
!      ENDDO
!    ENDDO
!    ENDDO
!    ENDDO
!    ENDDO
!    DO N=1,NUMDIMS
!      OC(N)=(OBSPOSTN(N,O)-ORIPSTN(N))/GRDSPAC(N)+1
!    ENDDO
!================== modified by zhongjie he ========
    DO N=1,MAXDIMS
      LM(N)=NP(N)+1
      IF(NUMDIMS.LT.N) LM(N)=NP(N)
    ENDDO
    DO T=NP(4),LM(4)
    DO K=NP(3),LM(3)
    DO J=NP(2),LM(2)
    DO I=NP(1),LM(1)
      NN(1)=MIN0(I,NUMGRID(1))
      NN(2)=MIN0(J,NUMGRID(2))
      NN(3)=MIN0(K,NUMGRID(3))
      NN(4)=MIN0(T,NUMGRID(4))
      M=M+1
      DO N=1,NUMDIMS
        AC(N,M)=NN(N)*1.0
      ENDDO
    ENDDO
    ENDDO
    ENDDO
    ENDDO
    DO N=1,NUMDIMS
      IF(NUMGRID(N).GE.2) THEN
        OC(N)=(OBSPOSTN(N,O)-ORIPSTN(N))/GRDSPAC(N)+1
      ELSE
        OC(N)=1
      ENDIF
    ENDDO
!====================================================
    ! CALL INTERPLTN_XIE(NUMDIMS,NGPTOBS,CO,AC,OC,3,NUMGRID(3),PPM)
    CALL INTERPLTN(NUMDIMS,NGPTOBS,CO,AC,OC)
    DO M=1,NGPTOBS
      OBSCOEFF(M,O)=CO(M)
    ENDDO
  ENDDO
  UV=NOBSTAT(U_CMPNNT)+NOBSTAT(V_CMPNNT)
  RR=NOBSTAT(NUMSTAT+1)
  OBSRADAR = 1.0
  IF(RR.NE.0)OBSRADAR=100.0*UV/FLOAT(RR)
  RR=NOBSTAT(NUMSTAT+2)
  OBS_SFMR = 1.0
  IF(RR.NE.0)OBS_SFMR=1.0/RR
!jhui 
  RR=NOBSTAT(NUMSTAT+3)
  IF(RR.NE.0)OBSREF=1.0/RR
  
  RETURN
END SUBROUTINE GETCOEFFT

SUBROUTINE MINIMIZER_XIE
!*************************************************
! MINIMIZE THE COST FUNCTION
! HISTORY: AUGUST 2007, CODED by WEI LI.
!
!          MODIFIED BY YUANFU FOR USING A SINGLE
!          PRECISION LBFGS ROUTINE
!*************************************************
  IMPLICIT NONE
! --------------------
  INTEGER ,PARAMETER :: MM=5
  CHARACTER(LEN=60) :: TA,CS
  LOGICAL           :: LS(4)
  INTEGER    :: I0,IC,IP,IT,ISBMN,N,O,S,T,K,J,I,NO,ER
  INTEGER    :: IS(44),NB(NUMVARS),IW(3*NUMVARS)
  INTEGER    :: NN(MAXDIMS+1),NG(MAXDIMS+1),NC
  REAL       :: MN(NUMSTAT+3),MX(NUMSTAT+3)

  REAL :: LB(NUMVARS), UB(NUMVARS)
  REAL :: FA, PG, DS(29)
  REAL,ALLOCATABLE :: WA(:)

  REAL  ::temp,temp1,temp2,dif1,dif2,temp0
  INTEGER::  locx,locy,locz,loct,locv
! --------------------

  ! ALLOCATE WORKING ARRAY:
  ALLOCATE(WA(2*MM*NUMVARS+4*NUMVARS+12*MM*MM+12*MM),STAT=ER)
  IF (ER .NE. 0) THEN
    PRINT*,'MINIMIZER: Cannot allocate enough memory for the working array'
    STOP
  ELSE
    PRINT*,'Successfully allocate memory for LBFGS!'
  ENDIF

  IP=1
  FA=1.0d+2
  PG=1.0d-10
  ISBMN = 1	! SUBSPACE MINIMIZATION
  DO N=1,NUMVARS
    NB(N)=0
    LB(N)=0.0
    UB(N)=0.0
  ENDDO

  ! BOUND: IF IFBOUND EQ 1, USE (MIN(OBS), MAX(OBS)) TO BOUND
  !        ANALYSIS
  IF(IFBOUND.EQ.1 .AND. NALLOBS.GE.1)THEN

    ! FIND THE MIN(OBS) AND MAX(OBS):

    ! BOUND AT LEAST ALLOW ZERO INCREMENT: BY YUANFU CORRECTING ZHONGJIE'S SETTING
    MN = 0.0
    MX = 0.0

    ! CONVENTIONAL OBS:
    DO N=1,MAXDIMS
      NG(N)=NUMGRID(N)
    ENDDO
    NG(MAXDIMS+1)=NUMSTAT+1
    O=0
    DO S=1,NUMSTAT
      DO NO=1,NOBSTAT(S)
        O=O+1
        MN(S)=MIN(MN(S),OBSVALUE(O))
        MX(S)=MAX(MX(S),OBSVALUE(O))
      ENDDO
    ENDDO

    ! RADAR AND SFMR:
    S=NUMSTAT+1
    DO NO=1,NOBSTAT(S)
      O=O+1
      MN(U_CMPNNT)=MIN(MN(U_CMPNNT),OBSVALUE(O))
      MX(U_CMPNNT)=MAX(MX(U_CMPNNT),OBSVALUE(O))
      MN(V_CMPNNT)=MIN(MN(V_CMPNNT),OBSVALUE(O))
      MX(V_CMPNNT)=MAX(MX(V_CMPNNT),OBSVALUE(O))
    ENDDO
    S=NUMSTAT+2
    DO NO=1,NOBSTAT(S)
      O=O+1
      MN(U_CMPNNT)=MIN(MN(U_CMPNNT),-1.*OBSVALUE(O))
      MX(U_CMPNNT)=MAX(MX(U_CMPNNT),OBSVALUE(O))
      MN(V_CMPNNT)=MIN(MN(V_CMPNNT),-1.*OBSVALUE(O))
      MX(V_CMPNNT)=MAX(MX(V_CMPNNT),OBSVALUE(O))
    ENDDO
!jhui
!----------------------------------
!changed by shuyuan 20100722
!      MN(6) =0.0
!      MX(6) =0.0
       
    S=NUMSTAT+3
    MN(S) =0.0
    MX(S) =0.0
    DO NO=1,NOBSTAT(S)
      O=O+1
      MN(S)=MIN(MN(S),OBSVALUE(O))
      MX(S)=MAX(MX(S),OBSVALUE(O))
    ENDDO

    DO S=6,7
     MN(S) =0.0
     MX(S) =0.0
     DO NO=1,NOBSTAT(S)
      O=O+1
      MN(S)=0.
      MX(S)=1000.!just for test
     ENDDO
    ENDDO
!--------------------------------------------------
    DO S=1,5!!NUMSTAT+1 
      DO T=1,NUMGRID(4)
      DO K=1,NUMGRID(3)
      DO J=1,NUMGRID(2)
      DO I=1,NUMGRID(1)
        NN(1)=I
        NN(2)=J
        NN(3)=K
        NN(4)=T
        NN(MAXDIMS+1)=S
        CALL PSTN2NUMB(MAXDIMS+1,NN,NG,NC)
        IF(MN(S).LE.MX(S))THEN
          NB(NC)=2
          LB(NC)=MN(S)
          UB(NC)=MX(S)
        ELSE
          NB(NC)=0
          LB(NC)=0.0D0
          UB(NC)=0.0D0
        ENDIF
      ENDDO
      ENDDO
      ENDDO
      ENDDO
    ENDDO


    IF(IFBKGND.EQ.1)THEN
      DO N=1,NUMVARS
        IF(NB(N).EQ.2)THEN
          LB(N)=MIN(LB(N),0.0)
          UB(N)=MAX(UB(N),0.0)
        ENDIF
      ENDDO
    ENDIF

  ENDIF 

! BOUND
! FOR 3D RADAR
  IF(W_CMPNNT.NE.0)THEN
    DO N=1,MAXDIMS
      NG(N)=NUMGRID(N)
    ENDDO
    NG(MAXDIMS+1)=NUMSTAT
    S=W_CMPNNT
    K=1
    DO T=1,NUMGRID(4)
    DO J=1,NUMGRID(2)
    DO I=1,NUMGRID(1)
      NN(1)=I
      NN(2)=J
      NN(3)=K
      NN(4)=T
      NN(MAXDIMS+1)=S
      CALL PSTN2NUMB(MAXDIMS+1,NN,NG,NC)
      NB(NC)=2
      LB(NC)=0.0
      UB(NC)=0.0
    ENDDO
    ENDDO
    ENDDO
  ENDIF
! FOR 3D RADAR
  DO N=1,3*NUMVARS
    IW(N)=0
  ENDDO

  WA=0.0
  TA='START'
  I0=0
  IC=0
  WRITE(*,9001)

  IF(W_CMPNNT.NE.0) THEN         ! BY ZHONGJIE HE
    CALL COSTFUNCT1
    CALL COSTGRADT1
  ELSE                           ! BY ZHONGJIE HE
    CALL WCOMPGERNL
    
    CALL COSTFUNCT2
    CALL COSTGRADT2
  ENDIF
print*,'minvalue of bk: ',minval(grdbkgnd(1:numgrid(1),1:numgrid(2),1:numgrid(3),1:numgrid(4),5))

  ! COUNT NUMBER OF ITERATIONS:
  IT = 0
  ITERLOOP: DO WHILE (.TRUE.)

    ! ADD LOW BOUND FOR SPECIFIC HUMIDITY:
    NG(1:4) = NUMGRID(1:4)
    NG(5) = NUMSTAT  ! THE NUMBER OF STATES IN THE 5TH DIMENSION
    DO T=1,NUMGRID(4)
      DO K=1,NUMGRID(3)
        DO J=1,NUMGRID(2)
          DO I=1,NUMGRID(1)
            NN(1)=I
            NN(2)=J
            NN(3)=K
            NN(4)=T
            NN(5)=5  ! POSITION OF SPECIFIC HUMIDITY
           
            CALL PSTN2NUMB(5,NN,NG,NC)

            NB(NC) = 0
            IF ((MAXGRID(1)-1)/2+1 .LE. NUMGRID(1)) NB(NC) = 1
            
            ! LOW BOUND FROM REFLECTIVITY DID NOT GET SCALED AND SO HERE IT DOES:
            LB(NC) = -GRDBKGND(I,J,K,T,5)+GRDBKGND(I,J,K,T,NUMSTAT+1)
            UB(NC) = -GRDBKGND(I,J,K,T,5)+GRDBKGND(I,J,K,T,NUMSTAT+2)
          ENDDO
        ENDDO
      ENDDO
    ENDDO
    ! ADD LOWER BOUNDS FOR RAIN AND SNOW:
    IF (NUMSTAT .GT. 5) THEN ! RAIN AND SNOW ARE 6TH AND 7TH:
    DO T=1,NUMGRID(4)
      DO K=1,NUMGRID(3)
        DO J=1,NUMGRID(2)
          DO I=1,NUMGRID(1)
            NN(1)=I
            NN(2)=J
            NN(3)=K
            NN(4)=T
            NN(5)=6  ! POSITION OF RAIN
           
            CALL PSTN2NUMB(5,NN,NG,NC)

            NB(NC) = 1
            LB(NC) = -GRDBKGND(I,J,K,T,6)

            NN(5)=7  ! POSITION OF SNOW
           
            CALL PSTN2NUMB(5,NN,NG,NC)

            NB(NC) = 1
            LB(NC) = -GRDBKGND(I,J,K,T,7)
          ENDDO
        ENDDO
      ENDDO
    ENDDO
    ENDIF
 
    ! CALL SETULB(NUMVARS,MM,GRDANALS,LB,UB,NB,COSTFUN,GRADINT,FA,PG,WA,IW, &
    !            TA,IP,CS,LS,IS,DS,IT)

    ! LBFGS: SINGLE PRECISION
    CALL LBFGSB(NUMVARS,MM,GRDANALS,LB,UB,NB,COSTFUN,GRADINT,FA,WA,IW,TA,IP,ISBMN,CS,LS,IS,DS)
    
!    IF(GRDLEVL.EQ.2.AND.IT.EQ.1)CALL CHECK_F_G

    IF(TA(1:2).EQ.'FG')THEN
      IF(W_CMPNNT.NE.0) THEN         ! BY ZHONGJIE HE
        CALL COSTFUNCT1
        CALL COSTGRADT1
      ELSE                           ! BY ZHONGJIE HE
        CALL WCOMPGERNL
        CALL COSTFUNCT2
        CALL COSTGRADT2
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!for test
       temp=0
      temp0=0
!      T=2
!     DO K=1,NUMGRID(3)
!        DO J=10,NUMGRID(2)
!        DO I=20,NUMGRID(1)
    !      I=33
    !      J=31
   !       K=7
!         GRDANALS(I,J,K,T,ROUR_CMPNNT)=GRDANALS(I,J,K,T,ROUR_CMPNNT)+0.01
!         CALL COSTFUNCT2
!          temp1=COSTFUN
!          GRDANALS(I,J,K,T,ROUR_CMPNNT)=GRDANALS(I,J,K,T,ROUR_CMPNNT)-2.0*0.01
!         CALL COSTFUNCT2
!         temp2=COSTFUN 
               
!          dif1=(temp1-temp2)/(2.0*0.01)
!          dif2=ABS(dif1-GRADINT(I,J,K,T,ROUR_CMPNNT))

 !         print*,'    GRADINT(I,J,K,T,ROUR_CMPNNT )=   ',GRADINT(I,J,K,2,ROUR_CMPNNT)
 !          print*,'    costfun1=    ', temp1
 !          print*,'    costfun2=    ', temp2
 !          print*,'    dif1=    ', dif1       
 !          print*,'    dif2=    ', dif2
 !         if(dif2>temp)then
 !          temp=dif2
 !          temp0=dif1
 !          locx=I
 !          locy=J
 !          locz=K
 !          loct=T 
 !          if(dif2>0.01)then 
 !             print*,'    GRADINT(I,J,K,T,ROUR_CMPNNT )=   ',GRADINT(locx,locy,locz,2,ROUR_CMPNNT)
 !              print*,'    dif1=    ', temp0       
 !             print*,'    dif2=    ', temp
 !             print*,'    x=    ', locx
 !             print*,'    y=    ', locy
 !             print*,'    z=    ', locz       
 !             print*,'    t=    ', loct 
 !             stop
 !          endif        
 !          endif
 !       ENDDO
 !     ENDDO
 !    ENDDO  
    ! print*,'    GRADINT(I,J,K,T,ROUR_CMPNNT )=   ',GRADINT(locx,locy,locz,2,ROUR_CMPNNT)
   !  print*,'    dif1=    ', temp0       
  !   print*,'    dif2=    ', temp
 !     print*,'    x=    ', locx
  !    print*,'    y=    ', locy
   !   print*,'    z=    ', locz       
  !    print*,'    t=    ', loct 
  !    stop
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!     
       
      ENDIF
      IC=IC+1
      CYCLE ITERLOOP
    ELSEIF(TA(1:5).EQ.'NEW_X')THEN
      IF(I0.EQ.0)THEN
        WRITE(*,1003)IS(30),IS(34),DS(13),COSTFUN
      ELSE
        WRITE(*,3001)IS(30),IS(34),DS(14),DS(13),COSTFUN
      ENDIF
      I0=I0+1
      IT = IT+1

      ! Exceeds maximum iterations:
      IF(GRDLEVL.LE.MIDGRID.AND.IT.GT.COSSTEP) EXIT ITERLOOP
      IF(GRDLEVL.GT.MIDGRID.AND.IT.GT.FINSTEP) EXIT ITERLOOP

      CYCLE ITERLOOP
    ELSE
      IF(IP.LE.-1.AND.TA(1:4).NE.'STOP')WRITE(6,*)TA
      EXIT ITERLOOP
    ENDIF
  END DO ITERLOOP
  1003 FORMAT (2(1x,i4),5x,'-',3x,1p,2(1x,d10.3))
  9001 FORMAT (/,3x,'it',3x,'nf',2x,'stepl',5x,'projg',8x,'f')
  3001 FORMAT (2(1x,i4),1p,2x,d7.1,1p,2(1x,d10.3))

  IF(W_CMPNNT.NE.0) THEN         ! BY ZHONGJIE HE
    CALL COSTFUNCT1
!    CALL COSTGRADT1
  ELSE                           ! BY ZHONGJIE HE
    CALL WCOMPGERNL
    CALL COSTFUNCT2
    
    
!    CALL COSTGRADT2
  ENDIF

  ! DEALLOCATE WORKING ARRAY:
  DEALLOCATE(WA,STAT=ER)
  IF (ER .NE. 0) THEN
    PRINT*,'MINIMIZER: Cannot deallocate enough memory for the working array'
    STOP
  ENDIF

  WRITE(8,*)'BOTTOM FUNCTION =',COSTFUN
  RETURN
END SUBROUTINE MINIMIZER_XIE

SUBROUTINE COAS2FINE_XIE
!*************************************************
! INTERPOLATION FROM COARSE GRID TO FINE GRID
! HISTORY: AUGUST 2007, CODED by WEI LI.
!		MODIFIED BY YUANFU FROM WEI LI'S 
!		COAS2FINE,WHICH IS INCORRECTLY
!		INTERPOLATING COASE TO FINE GRID.
!
!	NOTE: THIS ROUTINE ASSUME FINE GRID HALVES
!		THE COASE RESOLUTION.
!*************************************************
  IMPLICIT NONE
! --------------------
  INTEGER  :: I,J,K,T,S,N,I0,J0,K0,T0,SM
  INTEGER  :: IC(MAXDIMS)
! --------------------
  DO N=1,MAXDIMS
    NTMPGRD(N)=NUMGRID(N)
  ENDDO
  CALL TMPMEMALC
  CALL GRDMEMRLS
  DO N=1,MAXDIMS
    IC(N)=1
    IF(NTMPGRD(N).LT.MAXGRID(N)) THEN
!      IF(N.NE.3 .OR. GRDLEVL.GT.3) THEN         ! ADDED BY ZHONGJIE HE
        IC(N)=2
        NUMGRID(N)=2*NUMGRID(N)-1
!      ENDIF
    ENDIF
  ENDDO

  ! PRESSURE COORDINATE LEVELS:
  I = (MAXGRID(PRESSURE)-1)/(NUMGRID(PRESSURE)-1)
  DO K=1,NUMGRID(PRESSURE)
    PPM(K) = PP0((K-1)*I+1)
  ENDDO

  CALL GRDMEMALC
! GET THE GRID SPACING INFORMATION FOR NEW GRD ARRAY
  DO N=1,NUMDIMS
    IF(IC(N).EQ.2)GRDSPAC(N)=GRDSPAC(N)/2.0
  ENDDO

! NOTE FINE GRID DOUBLES RESOLUTION FROM COASE GRID:

! 1. PROJECT COASE GRID ONTO FINE GRID:
  DO T=1,NUMGRID(4),IC(4)
    T0 = (T-1)/IC(4)+1
  DO K=1,NUMGRID(3),IC(3)
    K0 = (K-1)/IC(3)+1
  DO J=1,NUMGRID(2),IC(2)
    J0 = (J-1)/IC(2)+1
  DO I=1,NUMGRID(1),IC(1)
    I0 = (I-1)/IC(1)+1

    GRDANALS(I,J,K,T,1:NUMSTAT) = TMPANALS(I0,J0,K0,T0,1:NUMSTAT)
  ENDDO
  ENDDO
  ENDDO
  ENDDO

  ! RELEASE TEMPORARY MEMORY:
  CALL TMPMEMRLS

! 2. X DIRECTION:
  IF (IC(1) .EQ. 2) THEN
    DO T=1,NUMGRID(4),IC(4)
    DO K=1,NUMGRID(3),IC(3)
    DO J=1,NUMGRID(2),IC(2)
    DO I=2,NUMGRID(1),IC(1)

      GRDANALS(I,J,K,T,1:NUMSTAT) = 0.5*(GRDANALS(I-1,J,K,T,1:NUMSTAT) &
                                        +GRDANALS(I+1,J,K,T,1:NUMSTAT))
    ENDDO
    ENDDO
    ENDDO
    ENDDO
  ENDIF

! 3. Y DIRECTION:
  IF (IC(2) .EQ. 2) THEN
    DO T=1,NUMGRID(4),IC(4)
    DO K=1,NUMGRID(3),IC(3)
    DO J=2,NUMGRID(2),IC(2)
    DO I=1,NUMGRID(1)

      GRDANALS(I,J,K,T,1:NUMSTAT) = 0.5*(GRDANALS(I,J-1,K,T,1:NUMSTAT) &
                                        +GRDANALS(I,J+1,K,T,1:NUMSTAT))
    ENDDO
    ENDDO
    ENDDO
    ENDDO
  ENDIF

! 4. Z DIRECTION:
  IF (IC(3) .EQ. 2) THEN
    DO T=1,NUMGRID(4),IC(4)
    DO K=2,NUMGRID(3),IC(3)
    DO J=1,NUMGRID(2)
    DO I=1,NUMGRID(1)

      GRDANALS(I,J,K,T,1:NUMSTAT) = 0.5*(GRDANALS(I,J,K-1,T,1:NUMSTAT) &
                                        +GRDANALS(I,J,K+1,T,1:NUMSTAT))
    ENDDO
    ENDDO
    ENDDO
    ENDDO
  ENDIF

! 5. T DIRECTION:
  IF (IC(4) .EQ. 2) THEN
    DO T=2,NUMGRID(4),IC(4)
    DO K=1,NUMGRID(3)
    DO J=1,NUMGRID(2)
    DO I=1,NUMGRID(1)

      GRDANALS(I,J,K,T,1:NUMSTAT) = 0.5*(GRDANALS(I,J,K,T-1,1:NUMSTAT) &
                                        +GRDANALS(I,J,K,T+1,1:NUMSTAT))
    ENDDO
    ENDDO
    ENDDO
    ENDDO
  ENDIF

  ! MAKE SURE INTERPOLATED SH ANALYSIS POSITIVE:
  DO T=1,NUMGRID(4)
  DO K=1,NUMGRID(3)
  DO J=1,NUMGRID(2)
  DO I=1,NUMGRID(1)
    GRDANALS(I,J,K,T,HUMIDITY) = &
      MAX(-GRDBKGND(I,J,K,T,HUMIDITY),GRDANALS(I,J,K,T,HUMIDITY))
  ENDDO
  ENDDO
  ENDDO
  ENDDO

  RETURN
END SUBROUTINE COAS2FINE_XIE

SUBROUTINE COAS2FINE
!*************************************************
! INTERPOLATION FROM COARSE GRID TO FINE GRID
! HISTORY: AUGUST 2007, CODED by WEI LI.
!*************************************************
  IMPLICIT NONE
! --------------------
  INTEGER  :: I,J,K,T,S,N,I0,J0,K0,T0,SM
  INTEGER  :: IC(MAXDIMS)
! --------------------
  DO N=1,MAXDIMS
    NTMPGRD(N)=NUMGRID(N)
  ENDDO
  CALL TMPMEMALC
  CALL GRDMEMRLS
  DO N=1,MAXDIMS
    IC(N)=1
    IF(NTMPGRD(N).LT.MAXGRID(N)) THEN
!      IF(N.NE.3 .OR. GRDLEVL.GT.3) THEN         ! ADDED BY ZHONGJIE HE
        IC(N)=2
        NUMGRID(N)=2*NUMGRID(N)-1
!      ENDIF
    ENDIF
  ENDDO
  CALL GRDMEMALC
! GET THE GRID SPACING INFORMATION FOR NEW GRD ARRAY
  DO N=1,NUMDIMS
    IF(IC(N).EQ.2)GRDSPAC(N)=GRDSPAC(N)/2.0
  ENDDO
! GET THE INFORMATION FOR NEW GRID ARRAY BY INTERPOLATION
!======================== MODIFIED BY ZHONGJIE HE
  DO T=1,NUMGRID(4),IC(4)
  DO K=1,NUMGRID(3),IC(3)
  DO J=1,NUMGRID(2),IC(2)
  DO I=1,NUMGRID(1),IC(1)
    I0=0.5*(I+1)
    J0=0.5*(J+1)
    K0=0.5*(K+1)
    T0=0.5*(T+1)
    IF(IC(1).EQ.1)I0=I
    IF(IC(2).EQ.1)J0=J
    IF(IC(3).EQ.1)K0=K
    IF(IC(4).EQ.1)T0=T

    DO S=1,NUMSTAT
      SM=0
      IF(IC(1).EQ.2) THEN
        IF(I0.EQ.1) THEN
          GRDANALS(I,J,K,T,S)=GRDANALS(I,J,K,T,S)+TMPANALS(I0+1,J0,K0,T0,S)
          SM=SM+1
        ELSEIF(I0.EQ.NTMPGRD(1)) THEN
          GRDANALS(I,J,K,T,S)=GRDANALS(I,J,K,T,S)+TMPANALS(I0-1,J0,K0,T0,S)
          SM=SM+1
        ELSE
          GRDANALS(I,J,K,T,S)=GRDANALS(I,J,K,T,S)+TMPANALS(I0-1,J0,K0,T0,S)+TMPANALS(I0+1,J0,K0,T0,S)
          SM=SM+2
        ENDIF
      ENDIF
      IF(IC(2).EQ.2) THEN
        IF(J0.EQ.1) THEN
          GRDANALS(I,J,K,T,S)=GRDANALS(I,J,K,T,S)+TMPANALS(I0,J0+1,K0,T0,S)
          SM=SM+1
        ELSEIF(J0.EQ.NTMPGRD(2)) THEN
          GRDANALS(I,J,K,T,S)=GRDANALS(I,J,K,T,S)+TMPANALS(I0,J0-1,K0,T0,S)
          SM=SM+1
        ELSE
          GRDANALS(I,J,K,T,S)=GRDANALS(I,J,K,T,S)+TMPANALS(I0,J0-1,K0,T0,S)+TMPANALS(I0,J0+1,K0,T0,S)
          SM=SM+2
        ENDIF
      ENDIF
      IF(IC(3).EQ.2) THEN
        IF(K0.EQ.1) THEN
          GRDANALS(I,J,K,T,S)=GRDANALS(I,J,K,T,S)+TMPANALS(I0,J0,K0+1,T0,S)
          SM=SM+1
        ELSEIF(K0.EQ.NTMPGRD(3)) THEN
          GRDANALS(I,J,K,T,S)=GRDANALS(I,J,K,T,S)+TMPANALS(I0,J0,K0-1,T0,S)
          SM=SM+1
        ELSE
          GRDANALS(I,J,K,T,S)=GRDANALS(I,J,K,T,S)+TMPANALS(I0,J0,K0-1,T0,S)+TMPANALS(I0,J0,K0+1,T0,S)
          SM=SM+2
        ENDIF
      ENDIF
      IF(IC(4).EQ.2) THEN
        IF(T0.EQ.1) THEN
          GRDANALS(I,J,K,T,S)=GRDANALS(I,J,K,T,S)+TMPANALS(I0,J0,K0,T0+1,S)
          SM=SM+1
        ELSEIF(T0.EQ.NTMPGRD(4)) THEN
          GRDANALS(I,J,K,T,S)=GRDANALS(I,J,K,T,S)+TMPANALS(I0,J0,K0,T0-1,S)
          SM=SM+1
        ELSE
          GRDANALS(I,J,K,T,S)=GRDANALS(I,J,K,T,S)+TMPANALS(I0,J0,K0,T0-1,S)+TMPANALS(I0,J0,K0,T0+1,S)
          SM=SM+2
        ENDIF
      ENDIF

      IF(SM.GE.1) THEN
        GRDANALS(I,J,K,T,S)=GRDANALS(I,J,K,T,S)/FLOAT(SM)
      ELSE
        GRDANALS(I,J,K,T,S)=TMPANALS(I0,J0,K0,T0,S)
      ENDIF
    ENDDO
  ENDDO
  ENDDO
  ENDDO
  ENDDO
!========================================================== END OF MODIFICATION BY ZHONGJIE HE
! X DIRECTION
  IF(IC(1).EQ.2)THEN
    DO T=1,NUMGRID(4)  ,IC(4)
    DO K=1,NUMGRID(3)  ,IC(3)
    DO J=1,NUMGRID(2)  ,IC(2)
    DO I=2,NUMGRID(1)-1,IC(1)
      DO S=1,NUMSTAT
        GRDANALS(I,J,K,T,S)=0.5*(GRDANALS(I-1,J,K,T,S)+GRDANALS(I+1,J,K,T,S))
      ENDDO
    ENDDO
    ENDDO
    ENDDO
    ENDDO
  ENDIF
! Y DIRECTION
  IF(IC(2).EQ.2)THEN
    DO T=1,NUMGRID(4)  ,IC(4)
    DO K=1,NUMGRID(3)  ,IC(3)
    DO J=2,NUMGRID(2)-1,IC(2)
    DO I=1,NUMGRID(1)
      DO S=1,NUMSTAT
        GRDANALS(I,J,K,T,S)=0.5*(GRDANALS(I,J-1,K,T,S)+GRDANALS(I,J+1,K,T,S))
      ENDDO
    ENDDO
    ENDDO
    ENDDO
    ENDDO
  ENDIF
! Z DIRECTION
  IF(IC(3).EQ.2)THEN
    DO T=1,NUMGRID(4)  ,IC(4)
    DO K=2,NUMGRID(3)-1,IC(3)
    DO J=1,NUMGRID(2)
    DO I=1,NUMGRID(1)
      DO S=1,NUMSTAT
        GRDANALS(I,J,K,T,S)=0.5*(GRDANALS(I,J,K-1,T,S)+GRDANALS(I,J,K+1,T,S))
      ENDDO
    ENDDO
    ENDDO
    ENDDO
    ENDDO
  ENDIF
! T DIRECTION
  IF(IC(4).EQ.2)THEN
    DO T=2,NUMGRID(4)-1,IC(4)
    DO K=1,NUMGRID(3)
    DO J=1,NUMGRID(2)
    DO I=1,NUMGRID(1)
      DO S=1,NUMSTAT
        GRDANALS(I,J,K,T,S)=0.5*(GRDANALS(I,J,K,T-1,S)+GRDANALS(I,J,K,T+1,S))
      ENDDO
    ENDDO
    ENDDO
    ENDDO
    ENDDO
  ENDIF
  CALL TMPMEMRLS
  RETURN
END SUBROUTINE COAS2FINE

SUBROUTINE FINE2COAS_XIE
!*************************************************
! INTERPOLATION FROM COARSE GRID TO FINE GRID
! HISTORY: AUGUST 2007, CODED by WEI LI.
!		MODIFIED BY YUANFU FROM WEI LI'S 
!		COAS2FINE,WHICH IS INCORRECTLY
!		INTERPOLATING COASE TO FINE GRID.
!		THUS YUANFU REWRITES THE FINE2COAS.
!
!	NOTE: THIS ROUTINE ASSUME FINE GRID HALVES
!		THE COASE RESOLUTION.
!*************************************************
  IMPLICIT NONE
! --------------------
  INTEGER  :: I,J,K,T,S,N,I0,J0,K0,T0,SM
  INTEGER  :: IC(MAXDIMS)
! --------------------
  DO N=1,MAXDIMS
    NTMPGRD(N)=NUMGRID(N)
  ENDDO
  CALL TMPMEMALC		! TEMPORARY MEMORY AND COPY GRDANALS TO HERE
  CALL GRDMEMRLS
  DO N=1,MAXDIMS
    IC(N)=1
    IF(NTMPGRD(N).GT.INIGRID(N)) THEN
        IC(N)=2
        NUMGRID(N)=(NUMGRID(N)-1)/2+1			! ASSUME NUMGRID ODD NUMBER
    ENDIF
  ENDDO
  CALL GRDMEMALC
! GET THE GRID SPACING INFORMATION FOR NEW GRD ARRAY
  DO N=1,NUMDIMS
    IF(IC(N) .EQ. 2) GRDSPAC(N)=GRDSPAC(N)*2.0
  ENDDO

! NOTE FINE GRID DOUBLES RESOLUTION FROM COASE GRID:

! 1. PROJECT COASE GRID ONTO FINE GRID:
  DO T=1,NUMGRID(4)
    T0 = (T-1)*IC(4)+1
  DO K=1,NUMGRID(3)
    K0 = (K-1)*IC(3)+1
  DO J=1,NUMGRID(2)
    J0 = (J-1)*IC(2)+1
  DO I=1,NUMGRID(1)
    I0 = (I-1)*IC(1)+1

    GRDANALS(I,J,K,T,1:NUMSTAT) = TMPANALS(I0,J0,K0,T0,1:NUMSTAT)
  ENDDO
  ENDDO
  ENDDO
  ENDDO

  ! RELEASE TEMPORARY MEMORY:
  CALL TMPMEMRLS

  RETURN
END SUBROUTINE FINE2COAS_XIE

SUBROUTINE FINE2COAS
!*************************************************
! PROJECTION FROM FINE GRID TO COARSE GRID (NOT USED)
! HISTORY: AUGUST 2007, CODED by WEI LI.
!*************************************************
  IMPLICIT NONE
! --------------------
  INTEGER  :: I,J,K,T,S,N,M,I0,J0,K0,T0,SM
  INTEGER  :: IC(MAXDIMS)
! --------------------
  DO N=1,MAXDIMS
    NTMPGRD(N)=NUMGRID(N)
  ENDDO
  CALL TMPMEMALC
  DO N=1,MAXDIMS
    IC(N)=1
    IF(NTMPGRD(N).GT.INIGRID(N))IC(N)=2
  ENDDO

!======================== MODIFIED BY ZHONGJIE HE
  DO T=1,NTMPGRD(4)
  DO K=1,NTMPGRD(3)
  DO J=1,NTMPGRD(2)
  DO I=1,NTMPGRD(1)
    DO S=1,NUMSTAT
      SM=0
      TMPANALS(I,J,K,T,S)=0
      IF(IC(1).EQ.2) THEN
        IF(I.EQ.1) THEN
          TMPANALS(I,J,K,T,S)=TMPANALS(I,J,K,T,S)+GRDANALS(I+1,J,K,T,S)
          SM=SM+1
        ELSEIF(I.EQ.NTMPGRD(1)) THEN
          TMPANALS(I,J,K,T,S)=TMPANALS(I,J,K,T,S)+GRDANALS(I-1,J,K,T,S)
          SM=SM+1
        ELSE
          TMPANALS(I,J,K,T,S)=TMPANALS(I,J,K,T,S)+GRDANALS(I-1,J,K,T,S)+GRDANALS(I+1,J,K,T,S)
          SM=SM+2
        ENDIF
      ENDIF
      IF(IC(2).EQ.2) THEN
        IF(J.EQ.1) THEN
          TMPANALS(I,J,K,T,S)=TMPANALS(I,J,K,T,S)+GRDANALS(I,J+1,K,T,S)
          SM=SM+1
        ELSEIF(J.EQ.NTMPGRD(2)) THEN
          TMPANALS(I,J,K,T,S)=TMPANALS(I,J,K,T,S)+GRDANALS(I,J-1,K,T,S)
          SM=SM+1
        ELSE
          TMPANALS(I,J,K,T,S)=TMPANALS(I,J,K,T,S)+GRDANALS(I,J-1,K,T,S)+GRDANALS(I,J+1,K,T,S)
          SM=SM+2
        ENDIF
      ENDIF
      IF(IC(3).EQ.2) THEN
        IF(K.EQ.1) THEN
          TMPANALS(I,J,K,T,S)=TMPANALS(I,J,K,T,S)+GRDANALS(I,J,K+1,T,S)
          SM=SM+1
        ELSEIF(K.EQ.NTMPGRD(3)) THEN
          TMPANALS(I,J,K,T,S)=TMPANALS(I,J,K,T,S)+GRDANALS(I,J,K-1,T,S)
          SM=SM+1
        ELSE
          TMPANALS(I,J,K,T,S)=TMPANALS(I,J,K,T,S)+GRDANALS(I,J,K-1,T,S)+GRDANALS(I,J,K+1,T,S)
          SM=SM+2
        ENDIF
      ENDIF
      IF(IC(4).EQ.2) THEN
        IF(T.EQ.1) THEN
          TMPANALS(I,J,K,T,S)=TMPANALS(I,J,K,T,S)+GRDANALS(I,J,K,T+1,S)
          SM=SM+1
        ELSEIF(T.EQ.NTMPGRD(4)) THEN
          TMPANALS(I,J,K,T,S)=TMPANALS(I,J,K,T,S)+GRDANALS(I,J,K,T-1,S)
          SM=SM+1
        ELSE
          TMPANALS(I,J,K,T,S)=TMPANALS(I,J,K,T,S)+GRDANALS(I,J,K,T-1,S)+GRDANALS(I,J,K,T+1,S)
          SM=SM+2
        ENDIF
      ENDIF

      IF(SM.GE.1) THEN
        TMPANALS(I,J,K,T,S)=TMPANALS(I,J,K,T,S)/FLOAT(SM)
      ELSE
        TMPANALS(I,J,K,T,S)=GRDANALS(I,J,K,T,S)
      ENDIF
    ENDDO
  ENDDO
  ENDDO
  ENDDO
  ENDDO
!========================================================== END OF MODIFICATION BY ZHONGJIE HE

  CALL GRDMEMRLS
  DO N=1,MAXDIMS
    IF(IC(N).EQ.2)NUMGRID(N)=0.5*(NUMGRID(N)+1)
  ENDDO
  CALL GRDMEMALC
  DO N=1,NUMDIMS
    IF(IC(N).EQ.2)GRDSPAC(N)=GRDSPAC(N)*2.0
  ENDDO
! ----
  IF(.FALSE.)THEN
! ----
  DO T=1,NTMPGRD(4),IC(4)
  DO K=1,NTMPGRD(3),IC(3)
  DO J=1,NTMPGRD(2),IC(2)
  DO I=1,NTMPGRD(1),IC(1)
    DO S=1,NUMSTAT
      GRDANALS(I,J,K,T,S)=0.0
      M=0
      DO T0=MAX0(T-1,1),MIN0(T+1,NTMPGRD(4))
      DO K0=MAX0(K-1,1),MIN0(K+1,NTMPGRD(3))
      DO J0=MAX0(J-1,1),MIN0(J+1,NTMPGRD(2))
      DO I0=MAX0(I-1,1),MIN0(I+1,NTMPGRD(1))
        IF(I0.EQ.I.AND.J0.EQ.J.AND.K0.EQ.K.AND.T0.EQ.T)CYCLE
        M=M+1
        GRDANALS(I,J,K,T,S)=GRDANALS(I,J,K,T,S)+TMPANALS(I0,J0,K0,T0,S)
      ENDDO
      ENDDO
      ENDDO
      ENDDO
      IF(M.GT.0)GRDANALS(I,J,K,T,S)=GRDANALS(I,J,K,T,S)/M
    ENDDO
  ENDDO
  ENDDO
  ENDDO
  ENDDO
! ----
  ELSE
! ----
  DO T=1,NTMPGRD(4),IC(4)
  DO K=1,NTMPGRD(3),IC(3)
  DO J=1,NTMPGRD(2),IC(2)
  DO I=1,NTMPGRD(1),IC(1)
    I0=0.5*(I+1)
    J0=0.5*(J+1)
    K0=0.5*(K+1)
    T0=0.5*(T+1)
    IF(IC(1).EQ.1)I0=I
    IF(IC(2).EQ.1)J0=J
    IF(IC(3).EQ.1)K0=K
    IF(IC(4).EQ.1)T0=T
    DO S=1,NUMSTAT
      GRDANALS(I0,J0,K0,T0,S)=TMPANALS(I,J,K,T,S)
    ENDDO
  ENDDO
  ENDDO
  ENDDO
  ENDDO
! ----
  ENDIF
! ----
  CALL TMPMEMRLS
  RETURN
END SUBROUTINE FINE2COAS


SUBROUTINE CHECK_F_G
!*************************************************
! CHECK WHETHER THE GRADIENT MATCH COST FUNCTION (AFFILIATE)
! HISTORY: AUGUST 2007, CODED by WEI LI.
!*************************************************
  IMPLICIT NONE
! --------------------
  INTEGER  :: I,J,K,T,S
  REAL     :: CONTROL(NUMGRID(1),NUMGRID(2),NUMGRID(3),NUMGRID(4),NUMSTAT)
  REAL     :: ED,F2,F1,GG
! --------------------
  ED=0.00001
  DO S=1,NUMSTAT
  DO T=1,NUMGRID(4)
  DO K=1,NUMGRID(3)
  DO J=1,NUMGRID(2)
  DO I=1,NUMGRID(1)
    CONTROL(I,J,K,T,S)=GRDANALS(I,J,K,T,S)
  ENDDO
  ENDDO
  ENDDO
  ENDDO
  ENDDO
  CALL WCOMPGERNL
  CALL COSTGRADT2
  DO S=1,NUMSTAT
  DO T=1,NUMGRID(4)
  DO K=1,NUMGRID(3)
  DO J=1,NUMGRID(2)
  DO I=1,NUMGRID(1)
    PRINT*,'       '
    PRINT*,'       '
    PRINT*,'       '
    PRINT*,'       '
    PRINT*,'       '
    GRDANALS(I,J,K,T,S)=CONTROL(I,J,K,T,S)+ED
    CALL COSTFUNCT2
    F2=COSTFUN
    GRDANALS(I,J,K,T,S)=CONTROL(I,J,K,T,S)-ED
    CALL COSTFUNCT2
    F1=COSTFUN
    GRDANALS(I,J,K,T,S)=CONTROL(I,J,K,T,S)
    GG=(F2-F1)/(2.0*ED)
!    PRINT*,F2,F1,GG
	IF(ABS(GRADINT(I,J,K,T,S)-GG).GT.1.0E-19) &
    PRINT*,I,J,K,T,S,GRADINT(I,J,K,T,S),GG,GRADINT(I,J,K,T,S)-GG
	IF(ABS(GRADINT(I,J,K,T,S)-GG).GT.1000.0)STOP
  ENDDO
  ENDDO
  ENDDO
  ENDDO
  ENDDO
  RETURN
END SUBROUTINE CHECK_F_G


SUBROUTINE GETW
  IMPLICIT NONE
! --------------------
  INTEGER  :: I,J,K,T
! --------------------
  CALL WCOMPGERNL      ! MODIFIED BY ZHONGJIE HE
  DO T=1,NUMGRID(4)
  DO K=1,NUMGRID(3)
  DO J=1,NUMGRID(2)
  DO I=1,NUMGRID(1)
    GRDANALS(I,J,K,T,3)=WWW(I,J,K,T) !*SCL(U_CMPNNT)
  ENDDO
  ENDDO
  ENDDO
  ENDDO
  RETURN
END SUBROUTINE GETW


END MODULE STMAS4D_CORE
