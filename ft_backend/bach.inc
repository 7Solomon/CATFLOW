c-----------------------------------------------------------------------
c  BACH.INC              drainage network
c-----------------------------------------------------------------------
      integer*4  iacnb, ib_nr, igang, iacgng, ihgb, ibrart 
      integer*4  ibnext, inhang, inarea, ib_ord, ib_reg, itmax, ibtop
	  integer*4   iacqbr, iqrbb,iqsour, iacbrf, ibrbf, irb_b
      real*8   b_dx, b_gef, b_ezg, b_yso, b_vorl, y_vorl, y_bach
      real*8   b_rauh, b_m, qhang, qarea, qbas, brso, v_bach, weg_br
      real*8   qpegel, qpmax, dtsur, aahang, xba, yba
      real*8   bapsi, stpsi(3), lapsi(3)
      real*8   qtol, qshg, qsour, flek, szbach, zfbach, bwq, zbach
	  real*8   qshang
	  character*30 brbfil
  
c  tolerance for drainage network runoff computation in [cbm/s per s].
c  If acceleration of runoff is lower, runoff process is tempral neglected.
c  swich is true when drainage network runoff is active
      logical  lqactiv
      logical  exhg, inter, auint, rbbneu

c  number of actual node of drainage network
      dimension ib_nr(maxnb)
c  node in the river system assocoiated with a hill slope
      dimension ihgb(maxnh)
c  number of subsequent downstream node
      dimension ibnext(maxnb)
c  number of incoming hillslope
      dimension inhang(maxnb)
c  if > 0, contributing sealed surface is present
      dimension inarea(maxnb)
c  STRAHLER-order
      dimension ib_ord(maxnb)
c  rainfall-gauge number which contributes to runoff
c  (according to the numbering in input file for rainfall time series)
      dimension ib_reg(maxnb)
c  length to next downstream node in [m]
      dimension b_dx(maxnb)
c  width of sealed surface along channel
      dimension weg_br(maxnb)
c  slope of drainage network reach
      dimension b_gef(maxnb)
c  local catchment area of current node
      dimension b_ezg(maxnb)
c  elevation of channel bottom
      dimension b_yso(maxnb)
c  elevation of channel top
      dimension b_vorl(maxnb)
c  horizontal coordinates
      dimension xba(maxnb)
      dimension yba(maxnb)
c  channel depth (bottom to top)
      dimension y_vorl(maxnb)
c  actual runoff depth
      dimension y_bach(maxnb)
c  bottom width of trapeziodial channel
      dimension brso(maxnb)
c  wetted channel volume
      dimension v_bach(maxnb)
c  max. number of inflowing upstream nodes ...
      dimension itmax(maxnb)
c  ... and related channel reach numbers
      dimension ibtop(maxnb,maxit)
c  surface area of linked hillslope
      dimension aahang(maxnb)
c  leakage coefficient for interchange of subsurface and drainage water
c  iqsour indices whether a node is a boundary node (value 1) or not (value 0)
c  iqrbb pointer to the nodes specified as boundary nodes
c   ibrbf pointer to the boundary condition files
      dimension flek(maxnb),iqrbb(maxnb),iqsour(maxnb), ibrbf(maxbrf)
	  dimension szbach(maxbrf), ibrart(maxbrf), zfbach(maxbrf)
	  dimension irb_b(maxnb), zbach(2,maxbrf)
c   bwq Boundary value for boundary (source) knotes of the drainage network
      dimension bwq(2,maxbrf)
c  channel node numbers, where hydrographs will be output
      dimension igang(maxgng)

c  channel roughness (Strickler)
      dimension b_rauh(maxnb)
c  slope of wall of trapeziodial crossection (1:b_m vertical/horizontal)
      dimension b_m(maxnb)
c  mean inflow from hillslope during time up to actual time horizon (in CATFLOW.FOR)
      dimension qhang(maxnh), qshg(maxnh), qshang(maxnh)
c  true, after hillslope number (not counter ih, but hangnr(ih)) has been computed
      dimension exhg(maxnum)
c  mean inflow from sealed surfaces during time up to actual time horizon (in CATFLOW.FOR)
      dimension qarea(maxnb)
c  baseflow qbas per unit channel length, which has to be given as a boundary condition
c  if no interaction between brook and soil water is simulated  
c   (e.g. due to springs from outside the control volume of the hillslopes),
c  flow from sources qsour into the drainage system [cbm/s], which has to be given as boundary condtion
c  if interaction between brook and soil water is simulated, 
      dimension qbas(maxnb), qsour(maxnb)
c  logical variable to indicate whether interation at a node is allowed or not
      dimension inter(maxnb)
c   Inputfile names
      dimension brbfil(maxbrf)
 
	 	   
      common /cbachr/
     &   b_dx, b_gef, b_ezg, b_yso, b_vorl, y_vorl, y_bach, weg_br,
     &   b_rauh, b_m, qhang, qarea, qbas, brso, v_bach, aahang,
     &   qpegel, qpmax, xba, yba,dtsur, qtol, bapsi, stpsi, lapsi,
     &   qshg, qsour, flek, szbach, zfbach, bwq, zbach, qshang

      common /cbachi/
     &   iacnb, ib_nr, igang, iacgng, ibnext, inhang, inarea,
     &   ib_ord, ib_reg, itmax, ibtop, ihgb,
     &   iacqbr, iqrbb,iqsour, iacbrf, ibrbf, ibrart, irb_b

      common /cbachl/ lqactiv, exhg, inter, auint, rbbneu

      common /cbachc/
     & brbfil