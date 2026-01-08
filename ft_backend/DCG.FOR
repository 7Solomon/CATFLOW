      subroutine cg_solv(ih,dPhi,rsq,it_act,cgeps2)
c-----------------------------------------------------------------------
c  Hang: Konjungierte Gradienten Verfahren
c        (using sparse matrix multiplications) originalversion
c-----------------------------------------------------------------------
      include 'dim.inc'
      include 'hgfest.inc'
      include 'hgvari.inc'
      include 'hgbdry.inc'

      integer iv,il,ih
      integer it_act
      real*8  err
      real*8  cgeps2

      real*8 dPhi, dPhivec, RSvec, rsq
      dimension  dPhi(maxnv,maxnl)
      dimension  dPhivec(maxnv*maxnl)
      dimension  RSvec(maxnv*maxnl)
      real*8  sa
      integer ija
      dimension  sa(5*maxnv*maxnl)
      dimension  ija(5*maxnv*maxnl)
      integer nv, nl, imax, i, nmax, j, ij
      integer igl, ia, iiv, iil, k, sumigl, icol
      real*8 Fak
      dimension  igl(maxnv*maxnl)
      dimension  ia(maxnv*maxnl)
      dimension  iiv(maxnv*maxnl)
      dimension  iil(maxnv*maxnl)
      dimension  Fak(4), icol(4)
      logical fstfound

      common /nrmat/ sa, ija

      external linbcg
      intrinsic dble, abs, int, mod

c-----------------------------------------------------------------------
c  Aufbau der Koeffizientenmatrix, der rechten Seite
c-----------------------------------------------------------------------
c  Loesung der Gleichung  LS*Delta = R  nach Delta
c-----------------------------------------------------------------------
      nv=iacnv(ih)
      nl=iacnl(ih)
      imax=nv*nl
      do 100 il = 2,nl-1
        iv=1
        i=(il-1)*nv+iv
        if (vorz_u(il,ih) .lt. 0) then
c          igl(i)=0
          igl(i)=1
          dPhi(iv,il)=pu_pot(il)-phineu(iv,il)
        else
          igl(i)=1
        endif
        iv=nv
        i=(il-1)*nv+iv
        if (vorz_o(il,ih) .lt. 0) then
c          igl(i)=0
          igl(i)=1
          dPhi(iv,il)=po_pot(il)-phineu(iv,il)
        else
          igl(i)=1
        endif
  100 continue
      do 110 iv = 2,nv-1
        il=1
        i=(il-1)*nv+iv
        if (vorz_l(iv,ih) .lt. 0) then
c          igl(i)=0
          igl(i)=1
          dPhi(iv,il)=pl_pot(iv)-phineu(iv,il)
        else
          igl(i)=1
        endif
        il=nl
        i=(il-1)*nv+iv
        if (vorz_r(iv,ih) .lt. 0) then
c          igl(i)=0
          igl(i)=1
          dPhi(iv,il)=pr_pot(iv)-phineu(iv,il)
        else
          igl(i)=1
        endif
  110 continue
      iv=1
      il=1
      i=(il-1)*nv+iv
      if ((vorz_l(iv,ih) .lt. 0) .or. (vorz_u(il,ih) .lt. 0)) then
c        igl(i)=0
          igl(i)=1
        if (vorz_l(iv,ih) .lt. 0) dPhi(iv,il)=pl_pot(iv)-phineu(iv,il)
        if (vorz_u(il,ih) .lt. 0) dPhi(iv,il)=pu_pot(il)-phineu(iv,il)
      else
        igl(i)=1
      endif

      iv=1
      il=nl
      i=(il-1)*nv+iv
      if ((vorz_r(iv,ih) .lt. 0) .or. (vorz_u(il,ih) .lt. 0)) then
