      subroutine stpbil(ih,dt)
c-----------------------------------------------------------------------
c     Einzelschrittbilanz
c     einbau Massenverluste nplos * mpact, bm_l(ih), bm_r, bm_u
c-----------------------------------------------------------------------
      include 'dim.inc'
      include 'soil.inc'
      include 'hgfest.inc'
      include 'hgvari.inc'
      include 'hgbdry.inc'
	include 'pvari.inc'

      integer*4 iv,il,ih,icv
      real*8  dt, qq, bb
      real*8  locfak

      external mtheta
      intrinsic abs

      call mtheta(ih)

      vueb_l = 0.
      vueb_r = 0.
      vueb_u = 0.
      vueb_o = 0.
      do 501 iv = 1,iacnv(ih)
        il=1
        vueb_l = vueb_l + ueb_l(iv)*dr_l(iv,ih)*varbr(il,ih)
        il=iacnl(ih)
        vueb_r = vueb_r + ueb_r(iv)*dr_r(iv,ih)*varbr(il,ih)
  501 continue
      do 601 il = 1,iacnl(ih)
        iv=1
        vueb_u = vueb_u + ueb_u(il)*dr_u(il,ih)*varbr(il,ih)
        iv=iacnv(ih)
        vueb_o = vueb_o + ueb_o(il)*dr_o(il,ih)*varbr(il,ih)
  601 continue
      
c	vueb_l = vueb_l*dt/vola(1,ih)
c      vueb_r = vueb_r*dt/vola(1,ih)
c      vueb_u = vueb_u*dt/vola(1,ih)
c      vueb_o = vueb_o*dt/vola(1,ih)
	vueb_l = vueb_l*dt
      vueb_r = vueb_r*dt
      vueb_u = vueb_u*dt
      vueb_o = vueb_o*dt

      do 100 icv=1,iaccv(ih)
      vrfl_l(icv) = 0.
      vrfl_r(icv) = 0.
      vrfl_u(icv) = 0.
      vrfl_o(icv) = 0.
      vsenk(icv)  = 0.
      vsueb(icv)  = 0.
      vnied(icv)  = 0.
	vnied2(icv) =0.
      vintz(icv)  = 0.
      vevapo(icv) = 0.
      vtrans(icv) = 0.
      do 500 iv = icvu(icv,ih),icvo(icv,ih)
        il=icvl(icv,ih)
        if (il .eq. 1) then
          qq=q_xsi(iv,il)
          bb=varbr(il,ih)
        else
          qq=(q_xsi(iv,il)+q_xsi(iv,il-1))/2.
          bb=(varbr(il,ih)+varbr(il-1,ih))/2.
        endif
        vrfl_l(icv) = vrfl_l(icv) + qq*dreta(iv,il,ih)*bb

        il=icvr(icv,ih)
        if (il .eq. iacnl(ih)) then
          qq=q_xsi(iv,il)
          bb=varbr(il,ih)
        else
          qq=(q_xsi(iv,il)+q_xsi(iv,il+1))/2.
          bb=(varbr(il,ih)+varbr(il+1,ih))/2.
        endif
        vrfl_r(icv) = vrfl_r(icv) + qq*dreta(iv,il,ih)*bb
  500 continue
      do 600 il = icvl(icv,ih),icvr(icv,ih)
        iv=icvu(icv,ih)
        if (iv .eq. 1) then
          qq=q_eta(iv,il)
          bb=varbr(il,ih)
        else
          qq=(q_eta(iv,il)+q_eta(iv-1,il))/2.
          bb=varbr(il,ih)
        endif
        vrfl_u(icv) = vrfl_u(icv) + qq*drxsi(iv,il,ih)*bb

        iv=icvo(icv,ih)
        if (iv .eq. iacnv(ih)) then
          qq=q_eta(iv,il)
          bb=varbr(il,ih)
        else
          qq=(q_eta(iv,il)+q_eta(iv+1,il))/2.
          bb=varbr(il,ih)
        endif
        vrfl_o(icv) = vrfl_o(icv) + qq*drxsi(iv,il,ih)*bb
        locfak=dr_o(il,ih)*varbr(il,ih)*slopeo(il,ih) 
