      subroutine calgeo(ih)
c-----------------------------------------------------------------------
c  Hang: Berechnung (unveraenderlicher), meist geometrischer Werte
c-----------------------------------------------------------------------
      include 'dim.inc'
      include 'hgfest.inc'
      include 'soil.inc'
	include 'bach.inc'

      integer*4 iv,il,ih, icv
      integer*4 ilp
      real*8 help, strahl, s, h, rel_a, dx, dy
      dimension help(maxnl)

      external strahl, ggcross, hunt
      intrinsic sin, cos, tan, abs, atan2

      do 110 il = 2,iacnl(ih)-1
        x_p1m1(il-1,ih) = xsi(il+1,ih)-xsi(il-1,ih)
  110 continue
      do 120 il = 1,iacnl(ih)-1
        x_p1m0(il,ih) = xsi(il+1,ih)-xsi(il,ih)
  120 continue
      do 210 iv = 2,iacnv(ih)-1
        e_p1m1(iv-1,ih) = eta(iv+1,ih)-eta(iv-1,ih)
  210 continue
      do 220 iv = 1,iacnv(ih)-1
        e_p1m0(iv,ih) = eta(iv+1,ih)-eta(iv,ih)
c        write(6,*)'e_p1m0',e_p1m0(iv,ih),eta(iv,ih)
  220 continue

      do 310 il = 2,iacnl(ih)-1
        do 320 iv = 2,iacnv(ih)-1
          drxsi(iv,il,ih) = 0.50*(x_p1m0(il,ih)+x_p1m0(il-1,ih))
     &      *f_xsi(iv,il,ih)
          dreta(iv,il,ih) = 0.50*(e_p1m0(iv,ih)+e_p1m0(iv-1,ih))
     &      *f_eta(iv,il,ih)
          area(iv,il,ih) = 0.25*x_p1m1(il-1,ih)*e_p1m1(iv-1,ih)
     &      *f_xsi(iv,il,ih)*f_eta(iv,il,ih)
cc          xyxpy(iv,il,ih)=area(iv,il,ih)**2./
cc     &       ((0.5*x_p1m1(il-1,ih)*f_xsi(iv,il,ih))**2.
cc     &      + (0.5*e_p1m1(iv-1,ih)*f_eta(iv,il,ih))**2.)
  320   continue
  310 continue

c               flaeche <-> area? area oben für innere Knoten, unten für Rest; "flaeche" 1 Reihe weniger
      do 311 il = 1,iacnl(ih)-1
        do 321 iv = 1,iacnv(ih)-1
          flaeche(iv,il,ih)=x_p1m0(il,ih)*e_p1m0(iv,ih)
     &    *f_eta(iv+1,il,ih)*f_xsi(iv+1,il,ih)
  321   continue
  311 continue

c...unten links
      il = 1
      iv = 1
      dr_l(iv,ih) = 0.50*e_p1m0(iv,ih)*f_eta(iv,il,ih)
      dreta(iv,il,ih)=dr_l(iv,ih)
      dr_u(il,ih) = 0.50*x_p1m0(il,ih)*f_xsi(iv,il,ih)
      drxsi(iv,il,ih)=dr_u(il,ih)
      area(iv,il,ih) = 0.25*x_p1m0(il,ih)*e_p1m0(iv,ih)
     &      *f_xsi(iv,il,ih)*f_eta(iv,il,ih)
cc      xyxpy(iv,il,ih)=(4.*area(iv,il,ih))**2./
cc     &   ((x_p1m0(il,ih)*f_xsi(iv,il,ih))**2.
cc     &  + (e_p1m0(iv,ih)*f_eta(iv,il,ih))**2.)

      do 410 iv = 2,iacnv(ih)-1
        dr_l(iv,ih) = 0.50*(e_p1m0(iv,ih)+e_p1m0(iv-1,ih))
     &      *f_eta(iv,il,ih)
        dreta(iv,il,ih)=dr_l(iv,ih)
        drxsi(iv,il,ih) = 0.50*x_p1m0(il,ih)*f_xsi(iv,il,ih)
        area(iv,il,ih) = 0.25*x_p1m0(il,ih)*e_p1m1(iv-1,ih)
     &      *f_xsi(iv,il,ih)*f_eta(iv,il,ih)
