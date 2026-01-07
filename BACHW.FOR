      subroutine bach(dt,regen)
	
c-----------------------------------------------------------------------
c   Abflusshoehen als kinematische Kaskade (kinematische Welle)
c   Aneinanderreihung von einzelnen unabhaengigen Kaskaden
c   der Abfluss berechnet sich nur aufgrund der Wasserspiegelhoehe
c   des vorherigen Zeitschritts.
c     

      include 'dim.inc'
      include 'zeit.inc'
      include 'bach.inc'
      include 'hgfest.inc'


      integer*4  ib, it, ih
      integer*4 isur
      integer*4 icour
      real*8 dt, dtm, regen
      real*8 yb, vb, qb, qbsum, b_br
      real*8 lokgef, cour, kgef, flaech, qbzu, Ig, rdum
      real*8 yotest, yotst, ybalt, co, vol, dy, cel, Qp, Qm, totvol
      real*8 qbpeg1, qbpegn, y_alt
      dimension yb(maxnb), vb(maxnb), qb(maxnb), qbsum(maxnb), co(maxnb)
      dimension vol(maxnb), b_br(maxnb), y_alt(maxnb)
      dimension qbpeg1(maxnb), qbpegn(maxnb)

      intrinsic dble, sqrt, min, max, int, abs
      external trapez, koeffbr

      
      dtm=dt_min/100.
      dy=0.005
      icour=2

      Ig=1.
      yotst= 1.e-8

c      update der Randbedingung, falls sich was geändert hat
c      if (rbbneu) call koeffbr()               ! jw warum kommentiert

 1000 continue

      yotest=0.
C      write(6,*)'bachw regen', regen
      do 100 ib=1,iacnb
        yb(ib)=y_bach(ib)
	  y_alt(ib)=y_bach(ib)
        vol(ib)=v_bach(ib)
        qbsum(ib)=0.
        if (yb(ib) .gt. 0.) yotest=yb(ib)
  100 continue
c wird das noch gebraucht???                    ! jw Bedeutung comment?
      if (yotest .lt. yotst) then
        do 105 ih=1,iacnh
          if (qhang(ih) .gt. 0.) yotest=qhang(ih)
  105   continue
      endif

cc      if (yotest .lt. yotst) then
cc        do 150 ib=1,iacnb
cc          y_bach(ib)=yb(ib)
cc          qb(ib)=0.
cc          vb(ib)=0.
cc          qbsum(ib)=0.
cc  150   continue
cc      else
c===kinematische Kaskade, unter Einhaltung des Courant-Kriteriums
        if (dtsur .lt. 0.) dtsur=dt
        icour=int(dt/dtsur)
        if (icour .ge. 2) then
          dtsur=dt/dble(icour)
        else
          icour=1
          dtsur=dt
        endif
        if (dtsur .lt. min(dtm, dt/100.) ) then
          stop 'Zeitschritt zur Abflussberechnung zu klein! (BACH.FOR)'
        endif

        do 2000 isur=1,icour
          cour=0.
          do 200 ib=1,iacnb
            if (brso(ib) .lt.  0.00001) brso(ib)=0.0001

c  Diffusion wave approximation
c           if (ib .eq. iacnb) then
c             lokgef=b_gef(ib)-( yb(ib)-yb(ib-1) )/b_dx(ib-1)
c           else
c             lokgef=b_gef(ib)-( yb(ib+1)-yb(ib) )/b_dx(ib)
c           endif
cc  Kinematic wave approximation
             lokgef=b_gef(ib)

            if(lokgef .gt. 0.0001) then
              kgef = b_rauh(ib_ord(ib)) * sqrt(lokgef)
            else
              kgef = b_rauh(ib_ord(ib)) * 0.01
            endif

            call trapez(qb(ib),rdum,vb(ib),b_br(ib),
     &                     Ig,kgef,yb(ib),brso(ib),b_m(ib))
            qbsum(ib)=qbsum(ib)+qb(ib)

