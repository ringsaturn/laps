       subroutine btemp_convert(nelems,nlines,
     &                        rcnt_to_btemp_lut,
     &                        r_missing_data,
     &                        image)
c
c
c
       implicit none

       integer i,j
       integer nelems
       integer nlines

       real*4  image(nelems,nlines)
       real*4  rcnt_to_btemp_lut(0:1023)
       real*4  r_missing_data

       do j=1,nlines
       do i=1,nelems

          if(image(i,j).ne.r_missing_data)then
             image(i,j)=rcnt_to_btemp_lut(int(image(i,j)))
          endif

       enddo
       enddo

       return
       end
