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

        subroutine insert_tobs(i4time               ! Input
     1               ,lat,lon                       ! Input
     1               ,heights_3d                    ! Input
     1               ,sh_3d                         ! Input
     1               ,pres_3d                       ! Input
     1               ,temp_3d                       ! Input/Output
     1               ,ilaps_cycle_time              ! Input
     1               ,l_use_raob                    ! Input
     1               ,weight_bkg_const              ! Input
     1               ,rms_thresh_norm               ! Input
     1               ,ni,nj,nk                      ! Input
     1               ,max_snd,max_obs               ! Input
     1               ,grid_spacing_m                ! Input
     1               ,istatus)                      ! Output

!       Nov. 1992               Steve Albers
!       So far, this routine uses only one RASS or combined RASS sounding.
!       The top part of this routine evaluates the biases and does more QC
!       The bottom part inserts the RASS

!       Oct. 1993               Steve Albers
!       Code upgraded to do a Barnes analysis of multiple RASS

!       Dec. 1995               Keith Brewster
!       Changed to call read_tsnd and process temperature data from
!       rawinsondes as well as RASS.

!       Dec 11 1995             Steve Albers
!       Misc bug fixes and variable name changes

!       Jun 16 1997             Ken Dritz
!       Changed NZ_L_MAX to nk.

!       Jun 16 1997             Ken Dritz
!       Added call to get_r_missing_data.  Pass r_missing_data to
!       read_tsnd and analyze_tsnd.

        real*4 lat(ni,nj),lon(ni,nj)
        real*4 temp_3d(ni,nj,nk)                    ! Input = model temp fg
                                                    ! Output = analyzed temp
        real*4 sh_3d(ni,nj,nk)
        real*4 pres_3d(ni,nj,nk)
        real*4 heights_3d(ni,nj,nk)

        real*4 bias_tsnd(max_snd,nk),bias_htlow(max_snd)
!       real*4 wt_tsnd(max_snd,nk)

        real*4 lat_tsnd(max_snd),lon_tsnd(max_snd)
        integer*4 igrid_tsnd(max_snd),jgrid_tsnd(max_snd)
        real*4 tsnd(max_snd,nk)     ! Vertically interpolated TSND temp
        real*4 inst_err_tsnd(max_snd) 
        character*5 c5_name(max_snd) 
        character*8 c8_obstype(max_snd) 

        logical l_qc,l_flag_vv,l_good_tsnd(max_snd),l_use_raob
        logical l_string_contains,l_struct

        include 'tempobs.inc'

        l_struct = .true.

        call get_r_missing_data(r_missing_data,istatus)
        if (istatus .ne. 1) then
           write (6,*) 'Error getting r_missing_data'
           return
        endif

        call get_tempob_time_window('SND',i4_window_ob,istatus)

        i4time_raob_window = 0

        do i_tsnd = 1,max_snd
            l_good_tsnd(i_tsnd) = .false.
            do k = 1,nk
                bias_tsnd(i_tsnd,k) = r_missing_data
            enddo ! k
        enddo

!       Read in TSND and Temperature sonde data

        call read_tsnd(i4time,heights_3d,                     ! Input
     1                   temp_3d,sh_3d,pres_3d,               ! Input
     1                   lat_tsnd,lon_tsnd,                   ! Output
     1                   lat,lon,                             ! Input
     1                   max_snd,                             ! Input
     1                   tsnd,inst_err_tsnd,                  ! Output
     1                   c5_name,c8_obstype,                  ! Output
     1                   l_use_raob,l_struct,                 ! Input
     1                   i4time_raob_window,                  ! Input
!    1                   t_maps_inc,                          ! Input
     1                   bias_htlow,                          ! Output
     1                   n_rass,n_snde,n_tsnd,                ! Output
     1                   ilaps_cycle_time,                    ! Input
     1                   ni,nj,nk,                            ! Input
     1                   r_missing_data,                      ! Input
     1                   istatus)                             ! Output

        if(istatus .ne. 1)then
            write(6,*)' bad istatus returned from read_tsnd'
            return
        endif

        n_good_tsnd = 0
        n_bad_tsnd = 0

        n_obs = 0

        do i_tsnd = 1,n_tsnd

          if(i_tsnd .le. 200 .or. i_tsnd .eq. (i_tsnd/10)*10)then
              iwrite = 1
          else
              iwrite = 0
          endif

          call latlon_to_rlapsgrid(lat_tsnd(i_tsnd),lon_tsnd(i_tsnd)
     1                          ,lat,lon,ni,nj,ri,rj,istatus)

          igrid_tsnd(i_tsnd) = nint(ri)
          jgrid_tsnd(i_tsnd) = nint(rj)


          if(istatus .eq. 1)then

