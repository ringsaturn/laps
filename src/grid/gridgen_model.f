cdis    Forecast Systems Laboratory
cdis    NOAA/OAR/ERL/FSL
cdis    325 Broadway
cdis    Boulder, CO     80303
cdis 
cdis    Forecast Research Division
cdis    Local Analysis and Prediction Branch
cdis    LAPS 
cdis 
cdis    This software and its documentation are in the public domain and 
cdis    are furnished "as is."  The United States government, its 
cdis    instrumentalities, officers, employees, and agents make no 
cdis    warranty, express or implied, as to the usefulness of the software 
cdis    and documentation for any purpose.  They assume no responsibility 
cdis    (1) for the use of the software and documentation; or (2) to provide
cdis     technical support to users.
cdis    
cdis    Permission to use, copy, modify, and distribute this software is
cdis    hereby granted, provided that the entire disclaimer notice appears
cdis    in all copies.  All modifications to this software must be clearly
cdis    documented, and are solely the responsibility of the agent making 
cdis    the modifications.  If significant modifications or enhancements 
cdis    are made to this software, the FSL Software Policy Manager  
cdis    (softwaremgr@fsl.noaa.gov) should be notified.
cdis 
cdis 
cdis 
cdis 
cdis 
cdis 
cdis 

	Program gridgen_model
