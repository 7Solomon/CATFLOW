      program catflow
C-----------------------------------------------------------------------
     
      include 'dim.inc'
      include 'zeit.inc'
      include 'bach.inc'
      include 'hgfest.inc'
      include 'hgvari.inc'
      include 'hgbdry.inc'
      include 'pbdry.inc'
      include 'pfest.inc'
      include 'pvari.inc'

      real*8 tic,toc,toc2
      real*8 dt_s, dt, t_off, dtzh  !, dt_help ! jw unused
      dimension dt(maxnh)

      integer*4 i, ncf, ieins       !, im       ! jw unused
      integer*4 izero, ipp

      integer*4 il, iv, ih, icv, istp, ibla
      character*3 meth
	character*6 q_meth


      integer*4 ii0, ii00
      character*30 ifile00, ifile0
      character*60 ckst
      dimension ifile0(maxfil)

      integer*4 iihg, iist, ibna, iini, iprt, irbs, iima, iicv, iinip
	integer*4 iinks, iinths
      character*30 hgfile, stfile, bnafil, inifil, prtfil, rbsfil
      character*30 mafile, cvfile, inpfil
      character*30 pobfil, rksfile, rthsfile

      integer*4 i_s, ntr, ib
      character*30 ifile
      dimension ifile(maxin)
      character*30 ofile
      dimension ofile(maxout)
      logical*4 ex
      real grs, gre
      integer*4 igrs, igre
      integer*4 clsum
      real*8  t_sum, clrel, t_rel, one, t_eff, t_nzh
      dimension t_rel(maxgr+1), clrel(maxgr+1)
      dimension t_eff(maxgr+1)
      real*8 rcoeff, rtim
      real tagnr, tagstd

      integer*4 ipkt, npkt, opkt
      logical*4 pktex
      integer*4 punkt
      dimension punkt(maxpkt,6)


      external dsps2ds
      external ds2diny
      external openi, openo
      external rdhang, calbna, calgeo, rdsoil, bodtab, inicon, rdstyp
      external rdprt, hgcopy, rdmak, rdcv, psi_phi, rdpob, rdlpar
      external rel_sec, dsds2ds, maxtst, rdwind, rdbach
      external getln, hg, wrres, rdrbf, rdrbs, gettn, getnrb
      external upvorz, upvors, nullen, savevz, hgnull
      external cal_q, kc_phi, calfak, bach
      external v_strb, c_ipob,  getbpt, getrrb, rdbini
      external inipart, calipos, calflek
      intrinsic abs, max, min, index
      intrinsic aint, log10, dble, int

      call rel_sec(tic)

      izero=0
      ieins=1
      ibla=0

      opkt = 14
      ilok = 15
      ii00 = 19
      ii0  = 20
      iihg = 21
      iist = 22
      iini = 23
	iinip =24
      iprt = 25
      ibna = 26
      irbs = 27
      ipar = 28
      inutz= 29
      iima = 30
      iicv = 31
	iinks = 32
	iinths = 33

      i_s = 34
c      write(6,*)' Zuweisen der Unit nummern'
c      write(6,*)'maxmif', maxmif
      do 333 i = 1,maxout
        io(i) = i_s + i
  333 continue
      do 334 i = 1,maxin
        iin(i) = io(maxout) + i
  334 continue
      do 345 i = 1,maxkli
        iikli(i) = iin(maxin) + i
  345 continue
      do 346 i = 1,maxnie
        iinie(i) = iikli(maxkli) + i
  346 continue
      do 347 i = 1,maxrbf
        iirbf(i) = iinie(maxnie) + i
  347 continue
      do 348 i = 1,maxsnk
        iisnk(i) = iirbf(maxrbf) + i
  348 continue
      do 349 i = 1, maxmif
         iimif(i) = iisnk(maxsnk) + i
c         write(6,*)'iimif=', iimif(i)
  349 continue
      do 350 i= 1, maxbrf
	   ibrbf(i)=iimif(maxmif) +i
  350 continue

c-----------------------------------------------------------------------
c  Einlesen Haupt-Steuerfile
c-----------------------------------------------------------------------
      write(6,*)'FILES EINLESEN'
      ifile00='catflow.in'
c      call openi(ii00,ifile00,0)
      call openi(ii00,ifile00,ibla)
      icf=1
  552 read (ii00,'(a)',end=551) ckst
      ifile0(icf)=ckst(1:30)

      call maxtst('ICF      ',icf,'MAXFIL  ',maxfil,'CATFLOW ')
      if (ifile0(icf)(1:2).eq.'  ') goto 551
      read (ckst(31:60),*) kstall(icf)
      icf=icf+1
      goto 552
  551 ncf=icf-1
      close(ii00)

      do 9000 icf=1,ncf
c-----------------------------------------------------------------------
c  Einlesen Steuerfile
c-----------------------------------------------------------------------
      write(*,1114) ifile0(icf)
 1114 format(10(/),'Steuerfile              ',a30)
c      call openi(ii0,ifile0(icf),0)
      call openi(ii0,ifile0(icf),ibla)

      read (ii0,'(a22)') dstrs
      read (ii0,'(a22)') dstre
        call dsds2ds(dstre, dstrs, t_end)
      read(ii0,*) t_off
       t_start = t_off
       t_alt = t_start
       lqactiv=.true.
       t_nzh=t_end

c   Datumstring plus Sekunden zu Datumsstring
       call dsps2ds(dstrs, t_start, dstrs2)
c   Datumstring zu Tag im Jahr
       call ds2diny(dstrs2,tagnr,tagstd)
       itag=dble(tagnr)
       stunde=dble(tagstd)
