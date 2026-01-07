      subroutine hg(ih,dt,meth)
C-----------------------------------------------------------------------

      include 'dim.inc'
      include 'zeit.inc'
      include 'hgfest.inc'
      include 'hgvari.inc'
      include 'hgbdry.inc'
	include 'pbdry.inc'
	include 'pfest.inc'
	include 'pvari.inc'

      integer*4 ih, i, icv, istp    !,iv,il ! jw unused
      integer*4 n_it, n_cg
      character*3 meth

c      integer*4 pos_old                    ! jw unused
      real*8 rel_ab
      real*8 dt, dts
      real*8 rsq, rcoeff
      logical abbruch, rbchg, lerst
c      character*22 dstra, dstrn
      character*22 datstr
      real tagnr, tagstd

      external stpbil, totbil, stpdif, hgcopy, obcopy
      external kc_phi
c     external diffcal
c      external expstp, anzeig, pfeil
cc      external picadi
      external adistp, apkstp, bcgstp
      external piccg
      external wrres
      external dsps2ds
      external ds2diny
      external mtheta
      external cal_q
      external loadvz, savevz
      external updyo, etintz
      external v_strb, ptkinj2
      external p_stepb, pmass
      external c_ipob, gl_copy

      intrinsic abs, max, min, dble

      abbruch = .false.
      lerst=.true.
      call hgcopy(phialt(1,1,ih),phineu,ih)
      call obcopy(yo_alt(1,ih),yoben,ih)
c	### hier wird yoben auf yo_alt(1,ih) gesetzt
      call obcopy(iz_alt(1,ih),interz,ih)
      call kc_phi(phialt(1,1,ih),ih)
      call hgcopy(theta,th_alt,ih)
      call mtheta(ih)

      do 101 icv=1,iaccv(ih)
        th_mit(icv,1,ih)=th_mit(icv,2,ih)
  101 continue
      yo_mit(1,ih)=yo_mit(2,ih)
      dts=0.

c....Test auf Print-Zeitpunkte
        if (t_act+dt .ge. t_p(ip(ih),ih)) then
          dt = (t_p(ip(ih),ih)-t_act)
        endif

c   Datumstring plus Sekunden zu Datumsstring (Intervalmitte)
        call dsps2ds(dstrs, t_act+dt/2., datstr)
c   Datumstring zu Tag im Jahr
        call ds2diny(datstr,tagnr,tagstd)
        itag=dble(tagnr)
        stunde=dble(tagstd)


c-----------------------------------------------------------------------
c  lokale Zeitschleife
c-----------------------------------------------------------------------
  500 continue

        n_it=0
        n_cg=0
        rsq=0.
	  if (lland .and. lpob(ih)) call etintz(ih,dt)

        if (meth .eq. 'adi') then
          call adistp(ih,dt,rbchg)
c        elseif (meth .eq. 'exp') then
c          call diffcal(ih,dt_exp)
c          if (dt .gt. dt_exp) dt = 0.99*dt_exp
c          call expstp(ih,dt,rbchg)
        elseif (meth .eq. 'apk') then
          call apkstp(ih,dt,rbchg)
        elseif (meth .eq. 'bcg') then
          call bcgstp(ih,dt,n_cg,rbchg)
        elseif (meth .eq. 'pic') then
          call piccg(ih,dt,dt_min,abbruch,n_it,n_cg,rsq)
        elseif (meth .eq. 'mix') then
          call adistp(ih,dt,rbchg)
          call piccg(ih,dt,dt_min,abbruch,n_it,n_cg,rsq)
        else
          stop 'Hangberechnungsmethode unbekannt (HG)'
        endif

        call kc_phi(phineu,ih)
        call stpdif(ih,rel_ab)


c-----------------------------------------------------------------------
c  Zeitschrittsteuerung, Neuinitialisierung, Abspeichern, Rausschreiben
c-----------------------------------------------------------------------
        if ((dt .le. dt_min) .and. (.not.lerst)) then
          write(io(1),313) ih, t_act/86400., rsq
          write(*    ,313) ih, t_act/86400., rsq
  313     format('Genauigkeit nicht erreicht: Hang ',i3,
     &            ', Zeit ',f6.2,' Tage, rsq ',e12.4)
          rel_ab=1.
          abbruch=.false.
        endif

        if (rel_ab .lt. 0.5 .or. abbruch) then
	  write(io(1),314) ih, t_act/86400., rsq, rel_ab
  314     format('Genauigkeit nicht erreicht: Hang ',i3
     &            ,', Zeit ',f6.2,' Tage, rsq, rel_ab ',2e12.4)
        write(io(1),*) 'abbruch=', abbruch
