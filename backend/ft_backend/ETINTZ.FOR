      subroutine etintz(ih,dt)

      include 'dim.inc'
      include 'zeit.inc'
      include 'soil.inc'
      include 'hgbdry.inc'
      include 'hgfest.inc'
      include 'hgvari.inc'

      integer ih, il
      real*8  dt, itags

      external kolle, etidir
      intrinsic dble, dabs
      save itags

      data itags /0./

      if (lklima) then

c-- fuer den gesamten Hang ---------------------------------------------
        do 1000 il=1,iacnl(ih)
          if (ktyp(ifixob(il,3,ih)) .eq. 1) then
            call kolle(il,ih,dt)
          elseif (ktyp(ifixob(il,3,ih)) .eq. 2) then
            call etidir(il,ih,dt)
          endif
          if (Ecanop(il) .lt. 0.) Ecanop(il)=0.
 1000   continue
        itags=itag
      else
        do 2000 il=1,iacnl(ih)
          neff(il)=nied(1,ifixob(il,2,ih))
          Esoil(il)=0.
 2000   continue
      endif

      return
      end


      subroutine etidir(il,ih,dt)
c-----------------------------------------------------------------------
c     Verdunstung Direkteingabe
c-----------------------------------------------------------------------
      include 'dim.inc'
      include 'zeit.inc'
      include 'soil.inc'
      include 'hgbdry.inc'
      include 'hgfest.inc'
      include 'hgvari.inc'

      real*8 strahl
      real*8 aroot, plrwt
      integer ih, il, iv
      real*8  dt, twu, wufak

      external strahl

      neff(il)=nied(1,ifixob(il,2,ih))
      Eintz(il)=0.
      Esoil(il) =strahl(klima(1,1,ifixob(il,3,ih)),
     &                  klima(2,1,ifixob(il,3,ih)),
     &                           zkli(1,ifixob(il,3,ih)),
     &                           zkli(2,ifixob(il,3,ih)),t_act+dt)
      Ecanop(il)=strahl(klima(1,2,ifixob(il,3,ih)),
     &                  klima(2,2,ifixob(il,3,ih)),
     &                           zkli(1,ifixob(il,3,ih)),
     &                           zkli(2,ifixob(il,3,ih)),t_act+dt)
      twu       =strahl(klima(1,3,ifixob(il,3,ih)),
     &                  klima(2,3,ifixob(il,3,ih)),
     &                           zkli(1,ifixob(il,3,ih)),
     &                           zkli(2,ifixob(il,3,ih)),t_act+dt)
c---wenn hier die Anzahl der Eingabewerte veraendert wird,
c   muss auch in RDRBS der Parameter IACKLD angepasst sein!!!!


c-------- mittlere Feuchte in der Wurzelzone (plant reachable water)
      plrwt=0.
      aroot=0.
      do 103 iv=1,iacnv(ih)
        plrw(iv,il)=0.
  103 continue
      if (twu .gt. 0.) then
        do 100 iv=iacnv(ih)-1,1,-1
          if (depth(iv,il,ih) .le. twu) then
            plrw(iv,il)=
     &         (theta(iv,il)-th_pwp(iboden(iv,il,ih)))*area(iv,il,ih)
            if (plrw(iv,il) .lt. 0.) plrw(iv,il)=0.
            plrwt=plrwt+plrw(iv,il)
            aroot=aroot+area(iv,il,ih)
            ivroot(il)=iv
          else
            if ((iv.gt.1) .and. (depth(iv+1,il,ih).le.twu)) then
              wufak=(twu-depth(iv+1,il,ih))/
     &              (depth(iv,il,ih)-depth(iv+1,il,ih))
              plrw(iv,il)=
     &         (theta(iv,il)-th_pwp(iboden(iv,il,ih)))*area(iv,il,ih)
     &         *wufak
              if (plrw(iv,il) .lt. 0.) plrw(iv,il)=0.
              aroot=aroot+area(iv,il,ih)*wufak
              ivroot(il)=iv
            endif
            goto 101
          endif
  100   continue
  101   continue
        if (plrwt .le. 0.) then
          Ecanop(il)=0.
        else
          do 102 iv=iacnv(ih)-1,ivroot(il),-1
            plrw(iv,il)=plrw(iv,il)/plrwt
  102     continue
        endif
      else
        Ecanop(il)=0.
      endif

      return
      end


      subroutine kolle(il,ih,dt)
c-----------------------------------------------------------------------
c     Berechnung von Verdunstung und Interzeption nach Olaf Kolle
c-----------------------------------------------------------------------

      include 'dim.inc'
      include 'zeit.inc'
      include 'soil.inc'
      include 'hgbdry.inc'
      include 'hgfest.inc'
      include 'hgvari.inc'

      real*8 msmmd
      integer iv, il, ih, iwrf
      real*8 dt, strahl
      logical hoch, tief
      integer ipos
      real*8 lai, bbg, twu, wufak, pfh, palb, balb, saett, albedo
      real*8 rGlo, rBil, rBilm, temp, relhum, uref, uricht
