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

        subroutine latlon_to_rlapsgrid(rlat,rlon,lat,lon,ni,nj,ri,rj
     1                                ,istatus)

!       1991            Steve Albers
!       1994            Steve Albers - partially added lambert option
!       1997            Steve Albers - Added both kinds of lambert projections
!                                    - as well as mercator projection
!       1997            Steve Albers - Added local stereographic

!       This routine assumes a polar stereographic, lambert conformal,
!       or mercator projection.

        real*4 rlat                         ! Input Lat
        real*4 rlon                         ! Input Lon
        real*4 lat(ni,nj),lon(ni,nj)        ! Input (Arrays of LAT/LON)
        integer ni,nj                       ! Input (LAPS Dimensions)
        real*4 ri,rj                        ! Output (I,J on LAPS Grid)
        integer istatus                     ! Output

        save init,umin,umax,vmin,vmax
        data init/0/

        if(init .eq. 0)then
            call latlon_to_uv(lat(1,1),lon(1,1),umin,vmin,istatus)
            call latlon_to_uv(lat(ni,nj),lon(ni,nj),umax,vmax,istatus)

            write(6,101)umin,umax,vmin,vmax
101         format(1x,' Initializing latlon_to_rlapsgrid',4f10.5)
            init = 1
        endif

        uscale = (umax - umin) / (float(ni) - 1.)
        vscale = (vmax - vmin) / (float(nj) - 1.)

        u0 = umin - uscale
        v0 = vmin - vscale

!       Compute ulaps and vlaps

        call latlon_to_uv(rlat,rlon,ulaps,vlaps,istatus)

        ri = (ulaps - u0) / uscale
        rj = (vlaps - v0) / vscale

!       Set status if location of point rounded off is on the LAPS grid
        if(nint(ri) .ge. 1 .and. nint(ri) .le. ni .and.
     1     nint(rj) .ge. 1 .and. nint(rj) .le. nj         )then
            istatus = 1
        else
            istatus = 0
        endif

        return
        end

        subroutine rlapsgrid_to_latlon(ri,rj,lat,lon,ni,nj,rlat,rlon
     1                                ,istatus)

!       1997            Steve Albers 

!       This routine assumes a polar stereographic, lambert conformal,
!       or mercator projection.

        real*4 ri,rj                        ! Input (I,J on LAPS Grid)
        real*4 lat(ni,nj),lon(ni,nj)        ! Input (Arrays of LAT/LON)
        integer ni,nj                       ! Input (LAPS Dimensions)
        real*4 rlat                         ! Output Lat
        real*4 rlon                         ! Output Lon
        integer istatus                     ! Output

        save init,umin,umax,vmin,vmax
        data init/0/

        if(init .eq. 0)then
            call latlon_to_uv(lat(1,1),lon(1,1),umin,vmin,istatus)
            call latlon_to_uv(lat(ni,nj),lon(ni,nj),umax,vmax,istatus)

            write(6,101)umin,umax,vmin,vmax
101         format(1x,' Initializing rlapsgrid_to_latlon',4f10.5)
            init = 1
        endif

        uscale = (umax - umin) / (float(ni) - 1.)
        vscale = (vmax - vmin) / (float(nj) - 1.)

        u0 = umin - uscale
        v0 = vmin - vscale

!       Compute lat,lon
        ulaps = u0 + uscale * ri
        vlaps = v0 + vscale * rj

        call uv_to_latlon(ulaps,vlaps,rlat,rlon,istatus)

        istatus = 1

        return
        end

        
        subroutine latlon_to_uv(rlat,rlon,u,v,istatus)

!       1997            Steve Albers 

!       This routine assumes a polar stereographic, lambert conformal,
!       or mercator projection.

        include 'lapsparms.cmn'

        if(iflag_lapsparms_cmn .ne. 1)then
            write(6,*)' ERROR, get_laps_config not called'
            stop
        endif

        if(c6_maproj .eq. 'plrstr')then ! polar stereo
            slat1 = standard_latitude
            polat = standard_latitude2
            slon = standard_longitude

            call latlon_to_uv_ps(rlat,rlon,slat1,polat,slon,u,v)

        elseif(c6_maproj .eq. 'lambrt')then ! lambert
            slat1 = standard_latitude
            slat2 = standard_latitude2
            slon = standard_longitude

            call latlon_to_uv_lc(rlat,rlon,slat1,slat2,slon,u,v)

        elseif(c6_maproj .eq. 'merctr')then ! mercator
            slat1  = standard_latitude
            cenlon = grid_cen_lon_cmn

            call latlon_to_uv_mc(rlat,rlon,slat1,cenlon,u,v)

        else
            write(6,*)'latlon_to_uv: unrecognized projection '
     1                ,c6_maproj       
            stop

        endif

        istatus = 1

        return
        end


        subroutine latlon_to_uv_ps(rlat_in,rlon_in,slat,polat,slon,u,v)

        if(abs(polat) .eq. 90.)then ! pole at N/S geographic pole
            if(.true.)then
                polon = slon
                call GETOPS(rlat,rlon,rlat_in,rlon_in,polat,polon)
                rlon = rlon - 270.  ! Counteract rotation done in GETOPS

            else ! .false. (older simple method)
                rlat = rlat_in
                rlon = rlon_in

            endif

            b = rlon - slon         ! rotate relative to standard longitude

        else                        ! local stereographic
            polon = slon
            call GETOPS(rlat,rlon,rlat_in,rlon_in,polat,polon)
            b = rlon - 270.         ! rlon has zero angle pointing east
                                    ! b has zero angle pointing south
        endif

        a=90.-rlat
        r = tand(a/2.)      ! Consistent with Haltiner & Williams 1-21

