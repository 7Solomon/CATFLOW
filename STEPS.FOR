      subroutine expstp(ih,dt,abbruch)
C-----------------------------------------------------------------------
C  Hang: expliziter Rechenschritt
C-----------------------------------------------------------------------
      include 'dim.inc'
      include 'hgfest.inc'
      include 'hgvari.inc'

      integer*4 ih, n_chg
      real*8 dt
      logical rbchg, abbruch
      character*80 rblog

      external chko_rb, rand_fl
      external koeff, expcal

      n_chg=0
      rbchg=.false.
      abbruch=.false.

 1000 continue
      call koeff(ih,dt)
      call expcal(ih)

      call rand_fl(ih)
      call chko_rb(ih,rbchg,rblog)
      if (rbchg) then
        n_chg = n_chg+1
c        write(io(1),*) 'RB-Wechsel: ', n_chg, dt
        if (io_log(1) .gt. 0) then
          if (iacnh .gt. 1) write(io(1),'(a)') rblog
        endif
        if (n_chg .ge. 2) then
c         abbruch = .true.
          goto 999
        endif
        goto 1000
      endif

  999 continue
      return
      end

      subroutine bcgstp(ih,dt,n_cg,abbruch)
C-----------------------------------------------------------------------
C  Hang: preconditioned biconjugate gradient method
C-----------------------------------------------------------------------
      include 'dim.inc'
      include 'hgfest.inc'
      include 'hgvari.inc'

      integer*4 ih, il, iv
      integer*4 n_cg, n_chg
      real*8 dt
      real*8 rsq
      real*8 Phi
      logical rbchg, abbruch
      dimension  Phi(maxnv,maxnl)
      character*80 rblog

      external chko_rb, rand_fl
      external koeff, cg_solv, hgcopy, kc_phi, hgnull

      n_chg=0
      rbchg=.false.
      abbruch=.false.

 1000 continue
      call koeff(ih,dt)
      do 100 iv = 1,iacnv(ih)
        do 110 il = 1,iacnl(ih)
          RS(iv,il) =
     &      RS(iv,il)-phialt(iv,il,ih)
  110   continue
  100 continue
      call hgcopy(phineu,Phi,ih)
      call hgnull(phineu,ih)
      call cg_solv(ih,Phi,rsq,n_cg,cgeps/100.)
      call hgcopy(Phi,phineu,ih)

      call rand_fl(ih)
      call chko_rb(ih,rbchg,rblog)
      if (rbchg) then
        n_chg = n_chg+1
c        write(io(1),*) 'RB-Wechsel: ', n_cg, n_chg, dt
        if (io_log(1) .gt. 0) then
          if (iacnh .gt. 1) write(io(1),'(a)') rblog
        endif
        if (n_chg .ge. 2) then
          abbruch = .true.
          goto 999
        endif
        call kc_phi(phialt(1,1,ih),ih)
        call hgcopy(phialt(1,1,ih),phineu,ih)
        goto 1000
      endif

  999 continue
      return
      end

      subroutine adistp(ih,dt,abbruch)
C-----------------------------------------------------------------------
C  Hang: ADI Rechenschritt
C-----------------------------------------------------------------------
      include 'dim.inc'
      include 'hgfest.inc'
      include 'hgvari.inc'

      integer*4 ih, n_chg
      real*8 dt
      real*8 expant, ome, omx
      logical rbchg, abbruch
      character*80 rblog

      external chko_rb, rand_fl
      external koeff, ex_ie, ee_ix, kc_phi, hgcopy

      expant=1.0
      ome=0.0
      omx=0.0

      n_chg=0
      rbchg=.false.
      abbruch=.false.

 1000 continue
c  erster Halbschritt
      call koeff(ih,dt/2.)
      call ex_ie(phineu,ih,expant,ome)

c  Neuberechnung von k,c
      call kc_phi(phineu,ih)

c  zweiter Halbschritt
      call koeff(ih,dt/2.)
      call ee_ix(phineu,ih,expant,omx)

      call rand_fl(ih)
      call chko_rb(ih,rbchg,rblog)
      if (rbchg) then
        n_chg = n_chg+1
