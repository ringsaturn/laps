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
c
c
	subroutine mdat_laps(i4time,atime,ni,nj,mxstn,laps_cycle_time,
     &    lat,lon,east,west,anorth,south,topo,x1a,x2a,y2a,
     &     lon_s, elev_s, t_s, td_s, dd_s, ff_s, pstn_s, pmsl_s, alt_s, 
     &     vis_s, stn, rii, rjj, ii, jj, n_obs_b, n_sao_g,
     &     u_bk, v_bk, t_bk, td_bk, rp_bk, mslp_bk, stnp_bk, vis_bk, 
     &     wt_u, wt_v, wt_rp, wt_mslp, ilaps_bk, 
     &     u1, v1, rp1, t1, td1, sp1, tb81, mslp1, vis1, elev1,
     &     back_t,back_td,back_uv,back_sp,back_rp,back_mp,back_vis,
     &     jstatus)
c
c*******************************************************************************
c
c	rewritten version of the mcginley mesodat program
c	-- rewritten again for the LAPS surface analysis...1-12-88
c
c	Changes:
c 	P.A. Stamus	06-27-88  Changed LAPS grid to new dimensions.
c			07-13-88  Restructured for new data formats
c				                  and MAPS first-guess.
c			07-26-88  Finished new stuff.
c			08-05-88  Rotate SAO winds to the projection.
c			08-23-88  Changes for laps library routines.
c			09-22-88  Make 1st guess optional.
c			10-11-88  Make filenames time dependent.
c-------------------------------------------------------------------------------
c			12-15-88  Rewritten.
c			01-09-89  Changed header, added meanpres calc.
c			03-29-89  Corrected for staggered grid. Removed
c					dependence on file for correct times.
c			04-12-89  Changed to do only 1 time per run.
c			05-12-89  Fixed i4time error.
c			06-01-89  New grid -- add nest6grid.
c			11-07-89  Add nummeso/sao to the output header.
c			--------------------------------------------------------
c			03-12-90  Subroutine version.
c			04-06-90  Pass in ihr,del,gam,ak for header.
c			04-11-90  Pass in LAPS lat/lon and topography.
c			04-16-90  Bag cloud stuff except ceiling.
c			04-17-90  Add MSL pressure.
c			06-18-90  New cloud check routine.
c			06-19-90  Add topo.
c			10-03-90  Changes for new vas data setup.
c			10-30-90  Put Barnes anl on boundaries.
c			02-15-91  Add solar radiation code.
c			05-01-91  Add Hartsough QC code.
c			11-01-91  Changes for new grids.
c			01-15-92  Add visibility analysis.
c			01-22-93  Changes for new LSO/LVD.
c			07-29-93  Changes for new barnes_wide routine.
c                       02-24-94  Remove ceiling ht stuff.
c                       04-14-94  Changes for CRAY port.
c                       07-20-94  Add include file.
c                       09-31-94  Change to LGA from LMA for bkgs.
c                       02-03-95  Move background calls to driver routine.
c                       02-24-95  Add code to check bkgs for bad winds.
c                       08-08-95  Changes for new verify code.
c                       03-22-96  Changes for 30 min cycle.
c                       10-09-96  Grid stn elevs for use in temp anl.
c                       11-18-96  Ck num obs.
c                       12-13-96  More porting changes...common for
c                                   sfc data, LGS grids. Bag stations.in
c                       08-27-97  Changes for dynamic LAPS.
c                       09-24-98  If missing background, do a smooth Barnes
c                                   so something is there.
c                       09-30-98  Housekeeping.
c
c	Notes:
c
c******************************************************************************
c
	include 'laps_sfc.inc'
c
c..... Stuff for the sfc data and other station info (LSO +)
c
	real*4 lon_s(mxstn), elev_s(mxstn)
	real*4 t_s(mxstn), td_s(mxstn), dd_s(mxstn), ff_s(mxstn)
	real*4 pstn_s(mxstn), pmsl_s(mxstn), alt_s(mxstn)
	real*4 vis_s(mxstn)
	real*4 rii(mxstn), rjj(mxstn)
c
	integer*4 ii(mxstn), jj(mxstn)
c
	character stn(mxstn)*3 
c
c.....	Arrays for derived variables from OBS data
c
	real*4 uu(mxstn), vv(mxstn), pred_s(mxstn)
c
c.....	Stuff for satellite data.
c
	integer*4 lvl_v(1)
	character var_v(1)*3, units_v(1)*10
	character comment_v(1)*125, ext_v*31
c
c.....  Stuff for intermediate grids (old LGS file)
c
	real*4 u1(ni,nj), v1(ni,nj)
	real*4 t1(ni,nj), td1(ni,nj), tb81(ni,nj)
	real*4 rp1(ni,nj), sp1(ni,nj), mslp1(ni,nj)
	real*4 vis1(ni,nj), elev1(ni,nj)