c        igl(i)=0
        igl(i)=1
        if (vorz_r(iv,ih) .lt. 0) dPhi(iv,il)=pr_pot(iv)-phineu(iv,il)
        if (vorz_u(il,ih) .lt. 0) dPhi(iv,il)=pu_pot(il)-phineu(iv,il)
      else
        igl(i)=1
      endif

      iv=nv
      il=1
      i=(il-1)*nv+iv
      if ((vorz_l(iv,ih) .lt. 0) .or. (vorz_o(il,ih) .lt. 0)) then
c        igl(i)=0
        igl(i)=1
        if (vorz_l(iv,ih) .lt. 0) dPhi(iv,il)=pl_pot(iv)-phineu(iv,il)
        if (vorz_o(il,ih) .lt. 0) dPhi(iv,il)=po_pot(il)-phineu(iv,il)
      else
        igl(i)=1
      endif

      iv=nv
      il=nl
      i=(il-1)*nv+iv
      if ((vorz_r(iv,ih) .lt. 0) .or. (vorz_o(il,ih) .lt. 0)) then
c        igl(i)=0
        igl(i)=1
        if (vorz_r(iv,ih) .lt. 0) dPhi(iv,il)=pr_pot(iv)-phineu(iv,il)
        if (vorz_o(il,ih) .lt. 0) dPhi(iv,il)=po_pot(il)-phineu(iv,il)
      else
        igl(i)=1
      endif

      do 210 iv = 2,nv-1
        do 200 il = 2,nl-1
          i=(il-1)*nv+iv
          if (vorz_s(iv,il,ih) .lt. 0) then
c           igl(i)=0
            write(io(1),*) iv,il, 'vorzeichenwechsel senken'
		  igl(i)=1
            dPhi(iv,il)=ps_pot(iv,il)-phineu(iv,il)
          else
            igl(i)=1
          endif
  200   continue
  210 continue

c igl: Markierung tatsaechlich verwendeten Gleichungen mit 1, sonst 0
c ia: fortlaufende Nummerierung der tatsaechlich verwendeten Gleichungen
      sumigl=0
      do 300 i=1,imax
        sumigl=sumigl+igl(i)
        ia(i)=sumigl
  300 continue
      nmax=sumigl

C Bau der Sparse Matrix (Numerical Recipes, 2.ed.)
c i: spaltenweise durch die Punkte des rechteckigen Gebiets
      k=nmax+2
      do 400 i=1,imax
        iv=mod(i+nv-1,nv)+1
        il=int((i-1)/nv)+1
        if (igl(i) .eq. 1) then
          fstfound = .false.
          sa(ia(i))=Fe_00(iv,il)+Fx_00(iv,il)-1
          RSvec(ia(i)) = RS(iv,il)
          dPhivec(ia(i)) = dPhi(iv,il)
          iiv(ia(i))=iv
          iil(ia(i))=il
          icol(1)=i-nv
          icol(2)=i-1
          icol(3)=i+1
          icol(4)=i+nv
          Fak(1)=Fx_m1(iv,il)
          Fak(2)=Fe_m1(iv,il)
          Fak(3)=Fe_p1(iv,il)
          Fak(4)=Fx_p1(iv,il)
          do 410 j=1,4
            if ((icol(j) .gt. 0) .and. (icol(j) .le. imax)) then
              ij=igl(icol(j))
              if (ij .eq. 1) then
                sa(k)=Fak(j)
                ija(k)=ia(icol(j))
                if (.not.fstfound) then
                  ija(ia(i))=k
                  fstfound = .true.
                endif
                k=k+1
              else
                iv=mod(ij+nv-1,nv)+1
                il=int((ij-1)/nv)+1
                RSvec(ia(i)) = RSvec(ia(i))-Fak(j)*dPhi(iv,il)
              endif
            endif
  410     continue
        endif
  400 continue
      ija(nmax+1)=k

c aus Numerical Recipes 2. edition
      call linbcg(nmax,RSvec,dPhivec,
     &              3 ,cgeps2, 500 ,it_act,err,ih)
