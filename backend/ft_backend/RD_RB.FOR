
      subroutine rdnutz()
c-----------------------------------------------------------------------
c  Lesen des zeitlich naechsten Zuordnungsfiles Schlag-Landnutzung
c-----------------------------------------------------------------------
      include 'dim.inc'
      include 'zeit.inc'
      include 'hgbdry.inc'

      character*22 date

      external dsds2ds

      t_ln(1)=t_ln(2)
      read(inutz,'(a30)',end=900) lnfile
      read (inutz,'(a22)') date
      call dsds2ds(date, dstrs, t_ln(2))
      goto 999
  900 continue
      stop 'Dateiende in RDNUTZ'
  999 continue
      return
      end


      subroutine rdzsnk(i)
c-----------------------------------------------------------------------
c  Lesen der naechsten Senke von Datei i
c-----------------------------------------------------------------------
      include 'dim.inc'
      include 'hgbdry.inc'
      integer*4 i, j, k
      integer*4 idum
      real*8  rdum
      character*80 cdum

      intrinsic abs

      do 1000 k=1,2
  100   read(iisnk(i),'(a)',end=900) cdum
        if (cdum(1:1).eq.'#') goto 100
        read(cdum,*) zsnk(k,i), isktyp(k,i)
        zsnk(k,i) = zsnk(k,i)*z2ssnk(i)-szsnk(i)
        read(cdum,*) rdum, idum, (skpar(k,j,i),j=1,1)
        if (abs(isktyp(k,i)) .eq. 1) then
          read(cdum,*) rdum, idum, (skpar(k,j,i),j=1,1)
        elseif (abs(isktyp(k,i)) .eq. 2) then
          read(cdum,*) rdum, idum, (skpar(k,j,i),j=1,1)
        elseif (abs(isktyp(k,i)) .eq. 11) then
          read(cdum,*) rdum, idum, (skpar(k,j,i),j=1,2)
        elseif (isktyp(k,i) .eq. 0) then
        elseif (isktyp(k,i) .eq. -4) then
        elseif (abs(isktyp(k,i)) .eq. 10) then
        elseif (abs(isktyp(k,i)) .eq. 99) then
          if (.not.lland) stop 'Landnutzung etc. fehlt (RDZSNK)'
        else
          stop 'Senkentyp existiert nicht (RDZSNK)'
        endif
 1000 continue
      backspace iisnk(i)

c... Festlegen, ob interpoliert wird
      lsintp(i) = .false.
c... Potential
      if ((isktyp(1,i) .eq. -1) .or. (isktyp(1,i) .eq. -2)) then
        if (isktyp(2,i) .eq. -1) lsintp(i) = .true.
        if (isktyp(2,i) .eq. -2) lsintp(i) = .true.
      endif
c... Fluss
      if ((isktyp(1,i) .eq. 0) .or. (isktyp(1,i) .eq.  1)
     &    .or. (isktyp(1,i) .eq.  2)) then
        if (isktyp(2,i) .eq.  0) lsintp(i) = .true.
        if (isktyp(2,i) .eq.  1) lsintp(i) = .true.
        if (isktyp(2,i) .eq.  2) lsintp(i) = .true.
      endif

      goto 999
  900 continue
      stop 'RB-Dateiende in RDZSNK'
  999 continue
      return
      end


      subroutine rdzkli(i)
c-----------------------------------------------------------------------
c  Lesen des naechsten Klimas von Datei i
c-----------------------------------------------------------------------
      include 'dim.inc'
      include 'hgbdry.inc'
      integer*4 i, j, k
      integer*4 iken, izehn
      real*8  rdum
      character*80 cdum
      save iken

      intrinsic dabs

      etilog=.true.
      do 1000 k=1,2
  100   read(iikli(i),'(a)',end=900) cdum
        if (cdum(1:1).eq.'#') goto 100
        read(cdum,*) zkli(k,i)
        zkli(k,i) = zkli(k,i)*z2skli(i)-szkli(i)
        read(cdum,*) rdum, (klima(k,j,i),j=1,iackld(i))
        if (k .eq. 1) then
          if (klfehlt(i)) then
            klfehlt(i)=.false.
            write(io(1),1111) zkli(k,i)/86400, iken
 1111       format(' Zeitpunkt ',f12.4,': Klimadaten ', i8, ' fehlen')
            do 301 j=1,iackld(i)
              klima(1,j,i)=klimas(j,i)
  301       continue
          endif
        elseif (k .eq. 2) then
          iken=0
          izehn=10
          do 300 j=1,iackld(i)
            if (klima(2,j,i) .lt. -998.99) then
              klfehlt(i)=.true.
              klima(2,j,i)=klima(1,j,i)
              klimas(j,i)=klima(1,j,i)
              iken=iken+izehn**(j-1)
            else
              klimas(j,i)=klima(2,j,i)
            endif
  300     continue
        endif
