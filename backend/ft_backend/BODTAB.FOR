      subroutine  bodtab()
c-----------------------------------------------------------------------
c  generiere Bodentabellen aus
c  imod
c   1    van Genuchten (1980) Modell
c   2    Tang & Skaggs (1977) Modell
c   3    Broadbridge & White (1988) Modell
c  99    Tabelle
c
c  stab
c   1    th  ansteigend
c   2    psi abfallend
c   3    k  ansteigend
c   4    c  nicht monoton (daher nicht umkehrbar)
c-----------------------------------------------------------------------

      include 'dim.inc'
      include 'soil.inc'
      integer*4 ityp, ilp
      real*8  psipwp, th_psi

      external maxtst
      external vg_tab, ts_tab, filtab, th_psi, bw_tab

      iaceig=4
      call maxtst('IACEIG  ',iaceig,'MAXEIG  ',maxeig,'BODTAB  ')

      psipwp=10.**4.2/100.
      ilp=1
      do 100 ityp = 1,iactyp
        if (imod(ityp) .eq. 1) call vg_tab(ityp)
        if (imod(ityp) .eq. 2) call ts_tab(ityp)
        if (imod(ityp) .eq. 3) call bw_tab(ityp)
        if (imod(ityp) .eq. 99) call filtab(ityp)
        th_pwp(ityp)=th_psi(ityp,psipwp,ilp)
  100 continue

      return
      end

      subroutine  vg_tab(ityp)
c-----------------------------------------------------------------------
c  generiere Bodentabellen aus van Genuchten Parametern
c
c  th  ansteigend
c  psi abfallend
c  k  ansteigend
c  c  nicht monoton (daher nicht umkehrbar)
c-----------------------------------------------------------------------

      include 'dim.inc'
      include 'soil.inc'
      real*8 k_s, th_s, th_r, vg_a, vg_n, vg_m
      real*8 psimin, psimax, thstar, thhelp, vg_an
      integer*4 itab,ityp
      integer*4 ieig

      intrinsic dble

        if ((io_act .ge. 2) .and. (io_log(2) .gt. 0)) then
        write(io(2),'(a30,2f8.3,i4,i6,e13.4)') boden(ityp),
     &           anisot(1,ityp),anisot(2,ityp),imod(ityp),iactab(ityp),
     &           snull(ityp)
        endif
        k_s  = bodpar(1,ityp)
        th_s = bodpar(2,ityp)
        th_r = bodpar(3,ityp)
        vg_a = bodpar(4,ityp)
        vg_n = bodpar(5,ityp)
        vg_m = 1.-1./vg_n
        do 110 itab = 1,iactab(ityp)
           psimin= bodpar(6,ityp)
           psimax= bodpar(7,ityp)
           thstar = psimax-(psimax-psimin)*dble(itab-1)
     &                                    /dble(iactab(ityp)-1)
c  Saugspannung (positiv bei ungesaettigten Verhaeltnissen) [m]
           s_tab(itab,2,ityp) = 10.**thstar
c  Wassergehalt (volumetrisch) [-]
           thstar = (1.+(vg_a*s_tab(itab,2,ityp))**vg_n)**(-vg_m)
           s_tab(itab,1,ityp) = thstar * (th_s-th_r) + th_r
c  Leitfaehigkeit [m/s]
           thhelp = thstar**(1./vg_m)
           s_tab(itab,3,ityp) =
     &       k_s * thstar**(0.5)*(1.-(1.-thhelp)**vg_m)**2.
c  Wasserkapazitaet [1/m]
           vg_an = vg_a**vg_n
           s_tab(itab,4,ityp) =
     &       (th_r-th_s)*vg_n*vg_m*vg_an*s_tab(itab,2,ityp)**(vg_n-1.)
     &       *(1.+ (vg_a*s_tab(itab,2,ityp))**vg_n)**(-vg_m-1.)
         if ((io_act .ge. 2) .and. (io_log(2) .gt. 0)) then
           write(io(2),1000) (s_tab(itab,ieig,ityp),ieig=1,iaceig)
         endif
  110   continue
      return
 1000 format(4e14.6)
      end

      subroutine  ts_tab(ityp)