c-----------------------------------------------------------------------
c  Wiederholung mit kuerzerem/gleichem Zeitschritt
          call kc_phi(phialt(1,1,ih),ih)
          call hgcopy(phialt(1,1,ih),phineu,ih)
          call obcopy(yo_alt(1,ih),yoben,ih)
c		### hier wird yoben auf yo_alt gesetzt
          call obcopy(iz_alt(1,ih),interz,ih)
          call loadvz(ih)
          if (lerst) then
            dt = max(dt/5., dt_min)
            lerst=.false.
          else
            dt = max(dt/10., dt_min)
          endif
          abbruch = .false.

        else
c-----------------------------------------------------------------------
c  Weiter mit naechstem Zeitschritt
c....Vorbereitung naechster Zeitschritt 
          lerst=.true.
c--------------------------------------------------------------------
c        Teilchenstep, Input mit mathematischem Randfluss
c--------------------------------------------------------------------

c          write(6,*) 'ih1', ih
	    call ptkinj2(ih,dt,t_act) ! Einspeisung der Teilchen am oberen Rand
          call hgcopy(q_xsi,qxalt,ih)
          call hgcopy(q_eta,qealt,ih)
          call cal_q(ih)
          call hgcopy(gtxact,gtxalt,ih)
          call hgcopy(gteact,gtealt,ih)
c         call gl_copy(vxact,vxalt,ih)
c         call gl_copy(veact,vealt,ih)
          call gl_copy(vx_st,vx_sta,ih)
          call gl_copy(ve_st,ve_sta,ih)


c--------- hko, sko system hier wird der Stofftransport gerechnet ------------------
          do istp=1,  istact		! istp: Zahl unterschiedlicher Stofftypen
           call v_strb(istp,ih, dt)	! Interpoliert Geschwindigkeitsfeld
           call p_stepb(istp,dt,ih)	! Teilchen schritt
           call pmass(istp,t_act,ih)	! Teilchenmasse
c        write(6,*) 'ih1, istp', ih, istp, npact(istp,ih)
            call c_ipob(istp,ih) ! berechne Konzentrationen
          end do

          call stpbil(ih,dt)
          call hgcopy(phineu,phialt(1,1,ih),ih)
          call obcopy(yoben,yo_alt(1,ih),ih)
c		 ... hier wird yo_alt auf yoben gesetzt
          call obcopy(interz,iz_alt(1,ih),ih)
          call savevz(ih)
          call hgcopy(theta,th_alt,ih)

c	Zeitschritt weiterz�hlen
c          t_act = t_act+dt		! jw warum schon hier Zeitschritt weiter z�hlen??

          do 102 icv=1,iaccv(ih)
            th_mit(icv,1,ih)=th_mit(icv,2,ih)
  102     continue

c .......	Oberflaechenabfluss          
		if (lland .and. lpob(ih)) call updyo(ih,dt,it_p(ip(ih),ih))
		yo_mit(1,ih)=yo_mit(2,ih)

c		jw neu hier zeitinkrement dazu - test jw 110218	 
	 t_act = t_act+dt

		izaehl(ih) = izaehl(ih)+1
          call totbil(ih,istact)
          if (iacnh .le. ihgr) then
           if (io_log(1) .gt. 0) then
           write(io(1),1500) hangnr(ih), izaehl(ih), t_act/86400., dt,
     &       biltot(1,ih), bilanz(1), rel_ab, n_cg, n_it, rsq
           endif
          write(*    ,1500) hangnr(ih), izaehl(ih), t_act/86400., dt,
     &      biltot(1,ih), bilanz(1), rel_ab, n_cg, n_it, rsq
          endif
 1500     format(i3,i6,f10.5,f8.1,e11.3,e11.3,f7.2,i4,i3,1x,e9.3)

c....falls Printzeitpunkt:
          if (abs(t_act-t_p(ip(ih),ih)) .lt. 0.001) then
            if (qosum(ih) .gt. 0. .and. bnied(1,ih) .gt. 0.) then
