cdis    forecast systems laboratory
cdis    noaa/oar/erl/fsl
cdis    325 broadway
cdis    boulder, co     80303
cdis
cdis    forecast research division
cdis    local analysis and prediction branch
cdis    laps
cdis
cdis    this software and its documentation are in the public domain and
cdis    are furnished "as is."  the united states government, its
cdis    instrumentalities, officers, employees, and agents make no
cdis    warranty, express or implied, as to the usefulness of the software
cdis    and documentation for any purpose.  they assume no responsibility
cdis    (1) for the use of the software and documentation; or (2) to provide
cdis     technical support to users.
cdis
cdis    permission to use, copy, modify, and distribute this software is
cdis    hereby granted, provided that the entire disclaimer notice appears
cdis    in all copies.  all modifications to this software must be clearly
cdis    documented, and are solely the responsibility of the agent making
cdis    the modifications.  if significant modifications or enhancements
cdis    are made to this software, the fsl software policy manager
cdis    (softwaremgr@fsl.noaa.gov) should be notified.
cdis
cdis
cdis
cdis
cdis
cdis
cdis
        subroutine analq
     1   (i4time,plevel,ps,t,ph,td,data,cg,tpw,bias_one,
     1  kstart,qs,glat,glon,ii,jj,kk)

c       $log: analq.for,v $
c revision 1.3  1995/09/13  21:35:18  birk
c added disclaimer to files
c
c revision 1.2  1994/10/11  17:08:33  birk
c put in a loop-counter "safety valve" to prevent non-converging
c loops.  the type of which occurred operationally 10/11/94 dan b.
c
c revision 1.1  1994/04/25  15:16:15  birk
c initial revision
c

c       birkenheuer august 1992
c       this routine:

c       modifies the boundary layer
c       modifies the whole column based on the radiometer data
c       updated 21 september 1993

c       this routine was updated beginning november 4 1992 to consolidate
c       loops and choose one of the profilers for the bias adjustment.  it
c       is now felt that the radiometer data can be unreliable.
c
c       variables
c
c       plevel(kk)  the laps pressure levels
c       ps (ii,jj)  is the surface pressure field hpa
c       t (ii,jj)  surfact temp (c)
c       ph (ii,jj)  is the top of boundary layer pressure hpa
c       td (ii,jj)  is the surface dew point
c       data (ii,jj,kk) is the laps sh field (input and output here)
c       cg is the cloud grid.  if radiometer column is cloudy, no scaling is
c          performed
c
c       other variables
c
c       qs (ii,jj) surface q g/kg
c       qk  (ii,jj) the k index of the top of the b.l. at each point
c       tpw_point is the radiometer's total precipitable water
c       tpw is the field tpw
c       irad  is the i index of the radiometer position in the laps domain
c       jrad is the j index of the radiometer position in laps domain
c       i4time is the i4time for the call to get_radiometer data (get_rad)
c       pw is a get_rad input
c       plat is a get_rad output
c       plon is a get_rad output
c       npts is a getrad output indicating the nprofilepts in calling routine
c       istatus is normal status indicator
c       ix,jy are indexes of laps gridpoints nearest the radiometer.

c       preliminary computations

        implicit none

c input variables

      integer i4time,ii,jj,kk
      real plevel (kk)
      real ps (ii,jj)
      real t (ii,jj)
      real ph (ii,jj)
      real td (ii,jj)
      real data (ii,jj,kk)
      real cg (ii,jj,kk)
      real tpw (ii,jj)
      real bias_one
      integer kstart (ii,jj)
      real qs (ii,jj)
      real glat (ii,jj)
      real glon (ii,jj)

c internal variables requiring dynamic dimensions

      integer*4 qk(ii,jj)

c regular internal variables

        real tpw_point
        real bias, bias_correction ! bias one used for validation
        integer irad,jrad
        integer i,j,k
        real cgsum ! cloud grid sum for vertical cloud check
        real frac ! fraction used in linear interpolation BL moisture
        integer
     1  npts,  !npfilepts in calling routine
     1  istatus
        integer loop_counter

c internal variables with fixed dimensions


      real pw(4)
      real plat(4)
      real plon(4)
      integer ix(4),jy(4)

c       preliminary computations

        loop_counter = 0
        bias_one = -500.


c       compute top of b.l. q from data and ph
c       compute level of bl (qk)

        do j = 1,jj
        do i = 1,ii

c       check integrity
        if (ph(i,j) .le. 0.0) return  ! this cannot be 0.0

        k = kstart (i,j) ! k is "surface"
10      if (plevel(k) .gt. ph(i,j)) then !  haven't reached the bl top
        k = k+1
        if (k.gt.kk) then
                print *, 'error in analq, top of grid reached for ph com
     1p'
                return
        endif
        goto 10
        endif

        ph(i,j) = plevel(k) ! this is the top of bl in reg grid
        qk(i,j) = k

        enddo
        enddo

