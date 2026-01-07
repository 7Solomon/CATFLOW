c-----------------------------------------------------------------------
c  HGFEST.INC       time independent variables hillslope 
c-----------------------------------------------------------------------
c  rlongi reference longitude of time zone (CET: 15 degree east of Greenwich)
c  longi  longitude of catchment
c  lati   latitude of catchment
      real*8 rlongi, longi, lati
      real*8 varbr, fbrup, fbrlow
      real*8 f_xsi, f_eta, fmf, fdf
      real*8 xsi, eta, x_p1m0, x_p1m1, e_p1m0, e_p1m1
      real*8 xko, yko, hko, sko, xkobez, ykobez, hkobez
      real*8 hgobfl, hgbreit, hglang, lambda
      real*8 macro, depth, area, xyxpy, alla, vola, hkomin, amak
      real*8 slopeo, slopeu, sloper, slopel, gefall, azimut
      real*8 av_fak, al_fak
      real*8 dr_u, dr_o, dr_l, dr_r, drxsi, dreta
      real*8 lrd_u, lrd_o, lrd_l, lrd_r
      real*8 kxx, kee, kxe, w_hohr, w_xshr, w_xsho, w_xshol
      real*8 d_Th_opt, d_Phi_opt
      real*8 kxxf, kxef, keef
      real*8 fcabf(maxnh), fabf(maxnh), flaeche
      real*8 rel_ks, rel_ths, b_mac

      integer*4 iboden, mm_xsi, mm_eta
      integer*4 ivm, igewkn
      integer*4 icvo, icvu, icvl, icvr
      integer*4 hangnr, hgih
      integer*4 ihgr
      integer*4 iacnh
      integer*4 iacnv(maxnh), iacnl(maxnh)
      integer*4 iaccv(maxnh), m_aniso

      logical lmak
	  character*3 vimet(maxnh)


c  metric coefficients (conversion to curvelinear coordinates) xsi-direction
      dimension  f_xsi(maxnv,maxnl,maxnh)
c  metric coefficients (conversion to curvelinear coordinates) eta-direction
      dimension  f_eta(maxnv,maxnl,maxnh)
c  tensor of anisotropy (normed with saturated conductivity k_s)
      dimension  kxx(maxnv,maxnl,maxnh)
      dimension  kee(maxnv,maxnl,maxnh)
      dimension  kxe(maxnv,maxnl,maxnh)
      dimension  kxxf(maxnv,maxnl,maxnh)
      dimension  keef(maxnv,maxnl,maxnh)
      dimension  kxef(maxnv,maxnl,maxnh)
c angle between xsi-direction and main direction of anisotropy, positiv counterclockwise
      dimension  w_xshr(maxnv,maxnl)
c angle between xsi-direction and horizontal line, positiv counterclockwise,
c depends only on coordinate system
      dimension  w_xsho(maxnv,maxnl), w_xshol(maxnv,maxnl,maxnh)
c angle between horizontal line and main direction of anisotropy, positiv counterclockwise
      dimension  w_hohr(maxnv,maxnl)
c xsi-coordinate
      dimension  xsi(maxnl,maxnh), flaeche(maxnv,maxnl,maxnh)
c
c    1                    il-1       il                   il+1
c    o------------o--....--o---------o----------------------o-------o---....
c    |      |                   |                |
c    |<---->|                   |<--dr_o(il,?)-->|
c    dr_o(1,?)                     drxsi(?,il,?)
c
c real length in [m] (related interval to a point)
c  dr_o: along surface boundary
c  dr_u: along bottom  boundary
c  drxsi: all lateral distances
      dimension  dr_o(maxnl,maxnh)
      dimension  dr_u(maxnl,maxnh)
      dimension  drxsi(maxnv,maxnl,maxnh)
c xsi(il+1)-xsi(il)
      dimension  x_p1m0(maxnl-1,maxnh)
