c-----------------------------------------------------------------------
c  SOIL.INC           soil properties etc.
c-----------------------------------------------------------------------
c  boundary between arithmetric and geometric averaging for
c  Van Genuchtens n (after Zurmuehl)
      real*8 vg_ngr
      parameter (vg_ngr = 2.)
c  storage coefficient for saturated soil
      real*8 snull
c  soil-albedo-parameter: dry conditions:            balmax
c                         from satkni * saturation:  balmin
      real*8 satkni,balmax,balmin
c  soil resistance parameter (Kolle-model)
      real*8 f_rs,wp_rs,zd_max
c  soil erosion parameter (Schramm-Model, Scherer-Model ?)
      real*8 eross

c  soil hydraulic table
      real*8 s_tab
c  soil parameters
      real*8 bodpar
c  soil anisotropy
      real*8 anisot
c  permanent wilting point [Vol.-%]
      real*8 th_pwp
c  integer*4 for method to convert soil parameters to soil table
      integer*4 imod
c  soil describing string
      character*30 boden
c  name of a input file holding a table of soil hydraulic properties
      character*30 tabfil
c  actual dimensions of soil table: soiltypes, rows, columns
      integer*4 iactyp, iactab, iaceig
      dimension s_tab(maxtab,maxeig,maxtyp)
      dimension bodpar(maxpbm,maxtyp)
      dimension anisot(2,maxtyp)
      dimension imod(maxtyp)
      dimension boden(maxtyp)
      dimension th_pwp(maxtyp)
      dimension snull(maxtyp)
      dimension satkni(maxtyp), balmax(maxtyp), balmin(maxtyp)
      dimension f_rs(maxtyp), wp_rs(maxtyp), zd_max(maxtyp)
      dimension eross(maxero,maxtyp)
      dimension iactab(maxtyp)
      dimension tabfil(maxtyp)

      common /soilr/ s_tab, bodpar, snull, anisot, th_pwp,  
     &       satkni,balmax,balmin,eross,f_rs,wp_rs,zd_max

      common /soili/ iactyp, iactab,iaceig,imod
      common /soill/ boden, tabfil