c-----------------------------------------------------------------------
c  HGVARI.INC       time dependent hillslope variables
c-----------------------------------------------------------------------
      real*8 Fx_p1,Fx_00,Fx_m1,Fe_p1,Fe_00,Fe_m1
      real*8 RS,vorfak,A_x,A_e,psi,durchl,wasska,diffus
      real*8 A2x,A2e
      real*8 rfl_u, rfl_o, rfl_r, rfl_l
      real*8 ueb_u, ueb_o, ueb_r, ueb_l
      real*8 phiini, phialt, phineu
      real*8 theta, th_ini, th_alt, senk, sueb
      real*8 hwsp, yoben, yo_alt
      real*8 qomax, qosum, qssum, q
      real*8 th_mit, yo_mit
      real*8 q_eta, q_xsi, qxalt, qealt
      integer*4 tabpos,ih1st

c... lrill     true, if rillflow is computed, currently fixed (false)
      logical lrill, mak_an
c... lwriten   true, if rainfall has to be dumped to surface runoff output file
c... lwriteq   true, if runoff has to be dumped to surface runoff output file
c... lwrites   true, if runoff has to be dumped, ensures one more value to be dumped
c              after event ended
c... lw1st     true, as long as no surface runoff output has been dumped
c... lw11st    true, as long header line has not been dumped to surface runoff file
c              (factors fabf, fcabf)
c... ih1st     number of that hillslope, which first produces surface runoff
      logical lwriten,lwriteq,lwrites,lw1st,lw11st

c... total incremental water balance within a time step, should be zero
      real*8 bilanz
c... incremental flux terms across individual boundaries within a time step
      real*8 vrfl_u, vrfl_o, vrfl_r, vrfl_l, vsenk
      real*8 vueb_u, vueb_o, vueb_r, vueb_l, vsueb
      real*8 vnied, vnied2, vintz, vevapo, vtrans
c... cumulative flux terms across individual boundaries
c    since start of computation
      real*8 brfl_u, brfl_o, brfl_r, brfl_l
      real*8 bueb_u, bueb_o, bueb_r, bueb_l
      real*8 bnied, bnied2,  bintz, bevapo, btrans
c... incremental flux terms across all boundaries within a time step
      real*8 volrd
c... cumulative flux terms across all boundaries since start of computation
      real*8 bilrd
c... cumulative flux terms from sinks/sources since start of computation
      real*8 bsenk, bsueb
c... incremental change in total water content within a time step
      real*8 volin
c... cumulative change in total water content since start of computation
      real*8 bilin
c... total cumulativ balance (bilin-bilrd+bsenk), should be zero
      real*8 biltot
c..... balance of cumulative mass loss accross boundaries
      real*8 bm_l, bm_u, bm_r
c... coefficients of numerical scheme
      dimension  Fx_p1(maxnv,maxnl)
      dimension  Fx_00(maxnv,maxnl)
      dimension  Fx_m1(maxnv,maxnl)
      dimension  Fe_p1(maxnv,maxnl)
      dimension  Fe_00(maxnv,maxnl)
      dimension  Fe_m1(maxnv,maxnl)
      dimension  RS(maxnv,maxnl)
      dimension  vorfak(maxnv,maxnl)
      dimension  A_x(maxnv,maxnl-1)
      dimension  A_e(maxnv-1,maxnl)
      dimension  A2x(maxnv,maxnl-1)
      dimension  A2e(maxnv-1,maxnl)
c... fluxes in eta-direction
      dimension  q_eta(maxnv,maxnl), qealt(maxnv,maxnl)
c... fluxes in xsi-direction
      dimension  q_xsi(maxnv,maxnl), qxalt(maxnv,maxnl)

c... old state of the system (potential), to be used e.g. if iteration
c    fails and time step has to be repeated
      dimension  phialt(maxnv,maxnl,maxnh)
c... new state of the system (potential)
      dimension  phineu(maxnv,maxnl)
c... initial state of the system (potential)
      dimension  phiini(maxnv,maxnl)
c... suction head
      dimension  psi(maxnv,maxnl)
c... current position in soil hydraulic function table
      dimension  tabpos(maxnv,maxnl,maxnh)
c... initial soil moisture
      dimension  th_ini(maxnv,maxnl)
c... actual soil moisture
      dimension  theta(maxnv,maxnl)
c... old soil moisture
      dimension  th_alt(maxnv,maxnl)
c... actual conductivity
      dimension  durchl(maxnv,maxnl)
c... actual water capacity
      dimension  wasska(maxnv,maxnl)
c... actual diffusion number
      dimension  diffus(maxnv,maxnl)
c... true, if macropores are active
      dimension  mak_an(maxnv,maxnl)
c... sink terms  [1/sec]
      dimension  senk(maxnv,maxnl)
      dimension  sueb(maxnv,maxnl)