c Umrechnung Evaporation/Transpiration -> m/s, ggf. Vorzeichen
        if (ktyp(i) .eq. 2) then
          klima(k,1,i)=dabs(klima(k,1,i)*klifak(i))
          klima(k,2,i)=dabs(klima(k,2,i)*klifak(i))
        endif
        if (.not.lland) stop 'Landnutzung etc. fehlt (RDZKLI)'
 1000 continue
      backspace iikli(i)

      goto 999
  900 continue
      stop 'RB-Dateiende in RDZKLI'
  999 continue
      return
      end

      subroutine rdznie(i)
c-----------------------------------------------------------------------
c  Lesen des naechsten Niederschlags von Datei i
c-----------------------------------------------------------------------
      include 'dim.inc'
      include 'hgbdry.inc'
      integer*4 i, k
      real*8  rdum
      character*80 cdum

      intrinsic dabs

      do 1000 k=1,2
  100   read(iinie(i),'(a)',end=900) cdum
        if (cdum(1:1).eq.'#') goto 100
        read(cdum,*) znie(k,i)
        znie(k,i) = znie(k,i)*z2snie(i)-sznie(i)
        read(cdum,*) rdum, nied(k,i)
c Umrechnung Niederschlagseinheiten -> m/s, ggf. Vorzeichen
        nied(k,i)=dabs(nied(k,i)*niefak(i))

 1000 continue
      backspace iinie(i)

c... Festlegen, ob interpoliert wird
      lnintp(i) = .true.

      goto 999
  900 continue
      stop 'RB-Dateiende in RDZNIE'
  999 continue
      return
      end

      subroutine rdrbb()
c-----------------------------------------------------------------------
c  Lesen der Randbedingungszuordnung fuer den Bach
c-----------------------------------------------------------------------
      include 'dim.inc'
      include 'bach.inc'

      integer*4 iacbbr,ib 
	
	read(iin(7), *) iacbbr
c	write(6,*) iacqbr, iacbbr
	if (iacbbr .ne. iacqbr) then 
	 stop ' Randbedingungszuordnung ist nicht fuer alle
     &  Randknoten des Baches erfolgt'
      end if 
	
	do 100 ib=1, iacqbr
       read(iin(7),*) irb_b(ib)
 100  continue
 	 
      return
	end

      subroutine rdbrbf(i)
c-----------------------------------------------------------------------
c  Lesen des naechsten Abflusses respektable Wasserstandes von Datei i
c-----------------------------------------------------------------------
      include 'dim.inc'
      include 'bach.inc'
      integer*4 i, k
      real*8  rdum
      character*80 cdum


c ----------------------------------------------------------------------
c     bwq inputvariable fuer den bach entweder Wasserstand (ibrart=1) oder 
c     Abfluﬂ ibrart=2

      intrinsic dabs

c      write(6,*) 'rbbneu, rdbrbf Anfang', rbbneu, ibrbf(i)
	do 1000 k=1,2
  100   read(ibrbf(i),'(a)',end=900) cdum
        if (cdum(1:1).eq.'#') goto 100
        read(cdum,*) zbach(k,i)
        zbach(k,i) = zbach(k,i)*zfbach(i)-szbach(i)
        read(cdum,*) rdum, bwq(k,i)
c      write(6,*)'lese Rand rdbrbf, zeit, bwq', zbach(k,i), bwq(k,i)

 1000 continue
      backspace ibrbf(i)
      rbbneu = .true.
	write(6,*) 'rbbneu, rdbrbf ende', rbbneu
      goto 999
  900 continue
      stop 'RB-Dateiende in RDBRBF'
  999 continue
      return
      end


      subroutine rdrbs(irbs,ih)
