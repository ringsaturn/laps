cdis    Forecast Systems Laboratory
cdis    NOAA/OAR/ERL/FSL
cdis    325 Broadway cdis    Boulder, CO     80303 
cdis 
cdis    Forecast Research Division cdis    Local Analysis and Prediction Branch 
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

        subroutine lapswind_plot(c_display,i4time_ref,lun,NX_L,NY_L,
     1                           NZ_L, MAX_RADARS, L_RADARS,
     1                           r_missing_data,
     1                           laps_cycle_time,zoom)

!       1995        Steve Albers         Original Version
!       1995 Dec 8  Steve Albers         Automated pressure range
!       97-Aug-14     Ken Dritz     Added NX_L, NY_L, NZ_L as dummy args
!       97-Aug-14     Ken Dritz     Added MAX_RADARS as dummy arg
!       97-Aug-14     Ken Dritz     Added r_missing_data as dummy arg
!       97-Aug-14     Ken Dritz     Added laps_cycle_time as dummy arg
!       97-Aug-14     Ken Dritz     Removed include of lapsparms.for
!       97-Aug-14     Ken Dritz     Pass NX_L, NY_L, r_missing_data, and
!                                   laps_cycle_time to plot_cont
!       97-Aug-14     Ken Dritz     Pass NX_L, NY_L (a second time) and
!                                   r_missing_data, laps_cycle_time to
!                                   plot_barbs
!       97-Aug-14     Ken Dritz     Pass NX_L, NY_L, and laps_cycle_time to
!                                   plot_grid
!       97-Aug-14     Ken Dritz     Pass NX_L, NY_L, and laps_cycle_time to
!                                   plot_cldpcp_type
!       97-Aug-14     Ken Dritz     Pass NX_L, NY_L, and laps_cycle_time to
!                                   plot_stations
!       97-Aug-17     Ken Dritz     Pass r_missing_data to divergence
!       97-Aug-25     Steve Albers  Removed equivalence for uv_2d.
!                                   Removed equivalence for slwc_int.
!                                   Removed equivalence for slwc_2d.
!                                   Removed /lapsplot_cmn1/ and /lapsplot_cmn2/
!       97-Sep-24     John Smart    Added display funtionality for
!                                   polar orbiter (lrs).
!       98-Mar-23        "          Added lvd subdirectory flexibility.

        include 'trigd.inc'

        real*4 lat(NX_L,NY_L),lon(NX_L,NY_L),topo(NX_L,NY_L)
        real*4 rlaps_land_frac(NX_L,NY_L)
        real*4 soil_type(NX_L,NY_L)

        character*1 c_display, qtype
        character*1 cansw
        character*13 filename,a13_time
        character*3 c3_site
        character*4 c4_string,fcst_hhmm
        character*5 c5_string
        character*4 c4_log
        character*7 c7_string
        character*9 c9_string,a9_start,a9_end
        character infile*255
        character*20 c_model

        character i4_to_byte

        real clow,chigh,cint_ref
        data clow/-200./,chigh/+400/,cint_ref/10./

        integer*4 idum1_array(NX_L,NY_L)

        real*4 dum1_array(NX_L,NY_L)
        real*4 dum2_array(NX_L,NY_L)
        real*4 dum3_array(NX_L,NY_L)
        real*4 dum4_array(NX_L,NY_L)

      ! Used for "Potential" Precip Type
        logical iflag_mvd,iflag_icing_index,iflag_cloud_type
     1         ,iflag_bogus_w
        logical iflag_snow_potential, l_plot_image

        integer*4 ibase_array(NX_L,NY_L)
        integer*4 itop_array(NX_L,NY_L)

        character*2 c_field
        character*2 c_metacode
        character*3 c_type
        character*3 c_bkg
        character c19_label*19,c33_label*33

!       integer*4 ity,ily,istatus
!       data ity/35/,ily/1010/

        real*4 mspkt
        data mspkt/.518/

!       Stuff to read in WIND file
        integer*4 KWND
        parameter (KWND = 3)
        real*4 u_2d(NX_L,NY_L) ! WRT True North
        real*4 v_2d(NX_L,NY_L) ! WRT True North
        real*4 w_2d(NX_L,NY_L)
        real*4 liw(NX_L,NY_L)
        real*4 helicity(NX_L,NY_L)
        real*4 vas(NX_L,NY_L)
        real*4 cint
        real*4 uv_2d(NX_L,NY_L,2)

        real*4 div(NX_L,NY_L)
        real*4 dir(NX_L,NY_L)
        real*4 spds(NX_L,NY_L)
        real*4 umean(NX_L,NY_L) ! WRT True North
        real*4 vmean(NX_L,NY_L) ! WRT True North

        real*4 sndr_po(19,NX_L,NY_L)

        character*3 var_2d
        character*150  directory
        character*31  ext
        character*10  units_2d
        character*125 comment_2d
        character*9 comment_a,comment_b

!       For reading in radar data
        real*4 dummy_array(NX_L,NY_L)
        real*4 radar_array(NX_L,NY_L)
        real*4 radar_array_adv(NX_L,NY_L)

        real*4 v_nyquist_in_a(MAX_RADARS)
        real*4 rlat_radar_a(MAX_RADARS), rlon_radar_a(MAX_RADARS) 
        real*4 rheight_radar_a(MAX_RADARS)
        integer*4 i4time_radar_a(MAX_RADARS)
        integer*4 n_vel_grids_a(MAX_RADARS)
        character*4 radar_name,radar_name_a(MAX_RADARS)
        character*31 ext_radar_a(MAX_RADARS)

!       real*4 omega_3d(NX_L,NY_L,NZ_L)
        real*4 grid_ra_ref(NX_L,NY_L,NZ_L,L_RADARS)
        real*4 grid_ra_vel(NX_L,NY_L,NZ_L,MAX_RADARS)
        real*4 grid_ra_nyq(NX_L,NY_L,NZ_L,MAX_RADARS)
        real*4 field_3d(NX_L,NY_L,NZ_L)

        real*4 lifted(NX_L,NY_L)
        real*4 height_2d(NX_L,NY_L)
        real*4 temp_2d(NX_L,NY_L)
        real*4 tw_sfc_k(NX_L,NY_L)
        real*4 td_2d(NX_L,NY_L)
        real*4 pres_2d(NX_L,NY_L)
        real*4 temp_3d(NX_L,NY_L,NZ_L)
        real*4 temp_col_max(NX_L,NY_L)
        real*4 pressures_mb(NZ_L)

!       real*4 slwc_int(NX_L,NY_L)
        real*4 column_max(NX_L,NY_L)
        character pcp_type_2d(NX_L,NY_L)
        character b_array(NX_L,NY_L)

        real*4 slwc_2d(NX_L,NY_L)
        real*4 cice_2d(NX_L,NY_L)
        real*4 field_2d(NX_L,NY_L)

        real*4 snow_2d(NX_L,NY_L)
        real*4 snow_2d_buf(NX_L,NY_L)
        real*4 precip_2d(NX_L,NY_L)
        real*4 precip_2d_buf(NX_L,NY_L)
        real*4 accum_2d(NX_L,NY_L)
        real*4 accum_2d_buf(NX_L,NY_L)

!       Local variables used in
        logical l_mask(NX_L,NY_L)
        integer ipcp_1d(NZ_L)

        integer*4 iarg

        real*4 cloud_cvr(NX_L,NY_L)
        real*4 cloud_ceil(NX_L,NY_L)
        real*4 cloud_low(NX_L,NY_L)
        real*4 cloud_top(NX_L,NY_L)

        character*255 c_filespec_ra
        character*255 c_filespec_src
        data c_filespec_src/'*.src'/

        character*255 c_filespec
        character*255 cfname
        character*2   cchan

        include 'satellite_dims_lvd.inc'

        character*15  clvdvars(maxchannel)
        data clvdvars/'[SVS, SVN, ALB]',
     1                '[S3A, S3C,    ]',
     1                '[S4A, S4C,    ]',
     1                '[S8A, S8W, S8C]',
     1                '[SCA, SCC,    ]'/

        logical lfndtyp

        logical lapsplot_pregen,l_precip_pregen,l_pregen,l_radar_read
        data lapsplot_pregen /.true./

!       real*4 heights_3d(NX_L,NY_L,NZ_L)

        real*4 p_1d_pa(NZ_L)
        real*4 rh_2d(NX_L,NY_L)
        real*4 sh_2d(NX_L,NY_L)

        real*4 k_to_f, k_to_c
        real*4 make_rh

        include 'laps_cloud.inc'
        include 'bgdata.inc'

        real*4 clouds_3d(NX_L,NY_L,KCLOUD)
        real*4 cld_pres(KCLOUD)

        common /supmp1/ dummy,part
        common /image/ n_image

!       COMMON /CONRE1/IOFFP,SPVAL,EPSVAL,CNTMIN,CNTMAX,CNTINT,IOFFM

        character asc9_tim_3dw*9, asc_tim_24*24
        character asc9_tim_r*9, asc9_tim*9, asc_tim_9
        character asc9_tim_t*9
        character asc9_tim_n*9
        character c9_radarage*9

        character*9   c_fdda_mdl_src(maxbgmodels)
        character*10  cmds

c       include 'satellite_dims_lvd.inc'
        include 'satellite_common_lvd.inc'

        data mode_lwc/2/

        icen = NX_L/2+1
        jcen = NY_L/2+1

        i_overlay = 0
        n_image = 0
        jdot = 1   ! 1 = Dotted County Boundaries, 0 = Solid County Boundaries
        part = 0.9 ! For plotting routines

        ioffm = 1 ! Don't plot label stuff in conrec

!       Get fdda_model_source from parameter file
        call get_fdda_model_source(c_fdda_mdl_src,n_fdda_models,istatus)

        ext = 'nest7grid'

!       Get the location of the static grid directory
        call get_directory(ext,directory,len_dir)

        var_2d='LAT'
        call rd_laps_static (directory,ext,nx_l,ny_l,1,var_2d,
     1                       units_2d,comment_2d,
     1                       lat,rspacing_dum,istatus)
        if(istatus .ne. 1)then
            write(6,*)' Error reading LAPS static-lat'
            return
        endif

        var_2d='LON'
        call rd_laps_static (directory,ext,nx_l,ny_l,1,var_2d,
     1                       units_2d,comment_2d,
     1                       lon,rspacing_dum,istatus)
        if(istatus .ne. 1)then
            write(6,*)' Error reading LAPS static-lon'
            return
        endif

        var_2d='AVG'
        call rd_laps_static (directory,ext,nx_l,ny_l,1,var_2d,
     1                       units_2d,comment_2d,
     1                       topo,rspacing_dum,istatus)
        if(istatus .ne. 1)then
            write(6,*)' Error reading LAPS static-topo'
            return
        endif

        var_2d='LDF'
        call rd_laps_static (directory,ext,nx_l,ny_l,1,var_2d,
     1                       units_2d,comment_2d,
     1                       rlaps_land_frac,rspacing_dum,istatus)
        if(istatus .ne. 1)then
            write(6,*)' Error reading LAPS static-ldf'
            return
        endif

        var_2d='USE'
        call rd_laps_static (directory,ext,nx_l,ny_l,1,var_2d,
     1                       units_2d,comment_2d,
     1                       soil_type,rspacing_dum,istatus)
        if(istatus .ne. 1)then
            write(6,*)' Warning: could not read LAPS soil-type'
!           return
        endif