c
c..... Other arrays for intermediate grids 
c
        real*4 wwu(ni,nj), wwv(ni,nj)
	real*4 wp(ni,nj), wsp(ni,nj), wmslp(ni,nj)
	real*4 wt(ni,nj), wtd(ni,nj), welev(ni,nj), wvis(ni,nj)
c
        real*4 fnorm(0:ni-1,0:nj-1)
	real*4 x1a(ni), x2a(nj), y2a(ni,nj)    !interp routine
	real*4 d1(ni,nj)   ! work array
c
c..... LAPS Lat/lon grids.
c
	real*4 lat(ni,nj),lon(ni,nj), topo(ni,nj)
c
	real*4 lapse_t, lapse_td
	character atime*24
c
c.....	Grids for the background fields...use if not enough sao data.
c
        real*4 u_bk(ni,nj), v_bk(ni,nj), t_bk(ni,nj), td_bk(ni,nj)
        real*4 wt_u(ni,nj), wt_v(ni,nj)
        real*4 rp_bk(ni,nj), mslp_bk(ni,nj), stnp_bk(ni,nj)
        real*4 wt_rp(ni,nj), wt_mslp(ni,nj) 
        real*4 vis_bk(ni,nj) 
        integer back_t, back_td, back_rp, back_uv, back_vis, back_sp
        integer back_mp
c
c.....  Stuff for checking the background fields.
c
	real*4 interp_spd(mxstn), bk_speed(ni,nj)
	parameter(threshold = 2.)  ! factor for diff check
	parameter(spdt      = 20.) ! spd min for diff check
	character stn_mx*3, stn_mn*3, amax_stn_id*3
c       
	integer*4 jstatus(20)
c
c.....	START.  Set up constants.
c
	jstatus(1) = -1		! put something in the status
	jstatus(2) = -1
	ibt = 0
	imax = ni
	jmax = nj
	icnt = 0
	delt = 0.035
c
c.....  Zero out the sparse obs arrays.
c
	call zero(u1,    imax,jmax)
	call zero(v1,    imax,jmax)
	call zero(t1,    imax,jmax)
	call zero(td1,   imax,jmax)
	call zero(rp1,   imax,jmax)
	call zero(sp1,   imax,jmax)
	call zero(mslp1, imax,jmax)
	call zero(vis1,  imax,jmax)
	call zero(elev1, imax,jmax)
	do i=1,mxstn
	   uu(i) = 0.
	   vv(i) = 0.
	enddo !i
c
c.....  Stuff for checking the background windspeed.
c
	if(ilaps_bk.ne.1 .or. back_uv.ne.1) then
	   call constant(bk_speed,badflag, imax,jmax)
	else
	   call windspeed(u_bk,v_bk,bk_speed, imax,jmax)
	endif
c
c.....	Rotate sao winds to the projection grid, then change dd,fff to u,v
c
	do i=1,n_obs_b
	   if(dd_s(i).eq.badflag .or. ff_s(i).eq.badflag) then
	      uu(i) = badflag
	      vv(i) = badflag
	   else
	      dd_rot = dd_s(i) - projrot_laps( lon_s(i) )
	      dd_rot = mod( (dd_rot + 360.), 360.)
	      call decompwind_gm(dd_rot,ff_s(i),uu(i),vv(i),istatus)     
	      if(uu(i).lt.-150. .or. uu(i).gt.150.) uu(i) = badflag
	      if(vv(i).lt.-150. .or. vv(i).gt.150.) vv(i) = badflag
	   endif
	enddo !i
c
c.....  Before continuing, use the SAO data to check the backgrounds.
c.....  Find the background at each station location, then compare
c.....  to the current observation.  If the difference is larger than the
c.....  threshold, zero out the background weights for that variable.
c
c
c.....  First find the max in the background wind speed field.
c
	print *,' '
	print *,' Checking background...'
	print *,' '
	if(ilaps_bk.ne.1 .or. back_uv.ne.1) then
	   print *,' NO BACKGROUND WIND FIELDS AVAILIBLE...SKIPPING...'
	   go to 415
	endif
c
	do j=1,jmax
	do i=1,imax
	   if(bk_speed(i,j) .gt. bksp_mx) then
	      bksp_mx = bk_speed(i,j)
	      ibksp = i
	      jbksp = j
	   endif
	enddo !i
	enddo !j
c
c.....  Find the 2nd derivative table for use by the splines later.
c
	call splie2(x1a,x2a,bk_speed,imax,jmax,y2a)
