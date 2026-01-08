      subroutine expcal(ih)
	implicit none
c-----------------------------------------------------------------------
c  Hang: Loesung eines vollen expliziten Schritts (eta, xsi)
c-----------------------------------------------------------------------
      include 'dim.inc'
      include 'hgfest.inc'
      include 'hgvari.inc'

      integer*4 iv,il,ih

      do 100 iv = 1,iacnv(ih)
        do 110 il = 1,iacnl(ih)
          phineu(iv,il) =
     &     -RS(iv,il)+phialt(iv,il,ih)*(Fx_00(iv,il)+Fe_00(iv,il)+1.)
  110   continue
  100 continue
      do 200 iv = 1,iacnv(ih)
        do 210 il = 1,iacnl(ih)-1
          phineu(iv,il) =
     &      phineu(iv,il)+phialt(iv,il+1,ih)*Fx_p1(iv,il)
  210   continue
        do 220 il = 2,iacnl(ih)
          phineu(iv,il) =
     &      phineu(iv,il)+phialt(iv,il-1,ih)*Fx_m1(iv,il)
  220   continue
  200 continue
      do 300 il = 1,iacnl(ih)
        do 310 iv = 1,iacnv(ih)-1
          phineu(iv,il) =
     &      phineu(iv,il)+phialt(iv+1,il,ih)*Fe_p1(iv,il)
  310   continue
        do 320 iv = 2,iacnv(ih)
          phineu(iv,il) =
     &      phineu(iv,il)+phialt(iv-1,il,ih)*Fe_m1(iv,il)
  320   continue
  300 continue
      return
      end