!           Find Temperature bias for each level
            write(6,*)
            write(6,*)' Temperature bias, sounding # ',i_tsnd,'  '
     1                ,c5_name(i_tsnd),'  ',c8_obstype(i_tsnd)       
            if(iwrite .eq. 1)write(6,*)
     1      '   k     Tobs        sh      tamb      tlaps      bias'

            l_qc = .false.
!           l_flag_vv = .true.
            l_flag_vv = .false.

            do k = 1,nk
              if(tsnd(i_tsnd,k) .ne. r_missing_data)then

                IF(l_string_contains(c8_obstype(i_tsnd),'RASS',istatus)
     1                                                            ) THEN       
!                   Convert from virtual temperature to temperature
                    tvir = tsnd(i_tsnd,k)
                    sh = sh_3d(igrid_tsnd(i_tsnd),jgrid_tsnd(i_tsnd),k)       
                    p_pa = 
     1                 pres_3d(igrid_tsnd(i_tsnd),jgrid_tsnd(i_tsnd),k)    
                    tamb = devirt_sh(tvir,sh,p_pa)
                ELSE
                    sh = 0.
                    tamb = tsnd(i_tsnd,k)
                END IF

                bias_tsnd(i_tsnd,k) =  tamb -
     1                  temp_3d(igrid_tsnd(i_tsnd),jgrid_tsnd(i_tsnd),k)
!               wt_tsnd(i_tsnd,k) = 1.0

                if(iwrite .eq. 1)write(6,1)k,tsnd(i_tsnd,k),sh,tamb,
     1                  temp_3d(igrid_tsnd(i_tsnd),jgrid_tsnd(i_tsnd),k)
     1                                ,bias_tsnd(i_tsnd,k)
1               format(i4,f10.1,f10.4,3f10.1)
                if(abs(bias_tsnd(i_tsnd,k)) .gt. 10.)then
                   l_qc = .true.
                   if(iwrite .eq. 1)write(6,*)
     1                 ' ABS(Temp - FIRST GUESS) > 10., Temp NOT USED'       
                endif

!               This should discriminate the vertical velocity data (inactive)
                IF(l_string_contains(c8_obstype(i_tsnd),'RASS',istatus)
     1                                                            ) THEN       
                    if(abs(tamb-267.7) .gt. 3.0)then
                        l_flag_vv = .false.
                    endif
                ENDIF

              endif ! Valid data for this TSND at this level
            enddo ! k

!           Find range of levels with a bias value
            k_highest = 0
            k_lowest = nk+1
            do k = 1,nk
                if(bias_tsnd(i_tsnd,k) .ne. r_missing_data)then
                    k_highest = max(k_highest,k)
                    k_lowest  = min(k_lowest,k)
                endif
            enddo ! k

            if(iwrite .eq. 1)write(6,*)
     1                ' Vertically blended bias field, old/new temps # '       
     1               ,i_tsnd
            do k = 1,nk
                if(iwrite .eq. 1)write(6,11,err=12)k,bias_tsnd(i_tsnd,k)       
     1                 ,temp_3d(igrid_tsnd(i_tsnd),jgrid_tsnd(i_tsnd),k)
     1                 ,temp_3d(igrid_tsnd(i_tsnd),jgrid_tsnd(i_tsnd),k)    
     1                + bias_tsnd(i_tsnd,k) ! ,wt_tsnd(i_tsnd,k)
11              format(1x,i4,f7.1,3f8.1)
12              continue
            enddo ! k


!           Identify good TSND obs 
            if((.not. l_qc) .and. (.not. l_flag_vv))then
                if(iwrite .eq. 1)
     1              write(6,*)' Applying the TSND bias corrections'
                l_good_tsnd(i_tsnd) = .true.
                n_good_tsnd = n_good_tsnd + 1