c
c.....  Now call the spline routine for each station in the grid.
c
	ithresh = 0
	ibkthresh = 0
	diff_mx = -1.e30
	diff_mn = 1.e30
	amax_stn = -1.e30
	do i=1,n_obs_b
	   if(ii(i).lt.1 .or. ii(i).gt.imax) go to 330
	   if(jj(i).lt.1 .or. jj(i).gt.jmax) go to 330
	   aii = float(ii(i))
	   ajj = float(jj(i))
	   call splin2(x1a,x2a,bk_speed,y2a,imax,jmax,aii,ajj,
     &                 interp_spd(i))
	   if(ff_s(i) .le. badflag) then
	      diff = badflag
	   else
	      diff = interp_spd(i) - ff_s(i)
	      if(ff_s(i) .lt. 1.) then
		 percent = -1.
	      else
	         percent = ( abs(diff) / ff_s(i) ) * 100.
	      endif
	   endif
	   write(6,400) 
     &         i,stn(i),ii(i),jj(i),interp_spd(i),ff_s(i),diff,percent
	   if(diff .eq. badflag) go to 330
	   diff = abs( diff )         ! only really care about magnitude
	   if(diff .gt. diff_mx) then
	      diff_mx = diff
	      stn_mx = stn(i)
	   endif
	   if(diff .lt. diff_mn) then
	      diff_mn = diff
	      stn_mn = stn(i)
	   endif
	   if(diff.gt.(threshold * ff_s(i)).and.ff_s(i).gt.spdt) then
	      ithresh = ithresh+1
	   endif
	   if(ff_s(i) .gt. amax_stn) then
	      amax_stn = ff_s(i)
	      amax_stn_id = stn(i)
	   endif
 330	enddo !i
 400	format(1x,i3,':',1x,a3,' at i,j ',2i3,':',3f12.2,f12.0)
	write(6,405) diff_mx, stn_mx
 405	format(1x,' Max difference of ',f12.2,'  at ',a3)
	write(6,406) diff_mn, stn_mn
 406	format(1x,' Min difference of ',f12.2,'  at ',a3)
	write(6,410) ithresh, threshold, spdt
 410	format(1x,' There were ',i4,
     &            ' locations exceeding threshold of ',f6.3,
     &            ' at speeds greater than ',f6.1,' kts.')
c
c.....  If too many stations exceed threshold, or if the max in the 
c.....  background is too much larger than the max in the obs, backgrounds 
c.....  probably bad.  Zero out the wt arrays so they won't be used.
c
	print *,' '
	write(6,420) bksp_mx, ibksp, jbksp
 420	format(1x,' Background field max: ',f12.2,' at ',i3,',',i3)
	write(6,421) amax_stn, amax_stn_id
 421	format(1x,' Max speed at station: ',f12.2,' at ',a3)
c
	if(bksp_mx .ge. 60.) then
	   if(bksp_mx .gt. amax_stn*2.66) ibkthresh = 1
	endif
c
	if(ithresh.gt.2 .or. ibkthresh.gt.0) then
	   write(6,412)
 412	   format(1x,
     &      '  Possible bad wind/pressure backgrounds...skipping.')
	   call zero(wt_u, imax,jmax)
	   call zero(wt_v, imax,jmax)
	   call zero(wt_rp, imax,jmax)
	   call zero(wt_mslp, imax,jmax)
	endif
	print *,' '
c
c
c.....  Now, back to the analysis.
c.....	Convert altimeters to station pressure.
c
 415	do j=1,n_obs_b
	  if(alt_s(j) .le. badflag) then
	    pstn_s(j) = badflag
	  else
	    pstn_s(j) = alt_2_sfc_press(alt_s(j), elev_s(j)) !conv alt to sp
	  endif
	enddo !j
c
c.....	Now reduce station pressures to standard levels...1500 m (for CO) 
c.....  and MSL.  Use background 700 mb and 850 mb data from LGA (or equiv).
c
cc	call mean_lapse(n_obs_b,elev_s,t_s,td_s,a_t,lapse_t,a_td,
cc     &                    lapse_td,hbar,badflag)
c
c.....  Set standard lapse rates in deg F.
c
        lapse_t = -.01167
        lapse_td = -.007
