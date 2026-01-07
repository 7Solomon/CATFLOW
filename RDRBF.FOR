c-----------------------------------------------------------------------
c   Lesen der Dateinamen, Oeffnen und Positionieren auf ersten Wert der
c    - Randbedingungs-Zeitreihen
c    - Senken-Zeitreihen
c    - Niederschlags-Zeitreihen
c    - Klima-Zeitreihen
c    - Landnutzungs-Zeitreihen und Daten
c-----------------------------------------------------------------------
      subroutine rdrbf()

      include 'dim.inc'
      include 'zeit.inc'
      include 'hgbdry.inc'
      include 'pbdry.inc'
      include 'pfest.inc'
	include 'bach.inc'

      integer*4 maxken
      parameter (maxken = 11)
      integer*4 i
      character*1  kenn, klib(maxken)
      character*80 cdum
      character*30 ftnutz
      character*22 date

      external maxtst, openi, dsds2ds
      external rdzrbf,rdzsnk,rdznie,rdzkli
      external rdnutz, rdminf, rdbrbf

      data klib /'R','S','N','K','V','L','B','P','C','M','D'/
      iacrbf=0
      iacsnk=0
      iacnie=0
      iackli=0
c      istact=0
      iacmif=0
      lland = .false.
      lklima= .false.
      lnied = .false.

   1  read(iin(2),'(a1)',end=900) kenn
      do 20 i=1,maxken
        if (kenn .eq. klib(i)) goto (1000,2000,3000,4000,7000,5000,
     &                               1000,3000,4000,6000,7000) i
  20  continue
      goto 1

c Lese Randbedingungszeitreihe, neu lese istact ------------------------
 1000 continue
      read(iin(2),*) iacrbf !,istact                       ! jw comment?
      call maxtst('IACRBF  ',iacrbf,'MAXRBF  ',maxrbf,'RDRBF   ')
      call maxtst('ISTACT  ',istact,'MAXSTT  ',maxstt,'RDRBF   ')
      do 330 i=1,iacrbf
        read(iin(2),'(a30)') rbfil(i)
        call openi(iirbf(i),rbfil(i),io(1))
c.... Auffinden des ersten Intervalls
  101   read (iirbf(i),'(a)') cdum
        if (cdum(1:1).eq.'#') goto 101
        call dsds2ds(dstrs, cdum(1:22), szrbf(i))
        if (szrbf(i) .lt. 0.) stop 'RBed. unvollstaendig! (RDRBF)'
        read (cdum(23:80),*) z2srbf(i)

 1001   call rdzrbf(i)
        if (zrbf(2,i) .le. t_start) goto 1001
  330 continue
      goto 1

c-----------------------------------------------------------------------
 2000 continue
      read(iin(2),*) iacsnk
      call maxtst('IACSNK  ',iacsnk,'MAXSNK  ',maxsnk,'RDRBF   ')
      do 331 i=1,iacsnk
        read(iin(2),'(a30)') snkfil(i)
        call openi(iisnk(i),snkfil(i),io(1))
c.... Auffinden des ersten Intervalls
  201   read (iisnk(i),'(a)') cdum
        if (cdum(1:1).eq.'#') goto 201
        call dsds2ds(dstrs, cdum(1:22), szsnk(i))
        if (szsnk(i) .lt. 0.) stop 'Senk. unvollstaendig! (RDRBF)'
        read (cdum(23:80),*) z2ssnk(i)
 2001   call rdzsnk(i)
        if (zsnk(2,i) .le. t_start) goto 2001
  331 continue
      goto 1

c-----------------------------------------------------------------------
 3000 continue
      read(iin(2),*) iacnie
      call maxtst('IACNIE  ',iacnie,'MAXNIE  ',maxnie,'RDRBF   ')
      do 332 i=1,iacnie
        lnied=.true.
        read(iin(2),'(a30)') n_fil(i)
        call openi(iinie(i),n_fil(i),io(1))