!               Add TSND to data structure / observation vector
                do k = 1,nk
                    if(bias_tsnd(i_tsnd,k) .ne. r_missing_data)then
                        n_obs = n_obs + 1

                        if(n_obs .gt. max_obs)then
                            write(6,*)
     1                      ' Error - too many obs in data structure'
                            write(6,*)
     1                      ' Increase max_obs parameter from',max_obs       
                            istatus = 0
                            return
                        endif

                        temp_obs(n_obs,i_ri) = igrid_tsnd(i_tsnd)
                        temp_obs(n_obs,i_rj) = jgrid_tsnd(i_tsnd)
                        temp_obs(n_obs,i_rk) = k
                        temp_obs(n_obs,i_i) = igrid_tsnd(i_tsnd)
                        temp_obs(n_obs,i_j) = jgrid_tsnd(i_tsnd)
                        temp_obs(n_obs,i_k) = k
                        temp_obs(n_obs,i_ob_grid) = 
     1                  temp_3d(igrid_tsnd(i_tsnd),jgrid_tsnd(i_tsnd),k)       
     1                                            + bias_tsnd(i_tsnd,k)
                        temp_obs(n_obs,i_wt) = 
     1                      1.0 / inst_err_tsnd(i_tsnd)**2
                        temp_obs(n_obs,i_bias) = bias_tsnd(i_tsnd,k)
                        temp_obs(n_obs,i_inst_err) = 
     1                      inst_err_tsnd(i_tsnd)     
                    endif
                enddo ! k

            else
                write(6,*)' Not using TSND data due to QC problems'
                write(6,*)' l_qc =      ',l_qc
                write(6,*)' l_flag_vv = ',l_flag_vv
                l_good_tsnd(i_tsnd) = .false.
                n_bad_tsnd = n_bad_tsnd + 1
                do k = 1,nk
                    bias_tsnd(i_tsnd,k) = r_missing_data
                enddo ! k
            endif

          else  ! failed istatus test
            write(6,*)' TSND station # ',i_tsnd,' is outside of LAPS'  
     1               ,' grid (or missing)'

          endif ! istatus test

        enddo ! i_tsnd

        write(6,*)' # of TSND stations passing QC = ',n_good_tsnd
        write(6,*)' # of TSND stations failing QC = ',n_bad_tsnd
        write(6,*)' % of TSND stations failing QC = '
     1                      ,pct_rejected(n_good_tsnd,n_bad_tsnd)

        write(6,*)' # of obs in data structure (tsnds only) = '
     1            ,n_obs

!       Read ACARS Temps
        n_obs_before = n_obs

        call get_meso_sao_pirep(dum,dum,MAX_ACARS,istatus)
        if(istatus .ne. 1)return

        call rd_acars_t(i4time,heights_3d,temp_3d                   ! I
     1                       ,MAX_ACARS                             ! I
     1                       ,n_good_acars                          ! O
     1                       ,'pin'                                 ! I
!    1                       ,u_maps_inc,v_maps_inc                 ! I
     1                       ,ni,nj,nk                              ! I
     1                       ,lat,lon,r_missing_data                ! I
     1                       ,temp_obs,max_obs,n_obs                ! I/O
     1                       ,istatus)                              ! O

!       n_obs = n_obs_before   ! Temporary for testing

        write(6,*)' # of obs in data structure (tsnds + acars) = '
     1            ,n_obs

        call get_rep_pres_intvl(pres_3d,ni,nj,nk,rep_pres_intvl
     1                         ,istatus)

        call analyze_tobs(n_tsnd,ni,nj,nk,l_good_tsnd          ! I
     1      ,weight_bkg_const                                  ! I
     1      ,grid_spacing_m,rep_pres_intvl,max_snd             ! I
     1      ,temp_obs,max_obs,n_obs                            ! I
     1      ,r_missing_data                                    ! I
     1      ,l_struct,rms_thresh_norm                          ! I
     1      ,igrid_tsnd,jgrid_tsnd,bias_tsnd                   ! I
     1      ,temp_3d                                           ! I/O
     1      ,istatus)                                          ! O

        if(istatus .ne. 1)then
            write(6,*)' Bad istatus returned from analyze_tobs'
            return
        endif

        istatus = 1
        return
        end


        subroutine analyze_tobs(n_tsnd,ni,nj,nk,l_good_tsnd       ! I     
     1      ,weight_bkg_const                                     ! I
     1      ,grid_spacing_m,rep_pres_intvl,max_snd                ! I
     1      ,temp_obs,max_obs,n_obs                               ! I
     1      ,r_missing_data                                       ! I
     1      ,l_struct,rms_thresh_norm                             ! I
     1      ,igrid_tsnd,jgrid_tsnd,bias_tsnd                      ! I
     1      ,temp_3d                                              ! I/O
     1      ,istatus)                                             ! I