c-----------------------------------------------------------------------
c  generiere Bodentabellen aus Tang & Skaggs (1977) Modell
c
c  stab
c   1    th  ansteigend
c   2    psi abfallend
c   3    k  ansteigend
c   4    c  nicht monoton (daher nicht umkehrbar)
c-----------------------------------------------------------------------

      include 'dim.inc'
      include 'soil.inc'
      real*8 k_s, th_s, ts_alp, ts_bet, ts_A, ts_B
      real*8 psimin, psimax
      integer*4 itab,ityp
      integer*4 ieig

      intrinsic dble

        if ((io_act .ge. 2) .and. (io_log(2) .gt. 0)) then
        write(io(2),'(a30,2f8.3,i4,i6,e11.4)') boden(ityp),
     &           anisot(1,ityp),anisot(2,ityp),imod(ityp),iactab(ityp),
     &           snull(ityp)
        endif
        k_s    = bodpar(1,ityp)
        th_s   = bodpar(2,ityp)
        ts_alp = bodpar(3,ityp)
        ts_bet = bodpar(4,ityp)
        ts_A   = bodpar(5,ityp)
        ts_B   = bodpar(6,ityp)

        do 110 itab = 1,iactab(ityp)
c  Saugspannung (positiv bei ungesaettigten Verhaeltnissen) [m]
           psimax = bodpar(8,ityp)
           psimin = bodpar(7,ityp)
           s_tab(itab,2,ityp) = 10.**(
     &     psimax - (psimax-psimin)*dble(itab-1)/dble(iactab(ityp)-1) )
c  Wassergehalt (volumetrisch) [-]
           s_tab(itab,1,ityp) = th_s*ts_alp/
     &        (ts_alp+(s_tab(itab,2,ityp)*100.)**ts_bet)
c  Leitfaehigkeit [m/s]
           s_tab(itab,3,ityp) = k_s*ts_A/
     &        (ts_A+(s_tab(itab,2,ityp)*100.)**ts_B)
c  Wasserkapazitaet [1/m]
           s_tab(itab,4,ityp) = -th_s*ts_alp*ts_bet*100.*
     &         (s_tab(itab,2,ityp)*100.)**(ts_bet-1.)/
     &         (ts_alp+(s_tab(itab,2,ityp)*100.)**ts_bet)**2.
         if ((io_act .ge. 2) .and. (io_log(2) .gt. 0)) then
           write(io(2),1000) (s_tab(itab,ieig,ityp),ieig=1,iaceig)
         endif
  110   continue
c        snull(ityp) = s_tab(iactab(ityp),4,ityp)
      return
c 1000 format(2f18.8,f18.14,f18.10)
 1000 format(4e14.6)
      end

      subroutine  bw_tab(ityp)
c-----------------------------------------------------------------------
c  generiere Bodentabellen aus Broadbridge & White Parametern
c
c  th  ansteigend
c  psi abfallend
c  k  ansteigend
c  c  nicht monoton (daher nicht umkehrbar)
c-----------------------------------------------------------------------

      include 'dim.inc'
      include 'soil.inc'
      real*8 k_s, th_s, th_r, lam_c, struc
c      real*8 psimin, psimax, thstar, cstar         !jw unused?
      integer*4 ityp                           
c      integer*4 itab, ieig                         !jw unused?

      intrinsic dble

        if ((io_act .ge. 2) .and. (io_log(2) .gt. 0)) then
        write(io(2),'(a30,2f8.3,i4,i6,e11.4)') boden(ityp),
     &           anisot(1,ityp),anisot(2,ityp),imod(ityp),iactab(ityp),
     &           snull(ityp)
        endif
        k_s  = bodpar(1,ityp)
        th_s = bodpar(2,ityp)
        th_r = bodpar(3,ityp)
        lam_c= bodpar(4,ityp)
        struc= bodpar(5,ityp)
        stop 'Broadbridge & White Model fehlt noch!'

      return
      end

      subroutine  filtab(ityp)