c
	sum_diffp = 0.
	num_diffp = 0
	print *,' '
	print *,' Calculating reduced pressures'
	print *,'----------------------------------'
	do k=1,n_obs_b
	  if(pstn_s(k).le.badflag .or. t_s(k).le.badflag 
     &                           .or. td_s(k).le.badflag) then
	    pred_s(k) = badflag
	    pmsl_s(k) = badflag
	  else
	    call reduce_p(t_s(k),td_s(k),pstn_s(k),elev_s(k),lapse_t,
     &                       lapse_td,pred_s(k),redp_lvl,badflag)  ! 1500 m for CO
	    call reduce_p(t_s(k),td_s(k),pstn_s(k),elev_s(k),lapse_t,
     &                       lapse_td,p_msl,0.,badflag)        ! MSL
	    if(pmsl_s(k).gt.900. .and. pmsl_s(k).lt.1100.) then
              if(p_msl .ne. badflag) then
		 diff_ps = p_msl - pmsl_s(k)
		 write(6,983) k, stn(k), p_msl, pmsl_s(k), diff_ps
		 sum_diffp = sum_diffp + diff_ps
		 num_diffp = num_diffp + 1
	      endif
	    else
	       pmsl_s(k) = p_msl
	    endif
	  endif
        enddo !k
	print *,' '
	if(num_diffp .le. 0) then
	   print *,' Bad num_diffp'
	else
	   bias = sum_diffp / float(num_diffp)
	   print *,'Num: ', num_diffp,'   MSL Pressure Bias = ', bias
	endif
 983    format(1x,i5,2x,a6,':',3f12.2)
	print *,' '
c
c.....	Convert visibility to log( vis ) for the analysis.
c
	call viss2log(vis_s,mxstn,n_obs_b,badflag)
c
c.....	READ IN THE BAND 8 BRIGHTNESS TEMPS (deg K)
c
	ext_v = 'lvd'
	lvl_v(1) = 0
	var_v(1) = 'S8W'	! satellite...band 8, warm pixel (K)
c
	call get_laps_2dvar(i4time,970,i4time_nearest,ext_v,var_v,
     &        units_v,comment_v,imax,jmax,tb81,lvl_v,istatus)
c
	if(istatus .ne. 1) then
	   write(6,962) atime
 962	   format(1x,' +++ Satellite data not available for the ',a24,
     &           ' analysis. +++')
	   call zero(tb81, imax,jmax)
	   go to 800
	endif
	ibt = 1
c
c.....  READ IN any other data here
c
 800	continue
c
c.....	Put the data on the grids.
c
c.....	Winds:
c
	call put_winds(uu,vv,mxstn,n_obs_b,u1,v1,wwu,wwv,icnt,
     &                 imax,jmax,rii,rjj,ii,jj,badflag)
	icnt_t = icnt
c
c.....	Temperatures:
c
	call put_thermo(t_s,mxstn,n_obs_b,t1,wt,icnt,
     &                  imax,jmax,ii,jj,badflag)
c
c.....	Dew points: 
c
	call put_thermo(td_s,mxstn,n_obs_b,td1,wtd,icnt,
     &                  imax,jmax,ii,jj,badflag)
c
c.....	Put the reduced pressure on the grid
c
	call put_thermo(pred_s,mxstn,n_obs_b,rp1,wp,icnt,
     &                  imax,jmax,ii,jj,badflag)
c
c.....	Put the station pressure on the grid
c
	call put_thermo(pstn_s,mxstn,n_obs_b,sp1,wsp,icnt,
     &                  imax,jmax,ii,jj,badflag)
c
c.....	Put the MSL pressure on the grid
c
	call put_thermo(pmsl_s,mxstn,n_obs_b,mslp1,wmslp,icnt,
     &                  imax,jmax,ii,jj,badflag)
c
c.....	Visibility:
c
	call put_thermo(vis_s,mxstn,n_obs_b,vis1,wvis,icnt,
     &                  imax,jmax,ii,jj,badflag)
c
c.....	Station elevation:
c
	call put_thermo(elev_s,mxstn,n_obs_b,elev1,welev,icnt,
     &                  imax,jmax,ii,jj,badflag)
c
c.....	Now find the values at the gridpts.
c
        write(6,1010) icnt_t
1010	FORMAT(1X,'DATA SET 1 INITIALIZED WITH ',I6,' OBSERVATIONS')
        call procar(u1,imax,jmax,wwu,imax,jmax,-1)
        call procar(v1,imax,jmax,wwv,imax,jmax,-1)
        call procar(t1,imax,jmax,wt,imax,jmax,-1)
        call procar(td1,imax,jmax,wtd,imax,jmax,-1)
        call procar(rp1,imax,jmax,wp,imax,jmax,-1)
        call procar(sp1,imax,jmax,wsp,imax,jmax,-1)
        call procar(mslp1,imax,jmax,wmslp,imax,jmax,-1)
        call procar(vis1,imax,jmax,wvis,imax,jmax,-1)
        call procar(elev1,imax,jmax,welev,imax,jmax,-1)