1200    write(6,11)
11      format(//'  SELECT FIELD:  ',
     1       /'     [wd,wb,wr,wf,bw] Wind'
     1       ,' (LW3/LWM, LGA/LGB, FUA/FSF, LAPS-BKG, QBAL), '
     1       /'     [wo,co,bo,lo] Anlyz/Cloud/Balance/Background Omega'        
     1       /'     [ra] Radar Data - NOWRAD vrc files,  [rx] Max Radar'
     1       /'     [rd] Radar Data - Doppler Ref-Vel (v01-v02...)'
     1       /
     1       /'     SFC: [p,pm,ps,tf,tc,df,dc,ws,vv,hu,ta,th,te,vo,mr'       
     1       ,',mc,dv,ha,ma,sp]'
     1       /'          [cs,vs,tw,fw,hi]'
     1       /'          [of,oc,os,qf,qc,qs] obs plot/station locations'       
     1       ,'  [bs] Sfc background'
     1       /'          [li,lw,he,pe,ne] li, li*w, helcty, CAPE, CIN,'
     1       /'          [s] Other Stability Indices'
     1       /
     1       /'     TEMP: [t, tb,tr,to,bt] (LAPS,LGA,FUA,OBS,QBAL)'      
     1       ,',   [pt,pb] Theta, Blnc Theta'
     1       /'     HGTS: [ht,hb,hr,hy,bh] (LAPS,LGA,FUA,Hydrstc,QBAL),'
     1       /'           [hh] Height of Const Temp Sfc'               )

        write(6,12)
 12     format(
     1       /'     [br,fr,lq] Humidity (lga;fua;lq3: [q or rh]) '
     1       ,' [pw] Precipitable Water'       
     1       /
     1       /'     CLOUDS/PRECIP: [ci] Cloud Ice,'
     1       ,' [ls] Cloud LWC'
     1       /'         [is] Integrated Cloud LWC  '
     1       /'         [mv] Mean Volume Drop Diam,   [ic] Icing Index,'       
     1       /'         [cc] Cld Ceiling (AGL),'
     1       ,' [cb,ct-i] Cld Base/Top (MSL)'      
     1       /'         [cv/cg] Cloud Cover (2-D)'
     1       ,' [cy,py] Cloud/Precip Type'
     1       /'         [sa/pa] Snow/Pcp Accum,'
     1       ,' [sc] Snow Cvr'
     1       /
     1       /'     [tn-i,lf,gr,so] Ter/LndFrac/Grid'
     1       /'     [lv(d),lr(lsr),v3,v5,po] lvd; lsr; VCF; Tsfc-11u;'
     1       , 'Polar Orbiter'
     1       //' ',52x,'[q] quit/display ? ',$)

 15     format(a2)

        read(lun,16)c_type
 16     format(a3)

!       c4_log = 'h '//c_type
!       if(lun .eq. 5 .and. c_type .ne. 'q ')call logit(c4_log)

!  ***  Ask for wind field ! ***************************************************
        if(    c_type .eq. 'wd' .or. c_type .eq. 'wb'
     1    .or. c_type .eq. 'co' .or. c_type .eq. 'wr'
     1    .or. c_type .eq. 'wf' .or. c_type .eq. 'bw'
     1    .or. c_type .eq. 'bo' .or. c_type .eq. 'lo'
     1    .or. c_type .eq. 'wo'                           )then

            if(c_type .eq. 'wd')then
                ext = 'lw3'
!               call get_directory(ext,directory,len_dir)
!               c_filespec = directory(1:len_dir)//'*.'//ext(1:3)

            elseif(c_type .eq. 'wb')then
                call make_fnam_lp(i4time_ref,asc9_tim_3dw,istatus)

                ext = 'lga'

            elseif(c_type .eq. 'wr')then
                call make_fnam_lp(i4time_ref,asc9_tim_3dw,istatus)

                ext = 'fua'

            elseif(c_type .eq. 'co')then
                ext = 'lco'

            elseif(c_type .eq. 'wo')then
                ext = 'lw3'

            elseif(c_type .eq. 'lo')then
                ext = 'lga'

            elseif(c_type .eq. 'wf')then
                ext = 'lw3'
!               call get_directory(ext,directory,len_dir)
!               c_filespec = directory(1:len_dir)//'*.'//ext(1:3)
            elseif(c_type .eq. 'bw'.or.c_type.eq.'bo')then
                ext = 'balance'
            endif


            if(c_type.eq.'bw'.or.c_type.eq.'bo')then
               call get_filespec(ext,1,c_filespec,istatus)
               ext='lw3'
               call s_len(c_filespec,ilen)
               c_filespec=c_filespec(1:ilen)//ext(1:3)//'/*.'//ext
            else
               call get_filespec(ext,2,c_filespec,istatus)
            endif

            if(c_type .eq. 'wd')then
                write(6,13)
13              format(
     1    '     Enter Level in mb, -1 = steering, 0 = sfc',24x,'? ',$)
            else
                write(6,14)
14              format(
     1    '     Enter Level in mb, 0 = sfc',39x,'? ',$)
            endif

            read(lun,*)k_level

            k_mb = k_level

            if(k_level .gt. 0)then
               k_level = nint(zcoord_of_pressure(float(k_level*100)))
            endif

            if(c_type.ne.'lo' .and. c_type .ne. 'wr'
     1                        .and. c_type .ne. 'wb')then
               write(6,*)
               write(6,*)'    Looking for laps wind data: ',ext(1:3)
               call get_file_time(c_filespec,i4time_ref,i4time_3dw)

            else 
               i4time_3dw = i4time_ref

            endif

            call make_fnam_lp(I4time_3dw,asc9_tim_3dw,istatus)

            if(c_type.eq.'bw'.or.c_type.eq.'bo')ext='balance'
            if(c_type.eq.'co'.or.c_type.eq.'bo'
     1     .or.c_type.eq.'lo'.or.c_type.eq.'wo')then
                c_field = 'w'
                goto115
            endif

            if(k_level .gt. -1)then

                if(k_level .eq. 0)then ! SFC Winds
                    write(6,102)
102                 format(/
     1          '  Field [di,sp,u,v,vc (barbs), ob (obs)]',30x,'? ',$)
                    read(lun,15)c_field

                    if(c_type .eq. 'wd')then
                        ext = 'lwm'
                    elseif(c_type .eq. 'wb')then
                        ext = 'lgb'
                    elseif(c_type .eq. 'wr')then
                        ext = 'fsf'
                    endif

                    if(ext(1:3) .eq. 'lgb' .or. ext(1:3) .eq. 'fsf')then       
                        call input_background_info(
     1                              ext                     ! I
     1                             ,directory               ! O
     1                             ,i4time_ref              ! I
     1                             ,laps_cycle_time         ! I
     1                             ,asc9_tim_3dw            ! O
     1                             ,fcst_hhmm               ! O
     1                             ,i4_initial              ! O
     1                             ,i4_valid                ! O
     1                             ,istatus)                ! O
                        if(istatus.ne.1)goto1200

                        level=0

                        if(ext(1:3) .eq. 'lgb')then
                            var_2d = 'USF'
                        else
                            var_2d = 'U'
                        endif

                        write(6,*)' Reading sfc wind data from: '
     1                            ,ext(1:3),' ',var_2d

                        CALL READ_LAPS(i4_initial,i4_valid,DIRECTORY,
     1                                 EXT,NX_L,NY_L,1,1,       
     1                                 VAR_2d,level,LVL_COORD_2d,
     1                                 UNITS_2d,COMMENT_2d,
     1                                 u_2d,ISTATUS)

                        if(istatus.ne.1)goto1200

                        if(ext(1:3) .eq. 'lgb')then
                            var_2d = 'VSF'
                        else
                            var_2d = 'V'
                        endif

                        write(6,*)' Reading sfc wind data from: '
     1                            ,ext(1:3),' ',var_2d

                        CALL READ_LAPS(i4_initial,i4_valid,DIRECTORY,
     1                                 EXT,NX_L,NY_L,1,1,       
     1                                 VAR_2d,level,LVL_COORD_2d,
     1                                 UNITS_2d,COMMENT_2d,
     1                                 v_2d,ISTATUS)

                        i4time_3dw = i4_valid
                        write(6,*)' Valid time = ',asc9_tim_3dw

                    else ! lwm
!                       call get_directory(ext,directory,len_dir)
!                       c_filespec = directory(1:len_dir)//'*.'//ext(1:3)      

                        call get_filespec(ext,2,c_filespec,istatus)

                        var_2d = 'SU'
                        call get_laps_2d(i4time_3dw,ext,var_2d
     1                      ,units_2d,comment_2d,NX_L,NY_L,u_2d,istatus)

                        var_2d = 'SV'
                        call get_laps_2d(i4time_3dw,ext,var_2d
     1                      ,units_2d,comment_2d,NX_L,NY_L,v_2d,istatus)

                    endif

                else if(k_level .gt. 0)then

                    write(6,103)
103                 format(/
     1              '  Field [di,sp,u,v,w,dv,vc (barbs), ob (obs))]'
     1                                          ,24x,'? ',$)
                    read(lun,15)c_field
                    write(6,*)' ext = ',ext
                    if(c_field .ne. 'w ')then
                      write(6,*)' Calling get_uv_2d for ',ext
                      call get_uv_2d(i4time_3dw,k_level,uv_2d,ext
     1                              ,NX_L,NY_L,fcst_hhmm,istatus)

!                     write(6,*)' Initial time = ',asc9_tim_3dw
                      call make_fnam_lp(i4time_3dw,asc9_tim_3dw,istatus)      
                      write(6,*)' Valid time = ',asc9_tim_3dw

                      if(c_type .eq. 'wf')then

!                       Calculate wind difference vector (lw3 - model first guess)
                        var_2d = 'U3'
                        call get_modelfg_3d(i4time_3dw,var_2d
     1                           ,NX_L,NY_L,NZ_L,field_3d,istatus) 
                        call multcon(field_3d(1,1,k_level),-1.
     1                        ,NX_L,NY_L)      
                        call add(field_3d(1,1,k_level),uv_2d(1,1,1),u_2d
     1                        ,NX_L,NY_L)      

                        var_2d = 'V3'
                        call get_modelfg_3d(i4time_3dw,var_2d
     1                           ,NX_L,NY_L,NZ_L,field_3d,istatus) 
                        call multcon(field_3d(1,1,k_level),-1.
     1                                       ,NX_L,NY_L)      
                        call add(field_3d(1,1,k_level),uv_2d(1,1,2),v_2d       
     1                                   ,NX_L,NY_L)      

                      else ! c_type .ne. 'wf'
                        call move(uv_2d(1,1,1),u_2d,NX_L,NY_L)
                        call move(uv_2d(1,1,2),v_2d,NX_L,NY_L)

                      endif ! c_type .eq. 'wf'
 
                    endif ! c_field = 'w'

                endif

            elseif(k_level .eq. -1)then ! Read mean winds from 3d grids

                write(6,*)' Getting pregenerated mean wind file'

                ext = 'lwm'
                call get_directory(ext,directory,len_dir)
                var_2d = 'MU'
                call get_laps_2d(i4time_3dw,ext,var_2d
     1          ,units_2d,comment_2d,NX_L,NY_L,u_2d,istatus)
                var_2d = 'MV'
                call get_laps_2d(i4time_3dw,ext,var_2d
     1          ,units_2d,comment_2d,NX_L,NY_L,v_2d,istatus)

                write(6,104)
104             format(/'  Field [di,sp,u,v,vc (barbs)]   ',25x,'? ',$)       
                read(lun,15)c_field
            endif

!  ***      Display Wind Data  ******************************************************

115         if(c_field .eq. 'di' .or. c_field .eq. 'sp')then
                do i = 1,NX_L
                do j = 1,NY_L
                    if(u_2d(i,j) .eq. r_missing_data
     1            .or. v_2d(i,j) .eq. r_missing_data)then
                        dir(i,j)  = r_missing_data
                        spds(i,j) = r_missing_data
                    else
                        call uvgrid_to_disptrue(u_2d(i,j),
     1                                  v_2d(i,j),
     1                                  dir(i,j),
     1                                  spds(i,j),
     1                                  lon(i,j)     )
                        spds(i,j) = spds(i,j) / mspkt
                    endif
                enddo ! j
                enddo ! i
            endif

            if(c_field .eq. 'di')then
                c19_label = ' Isogons   (deg)   '
                call mklabel33(k_level,c19_label,c33_label)

                call plot_cont(dir,1e0,clow,chigh,30.,asc9_tim_3dw,
     1          c33_label,i_overlay,c_display,lat,lon,jdot,       
     1          NX_L,NY_L,r_missing_data,laps_cycle_time)

            else if(c_field .eq. 'sp')then
                c19_label = ' Isotachs (kt)     '
                call mklabel33(k_level,c19_label,c33_label)

                if(k_level .gt. 0 .and. k_mb .le. 500)then
                    cint = 10.
                else
                    cint = 5.
                endif

                call plot_cont(spds,1e0,0.,300.,cint,asc9_tim_3dw,
     1           c33_label,i_overlay,c_display,lat,lon,jdot,       
     1           NX_L,NY_L,r_missing_data,laps_cycle_time)

            else if(c_field .eq. 'u ')then
                if(c_type .eq. 'wf')then
                    c19_label = ' U - Diff      '
                elseif(c_type .eq. 'wb')then
                    c19_label = ' U (lga) - Comp'
                elseif(c_type .eq. 'wr')then
                    c19_label = ' U (fua) - Comp'
                elseif(c_type .eq. 'bw')then
                    c19_label = ' U - Comp (bal)'
                else
                    c19_label = ' U - Comp (anal)'
                endif

                call mklabel33(k_level,c19_label,c33_label)

                call plot_cont(u_2d,1e0,clow,chigh,10.,asc9_tim_3dw,
     1           c33_label,i_overlay,c_display,lat,lon,jdot,
     1           NX_L,NY_L,r_missing_data,laps_cycle_time)

            else if(c_field .eq. 'v ')then
                if(c_type .eq. 'wf')then
                    c19_label = ' V - Diff       '
                elseif(c_type .eq. 'wb')then
                    c19_label = ' V (lga) - Comp '
                elseif(c_type .eq. 'wr')then
                    c19_label = ' V (fua) - Comp '
                elseif(c_type .eq. 'bw')then
                    c19_label = ' V - Comp (bal)'
                else
                    c19_label = ' V - Comp (anal) '
                endif
                call mklabel33(k_level,c19_label,c33_label)

                call plot_cont(v_2d,1e0,clow,chigh,10.,asc9_tim_3dw,
     1           c33_label,i_overlay,c_display,lat,lon,jdot,       
     1           NX_L,NY_L,r_missing_data,laps_cycle_time)

            else if(c_field .eq. 'vc' .or. c_field .eq. 'ob')then
                if(c_type .eq. 'wf')then
                    c19_label = ' WIND diff (kt)    '
                elseif(c_type.eq.'wb'                       )then
                    c19_label = ' WIND lga '//fcst_hhmm//'   kt'
                elseif(c_type.eq.'wr'                       )then
                    c19_label = ' WIND fua '//fcst_hhmm//'   kt'
                elseif(c_type.eq.'bw'                       )then
                    c19_label = ' WIND  (bal)    kt'
                else
                    c19_label = ' WIND  (anl)    kt'
                endif

                call mklabel33(k_level,c19_label,c33_label)

                if(k_level .ne. 0)then
                    interval = (max(NX_L,NY_L) / 50) + 1
                    size = float(interval) * .14

                else
                    nxz = float(NX_L) / zoom
                    nyz = float(NY_L) / zoom
                    interval = int(max(nxz,nyz) / 65.) + 1
                    size = float(interval) * .15

                endif

                call plot_barbs(u_2d,v_2d,lat,lon,topo,size,zoom
     1               ,interval,asc9_tim_3dw
     1               ,c33_label,c_field,k_level,i_overlay,c_display       
     1               ,NX_L,NY_L,NZ_L,grid_ra_ref,grid_ra_vel       
     1               ,NX_L,NY_L,r_missing_data,laps_cycle_time,jdot)

            else if(c_field .eq. 'w' .or. c_field .eq. 'om')then ! Omega 
                if(c_type .eq. 'co')then
                    write(6,*)' Reading cloud omega'
                    var_2d = 'COM'
                    ext = 'lco'
                    call get_laps_2dgrid(i4time_3dw,0,i4time_nearest
     1                                  ,ext,var_2d,units_2d,comment_2d
     1                                  ,NX_L,NY_L,w_2d,k_mb,istatus)
                    call mklabel33(k_level
     1                     ,' Cloud Omega ubar/s',c33_label)       

                elseif(c_type .eq. 'wo')then
                    write(6,*)' Reading lw3 omega'
                    var_2d = 'OM'
                    ext = 'lw3'
                    call get_laps_2dgrid(i4time_3dw,0,i4time_nearest,
     1              ext,var_2d,units_2d,comment_2d,NX_L,NY_L
     1                                          ,w_2d,k_mb,istatus)
                    call mklabel33(k_level
     1                     ,' Anlyz Omega ubar/s',c33_label)       

                else if(c_type .eq. 'bo')then
                    write(6,*)' Reading balanced omega'
                    var_2d = 'OM'
                    ext = 'lw3'
                    call get_directory('balance',directory,lend)
                    directory=directory(1:lend)//'lw3/'
                    call get_2dgrid_dname(directory,i4time_3dw
     1              ,laps_cycle_time*100,i4time_heights,ext,var_2d
     1              ,units_2d,comment_2d,NX_L,NY_L,w_2d,k_mb,istatus)       

                    call mklabel33(k_level
     1                     ,' Balnc Omega ubar/s',c33_label)       

                else if(c_type .eq. 'lo')then
                   write(6,211)ext(1:3)
                   read(5,221)a13_time
                   call get_fcst_times(a13_time,I4TIME,i4_valid,i4_fn)
                   call get_directory(ext,directory,lend)
                   var_2d = 'OM'

                   CALL READ_LAPS(I4TIME,i4_valid,DIRECTORY,EXT,NX_L
     1             ,NY_L,1,1,VAR_2d,k_mb,LVL_COORD_2d,UNITS_2d
     1             ,COMMENT_2d,w_2d,ISTATUS)

                    call make_fnam_lp(i4_valid,asc9_tim_3dw,istatus)
                    call mklabel33(k_level
     1                     ,' Bkgd Omega ubar/s',c33_label)

                endif

                do j = 1,NY_L
                do i = 1,NX_L
                    if(w_2d(i,j) .eq. r_missing_data)then
                        w_2d(i,j) = 0.
                    endif
                enddo ! i
                enddo ! j

                call plot_cont(w_2d,1e-1,0.,0.,-1.0,asc9_tim_3dw,
     1          c33_label,i_overlay,c_display,lat,lon,jdot,       
     1          NX_L,NY_L,r_missing_data,laps_cycle_time)

            elseif(c_field .eq. 'dv')then ! Display Divergence Field
                call divergence(u_2d,v_2d,div,lat,lon,NX_L,NY_L
     1                         ,dum1_array,dum2_array
     1                         ,dum3_array,dum4_array,dummy_array
     1                         ,radar_array,r_missing_data)
                call mklabel33(k_level,' DVRGNC  1e-5 s(-1)',c33_label)

                scale = 1e-5

                call contour_settings(div,NX_L,NY_L,clow,chigh,cint
     1                                                  ,zoom,scale)

                call plot_cont(div,scale,clow,chigh,cint,asc9_tim_3dw,
     1           c33_label,i_overlay,c_display,lat,lon,jdot,
     1           NX_L,NY_L,r_missing_data,laps_cycle_time)

            endif

        elseif(c_type .eq. 'lw')then ! Read in Liw field from 3d grids

            write(6,*)
            write(6,*)'    Looking for laps li*w data:'

            if(lapsplot_pregen)then
                ext = 'liw'
                call get_directory(ext,directory,len_dir)
                c_filespec = directory(1:len_dir)//'*.'//ext(1:3)
                call get_file_time(c_filespec,i4time_ref,i4time_3dw)
                call make_fnam_lp(I4time_3dw,asc9_tim_3dw,istatus)

                write(6,*)' Getting pregenerated Li * omega file'

                var_2d = 'LIW'
                ext = 'liw'
                call get_laps_2d(i4time_3dw,ext,var_2d
     1          ,units_2d,comment_2d,NX_L,NY_L,liw,istatus) ! K-Pa/s

            else ! Calculate LI * omega on the fly
                write(6,*)'    Looking for 3D laps wind data:'
                ext = 'lw3'
                call get_directory(ext,directory,len_dir)
                c_filespec = directory(1:len_dir)//'*.'//ext(1:3)
                call get_file_time(c_filespec,i4time_ref,i4time_3dw)
                call make_fnam_lp(I4time_3dw,asc9_tim_3dw,istatus)

                var_2d = 'OM'
                ext = 'lw3'
                lvl_2d = 600
                call get_laps_2dgrid(i4time_3dw,0,i4time_nearest,
     1              ext,var_2d,units_2d,comment_2d,NX_L,NY_L
     1                                          ,w_2d,lvl_2d,istatus)

!               Read in LI data
                var_2d = 'LI'
                ext = 'lst'
                call get_laps_2dgrid(i4time_3dw,laps_cycle_time
     1                              ,i4time_nearest,ext,var_2d
     1                              ,units_2d,comment_2d,NX_L,NY_L
     1                              ,lifted,0,istatus)

                if(istatus .ne. 1)then
                    write(6,*)' Error reading Lifted Index data'
                    stop
                endif

                call cpt_liw(lifted,w_2d,NX_L,NY_L,liw) ! K-Pa/s

            endif ! Pregenerated LI * omega field

!           Logarithmically scale the values for display
!           do j = 1,NY_L,1
!           do i = 1,NX_L,1

!               if(liw(i,j) .ge. 3.16)then
!                   liw(i,j) = alog10(liw(i,j))
!               elseif(liw(i,j) .ge. 0.)then
!                   liw(i,j) = liw(i,j) * 0.5/3.16
!               endif

!           enddo ! j
!           enddo ! i

            chigh = 50.

            call plot_cont(liw,1e0,0.0,50.0,-0.5,asc9_tim_3dw,
     1              'LAPS sfc LI X 600mb omega  Pa-K/s',i_overlay
     1              ,c_display,lat,lon,jdot
     1              ,NX_L,NY_L,r_missing_data,laps_cycle_time)

        elseif(c_type .eq. 'li')then ! Read in Li field from 3d grids
            if(lapsplot_pregen)then
                write(6,*)' Getting li from LST'
!               Read in LI data
                var_2d = 'LI'
                ext = 'lst'
                call get_laps_2dgrid(i4time_ref,7200,i4time_nearest,
     1          ext,var_2d,units_2d,comment_2d,NX_L,NY_L
     1                                          ,lifted,0,istatus)

            else
                call get_laps_2dgrid(i4time_ref,7200,i4time_nearest,
     1          ext,var_2d,units_2d,comment_2d,NX_L,NY_L
     1                                          ,lifted,0,istatus)

            endif

            if(istatus .ne. 1)then
                write(6,*)' Error reading Lifted Index data'
                goto1200
            endif

            call make_fnam_lp(i4time_nearest,asc9_tim_n,istatus)

            call plot_cont(lifted,1e-0,-20.,+40.,2.,asc9_tim_n,
     1          'LAPS    SFC Lifted Index     (K) ',i_overlay
     1          ,c_display,lat,lon,jdot,
     1          NX_L,NY_L,r_missing_data,laps_cycle_time)

        elseif(c_type .eq. 's')then ! Read in LST data generically
            ext = 'lst'

            write(6,825)
 825        format(/'  SELECT FIELD (VAR_2D):  '
     1       /
     1       /'     LST (stability): [li,pbe,nbe,si,tt,k,lcl,wb0] ? ',$)       

            read(lun,824)var_2d
 824        format(a)
            call upcase(var_2d,var_2d)

            level=0
            call get_laps_2dgrid(i4time_ref,7200
     1                          ,i4time_nearest
     1                          ,ext,var_2d,units_2d,comment_2d
     1                          ,NX_L,NY_L
     1                          ,field_2d,0,istatus)

            IF(istatus .ne. 1 .and. istatus .ne. -1)THEN
                write(6,*)' Error Reading Stability Analysis ',var_2d
                goto1200
            endif

            call make_fnam_lp(i4time_nearest,asc9_tim_t,istatus)

            call s_len(comment_2d,len_comment)
            call s_len(units_2d,len_units)

            if(len_units .gt. 0)then
                if(units_2d(1:len_units) .eq. 'M')then
                    c33_label = 'LAPS '
     1                      //comment_2d(1:len_comment)
     1                      //'   ('//units_2d(1:len_units)//'-MSL)'
                else
                    c33_label = 'LAPS '
     1                      //comment_2d(1:len_comment)
     1                      //'   ('//units_2d(1:len_units)//')'
                endif
            else
                c33_label = 'LAPS '
     1                      //comment_2d(1:len_comment)
            endif

            scale = 1.
            call contour_settings(field_2d,NX_L,NY_L,clow,chigh,cint
     1                                                   ,zoom,scale)       

            call plot_cont(field_2d,scale,clow,chigh,cint
     1                    ,asc9_tim_t,c33_label,i_overlay,c_display
     1                    ,lat,lon,jdot
     1                    ,NX_L,NY_L,r_missing_data,laps_cycle_time)

        elseif(c_type .eq. 'tw')then
            i4time_temp = i4time_ref / laps_cycle_time * laps_cycle_time

!           Read in surface temp data
            var_2d = 'T'
            ext = 'lsx'
            call get_laps_2dgrid(i4time_ref,laps_cycle_time,i4time_temp       
     1                          ,ext,var_2d,units_2d,comment_2d
     1                          ,NX_L,NY_L,temp_2d,0,istatus)

            if(istatus .ne. 1)then
                write(6,*)' LAPS Sfc Temp not available'
                return
            endif

!           Read in surface dewpoint data
            var_2d = 'TD'
            ext = 'lsx'
            call get_laps_2d(i4time_temp,
     1                       ext,var_2d,units_2d,comment_2d,
     1                       NX_L,NY_L,td_2d,istatus)

            if(istatus .ne. 1)then
                write(6,*)' LAPS Sfc Dewpoint not available'
                return
            endif

!           Read in surface pressure data
            var_2d = 'PS'
            ext = 'lsx'
            call get_laps_2d(i4time_temp,
     1                       ext,var_2d,units_2d,comment_2d,NX_L,NY_L
     1                       ,pres_2d,istatus)

            if(istatus .ne. 1)then
                write(6,*)' LAPS Sfc Pressure not available'
                return
            endif

            call get_tw_approx_2d(temp_2d,td_2d,pres_2d,NX_L,NY_L
     1                           ,tw_sfc_k)

            call make_fnam_lp(i4time_temp,asc9_tim_n,istatus)

            zero_c = 273.15

            do i = 1,NX_L
            do j = 1,NY_L
                field_2d(i,j) = tw_sfc_k(i,j) - zero_c
            enddo ! j
            enddo ! i


            call plot_cont(field_2d,1e-0,-30.,+30.,2.,asc9_tim_n,
     1                    'LAPS    SFC Wetbulb (approx) (C) '
     1                    ,i_overlay,c_display,lat,lon,jdot,
     1                     NX_L,NY_L,r_missing_data,laps_cycle_time)

        elseif(c_type .eq. 'ms' .or. c_type .eq. 'ob'
     1                          .or. c_type .eq. 'st'   
     1                          .or. c_type .eq. 'of'   
     1                          .or. c_type .eq. 'oc'   
     1                          .or. c_type .eq. 'os'   
     1                          .or. c_type .eq. 'qf'   
     1                          .or. c_type .eq. 'qc'   
     1                          .or. c_type .eq. 'qs'   
     1                                                )then
            i4time_plot = i4time_ref ! / laps_cycle_time * laps_cycle_time
            call get_filespec('lso',2,c_filespec,istatus)
            call get_file_time(c_filespec,i4time_ref,i4time_plot)
            call make_fnam_lp(i4time_plot,asc_tim_9,istatus)

            if(c_type(1:2) .eq. 'st')iflag = 0
            if(c_type(2:2) .eq. 's' )iflag = 0
            if(c_type      .eq. 'ms')iflag = 1
            if(c_type(2:2) .ne. 's' )iflag = 2

            c33_label = '                                 '

            call plot_stations(asc_tim_9,c33_label,c_type,i_overlay
     1                        ,c_display,lat,lon,c_file,iflag
     1                        ,NX_L,NY_L,laps_cycle_time,zoom)

        elseif(c_type .eq. 'he')then
            write(6,*)
!           write(6,*)'    Looking for 3D laps wind data:'
!           call get_file_time(c_filespec,i4time_ref,i4time_3dw)

            write(6,*)' Getting pregenerated helicity file'
            var_2d = 'LHE'
            ext = 'lhe'

            call get_laps_2dgrid(i4time_ref,7200,i4time_nearest,
     1          ext,var_2d,units_2d,comment_2d,NX_L,NY_L
     1                                  ,helicity,0,istatus)

            i4time_3dw = i4time_nearest
            call make_fnam_lp(I4time_3dw,asc9_tim_3dw,istatus)
            
            abs_max = 0
            do i = 1,NX_L
            do j = 1,NY_L
                abs_max = max(abs_max,abs(helicity(i,j)))
            enddo ! j
            enddo ! i

            write(6,*)' Max helicity magnitude = ',abs_max

            c_field = 'he'
            kwind = 0
            clow = -100.
            chigh = +100.

            if(abs_max .gt. 1.)then ! new way
                scale = 1.
!               c33_label = 'LAPS Helicity sfc-500mb m**2/s**2'           
                c33_label = 'LAPS Storm Rel Helicity m**2/s**2'           
                cint = 40.
            else                    ! old way
                scale = 1e-4
                c33_label = 'LAPS Helicity  sfc-500 1e-4m/s**2'          
                cint = 5.
            endif

            call plot_cont(helicity,scale,clow,chigh,cint,asc9_tim_3dw
     1                   ,c33_label
     1                   ,i_overlay,c_display,lat,lon,jdot       
     1                   ,NX_L,NY_L,r_missing_data,laps_cycle_time)

        elseif(c_type .eq. 'lv'.or.c_type .eq. 'lr' )then

         if(c_type .eq. 'lv' )then

          ext = 'lvd'

          call config_satellite_lvd(istatus)
          if(istatus.ne.1)then
             return
          endif

          do k=1,maxsat
           if(isats(k).eq.1)then
            write(6,114)c_sat_id(k)
114         format(5x,'plot the data for ',a6,45x,' [y/n]? ',$)
            read(lun,*)cansw
            if(cansw.eq.'y'.or.cansw.eq.'Y')then

             call get_directory(ext,directory,len_dir)
             directory=directory(1:len_dir)//c_sat_id(k)//'/'
c
c determine which channels have been processed for this satellite
c
             j=0
             lfndtyp=.false.
             do while(.not.lfndtyp.and.j.le.maxtype)
              j=j+1
              if(itypes(j,k).eq.1)then
               ist=j
               lfndtyp=.true.
              endif
             enddo

             write(6,118)
118          format(5x,'Select LVD field',5x,'(vis, 3.9, 6.7, 11.2, 12)'
     1                ,' [enter 1, 2, 3, 4, 5]? ',$)
             read(lun,*)ilvd

             if(ilvd .lt. 0)then
                 l_plot_image = .true.
                 ilvd = -ilvd
             else
                 l_plot_image = .false.
             endif
             
             write(6,*)
             write(6,*)'    Looking for Laps LVD data:'
c
             if(ichannels(ilvd,ist,k).eq.1)then
              write(6,121)clvdvars(ilvd)
121           format(5x,'Select 2D var name:',3x,a15,10x, $)
              read(lun,*)var_2d
              call upcase(var_2d,var_2d)
             else
              print*,'This channel was not processed'
              goto 119
             endif

             call get_2dgrid_dname(directory
     1               ,i4time_ref,100000,i4time_nearest,ext,var_2d
     1               ,units_2d,comment_2d,NX_L,NY_L,vas,0,istatus)

             if(istatus .eq. 0)then
              write(6,*)' Cant find ',var_2d,' Analysis ',istatus
              goto1200
             endif

             if(ilvd.gt.1)then
              c33_label='LAPS B-Temps (C): '//c_sat_id(k)//'/'//var_2d
              vasmx=-255.
              vasmn=255.
              do i = 1,NX_L
              do j = 1,NY_L
                 if(vas(i,j).ne.r_missing_data)then
                    vas(i,j) = vas(i,j) - 273.15
                    vasmx=int(max(vas(i,j),vasmx))
                    vasmn=int(min(vas(i,j),vasmn))
                 endif
              enddo
              enddo
              clow = -80.
              chigh = +40.
              cint = (vasmx-vasmn)/10.
              scale = 1e0
             elseif(var_2d.eq.'ALB')then
              c33_label='LAPS Albedo '//c_sat_id(k)
             elseif(var_2d.eq.'SVS')then
              c33_label='LAPS VIS counts (raw) - '//c_sat_id(k)
             else
              c33_label='LAPS VIS counts (normalized) - '//c_sat_id(k)
             endif

             call make_fnam_lp(i4time_nearest,asc9_tim,istatus)

             if(l_plot_image)then
                 scale_l = 313.0
                 scale_h = 223.0

                 n_image = n_image + 1
                 call ccpfil(vas,NX_L,NY_L,scale_l,scale_h,'linear')
                 call set(.00,1.0,.00,1.0,.00,1.0,.00,1.0,1)
                 call setusv_dum(2hIN,7)
                 call write_label_lplot(NX_L,NY_L,c33_label,asc9_tim
     1                                                    ,i_overlay)

             else ! contours
                 if(ilvd .eq. 1)then
                     if(var_2d.eq.'ALB')then
                         clow = 0.0
                         chigh = 1.
                         cint = 0.1
                         scale = 1e0
                     else
                         clow = 0.0
                         chigh = 256.
                         cint = 05.
                         scale = 1e0
                     endif
                 endif

                 call plot_cont(vas,scale,clow,chigh,cint,asc9_tim,
     1             c33_label,i_overlay,c_display,lat,lon,jdot,
     1             NX_L,NY_L,r_missing_data,laps_cycle_time)

             endif

            endif !(cansw)
           endif  !(isats)
119       enddo   !(maxsat)

         else     !(c_type='lr'?)

          print*,' lsr plotting currently not available'

         endif    !(c_type='lv'?)

        elseif(c_type .eq. 'v3')then

         var_2d = 'ALB'
         call get_2dgrid_dname(directory
     1        ,i4time_ref,100000,i4time_nearest,ext,var_2d
     1        ,units_2d,comment_2d,NX_L,NY_L,vas,0,istatus)

         if(istatus .eq. 0)then
            write(6,*)' Cant find ALB Analysis'
            goto1200
         endif
!        c33_label = 'LAPS VIS Cloud Fraction   -'//c_sat_id(k)
         c33_label = 'LAPS VIS Cld Frac (tenths) '//c_sat_id(k)
         clow  =  -6.
         chigh = +16.
         cint = 2.0
         scale = 1e-1

         do i = 1,NX_L
         do j = 1,NY_L
          if(vas(i,j) .ne. r_missing_data)then
             vas(i,j) = albedo_to_cloudfrac(vas(i,j))
          endif
         enddo
         enddo
         call make_fnam_lp(i4time_nearest,asc9_tim,istatus)

         call plot_cont(vas,scale,clow,chigh,cint,asc9_tim,
     1        c33_label,i_overlay,c_display,lat,lon,jdot,
     1        NX_L,NY_L,r_missing_data,laps_cycle_time)

        elseif(c_type .eq. 'v5')then

         var_2d = 'S8A'
         call get_2dgrid_dname(directory
     1       ,i4time_ref,100000,i4time_nearest,ext,var_2d
     1       ,units_2d,comment_2d,NX_L,NY_L,vas,0,istatus)
         if(istatus .eq. 0)then
            write(6,*)' Cant find VAS/S8A Analysis'
            goto1200
         endif
         c33_label = 'LAPS SFC T - Band 8  (K)  -'//c_sat_id(k)
         clow = -8.0
         chigh = 20.
         cint = 4.
         scale = 1e0

!  Get sfc T to take the difference...
         ext = 'lsx'
         var_2d = 'T'
         call get_laps_2dgrid(i4time_nearest,0,i4time_nearest
     1       ,ext,var_2d,units_2d,comment_2d,NX_L,NY_L,dum1_array,0
     1,istatus)
         if(istatus .ne. 1)then
            write(6,*)' Cant find VAS/S8A Analysis'
            goto1200
         endif

         do i = 1,NX_L
         do j = 1,NY_L
           vas(i,j) = dum1_array(i,j) - vas(i,j)
         enddo
         enddo

         call make_fnam_lp(i4time_nearest,asc9_tim,istatus)

         call plot_cont(vas,scale,clow,chigh,cint,asc9_tim,
     1       c33_label,i_overlay,c_display,lat,lon,jdot,
     1       NX_L,NY_L,r_missing_data,laps_cycle_time)


        elseif( c_type .eq. 'po' )then

          call make_fnam_lp(i4time_ref,asc9_tim,istatus)
          ext = 'lsr'
          call get_directory(ext,directory,len_dir)
          cfname=directory(1:len_dir)//asc9_tim//'_12.lsr'
          open(14,file=cfname,form='unformatted',status='old',err=18)
          goto 27
18        cfname=directory(1:len_dir)//asc9_tim//'_14.lsr'
          open(14,file=cfname,form='unformatted',status='old',err=19)

          n=index(cfname,' ')-1
          write(6,*)'Reading ',cfname(1:n)
          goto 28
27        write(6,*)'Reading ',cfname(1:n)
28        read(14)sndr_po
          write(6,*)'Enter the channel [1-19]'
          read(5,25)ichan
25        format(i2)
          do j=1,NY_L
          do i=1,NX_L
             if(sndr_po(ichan,i,j).ne.r_missing_data)then
                vas(i,j)=sndr_po(ichan,i,j)-273.15
             endif
          enddo
          enddo

          clow = -80.
          chigh = +40.
          cint = 5.
          write(cchan,111)ichan
 111      format(i2)
          if(cchan(1:1).eq.' ')cchan(1:1)='0'
          if(cchan(2:2).eq.' ')cchan(2:2)='0'

          c33_label = 'LAPS Polar Orbiter Channel '//cchan//' deg C'

          call plot_cont(vas,1e0,clow,chigh,cint,asc9_tim,
     1       c33_label,i_overlay,c_display,lat,lon,jdot,
     1       NX_L,NY_L,r_missing_data,laps_cycle_time)

          goto 21
19        write(6,*)'Not able to open an lsr file ', asc9_tim
21        continue

        elseif( c_type .eq. 'ra' .or. c_type .eq. 'gc'
     1    .or.  c_type .eq. 'rr'
     1    .or.  c_type .eq. 'rd'                          )then

            if(c_type .eq. 'ra')mode = 1
            if(c_type .eq. 'gc')mode = 2

            i4time_tmp1 = (i4time_ref)/laps_cycle_time * laps_cycle_time
            i4time_tmp2 = (i4time_ref-2400)/laps_cycle_time * laps_cycle
     1_time

            if(c_type .eq. 'rr')then
                if(i4time_ref .ne. i4time_tmp1)then
                    i4time_get = i4time_tmp2
                else
                    i4time_get = i4time_ref
                endif
            else
                i4time_get = i4time_ref
            endif

2010        if(.not. l_radar_read)then

              if(c_type .ne. 'rd')then ! Read data from vrc files

!               Obtain height field
                ext = 'lt1'
                var_2d = 'HT'
                call get_laps_3dgrid(
     1                   i4time_get,10000000,i4time_ht,
     1                   NX_L,NY_L,NZ_L,ext,var_2d
     1                  ,units_2d,comment_2d,field_3d,istatus)
                if(istatus .ne. 1)then
                    write(6,*)' Error locating height field'
                    return
                endif

                call get_radar_ref(i4time_get,100000,i4time_radar,mode
     1            ,.true.,NX_L,NY_L,NZ_L,lat,lon,topo,.true.,.true.
     1            ,field_3d
     1            ,grid_ra_ref,n_ref
     1            ,rlat_radar,rlon_radar,rheight_radar,istat_2dref
     1            ,istat_3dref)

              else ! 'rd' option: read data from v01, v02, etc.

                write(6,*)' Reading velocity data from the radars'

                call get_multiradar_vel(
     1            i4time_get,100000000,i4time_radar_a
     1           ,max_radars,n_radars,ext_radar_a,r_missing_data
     1           ,.true.,NX_L,NY_L,NZ_L
     1           ,grid_ra_vel,grid_ra_nyq,v_nyquist_in_a
     1           ,n_vel_grids_a
     1           ,rlat_radar_a,rlon_radar_a,rheight_radar_a,radar_name_a       
     1           ,istat_radar_vel,istat_radar_nyq)

                if(istat_radar_vel .eq. 1)then
                  write(6,*)' Radar 3d vel data successfully read in'
     1                       ,(n_vel_grids_a(i),i=1,n_radars)
                else
                  write(6,*)' Radar 3d vel data NOT successfully read in
     1'
     1                       ,(n_vel_grids_a(i),i=1,n_radars)
                  return
                endif


!               Ask which radar number (extension)
                write(6,*)
                write(6,2026)
2026            format('         Enter Radar # (for reflectivity)  '
     1                                                     ,27x,'? ',$)
                read(lun,*)i_radar

                write(6,*)' Reading reflectivity data from radar '
     1                                                       ,i_radar

!               Obtain radar time (call get_file_time - ala put_derived_wind)

!               Obtain height field
                ext = 'lt1'
                var_2d = 'HT'
                call get_laps_3dgrid(
     1                   i4time_radar_a(i_radar),1000000,i4time_ht,
     1                   NX_L,NY_L,NZ_L,ext,var_2d
     1                  ,units_2d,comment_2d,field_3d,istatus)

                write(6,*)

                call read_radar_3dref(i4time_radar_a(i_radar),
!    1               0,i4_dum
     1               .true.,NX_L,NY_L,NZ_L,ext_radar_a(i_radar),
     1               lat,lon,topo,.true.,.true.,
     1               field_3d,
     1               grid_ra_ref,
     1               rlat_radar,rlon_radar,rheight_radar,radar_name,
     1               n_ref_grids,istat_radar_2dref,istat_radar_3dref)

                     i4time_radar = i4time_radar_a(i_radar)

              endif

              call make_fnam_lp(i4time_radar,asc9_tim_r,istatus)
              l_radar_read = .true.
            endif

2015        write(6,2020)
2020        format(/'  [ve] Velocity Contours, '  
     1             ,' [vi] Velocity Image (no map)'
     1             /'  [rf] Reflectivity Data, '
     1             /'  [mr] Max Reflectivity, [vl] VIL, [mt] Max Tops,'       
     1             /'  [lr] Low Lvl Reflectivity, '
     1             ,'[f1] 1 HR Fcst Max Reflectivity,'
     1             /' ',61x,' [q] Quit ? ',$)
            read(lun,15)c_field

            if(  c_field .eq. 'rf' 
     1      .or. c_field .eq. 'vi' .or. c_field .eq. 've')then
                write(6,2021)
2021            format('         Enter Level in mb ',45x,'? ',$)
                read(lun,*)k_level

                if(k_level .gt. 0)then
                    k_level = 
     1                     nint(zcoord_of_pressure(float(k_level*100)))       
                endif

            endif

            if(c_field .eq. 'mr')then ! Reflectivity data

!               if(lapsplot_pregen)then
                if(.true.)then
                    write(6,*)' Getting pregenerated radar data file'
                    var_2d = 'R'
                    ext = 'lmr'
!                   i4time_hour = (i4time_radar+laps_cycle_time/2)
!    1                          /laps_cycle_time * laps_cycle_time
                    call get_laps_2dgrid(i4time_ref,10000,i4time_radar
     1                                  ,ext,var_2d,units_2d,comment_2d       
     1                                  ,NX_L,NY_L,radar_array,0
     1                                  ,istatus)

                else
                    call get_max_ref(grid_ra_ref,NX_L,NY_L,NZ_L
     1                              ,radar_array)

                endif

                call make_fnam_lp(i4time_radar,asc9_tim_r,istatus)

!               Display R field

                call plot_cont(radar_array,1e0,0.,chigh,cint_ref,
     1             asc9_tim_r,'LAPS  Column Max Reflectivity    ',
     1             i_overlay,c_display,lat,lon,jdot,
     1             NX_L,NY_L,r_missing_data,laps_cycle_time)

            elseif(c_field .eq. 'lr')then ! Low Lvl Reflectivity data
                i4time_hour = (i4time_radar+laps_cycle_time/2)
     1                          /laps_cycle_time * laps_cycle_time

                var_2d = 'LLR'
                ext = 'lmt'
                call get_laps_2dgrid(i4time_hour,laps_cycle_time*100
     1                              ,i4time_lr,ext,var_2d,units_2d
     1                              ,comment_2d,NX_L,NY_L
     1                              ,radar_array,0,istatus)

                call make_fnam_lp(i4time_lr,asc9_tim_r,istatus)

!               Display R field
                call plot_cont(radar_array,1e0,0.,chigh,cint_ref
     1                        ,asc9_tim_r
     1                        ,'LAPS Low LVL Reflectivity   (DBZ)'
     1                        ,i_overlay,c_display,lat,lon
     1                        ,jdot,NX_L,NY_L,r_missing_data
     1                        ,laps_cycle_time)

            elseif(c_field .eq. 've')then
                call mklabel33(k_level,'  Radial Vel  (kt) ',c33_label)

                write(6,2031)
2031            format('         Enter Radar # (of ones available)  '
     1                                                    ,28x,'? ',$)
                read(lun,*)i_radar

                call make_fnam_lp(i4time_radar_a(i_radar),asc9_tim_r
     1                                                      ,istatus)

                call plot_cont(grid_ra_vel(1,1,k_level,i_radar),.518
     1                        ,clow,chigh,5.,asc9_tim_r,c33_label
     1                        ,i_overlay,c_display,lat,lon        
     1                        ,jdot,NX_L,NY_L,r_missing_data
     1                        ,laps_cycle_time)                          

            elseif(c_field .eq. 'vi')then
                call mklabel33(k_level,'  Radial Vel  (kt) ',c33_label)

                write(6,2031)
                read(lun,*)i_radar

                call plot_obs(k_level,.false.,asc9_tim,i_radar
     1          ,NX_L,NY_L,NZ_L,grid_ra_ref,grid_ra_vel(1,1,1,i_radar)
     1          ,lat,lon,topo,2)

            elseif(c_field .eq. 'rf')then
                call mklabel33(k_level,'   Reflectivity    ',c33_label)

                call plot_cont(grid_ra_ref(1,1,k_level,1),1e0,0.,chigh
     1                        ,cint_ref,asc9_tim_r,c33_label,i_overlay
     1                        ,c_display,lat,lon,jdot,NX_L        
     1                        ,NY_L,r_missing_data,laps_cycle_time)

            elseif(c_field .eq. 'vl')then ! Do VIL

!               Initialize Radar Array
                do i = 1,NX_L
                do j = 1,NY_L
                    radar_array(i,j) = 0.
                enddo
                enddo

                do i = 1,NX_L
                do j = 1,NY_L
                do k = 1,NZ_L
                    radar_array(i,j) =
     1          max(radar_array(i,j),grid_ra_ref(i,j,k,1))

                enddo
                enddo
                enddo

                write(6,*)' Calculating VIL'
                call plot_cont(radar_array,1e0,clow,chigh,10.
     1                        ,asc9_tim_r
     1                        ,'LAPS DUMMY VIL                   '
     1                        ,i_overlay,c_display,lat,lon
     1                        ,jdot
     1                        ,NX_L,NY_L,r_missing_data,laps_cycle_time)       

            elseif(c_field .eq. 'mt')then ! Do Max Tops
                i4time_hour = (i4time_radar+laps_cycle_time/2)
     1                          /laps_cycle_time * laps_cycle_time

                var_2d = 'LMT'
                ext = 'lmt'
                call get_laps_2dgrid(i4time_hour,laps_cycle_time*100
     1                              ,i4time_lr,ext,var_2d,units_2d
     1                              ,comment_2d,NX_L,NY_L
     1                              ,radar_array,0,istatus)

                highest_top_m = 0.

                do i = 1,NX_L
                do j = 1,NY_L
                    highest_top_m = max(radar_array(i,j),highest_top_m)
                enddo ! j
                enddo ! i

!               Generate Contour Range and Interval
                cont_high = int(highest_top_m/1000.)
                cont_low = int(max(cont_high/2.,4.))

                if(cont_high - cont_low .gt. 4)then
                    cint = 2.
                else
                    cint = 1.
                endif

!               Create a floor to the array for better contouring
                do i = 1,NX_L
                do j = 1,NY_L
                    rfloor = cont_low - 0.1
                    radar_array(i,j) = radar_array(i,j) / 1000.
                    radar_array(i,j) =
     1                  max(radar_array(i,j),rfloor)
                enddo ! j
                enddo ! i

!               Display Max Tops
                write(6,*)' Displaying Max Tops, cint = '
     1                          ,cont_low,cont_high,cint
                call plot_cont(radar_array,1e0,cont_low
     1                        ,cont_high,cint,asc9_tim_r
     1                        ,'LAPS Max Echo Tops    (km MSL)   '
     1                        ,i_overlay,c_display,lat,lon
     1                        ,jdot,NX_L,NY_L,r_missing_data
     1                        ,laps_cycle_time)

            elseif(c_field .eq. 'f1')then ! Fcst Max Reflectivity

                if(lapsplot_pregen)then
                    write(6,*)' Getting pregenerated radar fcst file'

                    var_2d = 'R06'
                    ext = 'lmr'
                    i4time_hour = (i4time_radar+laps_cycle_time/2)
     1                          /laps_cycle_time * laps_cycle_time
                    call make_fnam_lp(i4time_hour,asc9_tim_r,istatus)
                    call get_laps_2d(i4time_hour,ext,var_2d,units_2d
     1                    ,comment_2d,NX_L,NY_L,radar_array_adv,istatus)       

                endif ! Pregenerated file


!               Display Advected Reflectivity Field
                call plot_cont(radar_array_adv,1e0,0.,chigh,cint_ref
     1         ,asc9_tim_r,'LAPS Max Reflectivity  1 HR Fcst',
     1          i_overlay,c_display,lat,lon,jdot,
     1          NX_L,NY_L,r_missing_data,laps_cycle_time)

!           elseif(c_field .eq. 'nt')then
!               l_radar_read = .false.
!               goto2010

            endif ! c_field

        elseif( c_type .eq. 'sn')then
            mode = 1

            call make_fnam_lp(I4time_radar,asc9_tim_r,istatus)

!           Read in surface temp data
            var_2d = 'T'
            ext = 'lsx'
            call get_laps_2dgrid(
     1          i4time_radar,laps_cycle_time,i4time_temp
     1         ,ext,var_2d,units_2d,comment_2d,NX_L,NY_L
     1         ,temp_2d,0,istatus)

            if(istatus .ne. 1)then
                write(6,*)' LAPS Sfc Temp not available'
                return
            endif

!           Read in surface dewpoint data
            var_2d = 'TD'
            ext = 'lsx'
            call get_laps_2d(i4time_temp,
     1                       ext,var_2d,units_2d,comment_2d,
     1                       NX_L,NY_L,td_2d,istatus)

            if(istatus .ne. 1)then
                write(6,*)' LAPS Sfc Dewpoint not available'
                return
            endif

!           Read in surface pressure data
            var_2d = 'PS'
            ext = 'lsx'
            call get_laps_2d(i4time_temp,
     1                       ext,var_2d,units_2d,comment_2d,NX_L,NY_L
     1                       ,pres_2d,istatus)

            if(istatus .ne. 1)then
                write(6,*)' LAPS Sfc Pressure not available'
                return
            endif

            call get_tw_approx_2d(temp_2d,td_2d,pres_2d,NX_L,NY_L,tw_sfc
     1_k)

            call zs(radar_array,temp_2d,td_2d,pres_2d,tw_sfc_k,NX_L,NY_L
     1                                                  ,snow_2d)

!           c33_label = 'LAPS Snow Rate (liq equiv) in/hr '
!           scale = 1. / ((100./2.54) * 3600.) ! DENOM = (IN/HR) / (M/S)

            c33_label = 'LAPS Snowfall Rate         in/hr '
            scale = 1. / (10. * (100./2.54) * 3600.) ! DENOM = (IN snow/HR) / (M/S)

            call plot_cont(snow_2d,scale,
     1          0.,0.,-0.1,asc9_tim_r,c33_label,
     1          i_overlay,c_display,lat,lon,jdot,
     1          NX_L,NY_L,r_missing_data,laps_cycle_time)

        elseif( c_type .eq. 'sa' .or. c_type .eq. 'pa' )then
            if(c_type .eq. 'sa')then
                write(6,1321)
1321            format('     ','Enter # of Hours of Snow Accumulation,',
     1          ' [-99 for Storm Total]     ','? ',$)
                var_2d = 'STO'
            else
                write(6,1322)
1322            format('     ','Enter # of Hours of Precip Accumulation,
     1',
     1          ' [-99 for Storm Total]   ','? ',$)
                var_2d = 'RTO'
            endif

            read(lun,*)r_hours

            write(6,*)

            ext = 'l1s'
            call get_directory(ext,directory,len_dir)

!           Cycle over at :28 after (if input time is not on the hour)
            if(i4time_ref .ne. (i4time_ref / 3600) * 3600)then
                i4time_ref1 = (i4time_ref-1680)/laps_cycle_time
     1                                        * laps_cycle_time
            else
                i4time_ref1 = i4time_ref
            endif

            if(r_hours .eq. -99.)then ! Storm Total
                write(6,*)' Getting Storm Total Accum from file'
                c9_string = 'Storm Tot'
                call get_laps_2dgrid(i4time_ref1,10000000,i4time_stm_tot
     1                  ,ext,var_2d
     1                  ,units_2d,comment_2d,NX_L,NY_L,accum_2d,0
     1                                                  ,istatus)
                write(6,*)' Storm Total was reset at ',comment_2d(1:9)
                call i4time_fname_lp(comment_2d(1:9),I4time_reset,istatu
     1s)
                istatus = 1
                num_hr_accum = (i4time_stm_tot - i4time_reset) / 3600
                i4time_accum = i4time_stm_tot
                i4time_end = i4time_stm_tot
                i4time_start = i4time_reset

!               encode(7,2017,c7_string)min(num_hr_accum,999)
                write(c7_string,2017)min(num_hr_accum,999)
2017            format(i4,' Hr')
                if(c_type .eq. 'sa')then
                    c33_label = 'LAPS Stm Tot Snow Acc (in)'//c7_string
                else
                    c33_label = 'LAPS Stm Tot Prcp Acc (in)'//c7_string
                endif

            else ! Near Realtime - look for snow accumulation files
                if(i4time_now_gg() - i4time_ref1 .lt. 300)then ! Real Time Radar
                   !Find latest time of radar data
                    if(.true.)then ! Read MHR packed data
                        c_filespec = c_filespec_ra
                    else
                        c_filespec = c_filespec_src
                    endif

                    call get_file_time(c_filespec,i4time_ref1,i4time_acc
     1um)
                else
!                   i4time_accum = (i4time_ref1+60) / 120 * 120 ! Rounded off time
                    i4time_accum = i4time_ref1
                endif

                i4time_end = i4time_accum
                i4time_interval = nint(r_hours * 3600.)
                i4time_start = i4time_end - i4time_interval

!               Round down to nearest cycle time
                i4time_endfile   = i4time_end  /laps_cycle_time*laps_cyc
     1le_time

!               Round up to nearest cycle time
                i4time_startfile = i4time_start/laps_cycle_time*laps_cyc
     1le_time

                if(i4time_start .gt. i4time_startfile)
     1          i4time_startfile = i4time_startfile + laps_cycle_time

                if(i4time_startfile .lt. i4time_endfile)then
                    istatus_file = 1
                    write(6,*)
     1     ' Looking for Storm Total Accumulations Stored In Files'

                    call get_laps_2d(i4time_endfile,ext,var_2d
     1          ,units_2d,comment_2d,NX_L,NY_L,accum_2d_buf,istatus_file
     1)
                    if(istatus_file .ne. 1)goto2100
                    comment_b = comment_2d(1:9)

                    call i4time_fname_lp(comment_2d(1:9),I4time_reset,is
     1tatus)
                    istatus = 1

                    if(i4time_startfile .ne. i4time_reset)then
                        call get_laps_2d(i4time_startfile,ext,var_2d
     1             ,units_2d,comment_2d,NX_L,NY_L,accum_2d,istatus_file)
                        if(istatus_file .ne. 1)goto2100
                        comment_a = comment_2d(1:9)

                        if(comment_a .ne. comment_b)then
                            write(6,*)' Storm Total was reset at '
     1                                            ,comment_b
!                           write(6,*)' Storm Total Clock was reset ',co
!    1mment_a
!    1                                                   ,' ',comment_b
                            write(6,*)
     1               ' Cannot subtract storm totals to get accumulation'
                            istatus_file = 0
                            goto2100
                        endif

                    else ! Reset time = Start File Time
                        write(6,*)
     1           ' Start File Time = Reset time, Set Init Accum to 0'
                        call zero(accum_2d,NX_L,NY_L)

                    endif

                    write(6,*)
     1     ' Subtracting Storm Totals to yield Accumulation over period'
                    call diff(accum_2d_buf,accum_2d,accum_2d,NX_L,NY_L)

                    do j = 1,NY_L
                    do i = 1,NX_L
                        if(accum_2d(i,j) .lt. 0.)then
                            write(6,*)' This should never happen:'
                            write(6,*)' Negative accum; Storm Total was
     1reset'
                            istatus_file = 0
                            goto2100
                        endif
                    enddo ! i
                    enddo ! j

                else
                    istatus_file = 0

                endif

2100            if(istatus_file .eq. 1)then ! Fill in ends of Pd with radar etc. data
                    if(i4time_start .lt. i4time_startfile)then
                        write(6,*)' Sorry, no L1S files present'
                        goto 1200

                    endif

                    if(i4time_end .gt. i4time_endfile)then
                        write(6,*)' Sorry, no L1S files present'
                        goto 1200

                    endif

                else ! Get entire time span from radar etc. data

                 write(6,*)' Sorry, no L1S files present'
                 goto 1200

!                write(6,*)
!    1       ' Getting Entire Time Span of Accumulation from Radar Data,
!    1 etc.'

!                   if(c_type .eq. 'sa')then
!                       call move(snow_2d,accum_2d,NX_L,NY_L)
!                   else
!                       call move(precip_2d,accum_2d,NX_L,NY_L)
!                   endif

                endif

!               encode(9,2029,c9_string)r_hours
                write(c9_string,2029)r_hours
2029            format(f5.1,' Hr ')

                if(c_type .eq. 'sa')then
                    c33_label = 'LAPS '//c9_string//' Snow Accum  (in)
     1'
                else
                    c33_label = 'LAPS '//c9_string//' Prcp Accum  (in)
     1'
                endif

            endif

            if(istatus .ne. 1)goto1200

            call make_fnam_lp(I4time_accum,asc9_tim_r,istatus)

            scale = 1. / ((100./2.54)) ! DENOM = (IN/M)


            if(c_type .eq. 'pa')then
                if(abs(r_hours) .gt. 1.0)then
                    cint = -0.05
                else
                    cint = -0.01
                endif
                chigh = 50.
            else ! 'sa'
                if(abs(r_hours) .gt. 1.0)then
                    cint = -0.2
                else
                    cint = -0.1
                endif
                chigh = 200.
            endif

!           Eliminate "minor" maxima
            do j = 1,NY_L
            do i = 1,NX_L
                if(c_type .eq. 'pa')then
                    if(accum_2d(i,j)/scale .lt. 0.005)then
                        accum_2d(i,j) = 0.0
                    endif
!                   if(accum_2d(i,j)/scale .le. 0.0001)then
!                       accum_2d(i,j) = -1e-6
!                   endif
                else
                    if(accum_2d(i,j)/scale .lt. 0.05)then
                        accum_2d(i,j) = 0.0
                    endif
!                   if(accum_2d(i,j)/scale .le. 0.0001)then
!                       accum_2d(i,j) = -1e-6
!                   endif
                endif
            enddo ! i
            enddo ! j

            call plot_cont(accum_2d,scale,
     1             0.,chigh,cint,asc9_tim_r,c33_label,
     1             i_overlay,c_display,lat,lon,jdot,
     1             NX_L,NY_L,r_missing_data,laps_cycle_time)

        elseif( c_type .eq. 'rx')then
            write(6,1311)
1311        format('     ','Enter # of Hours of Radar Data,',
     1          ' [-99 for Storm Total]     ','? ',$)
            read(lun,*)r_hours

            write(6,*)

            i4time_accum = (i4time_ref+60) / 120 * 120 ! Rounded off time
            i4time_end = i4time_accum
            i4time_interval = nint(r_hours * 3600.)
            i4time_start = i4time_end - i4time_interval

            if(.true.)then ! Get entire time span from radar etc. data
                 write(6,*)
     1           ' Getting Entire Time Span of Accumulation from Radar '       
     1          ,'Data, etc.'
                 call get_radar_max_pd(i4time_start,i4time_end
     1                ,NX_L,NY_L,NZ_L,lat,lon,topo,grid_ra_ref
     1                ,dummy_array,radar_array,frac_sum,istatus)

            endif

!           encode(9,2029,c9_string)r_hours
            write(c9_string,2029)r_hours
!2029        format(f5.1,' Hr ')

            c33_label = 'LAPS '//c9_string//' Reflctvty History '

            if(istatus .ne. 1)goto1200

            call make_fnam_lp(I4time_accum,asc9_tim_r,istatus)

            scale = 1.

            if(.false.)then
                write(6,*)' writing LRX field in current directory'
                directory = '[]'
                ext = 'lrx'
                var_2d = 'LRX'
                call put_laps_2d(i4time_accum,ext,var_2d
     1          ,units_2d,comment_2d,NX_L,NY_L,radar_array,istatus)
            endif

            call plot_cont(radar_array,scale,
     1          0.,80.,cint_ref,asc9_tim_r,c33_label,
     1          i_overlay,c_display,lat,lon,jdot,
     1          NX_L,NY_L,r_missing_data,laps_cycle_time)

        elseif( c_type .eq. 't'  .or. c_type .eq. 'pt'
     1     .or. c_type .eq. 'bt' .or. c_type .eq. 'pb')then
            write(6,1513)
1513        format('     Enter Level in mb',48x,'? ',$)
            read(lun,*)level_mb

!           if(istatus .ne. 1)goto1200

            if(level_mb .gt. 0)then
                k_level = nint(zcoord_of_pressure(float(level_mb*100)))       
!           else
!               k_level = level_mb
            endif

            if(c_type .eq. 'pt')then
                iflag_temp = 0 ! Returns Potential Temperature
                call get_temp_3d(i4time_ref,i4time_nearest,iflag_temp
     1                          ,NX_L,NY_L,NZ_L,temp_3d,istatus)

                call mklabel33(k_level,'  Potential Temp  K',c33_label)

                do i = 1,NX_L
                do j = 1,NY_L
                    temp_2d(i,j) = temp_3d(i,j,k_level)
                enddo ! j
                enddo ! i

            elseif(c_type .eq. 'pb')then
                iflag_temp = 3 ! Returns Balanced Potential Temperature
                call get_temp_3d(i4time_ref,i4time_nearest,iflag_temp
     1                          ,NX_L,NY_L,NZ_L,temp_3d,istatus)

                call mklabel33(k_level,'  Balanced Theta  K',c33_label)

                do i = 1,NX_L
                do j = 1,NY_L
                    temp_2d(i,j) = temp_3d(i,j,k_level)
                enddo ! j
                enddo ! i

            elseif(c_type .eq. 't ')then
                call get_temp_2d(i4time_ref,7200,i4time_nearest
     1                          ,level_mb,NX_L,NY_L,temp_2d,istatus)

                call mklabel33(k_level,' Temperature      C',c33_label)       

             elseif(c_type.eq. 'bt')then
                var_2d = 'T3'
                ext='lt1'

                call get_directory('balance',directory,lend)
                directory=directory(1:lend)//'lt1/'
                call get_2dgrid_dname(directory
     1           ,i4time_ref,laps_cycle_time*10000,i4time_nearest
     1           ,ext,var_2d,units_2d,comment_2d
     1           ,NX_L,NY_L,temp_2d,level_mb,istatus)       

                call mklabel33(k_level,' Temp (Bal)       C',c33_label)

            endif

            call make_fnam_lp(i4time_nearest,asc9_tim_t,istatus)

!           call get_pres_3d(i4time_nearest,NX_L,NY_L,NZ_L,pres_3d
!    1                                     ,istatus)

!           if(pres_3d(icen,jcen,k_level) .le. 80000.)then
!               clow =  0.
!               chigh = 0.
!               cint = 2.
!           else
!               clow =  0.
!               chigh = 0.
!               cint = 5.
!           endif

            scale = 1.
            call contour_settings(temp_2d,NX_L,NY_L,clow,chigh,cint
     1                                                   ,zoom,scale)

            call plot_cont(temp_2d,scale,clow,chigh,cint,
     1                     asc9_tim_t,c33_label,
     1                     i_overlay,c_display,lat,lon,jdot,
     1                     NX_L,NY_L,r_missing_data,laps_cycle_time)

            i4time_temp = i4time_nearest

        elseif(c_type .eq. 'hh')then
            write(6,1515)
1515        format('     Enter Temperature surface to display '
     1                      ,'height of (deg C)',11x,'? ',$)
            read(lun,*)temp_in_c
            temp_in_k = temp_in_c + 273.15

            iflag_temp = 1 ! Returns Ambient Temperature

            call get_temp_3d(i4time_ref,i4time_nearest,iflag_temp
     1                          ,NX_L,NY_L,NZ_L,temp_3d,istatus)
            if(istatus .ne. 1)goto1200

!           Obtain height field
            ext = 'lt1'
            var_2d = 'HT'
            call get_laps_3dgrid(i4time_ref,10000000,i4time_ht
     1                          ,NX_L,NY_L,NZ_L,ext,var_2d
     1                          ,units_2d,comment_2d,field_3d,istatus)
            if(istatus .ne. 1)then
                write(6,*)' Error locating height field'
                return
            endif

            write(c33_label,1516)nint(temp_in_c)
1516        format('LAPS Height of ',i3,'C Lvl (hft MSL)')

            do j = 1,NY_L
            do i = 1,NX_L
                height_2d(i,j) = 0.

                do k = 1,NZ_L-1
                    if(temp_3d(i,j,k  ) .gt. temp_in_k  .and.
     1                 temp_3d(i,j,k+1) .le. temp_in_k       )then

!                       Desired Temperature occurs in this layer
                        frac_k = (     temp_in_k - temp_3d(i,j,k))/
     1                         (temp_3d(i,j,k+1) - temp_3d(i,j,k))

                        height_2d(i,j) = field_3d(i,j,k) * (1.0-frac_k)       
     1                 +                 field_3d(i,j,k+1) * frac_k

                        height_2d(i,j) = height_2d(i,j) * 3.281

                    endif
                enddo ! k
            enddo ! i
            enddo ! j

            clow = 0.
            chigh = 0.
            cint = 5.

            call make_fnam_lp(i4time_nearest,asc9_tim_t,istatus)

            call plot_cont(height_2d,1e2,clow,chigh,cint,asc9_tim_t,
     1       c33_label,i_overlay,c_display,lat,lon,jdot,
     1       NX_L,NY_L,r_missing_data,laps_cycle_time)

        elseif(c_type .eq. 'la' .or. c_type .eq. 'lj' .or.
     1         c_type .eq. 'sj' .or. c_type .eq. 'ls' .or.
     1         c_type .eq. 'ss' .or. c_type .eq. 'ci'       )then
            write(6,1514)
1514        format('     Enter Level in mb; OR [-1] for max in column'
     1                          ,21x,'? ',$)
            read(lun,*)k_level
            k_mb = k_level

            if(k_level .gt. 0)then
               k_level = nint(zcoord_of_pressure(float(k_level*100)))
            endif

            i4time_lwc = i4time_ref/laps_cycle_time * laps_cycle_time

!           if(i4time_now_gg() - i4time_lwc .lt. 43200
!       1                               .and. c_type .eq. 'ls')then
                l_pregen = lapsplot_pregen
!           else
!               l_pregen = .false.
!           endif

            if(c_type .eq. 'la')then
                iflag_slwc = 1 ! Returns Adiabatic LWC
                if(k_level .gt. 0)then
                    call mklabel33(k_level,
     1          ' Adiabt LWC  g/m^3 ',c33_label)
                else
                    c33_label = 'LAPS Maximum Adiabatic LWC g/m^3 '
                endif

            elseif(c_type .eq. 'lj')then
                iflag_slwc = 2 ! Returns Adjusted LWC
                if(k_level .gt. 0)then
                    call mklabel33(k_level,
     1          ' Adjstd LWC  g/m^3 ',c33_label)
                else
                    c33_label = 'LAPS Maximum Adjusted  LWC g/m^3 '
                endif

            elseif(c_type .eq. 'sj')then
                iflag_slwc = 3 ! Returns Adjusted SLWC
                if(k_level .gt. 0)then
                    call mklabel33(k_level,
     1          ' Adjstd SLWC g/m^3 ',c33_label)
                else
                    c33_label = 'LAPS Maximum Adjusted SLWC g/m^3 '
                endif

            elseif(c_type .eq. 'ls')then
                iflag_slwc = 13 ! Returns New Smith - Feddes LWC
                if(k_level .gt. 0)then
                    call mklabel33(k_level,
!    1                             ' Smt-Fed LWC g/m^3 ',c33_label)
     1                             ' Cloud LWC g/m^3   ',c33_label)
                else
