       subroutine genbtemplut(chid,cnt2btemp,istatus)
c
c
c
       implicit none
c
       integer chid,i
       integer istatus
       real*4    cnt2btemp(0:1023)

       istatus=1
       if(chid.eq.4.or.chid.eq.5)then
          do i=0,180
             cnt2btemp(i)=(660.0-float(i))/2.0
          enddo
          do i=181,255
             cnt2btemp(i)=420.0-float(i)
          enddo

       elseif(chid.eq.2)then

          do i=0,183
             cnt2btemp(i)=(660.4-float(i))/2.0
          enddo
          do i=184,216
             cnt2btemp(i)=421.7-float(i)
          enddo
          do i=217,255
             cnt2btemp(i)=0.0
          enddo

       elseif(chid.eq.3)then

Count range 255 --> 0, T = (1349.27 - C)/5.141.   4/26/96. Recommendation from D. Birkenheuer

Channel 3 
Count range 255 --> 0, T = (1354.235 - C)/5.1619  5/14/96.   "

          do i=0,255

C            cnt2btemp(i) = 249.346 - 0.12945*float(i)
C            cnt2btemp(i) = (1354.235 - float(i))/5.1619
C            cnt2btemp(i) = (1349.27 - float(i))/5.141
C            cnt2btemp(i) = (1344.38 - float(i))/5.12 
c
c new as of 10-3-96.
             cnt2btemp(i) = (1348.925 - float(i) ) / 5.1417

          enddo

       else

          write(6,*)'Channel # error, it doesnt exist'
          istatus=0

       endif
c
c test output of cnt2btemp table
c
c      write(6,*)'cnt 2 btemp for channel: ',chid
c      write(6,*)'-----------------------------'
c      do i=0,255,8
c         write(6,33)i,i+7,(cnt2btemp(j),j=i,i+7)
c      enddo
33     format(2x,i3,'-',i3,1x,'||',2x,8(f5.1,1x))
c      write(6,*)'-----------------------------'
       return
       end
