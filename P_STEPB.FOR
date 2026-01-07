      subroutine p_stepb(istp,dt,ih)

c----------------------------------------------------------------------
c  Routinte zur Berechnung des Teilchenstep
c     iplos, zeigt ob Teilchen in der Domaene ist 1, oder nicht 0
c     nur bei iplos=1 wird die schleife gerechnet, bei verlust wird iplos =0 gesetzt
c     Anzahl der Teichlen die pro zeitschritt über rechten, linken, und unteren Rand verschwinden
c     nplosu, nplosl, nplosr, wird übergeben in bilanzfile
c----------------------------------------------------------------------

      include 'dim.inc'
      include 'hgfest.inc'
      include 'hgbdry.inc'
      include 'hgvari.inc'
      include 'pbdry.inc'
      include 'pfest.inc'
      include 'pvari.inc'

      real*8 spvir, hpvir, vxipa, veipa ,dt, ran1, ran2
	  real*8 zxsi, zeta, yh, xh, vzx, vze, rs_z, rh_z
      integer*4 ih, istp, npt, ihstep, ivstep
      dimension spvir(maxstt, npmax), hpvir(maxstt,npmax)
       
      intrinsic abs, int, sign, sqrt
      external v_intb, ran1, ran2


c      write(6,*)'npact, istact',npact(1,ih), istact, ih
      xh=1.
      zxsi=0.
      zeta=0.

!      do 55 istp = 1, istact	!Schleife über Teilchenarten in HG.FOR Z. 176
	nplosl(istp,ih)=0
	nplosu(istp,ih)=0
	nplosr(istp,ih)=0
      mlos_l(istp,ih)=0.       
      mlos_u(istp,ih)=0.       
      mlos_r(istp,ih)=0.       

	do 65 npt = 1, npact(istp,ih)
      if (iplos(istp,npt,ih) .eq. 1) then                           ! i1
		! Teilchenschleife läuft nur wenn iplos =1, teilchen in der domaine
c-----Interpoliere v'alt auf Teilchenort vxipo, veipo --------------------

         call v_intb(iealt(istp,npt,ih),ixalt(istp,npt,ih),
     &   vx_sta, ve_sta,istp,npt,ih)