c-----------------------------------------------------------------------
c  Lesen der Randbedingungszuordnung fuer einen Hang
c-----------------------------------------------------------------------
      include 'dim.inc'
      include 'hgfest.inc'
      include 'hgbdry.inc'
      include 'pbdry.inc'

      integer*4 maxken
      parameter (maxken = 8)

      character*1  kenn, klib(maxken)
      integer*4 kfound(maxken)
      integer*4 i, j, irbs
      integer*4 iv, il, ih
      integer*4 ianz, iart, ival
      integer*4 av, ev, al, el
      real*8  rav, rev, ral, rel

      external maxtst, getpts
      intrinsic int

      data klib /'R','L','O','U','S','T','B','M'/
      do 10 i=1,maxken
        kfound(i)=0
  10  continue

c Defaultwerte
         ival =  0              ! Nullfluss
c atmosphaerische RB
c         if (lland) then ival = -99        ! war inaktiv - ge‰ndert jw 2012-01-31 
      do 210 iv=1,iacnv(ih)
        irb_r(iv,ih)=ival
        irb_l(iv,ih)=ival
 210  continue
      do 230 il=1,iacnl(ih)
        irb_o(il,ih)=ival
        irb_u(il,ih)=ival
 230  continue
      do 260 iv=1,iacnv(ih)
        do 250 il=1,iacnl(ih)
          isnk(iv,il,ih)=ival
 250    continue
 260  continue

   1  read(irbs,'(a1)',end=900) kenn
      do 20 i=1,maxken
        if (kenn .eq. klib(i)) then
          kfound(i)=1
          goto (100,200,300,400,500,300,400,600) i
        endif
  20  continue
      goto 1
c
c  ianz            Anzahl von Bloecken
c  iart   = 0      relative Werte    [0-1]
c  iart   = 1      Punktnummern
c

c--rechts---------------------------------------------------------------
 100  continue
        read(irbs,*) ianz, iart
        do 111 j = 1,ianz
          if (iart .eq. 0) then
            read(irbs,*) rav,rev,ival
c    #jw#100826#  ge statt gt , ebenso weiter unten      
            if ((rav .ge. 1.) .and. (rev .ge. 1.)) then
              av = int(rav)
              ev = int(rev)
            else
              call getpts(av,ev,rav,rev,eta(1,ih),iacnv(ih))
            endif
          else
            read(irbs,*) av,ev,ival
          endif
           call maxtst('IVAL    ',ival,'IACRBF  ',iacrbf,'RDRBS   ')
          do 112 iv = av, ev
            irb_r(iv,ih)=ival
  112     continue
  111   continue
      goto 1
c--links----------------------------------------------------------------
 200  continue
        read(irbs,*) ianz, iart
        do 222 j = 1,ianz
          if (iart .eq. 0) then
            read(irbs,*) rav,rev,ival
            if ((rav .ge. 1.) .and. (rev .ge. 1.)) then
              av = int(rav)
              ev = int(rev)
            else
              call getpts(av,ev,rav,rev,eta(1,ih),iacnv(ih))
            endif
          else
            read(irbs,*) av,ev,ival
          endif
          call maxtst('IVAL    ',ival,'IACRBF  ',iacrbf,'RDRBS   ')
          do 121 iv = av, ev
            irb_l(iv,ih)=ival
  121     continue
  222   continue
      goto 1
c--oben-----------------------------------------------------------------
 300  continue
        read(irbs,*) ianz, iart
        do 333 j = 1,ianz
          if (iart .eq. 0) then
            read(irbs,*) ral,rel,ival
            if ((ral .ge. 1.) .and. (rel .ge. 1.)) then
              al = int(ral)
              el = int(rel)
            else
              call getpts(al,el,ral,rel,xsi(1,ih),iacnl(ih))
            endif
          else
            read(irbs,*) al,el,ival
          endif
          call maxtst('IVAL    ',ival,'IACRBF  ',iacrbf,'RDRBS   ')
          do 132 il = al, el
            irb_o(il,ih)=ival
  132     continue
  333   continue
      goto 1
c--unten----------------------------------------------------------------
 400  continue
        read(irbs,*) ianz, iart
        do 444 j = 1,ianz
          if (iart .eq. 0) then
            read(irbs,*) ral,rel,ival
            if ((ral .ge. 1.) .and. (rel .ge. 1.)) then
              al = int(ral)
              el = int(rel)
            else
              call getpts(al,el,ral,rel,xsi(1,ih),iacnl(ih))
            endif
          else
            read(irbs,*) al,el,ival
          endif
          call maxtst('IVAL    ',ival,'IACRBF  ',iacrbf,'RDRBS   ')
          do 142 il = al, el
            irb_u(il,ih)=ival
  142     continue
  444   continue
      goto 1