!                   c33_label = 'LAPS Max Smith-Feddes  LWC g/m^3 '
                    c33_label = 'LAPS Column Max LWC        g/m^3 '
                endif

            elseif(c_type .eq. 'ci')then
                iflag_slwc = 13 ! Returns Cloud Ice
                if(k_level .gt. 0)then
                    call mklabel33(k_level,
!    1                             ' Smt-Fed ICE g/m^3 ',c33_label)
     1                             ' Cloud ICE g/m^3   ',c33_label)
                else
                    c33_label = 'LAPS Max Smith-Feddes  ICE g/m^3 '
                endif

            elseif(c_type .eq. 'ss')then
                iflag_slwc = 14 ! Returns Smith - Feddes SLWC
                if(k_level .gt. 0)then
                    call mklabel33(k_level,
     1                             'Smt-Fed SLWC g/m^3 ',c33_label)
                else
!                   c33_label = 'LAPS Max Smith-Feddes SLWC g/m^3 '
                    c33_label = 'LAPS Column Max SLWC       g/m^3 '
                endif

            endif


            if(l_pregen)then
                write(6,*)' Getting pregenerated LWC file'
                if(c_type .ne. 'ci')then
                    var_2d = 'LWC'
                else
                    var_2d = 'ICE'
                endif
                ext = 'lwc'
                call get_directory(ext,directory,len_dir)

                if(k_mb .eq. -1)then ! Get 3D Grid
                  if(c_type .ne. 'ci')then
                    call get_laps_3dgrid(i4time_ref,86400,i4time_cloud,
     1                                   NX_L,NY_L,NZ_L,ext,var_2d
     1                            ,units_2d,comment_2d,field_3d,istatus) ! slwc_3d
                  else
                    call get_laps_3dgrid(i4time_ref,86400,i4time_cloud,
     1                                   NX_L,NY_L,NZ_L,ext,var_2d
     1                            ,units_2d,comment_2d,field_3d,istatus) ! cice_3d
                  endif

                else ! Get 2D horizontal slice from 3D Grid
                  if(c_type .ne. 'ci')then
                    call get_laps_2dgrid(i4time_ref,86400,i4time_cloud,
     1                                   ext,var_2d,units_2d,
     1                                   comment_2d,NX_L,NY_L,slwc_2d,
     1                                   k_mb,istatus)
                  else
                    call get_laps_2dgrid(i4time_ref,86400,i4time_cloud,
     1                                   ext,var_2d,units_2d,comment_2d,
     1                                   NX_L,NY_L,cice_2d,k_mb,istatus)       
                  endif

                endif

            endif ! L_pregen

            call make_fnam_lp(i4time_lwc,asc9_tim_t,istatus)

            clow = 0.
            chigh = 0.
            cint = -0.1

            if(k_level .gt. 0)then ! Plot SLWC on const pressure sfc
               if(c_type .ne. 'ci')then
