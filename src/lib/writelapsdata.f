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
      subroutine write_laps_data(i4time,dir,ext,imax,jmax,
     1   kmax,kdim,var,lvl,lvl_coord,units,comment,data,
     1   istatus)

C**********************************************************************
C
C      This file contains the following FORTRAN subroutines:
C            write_laps_data
C
C      The write_laps_data subroutine reads the following FORTRAN
C      subroutines from the readlapsdata.f file:
C            cvt_fname_v3
C
C      The write_laps_data subroutine reads the following C subroutines
C      from the rwl_v3.c file:
C            write_cdf_v3
C
C**********************************************************************
C
C      Subroutine WRITE_LAPS_DATA
C
C      Author:    John Snook
C      Modified:  To write netCDF data files  1/93 Linda Wharton
C                 To remove BYTE arrays       4/94 Linda Wharton
C                 To accept netCDF ver. 3 data files  9/97 Linda Wharton
C
C      Writes data in arrays DATA and COMMENT to the netCDF file name
C      specified by I4TIME, DIR and EXT.  The data in VAR, LVL, LVL_COORD,
C      IMAX, JMAX, KMAX, KDIM and UNITS are stored into the netCDF file
C      when it is created.  ISTATUS is returned.
C
C**********************************************************************
C
        implicit  none
C
      integer*4      i4time,               !INPUT I4time of data
     1               i4_valtime,
     1               imax,jmax,kmax,       !INPUT # cols, # rows, # fields
     1               kdim,                 !INPUT K dimension of DATA array
     1               lvl(kdim),            !INPUT Level of each field 
     1               istatus               !OUTPUT

      real*4         data(imax,jmax,kdim)  !INPUT Raw data to be written
      character*(*)  dir                   !INPUT Directory to be written to
      character*(*)  ext                   !INPUT File name ext
      character*(*)  var(kdim)             !INPUT 3 letter ID of each field
      character*(*)  lvl_coord(kdim)       !INPUT Vertical coordinate of fields
      character*(*)  units(kdim)           !INPUT units of each field
      character*(*)  comment(kdim)         !INPUT Comments for each field
C
      integer*4      flag,                 !Print flag (1 = off)
     1               i_reftime,            !UNIX time of data
     1               i_valtime,            !UNIX time of data
     1               error(2),
     1               i,j,n7g_nx, n7g_ny,
     1               fn_length,
     1               var_len,
     1               comm_len,
     1               ext_len,
     1               asc_len,
     1               lvl_coord_len,
     1               units_len,
     1               cdl_path_len,
     1               stat_len,
     1               n_levels,
     1               max_levels,	   !maximum vertical levels
     1               called_from,          !0=FORTRAN, 1=C
     1               append                !0=no, 1=yes
C
      parameter (max_levels=100)
      real*4         base,                 !bottom of LAPS levels
     1               interval,             !interval of LAPS levels
     1               cdl_levels(max_levels)
C
      character*4    fcst_hh_mm
      character*9    gtime
      character*128  file_name
      character*128  cdl_path
      character*128  static_path
      character*9    laps_dom_file
      character*24   asctime
C
      common         /prt/flag
C
      include 'lapsparms.cmn'
C
C-------------------------------------------------------------------------------
C
      error(1)=1
      error(2)=0
C
C ****  Specify laps domain name
C
      laps_dom_file = 'nest7grid'
C 
C
C ****  call get_laps_config to read nest7grid.parms
C
      call get_laps_config(laps_dom_file,istatus)
      n_levels = nk_laps
      base = PRESSURE_BOTTOM_L / 100.0
      interval = PRESSURE_INTERVAL_L / 100.0
      n7g_nx = NX_L_CMN 
      n7g_ny =  NY_L_CMN

C **** Special case where write_laps_data is called with fua or fsf extension
      if (ext .eq. 'fua') then
        j = base
        do i = 1, n_levels
          cdl_levels(i) = j 
          j = j - interval
        enddo
      endif
      if (ext .eq. 'fsf') then
        n_levels = 1
        cdl_levels(1) = 0
      endif
