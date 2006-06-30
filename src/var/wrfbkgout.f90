!dis
!dis    Open Source License/Disclaimer, Forecast Systems Laboratory
!dis    NOAA/OAR/FSL, 325 Broadway Boulder, CO 80305
!dis
!dis    This software is distributed under the Open Source Definition,
!dis    which may be found at http://www.opensource.org/osd.html.
!dis
!dis    In particular, redistribution and use in source and binary forms,
!dis    with or without modification, are permitted provided that the
!dis    following conditions are met:
!dis
!dis    - Redistributions of source code must retain this notice, this
!dis    list of conditions and the following disclaimer.
!dis
!dis    - Redistributions in binary form must provide access to this
!dis    notice, this list of conditions and the following disclaimer, and
!dis    the underlying source code.
!dis
!dis    - All modifications to this software must be clearly documented,
!dis    and are solely the responsibility of the agent making the
!dis    modifications.
!dis
!dis    - If significant modifications or enhancements are made to this
!dis    software, the FSL Software Policy Manager
!dis    (softwaremgr@fsl.noaa.gov) should be notified.
!dis
!dis    THIS SOFTWARE AND ITS DOCUMENTATION ARE IN THE PUBLIC DOMAIN
!dis    AND ARE FURNISHED "AS IS."  THE AUTHORS, THE UNITED STATES
!dis    GOVERNMENT, ITS INSTRUMENTALITIES, OFFICERS, EMPLOYEES, AND
!dis    AGENTS MAKE NO WARRANTY, EXPRESS OR IMPLIED, AS TO THE USEFULNESS
!dis    OF THE SOFTWARE AND DOCUMENTATION FOR ANY PURPOSE.  THEY ASSUME
!dis    NO RESPONSIBILITY (1) FOR THE USE OF THE SOFTWARE AND
!dis    DOCUMENTATION; OR (2) TO PROVIDE TECHNICAL SUPPORT TO USERS.
!dis
!dis
!dis
!dis
!dis

SUBROUTINE wrfbkgout(times,imax,jmax,kmax,ptop,znu,znw,dxy, &
     		     mapfac,lat,lon,dam,pdam,t,sh,u,v)

