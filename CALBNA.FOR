      subroutine calbna(ih,ibna)
c-----------------------------------------------------------------------
c  Hang: Berechnung und Schreibe BNA (Polygon) Datei
c-----------------------------------------------------------------------
      include 'dim.inc'
      include 'hgfest.inc'

      real*8 sxz, hxz, sez, hez, sz, hz
      dimension  sxz(maxnv,maxnl-1)
      dimension  hxz(maxnv,maxnl-1)
      dimension  sez(maxnv-1,maxnl)
      dimension  hez(maxnv-1,maxnl)
      dimension  sz(maxnv-1,maxnl-1)
      dimension  hz(maxnv-1,maxnl-1)

      integer*4 iv,il,ih
      integer*4 ibna, ilfdnr, inr4, inr6, inr8

      external ggcross

      ilfdnr = 0
      inr4 = 5
      inr6 = 7
      inr8 = 9

      do 120 il = 1,iacnl(ih)-1
        do 125 iv = 1,iacnv(ih)
          sxz(iv,il) = 0.5*(sko(iv,il,ih)+sko(iv,il+1,ih))
          hxz(iv,il) = 0.5*(hko(iv,il,ih)+hko(iv,il+1,ih))
  125   continue
  120 continue
      do 220 iv = 1,iacnv(ih)-1
        do 225 il = 1,iacnl(ih)
          sez(iv,il) = 0.5*(sko(iv,il,ih)+sko(iv+1,il,ih))
          hez(iv,il) = 0.5*(hko(iv,il,ih)+hko(iv+1,il,ih))
  225   continue
  220 continue

      do 230 il = 1,iacnl(ih)-1
        do 240 iv = 1,iacnv(ih)-1
          call ggcross(sxz(iv,il),hxz(iv,il),sxz(iv+1,il),hxz(iv+1,il),
     &                 sez(iv,il),hez(iv,il),sez(iv,il+1),hez(iv,il+1),
     &                 sz(iv,il),hz(iv,il))
  240   continue
  230 continue

      il=1
      iv=1
      ilfdnr = ilfdnr+1
      write(ibna,5000) ilfdnr, inr4, sko(iv,il,ih), hko(iv,il,ih)
      write(ibna,5001) sko(iv,il,ih), hko(iv,il,ih)
      write(ibna,5001) sez(iv,il), hez(iv,il)
      write(ibna,5001) sz(iv,il), hz(iv,il)
      write(ibna,5001) sxz(iv,il), hxz(iv,il)
      write(ibna,5001) sko(iv,il,ih), hko(iv,il,ih)
      do 300 iv = 2,iacnv(ih)-1
        ilfdnr = ilfdnr+1
        write(ibna,5000) ilfdnr, inr6, sko(iv,il,ih), hko(iv,il,ih)
        write(ibna,5001) sko(iv,il,ih), hko(iv,il,ih)
        write(ibna,5001) sez(iv,il), hez(iv,il)
        write(ibna,5001) sz(iv,il), hz(iv,il)
        write(ibna,5001) sxz(iv,il), hxz(iv,il)
        write(ibna,5001) sz(iv-1,il), hz(iv-1,il)
        write(ibna,5001) sez(iv-1,il), hez(iv-1,il)
        write(ibna,5001) sko(iv,il,ih), hko(iv,il,ih)
  300 continue
      iv=iacnv(ih)
      ilfdnr = ilfdnr+1
      write(ibna,5000) ilfdnr, inr4, sko(iv,il,ih), hko(iv,il,ih)
      write(ibna,5001) sko(iv,il,ih), hko(iv,il,ih)
      write(ibna,5001) sxz(iv,il), hxz(iv,il)
      write(ibna,5001) sz(iv-1,il), hz(iv-1,il)
      write(ibna,5001) sez(iv-1,il), hez(iv-1,il)
      write(ibna,5001) sko(iv,il,ih), hko(iv,il,ih)

      do 310 il = 2,iacnl(ih)-1
        iv=1
        ilfdnr = ilfdnr+1
        write(ibna,5000) ilfdnr, inr6, sko(iv,il,ih), hko(iv,il,ih)
        write(ibna,5001) sko(iv,il,ih), hko(iv,il,ih)
        write(ibna,5001) sxz(iv,il-1), hxz(iv,il-1)
        write(ibna,5001) sz(iv,il-1), hz(iv,il-1)
        write(ibna,5001) sez(iv,il), hez(iv,il)
        write(ibna,5001) sz(iv,il), hz(iv,il)
        write(ibna,5001) sxz(iv,il), hxz(iv,il)
        write(ibna,5001) sko(iv,il,ih), hko(iv,il,ih)
        do 320 iv = 2,iacnv(ih)-1
          ilfdnr = ilfdnr+1
          write(ibna,5000) ilfdnr, inr8, sko(iv,il,ih), hko(iv,il,ih)
          write(ibna,5001) sxz(iv,il-1), hxz(iv,il-1)
          write(ibna,5001) sz(iv,il-1), hz(iv,il-1)
          write(ibna,5001) sez(iv,il), hez(iv,il)
          write(ibna,5001) sz(iv,il), hz(iv,il)
          write(ibna,5001) sxz(iv,il), hxz(iv,il)
          write(ibna,5001) sz(iv-1,il), hz(iv-1,il)
          write(ibna,5001) sez(iv-1,il), hez(iv-1,il)
          write(ibna,5001) sz(iv-1,il-1), hz(iv-1,il-1)
          write(ibna,5001) sxz(iv,il-1), hxz(iv,il-1)
  320   continue
        iv=iacnv(ih)
        ilfdnr = ilfdnr+1
        write(ibna,5000) ilfdnr, inr6, sko(iv,il,ih), hko(iv,il,ih)
        write(ibna,5001) sko(iv,il,ih), hko(iv,il,ih)
        write(ibna,5001) sxz(iv,il), hxz(iv,il)
        write(ibna,5001) sz(iv-1,il), hz(iv-1,il)
        write(ibna,5001) sez(iv-1,il), hez(iv-1,il)
        write(ibna,5001) sz(iv-1,il-1), hz(iv-1,il-1)
        write(ibna,5001) sxz(iv,il-1), hxz(iv,il-1)
        write(ibna,5001) sko(iv,il,ih), hko(iv,il,ih)
  310 continue

      il=iacnl(ih)
      iv=1
      ilfdnr = ilfdnr+1
      write(ibna,5000) ilfdnr, inr4, sko(iv,il,ih), hko(iv,il,ih)
      write(ibna,5001) sko(iv,il,ih), hko(iv,il,ih)
      write(ibna,5001) sxz(iv,il-1), hxz(iv,il-1)
      write(ibna,5001) sz(iv,il-1), hz(iv,il-1)
      write(ibna,5001) sez(iv,il), hez(iv,il)
      write(ibna,5001) sko(iv,il,ih), hko(iv,il,ih)
      do 330 iv = 2,iacnv(ih)-1
        ilfdnr = ilfdnr+1
        write(ibna,5000) ilfdnr, inr6, sko(iv,il,ih), hko(iv,il,ih)
        write(ibna,5001) sko(iv,il,ih), hko(iv,il,ih)
        write(ibna,5001) sez(iv-1,il), hez(iv-1,il)
        write(ibna,5001) sz(iv-1,il-1), hz(iv-1,il-1)
        write(ibna,5001) sxz(iv,il-1), hxz(iv,il-1)
        write(ibna,5001) sz(iv,il-1), hz(iv,il-1)
        write(ibna,5001) sez(iv,il), hez(iv,il)
        write(ibna,5001) sko(iv,il,ih), hko(iv,il,ih)
  330 continue
      iv=iacnv(ih)
      ilfdnr = ilfdnr+1
      write(ibna,5000) ilfdnr, inr4, sko(iv,il,ih), hko(iv,il,ih)
      write(ibna,5001) sko(iv,il,ih), hko(iv,il,ih)
      write(ibna,5001) sez(iv-1,il), hez(iv-1,il)
      write(ibna,5001) sz(iv-1,il-1), hz(iv-1,il-1)
      write(ibna,5001) sxz(iv,il-1), hxz(iv,il-1)
      write(ibna,5001) sko(iv,il,ih), hko(iv,il,ih)

 5000 format(2i5,2f12.4)
 5001 format(2f12.4)

      return
      end