c      real*8 s_cov, f_cov, wicht1
      real*8 shf, rBilc, rBils, p_atm, druck
      real*8 ustar, u100, r_at, ratmos, rblpfl, catmp, rblp
      real*8 thplrw, aroot, cinf, plrwt
      real*8 rcut, f_stom, rstmin, f_rad, f_hum, f_bfw, wp_bfw
      real*8 ssintz, potint, rainc, rains, penmon, f_intz
      real*8 rcanop, ccanop, rblsoi, catms, rbls
      real*8 csoil, rsoil, e_sat, rh_kor
      real*8 sConst, PI, PI2
      real*8 zenit, optmas, radhor, radslo, rDiff, radfak
      real*8 e_act, truebe, swrBil
      real*8 sunazi, sunele, ar, elevat, zenslo, horiz
      real*8 x1, y1, z1, x2, y2, z2
      integer ihor, ibod, ikli

      external lookup, strahl, druck, uschub, e_sat
      external rsoil, rcanop, ratmos, rblp, rbls, penmon
      external sunpos
c      external wicht1

      intrinsic dble, atan, acos, int
      intrinsic sin, cos, exp

      PARAMETER (PI = 3.14159265359D0, PI2 = PI/2.0)
c-- Solarkonstante
      PARAMETER (SCONST = 1367.) ! 1325 - 1420 W/m², gesetzt: 1367 W/m²

c-- Faktor  m/s -> mm/d
      msmmd=86400000.
      hoch=.false.
      tief=.false.

      ipos=int(dble(iacpft(iusenr(il,ih)))/2.)
      call lookup(pflpar(1,1,iusenr(il,ih)),pflpar(1,4,iusenr(il,ih)),
     &            iacpft(iusenr(il,ih)),itag,lai,hoch,tief,ipos)
      call lookup(pflpar(1,1,iusenr(il,ih)),pflpar(1,5,iusenr(il,ih)),
     &            iacpft(iusenr(il,ih)),itag,bbg,hoch,tief,ipos)
      call lookup(pflpar(1,1,iusenr(il,ih)),pflpar(1,6,iusenr(il,ih)),
     &            iacpft(iusenr(il,ih)),itag,twu,hoch,tief,ipos)
      call lookup(pflpar(1,1,iusenr(il,ih)),pflpar(1,7,iusenr(il,ih)),
     &            iacpft(iusenr(il,ih)),itag,pfh,hoch,tief,ipos)
      call lookup(pflpar(1,1,iusenr(il,ih)),pflpar(1,8,iusenr(il,ih)),
     &            iacpft(iusenr(il,ih)),itag,palb,hoch,tief,ipos)

      ikli=ifixob(il,3,ih)
c Klimadateien auswerten:
c  Globalstr., Str.bilanz, Temperatur, rel. Luftf., Windgeschw., Windricht.
c   [w/m*m]      [w/m*m]     [øc]      [%] (0..100)   [m/s]     [1...iwrf]
c    rGlo,        rBil,      temp,        relhum,      uref,       uricht
       rGlo  =strahl(klima(1,1,ikli),klima(2,1,ikli),
     &               zkli(1,ikli),zkli(2,ikli),t_act+dt)
c wird berechnet, s.u.
       rBilm  =strahl(klima(1,2,ikli),klima(2,2,ikli),
     &              zkli(1,ikli),zkli(2,ikli),t_act+dt)
       temp  =strahl(klima(1,3,ikli),klima(2,3,ikli),
     &               zkli(1,ikli),zkli(2,ikli),t_act+dt)
       relhum=strahl(klima(1,4,ikli),klima(2,4,ikli),
     &               zkli(1,ikli),zkli(2,ikli),t_act+dt)/100.
       uref  =strahl(klima(1,5,ikli),klima(2,5,ikli),
     &               zkli(1,ikli),zkli(2,ikli),t_act+dt)
       uricht=strahl(klima(1,6,ikli),klima(2,6,ikli),
     &               zkli(1,ikli),zkli(2,ikli),t_act+dt)
c---wenn hier die Anzahl der Eingabewerte veraendert wird,
c   muss auch in RDRBS der Parameter IACKLD angepasst sein!!!!
      do 120 iwrf=1,iacwrf
        if  (wro(iwrf) .lt. wru(iwrf)) then
          if (((uricht .le. wro(iwrf)) .and. (uricht .gt. 0.)) .or.
     &       ((uricht .le. 360.) .and. (uricht .gt. wru(iwrf)))) then
            uref=uref/bezfak(iwrf,ikli)*wrf(il,iwrf,ih)
            goto 121
          endif
        else
          if ((uricht .le. wro(iwrf)).and.(uricht .gt. wru(iwrf))) then
            uref=uref/bezfak(iwrf,ikli)*wrf(il,iwrf,ih)
            goto 121
          endif
        endif
  120 continue
  121 continue
      if (uref .le. 0.) uref=1.e-10

c-------- Atmosphaerendruck
      p_atm=druck(temp,hko(iacnv(ih),il,ih)+hkomin(ih))
c-------- aktueller Dampfdruck
      e_act=e_sat(temp)*relhum

c---------CALCULATION OF ATMOSPHERIC DIMMING UNDER CONSIDERATION
c         OF WATER VAPOUR PRESSURE:  Truebungsfaktor (???)
c         trueb  und  truebf  muessen mit gemessenen Daten
c         an klaren Tagen mit voller Sonnenstrahlung angepasst werden.
      truebe = trueb(ikli)+truebf(ikli)*e_act

C---------CALCULATION OF THE DIRECT SOLAR RADIATION ON
C         HORIZONTAL TERRAIN (RADHOR)

      call sunpos(itag,stunde,longi,lati,rlongi,sunazi,sunele)
      if (sunele .gt. 0.) then
        zenit = PI2-sunele
        optmas = sin(1.570717963)/sin(PI-zenit-1.570717963)
        optmas = optmas*p_atm/1013.
        ar = 0.02218+0.09024/(1.+0.0170227*optmas)
        radhor = sConst*exp(-ar*truebe*optmas)*cos(zenit)
      else
        radhor = 0.
        zenit = -99.9/180.*PI
      endif

