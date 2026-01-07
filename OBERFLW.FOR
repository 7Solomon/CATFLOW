      subroutine updyo(ih,dt,itp)           ! jw itp unused
c-----------------------------------------------------------------------
c   Abflusshoehen mit
c      kinematischer Welle  (Abfluss aus Sohlgefaelle)
c      Diffusionsanalogie   (Abfluss aus Wasserspiegelgefaelle)
c   Explizites Verfahren auf Basis des Zustandes (Abflusshoehe)
c   des vorherigen Zeitschritts unter Einhaltung des COURANT-Kriteriums.
c
c   ih: Hangnummer
c   dt: Zeitschritt; ueber dessen Laenge wird hier der Oberflaechenabfluss
c       in vielen kuerzeren Zeitschritten berechnet
c
c   So sieht beispielsweise die Hangdiskretisierung eines
c   Hangs (z.B. Hang 6) mit iacnv(ih)=5 vertikalen und
c   iacnl(ih)=7 lateralen Elementen aus:
c
c
c                                Oberflaeche
c    iacnv(ih) = 5    2-----2----2-------2------2------2-----2
c                     |     |    |       |      |      |     |
c                     |     |    |       |      |      |     |
c                4    1-----1----1-------1------1------1-----1
c                     |     |    |       |      |      |     |
c                     |     |    |       |      |      |     |
c                3    1-----1----1-------1------1------1-----1
c                     |     |    |       |      |      |     |
c                2    2-----2----2-------2------2------2-----2
c                     |     |    |       |      |      |     |
c           iv = 1    2-----2----2-------2------2------2-----2
c
c                il = 1     2    3       4      5      6     7 = iacnl(ih)
c
c
c     Die Zahlen im Gitter deuten die Bodenart an:
c
c     sei z.B. iv=2, il=5, ih=6. Dann ist IBODEN(iv,il,ih)=2,
c     d.h. Bodentyp 2.
c     Benoetigt man den Bodentyp der Bodenoberflaeche, dann ist immer
c     iv=iacnv(ih) und man waehlt IBODEN(iacnv(ih),il,ih)!!
c
c     Nach ganz aehnlichem Prinzip arbeiten Pflanzenparameter, nur dass
c     jetzt die vertikale Dimension wegfaellt: IUSENR(il,ih).
c     Im Feld PFLPAR stehen nun die Jahresgaenge der Pflanzenparameter
c     PFLPAR(izeit,ipar,iusenr)

      include 'dim.inc'
      include 'zeit.inc'
      include 'hgbdry.inc'
      include 'hgfest.inc'
      include 'hgvari.inc'

c   alle Variablen muessen erklaert werden
c   double precision, d.h. real*8 fuer REAL-Zahlen!!
      integer*4 ih, il, i, itp
      integer*4 icour, isur
      real*8 dt, dtsur, dtm
      real*8 cour, qp, yotst
      real*8 vo(maxnl), dq, yotest
      real*8 yo(maxnl), kgef
      real*8 qsum(maxnl)

      real*8 kst, vmitt, dnull, lokgef
      external kst, vmitt
cc      real*8 vrill
cc      external vrill

c  alle INTRINSIC FUNCTION muessen erklaert werden
      intrinsic dble, sqrt, min, max, int

      dnull=0.					! dummy fuer ersten Niederschlag in Ausgabe

      if (dt .le. 0.) then
        stop 'dt < 0 in UPYDO 3'
      endif


c	---------------------------------------------------------------------------


      icour=1
      dtm=dt_min/100.

C-----------------------------------------------------------------------
c  1000:  falls COURANT-Kriterium verletzt wird (s.u.) geht
c         die Berechnung ab hier nochmals los!!
C-----------------------------------------------------------------------

c    yo: Wassertiefe senkrecht zur Oberflaeche, lokal (hier) verwendet
c    yoben: hydraulisch effektive Wassertiefe senkrecht zur Oberflaeche,
c		  projiziert in die Vertikale (nach Scherer, U), global verwendet

 1000 continue
      yotest=0.
      do 100 il=1,iacnl(ih)
        lrill(il,ih)=.false.
        yo(il)=yoben(il)/slopeo(il,ih)
        if (yo(il) .gt. yotest) yotest=yo(il)
        qsum(il)=0.							! jw qsum für zeitschritt initialisieren
  100 continue

