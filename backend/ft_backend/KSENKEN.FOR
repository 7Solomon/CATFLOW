      subroutine ksenken(ih,dt)
c-----------------------------------------------------------------------
      include 'dim.inc'
      include 'hgfest.inc'
      include 'hgvari.inc'
      include 'hgbdry.inc'
      include 'zeit.inc'

      integer*4 iv,il,ih
      real*8 dt, dnull, strahl

      external strahl
      intrinsic abs

      dnull=0.

      do 100 il = 2,iacnl(ih)-1
        do 200 iv = 2,iacnv(ih)-1
C-----------keine Senke
        if (isnk(iv,il,ih) .eq. 0) then
          qs_pot(iv,il)=0.
C-----------alten Wert festhalten
        elseif (isnk(iv,il,ih) .eq. -4) then
          ps_pot(iv,il)=phialt(iv,il,ih)
C-----------Sickerrand (einseitige RB)
        elseif (isnk(iv,il,ih) .eq. -10) then
          qs_pot(iv,il)=0.
          ps_pot(iv,il)=hko(iv,il,ih)
C-----------atmosphaerisch
        elseif (isnk(iv,il,ih) .eq. -99) then
          if (plrw(iv,il) .gt. 0.) then
c Senke:  Fluss, positiv aus Volumen heraus [1/s] 
c           ! jw varbr?
            qs_pot(iv,il)=Ecanop(il)*dr_o(il,ih)*slopeo(il,ih)*    
     &                    plrw(iv,il)/area(iv,il,ih)
           if( qs_pot(iv,il) .lt. 0.) then
	      write(io(1),*) Ecanop(il), dr_o(il,ih), il, slopeo(il,ih)
            write(io(1),*) plrw(iv,il), area(iv,il,ih), 'senke negativ'
	     end if
          else
            qs_pot(iv,il)=0.
          endif
          ps_pot(iv,il)=hko(iv,il,ih)-10.**4.2/100.             ! 
c           jw ps_pot negativ ?

C*** Zeitreihe
        else
C-------------keine Senke
          if (isktyp(1,isnk(iv,il,ih)) .eq. 0) then
            if (lsintp(isnk(iv,il,ih))) then
              qs_pot(iv,il) = strahl(dnull,
     &          skpar(2,1,isnk(iv,il,ih)),zsnk(1,isnk(iv,il,ih)),
     &                                zsnk(2,isnk(iv,il,ih)),t_act+dt)
            else
              qs_pot(iv,il)=0.
            endif
C-------------vorgegebener Fluss [1/s]
          elseif (isktyp(1,isnk(iv,il,ih)) .eq. 1) then
            if (lsintp(isnk(iv,il,ih))) then
              qs_pot(iv,il) = strahl(skpar(1,1,isnk(iv,il,ih)),
     &          skpar(2,1,isnk(iv,il,ih)),zsnk(1,isnk(iv,il,ih)),
     &                                zsnk(2,isnk(iv,il,ih)),t_act+dt)
            else
              qs_pot(iv,il) = skpar(1,1,isnk(iv,il,ih))
            endif
C-------------vorgegebener Fluss [m*m/s]
          elseif (isktyp(1,isnk(iv,il,ih)) .eq. 2) then
            qs_pot(iv,il) = skpar(1,1,isnk(iv,il,ih))/area(iv,il,ih)
C-------------Saugspannung
          elseif (isktyp(1,isnk(iv,il,ih)) .eq. -1) then
            if (lsintp(isnk(iv,il,ih))) then
              ps_pot(iv,il) = hko(iv,il,ih)-
     &          strahl(skpar(1,1,isnk(iv,il,ih)),
     &          skpar(2,1,isnk(iv,il,ih)),zsnk(1,isnk(iv,il,ih)),
     &                                zsnk(2,isnk(iv,il,ih)),t_act+dt)
            else
              ps_pot(iv,il) = hko(iv,il,ih)-skpar(1,1,isnk(iv,il,ih))
            endif
C-------------Potential relativ zu *.GEO Datei
          elseif (isktyp(1,isnk(iv,il,ih)) .eq. -2) then
            if (lsintp(isnk(iv,il,ih))) then
              ps_pot(iv,il) = strahl(skpar(1,1,isnk(iv,il,ih)),
     &          skpar(2,1,isnk(iv,il,ih)),zsnk(1,isnk(iv,il,ih)),
     &                   zsnk(2,isnk(iv,il,ih)),t_act+dt)-hkomin(ih)
            else
              ps_pot(iv,il) = skpar(1,1,isnk(iv,il,ih))-hkomin(ih)
            endif
C-------------alten Wert festhalten
          elseif (isktyp(1,isnk(iv,il,ih)) .eq. -4) then
            ps_pot(iv,il) = phialt(iv,il,ih)
C-------------Sickerrand (einseitige RB)
          elseif (abs(isktyp(1,isnk(iv,il,ih))) .eq. 10) then
            qs_pot(iv,il)=0.
            ps_pot(iv,il)=hko(iv,il,ih)
C-------------einseitige RB
          elseif (abs(isktyp(1,isnk(iv,il,ih))) .eq. 11) then
            qs_pot(iv,il)=skpar(1,2,isnk(iv,il,ih))
            ps_pot(iv,il)=hko(iv,il,ih)-skpar(1,1,isnk(iv,il,ih))
C-------------atmosphaerisch
          elseif (isktyp(1,isnk(iv,il,ih)) .eq. 99) then
            stop '99 noch nicht implementiert'
          else
            stop 'Fehler im Senkenterm'
          endif
        endif

        if (vorz_s(iv,il,ih) .gt. 0) then
c Senke:  Fluss, positiv aus Volumen heraus [1/s]
          RS(iv,il) = RS(iv,il) - vorfak(iv,il)*qs_pot(iv,il)
     &                           *f_xsi(iv,il,ih)*f_eta(iv,il,ih)
          senk(iv,il) = qs_pot(iv,il)
        elseif (vorz_s(iv,il,ih) .lt. 0) then
c  Senke: Potentialbedingung
          Fx_m1(iv,il) = 0.
          Fx_p1(iv,il) = 0.
          Fx_00(iv,il) = -0.5
          Fe_00(iv,il) = -0.5
          Fe_p1(iv,il) = 0.
          Fe_m1(iv,il) = 0.
          RS(iv,il)    = -ps_pot(iv,il)
        endif

  200   continue
  100 continue

      return
      end
