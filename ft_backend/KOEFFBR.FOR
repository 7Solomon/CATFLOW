      subroutine koeffbr()
c-----------------------------------------------------------------------
c     Wasserstände bzw. Abflüsse auf den Randknoten  
c---------------------------------------------------------------------
      include 'dim.inc'
	include 'bach.inc'
	include 'hgfest.inc'

      integer*4  ib
      real*8     Ig
c      real*8 lokgef, cour, kgef, flaech, qbzu, rdum        ! jw all unused here
c      external trapez
 
      Ig = 1.                                               !jw meaning?
	
c	write(6,*)'rbbneu in koeffbr am Anfang', rbbneu
      do 100 ib=1, iacqbr
	  qsour(iqrbb(ib))=bwq(1,irb_b(ib))
 100  continue

      rbbneu = .false.
c	write(6,*)'rbbneu in koeffbr am Schluss', rbbneu
      return
      end
