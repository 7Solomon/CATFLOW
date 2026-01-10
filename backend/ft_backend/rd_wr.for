      subroutine rdsoil()
c-----------------------------------------------------------------------
c  Lesen der Bodenarten und deren Parameter
c-----------------------------------------------------------------------

      include 'dim.inc'
      include 'soil.inc'
      include 'pfest.inc'
      include 'pbdry.inc'
	include 'hgbdry.inc'

      integer*4 ipbm,ityp, npbm ,istp, ibod

      intrinsic real
      external maxtst

      read (iin(1),*) iactyp
      call maxtst('IACTYP  ',iactyp,'MAXTYP  ',maxtyp,'RDSOIL  ')
c      do 100 ityp = 1,iactyp
c         read(iin(1),1000) boden(ityp)
c         read(iin(1),*) imod(ityp), iactab(ityp),
c     &                  anisot(1,ityp), anisot(2,ityp),
c     &                  snull(ityp),
c     &                  satkni(ityp),balmax(ityp),balmin(ityp),
c     &                  f_rs(ityp),wp_rs(ityp),zd_max(ityp)
c         call maxtst('IACTAB  ',iactab(ityp),'MAXTAB  ',maxtab,
c     &                                                 'RDSOIL  ')
c------ geaendert 7.7. Lagerungsdichte wird zum Vg-modell ergaenzt
c         if (imod(ityp) .eq. 1) then
c           npbm = 8
c         elseif (imod(ityp) .eq. 2) then
c           npbm = 9
c         elseif (imod(ityp) .eq. 3) then
c           npbm = 7
c         elseif (imod(ityp) .eq. 99) then
c           npbm = 0
c         else
c          write(*,4000) imod(ityp), ityp
c 4000     format(/,'Bodenparametermodell ',i2,' des ',i2,
c     &                  '. Bodens existiert nicht vorgesehen',/)
c          STOP 'Unterprogramm RDSOIL'
c         endif
c         call maxtst('NPBM    ',npbm,'MAXPBM  ',maxpbm,'RDSOIL  ')
c         if (imod(ityp) .eq. 99) then
c           read(iin(1),'(a30)') tabfil(ityp)
c         else
c           read(iin(1),*) (bodpar(ipbm,ityp), ipbm=1,npbm), sattgr(ityp)
cc          write(6,*)'lagerungsdichte', bodpar(8,ityp),ityp
c           read(iin(1),*) (abbau(istp,ityp), istp=1, istact)
c           read(iin(1),*) (k_sorp(istp,ityp), istp=1, istact)
c	     read(iin(1),*)  (d_koef(istp,ityp), istp=1, istact)

c         endif
c  100 continue
c     neu mit expliziter Vergabe der Bodenartennummer
      do 100 ityp = 1,iactyp
         read(iin(1),1000) boden(ityp)
	   read(boden(ityp),*) ibod 
	   write(6,*) 'bodenprofil ', boden(ityp)
c	   write(6,*) ibod
         read(iin(1),*) imod(ibod), iactab(ibod),
     &                  anisot(1,ibod), anisot(2,ibod),
     &                  snull(ibod),
     &                  satkni(ibod),balmax(ibod),balmin(ibod),
     &                  f_rs(ibod),wp_rs(ibod),zd_max(ibod)
         call maxtst('IACTAB  ',iactab(ibod),'MAXTAB  ',maxtab,
     &                                                 'RDSOIL  ')

         if (imod(ibod) .eq. 1) then
           npbm = 8
         elseif (imod(ibod) .eq. 2) then
           npbm = 9
         elseif (imod(ibod) .eq. 3) then
           npbm = 7
         elseif (imod(ibod) .eq. 99) then
           npbm = 0
         else
          write(*,4000) imod(ibod), ibod
 4000     format(/,'Bodenparametermodell ',i2,' des ',i2,
     &                  '. Bodens existiert nicht vorgesehen',/)
          STOP 'Unterprogramm RDSOIL'
         endif
         call maxtst('NPBM    ',npbm,'MAXPBM  ',maxpbm,'RDSOIL  ')
         
         if (imod(ibod) .eq. 99) then
           read(iin(1),'(a30)') tabfil(ibod)
         else
           read(iin(1),*) (bodpar(ipbm,ibod), ipbm=1,npbm), sattgr(ibod)
           read(iin(1),*) (abbau(istp,ibod), istp=1, istact)
c       ### different adsorption isothermes
c       ##   i_sorp =1 linear, i_sorp = 2 Freundlich, i_sorp = 3 Langmuir           
            if (i_sorp .eq. 1) then
		     read(iin(1),*) (k_sorp(istp,ibod), istp=1, istact)
		    else if (i_sorp .gt. 1) then
		     read(iin(1),*) (k_sorp(istp,ibod),sorp2(istp,ibod),
     &       istp=1, istact)
		    end if   
           read(iin(1),*)  (d_koef(istp,ibod), istp=1, istact)
c		 write(6,*) (d_koef(istp,ibod), istp=1, istact)
         endif
  100 continue

 1000 format(a30)

      return
      end

      subroutine rdwind()
c-----------------------------------------------------------------------
c  Lesen der Windrichtungssektoren
c-----------------------------------------------------------------------
      include 'dim.inc'
      include 'hgbdry.inc'
      integer iwrf, ikli
      external maxtst
      
c	write(6,*) 'unit=', iin(4)
      read(iin(4),*) iacwrf
      do iwrf=1, iacwrf
       read(iin(4),*) wru(iwrf),(bezfak(iwrf,ikli),ikli=1,iackli)
      end do
 	write(6,*) 'iacwrf', iacwrf
      
c	write(6,*) 'rein maxtst, rdwind', iacwrf, maxwrf
      call maxtst('IACWRF  ',iacwrf,'MAXWRF  ',maxwrf,'RDWIND  ')
c      write(6,*) 'raus maxtst, rdwind'
	do 110 iwrf=1,iacwrf-1
        wro(iwrf)=wru(iwrf+1)
  110 continue
      wro(iacwrf)=wru(1)

      return
      end

      subroutine rdbach()