c--senken---------------------------------------------------------------
 500  continue
        read(irbs,*) ianz, iart
        do 555 j = 1,ianz
          if (iart .eq. 0) then
            read(irbs,*) rav,rev,ral,rel,ival
            if ((rav .ge. 1.) .and. (rev .ge. 1.)) then
              av = int(rav)
              ev = int(rev)
            else
              call getpts(av,ev,rav,rev,eta(1,ih),iacnv(ih))
            endif
            if ((ral .ge. 1.) .and. (rel .ge. 1.)) then
              al = int(ral)
              el = int(rel)
            else
              call getpts(al,el,ral,rel,xsi(1,ih),iacnl(ih))
            endif
          else
            read(irbs,*) av,ev,al,el,ival
          endif
          call maxtst('IVAL    ',ival,'IACSNK  ',iacsnk,'RDRBS   ')
          do 151 iv = av, ev
            do 152 il = al, el
              isnk(iv,il,ih)=ival
  152       continue
  151     continue
  555   continue
      goto 1

  600 continue 
      if(istact .ge. 1) then 
       read(irbs,*) ival
	  imf(ih)=ival
	end if
	goto 1
	 

      
c-----------------------------------------------------------------------

 900  continue
c----------- Tests
      do 710 iv=1,iacnv(ih)
        if (irb_r(iv,ih).eq.-99) then
        endif
        if (irb_l(iv,ih).eq.-99) then
        endif
 710  continue
      do 730 il=1,iacnl(ih)
        if (irb_o(il,ih).eq.-99) then
          if (.not.lland)
     &          write(*,*) 'Warnung: Keine Landnutzungsdaten gelesen'
          if (.not.lpob(ih)) stop 'Keine Oberflaechenindizes gelesen'
        endif
        if (irb_u(il,ih).eq.-99) then
        endif
 730  continue
      do 760 iv=1,iacnv(ih)
        do 750 il=1,iacnl(ih)
          if (isnk(iv,il,ih).eq.-99) then
            if (.not.lklima)
     &         stop 'Keine Klimadaten gelesen (RDRBS)'
            if (.not.lland)
     &         stop 'Keine Landnutzungsdaten gelesen (RDRBS)'
            if (.not.lpob(ih))
     &         stop 'Keine Oberflaechenindizes gelesen (RDRBS)'
          endif
 750    continue
 760  continue

c---Initialisiere Vorzeichen
      do 540 iv=1,iacnv(ih)
        vorz_l(iv,ih)=1
        vorz_r(iv,ih)=1
        if (irb_r(iv,ih) .eq.   0) vorz_r(iv,ih)= 1
        if (irb_r(iv,ih) .eq. - 3) vorz_r(iv,ih)= 1
        if (irb_r(iv,ih) .eq. -10) vorz_r(iv,ih)= 1
        if (irb_r(iv,ih) .eq. -99) vorz_r(iv,ih)= 1
        if (irb_r(iv,ih) .eq. - 4) vorz_r(iv,ih)=-1
        if (irb_r(iv,ih) .eq. - 5) vorz_r(iv,ih)=1
        if (irb_l(iv,ih) .eq.   0) vorz_l(iv,ih)= 1
        if (irb_l(iv,ih) .eq. - 3) vorz_l(iv,ih)= 1
        if (irb_l(iv,ih) .eq. -10) vorz_l(iv,ih)= 1
        if (irb_l(iv,ih) .eq. -99) vorz_l(iv,ih)= 1
        if (irb_l(iv,ih) .eq. - 4) vorz_l(iv,ih)=-1
        lueb_r(iv)=.false.
        lueb_l(iv)=.false.
 540  continue

	do 640 il=1,iacnl(ih)
        vorz_o(il,ih)=1
        vorz_u(il,ih)=1
        if (irb_o(il,ih) .eq.   0) vorz_o(il,ih)= 1
	  if (irb_o(il,ih) .eq. - 3) vorz_o(il,ih)= 1
        if (irb_o(il,ih) .eq. -10) vorz_o(il,ih)= 1
        if (irb_o(il,ih) .eq. -99) vorz_o(il,ih)= 1
        if (irb_o(il,ih) .eq. - 4) vorz_o(il,ih)=-1
        if (irb_u(il,ih) .eq.   0) vorz_u(il,ih)= 1
        if (irb_u(il,ih) .eq. - 3) vorz_u(il,ih)= 1
        if (irb_u(il,ih) .eq. -10) vorz_u(il,ih)= 1
        if (irb_u(il,ih) .eq. -99) vorz_u(il,ih)= 1
        if (irb_u(il,ih) .eq. - 4) vorz_u(il,ih)=-1
        if (irb_u(iv,ih) .eq. - 5) vorz_u(iv,ih)=1
        lueb_o(il)=.false.
        lueb_u(il)=.false.
 640  continue
      do 860 iv=1,iacnv(ih)
        do 850 il=1,iacnl(ih)
          if (isnk(iv,il,ih).eq.  0) vorz_s(iv,il,ih)= 1
          if (isnk(iv,il,ih).eq.- 3) vorz_s(iv,il,ih)= 1
          if (isnk(iv,il,ih).eq.-10) vorz_s(iv,il,ih)= 1
          if (isnk(iv,il,ih).eq.-99) vorz_s(iv,il,ih)= 1
          if (isnk(iv,il,ih).eq.- 4) vorz_s(iv,il,ih)=-1
          lueb_s(iv,il)=.false.
 850    continue
 860  continue

      return
      end

      subroutine rdpob(ih)
