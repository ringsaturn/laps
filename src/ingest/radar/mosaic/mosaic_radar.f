      program  mosaic_radar

      include  'lapsparms.cmn'
      include  'radar_mosaic_dim.inc'

      integer   istatus
      integer   n_radars
      integer   i_window
      integer   imosaic_3d
      integer   i
      character c_radar_ext(max_radars_mosaic)*3
      character c_radar_mosaic*3

      call get_laps_config('nest7grid',istatus)
c
c Radar mosaic. There are two types:  wideband remapper (vxx series - rrv output)
c and rpg narrow band (wfo arena: rdr/./vrc/).
c
c namelist items

c     c_mosaic_type='vxx'
c     c_mosaic_type='rdr'

      call mosaic_radar_nl(c_radar_mosaic,n_radars,c_radar_ext,
     & i_window,imosaic_3d,istatus)
    
c     if(c_radar_mosaic.eq.'vxx')then
c        n_radars=3
c        c_radar_ext(1)='v01'
c        c_radar_ext(2)='v02'
c        c_radar_ext(3)='v03'
c     else
c        n_radars=2
c        c_radar_ext(1)='001'
c        c_radar_ext(2)='002'
c     endif

      if(n_radars.gt.max_radars_mosaic)then
         print*,'the namelist item n_radars exceeds',
     + 'the maximum number of radars allowed'
         print*,'Aborting ','n_radars = ',n_radars,' max = ',
     + max_radars_mosaic
         goto 1000
      endif

      print*,'Process parameters'
      print*,'Mosaic type: ',c_radar_mosaic
      print*,'N radars to mosaic: ',n_radars
      write(6,50)'Radar extensions: ',(c_radar_ext(i),i=1,n_radars)
50    format(1x,a,10(:,a3,1x))
 
      call mosaic_radar_sub(nx_l_cmn,ny_l_cmn,nk_laps,max_radars_mosaic,
     + n_radars,c_radar_ext,c_radar_mosaic,i_window,imosaic_3d,istatus)
 
      if(istatus.ne.1)then
         print*,'Error in vrc_vxx_driver_sub'
      else
         print*,'Finished '
      endif

1000  stop
      end

      subroutine mosaic_radar_sub(nx_l,ny_l,nz_l,mx_radars,
     & n_radars,c_radar_ext,c_mosaic_type,i_window_size,imosaic_3d,
     & istatus)
c
c A LAPS vrc file is generated by mosaicing v'xx' type files
c (where xx = 01, 02, ..., 20; corresponding to radar ingest files v01, v02,
c  ..., v20). The v'xx' files are remapped 3d laps grid single radar files
c corresponding to a wsr88D within the laps domain.
c
c Mosaics can also be made from 2d radar files using switch 'rdr' which is
c WFO type configuration.
c
c There is no path to data. The files processed are in the lapsprd subdirectory
c and get_directory satisfies the pathway requirements.
c

      Integer       maxfiles
      parameter    (maxfiles=500)

      Integer       x,y,z,record

      Real*4        grid_ra_ref(nx_l,ny_l,nz_l,n_radars)
      Real*4        grid_ra_vel(nx_l,ny_l,nz_l,n_radars)
      Real*4        grid_mosaic_3dref(nx_l,ny_l,nz_l)
      Real*4        lat(nx_l,ny_l)
      Real*4        lon(nx_l,ny_l)
      Real*4        topo(nx_l,ny_l)
      Real*4        rheight_laps(nx_l,ny_l,nz_l)
      Real*4        rlat_radar(n_radars)
      Real*4        rlon_radar(n_radars)
      Real*4        rheight_radar(n_radars)

      Real*4        zcoord_of_level
      Integer       lvl_3d(nz_l)