C**********************************************************************
c Portions of the following code were taken from the RAMS software and 
c   were used by permission of the *ASTER Division/Mission Research 
c   Corporation. 
C**********************************************************************
C*	This program will be used to map model grids based on the RAMS*
C*  version 2b which uses polar stereographic projections. Other      *
C*  projections have since been added.                                *
c*                                                                    *
C*********************************************************************
c Beginning July 2000, this software was updated to accomodate the    *
c WRFSI (Weather Research and Forecasting Standard Initialization)    *
c grid requirements.  This included adding stagger calculations, and  *
c map projection factors (map factor and components of coriolis parm, *
c landuse, soil type, vegetation greenness fraction, mean annual soil *
c temperature, albedo, and sea surface temperature.  Significant work *
c has occurred to reduce memory requirements.  Many sections of code  *
c previously in this file now reside in file gridgen_utils.f          *
c For further information contact                                     *
c Mr. John Smart NOAA/FSL, smart@fsl.noaa.gov (303-497-6590)          *
c*********************************************************************

        use horiz_interp

        integer istag
        integer n_staggers
        integer NX_L,NY_L
        integer lf
        character c10_grid_fname*10
        character c_dataroot*200
        character cstaticdir*200
        logical   localize
        real,     allocatable  ::  moad_lat(:,:)
        real,     allocatable  ::  moad_lon(:,:)
        real,     allocatable  ::  dum2d(:,:)
        real      La1,Lo1,LoV,Latin1,Latin2
        real      Dx,Dy

        include 'grid_fname.cmn'

        write(6,*)
        write(6,*)' gridgen_model: start'

        call get_config(istatus)
        if(istatus.ne.1)then
           print*,'Error returned: get_config'
           stop
        endif

        call find_domain_name(c_dataroot,c10_grid_fname,istatus)
        if(istatus .ne. 1)then
            write(6,*) 'Error: find domain name - stop'
            stop
        endif
        call s_len(c10_grid_fname,lf)

        if(c10_grid_fname(1:lf).eq.'wrfsi')then
           call get_num_domains(num_domains,istatus)
           if(istatus.ne.1)then
              print*,'Error returned: get_num_domains'
              stop
           endif
        else
           num_domains=1
        endif

        do nest=1,num_domains

c first detemine if this domain requires localizing or re-localizing

           call get_directory('static',cstaticdir,len_dir)

           call rd_static_attr(cstaticdir,nest
     .,c10_grid_fname,Nx_l,Ny_l,Dx,Dy,La1,Lo1,Latin1
     .,Latin2,LoV,istatus)

           call eval_localization(cstaticdir,nest,localize
     .,c10_grid_fname,La1,Lo1,istatus)
c
c force localizations until we are ready to ignore them otherwise
c
           localize = .true.

           if(localize)then

              call get_grid_dim_xy(NX_L,NY_L,istatus)
              if (istatus .ne. 1) then
                 print*, 'Error getting horizontal domain dimensions'
                 goto999
              endif

              call get_grid_spacing(Dx,istatus)
              call get_domain_origin_parent(i_orig,j_orig,istatus)

              print*,'grid_spacing(m)  = ',Dx
              print*,'grid dims        = ',nx_l,ny_l
              print*,'grid origin i/j  = ',i_orig,j_orig
              Dy=Dx

              if(nest.gt.1)then
                 print*,' calculate center lat/lon '
                 La1=moad_lat(i_orig,j_orig)
                 Lo1=moad_lon(i_orig,j_orig)
                 print*,' SW lat/lon = ',La1,Lo1
                 call get_earth_radius(erad,istatus)
c Get X/Y for grid center
                 CALL POLAR_GP(La1,Lo1,Xcen,Ycen,Dx,Dy,NX_L,NY_L,-1.)
                 call xy_to_latlon(Xcen,Ycen,erad,rlat,rlon)
              endif

              call get_n_staggers(n_staggers,istatus)
              call get_stagger_index(istag,istatus)

              if(istatus.ne.1)then
                 print*,'Error getting namelist info for',
     +': ',c10_grid_fname(1:lf)
                 stop
              endif

              call Gridmap_sub(NX_L,NY_L,n_staggers,istag,nest,istatus)

              if(istatus.eq.1)then
                 print*,' Gridmap_sub finish successfully'
                 if(nest.eq.1.and.num_domains.gt.1)then
                    allocate (moad_lat(nx_l,ny_l),
     .                        moad_lon(nx_l,ny_l),
     .                        dum2d(nx_l,ny_l))
                    call get_laps_domain(nx_l,ny_l,c10_grid_fname
     +,moad_lat,moad_lon,dum2d,istatus)
                    if(istatus.lt.1)then
                       print *,'Error reading MOAD lat, lon data.'
                       stop
                    endif
                 endif
              endif

              print*,' Gridmap_sub finished '
              print*

           else
              print*
              print*,' No need to re-localize this domain '
              print*
              if(nest.eq.1.and.num_domains.gt.1)then
                 allocate (moad_lat(nx_l,ny_l),
     .                     moad_lon(nx_l,ny_l),
     .                        dum2d(nx_l,ny_l))
                 call get_laps_domain(nx_l,ny_l,c10_grid_fname
     +,moad_lat,moad_lon,dum2d,istatus)
                 if(istatus.lt.1)then
                    print *,'Error reading MOAD lat, lon data.'
                    stop
                 endif
              endif
           endif

        enddo

 999	print*,' gridgen_model finish: istatus = ',istatus
        print*

        stop
        end
c
c --------------------------------------------------------------------
c
        subroutine Gridmap_sub(nnxp,nnyp,n_staggers,istag,nest,istatus)

        include 'trigd.inc'

        logical exist,new_DEM
        logical lforce_ter_2_zero

        integer nnxp,nnyp,mode
        integer ngrids
        integer n_staggers
        integer nest
        integer iter
        integer istag

        Real  mdlat,mdlon
        Real  xmn(nnxp),ymn(nnyp)
        Real  xtn(nnxp,n_staggers)
        Real  ytn(nnyp,n_staggers)

        real, allocatable ::  topt_10   (:,:)
        real, allocatable ::  topt_10_s (:,:)
        real, allocatable ::  topt_10_ln(:,:)
        real, allocatable ::  topt_10_lt(:,:)
        real, allocatable ::  topt_30   (:,:)
        real, allocatable ::  topt_30_s (:,:)
        real, allocatable ::  topt_30_ln(:,:)
        real, allocatable ::  topt_30_lt(:,:)

        real  topt_out   (nnxp,nnyp)
        real  topt_out_s (nnxp,nnyp)
        real  topt_out_ln(nnxp,nnyp)
        real  topt_out_lt(nnxp,nnyp)

        integer maxdatacat
        parameter (maxdatacat=24)

        real, allocatable ::  adum2d  (:,:)
        real, allocatable ::  adum3d  (:,:,:)

        real, allocatable ::  GEODAT2D(:,:)
        real, allocatable ::  GEODAT3D(:,:,:)

        real lats(nnxp,nnyp,n_staggers)
        real lons(nnxp,nnyp,n_staggers)

        character (len=3),   allocatable :: var(:)
        character (len=125), allocatable :: comment(:)

        character*131 model

        character*200 path_to_topt30s
        character*200 path_to_topt10m
        character*200 path_to_pctl10m
        character*200 path_to_soiltype_top_30s
        character*200 path_to_soiltype_bot_30s
        character*200 path_to_green_frac    !no reference to res since there is both
                                            !10m and 8.64m
        character*200 path_to_soiltemp_1deg
        character*200 path_to_luse_30s
        character*200 path_to_albedo        !albedo = 0.144 deg res or 8.64m 
        character*200 path_to_maxsnoalb
        character*200 path_to_islope

        character*255 filename
        character*200 c_dataroot
        character*200 cdl_dir
        character*180 static_dir 
        character*10  c10_grid_fname 
        character*6   c6_maproj
        character*1   cdatatype
        integer len,lf,lfn,ns
        integer ishow_timer,init_timer
        integer itstatus

        real,  allocatable ::  rmapdata(:,:,:)
        real,  allocatable ::  data(:,:,:)     !primary output array storage unit.
 
        interface

          subroutine adjust_geog_data(nnxp,nnyp,ncat
     &,istatgrn,istattmp,istatslp,lat,topt_out,path_to_soiltemp
     &,landmask,soiltemp_1deg,greenfrac,islope,istatus)

          integer nnxp,nnyp
          integer istatus
          integer istatgrn
          integer istattmp
          integer istatslp

          character*(*) path_to_soiltemp
          real    lat(nnxp,nnyp)
          real    landmask(nnxp,nnyp)
          real    topt_out(nnxp,nnyp)
          real    soiltemp_1deg(nnxp,nnyp)
          real    islope(nnxp,nnyp)
          real    greenfrac(nnxp,nnyp,12)
          end subroutine

          subroutine proc_geodat(nx_dom,ny_dom,ncat
     1,path_to_tile_data,dom_lats_in,dom_lons_in,lmask_out
     1,geodat,istatus)

          integer nx_dom 
          integer ny_dom
          integer ncat
          character*(*) path_to_tile_data
          real    dom_lats_in(nx_dom,ny_dom)
          real    dom_lons_in(nx_dom,ny_dom)
          real    lmask_out(nx_dom,ny_dom)
          real    geodat(nx_dom,ny_dom,ncat)
          integer istatus
          end subroutine

        end interface

C*********************************************************************

        itstatus = init_timer()

        call find_domain_name(c_dataroot,c10_grid_fname,istatus)
        if(istatus .ne. 1)then
            write(6,*) 'Error: returned fro find_domain_name '
            return
        endif

        call s_len(c10_grid_fname,lf)

c add 12 for albedo month 1 - 12.
c add 1 more for islope JS: 2-25-03
        if(c10_grid_fname(1:lf).eq.'wrfsi')then
           ngrids=112 
        else
           ngrids=38
        endif

        if(.not. allocated (data))then
           allocate (data(nnxp,nnyp,ngrids),stat=istat)
        
           if(istat.ne.0)then
              print*,'Error allocating data object: array data ',istat
              print*,'Terminating: Maybe not enough memory'
              stop
           endif
        endif

        model = 'MODEL 4 delta x smoothed filter\0'

        icount_10 = 0
        icount_30 = 0
        icount_ramp = 0

        call get_directory('static',static_dir,lens)

c iplttopo is 1 if you want to plot the topography
c   the 30s topo covers the continental US
cc        itoptfn_30=static_dir(1:len)//'model/topo_30s/U'
c   the 10m topo covers the world
cc        itoptfn_10=static_dir(1:len)//'model/topo_10m/H'

        call get_path_to_topo_10m(path_to_topt10m,istatus)
        if(istatus .ne. 1)then
           write(6,*) 'Error getting path_to_topt10m'
           return
        endif

        call get_path_to_topo_30s(path_to_topt30s,istatus)
        if(istatus .ne. 1)then
           write(6,*) 'Error getting path_to_topt30s'
           return
        endif

        call get_path_to_soiltype_top(path_to_soiltype_top_30s
     +,istatus)
        if(istatus .ne. 1)then
           write(6,*)'Error getting path_to_soiltype_top_30s'
           return
        endif

        call get_path_to_soiltype_bot(path_to_soiltype_bot_30s
     +,istatus)
        if(istatus .ne. 1)then
           write(6,*)'Error getting path_to_soiltype_bot_30s'
           return
        endif

        call get_path_to_landuse_30s(path_to_luse_30s,istatus)
        if(istatus .ne. 1)then
           write(6,*)'Error getting path_to_luse_30s'
           return
        endif

        call get_path_to_green_frac(path_to_green_frac,istatus)
        if(istatus .ne. 1)then
           print*,'Error getting path_to_green_frac'
           return
        endif

        call get_path_to_soiltemp_1deg(path_to_soiltemp_1deg
     &,istatus)
        if(istatus .ne. 1)then
           print*, 'Error getting path_to_soiltemp_1deg'
           return
        endif

        call get_path_to_albedo(path_to_albedo,istatus)
        if(istatus .ne. 1)then
           print*, 'Error getting path_to_albedo'
           return
        endif

        call get_path_to_maxsnoalb(path_to_maxsnoalb,istatus)
        if(istatus .ne. 1)then
           print*, 'Error getting path_to_maxsnoalb'
           return
        endif

        call get_path_to_islope(path_to_islope,istatus)
        if(istatus .ne. 1)then
           print*, 'Error getting path_to_islope'
           return
        endif

        call s_len(path_to_topt30s,len)
        print*,'path to topt30s:        ',path_to_topt30s(1:len)
        path_to_topt30s(len+1:len+2)='/U'

        call s_len(path_to_topt10m,len)
        if(len.gt.0)then
           print*,'path to toptl0m:        ',path_to_topt10m(1:len)
        endif
        path_to_topt10m(len+1:len+2)='/H'

        call s_len(path_to_soiltype_top_30s,len)
        print*,'path to soiltype_top:   '
     .,path_to_soiltype_top_30s(1:len)
       path_to_soiltype_top_30s(len+1:len+2)='/O'
        print*,'path to soiltype_bot:   '
     .,path_to_soiltype_bot_30s(1:len)
        path_to_soiltype_bot_30s(len+1:len+2)='/O'

        call s_len(path_to_luse_30s,len)
        print*,'path to landuse 30s: ',path_to_luse_30s(1:len)
        path_to_luse_30s(len+1:len+2)='/V'

        call s_len(path_to_green_frac,len)
        print*,'path to green frac:     ',path_to_green_frac(1:len)
        path_to_green_frac(len+1:len+2)='/G'

        call s_len(path_to_soiltemp_1deg,len)
        print*,'path to soiltemp 1deg:  ',path_to_soiltemp_1deg(1:len)
        path_to_soiltemp_1deg(len+1:len+2)='/T'

        call s_len(path_to_albedo,len)
        print*,'path to albedo:         ',path_to_albedo(1:len)
        path_to_albedo(len+1:len+2)='/A'

        call s_len(path_to_maxsnoalb,len)
        print*,'path to max snow albedo: ',path_to_maxsnoalb(1:len)
        path_to_maxsnoalb(len+1:len+2)='/M'

        call s_len(path_to_islope,len)
        print*,'path to islope categorical: ',path_to_islope(1:len)
        path_to_islope(len+1:len+2)='/I'

        call get_topo_parms(silavwt_parm,toptwvl_parm,istatus)
	if (istatus .ne. 1) then
           write (6,*) 'Error getting terrain smoothing parms'
	   return
	endif

        call get_r_missing_data(r_missing_data,istatus)
	if (istatus .ne. 1) then
           write (6,*) 'Error getting r_missing_data'
	   return
	endif

!       Silhouette weighting parameter
        silavwt=silavwt_parm

!       Terrain wavelength for filtering
        toptwvl=toptwvl_parm

        iplttopo=1

C*********************************************************************
        call get_gridnl(mode) 

c calculate delta x and delta y using grid and map projection parameters
        call get_standard_latitudes(std_lat,std_lat2,istatus)
        if(istatus .ne. 1)then
            write(6,*)' Error calling laps routine'
            return
        endif
        write(6,*)' standard_lats = ',std_lat,std_lat2

        call get_grid_spacing(grid_spacing_m,istatus)
        if(istatus .ne. 1)then
            write(6,*)' Error calling laps routine'
            return
        endif
        write(6,*)' grid_spacing = ',grid_spacing_m

        call get_grid_center(mdlat,mdlon,istatus)
        if(istatus .ne. 1)then
            write(6,*)' Error calling laps routine'
            return
        endif
        write(6,*)' grid_center = ',mdlat,mdlon

        call get_c6_maproj(c6_maproj,istatus)
        if(istatus .ne. 1)then
            write(6,*)' Error calling laps routine'
            return
        endif
        write(6,*)' c6_maproj = ',c6_maproj

        call get_standard_longitude(std_lon,istatus)
        if(istatus .ne. 1)then
            write(6,*)' Error calling laps routine'
            return
        endif
        write(6,*)' std_lon = ',std_lon

        call get_earth_radius(erad,istatus)
        if(istatus .ne. 1)then
            write(6,*)' Error calling laps routine'
            return
        endif
        write(6,*)' Earth Radius = ',erad

        if(c6_maproj .eq. 'plrstr')then
            call get_ps_parms(std_lat,std_lat2,grid_spacing_m,phi0
     1                       ,grid_spacing_proj_m)

            deltax = grid_spacing_proj_m

            if(phi0 .eq. 90.)then
                write(6,*)' Projection is tangent to earths surface'
            else
                write(6,*)' Projection is secant to earths surface'
            endif

            if(std_lat2 .eq. +90.)then
                write(6,*)' Note, grid spacing will equal '
     1                    ,grid_spacing_m,' at a latitude of ',std_lat
!               write(6,*)' deltax, deltay ',deltax,deltay
!    1                   ,' at the north pole'

            elseif(std_lat2 .eq. -90.)then
                write(6,*)' Note, grid spacing will equal '
     1                    ,grid_spacing_m,' at a latitude of ',std_lat       
!               write(6,*)' deltax, deltay ',deltax,deltay
!    1                   ,' at the south pole'

            else ! abs(std_lat2) .ne. 90. (local stereographic)
                write(6,*)' The standard latitude ',std_lat,' is'
     1                   ,' relative to where the pole'
                write(6,*)' of the map projection is: lat/lon '
     1                   ,std_lat2,std_lon
!               write(6,*)' deltax, deltay ',deltax,deltay
!    1                   ,' at the projection pole'
                if(std_lat .ne. +90.)then
                    write(6,*)' Note: std_lat should usually be set'
     1                       ,' to +90. for local stereographic'
                endif

            endif

        else ! c6_maproj .ne. 'plrstr'
            deltax = grid_spacing_m

        endif ! c6_maproj .eq. 'plrstr'

        deltay = deltax
        write(6,*)' deltax, deltay (in projection plane) '
     1             ,deltax,deltay
 
c*********************************************************************
c in arrays lats/lons, the first stagger is actually not staggered
c but is the usual lat/lon values at non-staggered grid points. These
c are used for the analysis (LAPS-nest7grid). For WRFSI, we use the
c mass c-stagger (#4); staggered in both x and y. 

        call compute_latlon(nnxp,nnyp,n_staggers
     + ,deltax,xtn,ytn,lats,lons,istatus)
        if(istatus.ne.1)then
           print*,'Error returned: compute_latlon'
           return
        endif

        ns = istag

        print*,'ns [staggers array index] = ',ns
        if(ns.ne.1)
     &print*,' Using C-stagger grid for LSM fields and other output'

C*****************************************************************
        write(6,*)
        write(6,*)'Corner points.'
        write(6,701,err=702)1,1,lats(1,1,ns),      lons(1,1,ns)
        write(6,701,err=702)nnxp,1,lats(nnxp,1,ns),lons(nnxp,1,ns)   
        write(6,701,err=702)1,nnyp,lats(1,nnyp,ns),lons(1,nnyp,ns)   
        write(6,701,err=702)nnxp,nnyp,lats(nnxp,nnyp,ns)
     +,lons(nnxp,nnyp,1)   
 701    format(' lat/lon at ',i5,',',i5,' =',2f12.5)
 702    continue

        call check_domain(lats(1,1,ns),lons(1,1,ns),nnxp,nnyp
     +,grid_spacing_m,1,istat_chk)  
        if(istat_chk.ne.1)then
           print*,'Error returned from check_domain'
           istatus = istat_chk
           return
        endif
        open(666,file=static_dir(1:lens)//'latlon2d.dat')
        do j=1,nnyp
          do i=1,nnxp
            write(666,*) lats(i,j,ns),lons(i,j,ns)
          enddo
            write(666,'()')
        enddo
        close(666)


! We will end at this step given the showgrid or max/min lat lon
! options.
       if(mode.eq.2) then

           print*,'We no longer run showgrid in gridgen_model'
           return

       elseif(mode.eq.3)then

           print*,'get perimeter of grid'
           call get_domain_perimeter_grid(nnxp,nnyp,c10_grid_fname
     1                  ,lats(1,1,ns),lons(1,1,ns)
     1                  ,1.0,rnorth,south,east,west,istatus)
           print*,'static dir = ',static_dir(1:lens)
           open(10,file=static_dir(1:lens)//'/llbounds.dat'
     +         ,status='unknown')

           print*,'write llbounds.dat'
           write(10,*)rnorth,south,east,west
           close(10)
	   return
       endif

       write(6,*)'deltax = ',deltax
       write(6,*)'check_domain:status = ',istat_chk
c
C*****************************************************************
c calculate surface static fields
c
c ------------ Terrain USGS 30 sec ----------------
c ------------ and 10m if necessary ---------------
c type = U
c
       itstatus=ishow_timer()
       print*
       print*,' Processing 30s topo data....'

       allocate (topt_30(nnxp,nnyp),
     +           topt_30_s(nnxp,nnyp),
     +           topt_30_ln(nnxp,nnyp),
     +           topt_30_lt(nnxp,nnyp))

       CALL GEODAT(nnxp,nnyp,erad,90.,std_lon,xtn(1,1)
     +,ytn(1,1),deltax,deltay,TOPT_30,TOPT_30_S,TOPT_30_LN
     +,TOPT_30_LT,PATH_TO_TOPT30S,TOPTWVL,SILAVWT,new_DEM,1
     +,istatus_30s)

       if(istatus_30s .ne. 1)then

          print*,'WARNING: File(s) missing for 30s terrain data'
          print*,' >>>> Try Processing 10m topo data <<<<'
          print*

          allocate (topt_10(nnxp,nnyp),
     +              topt_10_s(nnxp,nnyp),
     +              topt_10_ln(nnxp,nnyp),
     +              topt_10_lt(nnxp,nnyp))

          print*
          print*,' Calling GEODAT:  10m terrain data ....'

          CALL GEODAT(nnxp,nnyp,erad,90.,std_lon,xtn(1,1)
     +,ytn(1,1),deltax,deltay,TOPT_10,TOPT_10_S,TOPT_10_LN
     +,TOPT_10_LT,PATH_TO_TOPT10M,TOPTWVL,SILAVWT,new_DEM,1
     +,istatus_10m)

          if(istatus_10m .ne. 1)then

             print*
             print*,'Error: File(s) missing for both 10m and
     +30s terrain data'
             print*,'Error: Aborting --- No static file created'
             return

          else

             print *,'topt_10    =',topt_10(1,1),topt_10(nnxp,nnyp)
             print*
             print*,'try blending 10min and 30s terrain data'
             call blend_topo(nnxp,nnyp,lats(1,1,1),lons(1,1,1)
     1,topt_10,topt_10_s,topt_10_ln,topt_10_lt
     1,topt_30,topt_30_s,topt_30_ln,topt_30_lt
     1,topt_out,topt_out_s,topt_out_ln,topt_out_lt)

             deallocate (topt_10,
     1                   topt_10_s,
     1                   topt_10_ln,
     1                   topt_10_lt)

          endif

       else ! go with 30s topo data since all tiles available

          print*,'Topo SW and NE corner values'
          print *,'topt_30    =',topt_30(1,1),topt_30(nnxp,nnyp)

          topt_out=topt_30
          topt_out_s=topt_30_s
          topt_out_ln=topt_30_ln
          topt_out_lt=topt_30_lt
          icount_30=nnyp*nnxp
          
       endif !istatus_30s ... data processed ok 

       deallocate (topt_30,
     1             topt_30_s,
     1             topt_30_ln,
     1             topt_30_lt)

       print*
c
c -------------- 30s Landuse -------------------------
c type = V
c
       itstatus=ishow_timer()
       print*
       print*,' Calling GEODAT: Processing 30s landuse data.'
       print*,' Re-allocate GEODAT3D ',nnxp,nnyp,' 24'
       print*
       allocate  (adum2d(nnxp,nnyp))
       allocate  (GEODAT2D(nnxp,nnyp))
       allocate  (GEODAT3D(nnxp,nnyp,24))

       CALL GEODAT(nnxp,nnyp,erad,90.,std_lon,xtn(1,ns)
     +,ytn(1,ns),deltax,deltay,GEODAT2D,GEODAT3D
     +,adum2d,adum2d,PATH_TO_LUSE_30S,2.0,0.0,new_DEM,24
     +,istatus)

       if(istatus.ne.1)then
         print*,'********* ERROR ***********'
         print*,'ERROR:  File(s) missing for landuse data'
         print*,'ERROR:  Static file not created'
         print*
         return
       endif

       ilndmsk=12  !land mask is 12 for both wrfsi and laps
       if(c10_grid_fname(1:lf).eq.'wrfsi')then

c dominant category landuse
          ilnduse=11
          data(:,:,ilnduse)=GEODAT2D
c landmask for wrfsi
          data(:,:,ilndmsk) = 1.
          where(data(:,:,11) .eq. 16.)data(:,:,ilndmsk)=0.

c grids 15 thru 38 are percent distributions
          i=14
          do j=1,24
             data(:,:,i+j)=GEODAT3D(:,:,j)
          enddo
       else
c dominant category landuse
          ilnduse=5
          data(:,:,ilnduse)=GEODAT2D   !landuse for laps
c landmask for laps
          data(:,:,ilndmsk)=1.
          where(data(:,:,5) .eq. 16.)data(:,:,ilndmsk)=0.
       endif
c
c **********************************************
c fix water areas to have 0.0m terrain elevation
c currently no fix going on!
c **********************************************
       lforce_ter_2_zero=.false.
       if(lforce_ter_2_zero)then
          where(data(:,:,ilndmsk).eq.0)topt_out=0.0
       endif


c for WRFSI we'll bilinearly interpolate to get the topo
c from the non-staggered topo

       if(c10_grid_fname(1:lf).eq.'wrfsi')then

          data(:,:,9)=topt_out
          call move(topt_out_s,data(1,1,48),nnxp,nnyp)
          call move(topt_out_ln,data(1,1,49),nnxp,nnyp)
          call move(topt_out_lt,data(1,1,50),nnxp,nnyp)

          indxter=51
          do j=2,nnyp
          do i=2,nnxp
             data(i,j,indxter) = r_missing_data
             call bilinear_interp(i,j,nnxp,nnyp,topt_out,result)
             data(i-1,j-1,indxter)=result
          enddo
          enddo

          where((data(:,:,indxter).lt. 0.01).and.
     1          (data(:,:,indxter).gt.-0.01))data(:,:,indxter)=0.0

       else  !must be LAPS

          indxter=3
          call move(topt_out,data(1,1,indxter),nnxp,nnyp)         ! KWD
          call move(topt_out_s,data(1,1,7),nnxp,nnyp)             ! JS
          call move(topt_out_ln,data(1,1,8),nnxp,nnyp)            ! JS
          call move(topt_out_lt,data(1,1,9),nnxp,nnyp)            ! JS

       endif 

       print*
       print *,'terrain  = ',data(1,1,indxter),data(nnxp,nnyp,indxter)
       print *,'# of grid pts using 30 sec terrain data =  ',icount_30
       print *,'# of grid pts using 10 min terrain data =  ',icount_10
       print *,'# of grid pts using blended terrain data = ',icount_ramp
       print*
C
       call s_len(static_dir,len)
       open(10,file=static_dir(1:len)//'latlon.dat'
     +         ,status='unknown',form='unformatted')
       open(11,file=static_dir(1:len)//'topo.dat'
     +         ,status='unknown',form='unformatted')
       open(15,file=static_dir(1:len)//'corners.dat'
     +         ,status='unknown')
       write(10)lats(1:nnxp,1:nnyp,ns),lons(1:nnxp,1:nnyp,ns)
       close(10)
       write(11)data(:,:,indxter)
       close(11)
       write(15,*)lats(1,1,ns),lons(1,1,ns)
       write(15,*)lats(1,nnyp,ns),lons(1,nnyp,ns)
       write(15,*)lats(nnxp,1,ns),lons(nnxp,1,ns)
       write(15,*)lats(nnxp,nnyp,ns),lons(nnxp,nnyp,ns)
       close(15)

c SG97  topography.dat is written to be displayed with gnuplot
c SG97  this will make an elevated view from the SW direction over the domain
c SG97  start gnuplot and type in the following commands:
c SG97  set data style lines
c SG97  set view 30,330
c SG97  splot 'topography.dat'

	open(666,file=static_dir(1:len)//'topography.dat')
        do j=1,nnyp
	  do i=1,nnxp
	    write(666,*) data(i,j,indxter)
          enddo
            write(666,'()')
        enddo
        close(666)
c
c ------ Land Fraction from 30s Land Use ----------------------------
c type = L (no longer used ... no land fraction data base)
c
        print*
        print*,' Create from 30s land use fractional dist'
        print*
 
        GEODAT2D(:,:)=1.- GEODAT3D(:,:,16)
c
c this function allows variable amounts of smoothing of
c the land fraction data depending on grid spacing
c
        iter=min(10,int(8000./deltax))
        
        print*,'Filter land fraction with 2dx ',iter
        do k=1,iter
           call filter_2dx(GEODAT2D,nnxp,nnyp,1, 0.5)
           call filter_2dx(GEODAT2D,nnxp,nnyp,1,-0.5)
        enddo

        idx=4
        if(c10_grid_fname(1:lf).eq.'wrfsi')idx=10

        data(:,:,idx)=GEODAT2D
        print *,'pctlandfrac=',GEODAT2D(1,1),GEODAT2D(nnxp,nnyp)       
c
c -------------------------------------------------------------------
c potential fix of fictitous islands for certain resolution domains.
c Story here is that west coast terrain can be "funky" possibly due
c to steepness and method to compute avg terrain.

        where(data(:,:,idx).le.0.1 .and. data(:,:,indxter).lt.5.0)
     &data(:,:,indxter)=0.0

c
c -------------- Top Layer Soil Type -------------------------
c type = O
c
        itstatus=ishow_timer()
        print*
        print*,' Processing 30s soil type top layer data....'

        deallocate(GEODAT3D)
        allocate (GEODAT3D(nnxp,nnyp,16))

        CALL GEODAT(nnxp,nnyp,erad,90.,std_lon,xtn(1,ns),ytn(1,ns)
     +,deltax,deltay,GEODAT2D,GEODAT3D,adum2d,adum2d
     +,PATH_TO_SOILTYPE_TOP_30S,2.0,0.0,new_DEM,16   !maxdatacat
     +,istatus)

        if(istatus.ne.1)then
           print*
           print*,' Soil type data not processed completely'
           if(c10_grid_fname(1:lf).eq.'wrfsi')then
             print*,' File(s) missing for soil type top layer data'
             print*,' Error:  Static file not created'
             print*
             return
           else
             print*,' File(s) missing for soil type top layer data'
             print*,'           *** WARNING ***'
             print*,' Soil Type Top data not added to static file'
             print*
           endif
           GEODAT2D=r_missing_data
           GEODAT3D=r_missing_data
        endif

c top layer dominant category and percent distribution soil type

        if(c10_grid_fname(1:lf).eq.'wrfsi')then
           data(:,:,13)=GEODAT2D
           i=51
           do j=1,16
              data(:,:,i+j)=GEODAT3D(:,:,j)
           enddo
        else
           data(:,:,10)=GEODAT2D
        endif
c
c -------------- Bottom Layer Soil Type -------------------------
c type = O
c
        itstatus=ishow_timer()
        print*
        print*,' Processing 30s soil type bottom layer data'

        CALL GEODAT(nnxp,nnyp,erad,90.,std_lon,xtn(1,ns)
     +,ytn(1,ns),deltax,deltay,GEODAT2D,GEODAT3D,adum2d,adum2d
     +,PATH_TO_SOILTYPE_BOT_30S,2.0,0.0,new_DEM,16   !maxdatacat
     +,istatus)

        if(istatus.ne.1)then
           print*
           print*,' Bottom layer soil data not processed completely'
           if(c10_grid_fname(1:lf).eq.'wrfsi')then
             print*,' File(s) missing for soil type bot layer data'
             print*,' Error:  Static file not created'
             print*
             return
           else
             print*,' File(s) missing for soil type bot layer data'
             print*,'           *** WARNING ***'
             print*,' Soil Type Bot data not added to static file'
             print*
           endif
           GEODAT2D=r_missing_data
           GEODAT3D=r_missing_data
        endif

c bottom layer dominant category and percent distribution soil type

c
c soiltype bottom layer ... 68 thru 83
c
        if(c10_grid_fname(1:lf).eq.'wrfsi')then
            data(:,:,14)=GEODAT2D
            i=67
            do j=1,16
               data(:,:,i+j)=GEODAT3D(:,:,j)
            enddo
        else
            data(:,:,11)=GEODAT2D
        endif
c
c ------------- Greenness Fraction --------------------
c type = G
c
        itstatus=ishow_timer()
        print*
        print*,' Calling PROC_GEODAT: Process green frac data.'
        print*,' Re-allocate GEODAT3D ',nnxp,nnyp,' 12'
        print*

        deallocate(GEODAT3D)
        allocate  (GEODAT3D(nnxp,nnyp,12),stat=istat)
        if(istat.ne.0)then
           print*,'Error allocating data object GEODAT3D ',istat
           if(c10_grid_fname(1:lf).eq.'wrfsi')then
              print*,'Error: Aborting process'
              print*,'Error: Maybe not enough memory'
              print*,'Error: Cannot allocate GEODAT3D'
              stop
           else
              print*,'Warning: Continue without green fraction'         
           endif
        endif

        print*,'Calling proc_geodat'
        call proc_geodat(nnxp,nnyp,12,path_to_green_frac
     +,lats(1,1,ns),lons(1,1,ns),data(1,1,ilndmsk)
     +,GEODAT3D,istatus_grn)

        if(istatus_grn.ne.1)then
         print*
         print*,'greenness fraction data not processed completely'
         if(c10_grid_fname(1:lf).eq.'wrfsi')then
            print*,' Error: File(s) missing for green frac data'
            print*,' Error: Static file not created'
            print*
            istatus=0
            return
         else
            print*,' Warning: File(s) missing for green frac data'
            print*,' Warning: green frac not added to static file'
            print*
         endif
         GEODAT3D=r_missing_data
        endif

        if(c10_grid_fname(1:lf).eq.'wrfsi')then
           igrn=83
        else
           igrn=12
        endif
        do j=1,12
           data(:,:,igrn+j)=GEODAT3D(:,:,j)
        enddo
c
c --------------- Deep Soil Temperature -------------------
c type = T
c
        itstatus=ishow_timer()
        print*
        print*,' Call PROC_GEODAT: Process 1 deg soiltemp data.'

        GEODAT2D=0.0

        call proc_geodat(nnxp,nnyp,1
     1,path_to_soiltemp_1deg,lats(1,1,ns),lons(1,1,ns)
     1,data(1,1,ilndmsk),GEODAT2D,istatus_tmp)

        if(istatus_tmp.ne.1)then
         print* 
         print*,'soiltemp data not processed completely' 
         if(c10_grid_fname(1:lf).eq.'wrfsi')then 
            print*,' Error:  File(s) missing for soiltemp data' 
            print*,' Error:  Static file not created'
            print*
            istatus=0
            return
         else
            print*,' File(s) missing for soiltemp data'
            print*,'           *** WARNING ***'
            print*,' soiltemp data not added to static file'
            print*
         endif
         GEODAT2D=r_missing_data
        endif

        idst=25
        if(c10_grid_fname(1:lf).eq.'wrfsi')then 
           idst=96
        endif 
        data(:,:,idst)=GEODAT2D
c
c -------------- Terrain slope index categories -------------------------
c type = I
c
        itstatus=ishow_timer()
        print*
        print*,' Processing 1 deg islope data'

        allocate (adum3d(nnxp,nnyp,9))  !temporarily holds %dist of islope cat

        CALL GEODAT(nnxp,nnyp,erad,90.,std_lon,xtn(1,ns)
     +,ytn(1,ns),deltax,deltay,GEODAT2D,adum3d,adum2d,adum2d
     +,PATH_TO_ISLOPE,2.0,0.0,new_DEM,9,istatus_slp)

        deallocate (adum2d,adum3d)

        if(istatus_slp.ne.1)then
           print*
           print*,' ter slope category data not processed completely'
           if(c10_grid_fname(1:lf).eq.'wrfsi')then
             print*,' Error: File(s) missing for islope data'
             print*,' Error: Static file not created'
             print*
             return
           else
             print*,' Warning: File(s) missing for islope data'
             print*,' Warning: islope not added to static file'
             print*
           endif
           GEODAT2D=r_missing_data
           GEODAT3D=r_missing_data
        endif

c put the categories back to the original raw data. if it is a land
c point but islope indicates water, force islope = 1.
        where(GEODAT2D .eq. 8)GEODAT2D=13.0
        where(GEODAT2D .eq. 9)GEODAT2D=0.0

        if(c10_grid_fname(1:lf).eq.'wrfsi')then
           islp=109
        else
           islp=38
        endif
        data(:,:,islp)=GEODAT2D
c
c Adjust geog data to conform to landuse data (the most
c accurate for defining land-water boundaries).
c Adjust soil temps to terrain elevations.
c
        print*,'Calling adjust_geog_data'

        if(c10_grid_fname(1:lf).eq.'wrfsi')then

           call adjust_geog_data(nnxp-1,nnyp-1,12,istatus_grn,
     &istatus_tmp,istatus_slp,lats(1,1,ns),data(1:nnxp-1,1:nnyp-1,
     &indxter),path_to_soiltemp_1deg,data(1:nnxp-1,1:nnyp-1,ilndmsk),
     &data(1:nnxp-1,1:nnyp-1,idst),GEODAT3D(1:nnxp-1,1:nnyp-1,:),
     &data(1:nnxp-1,1:nnyp-1,islp),istatus)

        else

           call adjust_geog_data(nnxp,nnyp,12,istatus_grn,
     &istatus_tmp,istatus_slp,lats(1,1,ns),data(1,1,indxter),
     &path_to_soiltemp_1deg, data(1,1,ilndmsk),data(1,1,idst),
     &GEODAT3D,data(1,1,islp),istatus)

        endif

        if(istatus.ne.1)then
           print*,' Warning: Processing incomplete: adjust_geog_data'
           if(c10_grid_fname(1:lf).eq.'wrfsi')then
              print*,'Error: wrfsi static file not generated'
              return
           endif
        endif

c force land points to have the correct (default) islope value.
        where(data(:,:,islp)   .eq. 0.0 .and.
     .        data(:,:,ilndmsk).eq. 1.0)data(:,:,islp)=1.0
c force water points to have the correct category for islope
        where(data(:,:,ilndmsk).eq. 0.0)data(:,:,islp)=0.0


c rewrite adjusted greenfrac into output array
        do j=1,12
           data(:,:,igrn+j)=GEODAT3D(:,:,j)
        enddo
c
c annual max/min greenness fraction in domain
c
        if(c10_grid_fname(1:lf).eq.'wrfsi')then
           print*,' compute max/min greenness frac at grid points'
           do j=1,nnyp
           do i=1,nnxp
              data(i,j,110)=MAXVAL(GEODAT3D(i,j,:))
              data(i,j,111)=MINVAL(GEODAT3D(i,j,:))
           enddo
           enddo
        endif
c
c ---------------Monthly Albedo Climatology--------------------------------
c type = A
c
        itstatus=ishow_timer()
        print*
        print*,' Processing albedo climo data'

        call proc_geodat(nnxp,nnyp,12,path_to_albedo
     +,lats(1,1,ns),lons(1,1,ns),data(1,1,ilndmsk)
     +,GEODAT3D,istatus_alb)

        print*,'Done in proc_geodat: albedo'

        if(istatus_alb.ne.1)then
         print*
         print*,' Error: Albedo climo data not processed completely'
         print*,' Error: File(s) missing for albedo data'
         print*,' Error: Static file not created: albedo missing'
         print*
         istatus=0
         return
        endif

c force water points to 0.08 albedo

        do k=1,12
           where(data(:,:,ilndmsk).eq.0.0)GEODAT3D(:,:,k)=0.08
        enddo

        if(c10_grid_fname(1:lf).eq.'wrfsi')then
           i=96
        else
           i=25
        endif
        do j=1,12
           data(:,:,i+j)=GEODAT3D(:,:,j)
        enddo
c
c ---------------- Max Snow Albedo ------------------
c type = M
c
        call proc_geodat(nnxp,nnyp,1,path_to_maxsnoalb
     +,lats(1,1,ns),lons(1,1,ns),data(1,1,ilndmsk)
     +,GEODAT2D,istatus_alb)

        print*,'Done in proc_geodat: Max Snow Albedo'

        if(istatus_alb.ne.1)then
         print*
         if(c10_grid_fname(1:lf).eq.'wrfsi')then
            print*,'--------------- WRFSI ------------------'
            print*,'Error: Max Snow Albedo not processed completely'
            print*,'Error: Static file not created '
            print*
            istatus=0
            return
         else
            print*,'Warning: Max Snow Albedo not processed completely'
         endif
        endif
c
c force max albedo = 0.08 over water. force max albedo = 0.7 over ice
c
        where(data(:,:,ilndmsk).eq.0.0)GEODAT2D=0.08
        where(data(:,:,ilnduse).eq.24.0)GEODAT2D=0.7

        if(c10_grid_fname(1:lf).eq.'wrfsi')then
           data(:,:,47)=GEODAT2D
        else
           data(:,:,6)=GEODAT2D
        endif

        deallocate (GEODAT2D)
        deallocate (GEODAT3D)

        allocate (var(ngrids), comment(ngrids))

        if(c10_grid_fname(1:lf).eq.'wrfsi')then

           in1=0
           in2=0
           do j=1,ns
              in1=in2+1
              in2=in1+1
              data(:,:,in1)=lats(:,:,j)
              data(:,:,in2)=lons(:,:,j)
           enddo


c compute map/grid information. Reallocate GEODAT3D array
           allocate (GEODAT3D(nnxp,nnyp,4))
           call get_projrot_grid(nnxp,nnyp,lats(1,1,ns)
     +,lons(1,1,ns),GEODAT3D,istatus)

           i=39

           data(:,:,i)  =GEODAT3D(:,:,1)
           data(:,:,i+1)=GEODAT3D(:,:,2)
 
           call get_map_factor_grid(nnxp,nnyp,n_staggers
     +,lats,lons ,GEODAT3D,istatus)
           if(istatus.ne.1)then
              print*,'Error returned: get_maps_factor_grid'
              return
           endif

           do j=1,ns
              data(:,:,i+j+1)=GEODAT3D(:,:,j)
           enddo
c           
           call get_coriolis_components(nnxp,nnyp,lats(1,1,ns)
     +,GEODAT3D)
           data(:,:,i+6)=GEODAT3D(:,:,1)
           data(:,:,i+7)=GEODAT3D(:,:,2)

           deallocate(GEODAT3D)

c          call move(static_albedo,data(1,1,i+8),nnxp,nnyp)

           call move(topt_out_s,data(1,1,i+9),nnxp,nnyp)
           call move(topt_out_ln,data(1,1,i+10),nnxp,nnyp)
           call move(topt_out_lt,data(1,1,i+11),nnxp,nnyp)
c          call move(topt_stag_out,data(1,1,i+12),nnxp,nnyp) !51

           call get_gridgen_var(ngrids,ngrids,var,comment)

        else

           call move(lats(1,1,1),data(1,1,1),nnxp,nnyp)            ! KWD
           call move(lons(1,1,1),data(1,1,2),nnxp,nnyp)            ! KWD
           call move(topt_out,data(1,1,3),nnxp,nnyp)               ! KWD
           call move(topt_out_s,data(1,1,7),nnxp,nnyp)             ! JS
           call move(topt_out_ln,data(1,1,8),nnxp,nnyp)            ! JS
           call move(topt_out_lt,data(1,1,9),nnxp,nnyp)            ! JS 

           call get_gridgen_var(ngrids,ngrids,var,comment)
 
        endif

        filename = c10_grid_fname(1:lf)//'.cdl'
        call s_len(filename,lfn)
        call get_directory('cdl',cdl_dir,lcdl)

        INQUIRE(FILE=cdl_dir(1:lcdl)//filename(1:lfn),EXIST=exist)

        if(.not.exist)then
           print*,'Error: Could not find file '
     +           ,cdl_dir(1:lcdl)//filename(1:lfn)
           print*,'c10_grid_fname: ',c10_grid_fname(1:lf)
           istatus = 0
           return
        endif

        call check_domain(lats(1,1,ns),lons(1,1,ns)
     +,nnxp,nnyp,grid_spacing_m,1,istat_chk)

        write(6,*)'deltax = ',deltax

        if(istat_chk .eq. 1)then
            write(6,*)'check_domain: status = ',istat_chk
        else
            write(6,*)'ERROR in check_domain: status = ',istat_chk       
        endif

        call put_laps_static(grid_spacing_m,model,comment,var
     1,data,nnxp,nnyp,ngrids,ngrids,std_lat,std_lat2,std_lon
     1,c6_maproj,deltax,deltay,nest)

        istatus = istat_chk

        itstatus=ishow_timer()
        print*,' -------------------------------'
        print*,' Total Elapsed time: ', itstatus
        print*,' -------------------------------'

        return
        End
c
c ================================================================
c
      SUBROUTINE GEODAT(n2,n3,erad,rlat,wlon1,xt,yt,deltax,deltay
     1 ,DATR,DATS,DATLN,DATLT,OFN,WVLN,SILWT,which_data,maxdatacat
     1 ,istat_files)

      include 'trigd.inc'

      implicit none


      integer n2,n3
      integer lbf
      integer lb,mof,np,niq,njq,nx,ny,isbego,iwbego,
     1  iblksizo,no,iodim,istat_files,maxdatacat

      real erad,rlat,wlon1,deltax,deltay,wvln,silwt

      real DATR(N2,N3)
      real DATS(N2,N3,maxdatacat)
      real DATLN(N2,N3)
      real DATLT(N2,N3)

c this parameter can be increased if we ever read data with
c resolution finer than 30 sec, or if the tilesize for 30s
c data becomes greater than 10x10 deg.

      PARAMETER(IODIM=5800000)

      real xt(N2),YT(N3)
      real deltallo,deltaxq,deltayq,
     1  deltaxp,deltayp

      real RSOFF,RWOFF

      real std_lon
      integer istatus
      integer lcat

      CHARACTER*(*) OFN
      character*180 TITLE
      logical which_data
C
c *********************
      nx=n2-1
      ny=n3-1
c ****************************

      lcat = 1
      LBF=INDEX(OFN,' ')-1
      TITLE=OFN(1:LBF)//'HEADER'


      LB=INDEX(TITLE,' ')-1

      CALL JCLGET(29,TITLE(1:LB),'FORMATTED',1,istat_files)
      if(istat_files .ne. 1)then
         write(6,*)' Warning in gridgen_model opening HEADER: '
     1,' geog path = ', title(1:lb)
         return
      endif

      READ(29,*)IBLKSIZO,NO,ISBEGO,IWBEGO,RSOFF,RWOFF
c 2    FORMAT(4I5,2(F10.8))
      print *,'title=',title
      print *,'rsoff,rwoff = ',rsoff,rwoff
      print *,'isbego,iwbego =',isbego,iwbego
      print *,'iblksizo,no =',iblksizo,no
      CLOSE(29)

      if(NO .gt. 1)then
         DELTALLO=FLOAT(IBLKSIZO)/FLOAT(NO-1)
      elseif(NO .eq. 1)then
         DELTALLO=FLOAT(IBLKSIZO)/FLOAT(NO)
      else
         print*,'HEADER value NO = 0'
         return
         istat_files = 0
      endif

      MOF=IODIM/(NO*NO)

      if(ofn(lbf:lbf).eq.'G'.or.ofn(lbf:lbf).eq.'A')then
         lcat=12
         if(no.eq.1250)then
            MOF=1
         endif
      endif
c SG97 MOF determines the number of files held in buffer while reading
c SG97 DEM data; it saves some time when buffer data can be used instead
c SG97 of reading DEM file again. Originally MOF was 4.
      if (MOF.gt.10) MOF=5
      
      DELTAXQ=0.5*WVLN*DELTAX
      DELTAYQ=0.5*WVLN*DELTAY
      print *,'deltaxq,deltayq=',deltaxq,deltayq
      NP=MIN(10,MAX(1,INT(DELTAXQ/(DELTALLO*111000.))))
      print *,' np=',np
      DELTAXP=DELTAXQ/FLOAT(NP)
      DELTAYP=DELTAYQ/FLOAT(NP)
      NIQ=INT(FLOAT(NX)*DELTAX/DELTAXQ)+4
      NJQ=INT(FLOAT(NY)*DELTAY/DELTAYQ)+4
C
      call get_standard_longitude(std_lon,istatus)
      if(istatus .ne. 1)then
          write(6,*)' Error calling laps routine'
          stop 
      endif

      CALL SFCOPQR(NO,MOF,NP,NIQ,NJQ,N2,N3,lcat
     +,XT,YT,90.,std_lon,ERAD,RWOFF,RSOFF
     +,DELTALLO,DELTAXP,DELTAYP,DELTAXQ,DELTAYQ
     +,IBLKSIZO,ISBEGO,IWBEGO,DATR,DATS,DATLN,DATLT
     +,OFN,WVLN,SILWT,which_data,maxdatacat,istat_files)       
      RETURN
      END


C
C     ******************************************************************
C
      SUBROUTINE SFCOPQR(NO,MOF,NP,NIQ,NJQ,N2,N3,lcat
     +          ,XT,YT,RLAT,WLON1,ERAD,RWOFF,RSOFF
     +          ,DELTALLO,DELTAXP,DELTAYP,DELTAXQ,DELTAYQ
     +          ,IBLKSIZO,ISBEGO,IWBEGO,DATR,DATS,DATLN,DATLT
     +          ,OFN,WVLN,SILWT,dem_data,maxdatacat,istat_files)

c JS: removed dato array from subroutine argument list
c JS: added RWOFF/RSOFF - West and South offset of tile data

      real,  allocatable ::  dato(:,:,:,:)    !dato(no,no,mof,lcat)

      real,  allocatable ::  DATP(:,:,:)
      real,  allocatable ::  DATQ(:,:)
      real,  allocatable ::  DATQS(:,:,:)
      real,  allocatable ::  DATSM(:,:)
      real,  allocatable ::  DATSMX(:,:)
      real,  allocatable ::  DATSLN(:,:)
      real,  allocatable ::  DATSLT(:,:)

      real,  intent(inout) ::  DATLN(N2,N3)  !also used as input landmask for
      real,  intent(out)   ::  DATLT(N2,N3)
      real,  intent(out)   ::  DATR(N2,N3)
      real,  intent(out)   ::  DATS(N2,N3,maxdatacat)

      real ISO(MOF),IWO(MOF),XT(N2),YT(N3),rlat,wlon1,
     +     erad,deltallo,deltaxp,deltayp,deltaxq,deltayq,
     +     wvln,silwt,xq,yq,xp,yp,xcentr,ycentr,glatp,               ! pla,plo,
     +     glonp,rio,rjo,wio2,wio1,wjo2,wjo1,xq1,yq1,
     +     rwoff,rsoff

      real r_missing_data
      real xr,yr,rval,sh,sha,rh,rha,rhn,rht,shn,sht
      real shln,shlt,rhln,rhlt
      real delta_ln(np,np),delta_lt(np,np)

c     real xpmn,xpmx,ypmn,ypmx
      real xp1,xp2,yp1,yp2
      real xpcentr,ypcentr

      real  pctcat(maxdatacat)

      integer lp
      integer ixr,iyr
      integer lent

      CHARACTER*180 OFN
      CHARACTER*180 TITLE3,TITLE3_last_read,TITLE3_last_inquire
      CHARACTER*3   TITLE1
      CHARACTER*4   TITLE2
      CHARACTER*10  cdatatype

      LOGICAL L1,L2,dem_data,l_string_contains

      data icnt/0/
      save icnt
C
      print *,'no,mof,np,niq,njq=',no,mof,np,niq,njq

      istat_files = 1

      NONO=NO*NO
      XCENTR=0.5*(XT(1)+XT(N2))
      YCENTR=0.5*(YT(1)+YT(N3))
      print *,xt(1),xt(n2),xcentr
      print *,'deltaxp=',deltaxp
      NOFR=0
      DO 11 IOF=1,MOF
         ISO(IOF)=0
         IWO(IOF)=0
  11  continue

      TITLE3_last_read    = '/dev/null'
      TITLE3_last_inquire = '/dev/null'


      lcat=1
      len=index(ofn,' ')
      if(ofn(len-1:len-1).eq.'V'.or.
     &   ofn(len-1:len-1).eq.'I')then
         icnt = 0
         cdatatype='landuse'
         if(ofn(len-1:len-1).eq.'I')cdatatype='islope'
      elseif(ofn(len-1:len-1).eq.'O')then
         icnt = 0
         cdatatype='soiltype'
      elseif(ofn(len-1:len-1).eq.'U' .or.
     &       ofn(len-1:len-1).eq.'H')then
         cdatatype='topography'
      endif

      print*,'SFCOPQR: cdatatype = ',cdatatype

      call s_len(cdatatype,lent)

      allocate(dato(no,no,mof,lcat))

      allocate (DATP(NP,NP,lcat),
     &          DATQ(NIQ,NJQ),
     &          DATSM(NIQ,NJQ),
     &          DATSMX(NIQ,NJQ),
     &          DATSLN(NIQ,NJQ),
     &          DATSLT(NIQ,NJQ),
     &          DATQS(NIQ,NJQ,maxdatacat))

      call get_r_missing_data(r_missing_data,istatus)
      if(istatus.ne.1)then
         print*,'failed to get r_missing_data'
         return
      endif

      DO 15 JQ=1,NJQ
         print *,'jq,njq,niq=',jq,njq,niq
         DO 16 IQ=1,NIQ

            XQ=(FLOAT(IQ)-0.5*FLOAT(NIQ+1))*DELTAXQ+XCENTR
            YQ=(FLOAT(JQ)-0.5*FLOAT(NJQ+1))*DELTAYQ+YCENTR

            xpmn=1.0e30
            ypmn=1.0e30
c           xpmx=-1.0e30
c           ypmx=-1.0e30

            DO 17 JP=1,NP
               DO 18 IP=1,NP

                  XP=XQ+(FLOAT(IP)-0.5*FLOAT(NP+1))*DELTAXP
                  YP=YQ+(FLOAT(JP)-0.5*FLOAT(NP+1))*DELTAYP
!                 CALL XYTOPS(XP,YP,PLA,PLO,ERAD)
!                 CALL PSTOGE(PLA,PLO,GLATP,GLONP,rlat,wlon1)

c                 call xy_to_latlon(XP,YP,erad,rlat,wlon1,GLATP,GLONP) 

                  call xy_to_latlon(XP,YP,erad,GLATP,GLONP) 

                  glatp = max(-89.9999,min(89.9999,glatp - rsoff))
                  glonp = glonp - rwoff
                  if(glonp.ge.180.) glonp = glonp - 360.
                  if(glonp.le.-180.) glonp = glonp + 360.

c                 print *,'rlat,wlon1=',rlat,wlon1

                  ISOC=(INT((GLATP-FLOAT(ISBEGO))/FLOAT(IBLKSIZO)
     &          +200.)-200)*IBLKSIZO+ISBEGO
            IWOC=(INT((GLONP-FLOAT(IWBEGO))/FLOAT(IBLKSIZO)
     &          +400.)-400)*IBLKSIZO+IWBEGO

                  DO 19 IOFR=1,NOFR
                     JOFR=IOFR
                     IF(ISO(IOFR).EQ.ISOC.AND.IWO(IOFR).EQ.IWOC)GO TO 10
 19                 continue
                  ISOCPT=ABS(ISOC)/10
                  ISOCPO=ABS(ISOC)-ISOCPT*10
                  IWOCPH=ABS(IWOC)/100
                  IWOCPT=(ABS(IWOC)-IWOCPH*100)/10
                  IWOCPO=ABS(IWOC)-IWOCPH*100-IWOCPT*10
                  IF(ISOC.GE.0)THEN
                     WRITE(TITLE1,'(2I1,A1)')ISOCPT,ISOCPO,'N'
                  ELSE
                     WRITE(TITLE1,'(2I1,A1)')ISOCPT,ISOCPO,'S'
                  ENDIF

                  IF(IWOC.GE.0 
     1               .and. IWOC .ne. 180                    ! 1998 Steve Albers
     1                                      )THEN
                     WRITE(TITLE2,'(3I1,A1)')IWOCPH,IWOCPT,IWOCPO,'E'
                  ELSE
                     WRITE(TITLE2,'(3I1,A1)')IWOCPH,IWOCPT,IWOCPO,'W'
                  ENDIF

                  LB=INDEX(OFN,' ')-1
                  TITLE3=OFN(1:LB)//TITLE1//TITLE2
                  LB=INDEX(TITLE3,' ')-1

                  if(TITLE3 .ne. TITLE3_last_inquire)then
                     INQUIRE(FILE=TITLE3(1:LB),EXIST=L1,OPENED=L2)
                     TITLE3_last_inquire = TITLE3
                  endif

                  IF(.NOT.L1)THEN
                     iwrite = 0

                     if(icnt .le. 100)then ! Reduce the output
                         iwrite=1

                     elseif(icnt .le. 1000)then
                         if(icnt .eq. (icnt/100)*100)iwrite=1

                     elseif(icnt .le. 10000)then
                         if(icnt .eq. (icnt/1000)*1000)iwrite=1

                     elseif(icnt .le. 100000)then
                         if(icnt .eq. (icnt/10000)*10000)iwrite=1

                     else
                         if(icnt .eq. (icnt/100000)*100000)iwrite=1

                     endif

                     if(iwrite .eq. 1)then
                        if(l_string_contains(TITLE3(1:LB),
     1                                       'world_topo_30s',
     1                                       istatus)             )then       
                           PRINT*, ' ERROR: ',TITLE3(1:LB)
     1                            ,' DOES NOT EXIST ',icnt

                        elseif(l_string_contains(TITLE3(1:LB),
     1                                           'topo_30s',
     1                                       istatus)             )then       
                           PRINT*, ' topo_30s file ',TITLE3(1:LB)
     1                            ,' does not exist, using topo_10m '
     1                            ,icnt

                        else ! Generic warning message
                           PRINT*, ' WARNING: ',TITLE3(1:LB)
     1                            ,' DOES NOT EXIST ',icnt

                        endif

                     endif ! iwrite

                     icnt = icnt + 1

c initialize these arrays as they may have some garbage in them
c if we don't actually read in any data.
c
                     DATP(IP,JP,:) = 0.
                     DELTA_LN(IP,JP) = 0.
                     DELTA_LT(IP,JP) = 0.
                     istat_files = 0
                     GO TO 20

                  ENDIF

                  IF(NOFR.GE.MOF)THEN
                     DO 21 IOF=1,MOF
                        ISO(IOF)=0
                        IWO(IOF)=0
21                    continue
                     NOFR=0
                  ENDIF
                  NOFR=NOFR+1
                  JOFR=NOFR

!                 Read the tile
                  if(TITLE3 .ne. TITLE3_last_read)then
                    if( (ofn(len-1:len).eq.'U').and.(no.eq.1200).or.
     .                   no.eq.1201 )then
                         if(no.eq.1201)then
                            print*,'Reading ', title3(1:lb)
                            CALL READ_DEM(29,TITLE3(1:LB),no,no,4,4, ! topo_3s experimental
     .                              DATO(1,1,NOFR,1))
                         else
                            CALL READ_DEM(29,TITLE3(1:LB),no,no,2,2, ! world topo_30s
     .                              DATO(1,1,NOFR,1))
                         endif
                      dem_data=.true.
                    elseif( (ofn(len-1:len).eq.'O') )then      ! soiltype top and bot layer
                      CALL READ_DEM(29,TITLE3(1:LB),no,no,1,4,
     .                              DATO(1,1,NOFR,1))
                      dem_data=.true.
                    elseif( (ofn(len-1:len).eq.'V') )then      ! world USGS 30s landuse
                      CALL READ_DEM(29,TITLE3(1:LB),no,no,1,4,
     .                              DATO(1,1,NOFR,1))
                      dem_data=.true.
                    elseif( (ofn(len-1:len).eq.'G').or.
     .                      (ofn(len-1:len).eq.'I').or.
     .                      (ofn(len-1:len).eq.'A') )then      ! greenfrac/albedo/islope
                      CALL READ_DEM_G(29,TITLE3(1:LB),no,no,mof,lcat
     .                     ,nofr, 1,4, DATO,istat)
                         if(istat.ne.0)then
                            print*,'Error returned from READ_DEM_G'
                            return
                         endif
                         dem_data=.true.
                    elseif( (ofn(len-1:len).eq.'T') )then      ! soiltemp
                      CALL READ_DEM(29,TITLE3(1:LB),no,no,2,2,
     .                              DATO(1,1,NOFR,1))
                      dem_data=.true.
                    else                                       ! other
                      CALL JCLGET(29,TITLE3(1:LB),'FORMATTED',0,istatus)      
                      CALL VFIREC(29,DATO(1,1,NOFR,1),NONO,'LIN')
                      if ((ofn(len-1:len).eq.'U').and.(no.eq.121)) then
                        dem_data=.false.                       ! topo_30s
                      endif
                    endif

                    TITLE3_last_read = TITLE3

c                   print *,'nofr,dato=',nofr,dato(1,1,nofr)
                    CLOSE(29)

                  else
                    write(6,*)' We have made the code more efficient'

                  endif ! Is this a new file we haven't read yet?

                  ISO(NOFR)=ISOC
                  IWO(NOFR)=IWOC
10		  continue

                  RIO=(GLONP-FLOAT(IWOC))/DELTALLO+1.
                  RJO=(GLATP-FLOAT(ISOC))/DELTALLO+1.

!                 Prevent Bounds Error (Steve Albers)
                  if(RIO .lt. 1.0)then
                      if(RIO .gt. 0.98)then
                          write(6,*)' Reset RIO for Machine Epsilon'      
                          RIO = 1.0
                      elseif(RIO .lt. 0.5)then
                          write(6,*)' ERROR: RIO out of bounds',RIO
                          stop
                      endif
                  endif

                  if(RJO .lt. 1.0)then
                      if(RJO .gt. 0.98)then
                          write(6,*)' Reset RJO for Machine Epsilon'      
                          write(6,*)JQ,IQ,
     1                          IP,JP,IO1,JO1,JOFR,RIO,RJO,GLATP,ISOC
                          RJO = 1.0
                      elseif(RJO .lt. 0.5)then
                          write(6,*)' ERROR: RJO out of bounds',RJO
                          write(6,*)JQ,IQ,
     1                          IP,JP,IO1,JO1,JOFR,RIO,RJO,GLATP,ISOC
                          stop
                      endif
                  endif

C Interp OK for continuous data such as topo and landfrac

                  if(cdatatype.eq.'topography'.or.
     &               cdatatype.eq.'landfrac' )then

                   IO1=INT(RIO)
                   JO1=INT(RJO)
                   IO2=IO1+1
                   JO2=JO1+1
                   WIO2=RIO-FLOAT(IO1)
                   WJO2=RJO-FLOAT(JO1)
                   WIO1=1.0-WIO2
                   WJO1=1.0-WJO2

                   do LP = 1,lcat

                   DATP(IP,JP,LP)=WIO1*(WJO1*DATO(IO1,JO1,JOFR,LP)
     +                                 +WJO2*DATO(IO1,JO2,JOFR,LP))
     +                           +WIO2*(WJO1*DATO(IO2,JO1,JOFR,LP)
     +                                 +WJO2*DATO(IO2,JO2,JOFR,LP))

!S & W-facing slopes > 0.
                   DELTA_LN(IP,JP)=
     .           ((DATO(IO2,JO1,JOFR,LP)-DATO(IO1,JO1,JOFR,LP))+
     .            (DATO(IO2,JO2,JOFR,LP)-DATO(IO1,JO2,JOFR,LP)))*.5

                   DELTA_LT(IP,JP)=
     .           ((DATO(IO1,JO2,JOFR,LP)-DATO(IO1,JO1,JOFR,LP))+
     .            (DATO(IO2,JO2,JOFR,LP)-DATO(IO2,JO1,JOFR,LP)))*.5

                   enddo !LP = 1,lcat

                  else

C Nearest grid point for landfrac, landuse, soiltype, soiltemp

                   IO1=NINT(RIO)
                   JO1=NINT(RJO)
                   do LP = 1,lcat
                    DATP(IP,JP,LP)= DATO(IO1,JO1,JOFR,LP)
                   enddo

                  endif ! cdatatype eq topography or landfrac
                   
20               CONTINUE
18             continue ! IP
17           continue ! JP


!           print*,'xpmx/xpmn//ypmx/ypmn/ ',xpmx,xpmn,ypmx,ypmn

! Calculate average and silhouette terrain, then apply SILWT weight

            if(cdatatype(1:lent).eq.'topography'.or.
     &         cdatatype(1:lent).eq.'soiltemp'   )then


             SHA=0.
             RHA=0.
             RHLN=0.
             RHLT=0.
             shmax=0.

             DO 22 JP=1,NP
               SH=0.
               RH=0.
               RHN=0.
               RHT=0.
               DO 23 IP=1,NP
!                 Test for missing - then go to 16?
                  SH=max(SH,DATP(IP,JP,1)) 
                  RH=RH+DATP(IP,JP,1)
                  RHN=RHN+DELTA_LN(IP,JP)
                  RHT=RHT+DELTA_LT(IP,JP)
23             continue ! IP
               SHA=SHA+SH/(2.*FLOAT(NP))
               RHA=RHA+RH
               RHLN=RHLN+RHN
               RHLT=RHLT+RHT
               SHMAX=max(SHMAX,SH)
22           continue ! JP
 
             RHA=RHA/FLOAT(NP*NP)
             RMS=0.0
             DO 24 IP=1,NP 
               SH=0.
               DO 25 JP=1,NP
                  SH=max(SH,DATP(IP,JP,1))
                  RMS=RMS+((DATP(IP,JP,1)-RHA)*(DATP(IP,JP,1)-RHA))
25             continue ! JP
               SHA=SHA+SH/(2.*FLOAT(NP))
24           continue ! IP

             DATQS(IQ,JQ,1)=SQRT(RMS/FLOAT(NP*NP))
             DATQ(IQ,JQ)=SHA*SILWT+RHA*(1.-SILWT)
             DATSM(IQ,JQ)=RHA                           !mean value of points used for IQ,JQ
             DATSMX(IQ,JQ)=SHMAX                        !max value from points used for IQ,JQ
             DATSLN(IQ,JQ)=RHLN/FLOAT(NP*NP)/DELTAXP
             DATSLT(IQ,JQ)=RHLT/FLOAT(NP*NP)/DELTAYP

c            print *,'datq=',datq(iq,jq)

            elseif(cdatatype(1:lent).eq.'islope'    .or.
     &             cdatatype(1:lent).eq.'landuse'   .or.
     &             cdatatype(1:lent).eq.'soiltype'    )then

             call compute_categories(cdatatype,np*np,DATP(1,1,1)
     &               ,maxdatacat,domcat,pctcat)
             datq(iq,jq)=domcat 
             datqs(iq,jq,:)=pctcat(:)

            elseif(cdatatype(1:lent).eq.'greenfrac'   )then

c dominant greenness fraction for each month

             do lp=1,lcat
              call compute_categories(cdatatype,np*np,DATP(1,1,lp)
     &                               ,1,domcat,pctcat)
              datqs(iq,jq,lp)=domcat
             enddo

            endif

16       continue ! IQ
15    continue ! JQ

      print *,'after 15'
 
      XQ1=(1.-0.5*FLOAT(NIQ+1))*DELTAXQ+XCENTR
      YQ1=(1.-0.5*FLOAT(NJQ+1))*DELTAYQ+YCENTR

      if(cdatatype(1:lent).eq.'topography')then

        print*
        print*,'Before GDTOST2'
        print*,'--------------'
        print*,'datq(1,1)/(niq,njq)= ',datq(1,1),datq(niq,njq)
        print*,'datqs(1,1,1)/(niq,njq)= ',datqs(1,1,1),datqs(niq,njq,1)
        print*,'datsln(1,1)/(niq,njq)= ',datsln(1,1),datsln(niq,njq)
        print*,'datslt(1,1)/(niq,njq)= ',datslt(1,1),datslt(niq,njq)
        print*,'Mean/Max topo at IQ,JQ (1,1)/(niq,njq): '
     +,datsm(1,1),datsmx(1,1),datsm(niq,njq),datsmx(niq,njq)

        DO 28 JR=1,N3
         DO 29 IR=1,N2
           XR=(XT(IR)-XQ1)/DELTAXQ+1.
           YR=(YT(JR)-YQ1)/DELTAYQ+1.

           CALL GDTOST2(DATQ,NIQ,NJQ,XR,YR,RVAL)
           DATR(IR,JR)=max(0.,RVAL)
           if( DATR(IR,JR).gt.30000. )then
               print*,'Warning: value out of bounds'
           endif    

           CALL GDTOST2(DATQS,NIQ,NJQ,XR,YR,RVAL)
           DATS(IR,JR,1)=max(0.,RVAL)
           CALL GDTOST2(DATSLN,NIQ,NJQ,XR,YR,RVAL)
           DATLN(IR,JR)=RVAL
           CALL GDTOST2(DATSLT,NIQ,NJQ,XR,YR,RVAL)
           DATLT(IR,JR)=RVAL

 29      CONTINUE
 28     CONTINUE

        print*,'After GDTOST2'
        print*,'-------------'
        print*,'datr(1,1)/(n2,n3)= ',datr(1,1),datr(N2,N3)
        print*,'dats(1,1,1)/(n2,n3)= ',dats(1,1,1),dats(n2,n3,1)
        print*,'datln(1,1)/(n2,n3)= ',datln(1,1),datln(n2,n3)
        print*,'datlt(1,1)/(n2,n3)= ',datlt(1,1),datlt(n2,n3)
 
      elseif(cdatatype(1:lent).eq.'landuse'.or.
     +       cdatatype(1:lent).eq.'islope' .or.
     +       cdatatype(1:lent).eq.'soiltype')then

        DO 38 JR=1,N3
         DO 39 IR=1,N2
            IXR=NINT((XT(IR)-XQ1)/DELTAXQ)+1.
            IYR=NINT((YT(JR)-YQ1)/DELTAYQ)+1.
            if(ixr.lt.1)ixr=1
            if(iyr.lt.1)iyr=1
            if(ixr.gt.n2)ixr=niq
            if(iyr.gt.n3)iyr=njq

            datr(ir,jr)=  datq(ixr,iyr)     !dominant category
            dats(ir,jr,:)=datqs(ixr,iyr,:)  !percent dist for ea category

 39      CONTINUE
 38     CONTINUE

      endif

      deallocate(dato)
      deallocate(DATP,
     &           DATQ,
     &           DATQS,
     &           DATSM, 
     &           DATSMX,
     &           DATSLN,
     &           DATSLT)

      RETURN
      END

      SUBROUTINE GDTOST2(A,IX,IY,STAX,STAY,STAVAL)
*  SUBROUTINE TO RETURN STATIONS BACK-INTERPOLATED VALUES(STAVAL)
*  FROM UNIFORM GRID POINTS USING OVERLAPPING-QUADRATICS.
*  GRIDDED VALUES OF INPUT ARRAY A DIMENSIONED A(IX,IY),WHERE
*  IX=GRID POINTS IN X, IY = GRID POINTS IN Y .  STATION
*  LOCATION GIVEN IN TERMS OF GRID RELATIVE STATION X (STAX)
*  AND STATION COLUMN.
*  VALUES GREATER THAN 1.0E30 INDICATE MISSING DATA.
*
      real A(IX,IY),R(4),SCR(4),stax,stay,staval
     +  ,fixm2,fiym2,yy,xx
      IY1=INT(STAY)-1
      IY2=IY1+3
      IX1=INT(STAX)-1
      IX2=IX1+3
      STAVAL=1E30
      FIYM2=FLOAT(IY1)-1
      FIXM2=FLOAT(IX1)-1
      II=0
      DO 100 I=IX1,IX2
      II=II+1
      IF(I.GE.1.AND.I.LE.IX) GO TO 101
      SCR(II)=1E30
      GO TO 100
101   JJ=0
      DO 111 J=IY1,IY2
      JJ=JJ+1
      IF(J.GE.1.AND.J.LE.IY) GO TO 112
      R(JJ)=1E30
      GO TO 111
112   R(JJ)=A(I,J)
111   CONTINUE
      YY=STAY-FIYM2
      CALL BINOM(1.,2.,3.,4.,R(1),R(2),R(3),R(4),YY,SCR(II))
100   CONTINUE
      XX=STAX-FIXM2
      CALL BINOM(1.,2.,3.,4.,SCR(1),SCR(2),SCR(3),SCR(4),XX,STAVAL)
      RETURN
      END
c
cc ------------------------------------------------------------------
c
      subroutine vfirec(iunit,a,n,type)
      character*1 vc
      character*(*) type
      common/vform/vc(0:63)
      character line*80, cs*1
      dimension a(*)

      if(vc(0).ne.'0') call vfinit

      ich0=ichar('0')
      ich9=ichar('9')
      ichcz=ichar('Z')
      ichlz=ichar('z')
      ichca=ichar('A')
      ichla=ichar('a')
      
      read(iunit,10)nn,nbits,bias,fact
 10   format(2i8,2e20.10)
      if(nn.ne.n) then
         print*,' Word count mismatch on vfirec record '
         print*,' Words on record - ',nn
         print*,' Words expected  - ',n
         stop 'vfirec'
      endif

      nvalline=(78*6)/nbits
      nchs=nbits/6
      do 20 i=1,n,nvalline
         read(iunit,'(a78)') line
         ic=0
         do 30 ii=i,i+nvalline-1
            isval=0
            if(ii.gt.n) go to 20
            do 40 iii=1,nchs
               ic=ic+1
               cs=line(ic:ic)
               ics=ichar(cs)
               if(ics.le.ich9)then
                  nc=ics-ich0
               elseif(ics.le.ichcz) then
                  nc=ics-ichca+10
               else
                  nc=ics-ichla+36
               endif
               isval=ior(ishft(nc,6*(nchs-iii)),isval)
 40         continue
            a(ii)=isval
 30      continue
 20   continue

      facti=1./fact
      if(type.eq.'LIN') then
         do 48 i=1,n
            a(i)=a(i)*facti-bias
 48      continue
      elseif(type.eq.'LOG') then
         scfct=2.**(nbits-1)
         do 55 i=1,n
            a(i)=sign(1.,a(i)-scfct)
     +           *(10.**(abs(20.*(a(i)/scfct-1.))-10.))
 55      continue
      endif

      return
      end
c
cc ------------------------------------------------------------------
c
      subroutinevfinit                                                  
      character*1vc,vcscr(0:63)                                         
      common/vform/vc(0:63)                                             
      datavcscr/'0','1','2','3','4','5','6','7','8','9'                 
     +,'A','B','C','D','E','F','G','H','I','J'                          
     +,'K','L','M','N','O','P','Q','R','S','T'                          
     +,'U','V','W','X','Y','Z','a','b','c','d'                          
     +,'e','f','g','h','i','j','k','l','m','n'                          
     +,'o','p','q','r','s','t','u','v','w','x'                          
     +,'y','z','{','|'/                                                 
                                                                        
      do10n=0,63                                                        
      vc(n)=vcscr(n)                                                    
  10  continue                                                          
                                                                        
      return                                                            
      end
C +------------------------------------------------------------------+
      FUNCTION INTLSHFT(IWORD,NSHFT)
C
C       This function shifts IWORD to the left NSHFT bits in a
C         circular manner.
C
      INTLSHFT=ISHFT(IWORD,NSHFT)
      RETURN
      END
C +------------------------------------------------------------------+
      FUNCTION INTOR(IWORD1,IWORD2)
C
C       This function performs a bit-by-bit OR between IWORD1 and
C         IWORD2.
C
      INTOR=IOR(IWORD1,IWORD2)
      RETURN
      END


      SUBROUTINE BINOM2(X1,X2,X3,X4,Y1,Y2,Y3,Y4,XXX,YYY)
      implicit none
      real x1,x2,x3,x4,y1,y2,y3,y4,xxx,yyy,
     +   wt1,wt2,yz22,yz23,yz24,yz11,yz12,yz13,yoo
      integer istend
c      COMMON/BIN/ITYPP,I0X,I1X,I2X,YOO
       YYY=1E30
       IF(X2.GT.1.E19.OR.X3.GT.1.E19.OR.
     +   Y2.GT.1.E19.OR.Y3.GT.1.E19)RETURN
      WT1=(XXX-X3)/(X2-X3)
      WT2=1.0-WT1
      ISTEND=0
      IF(Y4.LT.1.E19.AND.X4.LT.1.E19) GO TO 410
      YZ22=WT1
      YZ23=WT2
      YZ24=0.0
      ISTEND= 1
410   IF(Y1.LT.1.E19.AND.X1.LT.1.E19) GO TO 430
      YZ11=0.0
      YZ12=WT1
      YZ13=WT2
      IF(ISTEND.EQ.1)GO TO 480
      GO TO 450
430   YZ11=(XXX-X2)*(XXX-X3)/((X1-X2)*(X1-X3))
      YZ12=(XXX-X1)*(XXX-X3)/((X2-X1)*(X2-X3))
      YZ13=(XXX-X1)*(XXX-X2)/((X3-X1)*(X3-X2))
      IF(ISTEND.EQ.  1    ) GO TO 470
450   YZ22=(XXX-X3)*(XXX-X4)/((X2-X3)*(X2-X4))
      YZ23=(XXX-X2)*(XXX-X4)/((X3-X2)*(X3-X4))
      YZ24=(XXX-X2)*(XXX-X3)/((X4-X2)*(X4-X3))
470   YYY=WT1*(YZ11*Y1+YZ12*Y2+YZ13*Y3)+WT2*(YZ22*Y2+YZ23*Y3+YZ24*Y4)
       GO TO 490
480      YYY=WT1*Y2+WT2*Y3
490   YOO=YYY
      RETURN
      END
c
c determine dominant category 1-05-01 JS
c

      subroutine compute_categories(ctype,nnp,data,nlcat,domcat
     +,pctcat)

      implicit none

      character*(*) ctype

      integer nnp
      integer igc
      integer i,j,k
      integer nlcat
      integer maxcat
      integer lcat(nlcat)
      real    pctcat(nlcat)
      real    data(nnp)
      real    domcat
      real    sum_g

c categorical data types
      if(ctype.eq.'landuse'   .or.
     +   ctype.eq.'soiltype'  .or.
     +   ctype.eq.'islope'  )then

         do k=1,nlcat
            lcat(k)=0
            pctcat(k)=0.
         enddo

         do i=1,nnp
         do k=1,nlcat
            if(nint(data(i)).eq.k)then
               lcat(k)=lcat(k)+1
            endif
         enddo
         enddo

         maxcat=-1
         do k=1,nlcat
            pctcat(k)=lcat(k)/float(nnp)
            if(lcat(k).gt.maxcat)then
               maxcat=lcat(k)
               domcat=float(k)
            endif
         enddo
         if(ctype.eq.'landuse')then
          if(domcat.eq.16.and.pctcat(16).lt.0.5)then
            maxcat=-1
            do k=1,nlcat
               if(k.ne.16)then
                  if(lcat(k).gt.maxcat)then
                     maxcat=lcat(k)
                     domcat=float(k)
                  endif
               endif
            enddo
          endif
         endif

c quantitative data types
      elseif(ctype.eq.'greenfrac'.or.ctype.eq.'soiltemp')then

         sum_g=0.
         igc=0
         do i=1,nnp
          if(data(i).gt.0.0)then
             sum_g=sum_g+data(i)
             igc = igc+1
          endif
         enddo
         if(igc.gt.0)then
            domcat=sum_g/float(igc)
         else
            domcat=0.0
         endif

      endif

      return
      end
c
c ----------------------------------------------------------
c
      subroutine adjust_geog_data(nnxp,nnyp,ncat
     &,istatgrn,istattmp,istatslp,lat,topt_out,path_to_soiltemp
     &,landmask,soiltemp_1deg,greenfrac,islope,istatus)
c
c This routine uses landmask to refine the course resolution
c soil temp and green fraction data to conform to water-land
c boundaries. It also fills small islands or isolated land
c bodies with appropriate temp or green frac values as necessary
c J. Smart NOAA/FSL  6-22-01
c
      implicit none

      integer nnxp,nnyp
      integer i,j,l,ii,jj
      integer is,js
      integer istatus
      integer istatgrn
      integer istattmp
      integer istatslp
      integer ijsthresh
      integer isum
      integer l1,l2
      integer lent
      integer ncat

      integer isc
      integer ic(ncat) 

      character*(*) path_to_soiltemp

      logical endsearch

      real,intent(inout)  ::    lat(nnxp,nnyp)
      real,intent(inout)  ::    landmask(nnxp,nnyp)
      real,intent(inout)  ::    topt_out(nnxp,nnyp)
      real,intent(inout)  ::    soiltemp_1deg(nnxp,nnyp)
      real,intent(inout)  ::    greenfrac(nnxp,nnyp,ncat)
      real,intent(inout)  ::    islope(nnxp,nnyp)

      real,   allocatable ::    grnfrctmp     (:,:,:)
      real,   allocatable ::    soiltmp       (:,:)
      real,   allocatable ::    islopetmp     (:,:)
      real,   allocatable ::    rmeanlattemp  (:)

      real    avgtmp
      real    avggrn(ncat)
      real    avgslpcat
      real    tatlmx,tatlmn
      real    rlatmx,rlatmn
      real    r_missing_data
      real    rmngrn
      real    islp
      real    sumt
      real    sumg
      real    sum(ncat)
      real    tslp

      istatus=0
      if(istatgrn.eq.0.and.istattmp.eq.0.and.istatslp.eq.0)then
	 print*,'Unable to process greenfrac soiltemp or slp ',
     &'in adjust_geog ... no data'
	 return
      endif


c use moist adiabatic laps rate (6.5 deg/km) to get new temp
 
      allocate (grnfrctmp(nnxp,nnyp,ncat),
     &          soiltmp(nnxp,nnyp),
     &          islopetmp(nnxp,nnyp))

      call get_r_missing_data(r_missing_data,istatus)

      soiltmp=soiltemp_1deg
      grnfrctmp=greenfrac
      islopetmp=islope

      where(grnfrctmp.eq.0.0)grnfrctmp=r_missing_data
      rmngrn=minval(grnfrctmp(1:nnxp,1:nnyp,1:1))
      print*,'minimum green fraction = ',rmngrn
      where(soiltmp.eq.0.0)soiltmp=r_missing_data
      where(islopetmp.eq.0.0)islopetmp=r_missing_data

c determine average soiltemp and greenfrac in domain
      sumt=0.0
      sum=0.0
      isc=0
      ic=0
      do j = 1,nnyp
      do i = 1,nnxp
         if(soiltmp(i,j).ne. r_missing_data)then
            sumt=soiltmp(i,j)+sumt
            isc=isc+1
         endif

c greenfrac is assumed to be continuous globally; only use land points
         if(rmngrn.lt.r_missing_data)then
            do l=1,ncat
               if(landmask(i,j) .ne. 0 .and.
     &            grnfrctmp(i,j,l).lt.r_missing_data)then
                  sum(l)=grnfrctmp(i,j,l)+sum(l)
                  ic(l)=ic(l)+1
               endif
            enddo
         endif
         if(islopetmp(i,j).ne. r_missing_data)then
            isum=islopetmp(i,j)+isum
            islp=islp+1
         endif

      enddo
      enddo

      if(isc.gt.0)then
         avgtmp=sumt/float(isc)
      else
         sumt=0.0
         print*,'*** Using mean lat temps -> LATMEANTEMP ***'
         allocate (rmeanlattemp(180))
         call  get_directory_length(path_to_soiltemp,lent)
         call  get_meanlattemp(path_to_soiltemp(1:lent-1)
     &,rmeanlattemp,istatus)
         if(istatus.ne.1)then
            print*,'Error returned: get_meanlattemp'
            return
         endif
         l1=90-nint(minval(lat(:,1)))+1
         l2=90-nint(maxval(lat(:,nnyp)))+1
         if(l1.gt.180)l1=180
         if(l2.gt.180)l2=180

!        avgtmp=(rmeanlattemp(l1)+rmeanlattemp(l2))/2.0
!        where(soiltmp.eq.r_missing_data)soiltmp=avgtmp
! or this way: hasn't been tested yet.
         rlatmn=minval(lat(:,1))
         rlatmx=maxval(lat(:,nnyp))
         tatlmx=rmeanlattemp(l2)
         tatlmn=rmeanlattemp(l1)
         if(tatlmx.ne.0.and.tatlmn.ne.0.and.
     .      tatlmx.ne.tatlmn)then
            tslp=(rlatmx-rlatmn)/(tatlmx-tatlmn)
            do j=1,nnyp
            do i=1,nnxp
               soiltemp_1deg(i,j)=tatlmn+(rlatmx-lat(i,j))/tslp
               sumt=soiltemp_1deg(i,j)+sumt
            enddo
            enddo
            avgtmp=sumt/(nnyp*nnxp)
         elseif(tatlmx.gt.0)then
            avgtmp=tatlmx
         elseif(tatlmn.gt.0)then
            avgtmp=tatlmn
         else
            avgtmp=0.0
         endif
         deallocate (rmeanlattemp)
      endif

      print*,'Domain average annual mean temp = ',avgtmp

      avggrn=r_missing_data

      do l=1,ncat
         if(ic(l).gt.0)then
            avggrn(l)=sum(l)/float(ic(l))
         else
            avggrn(l)=0.0
         endif
         print*,'Domain average greenfrac = ',l,avggrn(l)
      enddo

      avgslpcat=r_missing_data
      if(islp.gt.0)then
         avgslpcat=float(isum)/islp
         print*,'Average slope category: ',avgslpcat
      else
         print*,'Could not compute average slpe cat ?'
         print*,'Average slope category: ',avgslpcat
      endif

c extend search to a fraction of the domain size. someday improve this for
c ratio geog-data-res/domain-res or something to avoid unreasonable
c search distance.

      ijsthresh = int(nnxp/2)

      do j = 1,nnyp
       do i = 1,nnxp

        if(landmask(i,j).eq.1)then               !a land point

         if(soiltmp(i,j).eq.r_missing_data)then  !an inconsistency exists
 
          is=1
          js=1
          endsearch = .false.

          sumt=0.0
          isc=0

          do while (.not.endsearch)

           do jj=j-js,j+js
           do ii=i-is,i+is

              if((ii.ge.1) .and. (ii.le.nnxp) .and.
     &           (jj.ge.1) .and. (jj.le.nnyp)) then

                 if(soiltmp(ii,jj).ne.r_missing_data)then
                    sumt=sumt+soiltmp(ii,jj)
                    isc=isc+1
                 endif

              endif

           enddo
           enddo

           if(isc.gt.0)then
              soiltemp_1deg(i,j)=-0.0065*topt_out(i,j)+sumt/isc
              endsearch=.true.
           else
              is=is+1
              js=js+1
              if(is.gt.ijsthresh)endsearch=.true.
           endif

          enddo

         else

          soiltemp_1deg(i,j)=-0.0065*topt_out(i,j)+soiltemp_1deg(i,j)

         endif

         if(soiltemp_1deg(i,j).lt.0.00)then
            print*,'Here:  bizzare soil temp'
            print*,'i/j/soiltemp ',i,j,soiltemp_1deg(i,j)
         endif
! greenness frac

         if(grnfrctmp(i,j,1).eq.r_missing_data.and.
     &                rmngrn.lt.r_missing_data)then  !an inconsistency exists

          endsearch = .false.

          sum=0.0
          ic=0
          is=1
          js=1
          jj=j
        
          do while (.not.endsearch)
           do ii=i-is,i+is
           do jj=j-js,j+js

            if( (ii.ge.1) .and. (ii.le.nnxp)
     &     .and.(jj.ge.1) .and. (jj.le.nnyp)) then

             if(landmask(ii,jj).eq.1.and.
     &         grnfrctmp(ii,jj,1).lt.r_missing_data)then

               do l=1,12
                  sum(l)=sum(l)+grnfrctmp(ii,jj,l)
                  ic(l)=ic(l)+1
               enddo
             endif

            endif

           enddo
           enddo

           if(ic(1).gt.0)then
              do l=1,12
                 greenfrac(i,j,l)=sum(l)/float(ic(l))
              enddo
              endsearch=.true.
           else
              is=is+1
              js=js+1
              if(is.gt.ijsthresh.or.js.gt.ijsthresh)endsearch=.true.
           endif

          enddo

         else

          greenfrac(i,j,:)=grnfrctmp(i,j,:)

         endif
c ------------------------------------------
c this section for terrain slope categories
c
         if(islopetmp(i,j).eq.r_missing_data)then !an inconsistency

          endsearch = .false.

          sumt=0.0
          isc=0
          islp=-9
          is=1
          js=1
          jj=j

          do while (.not.endsearch)
           do ii=i-is,i+is
           do jj=j-js,j+js

            if( (ii.ge.1) .and. (ii.le.nnxp)
     &     .and.(jj.ge.1) .and. (jj.le.nnyp)) then

             if(landmask(ii,jj).eq.1.and.
     &         islopetmp(ii,jj).lt.r_missing_data)then
               islp=islopetmp(ii,jj)
               sumt=sumt+islopetmp(ii,jj)
               isc=isc+1
             endif

            endif

           enddo
           enddo

           if(isc.gt.0)then
              if(islp.gt.7.0)islp=13.0    !force mean to glacial ice as necessary
              if(sumt.lt.isc)then
                 islp=1.0
              else
                 islp=float(nint(sumt/float(isc)))
              endif
              islope(i,j)=islp
              endsearch=.true.
           else
              is=is+1
              js=js+1
              if(is.gt.ijsthresh.or.js.gt.ijsthresh)endsearch=.true.
           endif

          enddo

         else

          islope(i,j)=islopetmp(i,j)

         endif

        else     !this is a water point

         if(soiltemp_1deg(i,j).ne.r_missing_data)then
            soiltemp_1deg(i,j)=r_missing_data
         endif

         do l=1,12
            if(greenfrac(i,j,l).ne. 0.0 .and.
     &         greenfrac(i,j,l).lt.r_missing_data)then
               greenfrac(i,j,l)=0.0
            endif
         enddo

         if(islope(i,j).ne.r_missing_data)then
            islope(i,j)=r_missing_data
         endif

        endif

       enddo
      enddo

      deallocate (grnfrctmp,soiltmp,islopetmp)

c if the above search failed to find nearby soil temp or greenness frac
c then use average value

      do j = 1,nnyp
      do i = 1,nnxp

         if(landmask(i,j).eq.1)then  !a land point

            if(soiltemp_1deg(i,j).eq.r_missing_data)then
               soiltemp_1deg(i,j) = avgtmp-0.0065*topt_out(i,j)
            endif

            do l = 1,12
               if(greenfrac(i,j,l).eq.0.0)then
                  greenfrac(i,j,l)=avggrn(l)
               endif
            enddo

            if(islope(i,j).eq.r_missing_data)then
               islope(i,j)=float(nint(avgslpcat))
            endif

         endif

      enddo
      enddo

      where(islope.eq.r_missing_data)islope=0.0  !put water category back to original value

      istatus=1

      return
      end