c-----------------------------------------------------------------------
c  lese Bodentabellen aus Datei
c
c  th  ansteigend
c  psi abfallend
c  k  ansteigend
c  c  nicht monoton (daher nicht umkehrbar)
c-----------------------------------------------------------------------

      include 'dim.inc'
      include 'soil.inc'
      character*50 hlpstr
      integer*4 itab,ityp
      integer*4 ieig

      external maxtst, openi

      call openi(iin(1),tabfil(ityp),io(1))
      read(iin(1),'(a30,a50)') boden(ityp), hlpstr
      read(hlpstr,*) anisot(1,ityp),anisot(2,ityp),snull(ityp)
      itab=1
  950 read(iin(1),*,end=951) (s_tab(itab,ieig,ityp),ieig=1,iaceig)
      itab=itab+1
      goto 950
  951 continue
      close(iin(1))
      iactab(ityp)=itab-1
      call maxtst('IACTAB  ',iactab(ityp),'MAXTAB  ',maxtab,'FILTAB  ')

      if ((io_act .ge. 2) .and. (io_log(2) .gt. 0)) then
      write(io(2),'(a30,2f8.3,i4,i6)') boden(ityp),
     &       anisot(1,ityp),anisot(2,ityp),imod(ityp),iactab(ityp)
      do 110 itab = 1,iactab(ityp)
         write(io(2),1000) (s_tab(itab,ieig,ityp),ieig=1,iaceig)
  110 continue
      endif

      return
 1000 format(4e14.6)
      end

      subroutine kc_phi(phi,ih)
c-----------------------------------------------------------------------
c  Hang: Bestimmung von Durchlaessigkeit und Wasserkapazitaet
c        fuer beliebiges PHI
c
c  psi, theta, durchl, wasska
c              in commonbock hgvari werden updated!
c-----------------------------------------------------------------------
      include 'dim.inc'
      include 'hgfest.inc'
      include 'hgvari.inc'

      integer*4 ih
      real*8 phi
      dimension  phi(maxnv,maxnl)
c  psi ist im commonbock hgvari, phi nicht!

      external psi_phi, kc_psi

      call psi_phi(psi,phi,ih)
      call kc_psi(ih)

      return
      end

      subroutine psi_phi(psi,phi,ih)
c-----------------------------------------------------------------------
c  Hang: Umrechnung von phi in psi
c-----------------------------------------------------------------------
      include 'dim.inc'
      include 'hgfest.inc'

      integer*4 iv,il,ih
      real*8 psi, phi
      dimension  psi(maxnv,maxnl)
      dimension  phi(maxnv,maxnl)

      do 100 iv = 1, iacnv(ih)
        do 110 il = 1, iacnl(ih)
          psi(iv,il) = hko(iv,il,ih) - phi(iv,il)
  110   continue
  100 continue

      return
      end

      subroutine kc_psi(ih)
c-----------------------------------------------------------------------
c  Hang: Bestimmung von Durchlaessigkeit und Wasserkapazitaet
c-----------------------------------------------------------------------
      include 'dim.inc'
      include 'soil.inc'
      include 'hgfest.inc'
      include 'hgvari.inc'

      integer*4 iv,il,ih
      real*8 k_psi, c_psi, th_psi

      external k_psi, c_psi, th_psi, chk_ma
  
      do 100 iv = 1,iacnv(ih)
        do 110 il = 1,iacnl(ih)
          durchl(iv,il) =
     &      k_psi(iboden(iv,il,ih),psi(iv,il),tabpos(iv,il,ih))
          theta(iv,il) =
     &      th_psi(iboden(iv,il,ih),psi(iv,il),tabpos(iv,il,ih))
          wasska(iv,il) =
     &      c_psi(iboden(iv,il,ih),psi(iv,il),tabpos(iv,il,ih))-
     &      snull(iboden(iv,il,ih))*theta(iv,il)/
     &      s_tab(iactab(iboden(iv,il,ih)),1,iboden(iv,il,ih))
           call chk_ma(durchl(iv,il),iv,il,ih)

  110   continue
  100 continue
      return
      end

      subroutine chk_ma(ku,iv,il,ih)
c-----------------------------------------------------------------------
c  Makroporen: ggf. Modifikation der Durchlaessigkeit
c-----------------------------------------------------------------------
      include 'dim.inc'
      include 'soil.inc'
      include 'hgfest.inc'
      include 'hgvari.inc'
      include 'hgbdry.inc'

      integer*4 iv,il,ih
      real*8  ku, strahl2                     ! th_q strahl, !jw unused?
      real*8  th_gr, mak_gr, mfak

      intrinsic cos, sin, abs
      external strahl2                          !strahl, !jw unused?

      mak_gr=1.
      mak_an(iv,il)=.false.
 
