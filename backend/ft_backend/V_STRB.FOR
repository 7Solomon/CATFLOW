      subroutine v_strb(istp,ih, dt)     ! jw dt unused

c----------------------------------------------------------
c	 30.6.1998
c    Unterprogramm zur Berechnung der Aktuellen und der
c    alten Abstandgeschwindigkeit bzw. Feuchtegradienten
c    an jedem Knoten
c-----------------------------------------------------------

      include 'dim.inc'
      include 'hgfest.inc'
      include 'hgbdry.inc'
	  include 'hgvari.inc'
	  include 'soil.inc'
      include 'pbdry.inc'
      include 'pfest.inc'
      include 'pvari.inc'
      include 'zeit.inc'

      real* 8 vhp_m, dt, va_kfz
      integer*4 il, iv, ih, istp
      dimension va_kfz(maxnv,maxnl,maxnh)
      intrinsic abs, cos, sin, min, max, sqrt
c----------------------------------------------------------------------
c  Abstandsgeschwindigkeit im gedrehten Koordinatensystem und Gradient
c  der Winkel w_xshol ist positiv im Gegenuhrzeigersinn, gerechnet von
c  xsi Achse
c---------------------------------------------------------------------

      vhp_m = 1.e-6
      dt_mak = dt_max
c	  write(6,*)'v_abs'
      do 45 iv = 1, iacnv(ih)
       do 55 il = 1, iacnl(ih)
c         write(6,*)'amak', amak(iv,il,ih), macro(iv,il,ih), iv,il
          vsact(iv,il) = q_xsi(iv,il)*cos(w_xshol(iv,il,ih))/
     &     theta(iv,il)
     &     + q_eta(iv,il)*sin(w_xshol(iv,il,ih))/theta(iv,il)

         if (mak_an(iv,il)) then
          if(vimet(ih) .eq. 'ari') then
c          vhact(iv,il) = q_eta(iv,il)*cos(w_xshol(iv,il,ih))
c     &       /(theta(iv,il)*drxsi(iv,il,ih)*hgbreit(ih))
c     &      - q_xsi(iv,il)*sin(w_xshol(iv,il,ih))/(theta(iv,il)
c     &         *drxsi(iv,il,ih)*hgbreit(ih))

c------ Arithmetisches Mittel zwischen vmik und vmak-----------

           vhact(iv,il) = (q_eta(iv,il)*cos(w_xshol(iv,il,ih))
     &       /theta(iv,il)
     &      - q_xsi(iv,il)*sin(w_xshol(iv,il,ih))/theta(iv,il))*
     &      (1./(2.*(macro(iv,il,ih)+1.))+macro(iv,il,ih)/
     &      (2.*(macro(iv,il,ih)+1.)*amak(iv,il,ih)))
          else if(vimet(ih) .eq. 'geo' ) then 
c------- geometrisches Mittel aus vmak und vmik
             if (amak(iv,il,ih) .le. 0. .or. macro(iv,il,ih) .le. 0.)
     &        then
              write(6,*)amak(iv,il,ih), iv, il
              stop 'FEHLER IN V_STRB'
            end if
            va_kfz(iv,il,ih)= 1./(macro(iv,il,ih)+1.)
     &       *sqrt(macro(iv,il,ih)/amak(iv,il,ih))
            vhact(iv,il)=(q_eta(iv,il)*cos(w_xshol(iv,il,ih))/
     &       theta(iv,il)-q_xsi(iv,il)*sin(w_xshol(iv,il,ih))
     &       /theta(iv,il))*va_kfz(iv,il,ih)
	     end if
         else
            vhact(iv,il) = q_eta(iv,il)*cos(w_xshol(iv,il,ih))
     &       /theta(iv,il)
     &      - q_xsi(iv,il)*sin(w_xshol(iv,il,ih))/theta(iv,il)
         end if