c                 itol, tol  ,itmax,iter  ,err,ih)
c      write(*,*) it_act, err

c-----------------------------------------------------------------------
c  Berechne RSQ und rueckspeichern
c-----------------------------------------------------------------------
      rsq=0.
      do 800 i = 1,nmax
        dPhi(iiv(i),iil(i)) = dPhivec(i)
        if (abs(dPhi(iiv(i),iil(i))*wasska(iiv(i),iil(i))) .gt. rsq)
     &              rsq=abs(dPhi(iiv(i),iil(i))*wasska(iiv(i),iil(i)))
  800 continue

      return
      end


      SUBROUTINE linbcg(n,b,x,itol,tol,itmax,iter,err,ih)    
C-------------------------------------------------------------! jw ih unused----------
      include 'dim.inc'

      INTEGER iter,itmax,itol,n,ih
      DOUBLE PRECISION err,tol,b(*),x(*),EPS
      PARAMETER (EPS=1.d-12)
CU    USES atimes,asolve,snrm
      INTEGER j
      DOUBLE PRECISION ak,akden,bk,bkden,bknum,bnrm,dxnrm,xnrm,zm1nrm
      DOUBLE PRECISION znrm, snrm
      DOUBLE PRECISION p(MAXNV*MAXNL),pp(MAXNV*MAXNL)
      DOUBLE PRECISION r(MAXNV*MAXNL),rr(MAXNV*MAXNL)
      DOUBLE PRECISION z(MAXNV*MAXNL),zz(MAXNV*MAXNL)

      external atimes, asolve, snrm
      intrinsic abs

c .... Berechne erste Schaetzung (16.11.1995, Thomas Maurer)
c      call asolve(n,b,x,0)

      iter=0
      call atimes(n,x,r,0)
      do 11 j=1,n
        r(j)=b(j)-r(j)
        rr(j)=r(j)
11    continue
C     call atimes(n,r,rr,0)
      znrm=1.d0
      if(itol.eq.1) then
        bnrm=snrm(n,b,itol)
      else if (itol.eq.2) then
        call asolve(n,b,z,0)
        bnrm=snrm(n,z,itol)
      else if (itol.eq.3.or.itol.eq.4) then
        call asolve(n,b,z,0)
        bnrm=snrm(n,z,itol)
        call asolve(n,r,z,0)
        znrm=snrm(n,z,itol)
      else
        pause 'illegal itol in linbcg'
      endif
      call asolve(n,r,z,0)
100   if (iter.le.itmax) then
        iter=iter+1
        zm1nrm=znrm
        call asolve(n,rr,zz,1)
        bknum=0.d0
        do 12 j=1,n
          bknum=bknum+z(j)*rr(j)
12      continue
        if(iter.eq.1) then
          do 13 j=1,n
            p(j)=z(j)
            pp(j)=zz(j)
13        continue
        else
          bk=bknum/bkden
          do 14 j=1,n
            p(j)=bk*p(j)+z(j)
            pp(j)=bk*pp(j)+zz(j)
14        continue
        endif
        bkden=bknum
        call atimes(n,p,z,0)
        akden=0.d0
        do 15 j=1,n
          akden=akden+z(j)*pp(j)
15      continue
        ak=bknum/akden
        call atimes(n,pp,zz,1)
        do 16 j=1,n
          x(j)=x(j)+ak*p(j)
          r(j)=r(j)-ak*z(j)
          rr(j)=rr(j)-ak*zz(j)