c.... Auffinden des ersten Intervalls
  301   read (iinie(i),'(a)') cdum
        if (cdum(1:1).eq.'#') goto 301
        call dsds2ds(dstrs, cdum(1:22), sznie(i))
        if (sznie(i) .lt. 0.) stop 'Nied.unvollstaendig! (RDRBF)'
        read (cdum(23:80),*) z2snie(i), niefak(i)
 3001   call rdznie(i)
        if (znie(2,i) .le. t_start) goto 3001
  332 continue
      goto 1

c-----------------------------------------------------------------------
 4000 continue
      read(iin(2),*) iackli
      call maxtst('IACKLI  ',iackli,'MAXKLI  ',maxkli,'RDRBF   ')
      do 333 i=1,iackli
        klfehlt(i)=.false.
        lklima=.true.
        read(iin(2),'(a30)') k_fil(i)
        call openi(iikli(i),k_fil(i),io(1))
c.... Auffinden des ersten Intervalls
  401   read (iikli(i),'(a)') cdum
        if (cdum(1:1).eq.'#') goto 401
        read (cdum,*) ktyp(i), rbilart(i)
  402   read (iikli(i),'(a)') cdum
        if (cdum(1:1).eq.'#') goto 402
        call dsds2ds(dstrs, cdum(1:22), szkli(i))
        if (szkli(i) .lt. 0.) stop 'Klima unvollstaendig! (RDRBF)'
        if (ktyp(i) .eq. 1) then
          iackld(i)=6
c     erfordert 10 Pflanzenparameter (IACPFP=10)
          read (cdum(23:80),*) z2skli(i), zref(i),
     &                 sw0(i),sw1(i),sw2(i),trueb(i),truebf(i)
        elseif (ktyp(i) .eq. 2) then
          iackld(i)=3
c     erfordert 2 Pflanzenparameter (IACPFP=2)
          read (cdum(23:80),*) z2skli(i), klifak(i)
        else
          stop 'Klimatyp existiert nicht! (RDRBF)'
        endif
 4001   call rdzkli(i)
        if (zkli(2,i) .le. t_start) goto 4001
  333 continue
      goto 1

c-----------------------------------------------------------------------
 5000 continue
        lland = .true.
c.....Landnutzungsaenderungszeitpunkte
        read(iin(2),'(a30)') ftnutz
        call openi(inutz,ftnutz,io(1))
c.... Auffinden des ersten relevanten Intervalls
        read (inutz,'(a22)') date
        call dsds2ds(date, dstrs, t_ln(2))
        if (t_ln(2) .gt. 0.) stop 'LN-Zeitreihe unvollstaendig! (RDRBF)'
 5001   call rdnutz()
        if (t_ln(2) .le. t_start) goto 5001
      goto 1
c----------------------------------------------
c  Lese inputmassen fÅr verschiedene Stofftypen
c  iacrbf=iacmif (muessen gleich sein)

 6000 continue
      read(iin(2),*) iacmif
      call maxtst('IACMIF  ',iacmif,'MAXRBF  ',maxrbf,'RDRBF   ')
      do 630 i=1,iacmif
        read(iin(2),'(a30)') minfil(i)
        call openi(iimif(i),minfil(i),io(1))
        call rdminf(i,istact)
  630 continue
      goto 1

c---- Einlesen der Randbedingungsfiles f¸r Randknoten im Bach
 7000 continue
      read(iin(2),*) iacbrf
      call maxtst('IACBRF  ',iacbrf,'MAXBRF  ',maxbrf,'RDRBF   ')
      do 650 i=1,iacbrf
        read(iin(2),'(a30)') brbfil(i)
        call openi(ibrbf(i),brbfil(i),io(1))
c.... Auffinden des ersten Intervalls
  701   read (ibrbf(i),'(a)') cdum
        if (cdum(1:1).eq.'#') goto 701
        call dsds2ds(dstrs, cdum(1:22), szbach(i))
        if (szbach(i).lt.0.)stop 'Randbed. Bach unvollstaendig! (RDRBF)'
	  read (cdum(23:80),*) zfbach(i)
        call rdbrbf(i)
  650 continue
      goto 1


  900 continue  
      return
      end