c	  write(6,*) ifixob(il,2,ih),il
	  vnied(icv)  = vnied(icv)  + nied(1,ifixob(il,2,ih))*locfak
        if (slopeo(il,ih) .gt. 0.) then
        vnied2(icv) =vnied2(icv) + nied(1,ifixob(il,2,ih))*locfak
c     &  /slopeo(il,ih)                                              ! jw commented 2011-11-07 - correct to divide by slopeo? ; vnied2 used for prec in mm
	  else
          vnied2(icv) =vnied2(icv) + nied(1,ifixob(il,2,ih))*locfak
	  end if

c !c jw lokfak hier korrekt -> Ecanop in mm?? Ecanop <-> senk; Rückkopplung beim UMschalten?
	  vintz(icv)  = vintz(icv)  + Eintz(il)*locfak            
        vevapo(icv) = vevapo(icv) + Esoil(il)*locfak              
	  vtrans(icv) = vtrans(icv) + Ecanop(il)*locfak             
c      write(6,*)'vnied', vnied2(icv), vnied(icv)                
  600 continue

      do 700 iv = icvu(icv,ih),icvo(icv,ih)
        do 710 il = icvl(icv,ih),icvr(icv,ih)
          if (isnk(iv,il,ih) .ne. 0) then
c           if(senk(iv,il) .lt. 0.) write(6,*) senk(iv,il), il, iv
            vsenk(icv) = vsenk(icv) + senk(iv,il)
     &                       *area(iv,il,ih)*varbr(il,ih)       
            vsueb(icv) = vsueb(icv) + sueb(iv,il)
     &                       *area(iv,il,ih)*varbr(il,ih)
          endif
  710   continue
  700 continue

c... Wassermenge ueber Rand in [cbm]
      vrfl_l(icv) = vrfl_l(icv)*dt
      vrfl_r(icv) = vrfl_r(icv)*dt
      vrfl_u(icv) = vrfl_u(icv)*dt
      vrfl_o(icv) = vrfl_o(icv)*dt
      vsenk(icv) = vsenk(icv)*dt
      vsueb(icv) = vsueb(icv)*dt
      vnied(icv)  = vnied(icv)*dt
	vnied2(icv) =vnied2(icv)*dt
      vintz(icv)  = vintz(icv)*dt
      vevapo(icv) = vevapo(icv)*dt
      vtrans(icv) = vtrans(icv)*dt
c      write(6,*)'vnied*dt', vnied2(icv), dt, vnied(icv)

      volrd(icv)  = vrfl_u(icv) +vrfl_l(icv) -vrfl_o(icv) -vrfl_r(icv)
      volin(icv)  = (th_mit(icv,2,ih)-th_mit(icv,1,ih))*vola(icv,ih)


c.. Schrittbilanz: Auffeuchtung - Randfluss ins Hangvolumen + Senkenfluss
      if (abs(volrd(icv)-vsenk(icv)) .lt. 1.e-8) then
        bilanz(icv) = 0.
      else
        bilanz(icv) = (volin(icv) - volrd(icv) + vsenk(icv))
      endif
 100  continue
c     Abflussmenge am rechten Rand cv=1, vorerst über den ganzen Rand
       qssum(ih)=qssum(ih)+vrfl_r(1)               
c      write(6,*)'qssum bilanzfile', qssum(ih)
      return
      end

      subroutine totbil(ih,istact)
c-----------------------------------------------------------------------
c     Gesamtbilanz bis zur momentanen Berechnungszeit
c-----------------------------------------------------------------------
      include 'dim.inc'
      include 'hgfest.inc'
      include 'hgvari.inc'
	include 'pvari.inc'

      integer*4 ih,icv,istp, istact