c   celerity = kinematic wave speed c
c           Courant-Friedrichs-Levy condition (z.B. Noye:1978)
c                cour = c*dt/dx< 1
c       fuer unendlich breites Gerinne: c = 5/3 * v_gerinne
c       allgemein: c = 1/b * dQ/dy, im folgenden numerisch ausgewertet

            call trapez(Qp,rdum,rdum,rdum,
     &                     Ig,kgef,yb(ib)+dy,brso(ib),b_m(ib))
            if (yb(ib).gt.dy) then
              call trapez(Qm,rdum,rdum,rdum,
     &                       Ig,kgef,yb(ib)-dy,brso(ib),b_m(ib))
              cel=(Qp-Qm)/2./dy/b_br(ib)
              co(ib)=cel*dtsur/b_dx(ib)
              cour=max(cour,co(ib))
c            else
c              cel=Qp/(yb(ib)+dy)/b_br(ib)
            endif
  200     continue

c  wenn Courant-Kriterium verletzt, neue Berechnung mit halbem Zeitschritt
          if (cour .gt. 0.99) then
             dtsur=dtsur/2.
            goto 1000
          endif

c  Berechnung des Abflusses [cbm/s]
          do 300 ib=1,iacnb
            qb(ib)=vb(ib)*yb(ib)*(brso(ib)+b_m(ib)*yb(ib))
  300     continue

c  Speichern des Abflusses im ersten und letzten Schritt
          if (isur.eq.1) then
            do 302 ib=1,iacnb
              qbpeg1(ib)=qb(ib)
  302       continue
          endif
          if (isur.eq.icour) then
            do 304 ib=1,iacnb
              qbpegn(ib)=qb(ib)
  304       continue
          endif

c  Neuberechnung der Wassertiefe nach einem (Teil-)Zeitschritt
          do 320 ib=1,iacnb
c  wenn es ein Einzugsgebiet des Punktes gibt - jw : Wann ist EZG = 0 ??
            if (b_ezg(ib) .gt. 0.) then       ! jw sonst: yb, vol = 0 ?!
              qbzu=0.
c  fuer alle oberstrom gelegenen Punkte...
c  Wasserstandserhoehung infolge ...
c      ... Zuflusswassermengen von oberstrom und
              do 330 it = 1,itmax(ib)
                if (ibtop(ib,it) .gt. 0) then
                  qbzu= qbzu+ qb(ibtop(ib,it))
                endif
  330         continue
c      ... infolge Hangzufluss (Volumenbilanz mit Zentrum in ib)
              if (inhang(ib) .ne. 0) then
                if (exhg(inhang(ib))) then
                  if(qhang(hgih(inhang(ib))) .gt. 0.) then          
c           jw surface runoff: addition only when positive ('if' clause actually obsolete)        
                    qbzu= qbzu+ qhang(hgih(inhang(ib)))
                  endif 
                 qbzu= qbzu + qshang(hgih(inhang(ib)))     
c                      ! jw changed: else if- clause deleted: addition when positive/negative and zero
                endif
              endif

c      ... infolge Zufluss von befestigten Flaechen
              if (inarea(ib) .ne. 0) then
                  qbzu= qbzu+ qarea(ib)*weg_br(ib)*b_dx(ib)
cbach                qbzu= qbzu+ qarea(ib)*weg_br(ib)*b_dx(ib)*
cbach     &                                         stpsi(ib_ord(ib))
              endif
c      ... infolge Zufluss durch direkten Niederschlag  -! jw changed: using only b_br                              
                  qbzu= qbzu+ qarea(ib)*b_br(ib)*b_dx(ib)               
 
c      ... infolge Zufluss von ausserhalb des Kontrollvolumens
c      entweder als Folge von Quellen qsour 
c      oder als vorgegebener Basisabfluss pro Laenge Gewaesserstrecke qbas
              if (auint) then
c                jw auint richtig zur Unterscheidung? - Quellen  nur bei Auint ?  ! Basisabfluss nur, wen nicht auint?
               qbzu= qbzu + qsour(ib)                                 
	        else if(.not. auint) then 
			 qbzu= qbzu+ qbas(ib)*b_dx(ib)                                    
	        end if

