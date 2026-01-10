      subroutine koeff(ih,dt)
c-----------------------------------------------------------------------
c  Koeffizienten
c-----------------------------------------------------------------------
      include 'dim.inc'
      include 'hgfest.inc'
      include 'hgvari.inc'

      integer*4 iv,il,ih
      real*8 dt

      external calfak, hgnull
      external kinnen, koeffrb
      external ksenken
c      external wrfak

      do 100 iv = 1,iacnv(ih)
        do 110 il = 1,iacnl(ih)
          Fx_m1(iv,il) = 0.
          Fx_00(iv,il) = 0.
          Fx_p1(iv,il) = 0.
          Fe_m1(iv,il) = 0.
          Fe_00(iv,il) = 0.
          Fe_p1(iv,il) = 0.
          RS(iv,il) = 0.
          vorfak(iv,il)=dt/f_xsi(iv,il,ih)/f_eta(iv,il,ih)/wasska(iv,il)
  110   continue
  100 continue

      call hgnull(senk,ih)
      call calfak(ih)
      call kinnen(ih)
      call koeffrb(ih,dt)
      call ksenken(ih,dt)
c      call wrfak(ih)

      return
      end


      subroutine calfak(ih)
c-----------------------------------------------------------------------
c  Koeffizienten
c-----------------------------------------------------------------------
      include 'dim.inc'
      include 'hgfest.inc'
      include 'hgvari.inc'
      include 'soil.inc'

      integer*4 iv,il,ih
      integer*4 poshlp
      real*8 th_hlp, k_hlp, k_hlp1, k_hlp2
      real*8 k_th, fdf0, fdf1

      external k_th
c      external chk_ma
      intrinsic sqrt

c  Berechnung der mittleren Leitfaehigkeit gemaess ZURMUEHL (1994)

      do 200 iv = 1,iacnv(ih)
        do 210 il = 1,iacnl(ih)-1
          fdf0=f_eta(iv,il  ,ih)/f_xsi(iv,il  ,ih)
          fdf1=f_eta(iv,il+1,ih)/f_xsi(iv,il+1,ih)
          if (mm_xsi(iv,il,ih) .eq. 2) then
c  arithmetisches Mittel
            A_x(iv,il) =
     &        (durchl(iv,il  )*fdf0*kxx(iv,il  ,ih) +
     &         durchl(iv,il+1)*fdf1*kxx(iv,il+1,ih))
     &         / x_p1m0(il,ih)
            A2x(iv,il) =
     &        (durchl(iv,il  )*kxe(iv,il  ,ih) +
     &         durchl(iv,il+1)*kxe(iv,il+1,ih))
     &         / x_p1m0(il,ih)
          else
            if (mm_xsi(iv,il,ih) .eq. 1) then
              if (mak_an(iv,il) .or. mak_an(iv,il+1)) then
c  geometrisches Mittel
                k_hlp1=durchl(iv,il  )
                k_hlp2=durchl(iv,il+1)
              else
c  Leitfaehigkeit aus mittlerem Wassergehalt
                th_hlp= theta(iv,il  )* al_fak(iv,il,ih) +
     &                  theta(iv,il+1)* (1.-al_fak(iv,il,ih))
                poshlp=tabpos(iv,il,ih)
                k_hlp=k_th(iboden(iv,il,ih),th_hlp,poshlp)
                k_hlp1=k_hlp
                k_hlp2=k_hlp
c                call chk_ma(k_hlp1,iv,il  ,ih)
c                call chk_ma(k_hlp2,iv,il+1,ih)
              endif
            elseif (mm_xsi(iv,il,ih) .eq. 3) then
c  geometrisches Mittel
              k_hlp1=durchl(iv,il  )
              k_hlp2=durchl(iv,il+1)
            endif