c... elevation of water level at hillfoot
      dimension  hwsp(maxnh)
c... depth of surface runoff (vertical, while local variable yo in UPDYO
c    is perpendicular to surface)
      dimension  yoben(maxnl)
c... old depth of surface runoff
      dimension  yo_alt(maxnl,maxnh)
c... true, if rillflow is computed, currently fixed (false)
      dimension  lrill(maxnl,maxnh)
c... max. runoff at hillfoot since start of simulation
      dimension  qomax(maxnh)
c... cumulative surace runoff and interflow at hillfoot since start of simulation
      dimension  qosum(maxnh), qssum(maxnh)
c... actual runoff at each surface node
      dimension  q(maxnl,maxnh)
c... true, as long as no output has been dumped
      dimension  lw1st(maxnh)
c... boundary fluxes
      dimension  rfl_u(maxnl)
      dimension  rfl_o(maxnl)
      dimension  rfl_r(maxnv)
      dimension  rfl_l(maxnv)
c... boundary flux infiltration excess (potentially) 
      dimension  ueb_u(maxnl)
      dimension  ueb_o(maxnl)
      dimension  ueb_r(maxnv)
      dimension  ueb_l(maxnv)
c old and new mean soil moisture
      dimension  th_mit(maxcv,2,maxnh)
c old and new mean depth of surface runoff on hillslope
      dimension  yo_mit(2,maxnh)
c... total cumulativ balance (bilin-bilrd+bsenk), should be zero
      dimension  biltot(maxcv,maxnh)
c... cumulative change in total water content since start of computation
      dimension  bilin(maxcv,maxnh)
c... cumulative flux terms across all boundaries since start of computation
      dimension  bilrd(maxcv,maxnh)
c... cumulative flux terms from sinks/sources since start of computation
      dimension  bsenk(maxcv,maxnh)
      dimension  bsueb(maxcv,maxnh)
c... cumulative flux terms across individual boundaries
c    since start of computation
      dimension  brfl_u(maxcv,maxnh)
      dimension  brfl_o(maxcv,maxnh)
      dimension  brfl_r(maxcv,maxnh)
      dimension  brfl_l(maxcv,maxnh)
      dimension  bueb_u(maxnh)
      dimension  bueb_o(maxnh)
      dimension  bueb_r(maxnh)
      dimension  bueb_l(maxnh)
      dimension  bnied(maxcv,maxnh), bnied2(maxcv,maxnh)
      dimension  bintz(maxcv,maxnh)
      dimension  bevapo(maxcv,maxnh)
      dimension  btrans(maxcv,maxnh)
      dimension  bm_l(maxstt,maxnh),bm_r(maxstt,maxnh) 
	  dimension  bm_u(maxstt,maxnh)
c... incremental flux terms across individual boundaries within a time step
      dimension  vrfl_u(maxcv), vrfl_o(maxcv)
      dimension  vrfl_r(maxcv), vrfl_l(maxcv)
      dimension  vsenk(maxcv),  vsueb(maxcv)
      dimension  vnied(maxcv), vnied2(maxcv),  vintz(maxcv)
      dimension  vevapo(maxcv), vtrans(maxcv)
c... incremental flux terms across all boundaries within a time step
      dimension  volrd(maxcv)
c... incremental change in total water content within a time step
      dimension  volin(maxcv)
c... total incremental water balance within a time step, should be zero
      dimension  bilanz(maxcv)

      common /hgvarr/
     &  Fx_p1,Fx_00,Fx_m1,Fe_p1,Fe_00,Fe_m1,
     &  RS,vorfak,A_x,A_e,psi,durchl,wasska,diffus,
     &  A2x,A2e,phiini,phialt,phineu,
     &  theta,th_ini,th_alt,senk,sueb,
     &  hwsp, yoben, yo_alt, rfl_u, rfl_o, rfl_r, rfl_l,
     &  th_mit, yo_mit, ueb_u, ueb_o, ueb_r, ueb_l,
     &  vrfl_u, vrfl_o, vrfl_r, vrfl_l, vsenk, bilanz,
     &  vueb_u, vueb_o, vueb_r, vueb_l, vsueb,
     &  vnied, vnied2, vintz, vevapo, vtrans,
     &  brfl_u, brfl_o, brfl_r, brfl_l, bsenk,
     &  bueb_u, bueb_o, bueb_r, bueb_l, bsueb,
     &  bnied, bnied2, bintz, bevapo, btrans,
     &  volrd, bilrd, volin, bilin, biltot,
     &  q_eta, q_xsi, qxalt, qealt, qomax, qosum, q,
     &  qssum, bm_l, bm_r, bm_u

      common /hgvari/ tabpos,ih1st
      
      common /hgvarl/
     & lwriten,lwriteq,lwrites,lw1st,lw11st, lrill, mak_an
