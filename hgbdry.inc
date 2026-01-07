c-----------------------------------------------------------------------
c  HGBDRY.INC      boundary conditions 
c-----------------------------------------------------------------------
      integer*4    irbtyp, isktyp, ktyp, iackld
      integer*4    irb_u, irb_o, irb_r, irb_l, isnk
      integer*4    vorz_u, vorz_o, vorz_r, vorz_l, vorz_s
      integer*4    vsav_u, vsav_o, vsav_r, vsav_l, vsav_s
      integer*4    hor
      integer*4    ifixob, ivroot
      integer*4    iacuse, iacpft, iacwrf, iacfix, iacpfp, iachor
      integer*4    iusenr, luseid
      integer*4    iacnie, iackli, iacsnk, iacrbf, rBilart

      real*8       rbpar, skpar, klima, klimas, zref, nied
      real*8       qu_pot, qo_pot, qr_pot, ql_pot, qs_pot
      real*8       pu_pot, po_pot, pr_pot, pl_pot, ps_pot
      real*8       wrf, wru, wro, bezfak
      real*8       neff, interz, iz_alt
      real*8       Esoil, Eintz, Ecanop, plrw
      real*8       t_ln, pflpar
      real*8       zrbf, z2srbf, szrbf
      real*8       zsnk, z2ssnk, szsnk
      real*8       zkli, z2skli, szkli
      real*8       znie, z2snie, sznie, niefak, klifak
      real*8       sw0,sw1,sw2,trueb,truebf, sattgr(maxtyp)

      character*30 lnfile
      character*30 n_fil, k_fil
      character*30 rbfil, snkfil
      character*30 cluse


      logical      lueb_u, lueb_o, lueb_r, lueb_l, lueb_s
      logical      lrintp,lsintp,lnintp,lklima,lnied,etilog
      logical      klfehlt

c  actual type of boundary condition  (mathematical)
      dimension  irbtyp(2,maxrbf)
c  actual type of sink/source boundary condition  (mathematical)
      dimension  isktyp(2,maxsnk)
c  associated actual B-C parameters
      dimension  rbpar(2,maxrbp,maxrbf)
c  associated actual sink/source B-C parameters
      dimension  skpar(2,maxskp,maxsnk)
c  actual climate data interval
      dimension  klima(2,maxkld,maxkli)
c  actual climate data (saved)
      dimension  klimas(maxkld,maxkli)
c  true, if climate data is missing (-999)
      dimension  klfehlt(maxkli)
c  reference height of wind velocity measurement
      dimension  zref(maxkli)
c  type of climatic data (1 or 2)
      dimension  ktyp(maxkli)
c  parameter of regression between rBil and shortwave-Bil (ETINTZ, Kolle-model)
      dimension  sw0(maxkli),sw1(maxkli),sw2(maxkli)
c  parameter for atmosperic dimming (ETINTZ, Kolle-model)
      dimension  trueb(maxkli),truebf(maxkli)
c  actual read number of different climate data per record (time)
      dimension  iackld(maxkli)
c  actual rainfall data interval
      dimension  nied(2,maxnie)
c  boundary condition file index (bottom boundary)
      dimension  irb_u(maxnl,maxnh)
c  boundary condition file index (surface boundary)
      dimension  irb_o(maxnl,maxnh)
c  boundary condition file index (right boundary)
      dimension  irb_r(maxnv,maxnh)
c  boundary condition file index (left boundary)
      dimension  irb_l(maxnv,maxnh)
c  sink/source boundary condition file index (internal boundary)
      dimension  isnk(maxnv,maxnl,maxnh)
c  sign of boundary condition (-1: potential,  1: flux) and saved values
      dimension  vorz_u(maxnl,maxnh)      ,  vsav_u(maxnl)
      dimension  vorz_o(maxnl,maxnh)      ,  vsav_o(maxnl)
      dimension  vorz_r(maxnv,maxnh)      ,  vsav_r(maxnv)
      dimension  vorz_l(maxnv,maxnh)      ,  vsav_l(maxnv)
      dimension  vorz_s(maxnv,maxnl,maxnh),  vsav_s(maxnv,maxnl)
c  true, if boundary flux cannot infiltrate totally (in case of unequality condition)
      dimension  lueb_u(maxnl)
      dimension  lueb_o(maxnl)
      dimension  lueb_r(maxnv)
      dimension  lueb_l(maxnv)
      dimension  lueb_s(maxnv,maxnl)
c  potential fluxes/potentials (in case of unequality condition)
      dimension  qu_pot(maxnl)      ,  pu_pot(maxnl)
      dimension  qo_pot(maxnl)      ,  po_pot(maxnl)
      dimension  qr_pot(maxnv)      ,  pr_pot(maxnv)
      dimension  ql_pot(maxnv)      ,  pl_pot(maxnv)
      dimension  qs_pot(maxnv,maxnl),  ps_pot(maxnv,maxnl)
c  effective (net) rainfall
      dimension  neff(maxnl)
c  share of total plant reachable water within current element (0...1)
      dimension  plrw(maxnv,maxnl)
c  vaporation of interception [m/s]
      dimension  Eintz(maxnl)
c  evaporation [m/s]
      dimension  Esoil(maxnl)
c  transpiration [m/s]
      dimension  Ecanop(maxnl)
c  interception [m] and saved value of state variable
      dimension  interz(maxnl)
      dimension  iz_alt(maxnl,maxnh)