c      if (k_hlp1 .lt. 0. .or. k_hlp2 .lt. 0) then
c       write(6,*) k_hlp1, k_hlp2, 'calfak'c
c	stop
c      else if(kxe(iv,il ,ih) .lt. 0. .or. kxe(iv,il+1,ih).lt.0) then 
c	 write(6,*) kxe(iv,il  ,ih),kxe(iv,il+1,ih), 'calfak'
c	stop
c      else if(fdf0 .lt. 0. .or. fdf1.lt.0) then 
c	 write(6,*) fdf0, fdf2, 'calfak'
c	stop
c      end if
            A_x(iv,il) = 2.*
     &        sqrt(k_hlp1*fdf0*kxx(iv,il  ,ih) *
     &             k_hlp2*fdf1*kxx(iv,il+1,ih))
     &             / x_p1m0(il,ih)
            !write(6,*) il, iv
           if(kxe(iv,il ,ih) .lt. 0. .or. kxe(iv,il+1,ih).lt.0) then 
          A2x(iv,il) = Sign(1.D0,kxe(iv,il,ih)*kxe(iv,il+1,ih))* 
     &	  2.*
     &        sqrt(k_hlp1*abs(kxe(iv,il  ,ih)) *
     &             k_hlp2*abs(kxe(iv,il+1,ih)))
     &             / x_p1m0(il,ih)
           else
		  A2x(iv,il) = 2.*
     &        sqrt(k_hlp1*kxe(iv,il  ,ih) *
     &             k_hlp2*kxe(iv,il+1,ih))
     &             / x_p1m0(il,ih)
           end if
		endif
  210   continue
  200 continue

      do 300 il = 1,iacnl(ih)
        do 310 iv = 1,iacnv(ih)-1
          fdf0=f_eta(iv  ,il,ih)/f_xsi(iv  ,il,ih)
          fdf1=f_eta(iv+1,il,ih)/f_xsi(iv+1,il,ih)
          if (mm_eta(iv,il,ih) .eq. 2) then
c  arithmetisches Mittel
            A_e(iv,il) =
     &        (durchl(iv  ,il)/fdf0*kee(iv  ,il,ih) +
     &         durchl(iv+1,il)/fdf1*kee(iv+1,il,ih))
     &         / e_p1m0(iv,ih)
            A2e(iv,il) =
     &        (durchl(iv  ,il)*kxe(iv  ,il,ih) +
     &         durchl(iv+1,il)*kxe(iv+1,il,ih))
     &         / e_p1m0(iv,ih)
          else
            if (mm_eta(iv,il,ih) .eq. 1) then
              if (mak_an(iv,il) .or. mak_an(iv+1,il)) then
c  geometrisches Mittel
                k_hlp1=durchl(iv  ,il)
                k_hlp2=durchl(iv+1,il)
              else
c  Leitfaehigkeit aus mittlerem Wassergehalt
                th_hlp= theta(iv  ,il)* av_fak(iv,il,ih) +
     &                  theta(iv+1,il)* (1.-av_fak(iv,il,ih))
                poshlp=tabpos(iv,il,ih)
                k_hlp=k_th(iboden(iv,il,ih),th_hlp,poshlp)
                k_hlp1=k_hlp
                k_hlp2=k_hlp
c                call chk_ma(k_hlp1,iv  ,il,ih)
c                call chk_ma(k_hlp2,iv+1,il,ih)
              endif
            elseif (mm_eta(iv,il,ih) .eq. 3) then
c  geometrisches Mittel
              k_hlp1=durchl(iv  ,il)
              k_hlp2=durchl(iv+1,il)
            endif
            A_e(iv,il) = 2.*
     &        sqrt(k_hlp1/fdf0*kee(iv  ,il,ih) *
     &             k_hlp2/fdf1*kee(iv+1,il,ih))
     &             / e_p1m0(iv,ih)
           if(kxe(iv,il ,ih) .lt. 0. .or. kxe(iv+1,il,ih).lt.0) then 
            A2e(iv,il) = Sign(1.D0,kxe(iv,il,ih)*kxe(iv+1,il,ih))*
     &		  2.*
     &        sqrt(k_hlp1*abs(kxe(iv  ,il,ih)) *
     &             k_hlp2*abs(kxe(iv+1,il,ih)))
     &             / e_p1m0(iv,ih)
           else
            A2e(iv,il) = 2.*
     &        sqrt(k_hlp1*kxe(iv  ,il,ih) *
     &             k_hlp2*kxe(iv+1,il,ih))
     &             / e_p1m0(iv,ih)

	     end if
          endif
  310   continue
  300 continue

      return
      end