c-----------------------------------------------------------------------
c  Lesen der Vorflutergeometrie
c-----------------------------------------------------------------------
      include 'dim.inc'
      include 'bach.inc'
      include 'hgfest.inc'
      include 'hgbdry.inc'

      integer*4 ib, ib2, idum, ih, k
      real*8 rdum, xbbez, ybbez

      intrinsic sqrt
      external maxtst

      read(iin(5),*) xbbez, ybbez
      read(iin(5),*)
      read(iin(5),*)
      read(iin(5),*)
      read(iin(5),*)
      ib=1
      iacgng=1
  100 read(iin(5),*,end=99)
     &  idum, ibnext(ib), ib_ord(ib), inhang(ib), inarea(ib),
     &  xba(ib), yba(ib), b_vorl(ib),
     &  b_dx(ib), rdum, rdum, aahang(ib), b_ezg(ib), ib_reg(ib),
     &  b_rauh(ib), b_yso(ib), y_vorl(ib), brso(ib), b_m(ib),
     &  b_gef(ib), weg_br(ib), qbas(ib), flek(ib), iqsour(ib)
c     	write(6,*) idum, ibnext(ib), ib_ord(ib), inhang(ib), inarea(ib),
c     &  xba(ib), yba(ib), b_vorl(ib),
c     &  b_dx(ib), rdum, rdum, aahang(ib), b_ezg(ib), ib_reg(ib),
c     &  b_rauh(ib), b_yso(ib), y_vorl(ib), brso(ib), b_m(ib),
c     &  b_gef(ib), weg_br(ib), qbas(ib), flek(ib), iqsour(ib)

	if (idum .lt. 0) then
        igang(iacgng)=-idum
        iacgng=iacgng+1
      endif
      xba(ib)=xba(ib)+xbbez
      yba(ib)=yba(ib)+ybbez
      
c    Austausch findet statt an Hauptknoten im System, die stets Wasser fuehren
	if((flek(ib) .gt. 0.) .and. (inhang(ib) .gt. 0)) then
	 inter(ib)=.true.
	else
	 inter(ib)= .false.
	end if
c      write(6,*)qbas(ib), qsour(ib), inter(ib), ib
      ib=ib+1
      goto 100
   99 continue
      
	iacgng=iacgng-1
      call maxtst('IACGNG  ',iacgng,'MAXGNG  ',maxgng,'RDBACH  ')
      iacnb=ib-1
      call maxtst('IACNB   ',iacnb,'MAXNB   ',maxnb,'RDBACH  ')
      ib_ord(iacnb)=ib_ord(iacnb-1)
      b_dx(iacnb)=b_dx(iacnb-1)
      

      do 110 ib=1,iacnb
        if (inhang(ib) .ne. 0) then
          igewkn(1,inhang(ib))=ib
          exhg(inhang(ib))=.false.
          do 111 ih=1,iacnh
            if (inhang(ib) .eq. hangnr(ih)) then
              exhg(inhang(ib))=.true.
              goto 112
            endif
  111     continue
  112     continue
          if (.not.exhg(inhang(ib))) then
             write(*,*) 'WARNUNG: Gewaesserzufluss wird nicht',
     &       ' berechnet von Hang ', inhang(ib)
             write(io(1),*) 'WARNUNG: Gewaesserzufluss wird nicht',
     &       ' berechnet von Hang ', inhang(ib)
          endif
        endif
        if (inarea(ib) .ne. 0) igewkn(2,inarea(ib))=ib
        itmax(ib)=0
        do 120 ib2 = 1,ib
          if (ib .eq. ibnext(ib2)) then
            itmax(ib)=itmax(ib)+1
            ibtop(ib,itmax(ib))=ib2
           call maxtst('ITMAX   ',itmax(ib),'MAXIT   ',maxit,'RDBACH  ')
          endif
  120   continue
c        call maxtst('IB_REG  ',ib_reg(ib),'IACNIE  ',iacnie,'RDBACH  ')
  110 continue

      do 233 ib=1,iacnb
        y_bach(ib)=0.
        v_bach(ib)=0.
  233 continue
      qpegel=0.
      qpmax=0.
      dtsur=-1.

c     Auffinden der Rand- bzw. Quellknoten
      
	k=0
	do 130 ib =1, iacnb
c	 write(6,*) iqsour(ib),ib
	 if(iqsour(ib) .eq. 0) then
	  qsour(ib)=0.
	  else if (iqsour(ib) .eq. 1) then 
	  iqrbb(k+1)=ib
	  k=k+1
	 end if
 130  continue
      iacqbr=k 	   
c      write(6,*) 'iacqbr', iacqbr
	return
      end


      subroutine calflek

c     Einbau eines Leckage Faktors fuer die Simulation von Aueninteraktion
      include 'dim.inc'
      include 'hgfest.inc'
      include 'soil.inc'
	include 'bach.inc'

      integer*4 iv,il,ih
      
	do ih=1, iacnh
 	 do il= iacnl(ih), iacnl(ih)-1, -1
	  do iv =1, iacnv(ih)
	   kxx(iv,il,ih)= flek(ihgb(ih))*kxx(iv,il,ih)
         kxe(iv,il,ih)= flek(ihgb(ih))*kxe(iv,il,ih)
         kxxf(iv,il,ih) = kxx(iv,il,ih)
         kxef(iv,il,ih) = kxe(iv,il,ih)
        end do
	 end do
      end do	
      return
	end

      subroutine rdbini()
c-----------------------------------------------------------------------
c  Lesen des Anfangszustands im Bach 
c   Wasserstände m
c-----------------------------------------------------------------------
      include 'dim.inc'
      include 'bach.inc'
      include 'hgfest.inc'
      include 'hgbdry.inc'

      integer*4 ib          !, ib1! jw not used
	real*8 y_bbach
      

c	ib=0

 
  200 read(iin(6),*,end=99) ib, y_bbach
      y_bach(ib)=y_bbach
	goto 200

   99 continue
      if (ib .ne. iacnb) then
	 write(6,*)'Fehler in Inputdatei Nr. 6:'
	 write(6,100) ib, iacnb
100   format('Wasserstand an ', i3,' von ', i3,' Knoten vorgegeben')
	 stop ' Abbruch'
	end if
      
	return
      end

      subroutine rdhang(iihg,ih)