cc        xyxpy(iv,il,ih)=(2.*area(iv,il,ih))**2./
cc     &     (( x_p1m0(il,ih)*f_xsi(iv,il,ih))**2.
cc     &    + (0.5*e_p1m1(iv-1,ih)*f_eta(iv,il,ih))**2.)
  410 continue

c...oben links
      iv = iacnv(ih)
      dr_l(iv,ih) = 0.50*e_p1m0(iv-1,ih)*f_eta(iv,il,ih)
      dreta(iv,il,ih)=dr_l(iv,ih)
      dr_o(il,ih) = 0.50*x_p1m0(il,ih)*f_xsi(iv,il,ih)
      drxsi(iv,il,ih)=dr_o(il,ih)
      area(iv,il,ih) = 0.25*x_p1m0(il,ih)*e_p1m0(iv-1,ih)
     &      *f_xsi(iv,il,ih)*f_eta(iv,il,ih)
cc      xyxpy(iv,il,ih)=(4.*area(iv,il,ih))**2./
cc     &   ((x_p1m0(il,ih)*f_xsi(iv,il,ih))**2.
cc     &    + (e_p1m0(iv-1,ih)*f_eta(iv,il,ih))**2.)

      do 420 il = 2,iacnl(ih)-1
        dr_o(il,ih) = 0.50*(x_p1m0(il,ih)+x_p1m0(il-1,ih))
     &      *f_xsi(iv,il,ih)
        drxsi(iv,il,ih)=dr_o(il,ih)
        dreta(iv,il,ih) = 0.50*e_p1m0(iv-1,ih)*f_eta(iv,il,ih)
        area(iv,il,ih) = 0.25*x_p1m1(il-1,ih)*e_p1m0(iv-1,ih)
     &      *f_xsi(iv,il,ih)*f_eta(iv,il,ih)
cc        xyxpy(iv,il,ih)=(2.*area(iv,il,ih))**2./
cc     &     ((0.5*x_p1m1(il-1,ih)*f_xsi(iv,il,ih))**2.
cc     &     + (e_p1m0(iv-1,ih)*f_eta(iv,il,ih))**2.)
  420 continue

c...oben rechts
      il = iacnl(ih)
      dr_o(il,ih) = 0.50*x_p1m0(il-1,ih)*f_xsi(iv,il,ih)
      drxsi(iv,il,ih)=dr_o(il,ih)
      dr_r(iv,ih) = 0.50*e_p1m0(iv-1,ih)*f_eta(iv,il,ih)
      dreta(iv,il,ih)=dr_r(iv,ih)
      area(iv,il,ih) = 0.25*x_p1m0(il-1,ih)*e_p1m0(iv-1,ih)
     &      *f_xsi(iv,il,ih)*f_eta(iv,il,ih)
cc      xyxpy(iv,il,ih)=(4.*area(iv,il,ih))**2./
cc     &   ((x_p1m0(il-1,ih)*f_xsi(iv,il,ih))**2.
cc     &     + (e_p1m0(iv-1,ih)*f_eta(iv,il,ih))**2.)

      do 430 iv = 2,iacnv(ih)-1
        dr_r(iv,ih) = 0.50*(e_p1m0(iv,ih)+e_p1m0(iv-1,ih))
     &      *f_eta(iv,il,ih)
        dreta(iv,il,ih)=dr_r(iv,ih)
        drxsi(iv,il,ih) = 0.50*x_p1m0(il-1,ih)*f_xsi(iv,il,ih)
        area(iv,il,ih) = 0.25*x_p1m0(il-1,ih)*e_p1m1(iv-1,ih)
     &      *f_xsi(iv,il,ih)*f_eta(iv,il,ih)
cc        xyxpy(iv,il,ih)=(2.*area(iv,il,ih))**2./
cc     &     ((x_p1m0(il-1,ih)*f_xsi(iv,il,ih))**2.
cc     &     + (0.5*e_p1m1(iv-1,ih)*f_eta(iv,il,ih))**2.)
  430 continue