C
C ****  Various checks on input data.
C
      if (kmax .gt. kdim) then
        if (flag .ne. 1)
     1write (6,*) 'Illegal K dimension in DATA array...write aborted.'
        istatus=error(2)
        return
      endif
C
      if (imax .ne. n7g_nx) then
        if (flag .ne. 1)
     1write (6,*) 
     1'imax passed in does not match nest7grid.parms...write aborted.'
        istatus=error(2)
        return
      endif
C
      if (jmax .ne. n7g_ny) then
        if (flag .ne. 1)
     1write (6,*) 
     1'jmax passed in does not match nest7grid.parms...write aborted.'
        istatus=error(2)
        return
      endif
C
C ****  Get cdl_path
C
      call get_directory('cdl',cdl_path, cdl_path_len)

C ****  Get static_path
C
      call get_directory('static',static_path, stat_len)
C
C ****  Specify file name
C
      call make_fnam_lp(i4time,gtime,istatus)
      if (istatus .ne. 1) then
        write (6,*)
     1'Error converting i4time to file name...write aborted.'
        istatus=error(2)
        return
      endif
C
C **** get actual reftime from gtime...
C
      i_reftime = i4time - 315619200
      i_valtime = i_reftime

C
C ****  Create ascii time variables.
C
      i4_valtime = i_valtime +  315619200
      call cv_i4tim_asc_lp(i4_valtime,asctime,istatus)

      call s_len(ext, ext_len)

      fcst_hh_mm = '0000'

      call cvt_fname_v3(dir,gtime,fcst_hh_mm,ext,ext_len,
     1                  file_name,fn_length,istatus)

      called_from = 0    !called from FORTRAN
      append = 0         ! only one analysis time allowed per file

      var_len = len(var(1))
      comm_len = len(comment(1))
      lvl_coord_len = len(lvl_coord(1))
      units_len = len(units(1))
      asc_len = len(asctime)

C
C **** write out netCDF file
C
      call write_cdf_v3 (file_name,ext,var,comment,asctime,cdl_path, 
     1                   static_path,fn_length,ext_len,var_len, 
     1                   comm_len, asc_len, cdl_path_len, stat_len,
     1                   i_reftime, i_valtime,imax, jmax, kmax, kdim, 
     1                   lvl, data,base,interval, n_levels, cdl_levels,
     1                   called_from,append, istatus) 
C
      if (istatus .gt. 0) goto 980
      IF (istatus .eq. -2) goto 940
      IF (istatus .eq. -3) goto 950
      IF (istatus .eq. -4) goto 960
      IF (istatus .eq. -5) goto 970
      IF (istatus .eq. -6) goto 990
C
C ****  Return normally.
C
        ISTATUS=ERROR(1)
999     RETURN
C
C ****  Error trapping.
C
940     IF (FLAG .NE. 1)
     1    write (6,*) 'Error opening file to be written to...write abort
     1ed.'
        ISTATUS=ERROR(2)
        GOTO 999
C
950     IF (FLAG .NE. 1)
     1    write (6,*) 'Error in imax,jmax,or n_levels..write aborted'
        ISTATUS=ERROR(2)
        GOTO 999
C
960     IF (FLAG .NE. 1)
     1    write (6,*) 'Error writing data to file...write aborted.'
        ISTATUS=ERROR(2)
        GOTO 999
C
970     IF (FLAG .NE. 1)
     1    write (6,*) 
     1 'Error writing header info into file...write aborted.'
        ISTATUS=ERROR(2)
        GOTO 999
C
980     IF (FLAG .NE. 1)
     1    write (6,*) 
     1 'Some grids not written....could not convert LAPS variables.'
        ISTATUS=ERROR(2)
        GOTO 999
C
990     IF (FLAG .NE. 1)
     1    write (6,*) 
     1 'File already exists for analysis time...write aborted.'
        ISTATUS=ERROR(2)
        GOTO 999
C
        END

