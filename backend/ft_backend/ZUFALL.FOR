
      double precision function ran1(iseed)
c----------------------------------------------------------------------
c     Tragbare Zufallszahlen Generator aus Numerical
c     Recipies Seite 273
c----------------------------------------------------------------------

      integer*4 im ,ia, iq, ir, ntab, ndiv
      integer*4 iseed
      real*8  am, eps, rnmx
      parameter(im=2147483647,ia=16807, am=1./im, iq=127773, ir=2836,
     &         ntab=32,ndiv=1+(im-1)/ntab,eps=1.2e-7,rnmx=1.-eps)
      intrinsic max, min

      integer*4 j,k,iv(ntab),iy
      save iv, iy
      data iv/ntab*0/, iy/0/

c-----Initialisieren
      if (iseed .le. 0 .or. iy .eq. 0) then
        iseed=max(-iseed,1)

        do 20 j=ntab+8,1, -1
          k=iseed/iq
          iseed=ia*(iseed-k*iq)-k*ir
          if(iseed.lt. 0) iseed=iseed+im
          if(j .le. ntab) iv(j)=iseed
  20     continue
         iy=iv(1)
       end if

       k=iseed/iq
       iseed=ia*(iseed-k*iq)-k*ir
       if(iseed.lt. 0) iseed=iseed+im
       j=1+iy/ndiv
       iy=iv(j)
       iv(j)=iseed
       if(iy .lt. 1) iy=iy+im
       ran1=min(am*iy,rnmx)
       return
       end




      double precision function ran2(iseed)
c----------------------------------------------------------------------
c     Tragbare Zufallszahlen Generator aus Numerical
c     Recipies Seite 273
c----------------------------------------------------------------------

      integer*4 im1, im2, imm1
      integer*4 ia1, ia2, iq1, iq2, ir1, ir2, ntab, ndiv
      integer*4 iseed
      real*8  am, eps, rnmx
      parameter(im1=2147483563, im2= 2147483399, am=1./im1,imm1= im1-1,
     &         ia1=40014, ia2= 40692, iq1=53668, iq2=52774,ir1=12211,
     &         ir2=3791,ntab=32,ndiv=1+imm1/ntab,eps=1.2e-7,rnmx=1.-eps)
      intrinsic max, min
      integer*4 j,k,iv(ntab),iy
      integer*4 iseed2
      save iv, iy, iseed2
      data iseed2/123456789/, iv/ntab*0/, iy/0/

c-----Initialisieren
      if (iseed .le. 0) then
        iseed=max(-iseed,1)
        iseed2=iseed

        do 20 j=ntab+8,1, -1
          k=iseed/iq1
          iseed=ia1*(iseed-k*iq1)-k*ir1
          if(iseed.lt. 0) iseed=iseed+im1
          if(j .le. ntab) iv(j)=iseed
  20     continue
         iy=iv(1)
       end if

       k=iseed/iq1
       iseed=ia1*(iseed-k*iq1)-k*ir1
       if(iseed.lt. 0) iseed=iseed+im1
       k=iseed2/ndiv
       iseed2=ia2*(iseed2-k*iq2)-k*ir2
       if(iseed2.lt. 0) iseed2=iseed2+im2
       j=1+iy/ndiv
       iy=iv(j)-iseed2
       iv(j)=iseed
       if(iy .lt. 1) iy=iy+imm1
       ran2=min(am*iy,rnmx)
       return
       end