c 	yotst= max(-d_Phi_opt*wasska(iacnv(ih),iacnl(ih)),1.d-4)  ! jw: / neu - * nicht neu 
	yotst=	1.d-5						! test jw

      if (yotest .lt. yotst) then			 
c===kein laterales Fliessen, wenn Wasserspiegel zu gering
c===== d.h., wenn der groesste auftretende Wasserstand yo kleiner als yotst (s.o.) ist
        do 150 il=1,iacnl(ih)
          if (vorz_o(il,ih) .lt. 0.) then		
            yoben(il)=yoben(il)+
     &                ( neff(il) + rfl_o(il)/slopeo(il,ih))*dt 
            if (yoben(il) .lt. 0.) yoben(il)=0.
          else
            yoben(il)=0.
          endif
          q(il,ih)=0.
  150   continue
      else
C-----------------------------------------------------------------------
c===kinematische Kaskade, unter Einhaltung des Courant-Kriteriums
c    dtsur: Laenge eines von ICOUR Unterzeitschritten
        dtsur=dt/dble(icour)
        if (dtsur .lt. min(dtm, dt/1000.) ) then
          write(io(1),2300) hangnr(ih), min(dtm, dt/1000.)
          write(*    ,2300) hangnr(ih), min(dtm, dt/1000.)
          stop 'Zeitschritt zur Oberflaechenabflussberechnung zu klein!'
        endif
 2300   format('Oberflaechenabfluss Hang ',i3,' dtsur = ',e11.3)
C-----------------------------------------------------------------------
c    2000: Schleife ueber alle Unterzeitschritten
C-----------------------------------------------------------------------
        do 2000 isur=1,icour
          cour=0.
          do 200 il=1,iacnl(ih)
c Berechne Wasserspiegelgefaelle -> Diffusionsanalogie
            if (il .eq. 1) then
              lokgef=gefall(il,ih)-( yo(il+1)-yo(il) )
     &                               /dr_o(il,ih)/2.
            elseif (il .eq. iacnl(ih)) then
              lokgef=gefall(il,ih)-( yo(il)-yo(il-1) )
     &                               /dr_o(il,ih)/2.
            else
              lokgef=gefall(il,ih)-( yo(il+1)-2.*yo(il)+yo(il-1) )
     &                               /dr_o(il,ih)/2.
            endif
            if(lokgef .gt. 0.0001) then
              kgef = kst(il,ih) * sqrt(lokgef)
            else
              kgef = kst(il,ih) * 0.01
            endif

c  Rillenabflussgeschwindigkeit: momentan nicht aktiv
c            if (lrill(il,ih)) then
c             vo(il) = vrill(kgef,yo(il),rillab(il,ih),brmax(il,ih),
c     &                                                  mwand(il,ih))
c             cour=max(cour,(4./3.)*vo*dtsur/dr_o(il,ih))
c            else

c  Schichtabflussgeschwindigkeit
              vo(il) = vmitt(kgef,yo(il))
              cour=max(cour,(5./3.)*vo(il)*dtsur/dr_o(il,ih))

c            endif

  200     continue

c  wenn Courant-Kriterium verletzt, neue Berechnung mit halbem Zeitschritt...
c          if (cour .gt. 1.) then
c            icour=icour*int(cour+1.)
          if (cour .gt. 0.67) then
            icour=icour*int(cour+2.)
            goto 1000
c  ^-----------------
          endif

c  ...ansonsten geht es weiter...
c----------------------------------------------------------------------
c  Berechnung des Abflusses [cbm/s] und der (verbliebenen) Wassertiefe
c    q(il,ih) ist jetzt der laterale Fluss an der Stelle il innerhalb
c             des momentanen Untwerzeitschritts.
c    vo(il)   die bereits berechnete Geschwindigkeit
c    varbr(il,ih) die variable Breite an der Stelle il des Hangs ih
c-----------------------------------------------------------------------
          do 300 il=1,iacnl(ih)
            q(il,ih)=vo(il)*yo(il)*varbr(il,ih)