c-----------------------------------------------------------------------
c  Lesen einer Hanggeometrie  (*.geo)
c-----------------------------------------------------------------------
      include 'dim.inc'
      include 'hgfest.inc'
      include 'hgvari.inc'

      integer*4 iv,il,ih
      integer*4 iihg
      real*8 w_fix

      external maxtst

      read(iihg,*) iacnv(ih), iacnl(ih), w_fix, hangnr(ih)
      hgih(hangnr(ih))=ih
      call maxtst('IACNV   ',iacnv(ih),'MAXNV   ',maxnv,'RDHANG  ')
      call maxtst('IACNL   ',iacnl(ih),'MAXNL   ',maxnl,'RDHANG  ')
      read(iihg,*) xkobez(ih), ykobez(ih), hkobez(ih)
      read(iihg,*) hgobfl(ih), hgbreit(ih), hglang(ih)
      read(iihg,*) (eta(iv,ih),iv = 1,iacnv(ih))
      do 50 il = 1,iacnl(ih)
        read(iihg,*) xsi(il,ih),
c     &               xko(iacnv(ih),il,ih), yko(iacnv(ih),il,ih),
     &               xko(il), yko(il),
     &               varbr(il,ih)
   50 continue
      hkomin(ih) = 1.e10
      do 110 il = 1,iacnl(ih)
        do 100 iv = 1,iacnv(ih)
          read(iihg,*) hko(iv,il,ih), sko(iv,il,ih),
     &                 f_eta(iv,il,ih), f_xsi(iv,il,ih),
     &                 w_xsho(iv,il), w_hohr(iv,il),
     &                 iboden(iv,il,ih)
          if (hko(iv,il,ih) .lt. hkomin(ih)) hkomin(ih) = hko(iv,il,ih)
          w_xshr(iv,il) = 0.
          w_xshol(iv,il,ih)=w_xsho(iv,il)
  100   continue
  110 continue
      open(1001,file='angles.dat')
	open(1002,file='angles_2.dat')
c     rauschreiben der diskretisierung in file 16 und 17
      write(io(16),'(i5,x,i5,x,i5)')  -(1000+hangnr(ih)) 
     &	,iacnv(ih), iacnl(ih)
      if(iacnl(ih) .ge. 10) write(io(17),'(i5,x,i5,x,i5)')  
     &	-(1000+hangnr(ih)),iacnv(ih), iacnl(ih)

	  do 105 iv= iacnv(ih), 1, -1
        write(io(16),300) (hko(iv,il,ih), il=1,iacnl(ih))
        write(io(17),300) (sko(iv,il,ih), il=1,iacnl(ih))
        write(1001,300) (w_xsho(iv,il), il=1,iacnl(ih))
	  write(1002,300) (w_hohr(iv,il), il=1,iacnl(ih))
  105 continue
       close(1001)
	 close(1002)
c	  do 105 il=1, iacnl(ih)
c	   do 106 iv=1, iacnv(ih)
c        write(io(14),*) il, iv,'  1'
c  106 continue
c  105 continue
c	  do 107 il=1, iacnl(ih)
c	   do 108 iv= iacnv(ih), 1, -1
c	    write(io(13),300) sko(iv,il,ih), -1*hko(iv,il,ih)
c  108 continue
c  107 continue

  513 format(i5,2(x,e8.2) )             !jw unused?
  300 format(1001(f10.4,1x))
c  310 format(2i3)

c  Winkel gegen xsi muss an den beiden auessesten Punkten Null sein!!
      do 200 iv = 3,iacnv(ih)-2
        do 210 il = 3,iacnl(ih)-2
          w_xshr(iv,il)=w_hohr(iv,il)+w_xsho(iv,il)+w_fix
  210   continue
  200 continue
      return
      end


      subroutine rdstyp(iist,ih)
c-----------------------------------------------------------------------
c  Lesen der Bodentypzuweisung eines Hanges (*.art)
c-----------------------------------------------------------------------
      include 'dim.inc'
      include 'hgfest.inc'
      include 'hgvari.inc'
      include 'soil.inc'

      integer*4 iv,il,ih
      integer*4 iist,ianz,j,iart
      integer*4 av,ev,al,el
      integer*4 nv,nl,ihg
      real*8 rav,rev,ral,rel
      integer*4 isoil
      character cdum*100
      intrinsic int
      external getpts
      
      read(iist,'(a100)') cdum
	if (cdum(1:1) .eq. 'B') goto 200
      read(cdum,*) ianz, iart
c
c  iart   = 0    relative Werte    [m]
c  iart   = 1    Punktnummern      [m]
c
      if (ianz .eq. 0) goto 900

      if (iart .eq. 0) then
        do 500 j = 1,ianz
          read(iist,*) rav,rev,ral,rel,isoil
          if ((rav .ge. 1.) .and. (rev .gt. 1.)) then
            av = int(rav)
            ev = int(rev)
          else
            call getpts(av,ev,rav,rev,eta(1,ih),iacnv(ih))
          endif
          if ((ral .ge. 1.) .and. (rel .gt. 1.)) then
            al = int(ral)
            el = int(rel)
          else
            call getpts(al,el,ral,rel,xsi(1,ih),iacnl(ih))
          endif
          do 100 iv = av, ev
            do 110 il = al, el
                iboden(iv,il,ih) = isoil
  110       continue
  100     continue
  500   continue
      elseif (iart .eq. 1) then
        do 501 j = 1,ianz
          read(iist,*) av,ev,al,el,isoil
          do 101 iv = av, ev
            do 111 il = al, el
                iboden(iv,il,ih) = isoil
  111       continue
  101     continue
  501   continue
      endif
      goto 900

200   read (cdum(7:100),*)   nv, nl, ihg
       if (nv .ne. iacnv(ih)) stop 'Falsches nv in Bodenzuweisung'
       if (nl .ne. iacnl(ih)) stop 'Falsches nl in Bodenzuweisung'

      do 102 iv = iacnv(ih),1,-1
          read (iist,*) (iboden(iv,il,ih), il = 1,iacnl(ih))
 102  continue
	  

  900 continue
c      do iv= iacnv(ih),1, -1
c	 write(6,*) (iboden(iv,il,ih), il=1, iacnl(ih)), iv, il
c      end do
c     direkte zuweisung


      open (1000,file='boden.dat')
	write(1000,*) 'HANG', ih
	do iv=iacnv(ih), 1,-1
		 write(1000,'(2000i3)') (iboden(iv,il,ih),il=1, iacnl(ih))
	end do

      return
      end


      subroutine rdmak(iima,ih)
