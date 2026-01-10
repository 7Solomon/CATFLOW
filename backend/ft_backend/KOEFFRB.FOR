      subroutine koeffrb(ih,dt)
c-----------------------------------------------------------------------
c  Koeffizienten auf dem Rand
c  Anmerkung:
c   an den Eckpunkten muss entweder
c    -  ein Potential und ein Fluss in eine Richtung       oder
c    -  zwei Fluesse in beide Richtungen
c   vorgegeben werden
c-----------------------------------------------------------------------
      include 'dim.inc'
      include 'hgfest.inc'
      include 'hgvari.inc'
      include 'hgbdry.inc'
      include 'zeit.inc'
      include 'pbdry.inc'
	include 'bach.inc'
	include 'soil.inc'

      integer*4 iv,il,ih, istp, ib
      real*8 dnull
      real*8 dt, strahl

      external strahl
      intrinsic abs, cos

      dnull=0.
      ib=0
C-----------------------------------------------------------------------
C  unten
C-----------------------------------------------------------------------
      iv=1
      do 110 il = 1,iacnl(ih)
C*** pauschal
C-----------Null-Fluss
        if (irb_u(il,ih) .eq. 0) then
          qu_pot(il)=0.
C-----------Gravitationsfluss
        elseif (irb_u(il,ih) .eq. -3) then
          qu_pot(il)=-durchl(iv,il)/slopeu(il,ih)
C-----------alten Wert festhalten
        elseif (irb_u(il,ih) .eq. -4) then
          pu_pot(il)=phialt(iv,il,ih)
c------- null divergenz
        elseif (irb_u(iv,ih) .eq. -5) then
          if (q_eta(iv+1, il) .lt. 0) then
		 qu_pot(il)=q_eta(iv+1, il)
	    elseif (q_eta(iv+1, il) .ge. 0) then
	     qu_pot(il)=0
	    end if
C-----------Sickerrand (einseitige RB)
        elseif (irb_u(il,ih) .eq. -10) then
           qu_pot(il)=0. 
           pu_pot(il)=hko(iv,il,ih)
C-----------atmosphaerisch (unten: Gravitationsfluá)
        elseif (irb_u(il,ih) .eq. -99) then
          qu_pot(il)=-durchl(iv,il)/slopeu(il,ih)
          pu_pot(il)=hko(iv,il,ih)+999999.
C*** Zeitreihe
        else
C-------------Null-Fluss
          if (irbtyp(1,irb_u(il,ih)) .eq. 0) then
            if (lrintp(irb_u(il,ih))) then
              qu_pot(il)=strahl(dnull,rbpar(2,1,irb_u(il,ih)),
     &             zrbf(1,irb_u(il,ih)),zrbf(2,irb_u(il,ih)),t_act+dt)
            else
              qu_pot(il)=0.
            endif
C-------------Vorgegebener Fluss
          elseif (irbtyp(1,irb_u(il,ih)) .eq. 1) then
            if (lrintp(irb_u(il,ih))) then
              qu_pot(il)=strahl(rbpar(1,1,irb_u(il,ih)),
     &          rbpar(2,1,irb_u(il,ih)),zrbf(1,irb_u(il,ih)),
     &                                  zrbf(2,irb_u(il,ih)),t_act+dt)
            else
              qu_pot(il)=rbpar(1,1,irb_u(il,ih))
            endif
C-------------Gravitationsfluss
          elseif (irbtyp(1,irb_u(il,ih)) .eq. 3) then
            qu_pot(il)=-durchl(iv,il)/slopeu(il,ih)
C-------------Leakage-Rand (gemischte RB)
          elseif (irbtyp(1,irb_u(il,ih)) .eq.  5) then
            qu_pot(il)=rbpar(1,1,irb_u(il,ih))*( rbpar(1,2,irb_u(il,ih))
     &           -( hko(iv,il,ih)+ hkomin(ih)-psi(iv,il) ) )