c  Aufsummieren aller q, um spaeter (s.u.) den Durchschnitt innerhalb DT
c  bilden zu koennen!!
            qsum(il)=qsum(il)+q(il,ih)
c    dq ist die Veraenderung von q von Punkt zu Punkt
            if (il .eq. 1) then
              dq=       -q(il,ih)
            else
              dq=q(il-1,ih)-q(il,ih)
            endif
c    falls Potentialrandbedingung...
            if (vorz_o(il,ih) .lt. 0.) then

			!	jw cave: Oberflächenabfluss noch nicht verknüpft mit vorz_o !!!
			!  Zus. mit lueb_o ???

c    ... ergibt sich die neue Wassertiefe aus der alten + innerhalb
c    DTSUR einfallenden Regen NEFF + Randfluesse RFL_O aus der Bodenmatrix
c    + Differenz aus Ab- und Zufluss DQ
              yo(il)=yo(il)+( (neff(il))*slopeo(il,ih)		
     &               + rfl_o(il)  + dq/dr_o(il,ih)/varbr(il,ih) )*dtsur
            else
c... FALL A - "original"
c           yo(il)=yo(il)+( dq/dr_o(il,ih)/varbr(il,ih)        )*dtsur
c... FALL B
C          yo(il)=yo(il)+(rfl_o(il) + dq/dr_o(il,ih)/varbr(il,ih))*dtsur 		
c... FALL C -  TEST jw: yoben + neff infiltriert mit qo_pot, bleibt nur Fluss von oben 
c		  yo(il)= ( dq/dr_o(il,ih)/varbr(il,ih)        )*dtsur
c... FALL D -  TEST jw: wie oben 
		  yo(il)= yo(il)+( (neff(il))*slopeo(il,ih)		
     &               + rfl_o(il)  + dq/dr_o(il,ih)/varbr(il,ih) )*dtsur


            endif

            if (yo(il) .lt. 0.99e-37) yo(il)=0.
  300     continue
 2000   continue

c ...alle Unterzeitschritte abgearbeitet...
        do 400 il=1,iacnl(ih)
c ...jetzt Rueckberechnung von YOBEN aus dem neuen YO...
          yoben(il)=yo(il)*slopeo(il,ih)
c ...und ein DURCHSCHNITTLICHEN Abfluss ueber gesamt DT
          q(il,ih)=qsum(il)/dble(icour)
  400   continue

      endif

c	Ende Schleife Unterzeitschritte
C-----------------------------------------------------------------------


C-----------------------------------------------------------------------
c	Testen ob nennenswerter Abfluss stattfindet
c	Setzen von logicals

c Ausdrucken, wenn sich was tut (lwriten, lwriteq) und kurz danach (lwrites)
c      if (neff(1) .gt. 0.) then      
c         lwriten = .true.		! test jw 
c          lwrites = .true.
c 	else
c        lwriten = .false.
c      endif


ccc      if (q(iacnl(ih),ih)*alla(1,ih)/vola(1,ih)/lrd_o(ih) .gt. 0.) then

c Abfrage über yotst als 'dynamischer Schalter', nicht über q
c     yotst wird oben gesetzt, ändert bis hier her nicht

      if (yoben(iacnl(ih)) .gt. yotst) then
        lwriteq = .true.
        lwrites = .true.
        qp =q(iacnl(ih),ih)					! qp = q für Ausgabe
      else
        lwriteq = .false.
        qp =0.
      endif

c ... jw test : von oben hierher, damit Rate und Summe konsistent geschrieben werden
c ---Durchflussumme am Hangende [cbm]
        qosum(ih) = qosum(ih) + qp *dt			! jw : qp statt q
        if (qosum(ih) .lt. 0.99e-37) qosum(ih) = 0.	
c ---max. Durchfluss [cbm/s]
        qomax(ih) =max(qomax(ih),q(iacnl(ih),ih))