!==========================================================
!  This routine writes the background fields into wrf_inout
!  in netcdf format to be used by GSI.
!
!  HISTORY: MAR. 2006 by YUANFU XIE.
!==========================================================

  IMPLICIT NONE

  INCLUDE 'netcdf.inc'

  CHARACTER*19, INTENT(IN) :: times
  INTEGER*4, INTENT(IN) :: imax,jmax,kmax  	! 3D array dimensions
  REAL*4, INTENT(IN) :: lat(imax,jmax)	! Latitude
  REAL*4, INTENT(IN) :: lon(imax,jmax)	! Longitude
  REAL*4, INTENT(IN) :: ptop		! Pressure top
  REAL*4, INTENT(IN) :: znu(kmax-1),znw(kmax)	! Staggered eta,Eta
  REAL*4, INTENT(IN) :: dxy			! grid spacing
  REAL*4, INTENT(IN) :: mapfac(imax,jmax)	! Map factor projection
  REAL*4, INTENT(IN) :: dam(imax,jmax)	! Dry air mass (column)
  REAL*4, INTENT(IN) :: pdam(imax,jmax)	! Perturbation
  REAL*4, INTENT(IN) :: t(imax,jmax,kmax)   ! temperature
  REAL*4, INTENT(IN) :: sh(imax,jmax,kmax)	! specific humidity
  REAL*4, INTENT(IN) :: u(imax,jmax,kmax)   ! U
  REAL*4, INTENT(IN) :: v(imax,jmax,kmax)   ! V


  ! Local variables:
  CHARACTER*10 :: empty
  INTEGER :: ncid				! file id
  INTEGER :: tmid,uid,vid,tid,muid,mubid	! var ids
  INTEGER :: qid,mapid,ptid,znuid,znwid	! var ids
  INTEGER :: latid,lonid,rxid,ryid		! var ids
  INTEGER :: phbid,lmkid,iceid,sstid,vgid	! var ids
  INTEGER :: slid,vfid,snwid,u10id,v10id	! var ids
  INTEGER :: smsid,tslbid,tskid		! var ids
  INTEGER :: start(4),count(4)		! netcdf start/count
  INTEGER :: k,ierr				! error flag
  INTEGER :: time,dlen,ndim(4),ndm1(4),btop,we,sn,nd(4),scal,nsol
  INTEGER :: itnc(imax-1,jmax-1,kmax-1)
  REAL :: unc(imax,jmax-1,kmax-1),tmp(imax,jmax,kmax)
  REAL :: vnc(imax-1,jmax,kmax-1),tnc(imax-1,jmax-1,kmax-1)
  REAL :: zmp(kmax),tmp1(imax*jmax*kmax)
  integer*4 :: ii,jj,kk
  real*4 :: pi,err,ftn,maxdata,stagu(imax,jmax-1,kmax-1),&
            stag_diffu(imax,jmax-1,kmax-1),ppp(imax,jmax-1,kmax-1)

  empty = ' '

  ! Create the netcdf file:
  ncid = nccre('wrf_inout.nc',ncnoclob,ierr)

  ! Global attributes:
  CALL ncaptc(ncid,ncglobal,'TITLE',ncchar,22, &
     	      'LAPS BACKGROUND INGEST',ierr)
  CALL ncaptc(ncid,ncglobal,'START_DATE',ncchar, &
	      len(times),times,ierr)
  CALL ncapt(ncid,ncglobal,'WEST-EAST_GRID_DIMENSION', &
     	     nclong,1,imax,ierr)
  CALL ncapt(ncid,ncglobal,'SOUTH-NORTH_GRID_DIMENSION', &
    	     nclong,1,jmax,ierr)
  CALL ncapt(ncid,ncglobal,'BOTTOM-TOP_GRID_DIMENSION', &
 	     nclong,1,kmax,ierr)
  CALL ncaptc(ncid,ncglobal,'GRIDTYPE',ncchar,1,'C',ierr)
  CALL ncapt(ncid,ncglobal,'WEST-EAST_PATCH_START_UNSTAG', &
 	     nclong,1,1,ierr)
  CALL ncapt(ncid,ncglobal,'WEST-EAST_PATCH_END_UNSTAG', &
 	     nclong,1,imax-1,ierr)
  CALL ncapt(ncid,ncglobal,'WEST-EAST_PATCH_START_STAG', &
 	     nclong,1,1,ierr)
  CALL ncapt(ncid,ncglobal,'WEST-EAST_PATCH_END_STAG', &
 	     nclong,1,imax,ierr)
  CALL ncapt(ncid,ncglobal,'SOUTH-NORTH_PATCH_START_UNSTAG', &
 	     nclong,1,1,ierr)
  CALL ncapt(ncid,ncglobal,'SOUTH-NORTH_PATCH_END_UNSTAG', &
 	     nclong,1,jmax-1,ierr)
  CALL ncapt(ncid,ncglobal,'SOUTH-NORTH_PATCH_START_STAG', &
 	     nclong,1,1,ierr)
  CALL ncapt(ncid,ncglobal,'SOUTH-NORTH_PATCH_END_STAG', &
 	     nclong,1,jmax,ierr)
  CALL ncapt(ncid,ncglobal,'BOTTOM-TOP_PATCH_START_UNSTAG', &
 	     nclong,1,1,ierr)
  CALL ncapt(ncid,ncglobal,'BOTTOM-TOP_PATCH_END_UNSTAG', &
 	     nclong,1,kmax-1,ierr)
  CALL ncapt(ncid,ncglobal,'BOTTOM-TOP_PATCH_START_STAG', &
 	     nclong,1,1,ierr)
  CALL ncapt(ncid,ncglobal,'BOTTOM-TOP_PATCH_END_STAG', &
 	     nclong,1,kmax,ierr)
  CALL ncapt(ncid,ncglobal,'DX',ncfloat,1,dxy,ierr)
  CALL ncapt(ncid,ncglobal,'DY',ncfloat,1,dxy,ierr)

  ! Create dimensions:
  time = ncddef(ncid,'Time',ncunlim,ierr)
  dlen = ncddef(ncid,'DateStrLen',19,ierr)
  ndim(1) = ncddef(ncid,'west_east_stag',imax,ierr)
  ndim(2) = ncddef(ncid,'south_north_stag',jmax,ierr)
  ndim(3) = ncddef(ncid,'bottom_top_stag',kmax,ierr)
  ndm1(1) = ncddef(ncid,'west_east',imax-1,ierr)
  ndm1(2) = ncddef(ncid,'south_north',jmax-1,ierr)
  ndm1(3) = ncddef(ncid,'bottom_top',kmax-1,ierr)
  nsol = ncddef(ncid,'soil_layers_stag',4,ierr)
  scal = ncddef(ncid,'ext_scalar',1,ierr)

  ! Create variables:
  ! Times:
  nd(1) = dlen
  nd(2) = time
  tmid = ncvdef(ncid,'Times',ncchar,2,nd,ierr)
  ! U:
  nd(1) = ndim(1)
  nd(2:3) = ndm1(2:3)
  nd(4) = time
  uid = ncvdef(ncid,'U',ncfloat,4,nd,ierr)
  CALL ncapt(ncid,uid,'FieldType',nclong,1,104,ierr)
  CALL ncaptc(ncid,uid,'MemoryOrder',ncchar,3,'XYZ',ierr)
  CALL ncaptc(ncid,uid,'description',ncchar,16, &
 	     'x-wind component',ierr)
  CALL ncaptc(ncid,uid,'units',ncchar,7,'m s{-1}',ierr)
  CALL ncaptc(ncid,uid,'stagger',ncchar,1,'X',ierr)
  ! V:
  nd(1) = ndm1(1)
  nd(2) = ndim(2)
  nd(3) = ndm1(3)
  nd(4) = time
  vid = ncvdef(ncid,'V',ncfloat,4,nd,ierr)
  CALL ncapt(ncid,vid,'FieldType',nclong,1,104,ierr)
  CALL ncaptc(ncid,vid,'MemoryOrder',ncchar,3,'XYZ',ierr)
  CALL ncaptc(ncid,vid,'description',ncchar,16, &
 	      'y-wind component',ierr)
  CALL ncaptc(ncid,vid,'units',ncchar,7,'m s{-1}',ierr)
  CALL ncaptc(ncid,vid,'stagger',ncchar,1,'Y',ierr)
  ! T:
  nd(1:3) = ndm1(1:3)
  nd(4) = time
  tid = ncvdef(ncid,'T',ncfloat,4,nd,ierr)
  CALL ncapt(ncid,tid,'FieldType',nclong,1,104,ierr)
  CALL ncaptc(ncid,tid,'MemoryOrder',ncchar,3,'XYZ',ierr)
  CALL ncaptc(ncid,tid,'description',ncchar,45, &
 	'perturbation potential temperature (theta-t0)',ierr)
  CALL ncaptc(ncid,tid,'units',ncchar,1,'K',ierr)
  CALL ncaptc(ncid,tid,'stagger',ncchar,0,empty,ierr)
  ! MU:
  nd(1:2) = ndm1(1:2)
  nd(3) = time
  muid = ncvdef(ncid,'MU',ncfloat,3,nd,ierr)
  CALL ncapt(ncid,muid,'FieldType',nclong,1,104,ierr)
  CALL ncaptc(ncid,muid,'MemoryOrder',ncchar,3,'XY ',ierr)
  CALL ncaptc(ncid,muid,'description',ncchar,35, &
 	      'perturbation dry air mass in column',ierr)
  CALL ncaptc(ncid,muid,'units',ncchar,7,'pascals',ierr)
  CALL ncaptc(ncid,muid,'stagger',ncchar,0,empty,ierr)
  ! MUB:
  nd(1:2) = ndm1(1:2)
  nd(3) = time
  mubid = ncvdef(ncid,'MUB',ncfloat,3,nd,ierr)
  CALL ncapt(ncid,mubid,'FieldType',nclong,1,104,ierr)
  CALL ncaptc(ncid,mubid,'MemoryOrder',ncchar,3,'XY ',ierr)
  CALL ncaptc(ncid,mubid,'description',ncchar,32, &
 	'base state dry air mass in column',ierr)
  CALL ncaptc(ncid,mubid,'units',ncchar,7,'pascals',ierr)
  CALL ncaptc(ncid,mubid,'stagger',ncchar,0,empty,ierr)
  ! QVAPOR:
  nd(1:3) = ndm1(1:3)
  nd(4) = time
  qid = ncvdef(ncid,'QVAPOR',ncfloat,4,nd,ierr)
  CALL ncapt(ncid,qid,'FieldType',nclong,1,104,ierr)
  CALL ncaptc(ncid,qid,'MemoryOrder',ncchar,3,'XYZ',ierr)
  CALL ncaptc(ncid,qid,'description',ncchar,1,'-',ierr)
  CALL ncaptc(ncid,qid,'units',ncchar,1,'-',ierr)
  CALL ncaptc(ncid,qid,'stagger',ncchar,0,empty,ierr)
  ! MAPFAC_M:
  nd(1:2) = ndm1(1:2)
  nd(3) = time
  mapid = ncvdef(ncid,'MAPFAC_M',ncfloat,3,nd,ierr)
  CALL ncapt(ncid,mapid,'FieldType',nclong,1,104,ierr)
  CALL ncaptc(ncid,mapid,'MemoryOrder',ncchar,3,'XY ',ierr)
  CALL ncaptc(ncid,mapid,'description',ncchar,29, &
 	      'Map scale factor on mass grid',ierr)
  CALL ncaptc(ncid,mapid,'units',ncchar,13,'dimensionless',ierr)
  CALL ncaptc(ncid,mapid,'stagger',ncchar,0,empty,ierr)
  ! P_TOP:
  nd(1) = scal
  nd(2) = time
  ptid = ncvdef(ncid,'P_TOP',ncfloat,2,nd,ierr)
  CALL ncapt(ncid,ptid,'FieldType',nclong,1,104,ierr)
  CALL ncaptc(ncid,ptid,'MemoryOrder',ncchar,3,'0  ',ierr)
  CALL ncaptc(ncid,ptid,'description',ncchar,0,empty,ierr)
  CALL ncaptc(ncid,ptid,'units',ncchar,1,'-',ierr)
  CALL ncaptc(ncid,ptid,'stagger',ncchar,0,empty,ierr)
  ! ZNU:
  nd(1) = ndm1(3)
  nd(2) = time
  znuid = ncvdef(ncid,'ZNU',ncfloat,2,nd,ierr)
  CALL ncapt(ncid,znuid,'FieldType',nclong,1,104,ierr)
  CALL ncaptc(ncid,znuid,'MemoryOrder',ncchar,3,'Z  ',ierr)
  CALL ncaptc(ncid,znuid,'description',ncchar,32, &
 	      'eta values on half (mass) levels',ierr)
  CALL ncaptc(ncid,znuid,'units',ncchar,13,'dimensionless',ierr)
  CALL ncaptc(ncid,znuid,'stagger',ncchar,0,empty,ierr)
  ! ZNW:
  nd(1) = ndim(3)
  nd(2) = time
  znwid = ncvdef(ncid,'ZNW',ncfloat,2,nd,ierr)
  CALL ncapt(ncid,znwid,'FieldType',nclong,1,104,ierr)
  CALL ncaptc(ncid,znwid,'MemoryOrder',ncchar,3,'Z  ',ierr)
  CALL ncaptc(ncid,znwid,'description',ncchar,29, &
 	      'eta values on full (w) levels',ierr)
  CALL ncaptc(ncid,znwid,'units',ncchar,13,'dimensionless',ierr)
  CALL ncaptc(ncid,znwid,'stagger',ncchar,1,'Z',ierr)
  ! XLAT:
  nd(1:2) = ndm1(1:2)
  nd(3) = time
  latid = ncvdef(ncid,'XLAT',ncfloat,3,nd,ierr)
  CALL ncapt(ncid,latid,'FieldType',nclong,1,104,ierr)
  CALL ncaptc(ncid,latid,'MemoryOrder',ncchar,3,'XY ',ierr)
  CALL ncaptc(ncid,latid,'description',ncchar,27, &
 	      'LATITUDE, SOUTH IS NEGATIVE',ierr)
  CALL ncaptc(ncid,latid,'units',ncchar,6,'degree',ierr)
  CALL ncaptc(ncid,latid,'stagger',ncchar,0,empty,ierr)
  ! XLONG:
  nd(1:2) = ndm1(1:2)
  nd(3) = time
  lonid = ncvdef(ncid,'XLONG',ncfloat,3,nd,ierr)
  CALL ncapt(ncid,lonid,'FieldType',nclong,1,104,ierr)
  CALL ncaptc(ncid,lonid,'MemoryOrder',ncchar,3,'XY ',ierr)
  CALL ncaptc(ncid,lonid,'description',ncchar,28, &
 	      'LONGITUDE, WEST IS NEGATIVE',ierr)
  CALL ncaptc(ncid,lonid,'units',ncchar,6,'degree',ierr)
  CALL ncaptc(ncid,lonid,'stagger',ncchar,0,empty,ierr)
  ! RDX:
  nd(1) = scal
  nd(2) = time
  rxid = ncvdef(ncid,'RDX',ncfloat,2,nd,ierr)
  CALL ncapt(ncid,rxid,'FieldType',nclong,1,104,ierr)
  CALL ncaptc(ncid,rxid,'MemoryOrder',ncchar,3,'0  ',ierr)
  CALL ncaptc(ncid,rxid,'description',ncchar,21, &
 	      'INVERSE X GRID LENGTH',ierr)
  CALL ncaptc(ncid,rxid,'units',ncchar,0,empty,ierr)
  CALL ncaptc(ncid,rxid,'stagger',ncchar,0,empty,ierr)
  ! RDY:
  nd(1) = scal
  nd(2) = time
  ryid = ncvdef(ncid,'RDY',ncfloat,2,nd,ierr)
  CALL ncapt(ncid,ryid,'FieldType',nclong,1,104,ierr)
  CALL ncaptc(ncid,ryid,'MemoryOrder',ncchar,3,'0  ',ierr)
  CALL ncaptc(ncid,ryid,'description',ncchar,21, &
 	      'INVERSE Y GRID LENGTH',ierr)
  CALL ncaptc(ncid,ryid,'units',ncchar,0,empty,ierr)
  CALL ncaptc(ncid,ryid,'stagger',ncchar,0,empty,ierr)

  ! Extra variables requested by GSI:
  ! PHB:
  nd(1:2) = ndm1(1:2)
  nd(3) = ndim(3)
  nd(4) = time
  phbid = ncvdef(ncid,'PHB',ncfloat,4,nd,ierr)
  CALL ncapt(ncid,phbid,'FieldType',nclong,1,104,ierr)
  CALL ncaptc(ncid,phbid,'MemoryOrder',ncchar,3,'XYZ',ierr)
  CALL ncaptc(ncid,phbid,'description',ncchar,23, &
 	      'base-state geopotential',ierr)
  CALL ncaptc(ncid,phbid,'units',ncchar,10,'m{2} s{-2}',ierr)
  CALL ncaptc(ncid,phbid,'stagger',ncchar,1,'Z',ierr)
  ! LANDMASK:
  nd(1:2) = ndm1(1:2)
  nd(3) = time
  lmkid = ncvdef(ncid,'LANDMASK',ncfloat,3,nd,ierr)
  CALL ncapt(ncid,lmkid,'FieldType',nclong,1,104,ierr)
  CALL ncaptc(ncid,lmkid,'MemoryOrder',ncchar,3,'XY ',ierr)
  CALL ncaptc(ncid,lmkid,'description',ncchar,9, &
 	      'LAND MASK',ierr)
  CALL ncaptc(ncid,lmkid,'units',ncchar,4,'flag',ierr)
  CALL ncaptc(ncid,lmkid,'stagger',ncchar,0,empty,ierr)
  ! XICE:
  nd(1:2) = ndm1(1:2)
  nd(3) = time
  iceid = ncvdef(ncid,'XICE',ncfloat,3,nd,ierr)
  CALL ncapt(ncid,iceid,'FieldType',nclong,1,104,ierr)
  CALL ncaptc(ncid,iceid,'MemoryOrder',ncchar,3,'XY ',ierr)
  CALL ncaptc(ncid,iceid,'description',ncchar,7, &
 	      'SEA ICE',ierr)
  CALL ncaptc(ncid,iceid,'units',ncchar,0,empty,ierr)
  CALL ncaptc(ncid,iceid,'stagger',ncchar,0,empty,ierr)
  ! SST:
  nd(1:2) = ndm1(1:2)
  nd(3) = time
  sstid = ncvdef(ncid,'SST',ncfloat,3,nd,ierr)
  CALL ncapt(ncid,sstid,'FieldType',nclong,1,104,ierr)
  CALL ncaptc(ncid,sstid,'MemoryOrder',ncchar,3,'XY ',ierr)
  CALL ncaptc(ncid,sstid,'description',ncchar,23, &
 	      'SEA SURFACE TEMPERATURE',ierr)
  CALL ncaptc(ncid,sstid,'units',ncchar,1,'K',ierr)
  CALL ncaptc(ncid,sstid,'stagger',ncchar,0,empty,ierr)
  ! IVGTYP:
  nd(1:2) = ndm1(1:2)
  nd(3) = time
  vgid = ncvdef(ncid,'IVGTYP',nclong,3,nd,ierr)
  CALL ncapt(ncid,vgid,'FieldType',nclong,1,106,ierr)
  CALL ncaptc(ncid,vgid,'MemoryOrder',ncchar,3,'XY ',ierr)
  CALL ncaptc(ncid,vgid,'description',ncchar,15, &
 	      'VEGETATION TYPE',ierr)
  CALL ncaptc(ncid,vgid,'units',ncchar,0,empty,ierr)
  CALL ncaptc(ncid,vgid,'stagger',ncchar,0,empty,ierr)
  ! ISLTYP:
  nd(1:2) = ndm1(1:2)
  nd(3) = time
  slid = ncvdef(ncid,'ISLTYP',nclong,3,nd,ierr)
  CALL ncapt(ncid,slid,'FieldType',nclong,1,106,ierr)
  CALL ncaptc(ncid,slid,'MemoryOrder',ncchar,3,'XY ',ierr)
  CALL ncaptc(ncid,slid,'description',ncchar,9, &
 	      'SOIL TYPE',ierr)
  CALL ncaptc(ncid,slid,'units',ncchar,0,empty,ierr)
  CALL ncaptc(ncid,slid,'stagger',ncchar,0,empty,ierr)
  ! VEGFRA:
  nd(1:2) = ndm1(1:2)
  nd(3) = time
  vfid = ncvdef(ncid,'VEGFRA',ncfloat,3,nd,ierr)
  CALL ncapt(ncid,vfid,'FieldType',nclong,1,104,ierr)
  CALL ncaptc(ncid,vfid,'MemoryOrder',ncchar,3,'XY ',ierr)
  CALL ncaptc(ncid,vfid,'description',ncchar,19, &
 	      'VEGETATION FRACTION',ierr)
  CALL ncaptc(ncid,vfid,'units',ncchar,0,empty,ierr)
  CALL ncaptc(ncid,vfid,'stagger',ncchar,0,empty,ierr)
  ! SNOW:
  nd(1:2) = ndm1(1:2)
  nd(3) = time
  snwid = ncvdef(ncid,'SNOW',ncfloat,3,nd,ierr)
  CALL ncapt(ncid,snwid,'FieldType',nclong,1,104,ierr)
  CALL ncaptc(ncid,snwid,'MemoryOrder',ncchar,3,'XY ',ierr)
  CALL ncaptc(ncid,snwid,'description',ncchar,21, &
 	      'SNOW WATER EQUIVALENT',ierr)
  CALL ncaptc(ncid,snwid,'units',ncchar,0,empty,ierr)
  CALL ncaptc(ncid,snwid,'stagger',ncchar,0,empty,ierr)
  ! U10:
  nd(1:2) = ndm1(1:2)
  nd(3) = time
  u10id = ncvdef(ncid,'U10',ncfloat,3,nd,ierr)
  CALL ncapt(ncid,u10id,'FieldType',nclong,1,104,ierr)
  CALL ncaptc(ncid,u10id,'MemoryOrder',ncchar,3,'XY ',ierr)
  CALL ncaptc(ncid,u10id,'description',ncchar,9, &
 	      'U at 10 M',ierr)
  CALL ncaptc(ncid,u10id,'units',ncchar,3,'m/s',ierr)
  CALL ncaptc(ncid,u10id,'stagger',ncchar,0,empty,ierr)
  ! V10:
  nd(1:2) = ndm1(1:2)
  nd(3) = time
  v10id = ncvdef(ncid,'V10',ncfloat,3,nd,ierr)
  CALL ncapt(ncid,v10id,'FieldType',nclong,1,104,ierr)
  CALL ncaptc(ncid,v10id,'MemoryOrder',ncchar,3,'XY ',ierr)
  CALL ncaptc(ncid,v10id,'description',ncchar,9, &
 	      'V at 10 M',ierr)
  CALL ncaptc(ncid,v10id,'units',ncchar,3,'m/s',ierr)
  CALL ncaptc(ncid,v10id,'stagger',ncchar,0,empty,ierr)
  ! SMOIS:
  nd(1:2) = ndm1(1:2)
  nd(3) = nsol
  nd(4) = time
  smsid = ncvdef(ncid,'SMOIS',ncfloat,4,nd,ierr)
  CALL ncapt(ncid,smsid,'FieldType',nclong,1,104,ierr)
  CALL ncaptc(ncid,smsid,'MemoryOrder',ncchar,3,'XYZ',ierr)
  CALL ncaptc(ncid,smsid,'description',ncchar,13, &
 	      'SOIL MOISTURE',ierr)
  CALL ncaptc(ncid,smsid,'units',ncchar,0,empty,ierr)
  CALL ncaptc(ncid,smsid,'stagger',ncchar,1,'Z',ierr)
  ! TSLB:
  nd(1:2) = ndm1(1:2)
  nd(3) = nsol
  nd(4) = time
  tslbid = ncvdef(ncid,'TSLB',ncfloat,4,nd,ierr)
  CALL ncapt(ncid,tslbid,'FieldType',nclong,1,104,ierr)
  CALL ncaptc(ncid,tslbid,'MemoryOrder',ncchar,3,'XYZ',ierr)
  CALL ncaptc(ncid,tslbid,'description',ncchar,15, &
 	      'SOIL TEMPEATURE',ierr)
  CALL ncaptc(ncid,tslbid,'units',ncchar,1,'K',ierr)
  CALL ncaptc(ncid,tslbid,'stagger',ncchar,1,'Z',ierr)
  ! TSK:
  nd(1:2) = ndm1(1:2)
  nd(3) = time
  tskid = ncvdef(ncid,'TSK',ncfloat,3,nd,ierr)
  CALL ncapt(ncid,tskid,'FieldType',nclong,1,104,ierr)
  CALL ncaptc(ncid,tskid,'MemoryOrder',ncchar,3,'XY ',ierr)
  CALL ncaptc(ncid,tskid,'description',ncchar,24, &
 	      'SURFACE SKIN TEMPERATURE',ierr)
  CALL ncaptc(ncid,tskid,'units',ncchar,1,'K',ierr)
  CALL ncaptc(ncid,tskid,'stagger',ncchar,0,empty,ierr)

  ! End defining mode:
  CALL ncendf(ncid,ierr)

  ! assign values to variables:
  ! Times:
  start = (/1,1,1,1/)
  count(1) = 19
  count(2:4) = 1
  CALL ncvptc(ncid,tmid,start,count,times,19,ierr)
  ! U:
  ! Stagger: Y and Z:

  tmp(1:imax,1:jmax-1,1:kmax) = 0.5*( &
  	u(1:imax,1:jmax-1,1:kmax)+ &
     	u(1:imax,2:jmax  ,1:kmax))
  unc(1:imax,1:jmax-1,1:kmax-1) = 0.5*( &
  	tmp(1:imax,1:jmax-1,1:kmax-1)+ &
     	tmp(1:imax,1:jmax-1,2:kmax  ))

