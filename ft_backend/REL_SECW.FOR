      subroutine rel_sec(dr)
      real*8 dr
      character*22 dstre, dstrs
      integer*4 mm, dd, yy
      character*10 zeit
      integer*4 iarray(3)
      integer*4 values(8)

      external dsds2ds

      dstrs='01.01.1980 00:00:00.00'
      dstre='01.01.1980 00:00:00.00'
      
c     gfortran's IDATE takes an array argument
      call idate(iarray)
      dd = iarray(1)
      mm = iarray(2)
      yy = iarray(3) - 2000
      
c     Use date_and_time to get time values
      call date_and_time(time=zeit, values=values)
      
c     values(5) = hour, values(6) = minute, values(7) = second
      write(dstre(12:13), '(i2.2)') values(5)
      write(dstre(15:16), '(i2.2)') values(6)
      write(dstre(18:19), '(i2.2)') values(7)
      
      write(dstre(1:2), '(i2.2)') dd
      write(dstre(4:5), '(i2.2)') mm
      write(dstre(9:10),'(i2.2)') yy

      call dsds2ds(dstre, dstrs, dr)

      return
      end