c
      Character     c_filename_vxx(maxfiles,n_radars)*200
      Character     c_ra_filename(n_radars)*200
      Character     path_rdr*200
      Character     path*200
      Character     fname*9
      Character     atime*24
      Character     c_fname_cur*9
      Character     c_fname_pre*9
      Character     c_radar_ext(mx_radars)*3
      Character     c_ra_ext(n_radars)*3
      Character     c_directory*256
      Character     c_mosaic_type*(*)
      Character     c_rad_types(n_radars)
      Character     cradars*3

      Integer       nfiles_vxx(maxfiles)
      Integer       i_ra_count
      Integer       i_file_count(maxfiles)
      Integer       i_window_size
      Integer       len_dir

      Logical       first_time
      Logical       found_data
      Logical       l_low_level

      Integer       i4time_cur
      Integer       i4time_pre
      Integer       i4time_now_gg
      Integer       i4time_diff
      Integer       i4time_window_beg
      Integer       i4time_window_end
      Integer       i_ra_i4time(n_radars)
      Integer       i4timefile_vxx(maxfiles,n_radars)
      Integer       i4timefile_proc(maxfiles,n_radars)
      Integer       i4time_nearest
c
c vrc definitions
c
      character     dir_vrc*50
      character     ext_vrc*31
      character     comment_vrc*125
      character     units_vrc*10
      character     var_vrc*3
      character     lvl_coord_2d*4
c
c vrz definitions
c
      character     dir_vrz*50
      character     ext_vrz*31
      character     comment_vrz*125
      character     units_vrz*10
      character     var_vrz*3
c
c for getting laps heights
c
      character     ext*31
     +             ,var_3d(nz_l)*3
     +             ,lvl_coord_3d(nz_l)*4
     +             ,units_3d(nz_l)*10
     +             ,comment_3d(nz_l)*125

      character     units_2d*10
      character     var_2d*3
      character     comment_2d*125

      character     c_radar_id(n_radars)*4
      character     c_ra_ftime(n_radars)*9
      character     c_ftime_data*9

      data          lvl_2d/0/
c
c---------------------------------------------------------
c Start
c
      istatus = 0
      l_low_level=.false.
c
c get current time. Make the time window.
c --------------------------------------------------------
!     i4time_cur = i4time_now_gg()
      call get_systime_i4(i4time_cur,istatus)

      i4time_window_beg = i4time_cur-i_window_size
      i4time_window_end = i4time_cur+i_window_size
      call make_fnam_lp(i4time_cur,c_fname_cur,istatus)
c
c get lat/lon/topo data
c
      call get_laps_domain(nx_l,ny_l,'nest7grid',
     &                     lat,lon,topo,istatus)
      if(istatus .ne. 1)then
          write(6,*)'error reading static file'
          goto 1000
      end if
      write(6,*)
c
c determine if data from any radar is current. count the number of
c radars with current radar data. Terminate if no current data available.
c
      if(c_mosaic_type.eq.'rdr')then
         call get_directory('rdr',path_rdr,lprdr)
      endif

      do i=1,n_radars

         if(c_mosaic_type.eq.'vxx')then
            call get_directory(c_radar_ext(i),path,lenp)
         elseif(c_mosaic_type.eq.'rdr')then
            path=path_rdr(1:lprdr)//c_radar_ext(i)//'/vrc/'
            call s_len(path,lenp)
         endif

c        call make_fnam_lp(i4time_pre,c_fname_pre,istatus)

!        Should this be simplified with a call to 'get_file_times'?
         call get_file_names(path,
     &                    numoffiles,
     &                    c_filename_vxx(1,i),
     &                    maxfiles,
     &                    istatus)
         if(istatus.eq.1)then
            print*,'Success in get_file_names. Numoffiles = ',numoffiles
            if(numoffiles .le. 0)then
               write(6,*)'No Data Available in: ',c_radar_ext(i)
               goto 333
            end if
c
c laps internal filename convention always applies (yyjjjhhmm.ext).
c
            do l=1,numoffiles
               nn=index(c_filename_vxx(l,i),' ')