c------ Default setting for switch i_sorp
      i_sorp =1

      read (ii0,'(a3)') meth
      read(ii0,*) dtbach
      read(ii0,*) qtol
      read(ii0,*) dt_max
      read(ii0,*) dt_min
      read(ii0,*) dt_s
      read(ii0,*) d_Th_opt
      read(ii0,*) d_Phi_opt
      read(ii0,*) n_gr
      read(ii0,*) it_max
      read(ii0,*) piceps
      read(ii0,*) cgeps
      read(ii0,*) rlongi
      read(ii0,*) longi
      read(ii0,*) lati
      read(ii0,*) istact 
	if (istact .gt. 0) then
       backspace(ii0)
       read(ii0,*) istact, i_sorp           ! jw vgl. RDRBF.for. Z. 50
	end if  
      read(ii0,*) iseed
	read(ii0,'(a6)') q_meth

c...Initialisiere Statistik
      grs = log10(dt_min)
      if (grs .gt. 0) then
        igrs = int(grs+1.)
      else
        igrs = int(grs)
      endif
      gre = log10(dt_max)
      if (gre .gt. 0) then
        igre = int(gre)
      else
        igre = int(gre-1.)
      endif
      iacgr = igre-igrs+1
      call maxtst('IACGR   ',iacgr,'MAXGR   ',maxgr,'CATFLOW ')
      do 1 i=1,iacgr
        clgr(i) = 10.**(i-1+igrs)
   1  continue
      do 2 i=1,iacgr+1
       class(i) = 0
       cltim(i) = 0.
   2  continue

c---- Vorfluter - Hangaustausch ja oer nein
      if (q_meth .eq. 'simact') then
       auint= .true.
	elseif (q_meth .eq. 'noiact') then
	 auint= .false.
	end if

c...Initialisiere Dateien
      read(ii0,*) io_act
      if (io_act .lt. 1) stop 'zu wenig Ausgabedateien (CATFLOW)'
      read(ii0,*) (io_log(i),i=1,io_act)
      call maxtst('IO_ACT  ',io_act,'MAXOUT  ',maxout,'CATFLOW ')
      do 336 i=1,io_act
c        write(6,*)'Zahl der Ausgabefiles',io_act
        read(ii0,'(a30)') ofile(i)
        call openo(io(i),ofile(i),io(1))
  336 continue
      read(ii0,*) iin_act
      call maxtst('IIN_ACT ',iin_act,'MAXIN   ',maxin,'CATFLOW ')
      do 335 i=1,iin_act
        read(ii0,'(a30)') ifile(i)
        call openi(iin(i),ifile(i),io(1))
  335 continue

      write(io(1),1511) dstrs
      write(*    ,1511) dstrs
 1511 format('  Start: ',a22)
      write(io(1),1512) dstre, t_end
      write(*    ,1512) dstre, t_end
 1512 format('  Ende:  ',a22,'   d.h. ',f16.0, ' [s]')
      write(io(1),*) 't_off    ',t_off
      write(io(1),*) 'dtbach   ',dtbach
      write(io(1),*) 'qtol     ',qtol
      write(io(1),*) 'dt_max   ',dt_max
      write(io(1),*) 'dt_min   ',dt_min
      write(io(1),*) 'dt_s     ',dt_s
      write(io(1),*) 'd_Th_opt ',d_Th_opt
      write(io(1),*) 'd_Phi_opt',d_Phi_opt
      write(io(1),*) 'n_gr     ',n_gr
      write(io(1),*) 'it_max   ',it_max
      write(io(1),*) 'piceps   ',piceps
      write(io(1),*) 'cgeps    ',cgeps

      if (auint .and. iin_act .lt. 7) then
	 stop 'Zu wenig Eingabefiles, Anfangs-Randbed. Vorfluter fehlt'
	end if

      call rdsoil()
      close(iin(1))

      call bodtab()
      close(io(2))

      call rdrbf()
      close(iin(2))
      call gettn(t_nzh)

c.....Landnutzungen und Tabellennamen
      if (lnied .and. lklima) then
        if (iin_act .ge. 3) then
          call rdlpar()
          close(iin(3))
        else
          stop 'Zuweisungsdatei Landnutzungsnummer-Parameterdatei fehlt'
        endif
        if (iin_act .ge. 4) then
          call rdwind()
          close(iin(4))
        else
          stop 'Zuweisungsdatei Windsektoren fehlt'
        endif
      endif

      read(ii0,*) iacnh
      if (iacnh .lt. 0) then
        iacnh = -iacnh
        ihgr=0
      else
        ihgr=iacnh
      endif

      call maxtst('IACNH   ',iacnh,'MAXNH   ',maxnh,'CATFLOW ')
c-----------------------------------------------------------------------
c  Dateneinleseschleife ueber alle Haenge, Initialisierung
c-----------------------------------------------------------------------
      do 200 ih=1,iacnh


c jw hier richtig, oder besser unten, wenn geo-file eingelesen ist? s. comments


c--------------------------------------------------------------------
c    Teilchenzahlen: (TZ)
c    npact: akutelle  TZ; npalt: alte TZ
c    ninpot, ninact: potent. und aktuelle Injektion am Knoten il
c    np_ofl: Teilchenverlust mit O-abfluss
c    Verlust am rechten, linken und unteren Rand:
c    nplosr, nplosl und nplosu
c--------------------------------------------------------------------
        do 666 istp = 1, istact
          npalt(istp,ih) = 0
          npact(istp,ih) = 0
          np_ofl(istp,ih) = 0
          nposum(istp,ih) = 0
          nplosl(istp,ih) = 0
          nplosr(istp,ih) = 0
          nplosu(istp,ih) = 0
          m_pt(istp,ih)= 0.
          do 667 il = 1, maxnl        ! jw maxnl hier nicht bekannt?
            ninpot(istp,il) = 0       !! abhängig von ih (mehrere Hänge)
            ninact(istp,il) = 0
  667     continue
          do 668 iv=1, maxnv-1              ! jw besser iacnv(ih),
	     do 669 il= 1, maxnl-1              !  iacnl(ih)
		    c_tact(istp,iv,il,ih)=0.
		    mpkon(istp,iv,il)=0.
            npkon(istp,iv,il)=0
  669      continue
  668     continue
          ! initialize iplos
         do ipp=1,npmax
	    iplos(istp,ipp,ih)=1
	   end do
  666   continue

        read(ii0,'(a30)') hgfile
        write(*,1120) ih, hgfile
 1120   format('Hanggeometrie(',i3,')       ',a30)
        call openi(iihg,hgfile,io(1))
        call rdhang(iihg,ih)
        close(iihg)