c        write(io(1),*) 'RB-Wechsel: ', n_chg, dt
        if (io_log(1) .gt. 0) then
          if (iacnh .gt. 1) write(io(1),'(a)') rblog
        endif
        if (n_chg .ge. 2) then
          abbruch = .true.
          goto 999
        endif
        call kc_phi(phialt(1,1,ih),ih)
        call hgcopy(phialt(1,1,ih),phineu,ih)
        goto 1000
      endif

  999 continue
      return
      end

      subroutine apkstp(ih,dt,abbruch)
C-----------------------------------------------------------------------
C  Hang: ADI Rechenschritt mit Praediktor, Korrektor
C-----------------------------------------------------------------------
      include 'dim.inc'
      include 'hgfest.inc'
      include 'hgvari.inc'

      integer*4 ih, n_chg
      real*8 dt
      real*8 philoc
      dimension philoc(maxnv,maxnl)
      real*8 expant, ome, omx
      logical rbchg, abbruch
      character*80 rblog

      external chko_rb, rand_fl
      external koeff, ex_ie, ee_ix, hgcopy, kc_phi

      expant=1.0
      ome=0.0
      omx=0.0

      n_chg=0
      rbchg=.false.
      abbruch=.false.

 1000 continue
c  Pradiktorschritt
      call hgcopy(phineu,philoc,ih)
      call koeff(ih,dt/4.)
      call ex_ie(phineu,ih,expant,ome)

c  Neuberechnung von k,c (Korrektor)
      call kc_phi(phineu,ih)

c  erster Halbschritt (mit korrigiertem k,c)
      call hgcopy(philoc,phineu,ih)
      call koeff(ih,dt/2.)
      call ex_ie(phineu,ih,expant,ome)

c  Neuberechnung von k,c
      call kc_phi(phineu,ih)

c  Pradiktorschritt
      call hgcopy(phineu,philoc,ih)
      call koeff(ih,dt/4.)
      call ee_ix(phineu,ih,expant,omx)

c  Neuberechnung von k,c (Korrektor)
      call kc_phi(phineu,ih)

c  erster Halbschritt (mit korrigiertem k,c)
      call hgcopy(philoc,phineu,ih)
      call koeff(ih,dt/2.)
      call ee_ix(phineu,ih,expant,omx)

      call rand_fl(ih)
      call chko_rb(ih,rbchg,rblog)
      if (rbchg) then
        n_chg = n_chg+1
c        write(io(1),*) 'RB-Wechsel: ', n_chg, dt
        if (io_log(1) .gt. 0) then
          if (iacnh .gt. 1) write(io(1),'(a)') rblog
        endif
        if (n_chg .ge. 2) then
          abbruch = .true.
          goto 999
        endif
        call kc_phi(phialt(1,1,ih),ih)
        call hgcopy(phialt(1,1,ih),phineu,ih)
        goto 1000
      endif

  999 continue
      return
      end

      subroutine piccg(ih,dt,dt_min,abbruch,n_it,n_cg,rsq)
C-----------------------------------------------------------------------
C  Hang: PICARD Rechenschritt mit Konjungierte Gradienten Verfahren
C-----------------------------------------------------------------------
      include 'dim.inc'
      include 'hgfest.inc'
      include 'hgvari.inc'

      integer*4 ih
      integer*4 n_it, n_cg, it_act, n_chg
      real*8 dt, dt_min
      real*8 dPhi, rsq
      logical rbchg
      logical abbruch
      dimension dPhi(maxnv,maxnl)
      character*80 rblog

      external kc_phi, koeff, hgnull, hgadd, hgcopy
      external pic_it
      external cg_solv
      external chko_rb, rand_fl

      n_it=0
      abbruch=.false.
      n_cg=0
      n_chg=0
      rbchg=.false.

 1000 continue
        call hgnull(dPhi,ih)
        call koeff(ih,dt)
        call pic_it(ih)
        call cg_solv(ih,dPhi,rsq,it_act,cgeps)
        call hgadd(phineu,dPhi,ih)
        call rand_fl(ih)
        call chko_rb(ih,rbchg,rblog)
        n_it = n_it+1
        n_cg = n_cg+it_act
        if (rbchg .and. (dt .gt. dt_min)) then
          n_chg = n_chg+1