!       Original Version        Steve Albers

!       Jun 16 1997             Ken Dritz
!       Changed NZ_L_MAX to nk.

!       Jun 16 1997             Ken Dritz
!       Added r_missing_data as dummy argument.  Pass r_missing_data to
!       barnes_univariate_shell.

        real*4 temp_3d(ni,nj,nk)

!       These arrays are passed in
        real*4 bias_3d(ni,nj,nk)
        real*4 bias_tsnd(max_snd,nk)
!       real*4 wt_tsnd(max_snd,nk)

        integer*4 igrid_tsnd(max_snd),jgrid_tsnd(max_snd)

        logical l_good_tsnd(max_snd),l_analyze(nk),l_struct

        include 'tempobs.inc'

        write(6,*)
        write(6,*)' Subroutine analyze_tsnd'

        if(.true.)then ! Use Barnes analysis routine (multi-TSND)

          if(n_obs .gt. 0)then
           ! This is in effect a single pass Barnes with a spatially varying
           ! radius of influence to account for clustering of data

             call get_fnorm_max(ni,nj,r0_norm,r0_value_min,fnorm_max)
             n_fnorm = int(fnorm_max) + 1

             write(6,*)' Calling new barnes_univariate_shell routine'

             call barnes_univariate_shell(ni,nj,nk           ! Inputs
     1               ,r_missing_data                         ! Input
     1               ,grid_spacing_m,rep_pres_intvl          ! Input
     1               ,max_snd                                ! Input
     1               ,l_good_tsnd,n_tsnd                     ! Inputs
     1               ,bias_tsnd                              ! Input
     1               ,temp_obs,max_obs,n_obs                 ! Input
     1               ,bias_3d                                ! Output
     1               ,l_analyze                              ! Output
     1               ,l_struct,rms_thresh_norm               ! Input
     1               ,igrid_tsnd,jgrid_tsnd                  ! Inputs
     1               ,weight_bkg_const                       ! Input
     1               ,n_fnorm                                ! Input
     1               ,istatus)                               ! Output

             if(istatus .ne. 1)then
                 write(6,*)' Bad status ret fm barnes_univariate'
                 return
             endif

             write(6,*)' Adding back in the biases'
             do k = 1,nk
               if(.true.)then
                 do j = 1,nj
                 do i = 1,ni
                   if(bias_3d(i,j,k) .ne. r_missing_data)then
                     temp_3d(i,j,k) = temp_3d(i,j,k) + bias_3d(i,j,k)       
                   endif
                 enddo ! i
                 enddo ! j
               endif ! l_analyze(k)
             enddo ! k

          else
             write(6,*)' No Good Obs Data, Barnes skipped'
             istatus = 1

          endif ! N GOOD OBS > 0

        endif ! Do Barnes

        return
        end


        subroutine barnes_univariate_shell(ni,nj,nk              ! Inputs
     1                   ,r_missing_data                         ! Input
     1                   ,grid_spacing_m,rep_pres_intvl          ! Input
     1                   ,max_snd                                ! Input
     1                   ,l_good_tsnd,n_tsnd                     ! Inputs
     1                   ,bias_tsnd                              ! Input
     1                   ,temp_obs,max_obs,n_obs                 ! Input
     1                   ,bias_3d                                ! Output
     1                   ,l_analyze                              ! Output
     1                   ,l_struct,rms_thresh_norm               ! Input
     1                   ,igrid_tsnd,jgrid_tsnd                  ! Inputs
     1                   ,weight_bkg_const                       ! Input
     1                   ,n_fnorm                                ! Input
     1                   ,istatus)                               ! Output

!       Jun 16 1997             Ken Dritz
!       Changed NZ_L_MAX to nk.

!       Jun 16 1997             Ken Dritz
!       Added r_missing_data as dummy argument.

        integer*4 max_obs_b
        parameter (max_obs_b = 40000)       
        include 'barnesob.inc'
        type (barnesob) obs_barnes(max_obs_b)                           

        logical l_good_tsnd(max_snd),l_struct,l_not_struct
        real*4 bias_tsnd(max_snd,nk)
        integer*4 igrid_tsnd(max_snd),jgrid_tsnd(max_snd)
