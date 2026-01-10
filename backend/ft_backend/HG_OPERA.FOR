      subroutine hgcopy(hg_rd,hg_wr,ih)
c-----------------------------------------------------------------------
c  Hang: Umspeichern von hg_rd auf hg_wr
c  (kann ein beliebiges Feld sein, das auf der Hangdiskretisierung
c  gespeichert ist)
c-----------------------------------------------------------------------
      include 'dim.inc'
      include 'hgfest.inc'

      integer*4 iv,il,ih
      real*8 hg_rd, hg_wr
      dimension  hg_rd(maxnv,maxnl)
      dimension  hg_wr(maxnv,maxnl)

      do 100 iv = 1, iacnv(ih)
        do 110 il = 1, iacnl(ih)
          hg_wr(iv,il) = hg_rd(iv,il)
  110   continue
  100 continue

      return
      end

      subroutine gl_copy(hg_rd,hg_wr,ih)
c-----------------------------------------------------------------------
c  Hang: Umspeichern von hg_rd auf hg_wr
c  (kann ein beliebiges Feld sein, das auf der Hangdiskretisierung
c  gespeichert ist)
c-----------------------------------------------------------------------
      include 'dim.inc'
      include 'hgfest.inc'

      integer*4 iv,il,ih
      real*8 hg_rd, hg_wr
      dimension  hg_rd(maxnv,maxnl,maxnh)
      dimension  hg_wr(maxnv,maxnl,maxnh)

      do 100 iv = 1, iacnv(ih)
        do 110 il = 1, iacnl(ih)
          hg_wr(iv,il,ih) = hg_rd(iv,il,ih)
  110   continue
  100 continue

      return
      end
      subroutine hgadd(hg_sum,d_hg,ih)
c-----------------------------------------------------------------------
c  Hang: Addieren von d_hg auf hg_sum
c  (kann ein beliebiges Feld sein, das auf der Hangdiskretisierung
c  gespeichert ist)
c-----------------------------------------------------------------------
      include 'dim.inc'
      include 'hgfest.inc'

      integer*4 iv,il,ih
      real*8 hg_sum, d_hg
      dimension  hg_sum(maxnv,maxnl)
      dimension  d_hg(maxnv,maxnl)

      do 100 iv = 1, iacnv(ih)
        do 110 il = 1, iacnl(ih)
          hg_sum(iv,il) = hg_sum(iv,il) + d_hg(iv,il)
  110   continue
  100 continue

      return
      end

      subroutine hgnull(hang,ih)
c-----------------------------------------------------------------------
c  Hang: Nullsetzen eines REAL*8 Feldes
c-----------------------------------------------------------------------
      include 'dim.inc'
      include 'hgfest.inc'

      integer*4 iv,il,ih
      real*8 hang
      dimension  hang(maxnv,maxnl)

      do 100 iv = 1, iacnv(ih)
        do 110 il = 1, iacnl(ih)
          hang(iv,il) = 0.
  110   continue
  100 continue

      return
      end

      subroutine hgnuli(hang,ih)
c-----------------------------------------------------------------------
c  Hang: Nullsetzen eines integer*4 Feldes
c-----------------------------------------------------------------------
      include 'dim.inc'
      include 'hgfest.inc'

      integer*4 iv,il,ih
      integer*4 hang
      dimension  hang(maxnv,maxnl)

      do 100 iv = 1, iacnv(ih)
        do 110 il = 1, iacnl(ih)
          hang(iv,il) = 0
  110   continue
  100 continue

      return
      end

      subroutine obcopy(hg_rd,hg_wr,ih)
c-----------------------------------------------------------------------
c  Hang: Umspeichern von hg_rd auf hg_wr
c  (kann ein beliebiges Feld sein, das auf der Hangdiskretisierung
c  gespeichert ist)
c-----------------------------------------------------------------------
      include 'dim.inc'
      include 'hgfest.inc'

      integer*4 il,ih
      real*8 hg_rd, hg_wr
      dimension  hg_rd(maxnl)
      dimension  hg_wr(maxnl)

      do 110 il = 1, iacnl(ih)
        hg_wr(il) = hg_rd(il)
  110 continue

      return
      end