c ----------  mixing step

        do j = 1,jj
        do i = 1,ii

c check for clouds in the boundary layer...if there, do not modify the
c boundary at this time  2.2.93

        cgsum = 0.0
        do k = kstart(i,j),qk(i,j)
        cgsum = cgsum + cg(i,j,k)
        enddo

        if (cgsum .lt. 0.1) then  ! fill in the boundary layer

        do k = kstart(i,j),qk(i,j)
                if (kstart (i,j) .ge. qk(i,j) ) goto 11 ! skip loop

c new method is simple linear approximation in pressure space.
c this method is independent of grid spacing, the old method was
c not going to be consistent if vertical grid were to vary.  However, 
c the old method didn't overestimate Q so badily.  So to emulate that
c aspect, the new analysis will average the "backgraound" with the
c linear approximation at all levels.

             frac = (float(k) - float(qk(i,j)) )/
     1              (float(kstart(i,j) ) -  float(qk(i,j)) )

             frac = abs (frac)


             data(i,j,k) = data(i,j,kstart(i,j)) * frac +
     1             (1. - frac) * data(i,j,qk(i,j)) 
     1       + data(i,j,k)

             data (i,j,k) = data (i,j,k) /2.


c old method replaced 6/9/98 DB, new method is grid independent.
c                data(i,j,k) = (data(i,j,k) + data(i,j,k+1) )/2.
        enddo
        endif
11      continue  ! loop skipped  no boundary layer, no mixing

        enddo
        enddo


c ---------- end mixing step

c       note that qs  has units of g/kg



c       now obtain the radiometer tpw units of cm or gm/cm**2

        call get_rad(i4time,pw,plat,plon,npts,istatus)

        if (istatus.eq.1) then

        do i = 1,npts
        plon(i) = -plon(i)
        enddo

        call get_laps_gp (npts,plat,plon,ix,jy,glat,glon,ii,jj)


c       now determine the tpw at the selected gridpoints and decide on
c       tpw_point, irad and jrad

c       integrate the tpw field

        call int_tpw(data,kstart,qs,ps,plevel,tpw,ii,jj,kk)

c       determine the radiometer with the lowest bias correction and assume
c       that it is "true"

        do i = 1,npts

        if (i .eq. 1) then
                tpw_point = pw(i)
                irad = ix(i)
                jrad = jy(i)
                bias = tpw_point - tpw(irad,jrad)
        else

                if ( abs(pw(i) - tpw(ix(i),jy(i)) ) .lt. abs(bias) ) the
     1n

                tpw_point = pw(i)
                irad = ix(i)
                jrad = jy(i)
                bias = tpw_point - tpw(irad,jrad)

                endif

        endif

        enddo
c
c       now begins a loop to converge the bias correction and integrate the
c       moisture.  the surface
c       sh from td is not changed since we have faith in this value.
c       the values aloft are however changed interatively to agree with
c       an integral of tpw.  this loop also improves the tpw.
c       note: this loop does not mix water from the surface up or down


c       mod for version 6.0  2.2.93  db
c       check vertical column over radiometer and do not scale if cloudy

        cgsum = 0.
        k = 1
        do while (plevel(k).gt.600)  !integrate cloud in lower trop
        cgsum=cgsum+cg(irad,jrad,k)
        k = k+1
        enddo
        if(cgsum .gt. 0.6) then ! cloudy over radiometer
        print*, 'clouds analyzed over radiometer scaling step bypassed'
        bias = 0.005 ! bias is assigned this value for tracking
        endif

c       the value of bias will cause the code to branch at this point

        do while ( abs(bias) .gt. 0.01 )

c       integrate the tpw field

        call int_tpw(data,kstart,qs,ps,plevel,tpw,ii,jj,kk)


c       compute the bias at the radiometer site

        bias = tpw_point - tpw(irad,jrad)
c       record first iteration bias (bias_one) to monitor the process
        if (bias_one.eq.-500.) bias_one = bias
        bias_correction = tpw_point/tpw(irad,jrad)
        print*, bias_correction, 'factor', bias , 'bias'

c       apply the bias change at upper levels only

        do k = 1,kk
        do j = 1,jj
        do i = 1,ii
                if(data(i,j,k) .gt. 0.0 )
     1          data(i,j,k) = data(i,j,k) * bias_correction
        enddo
        enddo
        enddo

c       repeat the integration of tpw

c       increment loop-counter to prevent run-away situation experienced
c     1 0/11/94 db

        loop_counter = loop_counter+1
        if (loop_counter.gt.15) go to 123

        enddo !  (while)

123     continue  ! bailout for loop counter

c       at this point tpw has been integrated
c       at this point data array has been modified.

        else

c       the routine goes here if there are no radiometer data avail
c       integrate the tpw field one pass and beleive it to be good

        print*, 'no radiometer data avail...no bias correction to tpw'

        call int_tpw(data,kstart,qs,ps,plevel,tpw,ii,jj,kk)

        endif

        return
        end