c....Totalbilanz: Auffeuchtung - Randfluss ins Hangvolumen + Senkenfluss
c                    bilin     -      bilrd                +   bsenk
      do 100 icv=1,iaccv(ih)
        bilin(icv,ih)  = bilin(icv,ih) + volin(icv)
        bilrd(icv,ih)  = bilrd(icv,ih) + volrd(icv)
        bsenk(icv,ih)  = bsenk(icv,ih) + vsenk(icv)
        bsueb(icv,ih)  = bsueb(icv,ih) + vsueb(icv)
        biltot(icv,ih) = bilin(icv,ih) - bilrd(icv,ih) + bsenk(icv,ih)
        brfl_u(icv,ih) = brfl_u(icv,ih) + vrfl_u(icv)
        brfl_o(icv,ih) = brfl_o(icv,ih) + vrfl_o(icv)
        brfl_r(icv,ih) = brfl_r(icv,ih) + vrfl_r(icv)
        brfl_l(icv,ih) = brfl_l(icv,ih) + vrfl_l(icv)
        bnied(icv,ih)  = bnied(icv,ih)  + vnied(icv)
	  bnied2(icv,ih) = bnied2(icv,ih)  + vnied2(icv)/hgobfl(ih)* 1e3 ! [mm]
        bintz(icv,ih)  = bintz(icv,ih)  + vintz(icv)
        bevapo(icv,ih) = bevapo(icv,ih) + vevapo(icv)
        btrans(icv,ih) = btrans(icv,ih) + vtrans(icv)
c      write(6,*)'bnied', bnied2(icv,ih), bnied(icv,ih)
 100  continue
c     bilanz der Massen die üeber den Rand des Gebiets laufen
	do istp=1, istact
	   bm_l(istp,ih)=bm_l(istp,ih)+mlos_l(istp,ih)  
	   bm_r(istp,ih)=bm_r(istp,ih)+mlos_r(istp,ih)
	   bm_u(istp,ih)=bm_u(istp,ih)+mlos_u(istp,ih)
      end do

        bueb_u(ih) = bueb_u(ih) + vueb_u
        bueb_o(ih) = bueb_o(ih) + vueb_o
        bueb_r(ih) = bueb_r(ih) + vueb_r
        bueb_l(ih) = bueb_l(ih) + vueb_l

      return
      end

      subroutine mtheta(ih)
C-----------------------------------------------------------------------
      include 'dim.inc'
      include 'hgfest.inc'
      include 'hgvari.inc'

      integer*4 iv,il,ih,icv

      do 10 icv = 1,iaccv(ih)
        th_mit(icv,2,ih) = 0.
        do 100 iv = icvu(icv,ih),icvo(icv,ih)
          do 110 il = icvl(icv,ih),icvr(icv,ih)
            th_mit(icv,2,ih) = th_mit(icv,2,ih)
     &            + theta(iv,il)*area(iv,il,ih)*varbr(il,ih)
  110     continue
  100   continue
        th_mit(icv,2,ih) = th_mit(icv,2,ih)/vola(icv,ih)
   10 continue

      yo_mit(2,ih) = 0.
      do 111 il = 1,iacnl(ih)
        yo_mit(2,ih)=yo_mit(2,ih)
     &          + yoben(il)*slopeo(il,ih)*dr_o(il,ih)*varbr(il,ih)
  111 continue
      yo_mit(2,ih) = yo_mit(2,ih)/vola(1,ih)

      return
      end

      subroutine stpdif(ih,rel_ab)
c-----------------------------------------------------------------------
c     Einzelschrittaenderungen
c-----------------------------------------------------------------------
      include 'dim.inc'
c      include 'soil.inc'
      include 'hgfest.inc'
      include 'hgvari.inc'

      integer*4 iv,il,ih
      real*8  delta1, delta2
      real*8  d_Th_max, d_Phi_max
      real*8  rel1ab, rel2ab
      real*8  rel_ab

      intrinsic abs, min

      do 400 iv = 1,iacnv(ih)
        do 410 il = 1,iacnl(ih)
          if (th_max(ih) .lt. theta(iv,il)) th_max(ih)=theta(iv,il)
          if (th_min(ih) .gt. theta(iv,il)) th_min(ih)=theta(iv,il)
          if (psi_max(ih) .lt. psi(iv,il)) psi_max(ih)=psi(iv,il)
          if (psi_min(ih) .gt. psi(iv,il)) psi_min(ih)=psi(iv,il)
          if (phi_max(ih) .lt. phineu(iv,il)) phi_max(ih)=phineu(iv,il)
          if (phi_min(ih) .gt. phineu(iv,il)) phi_min(ih)=phineu(iv,il)
  410   continue
  400 continue

      d_Th_max  =   0.
      d_Phi_max =   0.
