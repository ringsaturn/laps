
!     Ken Dritz     28-Jul-1997         Added call to get_grid_dim_xy to
!                                       get the values of NX_L, NY_L.
!     Ken Dritz     28-Jul-1997         Pass the values of NX_L and NY_L to
!                                       get_raob_data and get_raob_data_af.

!     Input file 
      character*70 filename_in
      character*9 a9_time
      character*80 dir_in
      character*255 c_filespec
      integer max_files
      parameter(max_files = 3000)
      character*255 c_fnames(max_files)
      integer i4times(max_files)
      character*9 a8_to_a9
      character*8 a8_time,a8_time_orig(max_files)
      character*8 c8_project

!     Output file
      character*13 filename13
      character*31    ext
      integer*4       len_dir

      character*40 c_vars_req
      character*100 c_values_req

!     Define width of raob release time window centered on the SND filetime
!     +/- 3 hr for AFGWC, +/- laps_cycle_time for NIMBUS
      integer i4_raob_window

!     Define interval to be used (between timestamps) for creation of SND files
      integer i4_snd_interval
      parameter (i4_snd_interval = 3600)

      iopen = 0

      call get_systime(i4time_sys,a9_time,istatus)
      if(istatus .ne. 1)go to 999

      i4time_sys = (i4time_sys/i4_snd_interval) * i4_snd_interval ! For testing only

      call get_grid_dim_xy(NX_L,NY_L,istatus)
      if (istatus .ne. 1) then
          write (6,*) 'Error getting horizontal domain dimensions'
          go to 999
      endif

      call get_laps_cycle_time(ilaps_cycle_time,istatus)
      if(istatus .eq. 1)then
          write(6,*)' ilaps_cycle_time = ',ilaps_cycle_time
      else
          write(6,*)' Error getting laps_cycle_time'
          go to 999
      endif

!     Get List of input /public NetCDF files
      c_vars_req = 'path_to_raw_raob'
      call get_static_info(c_vars_req,c_values_req,1,istatus)
      if(istatus .eq. 1)then
          write(6,*)c_vars_req(1:30),' = ',c_values_req
          dir_in = c_values_req
      else
          write(6,*)' Error getting ',c_vars_req
          goto 999
      endif

      call s_len(dir_in,len_dir_in)

      c8_project = 'NIMBUS'
      c_filespec = dir_in(1:len_dir_in)//'*0300o'
      call get_file_times(c_filespec,max_files,c_fnames
     1                      ,i4times,i_nbr_files_ret,istatus)

      if(i_nbr_files_ret .eq. 0)then
          write(6,*)' No files found in NIMBUS filename format'
          c8_project = 'AFGWC'
          c_filespec = dir_in(1:len_dir_in)//'raob.*'
          call get_file_names(c_filespec,i_nbr_files_ret,c_fnames
     1                      ,max_files,istatus)

!         Obtain file times from file names
          do i = 1,i_nbr_files_ret
              call s_len(c_fnames(i),len_fname)
              call get_directory_length(c_fnames(i),len_dir)
              a8_time = c_fnames(i)(len_dir+6:len_fname)
              a8_time_orig(i) = a8_time

!             Compensate for omission of leading zero in hours position
!             if(a8_time(8:8) .eq. ' ')a8_time(7:8) = '0'//a8_time(7:7) 

              a9_time = a8_to_a9(a8_time)
              call i4time_fname_lp(a9_time,i4times(i),istatus)
              write(6,*)c_fnames(i)(1:len_fname),i4times(i)
          enddo ! i

      endif

!     Loop through raob files and choose ones in time window
      write(6,*)' # of files using filename format ',c8_project,' = '          
     1                                              ,i_nbr_files_ret
      do i = 1,i_nbr_files_ret
          call make_fnam_lp(i4times(i),a9_time,istatus)

          if(c8_project(1:6) .eq. 'NIMBUS')then
              filename_in = dir_in(1:len_dir_in)//a9_time//'0300o'
              i4_raob_window = 2 * ilaps_cycle_time
!             i4_raob_window = 60000  ! Temporary for testing
              i4_raob_lag = 10800
          else ! AFGWC
              filename_in = dir_in(1:len_dir_in)//'/raob.'//
     1                                            a8_time_orig(i)
              i4_raob_window = 21600
              i4_raob_lag = 3600
          endif

!         filename_in = 'test.nc                                 '

!         Define limits of RAOB release times we are interested in
          i4time_raob_latest =   i4time_sys + i4_raob_window / 2
          i4time_raob_earliest = i4time_sys - i4_raob_window / 2

!         Define limits of NetCDF file times we are interested in. This 
!         assumes NetCDF files have RAOBs for 3 hours ending at the NetCDF
!         file time.
          i4time_file_latest =   i4time_raob_latest + i4_raob_lag
          i4time_file_earliest = i4time_raob_earliest 
          
          if(i .eq. 1)then
              write(6,*)' i4 raob sys/window'
     1                   ,i4time_sys,i4_raob_window
              write(6,*)' i4 raob range     '
     1                   ,i4time_raob_earliest,i4time_raob_latest
              write(6,*)' i4 file range     '
     1                   ,i4time_file_earliest,i4time_file_latest
          endif

          if(i4times(i) .lt. i4time_file_earliest)then
              write(6,*)' File is too early ',a9_time,i
          elseif(i4times(i) .gt. i4time_file_latest)then
              write(6,*)' File is too late ',a9_time,i
          else

!             Open output SND file
              if(iopen .eq. 0)then
                  ext = 'snd'
                  call open_lapsprd_file(11,i4time_sys,ext,istatus)
                  if(istatus .ne. 1)go to 998
                  iopen = 1
              endif

              write(6,*)
              write(6,*)' File is in time window ',a9_time,i
              write(6,*)' Input file ',filename_in
              write(6,*)

!             Read from the NetCDF pirep file and write to the opened PIN file
              if(c8_project(1:6) .eq. 'NIMBUS')then
                  call get_raob_data   (i4time_sys,ilaps_cycle_time
     1                ,NX_L,NY_L
     1                ,i4time_raob_earliest,i4time_raob_latest
     1                ,filename_in,istatus)
              else
                  call get_raob_data_af(i4time_sys,ilaps_cycle_time
     1                ,NX_L,NY_L
     1                ,i4time_raob_earliest,i4time_raob_latest,a9_time       
     1                ,filename_in,istatus)
              endif
          endif
      enddo


      close(11) ! Output PIN file

      go to 999

 998  write(6,*)' Error opening output sounding file: '

 999  continue

      write(6,*)' End of raob ingest program'

      end
 