c
c.....  Now that the data is ready, check the backgrounds.  If they
c.....  are missing, fill the background field for the variable
c.....  with a smooth Barnes analysis of the obs.  This will allow
c.....  us to cold start the analysis, or run the analysis in a 
c.....  stand-alone mode.
c
	n_obs_var = 0
        fill_val = 1.e37
        smsng = 1.e37
	npass = 1
	if(back_t .ne. 1) then
	   print *,' '
	   print *,
     & ' **WARNING. No T background. Using smooth Barnes anl of obs'
	   rom2 = 0.005
	   call dynamic_wts(imax,jmax,n_obs_var,rom2,d,fnorm)
	   call barnes2(t_bk,imax,jmax,t1,smsng,mxstn,npass,fnorm)
	   call check_field_2d(t_bk,imax,jmax,fill_val,istatus)
	endif
c
	if(back_td .ne. 1) then
	   print *,' '
	   print *,
     & ' **WARNING. No Td background. Using smooth Barnes anl of obs'
	   rom2 = 0.005
	   call dynamic_wts(imax,jmax,n_obs_var,rom2,d,fnorm)
	   call barnes2(td_bk,imax,jmax,td1,smsng,mxstn,npass,fnorm)
	   call check_field_2d(td_bk,imax,jmax,fill_val,istatus)
	endif
c
	if(back_uv .ne. 1) then
	   print *,' '
	   print *,
     & ' **WARNING. No wind background. Using smooth Barnes anl of obs'
	   rom2 = 0.005
	   call dynamic_wts(imax,jmax,n_obs_var,rom2,d,fnorm)
	   call barnes2(u_bk,imax,jmax,u1,smsng,mxstn,npass,fnorm)
	   call check_field_2d(u_bk,imax,jmax,fill_val,istatus)
	   call dynamic_wts(imax,jmax,n_obs_var,rom2,d,fnorm)
	   call barnes2(v_bk,imax,jmax,v1,smsng,mxstn,npass,fnorm)
	   call check_field_2d(v_bk,imax,jmax,fill_val,istatus)
	endif
c
	if(back_sp .ne. 1) then
	   print *,' '
	   print *,
     & ' **WARNING. No sfc P background. Using smooth Barnes anl of obs'
	   rom2 = 0.005
	   call dynamic_wts(imax,jmax,n_obs_var,rom2,d,fnorm)
	   call barnes2(stnp_bk,imax,jmax,sp1,smsng,mxstn,npass,fnorm)
	   call check_field_2d(stnp_bk,imax,jmax,fill_val,istatus)
	endif
c
	if(back_rp .ne. 1) then
	   print *,' '
	   print *, ' **WARNING. No reduced P background.',
     &              ' Using smooth Barnes anl of obs'
	   rom2 = 0.005
	   call dynamic_wts(imax,jmax,n_obs_var,rom2,d,fnorm)
	   call barnes2(rp_bk,imax,jmax,rp1,smsng,mxstn,npass,fnorm)
	   call check_field_2d(rp_bk,imax,jmax,fill_val,istatus)
	endif
c
	if(back_mp .ne. 1) then
	   print *,' '
	   print *,
     & ' **WARNING. No MSL P background. Using smooth Barnes anl of obs'
	   rom2 = 0.005
	   call dynamic_wts(imax,jmax,n_obs_var,rom2,d,fnorm)
	   call barnes2(mslp_bk,imax,jmax,mslp1,smsng,mxstn,npass,fnorm)
	   call check_field_2d(mslp_bk,imax,jmax,fill_val,istatus)
	endif
c
	if(back_vis .ne. 1) then
	   print *,' '
	   print *,
     & ' **WARNING. No Vis background. Using smooth Barnes anl of obs'
	   rom2 = 0.005
	   call dynamic_wts(imax,jmax,n_obs_var,rom2,d,fnorm)
	   call barnes2(vis_bk,imax,jmax,vis1,smsng,mxstn,npass,fnorm)
	   call check_field_2d(vis_bk,imax,jmax,fill_val,istatus)
	endif
c
c.....	Fill in the boundary of each field with values from the
c.....  background.
c
	  call back_bounds(u1,imax,jmax,u_bk,badflag)
	  call back_bounds(v1,imax,jmax,v_bk,badflag)
	  call back_bounds(t1,imax,jmax,t_bk,badflag)
	  call back_bounds(td1,imax,jmax,td_bk,badflag)
	  call back_bounds(rp1,imax,jmax,rp_bk,badflag)
	  call back_bounds(sp1,imax,jmax,stnp_bk,badflag)
	  call back_bounds(mslp1,imax,jmax,mslp_bk,badflag)
	  call back_bounds(vis1,imax,jmax,vis_bk,badflag)
	  call back_bounds(elev1,imax,jmax,topo,badflag)