c...unten rechts
      iv = 1
      dr_u(il,ih) = 0.50*x_p1m0(il-1,ih)*f_xsi(iv,il,ih)
      drxsi(iv,il,ih)=dr_u(il,ih)
      dr_r(iv,ih) = 0.50*e_p1m0(iv,ih)*f_eta(iv,il,ih)
      dreta(iv,il,ih)=dr_r(iv,ih)
      area(iv,il,ih) = 0.25*x_p1m0(il-1,ih)*e_p1m0(iv,ih)
     &      *f_xsi(iv,il,ih)*f_eta(iv,il,ih)
cc      xyxpy(iv,il,ih)=(4.*area(iv,il,ih))**2./
cc     &   ((x_p1m0(il-1,ih)*f_xsi(iv,il,ih))**2.
cc     &      + (e_p1m0(iv,ih)*f_eta(iv,il,ih))**2.)

      do 440 il = 2,iacnl(ih)-1
        dr_u(il,ih) = 0.50*(x_p1m0(il,ih)+x_p1m0(il-1,ih))
     &      *f_xsi(iv,il,ih)
        drxsi(iv,il,ih)=dr_u(il,ih)
        dreta(iv,il,ih) = 0.50*e_p1m0(iv,ih)*f_eta(iv,il,ih)
        area(iv,il,ih) = 0.25*x_p1m1(il-1,ih)*e_p1m0(iv,ih)
     &      *f_xsi(iv,il,ih)*f_eta(iv,il,ih)
cc        xyxpy(iv,il,ih)=(2.*area(iv,il,ih))**2./
cc     &     ((0.5*x_p1m1(il-1,ih)*f_xsi(iv,il,ih))**2.
cc     &      + (e_p1m0(iv,ih)*f_eta(iv,il,ih))**2.)
  440 continue

c     jw scaling of variable width
c       rel_a surface area of hillslope, hgobfl area of hillslope from geofile
      rel_a=0.                                  !
      do 509 il = 1,iacnl(ih)                   ! 
        rel_a= rel_a+dr_o(il,ih)*varbr(il,ih)
  509 continue
      do 508 il = 1,iacnl(ih)
        varbr(il,ih)=varbr(il,ih)*hgobfl(ih)/rel_a ! 
  508 continue

      do 501 icv = 1,iaccv(ih)
        alla(icv,ih) = 0.
        vola(icv,ih) = 0.
        do 511 il = icvl(icv,ih),icvr(icv,ih)
          do 521 iv = icvu(icv,ih),icvo(icv,ih)
            alla(icv,ih) = alla(icv,ih) + area(iv,il,ih)
            vola(icv,ih) = vola(icv,ih) + area(iv,il,ih)*varbr(il,ih)
  521     continue
  511   continue
  501 continue

      do 510 il = 1,iacnl(ih)
        do 520 iv = 1,iacnv(ih)
          hko(iv,il,ih) = hko(iv,il,ih) - hkomin(ih)
          kxx(iv,il,ih) =  (anisot(1,iboden(iv,il,ih))
     &                     *cos(w_xshr(iv,il))**2+
     &                     anisot(2,iboden(iv,il,ih))
     &                     *sin(w_xshr(iv,il))**2)*rel_ks(iv,il,ih)
          kee(iv,il,ih) =  (anisot(1,iboden(iv,il,ih))
     &                     *sin(w_xshr(iv,il))**2+
     &                     anisot(2,iboden(iv,il,ih))
     &                     *cos(w_xshr(iv,il))**2)*rel_ks(iv,il,ih)
          kxe(iv,il,ih) = (anisot(1,iboden(iv,il,ih))-
     &                     anisot(2,iboden(iv,il,ih)))
     &                     *sin(w_xshr(iv,il))*cos(w_xshr(iv,il))
     &                      *rel_ks(iv,il,ih) !### Erwin Zehe 27.03.2006
          kxxf(iv,il,ih) = kxx(iv,il,ih)
          keef(iv,il,ih) = kee(iv,il,ih)
          kxef(iv,il,ih) = kxe(iv,il,ih)
  520   continue
  510 continue

      

      lrd_l(ih)=0.
      lrd_r(ih)=0.
      do 600 iv = 1,iacnv(ih)

        sloper(iv,ih)=cos(1.5708-w_xsho(iv,iacnl(ih)))
        slopel(iv,ih)=cos(1.5708-w_xsho(iv,1))

        lrd_l(ih)=lrd_l(ih)+dr_l(iv,ih)
        lrd_r(ih)=lrd_r(ih)+dr_r(iv,ih)

        il = 1
        al_fak(iv,il,ih) =
     &      2.*area(iv,il,ih)/(2.*area(iv,il,ih)+area(iv,il+1,ih))
        do 610 il = 2,iacnl(ih)-2
          al_fak(iv,il,ih) =
     &        area(iv,il,ih)/(area(iv,il,ih)+area(iv,il+1,ih))
  610   continue
        il = iacnl(ih)-1
        al_fak(iv,il,ih) =
     &      area(iv,il,ih)/(area(iv,il,ih)+2.*area(iv,il+1,ih))
  600 continue

      lrd_u(ih)=0.
      lrd_o(ih)=0.
      do 700 il = 1,iacnl(ih)
        slopeo(il,ih)=cos(w_xsho(iacnv(ih),il))
        gefall(il,ih)=tan(w_xsho(iacnv(ih),il))
        slopeu(il,ih)=cos(w_xsho(1,il))

        lrd_u(ih)=lrd_u(ih)+dr_u(il,ih)
        lrd_o(ih)=lrd_o(ih)+dr_o(il,ih)

        iv = 1
        av_fak(iv,il,ih) =
     &      2.*area(iv,il,ih)/(2.*area(iv,il,ih)+area(iv+1,il,ih))
        do 710 iv = 2,iacnv(ih)-2
          av_fak(iv,il,ih) =
     &        area(iv,il,ih)/(area(iv,il,ih)+area(iv+1,il,ih))
  710   continue
        iv = iacnv(ih)-1
        av_fak(iv,il,ih) =
     &      area(iv,il,ih)/(area(iv,il,ih)+2.*area(iv+1,il,ih))
  700 continue

      do 800 iv = 1,iacnv(ih)
        do 810 il = 1,iacnl(ih)-1
          if (iboden(iv,il,ih) .eq. iboden(iv,il+1,ih)) then
