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
      subroutine process_ir_satellite(i4time,
     &           ni,nj,lat,lon,
     &           n_ir_lines,n_ir_elem,
     &           r_grid_ratio,
     &           image_ir,
     &           r_llij_lut_ri,
     &           r_llij_lut_rj,
     &           c_type,
     &           ta8,tb8,tc8,
     &           istatus)
c
c**************************************************************************
c
c       Routine to collect satellite data for the LAPS analyses.
c
c       Changes:
c        P.A. Stamus       12-01-92       Original (from 'get_vas_bt' routine).
c                     01-11-93       Write output in LAPS standard format.
c                     02-01-93       Add snooze call for vis data.
c                     09-16-93       Add Bands 3,4,5,12 data.
c       J.R. Smart    03-01-94	     Implement on the Sun.  Adapt to ISPAN
c                             grids. This required removing all references to
c                             GOES mdals/ground station satellite receiving.
c          "          10-26-94       modified for goes-8 data. No need to compute
c                                    radiance and btemp as this conversion is included
c                                    in icnt_lut.
c          "          11-28-95       Extract IR processing from original sub (process_satellite)
c                                    to isolate the IR processing in one subroutine.
c          "           3-8-96        Removed icnt_lut.
c
c       Notes:
c       This program gets satellite data from ISPAN satellite database, does
c       some processing, then writes the data on the LAPS grids to the
c       LVD file.  LVD is written in standard LAPS NETCDF form.
c       The ISPAN data will only initially contain  band-8 (11.2)
c       and visible data.  More bands should be available when GOES-I becomes
c       operational.
c
c
c       Variables:
c       ta8              RA       O       Band 8 Brightness temps (averaged)
c       tb8              RA       O       Band 8 Brightness temps (warm pixel)
c       tc8              RA       O       Band 8 Brightness temps (filtered)
c
c
c       Note: For details on the filtering and averaging methods, see the
c       VASDAT2 routine or talk to S. Albers.
c
c****************************************************************************
c
       implicit none
c
       integer ni,nj
c
c..... Grids to put the satellite data on.
c
       real*4 ta8(ni,nj)
       real*4 tb8(ni,nj)
       real*4 tc8(ni,nj)
c 
c..... LAPS lat/lon files.
c
       real*4 lat(ni,nj)
       real*4 lon(ni,nj)
c
       integer n_ir_lines,n_ir_elem

       real*4 r_llij_lut_ri(ni,nj)
       real*4 r_llij_lut_rj(ni,nj)
       real*4 r_grid_ratio
       real*4 image_ir(n_ir_elem,n_ir_lines)
c
       integer istatus_a, istatus_f
       integer istatus_r
       integer istatus_w, istatus
       integer i,j,ik
       integer nn

       real*4 badlow,badhigh
       real*4 favgthr
       real*4 favgthr_39u
       real*4 favgthr_67u
       real*4 favgthr_11u
       real*4 favgthr_12u

       real*4 r_missing_data
       real*4 ave
       real*4 rmxbtemp,rmnbtemp
       real*4 btempsum

c these should be seasonally dependent. 6-13-99. 
c used for "bad" meteosat (11u) data. 
       data favgthr_39u /210.0/
       data favgthr_67u /209.0/
       data favgthr_11u /259.0/
       data favgthr_12u /257.0/
c
       integer i4time,imax,jmax

       character c_type*3
c
c using the original lvd output required 14 fields. We will stay with this
c so to keep the lvd output and reduce (eliminate) impact on other processes.
c
       istatus = -1

c      bad = 1.e6 - 2.
c
c these values are bases upon the GVAR cnt-to-btemp lookup tables.
c they are good estimates for satellites other than GOES.
c
c the favgthr (field avg threshold) doesn't work for all domains.
c
       if(c_type.eq.'wv '.or.c_type.eq.'iwv'.or.c_type.eq.'wvp')then
          badlow=148.486
          badhigh=291.182
          favgthr=favgthr_67u
       elseif(c_type.eq.'4u'.or.c_type.eq.'i39')then
          badlow=205.908
          badhigh=341.786
          favgthr=favgthr_39u
       elseif(c_type.eq.'11u'.or.c_type.eq.'i11')then
          badlow=112.105
          badhigh=341.25  !in line with goes08 cnt-to-btemp lut max value.
          favgthr=favgthr_11u
       else          !must be the 12u data
          badlow=110.611
          badhigh=336.347
          favgthr=favgthr_12u
       endif

       imax = ni
       jmax = nj

       call get_r_missing_data(r_missing_data,istatus)
       if(istatus.ne.1)then
          write(6,*)'error getting r_missing_data'
          goto 999
       endif

       do j = 1,jmax
       do i = 1,imax
          ta8(i,j) = r_missing_data
          tb8(i,j) = r_missing_data
          tc8(i,j) = r_missing_data
       enddo
       enddo