C-------------Saugspannung
          elseif (irbtyp(1,irb_u(il,ih)) .eq. -1) then
            if (lrintp(irb_u(il,ih))) then
              pu_pot(il)=hko(iv,il,ih)-strahl(rbpar(1,1,irb_u(il,ih)),
     &          rbpar(2,1,irb_u(il,ih)),zrbf(1,irb_u(il,ih)),
     &                                  zrbf(2,irb_u(il,ih)),t_act+dt)
            else
              pu_pot(il)=hko(iv,il,ih)-rbpar(1,1,irb_u(il,ih))
            endif
C-------------Potential relativ zu *.GEO Datei
          elseif (irbtyp(1,irb_u(il,ih)) .eq. -2) then
            if (lrintp(irb_u(il,ih))) then
              pu_pot(il)=strahl(rbpar(1,1,irb_u(il,ih)),
     &          rbpar(2,1,irb_u(il,ih)),zrbf(1,irb_u(il,ih)),
     &                   zrbf(2,irb_u(il,ih)),t_act+dt)-hkomin(ih)
            else
              pu_pot(il)=rbpar(1,1,irb_u(il,ih))-hkomin(ih)
            endif
C-------------alten Wert festhalten
          elseif (irbtyp(1,irb_u(il,ih)) .eq. -4) then
            pu_pot(il)=phialt(iv,il,ih)
C-------------Sickerrand (einseitige RB)
          elseif (abs(irbtyp(1,irb_u(il,ih))) .eq. 10) then
            qu_pot(il)=0.
            pu_pot(il)=hko(iv,il,ih)
C-------------einseitige RB
          elseif (abs(irbtyp(1,irb_u(il,ih))) .eq. 11) then
            qu_pot(il)=rbpar(1,2,irb_u(il,ih))
            pu_pot(il)=hko(iv,il,ih)-rbpar(1,1,irb_u(il,ih))
C-------------atmosphaerisch (unten: Gravitationsfluá)
          elseif (abs(irbtyp(1,irb_u(il,ih))) .eq.  99) then
            qu_pot(il)=-durchl(iv,il)/slopeu(il,ih)
            pu_pot(il)=hko(iv,il,ih)+999999.
          else
            stop 'Fehler am unteren Rand'
          endif
        endif

        if (vorz_u(il,ih) .gt. 0) then
c  RB 2.Art, Neumann, Fluss
          if ( (il.eq.1)         .and. (vorz_l(iv,ih) .lt. 0)) goto 10
          if ( (il.eq.iacnl(ih)) .and. (vorz_r(iv,ih) .lt. 0)) goto 10
            Fe_p1(iv,il) = - A_e(iv,il)*vorfak(iv,il)/e_p1m0(iv,ih)
            Fe_00(iv,il) = - Fe_p1(iv,il)
            RS(iv,il)    = RS(iv,il)
     &                     + 2.*f_xsi(iv,il,ih)*qu_pot(il)*
     &                       vorfak(iv,il)/e_p1m0(iv,ih)
   10     continue
          rfl_u(il)=qu_pot(il)
        elseif (vorz_u(il,ih) .lt. 0) then
c  RB 1.Art, Dirichlet, Potential
          Fe_p1(iv,il) = 0.
          Fe_00(iv,il) = -0.5
          Fx_00(iv,il) = -0.5
          Fx_p1(iv,il) = 0.
          Fx_m1(iv,il) = 0.
          RS(iv,il)    = -pu_pot(il)
        endif
  110 continue

C-----------------------------------------------------------------------
C  oben, d.h Atmosphere
C-----------------------------------------------------------------------
      iv=iacnv(ih)
      do 210 il = 1,iacnl(ih)
C*** pauschal
C-----------Null-Fluss
        if (irb_o(il,ih) .eq. 0) then
          qo_pot(il)=0.
C-----------Gravitationsfluss
        elseif (irb_o(il,ih) .eq. -3) then
          qo_pot(il)=-durchl(iv,il)/slopeo(il,ih)
C-----------alten Wert festhalten
        elseif (irb_o(il,ih) .eq. -4) then
          po_pot(il)=phialt(iv,il,ih)