c ----- Calculation of retardation coefficient for different adsorption models
c        i_sorp =1 linear, i_sorp =2 Freundlich, i_sorp =3 Langmuir
         if(imod(iboden(iv,il,ih)) .eq. 1) then 
	     if (i_sorp .eq. 1) then
            r_ret(istp,iv,il) = 1.+bodpar(8,iboden(iv,il,ih))
     &       *k_sorp(istp,iboden(iv,il,ih))/theta(iv,il)
	      elseif (i_sorp .eq. 2) then
	       if (c_pw(istp,iv,il,ih) .gt. 0) then
              r_ret(istp,iv,il) = 1.+bodpar(8,iboden(iv,il,ih))
     &        *k_sorp(istp,iboden(iv,il,ih))/theta(iv,il)
     &        *sorp2(istp,iboden(iv,il,ih))
     &       *1./(c_pw(istp,iv,il,ih)**(1-sorp2(istp,iboden(iv,il,ih))))
	       else
               r_ret(istp,iv,il) = 1.+bodpar(8,iboden(iv,il,ih))
     &         *k_sorp(istp,iboden(iv,il,ih))/theta(iv,il)
	       end if
		  elseif (i_sorp .eq. 3) then
            r_ret(istp,iv,il)=1.+bodpar(8,iboden(iv,il,ih))/theta(iv,il)
     &      *(sorp2(istp,iboden(iv,il,ih))+k_sorp(istp,iboden(iv,il,ih))
     &      *c_pw(istp,iv,il,ih)-k_sorp(istp,iboden(iv,il,ih))
     &      *sorp2(istp,iboden(iv,il,ih))*c_pw(istp,iv,il,ih))
     &      /((1/k_sorp(istp,iboden(iv,il,ih)))+2*c_pw(istp,iv,il,ih)
     &      +k_sorp(istp,iboden(iv,il,ih))*c_pw(istp,iv,il,ih)**2) 
          end if
	    else if(imod(iboden(iv,il,ih)) .eq. 2) then
            r_ret(istp,iv,il) = 1.+bodpar(9,iboden(iv,il,ih))
     &       *k_sorp(istp,iboden(iv,il,ih))/theta(iv,il)
	    end if
c           	if (r_ret(istp,iv,il) .eq. 0.) then
c             write(6,*)'r_ret', r_ret(istp,iv,il), iv, il
c             write(6,*)'dichte',bodpar(8,iboden(iv,il,ih))
c             write(6,*)'k_s',k_sorp(istp,iboden(iv,il,ih))
c             write(6,*)'ibod',iboden(iv,il,ih), il
c             stop'fehler in v_strb'
c            end if

c		  r_ret(1,iv,il) = 1.
c		  r_ret(2,iv,il) = 0.68
  55   continue
c       write(6,*)'r_ret,1', r_ret(1,iv,5), iv
c       write(6,*)'r_ret,2', r_ret(2,iv,5), iv
  45  continue
c      write(6,*)'vhact, vsact', vhact(21,15),vsact(21,15)
c      write(6,*)'npact, w_xshol',npact(1,ih), w_xshol(1,1)
c      write(6,*)'q_eta, qealt', q_eta(21,15),qealt(21,15)

c------ Gradient an inneren Punkte -----------------------------
c	  write(6,*)'grad1'
      do 65 iv = 2, iacnv(ih)-1
        do 75 il = 2, iacnl(ih)-1
          gtxact(iv,il) = (theta(iv,il+1)-theta(iv,il-1))
     &     *cos(w_xshol(iv,il,ih))/(f_xsi(iv,il,ih)*x_p1m1(il-1,ih))
     &    + (theta(iv+1,il)-theta(iv-1,il))*sin(w_xshol(iv,il,ih))/
     &       (f_eta(iv,il,ih)*e_p1m1(iv-1,ih))
          gteact(iv,il) = (theta(iv+1,il)-theta(iv-1,il))
     &     *cos(w_xshol(iv,il,ih))/(f_eta(iv,il,ih)*e_p1m1(iv-1,ih))
     &    - (theta(iv,il+1)-theta(iv,il-1))*sin(w_xshol(iv,il,ih))/
     &      (f_xsi(iv,il,ih)*x_p1m1(il-1,ih))
  75    continue
  65   continue

c----- Etagradient obere und unter Reihe
c	  write(6,*)'grad2'
      iv = 1
      do 67 il = 1, iacnl(ih)
