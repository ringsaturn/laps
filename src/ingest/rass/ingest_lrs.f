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

!       1997 Jul      Ken Dritz        Added call to get_grid_dim_xy.
!       1997 Jul      Ken Dritz        Pass NX_L, NY_L to ingest_lrs.

        character*9 a9_time

        call get_systime(i4time,a9_time,istatus)
        if(istatus .ne. 1)go to 999

        call get_grid_dim_xy(NX_L,NY_L,istatus)
	if (istatus .ne. 1) then
           write (6,*) 'Error getting horizontal domain dimensions'
           go to 999
        endif

        write(6,*)
        write(6,*)' Running WPDN (NIMBUS) Rass ingest'
        call ingest_lrs(i4time,NX_L,NY_L,j_status)
        write(6,*)' Return from WPDN (NIMBUS) Rass ingest'

        write(6,*)
        write(6,*)' Running BLP (NIMBUS) Rass ingest'
        call ingest_blplrs(i4time,NX_L,NY_L,j_status)
        write(6,*)' Return from BLP (NIMBUS) Rass ingest'

999     continue
        end