c-----------------------------------------------------------------------
c  Lesen der Makroporenzuweisung eines Hanges (*.mak)
c-----------------------------------------------------------------------
      include 'dim.inc'
      include 'hgfest.inc'
      include 'hgvari.inc'
      include 'soil.inc'
      include 'hgbdry.inc'


      integer*4 iv,il,ih
      integer*4 iima,ianz,j,iart
      integer*4 av,ev,al,el
      real*8 rav,rev,ral,rel
      real*8 vmak, amakh, b_makh
      character*100 cdummy
      intrinsic int
      external getpts

c ... commented jw 2011-11-04 -> done once in CATFLOW.FOR
!      do 10 iv = 1, iacnv(ih)
!        do 11 il = 1, iacnl(ih)
!            macro(iv,il,ih) = 1.
!            amak(iv,il,ih) = 1.
!   11   continue
!   10 continue

      read(iima,'(a100)') cdummy
	if (cdummy(1:1) .eq. 'D') goto 200
	read(cdummy,*) ianz, iart, m_aniso
	read(iima,'(a3)') vimet(ih)
c
c
c  iart   = 0    relative Werte    [m]
c  iart   = 1    Punktnummern      [m]
c
      if (ianz .eq. 0) goto 900

c jw iart necessary? 0: mixing possible; 1: no mixing possible
      if (iart .eq. 0) then                             !
        do 500 j = 1,ianz
          read(iima,*) rav,rev,ral,rel,vmak, amakh, b_makh
          if ((rav .ge. 1.) .and. (rev .gt. 1.)) then
            av = int(rav)
            ev = int(rev)
          else
            call getpts(av,ev,rav,rev,eta(1,ih),iacnv(ih))
          endif
          if ((ral .ge. 1.) .and. (rel .gt. 1.)) then
            al = int(ral)
            el = int(rel)
          else
            call getpts(al,el,ral,rel,xsi(1,ih),iacnl(ih))
          endif
          do 100 iv = av, ev
            do 110 il = al, el
                if( pflpar(2,3,iusenr(il,ih)) .gt. 1. 
     &          .and. vmak .gt. 1.) then    
                    macro(iv,il,ih) = pflpar(2,3,iusenr(il,ih))
                else
                   macro(iv,il,ih) = vmak
                end if
                amak(iv,il,ih) = amakh
                b_mac(iv,il,ih) = b_makh
  110       continue
  100     continue
  500   continue
      elseif (iart .eq. 1) then
        do 501 j = 1,ianz
          read(iima,*) av,ev,al,el,vmak, amakh
          do 101 iv = av, ev
            do 111 il = al, el
                if( pflpar(1,3,iusenr(il,ih)) .gt. 1.) then    
                    macro(iv,il,ih) = pflpar(1,3,iusenr(il,ih))
                else
                   macro(iv,il,ih) = vmak
                end if
                amak(iv,il,ih) = amakh
                b_mac(iv,il,ih) = b_makh
c       jw  amak(iv,il,ih)=1   correct?
                if (amak(iv,il,ih) .le. 1.e-8) amak(iv,il,ih)=1.    ! 
  111       continue
  101     continue
  501   continue
	endif
      goto 201 

c     jw this part is executed when header starts with 'D' (?)
  200 read(cdummy(7:100), *) amakh, b_makh, m_aniso         ! 
	read(iima,'(a3)') vimet(ih)
      do iv = iacnv(ih),1,-1
          read (iima,*) (macro(iv,il,ih), il = 1,iacnl(ih))
          do  il = 1, iacnl(ih)
            amak(iv,il,ih) = amakh
            b_mac(iv,il,ih) = b_makh
	    end do
      end do

c     purpose: counting deepeest macropore position
  201    do 21 il = 1, iacnl(ih)                                !
        do 20 iv = iacnv(ih),1,-1
c           jw always gt 0 ?
           if (macro(iv,il,ih) .gt. 0.) ivm(il,ih) = iv         ! 
   20   continue
   21 continue

  900 continue
      return
      end

      subroutine inicon(iini,ih)
c-----------------------------------------------------------------------
      include 'dim.inc'
      include 'hgfest.inc'
      include 'hgvari.inc'
      include 'hgbdry.inc'
      include 'zeit.inc'
      include 'soil.inc'

      integer*4 iv,il,ih
      integer*4 iini,ianz,j,ischal, iart
      integer*4 av,ev,al,el
      real*8 rav,rev,ral,rel
      real*8 psi_th, th_psi, thproz
      character*80 sdum
      character*5  kenn
      real*8 phi_s, hm, tzeit
      integer*4 ihg, nv, nl
      logical istpsi

      external psi_th, th_psi, hgcopy, getpts
      intrinsic int, abs

      istpsi=.false.

      read (iini,'(a80)') sdum
      read (sdum,'(a5)') kenn
      if (kenn .eq. 'PSI  ') then
        istpsi=.true.
c-------  File-Typ 1 (Vorgabe von PSI an jedem Punkt)
  828 read (sdum(6:80),*) tzeit, ihg, nv, nl
c        if (ihg.ne.hangnr(ih)) then
        if ((ihg.ne.hangnr(ih)).or.(abs(tzeit-t_start).gt.0.001)) then
  829     read (iini,'(a80)',end=9001) sdum
          read (sdum,'(a5)') kenn
          if (kenn .eq. 'PSI  ') goto 828
          goto 829
        endif
c        if (abs(tzeit-t_start) .gt. 0.001)
c     &                      stop 'Falscher Zeitpunkt in INICON'
        if (nv .ne. iacnv(ih)) stop 'Falsche Dimension in INICON'
        if (nl .ne. iacnl(ih)) stop 'Falsche Dimension in INICON'
        do 102 iv = iacnv(ih),1,-1
          read (iini,*) (psi(iv,il), il = 1,iacnl(ih))
          do 103 il = 1,iacnl(ih)
            phiini(iv,il) = hko(iv,il,ih) - psi(iv,il)
            tabpos(iv,il,ih) = iactab(iboden(iv,il,ih))/2
            th_ini(iv,il) =
     &         th_psi(iboden(iv,il,ih),psi(iv,il),tabpos(iv,il,ih))
  103     continue
  102   continue
      elseif (kenn .eq. 'THETA') then