C---------CALCULATION OF THE DIRECT SOLAR RADIATION ON
C         SLOPING TERRAIN (RADSLO)

      if ((radhor .gt. 0.) .and. (radhor .lt. rGlo)) then
        if (sunele .lt. 0.) sunele = 0.00001
c-- Vektor des Sonnenstandes
        x1=sin(sunazi)*cos(sunele)
        y1=cos(sunazi)*cos(sunele)
        z1=            sin(sunele)
c-- Vektor des Flaechennormalen
        elevat=PI2-atan(gefall(il,ih))
        x2=sin(azimut(il,ih))*cos(elevat)
        y2=cos(azimut(il,ih))*cos(elevat)
        z2=                   sin(elevat)
c-- Zenitwinkel auf schiefe Flaeche
        zenslo=acos(x1*x2+y1*y2+z1*z2)

        if (iachor .gt. 0) then
c-- Auffinden der passenden Horizontueberhoehung und Decodierung
          ihor=int(dble(iachor)*sunazi/2./PI+1)
          if (hor(il,ihor,ih) .eq. -9) then
            horiz = 0.
          else
            horiz = dble(hor(il,ihor,ih)-50)*PI/180.
          endif
        else
          horiz = 0.
        endif

        if ((zenslo .lt. PI2) .and. (sunele .gt. horiz)) then
          zenit = PI2-sunele
          optmas = sin(1.570717963)/sin(PI-zenit-1.570717963)
          optmas = optmas*p_atm/1013.
          ar = 0.02218+0.09024/(1.+0.0170227*optmas)
          radslo = sConst*exp(-ar*truebe*optmas)*cos(zenslo)
        else
          radslo = 0.
        endif
      else
        radslo = 0.
        zenslo = -88.8/180.*PI
      endif

C---------DIFFUSE SOLAR RADIATION: rDiff
C---------GLOBAL RADIATION ON SLOPING TERRAIN: radslo
      if (rGlo .gt. 0.) then
        if (radhor .lt. rGlo) then
          rDiff=rGlo-radhor
          radslo=radslo+rDiff
        else
          radslo=rGlo
        endif
C---------FACTOR FOR THE GLOBAL RADIATION
        radfak = radslo/rGlo
        rGlo=radslo
      endif

c------- Aufteilung Strahlung (SIGMA bei O. Kolle = bbg)
c        hier: Bodenbedeckungsgrad wird pflanzenspezifisch vorgegeben
c##      s_cov=1.5
c##      f_cov=3.0
c##      bbg=wicht1(f_cov,lai,s_cov)

c Berechnung der Strahlungsbilanz, abhaengig von der kurzwelligen
c Strahlungsbilanz; dazu ist die Berechnung der Albedo notwendig,
c die wiederum abhaengig von Bodenart und Feuchte ist
       if (rGlo .gt. 1.) then
c Saettigungsgrad der obersten Bodenschicht
         ibod=iboden(iacnv(ih),il,ih)
         saett = theta(iacnv(ih),il)/
     &           s_tab(iactab(ibod),1,ibod)
         if (saett .lt. satkni(ibod)) then
           balb=(balmax(ibod)*(satkni(ibod)-saett)
     &          +balmin(ibod)*(             saett))/satkni(ibod)
         else
           balb=balmin(ibod)
         endif
c Bodenalbedo is 0.34 -0.46/theta/theta_s (>0,5,) 0.11 sonst         
         albedo=balb*(1.-bbg)+palb*bbg
         swrBil=rGlo*(1.-albedo)
         rBil= sw0(ikli)+(sw1(ikli)+sw2(ikli)*swrBil)*swrBil
C---------NET RADIATION ON SLOPING TERRAIN
c Dies ist nicht noetig, da bereits rGlo den Einfluss der geneigten
c Flaeche erfasst (siehe oben) !????
c         if (rGlo .gt. 10.) rBil=rBil*radfak
       else
         rBil= -25.
         albedo=-9.9
       endif

c-------- soil-heat-flux
      if (rBil .gt. 0.) then
        shf = 0.32*rBil*(1.-bbg)
      else
        shf = 0.69*rBil*(1.-bbg)
      endif

c-------- Strahlung auf Canopy und Soil
c schrott      if (rBil .le. 0.) rBil=0.
      rBilc = (rBil-shf)*bbg
      rBils = (rBil-shf)*(1.-bbg)

c-------- Schubspannungsgeschwindigkeit
      call uschub(uref,zref(ikli),pfh,rGlo,rBil,ustar,u100)
c-------- atmosphaerischer Widerstand
      r_at=ratmos(u100,ustar)

c-------- mittlere Feuchte in der Wurzelzone (plant reachable water)
        plrwt=0.
        aroot=0.
        do 103 iv=1,iacnv(ih)
          plrw(iv,il)=0.
  103   continue
        if (twu .gt. 0.) then
          do 100 iv=iacnv(ih)-1,1,-1
            if (depth(iv,il,ih) .le. twu) then