!//compare stagger_data and real_function_data
! pi = 4.0*ATAN(1.0)
!
!       do kk = 1,kmax-1
!        do jj = 1,jmax-1
!         do ii = 1,imax
!	   ppp(ii,jj,kk) = znu(kk)*(dam(ii,jj)-ptop)+ptop
!           stagu(ii,jj,kk) = sin(2.0*pi*(float(ii))/float(imax-1))*&
!                    sin(2.0*pi*(float(jj)-0.5)/float(jmax-1))*&
!                    sin(2.0*pi*(ppp(ii,jj,kk)-110000.0)/(ptop-110000.0))
!         enddo
!        enddo
!       enddo
!  write(*,*) 'mass_unstag_u=',u(4,4,1:21)
!  write(*,*) 'mass_stag_u=',unc(4,4,1:20)
!  write(*,*) 'stag_mass_pressure=',ppp(4,4,1:20)
!  
!  stag_diffu(1:imax,1:jmax-1,1:kmax-1) = unc(1:imax,1:jmax-1,1:kmax-1)&
!                                       -stagu(1:imax,1:jmax-1,1:kmax-1)
!
!  do kk = 1,kmax-1
!  write(*,*) 'k=',kk
!  write(*,*) 'mass_unstag2stag_u_diff(4,4,k)(%)=',stag_diffu(4,4,kk)*100.0
!  write(*,*) 'mass_unstag2stag_u=',unc(4,4,kk)
!  write(*,*) 'real_mass_unstag2stag_u=',stagu(4,4,kk)
!  write(*,*) '                                            '
!  enddo
!       err = 0.0
!       ftn = 0.0
!       maxdata = 0.0
!       DO kk=1,kmax-1
!         DO jj=1,jmax-1
!           DO ii=1,imax
!             err = err+stag_diffu(ii,jj,kk)**2
!             ftn = ftn+stagu(ii,jj,kk)**2
!             maxdata = max(maxdata,ABS(stag_diffu(ii,jj,kk)))
!           ENDDO
!         ENDDO
!       ENDDO
!        PRINT*,'Relative error of stagger conversion: ',sqrt(err/ftn)
! 
!      DO kk=1,kmax-1
!         DO jj=1,jmax-1
!           DO ii=1,imax
!              if(ABS(stag_diffu(ii,jj,kk)) == maxdata) then
!                 print*,'i=',ii,'j=',jj,'k=',kk,'maxdata=',maxdata
!              endif
!           ENDDO
!         ENDDO
!       ENDDO

 

  count(1) = imax
  count(2) = jmax-1
  count(3) = kmax-1
  CALL ncvpt(ncid,uid,start,count,unc,ierr)
  ! V:
  ! Stagger: X and Z:


  tmp(1:imax-1,1:jmax,1:kmax) = 0.5*( &
 	v(1:imax-1,1:jmax,1:kmax)+ &
     	v(2:imax  ,1:jmax,1:kmax))
  vnc(1:imax-1,1:jmax,1:kmax-1) = 0.5*( &
 	tmp(1:imax-1,1:jmax,1:kmax-1)+ &
     	tmp(1:imax-1,1:jmax,2:kmax  ))
 
  count(1) = imax-1
  count(2) = jmax
  count(3) = kmax-1
  CALL ncvpt(ncid,vid,start,count,vnc,ierr)
  ! T:
  ! Stagger: X, Y and Z:
  tmp(1:imax-1,1:jmax,1:kmax) = 0.5*( &
 	t(1:imax-1,1:jmax,1:kmax)+ &
     	t(2:imax  ,1:jmax,1:kmax))
  tmp(1:imax-1,1:jmax-1,1:kmax) = 0.5*( &
 	tmp(1:imax-1,1:jmax-1,1:kmax)+ &
     	tmp(1:imax-1,2:jmax  ,1:kmax))
  tnc(1:imax-1,1:jmax-1,1:kmax-1) = 0.5*( &
 	tmp(1:imax-1,1:jmax-1,1:kmax-1)+ &
     	tmp(1:imax-1,1:jmax-1,2:kmax  ))

  ! Test stagger:
  CALL StaggerLogP(ptop,dam,znw,tmp(1:imax-1,1:jmax-1,1:kmax),&
	imax-1,jmax-1,kmax,tmp(1:imax-1,1:jmax-1,1:kmax-1))
  tnc(1:imax-1,1:jmax-1,1:kmax-1) = tmp(1:imax-1,1:jmax-1,1:kmax-1)


  count(1) = imax-1
  count(2) = jmax-1
  count(3) = kmax-1
  CALL ncvpt(ncid,tid,start,count,tnc,ierr)
  ! MU:
  ! Stagger: X, and Y:
  tmp(1:imax-1,1:jmax,1) = 0.5*( &
 	pdam(1:imax-1,1:jmax)+ &
     	pdam(2:imax  ,1:jmax))
  tnc(1:imax-1,1:jmax-1,1) = 0.5*( &
 	tmp(1:imax-1,1:jmax-1,1)+ &
     	tmp(1:imax-1,2:jmax  ,1))
  count(1) = imax-1
  count(2) = jmax-1
  count(3) = 1
  CALL ncvpt(ncid,muid,start,count,tnc,ierr)
  ! MUB:
  ! Stagger: X, and Y:
  tmp(1:imax-1,1:jmax,1) = 0.5*( &
 	dam(1:imax-1,1:jmax)+ &
     	dam(2:imax  ,1:jmax))
  tnc(1:imax-1,1:jmax-1,1) = 0.5*( &
 	tmp(1:imax-1,1:jmax-1,1)+ &
     	tmp(1:imax-1,2:jmax  ,1))
  count(1) = imax-1
  count(2) = jmax-1
  count(3) = 1
  CALL ncvpt(ncid,mubid,start,count,tnc,ierr)
  ! QVAPOR:
  ! Stagger: X, Y and Z:
  tmp(1:imax-1,1:jmax,1:kmax) = 0.5*( &
 	sh(1:imax-1,1:jmax,1:kmax)+ &
     	sh(2:imax  ,1:jmax,1:kmax))
  tmp(1:imax-1,1:jmax-1,1:kmax) = 0.5*( &
 	tmp(1:imax-1,1:jmax-1,1:kmax)+ &
     	tmp(1:imax-1,2:jmax  ,1:kmax))
  tnc(1:imax-1,1:jmax-1,1:kmax-1) = 0.5*( &
 	tmp(1:imax-1,1:jmax-1,1:kmax-1)+ &
     	tmp(1:imax-1,1:jmax-1,2:kmax  ))
  count(1) = imax-1
  count(2) = jmax-1
  count(3) = kmax-1
  CALL ncvpt(ncid,qid,start,count,tnc,ierr)
  ! MAPFAC_M:
  ! Stagger: X, and Y:
  tmp(1:imax-1,1:jmax,1) = 0.5*( &
 	mapfac(1:imax-1,1:jmax)+ &
     	mapfac(2:imax  ,1:jmax))
  tnc(1:imax-1,1:jmax-1,1) = 0.5*( &
 	tmp(1:imax-1,1:jmax-1,1)+ &
     	tmp(1:imax-1,2:jmax  ,1))
  count(1) = imax-1
  count(2) = jmax-1
  count(3) = 1
  CALL ncvpt(ncid,mapid,start,count,tnc,ierr)
  ! P_TOP:
  count(1) = 1
  count(2) = 1
  CALL ncvpt(ncid,ptid,start,count,ptop,ierr)
  ! ZNU:
  ! Stagger: Z:
  count(1) = kmax-1
  count(2) = 1
  CALL ncvpt(ncid,znuid,start,count,znu,ierr)
  ! ZNW:
  ! Unstagger: Z:
  count(1) = kmax
  count(2) = 1
  CALL ncvpt(ncid,znwid,start,count,znw,ierr)
  ! XLAT:
  ! Stagger: X, and Y:
  tmp(1:imax-1,1:jmax,1) = 0.5*( &
 	lat(1:imax-1,1:jmax)+lat(2:imax  ,1:jmax))
  tnc(1:imax-1,1:jmax-1,1) = 0.5*( &
 	tmp(1:imax-1,1:jmax-1,1)+ &
     	tmp(1:imax-1,2:jmax  ,1))
  count(1) = imax-1
  count(2) = jmax-1
  count(3) = 1
  CALL ncvpt(ncid,latid,start,count,tnc,ierr)
  ! XLONG:
  ! Stagger: X, and Y:
  tmp(1:imax-1,1:jmax,1) = 0.5*( &
 	lon(1:imax-1,1:jmax)+lon(2:imax  ,1:jmax))
  tnc(1:imax-1,1:jmax-1,1) = 0.5*( &
 	tmp(1:imax-1,1:jmax-1,1)+ &
     	tmp(1:imax-1,2:jmax  ,1))
  count(1) = imax-1
  count(2) = jmax-1
  count(3) = 1
  CALL ncvpt(ncid,lonid,start,count,tnc,ierr)
  ! RDX:
  count(1:2) = 1
  CALL ncvpt(ncid,rxid,start,count,1.0/dxy,ierr)
  ! RDY:
  count(1:2) = 1
  CALL ncvpt(ncid,ryid,start,count,1.0/dxy,ierr)

  ! Assign fake values to the extra variables:
  ! PHB:
  ! Stagger: X, Y:
  DO k=1,kmax-1
    tnc(1:imax-1,1:jmax-1,k) = 40000.0+(k-1)*90000.0
  ENDDO
  count(1) = imax-1
  count(2) = jmax-1
  count(3) = kmax-1
  CALL ncvpt(ncid,phbid,start,count,tnc,ierr)
  ! LANDMASK:
  ! Stagger: X, and Y:
  tnc(1:imax-1,1:jmax-1,1) = 1.0
  count(1) = imax-1
  count(2) = jmax-1
  count(3) = 1
  CALL ncvpt(ncid,lmkid,start,count,tnc,ierr)
  ! XICE:
  ! Stagger: X, and Y:
  tnc(1:imax-1,1:jmax-1,1) = 0.0
  count(1) = imax-1
  count(2) = jmax-1
  count(3) = 1
  CALL ncvpt(ncid,iceid,start,count,tnc,ierr)
  ! SST:
  ! Stagger: X, and Y:
  tnc(1:imax-1,1:jmax-1,1) = 280.0
  count(1) = imax-1
  count(2) = jmax-1
  count(3) = 1
  CALL ncvpt(ncid,sstid,start,count,tnc,ierr)
  ! IVGTYP:
  ! Stagger: X, and Y:
  itnc(1:imax-1,1:jmax-1,1) = 2
  count(1) = imax-1
  count(2) = jmax-1
  count(3) = 1
  CALL ncvpt(ncid,vgid,start,count,itnc,ierr)
  ! ISLTYP:
  ! Stagger: X, and Y:
  itnc(1:imax-1,1:jmax-1,1) = 1
  count(1) = imax-1
  count(2) = jmax-1
  count(3) = 1
  CALL ncvpt(ncid,slid,start,count,itnc,ierr)
  ! VEGFRA:
  ! Stagger: X, and Y:
  tnc(1:imax-1,1:jmax-1,1) = 0.0
  count(1) = imax-1
  count(2) = jmax-1
  count(3) = 1
  CALL ncvpt(ncid,vfid,start,count,tnc,ierr)
  ! SNOW:
  ! Stagger: X, and Y:
  tnc(1:imax-1,1:jmax-1,1) = 0.0
  count(1) = imax-1
  count(2) = jmax-1
  count(3) = 1
  CALL ncvpt(ncid,snwid,start,count,tnc,ierr)
  ! U10:
  ! Stagger: X, and Y:
  tnc(1:imax-1,1:jmax-1,1) = 0.0
  count(1) = imax-1
  count(2) = jmax-1
  count(3) = 1
  CALL ncvpt(ncid,u10id,start,count,tnc,ierr)
  ! V10:
  ! Stagger: X, and Y:
  tnc(1:imax-1,1:jmax-1,1) = 0.0
  count(1) = imax-1
  count(2) = jmax-1
  count(3) = 1
  CALL ncvpt(ncid,v10id,start,count,tnc,ierr)
  ! SMOIS:
  ! Stagger: X, and Y:
  tnc(1:imax-1,1:jmax-1,1:nsol) = 0.0
  count(1) = imax-1
  count(2) = jmax-1
  count(3) = 4
  count(4) = 1
  CALL ncvpt(ncid,smsid,start,count,tnc,ierr)
  ! TSLB:
  ! Stagger: X, and Y:
  tnc(1:imax-1,1:jmax-1,1:nsol) = 280.0
  count(1) = imax-1
  count(2) = jmax-1
  count(3) = 4
  count(4) = 1
  CALL ncvpt(ncid,tslbid,start,count,tnc,ierr)
  ! TSK:
  ! Stagger: X, and Y:
  tnc(1:imax-1,1:jmax-1,1) = 280.0
  count(1) = imax-1
  count(2) = jmax-1
  count(3) = 1
  CALL ncvpt(ncid,tskid,start,count,tnc,ierr)

  ! Close the netcdf file:
  CALL ncclos(ncid,ierr)

  return
  end