c       write(*    ,913) iacnv(ih)      ! jw hier ist iacnv, iacnl bekannt
c 913   format('iacnv(ih)              ',i5)

        read(ii0,'(a30)') stfile
        write(*,1122) ih, stfile
 1122   format('Bodentypzuweisung(',i3,')   ',a30)
        call openi(iist,stfile,io(1))
        call rdstyp(iist,ih)
        close(iist)
  
        read(ii0,'(a30)') rksfile
        write(*,1222) ih, rksfile
 1222   format('KS STATISTIK(',i3,')   ',a30)
        call openi(iinks,rksfile,io(1))
        call statks(iinks,ih)
        close(iinks)

        read(ii0,'(a30)') rthsfile
        write(*,1222) ih, rthsfile
 1223   format('Theta_s STATISTIK(',i3,')   ',a30)
        call openi(iinths,rthsfile,io(1))
        call statths(iinths,ih)
        close(iinths)

c... macropore parameters
        read(ii0,'(a30)') mafile
        write(*,1123) ih, mafile
 1123   format('Makroporenzuweisung(',i3,') ',a30)

c      ... initialise 'macro'-array
          do 10 iv = 1, iacnv(ih)
            do 11 il = 1, iacnl(ih)
                macro(iv,il,ih) = 1.
   11       continue
   10     continue
  
  !   ### Changed by EZ read macropore file after surface attribute to use landuse specific fmak     
  !      inquire (file=mafile,exist=ex)
  !      
  !      if (.not.ex) then
  !        lmak(ih)=.false.
  !      else
  !        lmak(ih)=.true.
  !        call openi(iima,mafile,io(1))
  !        call rdmak(iima,ih)
  !        close(iima)
  !      endif

        read(ii0,'(a30)') cvfile
        write(*,1130) ih, cvfile
 1130   format('Kontrollv.zuweisung(',i3,') ',a30)
        iaccv(ih)=1
        icvu(1,ih)=1
        icvo(1,ih)=iacnv(ih)
        icvl(1,ih)=1
        icvr(1,ih)=iacnl(ih)
        inquire (file=cvfile,exist=ex)
        if (ex) then
          call openi(iicv,cvfile,io(1))
          call rdcv(iicv,ih)
          close(iicv)
        endif

        ntr = index(hgfile,'.')
        bnafil = hgfile
        bnafil(ntr:ntr+3) = '.bna'
        inquire (file=bnafil,exist=ex)
c        if (.not.ex) then
          write(*,1124) ih, bnafil
 1124     format('Bodenzellenpolygone(',i3,') ',a30)
          call openo(ibna,bnafil,io(1))
          call calbna(ih,ibna)
          close(ibna)
c        endif

        call calgeo(ih)

        read(ii0,'(a30)') inifil
        write(*,1126) ih, inifil
 1126   format('Anfangsfeuchte(',i3,')      ',a30)
        call openi(iini,inifil,io(1))
        call inicon(iini,ih)
        close(iini)
        call hgcopy(phiini,phialt(1,1,ih),ih)

        if (istact .gt. 0) then
         read(ii0,'(a30)') inpfil
         inquire (file=inpfil,exist=ex)
         write(*,1127) ih, inpfil
 1127    format('Anfangskonzentration(',i3,')      ',a30)
         if(ex) then
          call openi(iinip,inpfil,io(1))
          call inipart(iinip,ih)
          close(iinip)
	   else
	     stop 'Datei mit Anfangskonzentrationen fehlt (CATFLOW)'
         end if
	  end if

        read(ii0,'(a30)') prtfil
        write(*,1128) ih, prtfil
 1128   format('Ausgabezeitpunkte(',i3,')   ',a30)
        inquire (file=prtfil,exist=ex)
        if (.not.ex) then
          do 191 i = 1,maxprt
  191     t_p(i,ih) = 1.e20
        else
          call openi(iprt,prtfil,io(1))
          call rdprt(iprt,ih)
          close(iprt)
        endif

        read(ii0,'(a30)') pobfil
        if (lnied .or. lklima) then
          inquire (file=pobfil,exist=ex)
          write(*,1131) ih, pobfil
 1131     format('Oberflaech.indizes(',i3,') ',a30)
          if (ex) then
            lpob(ih)=.true.
            call openi(ilok,pobfil,io(1))
            call rdpob(ih)
            close(ilok)
          else
            lpob(ih)=.false.
            if (lnied .or. lklima) then
              stop 'Datei mit Oberflaechenindizes fehlt (CATFLOW)'
            endif
          endif
        endif

        read(ii0,'(a30)') rbsfil
        write(*,1129) ih, rbsfil
 1129   format('Randbedingungen/S.(',i3,')  ',a30)
        call openi(irbs,rbsfil,io(1))
        call rdrbs(irbs,ih)
        close(irbs)

 
        
c--------------------------------------------------------------------           jw vielleicht auch hier entspr. Teil von oben - Z304?
c    Teilchenzahlen: (TZ)
c    npact: akutelle  TZ; npalt: alte TZ
c    ninpot, ninact: potent. und aktuelle Injektion am Knoten il
c    np_ofl: Teilchenverlust mit O-abfluss
c    Verlust am rechten, linken und unteren Rand:
c    nplosr, nplosl und nplosu
c--------------------------------------------------------------------



c---   Errechnung der Teilchenmassen fuer alle Haenge und Initialsieren
c      der Teilchenorte aus den Anfangsbedinungen