C-----------Sickerrand (einseitige RB)
        elseif (irb_o(il,ih) .eq. -10) then
          qo_pot(il)=0.
          po_pot(il)=hko(iv,il,ih)
C-----------atmosphaerisch (oben: Klima)
        elseif (irb_o(il,ih) .eq. -99) then

cc	Ullis Version, geändert slopeo jw
	   qo_pot(il)=(-neff(il)+Esoil(il))*slopeo(il,ih)
     &				-yoben(il)/slopeo(il,ih)/dt
c jw	Begrenzen mit Inf.kapazitaet?		- min(durchl(iacnv(ih), il) * (grad-_z -1)
        po_pot(il)=hko(iv,il,ih)+yoben(il) + (neff(il))*dt 
ccc	---------------



C*** Zeitreihe
        else
C-------------Null-Fluss
          if (irbtyp(1,irb_o(il,ih)) .eq. 0) then
            if (lrintp(irb_o(il,ih))) then
              qo_pot(il)=strahl(dnull,rbpar(2,1,irb_o(il,ih)),
     &             zrbf(1,irb_o(il,ih)),zrbf(2,irb_o(il,ih)),t_act+dt)
              do 53 istp= 1, istact
               cil_o(istp,il,ih) = strahl(rbpar(1,istp+1,irb_o(il,ih)),
     &          rbpar(2,istp+1,irb_o(il,ih)),zrbf(1,irb_o(il,ih)),
     &                                  zrbf(2,irb_o(il,ih)),t_act+dt)
  53          continue
            else
              qo_pot(il)=0.
              do 54 istp= 1, istact
               cil_o(istp,il,ih) = 0.
  54          continue
            endif
C-------------Vorgegebener Fluss
          elseif (irbtyp(1,irb_o(il,ih)) .eq. 1) then
            if (lrintp(irb_o(il,ih))) then
              qo_pot(il)=strahl(rbpar(1,1,irb_o(il,ih)),
     &          rbpar(2,1,irb_o(il,ih)),zrbf(1,irb_o(il,ih)),
     &                                  zrbf(2,irb_o(il,ih)),t_act+dt)
              do 55 istp= 1, istact
               cil_o(istp,il,ih) = strahl(rbpar(1,istp+1,irb_o(il,ih)),
     &          rbpar(2,istp+1,irb_o(il,ih)),zrbf(1,irb_o(il,ih)),
     &                                  zrbf(2,irb_o(il,ih)),t_act+dt)
  55          continue
            else
              qo_pot(il)=rbpar(1,1,irb_o(il,ih))
              do 56 istp= 1, istact
               cil_o(istp,il,ih) = rbpar(1,istp+1,irb_o(il,ih))
  56          continue
            endif
C-------------Gravitationsfluss
          elseif (irbtyp(1,irb_o(il,ih)) .eq. 3) then
            qo_pot(il)=-durchl(iv,il)/slopeo(il,ih)
C-------------Leakage-Rand (gemischte RB)
          elseif (irbtyp(1,irb_o(il,ih)) .eq.  5) then
            qo_pot(il)=rbpar(1,1,irb_o(il,ih))*( rbpar(1,2,irb_o(il,ih))
     &           -( hko(iv,il,ih)+ hkomin(ih)-psi(iv,il) ) )
C-------------Saugspannung
          elseif (irbtyp(1,irb_o(il,ih)) .eq. -1) then
            if (lrintp(irb_o(il,ih))) then
              po_pot(il)=hko(iv,il,ih)-strahl(rbpar(1,1,irb_o(il,ih)),
     &          rbpar(2,1,irb_o(il,ih)),zrbf(1,irb_o(il,ih)),
     &                                  zrbf(2,irb_o(il,ih)),t_act+dt)
            else
              po_pot(il)=hko(iv,il,ih)-rbpar(1,1,irb_o(il,ih))
            endif
C-------------Potential relativ zu *.GEO Datei
          elseif (irbtyp(1,irb_o(il,ih)) .eq. -2) then
            if (lrintp(irb_o(il,ih))) then
              po_pot(il)=strahl(rbpar(1,1,irb_o(il,ih)),
     &          rbpar(2,1,irb_o(il,ih)),zrbf(1,irb_o(il,ih)),
     &                   zrbf(2,irb_o(il,ih)),t_act+dt)-hkomin(ih)
            else
              po_pot(il)=rbpar(1,1,irb_o(il,ih))-hkomin(ih)
            endif
C-------------alten Wert festhalten
          elseif (irbtyp(1,irb_o(il,ih)) .eq. -4) then
            po_pot(il)=phialt(iv,il,ih)
C-------------Sickerrand (einseitige RB)
          elseif (abs(irbtyp(1,irb_o(il,ih))) .eq. 10) then
            qo_pot(il)=0.
            po_pot(il)=hko(iv,il,ih)
C-------------einseitige RB
          elseif (abs(irbtyp(1,irb_o(il,ih))) .eq. 11) then
            qo_pot(il)=rbpar(1,2,irb_o(il,ih))
            po_pot(il)=hko(iv,il,ih)-rbpar(1,1,irb_o(il,ih))
            do 57 istp = 1, istact
               cil_o(istp,il,ih) = rbpar(1,istp+2,irb_o(il,ih))
  57        continue
C-------------atmosphaerisch (oben: Klima)
          elseif (abs(irbtyp(1,irb_o(il,ih))) .eq.  99) then
            stop '99 noch nicht implementiert'
          else
            stop 'Fehler am oberen Rand'
          endif
        endif

        if (vorz_o(il,ih) .gt. 0) then
c  RB 2.Art, Neumann, Fluss
          if ( (il.eq.1)         .and. (vorz_l(iv,ih) .lt. 0)) goto 20
          if ( (il.eq.iacnl(ih)) .and. (vorz_r(iv,ih) .lt. 0)) goto 20
            Fe_m1(iv,il) = - A_e(iv-1,il)*vorfak(iv,il)/e_p1m0(iv-1,ih)
            Fe_00(iv,il) = - Fe_m1(iv,il)
            RS(iv,il)    = RS(iv,il)
     &                     - 2.*f_xsi(iv,il,ih)*qo_pot(il)*
     &                       vorfak(iv,il)/e_p1m0(iv-1,ih)
   20     continue
          rfl_o(il)=qo_pot(il)
        elseif (vorz_o(il,ih) .lt. 0) then
c  RB 1.Art, Dirichlet, Potential
          Fe_m1(iv,il) = 0.
          Fe_00(iv,il) = -0.5
          Fx_00(iv,il) = -0.5
          Fx_p1(iv,il) = 0.
          Fx_m1(iv,il) = 0.
          RS(iv,il)    =  -po_pot(il)
        endif
  210 continue

C-----------------------------------------------------------------------
C  rechts, d.h. Hangfuss
C-----------------------------------------------------------------------
      il=iacnl(ih)
       do 100 iv = 1,iacnv(ih)
c       write(6,*)'irbtyp(1,irb_r(iv,ih))',irbtyp(1,irb_r(iv,ih))
C*** pauschal
C-----------Null-Fluss
        if (irb_r(iv,ih) .eq. 0) then
          qr_pot(iv)=0.
C-----------Gravitationsfluss
        elseif (irb_r(iv,ih) .eq. -3) then
          qr_pot(iv)=durchl(iv,il)/sloper(iv,ih)
C-----------free outflow
        elseif (irb_r(iv,ih) .eq. -5) then
          if (q_xsi(iv, il-1) .gt. 0) then
		 qr_pot(iv)=q_xsi(iv, il-1)
	    elseif (q_xsi(iv, il-1) .le. 0) then
	     qr_pot(iv)=0
		end if
C-----------alten Wert festhalten
        elseif (irb_r(iv,ih) .eq. -4) then
          pr_pot(iv)=phialt(iv,il,ih)
C-----------Sickerrand (einseitige RB)
        elseif (irb_r(iv,ih) .eq. -10) then
          qr_pot(iv)=0.
          if (imod(iboden(iv,il  ,ih)) .eq. 1) then
C##modified by Theresa and Thomas 28.03.2008
           pr_pot(iv) = -0.63 +hko(iv,il,ih)                !- 1      jw
	    else
           write(6,*) ' Seepage boundary condition only defined for
     &		 VanGenuchten soil hydraulic model!'
		 stop 
	    end if 

C-----------atmosphaerisch (rechts: Vorfluter)
        elseif (irb_r(iv,ih) .eq. -99) then
          qr_pot(iv)=0.
          pr_pot(iv)=9999999.
C*** Zeitreihe
        else
C-------------Null-Fluss
          if (irbtyp(1,irb_r(iv,ih)) .eq. 0) then
		  if (lrintp(irb_r(iv,ih))) then
             qr_pot(iv)=strahl(dnull,rbpar(2,1,irb_r(iv,ih)),
     &            zrbf(1,irb_r(iv,ih)),zrbf(2,irb_r(iv,ih)),t_act+dt)
            else
             qr_pot(iv)=0.
          endif
C-------------Vorgegebener Fluss
          elseif (irbtyp(1,irb_r(iv,ih)) .eq. 1) then
            if (lrintp(irb_r(iv,ih))) then
                qr_pot(iv)=strahl(rbpar(1,1,irb_r(iv,ih)),
     &           rbpar(2,1,irb_r(iv,ih)),zrbf(1,irb_r(iv,ih)),
     &                                  zrbf(2,irb_r(iv,ih)),t_act+dt)
            else
               qr_pot(iv)=rbpar(1,1,irb_r(iv,ih))
            endif
C-------------Gravitationsfluss
          elseif (irbtyp(1,irb_r(iv,ih)) .eq. 3) then
            qr_pot(iv)=durchl(iv,il)/sloper(iv,ih)
C-------------Leakage-Rand (gemischte RB)
          elseif (irbtyp(1,irb_r(iv,ih)) .eq.  5) then
            qr_pot(iv)=rbpar(1,1,irb_r(iv,ih))*( rbpar(1,2,irb_r(iv,ih))
     &           -( hko(iv,il,ih)+ hkomin(ih)-psi(iv,il) ) )
C-------------Saugspannung
		elseif (irbtyp(1,irb_r(iv,ih)) .eq. -1) then
            if (auint .and. inter(ihgb(hangnr(ih)))) then
	        pr_pot(iv)=hko(iacnv(ih),il,ih)+y_bach(ihgb(hangnr(ih)))-
     &	    y_vorl(ihgb(hangnr(ih)))-hko(iv,il,ih)
            end if
            if (lrintp(irb_r(iv,ih))) then
              pr_pot(iv)=hko(iv,il,ih)-strahl(rbpar(1,1,irb_r(iv,ih)),
     &          rbpar(2,1,irb_r(iv,ih)),zrbf(1,irb_r(iv,ih)),
     &                                  zrbf(2,irb_r(iv,ih)),t_act+dt)
            else
               pr_pot(iv)=hko(iv,il,ih)-rbpar(1,1,irb_r(iv,ih))
            endif
C-------------Potential relativ zu *.GEO Datei
          elseif (irbtyp(1,irb_r(iv,ih)) .eq. -2) then
            if (lrintp(irb_r(iv,ih))) then
              pr_pot(iv)=strahl(rbpar(1,1,irb_r(iv,ih)),
     &          rbpar(2,1,irb_r(iv,ih)),zrbf(1,irb_r(iv,ih)),
     &                   zrbf(2,irb_r(iv,ih)),t_act+dt)-hkomin(ih)
            else
              pr_pot(iv)=rbpar(1,1,irb_r(iv,ih))-hkomin(ih)
            endif
C-------------alten Wert festhalten
          elseif (irbtyp(1,irb_r(iv,ih)) .eq. -4) then
            pr_pot(iv)=phialt(iv,il,ih)
C-------------Sickerrand (einseitige RB)
          elseif (abs(irbtyp(1,irb_r(iv,ih))) .eq. 10) then
            qr_pot(iv)=0.
            pr_pot(iv)=hko(iv,il,ih)
C-------------einseitige RB
          elseif (abs(irbtyp(1,irb_r(iv,ih))) .eq. 11) then
            qr_pot(iv)=rbpar(1,2,irb_r(iv,ih))
            pr_pot(iv)=hko(iv,il,ih)-rbpar(1,1,irb_r(iv,ih))
C-------------atmosphaerisch (rechts: Vorfluter)
          elseif (abs(irbtyp(1,irb_r(iv,ih))) .eq.  99) then
            stop '99 noch nicht implementiert'
          else
            stop 'Fehler am rechten Rand'
          endif
        endif					! end if rechter Rand

        if (vorz_r(iv,ih) .gt. 0) then
c  RB 2.Art, Neumann, Fluss
          if ( (iv.eq.1)         .and. (vorz_u(il,ih) .lt. 0)) goto 30
          if ( (iv.eq.iacnv(ih)) .and. (vorz_o(il,ih) .lt. 0)) goto 30
            Fx_m1(iv,il) = - A_x(iv,il-1)*vorfak(iv,il)/x_p1m0(il-1,ih)
     &                       *fbrlow(il,ih)
            Fx_00(iv,il) = - Fx_m1(iv,il)
            RS(iv,il)    = RS(iv,il)
     &                     - 2.*f_eta(iv,il,ih)*qr_pot(iv)*
     &                       vorfak(iv,il)/x_p1m0(il-1,ih)
   30     continue
          rfl_r(iv)=qr_pot(iv)
        elseif (vorz_r(iv,ih) .lt. 0) then
c  RB 1.Art, Dirichlet, Potential
          Fx_m1(iv,il) = 0.
          Fx_00(iv,il) = -0.5
          Fe_00(iv,il) = -0.5
          Fe_p1(iv,il) = 0.
          Fe_m1(iv,il) = 0.
          RS(iv,il)    = - pr_pot(iv)
	  endif
  100 continue

C-----------------------------------------------------------------------
C  links, d.h. Hangtop
C-----------------------------------------------------------------------
C*** pauschal
      il=1
      do 200 iv = 1,iacnv(ih)
C*** pauschal
C-----------Null-Fluss
        if (irb_l(iv,ih) .eq. 0) then
          ql_pot(iv)=0.
C-----------Gravitationsfluss
        elseif (irb_l(iv,ih) .eq. -3) then
          ql_pot(iv)=durchl(iv,il)/slopel(iv,ih)
C-----------alten Wert festhalten
        elseif (irb_l(iv,ih) .eq. -4) then
          pl_pot(iv)=phialt(iv,il,ih)
C-----------Sickerrand (einseitige RB)
        elseif (irb_l(iv,ih) .eq. -10) then
          ql_pot(iv)=0.
          pl_pot(iv)=hko(iv,il,ih)
C-----------atmosphaerisch (links: Null-Fluss)
        elseif (irb_l(iv,ih) .eq. -99) then
          ql_pot(iv)=0.
          pl_pot(iv)=9999999.
C*** Zeitreihe
        else
C-------------Null-Fluss
          if (irbtyp(1,irb_l(iv,ih)) .eq. 0) then
            if (lrintp(irb_l(iv,ih))) then
              ql_pot(iv)=strahl(dnull,rbpar(2,1,irb_l(iv,ih)),
     &             zrbf(1,irb_l(iv,ih)),zrbf(2,irb_l(iv,ih)),t_act+dt)
            else
              ql_pot(iv)=0.
            endif
C-------------Vorgegebener Fluss
          elseif (irbtyp(1,irb_l(iv,ih)) .eq. 1) then
            if (lrintp(irb_l(iv,ih))) then
              ql_pot(iv)=strahl(rbpar(1,1,irb_l(iv,ih)),
     &          rbpar(2,1,irb_l(iv,ih)),zrbf(1,irb_l(iv,ih)),
     &                                  zrbf(2,irb_l(iv,ih)),t_act+dt)
            else
              ql_pot(iv)=rbpar(1,1,irb_l(iv,ih))
            endif
C-------------Gravitationsfluss
          elseif (irbtyp(1,irb_l(iv,ih)) .eq. 3) then
            ql_pot(iv)=durchl(iv,il)/slopel(iv,ih)
C-------------Leakage-Rand (gemischte RB)
          elseif (irbtyp(1,irb_l(iv,ih)) .eq.  5) then
            ql_pot(iv)=rbpar(1,1,irb_l(iv,ih))*( rbpar(1,2,irb_l(iv,ih))
     &           -( hko(iv,il,ih)+ hkomin(ih)-psi(iv,il) ) )
C-------------Saugspannung
          elseif (irbtyp(1,irb_l(iv,ih)) .eq. -1) then
            if (lrintp(irb_l(iv,ih))) then
              pl_pot(iv)=hko(iv,il,ih)-strahl(rbpar(1,1,irb_l(iv,ih)),
     &          rbpar(2,1,irb_l(iv,ih)),zrbf(1,irb_l(iv,ih)),
     &                                  zrbf(2,irb_l(iv,ih)),t_act+dt)
            else
              pl_pot(iv)=hko(iv,il,ih)-rbpar(1,1,irb_l(iv,ih))
            endif
C-------------Potential relativ zu *.GEO Datei
          elseif (irbtyp(1,irb_l(iv,ih)) .eq. -2) then
            if (lrintp(irb_l(iv,ih))) then
              pl_pot(iv)=strahl(rbpar(1,1,irb_l(iv,ih)),
     &          rbpar(2,1,irb_l(iv,ih)),zrbf(1,irb_l(iv,ih)),
     &                   zrbf(2,irb_l(iv,ih)),t_act+dt)-hkomin(ih)
            else
              pl_pot(iv)=rbpar(1,1,irb_l(iv,ih))-hkomin(ih)
            endif
C-------------alten Wert festhalten
          elseif (irbtyp(1,irb_l(iv,ih)) .eq. -4) then
            pl_pot(iv)=phialt(iv,il,ih)
C-------------Sickerrand (einseitige RB)
          elseif (abs(irbtyp(1,irb_l(iv,ih))) .eq. 10) then
            ql_pot(iv)=0.
            pl_pot(iv)=hko(iv,il,ih)
C-------------einseitige RB
          elseif (abs(irbtyp(1,irb_l(iv,ih))) .eq. 11) then
            ql_pot(iv)=rbpar(1,2,irb_l(iv,ih))
            pl_pot(iv)=hko(iv,il,ih)-rbpar(1,1,irb_l(iv,ih))
C-------------atmosphaerisch (links: Null-Fluss)
          elseif (abs(irbtyp(1,irb_l(iv,ih))) .eq.  99) then
            stop '99 noch nicht implementiert'
          else
            stop 'Fehler am linken Rand'
          endif
        endif

        if (vorz_l(iv,ih) .gt. 0) then
c RB 2.Art, Neumann, Fluss
          if ( (iv.eq.1)         .and. (vorz_u(il,ih) .lt. 0)) goto 40
          if ( (iv.eq.iacnv(ih)) .and. (vorz_o(il,ih) .lt. 0)) goto 40
            Fx_p1(iv,il) = - A_x(iv,il)*vorfak(iv,il)/x_p1m0(il,ih)
     &                       *fbrup(il,ih)
            Fx_00(iv,il) = - Fx_p1(iv,il)
            RS(iv,il)    = RS(iv,il)
     &                     + 2.*f_eta(iv,il,ih)*ql_pot(iv)*
     &                       vorfak(iv,il)/x_p1m0(il,ih)
   40     continue
          rfl_l(iv)=ql_pot(iv)
        elseif (vorz_l(iv,ih) .lt. 0) then
c RB 1.Art, Dirichlet, Potential
          Fx_p1(iv,il) = 0.
          Fx_00(iv,il) = -0.5
          Fe_00(iv,il) = -0.5
          Fe_p1(iv,il) = 0.
          Fe_m1(iv,il) = 0.
          RS(iv,il)    = - pl_pot(iv)
        endif
  200 continue

      return
      end