C##########################################################################
      subroutine write_laps_multi(i4time,dir,ext,imax,jmax,
     1   kmax,kdim,var,lvl,lvl_coord,units,comment,data,
     1   istatus)

C**********************************************************************
C
C      This file contains the following FORTRAN subroutines:
C            write_laps_data
C
C      The write_laps_data subroutine reads the following FORTRAN
C      subroutines from the readlapsdata.f file:
C            cvt_fname_v3
C
C      The write_laps_data subroutine reads the following C subroutines
C      from the rwl_v3.c file:
C            write_cdf_v3
C
C**********************************************************************
C
C      Subroutine WRITE_LAPS_MULTI
C
C      Author:    John Snook
C      Modified:  To write netCDF data files  1/93 Linda Wharton
C                 To remove BYTE arrays       4/94 Linda Wharton
C                 To accept netCDF ver. 3 
C                   data files                9/97 Linda Wharton
C                 To allow multiple writes to 
C                   one file                 10/97 Linda Wharton
C
C      Writes data in arrays DATA and COMMENT to the netCDF file name
C      specified by I4TIME, DIR and EXT.  The data in VAR, LVL, LVL_COORD,
C      IMAX, JMAX, KMAX, KDIM and UNITS are stored into the netCDF file
C      when it is created.  ISTATUS is returned.
C
C**********************************************************************
C
        implicit  none
C
      integer*4      i4time,               !INPUT I4time of data
     1               i4_valtime,
     1               imax,jmax,kmax,       !INPUT # cols, # rows, # fields
     1               kdim,                 !INPUT K dimension of DATA array
     1               lvl(kdim),            !INPUT Level of each field 
     1               istatus               !OUTPUT

      real*4         data(imax,jmax,kdim)  !INPUT Raw data to be written
      character*(*)  dir                   !INPUT Directory to be written to
      character*(*)  ext                   !INPUT File name ext
      character*(*)  var(kdim)             !INPUT 3 letter ID of each field
      character*(*)  lvl_coord(kdim)       !INPUT Vertical coordinate of fields
      character*(*)  units(kdim)           !INPUT units of each field
      character*(*)  comment(kdim)         !INPUT Comments for each field
C
      integer*4      flag,                 !Print flag (1 = off)
     1               i_reftime,            !UNIX time of data
     1               i_valtime,            !UNIX time of data
     1               error(2),
     1               i,j,n7g_nx, n7g_ny,
     1               fn_length,
     1               var_len,
     1               comm_len,
     1               ext_len,
     1               asc_len,
     1               lvl_coord_len,
     1               units_len,
     1               cdl_path_len,
     1               stat_len,
     1               n_levels,
     1               max_levels,	   !maximum vertical levels
     1               called_from,          !0=FORTRAN, 1=C
     1               append                !0=no, 1=yes
C
      parameter (max_levels=100)
      real*4         base,                 !bottom of LAPS levels
     1               interval,             !interval of LAPS levels
     1               cdl_levels(max_levels)
C
      character*4    fcst_hh_mm
      character*9    gtime
      character*128  file_name
      character*128  cdl_path
      character*128  static_path
      character*9    laps_dom_file
      character*24   asctime
C
      common         /prt/flag
C
      include 'lapsparms.cmn'
C
C-------------------------------------------------------------------------------
C
      error(1)=1
      error(2)=0
C
C ****  Specify laps domain name
C
      laps_dom_file = 'nest7grid'
C
C ****  call get_laps_config to read nest7grid.parms
C
      call get_laps_config(laps_dom_file,istatus)
      n_levels = nk_laps
      base = PRESSURE_BOTTOM_L / 100.0
      interval = PRESSURE_INTERVAL_L / 100.0
      n7g_nx = NX_L_CMN 
      n7g_ny =  NY_L_CMN

C **** Special case where write_laps_data is called with fua or fsf extension
      if (ext .eq. 'fua') then
        j = base
        do i = 1, n_levels
          cdl_levels(i) = j
          j = j - interval
        enddo
      endif
      if (ext .eq. 'fsf') then
        n_levels = 1
        cdl_levels(1) = 0
      endif