!       b = angle measured counterclockwise from -v axis (zero angle south)
        u =  r * sind(b)
        v = -r * cosd(b)

        return
        end

        subroutine latlon_to_uv_lc(rlat,rlon,slat1,slat2,slon,u,v)

        real*4 n

!       Difference between two angles, result is between -180. and +180.
        angdif(X,Y)=MOD(X-Y+540.,360.)-180.

        call lambert_parms(slat1,slat2,n,s,rconst)

        r = (tand(45.-s*rlat/2.))**n
        u =    r*sind(n*angdif(rlon,slon))
        v = -s*r*cosd(n*angdif(rlon,slon))

        return
        end

        subroutine latlon_to_uv_mc(rlat,rlon,slat,cenlon,u,v)

        real*4 pi, rpd

        parameter (pi=3.1415926535897932)
        parameter (rpd=pi/180.)

!       Difference between two angles, result is between -180. and +180.
        angdif(X,Y)=MOD(X-Y+540.,360.)-180.
 
        a = 90.-rlat
        b = cosd(slat)

        u = angdif(rlon,cenlon) * rpd * b
        v = alog(1./tand(a/2.))       * b

        return
        end


        
        subroutine uv_to_latlon(u,v,rlat,rlon,istatus)

!       1997            Steve Albers 

!       This routine assumes a polar stereographic, lambert conformal,
!       or mercator projection.

        include 'lapsparms.cmn'

        if(iflag_lapsparms_cmn .ne. 1)then
            write(6,*)' ERROR, get_laps_config not called'
            stop
        endif

        if(c6_maproj .eq. 'plrstr')then ! polar stereo
            slat1 = standard_latitude
            polat = standard_latitude2
            slon = standard_longitude

            call uv_to_latlon_ps(u,v,slat1,polat,slon,rlat,rlon)

        elseif(c6_maproj .eq. 'lambrt')then ! lambert
            slat1 = standard_latitude
            slat2 = standard_latitude2
            slon = standard_longitude

            call uv_to_latlon_lc(u,v,slat1,slat2,slon,rlat,rlon)

        elseif(c6_maproj .eq. 'merctr')then ! mercator
            slat1  = standard_latitude
            cenlon = grid_cen_lon_cmn

            call uv_to_latlon_mc(u,v,slat1,cenlon,rlat,rlon)

        else
            write(6,*)'uv_to_latlon: unrecognized projection '
     1                ,c6_maproj       
            stop

        endif

        istatus = 1

        return
        end

        subroutine uv_to_latlon_ps(u,v,slat,polat,slon
     1                                         ,rlat_out,rlon_out)

        r=sqrt(u**2+v**2)

        if (r .eq. 0) then
            rlat=90.
            rlon=0.

        else                           
            a=2.* atand(r)               ! From Haltiner & Williams 1-21
            rlat=90.- a
            rlon = atan2d(v,u)
            rlon = rlon + 90.

        endif

        if(.true.)then ! Rotate considering where the projection pole is
            polon = slon
!           This routine will rotate the longitude even if polat = +90.
            call PSTOGE(rlat,rlon,rlat_out,rlon_out,polat,polon)
        else
            rlat_out = rlat
            rlon_out = rlon + slon
        endif

        rlon_out = amod(rlon_out+540.,360.) - 180. ! Convert to -180/+180 range

        return
        end

        subroutine uv_to_latlon_lc(u,v,slat1,slat2,slon,rlat,rlon)

        real*4 n

        call lambert_parms(slat1,slat2,n,s,rconst)

