      subroutine kinnen(ih) 
c-----------------------------------------------------------------------
c  Hang: zur DGL Loesung: Koeffizienten an inneren Punkten
c  (in den beiden aeussersten Berechnungspunkten sind die
c   Hauptrichtungen der Anisotropie immer in Richtung der
c   krummlinigen Koordinaten)
c-----------------------------------------------------------------------
      include 'dim.inc'
      include 'hgfest.inc'
      include 'hgvari.inc'

      integer*4 iv,il,ih

c  in XSI-Richtung
      do 120 il = 2,iacnl(ih)-1
        iv=1
          Fx_p1(iv,il) = -  A_x(iv,il)*vorfak(iv,il)/x_p1m1(il-1,ih)
     &                      *fbrup(il,ih)
          Fx_00(iv,il) =   ( A_x(iv,il)*fbrup(il,ih)
     &                      +A_x(iv,il-1)*fbrlow(il,ih))
     &                      *vorfak(iv,il)/x_p1m1(il-1,ih)
          Fx_m1(iv,il) = -  A_x(iv,il-1)*vorfak(iv,il)/x_p1m1(il-1,ih)
     &                      *fbrlow(il,ih)
        do 100 iv = 2,iacnv(ih)-1
          Fx_p1(iv,il) = - vorfak(iv,il)*(
     &                       A_x(iv,il)/x_p1m1(il-1,ih)*fbrup(il,ih)
     &                     + A2x(iv,il)/e_p1m1(iv-1,ih)*fbrup(il,ih)  )
          Fx_00(iv,il) =   vorfak(iv,il)*(
     &                      ( A_x(iv,il)*fbrup(il,ih)
     &                       +A_x(iv,il-1)*fbrlow(il,ih))
     &                       /x_p1m1(il-1,ih)
     &                     +( A2x(iv,il)*fbrup(il,ih)
     &                       +A2x(iv,il-1)*fbrlow(il,ih))
     &                       /e_p1m1(iv-1,ih) )
          Fx_m1(iv,il) = - vorfak(iv,il)*(
     &                       A_x(iv,il-1)/x_p1m1(il-1,ih)*fbrlow(il,ih)
     &                     + A2x(iv,il-1)/e_p1m1(iv-1,ih)*fbrlow(il,ih))
  100   continue
        iv=iacnv(ih)
          Fx_p1(iv,il) = -  A_x(iv,il)*vorfak(iv,il)/x_p1m1(il-1,ih)
     &                      *fbrup(il,ih)
          Fx_00(iv,il) =   ( A_x(iv,il)*fbrup(il,ih)
     &                      +A_x(iv,il-1)*fbrlow(il,ih))
     &                      *vorfak(iv,il)/x_p1m1(il-1,ih)
          Fx_m1(iv,il) = -  A_x(iv,il-1)*vorfak(iv,il)/x_p1m1(il-1,ih)
     &                      *fbrlow(il,ih)
  120 continue

c  in ETA-Richtung
      do 220 iv = 2,iacnv(ih)-1
        il=1
          Fe_p1(iv,il) = -  A_e(iv,il)*vorfak(iv,il)/e_p1m1(iv-1,ih)
          Fe_00(iv,il) =   (A_e(iv,il)+A_e(iv-1,il))*vorfak(iv,il)/
     &                      e_p1m1(iv-1,ih)
          Fe_m1(iv,il) = -  A_e(iv-1,il)*vorfak(iv,il)/e_p1m1(iv-1,ih)
        do 200 il = 2,iacnl(ih)-1
          Fe_p1(iv,il) = - vorfak(iv,il)*(
     &                       A_e(iv,il)/e_p1m1(iv-1,ih)
     &                     + A2e(iv,il)/x_p1m1(il-1,ih)  )
          Fe_00(iv,il) =   vorfak(iv,il)*(
     &                      (A_e(iv,il)+A_e(iv-1,il))/e_p1m1(iv-1,ih)
     &                     +(A2e(iv,il)+A2e(iv-1,il))/x_p1m1(il-1,ih) )
          Fe_m1(iv,il) = - vorfak(iv,il)*(
     &                       A_e(iv-1,il)/e_p1m1(iv-1,ih)
     &                     + A2e(iv-1,il)/x_p1m1(il-1,ih)  )
  200   continue
        il=iacnl(ih)
          Fe_p1(iv,il) = -  A_e(iv,il)*vorfak(iv,il)/e_p1m1(iv-1,ih)
          Fe_00(iv,il) =   (A_e(iv,il)+A_e(iv-1,il))*vorfak(iv,il)/
     &                      e_p1m1(iv-1,ih)
          Fe_m1(iv,il) = -  A_e(iv-1,il)*vorfak(iv,il)/e_p1m1(iv-1,ih)
  220 continue

      return
      end