c  boundary condition filenames
      dimension  rbfil(maxrbf), snkfil(maxsnk)
c  true, if interpolation between subsequent boundary condition values is desired
      dimension  lrintp(maxrbf), lsintp(maxsnk)
c  number of vertical element at rooting depth
      dimension  ivroot(maxnl)
c  array of surface indices
      dimension  ifixob(maxnl,maxfix,maxnh)
c  array of wind reduction factors assigned to surface nodes
      dimension  wrf(maxnl,maxwrf,maxnh)
c  array of angle on horizon assigned to surface nodes
      dimension  hor(maxnl,maxhor,maxnh)
c  reference wind factors at climate stations
      dimension  bezfak(maxwrf,maxkli)
c  boundaries of wind direction sectors (lower and upper value, in degree)
      dimension  wru(maxwrf), wro(maxwrf)
c  land-use number of a surface node
      dimension  iusenr(maxnl,maxnh)
c  land-use descriptive string
      dimension  cluse(maxuse)
c  land-use parameter table
      dimension  pflpar(maxpft,maxpfp+1,maxuse)
c  actual length of time series of landuse parameters
      dimension  iacpft(maxuse)
c  IDs of land uses
      dimension  luseid(maxuse)
c  rainfall and climate filenames
      dimension  n_fil(maxnie), k_fil(maxkli)
c  true, if interpolation between subsequent rainfall values is desired
      dimension  lnintp(maxnie)
c  time series of land use assignment files
      dimension  t_ln(2)
c  time series of boundary conditions
c    z___    time since t_start in [s]
c    z2s___  conversion factor file time unit -> seconds
c    sz___   offset between computation time and time in input file
      dimension  zrbf(2,maxrbf)
      dimension  z2srbf(maxrbf), szrbf(maxrbf)
      dimension  zsnk(2,maxsnk)
      dimension  z2ssnk(maxsnk), szsnk(maxsnk)
      dimension  zkli(2,maxkli)
      dimension  z2skli(maxkli), szkli(maxkli), klifak(maxkli)
      dimension  znie(2,maxnie)
      dimension  z2snie(maxnie), sznie(maxnie), niefak(maxnie)
c     way of computing net radiation rBil (1), rBil is computed, (2)rBil =rBilm
      dimension rBilart(maxkli)

c      common /hgbdry/
c     &     irbtyp, isktyp, klfehlt,
c     &     rbpar, skpar, klima, klimas, zref, ktyp, iackld, nied,
c     &     wrf, wru, wro, bezfak, ifixob, ivroot,
c     &     t_ln, lnfile,
c     &     iacuse, iacpft, iacwrf, iacfix, iacpfp,
c     &     iusenr, luseid, cluse, pflpar,
c     &     n_fil, k_fil, iacnie, iackli,
c     &     irb_u, irb_o, irb_r, irb_l, isnk,
c     &     vorz_u, vorz_o, vorz_r, vorz_l, vorz_s,
c     &     vsav_u, vsav_o, vsav_r, vsav_l, vsav_s,
c     &     lueb_u, lueb_o, lueb_r, lueb_l, lueb_s,
c     &     qu_pot, qo_pot, qr_pot, ql_pot, qs_pot,
c     &     pu_pot, po_pot, pr_pot, pl_pot, ps_pot,
c     &     neff, interz, iz_alt, sattgr,
c     &     Esoil, Eintz, Ecanop, plrw,
c     &     rbfil, snkfil, iacrbf, iacsnk,
c     &     lrintp, lsintp, lnintp, lklima, lnied, etilog
c      common /hgrb_t/
c     &      zrbf,  zsnk,  zkli,  znie,
c     &      z2srbf,z2ssnk,z2skli,z2snie,
c     &      szrbf, szsnk, szkli, sznie, niefak, klifak,
c     &      sw0,sw1,sw2,trueb,truebf,hor,iachor
      common /hgrbi/
     &    irbtyp, isktyp, ktyp, iackld,
     &    irb_u, irb_o, irb_r, irb_l, isnk,
     &    vorz_u, vorz_o, vorz_r, vorz_l, vorz_s,
     &    vsav_u, vsav_o, vsav_r, vsav_l, vsav_s,
     &    hor,ifixob, ivroot,rBilart,
     &    iacuse, iacpft, iacwrf, iacfix, iacpfp, iachor,
     &    iusenr, luseid, iacnie, iackli, iacsnk, iacrbf

      common /hgrbr/
     &       rbpar, skpar, klima, klimas, zref, nied,
     &       qu_pot, qo_pot, qr_pot, ql_pot, qs_pot,
     &       pu_pot, po_pot, pr_pot, pl_pot, ps_pot,
     &       wrf, wru, wro, bezfak,
     &       neff, interz, iz_alt,
     &       Esoil, Eintz, Ecanop, plrw,
     &       t_ln, pflpar, zrbf, z2srbf, szrbf,
     &       zsnk, z2ssnk, szsnk, zkli, z2skli, szkli,
     &       znie, z2snie, sznie, niefak, klifak,
     &       sw0,sw1,sw2,trueb,truebf, sattgr
      common /hgrbc/
     & lnfile, n_fil, k_fil, rbfil, snkfil, cluse

      common /hgrbl/
     & lueb_u, lueb_o, lueb_r, lueb_l, lueb_s,
     & lrintp,lsintp,lnintp,lklima,lnied,etilog,
     & klfehlt