c-------  File-Typ 2 (Vorgabe von THETA an jedem Punkt)
  728   read (sdum(6:80),*) tzeit, ihg, nv, nl
        if ((ihg.ne.hangnr(ih)).or.(abs(tzeit-t_start).gt.0.001)) then
  729     read (iini,'(a80)',end=9001) sdum
          read (sdum,'(a5)') kenn
          if (kenn .eq. 'THETA') goto 728
          goto 729
        endif
        if (abs(tzeit-t_start) .gt. 0.001)
     &                      stop 'Falscher Zeitpunkt in INICON'
        if (ihg .ne. hangnr(ih)) stop 'Falscher Hang in INICON'
        if (nv .ne. iacnv(ih)) stop 'Falsche Dimension in INICON'
        if (nl .ne. iacnl(ih)) stop 'Falsche Dimension in INICON'
        do 107 iv = iacnv(ih),1,-1
          read (iini,*) (th_ini(iv,il), il = 1,iacnl(ih))
          do 106 il = 1,iacnl(ih)
            tabpos(iv,il,ih) = iactab(iboden(iv,il,ih))/2
            psi(iv,il) =
     &         psi_th(iboden(iv,il,ih),th_ini(iv,il),tabpos(iv,il,ih))
            phiini(iv,il) = hko(iv,il,ih) - psi(iv,il)
  106     continue
  107   continue
      elseif (kenn .eq. 'PHI  ') then
c-------  File-Typ 3 (Einheitspotential)
        read (sdum(6:80),*) phi_s, iart
        if (iart .eq. 0) then
c....Eingabe vor Hoehen-Koordinatenverschiebung (vgl. CALGEO)
          hm = hkomin(ih)
        else
c....Eingabe nach Hoehen-Koordinatenverschiebung (vgl. CALGEO)
          hm = 0.
        endif
        do 104 il = 1,iacnl(ih)
          do 105 iv = 1,iacnv(ih)
            psi(iv,il) = hko(iv,il,ih) + hm - phi_s
            phiini(iv,il) = hko(iv,il,ih) - psi(iv,il)
            tabpos(iv,il,ih) = iactab(iboden(iv,il,ih))/2
            th_ini(iv,il) =
     &         th_psi(iboden(iv,il,ih),psi(iv,il),tabpos(iv,il,ih))
  105     continue
  104   continue
      else
c-------  File-Typ 4 (Bloecke)

      read(sdum,*) ianz, ischal, iart
c  ianz            Anzahl von Bloecken
c
c  iart     = 0    relative Werte    [0-1]
c    ischal = 0    Bodenfeuchtewerte [Bruchteil von theta_s]
c    ischal = 1    Saugspannungen    [m]
c
c  iart   = 1      Punktnummern
c    ischal = 0    Bodenfeuchtewerte [Bruchteil von theta_s]
c    ischal = 1    Saugspannungen    [m]
c
      if (iart .eq. 0) then
        do 500 j = 1,ianz
          read(iini,*) rav,rev,ral,rel,thproz
          if ((rav .ge. 1.) .and. (rev .gt. 1.)) then
            av = int(rav)
            ev = int(rev)
          else
            call getpts(av,ev,rav,rev,eta(1,ih),iacnv(ih))
          endif
          if ((ral .ge. 1.) .and. (rel .gt. 1.)) then
            al = int(ral)
            el = int(rel)
          else
            call getpts(al,el,ral,rel,xsi(1,ih),iacnl(ih))
          endif
          if (ischal .eq. 0) then
            do 100 iv = av, ev
              do 110 il = al, el
                th_ini(iv,il) = thproz*s_tab(iactab(iboden(iv,il,ih)),
     &                                               1,iboden(iv,il,ih))
  110         continue
  100       continue
          elseif (ischal .eq. 1) then
            do 120 iv = av, ev
              do 130 il = al, el
                  psi(iv,il) = thproz
  130         continue
  120       continue
          endif
  500   continue
      elseif (iart .eq. 1) then
        do 501 j = 1,ianz
          read(iini,*) av,ev,al,el,thproz
          if (ischal .eq. 0) then
            do 101 iv = av, ev
              do 111 il = al, el
                th_ini(iv,il) = thproz*s_tab(iactab(iboden(iv,il,ih)),
     &                                               1,iboden(iv,il,ih))
  111         continue
  101       continue
          elseif (ischal .eq. 1) then
            do 121 iv = av, ev
              do 131 il = al, el
                  psi(iv,il) = thproz
  131         continue
  121       continue
          endif
  501   continue
      endif

      if (ischal .eq. 0) then
        do 200 iv = 1, iacnv(ih)
          do 210 il = 1, iacnl(ih)
            tabpos(iv,il,ih) = iactab(iboden(iv,il,ih))/2
            psi(iv,il) =
     &          psi_th(iboden(iv,il,ih),th_ini(iv,il),tabpos(iv,il,ih))
            phiini(iv,il) = hko(iv,il,ih) - psi(iv,il)
  210     continue
  200   continue
      elseif (ischal .eq. 1) then
        do 220 iv = 1, iacnv(ih)
          do 230 il = 1, iacnl(ih)
            tabpos(iv,il,ih) = iactab(iboden(iv,il,ih))/2
            th_ini(iv,il) =
     &          th_psi(iboden(iv,il,ih),psi(iv,il),tabpos(iv,il,ih))
            phiini(iv,il) = hko(iv,il,ih) - psi(iv,il)
  230     continue
  220   continue
      endif

      endif
      call hgcopy(th_ini,theta,ih)

c-- Oberflaechenabfluss initialisieren
c      lwrites=.true.  (produziert Anfangszeile in qoben.out)
      lwrites=.false.
      lwriteq=.false.
      lwriten=.false.
      lw11st=.true.
      lw1st(ih)=.true.
      do 300 il = 1, iacnl(ih)
        if (istpsi .and. (psi(iacnv(ih),il) .lt. 0)) then
          yo_alt(il,ih) = -psi(iacnv(ih),il)
        else
          yo_alt(il,ih)=0.
        endif
        q(il,ih)=0.
        neff(il)=0.
        iz_alt(il,ih)=0.
  300 continue
      yo_mit(1,ih)=0.

      goto 900
 9000 continue
      stop 'Fehler in Anfangsbedingungsdatei in INICON'
 9001 continue
      stop 'Falscher Zeitpunkt in INICON'

  900 continue
      return
      end


      subroutine inipart(iinip,ih)