c   -0.001, damit der permanente Welkepunkt bestimmt nicht auch
c           nur knapp unterschritten wird!!
              plrw(iv,il)=
     &           (theta(iv,il)-th_pwp(iboden(iv,il,ih))-0.001)
     &           *area(iv,il,ih)
              if (plrw(iv,il) .lt. 0.) plrw(iv,il)=0.
              plrwt=plrwt+plrw(iv,il)
              aroot=aroot+area(iv,il,ih)
              ivroot(il)=iv
            else
              if ((iv.gt.1) .and. (depth(iv+1,il,ih).le.twu)) then
                wufak=(twu-depth(iv+1,il,ih))/
     &                (depth(iv,il,ih)-depth(iv+1,il,ih))
                plrw(iv,il)=
     &             (theta(iv,il)-th_pwp(iboden(iv,il,ih))-0.001)
     &             *area(iv,il,ih)*wufak
                if (plrw(iv,il) .lt. 0.) plrw(iv,il)=0.
                aroot=aroot+area(iv,il,ih)*wufak
                ivroot(il)=iv
              endif
              goto 101
            endif
  100     continue
  101     continue
          if (plrwt .le. 0.) then
            thplrw=0.
          else
            thplrw=plrwt/aroot
            do 102 iv=iacnv(ih)-1,ivroot(il),-1
              plrw(iv,il)=plrw(iv,il)/plrwt
  102       continue
          endif
        else
          thplrw=0.
        endif

      if (lai .gt. 0.0001) then
c-------- atmosphaerischer Widerstand fuer Pflanzen
c      charakteristisches Laengenmass
        rblpfl=0.1
        catmp=1./(r_at+rblp(u100,pfh,rblpfl))

c  INTERZEPTION
c           interz  aktueller Interz.speicher in m
c--------- 'unendliche' Oberflaechenleitfaehigkeit
        cinf=9.e20
c--------- lai-spez.potentieller Interz.speicher in m (0.0001 m)
        ssintz=0.0001
c--------- Regen auf Canopy und Soil (in m)
        rainc=nied(1,ifixob(il,2,ih))*dt*bbg
        rains=nied(1,ifixob(il,2,ih))*dt*(1.-bbg)
c--------- potentielle (zusaetzliche) Interzeption
        potint=ssintz*lai-interz(il)
        if (potint .lt. 0.) then
c--------- d.h. Ueberschusswasser faellt auf den Boden
          rains=rains+potint
c          ...und der Rest fuellt den gesamten Interzeptionsspeicher
          interz(il)=ssintz*lai
c          ...d.h. kein zusaetzlich zu fuellendes Volumen
          potint=0.
        endif
c--------- aktuelle Interzeption und effektiver Niederschlag
        if (potint .ge. rainc) then
c          d.h. der gesamte Regen fuellt den Speicher...
          interz(il)=interz(il)+rainc
c          ...und effektiv wird nur der direkte Regenfall auf den Boden
          neff(il)=rains/dt
        else
c          ansonsten wird der Interzeptionsspeicher voll...
          interz(il)=interz(il)+potint
c          ...und der Ueberschuss faellt auf den Boden
          neff(il)=(rains+rainc-potint)/dt
        endif
        if (interz(il) .gt. 0.) then
c--------- Interzeptionsverdunstung
          Eintz(il)=penmon(temp, rBilc, catmp, cinf, relhum, p_atm)*dt
          if (Eintz(il) .lt. 0.) Eintz(il) = 0.
          if (Eintz(il) .ge. interz(il)) then
            Eintz(il) = interz(il)/dt
            interz(il) = 0.
          else
            interz(il) = interz(il)-Eintz(il)
            Eintz(il) = Eintz(il)/dt
          endif
        else
          if (interz(il) .lt. 0.) then
            write(io(1),*) 'interz < 0'
          endif
          Eintz(il)=0.
        endif

c TRANSPIRATION
c--------- Erhoehung des Pflanzenwiderstandes bei benetzten Pflanzen
        f_intz=interz(il)/(lai*ssintz)
c--------- Pflanzenwiderstand
c        Cuticula-Widerstand
        rcut=3000.
c        beteiligte Blattseiten 1...2
        f_stom=2.
cccc     minimaler Stomatawiderstand (wichtig)
      call lookup(pflpar(1,1,iusenr(il,ih)),pflpar(1,9,iusenr(il,ih)),
     &            iacpft(iusenr(il,ih)),itag,rstmin,hoch,tief,ipos)
c        Faktor fuer Strahlungseinfluss
        f_rad=20.
c        Faktor fuer Luftfeuchteeinfluss
        f_hum=0.015
cccc   Wichtungsfunktion fuer Bodenfeuchteeinfluss (Neigung u. Wendepunkt)
c      typisch: f_bfw=30.  wp_bfw=0.05
      call lookup(pflpar(1,1,iusenr(il,ih)),pflpar(1,10,iusenr(il,ih)),
     &            iacpft(iusenr(il,ih)),itag,wp_bfw,hoch,tief,ipos)
      call lookup(pflpar(1,1,iusenr(il,ih)),pflpar(1,11,iusenr(il,ih)),
     &            iacpft(iusenr(il,ih)),itag,f_bfw,hoch,tief,ipos)
        ccanop=1./rcanop(f_intz,rcut,f_stom,
     &             rstmin,lai,rGlo,f_rad,f_hum,
     &             relhum,temp,thplrw,f_bfw,wp_bfw)