c
c.....	Check the brightness temperatures for clouds.
c
	if(ilaps_bk.eq.0 .or. back_t.eq.0) then
	   print *,' ++ No previous temperature est for cloud routine ++'
	   go to 720
	endif
	call zero(d1,imax,jmax)
	call conv_f2k(t_bk,d1,imax,jmax)
	call clouds(imax,jmax,topo,d1,badflag,tb81,i4time,
     &              laps_cycle_time,lat,lon,1.e37)
c
c.....  Convert tb8 from K to F...watch for 0.0's where clds removed.
c
720	continue
	do j=1,jmax
	do i=1,imax
	   if(tb81(i,j) .gt. 400.) tb81(i,j) = 0.
	   if(tb81(i,j) .ne. 0.) then
	      tb81(i,j) = (1.8 * (tb81(i,j) - 273.15)) + 32.
	   endif
	enddo !i
	enddo !j
c
c..... That's it here....
c
	jstatus(1) = 1		! everything's ok...
	print *,' Normal completion of MDATLAPS'
c
	return
	end
c
c
	subroutine put_winds(u_in,v_in,max_stn,num_sta,u,v,wwu,wwv,icnt,
     &                       ni,nj,rii,rjj,ii,jj,badflag)
c
c*******************************************************************************
c
c	Routine to put the u and v wind components on the LAPS grid...properly
c       located on the staggered u- and v- grids.
c
c	Changes:
c		P.A. Stamus	12-01-88  Original (cut from old mdatlaps)
c				03-29-89  Fix for staggered grid.
c                               02-24-94  Change method to use rii,rjj locatns.
c                               08-27-97  Pass in bad flag value.
c
c	Inputs/Outputs:
c	   Variable     Var Type   I/O   Description
c	  ----------   ---------- ----- -------------
c	   u_in            RA       I    Array of u wind components at stations
c	   v_in            RA       I      "      v  "       "       "     "
c	   max_stn         I        I    Max number of stations (for dimension)
c	   num_sta         I        I    Number of stations in input file
c	   u, v            RA       O    U and V component grids.
c	   wwu             RA       O    Weight grid for U.
c	   wwv             RA       O    Weight grid for V.
c	   icnt            I        O    Number of stations put on grid.
c          rii, rjj        RA       I    i,j locations of stations (real)
c          ii, jj          IA       I    i,j locations of stations (integer)
c          badflag         R        I    Bad flag value.
c
c	User Notes:
c
c*******************************************************************************
c
	real*4 u_in(max_stn), v_in(max_stn), u(ni,nj), v(ni,nj)
	real*4 wwu(ni,nj), wwv(ni,nj)
        real*4 rii(max_stn), rjj(max_stn)
        integer*4 ii(max_stn), jj(max_stn)
c
	zeros = 1.e-30
	call zero(wwu, ni,nj)
	call zero(wwv, ni,nj)
c
	do 10 ista=1,num_sta
c
c.....	Find ixx, iyy to put data at proper location at the grid square
c
	  ixxu = ii(ista)
	  iyyu = rjj(ista) + 0.5   ! grid offset for u-grid from major grid
	  ixxv = rii(ista) + 0.5   ! grid offset for v-grid from major grid
	  iyyv = jj(ista)
	  icnt = icnt + 1
c
c.....	Put wind components on the u and v grids
c
	  if(u_in(ista).eq.badflag .or. v_in(ista).eq.badflag) go to 10
	  if(u_in(ista) .eq. 0.) u_in(ista) = zeros
	  if(v_in(ista) .eq. 0.) v_in(ista) = zeros
	  if(ixxu.lt.1 .or. ixxu.gt.ni) go to 15
	  if(iyyu.lt.1 .or. iyyu.gt.nj) go to 15
	  u(ixxu,iyyu) = u_in(ista) + u(ixxu,iyyu)
	  wwu(ixxu,iyyu) = wwu(ixxu,iyyu) + 1.
15	  if(ixxv.lt.1 .or. ixxv.gt.ni) go to 10
	  if(iyyv.lt.1 .or. iyyv.gt.nj) go to 10
	  v(ixxv,iyyv) = v_in(ista) + v(ixxv,iyyv)
	  wwv(ixxv,iyyv) = wwv(ixxv,iyyv) + 1.
10	continue
c
	return
	end
c
c
	subroutine put_thermo(var_in,max_stn,num_sta,x,w,icnt,
     &                        ni,nj,ii,jj,badflag)