c---- Virtueller Schritt auf Zwischenposition --------------------------
c         1.7= sqrt (3) als Faktor um Zufallszahlen mit
c         Varianz 1 zu nutzen (var = 1/3 U^2, u ist Breite des Intervalls
c------------------------------------------------------------------------
         yh= 0.5 - ran1(iseed)
         vzx =sign(xh,yh)
         rs_z= ran2(iseed)
         zxsi= vzx * rs_z*1.7
         yh = 0.5 -ran1(iseed)
         vze = sign(xh,yh)
         rh_z = ran2(iseed)
         zeta = vze * rh_z*1.7
         spvir(istp,npt) = skpalt(istp,npt,ih) + vxipo*dt
     &    /r_ret(istp,iealt(istp,npt,ih),ixalt(istp,npt,ih))
     &  + zeta*sqrt(6.*d_koef(istp,iboden(iealt(istp,npt,ih),
     &   ixalt(istp,npt,ih),ih)) *dt)
         hpvir(istp,npt) = hkpalt(istp,npt,ih) + veipo*dt
     &    /r_ret(istp,iealt(istp,npt,ih),ixalt(istp,npt,ih))
     &   + zeta*sqrt(6.* d_koef(istp,iboden(iealt(istp,npt,ih),
     &   ixalt(istp,npt,ih),ih))*dt)

c---- Linker Rand: Teilchenverlust bei entsprechender Randbedingung

        if(spvir(istp,npt) .lt. sko(iealt(istp,npt,ih),1,ih)) then   !i2
c    	 write(6,*)'spvir < 0'

c--------Nullfluss, Teilchenreflektion
          if (irb_l(ieact(istp,npt,ih),ih) .eq. 0) then
             ixact(istp,npt,ih)= 1
             spvir(istp,npt) = sko(iealt(istp,npt,ih),1,ih)
     &        +abs(sko(iealt(istp,npt,ih),1,ih)-spvir(istp,npt))
c---------- Sonst Teilchenverlust
          else
             ixact(istp,npt,ih)= 1
             spvir(istp,npt) = sko(iealt(istp,npt,ih),1,ih)
          end if

c---- rechter Rand: Teilchenverlust bei entsprechender Randbedingung
        else if(spvir(istp,npt) .gt. sko(iealt(istp,npt,ih),         !e2
     &    iacnl(ih),ih)) then
c            write(6,*)'spvir >1'

c--------Nullfluss, Teilchenreflektion
          if (irb_r(ieact(istp,npt,ih),ih) .eq. 0) then
             ixact(istp,npt,ih)= iacnl(ih)-1
             spvir(istp,npt) = sko(iealt(istp,npt,ih),iacnl(ih),ih)
     &     -abs(spvir(istp,npt) -sko(iealt(istp,npt,ih),iacnl(ih),ih))
c---------- Sonst Teilchenverlust
          else
             ixact(istp,npt,ih)= iacnl(ih)-1
             spvir(istp,npt) = sko(iealt(istp,npt,ih),iacnl(ih),ih)
          end if
        else if (spvir(istp,npt) > sko(iealt(istp,npt,ih)            !e2
     &    ,ixalt(istp,npt,ih),ih)) then
c		 Bestimmung der Spaltennummer jw 2007-12-06
		 do 131 ihstep= ixalt(istp,npt,ih),iacnl(ih)
		   if(spvir(istp,npt) < sko(ieact(istp,npt,ih),ihstep,ih))
     &		    then
				ixact(istp,npt,ih)=ihstep-1
				exit  
		   else if (ihstep == iacnl(ih)) then
c Teilchen bleibt am rechten Rand
				ixact(istp,npt,ih)=ihstep
				exit
		   end if         
131		continue
c           if(ixact(istp,npt,ih) .gt. iacnl(ih)-1)
c     &       ixact(istp,npt,ih) = iacnl(ih)-1
c       nötig???
c						???endif
	  else if (spvir(istp,npt) < sko(iealt(istp,npt,ih),           !e2
     &    ixalt(istp,npt,ih),ih)) then
c        Bestimme Spaltennummer jw 2007-12-06
		 do 132 ihstep= ixalt(istp,npt,ih),1,-1
		   if(spvir(istp,npt) > sko(ieact(istp,npt,ih),ihstep,ih))
     &		   then
				ixact(istp,npt,ih)=ihstep
				exit
		   end if         
132		 continue

		end if                                                          !ei2

c        write(6,*)'oberer und unterer'
c----- Oberer Rand: kein Teilchenverlust ist erlaubt

        if(hpvir(istp,npt) .gt. hko(iacnv(ih),ixalt(istp,npt,ih),ih)) 
     &   then                                                        !i3
           ieact(istp,npt,ih)= iacnv(ih)
           hpvir(istp,npt)= hko(iacnv(ih),ixalt(istp,npt,ih),ih)
c           write(6,*)'hpvir > 0'

c---- unterer Rand: Teilchenverlust bei entsprechender Randbedingung

        else if(hpvir(istp,npt) .lt. hko(1,ixalt(istp,npt,ih),ih))   !e3
     &   then
c           write(6,*)'hpvir < -1'
c--------Nullfluss, Teilchenreflektion
          if (irb_u(ixact(istp,npt,ih),ih) .eq. 0) then
             ieact(istp,npt,ih)= 1
             hpvir(istp,npt) = hko(1,ixalt(istp,npt,ih),ih)
c---------- Sonst Teilchenverlust
          else
             ieact(istp,npt,ih)= 1
             hpvir(istp,npt) = hko(1,ixalt(istp,npt,ih),ih)
          end if
        else if(hpvir(istp,npt) .gt. hko(iealt(istp,npt,ih),ixalt    !e3
     &    (istp,npt,ih),ih)) then
c        Bestimme Differenz der Indizes jw 2007-12-06
		 do 108 ivstep= iealt(istp,npt,ih),iacnv(ih),1
			if(hpvir(istp,npt) .lt. hko(ivstep,ixact(istp,npt,ih),ih))  
     &			 then
				ieact(istp,npt,ih)=ivstep
				exit
			end if         
108	   continue   
 
           if (ieact(istp,npt,ih) .gt. iacnv(ih))
     &      ieact(istp,npt,ih)=iacnv(ih)
	  
        else if (hpvir(istp,npt) .lt. hko(iealt(istp,npt,ih),        !e3
     &    ixalt(istp,npt,ih),ih)) then
c        Bestimme Differenz der Indizes jw 2007-12-06
          do 109 ivstep= iealt(istp,npt,ih),1,-1
			if(hpvir(istp,npt) .gt. hko(ivstep,ixact(istp,npt,ih),ih))
     &			 then
				ieact(istp,npt,ih)=ivstep +1
				exit
			else if (ivstep == 1) then
				ieact(istp,npt,ih)=ivstep				
				exit
			end if         
109	   continue 
        end if                                                      !ei3

         vxipa=vxipo
         veipa=veipo

c-----Interpoliere v'act linear auf Teilchenorte----------------------

         call v_intb(ieact(istp,npt,ih),ixact(istp,npt,ih),
     &    vx_st, ve_st,istp,npt,ih)

c-----Teilchenstep nach Runge Kutta

         skpact(istp,npt,ih) = skpalt(istp,npt,ih) + 0.5* (
     &    vxipo/r_ret(istp,ieact(istp,npt,ih),ixact(istp,npt,ih))+
     &     vxipa/r_ret(istp,iealt(istp,npt,ih),ixalt(istp,npt,ih)))*dt
     &    +zxsi*sqrt(6.*d_koef(istp,iboden(ieact(istp,npt,ih),
     &     ixact(istp,npt,ih),ih)) * dt)
         
         hkpact(istp,npt,ih) = hkpalt(istp,npt,ih) + 0.5* (
     &    veipo/r_ret(istp,ieact(istp,npt,ih),ixact(istp,npt,ih))+
     &     veipa/r_ret(istp,iealt(istp,npt,ih),ixalt(istp,npt,ih)))*dt
     &    +zeta*sqrt(6.* d_koef(istp,iboden(ieact(istp,npt,ih),
     &     ixact(istp,npt,ih),ih)) * dt)


c---- Linker Rand: Teilchenverlust bei entsprechender Randbedingung !i4
                                                                        
        if(skpact(istp,npt,ih) .lt. sko(iealt(istp,npt,ih),1,ih)) then  

c--------Nullfluss, Teilchenreflektion
          if (irb_l(ieact(istp,npt,ih),ih) .eq. 0) then
             ixact(istp,npt,ih)= 1
             skpact(istp,npt,ih) = sko(iealt(istp,npt,ih),1,ih)
     &        +abs(sko(iealt(istp,npt,ih),1,ih)-skpact(istp,npt,ih))
c---------- Sonst Teilchenverlust
          else
             ixact(istp,npt,ih)= 1
            skpact(istp,npt,ih) = sko(iealt(istp,npt,ih),1,ih)
            nplosl(istp,ih)=nplosl(istp,ih)+1
            mlos_l(istp,ih)=mlos_l(istp,ih)+mpact(istp,npt,ih)
             iplos(istp,npt,ih)=0
          end if

c---- rechter Rand: Teilchenverlust bei entsprechender Randbedingung

        else if(skpact(istp,npt,ih) .gt. sko(iealt(istp,npt,ih),     !e4
     &    iacnl(ih),ih)) then

c--------Nullfluss, Teilchenreflektion
           if (irb_r(ieact(istp,npt,ih),ih) .eq. 0) then
             ixact(istp,npt,ih)= iacnl(ih)-1
             skpact(istp,npt,ih) = sko(iealt(istp,npt,ih),iacnl(ih),ih)
     &        -abs(skpact(istp,npt,ih) 
     &          -sko(iealt(istp,npt,ih),iacnl(ih),ih))
c---------- Sonst Teilchenverlust
           else
             ixact(istp,npt,ih)= iacnl(ih)-1
             skpact(istp,npt,ih) = sko(iealt(istp,npt,ih),iacnl(ih),ih)
             nplosr(istp,ih)=nplosr(istp,ih)+1
             mlos_r(istp,ih)=mlos_r(istp,ih)+mpact(istp,npt,ih)
             iplos(istp,npt,ih)=0
           end if
	  else if(skpact(istp,npt,ih) > sko(iealt(istp,npt,ih),             !e4
     &    ixalt(istp,npt,ih),ih)) then
		  do ihstep= ixalt(istp,npt,ih)+1,iacnl(ih),1
		   if(skpact(istp,npt,ih) < sko(ieact(istp,npt,ih),ihstep,
     &		   ih))
     &		   then
				ixact(istp,npt,ih)=ihstep-1
				exit
		   else if (ihstep == iacnl(ih)) then
				ixact(istp,npt,ih)=ihstep
				exit 
		   end if         
c121		continue
		  end do
		   
          if(ixact(istp,npt,ih) .gt. iacnl(ih)-1)
     &         ixact(istp,npt,ih) = iacnl(ih)-1

	  else if (skpact(istp,npt,ih) < sko(iealt(istp,npt,ih),            !e4
     &    ixalt(istp,npt,ih),ih)) then
c        Bestimme Differenz der Indizes jw 2006-12-06
		  do 122 ihstep= ixalt(istp,npt,ih)-1,1,-1
			if(skpact(istp,npt,ih) > sko(ieact(istp,npt,ih),ihstep,
     &			ih))
     &		    then
			  ixact(istp,npt,ih)=ihstep
			  exit 
			end if         
122		  continue
        end if                                                      !ei4

c----- Oberer Rand: kein Teilchenverlust ist erlaubt

        if(hkpact(istp,npt,ih) .gt. hko(iacnv(ih),ixalt(istp,npt,ih),   
     &    ih)) then                                                  !i5
           ieact(istp,npt,ih)= iacnv(ih)
           hkpact(istp,npt,ih)= hko(iacnv(ih),ixalt(istp,npt,ih),ih)

c---- unterer Rand: Teilchenverlust bei entsprechender Randbedingung

        else if(hkpact(istp,npt,ih) .lt. hko(1,ixalt(istp,npt,ih),ih))  
     &    then                                                       !e5

c----------Nullfluss, Teilchenreflektion
            if (irb_u(ixact(istp,npt,ih),ih) .eq. 0) then
             ieact(istp,npt,ih)= 1
             hkpact(istp,npt,ih) = hko(1,ixalt(istp,npt,ih),ih)
c---------- Sonst Teilchenverlust
            else
             ieact(istp,npt,ih)= 1
             hkpact(istp,npt,ih) = hko(1,ixalt(istp,npt,ih),ih)
             nplosu(istp,ih)=nplosu(istp,ih)+1
             mlos_u(istp,ih)=mlos_u(istp,ih)+mpact(istp,npt,ih)
             iplos(istp,npt,ih)=0
            end if
	  else if(hkpact(istp,npt,ih) .gt. hko(iealt(istp,npt,ih),         !e5
     &    ixalt(istp,npt,ih),ih)) then
c        Bestimme Differenz der Indizes
		   do 112 ivstep= iealt(istp,npt,ih)+1,iacnv(ih),1
			if(hkpact(istp,npt,ih) .lt. hko(ivstep,ixact(istp,npt,ih) 
     &			,ih) ) then
				ieact(istp,npt,ih)=ivstep
				exit 
			end if         
112		   continue
   
           if(ieact(istp,npt,ih) .gt. iacnv(ih)) ieact(istp,npt,ih)
     &      =iacnv(ih)
	  else if (hkpact(istp,npt,ih) .le. hko(iealt(istp,npt,ih),       !e5
     &      ixalt(istp,npt,ih),ih)) then
		   do 113 ivstep= iealt(istp,npt,ih)-1,1,-1		
c		    Bestimme Differenz der Indizes jw 2007-12-06
c			sobald hkpact grösser als die linke obere Ecke wird,
c			ist man einen Schritt zu weit gegangen-> ivstep +1
			if(hkpact(istp,npt,ih) > hko(ivstep,ixact(istp,npt,ih),ih)  
     &			  ) then
				ieact(istp,npt,ih)=ivstep +1
				exit
			else if (ivstep == 1) then
c			bei Element 1 bleibts 1
				ieact(istp,npt,ih)=ivstep
				exit
			end if         
113		   continue   
	  end if                                                           !ei5

c       aktualisiere alte Teilchen position
         iealt(istp,npt,ih)=ieact(istp,npt,ih)
         ixalt(istp,npt,ih)=ixact(istp,npt,ih)
         skpalt(istp,npt,ih)=skpact(istp,npt,ih)
         hkpalt(istp,npt,ih)=hkpact(istp,npt,ih)

      end if    !if block 1, teilchenschritt/ teilchen in Domaene -  ei1
  65  continue ! ende schleife Teilchenzahl
!       if (nplosu(istp,ih) .gt. 0) write(6,*) 'mlos_u=',mlos_u(istp,ih) 
!       if (nplosr(istp,ih) .gt. 0) write(6,*) 'mlos_r=',mlos_r(istp,ih) 
!       if (nplosl(istp,ih) .gt. 0) write(6,*) 'mlos_l=',mlos_l(istp,ih) 
     
!  55  continue  ! ende unterschiedliche Teilchentypen

	return
      end

c--------
c	jw 12.12.07		Auskommentierte Teile (alter Elementschritt) rausgenommen
c
c