c xsi(il+1)-xsi(il-1)
      dimension  x_p1m1(maxnl-2,maxnh)
c eta-coordinate
      dimension  eta(maxnv,maxnh)
c
c    1                    iv-1       iv                   iv+1
c    o------------o--....--o---------o----------------------o-------o---....
c    |      |                   |                |
c    |<---->|                   |<--dr_r(iv,?)-->|
c    dr_r(1,?)                     drxsi(?,iv,?)
c
c real length in [m] (related interval to a point)
c  dr_r: along right boundary
c  dr_l: along left  boundary
c  dreta: all vertical distances
      dimension  dr_l(maxnv,maxnh)
      dimension  dr_r(maxnv,maxnh)
      dimension  dreta(maxnv,maxnl,maxnh)
c eta(iv+1)-eta(iv)
      dimension  e_p1m0(maxnv-1,maxnh)
c eta(iv+1)-eta(iv-1)
      dimension  e_p1m1(maxnv-2,maxnh)
c lateral hillslope coordinates of computational nodes (grid points) in [m]
      dimension  sko(maxnv,maxnl,maxnh)
c horizontal global coordinates ("Rechtswert") in [m]
      dimension  xko(maxnl)
c reference coordinate ("Rechtswert") in [m]
      dimension  xkobez(maxnh)
c horizontal global coordinates ("Hochwert") in [m]
      dimension  yko(maxnl)
c reference coordinates ("Hochwert") in [m]
      dimension  ykobez(maxnh)
c vertical hillslope coordinates of grid points in [m+above reference level]
      dimension  hko(maxnv,maxnl,maxnh)
c vertical hillslope coordinates reference level in [m]
      dimension  hkobez(maxnh)
c depth under surface
      dimension  depth(maxnv,maxnl,maxnh)
c true, if macropore information is read from file
      dimension  lmak(maxnh)
c macropore factors
      dimension  macro(maxnv,maxnl,maxnh), amak(maxnv,maxnl,maxnh)
      dimension  b_mac(maxnv,maxnl,maxnh)
c vertical index of deepest macroporous element
      dimension  ivm(maxnl,maxnh)
c tangens of angle between surface and horizontal
      dimension  gefall(maxnl,maxnh)
c azimut (orientation) of hillslope line (clockwise from north)
      dimension  azimut(maxnl,maxnh)
c cosine of angle between surface and horizontal
c   slopeo: top
c   slopeu: bottom
c   sloper: right
c   slopel: left
      dimension  slopeo(maxnl,maxnh)
      dimension  slopeu(maxnl,maxnh)
      dimension  sloper(maxnv,maxnh)
      dimension  slopel(maxnv,maxnh)
c index of soil type
      dimension  iboden(maxnv,maxnl,maxnh)
c method of averaging conductivity between two elements
      dimension  mm_xsi(maxnv,maxnl-1,maxnh)
      dimension  mm_eta(maxnv-1,maxnl,maxnh)
c related element area to a computational node
      dimension  area(maxnv,maxnl,maxnh)
c weighting factor, used when computing mean moisture of two elements
      dimension  al_fak(maxnv,maxnl-1,maxnh)
      dimension  av_fak(maxnv-1,maxnl,maxnh)
c geometrical quantity used for computation of diffusion number (DIFFCAL, not activ anymore)
c      dimension  xyxpy(maxnv,maxnl,maxnh)
c area of longitudinal section of entire hillslope and (sub)-control-volumes
      dimension  alla(maxcv,maxnh)
c volume of entire hillslope and (sub)-control-volumes (variable width)
      dimension  vola(maxcv,maxnh)
c total length of boundaries along hillslope
c   lrd_o: top
c   lrd_u: bottom
c   lrd_r: right
c   lrd_l: left
      dimension  lrd_o(maxnh)
      dimension  lrd_u(maxnh)
      dimension  lrd_l(maxnh)
      dimension  lrd_r(maxnh)
c total surface area of hillslope
      dimension  hgobfl(maxnh)