c-------Beruecksichtigung von Makroporen
      if (lmak(ih)) then

      
c---------Bei Oberflaechenabfluss: Alle darunter liegenden Knoten werden auf Makroporenfluss geschaltet
        th_gr=sattgr(iboden(iacnv(ih),il,ih))*
     &        s_tab(iactab(iboden(iacnv(ih),il,ih)),1,
     &                     iboden(iacnv(ih),il,ih))
         if (theta(iacnv(ih),il) .gt. th_gr .and. theta(iacnv(ih)-1,il)
     &     .gt. th_gr ) then
          if (macro(iv,il,ih) .gt. 1.) then
            mfak=strahl2(mak_gr,macro(iv,il,ih),th_gr,
     &              s_tab(iactab(iboden(iacnv(ih),il,ih)),1,
     &               iboden(iacnv(ih),il,ih)),theta(iacnv(ih),il),
     &               b_mac(iacnv(ih),il,ih))
            ku=ku*mfak
c         ku corresponds to durchl(iv,il) in koeffrb
            mak_an(iv,il)=.true.
          endif
        
        else
c-----------bei Überschreiten des Schwellenwertes
          th_gr=sattgr(iboden(iv,il,ih))*
     &        s_tab(iactab(iboden(iv,il,ih)),1,iboden(iv,il,ih))
          if (theta(iv,il) .gt. th_gr) then
            if (macro(iv,il,ih) .gt. 1.) then 
              mfak=strahl2(mak_gr,macro(iv,il,ih),th_gr,
     &              s_tab(iactab(iboden(iv,il,ih)),1,
     &               iboden(iv,il,ih)),theta(iv,il),
     &               b_mac(iv,il,ih))

              ku = ku* mfak
              mak_an(iv,il)=.true.
            endif
          endif
        endif
c ----Im Falle m_aniso= 1/2 wird bei Makroporenfluss wird die Leitfaehigkeit anisotrop erhoeht
c     sonst wird die Leitfaehigkeit in beiden Richtungen erhöht
        if (mak_an(iv,il)) then
c .... vertical macropores (direction of gravity)
	   if(m_aniso .eq. 1) then
           kxx(iv,il,ih) = anisot(1,iboden(iv,il,ih))/mfak
     &        *cos(w_xshr(iv,il))**2 +anisot(2,iboden(iv,il,ih))
     &        *sin(w_xshr(iv,il))**2
           kee(iv,il,ih) = anisot(1,iboden(iv,il,ih))/mfak
     &       *sin(w_xshr(iv,il))**2+anisot(2,iboden(iv,il,ih))
     &       *cos(w_xshr(iv,il))**2
           kxe(iv,il,ih)=(anisot(1,iboden(iv,il,ih))/mfak
     &       -anisot(2,iboden(iv,il,ih)))*cos(w_xshr(iv,il))*
     &        sin(w_xshr(iv,il))
	    if(kxe(iv,il,ih) .lt. 0.) then
           kxe(iv,il,ih)=-1.*kxe(iv,il,ih)
          endif  
c         #### Anisotropic macropores that work exclusively in 
c         downslope direction/ xsi/xx directions, added by theresa and erwin 21.04.2010
          else if(m_aniso .eq. 2) then
           kee(iv,il,ih) = keef(iv,il,ih)/mfak
           kxe(iv,il,ih) = kxef(iv,il,ih)/mfak
 		else 
           kxx(iv,il,ih) = kxxf(iv,il,ih)
           kee(iv,il,ih) = keef(iv,il,ih)
           kxe(iv,il,ih) = kxef(iv,il,ih)
          end if
         end if
      if (kxx(iv,il,ih) .lt. 0.) then
	 write(6,*) kxx(iv,il,ih), 'kxx'
       stop 'Fehler in CHK_MA'
	else if (kxe(iv,il,ih) .lt. 0.) then
	 write(6,*) kxe(iv,il,ih), 'kxe',cos(w_xshr(iv,il))
	write(6,*) sin(w_xshr(iv,il)), mfak
       stop 'Fehler in CHK_MA'
	else if (kee(iv,il,ih) .lt. 0.) then
	 write(6,*) kee(iv,il,ih), 'kee'
       stop 'Fehler in CHK_MA'
      end if

	endif
      return
      end


      double precision function c_psi(iboden,psiact,ipos)