c------ Initialisiere Teilchenzahl und Position am oberen Rand als Linienquelle
c        write(6,*)'TEILCHENRB.', strand

        if (istact .gt. 0) then
	   call calipos(ih)
	  end if
        if (lpob(ih)) then
          call getln(ih)
        endif
c  ### changed by erwin 11.02.2020  read makropore file after assignment of landuse id to surface nodes 
        inquire (file=mafile,exist=ex)
        
        if (.not.ex) then
          lmak(ih)=.false.
        else
          lmak(ih)=.true.
          call openi(iima,mafile,io(1))
          call rdmak(iima,ih)
          close(iima)
        endif
        
        izaehl(ih) = 0
        ip(ih) = 1
c Bilanzierungsgroessen
        do 640 icv=1,iaccv(ih)
          biltot(icv,ih) = 0.
          bilin(icv,ih)  = 0.
          bilrd(icv,ih)  = 0.
          bsenk(icv,ih)  = 0.
          bsueb(icv,ih)  = 0.
          brfl_u(icv,ih) = 0.
          brfl_o(icv,ih) = 0.
          brfl_r(icv,ih) = 0.
          brfl_l(icv,ih) = 0.
          bnied(icv,ih)  = 0.
          bnied2(icv,ih)  = 0.
          bintz(icv,ih)  = 0.
          bevapo(icv,ih) = 0.
          btrans(icv,ih) = 0.
  640   continue
        do istp=1,istact
	    bm_l(istp,ih)=0.
          bm_u(istp,ih)=0.
          bm_r(istp,ih)=0.
        end do
        bueb_u(ih) = 0.
        bueb_o(ih) = 0.
        bueb_r(ih) = 0.
        bueb_l(ih) = 0.
        qosum(ih)  = 0.
        qomax(ih)  = 0.
	  qssum(ih)  =0.
	  qshg(ih)   =0.
c MIN/MAX Groessen
        sk_max(ih)    =   0.
        fl_max(ih)    =   0.
        th_max(ih)    =   0.
        psi_max(ih)   =  -9.9e9
        phi_max(ih)   =  -9.9e9
        th_min(ih)    = 100.
        psi_min(ih)   =   9.9e9
        phi_min(ih)   =   9.9e9
  200 continue
c-----------------------------------------------------------------------
c  Ende: Dateneinleseschleife ueber alle Haenge, Initialisierung

      close(ii0)

      if (iin_act .ge. 5) then
        call rdbach()
	  close(iin(5))
      endif

c      Im Falle von Aueninteraktion, Assozieren der Gewaesserknoten mit Haengen (Pointer)
c      Initialisieren es Vorfluters
c      Update  der Rechten Randbed. und Berücksichtigen des Leckagefaktors in den gesättigten Leitfahikeiten

	  if(auint) then
         write(6,*)' Simulation von Aueninteraktion'
	   call getbpt()
         call getrrb()
         call rdbini()
         call calflek
	   close(iin(6))
         call rdrbb()
         do i=1,iacbrf
          call rdbrbf(i)
         end do
  	   close(iin(7))
	  end if



      do 211 i=1,iacrbf
        call upvorz(i)
  211 continue
      do 213 i=1,iacsnk
        call upvors(i)
  213 continue

      do 212 ih=1,iacnh
c schreibe AB auf Ausgabefiles
        call hgcopy(phialt(1,1,ih),phineu,ih)
        call savevz(ih)
        call kc_phi(phialt(1,1,ih),ih)
        call calfak(ih)
        call hgnull(senk,ih)
        call hgnull(sueb,ih)
        call nullen(ih)
        call cal_q(ih)
c        call hgnull(qxalt,ih)
c        call hgnull(qealt,ih)
		call hgcopy(q_xsi,qxalt,ih)
		call hgcopy(q_eta,qealt,ih)
        call hgcopy(theta,th_alt,ih)
        call hgnull(gtxact,ih)
        call hgnull(gtxalt,ih)
        call hgnull(gteact,ih)
        call hgnull(gtealt,ih)
		call hgnull(vx_sta,ih)
		call hgnull(ve_sta,ih)
c------- eta xsi System
c        call v_str(ih, dt)
c------- hko sko System
c        call v_strb(ih, dt)
        call wrres(t_start,ieins,ih)
        dt_mak=dt_max
c        write(6,*)'1 mal', dt_mak
        dt(ih)=dt_s
  212 continue

      call rel_sec(toc)
      write(*,1600) toc-tic
      write(io(1),1600) toc-tic
 1600 format(/,'Daten einlesen:     ',f8.1,' sec')
      write(*,1700) meth
      write(io(1),1700) meth
 1700 format(/,'Berechnungsmethode: ',5x,a3)

      call rel_sec(tic)

c Log-file
      write(io(1),1503)
      if (iacnh .lt. ihgr) then
        write(io(1),1501)
        write(io(1),1502)
        write(io(1),1503)
      endif
 1501 format( ' no  izaehl    t_act     dt    cumbil    stpbil    ',
     &        'opt/    n_it    dPhi')
 1502 format( '                [h]     [s]    [vol]     [rfl]     ',
     &        'max    cg pic    max')
 1503 format(73('-'))
c        1234567890 234567890 234567890 234567890 234567890 234567890 23456789
c Debug-file
c      write(io(3),4109)
      write(io(3),4110)
      write(io(3),4112)