C
C ****  Various checks on input data.
C
      if (kmax .gt. kdim) then
        if (flag .ne. 1)
     1write (6,*) 'Illegal K dimension in DATA array...write aborted.'
        istatus=error(2)
        return
      endif
 
      if (imax .ne. n7g_nx) then
        if (flag .ne. 1)
     1write (6,*) 
     1'imax passed in does not match nest7grid.parms...write aborted.'
        istatus=error(2)
        return
      endif
 
      if (jmax .ne. n7g_ny) then
        if (flag .ne. 1)
     1write (6,*) 
     1'jmax passed in does not match nest7grid.parms...write aborted.'
        istatus=error(2)
        return
      endif
C
C ****  Get cdl_path
C
      call get_directory('cdl',cdl_path, cdl_path_len)

C ****  Get static_path
C
      call get_directory('static',static_path, stat_len)
C
C ****  Specify file name
C
      call make_fnam_lp(i4time,gtime,istatus)
      if (istatus .ne. 1) then
        write (6,*)
     1'Error converting i4time to file name...write aborted.'
        istatus=error(2)
        return
      endif
C
C **** get actual reftime from gtime...
C
      i_reftime = i4time - 315619200
      i_valtime = i_reftime

C
C ****  Create ascii time variables.
C
      i4_valtime = i_valtime +  315619200
      call cv_i4tim_asc_lp(i4_valtime,asctime,istatus)

      call s_len(ext, ext_len)

      fcst_hh_mm = '0000'

      call cvt_fname_v3(dir,gtime,fcst_hh_mm,ext,ext_len,
     1                  file_name,fn_length,istatus)

      called_from = 2    !called from write_laps_multi FORTRAN
      append = 0         ! only one analysis time allowed per file

      var_len = len(var(1))
      comm_len = len(comment(1))
      lvl_coord_len = len(lvl_coord(1))
      units_len = len(units(1))
      asc_len = len(asctime)

C
C **** write out netCDF file
C
      call write_cdf_v3 (file_name,ext,var,comment,asctime,cdl_path, 
     1                   static_path,fn_length,ext_len,var_len, 
     1                   comm_len, asc_len, cdl_path_len, stat_len,
     1                   i_reftime, i_valtime,imax, jmax, kmax, kdim, 
     1                   lvl, data,base,interval, n_levels, cdl_levels,
     1                   called_from, append, istatus)
C
      if (istatus .gt. 0) goto 980
      IF (istatus .eq. -2) goto 940
      IF (istatus .eq. -3) goto 950
      IF (istatus .eq. -4) goto 960
      IF (istatus .eq. -5) goto 970
      IF (istatus .eq. -6) goto 990
C
C ****  Return normally.
C
        ISTATUS=ERROR(1)
999     RETURN
C
C ****  Error trapping.
C
940     IF (FLAG .NE. 1)
     1    write (6,*) 'Error opening file to be written to...write abort
     1ed.'
        ISTATUS=ERROR(2)
        GOTO 999
C
950     IF (FLAG .NE. 1)
     1    write (6,*) 'Error in imax,jmax,or n_levels..write aborted'
        ISTATUS=ERROR(2)
        GOTO 999
C
960     IF (FLAG .NE. 1)
     1    write (6,*) 'Error writing data to file...write aborted.'
        ISTATUS=ERROR(2)
        GOTO 999
C
970     IF (FLAG .NE. 1)
     1    write (6,*) 
     1 'Error writing header info into file...write aborted.'
        ISTATUS=ERROR(2)
        GOTO 999
C
980     IF (FLAG .NE. 1)
     1    write (6,*) 
     1 'Some grids not written....could not convert LAPS variables.'
        ISTATUS=ERROR(2)
        GOTO 999
C
990     IF (FLAG .NE. 1)
     1    write (6,*) 
     1 'File already exists for analysis time...write aborted.'
        ISTATUS=ERROR(2)
        GOTO 999
C
        END

C##########################################################################