c-----------------------------------------------------------------------
c  Wasserkapazitaet als Funktion der Saugspannung,
c  Tabellenauswertung mit Positionsschaetzung zur Beschleunigung
c-----------------------------------------------------------------------

      include 'dim.inc'
      include 'soil.inc'

      logical hoch, tief
      real*8 psiact, cact
      integer*4 iboden, ipos

      external lookup

      call lookup(s_tab(1,2,iboden),s_tab(1,4,iboden),iactab(iboden),
     &            psiact,cact,hoch,tief,ipos)
      if (hoch) then
        c_psi = s_tab(1,4,iboden)
      elseif (tief) then
        c_psi = s_tab(iactab(iboden),4,iboden)
      else
        c_psi = cact
      endif
      return
      end

      double precision function k_psi(iboden,psiact,ipos)
c-----------------------------------------------------------------------
c  Durchlaessigkeit als Funktion der Saugspannung,
c  Tabellenauswertung mit Positionsschaetzung zur Beschleunigung
c-----------------------------------------------------------------------

      include 'dim.inc'
      include 'soil.inc'

      logical hoch, tief
      real*8 psiact, kact
      integer*4 iboden, ipos

      external lookup

      call lookup(s_tab(1,2,iboden),s_tab(1,3,iboden),iactab(iboden),
     &            psiact,kact,hoch,tief,ipos)
      if (hoch) then
c  k_min
        k_psi = s_tab(1,3,iboden)
      elseif (tief) then
c  k_s
        k_psi = s_tab(iactab(iboden),3,iboden)
      else
        k_psi = kact
      endif
      return
      end

      double precision function k_th(iboden,th_act,ipos)
c-----------------------------------------------------------------------
c  Durchlaessigkeit als Funktion der Bodenfeuchte,
c  Tabellenauswertung mit Positionsschaetzung zur Beschleunigung
c-----------------------------------------------------------------------

      include 'dim.inc'
      include 'soil.inc'

      logical hoch, tief
      real*8 th_act, kact
      integer*4 iboden, ipos

      external lookup

      call lookup(s_tab(1,1,iboden),s_tab(1,3,iboden),iactab(iboden),
     &            th_act,kact,hoch,tief,ipos)
      if (hoch) then
c  k_s
        k_th = s_tab(iactab(iboden),3,iboden)
      elseif (tief) then
c  k_min
        k_th = s_tab(1,3,iboden)
      else
        k_th = kact
      endif
      return
      end

      double precision function th_psi(iboden,psiact,ipos)
c-----------------------------------------------------------------------
c  Wassergehalt als Funktion der Saugspannung,
c  Tabellenauswertung mit Positionsschaetzung zur Beschleunigung
c-----------------------------------------------------------------------

      include 'dim.inc'
      include 'soil.inc'

      logical hoch, tief
      real*8 psiact, thact
      integer*4 iboden,ipos

      external lookup

      call lookup(s_tab(1,2,iboden),s_tab(1,1,iboden),iactab(iboden),
     &            psiact,thact,hoch,tief,ipos)
      if (hoch) then
c  theta_r
        th_psi = s_tab(1,1,iboden)
      elseif (tief) then
c  theta_s
        th_psi = s_tab(iactab(iboden),1,iboden)
      else
        th_psi = thact
      endif
      return
      end

      double precision function psi_th(iboden,thact,ipos)
