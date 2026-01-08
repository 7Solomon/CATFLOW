      subroutine ptkinj2(ih,dt,t_ac)     ! jw dt unused

c----------------------------------------------------------
c    Unterprogramm zur Berechnung der Aktuellen und der
c    potentiellen Teilcheninjektion aus der Infiltration
c    rfl_o und dem Niederschlag qo_pot.
c    Gesamtzahl der pot. und aktuell eingspritzten Teilchen
c    pro Zeitschritt nact_sum, npot_sum
c-----------------------------------------------------------

      include 'dim.inc'
      include 'hgfest.inc'
      include 'hgbdry.inc'
      include 'hgvari.inc'
      include 'pbdry.inc'
      include 'pfest.inc'
      include 'pvari.inc'

      intrinsic int, abs


      integer*4 istp, il
      integer*4 iv, ih, iin2
      integer*4 npt, apint, aacint, nactsum, npotsum
      real*8 dt, rinpot, rinact, t_ac
      dimension nactsum(maxstt), npotsum(maxstt)
c      write(6,*) 'ih2', ih, imf(ih)
c      write(6,*) m_ges(1,ih), imf(ih)
      if(imf(ih) .ge.1) then
       if (t_ac .lt. 10. .and. ih .eq. 1) then
c       write(6,*)'t_injk',t_injk
        t_inj(0)=0.
        t_inj(1)=t_injk
        do 55 iin2=2, 10000
         t_inj(iin2)=t_inj(iin2-1)+t_injk
         iinj=1
         iinj1(ih)=0
c        write(6,*)'t_inj',t_inj(iin2)
 55     continue
       end if
c	  write(6,*)t_inj(249),'hier'
c	  write(6,*)t_inj(250)

       do 110 istp = 1, istact
        nactsum(istp) = 0
        npotsum(istp) = 0
 110   continue

c-----------------------------------------------------------------
c    Injektion am Oberen Rand auf den inneren Knoten iv= iacnv(ih)
c    lokaler update der Teilchenzahl an jedem inneren Knoten alle t_inj

       iv = iacnv(ih)
c	write(6,*) 't_ac', ih,t_ac, t_inj(iinj1(ih)),iinj1(ih) 
       if (t_ac .ge. t_inj(iinj1(ih)))then
        iinj=int(t_ac/t_injk)
c       write(6,*) 'iinj',iinj, iinj1(ih)
	  if (iinj .gt. iinj1(ih)) then
         do 111 il = 1, iacnl(ih)-1
c	    write(6,*) istact
	    do 112 istp = 1, istact
            npalt(istp,ih) = npact(istp,ih)
            rinpot= abs(0.5*(qo_pot(il)+qo_pot(il+1))*hgbreit(ih)*
     &       x_p1m0(il,ih)*f_xsi(iv,il,ih)* cil_o(istp,il,ih)
     &      *(t_inj(iinj)-t_inj(iinj1(ih)))/m_pt(istp,ih))
c            write(6,*)'rinpot ',rinpot
            apint=int(rinpot)
            ninpot(istp,il) = apint
            npotsum(istp) = npotsum(istp) + ninpot(istp,il)
            rinact = abs(0.5*(rfl_o(il)+rfl_o(il+1))*hgbreit(ih)*
     &       x_p1m0(il,ih)*f_xsi(iv,il,ih)* cil_o(istp,il,ih)
     &      *(t_inj(iinj)-t_inj(iinj1(ih)))/m_pt(istp,ih))
	        aacint = int(rinact)
c            write(6,*)'q, ih', rfl_o(il), ih, rinact

c	        write(6,*)'aacint= ', aacint
            ninact(istp,il) = aacint
c            write(6,*)'cil_o, ', cil_o(istp,il,ih),qo_pot(il)
c            write(6,*)'input',rinact, il 
            nactsum(istp) = nactsum(istp) + ninact(istp,il)
            npact(istp,ih) = npalt(istp,ih) + ninact(istp,il)
c            write(6,*)'npact=',npact(istp,ih),'npmax',npmax
            if (npact(istp,ih) .gt. npmax) then
              write(6,*) npact(istp,ih),'>',npmax
              write(6,*)'Inputkonzentration und Inputmasse'
              write(6,*)'des Stoffes',istp,' sind inkonsistent'
              stop ' overflow der Teilchenzahl in ptkinj'
            end if

c-----  ---- Initialisiere Teilchenposition--------------------
            do 113 npt = npalt(istp,ih)+1, npact(istp,ih)
c             write(6,*)'npt, ', npt,npalt(istp,ih), npact(istp,ih)
c-----  ---- reale Hoehen und Seitenkoordinate ------------------
              hkpact(istp,npt,ih) = hko(iv,il,ih)
              skpact(istp,npt,ih) = 0.5*(sko(iv,il,ih)+sko(iv,il+1,ih))
              skpalt(istp,npt,ih) = skpact(istp,npt,ih)
              hkpalt(istp,npt,ih) = hkpact(istp,npt,ih)

c-----  ---- Position im krummlinigen Gitter ---------------------
              xpact(istp,npt,ih) = 0.5*(xsi(il,ih)+xsi(il+1,ih))
              xpalt(istp,npt,ih) = xpact(istp,npt,ih)
              epact(istp,npt,ih) = eta(iv,ih)
              epalt(istp,npt,ih) = epact(istp,npt,ih)
c	      	write(6,*)epact(istp,npt)
c-----  ----- linker oberer Index der Zelle ----------------------
              ixact(istp,npt,ih) = il
              ixalt(istp,npt,ih) = il
              ieact(istp,npt,ih) = iv
              iealt(istp,npt,ih) = iv
c	      write(6,*)ieact(istp,npt,ih)
c  	      write(6,*)'hko_pt=',hko_pt(istp,npt)
  113       continue
  112     continue
  111    continue
c-----  Kumulativer Teilchenverlust durch O-abfluss

         do 114 istp = 1, istact
           np_ofl(istp,ih) = npotsum(istp) - nactsum(istp)
           nposum(istp,ih)= nposum(istp,ih) +np_ofl(istp,ih)
c           write(6,*)'cil_o=',cil_o(istp,10,ih)
c           write(6,*)'Zeit, npact ', t_ac, npact(istp,ih), istp
c           write(6,*)'nposum, vueb_o', nposum(istp,ih), vueb_o,'ih',ih
  114    continue
         iinj1(ih)=iinj+1
c        write(6,*)'iinj1(ih)',iinj1(ih), t_inj(iinj1(ih))
        end if
c      else
c        do 120 istp= 1, istact
c         write(6,*)'npact,typ ',npact(istp,ih), istp
c  120   continue
c         write(6,*)'Zeit',t_ac
       end if
      end if
c      write(6,*) 'npact', npact(1,ih), m_pt(1,ih)
      return
      end
