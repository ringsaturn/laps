      subroutine getsat_attributes(csat_id,csat_type,chtype,
     &istart,iend,jstart,jend,istatus)

      implicit none

      integer   i,j,k
      integer   ispec
      integer   istart,iend
      integer   jstart,jend
      integer   istatus

      character csat_id*6
      character csat_type*3
      character chtype*3

      include 'satellite_dims_lvd.inc'
      include 'satellite_common_lvd.inc'

      istatus = 0

      do k=1,maxsat
       if(c_sat_id(k).eq.csat_id)then

        do j=1,maxtype
         if(c_sat_types(j,k).eq.csat_type)then

          do i=1,maxchannel
           if(c_channel_types(i,j,k).eq.chtype)then

            call lvd_file_specifier(chtype,ispec,istatus)
            goto(1,2,3,2,2)ispec

1           istart=i_start_vis(j,k)
            iend  =i_end_vis(j,k)
            jstart=j_start_vis(j,k)
            jend  =j_end_vis(j,k)
            goto 10

2           istart=i_start_ir(j,k)
            iend  =i_end_ir(j,k)
            jstart=j_start_ir(j,k)
            jend  =j_end_ir(j,k)
            goto 10

3           istart=i_start_wv(j,k)
            iend  =i_end_wv(j,k)
            jstart=j_start_wv(j,k)
            jend  =j_end_wv(j,k)

10          continue
           endif
          enddo
         endif
        enddo
       endif
      enddo 

      if(min(istart,iend,jstart,jend).le.0)then
         write(6,*)'Error in getsat_attributes'
         write(6,*)'istart, iend, jstart, or jend = 0'
         return
      endif

      istatus = 1

      return
      end