16      continue
        call asolve(n,r,z,0)
        if(itol.eq.1.or.itol.eq.2)then
          znrm=1.d0
          err=snrm(n,r,itol)/bnrm
        else if(itol.eq.3.or.itol.eq.4)then
          znrm=snrm(n,z,itol)
          if(abs(zm1nrm-znrm).gt.EPS*znrm) then
            dxnrm=abs(ak)*snrm(n,p,itol)
            err=znrm/abs(zm1nrm-znrm)*dxnrm
          else
            err=znrm/bnrm
            goto 100
          endif
          xnrm=snrm(n,x,itol)
          if(err.le.0.5d0*xnrm) then
            err=err/xnrm
          else
            err=znrm/bnrm
            goto 100
          endif
        endif
c        write (*,*) ' iter=',iter,' err=',err
      if(err.gt.tol) goto 100
      endif
      return
      END

      FUNCTION snrm(n,sx,itol)
C-----------------------------------------------------------------------
      INTEGER n,itol,i,isamax
      DOUBLE PRECISION sx(n),snrm

      intrinsic abs, sqrt

      if (itol.le.3)then
        snrm=0.d0
        do 11 i=1,n
          snrm=snrm+sx(i)**2
11      continue
        snrm=sqrt(snrm)
      else
        isamax=1
        do 12 i=1,n
          if(abs(sx(i)).gt.abs(sx(isamax))) isamax=i
12      continue
        snrm=abs(sx(isamax))
      endif
      return
      END

      SUBROUTINE asolve(n,b,x,itrnsp)
C-----------------------------------------------------------------------

      INTEGER n,itrnsp,i                       !itrnsp, ! jw unused
      DOUBLE PRECISION x(n),b(n)

      include 'dim.inc'

      real*8  sa
      integer ija
      dimension  sa(5*maxnv*maxnl)
      dimension  ija(5*maxnv*maxnl)

      common /nrmat/ sa, ija

      do 100 i = 1,n
        x(i)=b(i)/sa(i)
  100 continue

      return
      END


      SUBROUTINE atimes(n,x,r,itrnsp)
C-----------------------------------------------------------------------
      INTEGER n,itrnsp
      DOUBLE PRECISION x(n),r(n)

      include 'dim.inc'

      real*8  sa
      integer ija
      dimension  sa(5*maxnv*maxnl)
      dimension  ija(5*maxnv*maxnl)

      common /nrmat/ sa, ija

      external sprsax, sprstx

      if (itrnsp.eq.0) then
        call sprsax(sa,ija,x,r,n)
      else
        call sprstx(sa,ija,x,r,n)
      endif

      return
      END


      SUBROUTINE sprsax(sa,ija,x,b,n)
      INTEGER n,ija(*)
      DOUBLE PRECISION b(n),sa(*),x(n)
      INTEGER i,k
      if (ija(1).ne.n+2) pause 'mismatched vector and matrix in sprsax'
      do 12 i=1,n
        b(i)=sa(i)*x(i)
        do 11 k=ija(i),ija(i+1)-1
	   if (ija(k).gt. n) then
	     write(6,*) ija(k)
	   end if	  
c	    do j=1,n 
c		 write(io(1),*) 'ija, k, i', l,j, (ija(l),l=ija(j),ija(j+1)-1)
c		 write(io(1),*) 'sa, k', l, (sa(l),l=ija(j),ija(j+1)-1)
c	     write(io(1),*) 'x, i',  (x(ija(l)),l=ija(j),ija(j+1)-1)
c		end do
c	   end if 

          b(i)=b(i)+sa(k)*x(ija(k))
11      continue
12    continue
      return
      END


      SUBROUTINE sprstx(sa,ija,x,b,n)
      INTEGER n,ija(*)
      DOUBLE PRECISION b(n),sa(*),x(n)
      INTEGER i,j,k
      if (ija(1).ne.n+2) pause 'mismatched vector and matrix in sprstx'
      do 11 i=1,n
        b(i)=sa(i)*x(i)
11    continue
      do 13 i=1,n
        do 12 k=ija(i),ija(i+1)-1
          j=ija(k)
          b(j)=b(j)+sa(k)*x(i)
12      continue
13    continue
      return
      END