c
c.....  Call the satellite data processing subroutine for each Band required.
c
       write(6,900)c_type 
900    format('Proc Channel Type ',a3,' Satellite data.')
c --------------------------------------------------------------------------
       call satdat2laps_ir(imax,jmax,
     &                     r_grid_ratio,
     &                     r_missing_data,
     &                     image_ir,
     &                     r_llij_lut_ri,
     &                     r_llij_lut_rj,
     &                     n_ir_lines,n_ir_elem,
     &                     tb8,tc8,ta8,
     &                     istatus_r)

       if(istatus_r .ne. 1) then
          write(6,920)istatus_r, c_type
920       format(' +++ WARNING. Bad status',i3,' from
     &  SATDAT2LAPS_IR for band ',a2)
       endif
c
c----------------------------------------------------------------------------
c.....       Do a quick check on the data. 
c
       ik=0
       do j=1,jmax
       do i=1,imax
          if(ta8(i,j).le.badlow .or. 
     &       ta8(i,j).gt.badhigh)then
             ik=ik+1
             if(ik.le.25)print*,'ta8(',i,',',j,')= ',ta8(i,j)
             ta8(i,j) = r_missing_data
          endif
          if(tb8(i,j).le.badlow .or.
     &       tb8(i,j).gt.badhigh) tb8(i,j) = r_missing_data
          if(tc8(i,j).le.badlow .or.
     &       tc8(i,j).gt.badhigh) tc8(i,j) = r_missing_data
       enddo !i
       enddo !j
       call check(ta8,r_missing_data,istatus_a,imax,jmax)
       call check(tb8,r_missing_data,istatus_w,imax,jmax)
       call check(tc8,r_missing_data,istatus_f,imax,jmax)

       if(istatus_a .lt. 0)then
          write(6,910) istatus_a
       else
          write(6,*)'ta8 checked out ok'
       end if
       if(istatus_w .lt. 0)then
          write(6,911) istatus_w
       else
          write(6,*)'tb8 checked out ok'
       end if
       if(istatus_f .lt. 0)then
          write(6,912) istatus_f
       else
          write(6,*)'tc8 checked out ok'
       end if
910    format(' WARNING! ta8 check istatus_a = ',i8)
911    format(' WARNING! tb8 check istatus_w = ',i8)
912    format(' WARNING! tc8 check istatus_f = ',i8)

       print*
       print*,'Computing IR field ave: ',c_type

       rmxbtemp=0.0
       rmnbtemp=999.
       nn=0
       btempsum=0.0
       do j=1,jmax
       do i=1,imax
          if(ta8(i,j).ne.r_missing_data)then
             nn=nn+1
             btempsum=btempsum+ta8(i,j)
             rmxbtemp=max(ta8(i,j),rmxbtemp)
             rmnbtemp=min(ta8(i,j),rmnbtemp)
          endif
       enddo
       enddo
       if(nn.gt.0)then
          ave=btempsum/nn
          print*,'------------------------------------'
          print*,'Field max:  ',rmxbtemp,' (K)'
          print*,'Field min:  ',rmnbtemp,' (K)'
          print*,'Field ave:  ',ave, ' (K)'
c            print*,'Field sdev: ',sdev,' (K)'
c            print*,'Field adev: ',adev,' (K)'
          print*,'------------------------------------'
       else
          print*,'No Stats computed'
       endif
       print*

      if(ave.lt.favgthr)then
         print*,'field avg < threshold. no lvd output.'
         istatus = 0
      else
         istatus = 1
      endif
     
999   return
      end