SUBROUTINE StaggerLogP(ptop,psfc,znw,vin,nx,ny,nz,vout)

!==========================================================
!  This routine computes a grid function on a stagger grid
!  using a given uniform grid function over a Log(p) grid.
!
!  Input:
!	ptop: 	Top pressure;
!	psfc:	Sfc pressure;
!	znw:	Eta value for a uniform grid;
!	vin:	Input grid function on a uniform grid;
!		(nx*ny*nz)
!	nx:	Number of uniform grid point in X;
!	ny:	Number of uniform grid point in Y;
!	nz:	Number of uniform vertical points;
!
!  Output:
!	vout:	Output grid funcion on a stagger grid.
!		(nx*ny*(nz-1))
!
!  HISTORY: APR. 2006 by YUANFU XIE.
!==========================================================

  IMPLICIT NONE

  INTEGER, INTENT(IN) :: nx,ny,nz
  REAL*4, INTENT(IN) ::  ptop,psfc(nx,ny),znw(nz)
  REAL, INTENT(IN) ::    vin(nx,ny,nz)
  REAL, INTENT(OUT) ::   vout(nx,ny,nz-1)

  ! Local variables:
  INTEGER :: i,j,k
  REAL :: a,b,p,p1,p2

  ! Linear interpolation:
  DO k=1,nz-1

    DO j=1,ny
      DO i=1,nx

	p1 = znw(k)*(psfc(i,j)-ptop)+ptop
	p2 = znw(k+1)*(psfc(i,j)-ptop)+ptop
	! Pressure value at the stagger grid:
	p = 0.5*(p1+p2)
    	a = LOG(p1/p)
    	b = LOG(p/p2)

    	vout(i,j,k) = (b*vin(i,j,k  )+ &
                       a*vin(i,j,k+1))/(a+b)

      ENDDO
    ENDDO

  ENDDO