c-----------------------------------------------------------------------
c  Oberflaechenindizes falls atmosphaerische Randbedingung
c-----------------------------------------------------------------------
      include 'dim.inc'
      include 'hgfest.inc'
      include 'hgbdry.inc'

      integer*4 ih, il, ifix, iwrf, ihor

      external maxtst

      if (lklima) then
       read(ilok,*) iacfix, iwrf, iachor
       call maxtst('IACFIX  ',iacfix,'MAXFIX  ',maxfix,'RDPOB   ')
       call maxtst('IWRF    ',iwrf  ,'MAXWRF  ',maxwrf,'RDPOB   ')
       if (iwrf .ne. iacwrf) then
	  stop 'Falsche Anzahl Windabminderungsfaktoren in RDPOB'
       endif
       read(ilok,*)
       do 100 il = 1,iacnl(ih)
        if (iacwrf .gt. 0) then
          if (iachor .gt. 0) then
            read(ilok,*) (ifixob(il,ifix,ih), ifix=1,iacfix),
     &                   (wrf(il,iwrf,ih), iwrf=1,iacwrf),
     &                   (hor(il,ihor,ih), ihor=1,iachor)
          else
            read(ilok,*) (ifixob(il,ifix,ih), ifix=1,iacfix),
     &                   (wrf(il,iwrf,ih), iwrf=1,iacwrf)
c	      write(6,*) (ifixob(il,ifix,ih), ifix=1,iacfix),
C     &                   (wrf(il,iwrf,ih), iwrf=1,iacwrf)
          endif
        else
          read(ilok,*) (ifixob(il,ifix,ih), ifix=1,iacfix)
        endif
        if (iacfix .ge. 2)
     &  call maxtst('IFIXOB  ',ifixob(il,2,ih),
     &              'IACNIE  ',iacnie,'RDPOB   ')
        if (iacfix .ge. 3)
     &  call maxtst('IFIXOB  ',ifixob(il,3,ih),
     &              'IACKLI  ',iackli,'RDPOB   ')
  100  continue

      else

       read(ilok,*) iacfix
       call maxtst('IACFIX  ',iacfix,'MAXFIX  ',maxfix,'RDPOB   ')
       read(ilok,*)
       do 101 il = 1,iacnl(ih)
        read(ilok,*) (ifixob(il,ifix,ih), ifix=1,iacfix)
        if (iacfix .ge. 2)
     &  call maxtst('IFIXOB  ',ifixob(il,2,ih),
     &              'IACNIE  ',iacnie,'RDPOB   ')
  101  continue

      endif
c      write(6,*) '(ifixob(il,ifix,ih)'
c	write(6,*) il,ifix,ih,iacnl(ih)
c	write(6,*) (ifixob(il,ifix,ih), ifix=1,iacfix), ifix
      return
      end

      subroutine rdlpar()