c-----------------------------------------------------------------------
c     reads initial concentration in soil and computes total solute mass 
      include 'dim.inc'
      include 'hgfest.inc'
      include 'hgvari.inc'
      include 'hgbdry.inc'
      include 'zeit.inc'
      include 'soil.inc'
      include 'pvari.inc'
	include 'pfest.inc'
	include 'pbdry.inc'

      integer*4 iv,il,ih, istp, istac, ist
      integer*4 iinip,ianz,j, iart
      integer*4 av,ev,al,el
      integer*4 ihg, nv, nl
      real*8 rav,rev,ral,rel, c_t
      real*8  tzeit         !hm, !jw not used
      character*80 sdum
      character*4  kenn

      external  getpts
      intrinsic int, abs


      read (iinip,'(a80)') sdum
      read (sdum,'(a4)') kenn
c-------  File-Typ 1 (Vorgabe von C an jedem Punkt)
      if (kenn .eq. 'KONZ') then
       read (sdum(6:80),*) tzeit, ihg, nv, nl, istac
	 if (abs(tzeit-t_start) .gt. 0.001)
     &                      stop 'Falscher Zeitpunkt in INICON'
       if (nv .ne. iacnv(ih)-1) stop 'Falsche Dimension in INICON'
       if (nl .ne. iacnl(ih)-1) stop 'Falsche Dimension in INICON'
	 if (istac .lt. istact) stop ' Weniger Anfangszustaende  
     &  als Stoffe definiert'
       do 103 istp=1, istact
	  read(iinip,*) ist      
	 do 102 iv = iacnv(ih)-1,1,-1
          read (iinip,*) (c_tact(istp,iv,il,ih), il = 1,iacnl(ih)-1)
 102   continue
  103  continue  
      else
c-------  File-Typ 2 (Bloecke)
c  ianz            Anzahl von Bloecken
c  iart   = 0      relative Werte    [0-1]
c  iart   = 1      Punktnummern
c

       read(sdum,*) ianz, iart, istac
	 if (istac .lt. istact) stop ' Weniger Anfangszustaende  
     &  als Stoffe definiert'
       if (iart .eq. 0) then
        do 600 istp=1, istact
        read(iinip,*) ist
	  do 500 j = 1,ianz
         read(iinip,*) rav,rev,ral,rel,c_t
         if ((rav .ge. 1.) .and. (rev .gt. 1.)) then
          av = int(rav)
          ev = int(rev)
         else
          call getpts(av,ev,rav,rev,eta(1,ih),iacnv(ih)-1)
         endif
         if ((ral .ge. 1.) .and. (rel .gt. 1.)) then
          al = int(ral)
          el = int(rel)
         else
          call getpts(al,el,ral,rel,xsi(1,ih),iacnl(ih)-1)
         endif
         do 100 iv = av, ev
          do 110 il = al, el
           c_tact(istp,iv,il,ih) = c_t
  110     continue
  100    continue
  500   continue
  600  continue
       elseif (iart .eq. 1) then
        do 601 istp=1,istact
	   do 501 j = 1,ianz
          read(iinip,*) av,ev,al,el,c_t
          do 101 iv = av,ev
           do 111 il = al, el
            c_tact(istp,iv,il,ih) =c_t 
  111      continue
  101     continue
  501    continue
  601   continue       
       endif
      end if
C----- Errechnen der Stoffmasse aus der Anfangskonzentration
      call calmini(ih)

      return
      end

      subroutine calmini(ih)

c----------------------------------------------------------
c	 7.07.1998	Routine zum Errechnen der Masse eines 
c      Stoffes aus der Anfangskonzentration
c-----------------------------------------------------------

      include 'dim.inc'
      include 'hgfest.inc'
      include 'hgbdry.inc'
      include 'hgvari.inc'
      include 'pbdry.inc'
      include 'pfest.inc'
      include 'pvari.inc'
      include 'soil.inc'


      integer*4 il, iv, ih, istp

      do 50 istp= 1, istact
       mp_ini(istp,ih)=0.
	 do 51 iv =1, iacnv(ih)-1
        do 52 il = 1, iacnl(ih)-1
         mpkon(istp,iv,il)= (c_tact(istp,iv,il,ih)/1000.)*
     &   (bodpar(8,iboden(iv,il,ih))*hgbreit(ih)*flaeche(iv,il,ih))
        mp_ini(istp,ih)=mp_ini(istp,ih)+mpkon(istp,iv,il)  
   52   continue
   51  continue
   50 continue     

      return
      end

      subroutine rdprt(iprt,ih)
c-----------------------------------------------------------------------
      include 'dim.inc'
      include 'zeit.inc'

      integer*4    iprt, i, ih
      real*8     rfak, szprt
      character*80 cdum

      external maxtst, dsds2ds

  101   read (iprt,'(a)') cdum
        if (cdum(1:1).eq.'#') goto 101
        call dsds2ds(dstrs, cdum(1:22), szprt)
        if (szprt .lt. 0.) stop 't_prt unvollstaendig! (RDPRT)'
c ...... Sekunden pro Zeiteinheit
        read (cdum(23:80),*) rfak

      ip(ih) = 1
 1000 continue
c ....... Druckzeitpunkte in Zeiteinheiten
  102   read (iprt,'(a)',end=900) cdum
        if (cdum(1:1).eq.'#') goto 102
        read(cdum,*) t_p(ip(ih),ih), it_p(ip(ih),ih)
        t_p(ip(ih),ih) = t_p(ip(ih),ih) * rfak - szprt
        if (t_p(ip(ih),ih) .le. t_start) goto 1000
        ip(ih) = ip(ih) + 1
      goto 1000
  900 continue
      call maxtst('IP      ',ip(ih),'MAXPRT  ',maxprt,'RDPRT   ')
      do 100 i = ip(ih),maxprt
  100   t_p(i,ih) = 1.e20
      return
      end

      subroutine rdcv(iicv,ih)
