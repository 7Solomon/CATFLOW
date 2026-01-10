      subroutine v_intb(ie,ix,vxsi,veta,ist,np,ih)

c----------------------------------------------------------------------
c  Routine zur Interpolation der Geschwindigkeiten
c  auf Zwischengitterplaetze
c  1.7.1998
c----------------------------------------------------------------------

      include 'dim.inc'
      include 'hgfest.inc'
      include 'hgbdry.inc'
      include 'hgvari.inc'
      include 'pbdry.inc'
      include 'pfest.inc'
      include 'pvari.inc'

      real*8 vxi1, vxi2, vei1, vei2
      real*8 vxsi, veta
      integer*4 ih, ist, ix, ie, np

      dimension vxsi(maxnv,maxnl,maxnh), veta(maxnv,maxnl,maxnh)
      intrinsic abs


c--- hko<0, positiv nach oben!


      if(ie .lt. 2) then
c       write(6,*)'ie',ie
c       stop'ie out of range'
        ie =1
        veipo = 0.
        goto 999
      else if(ie .gt. iacnv(ih)) then
        ie =iacnv(ih)
        veipo = 0.
        goto 999
      else if(ix .lt. 1 ) then
c       write(6,*)'ix', ix
c       stop'ix out of range'
        ix=1
        vxipo= 1.e-6                ! ´jw vxipo!= 0
        goto 999
      else if(ix .gt. iacnl(ih)) then
       ix= iacnl(ih)
       vxipo= 0.
      end if
c      vxi1 = vxsi(ie,ix,ih)+abs((hkpact(ist,np,ih)-hko(ie,ix,ih)))
c       /e_p1m0(ie-1,ih)*(vxsi(ie-1,ix,ih)-vxsi(ie,ix,ih))
c      vxi2 = vxsi(ie,ix+1,ih)+abs((hkpact(ist,np,ih)-hko(ie,ix,ih)))
c       /e_p1m0(ie-1,ih)*(vxsi(ie-1,ix+1,ih)-vxsi(ie,ix+1,ih))
c      vei1 = veta(ie,ix,ih)+(skpact(ist,np,ih)-sko(ie,ix,ih))
c       /x_p1m0(ix,ih)*(veta(ie,ix+1,ih)-veta(ie,ix,ih))
c      vei2 = veta(ie-1,ix,ih)+(skpact(ist,np,ih)-sko(ie,ix,ih))
c       /x_p1m0(ix,ih)*(veta(ie-1,ix+1,ih)-veta(ie-1,ix,ih))
c      vxipo  = vxi1+(skpact(ist,np,ih)-sko(ie,ix,ih))
c      /x_p1m0(ix,ih)*(vxi2-vxi1)
c      veipo = vei1+abs(hkpact(ist,np,ih)- hko(ie,ix,ih))
c       /e_p1m0(ie-1,ih)*(vei2 -vei1)

      if( mak_an(ie,ix)) then
       vxi1 = vxsi(ie,ix,ih)+abs((hkpact(ist,np,ih)-hko(ie,ix,ih)))
     &  /(hko(ie,ix,ih)-hko(ie-1,ix,ih))
     &   *(vxsi(ie-1,ix,ih)-vxsi(ie,ix,ih))
       vxi2 = vxsi(ie,ix+1,ih)+abs((hkpact(ist,np,ih)-
     &  hko(ie,ix+1,ih)))/(hko(ie,ix+1,ih)-hko(ie-1,ix+1,ih))
     &  *(vxsi(ie-1,ix+1,ih)-vxsi(ie,ix+1,ih))
       if (skpact(ist,np,ih)-sko(ie,ix,ih) .le. 0.5*(sko(ie,ix+1,ih)
     &  -sko(ie,ix,ih))) then
         vei1 = veta(ie,ix,ih)
         vei2 = veta(ie-1,ix,ih)
       else if(skpact(ist,np,ih)-sko(ie,ix,ih) .gt. 0.5*
     &   (sko(ie,ix+1,ih)-sko(ie,ix,ih))) then
         vei1 = veta(ie,ix+1,ih)
         vei2 = veta(ie-1,ix+1,ih)
       end if