c--------- Pflanzentranspiration
        Ecanop(il)=penmon(temp, rBilc, catmp, ccanop, relhum, p_atm)
      else
        neff(il)=nied(1,ifixob(il,2,ih))+interz(il)/dt
        interz(il)=0.
        Eintz(il)=0.
        Ecanop(il)=0.
        ccanop=0.
        catmp=0.
      endif

c EVAPORATION
c-------- atmosphaerischer Widerstand fuer Boden
c      charakteristisches Laengenmass
      rblsoi=0.1
      catms=1./(r_at+rbls(u100,lai,rblsoi))
c-------- Bodenwiderstand
c      maximale Dicke der Diffusionsschicht
c      Wichtungsfunktion fuer Bodenfeuchteeinfluss (Neigung u. Wendepunkt)
c      typisch: f_rs=80. wp_rs=0.08
      ibod=iboden(iacnv(ih),il,ih)
      csoil=1./rsoil(zd_max(ibod), theta(iacnv(ih),il),
     &               s_tab(iactab(ibod),1,ibod),s_tab(1,1,ibod),
     &               f_rs(ibod), wp_rs(ibod), temp, relhum)
c-------- Korrektur der rel. Luftfeuchte abhaengig von der Verdunstung
      rh_kor = relhum+(Ecanop(il)+Eintz(il))*4.6152*
     &         (temp+273.15)/e_sat(temp)
      if (rh_kor .gt. 1.) rh_kor=1.
c-------- Bodenverdunstung
      Esoil(il)=penmon(temp, rBils, catms, csoil, rh_kor, p_atm)

c-----Taubildung
      if (Ecanop(il) .lt. 0.) then
        Esoil(il) = Esoil(il)+Ecanop(il)
        Ecanop(il) = 0.
      endif

c-----------------------------------------------------------------------
      if((io_act .ge. 11) .and. (il .eq. 38 .or. il .eq. 41 .or. 
     &  il .eq. 61) .and. (io_log(11) .gt. 0)) then
       ! etilog=.false.
        write(io(11),1111)
     &    hangnr(ih), il, t_act/86400., lai, bbg, twu, pfh, rGlo, rBil,
     &    rBilm, shf, temp, relhum, uref, albedo, ustar, u100, thplrw,
     &    interz(il)*1000.,
     &    nied(1,ifixob(il,2,ih))*msmmd, neff(il)*msmmd,
     &    catmp, ccanop, catms, csoil,
     &    Ecanop(il)*msmmd, Eintz(il)*msmmd, Esoil(il)*msmmd
c     &    sunele*180./PI, sunazi*180./PI,
c     &    zenit*180./PI, zenslo*180./PI,
c     &    (PI2-atan(gefall(il,ih)))*180./PI,
c     &    azimut(il,ih)*180./PI
      endif
 1111 format(i3,i3,2f7.2, 2f6.2, f7.2, 5f8.2, f6.2, f5.1,f6.2, 2f5.1,
     &   2f7.3,2f7.2,4e10.2,2f7.3, f8.3)
      return
      end

      double precision function penmon(t_a, rad, c_at, c_surf, w_a, p)
c-----------------------------------------------------------------------
c penman-monteith equation
c penmon(t_a, k, l, g, c_at, c_surf, w_a, p)        [m/s]
c        t_a    air temperature                     [øC]
c        rad    net radiation                       [W/m^2]
c            =  k      net shortwave radiation
c              +l      net longwave radiation
c              -g      heatconduction into the ground
c        c_at   atmospheric conductance             [m/s]
c                          e.g.  0.25
c        c_surf surface conductance                 [m/s]
c                 water    -> infinity
c                 soil     e.g.
c                 canopy   e.g   0.0025
c        w_a    relative humidity                   [-]
c        p      air pressure                        [mb]
c  e.g. Dingman (1993), p. 282
c-----------------------------------------------------------------------
      real*8 c_a, rho_a, rho_w, psychro, e_sat
      real*8 delta
      real*8 lam_v, s_e_sat, t_a, rad, c_at, c_surf, w_a, p

      external s_e_sat, e_sat, lam_v, psychro, rho_a

c  heat capacity of air [J/g/øC]
      c_a = 1.0046
c  density of water [g/cm^3]
      rho_w = 1.00000

      delta = s_e_sat(t_a)
      penmon = (delta*rad/1000000. +
     &     rho_a(t_a,p,w_a)*c_a*c_at*e_sat(t_a)*(1.-w_a))/
     &    (rho_w*lam_v(t_a)*(delta+psychro(t_a,p)*(1.+c_at/c_surf)))

      return
      end


      double precision function rho_a(t,p,w_a)
c-----------------------------------------------------------------------
c  rho_a       :    density of air [g/cm^3]
c  t           :    temperature [øC]
c  p           :    pressure [mb]
c  w_a         :    relative humidity [-]
c-----------------------------------------------------------------------
      real*8 e, e_sat, w_a, t, sf, p, tvk

      external e_sat

      e=e_sat(t)*w_a
      sf = 622.*e/(p-0.378*e)
      tvk = (t+273.15)*(1.+6.08e-4*sf)
      rho_a= p*0.1/(287.05*tvk)

      return
      end

      double precision function psychro(t,p)
c-----------------------------------------------------------------------
c  psychro(t,p):    psychrometric constant [mb/øC]
c  t           :    temperature [øC]
c  p           :    pressure [mb]
c  e.g. Dingman (1993), p. 258
c-----------------------------------------------------------------------
      real*8 c_a
      real*8 t, p, lam_v

      external lam_v

