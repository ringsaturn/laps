      Program lvd_sat_ingest
c
c	3-6-97	J. Smart	New main driver for laps satellite image ingest process.
c				Purpose for having this new top-level driver is to accomdate
c				dynamic memory requirements.
c				1. Include remapping LUT as subroutine.
c				2. Include acquisition of domain parameters from
c				   static/ nest7grid.parms.
c				3. lvd_driver now a subroutine called by this main routine.
c
c       9-12-97 J. Smart        Dynamic array development. Renamed this to sub(routine)
c       2-19-98 J. Smart        Incorporate satellite_master.nl. This eliminates the need for
c                               all the separate files containing nav info for each sat and
c                               each format type.
c                               Made this the main program once again.
c       12-28-98   "            Added 'include lapsparms.cmn' and call get_laps_config
c
      Implicit None

      Integer nx_l
      Integer ny_l
      Integer nlinesir,nelemir
      Integer nlineswv,nelemwv
      Integer nlinesvis,nelemvis
      Integer i,j,k
      Integer ispec
      Integer nchannels
      Integer i4time_now_gg
      Integer i4time_cur
      Integer i4time_sys
      Integer istatus
      Integer laps_cycle_time
      Integer nav_status

      include 'satellite_dims_lvd.inc'
      include 'satellite_common_lvd.inc'

      character*3 chtype(maxchannel)
      character*9 cfname_cur
      character*9 cfname_sys
      character   cgeneric_dataroot*255
      character   c_gridfname*50

      real, allocatable :: gri(:,:,:)
      real, allocatable :: grj(:,:,:)
c
c ========================== START ==============================
c 
      call get_grid_dim_xy(nx_l,ny_l,istatus)
      if(istatus.ne.1)then
         print*,'Error returned from get_config'
         goto 1000
      endif

      call find_domain_name(cgeneric_dataroot,c_gridfname,istatus)
      write(6,*)'namelist parameters obtained: ',c_gridfname
c
      call config_satellite_lvd(istatus)
      if(istatus.ne.1)then
         write(*,*)'Error config_satellite - Cannot continue'
         stop
      endif

      i4time_cur = i4time_now_gg()
      call get_systime(i4time_sys,cfname_sys,istatus)
      call make_fnam_lp(i4time_cur,cfname_cur,istatus)

c this is designed to allow archive data runs!
      call get_laps_cycle_time(laps_cycle_time,istatus)
      if(i4time_cur-i4time_sys .gt. 2*laps_cycle_time)then
         print*,'Set current time to contents of systime.dat'
         cfname_cur=cfname_sys
         i4time_cur=i4time_sys
      endif

      allocate (gri(nx_l,ny_l,maxchannel),
     &          grj(nx_l,ny_l,maxchannel))

c---------------------------------------------------------------
c Compute array dimensions for ir, vis, and wv.
c
      do k=1,maxsat
       if(isats(k).eq.1)then

       do j=1,maxtype
        if(itypes(j,k).eq.1)then

        nav_status=0

50      nchannels=0
        do 4 i=1,maxchannel
         if(ichannels(i,j,k).eq.1)then
          nchannels=nchannels+1
          chtype(nchannels)=c_channel_types(i,j,k)
          call lvd_file_specifier(c_channel_types(i,j,k),ispec,istatus)
          if(istatus.ne.0)then
             write(6,*)'Error status returned from lvd_file_specifier'
             goto 1000
          endif

          if(ispec.eq.1)then
             nelemvis=i_end_vis(j,k)-i_start_vis(j,k)+1
             nlinesvis=j_end_vis(j,k)-j_start_vis(j,k)+1
          elseif(ispec.eq.2.or.ispec.eq.4.or.ispec.eq.5)then
             nelemir=i_end_ir(j,k)-i_start_ir(j,k)+1
             nlinesir=j_end_ir(j,k)-j_start_ir(j,k)+1
          elseif(ispec.eq.3)then
             nelemwv=i_end_wv(j,k)-i_start_wv(j,k)+1
             nlineswv=j_end_wv(j,k)-j_start_wv(j,k)+1
          endif
         endif

4       enddo
 
        write(6,*)'lvd process information'
        write(6,*)'==============================='
        write(6,*)'Satellite ID: ',c_sat_id(k)
        write(6,*)'Satellite TYPE: ',c_sat_types(j,k)
        write(6,40)(chtype(i),i=1,nchannels)
40      format(1x,'Satellite CHANNELS:',5(1x,a3))
        print*,'Path-to-raw-satellite'
        write(6,*)'==============================='
        do i=1,nchannels
           print*,' ',i,' ',TRIM(path_to_raw_sat(i,j,k))
        enddo
 
        if( (nlinesvis.eq.0.and.nelemvis.eq.0).and.
     +      (nlinesir .eq.0.and.nelemir .eq.0).and.
     +      (nlineswv .eq.0.and.nelemwv .eq.0) ) then
             print*, 'All satellite array dimensions = 0 '
             print*, 'Abort. Check static/satellite_lvd.nl'
             stop
        endif

        if(nlinesir.eq.0.or.nelemir.eq.0)then
             nlinesir=1
             nelemir =1
        endif
        if(nlinesvis.eq.0.or.nelemvis.eq.0)then
             nlinesvis=1
             nelemvis =1
        endif
        if(nlineswv.eq.0.or.nelemwv.eq.0)then
             nlineswv=1
             nelemwv =1
        endif

        write(6,*)'line/elem dimensions: '
        write(6,*)'VIS: ',nlinesvis,nelemvis
        write(6,*)'IR:  ',nlinesir,nelemir
        write(6,*)'WV:  ',nlineswv,nelemwv

        if(c_sat_id(k).ne.'foolit')then

c         if(nlinesvis.eq.0.and.nelemvis.eq.0)then
c            nav_status=1
c         endif

          if(nav_status.eq.0)then
            call compute_nav_llij(nx_l,ny_l,maxchannel,nchannels,
     &c_sat_id(k),c_sat_types(j,k),chtype,k,j,cfname_cur,gri,grj,
     &nav_status)

            if(nav_status.eq.1)then
              print*,'configure satellite common ',c_sat_id(k)
     +,'/',c_sat_types(j,k)
              call config_satellite_lvd(istatus)
c             goto 50
            elseif(nav_status.lt.0)then
              print*,'ERROR returned from compute_nav_llij - stop'
              goto 1000
            endif
          endif

        else
          print*,'sat id = ',c_sat_id(k), ': mapping not needed'
        endif
c
c ================================================================
c
        call lvd_driver_sub(nx_l,ny_l,k,j,n_images,
     &                      nlinesir,nelemir,
     &                      nlineswv,nelemwv,
     &                      nlinesvis,nelemvis,
     &                      chtype,maxchannel,nchannels,
     &                      i4time_cur,i_delta_sat_t_sec,
     &                      gri,grj,istatus)

        if(istatus.ne.1)then
           write(6,*)'NO data was processed by lvd_driver_sub'
        else
           write(6,*)'Data was processed by lvd_driver_sub'
        endif

c =================================================================
        endif 
       enddo
       endif
      enddo

1000  stop
      end