c-----------------------------------------------------------------------
c  Lesen der Kontrollvolumenzuweisung eines Hanges (*.cv)
c-----------------------------------------------------------------------
      include 'dim.inc'
      include 'hgfest.inc'
      include 'hgvari.inc'

      integer*4 ih
      integer*4 iicv,ianz,j
      real*8 rav,rev,ral,rel

      external maxtst, getpts
      intrinsic int

      read(iicv,*) ianz
      if (ianz .eq. 0) goto 900
      call maxtst('IACCV   ',ianz-1,'MAXCV   ',maxcv,'RDCV    ')

      iaccv(ih)=ianz+1
      do 500 j = 2,ianz+1
        read(iicv,*) rav,rev,ral,rel
        if ((rav .ge. 1.) .and. (rev .gt. 1.)) then
          icvu(j,ih) = int(rav)
          icvo(j,ih) = int(rev)
        else
          call getpts(icvu(j,ih),icvo(j,ih),rav,rev,eta(1,ih),iacnv(ih))
        endif
        if ((ral .ge. 1.) .and. (rel .gt. 1.)) then
          icvl(j,ih) = int(ral)
          icvr(j,ih) = int(rel)
        else
          call getpts(icvl(j,ih),icvr(j,ih),ral,rel,xsi(1,ih),iacnl(ih))
        endif
        if (icvu(j,ih) .lt. 1) icvu(j,ih)=1
        if (icvo(j,ih) .gt. iacnv(ih)) icvo(j,ih)=iacnv(ih)
        if (icvl(j,ih) .lt. 1) icvl(j,ih)=1
        if (icvr(j,ih) .gt. iacnl(ih)) icvr(j,ih)=iacnl(ih)
  500 continue

  900 continue
      return
      end

      subroutine wrfak(ih)
c-----------------------------------------------------------------------
      include 'dim.inc'
      include 'hgfest.inc'
      include 'hgvari.inc'

      integer*4 iv,il,ih
      real*8 F_sum

      do 100 iv = 1,iacnv(ih)
        do 110 il = 1,iacnl(ih)
          F_sum = Fx_00(iv,il)+ Fe_00(iv,il)+
     &            Fx_p1(iv,il)+ Fe_p1(iv,il)+
     &            Fx_m1(iv,il)+ Fe_m1(iv,il)
          write(io(3),1000) Fx_00(iv,il), Fe_00(iv,il),
     &                      Fx_p1(iv,il), Fe_p1(iv,il),
     &                      Fx_m1(iv,il), Fe_m1(iv,il),
     &                      RS(iv,il), F_sum
  110   continue
  100 continue
 1000 format(6g12.4,g12.4,g12.4)
      return
      end


      subroutine wrres(t_p,it_p,ih)
c-----------------------------------------------------------------------

      include 'dim.inc'
      include 'hgfest.inc'
      include 'hgvari.inc'
      include 'hgbdry.inc'
	include 'pbdry.inc'
	include 'pfest.inc'
	include 'pvari.inc'
	include 'soil.inc'

      integer*4 iv,il,ih, istp
      integer*4 it_p, is, dumax         !iu,  !jw not used
      real*8 t_p, t_star(maxnv,maxnl)

      intrinsic abs, int, real

      dumax=int(real(iacnl(ih))/2.)

c     berechner relative sättigung t_star 
	do iv=iacnv(ih),1,-1
	 do il =1, iacnl(ih)
	 t_star(iv,il)=(theta(iv,il)-bodpar(3,iboden(iv,il,ih)))/
     & (bodpar(2,iboden(iv,il,ih))-bodpar(3,iboden(iv,il,ih)))
       end do
	end do

         if ((io_log(4) .eq. 1) .or. (it_p .eq. 1)) then
           is=1
         write(io(4),504) t_p, -(1000+hangnr(ih)), iacnv(ih), iacnl(ih)
         else
           is=0
         endif

         if ((io_log(5) .eq. 1) .or. (it_p .eq. 1)) then
           is=1
         write(io(5),505) t_p, -(1000+hangnr(ih)), iacnv(ih), iacnl(ih)
         else
           is=0
         endif

         if ((io_log(7) .eq. 1) .or. (it_p .eq. 1)) then
           is=1
           write(io(7),507) t_p, -(1000+hangnr(ih)),iacnv(ih), iacnl(ih)
         else
           is=0
         endif

         if ((io_log(8) .eq. 1) .or. (it_p .eq. 1)) then
           is=1
           write(io(8),508) t_p, -(1000+hangnr(ih)),iacnv(ih),iacnl(ih)
         else
           is=0
         endif

         if ((io_log(9) .eq. 1) .or. (it_p .eq. 1)) then
           is=1
           write(io(9),509) t_p, -(1000+hangnr(ih)),iacnv(ih),iacnl(ih)
         else
           is=0
         endif

         if ((io_log(13) .eq. 1) .or. (it_p .eq. 1)) then
           is=1
           write(io(13),513) t_p, -(1000+hangnr(ih)),iacnv(ih),iacnl(ih)
         else
           is=0
         endif
         if ((io_log(14) .eq. 1) .or. (it_p .eq. 1)) then
           is=1
           write(io(14),514) t_p, -(1000+hangnr(ih)),iacnv(ih),iacnl(ih)
	   else
           is=0
         endif
      
         if ((io_log(15) .eq. 1) .or. (it_p .eq. 1)) then
           is=1
           write(io(15),515) t_p, -(1000+hangnr(ih)),
     &		 iacnv(ih)-1,iacnl(ih)-1, istact
         else
           is=0
         endif

!### Changed by EZ 5.9.2016 skipped output of relative saturation
!         if ((io_log(18) .eq. 1) .or. (it_p .eq. 1)) then
!           is=1
!           write(io(18),514) t_p,-(1000+hangnr(ih)),iacnv(ih),iacnl(ih)
!         else
!           is=0
!         endif

c         if ((io_log(19) .eq. 1) .or. (it_p .eq. 1)) then
c           is=1
c           write(io(19),514) t_p,-(1000+hangnr(ih)),iacnv(ih),iacnl(ih)
c         else
c           is=0
c         endif


      do 101 il = 1,iacnl(ih)
        if (yoben(il) .gt. 0) psi(iacnv(ih),il)= -yoben(il)             
        do 102 iv = 1,iacnv(ih)
          if (abs(q_xsi(iv,il)).lt.1.e-30) q_xsi(iv,il)=0.
          if (abs(q_eta(iv,il)).lt.1.e-30) q_eta(iv,il)=0.
  102   continue
  101 continue
    
       if(istact .gt. 0) then
          if ((io_log(15) .eq. 1)  .or. (it_p .eq. 1)) then
           do 120 istp=1, istact