c
c*******************************************************************************
c
c	Routine to put non-wind variables on the 'major' LAPS grid.
c
c	Changes:
c		P.A. Stamus	12-01-88  Original (cut from old mdatlaps)
c				03-29-89  Fix for staggered grid.
c				04-19-89  Added ii,jj for qc routine.
c				10-30-90  ii,jj now from 'FIND_IJ'.
c                               02-24-94  New ii,jj arrays.
c                               08-27-97  Pass in bad flag value.
c
c	Inputs/Outputs:
c	   Variable     Var Type   I/O   Description
c	  ----------   ---------- ----- -------------
c	   var_in          RA       I    Array of the station ob. 
c	   max_stn         I        I    Max number of stations (for dimension)
c	   num_sta         I        I    Number of stations in input file
c	   x               RA       O    Grid for the variable. 
c	   w               RA       O    Weight grid.
c	   icnt            I        O    Number of stations put on grid.
c          ii, jj          IA       I    i,j locations of the stations (integer)
c          badflag         R        I    Bad flag value.
c
c	User Notes:
c
c*******************************************************************************
c
	real*4 var_in(max_stn), x(ni,nj), w(ni,nj)
        integer*4 ii(max_stn), jj(max_stn)
c
	zeros = 1.e-30
        call zero(w,ni,nj)
c
	do 10 ista=1,num_sta
c
	  ixx = ii(ista)
	  iyy = jj(ista)
	  icnt = icnt + 1
c
c.....	Put variable on the LAPS grid
c
          if(ixx.lt.1 .or. ixx.gt.ni) go to 10
          if(iyy.lt.1 .or. iyy.gt.nj) go to 10
	  if(var_in(ista) .eq. badflag) go to 10
	  if(var_in(ista) .eq. 0.) var_in(ista) = zeros
	  x(ixx,iyy) = var_in(ista) + x(ixx,iyy)
	  w(ixx,iyy) = w(ixx,iyy) + 1.
10	continue
c
	return
	end
c
c
        Subroutine procar(a,imax,jmax,b,imax1,jmax1,iproc)
        real*4 a(imax,jmax),b(imax1,jmax1)
        do 2 j=1,jmax
        jj=j
        if(jmax.gt.jmax1) jj=jmax1
        do 2 i=1,imax
        ii=i
        if(imax.gt.imax1) ii=imax1
        if(b(ii,jj)) 3,4,3
    3   a(i,j)=a(i,j)*b(ii,jj)**iproc 
        GO TO 2
!    4   A(I,J)=0.
4	continue
    2   CONTINUE    
        return  
        end
c
c
	subroutine fill_bounds(x,imax,jmax,ii,jj,x_ob,
     &                           n_obs_b,badflag,mxstn)
c
c======================================================================
c
c       Routine to fill the boundary of an array with values from a
c       wide-area Barnes analysis.
c
c       Orginal:  P. Stamus  NOAA/FSL  c.1990
c       Changes:  P. Stamus  27 Aug 1997  Changes for dynamic LAPS
c
c======================================================================
c
	real*4 x(imax,jmax), x_ob(mxstn)
	real*4 fnorm(0:imax-1,0:jmax-1)
	real*4 dum(imax,jmax)  !work array
c
	integer ii(mxstn), jj(mxstn)
c
	npass = 1
	call zero(dum,imax,jmax)
c
c.....	Call the wide-area Barnes.
c
	rom2 = 0.01
	call dynamic_wts(imax,jmax,0,rom2,d,fnorm)
	call barnes_wide(dum,imax,jmax,ii,jj,x_ob,n_obs_b,badflag,
     &                   mxstn,npass,fnorm) 
c
c.....	Copy the boundaries from the dummy array to the main array--if--
c.....	there isn't a station there already.
c
	do i=1,imax
	 if(x(i,1).eq.0. .or. x(i,1).eq.badflag) x(i,1) = dum(i,1)
	 if(x(i,jmax).eq.0..or.x(i,jmax).eq.badflag) 
     &                                     x(i,jmax) = dum(i,jmax)
	enddo !i
	do j=1,jmax
	 if(x(1,j).eq.0. .or. x(1,j).eq.badflag) x(1,j) = dum(1,j)
	 if(x(imax,j).eq.0..or.x(imax,j).eq.badflag) 
     &                                     x(imax,j) = dum(imax,j)
	enddo !j
c
c
        do i=1,imax
           do j=1,2
              x(i,j)=dum(i,j)
           enddo
           do j=jmax-1,jmax
              x(i,j)=dum(i,j)
           enddo
        enddo

        do j=1,jmax
           do i=1,2
              x(i,j)=dum(i,j)
           enddo
           do i=imax-1,imax
              x(i,j)=dum(i,j)
           enddo
        enddo
	return
	end
c
c
	subroutine back_bounds(x,imax,jmax,dum,badflag)
c
c======================================================================
c
c       Routine to fill the boundary of an array with values from an
c       earlier analysis...for when we have limited data.
c
c       Orginal: P. Stamus  NOAA/FSL  c.1990
c       Changes: P. Stamus  27 Aug 1997  Pass in bad flag value.
c                J. Smart   15 Jul 1998  background put on the boundary
c                                        + 2 grid points in.
c                                  (McGinley and Stamus approved this mod)
c
c======================================================================
c
	real*4 x(imax,jmax), dum(imax,jmax)