c              write(6,*)c_filename_vxx(l,i)(1:nn)
               call cv_asc_i4time(c_filename_vxx(l,i)(nn-13:nn-5),
     &                            i4timefile_vxx(l,i))
            end do
            nfiles_vxx(i)=numoffiles
         else
            write(6,*)'istatus ne 1 in getfilenames - abort'
            stop
         end if

333   enddo
c
c need additional set of code here to examine vrc/vrz subdirectories
c to determine if the data found has already been processed.
c
c ------- additional code here ---------
c
c reorganize the directory results. Also need to count the number of mosaics
c needed. That is, if there is more than one file per radar then we will
c have n_mosaics > 1. Furthermore, we need to keep track of which files
c from the n_radars are mosaiced. This would be a nearest in time type
c of categorization. We will need another parameter -> used to threshold
c which files can be mosaiced. This parameter should be a function of the
c number of radars to be mosaiced (possibly).
c
      min_i4time=1999999999
      max_i4time=0
      found_data=.false.
      do i=1,n_radars
         first_time=.true.
         do l=1,nfiles_vxx(i)
            if(i4timefile_vxx(l,i).gt.i4time_window_beg.and.
     &         i4timefile_vxx(l,i).le.i4time_window_end)then

               if(first_time)then
                  found_data=.true.
                  first_time=.false.
                  i_ra_count=i_ra_count+1
                  c_ra_filename(i_ra_count) = c_filename_vxx(l,i)
                  c_ra_ext(i_ra_count) = c_radar_ext(i)
                  i_ra_i4time(i_ra_count) = i4timefile_vxx(l,i)
                  call make_fnam_lp(i4timefile_vxx(l,i),
     &                              c_ra_ftime(i_ra_count),istatus) 
                  min_i4time = min(min_i4time,
     &                             i_ra_i4time(i_ra_count))
                  max_i4time = max(max_i4time,
     &                             i_ra_i4time(i_ra_count))
               else   !this switch= if more than one file for same radar within window. Take lastest
c if files are already time ordered then the latest time will be loaded into array c_ra_filename.
c                 i_ra_count=i_ra_count+1
                  c_ra_filename(i_ra_count)=c_filename_vxx(l,i)
                  c_ra_ext(i_ra_count)=c_radar_ext(i)
                  i_ra_i4time(i_ra_count)=i4timefile_vxx(l,i)
                  min_i4time = min(min_i4time,
     &                             i_ra_i4time(i_ra_count))
                  max_i4time = max(max_i4time,
     &                             i_ra_i4time(i_ra_count))
               endif
            endif
         enddo ! file
         write(6,*)c_radar_ext(i), ' found radar = ', .not. first_time       
      enddo ! radar

      if(.not.found_data)then
         write(6,*)'No files in any vxx directories'
         write(6,*)'No data to process'
         goto 995
      endif
c
c Determine appropriate i4time for these data
c
      if(i_ra_count.gt.1)then
         itime_diff=max_i4time-min_i4time
         i4time_radar_ave = min_i4time+(itime_diff/i_ra_count)
         i4time_data = i4time_cur
         call make_fnam_lp(i4time_data,c_ftime_data,istatus)
         do i=1,i_ra_count
            print*,'Radar Info: ',i,' ',c_ra_ext(i),' ',i_ra_i4time(i),
     &             ' ',c_ra_ftime(i)
         enddo
         print*,'Data filetime: ',c_ftime_data
      elseif(i_ra_count.eq.1)then
         i4time_radar_ave = max_i4time
         i4time_data = i4time_cur
         call make_fnam_lp(i4time_data,c_ftime_data,istatus)
         print*,'Radar filetime: ',c_ra_ftime(1)
         print*,'Data filetime: ',c_ftime_data
      else
         write(6,*)'Ooops, i_ra_count = 0!'
         goto 1000
      endif

      write(6,*)'Get the data'