c  heat capacity of air [J/g/øC]
      c_a = 1.0046

      psychro = c_a * p/0.622/lam_v(t)

      return
      end


      double precision function lam_v(t)
c-----------------------------------------------------------------------
c  lam_v(t):    latent heat of vaporization [J/g]
c  t            temperature [øC]
c  e.g. Dingman (1993), p. 258
c-----------------------------------------------------------------------
      real*8 t

      lam_v = 2500.2978 - 2.3609 * t

      return
      end


      double precision function e_sat(t)
c-----------------------------------------------------------------------
c  e_sat(t):    saturation vapor pressure [mb]
c  t       :    temperature [øC]
c  e.g. Dingman (1993), p. 257
c-----------------------------------------------------------------------
      real*8 t
      real*8 a, b, c

      intrinsic dexp

      a = 6.1078
      b = 17.08085
      c = 234.175
      e_sat = a * dexp(b *t /(c+t))

      return
      end


      double precision function s_e_sat(t)
c-----------------------------------------------------------------------
c  s_e_sat(t):    slope of saturation vapor pressure [mb/øC]
c  t         :    temperature [øC]
c  e.g. Dingman (1993), p. 258
c-----------------------------------------------------------------------
      real*8 t
      real*8 a, b, c

      intrinsic dexp

      a = 6.1078
      b = 17.08085
      c = 234.175
      s_e_sat = a * dexp(b*t/(c+t)) *b*c/(c+t)/(c+t)

      return
      end


      double precision function wicht1(fak,var,wdepkt)
c-----------------------------------------------------------------------
c     wicht1:  0...1
c     Verlauf wie die Stammfunktion der Log-Normal-Verteilung,
c     Wendepunkt bei var=wdepkt
c-----------------------------------------------------------------------
      real*8 fak, var, wdepkt
      real*8 pih

      intrinsic datan

      pih=1.570796

      wicht1=1.-(pih-datan(fak*(var-wdepkt)))/(pih-datan(-fak*wdepkt))

      return
      end

      double precision function wicht2(var,varmin,varopt,varmax)
c-----------------------------------------------------------------------
c                                                var       wicht2
c     wicht2:  0...1                            varmin       0
c     Verlauf wie ein Halbkreisbogen            varopt       1
c     varmin < varopt < varmax                  varmax       0
c-----------------------------------------------------------------------
      real*8 var, varmin, varopt, varmax

      if ((var .lt. varmin).or.(var .gt. varmax)) then
        wicht2 = 0.
      else
        wicht2 = (var   -varmin)/(varopt-varmin) *
     &          ((varmax-var   )/(varmax-varopt))**
     &          ((varmax-varopt)/(varopt-varmin))
      endif

      return
      end

      double precision function rsoil(zd_max, th_top, th_max, th_min,
     &      f_rs, wp_rs, temp, relhum)
c-----------------------------------------------------------------------
c  determination of soil resistance [sec/m]:
c-----------------------------------------------------------------------
      real*8 zd_max, th_top, th_max, th_min, f_rs, wp_rs
      real*8 temp, relhum
      real*8 d0, zd, deff, fsw, wicht1, th_rel

      external wicht1

c--- Diffusionskoeffizient von Wasserdampf in Luft [m*m/s]
      d0=0.212d-4

      th_rel=(th_top-th_min)/(th_max-th_min)
      zd=zd_max/(1.+f_rs*th_rel)
      deff = d0*((temp+273.15)/273.15)**1.8
c     fsw = wicht1(f_rs,(th_top-th_min),wp_rs)
      fsw = wicht1(f_rs,th_rel,wp_rs)
      rsoil = zd/deff/fsw
c-------------------------------------------------------------- dewfall
      if (relhum .gt. 0.98) rsoil = rsoil/3.

      return
      end


      double precision function rcanop(f_intz,rcut,f_stom,
     &                 rstmin,lai,rGlo,frad,fhum,relhum,temp,
     &                 thplrw,f_bfw,wp_bfw)
c-----------------------------------------------------------------------
c  determination of canopy resistance [sec/m]:
c    f_intz  Faktor zur Erhoehung des Widerstands infolge Interzeption
c    rcut    cuticular resistance
c    f_stom  Faktor fuer Stomataverteilung (1...2 Blattseiten)
c    rstmin  minimaler Stomatawiderstand (120 s/m)
c    lai     Blattflaechenindex
c    rGlo    Globalstrahlung
c    frad    fuer Strahlungswichtung des Stomatawiderstands (20 [w/m*m])
c    fhum    Faktor fuer Feuchtewichtung des Stomatawiderstands (0.015 [1/mbar])
c    relhum  rel. Luftfeuchte [-]
c    temp    Temperatur [øc]
c    thplrw  theta_plant_reachable_water (integriert ueber Wurzelzone) [-]
c    f_bfw   Faktor der Bodenfeuchtewichtung des Stomatawiderstands (30)
c    wp_bfw  Wendepunkt der Bodenfeuchtewichtung des Stomatawiderstands (0.05)
c-----------------------------------------------------------------------
      real*8  f_intz, rcut, f_stom
      real*8  rstmin, lai, rGlo, frad, fhum, relhum, temp
      real*8  thplrw, f_bfw, wp_bfw
      real*8  par, fr, ft, fw
      real*8  tmin, topt, tmax
      real*8  wicht1, wicht2, e_sat, fh, rstoma, rleaf

      external wicht1, wicht2, e_sat