c          write(io(1),*) 'RB-Wechsel: ',n_it, n_cg, n_chg, dt
          if (io_log(1) .gt. 0) then
            if (iacnh .gt. 1) write(io(1),'(a)') rblog
          endif
          if (n_chg .ge. 2) then
            abbruch = .true.
            goto 999
          endif
          call kc_phi(phialt(1,1,ih),ih)
          call hgcopy(phialt(1,1,ih),phineu,ih)
          n_it = 0
          goto 1000
        endif
        if (rsq .lt. piceps) goto 999
        if (n_it .ge. it_max) then
          abbruch = .true.
          if (io_log(1) .gt. 0) then
            write(io(1),2000) n_it, it_max, rsq
          endif
          write(*,2000) n_it, it_max, rsq
          goto 999
        endif
        call kc_phi(phineu,ih)
      goto 1000
  999 continue
      return
 2000 format('PICCG: Iterationsanzahl: ',i2,' (',i2,')  RSQ: ',e9.3,
     &' -> starke Zeitschrittreduktion')
      end

      subroutine picadi(ih,dt,abbruch,n_it,rsq)
C-----------------------------------------------------------------------
C  Hang: PICARD Rechenschritt mit ADI-Verfahren
C-----------------------------------------------------------------------
      include 'dim.inc'
      include 'hgfest.inc'
      include 'hgvari.inc'

      integer*4 il, iv, ih
      integer*4 n_it, n_chg
      real*8 dt
      real*8 dPhi,  rsq
      logical rbchg
      logical abbruch
      dimension dPhi(maxnv,maxnl)
      real*8 philoc
      real*8 omx, ome, expant
      dimension philoc(maxnv,maxnl)
      character*80 rblog

      intrinsic abs
      external ex_ie, ee_ix
      external kc_phi, koeff, hgnull, hgadd
      external pic_it, hgcopy
      external chko_rb, rand_fl

      intrinsic dble

      n_it=0
      abbruch=.false.
c  Relaxationsparameter
      omx=0.
      ome=0.
      expant=0.
      n_chg=0

 1000 continue
        call hgnull(dPhi,ih)

c-----------------------------------------------------------
c Fall 1: ohne Update der Koeffizienten nach erstem Halbschritt
c         (konvergiert langsamer, rechnet aber etwas schneller)
c
c        call koeff(ih,dt)
c        call pic_it(ih)
c        call hgcopy(RS,philoc,ih)
c        call ex_ie(dPhi,ih,expant,ome)
c        call hgcopy(philoc,RS,ih)
c        call ee_ix(dPhi,ih,expant,omx)
c
c
c
c
c
c
c
c-----------------------------------------------------------
c Fall 2: mit Update der Koeffizienten nach erstem Halbschritt
c         (konvergiert schneller, rechnet aber langsamer)

        call hgcopy(phineu,philoc,ih)

        call koeff(ih,dt)
        call pic_it(ih)
        call ex_ie(dPhi,ih,expant,ome)
        call hgadd(phineu,dPhi,ih)

        call kc_phi(phineu,ih)
        call koeff(ih,dt)
        call pic_it(ih)
        call ee_ix(dPhi,ih,expant,omx)

        call hgcopy(philoc,phineu,ih)
c-----------------------------------------------------------

        call hgadd(phineu,dPhi,ih)

        rsq=0.
        do 1400 iv = 1,iacnv(ih)
          do 1410 il = 1,iacnl(ih)
            if (abs(dPhi(iv,il)) .gt. rsq) rsq=abs(dPhi(iv,il))
 1410     continue
 1400   continue
        call rand_fl(ih)
        call chko_rb(ih,rbchg,rblog)
        n_it = n_it+1
        if (rbchg) then
          n_chg = n_chg+1
          write(io(3),*) 'RB-Wechsel: ',n_it, n_chg, dt
          if (n_chg .ge. 2) then
            abbruch = .true.
            goto 999
          endif
          call kc_phi(phialt(1,1,ih),ih)
          call hgcopy(phialt(1,1,ih),phineu,ih)
          n_it = 0
          goto 1000
        endif
        if (rsq .lt. piceps) goto 999
        if (n_it .ge. it_max) then
          abbruch = .true.
          if (io_log(1) .gt. 0) then
            write(io(1),2000) n_it, it_max, rsq
          endif
          goto 999
        endif
        call kc_phi(phineu,ih)
      goto 1000
  999 continue
      return
 2000 format('PICADI: Iterationsanzahl: ',i2,' (',i2,')  RSQ:',e10.4)
      end