c	---------------------------------------------------------------------------
c	Ausdrucksblock
c	---------------------------------------------------------------------------
c		erste Zeile mit Faktoren
c Umrechnungsfaktoren:  Zeit in [d]
c Umrechnungsfaktoren:  Niederschlag in [mm/h]
c Umrechnungsfaktoren:  Abfluss in [mm/h]
c Umrechnungsfaktoren:  kum. Abfluss in [mm]
	  if (lw11st) then
          do 35 i=1,iacnh
            fabf(i) =alla(1,i)/vola(1,i)/lrd_o(i)*3600000.
            fcabf(i)=alla(1,i)/vola(1,i)/lrd_o(i)*1000.
  35      continue
          ih1st=ih
          write(io(10),9011) fabf(ih), fcabf(ih), hangnr(ih)	
          lw11st=.false.
        endif
c		zweite Zeile mit Startwerten 
        if (lw1st(ih)) then
          if ((io_act .ge. 10) .and. (io_log(10) .gt. 0)) then
            write(io(10),9010) hangnr(ih), t_act, t_act+dt, dnull, 
     &        q(iacnl(ih),ih),  qosum(ih)
          end if
		lw1st(ih)=.false.
        endif
 

c	Ausdruck	
      if (lwriten .or. lwriteq .or. lwrites) then
        if ((io_act .ge. 10) .and. (io_log(10) .gt. 0))
     &    write(io(10),9010) hangnr(ih), t_act, t_act+dt, neff(1), 
     &        qp, qosum(ih)

        if ((.not.lwriten) .and. (.not.lwriteq) .and. lwrites)
     &                     lwrites=.false.
	endif
c  Ende des Ausdruckblocks
C-----------------------------------------------------------------------


      return

 9010 format(i3,2f15.2,3e15.6,i6)
 9011 format(3x,'1.157407407e-05 1.157407407e-05  3600000.00',
     &			2e24.16, 1x, i3)
      end


      double precision function  vmitt(k,h)
c----------------------------------------------------------------------
c   Bestimmung der mittleren Geschwindigkeit [m/s]
c   nach Gauckler-Manning-Strickler
c
c     k   Stricklerwert*Wurzel(Gefaelle)
c     h   Wasserhoehe
c
      real*8    k,h,ex

      if (h .le. 0.)  goto 5
      ex = 2./3.
      vmitt =  k * h**ex
      return
 5    vmitt = 0.
      return
      end


      double precision function  vrill(k,h,rillab,bmax,m)
c----------------------------------------------------------------------
c   Bestimmung der mittleren Geschwindigkeit [m/s]
c   nach Gauckler-Manning-Strickler
c   fuer Furchen mit Rillenabstand rillab und
c   Dreiecksquerschnitt maximaler Breite bmax
c
c     k          Stricklerwert*Wurzel(Gefaelle)
c     h          Wasserhoehe
c     rillab     Rillenabstand
c     bmax       maximale Rillenbreite
c     m          Rillenneigung m(horizontal):1(vertikal)
c
      real*8    k,a,u,ex,r
      real*8    h,rillab,bmax,m, agrenz, bact

      intrinsic sqrt

      a = h*rillab
      if (a .le. 0.0)  goto 5

      agrenz = bmax*bmax/4./m

      if (agrenz .ge. a) then
        bact = sqrt(a * 4. * m)
        u = bact*sqrt(1./m/m + 1.)
      else
        u = bmax*sqrt(1./m/m + 1.) + 2.*(a-agrenz)/bmax
      endif

      ex = 2./3.
      r = a/u
      vrill =  k * r**ex
      return
 5    vrill = 0.
      return
      end


      double precision function  kst(il,ih)
c----------------------------------------------------------------------
c   Bestimmung des Strickler Beiwerts in Abhaengigkeit der
c   Landnutzung
c
c   kst = 10.  sehr glatt -> schneller Abfluss
c   kst =  1.  sehr rauh  -> langsamer Abfluss

      include 'dim.inc'
      include 'zeit.inc'
      include 'hgbdry.inc'
      include 'hgfest.inc'
      include 'hgvari.inc'

      logical hoch, tief
      integer*4 il, ih, ipos
      external lookup
      intrinsic dble, int

      if (lklima) then
      ipos=int(dble(iacpft(iusenr(il,ih)))/2.)
      call lookup(pflpar(1,1,iusenr(il,ih)),pflpar(1,2,iusenr(il,ih)),
     &            iacpft(iusenr(il,ih)),itag,kst,hoch,tief,ipos)
      else
        kst=kstall(icf)
      endif

      return
      end