END SUBROUTINE StaggerLogP


SUBROUTINE UnStaggerLogP(ptop,psfc,znw,vin,nx,ny,nz,vout)

!==========================================================
!  This routine computes a grid function on a uniform grid
!  using a given stagger grid function over a Log(p) grid.
!
!  Input:
!	ptop: 	Top pressure;
!	psfc:	Sfc pressure;
!	znw:	Eta value for a uniform grid;
!	vin:	Input grid function on a stagger grid;
!		(nx*ny*(nz-1))
!	nx:	Number of uniform grid point in X;
!	ny:	Number of uniform grid point in Y;
!	nz:	Number of uniform vertical points;
!
!  Output:
!	vout:	Output grid funcion on a uniform grid.
!		(nx*ny*nz)
!
!  HISTORY: APR. 2006 by YUANFU XIE.
!==========================================================

  IMPLICIT NONE

  INTEGER, INTENT(IN) :: nx,ny,nz
  REAL*4, INTENT(IN) ::  ptop,psfc(nx,ny),znw(nz)
  REAL, INTENT(IN) ::    vin(nx,ny,nz)
  REAL, INTENT(OUT) ::   vout(nx,ny,nz-1)

  ! Local variables:
  INTEGER :: i,j,k
  REAL :: a,b,p,p1,p2

  ! Linear interpolation:
  DO k=2,nz-1

    DO j=1,ny
      DO i=1,nx

	p1 = znw(k)*(psfc(i,j)-ptop)+ptop
	p2 = znw(k+1)*(psfc(i,j)-ptop)+ptop
	! Pressure value at the stagger grid:
	p = 0.5*(p1+p2)
    	a = LOG(p1/p)
    	b = LOG(p/p2)

    	vout(i,j,k) = (b*vin(i,j,k  )+ &
                       a*vin(i,j,k+1))/(a+b)

      ENDDO
    ENDDO

  ENDDO

END SUBROUTINE UnStaggerLogP