c       vei1 = veta(ie,ix+1,ih)+(skpact(ist,np,ih)-sko(ie,ix,ih))
c     &      /(sko(ie,ix+1,ih)-sko(ie,ix,ih))
c     &      *(veta(ie,ix+1,ih)-veta(ie,ix,ih))
c           vei2 = veta(ie-1,ix,ih)+(skpact(ist,np,ih)-sko(ie-1,ix,ih))
c     &      /(sko(ie-1,ix+1,ih)-sko(ie-1,ix,ih))
c     &      *(veta(ie-1,ix+1,ih)-veta(ie-1,ix,ih))
       vxipo  = vxi1+(skpact(ist,np,ih)-sko(ie,ix,ih))
     & /(sko(ie,ix+1,ih)-sko(ie,ix,ih))*(vxi2-vxi1)
       veipo = vei1+abs(hkpact(ist,np,ih)- hko(ie,ix,ih))
     &  /(hko(ie,ix,ih)-hko(ie-1,ix,ih))*(vei2 -vei1)
      else
       vxi1 = vxsi(ie,ix,ih)+abs((hkpact(ist,np,ih)-hko(ie,ix,ih)))
     &  /(hko(ie,ix,ih)-hko(ie-1,ix,ih))
     &   *(vxsi(ie-1,ix,ih)-vxsi(ie,ix,ih))
       vxi2 = vxsi(ie,ix+1,ih)+abs((hkpact(ist,np,ih)-
     &  hko(ie,ix+1,ih)))/(hko(ie,ix+1,ih)-hko(ie-1,ix+1,ih))
     &  *(vxsi(ie-1,ix+1,ih)-vxsi(ie,ix+1,ih))
       vei1 = veta(ie,ix,ih)+(skpact(ist,np,ih)-sko(ie,ix,ih))
     &  /(sko(ie,ix+1,ih)-sko(ie,ix,ih))
     &  *(veta(ie,ix+1,ih)-veta(ie,ix,ih))
       vei2 = veta(ie-1,ix,ih)+(skpact(ist,np,ih)-sko(ie-1,ix,ih))
     &  /(sko(ie-1,ix+1,ih)-sko(ie-1,ix,ih))
     &  *(veta(ie-1,ix+1,ih)-veta(ie-1,ix,ih))
       vxipo  = vxi1+(skpact(ist,np,ih)-sko(ie,ix,ih))
     & /(sko(ie,ix+1,ih)-sko(ie,ix,ih))*(vxi2-vxi1)
       veipo = vei1+abs(hkpact(ist,np,ih)- hko(ie,ix,ih))
     &  /(hko(ie,ix,ih)-hko(ie-1,ix,ih))*(vei2 -vei1)
c           vxipo  = vxi1+(skpact(ist,np,ih)-sko(ie,ix,ih))
c     &     /(0.5*(sko(ie,ix+1,ih)-sko(ie,ix,ih))
c     &     +(sko(ie-1,ix+1,ih)-sko(ie-1,ix,ih)))
c     &     *(vxi2-vxi1)
c           veipo = vei1+abs(hkpact(ist,np,ih)- hko(ie,ix,ih))
c     &      /(0.5*(hko(ie,ix,ih)-hko(ie-1,ix,ih))
c     &     +(hko(ie,ix+1,ih)-hko(ie-1,ix+1,ih)))
c     &*(v ei2 -vei1)
c            write(6,*)'vei1, vei2',vei1,vei2
c            write(6,*)'hkpact, hko',hkpact(ist,np,ih),hko(ie,ix,ih)
      end if

 999  continue
      return
      end