cc      subroutine diffcal(ih,dtexp)
c-----------------------------------------------------------------------
c  Hang: Berechnung der Diffusionszahl (Stabilitaetskriterium fuer
c  explizites Differenzenverfahren
c-----------------------------------------------------------------------
cc      include 'dim.inc'
cc      include 'hgfest.inc'
cc      include 'hgvari.inc'
cc
cc      integer*4 iv,il,ih
cc      real*8 dtexp
cc
cc      dtexp = 1.e20
cc      do 100 iv = 1,iacnv(ih)
cc        do 110 il = 1,iacnl(ih)
cc          diffus(iv,il) =-xyxpy(iv,il,ih)*wasska(iv,il)/durchl(iv,il)/2.
cc          if (diffus(iv,il) .lt. dtexp) dtexp = diffus(iv,il)
cc  110   continue
cc  100 continue
cc
cc      return
cc      end

      subroutine ee_ix(philoc,ih,expant,omx)
      implicit none
c-----------------------------------------------------------------------
c  Hang: Loesung eines ADI Halbschritts: explizit eta, implizit xsi
c-----------------------------------------------------------------------
      include 'dim.inc'
      include 'hgfest.inc'
      include 'hgvari.inc'

      integer*4 iv,il,ih
      real*8 A(maxnl),B(maxnl),C(maxnl)
      real*8 R(maxnl),L(maxnl),H(maxnl)
      real*8 philoc, expant, omx
      dimension philoc(maxnv,maxnl)

      external tridig

      do 100 iv = 1,iacnv(ih)
        do 110 il = 1,iacnl(ih)
          RS(iv,il) = RS(iv,il)-philoc(iv,il)*(Fe_00(iv,il)+expant)
  110   continue
  100 continue
      do 200 il = 1,iacnl(ih)
        do 210 iv = 1,iacnv(ih)-1
          RS(iv,il) = RS(iv,il)-philoc(iv+1,il)*Fe_p1(iv,il)
  210   continue
        do 220 iv = 2,iacnv(ih)
          RS(iv,il) = RS(iv,il)-philoc(iv-1,il)*Fe_m1(iv,il)
  220   continue
  200 continue
      do 300 iv = 1,iacnv(ih)
        do 310 il = 1,iacnl(ih)
          A(il) = Fx_m1(iv,il)
          B(il) = Fx_00(iv,il)-1.+omx
          C(il) = Fx_p1(iv,il)
          R(il) = RS(iv,il)
  310   continue
        call tridig(A,B,C,L,R,iacnl(ih),H)
        do 320 il = 1,iacnl(ih)
          philoc(iv,il) = L(il)
  320   continue
  300 continue
      return
      end

      subroutine ex_ie(philoc,ih,expant,ome)
      implicit none
c-----------------------------------------------------------------------
c  Hang: Loesung eines ADI Halbschritts: explizit xsi, implizit eta
c-----------------------------------------------------------------------
      include 'dim.inc'
      include 'hgfest.inc'
      include 'hgvari.inc'

      integer*4 iv,il,ih
      real*8 A(maxnv),B(maxnv),C(maxnv)
      real*8 R(maxnv),L(maxnv),H(maxnv)
      real*8 philoc, expant, ome
      dimension philoc(maxnv,maxnl)

      external tridig

      do 100 iv = 1,iacnv(ih)
        do 110 il = 1,iacnl(ih)
          RS(iv,il)=RS(iv,il)-philoc(iv,il)*(Fx_00(iv,il)+expant)
  110   continue
  100 continue
      do 200 iv = 1,iacnv(ih)
        do 210 il = 1,iacnl(ih)-1
          RS(iv,il)=RS(iv,il)-philoc(iv,il+1)*Fx_p1(iv,il)
  210   continue
        do 220 il = 2,iacnl(ih)
          RS(iv,il)=RS(iv,il)-philoc(iv,il-1)*Fx_m1(iv,il)
  220   continue
  200 continue
      do 300 il = 1,iacnl(ih)
        do 310 iv = 1,iacnv(ih)
          A(iv) = Fe_m1(iv,il)
          B(iv) = Fe_00(iv,il)-1.+ome
          C(iv) = Fe_p1(iv,il)
          R(iv) = RS(iv,il)
  310   continue
        call tridig(A,B,C,L,R,iacnv(ih),H)
        do 320 iv = 1,iacnv(ih)
          philoc(iv,il) = L(iv)
  320   continue
  300 continue
      return
      end

      subroutine tridig (a,b,c,u,r,n,gam)
	implicit none
c-----------------------------------------------------------------------
c     Loesung einer Tridiagonalmatrix
c
c     | b  c  -  -  - ..  - |  |u|   | r |         >
c     | a  b  c  -  - ..  - |  |u|   | r |         |
c     | -  a  b  c  - ..  - |  |u|   | r |         | n (Laenge)
c     | -  .  .  .  .  .  - |  |.|   | r |         |
c     | -  -  -  .  a  b  c |  |.| = | r |         |
c     | -  -  -  -  -  a  b |  |u|   | r |         >
c
c-----------------------------------------------------------------------

      include 'dim.inc'

      integer*4 i, n
      real*8 a(*), b(*), c(*), u(*), r(*)
      real*8 bet, gam(*)

      bet = b(1)
      u(1) = r(1)/bet

      do 10 i=2,n
         gam(i) = c(i-1)/bet
         bet   = b(i) - a(i) * gam(i)
         u(i)  = (r(i)-a(i)*u(i-1))/bet
   10 continue

      do 20 i=n-1,1,-1
         u(i) = u(i)-gam(i+1)*u(i+1)
   20 continue
      return
      end

      subroutine pic_it(ih)
	implicit none
c-----------------------------------------------------------------------
c  Hang: Erzeugen der iterationsfaehigen Gestalt
c        fuer die Durchfuehrung der Picarditeration
c-----------------------------------------------------------------------
      include 'dim.inc'
      include 'hgfest.inc'
      include 'hgvari.inc'

      integer*4 iv,il,ih

      do 100 iv = 1,iacnv(ih)
        do 110 il = 1,iacnl(ih)
          RS(iv,il)=RS(iv,il)-phineu(iv,il)*(Fx_00(iv,il)+Fe_00(iv,il))
     &              - (Theta(iv,il)-Th_alt(iv,il))/wasska(iv,il)
  110   continue
  100 continue
      do 200 iv = 1,iacnv(ih)
        do 210 il = 1,iacnl(ih)-1
          RS(iv,il)=RS(iv,il)-phineu(iv,il+1)*Fx_p1(iv,il)
  210   continue
        do 220 il = 2,iacnl(ih)
          RS(iv,il)=RS(iv,il)-phineu(iv,il-1)*Fx_m1(iv,il)
  220   continue
  200 continue
      do 300 il = 1,iacnl(ih)
        do 310 iv = 1,iacnv(ih)-1
          RS(iv,il) = RS(iv,il)-phineu(iv+1,il)*Fe_p1(iv,il)
  310   continue
        do 320 iv = 2,iacnv(ih)
          RS(iv,il) = RS(iv,il)-phineu(iv-1,il)*Fe_m1(iv,il)
  320   continue
  300 continue

      return
      end

      subroutine rand_fl(ih)
	implicit none
C-----------------------------------------------------------------------
C
C-----------------------------------------------------------------------
      include 'dim.inc'
      include 'hgbdry.inc'
      include 'hgfest.inc'
      include 'hgvari.inc'

      integer*4 iv,il,ih


c-----------------------------------------------------------------------
c... untere und obere (innere) Reihe
      do 120 il = 2,iacnl(ih)-1

c	unten
        iv=1
        if (vorz_u(il,ih) .lt. 0) then
          Fx_p1(iv,il) = -  A_x(iv,il)*vorfak(iv,il)/x_p1m1(il-1,ih)
     &                      *fbrup(il,ih)
          Fx_00(iv,il) =   ( A_x(iv,il)*fbrup(il,ih)
     &                      +A_x(iv,il-1)*fbrlow(il,ih))
     &                      *vorfak(iv,il)/x_p1m1(il-1,ih)
          Fx_m1(iv,il) = -  A_x(iv,il-1)*vorfak(iv,il)/x_p1m1(il-1,ih)
     &                      *fbrlow(il,ih)
          Fe_p1(iv,il) = - A_e(iv,il)*vorfak(iv,il)/e_p1m0(iv,ih)
          Fe_00(iv,il) = - Fe_p1(iv,il)
          rfl_u(il) = (
     &     Fx_p1(iv,il)                *phineu(iv  ,il+1)     +
     &     Fx_m1(iv,il)                *phineu(iv  ,il-1)     +
     &     Fe_p1(iv,il)                *phineu(iv+1,il  )     +
     &    (Fx_00(iv,il)+Fe_00(iv,il)-1)*phineu(iv  ,il  )     +
     &                                  phialt(iv  ,il  ,ih) )*
     &     e_p1m0(iv,ih)/(2.*f_xsi(iv,il,ih)*vorfak(iv,il))
        endif
        if (lueb_u(il)) then
          ueb_u(il) = qu_pot(il)-rfl_u(il)
        else
          ueb_u(il) = 0.
        endif

c	oben
        iv=iacnv(ih)
        if (vorz_o(il,ih) .lt. 0) then
          Fx_p1(iv,il) = -  A_x(iv,il)*vorfak(iv,il)/x_p1m1(il-1,ih)
     &                      *fbrup(il,ih)
          Fx_00(iv,il) =   ( A_x(iv,il)*fbrup(il,ih)
     &                      +A_x(iv,il-1)*fbrlow(il,ih))
     &                      *vorfak(iv,il)/x_p1m1(il-1,ih)
          Fx_m1(iv,il) = -  A_x(iv,il-1)*vorfak(iv,il)/x_p1m1(il-1,ih)
     &                      *fbrlow(il,ih)
          Fe_m1(iv,il) = - A_e(iv-1,il)*vorfak(iv,il)/e_p1m0(iv-1,ih)
          Fe_00(iv,il) = - Fe_m1(iv,il)
          rfl_o(il) = (
     &     Fx_p1(iv,il)                *phineu(iv  ,il+1)     +
     &     Fx_m1(iv,il)                *phineu(iv  ,il-1)     +
     &     Fe_m1(iv,il)                *phineu(iv-1,il  )     +
     &    (Fx_00(iv,il)+Fe_00(iv,il)-1)*phineu(iv  ,il  )     +
     &                                  phialt(iv  ,il  ,ih) )*
     &     e_p1m0(iv-1,ih)/(-2.*f_xsi(iv,il,ih)*vorfak(iv,il))
        endif
        if (lueb_o(il)) then
          ueb_o(il) = qo_pot(il)-rfl_o(il)
        else
          ueb_o(il) = 0.
        endif
  120 continue
c-----------------------------------------------------------------------
c... linke und rechte (innere) Reihe
      do 220 iv = 2,iacnv(ih)-1
        il=1
        if (vorz_l(iv,ih) .lt. 0) then
          Fe_p1(iv,il) = -  A_e(iv,il)*vorfak(iv,il)/e_p1m1(iv-1,ih)
          Fe_00(iv,il) =   (A_e(iv,il)+A_e(iv-1,il))*vorfak(iv,il)/
     &                      e_p1m1(iv-1,ih)
          Fe_m1(iv,il) = -  A_e(iv-1,il)*vorfak(iv,il)/e_p1m1(iv-1,ih)
          Fx_p1(iv,il) = - A_x(iv,il)*vorfak(iv,il)/x_p1m0(il,ih)
     &                      *fbrup(il,ih)
          Fx_00(iv,il) = - Fx_p1(iv,il)
          rfl_l(iv) = (
     &     Fe_p1(iv,il)                *phineu(iv+1,il  )     +
     &     Fe_m1(iv,il)                *phineu(iv-1,il  )     +
     &     Fx_p1(iv,il)                *phineu(iv  ,il+1)     +
     &    (Fx_00(iv,il)+Fe_00(iv,il)-1)*phineu(iv  ,il  )     +
     &                                  phialt(iv  ,il  ,ih) )*
     &     x_p1m0(il,ih)/(2.*f_eta(iv,il,ih)*vorfak(iv,il))
        endif
        if (lueb_l(iv)) then
          ueb_l(iv) = ql_pot(iv)-rfl_l(iv)
        else
          ueb_l(iv) = 0.
        endif

        il=iacnl(ih)
        if (vorz_r(iv,ih) .lt. 0) then
          Fe_p1(iv,il) = -  A_e(iv,il)*vorfak(iv,il)/e_p1m1(iv-1,ih)
          Fe_00(iv,il) =   (A_e(iv,il)+A_e(iv-1,il))*vorfak(iv,il)/
     &                      e_p1m1(iv-1,ih)
          Fe_m1(iv,il) = -  A_e(iv-1,il)*vorfak(iv,il)/e_p1m1(iv-1,ih)
          Fx_m1(iv,il) = - A_x(iv,il-1)*vorfak(iv,il)/x_p1m0(il-1,ih)
     &                      *fbrlow(il,ih)
          Fx_00(iv,il) = - Fx_m1(iv,il)
          rfl_r(iv) = (
     &      Fe_p1(iv,il)                *phineu(iv+1,il  )     +
     &      Fe_m1(iv,il)                *phineu(iv-1,il  )     +
     &      Fx_m1(iv,il)                *phineu(iv  ,il-1)     +
     &     (Fx_00(iv,il)+Fe_00(iv,il)-1)*phineu(iv  ,il  )     +
     &                                  phialt(iv  ,il  ,ih) )*
     &      x_p1m0(il-1,ih)/(-2.*f_eta(iv,il,ih)*vorfak(iv,il))
        endif
        if (lueb_r(iv)) then
          ueb_r(iv) = qr_pot(iv)-rfl_r(iv)
        else
          ueb_r(iv) = 0.
        endif
  220 continue

c-----------------------------------------------------------------------
c.... Ecke unten links
        il=1
        iv=1
        if ((vorz_u(il,ih) .lt. 0) .or. (vorz_l(iv,ih) .lt. 0)) then
          Fe_p1(iv,il) = - A_e(iv,il)*vorfak(iv,il)/e_p1m0(iv,ih)
          Fe_00(iv,il) = - Fe_p1(iv,il)
          Fx_p1(iv,il) = - A_x(iv,il)*vorfak(iv,il)/x_p1m0(il,ih)
     &                      *fbrup(il,ih)
          Fx_00(iv,il) = - Fx_p1(iv,il)

          if (vorz_u(il,ih)*vorz_l(iv,ih) .lt. 0) then
          if (vorz_l(iv,ih) .lt. 0) then
           rfl_l(iv) = (
     &     Fe_p1(iv,il)                *phineu(iv+1,il  )           -
     &     2.*f_xsi(iv,il,ih)*rfl_u(il)*vorfak(iv,il)/e_p1m0(iv,ih) +
     &     Fx_p1(iv,il)                *phineu(iv  ,il+1)           +
     &    (Fx_00(iv,il)+Fe_00(iv,il)-1)*phineu(iv  ,il  )           +
     &                                  phialt(iv  ,il  ,ih)       )*
     &     x_p1m0(il,ih)/(2.*f_eta(iv,il,ih)*vorfak(iv,il))
          endif

          if (vorz_u(il,ih) .lt. 0) then
           rfl_u(il) = (
     &     Fx_p1(iv,il)                *phineu(iv  ,il+1)           -
     &     2.*f_eta(iv,il,ih)*rfl_l(iv)*vorfak(iv,il)/x_p1m0(il,ih) +
     &     Fe_p1(iv,il)                *phineu(iv+1,il  )           +
     &    (Fx_00(iv,il)+Fe_00(iv,il)-1)*phineu(iv  ,il  )           +
     &                                  phialt(iv  ,il  ,ih)       )*
     &     e_p1m0(iv,ih)/(2.*f_xsi(iv,il,ih)*vorfak(iv,il))
          endif
          else
           rfl_u(il) = (
     &     Fx_p1(iv,il)                *phineu(iv  ,il+1)           +
     &     Fe_p1(iv,il)                *phineu(iv+1,il  )           +
     &    (Fx_00(iv,il)+Fe_00(iv,il)-1)*phineu(iv  ,il  )           +
     &                                  phialt(iv  ,il  ,ih)       )*
     &     e_p1m0(iv,ih)/(4.*f_xsi(iv,il,ih)*vorfak(iv,il))
           rfl_l(iv) = rfl_u(il)
          endif
        endif
        if (lueb_u(il)) then
          ueb_u(il) = qu_pot(il)-rfl_u(il)
        else
          ueb_u(il) = 0.
        endif
        if (lueb_l(iv)) then
          ueb_l(iv) = ql_pot(iv)-rfl_l(iv)
        else
          ueb_l(iv) = 0.
        endif

c-----------------------------------------------------------------------
c.... Ecke unten rechts
        il=iacnl(ih)
        iv=1
        if ((vorz_u(il,ih) .lt. 0) .or. (vorz_r(iv,ih) .lt. 0)) then
          Fe_p1(iv,il) = - A_e(iv,il)*vorfak(iv,il)/e_p1m0(iv,ih)
          Fe_00(iv,il) = - Fe_p1(iv,il)
          Fx_m1(iv,il) = - A_x(iv,il-1)*vorfak(iv,il)/x_p1m0(il-1,ih)
     &                      *fbrlow(il,ih)
          Fx_00(iv,il) = - Fx_m1(iv,il)

          if (vorz_u(il,ih)*vorz_r(iv,ih) .lt. 0) then
          if (vorz_r(iv,ih) .lt. 0) then
           rfl_r(iv) = (
     &     Fe_p1(iv,il)                *phineu(iv+1,il  )           -
     &     2.*f_xsi(iv,il,ih)*rfl_u(il)*vorfak(iv,il)/e_p1m0(iv,ih) +
     &     Fx_m1(iv,il)                *phineu(iv  ,il-1)           +
     &    (Fx_00(iv,il)+Fe_00(iv,il)-1)*phineu(iv  ,il  )           +
     &                                  phialt(iv  ,il  ,ih)       )*
     &     x_p1m0(il-1,ih)/(-2.*f_eta(iv,il,ih)*vorfak(iv,il))
          endif

          if (vorz_u(il,ih) .lt. 0) then
           rfl_u(il) = (
     &     2.*f_eta(iv,il,ih)*rfl_r(iv)*vorfak(iv,il)/x_p1m0(il-1,ih) +
     &     Fx_m1(iv,il)                *phineu(iv  ,il-1)             +
     &     Fe_p1(iv,il)                *phineu(iv+1,il  )             +
     &    (Fx_00(iv,il)+Fe_00(iv,il)-1)*phineu(iv  ,il  )             +
     &                                  phialt(iv  ,il  ,ih)         )*
     &     e_p1m0(iv,ih)/(2.*f_xsi(iv,il,ih)*vorfak(iv,il))
          endif
          else
           rfl_u(il) = (
     &     Fx_m1(iv,il)                *phineu(iv  ,il-1)             +
     &     Fe_p1(iv,il)                *phineu(iv+1,il  )             +
     &    (Fx_00(iv,il)+Fe_00(iv,il)-1)*phineu(iv  ,il  )             +
     &                                  phialt(iv  ,il  ,ih)         )*
     &     e_p1m0(iv,ih)/(4.*f_xsi(iv,il,ih)*vorfak(iv,il))
           rfl_r(iv) = -rfl_u(il)
          endif
        endif
        if (lueb_u(il)) then
          ueb_u(il) = qu_pot(il)-rfl_u(il)
        else
          ueb_u(il) = 0.
        endif
        if (lueb_r(iv)) then
          ueb_r(iv) = qr_pot(iv)-rfl_r(iv)
        else
          ueb_r(iv) = 0.
        endif
c-----------------------------------------------------------------------
c.... Ecke oben links
        il=1
        iv=iacnv(ih)
        if ((vorz_o(il,ih) .lt. 0) .or. (vorz_l(iv,ih) .lt. 0)) then
          Fe_m1(iv,il) = - A_e(iv-1,il)*vorfak(iv,il)/e_p1m0(iv-1,ih)
          Fe_00(iv,il) = - Fe_m1(iv,il)
          Fx_p1(iv,il) = - A_x(iv,il)*vorfak(iv,il)/x_p1m0(il,ih)
     &                      *fbrup(il,ih)
          Fx_00(iv,il) = - Fx_p1(iv,il)

          if (vorz_o(il,ih)*vorz_l(iv,ih) .lt. 0) then
          if (vorz_l(iv,ih) .lt. 0) then
           rfl_l(iv) = (
     &     2.*f_xsi(iv,il,ih)*rfl_o(il)*vorfak(iv,il)/e_p1m0(iv-1,ih) +
     &     Fe_m1(iv,il)                *phineu(iv-1,il  )             +
     &     Fx_p1(iv,il)                *phineu(iv  ,il+1)             +
     &    (Fx_00(iv,il)+Fe_00(iv,il)-1)*phineu(iv  ,il  )             +
     &                                  phialt(iv  ,il  ,ih)         )*
     &     x_p1m0(il,ih)/(2.*f_eta(iv,il,ih)*vorfak(iv,il))
          endif

          if (vorz_o(il,ih) .lt. 0) then
           rfl_o(il) = (
     &     Fx_p1(iv,il)                *phineu(iv  ,il+1)           +
     &     Fe_m1(iv,il)                *phineu(iv-1,il  )           -
     &     2.*f_eta(iv,il,ih)*rfl_l(iv)*vorfak(iv,il)/x_p1m0(il,ih) +
     &    (Fx_00(iv,il)+Fe_00(iv,il)-1)*phineu(iv  ,il  )           +
     &                                  phialt(iv  ,il  ,ih)       )*
     &     e_p1m0(iv-1,ih)/(-2.*f_xsi(iv,il,ih)*vorfak(iv,il))
          endif
          else
           rfl_o(il) = (
     &     Fx_p1(iv,il)                *phineu(iv  ,il+1)           +
     &     Fe_m1(iv,il)                *phineu(iv-1,il  )           +
     &    (Fx_00(iv,il)+Fe_00(iv,il)-1)*phineu(iv  ,il  )           +
     &                                  phialt(iv  ,il  ,ih)       )*
     &     e_p1m0(iv-1,ih)/(-4.*f_xsi(iv,il,ih)*vorfak(iv,il))
           rfl_l(iv) = -rfl_o(il)
          endif
        endif
        if (lueb_o(il)) then
          ueb_o(il) = qo_pot(il)-rfl_o(il)
        else
          ueb_o(il) = 0.
        endif
        if (lueb_l(iv)) then
          ueb_l(iv) = ql_pot(iv)-rfl_l(iv)
        else
          ueb_l(iv) = 0.
        endif
c-----------------------------------------------------------------------
c.... Ecke oben rechts
        il=iacnl(ih)
        iv=iacnv(ih)
        if ((vorz_o(il,ih) .lt. 0) .or. (vorz_r(iv,ih) .lt. 0)) then
          Fe_m1(iv,il) = - A_e(iv-1,il)*vorfak(iv,il)/e_p1m0(iv-1,ih)
          Fe_00(iv,il) = - Fe_m1(iv,il)
          Fx_m1(iv,il) = - A_x(iv,il-1)*vorfak(iv,il)/x_p1m0(il-1,ih)
     &                      *fbrlow(il,ih)
          Fx_00(iv,il) = - Fx_m1(iv,il)

          if (vorz_o(il,ih)*vorz_r(iv,ih) .lt. 0) then
          if (vorz_r(iv,ih) .lt. 0) then
          rfl_r(iv) = (
     &     2.*f_xsi(iv,il,ih)*rfl_o(il)*vorfak(iv,il)/e_p1m0(iv-1,ih) +
     &     Fe_m1(iv,il)                *phineu(iv-1,il  )             +
     &     Fx_m1(iv,il)                *phineu(iv  ,il-1)             +
     &    (Fx_00(iv,il)+Fe_00(iv,il)-1)*phineu(iv  ,il  )             +
     &                                  phialt(iv  ,il  ,ih)         )*
     &     x_p1m0(il-1,ih)/(-2.*f_eta(iv,il,ih)*vorfak(iv,il))
          endif

          if (vorz_o(il,ih) .lt. 0) then
           rfl_o(il) = (
     &     2.*f_eta(iv,il,ih)*rfl_r(iv)*vorfak(iv,il)/x_p1m0(il-1,ih) +
     &     Fx_m1(iv,il)                *phineu(iv  ,il-1)             +
     &     Fe_m1(iv,il)                *phineu(iv-1,il  )             +
     &    (Fx_00(iv,il)+Fe_00(iv,il)-1)*phineu(iv  ,il  )             +
     &                                  phialt(iv  ,il  ,ih)         )*
     &     e_p1m0(iv-1,ih)/(-2.*f_xsi(iv,il,ih)*vorfak(iv,il))
          endif
          else
           rfl_o(il) = (
     &     Fx_m1(iv,il)                *phineu(iv  ,il-1)             +
     &     Fe_m1(iv,il)                *phineu(iv-1,il  )             +
     &    (Fx_00(iv,il)+Fe_00(iv,il)-1)*phineu(iv  ,il  )             +
     &                                  phialt(iv  ,il  ,ih)         )*
     &     e_p1m0(iv-1,ih)/(-4.*f_xsi(iv,il,ih)*vorfak(iv,il))
           rfl_r(iv) = rfl_o(il)
          endif
        endif
        if (lueb_o(il)) then
          ueb_o(il) = qo_pot(il)-rfl_o(il)
        else
          ueb_o(il) = 0.
        endif
        if (lueb_r(iv)) then
          ueb_r(iv) = qr_pot(iv)-rfl_r(iv)
        else
          ueb_r(iv) = 0.
        endif

c-----------------------------------------------------------------------
c.... Senken (nur an inneren Punkten)
      do 100 il = 2,iacnl(ih)-1
        do 200 iv = 2,iacnv(ih)-1
        if (vorz_s(iv,il,ih) .lt. 0) then
          Fx_p1(iv,il) = -  A_x(iv,il)*vorfak(iv,il)/x_p1m1(il-1,ih)
     &                      *fbrup(il,ih)
          Fx_00(iv,il) =   ( A_x(iv,il)*fbrup(il,ih)
     &                      +A_x(iv,il-1)*fbrlow(il,ih))
     &                      *vorfak(iv,il)/x_p1m1(il-1,ih)
          Fx_m1(iv,il) = -  A_x(iv,il-1)*vorfak(iv,il)/x_p1m1(il-1,ih)
     &                      *fbrlow(il,ih)
          Fe_p1(iv,il) = -  A_e(iv,il)*vorfak(iv,il)/e_p1m1(iv-1,ih)
          Fe_00(iv,il) =   (A_e(iv,il)+A_e(iv-1,il))*vorfak(iv,il)/
     &                      e_p1m1(iv-1,ih)
          Fe_m1(iv,il) = -  A_e(iv-1,il)*vorfak(iv,il)/e_p1m1(iv-1,ih)
          senk(iv,il) = -(
     &     Fe_p1(iv,il)                *phineu(iv+1,il  )     +
     &     Fe_m1(iv,il)                *phineu(iv-1,il  )     +
     &     Fx_p1(iv,il)                *phineu(iv  ,il+1)     +
     &     Fx_m1(iv,il)                *phineu(iv  ,il-1)     +
     &    (Fx_00(iv,il)+Fe_00(iv,il)-1)*phineu(iv  ,il  )     +
     &                                  phialt(iv  ,il  ,ih) )/
     &     vorfak(iv,il)
        !if(senk(iv,il) .lt. 0.) then
	  !write(6,*) iv, il
	  !stop
	 ! endif
        endif
       
        if (lueb_s(iv,il)) then
          sueb(iv,il) = qs_pot(iv,il)-senk(iv,il)
        else
          sueb(iv,il) = 0.
        endif
  200   continue
  100 continue

      return
      end


      subroutine chko_rb(ih,rbchg,rblog)
	implicit none
c-----------------------------------------------------------------------
      include 'dim.inc'
      include 'hgbdry.inc'
      include 'hgfest.inc'
      include 'hgvari.inc'

      integer*4 iv, il, ih, irblog
      logical rbchg, ltest
      character*80 rblog

      intrinsic abs

      rbchg = .false.
      write(rblog,111)
  111 format(80(' '))
      irblog=1

      do 100 iv=1,iacnv(ih)
c ...rechts
        il=iacnl(ih)
        ltest=.false.
        if (irb_r(iv,ih) .gt. 0) then
          if (abs(irbtyp(1,irb_r(iv,ih))) .eq. 11) then
            ltest=.true.
          endif
          if (abs(irbtyp(1,irb_r(iv,ih))) .eq. 10) then
            ltest=.true.
          endif
        elseif (irb_r(iv,ih) .eq. -10) then
          ltest=.true.
        elseif (irb_r(iv,ih) .eq. -99) then
          ltest=.true.
        endif
        if (ltest) then
c-- wenn psi = psi_pot
          if (vorz_r(iv,ih) .eq. -1) then
            lueb_r(iv) = .true.
            if ( rfl_r(iv) .lt. qr_pot(iv)) then
              rbchg = .true.
              if (irblog .le. 77) then
                write(rblog(irblog+1:irblog+1),'(a)') 'r'
                write(rblog(irblog+2:irblog+3),'(i2)') iv
              endif
              irblog=irblog+3
              vorz_r(iv,ih) = 1
              lueb_r(iv) = .false.
            endif
c-- wenn q = q_pot
          elseif (vorz_r(iv,ih) .eq.  1) then
            lueb_r(iv) = .false.
            if (phineu(iv,il) .gt. pr_pot(iv)) then
              rbchg = .true.
              if (irblog .le. 77) then
                write(rblog(irblog+1:irblog+1),'(a)') 'R'
                write(rblog(irblog+2:irblog+3),'(i2)') iv
              endif
              irblog=irblog+3
              vorz_r(iv,ih) = -1
              lueb_r(iv) = .true.
            endif
          endif
        else
          lueb_r(iv) = .false.
        endif
c ...links
        il=1
        ltest=.false.
        if (irb_l(iv,ih) .gt. 0) then
          if (abs(irbtyp(1,irb_l(iv,ih))) .eq. 11) then
            ltest=.true.
          endif
          if (abs(irbtyp(1,irb_l(iv,ih))) .eq. 10) then
            ltest=.true.
          endif
        elseif (irb_l(iv,ih) .eq. -10) then
          ltest=.true.
        endif
        if (ltest) then
c-- wenn psi = psi_pot
          if (vorz_l(iv,ih) .eq. -1) then
            lueb_l(iv) = .true.
            if ( rfl_l(iv) .gt. ql_pot(iv)) then
              rbchg = .true.
              if (irblog .le. 77) then
                write(rblog(irblog+1:irblog+1),'(a)') 'l'
                write(rblog(irblog+2:irblog+3),'(i2)') iv
              endif
              irblog=irblog+3
              vorz_l(iv,ih) = 1
              lueb_l(iv) = .false.
            endif
c-- wenn q = q_pot
          elseif (vorz_l(iv,ih) .eq.  1) then
            lueb_l(iv) = .false.
            if (phineu(iv,il) .gt. pl_pot(iv)) then
              rbchg = .true.
              if (irblog .le. 77) then
                write(rblog(irblog+1:irblog+1),'(a)') 'L'
                write(rblog(irblog+2:irblog+3),'(i2)') iv
              endif
              irblog=irblog+3
              vorz_l(iv,ih) = -1
              lueb_l(iv) = .true.
            endif
          endif
        else
          lueb_l(iv) = .false.
        endif
 100  continue

      do 200 il=1,iacnl(ih)
c ...oben
        iv=iacnv(ih)
        ltest=.false.
        if (irb_o(il,ih) .gt. 0) then
          if (abs(irbtyp(1,irb_o(il,ih))) .eq. 11) then
            ltest=.true.
          endif
          if (abs(irbtyp(1,irb_o(il,ih))) .eq. 10) then
            ltest=.true.
          endif
        elseif (irb_o(il,ih) .eq. -10) then
          ltest=.true.
        elseif (irb_o(il,ih) .eq. -99) then
          ltest=.true.
        endif
        if (ltest) then
c-- wenn psi = psi_pot
          if (vorz_o(il,ih) .eq. -1) then
            lueb_o(il) = .true.
            if ( rfl_o(il) .lt. qo_pot(il)) then
              rbchg = .true.
              if (irblog .le. 77) then
                write(rblog(irblog+1:irblog+1),'(a)') 'o'
                write(rblog(irblog+2:irblog+3),'(i2)') il
              endif
              irblog=irblog+3
              vorz_o(il,ih) = 1
              lueb_o(il) = .false.
            endif
c-- wenn q = q_pot
          elseif (vorz_o(il,ih) .eq.  1) then
            lueb_o(il) = .false.
            if (phineu(iv,il) .ge. hko(iv,il,ih)) then		
c			.OR. yoben(il) .gt. 1e-4		! jw Test

              rbchg = .true.
              if (irblog .le. 77) then
                write(rblog(irblog+1:irblog+1),'(a)') 'O'
                write(rblog(irblog+2:irblog+3),'(i2)') il
              endif
              irblog=irblog+3
              vorz_o(il,ih) = -1
              lueb_o(il) = .true.
            endif
          endif
        else
          lueb_o(il) = .false.
        endif
c ...unten
        iv=1
        ltest=.false.
        if (irb_u(il,ih) .gt. 0) then
          if (abs(irbtyp(1,irb_u(il,ih))) .eq. 11) then
            ltest=.true.
          endif
          if (abs(irbtyp(1,irb_u(il,ih))) .eq. 10) then
            ltest=.true.
          endif
        elseif (irb_u(il,ih) .eq. -10) then
          ltest=.true.
        endif
        if (ltest) then
c-- wenn psi = psi_pot
          if (vorz_u(il,ih) .eq. -1) then
            lueb_u(il) = .true.
            if ( rfl_u(il) .gt. qu_pot(il)) then
              rbchg = .true.
              if (irblog .le. 77) then
                write(rblog(irblog+1:irblog+1),'(a)') 'u'
                write(rblog(irblog+2:irblog+3),'(i2)') il
              endif
              irblog=irblog+3
              vorz_u(il,ih) = 1
              lueb_u(il) = .false.
            endif
c-- wenn q = q_pot
          elseif (vorz_u(il,ih) .eq.  1) then
            lueb_u(il) = .false.
            if (phineu(iv,il) .gt. pu_pot(il)) then
              rbchg = .true.
              if (irblog .le. 77) then
                write(rblog(irblog+1:irblog+1),'(a)') 'U'
                write(rblog(irblog+2:irblog+3),'(i2)') il
              endif
              irblog=irblog+3
              vorz_u(il,ih) = -1
              lueb_u(il) = .true.
            endif
          endif
        else
          lueb_u(il) = .false.
        endif
 200  continue
c--Senken
      do 300 iv=2,iacnv(ih)-1
        do 400 il=2,iacnl(ih)-1
          ltest=.false.
          if (isnk(iv,il,ih) .gt. 0) then
            if (abs(isktyp(1,isnk(iv,il,ih))) .eq. 11) then
              ltest=.true.
            endif
            if (abs(isktyp(1,isnk(iv,il,ih))) .eq. 10) then
              ltest=.true.
            endif
          elseif (isnk(iv,il,ih) .eq. -10) then
            ltest=.true.
          elseif (isnk(iv,il,ih) .eq. -99) then
            ltest=.true.
c            ltest=.false.
          endif
          if (ltest) then
c** Sink
            if (qs_pot(iv,il) .ge. 0.) then
c-- wenn psi = psi_pot
              if (vorz_s(iv,il,ih) .eq. -1) then
                lueb_s(iv,il) = .true.
c        Es darf nicht mehr aus dem Boden stroemen als qs_pot
                if ( senk(iv,il) .gt. qs_pot(iv,il)) then
                  rbchg = .true.
                  if (irblog .le. 75) then
                    write(rblog(irblog+1:irblog+1),'(a)') 's'
                    write(rblog(irblog+2:irblog+5),'(2i2)') iv,il
                  endif
                  irblog=irblog+5
                  vorz_s(iv,il,ih) = 1
                  lueb_s(iv,il) = .false.
                endif
c-- wenn q = q_pot
              elseif (vorz_s(iv,il,ih) .eq.  1) then
                lueb_s(iv,il) = .false.
c        Der Boden darf nicht trockener werden als psi_pot
                if (phineu(iv,il) .lt. ps_pot(iv,il)) then
                  rbchg = .true.
                  if (irblog .le. 75) then
                    write(rblog(irblog+1:irblog+1),'(a)') 'S'
                    write(rblog(irblog+2:irblog+5),'(2i2)') iv,il
                  endif
                  irblog=irblog+5
                  vorz_s(iv,il,ih) = -1
                  lueb_s(iv,il) = .true.
                endif
              endif
c** Source
            elseif (qs_pot(iv,il) .lt. 0.) then
c-- wenn psi = psi_pot
              if (vorz_s(iv,il,ih) .eq. -1) then
                lueb_s(iv,il) = .true.
c        Es darf nicht mehr in den Boden stroemen als q_pot
                if ( senk(iv,il) .lt. qs_pot(iv,il)) then
                  rbchg = .true.
                  if (irblog .le. 75) then
                    write(rblog(irblog+1:irblog+1),'(a)') 's'
                    write(rblog(irblog+2:irblog+5),'(2i2)') iv,il
                  endif
                  irblog=irblog+5
                  vorz_s(iv,il,ih) = 1
                  lueb_s(iv,il) = .false.
                endif
c-- wenn q = q_pot
              elseif (vorz_s(iv,il,ih) .eq.  1) then
                lueb_s(iv,il) = .false.
c        Der Boden darf nicht nasser werden als psi_pot
                if (phineu(iv,il) .gt. ps_pot(iv,il)) then
                  rbchg = .true.
                  if (irblog .le. 75) then
                    write(rblog(irblog+1:irblog+1),'(a)') 'S'
                    write(rblog(irblog+2:irblog+5),'(2i2)') iv,il
                  endif
                  irblog=irblog+5
                  vorz_s(iv,il,ih) = -1
                  lueb_s(iv,il) = .true.
                endif
              endif
            endif
          else
            lueb_s(iv,il) = .false.
          endif
 400    continue
 300  continue

      return
      end


      subroutine savevz(ih)
	implicit none
c-----------------------------------------------------------------------
      include 'dim.inc'
      include 'hgbdry.inc'
      include 'hgfest.inc'

      integer*4 iv, il, ih

      do 100 il=1,iacnl(ih)
        vsav_u(il)=vorz_u(il,ih)
        vsav_o(il)=vorz_o(il,ih)
  100 continue
      do 200 iv=1,iacnv(ih)
        vsav_r(iv)=vorz_r(iv,ih)
        vsav_l(iv)=vorz_l(iv,ih)
  200 continue
      do 110 il=1,iacnl(ih)
        do 210 iv=1,iacnv(ih)
          vsav_s(iv,il)=vorz_s(iv,il,ih)
  210   continue
  110 continue
      return
      end


      subroutine loadvz(ih)
	implicit none
c-----------------------------------------------------------------------
      include 'dim.inc'
      include 'hgbdry.inc'
      include 'hgfest.inc'

      integer*4 iv, il, ih

      do 100 il=1,iacnl(ih)
        vorz_u(il,ih)=vsav_u(il)
        vorz_o(il,ih)=vsav_o(il)
  100 continue
      do 200 iv=1,iacnv(ih)
        vorz_r(iv,ih)=vsav_r(iv)
        vorz_l(iv,ih)=vsav_l(iv)
  200 continue
      do 110 il=1,iacnl(ih)
        do 210 iv=1,iacnv(ih)
          vorz_s(iv,il,ih)=vsav_s(iv,il)
  210   continue
  110 continue
      return
      end
