      subroutine openo(io,filnam,iwrite)
c-----------------------------------------------------------------------
c  Oeffnen einer Ausgabedatei (Ueberschreiben ohne Warnung)
c-----------------------------------------------------------------------

      character filnam*(*)
      integer*4 io, iwrite
      logical*4 ex

      inquire (file=filnam,exist=ex)
      if (ex) then
        open (unit=io,file=filnam,status='old')

	else
        open (unit=io,file=filnam,status='unknown')
      endif
      write(*,2000) filnam, io
      if (iwrite .ne. 0) write(iwrite,2000) filnam, io

      return
 2000 format('  Oeffne Ausgabedatei   ',a,' (Unit:',i3,')')
      end

      subroutine openi(io,filnam,iwrite)
c-----------------------------------------------------------------------
c  Oeffnen einer Eingabedatei (Programmstop bei Nichtvorhandensein)
c  Trim leading/trailing blanks from filnam before inquire/open
c-----------------------------------------------------------------------

      character filnam*(*)
      integer*4 io, iwrite, i, n
      logical*4 ex
      character*256 ftmp

c print trimmed name and length (original)
      write(*,9100) trim(filnam), len_trim(filnam)
 9100 format('DEBUG openi: "',a,'"  len=',i4)

c create left-adjusted, then get true length n
      ftmp = adjustl(filnam)
      n = len_trim(ftmp)
      if (n .le. 0) then
        ftmp = ' '
      endif

c print char codes of trimmed file name (helpful)
      do i = 1, n
        write(*,9200) i, ichar(ftmp(i:i))
 9200   format(' DEBUG char(',i3,') =',i3)
      enddo

      inquire (file=ftmp(1:n),exist=ex)
      if (ex) then
        write(*,2000) ftmp(1:n), io
        if (iwrite .ne. 0) write(iwrite,2000) ftmp(1:n), io
        open (unit=io,file=ftmp(1:n),status='old')
      else
        write(*,1000) ftmp(1:n), io
        if (iwrite .ne. 0) write(iwrite,1000) ftmp(1:n), io
        stop 'Programmabbruch'
      endif

      return
 1000 format('  Eingabedatei   ',a,' (Unit:',i3,') existiert nicht!')
 2000 format('  Oeffne Eingabedatei   ',a,' (Unit:',i3,')')
      end

      SUBROUTINE MAXTST (NNAM,N,MAXNAM,MAX,ROUTINE)

      CHARACTER*8 NNAM, MAXNAM
      CHARACTER*8 ROUTINE
      integer*4 N, MAX

      IF (N .GT. MAX) THEN
        write(*,1000) nnam,n,maxnam,max,routine
 1000   format(/,'Parameter ',a8,' =',i4,' > ',a8,' =',i4,' in ',a8,/)
        STOP 'Parameter in Datei DIM.INC groesser dimensionieren'
      ENDIF
      RETURN
      END
