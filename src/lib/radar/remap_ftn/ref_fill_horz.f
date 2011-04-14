
        subroutine ref_fill_horz(ref_3d,ni,nj,nk,lat,lon,dgr
     1                ,rlat_radar,rlon_radar,rheight_radar,istatus)

!       Steve Albers            1998

!       ni,nj,nk are input LAPS grid dimensions
!       rlat_radar,rlon_radar,rheight_radar are input radar coordinates
!       Input field 'ref_3d' is assumed to either equal 'ref_base' or 
!       'r_missing_data' or a valid value. QC flags are also allowed though
!       this is still being assessed. 
!       Output is either filled in value or original reflectivity

        include 'remap_constants.dat'
        include 'remap.cmn'

        real ref_3d(ni,nj,nk)                  ! Input/Output 3D reflct grid
        real lat(ni,nj),lon(ni,nj),topo(ni,nj) ! Input 2D grids

        real ref_2d_buf(ni,nj)
        real radar_dist(ni,nj)
        integer ngrids(ni,nj), ngrids_max

        logical l_fill, l_process(ni,nj)

        parameter (ngrids_max = 10)
        real weight_a(-ngrids_max:+ngrids_max,-ngrids_max:+ngrids_max)

        write(6,*)' Subroutine ref_fill_horz...'

!       Obtain grid spacing
        call get_grid_spacing(grid_spacing_m,istatus)
        if(istatus .ne. 1)then
            write(6,*)' ERROR in ref_fill_horz'
            return
        endif

!       Obtain base reflectivity
        call get_ref_base(ref_base,istatus)
        if(istatus .ne. 1)then
            write(6,*)' ref_fill_horz: Error reading ref_base'
            return
        endif

        call get_r_missing_data(r_missing_data,istatus)
        if(istatus .ne. 1)then
            write(6,*)' ref_fill_horz: Error reading r_missing_data'
            return
        endif

!       Calculate radar distance array
        do i = 1,ni
        do j = 1,nj
            call latlon_to_radar(lat(i,j),lon(i,j),0.,
     1                           azimuth,slant_range,elev,
     1                           rlat_radar,rlon_radar,rheight_radar)
            radar_dist(i,j) = slant_range

!           Determine number of gridpoints in potential gaps = f(radar_dist)
            ngrids(i,j) = radar_dist(i,j) * (dgr / 57.) / grid_spacing_m       

            if(ngrids(i,j)   .ge. 1 
     1                     .AND. 
     1         radar_dist(i,j) .le. 500000.) then
                l_process(i,j) = .true.
            else
                l_process(i,j) = .false.
            endif

        enddo ! j
        enddo ! i

!       Fill weight_a array (we can make this a Barnes weight later)
        do iw = -ngrids_max,+ngrids_max
        do jw = -ngrids_max,+ngrids_max
             weight_a(iw,jw) = 1.0
        enddo ! jw
        enddo ! iw

        do k = 1,nk
!           call move(ref_3d(1,1,k),ref_2d_buf,ni,nj) ! Initialize Buffer Array
            ref_2d_buf(:,:) = ref_3d(:,:,k)           ! Initialize Buffer Array
            n_add_lvl = 0

            do i = 1,ni
            do j = 1,nj
                n_neighbors     = 0
                n_neighbors_pot = 0

!               Assess neighbors to see if we should fill in this grid point
                if(l_process(i,j))then

                  if(ref_3d(i,j,k) .eq. r_missing_data)then       

                    ref_sum = 0.
                    z_sum = 0.
                    wt_sum = 0.

!                   weight = 1.0

                    iil = max(i-ngrids(i,j),1)
                    jjl = max(j-ngrids(i,j),1)
                    iih = min(i+ngrids(i,j),ni)
                    jjh = min(j+ngrids(i,j),nj)

                    do ii = iil,iih
                      iw = ii-i
                      do jj = jjl,jjh
                        jw = jj-j

                        weight = weight_a(iw,jw)

                        n_neighbors_pot = n_neighbors_pot + 1
                        if(ref_3d(ii,jj,k) .ne. r_missing_data   )then
                            n_neighbors = n_neighbors + 1
                            ref_sum = ref_sum + ref_3d(ii,jj,k) * weight       

                            ilut_ref = nint(ref_3d(ii,jj,k) * 10.)
                            ilut_ref = max(ilut_ref, -1000)
                            z = dbz_to_z_lut(ilut_ref)
                            z_sum = z_sum + z * weight
                          
                            wt_sum = wt_sum + weight
                            if(n_add_lvl .le. 20)then
                                write(6,10)i,j,ngrids(i,j),n_neighbors       
     1                                    ,ii,jj,ref_3d(ii,jj,k)
 10                             format(2i5,' neighbor ',2i3,2i5,f9.1)
                            endif
                        endif

                      enddo ! jj
                    enddo ! ii
                  endif
                endif ! l_process

!               if(ngrids(i,j) .le. 1)then
                    neighbor_thresh = 1
!               else
!                   neighbor_thresh = 1
!               endif

                l_fill = .false.

                if(n_neighbors .ge. neighbor_thresh)then 
                    ref_fill = ref_sum / float(n_neighbors)

                    z_ave = z_sum / float(n_neighbors)
                    dbz_ave = alog10(z_ave) * 10.  ! Currently just a test
                    
                    l_fill = .true. ! Improves coverage if always .true.

!                   Massage reflectivities based on likely QC flag averaging
                    if(ref_fill .lt. ref_base)then        ! QC flags present
                        if(ref_fill .gt. -50.)then
                            ref_fill = ref_base
                        elseif(ref_fill .lt. -100.5 .and. 
     1                         ref_fill .gt. -101.5          )then
                            ref_fill = -101.              ! QC Insuff Coverage
                        else
                            ref_fill = -102.              ! QC Low Ref
                        endif
                    endif
                endif

!               Fill into buffer array?
                if(l_fill)then 
                    ref_2d_buf(i,j) = ref_fill ! ref_3d(i,j,k) (test disable)
                    n_add_lvl = n_add_lvl + 1
                    if(n_add_lvl .le. 20)then
                        write(6,*)i,j,ngrids(i,j),n_neighbors
     1                           ,n_neighbors_pot,ref_fill
                    endif

                else          ! do not fill in this grid point
                    ref_2d_buf(i,j) = ref_3d(i,j,k) ! ref_base
                    if(n_add_lvl .le. 20 
     1                           .and. n_neighbors     .gt. 0
     1                           .and. n_neighbors_pot .gt. 0)then
                        write(6,*)i,j,ngrids(i,j),n_neighbors
     1                           ,n_neighbors_pot,' not filled'
                    endif

                endif         ! enough neighbors to fill in a grid point

            enddo ! j
            enddo ! i

!           Copy buffer array to main array
            if(n_add_lvl .gt. 0)then ! efficiency test
                write(6,11)k,n_add_lvl
 11             format(' lvl/n_added ',2i7)
                call move(ref_2d_buf,ref_3d(1,1,k),ni,nj)
            endif

        enddo ! k

        istatus = 1
        return

        end

