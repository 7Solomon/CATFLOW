

      subroutine c_ipob(istp,ih)

c----------------------------------------------------------
c	 7.07.1998	Routine zur Interpolation der Teilchenzahlen
c    respektive KOnzentration aufs Gitter
c-----------------------------------------------------------

      include 'dim.inc'
      include 'hgfest.inc'
      include 'hgbdry.inc'
      include 'hgvari.inc'
      include 'pbdry.inc'
      include 'pfest.inc'
      include 'pvari.inc'
      include 'soil.inc'


      real*8 mg_bil
      real*8 m_ofl
      integer*4 il, iv, ih, istp    !, im ! jw unused
      integer*4 np_bil, npt
      dimension mg_bil(maxstt,maxnh)
      dimension np_bil(maxstt,maxnh), m_ofl(maxstt,maxnh)
      intrinsic abs, real
c      external calcgm, cgmciup

c--- Zuordnung der Teilchen zu Knoten----------------------------------

c      write(6,*)'ih',ih
c      do 65, istp =1, istact
         mp_bil(istp,ih)=0.
         mkorrf(istp,ih)=0.
         mg_bil(istp,ih)=0.
         np_bil(istp,ih)=0
      do 66 iv = iacnv(ih)-1, 1, -1
       do 67 il = 1, iacnl(ih)- 1
         npkon(istp,iv,il) = 0
         mpkon(istp,iv,il) = 0.
 67    continue
 66   continue
c  65  continue

       do 47 npt= 1, npact(istp,ih)
c        write(6,*)'ixact,hkpact',ixact(istp,npt,ih),hkpact(istp,npt,ih)
        m_ofl(istp,ih)=real(nposum(istp,ih))*mpact(istp,npt,ih)
       do 45 iv = iacnv(ih)-1, 1,-1
        mp_bil(istp,ih) = 0.
        np_bil(istp,ih) = 0
C ###  uncomment Erwin 13.12.2009 to avoid erroneous corrections of particle mass in case
C      of particle outflow
C       if (npact(istp,ih) .gt. 10) then
C        mkorrf(istp,ih) = real(npmax-nposum(istp,ih))
C     &  /real(npact(istp,ih))
C       end if
        if(ieact(istp,npt,ih) .eq. iv+1) then
c          write(6,*)'ieact=',iv
         do 48 il = 1, iacnl(ih)-1
           if(ixact(istp,npt,ih) .eq. il) then
            npkon(istp,iv,il) = npkon(istp,iv,il) +1
            mpkon(istp,iv,il) = mpkon(istp,iv,il)+mpact(istp,npt,ih) 
     &     *real(iplos(istp,npt,ih))
! assures that inactive particles are not included into the calculation of concentrations
           end if
   48    continue
        end if
   45   continue
   47  continue

      do 51 iv =1, iacnv(ih)-1
       do 52 il = 1, iacnl(ih)-1
        c_pw(istp,iv,il,ih)= (npkon(istp,iv,il)*
     &   m_pt(istp,ih))
     &   /(theta(iv,il)*hgbreit(ih)*flaeche(iv,il,ih))
 
        c_tact(istp,iv,il,ih)= mpkon(istp,iv,il)*1000.
     &  /(bodpar(8,iboden(iv,il,ih))*hgbreit(ih)*flaeche(iv,il,ih))
c        write(6,*)bodpar(8,iboden(iv,il,ih)),hgbreit(ih)
c	  write(6,*) flaeche(iv,il,ih)
        mp_bil(istp,ih)=mp_bil(istp,ih)+mpkon(istp,iv,il)!*
!     &    mkorrf(istp,ih)
        mg_bil(istp,ih)= mg_bil(istp,ih)+c_tact(istp,iv,il,ih)/1000.*
     &   bodpar(8,iboden(iv,il,ih))*flaeche(iv,il,ih)*hgbreit(ih)
        np_bil(istp,ih)=np_bil(istp,ih)+npkon(istp,iv,il)
   52  continue
   51 continue
c       write(6,*) ih,(c_tact(istp,iacnv(ih)-1,il,ih), il=1,iacnl(ih)-1)

c---- Berechnen der Momente der Schwerp.-Verteilung und der Transd.-cdf
c      call cgmciup(istp,ih)

      return
      end

      subroutine calipos(ih)

c----------------------------------------------------------
c	 7.07.1998	Routine zur Errechnung der Teilchenmassen
c      und der Teilchenpositionen anhand der Anfangskonzentration
c-----------------------------------------------------------

      include 'dim.inc'
      include 'hgfest.inc'
      include 'hgbdry.inc'
      include 'hgvari.inc'
      include 'pbdry.inc'
      include 'pfest.inc'
      include 'pvari.inc'
      include 'soil.inc'
      

      integer*4 il, iv, ih, istp, npt
      intrinsic abs, real, int
      real*8   calmp
      external calmp



c ---   Errechnen der Teilchenmassen fuer jeden Hang
      do 100 istp =1, istact
       if(imf(ih) .eq. 0) then
         m_ges(istp,ih)= mp_ini(istp,ih) 
         m_pt(istp,ih) = calmp(m_ges(istp,ih),npmax)
       else if(imf(ih).gt.0) then
	   m_ges(istp,ih)= mp_ini(istp,ih)+mp_inj(istp,imf(ih))
	   m_pt(istp,ih)=calmp(m_ges(istp,ih),npmax)
	 end if  
c	 write(6,*) m_pt(istp,ih),  m_ges(istp,ih)
       do 120 iv = iacnv(ih)-1, 1,-1
        do 130 il =1, iacnl(ih)-1
c	  write(6,*)'il,iv, istp, istact',  il, iv,istp, istact 
         mpkon(istp,iv,il)= (c_tact(istp,iv,il,ih)/1000.)*
     &   (bodpar(8,iboden(iv,il,ih))*hgbreit(ih)*flaeche(iv,il,ih))        
	   npkon(istp,iv,il)= int(mpkon(istp,iv,il)/
     &   m_pt(istp,ih))
         npact(istp,ih)=npact(istp,ih)+npkon(istp,iv,il)
c        write(6,*) 'npact(istp,ih)', npact(istp,ih)
c        write(6,*) 'npalt(istp,ih)', npalt(istp,ih)
c-----  ---- Initialisiere Teilchenposition--------------------
        if(npact(istp,ih) .ge. 1) then
	   do 140 npt = npalt(istp,ih)+1, npact(istp,ih)
c-----  ---- reale Hoehen und Seitenkoordinate ------------------
          hkpact(istp,npt,ih) = hko(iv,il,ih)
          skpact(istp,npt,ih) = 0.5*(sko(iv,il,ih)+sko(iv,il+1,ih))
          skpalt(istp,npt,ih) = skpact(istp,npt,ih)
          hkpalt(istp,npt,ih) = hkpact(istp,npt,ih)
c          write(6,*) 'hkpalt(istp,npt,ih)', hkpalt(istp,npt,ih)
c-----  ---- linker oberer Index der Zelle ----------------------
          ixact(istp,npt,ih) = il
          ixalt(istp,npt,ih) = il
          ieact(istp,npt,ih) = iv
          iealt(istp,npt,ih) = iv
	    npalt(istp,ih)=npact(istp,ih)
  140    continue
        end if
  130   continue
  120  continue 
  100 continue
      if(npact(istp,ih) .gt. npmax) stop ' Zu viele Teilchen in Routine
     & calipos'

      return
      end