c variable width of hillslope
      dimension  varbr(maxnl,maxnh)
c factors for use in numerical scheme, build from variable width of hillslope
      dimension  fbrup(maxnl,maxnh)
c factors for use in numerical scheme, build from variable width of hillslope
      dimension  fbrlow(maxnl,maxnh)
c mean width of hillslope
      dimension  hgbreit(maxnh)
c length of hillslope
      dimension  hglang(maxnh)
c reference level of internal used vertical coordinates
      dimension  hkomin(maxnh)
c number of hillslopes (like a name)
      dimension hangnr(maxnh)
c position of hillslope number
      dimension hgih(maxnum)
c leakage-parameter (k'/d') of channel at hillfoot
      dimension lambda(maxnh)
c number of channel reach, where hillslope runoff (1) and sealed surface (2)
c contribute
      dimension igewkn(2,maxnh)
c indices of corners of control volumes for water balance
c   icv_o: top
c   icv_u: bottom
c   icv_r: right
c   icv_l: left
      dimension  icvo(maxcv,maxnh), icvu(maxcv,maxnh)
      dimension  icvl(maxcv,maxnh), icvr(maxcv,maxnh)
c... relative Faktors to represent statistical variability of ks values and
c    porosity
      dimension rel_ks(maxnv,maxnl,maxnh),rel_ths(maxnv,maxnl,maxnh)

c      common /hgfest/
c     &  f_xsi,f_eta,fmf,fdf,varbr,fbrup,fbrlow,vola,
c     &  xsi,eta,x_p1m0,x_p1m1,e_p1m0,e_p1m1,
c     &  sko,hko,iboden,area,xyxpy,alla,hkomin,iacnv,iacnl,iacnh,ihgr,
c     &  kxx,kee,kxe,w_hohr,w_xshr,w_xsho,w_xshol,mm_xsi,mm_eta,
c     &  av_fak, al_fak, fcabf, fabf,
c     &  d_Th_opt, d_Phi_opt, hangnr, hgih, lmak,
c     &  macro, ivm, depth, xko, yko, xkobez, ykobez, hkobez,
c     &  slopeo, slopeu, sloper, slopel, gefall, azimut,
c     &  hgobfl, hgbreit, hglang, lambda, igewkn,
c     &  dr_u, dr_o, dr_l, dr_r, drxsi, dreta,
c     &  lrd_u, lrd_o, lrd_l, lrd_r,
c     &  iaccv, icvo, icvu, icvl, icvr,
c     &  rlongi, longi, lati, kxxf, keef, kxef, amak 

      common /hfestr/
     & rlongi, longi, lati,
     & varbr, fbrup, fbrlow,
     & f_xsi, f_eta, fmf, fdf,
     & xsi, eta, x_p1m0, x_p1m1, e_p1m0, e_p1m1,
     & xko, yko, hko, sko, xkobez, ykobez, hkobez,
     & hgobfl, hgbreit, hglang, lambda,
     & macro, depth, area, xyxpy, alla, vola, hkomin, amak,
     & slopeo, slopeu, sloper, slopel, gefall, azimut,
     & av_fak, al_fak,
     & dr_u, dr_o, dr_l, dr_r, drxsi, dreta,
     & lrd_u, lrd_o, lrd_l, lrd_r,
     & kxx, kee, kxe, w_hohr, w_xshr, w_xsho, w_xshol,
     & d_Th_opt, d_Phi_opt,
     & kxxf, kxef, keef, fcabf, fabf, flaeche,
     & rel_ks, rel_ths, b_mac 

      common /hfesti/
     & iboden, mm_xsi, mm_eta,
     & ivm, igewkn, iaccv,
     & icvo, icvu, icvl, icvr,
     & hangnr, hgih,
     & ihgr, iacnh, iacnv, iacnl ,m_aniso


      common /hfestl/ lmak
	  common /hfestc/ vimet
