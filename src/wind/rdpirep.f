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
        subroutine rdpirep(i4time,heights_3d
     1  ,N_PIREP
     1  ,u_maps_inc,v_maps_inc,ni,nj,nk
     1  ,lat,lon
     1  ,pirep_i,pirep_j,pirep_k,pirep_u,pirep_v,n_pirep_obs
     1  ,grid_laps_wt,grid_laps_u,grid_laps_v
     1                                                  ,istatus)

!       Original version Steve Albers / FSL
!       Modified 2/1993 by Steve Albers to fix check on pirep being in the
!       domain as suggested by Steve Olson of LL.

!       1997 Jun    Ken Dritz     Added N_PIREP as dummy argument, making
!                                 arrays dimensioned therewith automatic.
!       1997 Jun    Ken Dritz     Removed include of 'lapsparms.for'.

!******************************************************************************
!       LAPS Grid Dimensions

        include 'windparms.inc' ! weight_pirep

        real*4 lat(ni,nj)
        real*4 lon(ni,nj)

!       Pireps

        integer pirep_i(N_PIREP) ! X pirep coordinates
        integer pirep_j(N_PIREP) ! Y pirep coordinates
        integer pirep_k(N_PIREP) ! Z pirep coordinates
        real    pirep_u(N_PIREP) ! u pirep component
        real    pirep_v(N_PIREP) ! v pirep component


!       Laps Analysis Grids
        real grid_laps_wt(ni,nj,nk)
        real grid_laps_u(ni,nj,nk)
        real grid_laps_v(ni,nj,nk)

!******************************************************************************

        real*4 heights_3d(ni,nj,nk)
        real*4 u_maps_inc(ni,nj,nk)
        real*4 v_maps_inc(ni,nj,nk)

        character*13 filename13

        character*9 asc9_tim_pirep
        character ext*31

        logical l_eof

        lun_pin = 31
        lun_pig = 32

        n_pirep_obs = 0

        ext = 'pin'
        call open_lapsprd_file(lun_pin,i4time,ext,istatus)
        if(istatus .ne. 1)go to 999

        ext = 'pig'
        call open_lapsprd_file(lun_pig,i4time,ext,istatus)
        if(istatus .ne. 1)go to 888


        call get_laps_cycle_time(ilaps_cycle_time,istatus)
        if(istatus .eq. 1)then
            write(6,*)' ilaps_cycle_time = ',ilaps_cycle_time
        else
            write(6,*)' Error getting laps_cycle_time'
            return
        endif

        i4time_pirep_thr = min(nint(ilaps_cycle_time*2.00),3600)
        write(6,*)' i4time_pirep_thr = ',i4time_pirep_thr

5       write(6,12)
12      format(/'             Reading Pirep Obs'
     1      /'   n   i  j  k    u      v'
     1      ,'       dd     ff      azi    ran ')

10      call read_laps_pirep_wind(lun_pin,xlat,xlon,elev,dd,ff
     1                                          ,asc9_tim_pirep,l_eof)
        if(l_eof)goto900

        call cv_asc_i4time(asc9_tim_pirep,i4time_pirep)


        if(abs(i4time_pirep - i4time) .lt. i4time_pirep_thr)then

            rcycles = float(i4time - i4time_pirep) 
     1              / float(ilaps_cycle_time)

!           Climo QC check
            if(dd .lt. 500.)then

                call latlon_to_rlapsgrid(xlat,xlon,lat,lon,ni,nj
     1                                  ,ri,rj,istatus)
                i_grid = nint(ri)
                j_grid = nint(rj)

                if(i_grid .ge.  1 .and. j_grid .ge. 1 .and.
     1             i_grid .le. ni .and. j_grid .le. nj)then

!                   Pirep is in horizontal domain

                    rk = height_to_zcoord2(elev,heights_3d
     1                          ,ni,nj,nk,i_grid,j_grid,istatus)
                    if(istatus .ne. 1)return

                    k_grid = nint(rk)

                    if(    .true.
     1             .and. k_grid .le. nk
     1             .and. k_grid .ge. 1    )then ! Pirep is in vertical domain

                        n_pirep_obs = n_pirep_obs + 1

                        if(n_pirep_obs .gt. N_PIREP)then
                           write(6,*)' Warning: Too many pireps, '
     1                              ,'limit is ',N_PIREP
                           istatus = 0
                           return
                        endif

                        pirep_i(n_pirep_obs) = i_grid
                        pirep_j(n_pirep_obs) = j_grid

                        if(elev .gt. 0.)call disp_to_uv(dd,ff,u_temp,v_t
     1emp)

                        pirep_k(n_pirep_obs) = k_grid

                        u_diff = u_maps_inc(i_grid,j_grid,k_grid) * rcyc
     1les
                        v_diff = v_maps_inc(i_grid,j_grid,k_grid) * rcyc
     1les

                        pirep_u(n_pirep_obs) = u_temp + u_diff
                        pirep_v(n_pirep_obs) = v_temp + v_diff

                        write(lun_pig,*)ri-1.,rj-1.,rk-1.,dd,ff

                        write(6,101)xlat,xlon,dd,ff,elev
     1          ,u_temp,v_temp,pirep_u(n_pirep_obs),pirep_v(n_pirep_obs)