c--------------------------------------------------- radiation weight
c   par:   photosynthetic active radiation in w/m**2
      par=rGlo/2.
      if (par .lt. 1.) par = 1.
      fr = 1.+frad/par
c----------------------------------------------- rel. humididy weight
      fh = 1.-(fhum*e_sat(temp)*(1.-relhum))
      if (fh .lt. 0.001) fh = 0.001
c------------------------------------------------- temperature weight
      tmin=0.
      topt=25.
      tmax=45.
      ft=wicht2(temp,tmin,topt,tmax)
      if (ft .lt. 0.001) ft = 0.001
c------------------------------------------ soil water content weight
c  thplrw:   plant reachable water (-)
      fw=wicht1(f_bfw,thplrw,wp_bfw)
      if (fw .lt. 0.001) fw = 0.001
c---------------------------------------- weighted stomata resistance
      rstoma = rstmin*fr/(fh*ft*fw)
!      if (rstoma .gt. 8000.) rstoma = 8000.


c-------- leaf resistance = stomata and cuticular resistance parallel
      rleaf = rstoma !*rcut/(rstoma+rcut)

c--------------------------------- canopy resistance (two leaf sides)
      rcanop = rleaf/(f_stom*lai)

c-------------------------------- rainfall --> high canopy resistance
      rcanop = rcanop+3000.*f_intz

      return
      end

      double precision function ratmos(u100,ustar)
c-----------------------------------------------------------------------
c  determination of atmospheric resistance [sec/m]:
c      raero   aerodynamic resistance
c      rtrans  transfer resistance
c-----------------------------------------------------------------------
      real*8   raero, rtrans
      real*8   u100, ustar

      raero = (u100/ustar**2)