c.. Ermittlung des Aenderungsbetrags nur an den inneren Punkten
      do 100 iv = 2,iacnv(ih)-1
        do 110 il = 2,iacnl(ih)-1
c      do 100 iv = 1,iacnv(ih)
c        do 110 il = 1,iacnl(ih)
          delta1 = abs(theta(iv,il)-th_alt(iv,il))
            if (delta1 .gt. d_Th_max) d_Th_max=delta1
c.. Berechnung des Aenderungsbetrags fuer phi nur wenn gesaettigt
          if (phineu(iv,il) .lt. 0.) then
            delta2 = abs((phineu(iv,il)-phialt(iv,il,ih))*wasska(iv,il))
            if (delta2 .gt. d_Phi_max) d_Phi_max=delta2
          endif
  110   continue
  100 continue

c .. jw - why large block below commented?

c      do 200 iv = 1,iacnv(ih)
c        il=1
c        if (vorz_l(iv,ih) .gt. 0) then
c          delta1 = abs(theta(iv,il)-th_alt(iv,il))
c            if (delta1 .gt. d_Th_max) d_Th_max=delta1
c          if (abs(theta(iv,il)-
c     &      s_tab(iactab(iboden(iv,il,ih)),1,iboden(iv,il,ih)))
c     &      .lt.0.001) then
c            delta2 = abs(phineu(iv,il)-phialt(iv,il,ih))
c              if (delta2 .gt. d_Phi_max) d_Phi_max=delta2
c          endif
c        endif
c        il=iacnl(ih)
c        if (vorz_r(iv,ih) .gt. 0) then
c          delta1 = abs(theta(iv,il)-th_alt(iv,il))
c            if (delta1 .gt. d_Th_max) d_Th_max=delta1
c          if (abs(theta(iv,il)-
c     &      s_tab(iactab(iboden(iv,il,ih)),1,iboden(iv,il,ih)))
c     &      .lt.0.001) then
c            delta2 = abs(phineu(iv,il)-phialt(iv,il,ih))
c              if (delta2 .gt. d_Phi_max) d_Phi_max=delta2
c          endif
c        endif
c  200 continue
c      do 300 il = 1,iacnl(ih)
c        iv=1
c        if (vorz_u(il,ih) .gt. 0) then
c          delta1 = abs(theta(iv,il)-th_alt(iv,il))
c            if (delta1 .gt. d_Th_max) d_Th_max=delta1
c          if (abs(theta(iv,il)-
c     &      s_tab(iactab(iboden(iv,il,ih)),1,iboden(iv,il,ih)))
c     &      .lt.0.001) then
c            delta2 = abs(phineu(iv,il)-phialt(iv,il,ih))
c              if (delta2 .gt. d_Phi_max) d_Phi_max=delta2
c          endif
c        endif
c        iv=iacnv(ih)
c        if (vorz_o(il,ih) .gt. 0) then
c          delta1 = abs(theta(iv,il)-th_alt(iv,il))
c            if (delta1 .gt. d_Th_max) d_Th_max=delta1
c          if (abs(theta(iv,il)-
c     &      s_tab(iactab(iboden(iv,il,ih)),1,iboden(iv,il,ih)))
c     &      .lt.0.001) then
c            delta2 = abs(phineu(iv,il)-phialt(iv,il,ih))
c              if (delta2 .gt. d_Phi_max) d_Phi_max=delta2
c          endif
c        endif
c  300 continue

      if (d_Th_max .lt. 0.0001) then
        rel1ab = 999.99
      else
        rel1ab = d_Th_opt/d_Th_max
      endif
      if (d_Phi_max .lt. 0.0001) then
        rel2ab = 999.99
      else
        rel2ab = d_Phi_opt/d_Phi_max
      endif
      rel_ab = min(rel1ab,rel2ab)

      return
      end

      subroutine cal_q(ih)