c		Abflussbeiwert
              rcoeff=qosum(ih)/bnied(1,ih)
            else
              rcoeff=0.
            endif

c.....	Schreiben ins Bilanzfile
            write(io(3),1600) hangnr(ih),';', izaehl(ih),';',t_act,';',
     &      biltot(1,ih),';',bilin(1,ih),';',-bsenk(1,ih),';',
     &      bilrd(1,ih),';',-brfl_o(1,ih),';', -brfl_r(1,ih), ';',
     &      brfl_u(1,ih), ';',brfl_l(1,ih),';',qosum(ih),';',rcoeff,
     &      ';',bnied(1,ih),';',bnied2(1,ih),';', bintz(1,ih), ';',
     &      bevapo(1,ih),';',btrans(1,ih),';',
     &     (bm_l(istp,ih),';',bm_u(istp,ih),';',bm_r(istp,ih),';',
     &     istp=1,istact)

1600            format(i3,a1,i6,a1,f18.6,a1,8(f18.6,a1),f18.6,a1,f12.4,
     &      a1,14(f18.6,a1))

            call wrres(t_p(ip(ih),ih),it_p(ip(ih),ih),ih)
            ip(ih) = ip(ih)+1
          endif


c....Statistik: Zeitschritthistogramm ueber alle Haenge
          if (dt .le. clgr(1)) then
            class(1)=class(1)+1
            cltim(1)=cltim(1)+dt
          endif
          do 1 i=2,iacgr
          if ( (dt .gt. clgr(i-1)) .and. (dt .le. clgr(i)) ) then
            class(i)=class(i)+1
            cltim(i)=cltim(i)+dt
          endif
    1     continue
          if (dt .gt. clgr(iacgr)) then
            class(iacgr+1)=class(iacgr+1)+1
            cltim(iacgr+1)=cltim(iacgr+1)+dt
          endif
          if (izaehl(ih) .eq. 15) then
                rel_ab=rel_ab
cc				jw - WOZU?
          endif

c....Zeitschrittbestimmung
          if (rel_ab .lt. 1.) then
c....Verkleinerung in Abhaengigkeit von REL_AB
            dt = max(rel_ab*rel_ab*dt, 0.5*dt, dt_min)
            if (n_it .gt. n_gr) then
c....Verkleinerung in Abhaengigkeit der Picarditerationsschritte
              dt = dt * (1.-dble(n_it-n_gr)/dble(it_max))
            endif
          else
            if (n_it .gt. n_gr) then
c....Verkleinerung in Abhaengigkeit der Picarditerationsschritte
              dt = dt * (1.-dble(n_it-n_gr)/dble(it_max))
            else
c....Vergroesserung in Abhaengigkeit von REL_AB,
c CFL Kriterium im Falle von Makroporenfluss
              dt = min((1.+rel_ab)/2. * dt, 1.5*dt, dt_mak)
c              write(6,*)'dt', dt,'dt_mak', dt_mak
c              write(6,*)'zeitschritterh�hung', dt, dt_mak
            endif
          endif
        endif
c--------------------------------------------------------------------


c....Test auf Print-Zeitpunkte
        if (t_act+dt .ge. t_p(ip(ih),ih)) then
          dt = (t_p(ip(ih),ih)-t_act)
        endif
c....Abschnitt zu Ende?
        if (t_act .ge. t_neu-1.e-10) then
          t_act=t_neu
          dt=max(dts,dt)
          goto 900
        endif
c....Neuer Zeitschritt ueber Abschnitt hinaus?
        if (t_act+dt .gt. t_neu) then
          dts=dt
          dt = t_neu-t_act
        endif

        if (dt .le. 0.) then
          stop 'dt < 0 in HG 1'
        endif

c   Datumstring plus Sekunden zu Datumsstring (Intervalmitte)
        call dsps2ds(dstrs, t_act+dt/2., datstr)
c   Datumstring zu Tag im Jahr
        call ds2diny(datstr,tagnr,tagstd)
        itag=dble(tagnr)
        stunde=dble(tagstd)

        goto 500
c ^-------------
  900 continue

        if (dt .le. 0.) then
          stop 'dt < 0 in HG 2'
        endif

      return
      end