c
c Read Analysis heights
c
      EXT = 'lt1'
      call get_directory(ext,c_directory,len_dir)
      do k = 1,nz_l
         lvl_3d(k) = nint(zcoord_of_level(k))/100
         lvl_coord_3d(k) = 'HPA'
         var_3d(k) = 'HT'
         units_3d(k) = 'M'
      enddo

      call get_file_time(c_directory,i4time_data,i4time_nearest)
      if(i4time_nearest-i4time_data .gt. 3600)then
         write(6,*)'No Current Hgts Available'
         l_low_level=.false.
      else
         write(6,*)'Reading Analysis Heights'

         var_2d = 'HT'
         i4_tol = 7200
         call get_laps_3dgrid(i4time_data,i4_tol,i4time_nearest,
     1          nx_l,ny_l,nz_l,EXT,var_2d,units_2d,
     1                          comment_2d,rheight_laps,istatus)
c
c        Call Read_Laps_Data(i4time_nearest,c_directory,ext,
c    &              nx_l, ny_l, nz_l,2d,rheight_laps,istatus) 
c    &              var_3d, lvl_3d, lvl_coord_3d,
c    &              units_3d, comment_3d, rheight_laps, IStatus)

         if(Istatus.ne.1)then
            write(6,*)'Error reading heights '
            write(6,*)'Setting l_low_level = false'
            l_low_level=.false.
         endif
      endif
c
c These subroutines could be in loop (do i=1,n_mosaics).
c ----------------------------------------------------------
      if(c_mosaic_type(1:3).eq.'vxx')then

!        Read 'vxx' file within 300s tolerance of 'i4time_cur'

         call getlapsvxx(nx_l,ny_l,nz_l,n_radars,c_radar_id,
     &      i_ra_count,c_ra_ext,i4time_cur,i_window_size,
     &      rheight_laps,lat,lon,topo,
     &      rlat_radar,rlon_radar,rheight_radar,grid_ra_ref,grid_ra_vel,       
     &      istatus)

      elseif(c_mosaic_type(1:3).eq.'rdr')then

!        Should this be simplified to read 'vrc' files on the LAPS grid?

         call get_rdr_dims(c_ra_filename(1),x,y,z,record,istatus)

         call get_laps_rdr(nx_l,ny_l,nz_l,z,record,i_ra_count,
     &     c_ra_filename,c_radar_id,rlat_radar,rlon_radar,rheight_radar,
     &     grid_ra_ref,istatus)

         if(istatus.ne.1)then
            call s_len(c_ra_filename(i),nc)
            print*,'Error reading ',c_ra_filename(i)(1:nc)
            return
         endif

      endif

c
c Determine max reflectivity 2-d field as composite of all radar files for
c the given time. Test i_ra_count > 1. If not then no need to mosaic!
c -------------------------------------------------------------------------
      if(i_ra_count.gt.1)then

c this subroutine does not yet use imosaic_3d parameter.

         call mosaic_ref_multi(i_ra_count,n_radars,l_low_level,
     & c_radar_id,lat,lon,nx_l,ny_l,nz_l,rlat_radar,rlon_radar,
     & rheight_radar,topo,rheight_laps,grid_ra_ref,grid_mosaic
     &_3dref,istatus)

      elseif(i_ra_count.eq.1)then

         print*,'Only 1 radar - no mosaic'

         if(imosaic_3d.eq.0.or.imosaic_3d.eq.2)then
            call move(grid_ra_ref(1,1,1,1),grid_mosaic_3dref(1,1,1),
     &                nx_l,ny_l)
         elseif(imosaic_3d.eq.1.or.imosaic_3d.eq.3)then
            do k=1,nz_l
               call move(grid_ra_ref(1,1,k,1),grid_mosaic_3dref(1,1,k),
     &                nx_l,ny_l)
            enddo
         endif

      else
          print*,'no radars?'
      endif