!       real*4 wt_tsnd(max_snd,nk)

        real*4 bias_obs_3d(ni,nj,nk)
        real*4 bias_3d(ni,nj,nk)
        real*4 wt_3d(ni,nj,nk)
        integer*4 n_obs_lvl(nk)                                ! Local

        logical l_analyze(nk)

        integer*4  n_fnorm

        dimension fnorm(0:n_fnorm)

        include 'tempobs.inc'

        write(6,*)' Subroutine Barnes_univariate_shell'

        do k = 1,nk

            l_analyze(k) = .false.

            do i = 1,ni
            do j = 1,nj

                wt_3d(i,j,k) = 0.
                bias_obs_3d(i,j,k) = r_missing_data

            enddo ! j
            enddo ! i

        enddo ! k

        write(6,*)' filling bias_obs_3d array from data structure'

        sumsq_inst = 0.
        n_obs_valid = 0
            
        do i_ob = 1,n_obs
            if(temp_obs(i_ob,i_bias) .ne. r_missing_data)then     

!               Determine i,j,k of ob and use the ob.
                i = temp_obs(i_ob,i_i)
                j = temp_obs(i_ob,i_j)
                k = temp_obs(i_ob,i_k)

                bias_obs_3d(i,j,k) = temp_obs(i_ob,i_bias)
                wt_3d(i,j,k) = temp_obs(i_ob,i_wt)

                l_analyze(k) = .true.

!               Should we reduce this?
                write(6,71)i,j,k,bias_obs_3d(i,j,k),wt_3d(i,j,k)
71              format(1x,3i4,2e11.4)

                sumsq_inst = sumsq_inst + temp_obs(i_ob,i_inst_err)**2
                n_obs_valid = n_obs_valid + 1

!               Place ob from 'temp_obs' structure into 'obs_barnes' structure
                obs_barnes(n_obs_valid)%i = temp_obs(i_ob,i_i) 
                obs_barnes(n_obs_valid)%j = temp_obs(i_ob,i_j)
                obs_barnes(n_obs_valid)%k = temp_obs(i_ob,i_k)
                obs_barnes(n_obs_valid)%weight = temp_obs(i_ob,i_wt)
                obs_barnes(n_obs_valid)%value(1) = temp_obs(i_ob,i_bias)

            endif

        enddo ! Loop through i_ob

        if(n_obs_valid .eq. n_obs)then
            if(n_obs_valid .gt. 0)then
                rms_inst = sqrt(sumsq_inst/float(n_obs_valid))
            else
                rms_inst = 0.
            endif

            write(6,*)' n_obs_valid,rms_inst = ',n_obs_valid,rms_inst       

        else
            write(6,*)' ERROR: n_obs_valid .ne. n_obs'
     1                          ,n_obs_valid,n_obs
        endif

!       Set the rms threshold for iteration cutoff, based on instrument error
        rms_thresh = rms_thresh_norm * rms_inst

        write(6,*)'rms_thresh_norm,rms_thresh'
     1            ,rms_thresh_norm,rms_thresh      

        n_var = 1

        l_not_struct = .not. l_struct

        call barnes_multivariate(
     1                      bias_3d                           ! Outputs
     1                     ,n_var,n_obs_valid,obs_barnes      ! Input
     1                     ,ni,nj,nk,grid_spacing_m           ! Inputs
     1                     ,rep_pres_intvl                    ! Input
     1                     ,bias_obs_3d,wt_3d,fnorm,n_fnorm   ! Inputs
     1                     ,l_analyze,l_not_struct,rms_thresh ! Input
     1                     ,weight_bkg_const                  ! Input
     1                     ,n_obs_lvl,istatus)                ! Outputs

        return
        end




      subroutine get_obstype(c_obstype,i_obstype,mode)

      integer n_obstypes
      parameter (n_obstypes = 4)
      character*8 c_obstype_a(n_obstypes),c_obstype

      data c_obstype_a /
     1     'RASS    ',
     1     'RAOB    ',
     1     'ACARS   ',
     1     'SATSND  '/
     
      if(mode .eq. 1)then ! Convert c_obstype to i_obstype

          call s_len(c_obstype,len1)

          i_obstype = 0                            ! UNKNOWN

          do i = 1,n_obstypes
              call s_len(c_obstype_a(i),len2)
              if(c_obstype(1:len1) .eq. 
     1           c_obstype_a(i)(1:len2))i_obstype = i
          enddo ! i

      else                ! Convert i_obstype to c_obstype
          if(i_obstype .gt. 0 .and. i_obstype .le. n_obstypes)then
              c_obstype = c_obstype_a(i_obstype)
          else
              c_obstype = 'UNKNOWN'
          endif

      endif

      return
      end