c  bevorzugt: Leitfaehigkeit aus mittlerem Wassergehalt -> 1
            mm_xsi(iv,il,ih) = 1
          else
            if (imod(iboden(iv,il  ,ih)) .eq. 1) then
c  (Empfehlung nach Zurmuehl fuer VAN GENUCHTEN MODELL)
              if ((bodpar(5,iboden(iv,il  ,ih)) .ge. vg_ngr) .and.
     &            (bodpar(5,iboden(iv,il+1,ih)) .ge. vg_ngr)) then
c           arithmetisches Mittel -> 2
                mm_xsi(iv,il,ih) = 2
              else
c           geometrisches Mittel -> 3
              mm_xsi(iv,il,ih) = 3
              endif
            else
c  andere Modelle: geometrisches Mittel -> 3
              mm_xsi(iv,il,ih) = 3
            endif
          endif
  810   continue
  800 continue

      do 801 il = 1,iacnl(ih)
        do 811 iv = 1,iacnv(ih)-1
          if (iboden(iv,il,ih) .eq. iboden(iv+1,il,ih)) then
c  bevorzugt: Leitfaehigkeit aus mittlerem Wassergehalt -> 1
            mm_eta(iv,il,ih) = 1
          else
            if (imod(iboden(iv,il  ,ih)) .eq. 1) then
c  (Empfehlung nach Zurmuehl fuer VAN GENUCHTEN MODELL)
              if ((bodpar(5,iboden(iv  ,il,ih)) .ge. vg_ngr) .and.
     &            (bodpar(5,iboden(iv+1,il,ih)) .ge. vg_ngr)) then
c           arithmetisches Mittel -> 2
                mm_eta(iv,il,ih) = 2
              else
c           geometrisches Mittel -> 3
                mm_eta(iv,il,ih) = 3
              endif
            else