c
c.....	Copy the boundaries from the dummy array to the main array--if--
c.....	there isn't a station there already.
c
	do i=1,imax
	 if(x(i,1).eq.0. .or. x(i,1).eq.badflag) x(i,1) = dum(i,1)
	 if(x(i,jmax).eq.0..or.x(i,jmax).eq.badflag) 
     &                                     x(i,jmax) = dum(i,jmax)
	enddo !i
	do j=1,jmax
	 if(x(1,j).eq.0. .or. x(1,j).eq.badflag) x(1,j) = dum(1,j)
	 if(x(imax,j).eq.0..or.x(imax,j).eq.badflag) 
     &                                     x(imax,j) = dum(imax,j)
	enddo !j
c
        do i=1,imax
           do j=1,2
              x(i,j)=dum(i,j)
           enddo
           do j=jmax-1,jmax
              x(i,j)=dum(i,j)
           enddo
        enddo

        do j=1,jmax
           do i=1,2
              x(i,j)=dum(i,j)
           enddo
           do i=imax-1,imax
              x(i,j)=dum(i,j)
           enddo
        enddo

	return
	end
c
c
      subroutine splie2(x1a,x2a,ya,m,n,y2a)

c	15 May 1991  birkenheuer

      dimension x1a(m),x2a(n),ya(m,n),y2a(m,n),ytmp(n*50),y2tmp(n*50)
      do 13 j=1,m
        do 11 k=1,n
          ytmp(k)=ya(j,k)
11      continue
        call spline_db(x2a,ytmp,n,1.e30,1.e30,y2tmp)
        do 12 k=1,n
          y2a(j,k)=y2tmp(k)
12      continue
13    continue
      return
      end
c
c
      subroutine splin2(x1a,x2a,ya,y2a,m,n,x1,x2,y)

c	15 May 1991 birkenheuer

       dimension x1a(m),x2a(n),ya(m,n),y2a(m,n),ytmp(n*50),
     &          y2tmp(n*50),yytmp(n*50)
       do 12 j=1,m
        do 11 k=1,n
          ytmp(k)=ya(j,k)
          y2tmp(k)=y2a(j,k)
11      continue
        call splint(x2a,ytmp,y2tmp,n,x2,yytmp(j))
12     continue
       call spline_db(x1a,yytmp,m,1.e30,1.e30,y2tmp)
       call splint(x1a,yytmp,y2tmp,m,x1,y)
       return
       end
c
c
      subroutine spline_db(x,y,n,yp1,ypn,y2)

c	15 may 1991  birkenheuer

      dimension x(n),y(n*50),y2(n*50),u(n*50)
      if (yp1.gt..99e30) then
        y2(1)=0.
        u(1)=0.
      else
        y2(1)=-0.5
        u(1)=(3./(x(2)-x(1)))*((y(2)-y(1))/(x(2)-x(1))-yp1)
      endif
      do 11 i=2,n-1
        sig=(x(i)-x(i-1))/(x(i+1)-x(i-1))
        p=sig*y2(i-1)+2.
        y2(i)=(sig-1.)/p
        u(i)=(6.*((y(i+1)-y(i))/(x(i+1)-x(i))-(y(i)-y(i-1))
     1      /(x(i)-x(i-1)))/(x(i+1)-x(i-1))-sig*u(i-1))/p
11    continue
      if (ypn.gt..99e30) then   ! test for overflow condition
        qn=0.
        un=0.
      else
        qn=0.5
        un=(3./(x(n)-x(n-1)))*(ypn-(y(n)-y(n-1))/(x(n)-x(n-1)))
      endif
      y2(n)=(un-qn*u(n-1))/(qn*y2(n-1)+1.)
      do 12 k=n-1,1,-1
        y2(k)=y2(k)*y2(k+1)+u(k)
12    continue
      return
      end
c
c
      subroutine splint(xa,ya,y2a,n,x,y)


c	15 May 1991 Birkenheuer

      dimension xa(n),ya(n*50),y2a(n*50)
      klo=1
      khi=n
1     if (khi-klo.gt.1) then
        k=(khi+klo)/2
        if(xa(k).gt.x)then
          khi=k
        else
          klo=k
        endif
      goto 1
      endif
      h=xa(khi)-xa(klo)
      if (h.eq.0.) pause 'bad xa input.'
      a=(xa(khi)-x)/h
      b=(x-xa(klo))/h
      y=a*ya(klo)+b*ya(khi)+
     1      ((a**3-a)*y2a(klo)+(b**3-b)*y2a(khi))*(h**2)/6.
      return
      end