!       rlon=slon + atand(-s*u/v) /n
!       rlat=(90.- 2.*atand((-  v/cosd(n*(rlon-slon)))**(1./n)))/s      

        angle  = atan2d(u,-s*v)
        rlat = (90.- 2.*atand((-s*v/cosd(angle))**(1./n))) / s      
        rlon = slon + angle / n

        rlon = mod(rlon+540.,360.) - 180.          ! Convert to -180/+180 range

        return
        end

        subroutine uv_to_latlon_mc(u,v,slat,cenlon,rlat,rlon)

        parameter (pi=3.1415926535897932)
        parameter (rpd=pi/180.)

        b = cosd(slat)

        rlat_abs = 90. - atand(exp(-abs(v)/b)) * 2.

        if(v .gt. 0)then
            rlat =  rlat_abs
        else
            rlat = -rlat_abs
        endif

        rlon = u/b/rpd + cenlon
        rlon = mod(rlon+540.,360.) - 180.          ! Convert to -180/+180 range

        return
        end


        function projrot_laps(rlon)

        entry projrot_latlon(rlat,rlon,istatus)

!       1997 Steve Albers    Calculate map projection rotation, this is the
!                            angle between the y-axis (grid north) and
!                            true north. Units are degrees.
!
!                            projrot_laps = (true north value of wind direction
!                                          - grid north value of wind direction)

        real*4 n

        save init
        data init/0/

        include 'lapsparms.cmn'

!       Difference between two angles, result is between -180. and +180.
        angdif(X,Y)=MOD(X-Y+540.,360.)-180.

        if(iflag_lapsparms_cmn .ne. 1)then
            write(6,*)' ERROR, get_laps_config not called'
            stop
        endif

        if(c6_maproj .eq. 'plrstr')then ! polar stereographic
            polat = standard_latitude2
            polon = standard_longitude

            if(polat .eq. +90.)then
                projrot_laps = standard_longitude - rlon

            elseif(polat .eq. -90.)then
                projrot_laps = rlon - standard_longitude 

            else ! abs(polat) .ne. 90.
                if(grid_cen_lat_cmn .eq. polat .and. 
     1             grid_cen_lon_cmn .eq. polon)then ! grid centered on proj pole

                    if(init .eq. 0)then
                        write(6,*)
     1                   ' NOTE: local stereographic projection.'
                        write(6,*)
     1                   ' Using approximation for "projrot_laps",'
     1                  ,' accurate calculation not yet in place.'
                        init = 1
                    endif

                    rn = cosd(90.-polat)
                    projrot_laps = rn * angdif(standard_longitude,rlon)      

                elseif(.true.)then
                    if(init .eq. 0)then
                        write(6,*)' ERROR in projrot_laps: '
                        write(6,*)' This type of local'
     1                  ,' stereographic projection not yet supported.'
                        write(6,*)' Grid should be centered on'
     1                  ,' projection pole.'
                        init = 1
                    endif

                    projrot_laps = 0.
         
                else ! .false.
!                   Find dx/lat and dy/lat, then determine projrot_laps

                endif

            endif ! polat

        elseif(c6_maproj .eq. 'lambrt')then ! lambert conformal

            slat1 = standard_latitude
            slat2 = standard_latitude2

            call lambert_parms(slat1,slat2,n,s,rconst)

            projrot_laps = n * s * angdif(standard_longitude,rlon)

        elseif(c6_maproj .eq. 'merctr')then ! mercator
            projrot_laps = 0.

        else
            write(6,*)'projrot_laps: unrecognized projection ',c6_maproj       
            stop

        endif

        projrot_latlon = projrot_laps

        return
        end


      subroutine check_domain(lat,lon,ni,nj,grid_spacing_m,intvl
     1                                                       ,istatus)

!     This routine checks whether the lat/lon grid is consistent with
!     map projection parameters as processed by latlon_to_rlapsgrid,
!     and rlapsgrid_to_latlon. The grid size is also checked.
!     This is a good sanity check of the NetCDF static file, nest7grid.parms,
!     as well as various grid conversion routines.

!     1997 Steve Albers

      real*4 pi, rpd
      parameter (pi=3.1415926535897932)
      parameter (rpd=pi/180.)

      real*4 lat(ni,nj),lon(ni,nj)

      istatus = 1
      tolerance_m = 1000.

      diff_grid_max = 0.

      write(6,*)
      write(6,*)' subroutine check_domain: checking latlon_to_rlapsgrid'

      do i = 1,ni,intvl
      do j = 1,nj,intvl
          call latlon_to_rlapsgrid(lat(i,j),lon(i,j),lat,lon,ni,nj
     1                                              ,ri,rj,istat)

          if(istat .ne. 1)then
              write(6,*)' Bad status from latlon_to_rlapsgrid'
              istatus = 0
              return
          endif

          diff_gridi = ri - float(i)
          diff_gridj = rj - float(j)
          diff_grid = sqrt(diff_gridi**2 + diff_gridj**2)
          diff_grid_max = max(diff_grid,diff_grid_max)
          diff_grid_max_m = diff_grid_max * grid_spacing_m

      enddo
      enddo

      write(6,*)' check_domain: max_diff (gridpoints) = ',diff_grid_max
      write(6,*)' check_domain: max_diff (approx m)   = '
     1                                                 ,diff_grid_max_m      

      if(diff_grid_max_m .gt. tolerance_m)then
          write(6,*)' WARNING: exceeded tolerance in check_domain'
     1               ,tolerance_m
          istatus = 0
      endif

