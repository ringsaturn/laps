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

        subroutine interp_prof(ob_pr_ht_obs,ob_pr_u_obs,ob_pr_v_obs,
     1                             u_diff       , v_diff,
     1                             u_interp     , v_interp,
     1                             r_interp     , t_interp,
     1                             di_interp    , sp_interp,
     1                             i_pr,ht,level,nlevels_obs_pr,
     1                             lat_pr,lon_pr,i_ob,j_ob,
     1                             azimuth,r_missing_data,
     1                             heights_3d,ni,nj,nk,
     1                             MAX_PR,MAX_PR_LEVELS,
     1                             n_vel_grids,istatus)

!************************ARRAYS.FOR******************************************

!       Profiler Observations

        integer nlevels_obs_pr(MAX_PR)
        real ob_pr_ht_obs(MAX_PR,MAX_PR_LEVELS)
        real ob_pr_u_obs(MAX_PR,MAX_PR_LEVELS)
        real ob_pr_v_obs(MAX_PR,MAX_PR_LEVELS)

!**************************** END ARRAYS.FOR ********************************
        real*4 heights_3d(ni,nj,nk)

        u_interp = r_missing_data
        v_interp = r_missing_data
        r_interp = r_missing_data
        t_interp = r_missing_data
        di_interp = r_missing_data
        sp_interp = r_missing_data

!  ***  Interpolate the profiler observations to the input height *******
        do i_obs = 1,nlevels_obs_pr(i_pr)

          if(i_obs .gt. 1)then

            if(ob_pr_ht_obs(i_pr,i_obs-1) .le. ht .and.
     1       ob_pr_ht_obs(i_pr,i_obs  ) .ge. ht)then

                h_lower  = ob_pr_ht_obs(i_pr,i_obs-1)
                h_upper =  ob_pr_ht_obs(i_pr,i_obs  )

                height_diff = h_upper - h_lower

                fracl = (h_upper - ht) / height_diff
                frach = 1.0 - fracl

                u_interp = ob_pr_u_obs(i_pr,i_obs) * frach
     1                    +       ob_pr_u_obs(i_pr,i_obs-1) * fracl

                v_interp = ob_pr_v_obs(i_pr,i_obs) * frach
     1                    +       ob_pr_v_obs(i_pr,i_obs-1) * fracl

!               Correct for the time lag
                u_interp = u_interp + u_diff
                v_interp = v_interp + v_diff

!               Calculate direction and speed
                call uv_to_disp(         u_interp,
     1                           v_interp,
     1                           di_interp,
     1                           sp_interp)

                if(n_vel_grids .gt. 0)then

!                  Calculate radial and tangential velocity

                   call uvtrue_to_radar( u_interp,
     1                           v_interp,
     1                           t_interp,
     1                           r_interp,
     1                           azimuth)

                endif ! Radar data is present

             endif
          endif

        enddo ! level

        if(.true.)return


!       Lower Tail

        if( float(level)
     1    .lt. height_to_zcoord2(ob_pr_ht_obs(i_pr,1),heights_3d
     1                          ,ni,nj,nk,i_ob,j_ob,istatus)
     1                          .and.
     1  (height_to_zcoord2(ob_pr_ht_obs(i_pr,1),heights_3d
     1                          ,ni,nj,nk,i_ob,j_ob,istatus)
     1       - float(level)) .le. 0.5)then

                u_interp  = ob_pr_u_obs(i_pr,1)
                v_interp  = ob_pr_v_obs(i_pr,1)

!               Correct for the time lag
                u_interp = u_interp + u_diff
                v_interp = v_interp + v_diff

!               Calculate direction and speed
                call uv_to_disp(         u_interp,
     1                           v_interp,
     1                           di_interp,
     1                           sp_interp)

                if(n_vel_grids .gt. 0)then

!                  Calculate radial and tangential velocity

                   call uvtrue_to_radar( u_interp,
     1                           v_interp,
     1                           t_interp,
     1                           r_interp,
     1                           azimuth)

              endif ! Radar data is present

        endif

        if(istatus .ne. 1)then
            write(6,*)' Warning, out of bounds in height_to_zcoord2/inte
     1rp_prof'
        endif

!       Upper Tail

        if( float(level) .gt.
     1  height_to_zcoord2(ob_pr_ht_obs(i_pr,nlevels_obs_pr(i_pr))
     1                  ,heights_3d,ni,nj,nk,i_ob,j_ob,istatus)
     1                           .and.
     1    (float(level) -
     1     height_to_zcoord2(ob_pr_ht_obs(i_pr,nlevels_obs_pr(i_pr))
     1                  ,heights_3d,ni,nj,nk,i_ob,j_ob,istatus))
     1                                          .le. 0.5)then

                u_interp  = ob_pr_u_obs(i_pr,nlevels_obs_pr(i_pr))
                v_interp  = ob_pr_v_obs(i_pr,nlevels_obs_pr(i_pr))

!               Correct for the time lag
                u_interp = u_interp + u_diff
                v_interp = v_interp + v_diff

!               Calculate direction and speed
                call uv_to_disp(         u_interp,
     1                           v_interp,
     1                           di_interp,
     1                           sp_interp)

            if(n_vel_grids .gt. 0)then

!               Calculate radial and tangential velocity

                call uvtrue_to_radar(    u_interp,
     1                           v_interp,
     1                           t_interp,
     1                           r_interp,
     1                           azimuth)

             endif

        endif

        if(istatus .ne. 1)then
            write(6,*)' Warning, out of bounds in height_to_zcoord2/inte
     1rp_prof'
        endif

        return

        end