c  andere Modelle: geometrisches Mittel -> 3
              mm_eta(iv,il,ih) = 3
            endif
          endif
  811   continue
  801 continue

      do 911 il = 1,iacnl(ih)
        help(il)=sko(iacnv(ih),il,ih)
  911 continue
      do 910 il = 1,iacnl(ih)
          ilp=1
          depth(iacnv(ih),il,ih) = 0.
        do 920 iv = iacnv(ih)-1,1,-1
          call hunt(help,iacnl(ih),sko(iv,il,ih),ilp)
          if (ilp .eq. 0) then
            depth(iv,il,ih) = hko(iacnv(ih),1,ih)-hko(iv,il,ih)
            ilp=1
          elseif (ilp .eq. iacnl(ih)) then
            depth(iv,il,ih) = hko(iacnv(ih),iacnl(ih),ih)-hko(iv,il,ih)
            ilp=iacnl(ih)-1
          else
            call ggcross(sko(iacnv(ih),ilp,ih),hko(iacnv(ih),ilp,ih),
     &                  sko(iacnv(ih),ilp+1,ih),hko(iacnv(ih),ilp+1,ih),
     &                  sko(iv,il,ih),hko(iv,il,ih),
     &                  sko(iv,il,ih),hko(iacnv(ih),il,ih),s,h)
            depth(iv,il,ih) = h-hko(iv,il,ih)
          endif
c          xko(iv,il,ih) = strahl(xko(iacnv(ih),ilp,ih),
c     &      xko(iacnv(ih),ilp+1,ih),help(ilp),help(ilp+1),sko(iv,il,ih))
c          yko(iv,il,ih) = strahl(yko(iacnv(ih),ilp,ih),
c     &      yko(iacnv(ih),ilp+1,ih),help(ilp),help(ilp+1),sko(iv,il,ih))
          xko(il) = strahl(xko(ilp), xko(ilp+1),
     &                    help(ilp),help(ilp+1),sko(iv,il,ih))
          yko(il) = strahl(yko(ilp), yko(ilp+1),
     &                    help(ilp),help(ilp+1),sko(iv,il,ih))
  920   continue
  910 continue

      do 1010 il = 1,iacnl(ih)-1
        fbrup(il,ih) = 0.5*(1. + varbr(il+1,ih)/varbr(il,ih) )
 1010 continue
        il = iacnl(ih)
        fbrup(il,ih)=1.
        il=1
        fbrlow(il,ih)=1.
      do 1020 il = 2,iacnl(ih)
        fbrlow(il,ih) = 0.5*(1. + varbr(il-1,ih)/varbr(il,ih) )
 1020 continue

      do 1110 il = 2,iacnl(ih)-1
c        dx=xko(iacnv(ih),il+1,ih)-xko(iacnv(ih),il-1,ih)
c        dy=yko(iacnv(ih),il+1,ih)-yko(iacnv(ih),il-1,ih)
        dx=xko(il+1)-xko(il-1)
        dy=yko(il+1)-yko(il-1)
        azimut(il,ih)=atan2(-dx,-dy)+3.1415926
 1110 continue
      azimut(1,ih)=azimut(2,ih)
      azimut(iacnl(ih),ih)=azimut(iacnl(ih)-1,ih)

!c     jw  Test area <-> flaeche
!       do 2001 iv = 1, iacnv(ih)
!         write(io(19),2222) (area(iv,il,ih), il=1,iacnl(ih))
!         write(io(20),2222) (flaeche(iv,il,ih), il=1,iacnl(ih))
! 2001  continue
!2222   format(2000e14.3E3)
      
      return
      end



      subroutine nullen(ih)
c-----------------------------------------------------------------------
c  Initialisierung
c-----------------------------------------------------------------------
      include 'dim.inc'
      include 'hgfest.inc'
      include 'hgvari.inc'

      integer*4 iv,il,ih

      do 800 iv = 1,iacnv(ih)
        rfl_r(iv) = 0.
        rfl_l(iv) = 0.
  800 continue
      do 900 il = 1,iacnl(ih)
        rfl_o(il) = 0.
        rfl_u(il) = 0.
  900 continue

      return
      end