!                if(l_pregen)then
                   call subcon(slwc_2d,1e-30,field_2d,NX_L,NY_L)
                   call plot_cont(field_2d,1e-3,clow,chigh,cint
     1                           ,asc9_tim_t,c33_label,i_overlay
     1                           ,c_display,lat,lon,jdot
     1                           ,NX_L,NY_L,r_missing_data
     1                           ,laps_cycle_time)

               else ! c_type .ne. 'ci'
                   call subcon(cice_2d,1e-30,field_2d,NX_L,NY_L)
                   call plot_cont(field_2d,1e-3,clow,chigh,cint
     1                           ,asc9_tim_t,c33_label,i_overlay
     1                           ,c_display,lat,lon,jdot
     1                           ,NX_L,NY_L,r_missing_data
     1                           ,laps_cycle_time)

               endif ! c_type

            else ! Find Maximum value in column
               do j = 1,NY_L
               do i = 1,NX_L
                   column_max(i,j) = 0.
                   if(c_type .ne. 'ci')then
                     do k = 1,NZ_L
                       column_max(i,j) = 
     1                 max(column_max(i,j),field_3d(i,j,k)) ! slwc_3d
                     enddo ! k
                   else
                     do k = 1,NZ_L
                       column_max(i,j) = 
     1                 max(column_max(i,j),field_3d(i,j,k)) ! cice_3d
                     enddo ! k
                   endif
               enddo ! i
               enddo ! j

               call subcon(column_max,1e-30,field_2d,NX_L,NY_L)

               call plot_cont(field_2d,1e-3,
     1                        clow,chigh,cint,asc9_tim_t,c33_label,
     1                        i_overlay,c_display,lat,lon,
     1                        jdot,NX_L,NY_L,r_missing_data,
     1                        laps_cycle_time)

            endif

        elseif(c_type .eq. 'mv' .or. c_type .eq. 'ic')then
            write(6,1514)

            read(lun,*)k_level
            k_mb = k_level

            if(k_level .gt. 0)then
               k_level = nint(zcoord_of_pressure(float(k_level*100)))
            endif

            i4time_lwc = i4time_ref/laps_cycle_time * laps_cycle_time

            if(c_type .eq. 'mv')then
                if(k_level .gt. 0)then
                    call mklabel33(k_level
     1                            ,'     MVD     m^-6  ',c33_label)     
                else
                    c33_label = 'LAPS Mean Volume Diameter  m^-6  '
                endif

                write(6,*)' Getting pregenerated LMD file'
                var_2d = 'LMD'
                ext = 'lmd'

            elseif(c_type .eq. 'ic')then
                if(k_level .gt. 0)then
                    call mklabel33(k_level,'   Icing Index     '
     1                            ,c33_label)
                else
                    c33_label = '        LAPS Icing Index         '
                endif

                write(6,*)' Getting pregenerated LRP file'
                var_2d = 'LRP'
                ext = 'lrp'

            endif ! c_type .eq. 'ic'

            if(k_mb .eq. -1)then ! Get 3D Grid
                call get_laps_3dgrid(i4time_ref,10000000
     1                                  ,i4time_cloud
     1                                  ,NX_L,NY_L,NZ_L,ext,var_2d
     1                                  ,units_2d,comment_2d,field_3d ! slwc_3d
     1                                  ,istatus)

            else ! Get 2D horizontal slice from 3D Grid
                call get_laps_2dgrid(i4time_ref,10000000
     1                                  ,i4time_cloud
     1                                  ,ext,var_2d
     1                                  ,units_2d,comment_2d,NX_L
     1                                  ,NY_L,field_2d,k_mb,istatus)

            endif


            call make_fnam_lp(i4time_cloud,asc9_tim_t,istatus)

            if(c_type .eq. 'mv')then
                clow = 10.
                chigh = 26.
                cint = 2.

                if(k_level .gt. 0)then ! Plot MVD on const pressure sfc
                   if(.true.)then
                       call subcon(mvd_2d,1e-30,field_2d,NX_L,NY_L)
                       call plot_cont(field_2d,0.9999e-6,
     1                   clow,chigh,cint,asc9_tim_t,c33_label,
     1                   i_overlay,c_display,lat,lon,jdot,
     1                   NX_L,NY_L,r_missing_data,laps_cycle_time)
                   else
                       call plot_cont(field_3d(1,1,k_level),0.9999e-6, ! mvd_3d
     1                   clow,chigh,cint,asc9_tim_t,c33_label,
     1                   i_overlay,c_display,lat,lon,jdot,
     1                   NX_L,NY_L,r_missing_data,laps_cycle_time)
                   endif

                else ! Find Maximum value in column
                   do j = 1,NY_L
                   do i = 1,NX_L
                       column_max(i,j) = -1e-30
                       do k = 1,NZ_L
                           column_max(i,j) = max(column_max(i,j)
     1                                          ,field_3d(i,j,k))      ! mvd_3d
                       enddo ! k
                   enddo ! i
                   enddo ! j

                   call plot_cont(column_max,0.9999e-6,
     1               clow,chigh,cint,asc9_tim_t,c33_label,
     1               i_overlay,c_display,lat,lon,jdot,
     1               NX_L,NY_L,r_missing_data,laps_cycle_time)

                endif

            elseif(c_type .eq. 'ic')then
                clow = 0.
                chigh = 10.
                cint = 1.0

                if(k_level .gt. 0)then ! Plot on const pressure sfc
                   if(.true.)then
                       call plot_cont(field_2d,1e0,clow,chigh,cint
     1                      ,asc9_tim_t
     1                      ,c33_label,i_overlay,c_display
     1                      ,lat,lon,jdot
     1                      ,NX_L,NY_L,r_missing_data,laps_cycle_time)

                   endif

                else ! Find Maximum value in column
                   if(.true.)then
                       do j = 1,NY_L
                       do i = 1,NX_L
                           column_max(i,j) = -1e-30
                           do k = 1,NZ_L
                            if(field_3d(i,j,k) .gt. 0.)column_max(i,j) ! slwc_3d
     1                     = max(column_max(i,j),field_3d(i,j,k)+.01)       
                           enddo ! k
                       enddo ! i
                       enddo ! j
                   endif

                   call plot_cont(column_max,1e0,
     1                  clow,chigh,cint,asc9_tim_t,c33_label,
     1                  i_overlay,c_display,lat,lon,jdot,
     1                  NX_L,NY_L,r_missing_data,laps_cycle_time)

                endif ! k_level

            endif ! c_type

        elseif(c_type .eq. 'cy')then
1524        write(6,1517)
1517        format('     Enter Lvl (mb); OR [0] 2D cldtyp'
!    1          ,' [-1] low cloud,'
!    1          ,' [-2] high cloud'
     1          ,' ? ',$)

1525        read(lun,*)k_level
            k_mb = k_level

            if(k_level .lt. 0)then
                write(6,*)' Try Again'
                goto1524
            endif

            if(.true.)then ! Read 2D cloud type field

                if(k_level .gt. 0)then ! Read from 3-D cloud type
                   k_level =
     1                   nint(zcoord_of_pressure(float(k_level*100)))
                    ext = 'lty'
                    var_2d = 'CTY'
                    call mklabel33
     1                    (k_level,'     Cloud Type    ',c33_label)

                else                   ! Read from 2-D cloud type
                    ext = 'lct'
                    var_2d = 'SCT'
                    c33_label = '      LAPS    2-D Cloud Type     '

                endif


                call get_laps_2dgrid(i4time_ref,laps_cycle_time*100
     1            ,i4time_cloud,ext,var_2d
     1            ,units_2d,comment_2d,NX_L,NY_L,field_2d,k_mb,istatus)

                IF(istatus .ne. 1 .and. istatus .ne. -1)THEN
                    write(6,*)' Error reading cloud type'
                    goto 1200
                endif

                call make_fnam_lp(i4time_cloud,asc9_tim,istatus)

!               Convert from real to byte
                do i = 1,NX_L
                do j = 1,NY_L
!                   Convert to byte
                    b_array(i,j) = i4_to_byte(int(field_2d(i,j)))
                enddo ! i
                enddo ! j


                call plot_cldpcp_type(b_array
     1                ,asc9_tim,c33_label,c_type,k,i_overlay,c_display
     1                ,lat,lon,idum1_array
     1                ,NX_L,NY_L,laps_cycle_time,jdot)

            else ! OLD ARCHAIC CODE

            endif ! k_level .eq. 0


        elseif(c_type .eq. 'tp' .or. c_type .eq. 'py')then
1624        write(6,1617)
1617        format('     Enter Level in mb; [0] for surface,'
     1          ,' OR [-1] for sfc thresholded: ','? ',$)

1625        read(lun,*)k_level
            k_mb = k_level

            if(k_level .gt. 0)then
                call mklabel33(k_level,'    Precip Type    ',c33_label)
            elseif(k_level .eq.  0)then
                c33_label = 'LAPS Sfc Precip Type   (nothresh)'
            elseif(k_level .eq. -1)then
                c33_label = 'LAPS Sfc Precip Type   (thresh)  '
            endif

            if(k_level .eq. -1)then
                var_2d = 'PTT'
                k_level = 0
            else
                var_2d = 'PTY'
            endif

            if(k_level .gt. 0)then
               k_level = nint(zcoord_of_pressure(float(k_level*100)))
            endif

            i4time_pcp = i4time_ref/laps_cycle_time * laps_cycle_time

            l_precip_pregen = .true.

            if(k_level .gt. 0)then ! Plot Precip Type on const pressure sfc
                if(l_precip_pregen)then ! Read pregenerated field

                    write(6,*)' Reading pregenerated precip type field'
                    ext = 'lty'
                    call get_laps_2dgrid(i4time_pcp,laps_cycle_time
     1                    ,i4time_nearest,ext,var_2d
     1                    ,units_2d,comment_2d,NX_L,NY_L
     1                    ,field_2d,k_mb,istatus)

!                   Convert from real to byte
                    do i = 1,NX_L
                    do j = 1,NY_L
!                       Convert to integer
                        iarg = int(field_2d(i,j)) * 16
!                       Convert to byte
                        pcp_type_2d(i,j) = i4_to_byte(iarg)
                    enddo ! i
                    enddo ! j

                    call make_fnam_lp(i4time_nearest,asc9_tim,istatus)

                    call plot_cldpcp_type(pcp_type_2d
     1              ,asc9_tim,c33_label,c_type,k_level,i_overlay
     1              ,c_display,lat,lon,idum1_array
     1              ,NX_L,NY_L,laps_cycle_time,jdot)

                endif

            elseif(k_level .eq. 0)then ! Extract Surface Precip Type Field

                if(l_precip_pregen)then

                  ! Read SFC precip type from lty field
                    write(6,*)
     1              ' Reading pregenerated SFC precip type field '
     1                  ,var_2d      

!                   var_2d was defined earlier in the if block
                    ext = 'lct'
                    call get_laps_2dgrid(i4time_pcp,laps_cycle_time
     1                                  ,i4time_temp,
     1                      ext,var_2d,units_2d,comment_2d,NX_L,NY_L
     1                                          ,field_2d,0,istatus)

                    if(istatus .ne. 1)goto1200

                    call make_fnam_lp(i4time_temp,asc9_tim,istatus)