c      ... Abflusswassermengen nach unterstrom und
              qbzu= qbzu- qb(ib)

              vol(ib)=vol(ib)+qbzu*dtsur
              if (vol(ib) .lt. 0.) then
                vol(ib)=0.
              endif

  44          continue
            
              flaech=0.
              ybalt=yb(ib)
            
             do 331 it = 1,itmax(ib)
                if (ibtop(ib,it) .gt. 0) then
                  if (yb(ib) .gt. 0.) then
                    flaech= flaech + b_dx(ibtop(ib,it))/2.
     &                          *(brso(ib)/yb(ib)+b_m(ibtop(ib,it)))
                  else
                    flaech= flaech + b_dx(ibtop(ib,it))/2.
     &                          *b_m(ibtop(ib,it))
                  endif
                endif
  331         continue
              
              if (yb(ib) .gt. 0.) then
                flaech = flaech + b_dx(ib)/2.
     &                          *(brso(ib)/yb(ib)+b_m(ib))
              else
                flaech= flaech + b_dx(ib)/2.*b_m(ib)
              endif
              yb(ib)=sqrt(vol(ib)/flaech)
              if (abs(ybalt-yb(ib)).gt. 0.001) then
                ybalt=yb(ib)
                goto 44
              endif
            else                           !jw wenn kein EZG des Punktes
              yb(ib)=0.
              vol(ib)=0.
            endif
  320     continue
 2000   continue

        lqactiv=.false.
c	  write(6,*)'bachw',lqactiv
        do 400 ib=1,iacnb
c  Festlegen ob stationaere Verhaeltnisse erreicht sind und
c  das Vorflutermodell ggf. eingefroren werden kann.
          if (abs(qbpeg1(ib)-qbpegn(ib))/dt .ge. qtol) lqactiv=.true.
c          write(6,*)'bachw',lqactiv
		y_bach(ib)=yb(ib)
          v_bach(ib)=vol(ib)
          qb(ib)=qbsum(ib)/dble(icour)
c	    write(6,*)'bachw qb',qb(ib),ib
  400   continue

c Hangende
c ---Durchflusssumme [cbm]
        qpegel = qpegel+qb(iacnb)*dt
        if (qpegel .lt. 0.99e-37) qpegel = 0.
c ---max. Durchfluss [cbm/s]
        qpmax =max(qpmax,qb(iacnb))
        if (cour .gt. 0.) then
          if (cour .lt. 0.4) dtsur=dtsur/cour*0.9
        endif
cc      endif

      if ((io_act .ge. 12) .and. (io_log(12) .gt. 0)) then
        totvol=0.
        do 401 ib=1,iacnb
          totvol=totvol+vol(ib)
  401   continue
        write(io(12),2500) t_neu,icour,qpegel,totvol,regen*1000.*3600.,
     &  qpmax,
     &    (qb(igang(ib)), yb(igang(ib)), vb(igang(ib)), ib=iacgng,1,-1)
      endif
 2500 format(f18.2,1x,i7,1x,f18.3,1x,f18.3,1x,f14.2,1x,
     &12(f14.3,1x,2(f10.3),1x))

      return
      end

      subroutine trapez(Q,A,v,bw,I,kst,y,bs,m)
	implicit none
c-----------------------------------------------------------------------
c
c   Ausgabe:
c      Q      Durchfluss
c      A      durchstroemte Flaeche
c      v      Fliessgeschwindigkeit
c      bw     Wasserspiegelbreite
c
c   Eingabe:
c      I      Gefaelle (ueblicherweise der Sohle)
c      kst    Strickler Beiwert
c      y      Wassertiefe
c      bs     Breite der Gerinnesohle
c      m      Neigung der Gerinnewaende (m breit : 1 hoch)
c
      real*8 Q,A,v,bw
      real*8 I,kst,y,bs,m

      real*8 U

      intrinsic sqrt

      A=(bs+m*y)*y
      U=bs+2.*y*sqrt(m*m+1)

      v=kst*sqrt(I)*(A/U)**(2./3.)
      Q=v*A
      bw=bs+2*m*y

      return
      end
