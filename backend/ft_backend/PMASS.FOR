      subroutine pmass(istp,t_a,ih)

c----------------------------------------------------------------------
c  Teilchenabbau 1. Ordnung, 
c----------------------------------------------------------------------

      include 'dim.inc'
      include 'hgfest.inc'
      include 'hgbdry.inc'
      include 'hgvari.inc'
      include 'pbdry.inc'
      include 'pfest.inc'
      include 'pvari.inc'

      integer*4 ih, istp    !, il, im ! jw unused
      integer*4 npt
      real*8  t_a

      intrinsic exp

c      do 55 istp =1, istact
c geaendert am 5.10.00    do 56 im= 1, iacmif
         do 60 npt = 1, npact(istp,ih)
         if (ieact(istp,npt,ih) .le. 0) then
c  	 JAN hier erfolgt ausgabe bei abbruch 	   
		   write(6,*) ieact(istp,npt,ih), iealt(istp,npt,ih)
	       write(6,*) 'ERROR ieact < 0'
		   stop
         else if (ixact(istp,npt,ih) .gt. iacnl(ih)) then
  	  	   write(6,*) ieact(istp,npt,ih), iealt(istp,npt,ih),
     &	   ixact(istp,npt,ih), ixalt(istp,npt,ih), npt
	       write(6,*) 'bla2'
	       stop
	   end if
          mpact(istp,npt,ih) = m_pt(istp,ih)*exp(-abbau(istp,
     &     iboden(ieact(istp,npt,ih),ixact(istp,npt,ih),ih))*t_a)
c          mpact(istp,npt,ih) = m_pt(istp,im)*exp(-abbau(istp,
c     &     iboden(ieact(istp,npt,ih),ixact(istp,npt,ih),ih))*t_a)
c          write(6,*)mpact(istp,npt,ih), t_a
  60     continue
c  56     continue
c  55  continue
      return
      end