!                   Convert from real to byte
                    do i = 1,NX_L
                    do j = 1,NY_L
                        iarg = field_2d(i,j) * 16 ! Code into left 4 bits
                        pcp_type_2d(i,j) = i4_to_byte(iarg)
                    enddo ! i
                    enddo ! j

                endif ! l_precip_pregen

                call plot_cldpcp_type(pcp_type_2d
     1             ,asc9_tim,c33_label,c_type,k,i_overlay,c_display  
     1             ,lat,lon,idum1_array
     1             ,NX_L,NY_L,laps_cycle_time,jdot)

            endif ! k_level

        elseif(c_type .eq. 'ia' .or. c_type .eq. 'ij'
     1                          .or. c_type .eq. 'is')then

          ext = 'lil'
          var_2d = 'LIL'
          call get_laps_2dgrid(i4time_ref,86400,i4time_cloud,
     1                         ext,var_2d,units_2d,comment_2d,
     1                         NX_L,NY_L,column_max,0,istatus)

          call make_fnam_lp(i4time_cloud,asc9_tim_t,istatus)
          c33_label = 'LAPS Integrated LWC         (mm) '

          clow = 0.
          chigh = +0.
          cint = -0.1

          call plot_cont(column_max,1e-3,
     1          clow,chigh,cint,asc9_tim_t,c33_label,
     1          i_overlay,c_display,lat,lon,jdot,
     1          NX_L,NY_L,r_missing_data,laps_cycle_time)

        elseif(c_type .eq. 'pe' .or. c_type .eq. 'ne')then
          ext = 'lst'

          if(c_type .eq. 'pe')then
              var_2d = 'PBE'

              call get_laps_2dgrid(i4time_ref,10000000,i4time_temp,
     1        ext,var_2d,units_2d,comment_2d,NX_L,NY_L
     1                                          ,field_2d,0,istatus)

          else
              var_2d = 'NBE'

              call get_laps_2dgrid(i4time_ref,10000000,i4time_temp,
     1        ext,var_2d,units_2d,comment_2d,NX_L,NY_L
     1                                          ,field_2d,0,istatus)

          endif

          call make_fnam_lp(i4time_temp,asc9_tim_t,istatus)


          scale = 1.
          call make_fnam_lp(i4time_temp,asc9_tim_t,istatus)

          if(c_type .eq. 'pe')then
!             Change flag value 
              do i = 1,NX_L
              do j = 1,NY_L
                  if(field_2d(i,j) .eq. r_missing_data)
     1                field_2d(i,j) = -1.           
              enddo ! j
              enddo ! i

              c33_label = 'LAPS CAPE                (J/KG)  '
              clow = 0.
              chigh = 8000.
              cint = +400.
              call plot_cont(field_2d,scale,clow,chigh,cint,asc9_tim_t,
     1                       c33_label,i_overlay,c_display,
     1                       lat,lon,jdot,
     1                       NX_L,NY_L,r_missing_data,laps_cycle_time)

          elseif(c_type .eq. 'ne')then
!             Change flag value (for now)
              do i = 1,NX_L
              do j = 1,NY_L
                  if(field_2d(i,j) .eq. -1e6)
     1                field_2d(i,j) = r_missing_data
                  if(field_2d(i,j) .ge. -2. .and. 
     1               field_2d(i,j) .ne. r_missing_data)
     1                                   field_2d(i,j) = +.0001
              enddo ! j
              enddo ! i

              c33_label = 'LAPS CIN                 (J/KG)  '
              clow = -500 !   0.
              chigh = 0.  !   0.
              cint = 50.  ! -10.
              call plot_cont(field_2d,scale,clow,chigh,cint,asc9_tim_t    
     1                      ,c33_label,i_overlay,c_display
     1                      ,lat,lon,jdot,NX_L,NY_L,r_missing_data
     1                      ,laps_cycle_time)
          endif
c
c J. Smart - 4/19/99. Updated moisture plotting. In addition, added two
c                     more switches for lga/fua plotting.
c
        elseif(c_type .eq. 'lq')then
c
c J. Smart - 4/19/99. lq is LAPS-lq3 either sh or rh
c
            print*,'You selected plotting of lq3 data '

            write(6,1513)
            read(lun,*)k_level
            if(k_level .gt. 0)then
               k_level = nint(zcoord_of_pressure(float(k_level*100)))
            endif

            write(6,1615)
1615        format(10x,'plot rh or q [r/q]  ? ',$)
            read(5,*)qtype

            if(qtype.eq.'q')then

              var_2d = 'SH '
              ext = 'lq3'

              call get_laps_3dgrid
     1        (i4time_ref,1000000,i4time_nearest,NX_L,NY_L,NZ_L
     1          ,ext,var_2d,units_2d,comment_2d
     1                                  ,field_3d,istatus) ! q_3d
              if(istatus.ne. 1)then
                 print*,'No plotting for the requested time period'
              else   

              call mklabel33(k_level,' LAPS Spec Hum x1e3',c33_label)

              clow = 0.
              chigh = +40.
              cint = 0.2
c             cint = -1.

              call make_fnam_lp(i4time_nearest,asc9_tim_t,istatus)

              call plot_cont(field_3d(1,1,k_level),1e-3,clow,chigh,cint, ! q_3d
     1             asc9_tim_t,c33_label,i_overlay,c_display
     1             ,lat,lon,jdot,
     1             NX_L,NY_L,r_missing_data,laps_cycle_time)
              endif

            elseif(qtype .eq. 'r')then

              write(6,1616)
1616          format(10x,'plot rh3 or rhl [3/l]? ',$)
              read(5,*)qtype

              ext = 'lh3'

              if(qtype .eq. '3')then
                 var_2d = 'RH3'
                 write(6,*)' Reading rh3 / ',var_2d
                 call mklabel33(k_level,' LAPS RH     (rh3) %'
     1                                 ,c33_label)     
              elseif(qtype .eq. 'l')then
                 var_2d = 'RHL'
                 write(6,*)' Reading rhl / ',var_2d
                 call mklabel33(k_level,' LAPS RH     (liq) %'
     1                                 ,c33_label)     
              endif

              call get_laps_3dgrid(i4time_ref,1000000,i4time_nearest
     1                            ,NX_L,NY_L,NZ_L
     1                            ,ext,var_2d,units_2d,comment_2d
     1                            ,field_3d,istatus)
              if(istatus.ne. 1)then
                 print*,'No plotting for the requested time period'
              else

              clow = 0.
              chigh = +100.
              cint = 10.

              call make_fnam_lp(i4time_nearest,asc9_tim_t,istatus)

              call plot_cont(field_3d(1,1,k_level),1e0,clow,chigh,cint,       
     1           asc9_tim_t,c33_label,i_overlay,
     1           c_display,lat,lon,jdot,
     1           NX_L,NY_L,r_missing_data,laps_cycle_time)

              endif
            endif

        elseif(c_type .eq. 'br'.or.c_type.eq.'fr')then
