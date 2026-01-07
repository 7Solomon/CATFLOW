c-----------------------------------------------------------------------
c  Lesen der naechsten Randbedingung von Datei i
c-----------------------------------------------------------------------
      subroutine rdzrbf(i)

      include 'dim.inc'
      include 'hgbdry.inc'
      include 'pbdry.inc'
      include 'pfest.inc'

      integer*4 i,k, j
      character*80 cdum
      integer*4 idum
      real*8 rdum

      intrinsic abs

      do 1000 k=1,2
  100   read(iirbf(i),'(a)',end=900) cdum
        if (cdum(1:1).eq.'#') goto 100
        read(cdum,*) zrbf(k,i), irbtyp(k,i)
	  zrbf(k,i) = zrbf(k,i)*z2srbf(i)-szrbf(i)
        if (irbtyp(k,i) .eq. -1) then
         read(cdum,*) rdum, idum, (rbpar(k,j,i),j=1,1)
        end if
        if (abs(irbtyp(k,i)) .eq. 1) then
c               bei flussrand gibt es einen RB-Wert mehr als Stofftypen
          read(cdum,*) rdum, idum, (rbpar(k,j,i),j=1,istact+1)  
          do 101 j=1, istact                                        
            c_inj(k,j,i)=rbpar(k,j+1,i)
            write(6,*)'c_inj=',c_inj(k,j,i)
  101     continue
        elseif (irbtyp(k,i) .eq. -2) then
          read(cdum,*) rdum, idum, (rbpar(k,j,i),j=1,1)
        elseif (irbtyp(k,i) .eq. 5) then
          read(cdum,*) rdum, idum, (rbpar(k,j,i),j=1,2)
        elseif (abs(irbtyp(k,i)) .eq. 11) then
          read(cdum,*) rdum, idum, (rbpar(k,j,i),j=1,istact+2)
          do 55 j =1, istact
            c_inj(k,j,i)= rbpar(k,j+2,i)
   55     continue
        elseif (irbtyp(k,i) .eq. 0) then
          do 102 j=1, istact
            c_inj(k,j,i)=0.
 102      continue
          do 103 j =1, maxstt+1
             rbpar(k,j,i) = 0.
 103      continue
		elseif (irbtyp(k,i) .eq. 3) then
        elseif (irbtyp(k,i) .eq. -4) then
        elseif (abs(irbtyp(k,i)) .eq. 10) then
        elseif (abs(irbtyp(k,i)) .eq. 99) then
          if (.not.lland) stop 'Landnutzung etc. fehlt (RDZRBF)'
        else
          stop 'Randbedingungstyp existiert nicht (RDZRBF)'
        endif 
 1000 continue
      backspace iirbf(i)

c... Festlegen, ob interpoliert wird
      lrintp(i) = .false.
c... Potential
      if ((irbtyp(1,i) .eq. -1) .or. (irbtyp(1,i) .eq. -2)) then
        if (irbtyp(2,i) .eq. -1) lrintp(i) = .true.
        if (irbtyp(2,i) .eq. -2) lrintp(i) = .true.
      endif
c... Fluss
c      if ((irbtyp(1,i) .eq. 0) .or. (irbtyp(1,i) .eq.  1)) then
c        if (irbtyp(2,i) .eq.  0) lrintp(i) = .true.
c        if (irbtyp(2,i) .eq.  1) lrintp(i) = .true.
c      endif

      goto 999
  900 continue
      stop 'RB-Dateiende in RDZRBF'
  999 continue
      return
      end