C-----------------------------------------------------------------------
C
C-----------------------------------------------------------------------
      include 'dim.inc'
      include 'hgbdry.inc'
      include 'hgfest.inc'
      include 'hgvari.inc'

      integer*4 iv,il,ih
      real*8 fluss

      intrinsic sqrt

      do 100 il = 2,iacnl(ih)-1
        do 200 iv = 2,iacnv(ih)-1
         q_xsi(iv,il) = - (
     &      A_x(iv  ,il  )*(phineu(iv  ,il+1)-phineu(iv  ,il  )) +
     &      A_x(iv  ,il-1)*(phineu(iv  ,il  )-phineu(iv  ,il-1)) +
     &      A2e(iv  ,il  )*(phineu(iv+1,il  )-phineu(iv  ,il  )) +
     &      A2e(iv-1,il  )*(phineu(iv  ,il  )-phineu(iv-1,il  ))   )
     &      /f_eta(iv,il,ih)/4.
         q_eta(iv,il) = - (
     &      A2x(iv  ,il  )*(phineu(iv  ,il+1)-phineu(iv  ,il  )) +
     &      A2x(iv  ,il-1)*(phineu(iv  ,il  )-phineu(iv  ,il-1)) +
     &      A_e(iv  ,il  )*(phineu(iv+1,il  )-phineu(iv  ,il  )) +
     &      A_e(iv-1,il  )*(phineu(iv  ,il  )-phineu(iv-1,il  ))   )
     &      /f_xsi(iv,il,ih)/4.
 
  200   continue
  100 continue
      do 300 il = 2,iacnl(ih)-1
        iv=1
        q_xsi(iv,il) = - (
     &     A_x(iv  ,il  )*(phineu(iv  ,il+1)-phineu(iv  ,il  )) +
     &     A_x(iv  ,il-1)*(phineu(iv  ,il  )-phineu(iv  ,il-1))    )
     &      /f_eta(iv,il,ih)/4.
        q_eta(iv,il) = rfl_u(il)
        iv=iacnv(ih)
        q_xsi(iv,il) = - (
     &     A_x(iv  ,il  )*(phineu(iv  ,il+1)-phineu(iv  ,il  )) +
     &     A_x(iv  ,il-1)*(phineu(iv  ,il  )-phineu(iv  ,il-1))    )
     &      /f_eta(iv,il,ih)/4.
        q_eta(iv,il) = rfl_o(il)
  300 continue
      do 400 iv = 2,iacnv(ih)-1
        il=1
        q_eta(iv,il) = - (
     &     A_e(iv  ,il  )*(phineu(iv+1,il  )-phineu(iv  ,il  )) +
     &     A_e(iv-1,il  )*(phineu(iv  ,il  )-phineu(iv-1,il  ))    )
     &      /f_xsi(iv,il,ih)/4.
        q_xsi(iv,il) = rfl_l(iv)
        il=iacnl(ih)
        q_eta(iv,il) = - (
     &     A_e(iv  ,il  )*(phineu(iv+1,il  )-phineu(iv  ,il  )) +
     &     A_e(iv-1,il  )*(phineu(iv  ,il  )-phineu(iv-1,il  ))    )
     &      /f_xsi(iv,il,ih)/4.
        q_xsi(iv,il) = rfl_r(iv)
  400 continue
      il=1
      iv=1
      q_xsi(iv,il) = rfl_l(iv)
      q_eta(iv,il) = rfl_u(il)
      il=iacnl(ih)
      iv=iacnv(ih)
      q_xsi(iv,il) = rfl_r(iv)
      q_eta(iv,il) = rfl_o(il)
      iv=iacnv(ih)
      il=1
      q_eta(iv,il) = rfl_o(il)
      q_xsi(iv,il) = rfl_l(iv)
      iv=1
      il=iacnl(ih)
      q_eta(iv,il) = rfl_u(il)
      q_xsi(iv,il) = rfl_r(iv)

      do 150 il = 1,iacnl(ih)
        do 250 iv = 1,iacnv(ih)
          fluss=sqrt(q_xsi(iv,il)*q_xsi(iv,il)
     &              +q_eta(iv,il)*q_eta(iv,il))
          if (fl_max(ih) .lt. fluss) fl_max(ih)=fluss
c          fluss=senk(iv,il)*area(iv,il,ih)
          fluss=senk(iv,il)
          if (sk_max(ih) .lt. fluss) sk_max(ih)=fluss
  250   continue
  150 continue

      return
      end