c
c J. Smart - 4/19/99. br is LAPS-lga either sh or rh (sh is converted to rh).
c
            ext='lga'
            if(c_type.eq.'fr')ext='fua'

            print*,'      plotting ',ext(1:3),' humidity data'

            call input_background_info(
     1                              ext                     ! I
     1                             ,directory               ! O
     1                             ,i4time_ref              ! I
     1                             ,laps_cycle_time         ! I
     1                             ,asc9_tim_t              ! O
     1                             ,fcst_hhmm               ! O
     1                             ,i4_initial              ! O
     1                             ,i4_valid                ! O
     1                             ,istatus)                ! O
            if(istatus.ne.1)goto1200

            write(6,1513)
            read(lun,*)k_level
            k_mb=k_level
            if(k_level .gt. 0)then
               k_level = nint(zcoord_of_pressure(float(k_level*100)))
            endif

            write(6,1615)
            read(5,*)qtype

            var_2d = 'SH '
            CALL READ_LAPS(i4_initial,i4_valid,DIRECTORY,
     1                                 EXT,NX_L,NY_L,1,1,       
     1                                 VAR_2d,k_mb,LVL_COORD_2d,
     1                                 UNITS_2d,COMMENT_2d,
     1                                 sh_2d,istat_sh)

            var_2d = 'RH3'
            CALL READ_LAPS(i4_initial,i4_valid,DIRECTORY,
     1                                 EXT,NX_L,NY_L,1,1,       
     1                                 VAR_2d,k_mb,LVL_COORD_2d,
     1                                 UNITS_2d,COMMENT_2d,
     1                                 rh_2d,istat_rh)
            if(istat_rh .eq. 0 .and. istat_sh .eq. 0)then
                print*,' RH/SH not obtained from ',ext(1:3)
                print*,'no plotting of data for requested time period'
                goto1200
            endif


            if(.true.)then

                if(qtype.eq.'q' .and. istat_sh .eq. 1)then

                    call mklabel33(k_level,' '//fcst_hhmm
     1                         //' '//ext(1:3)//' Q  (x1e3)',c33_label)

                    clow = 0.
                    chigh = +40.
                    cint = 0.2
c                   cint = -1.

                    call plot_cont(sh_2d,1e-3
     1                            ,clow,chigh,cint ! q_3d
     1                            ,asc9_tim_t,c33_label,i_overlay
     1                            ,c_display
     1                            ,lat,lon,jdot,NX_L,NY_L
     1                            ,r_missing_data,laps_cycle_time)

                elseif(qtype .eq. 'r')then
                    if(istat_rh .eq. 0 .and. istat_sh .eq. 1)then

                        write(6,1635)
1635                    format(10x
     1                       ,'input t_ref for RH calc [deg C] ? ',$)
                        read(5,*)t_ref

                        var_2d = 'T3 '
                        CALL READ_LAPS(i4_initial,i4_valid,DIRECTORY,
     1                                 EXT,NX_L,NY_L,1,1,       
     1                                 VAR_2d,k_mb,LVL_COORD_2d,
     1                                 UNITS_2d,COMMENT_2d,
     1                                 temp_2d,ISTATUS)

                        if(istatus.ne.1)then
                            print*,var_2d, ' not obtained from '
     1                            ,ext(1:3)
                        endif


                        call mklabel33(k_level,' '//fcst_hhmm
     1                         //' '//ext(1:3)//' rh %cptd ',c33_label)

                        clow = 0.
                        chigh = +100.
                        cint = 10.

                        call make_fnam_lp(i4_valid,asc9_tim_t,istatus)

                        do i = 1,NX_L
                        do j = 1,NY_L
                            rh_2d(i,j)=make_rh(float(k_mb)
     1                         ,temp_2d(i,j)-273.15
     1                         ,sh_2d(i,j)*1000.,t_ref)*100. ! q_3d
                        enddo ! j
                        enddo ! i

                    elseif(istat_rh .eq. 1)then
                        write(6,1636)
1636                    format(10x,'OK to plot RH as read in ? ',$)
                        read(5,*)directory   

                        if(directory(1:1) .eq. 'n' 
     1                .OR. directory(1:1) .eq. 'N')then
                            goto1200
                        endif

                        call mklabel33(k_level,' '//fcst_hhmm
     1                         //' '//ext(1:3)//' rh %     ',c33_label)

                    else
                        write(6,*)' RH/SH not obtained...'
                        goto1200

                    endif ! istat_rh / istat_sh

                    call plot_cont(rh_2d,1e0
     1                            ,clow,chigh,cint,asc9_tim_t
     1                            ,c33_label,i_overlay,c_display
     1                            ,lat,lon,jdot
     1                            ,NX_L,NY_L,r_missing_data
     1                            ,laps_cycle_time)

                endif ! plot RH
            endif ! True

        elseif(c_type .eq. 'hy')then
            write(6,1513)
            read(lun,*)k_level
            if(k_level .gt. 0)then
               k_level = nint(zcoord_of_pressure(float(k_level*100)))
            endif

            iflag_temp = 1 ! Returns Ambient Temperature
            call get_temp_3d(i4time_ref,i4time_nearest,iflag_temp
     1                          ,NX_L,NY_L,NZ_L,temp_3d,istatus)

!           Read in SFC pressure
            i4time_tol = 0
            var_2d = 'PS'
            ext = 'lsx'
            call get_laps_2dgrid(i4time_nearest,i4time_tol
     1                          ,i4time_nearest,ext,var_2d
     1                          ,units_2d,comment_2d,NX_L,NY_L
     1                          ,pres_2d,0,istatus)
            IF(istatus .ne. 1)THEN
                write(6,*)' Error Reading Surface Pres Analyses'
     1                  ,' - no hydrostatic heights calculated'
                goto1200
            endif

            call get_heights_hydrostatic(temp_3d,pres_2d,topo,
     1          dum1_array,dum2_array,dum3_array,dum4_array,
     1                                  NX_L,NY_L,NZ_L,field_3d)

            call mklabel33(k_level,' LAPS Heights    dm',c33_label)

            clow = 0.
            chigh = 0.
            cint = 1. ! 3.

            i4time_heights = i4time_nearest

            call make_fnam_lp(i4time_heights,asc9_tim_t,istatus)

            call plot_cont(field_3d(1,1,k_level),1e1,clow,chigh,cint       
     1          ,asc9_tim_t,c33_label,i_overlay,c_display
     1          ,lat,lon,jdot
     1          ,NX_L,NY_L,r_missing_data,laps_cycle_time)

        elseif(c_type .eq. 'hb' .or. c_type .eq. 'tb' .or.
     1         c_type .eq. 'hr' .or. c_type .eq. 'tr'     )then
            
            if(c_type(1:1) .eq. 'h')then
                var_2d = 'HT'
            else
                var_2d = 'T3'
            endif

            if(c_type(2:2) .eq. 'b')then
                ext = 'lga'
            else
                ext = 'fua'
            endif

            call input_background_info(
     1                              ext                     ! I
     1                             ,directory               ! O
     1                             ,i4time_ref              ! I
     1                             ,laps_cycle_time         ! I
     1                             ,asc9_tim_t              ! O
     1                             ,fcst_hhmm               ! O
     1                             ,i4_initial              ! O
     1                             ,i4_valid                ! O
     1                             ,istatus)                ! O
            if(istatus.ne.1)goto1200

            call get_pres_3d(i4_valid,NX_L,NY_L,NZ_L,field_3d,istatus)       

            write(6,1513)
            read(lun,*)k_mb
            k_level = nint(zcoord_of_pressure(float(k_mb*100)))
            k_mb    = nint(field_3d(icen,jcen,k_level) / 100.)

            CALL READ_LAPS(i4_initial,i4_valid,DIRECTORY,EXT,
     1          NX_L,NY_L,1,1,       
     1          VAR_2d,k_mb,LVL_COORD_2d,UNITS_2d,COMMENT_2d,
     1          field_2d,ISTATUS)

            IF(istatus .ne. 1)THEN
                write(6,*)' Error Reading Grid ',var_2d,' ',ext,istatus
                goto1200
            endif


            if(c_type(1:1) .eq. 'h')then
                scale = 10.

!               call mklabel33(k_level,' LAPS '//ext(1:3)//' Height dm'
!    1                        ,c33_label)

!               call mklabel33(k_level,ext(1:3)//' '
!    1                         //fcst_hhmm//' Fcst Ht dm',c33_label)

                call mklabel33(k_level,' '//fcst_hhmm
     1                         //' '//ext(1:3)//' Height dm',c33_label)

                clow = 0.
                chigh = 0.
                call array_range(field_2d,NX_L,NY_L,rmin,rmax
     1                          ,r_missing_data)

                range = (rmax-rmin) / scale

                if(range .gt. 40)then
                    cint = 6.
                elseif(range .gt. 20)then
                    cint = 3.
                elseif(range .gt. 8)then
                    cint = 2.
                else ! range < 8
                    cint = 1.
                endif

            else  
!               call mklabel33(k_level,' LAPS '//ext(1:3)//' Temp    C'
!    1                        ,c33_label)

                call mklabel33(k_level,' '//fcst_hhmm
     1                         //' '//ext(1:3)//' Temp    C',c33_label)

                scale = 1.

                do i = 1,NX_L
                do j = 1,NY_L
                    field_2d(i,j) = field_2d(i,j) - 273.15
                enddo ! j
                enddo ! i

                call contour_settings(field_2d,NX_L,NY_L
     1                             ,clow,chigh,cint,zoom,scale)       

            endif

            call make_fnam_lp(i4_valid,asc9_tim_t,istatus)

            call plot_cont(field_2d,scale,clow,chigh,cint
     1                    ,asc9_tim_t,c33_label,i_overlay,c_display
     1                    ,lat,lon,jdot
     1                    ,NX_L,NY_L,r_missing_data,laps_cycle_time)

            i4time_temp = i4_valid

        elseif(c_type .eq. 'to')then
            write(6,1513)
            read(lun,*)k_mb
            k_level = nint(zcoord_of_pressure(float(k_mb*100)))

            if(i4time_temp .eq. 0)then
                i4time_temp = (i4time_ref / laps_cycle_time) 
     1                        * laps_cycle_time
            endif

            call plot_temp_obs(k_level,i4time_temp,NX_L,NY_L,NZ_L
     1                        ,r_missing_data,lat,lon,topo)

        elseif(c_type .eq. 'ht'.or. c_type .eq. 'bh')then
            write(6,1513)
            read(lun,*)k_mb

            k_level = nint(zcoord_of_pressure(float(k_mb*100)))

            var_2d = 'HT'

            ext='lt1'

            if(c_type .eq. 'bh' )then
               call get_directory('balance',directory,lend)
               directory=directory(1:lend)//'lt1/'
               call get_2dgrid_dname(directory
     1             ,i4time_ref,laps_cycle_time*100,i4time_heights
     1             ,ext,var_2d,units_2d,comment_2d
     1             ,NX_L,NY_L,field_2d,k_mb,istatus)

               call mklabel33(k_level,' Height  (Bal)   dm',c33_label)       

            else ! 'ht'
               call get_laps_2dgrid(i4time_ref,laps_cycle_time*100
     1                             ,i4time_heights
     1                             ,ext,var_2d,units_2d,comment_2d
     1                             ,NX_L,NY_L,field_2d,k_mb,istatus)       
               call mklabel33(k_level,' Height          dm',c33_label)       

            endif

            IF(istatus .ne. 1)THEN
                write(6,*)' Error Reading LAPS Height Analysis'
                goto1200
            endif

            scale = 10.

            clow = 0.
            chigh = 0.
            call array_range(field_2d,NX_L,NY_L,rmin,rmax
     1                      ,r_missing_data)

            range = (rmax-rmin) / scale

            if(range .gt. 40)then
                cint = 6.
            elseif(range .gt. 20)then
                cint = 3.
            elseif(range .gt. 8)then
                cint = 2.
            else ! range < 8
                cint = 1.
            endif

            call make_fnam_lp(i4time_heights,asc9_tim_t,istatus)

            call plot_cont(field_2d,scale,clow,chigh,cint,
     1         asc9_tim_t,c33_label,i_overlay,c_display
     1                                          ,lat,lon,jdot,
     1         NX_L,NY_L,r_missing_data,laps_cycle_time)

        elseif(c_type .eq. 'pw')then
            var_2d = 'TPW'
            ext = 'lh4'
            call get_laps_2dgrid(i4time_ref,laps_cycle_time*100
     1                          ,i4time_pw,
     1              ext,var_2d,units_2d,comment_2d,NX_L,NY_L
     1                                     ,field_2d,0,istatus)

            IF(istatus .ne. 1)THEN
                write(6,*)' Error Reading Precipitable Water'
                goto1200
            endif

            c33_label = 'LAPS Total Precipitable Water  cm'

            clow = 0.
            chigh = 15.
            cint = .25

            call make_fnam_lp(i4time_pw,asc9_tim_t,istatus)

            call plot_cont(field_2d,1e-2,clow,chigh,cint,
     1           asc9_tim_t,c33_label,i_overlay,c_display
     1           ,lat,lon,jdot,
     1           NX_L,NY_L,r_missing_data,laps_cycle_time)

        elseif(c_type .eq. 'tt' .or. c_type .eq. 'tf'
     1                          .or. c_type .eq. 'tc')then
            var_2d = 'T'
            ext = 'lsx'
            call get_laps_2dgrid(i4time_ref,laps_cycle_time*100
     1                          ,i4time_pw,ext,var_2d,units_2d
     1                          ,comment_2d,NX_L,NY_L
     1                                     ,field_2d,0,istatus)

            if(c_type .ne. 'tc')then
                do i = 1,NX_L
                do j = 1,NY_L
                    field_2d(i,j) = k_to_f(field_2d(i,j))
                enddo ! j
                enddo ! i
                c33_label = 'LAPS Sfc Temperature     (F)     '
            else
                do i = 1,NX_L
                do j = 1,NY_L
                    field_2d(i,j) = k_to_c(field_2d(i,j))
                enddo ! j
                enddo ! i
                c33_label = 'LAPS Sfc Temperature     (C)     '
            endif

            IF(istatus .ne. 1)THEN
                write(6,*)' Error Reading Surface Temps'
                goto1200
            endif

            call contour_settings(field_2d,NX_L,NY_L,clow,chigh,cint
     1                                                   ,zoom,1.)       

            call make_fnam_lp(i4time_pw,asc9_tim_t,istatus)

            call plot_cont(field_2d,1e-0,clow,chigh,cint,asc9_tim_t
     1           ,c33_label,i_overlay,c_display
     1           ,lat,lon,jdot
     1           ,NX_L,NY_L,r_missing_data,laps_cycle_time)

        elseif(c_type .eq. 'hi')then
            var_2d = 'HI'
            ext = 'lsx'
            call get_laps_2dgrid(i4time_ref,laps_cycle_time*100
     1                          ,i4time_pw,
     1              ext,var_2d,units_2d,comment_2d,NX_L,NY_L
     1                                     ,field_2d,0,istatus)

!           K to F
            do i = 1,NX_L
            do j = 1,NY_L
                field_2d(i,j) = k_to_f(field_2d(i,j))
            enddo ! j
            enddo ! i

            IF(istatus .ne. 1)THEN
                write(6,*)' Error Reading Heat Index'
                goto1200
            endif

            c33_label = 'LAPS Heat Index          (F)     '

!           clow = +50.
!           chigh = +150.
!           cint = 5.
            call contour_settings(field_2d,NX_L,NY_L,clow,chigh,cint
     1                                                        ,zoom,1.)       

            call make_fnam_lp(i4time_pw,asc9_tim_t,istatus)

            call plot_cont(field_2d,1e-0,clow,chigh,cint,
     1       asc9_tim_t,c33_label,i_overlay,c_display
     1       ,lat,lon,jdot,
     1       NX_L,NY_L,r_missing_data,laps_cycle_time)

        elseif(c_type .eq. 'td' .or. c_type .eq. 'df'
     1                          .or. c_type .eq. 'dc')then
            var_2d = 'TD'
            ext = 'lsx'
            call get_laps_2dgrid(i4time_ref,laps_cycle_time*100
     1             ,i4time_pw
     1             ,ext,var_2d,units_2d,comment_2d,NX_L,NY_L
     1                                     ,field_2d,0,istatus)

            IF(istatus .ne. 1)THEN
                write(6,*)' Error Reading Surface Td'
                goto1200
            endif

            if(c_type .ne. 'dc')then
                do i = 1,NX_L
                do j = 1,NY_L
                    field_2d(i,j) = k_to_f(field_2d(i,j))
                enddo ! j
                enddo ! i
                c33_label = 'LAPS Sfc Dew Point       (F)     '
            else
                do i = 1,NX_L
                do j = 1,NY_L
                    field_2d(i,j) = k_to_c(field_2d(i,j))
                enddo ! j
                enddo ! i
                c33_label = 'LAPS Sfc Dew Point       (C)     '
            endif


!           clow = -50.
!           chigh = +120.
!           cint = 5.
            call contour_settings(field_2d,NX_L,NY_L,clow,chigh,cint
     1                                                         ,zoom,1.)       

            call make_fnam_lp(i4time_pw,asc9_tim_t,istatus)

            call plot_cont(field_2d,1e-0,clow,chigh,cint
     1           ,asc9_tim_t,c33_label,i_overlay,c_display
     1           ,lat,lon,jdot
     1           ,NX_L,NY_L,r_missing_data,laps_cycle_time)

        elseif(c_type .eq. 'mc')then
            var_2d = 'MRC'
            ext = 'lsx'
            call get_laps_2dgrid(i4time_ref,laps_cycle_time*100
     1             ,i4time_pw,
     1              ext,var_2d,units_2d,comment_2d,NX_L,NY_L
     1                                     ,field_2d,0,istatus)

            IF(istatus .ne. 1)THEN
                write(6,*)' Error Reading Surface Moisture Convergence'
                goto1200
            endif

            c33_label = 'LAPS Sfc Mstr Flux Conv  (x 1e-4)'

            clow = -100.
            chigh = +100.
            cint = 5.

            call make_fnam_lp(i4time_pw,asc9_tim_t,istatus)

            call plot_cont(field_2d,1e-4,clow,chigh,cint,
     1            asc9_tim_t,c33_label,i_overlay,c_display
     1                                          ,lat,lon,jdot,
     1            NX_L,NY_L,r_missing_data,laps_cycle_time)

        elseif(c_type .eq. 'ws')then ! surface wind
            ext = 'lsx'
            var_2d = 'U'
            call get_laps_2dgrid(i4time_ref,laps_cycle_time*100
     1                          ,i4time_pw,ext,var_2d,units_2d
     1                          ,comment_2d,NX_L,NY_L,u_2d,0,istatus)      
            var_2d = 'V'
            call get_laps_2dgrid(i4time_ref,laps_cycle_time*100
     1                          ,i4time_pw,ext,var_2d,units_2d
     1                          ,comment_2d,NX_L,NY_L,v_2d,0,istatus)      

            IF(istatus .ne. 1)THEN
                write(6,*)' Error Reading Surface Wind'
                goto1200
            endif

            c33_label = 'LAPS Surface Wind            (kt)'

            nxz = float(NX_L) / zoom
            nyz = float(NY_L) / zoom

            interval = int(max(nxz,nyz) / 65.) + 1
            size = float(interval) * .15

            call make_fnam_lp(i4time_pw,asc9_tim_t,istatus)

!           Rotate sfc winds from grid north to true north
            do i = 1,NX_L
            do j = 1,NY_L
                u_grid = u_2d(i,j)
                v_grid = v_2d(i,j)
                call uvgrid_to_uvtrue(  u_grid,
     1                                  v_grid,
     1                                  u_true,
     1                                  v_true,
     1                                  lon(i,j) )
                u_2d(i,j) = u_true
                v_2d(i,j) = v_true
            enddo ! j
            enddo ! i

            call plot_barbs(u_2d,v_2d,lat,lon,topo,size,zoom,interval       
     1                     ,asc9_tim_t,c33_label,c_field,k_level
     1                     ,i_overlay,c_display
     1                     ,NX_L,NY_L,NZ_L,grid_ra_ref,grid_ra_vel
     1                     ,NX_L,NY_L,r_missing_data,laps_cycle_time
     1                     ,jdot)

        elseif(c_type .eq. 'bs')then ! surface backgrounds
            write(6,711)
 711        format('   Background extension [lgb,fsf]',5x,'? ',$)
            read(lun,712)ext
 712        format(a3)

            call input_background_info(
     1                              ext                     ! I
     1                             ,directory               ! O
     1                             ,i4time_ref              ! I
     1                             ,laps_cycle_time         ! I
     1                             ,asc9_tim_t              ! O
     1                             ,fcst_hhmm               ! O
     1                             ,i4_initial              ! O
     1                             ,i4_valid                ! O
     1                             ,istatus)                ! O
            if(istatus.ne.1)goto1200

            if(ext.eq.'lgb')then
               write(6,723)
 723           format(/'  SELECT FIELD (VAR_2D):  '
     1          /
     1          /'     SFC: [usf,vsf,psf,tsf,dsf,fsf,slp] ? ',$)

            else
               write(6,725)
 725           format(/'  SELECT FIELD (VAR_2D):  '
     1          /
     1          /'  SFC: [u,v,ps,t,td,rh,msl,th,the'       
     1                 ,',pbe,nbe,lhe,llr,lmr,lcv] ? ',$)       

            endif

            read(lun,724)var_2d
 724        format(a)
            call upcase(var_2d,var_2d)

            level=0
            CALL READ_LAPS(i4_initial,i4_valid,DIRECTORY,EXT
     1         ,NX_L,NY_L,1,1,VAR_2d,level,LVL_COORD_2d
     1         ,UNITS_2d,COMMENT_2d,field_2d,ISTATUS)

            IF(istatus .ne. 1)THEN
                write(6,*)' Error Reading Grid ',var_2d,' ',ext,istatus       
                goto1200
            endif

            if(var_2d .eq. 'TSF' .or.
     1         var_2d .eq. 'DSF' .or.
     1         var_2d .eq. 'T'   .or.
     1         var_2d .eq. 'TD'       )then

                write(6,*)' Converting sfc data to Fahrenheit'

!               K to F
                do i = 1,NX_L
                do j = 1,NY_L
                    field_2d(i,j) = k_to_f(field_2d(i,j))
                enddo ! j
                enddo ! i

                scale = 1.
!               c33_label = 'LAPS Sfc Temperature     (F)     '

            elseif(var_2d .eq. 'PS'  .or. var_2d .eq. 'PSF'
     1        .or. var_2d .eq. 'MSL' .or. var_2d .eq. 'SLP')then
                scale = 100.

            else
                scale = 1.

            endif

            c33_label = 'LAPS Sfc Bkgnd/Fcst  '//fcst_hhmm//' '
     1                  //ext(1:3)//'/'//var_2d(1:3)

            call make_fnam_lp(i4_valid,asc9_tim,istatus)

            if(var_2d .ne. 'LCV')then
                call contour_settings(field_2d,NX_L,NY_L
     1                               ,clow,chigh,cint,zoom,scale)       

                call plot_cont(field_2d,scale,clow,chigh,cint
     1                        ,asc9_tim,c33_label,i_overlay,c_display
     1                        ,lat,lon,jdot
     1                        ,NX_L,NY_L,r_missing_data,laps_cycle_time)       
            
            else
                n_image = n_image + 1
                call ccpfil(field_2d,NX_L,NY_L,0.0,1.0,'linear')
                call set(.00,1.0,.00,1.0,.00,1.0,.00,1.0,1)
                call setusv_dum(2hIN,7)
                call write_label_lplot(NX_L,NY_L,c33_label,asc9_tim
     1                                                    ,i_overlay)

            endif

        elseif(c_type .eq. 'p' .or. c_type .eq. 'pm')then ! 1500m or MSL Pres
            if(c_type .eq. 'p')then
                var_2d = 'P'
                c33_label = 'LAPS 1500m Pressure          (mb)'
            else
                var_2d = 'MSL'
                c33_label = 'LAPS MSL Pressure            (mb)'
            endif

            ext = 'lsx'
            call get_laps_2dgrid(i4time_ref,laps_cycle_time*100
     1                          ,i4time_pw,ext,var_2d,units_2d
     1                          ,comment_2d,NX_L,NY_L,field_2d,0
     1                          ,istatus)

            IF(istatus .ne. 1)THEN
                write(6,*)' Error Reading Surface ',var_2d
                goto1200
            endif

            clow = 0.
            chigh = 0.
!           cint = 1. ! 3.

            scale = 100.

            call array_range(field_2d,NX_L,NY_L,pres_low_pa,pres_high_pa
     1                      ,r_missing_data)

            pres_high_mb = pres_high_pa / scale
            pres_low_mb  = pres_low_pa / scale
            range = (pres_high_pa - pres_low_pa) / scale

            if(range .gt. 30.)then
                cint = 4.
            elseif(range .gt. 8.)then
                cint = 2.
            else ! range < 8
                cint = 1.
            endif

            icint   = cint
            clow = int(pres_low_mb) / 4 * 4
            chigh = (int(pres_high_mb) / icint) * icint + icint

            call make_fnam_lp(i4time_pw,asc9_tim_t,istatus)

            call plot_cont(field_2d,1e+2,clow,chigh,cint,asc9_tim_t
     1                    ,c33_label,i_overlay,c_display
     1                    ,lat,lon,jdot
     1                    ,NX_L,NY_L,r_missing_data,laps_cycle_time)

        elseif(c_type .eq. 'ps')then ! Surface Pressure
            var_2d = 'PS'
            ext = 'lsx'
            call get_laps_2dgrid(i4time_ref,laps_cycle_time*100
     1                          ,i4time_pw,ext,var_2d,units_2d
     1                          ,comment_2d,NX_L,NY_L
     1                          ,field_2d,0,istatus)

            IF(istatus .ne. 1)THEN
                write(6,*)' Error Reading Surface ',var_2d
                goto1200
            endif

            c33_label = 'LAPS Surface Pressure        (mb)'

            scale = 100.

            call contour_settings(field_2d,NX_L,NY_L,clow,chigh,cint
     1                           ,zoom,scale)

            call make_fnam_lp(i4time_pw,asc9_tim_t,istatus)

            call plot_cont(field_2d,scale,clow,chigh,cint
     1             ,asc9_tim_t,c33_label,i_overlay,c_display
     1             ,lat,lon,jdot
     1             ,NX_L,NY_L,r_missing_data,laps_cycle_time)

        elseif(c_type .eq. 'vv')then
            var_2d = 'VV'
            ext = 'lsx'
            call get_laps_2dgrid(i4time_ref,laps_cycle_time*100
     1          ,i4time_pw,ext,var_2d,units_2d,comment_2d,NX_L,NY_L
     1                                     ,field_2d,0,istatus)

            IF(istatus .ne. 1)THEN
                write(6,*)' Error Reading Surface ',var_2d
                goto1200
            endif

            c33_label = 'LAPS Sfc Vert Velocity     (cm/s)'

            clow = -200.
            chigh = +200.
            cint = 10.

            call make_fnam_lp(i4time_pw,asc9_tim_t,istatus)

            call plot_cont(field_2d,1e-2,clow,chigh,cint
     1                    ,asc9_tim_t,c33_label,i_overlay
     1                    ,c_display,lat,lon,jdot
     1                    ,NX_L,NY_L,r_missing_data,laps_cycle_time)

        elseif(c_type .eq. 'hu')then
            var_2d = 'RH'
            ext = 'lsx'
            call get_laps_2dgrid(i4time_ref,laps_cycle_time*100,i4time_p
     1w,
     1              ext,var_2d,units_2d,comment_2d,NX_L,NY_L
     1                                     ,field_2d,0,istatus)

            IF(istatus .ne. 1)THEN
                write(6,*)' Error Reading Surface ',var_2d
                goto1200
            endif

!           c33_label = 'LAPS Sfc  Rel Hum       (PERCENT)'
            c33_label = 'LAPS Sfc Rel Humidity   (PERCENT)'

!           clow = 0.
!           chigh = +100.
!           cint = 10.
            call contour_settings(field_2d,NX_L,NY_L,clow,chigh,cint
     1                                                     ,zoom,1.)       

            call make_fnam_lp(i4time_pw,asc9_tim_t,istatus)

            call plot_cont(field_2d,1e-0,clow,chigh,cint,
     1      asc9_tim_t,c33_label,i_overlay,c_display
     1                                          ,lat,lon,jdot,
     1      NX_L,NY_L,r_missing_data,laps_cycle_time)

        elseif(c_type .eq. 'ta')then
            var_2d = 'TAD'
            ext = 'lsx'
            call get_laps_2dgrid(i4time_ref,laps_cycle_time*100,i4time_p
     1w,
     1              ext,var_2d,units_2d,comment_2d,NX_L,NY_L
     1                                     ,field_2d,0,istatus)

            IF(istatus .ne. 1)THEN
                write(6,*)' Error Reading Surface ',var_2d
                goto1200
            endif

            c33_label = 'LAPS Sfc Temp Adv (x 1e-5 Dg K/s)'

            clow = -100.
            chigh = +100.
            cint = 5.

            call make_fnam_lp(i4time_pw,asc9_tim_t,istatus)

            call plot_cont(field_2d,1e-5,clow,chigh,cint,
     1          asc9_tim_t,c33_label,i_overlay,c_display,lat,lon,jdot,
     1          NX_L,NY_L,r_missing_data,laps_cycle_time)

        elseif(c_type .eq. 'th')then
            var_2d = 'TH'
            ext = 'lsx'
            call get_laps_2dgrid(i4time_ref,laps_cycle_time*100
     1             ,i4time_pw,
     1              ext,var_2d,units_2d,comment_2d,NX_L,NY_L
     1                                     ,field_2d,0,istatus)

            IF(istatus .ne. 1)THEN
                write(6,*)' Error Reading Surface ',var_2d
                goto1200
            endif

            c33_label = 'LAPS Sfc Potential Temp   (Deg K)'

            clow = +240.
            chigh = +320.
            cint = 2.

            call make_fnam_lp(i4time_pw,asc9_tim_t,istatus)

            call plot_cont(field_2d,1e-0,clow,chigh,cint,asc9_tim_t
     1                    ,c33_label,i_overlay,c_display
     1                    ,lat,lon,jdot,NX_L,NY_L,r_missing_data
     1                    ,laps_cycle_time)

        elseif(c_type .eq. 'te')then
            var_2d = 'THE'
            ext = 'lsx'
            call get_laps_2dgrid(i4time_ref,laps_cycle_time*100
     1                          ,i4time_pw,ext,var_2d,units_2d
     1                          ,comment_2d,NX_L,NY_L
     1                          ,field_2d,0,istatus)

            IF(istatus .ne. 1)THEN
                write(6,*)' Error Reading Surface ',var_2d
                goto1200
            endif

            c33_label = 'LAPS Sfc Equiv Potl Temp  (Deg K)'

            clow = +240.
            chigh = +350.
            cint = 2.

            call make_fnam_lp(i4time_pw,asc9_tim_t,istatus)

            call plot_cont(field_2d,1e-0,clow,chigh,cint
     1                    ,asc9_tim_t,c33_label,i_overlay
     1                    ,c_display
     1                    ,lat,lon,jdot
     1                    ,NX_L,NY_L,r_missing_data,laps_cycle_time)       

        elseif(c_type .eq. 'vo')then
            var_2d = 'VOR'
            ext = 'lsx'
            call get_laps_2dgrid(i4time_ref,laps_cycle_time*100
     1                          ,i4time_pw
     1                          ,ext,var_2d,units_2d,comment_2d
     1                          ,NX_L,NY_L,field_2d,0,istatus)

            IF(istatus .ne. 1)THEN
                write(6,*)' Error Reading Surface ',var_2d
                goto1200
            endif

            c33_label = 'LAPS Sfc Vorticity  (x 1e-5 s^-1)'

            clow = -100.
            chigh = +100.
            cint = 5.

            call make_fnam_lp(i4time_pw,asc9_tim_t,istatus)

            call plot_cont(field_2d,1e-5,clow,chigh,cint,
     1             asc9_tim_t,c33_label,i_overlay,c_display
     1            ,lat,lon,jdot,
     1             NX_L,NY_L,r_missing_data,laps_cycle_time)

        elseif(c_type .eq. 'mr')then
            var_2d = 'MR'
            ext = 'lsx'
            call get_laps_2dgrid(i4time_ref,laps_cycle_time*100,i4time_p
     1w,
     1              ext,var_2d,units_2d,comment_2d,NX_L,NY_L
     1                                     ,field_2d,0,istatus)

            IF(istatus .ne. 1)THEN
                write(6,*)' Error Reading Surface ',var_2d
                goto1200
            endif

            c33_label = 'LAPS Sfc Mixing Ratio      (g/kg)'

            clow = -100.
            chigh = +100.
            cint = 2.

            call make_fnam_lp(i4time_pw,asc9_tim_t,istatus)

            call plot_cont(field_2d,1e-0,clow,chigh,cint,
     1        asc9_tim_t,c33_label,i_overlay,c_display,lat,lon,jdot,
     1        NX_L,NY_L,r_missing_data,laps_cycle_time)

        elseif(c_type .eq. 'dv')then
            var_2d = 'DIV'
            ext = 'lsx'
            call get_laps_2dgrid(i4time_ref,laps_cycle_time*100,i4time_p
     1w,
     1              ext,var_2d,units_2d,comment_2d,NX_L,NY_L
     1                                     ,field_2d,0,istatus)

            IF(istatus .ne. 1)THEN
                write(6,*)' Error Reading Surface ',var_2d
                goto1200
            endif

            c33_label = 'LAPS Sfc Divergence  (x 1e-5 s-1)'

            clow = -100.
            chigh = +100.
            cint = 5.

            call make_fnam_lp(i4time_pw,asc9_tim_t,istatus)

            call plot_cont(field_2d,1e-5,clow,chigh,cint,
     1        asc9_tim_t,c33_label,i_overlay,c_display,lat,lon,jdot,
     1        NX_L,NY_L,r_missing_data,laps_cycle_time)

        elseif(c_type .eq. 'ha')then ! Theta Advection
            var_2d = 'THA'
            ext = 'lsx'
            call get_laps_2dgrid(i4time_ref,laps_cycle_time*100,i4time_p
     1w,
     1              ext,var_2d,units_2d,comment_2d,NX_L,NY_L
     1                                     ,field_2d,0,istatus)

            IF(istatus .ne. 1)THEN
                write(6,*)' Error Reading Surface ',var_2d
                goto1200
            endif

            c33_label = 'LAPS Sfc Theta Adv   (x 1e-5 K/s)'

            clow = -100.
            chigh = +100.
            cint = 5.

            call make_fnam_lp(i4time_pw,asc9_tim_t,istatus)

            call plot_cont(field_2d,1e-5,clow,chigh,cint,
     1        asc9_tim_t,c33_label,i_overlay,c_display,lat,lon,jdot,
     1        NX_L,NY_L,r_missing_data,laps_cycle_time)

        elseif(c_type .eq. 'ma')then
            var_2d = 'MRA'
            ext = 'lsx'
            call get_laps_2dgrid(i4time_ref,laps_cycle_time*100,i4time_p
     1w,
     1              ext,var_2d,units_2d,comment_2d,NX_L,NY_L
     1                                     ,field_2d,0,istatus)

            IF(istatus .ne. 1)THEN
                write(6,*)' Error Reading Surface ',var_2d
                goto1200
            endif

            c33_label = 'LAPS Sfc Mstr Adv (x 1e-5 g/kg/s)'

            clow = -100.
            chigh = +100.
            cint = 5.

            call make_fnam_lp(i4time_pw,asc9_tim_t,istatus)

            call plot_cont(field_2d,1e-5,clow,chigh,cint,
     1        asc9_tim_t,c33_label,i_overlay,c_display,lat,lon,jdot,
     1        NX_L,NY_L,r_missing_data,laps_cycle_time)

        elseif(c_type .eq. 'sp')then
            ext = 'lsx'
            var_2d = 'U'
            call get_laps_2dgrid(i4time_ref,laps_cycle_time*100,i4time_p
     1w,
     1              ext,var_2d,units_2d,comment_2d,NX_L,NY_L
     1                                     ,u_2d,0,istatus)
            var_2d = 'V'
            call get_laps_2dgrid(i4time_ref,laps_cycle_time*100,i4time_p
     1w,
     1              ext,var_2d,units_2d,comment_2d,NX_L,NY_L
     1                                     ,v_2d,0,istatus)


            IF(istatus .ne. 1)THEN
                write(6,*)' Error Reading Surface ',var_2d
                goto1200
            endif

            c33_label = 'LAPS Sfc Wind Speed          (kt)'

            clow = 0.
            chigh = +100.
            cint = 10.

            do i = 1,NX_L
            do j = 1,NY_L
                    if(u_2d(i,j) .eq. r_missing_data
     1    .or. v_2d(i,j) .eq. r_missing_data)then
                        dir(i,j)  = r_missing_data
                        spds(i,j) = r_missing_data
                    else
                        call uvgrid_to_disptrue(u_2d(i,j),
     1                                  v_2d(i,j),
     1                                  dir(i,j),
     1                                  spds(i,j),
     1                                  lon(i,j)     )
                        spds(i,j) = spds(i,j) / mspkt
                    endif
            enddo ! j
            enddo ! i

            call make_fnam_lp(i4time_pw,asc9_tim_t,istatus)

            call plot_cont(spds,1.,clow,chigh,cint,
     1        asc9_tim_t,c33_label,i_overlay,c_display,lat,lon,jdot,
     1        NX_L,NY_L,r_missing_data,laps_cycle_time)

        elseif(c_type .eq. 'cs')then
            var_2d = 'CSS'
            ext = 'lsx'
            call get_laps_2dgrid(i4time_ref,laps_cycle_time*100,i4time_p
     1w,
     1              ext,var_2d,units_2d,comment_2d,NX_L,NY_L
     1                                     ,field_2d,0,istatus)

            IF(istatus .ne. 1)THEN
                write(6,*)' Error Reading Surface ',var_2d
                goto1200
            endif

            c33_label = 'LAPS  Colorado Severe Storm Index'

            clow = 0.
            chigh = +100.
            cint = 10.

            call make_fnam_lp(i4time_pw,asc9_tim_t,istatus)

            call plot_cont(field_2d,1e-0,clow,chigh,cint,
     1        asc9_tim_t,c33_label,i_overlay,c_display,lat,lon,jdot,
     1        NX_L,NY_L,r_missing_data,laps_cycle_time)

        elseif(c_type .eq. 'vs')then
            var_2d = 'VIS'
            ext = 'lsx'
            call get_laps_2dgrid(i4time_ref,laps_cycle_time*100,i4time_p
     1w,
     1              ext,var_2d,units_2d,comment_2d,NX_L,NY_L
     1                                     ,field_2d,0,istatus)

            IF(istatus .ne. 1)THEN
                write(6,*)' Error Reading Surface ',var_2d
                goto1200
            endif

            c33_label = 'LAPS Sfc Visibility       (miles)'

            clow = 0.
            chigh = +100.
            cint = -0.1

            call make_fnam_lp(i4time_pw,asc9_tim_t,istatus)

            call plot_cont(field_2d,1600.,clow,chigh,cint,
     1        asc9_tim_t,c33_label,i_overlay,c_display,lat,lon,jdot,
     1        NX_L,NY_L,r_missing_data,laps_cycle_time)

        elseif(c_type .eq. 'fw')then
            var_2d = 'FWX'
            ext = 'lsx'
            call get_laps_2dgrid(i4time_ref,laps_cycle_time*100,i4time_p
     1w,
     1              ext,var_2d,units_2d,comment_2d,NX_L,NY_L
     1                                     ,field_2d,0,istatus)

            IF(istatus .ne. 1)THEN
                write(6,*)' Error Reading Surface ',var_2d
                goto1200
            endif

            c33_label = 'LAPS Fire Weather          (0-20)'

            clow = 0.
            chigh = +20.
            cint = 2.0

            call make_fnam_lp(i4time_pw,asc9_tim_t,istatus)

            call plot_cont(field_2d,1.,clow,chigh,cint,
     1        asc9_tim_t,c33_label,i_overlay,c_display,lat,lon,jdot,
     1        NX_L,NY_L,r_missing_data,laps_cycle_time)

        elseif(c_type .eq. 'sc')then
            var_2d = 'SC'
            ext = 'lm2'
            call get_laps_2dgrid(i4time_ref,laps_cycle_time*100
     1                          ,i4time_pw,ext,var_2d,units_2d
     1                          ,comment_2d,NX_L,NY_L
     1                          ,field_2d,0,istatus)

            IF(istatus .ne. 1 .and. istatus .ne. -1)THEN
                write(6,*)' Error Reading Snow Cover'
                goto1200
            endif

!           c33_label = 'LAPS Snow Cover       (PERCENT)  '
            c33_label = 'LAPS Snow Cover       (TENTHS)   '

            clow = 0.
!           chigh = +100.
!           cint = 20.
            chigh = +10.
            cint = 2.

            call make_fnam_lp(i4time_pw,asc9_tim_t,istatus)

!           call plot_cont(field_2d,1e-2,clow,chigh,cint,
            call plot_cont(field_2d,1e-1,clow,chigh,cint,
     1        asc9_tim_t,c33_label,i_overlay,c_display,lat,lon,jdot,
     1        NX_L,NY_L,r_missing_data,laps_cycle_time)

        elseif(c_type .eq. 'cb' .or. c_type .eq. 'cc')then

            if(c_type .eq. 'cb')then ! Cloud Base
                ext = 'lcb'
                var_2d = 'LCB'
                call get_laps_2dgrid(i4time_ref,
     1              laps_cycle_time*100,i4time_nearest,
     1              ext,var_2d,units_2d,comment_2d,NX_L,NY_L
     1                                  ,cloud_ceil,0,istatus)

                IF(istatus .ne. 1 .and. istatus .ne. -1)THEN
                    write(6,*)' Error Reading Cloud Base'
                    goto1200
                endif

                c33_label = 'LAPS Cloud Base         m   MSL  '
                clow = 0.
                chigh = 10000.
                cint = 1000.

            elseif(c_type .eq. 'cc')then ! Cloud Ceiling

                ext = 'lcb'
                var_2d = 'CCE'
                call get_laps_2dgrid(i4time_ref,
     1              laps_cycle_time*100,i4time_nearest,
     1              ext,var_2d,units_2d,comment_2d,NX_L,NY_L
     1                                  ,cloud_ceil,0,istatus)

                IF(istatus .ne. 1 .and. istatus .ne. -1)THEN
                    write(6,*)' Error Reading Cloud Ceiling'
                    goto1200
                endif

                c33_label = 'LAPS Cloud Ceiling      m   AGL  '
                clow = 0.
                chigh = 0.
                cint = -100.

            endif

            call make_fnam_lp(i4time_nearest,asc9_tim,istatus)

            call plot_cont(cloud_ceil,1e0,
     1               clow,chigh,cint,asc9_tim,c33_label,
     1               i_overlay,c_display,lat,lon,jdot,
     1               NX_L,NY_L,r_missing_data,laps_cycle_time)

        elseif(c_type .eq. 'ct' .or. c_type .eq. 'cti')then
            var_2d = 'LCT'
            ext = 'lcb'
            call get_laps_2dgrid(i4time_ref,864000,i4time_nearest,
     1              ext,var_2d,units_2d,comment_2d,NX_L,NY_L
     1                                     ,cloud_top,0,istatus)

            IF(istatus .ne. 1 .and. istatus .ne. -1)THEN
                write(6,*)' Error Reading Cloud Top'
                goto1200
            endif

            c33_label = 'LAPS Cloud Top          m   MSL  '

            call make_fnam_lp(i4time_nearest,asc9_tim,istatus)

            if(c_type .eq. 'ct')then
                clow = 0.
                chigh = 20000.
                cint = 1000.
                call plot_cont(cloud_top,1e0,
     1                     clow,chigh,cint,asc9_tim,c33_label,
     1                     i_overlay,c_display,lat,lon,jdot,       
     1                     NX_L,NY_L,r_missing_data,laps_cycle_time)

            else
                n_image = n_image + 1
                call ccpfil(cloud_top,NX_L,NY_L,0.0,14000.,'linear')
                call set(.00,1.0,.00,1.0,.00,1.0,.00,1.0,1)
                call setusv_dum(2hIN,7)
                call write_label_lplot(NX_L,NY_L,c33_label,asc9_tim
     1                                                    ,i_overlay)

            endif

        elseif(c_type .eq. 'cv' .or. c_type .eq. 'cg')then
            write(6,2514)
2514        format('     Enter Level (1-42); [-bbbb] for mb; '
     1                          ,'OR [0] for max in column',5x,'? ',$)
            read(lun,*)k_level

            if(k_level .gt. 0)then
                var_2d = 'lc3'
                ext = 'lc3'

                call get_laps_2dgrid(i4time_ref,86400,i4time_nearest,
     1           ext,var_2d,units_2d,comment_2d,NX_L,NY_L
     1                                  ,cloud_cvr,k_level,istatus)

            elseif(k_level .lt. 0)then ! k_level is -pressure in mb
               var_2d = 'lcp'
               ext = 'lcp'

               call get_laps_2dgrid(i4time_ref,86400,i4time_nearest,
     1           ext,var_2d,units_2d,comment_2d,NX_L,NY_L
     1                                  ,cloud_cvr,-k_level,istatus)

            else ! k_level .eq. 0
               var_2d = 'lcv'
               ext = 'lcv'

               call get_laps_2dgrid(i4time_ref,86400,i4time_nearest,
     1           ext,var_2d,units_2d,comment_2d,NX_L,NY_L
     1                                  ,cloud_cvr,-k_level,istatus)

            endif

            call make_fnam_lp(i4time_nearest,asc9_tim,istatus)

!           Get Cloud Cover
            if(k_level .gt. 0)then
                read(comment_2d,3515)cloud_height
3515            format(e20.8)

                write(c33_label,3516)nint(cloud_height)
3516            format('LAPS ',i5,'  M MSL   Cloud Cover  ')

                write(6,*)' LVL_CLD = ',lvl_cld

            elseif(k_level .eq. 0)then
                c33_label = 'LAPS Cloud Cover                 '

            else ! k_level .lt. 0
                write(c33_label,3517)-k_level
3517            format('LAPS ',i5,'  MB    Cloud Cover    ')

            endif

            if(c_type .eq. 'cv')then
                clow = 0.2
                chigh = 0.8
                cint = 0.2
                call plot_cont(cloud_cvr,1e0,
     1               clow,chigh,cint,asc9_tim,c33_label,
     1               i_overlay,c_display,lat,lon,jdot,
     1               NX_L,NY_L,r_missing_data,laps_cycle_time)

            else ! 'cg'
                write(6,*)' calling solid fill cloud plot'
                n_image = n_image + 1
                call ccpfil(cloud_cvr,NX_L,NY_L,0.0,1.0,'linear')
                call set(.00,1.0,.00,1.0,.00,1.0,.00,1.0,1)
                call setusv_dum(2hIN,7)
                call write_label_lplot(NX_L,NY_L,c33_label,asc9_tim
     1                                                    ,i_overlay)

            endif

        elseif(c_type(1:2) .eq. 'tn')then
            clow = -400.
            chigh = +5000.
            cint = +200.
            c33_label = '                                 '
            asc9_tim_t = '         '

            if(c_type .eq. 'tni')then
                write(6,*)' calling solid fill plot'
                scale = 3000.
                call ccpfil(topo,NX_L,NY_L,0.0,scale,'linear')
                n_image = n_image + 1
            else
                call plot_cont(topo,1e0,
     1               clow,chigh,cint,asc9_tim_t,c33_label,
     1               i_overlay,c_display,lat,lon,jdot,
     1               NX_L,NY_L,r_missing_data,laps_cycle_time)
            endif

            i4time_topo = 0

        elseif(c_type .eq. 'gr')then
            call plot_grid(i_overlay,c_display,lat,lon,
     1                     NX_L,NY_L,laps_cycle_time)

        elseif(c_type .eq. 'lf')then
            clow = .5
            chigh = .5
            cint = .5
            c33_label = '                                 '
            asc9_tim_t = '         '
            call plot_cont(rlaps_land_frac,1e0,
     1               clow,chigh,cint,asc9_tim_t,c33_label,
     1               i_overlay,c_display,lat,lon,jdot,
     1               NX_L,NY_L,r_missing_data,laps_cycle_time)

            i4time_topo = 0

        elseif(c_type .eq. 'so')then
            clow = 0.
            chigh = 20.
            cint = 1.
            c33_label = 'Soil Type                        '
            asc9_tim_t = '         '
            call plot_cont(soil_type,1e0,
     1               clow,chigh,cint,asc9_tim_t,c33_label,
     1               i_overlay,c_display,lat,lon,jdot,
     1               NX_L,NY_L,r_missing_data,laps_cycle_time)

            i4time_topo = 0

        elseif(c_type .eq. 'cf')then
            call frame
            close(8)

        elseif(c_type .eq. 'q ')then
            goto9000

        endif ! c_field

        goto1200

9000    if(c_display .eq. 'm' .or. c_display .eq. 'p')then
            call frame
        else
            if(c_display .eq. 't')then
            elseif(c_display .eq. 'r')then
                call frame2(c_display)
            else
                call frame
            endif
        endif

 211    format(/' Enter yydddhhmmHHMM or HHMM for file: ',$)
 221    format(a13)

        return
        end


        subroutine plot_cont(array,scale,clow,chigh,cint,
     1    asc_tim_9,c33_label,i_overlay,c_display,lat,lon,jdot,
     1    NX_L,NY_L,r_missing_data,laps_cycle_time)

!       97-Aug-14     Ken Dritz     Added NX_L, NY_L as dummy arguments
!       97-Aug-14     Ken Dritz     Added r_missing_data, laps_cycle_time
!                                   as dummy arguments
!       97-Aug-14     Ken Dritz     Removed include of lapsparms.for

        common /MCOLOR/mini,maxi

        real*4 lat(NX_L,NY_L),lon(NX_L,NY_L)

        character c33_label*33,asc_tim_9*9,c_metacode*2,asc_tim_24*24
        character*1 c_display
        character*9 c_file

        real*4 array(NX_L,NY_L)
        real*4 array_plot(NX_L,NY_L)

!       integer*4 ity,ily,istatus
!       data ity/35/,ily/1010/

        include 'icolors.inc'

        Y_SPACING = 3

        c_file = 'nest7grid'

        write(6,1505)c33_label,scale,asc_tim_9
1505    format(7x,a33,4x,'Units = ',1pe9.0,6x,a9)

        if(asc_tim_9 .ne. '         ')then
            call i4time_fname_lp(asc_tim_9,I4time_file,istatus)
            call cv_i4tim_asc_lp(i4time_file,asc_tim_24,istatus)
!           asc_tim_24 = asc_tim_24(1:14)//asc_tim_24(16:17)//' '
        else
            asc_tim_24 = '                        '
        endif


        vmax = -1e30
        vmin = 1e30

        do i = 1,NX_L
        do j = 1,NY_L
            if(array(i,j) .ne. r_missing_data)then
                array_plot(i,j) = array(i,j) / scale
            else
                array_plot(i,j) = array(i,j) 
            endif
            vmax = max(vmax,array_plot(i,j))
            vmin = min(vmin,array_plot(i,j))
        enddo ! i
        enddo ! j

        X_SPACING = NX_L / 28

        do j=NY_L,1,-Y_SPACING
            write(6,500)
     1  (nint(min(max(array_plot(i,j),-99.),999.)),i=1,NX_L,X_SPACING)
500         format(1x,42i3)
        enddo ! j

!       Set Map Background stuff
        if(c_display .eq. 'r' .and. i_overlay .eq. 0)then
            c_metacode = 'm'
        elseif(c_display .eq. 'l' .and. i_overlay .eq. 0)then
            c_metacode = 'm'
        elseif(c_display .eq. 't' .and. i_overlay .eq. 0)then
            c_metacode = 'm'
        elseif(c_display .eq. 'e' .and. i_overlay .eq. 0)then
            c_metacode = 'm'
        elseif(c_display .eq. 'n' .and. i_overlay .eq. 0)then
            c_metacode = 'm'
        elseif(c_display .eq. 'o' .and. i_overlay .eq. 0)then
            c_metacode = 'm'
        elseif(c_display .eq. 'c' .and. i_overlay .eq. 0)then
            c_metacode = 'm'
        elseif(c_display .eq. 'v')then
            goto990
        elseif(c_display .eq. 'p')then ! Generate a Map background only
            c_metacode = 'm'
            call lapsplot(array_plot,NX_L,NY_L,clow,chigh,cint,lat,lon
     1                   ,c_metacode,jdot)
            goto990
        else
            c_metacode = 'c'
        endif

        if(c_metacode .eq. 'c ')then
            i_overlay = i_overlay + 1

        else if(c_metacode .eq. 'm ')then
            write(6,*)' c_metacode,i_overlay = ',c_metacode,i_overlay

            if(c_display .eq. 'r')then
                call lapsplot(array_plot,NX_L,NY_L
     1                       ,clow,chigh,cint,lat,lon
     1                       ,c_metacode,jdot)
            endif

            c_metacode = 'c '
            i_overlay = 1

            i4time_plot = i4time_file/laps_cycle_time*laps_cycle_time
!       1                                            -laps_cycle_time
            call setusv_dum(2hIN,34)

            iflag = 0

            call get_maxstns(maxstns,istatus)
            if (istatus .ne. 1) then
               write (6,*) 'Error getting value of maxstns'
               stop
            endif

            write(6,*)' Not calling plot_station_locations: 1'
!           call plot_station_locations(i4time_plot,lat,lon,NX_L,NY_L
!    1                                 ,iflag,maxstns)
        endif

        write(6,*)' Plotting: c_metacode,i_overlay = ',
     1                        c_metacode,i_overlay

        if(clow .eq. 0. .and. chigh .eq. 0. .and. cint .gt. 0.)then
            clow =  (nint(vmin/cint)-1) * cint
            chigh = (nint(vmax/cint)+1) * cint
        endif

        write(6,*)' CLOW,HIGH,CINT ',clow,chigh,cint
        write(6,*)' Max/Min = ',vmax,vmin

        call setusv_dum(2hIN,icolors(i_overlay))

        if(c_metacode .ne. 'n ')then
            if(c_metacode .eq. 'c ')then
                 call set(.00,1.0,.00,1.0,.00,1.0,.00,1.0,1)
                 call write_label_lplot(NX_L,NY_L,c33_label,asc_tim_9
     1                                                      ,i_overlay)
            endif

            if(c_display .ne. 't')then
                mini = icolors(i_overlay)
                maxi = icolors(i_overlay)
            else
                mini = icolors_tt(i_overlay)
                maxi = icolors_tt(i_overlay)
            endif

            call lapsplot(array_plot,NX_L,NY_L,clow,chigh,cint,lat,lon
     1                   ,c_metacode,jdot)
        endif

990     return
        end



        subroutine plot_barbs(u,v,lat,lon,topo,size,zoom,
     1  interval,asc_tim_9,
     1  c33_label,
     1  c_field,k_level,i_overlay,c_display,imax,jmax,kmax,
     1  grid_ra_ref,grid_ra_vel,NX_L,NY_L,r_missing_data,
     1  laps_cycle_time,jdot)      

!       97-Aug-14     Ken Dritz     Added NX_L, NY_L as dummy arguments
!       97-Aug-14     Ken Dritz     Added r_missing_data, laps_cycle_time
!                                   as dummy arguments
!       97-Aug-14     Ken Dritz     Changed LAPS_DOMAIN_FILE to hardwire
!       97-Aug-14     Ken Dritz     Removed include of lapsparms.for

        character c33_label*33,asc_tim_9*9,c_metacode*2,asc_tim_24*24
        character c_field*2,c_display*1
        character*9 c_file

        real*4 u(NX_L,NY_L)
        real*4 v(NX_L,NY_L)
        real*4 lat(NX_L,NY_L)
        real*4 lon(NX_L,NY_L)
        real*4 topo(NX_L,NY_L)

        real*4 grid_ra_ref(imax,jmax,kmax)
        real*4 grid_ra_vel(imax,jmax,kmax)

!       integer*4 ity,ily,istatus
!       data ity/35/,ily/1010/

        include 'icolors.inc'

        logical l_obs

        c_file = 'nest7grid'

        write(6,1505)c33_label,asc_tim_9
1505    format(2x,a33,2x,a9)

        call i4time_fname_lp(asc_tim_9,I4time_file,istatus)
        call cv_i4tim_asc_lp(i4time_file,asc_tim_24,istatus)
!       asc_tim_24 = asc_tim_24(1:14)//asc_tim_24(16:17)//' '

!       Set Map Background stuff
        if(c_display .eq. 'r' .and. i_overlay .eq. 0)then
            c_metacode = 'm'
        elseif(c_display .eq. 'l' .and. i_overlay .eq. 0)then
            c_metacode = 'm'
        elseif(c_display .eq. 't' .and. i_overlay .eq. 0)then
            c_metacode = 'm'
        elseif(c_display .eq. 'e' .and. i_overlay .eq. 0)then
            c_metacode = 'm'
        elseif(c_display .eq. 'n' .and. i_overlay .eq. 0)then
            c_metacode = 'm'
        elseif(c_display .eq. 'o' .and. i_overlay .eq. 0)then
            c_metacode = 'm'
        elseif(c_display .eq. 'c' .and. i_overlay .eq. 0)then
            c_metacode = 'm'
        elseif(c_display .eq. 'v')then
            goto990
        else
            c_metacode = 'c'
        endif

        if(c_metacode .eq. 'c ')then
            i_overlay = i_overlay + 1
        else if(c_metacode .eq. 'm ')then
            write(6,*)' c_metacode,i_overlay = ',c_metacode,i_overlay

            if(c_display .eq. 'r')then
                call lapsplot(array_plot,NX_L,NY_L,clow,chigh,cint
     1                       ,lat,lon,c_metacode,jdot)
            endif

            c_metacode = 'c '
            i_overlay = 1

            i4time_plot = i4time_file/laps_cycle_time*laps_cycle_time
!       1                                            -laps_cycle_time
            call setusv_dum(2hIN,34)

            iflag = 0

            call get_maxstns(maxstns,istatus)
            if (istatus .ne. 1) then
               write (6,*) 'Error getting value of maxstns'
               stop
            endif

            write(6,*)' Not calling plot_station_locations: 2'
!           call plot_station_locations(i4time_plot,lat,lon,NX_L,NY_L
!    1                                 ,iflag,maxstns)
        endif

        write(6,*)' Plotting: c_metacode,i_overlay = ',
     1                          c_metacode,i_overlay

        call setusv_dum(2hIN,icolors(i_overlay))

        if(c_metacode .ne. 'n ')then
            if(c_metacode .eq. 'y ' .or. c_metacode .eq. 'c ')then
                 call set(.00,1.0,.00,1.0,.00,1.0,.00,1.0,1)
                 call write_label_lplot(NX_L,NY_L,c33_label,asc_tim_9
     1                                                      ,i_overlay)
            endif


            if(c_metacode .eq. 'y ' .or. c_metacode .eq. 'c ')then
                if(c_field .eq. 'ob')then
                    call getset(mxa,mxb,mya,myb,umin,umax,vmin,vmax,ltyp
     1e)
                    write(6,2031)
2031                format('         Enter Radar #   ',45x,'? ',$)
                    read(5,*)i_radar

                    call plot_obs(k_level,.true.,asc_tim_9(1:7)//'00'
     1                  ,i_radar,imax,jmax,kmax
     1                  ,grid_ra_ref,grid_ra_vel,lat,lon,topo,1)
                    return
                endif

                call setusv_dum(2hIN,icolors(i_overlay))

                call get_border(NX_L,NY_L,x_1,x_2,y_1,y_2)

                call set(x_1,x_2,y_1,y_2,1.,float(NX_L),1.,float(NY_L)
     1                                                             ,1)       

                call plot_winds_2d(u,v,interval,size,zoom
     1          ,NX_L,NY_L,lat,lon,r_missing_data)
!               call frame

            endif

        endif

990     return
        end


        subroutine plot_grid(i_overlay,c_display,lat,lon,
     1                       NX_L,NY_L,laps_cycle_time)

!       97-Aug-14     Ken Dritz     Added NX_L, NY_L as dummy arguments
!       97-Aug-14     Ken Dritz     Added laps_cycle_time as dummy argument
!       97-Aug-14     Ken Dritz     Changed LAPS_DOMAIN_FILE to hardwire
!       97-Aug-14     Ken Dritz     Removed include of lapsparms.for

        character c33_label*33,asc_tim_9*9,c_metacode*2,asc_tim_24*24
        character c_field*2,c_display*1

        real*4 lat(NX_L,NY_L)
        real*4 lon(NX_L,NY_L)

!       integer*4 ity,ily,istatus
!       data ity/35/,ily/1010/

        include 'icolors.inc'

        logical l_obs

!       Set Map Background stuff
        if(c_display .eq. 'r' .and. i_overlay .eq. 0)then
            c_metacode = 'm'
        elseif(c_display .eq. 'l' .and. i_overlay .eq. 0)then
            c_metacode = 'm'
        elseif(c_display .eq. 't' .and. i_overlay .eq. 0)then
            c_metacode = 'm'
        elseif(c_display .eq. 'e' .and. i_overlay .eq. 0)then
            c_metacode = 'm'
        elseif(c_display .eq. 'n' .and. i_overlay .eq. 0)then
            c_metacode = 'm'
        elseif(c_display .eq. 'o' .and. i_overlay .eq. 0)then
            c_metacode = 'm'
        elseif(c_display .eq. 'c' .and. i_overlay .eq. 0)then
            c_metacode = 'm'
        elseif(c_display .eq. 'v')then
            goto990
        else
            c_metacode = 'c'
        endif

        if(c_metacode .eq. 'c ')then
            i_overlay = i_overlay + 1
        else if(c_metacode .eq. 'm ')then
            write(6,*)' c_metacode,i_overlay = ',c_metacode,i_overlay

            if(c_display .eq. 'r')then
                call lapsplot(array_plot,NX_L,NY_L,clow,chigh,cint
     1                       ,lat,lon,c_metacode,jdot)
            endif

            c_metacode = 'c '
            i_overlay = 1

!           i4time_plot = i4time_file/laps_cycle_time*laps_cycle_time
!       1                                            -laps_cycle_time
            call setusv_dum(2hIN,34)

        endif

        write(6,*)' Plotting: c_metacode,i_overlay = ',
     1                          c_metacode,i_overlay

        call setusv_dum(2hIN,icolors(i_overlay))

        if(c_metacode .ne. 'n ')then
            if(c_metacode .eq. 'y '
     1    .or. c_metacode .eq. 'c ')then
                 call set(.00,1.0,.00,1.0,.00,1.0,.00,1.0,1)
!                call pwrity(cpux(320),cpux(ity),c33_label,33,2,0,0)      
!                call pwrity
!    1                (cpux(800),cpux(ity),asc_tim_24(1:17),17,2,0,0)
                 call write_label_lplot(NX_L,NY_L,c33_label,asc_tim_9
     1                                                      ,i_overlay)
            endif


            if(c_metacode .eq. 'y ' .or. c_metacode .eq. 'c ')then

                call setusv_dum(2hIN,icolors(i_overlay))

!               call get_border(NX_L,NY_L,x_1,x_2,y_1,y_2)

!               call set(x_1,x_2,y_1,y_2,1.,float(NX_L),1.,float(NY_L))

                call plot_grid_2d(interval,size,NX_L,NY_L,lat,lon)

            endif

        endif

990     return
        end

        subroutine plot_cldpcp_type(cldpcp_type_2d
     1     ,asc_tim_9,c33_label,c_field,k_level,i_overlay,c_display
     1     ,lat,lon,ifield_2d
     1     ,NX_L,NY_L,laps_cycle_time,jdot)

!       97-Aug-14     Ken Dritz     Added NX_L, NY_L, laps_cycle_time as
!                                   dummy arguments
!       97-Aug-14     Ken Dritz     Removed include of lapsparms.for

        character c33_label*33,asc_tim_9*9,c_metacode*2,asc_tim_24*24
        character c_field*2,c_display*1
        character*9 c_file

        character cldpcp_type_2d(NX_L,NY_L)
        real*4 lat(NX_L,NY_L)
        real*4 lon(NX_L,NY_L)
        integer*4 ifield_2d(NX_L,NY_L)

        integer*4 iarg

!       integer*4 ity,ily,istatus
!       data ity/35/,ily/1010/

        include 'icolors.inc'

        logical l_obs

        c_file = 'nest7grid'

        write(6,1505)c33_label,asc_tim_9
1505    format(2x,a33,2x,a9)

        call i4time_fname_lp(asc_tim_9,I4time_file,istatus)
        call cv_i4tim_asc_lp(i4time_file,asc_tim_24,istatus)
!       asc_tim_24 = asc_tim_24(1:14)//asc_tim_24(16:17)//' '

!       Set Map Background stuff
        if(c_display .eq. 'r' .and. i_overlay .eq. 0)then
            c_metacode = 'm'
        elseif(c_display .eq. 'l' .and. i_overlay .eq. 0)then
            c_metacode = 'm'
        elseif(c_display .eq. 't' .and. i_overlay .eq. 0)then
            c_metacode = 'm'
        elseif(c_display .eq. 'e' .and. i_overlay .eq. 0)then
            c_metacode = 'm'
        elseif(c_display .eq. 'n' .and. i_overlay .eq. 0)then
            c_metacode = 'm'
        elseif(c_display .eq. 'o' .and. i_overlay .eq. 0)then
            c_metacode = 'm'
        elseif(c_display .eq. 'c' .and. i_overlay .eq. 0)then
            c_metacode = 'm'
        elseif(c_display .eq. 'v')then

            interval = 2

            call plot_types_2d(cldpcp_type_2d,interval,size,c_field,.fal
     1se.
     1                                  ,NX_L,NY_L,lat,lon,ifield_2d)
            goto990
        else
            c_metacode = 'c'
        endif

        if(c_metacode .eq. 'c ')then
            i_overlay = i_overlay + 1
        else if(c_metacode .eq. 'm ')then
            write(6,*)' c_metacode,i_overlay = ',c_metacode,i_overlay

            call lapsplot_setup(NX_L,NY_L,lat,lon,jdot)

            c_metacode = 'c '
            i_overlay = 1

            i4time_plot = i4time_file/laps_cycle_time*laps_cycle_time
!       1                                            -laps_cycle_time
            call setusv_dum(2hIN,34)

            iflag = 0

            call get_maxstns(maxstns,istatus)
            if (istatus .ne. 1) then
               write (6,*) 'Error getting value of maxstns'
               stop
            endif

            write(6,*)' Not calling plot_station_locations: 3'
!           call plot_station_locations(i4time_plot,lat,lon,NX_L,NY_L
!    1                                 ,iflag,maxstns)
        endif

        write(6,*)' Plotting: c_metacode,i_overlay = ',
     1                          c_metacode,i_overlay

        call i4time_fname_lp(asc_tim_9,I4time_file,istatus)
        call cv_i4tim_asc_lp(i4time_file,asc_tim_24,istatus)
!       asc_tim_24 = asc_tim_24(1:14)//asc_tim_24(16:17)//' '

        call setusv_dum(2hIN,icolors(i_overlay))

        if(c_metacode .ne. 'n ')then
            if(c_metacode .eq. 'y '
     1    .or. c_metacode .eq. 'c ')then
                 call set(.00,1.0,.00,1.0,.00,1.0,.00,1.0,1)
                 call write_label_lplot(NX_L,NY_L,c33_label,asc_tim_9
     1                                                      ,i_overlay)
            endif


            if(c_metacode .eq. 'y ' .or. c_metacode .eq. 'c ')then
                call setusv_dum(2hIN,icolors(i_overlay))

                if(max(NX_L,NY_L) .gt. 61)then
                    interval = 4
                else
                    interval = 2
                endif

                size = 1.0
                call plot_types_2d(cldpcp_type_2d,interval,size,c_field,
     1                       .true.,NX_L,NY_L,lat,lon,ifield_2d)
!               call frame

            endif

        endif

990     return
        end

        subroutine plot_stations(asc_tim_9,c33_label,c_field,i_overlay
     1   ,c_display,lat,lon,c_file,iflag
     1   ,NX_L,NY_L,laps_cycle_time,zoom)

!       97-Aug-14     Ken Dritz     Added NX_L, NY_L, laps_cycle_time as
!                                   dummy arguments
!       97-Aug-14     Ken Dritz     Removed include of lapsparms.for

        character c33_label*33,asc_tim_9*9,c_metacode*2,asc_tim_24*24
        character c_field*2,c_display*1
        character*(*) c_file

        real*4 lat(NX_L,NY_L)
        real*4 lon(NX_L,NY_L)

        integer*4 iarg

!       integer*4 ity,ily,istatus
!       data ity/35/,ily/1010/

        include 'icolors.inc'

        logical l_obs

        write(6,1505)c33_label,asc_tim_9
1505    format(2x,a33,2x,a9)

        call i4time_fname_lp(asc_tim_9,I4time_file,istatus)
        call cv_i4tim_asc_lp(i4time_file,asc_tim_24,istatus)
!       asc_tim_24 = asc_tim_24(1:14)//asc_tim_24(16:17)//' '

!       Set Map Background stuff
        if(c_display .eq. 'r' .and. i_overlay .eq. 0)then
            c_metacode = 'm'
        elseif(c_display .eq. 'v')then
            goto990
        else
            c_metacode = 'c'
        endif

        if(c_metacode .eq. 'c ')then
            i_overlay = i_overlay + 1
        else if(c_metacode .eq. 'm ')then

            if(iflag .eq. 1)then
                jdot = 0 ! Solid boundaries
            else
                jdot = 1 ! Dotted boundaries
            endif

            write(6,*)' c_metacode,i_overlay = ',c_metacode,i_overlay
            write(6,*)' iflag,jdot = ',iflag,jdot

            call lapsplot_setup(NX_L,NY_L,lat,lon,jdot)

            c_metacode = 'c '
            i_overlay = 1

            i4time_plot = i4time_file ! /laps_cycle_time*laps_cycle_time
!       1                                            -laps_cycle_time

            call setusv_dum(2hIN,34) ! Grey
!           call setusv_dum(2HIN,11)

            call get_maxstns(maxstns,istatus)
            if (istatus .ne. 1) then
               write (6,*) 'Error getting value of maxstns'
               stop
            endif

            write(6,*)' Not calling plot_station_locations: 4 '
     1               ,iflag,c_metacode

!           call plot_station_locations(i4time_plot,lat,lon,NX_L,NY_L
!    1                                 ,iflag,maxstns,c_field)
        endif

        write(6,*)' Plotting: c_metacode,i_overlay = ',
     1                          c_metacode,i_overlay

        call i4time_fname_lp(asc_tim_9,I4time_file,istatus)
        call cv_i4tim_asc_lp(i4time_file,asc_tim_24,istatus)
!       asc_tim_24 = asc_tim_24(1:14)//asc_tim_24(16:17)//' '

        call setusv_dum(2hIN,icolors(i_overlay))

        if(c_metacode .ne. 'n ')then
            if(c_metacode .eq. 'y '
     1  .or. c_metacode .eq. 'c ')then
                 call set(.00,1.0,.00,1.0,.00,1.0,.00,1.0,1)
!                call pwrity
!    1                (cpux(320),cpux(ity),c33_label,33,2,0,0)
!                call pwrity
!    1                (cpux(800),cpux(ity),asc_tim_24(1:17),17,2,0,0)

!                if(iflag .ge. 1)then
!                    c33_label = 'Sfc Obs'
!                endif

!                call write_label_lplot(NX_L,NY_L,c33_label,asc_tim_9
!    1                                                      ,i_overlay)
            endif

            if(c_metacode .eq. 'y ' .or. c_metacode .eq. 'c ')then

                if(iflag .eq. 2)then ! obs with station locations?
                    call setusv_dum(2hIN,icolors(i_overlay))
                else                 ! station locations by themselves
                    call setusv_dum(2hIN,34)                    ! Grey
                endif

                if(max(NX_L,NY_L) .gt. 61)then
                    interval = 4
                else
                    interval = 2
                endif

                size = 1.0

                call get_maxstns(maxstns,istatus)
                if(istatus .ne. 1) then
                   write (6,*) 'Error getting value of maxstns'
                   stop
                endif

                write(6,*)' Calling plot_station_locations: 5 '
     1                   ,iflag,c_metacode       
                call plot_station_locations(i4time_file,lat,lon
     1                      ,NX_L,NY_L,iflag,maxstns,c_field,zoom
     1                      ,asc_tim_24,c33_label,i_overlay)       
            endif

        endif

990     return
        end


        subroutine mklabel33(k_level,c19_label,c33_label)

!       97-Aug-17     Ken Dritz     Lines commented to (temporarily) hardwire
!                                   VERTICAL_GRID at 'PRESSURE' (without
!                                   accessing VERTICAL_GRID)
!       97-Aug-17     Ken Dritz     Removed include of lapsparms.for

        character c19_label*19,c33_label*33

        if(k_level .gt. 0)then
!            if(VERTICAL_GRID .eq. 'HEIGHT')then
!                write(c33_label,101)k_level,c19_label
!101             format('LAPS',I5,' km ',a19)

!            elseif(VERTICAL_GRID .eq. 'PRESSURE')then
                if(k_level .gt. 50)then ! k_level is given in pressure
                    ipres = nint(zcoord_of_level(K_Level)/100.)
                else                    ! k_level is level number
                    ipres = nint(pressure_of_level(K_Level)/100.)
                endif

                write(c33_label,102)ipres,c19_label
102             format('LAPS',I5,' hPa',a19)

!            endif
        else if(k_level .eq. 0)then
            write(c33_label,103)c19_label
103         format('LAPS  Surface',a19)

        else if(k_level .eq. -1)then
            write(c33_label,104)
104         format('LAPS Steering Winds              ')

        endif

        return
        end

        subroutine plot_station_locations(i4time,lat,lon,ni,nj,iflag
     1                                   ,maxstns,c_field,zoom,atime
     1                                   ,c33_label,i_overlay)

!       97-Aug-14     Ken Dritz     Added maxstns as dummy argument
!       97-Aug-14     Ken Dritz     Removed include of lapsparms.for
!       97-Aug-25     Steve Albers  Removed /read_sfc_cmn/.

!       This routine labels station locations on the H-sect

        real*4 lat(ni,nj),lon(ni,nj)

        real*4 lat_s(maxstns), lon_s(maxstns), elev_s(maxstns)
        real*4 cover_s(maxstns), hgt_ceil(maxstns), hgt_low(maxstns)
        real*4 t_s(maxstns), td_s(maxstns), pr_s(maxstns), sr_s(maxstns)
        real*4 dd_s(maxstns), ff_s(maxstns), ddg_s(maxstns)
     1       , ffg_s(maxstns)
        real*4 vis_s(maxstns)
        character stations(maxstns)*3, wx_s(maxstns)*8      ! c5_stamus

c
        character atime*24, infile*255, c33_label*33
        character directory*150,ext*31
        character*255 c_filespec
        character*9 c9_string, asc_tim_9
        character*13 filename13
        character*2 c_field
        character*3 c3_name, c3_presob

!       Declarations for new read_surface routine
!       New arrays for reading in the SAO data from the LSO files
        real*4   pstn(maxstns),pmsl(maxstns),alt(maxstns)
     1          ,store_hgt(maxstns,5)
        real*4   ceil(maxstns),lowcld(maxstns),cover_a(maxstns)
     1          ,vis(maxstns),rad(maxstns)

        Integer*4   obstime(maxstns),kloud(maxstns),idp3(maxstns)

        Character   obstype(maxstns)*8
     1             ,store_emv(maxstns,5)*1,store_amt(maxstns,5)*4

        call get_filespec('lso',2,c_filespec,istatus)
        call get_file_time(c_filespec,i4time,i4time_lso)

        if(i4time_lso .eq. 0)then
            write(6,*)' No LSO files available for station plotting'
            return
        endif

        call make_fnam_lp(i4time_lso,asc_tim_9,istatus)

        write(6,*)
     1  ' Reading Station locations from read_sfc for labeling: '
     1  ,asc_tim_9

        ext = 'lso'
        call get_directory(ext,directory,len_dir) ! Returns top level directory
        if(c_field(1:1) .eq. 'q')then ! LSO_QC file
            infile = 
     1      directory(1:len_dir)//filename13(i4time_lso,ext(1:3))//'_qc'    

        else ! Regular LSO file
            infile = 
     1      directory(1:len_dir)//filename13(i4time_lso,ext(1:3))  

        endif

        call read_surface_old(infile,maxstns,atime,n_meso_g,
     &           n_meso_pos,
     &           n_sao_g,n_sao_pos_g,n_sao_b,n_sao_pos_b,
     &           n_obs_g,n_obs_pos_g,
     &           n_obs_b,n_obs_pos_b,stations,obstype,lat_s,lon_s,
     &           elev_s,wx_s,t_s,td_s,dd_s,ff_s,ddg_s,
     &           ffg_s,pstn,pmsl,alt,kloud,ceil,lowcld,cover_a,rad,idp3,       
     &           store_emv,
     &           store_amt,store_hgt,vis,obstime,istatus)

100     write(6,*)'     n_obs_b',n_obs_b

        if(n_obs_b .gt. maxstns .or. istatus .ne. 1)then
            write(6,*)' Too many stations, or no file present'
            istatus = 0
            return
        endif

        size = 0.5
        call getset(mxa,mxb,mya,myb,umin,umax,vmin,vmax,ltype)
        du = float(ni) / 300.

        zoom_eff = max((zoom / 3.0),1.0)
        du2 = du / zoom_eff

!       call setusv_dum(2HIN,11)

        write(6,*)' plot_station_locations... ',iflag

        c3_presob = '   '
        if(iflag .ge. 1)then
            write(6,13)
13          format(' Select type of pressure ob [msl,alt,stn]'
     1            ,4x,'default=none      ? ',$)
            read(5,14)c3_presob
 14         format(a)

            if(c_field(1:1) .eq. 'q')then ! LSO_QC file
                c33_label = 'Sfc QC Obs   ('//c3_presob//' pres)'
            else
                c33_label = 'Sfc Obs      ('//c3_presob//' pres)'
            endif

            call set(.00,1.0,.00,1.0,.00,1.0,.00,1.0,1)
            call write_label_lplot(ni,nj,c33_label,asc_tim_9,i_overlay)       

        endif

        call get_border(ni,nj,x_1,x_2,y_1,y_2)
        call set(x_1,x_2,y_1,y_2,1.,float(ni),1.,float(nj),1)

        call get_r_missing_data(r_missing_data,istatus)
        call get_sfc_badflag(badflag,istatus)

!       Plot Stations
        do i = 1,n_obs_b ! num_sfc
            call latlon_to_rlapsgrid(lat_s(i),lon_s(i),lat,lon
     1                          ,ni,nj,xsta,ysta,istatus)

            if(xsta .lt. 1. .or. xsta .gt. float(ni) .OR.
     1         ysta .lt. 1. .or. ysta .gt. float(nj)          )then       
                    goto80
            endif
!           call supcon(lat_s(i),lon_s(i),usta,vsta)

!           IFLAG = 0        --        Station locations only
!           IFLAG = 1        --        FSL Mesonet only (for WWW)
!           IFLAG = 2        --        All Sfc Obs

            if(iflag .ge. 1)then

!             if(obstype(i) .eq. 'MESO' .or. iflag .eq. 2)then
              if(.true.)then

                if(iflag .eq. 1)call setusv_dum(2HIN,14)

                call s_len(stations(i),len_sta)

                if(len_sta .ge. 3)then
                    c3_name = stations(i)(len_sta-2:len_sta)
                else
                    c3_name = stations(i)
                endif

                charsize = .0040 / zoom_eff

!               call pwrity(xsta, ysta-du*3.5, c3_name, 3, -1, 0, 0)     
                CALL PCLOQU(xsta, ysta-du2*3.5, c3_name, 
     1                      charsize,ANGD,CNTR)

                relsize = 1.1

                if(iflag .eq. 1)call setusv_dum(2HIN,11)

                if(c_field(2:2) .ne. 'c')then ! Fahrenheit
                    temp = t_s(i)
                    dewpoint = td_s(i)
                else                          ! Celsius
                    if(t_s(i) .ne. badflag)then
                        temp = f_to_c(t_s(i))
                    else
                        temp = badflag
                    endif

                    if(td_s(i) .ne. badflag)then
                        dewpoint = f_to_c(td_s(i))
                    else
                        dewpoint = badflag
                    endif
                endif

                if(c3_presob .eq. 'msl')then
                    pressure = pmsl(i)
                elseif(c3_presob .eq. 'alt')then
                    pressure = alt(i)
                elseif(c3_presob .eq. 'stn')then 
                    pressure = pstn(i)
                else
                    pressure = r_missing_data
                endif

                call plot_mesoob(dd_s(i),ff_s(i),ffg_s(i)
     1                 ,temp,dewpoint
     1                 ,pressure,xsta,ysta
     1                 ,lat,lon,ni,nj,relsize,zoom,11,du2,iflag)

                if(iflag .eq. 1)call setusv_dum(2HIN,33)

              endif

            else ! Write station location only
                call line(xsta,ysta+du2*0.5,xsta,ysta-du2*0.5)
                call line(xsta+du2*0.5,ysta,xsta-du2*0.5,ysta)

            endif

80      enddo ! i

        if(iflag .eq. 1)then ! special mesonet label 
            call setusv_dum(2hIN,2)
            call cv_i4tim_asc_lp(i4time,atime,istatus)
            atime = atime(1:14)//atime(16:17)//' '
            ix = 590
            iy = 270
            call pwrity(cpux(ix),cpux(iy),atime(1:17),17,-1,0,-1)
        endif

        return
        end

        subroutine get_border(ni,nj,x_1,x_2,y_1,y_2)

        if(ni .eq. nj)then
            x_1 = .05
            x_2 = .95
            y_1 = .05
            y_2 = .95
        elseif(ni .lt. nj)then
            ratio = float(ni-1) / float(nj-1)
            x_1 = .50 - .45 * ratio
            x_2 = .50 + .45 * ratio
            y_1 = .05
            y_2 = .95
        elseif(ni .gt. nj)then
            ratio = float(nj-1) / float(ni-1)
            x_1 = .05
            x_2 = .95
            y_1 = .50 - .45 * ratio
            y_2 = .50 + .45 * ratio
        endif

        return
        end



        subroutine setusv_dum(c2_dum,icol_in)

        character*2 c2_dum

        common /icol_index/ icol_current

!       icol = min(icol_in,35)
        icol = icol_in

        write(6,*)' Color # ',icol,icol_in

        call GSTXCI(icol)            
        call GSPLCI(icol)          
        call GSPMCI(icol)           
        call GSFACI(icol)                 

        icol_current = icol

        return
        end


        subroutine write_label_lplot(ni,nj,c33_label,a9time,i_overlay)        

        character*33 c33_label
        character*24 asc_tim_24,asc_tim_24_in
        character*9 a9time

        common /image/ n_image

        call upcase(c33_label,c33_label)

        if(a9time .ne. '         ')then
            call i4time_fname_lp(a9time,I4time_lbl,istatus)       
            call cv_i4tim_asc_lp(i4time_lbl,asc_tim_24_in,istatus)      
        else
            asc_tim_24_in = '                        '
        endif

        asc_tim_24 = asc_tim_24_in(1:14)//asc_tim_24_in(16:17)//' '      

        i_label = i_overlay + n_image

        call get_border(ni,nj,x_1,x_2,y_1,y_2)

        jsize_t = 2 

!       Top label
        y_2 = y_2 + .0225 ! .025

        ix = 115
        iy = y_2 * 1024
        call pwrity(cpux(ix),cpux(iy),'NOAA/FSL',8,jsize_t,0,0)

!       Bottom label
        jsize_b = 1 ! [valid range is 0-2]
        rsize_b = jsize_b + 2.

        if(jsize_b .eq. 2)then
            y_1 = y_1 - .025 - .035 * float(i_label-1)
        else
            y_1 = y_1 - rsize_b*.0045 - rsize_b*.007
     1                              * float(i_label-1)
        endif

        ix = 320
        iy = y_1 * 1024
        call pwrity(cpux(ix),cpux(iy),c33_label,33,jsize_b,0,0)

        ix = 800
        iy = y_1 * 1024
        call pwrity(cpux(ix),cpux(iy),asc_tim_24(1:17),17,jsize_b,0,0)


        return
        end


        subroutine input_background_info(
     1                              ext                     ! I
     1                             ,directory               ! O
     1                             ,i4time_ref              ! I
     1                             ,laps_cycle_time         ! I
     1                             ,asc9_tim_t              ! O
     1                             ,fcst_hhmm               ! O
     1                             ,i4_initial              ! O
     1                             ,i4_valid                ! O
     1                             ,istatus)                ! O

        integer       maxbgmodels
        parameter     (maxbgmodels=10)

        integer       n_fdda_models
        integer       l,len_dir,lfdda
        integer       istatus
        character*9   c_fdda_mdl_src(maxbgmodels)
        character*(*) directory
        character*(*) ext
        character*20  c_model
        character*10  cmds
        character*1   cansw
        character*150 c_filenames(1000)

        character*4 fcst_hhmm
        character*9 asc9_tim_t, a9time
        character*13 a13_time

        logical l_parse

        write(6,*)' Subroutine input_background_info...'

        write(6,*)' Using ',ext(1:3),' file'

        istatus = 0

        call get_directory(ext,directory,len_dir)

        if(l_parse(ext,'lga') .or. l_parse(ext,'lgb'))go to 900 ! use LGA/LGB

!       Get fdda_model_source from nest7grid.parms
        call get_fdda_model_source(c_fdda_mdl_src,n_fdda_models,istatus)
 
        call s_len(directory,len_dir)
        cansw='n'
        l=1

!       do while((cansw.eq.'n'.or.cansw.eq.'N').and.l.le.n_fdda_models)
        do while(.false.)
           if(l.ne.n_fdda_models)then
              write(6,108)c_fdda_mdl_src(l)
108           format(/'  Plot field for FDDA source -> '
     1               ,a9,'[y/n]',25x,'? ',$)
              read(5,*)cansw
              if(cansw.eq.'y'.or.cansw.eq.'Y')then
                 call s_len(c_fdda_mdl_src(l),lfdda)
                 cmds=c_fdda_mdl_src(l)(1:lfdda)//'/'
                 DIRECTORY=directory(1:len_dir)//cmds
              endif
              l=l+1
           else
              write(6,109)c_fdda_mdl_src(l)
109           format(/'  Plotting field for FDDA source -> ',a9)
              call s_len(c_fdda_mdl_src(l),lfdda)
              cmds=c_fdda_mdl_src(l)(1:lfdda)//'/'
              cansw='y'
           endif
        enddo

        if(n_fdda_models.eq.0)then
           print*,'fdda is not turned on in nest7grid.parms'
           return 
        endif

        write(6,*)' Available models are...'

        do l = 1,n_fdda_models
            call s_len(c_fdda_mdl_src(l),lfdda)
            write(6,*)' ',c_fdda_mdl_src(l)(1:lfdda)
        enddo ! l

        call s_len(c_fdda_mdl_src(1),lfdda)
        write(6,205)c_fdda_mdl_src(1)(1:lfdda),ext(1:3)
 205    format(/'  Enter model [e.g. ',a,'] for ',a3,' file: ',$)

        read(5,206)c_model
 206    format(a)

        call s_len(c_model,len_model)

        DIRECTORY=directory(1:len_dir)//c_model(1:len_model)//'/'

 900    continue

        call get_file_names(directory,nfiles,c_filenames
     1                     ,1000,istatus)

        write(6,*)' Available files in ',directory(1:len_dir)
        if(nfiles .ge. 1)then
            call s_len(c_filenames(1),len_fname)
            do i = 1,nfiles
                write(6,*)c_filenames(i)(1:len_fname)
            enddo
        endif

        call       input_model_time(i4time_ref              ! I
     1                             ,laps_cycle_time         ! I
     1                             ,asc9_tim_t              ! O
     1                             ,fcst_hhmm               ! O
     1                             ,i4_initial              ! O
     1                             ,i4_valid                ! O
     1                                                            )

        istatus = 1
        return
        end

        subroutine input_model_time(i4time_ref              ! I
     1                             ,laps_cycle_time         ! I
     1                             ,asc9_tim_t              ! O
     1                             ,fcst_hhmm               ! O
     1                             ,i4_initial              ! O
     1                             ,i4_valid                ! O
     1                                                            )

        character*4 fcst_hhmm
        character*9 asc9_tim_t, a9time
        character*13 a13_time

 1200   write(6,211)
 211    format(/'  Enter yydddhhmmHHMM or HHMM for file: ',$)

        read(5,221)a13_time
 221    format(a13)

        call s_len(a13_time,len_time)

        if(len_time .eq. 13)then
                write(6,*)' len_time = ',len_time
                call get_fcst_times(a13_time,i4_initial,i4_valid,i4_fn)
                write(6,*)' a13_time = ',a13_time
                fcst_hhmm = a13_time(10:13)
                call make_fnam_lp(i4_valid,asc9_tim_t,istatus)
                write(6,*)' Valid time = ',asc9_tim_t

        elseif(len_time .eq. 4)then
                write(6,*)' len_time = ',len_time

                i4time_plot = i4time_ref / laps_cycle_time 
     1                                   * laps_cycle_time       
                call make_fnam_lp(i4time_plot,asc9_tim_t,istatus)
                write(6,*)' Valid time = ',asc9_tim_t

                fcst_hhmm = a13_time(1:4)

              ! Get fcst interval
                a13_time = asc9_tim_t//fcst_hhmm
                call get_fcst_times(a13_time,I4TIME,i4_valid,i4_fn) 
                i4_interval = i4_valid - I4TIME
                i4_initial = I4TIME - i4_interval ! Reset initial time
                i4_valid = i4_valid - i4_interval
                call make_fnam_lp(i4_initial,a9time,istatus)

                a13_time = a9time//fcst_hhmm
                write(6,*)' Modified a13_time = ',a13_time

        else
                write(6,*)' Try again, len_time = ',len_time
                goto1200

        endif

        return
        end