c-----------------------------------------------------------------------
c  Lesen der einzelnen Landnutzung und deren Parameterfiles
c-----------------------------------------------------------------------
      include 'dim.inc'
      include 'hgbdry.inc'

      character*80 cstring
      character*30 filnam
      integer*4 iuse, ipft, ipfp
      real*8 offset, fak
      dimension fak(maxpfp)

      external openi
      external maxtst
      intrinsic max

       iacuse=0
c      iuse=1
  100 continue
        read (iin(3),'(a80)',end=900) cstring
        read (cstring(1:9),*) iuse
        cluse(iuse)=cstring(10:39)
        filnam=cstring(40:69)

        read(cstring(1:9),*) luseid(iuse)
        call openi(ipar,filnam,io(1))
        read(ipar,*) iacpfp
        call maxtst('IACPFP+1',iacpfp+1,'MAXPFP  ',maxpfp,'RDLPAR  ')
        read(ipar,*) offset , (fak(ipfp),ipfp=2,iacpfp+1)
        ipft=1
   80   continue
          read(ipar,*,end=90) (pflpar(ipft,ipfp,iuse),ipfp=1,iacpfp+1)
          pflpar(ipft,1,iuse)=pflpar(ipft,1,iuse)+offset
          do 10 ipfp=2,iacpfp+1
            pflpar(ipft,ipfp,iuse)=pflpar(ipft,ipfp,iuse)*fak(ipfp)
   10     continue
          ipft=ipft+1
          goto 80
   90   continue
        close(ipar)
        iacpft(iuse)=ipft-1
        if (pflpar(1,1,iuse) .gt. 0.9) then
          do 11 ipft=iacpft(iuse),1,-1
            do 12 ipfp=1,iacpfp+1
              pflpar(ipft+1,ipfp,iuse)=pflpar(ipft,ipfp,iuse)
   12       continue
   11     continue
          iacpft(iuse)=iacpft(iuse)+1
          pflpar(1,1,iuse)=0.9
          do 13 ipfp=2,iacpfp+1
            pflpar(1,ipfp,iuse)=0.
   13     continue
        endif
        if (pflpar(iacpft(iuse),1,iuse) .lt. 366.1) then
          iacpft(iuse)=iacpft(iuse)+1
          do 14 ipfp=2,iacpfp+1
            pflpar(iacpft(iuse),ipfp,iuse)=0.    ! jw warum Null setzen?
   14     continue
          pflpar(iacpft(iuse),1,iuse)=366.1
        endif
       call maxtst('IACPFT  ',iacpft(iuse),'MAXPFT  ',maxpft,'RDLPAR  ')
c        iuse=iuse+1
      goto 100
  900 continue
c      iacuse=iuse-1
      iacuse=max(iuse,iacuse)
      call maxtst('IACUSE  ',iacuse,'MAXUSE  ',maxuse,'RDLPAR  ')
      return
      end

      subroutine getln(ih)
C-----------------------------------------------------------------------
C  Lese Zuweisung Schlagnr.-Landnutzungsnr.
C  Update der Oberflaechenpunkte eines Hangs mit neuen LN-nummern
C-----------------------------------------------------------------------

      include 'dim.inc'
      include 'hgfest.inc'
      include 'hgbdry.inc'

      integer*4 maxia
      parameter (maxia=20)
      integer*4 il, ih, ischl, iln, ia, ib, i
      dimension ib(maxia)

      external openi

      do 100 il=1,iacnl(ih)
        iusenr(il,ih)=-1
  100 continue

      call openi(ilok,lnfile,io(1))
      read(ilok,*,end=900) ia
      if (ia .gt. maxia) stop 'Redimensionieren in GETLN'

 2000 continue
      read(ilok,*,end=900) ischl, (ib(i),i=1,ia)
      iln = ib(ia)

      do 110 il=1,iacnl(ih)
        if (ifixob(il,1,ih) .eq. ischl) iusenr(il,ih)=iln
  110 continue
      goto 2000

  900 continue
      close(ilok)

      do 120 il=1,iacnl(ih)
        if (iusenr(il,ih) .eq. -1) then
          write(*,500) lnfile
          stop 'Datei vervollstaendigen!!!'
        endif
  120 continue

      return

  500 format('Schlagnr.-Landnutzungsnr. Zuweisung in Datei ',a,
     &       ' unvollstaendig!')
      end