c      write(io(3),4109)
 4109 format(158('-'))
 4110 format(
     & 'Hg.;Zeitschritt;Zeit;totale Bil.;Auffeuchtung; Summe Senkenfl.; 
     & Summe Randfl; ',
     &  'kumul. Oberrandfl.;kumul. rechter.Randfl.;kumul. Unterrandfl.;
     & kumul.linker Randfl.;', 'kumul. Oberfl. Abfl.;Abfl.-Beiwert;
     & kumul. Freiland Nied.;kumul. Freiland Nied.;kumul.Interz-Verd.;
     & kumul. Bodenverd.;kumul. Transpiration;',
     & 'links: kumul. Verlust Stoff1; unten: kumul. Verlust Stoff1; 
     & rechts: kumul. Verlust Stoff1;'
     & 'links: kumul. Verlust Stoff2; unten: kumul. Verlust Stoff2;  
     & rechts: kumul. Verlust Stoff2;'
     & 'links: kumul. Verlust Stoff3; unten: kumul. Verlust Stoff3;  
     & rechts: kumul. Verlust Stoff3;')
 4112 format(
     &  '[-];[-];[s];[-];[cbm];[cbm];[cbm];',
     &  '[cbm];[cbm];[cbm];[cbm];[cbm];[-];' ,
     &  '[cbm];[mm];[cbm];[cbm];[cbm]; [kg]; [kg]; [kg];
     & [kg]; [kg]; [kg]; [kg]; [kg]; [kg];')

c      Oberflächenabfluss-Datei
      if (io_act .ge. 10) write(io(10),'(a22)') dstrs

c Vegetations-file
      if (io_act .ge. 11) write(io(11),4203)
      if (io_act .ge. 11) write(io(11),4201)
      if (io_act .ge. 11) write(io(11),4202)
 4203 format(
     &  ' 1   2     3     4     5     6     7        8       9      10',
     &  '       11       12    13   14    15   16    17    18    19',
     &  '      20     21     22       23        24        25        26',
     &  '    27      28  ')
 4201 format(
     &  ' ih  il  time   lai   bbg   twu   pfh     rGlo    rBil    ',
     &  'rBilm    shf     temp  rhum uref  al-  ustar u100 thpfvw intz',
     &  '    nied   neff  catmp    ccanop     catms     csoil',
     &  '     Ecanop Eintz   Esoil ')
 4202 format(
     &  '  -   -   d      -     -     m     m      W/mm    W/mm    ',
     &  'W/mm     W/mm    øC     -   m/s  -bedo  m/s  m/s   -      ',
     &  'mm     mm/d   mm/d   m/s       m/s       m/s       m/s      ',
     &  'mm/d   mm/d    mm/d')


        mafile='punkte.dat'
        inquire (file=mafile,exist=pktex)
        if (pktex) then
          call openi(opkt,mafile,io(1))
          ipkt=1
 7078     read(opkt,*,end=7079) (punkt(ipkt,il), il=1,6)
          ipkt=ipkt+1
          goto 7078
 7079     continue
          npkt=ipkt-1
          close(opkt)
          mafile='pktzeit.dat'
          call openo(opkt,mafile,io(1))
        endif

c-----------------------------------------------------------------------
c  Zeitschleife
c-----------------------------------------------------------------------
  500 continue
c--- seed fuer Zufallszahlen
c.. Speichern des kumulativen Hangoberflächen und Zwischenabflusses in der gerade
c   nicht benoetigten Variable QHANG

        do 101 ih=1,iacnh
          qhang(ih)=qosum(ih)
	    qshang(ih)=qssum(ih)
  101   continue

c.. Sicherstellen, dass Zeitschritt nie groesser als DTBACH
c   wenn Oberflaechenabfluss aktiv
        t_neu = t_end						
        if (lqactiv) then
c	    write(6,*)'lqactiv', lqactiv
          if (t_neu-t_alt .ge. dtbach) then
            t_neu=t_alt+dtbach
          endif
        endif


        if (t_neu .gt. t_nzh) t_neu=t_nzh
c         write(*,*)' t_neu=', t_neu

c.. Berechnungsschleife ueber alle Haenge fuer einen Zeithorizont
        if (iacnh .gt. ihgr) then
          call rel_sec(toc2)
          call dsps2ds(dstrs, t_alt, dstrs2)
          rtim=(t_alt-t_start)/(t_end-t_start)
          rtim=max(rtim,1.d-10)
          write(*,1555) dstrs2(1:19), t_alt/3600./24.,rtim*100.,
     &                  (toc2-tic)/60., (toc2-tic)/60./rtim
          if (io_log(1) .gt. 0) then
          write(io(1),1555) dstrs2(1:19), t_alt/3600./24.,rtim*100.,
     &                  (toc2-tic)/60., (toc2-tic)/60./rtim
          endif
 1555     format(a19,' d.h.',f8.3,' Tage=',f6.2,' % (',
     &            f9.2,' -> ',f7.0,' min )')
        endif

        do 100 ih=1,iacnh
          if (dt(ih) .ge. t_neu-t_alt) then
            dt(ih)=t_neu-t_alt
          endif
          t_act = t_alt
c...... AURUF des HANGMODULS 
          call hg(ih,dt(ih),meth)

c.. Abspeichern von Zeitreihen der Bodenfeuchte an einzelnen Punkten
          if (pktex) then
            do 197 ipkt=1,npkt
              if (punkt(ipkt,3) .eq. hangnr(ih)) then
                write(opkt,7070) punkt(ipkt,1), t_alt/86400.,
     &          (theta(iv,punkt(ipkt,4)),iv=punkt(ipkt,5),punkt(ipkt,6))
 7070           format(i3,f9.3,20f6.3)
              endif
  197       continue
          endif

  100   continue

c.. Zeitschritt bis zum aktuellen Zeithorizont
        dtzh=t_neu-t_alt
c.. Ermittlung des MITTLEREN Hangabflusses innerhalb DTZH
        do 102 ih=1,iacnh
         qhang(ih)=(qosum(ih)-qhang(ih))/dtzh
         qshang(ih)=(qssum(ih)-qshang(ih))/dtzh
          if (qosum(ih) .gt. 0.) then
		 lqactiv=.true.
	    end if
		if (auint) then
		 if(abs(qssum(ih)) .gt. 0.) lqactiv=.true.
	    else
		 if (qssum(ih) .gt. 0.) lqactiv = .true.
          end if
c      update der Randbedingung, falls sich was geändert hat     ! jw auint --> better '.OR.'?
         if (auint .and. rbbneu ) then                      
	    call koeffbr()
	    lqactiv = .true.
         end if

  102   continue

      if (iin_act .ge. 5) then
c.. Ermittlung des Abflusses von befestigten Flaechen;
c   wirkt direkt, d.h. Nieders. kommt auf
c   Flaeche zu 100 % unmittelbar zum Abfluss
        do 103 ib=1,iacnb
          qarea(ib)=nied(1,ib_reg(ib))
c          qarea(ib)=nied(1,1)
          if (qarea(ib) .gt. 0.) lqactiv=.true.
  103   continue

c.. Berechnung des Entwaesserungsnetzes bis zum aktuellen Zeithorizont
c   der Regen des ERSTEN Schreibers wird hier nur fuer
c   Protokollzwecke weitergegeben, auskommentiert fuer Kleinskalige Simulationen
c	     write(6,*) lqactiv
        if (lqactiv) call bach(dtzh,nied(1,1))
      endif

        t_alt = t_neu
c-----------------------------------------------------------------------

        if (t_alt .ge. t_end-0.0001) then
          goto 900
        else
          if (t_alt .lt. t_nzh) then
            goto 500
          else
c..  Update der Randbedingungszeitreihen
            call getnrb(t_neu)
	      if(lqactiv .and. auint) call getrrb()

c..  Festlegen des neuen Zeithorizonts (kleinste Zeit aller RB)
            t_nzh=t_end
            call gettn(t_nzh)
            goto 500
          endif
        endif
c ^-------------
  900 continue

      call rel_sec(toc)

C-----------------------------------------------------------------------
C  Programmabschluss
C-----------------------------------------------------------------------
      write(*    ,2001)
      write(*    ,2000)
      write(*    ,2001)
      write(*    ,2010)
      write(*    ,2011)
      write(*    ,2012)
      write(*    ,2001)
c      write(io(3),4109)
      write(io(3),2100)
c      write(io(3),2101)
      write(io(3),2110)
c      write(io(3),2111)
c      write(io(3),2112)
c      write(io(3),2101)
      do 300 ih=1,iacnh
c      write(6,*) 'bla', ih

c------ Berechnen der Konzentration im hko sko System
       do istp=1, istact
	  call c_ipob(istp,ih)
       end do

c...Schreibe das letzte Berechnungsergebnis auf die Ausgabe-Dateien
c       jw  1110    nach oben geschoben, damit Psi für jeden Hang richtig gesetzt wird
      call psi_phi(psi,phialt(1,1,ih),ih)            !       

c       jw 1110  Abfrage wieder aktiviert, damit Zeitpkt nicht doppelt in .out-file
      if(abs(t_end - t_p(ip(ih)-1,ih)) .gt. 1.) then    !
          call cal_q(ih)
          call wrres(t_end,ieins,ih)
      endif
c...Schreibe das letzte Berechnungsergebnis auf die fin-Datei
        if (io_act .ge. 6) then
         
         write(io(6),590) t_end, hangnr(ih), iacnv(ih), iacnl(ih),ieins

          do 190 iv = iacnv(ih),1,-1
            write(io(6),2090) (psi(iv,il), il = 1,iacnl(ih))
  190     continue
  590     format('PSI  ',f12.1,i4,3i5)		
c 2090     format(30f8.3)						    ! commented jw 11/02/08
 2090     format(2000e15.4E3)						! new jw 11/02/08
        endif

c... fuer jeden Hang
        if (qosum(ih) .gt. 0.) then
c          rcoeff=qosum(ih)/(qosum(ih)-brfl_o(1,ih)*vola(1,ih))
          rcoeff=qosum(ih)/bnied(1,ih)
        else
          rcoeff=0.
        endif
        write(*    ,2020) hangnr(ih), iacnl(ih)*iacnv(ih), vola(1,ih),
     &      biltot(1,ih), bilin(1,ih), -bsenk(1,ih), bilrd(1,ih), rcoeff
c        write(io(3),2120) hangnr(ih), iacnl(ih)*iacnv(ih), vola(1,ih),
c     &       biltot(1,ih), bilin(1,ih), -bsenk(1,ih), bilrd(1,ih),
c     &       -brfl_o(1,ih), -brfl_r(1,ih), brfl_u(1,ih), brfl_l(1,ih),
c     &        bnied(1,ih), bintz(1,ih), bevapo(1,ih), btrans(1,ih)
        
	  write(io(3),2129)'Hang',';',hangnr(ih)  
        do 650 icv=2,iaccv(ih)
        write(io(3),2121) icvu(icv,ih),';', icvo(icv,ih),';', 
C        write(io(3),*) icvu(icv,ih),';', icvo(icv,ih),';', 
     &  icvl(icv,ih),';',icvr(icv,ih),';', vola(icv,ih),';',
     &  biltot(icv,ih),';',bilin(icv,ih), ';', -bsenk(icv,ih),';', 
     &  bilrd(icv,ih),';',-brfl_o(icv,ih),';',-brfl_r(icv,ih), 
     &  ';',brfl_u(icv,ih),';',brfl_l(icv,ih),';',bnied(icv,ih),
     &  ';',bnied2(icv,ih), ';',bintz(icv,ih),';',bevapo(icv,ih),
     &  ';', btrans(icv,ih)
  650   continue
c        write(io(3),2130)           -bsueb(1,ih),
c     &       -bueb_o(ih), -bueb_r(ih), bueb_u(ih), bueb_l(ih),
c     &       qosum(ih)/vola(1,ih), rcoeff,
c     &       phi_min(ih)+hkomin(ih), phi_max(ih)+hkomin(ih),
c     &       th_min(ih)*100., th_max(ih)*100.,
c     &       psi_min(ih), psi_max(ih), fl_max(ih), sk_max(ih)
  300 continue
      write(*    ,2001)
c      write(io(3),2101)

 2000 format(//'Abschlusstabelle mit Hangdaten und Bilanzgroessen')
 2001 format(78('-'))
c        1234567890 234567890 234567890 234567890 234567890 2345678
 2010 format(
     &  ' Nr.	Elem.	Hang-	totale	   Auf-	     sum.Senk.	 sum.Rand
     &     Abfl.')
 2011 format(
     &  '	anz.	volumen	Bilanz	   feucht.   Zufluesse	 Zufluesse
     &   beiwert')
 2012 format(
     &  ' [-]	[-]	[cbm]	[cbm]	   [cbm]       [cbm]	   [cbm]   
     &    [-]')
 2020 format(i4,1x,i6,1x,f8.1,4(f10.3,1x),f10.2)


 2100 format(/'Abschlusstabelle mit Bilanzgroessen der 
     & Kontrollvolumina')
 2101 format(201('-'))

 2110 format(
     & 'Kontrollvolumen; ; ; ;Volumen;totale Bilanz;Auffeuchtung;
     &  Summe Senkenfl.;Summe Randfl.;Oberrandfl.;kumul. rechter Randfl;
     & kumul. Unterrandfl.;kumul. linker Randfl;kumul. Freiland Nied.;
     & kumul. Freiland Nied.;kumul. Interz-Verd;kumul. Bodenverd.;
     & kumul. Transpiration')
                      
CC # jwien # auskommentierte Format-Spez. gehören zu auskomm. WRITE-Befehlen

c 2120 format(i3,i5,f11.2,8f10.6,18x,4f10.6)
c 2121 format(4i3  ,f7.4, 8f10.6,18x,4f10.6)
c 2130 format(39x,f10.6,10x,4f10.6,f10.6,f8.4,2f12.2,2f6.1,2f12.2,2e12.3)

 2120 format(i4,1x,i6,1x,f13.2,1x,8(f12.6,1x),18x,4(f12.6,1x))
c 2121 format(4(i4,a1) ,f9.4,a1,8(f12.6,a1),18x,4(f12.6,1x))
 2121 format(4(i4,a1),13(e12.3,a1),e12.3)
 2129 format(a4,a1,i5)
c 2130 format(39x,f12.6,10x,4(f12.6,1x),f12.6,1x,
c     & f10.4,2(f14.2,1x),2(f8.1,1x),2(f14.2,1x),2(e14.3,1x))

c...Zeitschrittstatistik
      clsum = 0
      t_sum = 0.
      do 3 i=1,iacgr+1
        clsum = clsum + class(i)
        t_sum = t_sum + cltim(i)
    3 continue
      do 4 i=1,iacgr+1
        clrel(i) = dble(class(i))/dble(clsum)
        t_rel(i) = cltim(i)/t_sum
        if (clrel(i) .gt. 0.) then
          t_eff(i) = t_rel(i)/clrel(i)
        else
          t_eff(i) = 0.
        endif
    4 continue
      write(*    ,5000) toc-tic
      write(*    ,5002)
      write(*    ,5001) (toc-tic)/dble(clsum)
      write(*    ,5003) t_sum/dble(clsum)
      write(*    ,5002)
c      write(io(3),5000) toc-tic
c      write(io(3),5002)
c      write(io(3),5001) (toc-tic)/dble(clsum)
c      write(io(3),5003) t_sum/dble(clsum)
c      write(io(3),5002)
      do 5 i=1,iacgr
        write(*    ,5010)  clgr(i), class(i), clrel(i), t_rel(i),
     &      t_eff(i)

    5 continue
      i=iacgr+1
      write(*    ,5020) class(i), clrel(i), t_rel(i), t_eff(i)
      one=1.
      write(*    ,5002)
      write(*    ,5030)  clsum, one, one

 5000 format(/'Histogramm: Zeitschritte, Naturzeit               ',
     &        '   Berech.dauer: ',f8.1,' sec')
 5002 format( '--------------------------------------------------')
 5001 format( ' Klassengrenze       Anzahl       Zeit   rel.Zeit/',
     &        '   Durchs.delta t',f8.1,' sec')
 5003 format( '      [s]        absolut relativ relativ rel.Anz. ',
     &        '   Durchs.Delta t',f8.1,' sec')
 5010 format(f13.3,3x,i7,f8.3,f8.3,f9.4)
 5020 format(16x     ,i7,f8.3,f8.3,f9.4)
 5030 format(16x     ,i7,f8.3,f8.3)

      do 446 i=2,io_act
        close(io(i))
  446 continue
      do 545 i = 1,iackli
        close(iikli(i))
  545 continue
      do 546 i = 1,iacnie
        close(iinie(i))
  546 continue
      do 547 i = 1,iacrbf
        close(iirbf(i))
  547 continue
      do 548 i = 1,iacsnk
        close(iisnk(i))
  548 continue
      do i=1,iacmif
	   close(iimif(i))
	end do

      if (lland) close(inutz)

      close(io(1))
      if (pktex) close(opkt)

 9000 continue

      end

c end of program CATFLOW
c ---------------------------------------------------------------------


      subroutine gettn(tneu)
C-----------------------------------------------------------------------
      include 'dim.inc'
      include 'hgbdry.inc'
	include 'bach.inc'

      integer*4 i
      real*8 tneu

      do 100 i=1,iacrbf
        if (zrbf(2,i) .lt. tneu) tneu=zrbf(2,i)
  100 continue
      do 200 i=1,iacsnk
        if (zsnk(2,i) .lt. tneu) tneu=zsnk(2,i)
  200 continue
      do 300 i=1,iackli
        if (zkli(2,i) .lt. tneu) tneu=zkli(2,i)
  300 continue
      do 400 i=1,iacnie
        if (znie(2,i) .lt. tneu) tneu=znie(2,i)
  400 continue
      if (auint) then
       do 600 i=1,iacbrf
        if (zbach(2,i) .lt. tneu) tneu=zbach(2,i)
  600  continue
      end if

      if (lland) then
        if (t_ln(2) .lt. tneu) tneu=t_ln(2)
      endif

      return
      end

      subroutine getnrb(tneu)
C-----------------------------------------------------------------------
C  Hole neue Randbedingungen etc.
C-----------------------------------------------------------------------
      include 'dim.inc'
      include 'hgbdry.inc'
      include 'hgfest.inc'
	include 'bach.inc'

      integer*4 i
      real*8 tneu, eps
      intrinsic abs
      external rdzrbf,rdzsnk,rdznie,rdzkli,rdnutz, getln
      external upvorz, upvors, rdbrbf

      eps = 0.01

      do 100 i=1,iacrbf
        if (abs(zrbf(2,i)-tneu) .lt. eps) then
          call rdzrbf(i)
          call upvorz(i)
        endif
  100 continue
      do 200 i=1,iacsnk
        if (abs(zsnk(2,i)-tneu) .lt. eps) then
          call rdzsnk(i)
          call upvors(i)
        endif
  200 continue
      do 300 i=1,iackli
        if (abs(zkli(2,i)-tneu) .lt. eps) call rdzkli(i)
  300 continue
      do 400 i=1,iacnie
        if (abs(znie(2,i)-tneu) .lt. eps) call rdznie(i)
  400 continue

      if (lland) then
        if (abs(t_ln(2)-tneu) .lt. eps) then
          call rdnutz()
          do 500 i=1,iacnh
            if (lpob(i)) call getln(i)
  500     continue
        endif
      endif

c ----- Bach --------------------------------------
      if (auint) then
       do 600 i=1,iacbrf
        if (abs(zbach(2,i)-tneu) .lt. eps) call rdbrbf(i)
  600  continue
      end if

      return
      end

      subroutine getrrb()
c-----------------------------------------------------------------------
c  Update der rechten Randbedingung am Hang aus dem Vorfluterwasserstand
c-----------------------------------------------------------------------
      include 'dim.inc'
      include 'hgfest.inc'
      include 'bach.inc'
      include 'hgbdry.inc'


      integer*4  ib         ! ihb,i, j, !jw unused
      integer*4 iv, il, ih
      integer*4 av, ev
      real*8  rav, rev

      external maxtst, getpts
      intrinsic int

c------------------------------------------------------
c  rechter Rand ist Sickerrand oberhalb des Wasserspiegels
c  sowie Druckrand unterhalb
c  Wasserstand wird bezogen auf Hangunterkannte
c
      do 120 ih=1, iacnh
        if (inter(ihgb(ih))) then
         il=iacnl(ih)
	   ib=ihgb(ih)
         do 110 iv=1, iacnv(ih)
         irb_r(iv,ih) = -10.
         vorz_r(iv,ih)= 1
 110     continue
         rav=0.
         rev=(hko(iacnv(ih),il,ih)-y_bach(ib)-y_vorl(ib)-
     &   hko(1,il,ih))/(hko(iacnv(ih),il,ih)-hko(1,il,ih))
         call getpts(av,ev,rav,rev,eta(1,ih),iacnv(ih ))
         do 111 iv = av, ev
          irb_r(iv,ih)=maxrbf
	    irbtyp(1,irb_r(iv,ih))=-1
	    vorz_r(iv,ih)=-1
 111     continue
        endif
 100   continue
 120  continue
	return
      end


      subroutine getbpt()
C-----------------------------------------------------------------------
C  Pointer auf den zum Hang gehörigen Gewässerknoten
C-----------------------------------------------------------------------
      include 'dim.inc'
      include 'hgbdry.inc'
      include 'hgfest.inc'
	include 'bach.inc'

      integer*4 ih, ib
c      real*8 tneu, eps             ! jw unused
      do 100 ih=1, iacnh
       do 110 ib=1, iacnb
      	 if(inhang(ib) .eq. hangnr(ih)) ihgb(ih)= ib
 110   continue
 100  continue
c      do ih=1, iacnh
c	 write(6,*) ih, hangnr(ih), ihgb(ih)
c	end do
      return
      end


      subroutine upvorz(i)
C-----------------------------------------------------------------------
      include 'dim.inc'
      include 'hgbdry.inc'
      include 'hgfest.inc'

      integer*4 iv,il,ih,i
      intrinsic isign

      do 110 ih=1,iacnh
        do 101 iv=1,iacnv(ih)
          if (irb_l(iv,ih) .eq. i) then
            vorz_l(iv,ih)=1.
            vorz_l(iv,ih)=isign(vorz_l(iv,ih),irbtyp(1,i))
          endif
          if (irb_r(iv,ih) .eq. i) then
            vorz_r(iv,ih)=1.
            vorz_r(iv,ih)=isign(vorz_r(iv,ih),irbtyp(1,i))
          endif
  101   continue
        do 102 il=1,iacnl(ih)
          if (irb_o(il,ih) .eq. i) then
            vorz_o(il,ih)=1.
            vorz_o(il,ih)=isign(vorz_o(il,ih),irbtyp(1,i))
c            write(6,*)'vor_o, irbtyp', vorz_o(il,ih), irbtyp(1,i)
          endif
          if (irb_u(il,ih) .eq. i) then
            vorz_u(il,ih)=1.
            vorz_u(il,ih)=isign(vorz_u(il,ih),irbtyp(1,i))
          endif
  102   continue
  110 continue
      return
      end

      subroutine upvors(i)
C-----------------------------------------------------------------------
      include 'dim.inc'
      include 'hgbdry.inc'
      include 'hgfest.inc'

      integer*4 iv,il,ih,i
      intrinsic isign

      do 110 ih=1,iacnh
        do 101 iv=1,iacnv(ih)
          do 103 il=1,iacnl(ih)
            if (isnk(iv,il,ih) .eq. i) then
              vorz_s(iv,il,ih)=1.
              vorz_s(iv,il,ih)=isign(vorz_s(iv,il,ih),isktyp(1,i))
            endif
  103     continue
  101   continue
  110 continue

      return
      end