c check it out
c
      print*,'------------------'
      print*,'The mosaiced field'
      print*,'------------------'

      do j=1,ny_l,10
      do i=1,nx_l,10
         write(6,31)i,j,grid_mosaic_3dref(i,j,1)
      enddo
      enddo
31    format(2(2x,i4),1x,f8.1)
 
c
c vrc output. there should be a corresponding vrz output as well.
c
      write(cradars,100)n_radars
100   format(i3)

      do i=1,3
         if(cradars(i:i).eq.' ')cradars(i:i)='0'
      enddo

      if(imosaic_3d.eq.0.or.imosaic_3d.eq.2)then
         ext_vrc = 'vrc'
         var_vrc = 'REF'
         units_vrc = 'DBZ'
         read(cradars,*)n_radars
         comment_vrc='Radar mosaic. Type = '//c_mosaic_type//' '
     1               //cradars
         call get_directory('vrc',path,lenp)
         dir_vrc = path(1:lenp)

         call write_laps_data(i4time_data,
     &                     dir_vrc,
     &                     ext_vrc,
     &                     nx_l,ny_l,1,1,
     &                     var_vrc,
     &                     lvl_2d,
     &                     lvl_coord_2d,
     &                     units_vrc,
     &                     comment_vrc,
     &                     grid_mosaic_3dref(1,1,1),
     &                     istatus)
         if(istatus.eq.1)then
            write(*,*)'VRC file successfully written'
            call cv_i4tim_asc_lp(i4time_data,atime,istatus)
            write(6,*)'for: ',atime
            write(*,*)'i4 time: ',i4time_data
         else
            write(6,*)'VRC not written!'
         end if

      endif

c
c vrz output. 
c
      if(imosaic_3d.eq.1.or.imosaic_3d.eq.2)then
         write(6,*)' Output VRZ file'
         ext_vrz = 'vrz'
         var_vrz = 'REF'
         units_vrz = 'DBZ'
         read(cradars,*)n_radars
         comment_vrz='Radar mosaic. Type = '//c_mosaic_type//' '
     1               //cradars

         if(.true.)then ! write radar info into comments
             call get_directory(ext_vrz,path,len_dir)
             write(6,11)path,ext_vrz,var_vrz
11           format(' Writing 3d ',a50,1x,a5,1x,a3)

             do k = 1,nz_l
                 units_3d(k) = units_vrz
                 lvl_3d(k) = nint(zcoord_of_level(k))/100
                 lvl_coord_3d(k) = 'HPA'
                 var_3d(k) = var_vrz
             enddo ! k

             comment_3d(1) = comment_vrz

             n_ref = 0

             do i_radar = 1,n_radars
                 ii = i_radar + 1
                 if(ii .le. nz_l)then
                     write(comment_3d(ii),1)rlat_radar(i_radar)
     1                                     ,rlon_radar(i_radar)
     1                                     ,rheight_radar(i_radar)
     1                                     ,n_ref
     1                                     ,c_radar_id(i_radar)
1                    format(2f9.3,f8.0,i7,a4)

                 else
                     write(6,*)
     1               ' Error: too many radars for comment output'
                     istatus = 0
                     return

                 endif

             enddo ! i

             CALL WRITE_LAPS_DATA(i4time_data,path,ext_vrz,
     1                            nx_l,ny_l,nz_l,nz_l,
     1                            VAR_3D,LVL_3D,LVL_COORD_3D,UNITS_3D,
     1                            COMMENT_3D,grid_mosaic_3dref,ISTATUS)       

         else
             call put_laps_3d(i4time_data,
     &                        ext_vrz,
     &                        var_vrz,
     &                        units_vrz,
     &                        comment_vrz,
     &                        grid_mosaic_3dref,
     &                        nx_l,ny_l,nz_l)


         endif

      endif


      goto 1000

995   write(6,*)'No data. Process stopping'
      goto 1000

998   write(6,*)'Error using systime.dat'

1000  return
      end