c          if ((io_log(19) .eq. 1)  .or. (it_p .eq. 1))
c         &     write(io(19),1001) cg_q(istp,ih), sig_cg(istp,ih), 
c         &     skew_cg(istp,ih)
	     write(io(15),*) mp_bil(istp,ih)               
            do 104 iv= iacnv(ih)-1, 1, -1
             write(io(15),3000) (c_tact(istp,iv,il,ih),il=1,iacnl(ih)-1)
  104      continue
  120      continue
          endif
       endif

      do 103 iv = iacnv(ih),1, -1
         if ((io_log(4) .eq. 1)  .or. (it_p .eq. 1))
     &     write(io(4),1000) (theta(iv,il), il = 1,iacnl(ih))
         if ((io_log(5) .eq. 1)  .or. (it_p .eq. 1))
     &     write(io(5),2000) (psi(iv,il), il = 1,iacnl(ih))
         if ((io_log(7) .eq. 1)  .or. (it_p .eq. 1))
     &     write(io(7),3000) (q_xsi(iv,il), il = 1,iacnl(ih))
         if ((io_log(8) .eq. 1)  .or. (it_p .eq. 1))
     &     write(io(8),3000) (q_eta(iv,il), il = 1,iacnl(ih))
         if ((io_log(9) .eq. 1)  .or. (it_p .eq. 1))
     &     write(io(9),3000) (senk(iv,il), il=1,iacnl(ih))
c     &    write(io(9),3000) (senk(iv,il)*area(iv,il,ih), il=1,iacnl(ih))
        if(istact .gt. 0) then
         if ((io_log(13) .eq. 1)  .or. (it_p .eq. 1))
     &     write(io(13),3000) (ve_st(iv,il,ih), il=1,iacnl(ih))
	   if ((io_log(14) .eq. 1)  .or. (it_p .eq. 1))
     &     write(io(14),3000) (vx_st(iv,il,ih), il=1,iacnl(ih))
        endif
 !### Changed by EZ 5.9.2016 skipped output of relative saturation
 !        if ((io_log(18) .eq. 1)  .or. (it_p .eq. 1))
 !    &     write(io(18),1000) (t_star(iv,il), il = 1,iacnl(ih))

  103 continue
 !### Changed by EZ 5.9.2016 skipped output of relative saturation

      if((io_log(18) .eq. 1)  .or. (it_p .eq. 1)) then
          write(io(18),1111) -(1000+hangnr(ih)), t_p,
     &    (Ecanop(il),il = 1,iacnl(ih))
          write(io(18),1111) -(2000+hangnr(ih)), t_p,
     &    (Eintz(il), il = 1,iacnl(ih))
          write(io(18),1111) -(3000+hangnr(ih)), t_p,
     &    (Esoil(il),il = 1,iacnl(ih))
 1111 format(i10 ,1e15.4, 1000e15.4)
        end if

  504 format(f12.1,i6,3i5)
  505 format(f12.1,i6,3i5)
  507 format(f12.1,i6,3i5)
  508 format(f12.1,i6,3i5)
  509 format(f12.1,i6,3i5)
  513 format(f12.1,i6,3i5)
  514 format(f12.1,i6,3i5)
  515 format(f12.1,i6,3i5)
  516 format(3e10.3)
 1000 format(2000f8.3)
 1001 format(3e10.3)
 2000 format(2000e14.3E3)
 3000 format(2000e12.3)

 3020 format(80i5)

      return
      end

      subroutine getpts(al,el,ral,rel,koor,len)
C-----------------------------------------------------------------------
      integer*4 len, i, j
      integer*4 al,el
      real*8  koor(len)
      real*8  ral,rel

      intrinsic abs, max, min

      al=1
      el=len

      do 100 i = len,1,-1
        j=i
        if (ral .gt. (koor(i)-koor(1))/(koor(len)-koor(1))) then
          al = i+1
          goto 101
        endif
  100 continue
  101 continue
      if (abs(ral-(koor(j)-koor(1))/(koor(len)-koor(1))).lt.0.00001)then
        al=max(al-1,1)
      endif

      do 200 i = 1,len
        j=i
        if (rel .lt. (koor(i)-koor(1))/(koor(len)-koor(1))) then
          el = i-1
          goto 202
        endif
  200 continue
  202 continue
      if (abs(rel-(koor(j)-koor(1))/(koor(len)-koor(1))).lt.0.00001)then
        el = min(el+1,len)
      endif

      return
      end
      subroutine statks(iinstat,ih)
c-----------------------------------------------------------------------
c     reads relative values to scale ks 
      include 'dim.inc'
      include 'hgfest.inc'
      include 'hgvari.inc'
      include 'hgbdry.inc'
      include 'zeit.inc'
      include 'soil.inc'
      include 'pvari.inc'
	include 'pfest.inc'
	include 'pbdry.inc'

      integer*4 iv,il,ih
      integer*4 iinstat        !,ianz,j, iart !jw unused
c      integer*4 av,ev,al,el            !jw unused
      integer*4 ihg, nv, nl

      read (iinstat,*)  ihg, nv, nl
       if (nv .ne. iacnv(ih)) stop 'Falsche Dimension in STATKS'
       if (nl .ne. iacnl(ih)) stop 'Falsche Dimension in STATKS'

      do 102 iv = iacnv(ih),1,-1
          read (iinstat,*) (rel_ks(iv,il,ih), il = 1,iacnl(ih))
 102  continue
      return
      end


      subroutine statths(iinstat,ih)
c-----------------------------------------------------------------------
c     reads relative values to scale porosity 
      include 'dim.inc'
      include 'hgfest.inc'
      include 'hgvari.inc'
      include 'hgbdry.inc'
      include 'zeit.inc'
      include 'soil.inc'
      include 'pvari.inc'
	include 'pfest.inc'
	include 'pbdry.inc'

      integer*4 iv,il,ih
      integer*4 iinstat !,ianz,j, iart  ! jw unused
c      integer*4 av,ev,al,el            ! jw unused
      integer*4 ihg, nv, nl

      read (iinstat,*)  ihg, nv, nl
       if (nv .ne. iacnv(ih)) stop 'Falsche Dimension in STATTHS'
       if (nl .ne. iacnl(ih)) stop 'Falsche Dimension in STATTHS'

      do 102 iv = iacnv(ih),1,-1
          read (iinstat,*) (rel_ths(iv,il,ih), il = 1,iacnl(ih))
 102  continue
      return
      end