101                     format(2f8.2,2f8.1,f8.0,4f8.2)

!                 ***   Remap pirep observation to LAPS observation grid

                        grid_laps_u
     1   (pirep_i(n_pirep_obs),pirep_j(n_pirep_obs),pirep_k(n_pirep_obs)
     1)
     1  = pirep_u(n_pirep_obs)

                        grid_laps_v
     1   (pirep_i(n_pirep_obs),pirep_j(n_pirep_obs),pirep_k(n_pirep_obs)
     1)
     1  = pirep_v(n_pirep_obs)

                        grid_laps_wt
     1   (pirep_i(n_pirep_obs),pirep_j(n_pirep_obs),pirep_k(n_pirep_obs)
     1)
     1  = weight_pirep

                    endif ! In vertical bounds


                    write(6,20)n_pirep_obs,
     1                 pirep_i(n_pirep_obs),
     1                 pirep_j(n_pirep_obs),
     1                 pirep_k(n_pirep_obs),
     1                 pirep_u(n_pirep_obs),
     1                 pirep_v(n_pirep_obs),
     1                 dd,ff
20                  format(i4,1x,3i3,2f7.1,2x,2f7.1,2x,2f7.1,2x,2f7.1)

                else
                    write(6,*)' Out of horizontal bounds',i_grid,j_grid        

                endif ! In horizontal bounds
            endif ! Good data

        else
            write(6,*)' Out of temporal bounds'
     1                              ,abs(i4time_pirep - i4time)

        endif ! In temporal bounds

100     goto10

900     write(6,*)' End of PIREP PIN file, # obs = ',n_pirep_obs

        close(lun_pin)
        close(lun_pig)

        istatus = 1

        return

999     write(6,*)' No pirep data present'
        istatus = 1
        return


888     write(6,*)' Open error for PIG file'
        istatus = 0
        close(lun_pig)
        return

        end


!       subroutine read_laps_pirep_windo(lun,xlat,xlon,elev,dd,ff
!    1                                          ,asc9_tim_pirep,l_eof)

!       real*4 elev ! ft
!       real*4 dd   ! degrees (99999. is missing)
!       real*4 ff   ! meters/sec (99999. is missing)

!       character*9 asc9_tim_pirep

!       logical l_eof

!       l_eof = .false.

!100     read(lun,895,err=100,end=900)xlat,xlon,elev,dd,ff,asc9_tim_pirep
! 895    FORMAT(2F8.2,f8.0,1X,'ddff',F7.0,F7.0,'  t',F8.1,2a10)

!       return

!900     l_eof = .true.

!       return
!       end

        subroutine read_laps_pirep_wind(lun,xlat,xlon,elev,dd,ff
     1                                          ,asc9_tim_pirep,l_eof)

        real*4 elev ! meters
        real*4 dd   ! degrees (99999. is missing)
        real*4 ff   ! meters/sec (99999. is missing)

        character*9 asc9_tim_pirep,asc9_tim_rcvd
        character*80 string

        logical l_eof

        dd = 99999.
        ff = 99999.

        l_eof = .false.

5       read(lun,101,end=900,err=5)string(1:6)
101     format(a6)

        if(string(2:5) .eq. 'Time')then
!           a9time = string(30:39)
            read(lun,151)asc9_tim_pirep,asc9_tim_rcvd
151         format(1x,a9,2x,a9)
            write(6,151)asc9_tim_pirep,asc9_tim_rcvd
        endif

        if(string(2:4) .eq. 'Lat')then
            read(lun,201)xlat,xlon,elev
201         format(2(f8.3,2x), f6.0,2i5)
        endif

        if(string(2:5) .eq. 'Wind')then
            read(lun,202)idir_deg,ff
202         format (' ', i3, ' deg @ ', f6.1, ' m/s')
            write(6,202)idir_deg,ff
            dd = idir_deg
!           ff = ispd_kt * .518
            return
        endif

        if(string(2:5) .eq. 'Clou')then
            do i = 1,3
                read(lun,203,err=500)cbase_ft,ctop_ft,icover
203             format (12x,2f8.0,i5)
            enddo ! i cloud layer
        endif ! Cloud Report String

!       if(string(2:5) .eq. 'Sky ')then
!           read(lun,204,err=500)isky_cover
!204         format (40x,i4)
!            write(6,*)' sky cover = ',isky_cover
!        endif

500     goto5

900     l_eof = .true.

        return

        end