c-----------------------------------------------------------------------
c  Saugspannung als Funktion des Wassergehalts,
c  Tabellenauswertung mit Positionsschaetzung zur Beschleunigung
c-----------------------------------------------------------------------

      include 'dim.inc'
      include 'soil.inc'

      logical hoch, tief
      real*8 psiact, thact
      integer*4 iboden, ipos

      external lookup

      call lookup(s_tab(1,1,iboden),s_tab(1,2,iboden),iactab(iboden),
     &            thact,psiact,hoch,tief,ipos)
      if (hoch) then
        stop 'error in psi_th, psi(th_s) kann nicht angegeben werden'
      elseif (tief) then
        psi_th = s_tab(1,2,iboden)
      else
        psi_th = psiact
      endif
      return
      end

      subroutine lookup(xsp,ysp,nsp,xval,yval,hoch,tief,isp)
c-----------------------------------------------------------------------
c  Tabellenauswertung (fuer monotone xsp!!)
c
c   hoch = .true. bedeutet xsp hoeher als der hoechste Wert
c   tief = .true. bedeutet xsp tiefer als der tiefste  Wert
c   (unabhaengig, ob am oberen oder unteren Ende der Tabelle)
c-----------------------------------------------------------------------

      real*8 xval, yval, xsp, ysp
      real*8 eps
      integer*4 nsp,isp
      dimension xsp(nsp),ysp(nsp)
      logical hoch, tief

      external hunt
      intrinsic dmin1, dmax1

      hoch = .false.
      tief = .false.
      eps  = 1.d-5

      call hunt(xsp,nsp,xval,isp)

      if ((isp .gt. 0) .and. (isp .lt. nsp))  then
        yval = ysp(isp) +
     &    (ysp(isp+1)-ysp(isp))*
     &    (xval-xsp(isp))/(xsp(isp+1)-xsp(isp))
        return
      endif
      if (xval .ge. dmax1(xsp(1),xsp(nsp))-eps ) then
        hoch = .true.
        return
      endif
      if (xval .le. dmin1(xsp(1),xsp(nsp))+eps ) then
        tief = .true.
        return
      endif
      stop 'Fehler in LOOKUP'
      end

      SUBROUTINE LOCATE(XX,N,X,J)
c-----------------------------------------------------------------------
c  Aufinden von J, so dass X innerhalb von XX(J) und XX(J+1) liegt
c  Intervallhalbierungsverfahren  (Numerical Recipes)
c-----------------------------------------------------------------------
      real*8 xx, x
      integer*4 jl, ju, j, n, jm
      DIMENSION XX(N)
      JL=0
      JU=N+1
10    IF(JU-JL.GT.1)THEN
        JM=(JU+JL)/2
        IF((XX(N).GT.XX(1)).EQV.(X.GT.XX(JM)))THEN
          JL=JM
        ELSE
          JU=JM
        ENDIF
      GO TO 10
      ENDIF
      J=JL
      RETURN
      END

      SUBROUTINE HUNT(XX,N,X,JLO)
c-----------------------------------------------------------------------
c  Aufinden von JLO, so dass X innerhalb von XX(JLO) und XX(JLO+1) liegt
c  Intervallhalbierungsverfahren, ausgehend von einer geschaetzten
c  Position JLO  (Numerical Recipes)
c-----------------------------------------------------------------------
      real*8 xx, x
      integer*4 jlo, jhi, n, jm, inc
      DIMENSION XX(N)
      LOGICAL ASCND
      ASCND=XX(N).GT.XX(1)
      IF(JLO.LE.0.OR.JLO.GT.N)THEN
        JLO=0
        JHI=N+1
        GO TO 3
      ENDIF
      INC=1
      IF(X.GE.XX(JLO).EQV.ASCND)THEN
1       JHI=JLO+INC
        IF(JHI.GT.N)THEN
          JHI=N+1
        ELSE IF(X.GE.XX(JHI).EQV.ASCND)THEN
          JLO=JHI
          INC=INC+INC
          GO TO 1
        ENDIF
      ELSE
        JHI=JLO
2       JLO=JHI-INC
        IF(JLO.LT.1)THEN
          JLO=0
        ELSE IF(X.LT.XX(JLO).EQV.ASCND)THEN
          JHI=JLO
          INC=INC+INC
          GO TO 2
        ENDIF
      ENDIF
3     IF(JHI-JLO.EQ.1)RETURN
      JM=(JHI+JLO)/2
      IF(X.GT.XX(JM).EQV.ASCND)THEN
        JLO=JM
      ELSE
        JHI=JM
      ENDIF
      GO TO 3
      END