c----------------------------------ln(z0/z0') = 2
      rtrans = 2./(0.4*ustar)

      ratmos = raero+rtrans

      return
      end

      double precision function rblp(u100,hplant,rblpfl)
c-----------------------------------------------------------------------
c      rblp    boundary layer resistance for plants [sec/m]
c-----------------------------------------------------------------------
      real*8   u100, rblpfl, hplant
      real*8   u_pfl, sleaf

      intrinsic sqrt

      u_pfl= u100/10.
      if (u_pfl .lt. 0.01) u_pfl = 0.01
      sleaf = rblpfl*hplant
      if (sleaf .lt. 0.1) sleaf = 0.1
      rblp = 1000./(6.62*sqrt(u_pfl/sleaf))
      if (rblp .gt. 500.) rblp = 500.
      if (rblp .lt. 5.) rblp = 5.

      return
      end

      double precision function rbls(u100,lai,rblsoi)
c-----------------------------------------------------------------------
c      rbls    boundary layer resistance for soil [sec/m]
c-----------------------------------------------------------------------
      real*8   u100, rblsoi, lai
      real*8   usoil

      intrinsic sqrt

      if (lai .gt. 1.) then
        usoil = u100/50.
      else if (lai .gt. 0.) then
        usoil = u100/10.
      else
        usoil = u100/5.
      end if
      if (usoil .lt. 0.01) usoil = 0.01
      rbls = 1000./(6.62*sqrt(usoil/rblsoi))
      if (rbls .gt. 500.) rbls = 500.
      if (rbls .lt. 5.) rbls = 5.

      return
      end

      subroutine uschub(uref,zref,hplant,rGlo,rBil,ustar,u100)
c-----------------------------------------------------------------------
c  out:
c  ustar    friction velocity
c  u100     wind speed in boundary layer
c  in:
c  uref     wind speed in reference height
c  zref     Messhoehe der Windgeschwindigkeit
c  hplant   Pflanzenhoehe
c  rGlo     Globalstrahlung
c  rBil     Strahlungsbilanz
c-----------------------------------------------------------------------
      real*8 ustar, uref, zref, hplant, rGlo, rBil
      real*8 mix(6), a0(6), b0(6)
      real*8 rough, disph, u100, urn, rlmon, phim, pi2
      integer istab, nstab

      external nstab
      intrinsic dlog, datan

      data mix/0.07,0.13,0.21,0.34,0.44,0.44/
      data a0/-.1135,-.0385,-.0081,0.,.0081,.0385/
      data b0/-.1025,-.1710,-.3045,-.5030,-.3045,-.1710/

      pi2=1.570796

c-----------------------------------------------------------------------
c  disph:   displacement height
c-----------------------------------------------------------------------
      if (hplant .le. 0.) then
        rough = 0.01
        disph = 0.0
      else
        rough = hplant/10.
        disph = 2.*hplant/3.
      end if
      
      if((zref-disph) .le. 0) then
        stop 'displacement height > reference height'
      end if

c--calculation of stability class
      istab = nstab(uref,rGlo,rBil)

      rlmon = a0(istab)*rough**b0(istab)

c-------------------------------------------------------- unstable case
      if (istab .le. 3) then
        urn = 100.
        u100 = uref*(urn/(zref-disph))**mix(istab)
        phim = (1.-(15.*(urn-6.*rough)*rlmon))**(-0.25)
        ustar = u100*0.41/(
     &            dlog((urn-6.*rough)/rough)
     &          - 2.*dlog(0.5*(1.+(1./phim)))
     &          - dlog(0.5*(1.+(1./phim**2)))
     &          + 2.*datan(1./phim)
     &          - pi2 )
      end if
c--------------------------------------------------------- neutral case
      if (istab .eq. 4) then
        urn = 60.
        u100 = uref*(urn/(zref-disph))**mix(istab)
        ustar = u100*0.41/(
     &            dlog((urn-6.*rough)/rough)  )
      end if
c---------------------------------------------------------- stable case
      if (istab .ge. 5) then
        if (istab .eq. 5) urn = 20.
        if (istab .eq. 6) urn = 10.
        u100 = uref*(urn/(zref-disph))**mix(istab)
        ustar = u100*0.41/(
     &            dlog((urn-6.*rough)/rough)
     &          + 5.*(urn-6.*rough)*rlmon     )
      end if

      return
      end


      integer function nstab(v,g,rb)
c-----------------------------------------------------------------------
c  determination of the atmospheric stability as a function of
c  wind speed v, global radiation g and radiation balance rb
c-----------------------------------------------------------------------
      real*8 v, g, rb

      if (g .gt. 5.) then
        if (g .gt. 520.) then
          nstab = 1
          if (v .gt. 3.) nstab = 2
          if (v .gt. 5.) nstab = 3
        else
          if (g .gt. 280.) then
            nstab = 2
            if (v .gt. 3.) nstab = 3
            if (v .gt. 6.) nstab = 4
          else
            nstab = 2
            if (v .gt. 2.) nstab = 3
            if (v .gt. 5.) nstab = 4
          end if
        end if
      else
        if (rb .gt. -50.) then
          nstab = 6
          if (v .gt. 2.) nstab = 5
          if (v .gt. 3.) nstab = 4
        else
          nstab = 6
          if (v .gt. 3.) nstab = 5
          if (v .gt. 5.) nstab = 4
        end if
      end if

      return
      end

      double precision function druck(temp,hoehe)
c-----------------------------------------------------------------------
c  druck       :    Luftdruck [mb]
c  temp        :    Temperatur [øC]
c  hoehe       :    Hoehe [m+NN]
c-----------------------------------------------------------------------
      real*8 temp, hoehe, tempk, tmk

      intrinsic dexp

      tempk = temp+273.15
      tmk = (tempk+(tempk-0.65*hoehe/100.))/2.
      druck = 1013.*dexp(-(9.81*hoehe)/(287.05*tmk))

      return
      end

      double precision function dewp(t,w_a)
c-----------------------------------------------------------------------
c  dewp        :    dewpoint [øC]
c  t           :    temperature [øC]
c  w_a         :    relative humidity [-]
c-----------------------------------------------------------------------
      real*8 lne, e_sat, w_a, t

      external e_sat
      intrinsic dlog

      lne=dlog(e_sat(t)*w_a)
      dewp=(lne-1.810)/(0.0805-0.00421*lne)

      return
      end

      SUBROUTINE SUNPOS(I,HR,GEOLON,GEOLAT,RLONGI,AZI,ELE)
C-----------------------------------------------------------------------
c      HR        Stunde
c      I         Tag im Jahr
c      GEOLON    Longitude
c      GEOLAT    Latitude
c
c      AZI       Azimuth
c      ELE       Elevation
C-----------------------------------------------------------------------

      real*8 HR,AZI,ELE,I,GEOLON,GEOLAT,RLONGI
      real*8 PI
      PARAMETER (PI = 3.14159265359D0)
      real*8 X,ZG,TLT,TAU,DECLIN
      real*8 BRR,DELCOS,DELSIN,STW,STWCOS,BRSIN,BRCOS,ELSIN,CW
      real*8 ELCOS,AZCOS,Z

      intrinsic sin, cos, asin, acos

C------------------------------------- CALCULATION OF THE TIME EQUATION
C                                      AND THE TRUE LOCAL TIME (TLT)
      X  = (2.0*PI/365.25)*I
      ZG = .0106557377
     &     +7.41801326*SIN(    X+3.10532435)
     &     +9.88975023*SIN(2.0*X+3.52403347)
     &     +0.23786619*SIN(3.0*X+3.43780751)
     &     +0.19440123*SIN(4.0*X+3.78637068)
      TLT = HR-(RLONGI-GEOLON)*(4./60.)+ZG/60.

C--------------------------------------- CALCULATION OF THE DECLINATION
      TAU = (I+TLT/24.0-80.055)*(PI/182.625)
      DECLIN = ASIN(SIN(23.45*PI/180.0)*SIN(TAU))

C------------------------------------- AZIMUTH AND ELEVATION OF THE SUN
      BRR = PI*GEOLAT/180.0
      DELCOS = COS(DECLIN)
      DELSIN = SIN(DECLIN)
      STW = (TLT/12.0-1.0)*PI
      STWCOS = COS(STW)
      BRSIN = SIN(BRR)
      BRCOS = COS(BRR)
      ELSIN = BRSIN*DELSIN+BRCOS*DELCOS*STWCOS
      IF (ELSIN .GT. 1.) ELSIN = 1.
      IF (ELSIN .LT. -1.) ELSIN = -1.
      ELE = ASIN(ELSIN)
      ELCOS = COS(ELE)
      Z = BRSIN*DELCOS*STWCOS-BRCOS*DELSIN
      AZCOS = Z/ELCOS
      IF (AZCOS .GT. 1.) AZCOS = 1.
      IF (AZCOS .LT. -1.) AZCOS = -1.
      CW = ACOS(AZCOS)
      IF ((TLT-12.0) .LT. 0.0) THEN
        AZI = PI-CW
      ELSE
        AZI = PI+CW
      END IF

C-------------------------------------------------------- END OF SUNPOS
      RETURN
      END