!...........................................................................

      diff_ll_max = 0.

      write(6,*)' Checking rlapsgrid_to_latlon'

      do i = 1,ni,intvl
      do j = 1,nj,intvl
          ri = i
          rj = j
          call rlapsgrid_to_latlon(ri,rj,lat,lon,ni,nj
     1                                  ,rlat,rlon,istat)

          if(istat .ne. 1)then
              write(6,*)' Bad status from rlapsgrid_to_latlon'
              istatus = 0
              return
          endif

          diff_lli =  rlat - lat(i,j)
          diff_llj = (rlon - lon(i,j)) * cosd(lat(i,j))
          diff_ll = sqrt(diff_lli**2 + diff_llj**2)
          diff_ll_max = max(diff_ll,diff_ll_max)
          diff_ll_max_m = diff_ll_max * 110000. ! meters per degree

      enddo
      enddo

      write(6,*)' check_domain: max_diff (degrees) = ',diff_ll_max
      write(6,*)' check_domain: max_diff (approx m)   = ',diff_ll_max_m

      if(diff_ll_max_m .gt. tolerance_m)then
          write(6,*)' WARNING: exceeded tolerance in check_domain'
     1               ,tolerance_m
          istatus = 0
      endif

!...........................................................................

      call check_grid_dimensions(ni,nj,istat_dim)

      istatus = istatus * istat_dim

!...........................................................................

      erad=6367000.
      icen = ni/2+1
      jcen = nj/2+1

      diff_lat =  lat(icen,jcen+1) - lat(icen,jcen-1)
      diff_lon = (lon(icen,jcen+1) - lon(icen,jcen-1)) 
     1                        * cosd(lat(icen,jcen))

      dist = sqrt((diff_lat)**2 + (diff_lon)**2) / 2. * rpd * erad   

      if(abs(lat(icen,jcen)) .lt. 89.)then ! should be reasonably accurate
          write(6,*)
     1    ' grid spacing on earths surface at domain center is:',dist       
      endif

!...........................................................................

      erad=6367000.

      call latlon_to_xy(lat(1,1),lon(1,1),erad,x1,y1)
      call latlon_to_xy(lat(2,1),lon(2,1),erad,x2,y2)

      dist = sqrt((x2-x1)**2 + (y2-y1)**2)

      write(6,*)
     1 ' grid spacing on projection plane using "latlon_to_xy" is:'      
     1 ,dist
      
!...........................................................................

      write(6,*)

      return
      end

      subroutine check_grid_dimensions(ni,nj,istatus)

      include 'lapsparms.inc'

      istatus = 1

      if(ni .gt. NX_L_MAX)then
          write(6,*)' ERROR: ni > NX_L_MAX', ni, NX_L_MAX
          istatus = 0
      endif

      if(nj .gt. NY_L_MAX)then
          write(6,*)' ERROR: nj > NY_L_MAX', nj, NY_L_MAX
          istatus = 0
      endif

      return
      end


      subroutine lambert_parms(slat1,slat2,n_out,s_out,rconst_out)

      real*4 n,n_out

!     We only have to do the calculations once since the inputs are constants
      data init/0/
      save init,n,s,rconst 

      if(init .eq. 0)then ! Calculate saved variables
          if(slat1 .ge. 0)then
              s = +1.
          else
              s = -1.
          endif

          colat1 = 90. - s * slat1
          colat2 = 90. - s * slat2

          if(slat1 .eq. slat2)then ! tangent lambert
              n = cosd(90.-s*slat1)
              rconst =  s *  tand(colat1)    / tand(colat1/2.)**n

          else                     ! two standard latitudes
              n = alog(cosd(slat1)/cosd(slat2))/
     1            alog(tand(45.-s*slat1/2.)/tand(45.-s*slat2/2.))
              rconst =      (sind(colat1)/n) / tand(colat1/2.)**n

          endif

          init = 1

      endif

      n_out = n
      s_out = s
      rconst_out = rconst

      return
      end