c      	write(6,*)'f_eta, e_p1m0', f_eta(iv,il,ih),e_p1m0(iv,ih)
          gteact(iv,il) = (theta(iv+1,il)-theta(iv,il))
     &     *cos(w_xshol(iv,il,ih))/(f_eta(iv,il,ih)*e_p1m0(iv,ih))
c     &    - (theta(iv,il+1)-theta(iv,il-1))*sin(w_xshol(iv,il,ih))/
c     &      (f_xsi(iv,il,ih)*x_p1m1(il-1,ih))
c        gteact(iv,il) = (theta(iv+1,il)-theta(iv,il))/
c     &   (f_eta(iv,il,ih)*e_p1m0(iv,ih))
   67 continue
c      write(6,*)'grad3'
      iv = iacnv(ih)
      do 68 il = 1, iacnl(ih)
          gteact(iv,il) = (theta(iv,il)-theta(iv-1,il))
     &     *cos(w_xshol(iv,il,ih))/(f_eta(iv,il,ih)*e_p1m0(iv-1,ih))
c     &    - (theta(iv,il+1)-theta(iv,il-1))*sin(w_xshol(iv,il,ih))/
c     &      (f_xsi(iv,il,ih)*x_p1m1(il-1,ih))
c        gteact(iv,il) = (theta(iv,il)-theta(iv-1,il))/
c     &       (f_eta(iv-1,il,ih)*e_p1m0(iv-1,ih))
  68  continue

c---- xsi-Gradient am rechten und linken Rand -----------------
c      write(6,*)'grad4'
	  il = 1
      do 69 iv = 1, iacnv(ih)
          gtxact(iv,il) = (theta(iv,il+1)-theta(iv,il))
     &     *cos(w_xshol(iv,il,ih))/(f_xsi(iv,il,ih)*x_p1m0(il,ih))
c     &    + (theta(iv+1,il)-theta(iv-1,il))*sin(w_xshol(iv,il,ih))/
c     &       (f_eta(iv,il,ih)*e_p1m1(iv-1,ih))
c        gtxact(iv,il) = (theta(iv,il+1)-theta(iv,il))/
c     &      (f_xsi(iv,il,ih)*x_p1m0(il,ih))
c        write(6,*)'gxtact',gtxact(iv,il)
c        write(6,*)'L= ',L,iv,il
  69  continue
c	  write(6,*)'grad5'
      il = iacnl(ih)
      do 70 iv = 1, iacnv(ih)
          gtxact(iv,il) = (theta(iv,il)-theta(iv,il-1))
     &     *cos(w_xshol(iv,il,ih))/(f_xsi(iv,il,ih)*x_p1m0(il-1,ih))
c     &    + (theta(iv+1,il)-theta(iv-1,il))*sin(w_xshol(iv,il,ih))/
c     &       (f_eta(iv,il,ih)*e_p1m1(iv-1,ih))
c        gtxact(iv,il) = (theta(iv,il)-theta(iv,il-1))/
c     &      (f_xsi(iv,il-1,ih)*x_p1m0(il-1,ih))
c        write(6,*)'gxtact',gtxact(iv,il)
  70  continue

c---- Berechne v'=v+D grad ln(theta)---------------------
c      write(6,*)'grad6'                                    ! jw 25 vx_st etc schon immer für volles grid gerechnet!
      do 77 iv = 1,iacnv(ih)
       do 88 il = 1, iacnl(ih)
       vx_st(iv,il,ih) = vsact(iv,il)+d_koef(istp,iboden(iv,il,ih))
     & *gtxact(iv,il)/theta(iv,il)
       ve_st(iv,il,ih) = vhact(iv,il)+d_koef(istp,iboden(iv,il,ih))
     & *gteact(iv,il)/theta(iv,il)
       if( abs(ve_st(iv,il,ih)) .lt. 1e-12) then
         ve_st(iv,il,ih)=0.
       else if( abs(vx_st(iv,il,ih)) .lt. 1e-12) then
         vx_st(iv,il,ih)=0.
       end if
   88  continue
   77 continue


      return
      end
