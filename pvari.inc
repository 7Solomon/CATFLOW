c-----------------------------------------------------------
c time dependent variables for particle tracking 
c-----------------------------------------------------------

      real*8 hkpact, skpact, hkpalt, skpalt, xpact, epact
      real*8 xpalt, epalt
      real*8 vxact, veact, vxalt, vealt
      real*8 vhact,vsact
      real*8 vx_st, ve_st, vx_sta, ve_sta
      real*8 gtxact, gteact, gtxalt, gtealt
      real*8 r_ret
      real*8 vxipo, veipo
      real*8 c_pw, c_ptr, c_wact, c_tact
      real*8 mpact, mpkon, mp_bil
      real*8 cg_q, sig_cg, skew_cg, chs_q, sig_hs, skew_hs
      real*8 kovc, kovcg, mkorrf,  cgz, mlos_l, mlos_u, mlos_r
      integer*4 ixalt, ixact, ieact, iealt
      integer*4 iplos
      integer*4 nplosl, nplosu, nplosr
      integer*4 npkon


c----actual and old position of particles in the cartesian grid
      dimension hkpact(maxstt,npmax,maxnh),skpact(maxstt,npmax,maxnh)
      dimension hkpalt(maxstt,npmax,maxnh),skpalt(maxstt,npmax,maxnh)

c----- actual and old generalised pore water velocites in the cartesian grid---------
      dimension vhact(maxnv, maxnl), vsact(maxnv,maxnl)

c-----actual and old position of particles in curivlinear coordiantes 
      dimension xpact(maxstt,npmax,maxnh), epact(maxstt,npmax,maxnh)
      dimension xpalt(maxstt,npmax,maxnh), epalt(maxstt,npmax,maxnh)

c-----actual and old index locating the number of the grid cell associated to the particle position 
c     Konvention ixact, ieact bezeichen iv bzw. il des linken, oberen Knotens
      dimension ixact(maxstt,npmax,maxnh),ieact(maxstt,npmax,maxnh)
      dimension ixalt(maxstt,npmax,maxnh),iealt(maxstt,npmax,maxnh)

c---- actual and old generalised pore water velocites in the curivlinear grid
      dimension vxact(maxnv,maxnl), veact(maxnv,maxnl)
      dimension vealt(maxnv,maxnl), vxalt(maxnv,maxnl)

c---- actual and old moisture gradient
      dimension gtxact(maxnv,maxnl), gteact(maxnv,maxnl)
      dimension gtxalt(maxnv,maxnl), gtealt(maxnv,maxnl)

c---- actual and old  v'=v+D grad ln(theta)
	  dimension vx_st(maxnv,maxnl,maxnh),ve_st(maxnv,maxnl,maxnh)
	  dimension vx_sta(maxnv,maxnl,maxnh),ve_sta(maxnv,maxnl,maxnh)

c----- actual and old pore water velocities at the particle position
c      dimension vxipo(maxstt,npmax), veipo(maxstt,npmax)
c      dimension vxipa(maxstt,npmax), veipa(maxstt,npmax)

c----- number of lost particle at right, left and lower boundary 
       dimension nplosl(maxstt, maxnh), nplosr(maxstt,maxnh)
       dimension nplosu(maxstt,maxnh)
       dimension mlos_l(maxstt, maxnh), mlos_r(maxstt,maxnh)
       dimension mlos_u(maxstt,maxnh)

c-----index of particles that inidcates whether the particle is in the domain or not 1/0
       dimension iplos(maxstt,npmax,maxnh)

c------ number of particles in a grid cell for concentration computation
       dimension npkon(maxstt,maxnv-1,maxnl-1)

c------residual concentration in the water phase and dry phase without degradation
       dimension c_pw(maxstt,maxnv-1,maxnl-1,maxnh)
       dimension c_ptr(maxstt,maxnv-1,maxnl-1,maxnh)

c------residual concentration in the water phase and dry phase without degradation
       dimension c_wact(maxstt,maxnv-1,maxnl-1,maxnh)
       dimension c_tact(maxstt,maxnv-1,maxnl-1,maxnh)
       dimension mkorrf(maxstt,maxnh)
	   dimension mp_bil(maxstt,maxnh)

c------ retardation factor--------------------------------------------
       dimension r_ret(maxstt,maxnv,maxnl)

c------- actual parctile mass and actual mass of all particles in a grid cell --------------
       dimension mpact(maxstt,npmax,maxnh)
	   dimension mpkon(maxstt,maxnv-1,maxnl-1)

c------ mean, standard deviation and skewnes of the solute center of mass in the soil
       dimension cg_q(maxstt,maxnh), sig_cg(maxstt,maxnh)
       dimension skew_cg(maxstt,maxnh)

c------ mean, standard deviation and skewnes of the solute center of mass in the soil of transport distance pdf
        dimension chs_q(maxstt,maxnh),sig_hs(maxstt,maxnh)
        dimension skew_hs(maxstt,maxnh)

c--------covarianz of solute concentrations
c        und der Schwerpunktstiefen
         dimension kovc(maxstt, maxnv,maxnl,maxnh)
         dimension kovcg(maxstt,maxnl,maxnh)
c-------- horizontal dsitribution of the solute center of mass in the grid columns
         dimension cgz(maxstt,maxnl-1, maxnh)

      common /pvari1/ hkpact, skpact, xpact, epact,
     & xpalt, epalt, vxact, veact, vxalt, vealt, r_ret,
     & skpalt, hkpalt, vhact, vsact, gtxact, gteact,
     & gtxalt, gtealt, mpact,vx_st, ve_st, vx_sta, ve_sta,
     & vxipo, veipo, c_pw, c_ptr, mpkon, c_wact, cg_q,
     & sig_cg, skew_cg, chs_q, sig_hs,skew_hs, kovcg, kovc,
     & c_tact, mkorrf, cgz, mp_bil, mlos_u, mlos_r, mlos_l

      common /pvari2/ ixalt, ixact,ieact, iealt, nplosl,
     & nplosr, nplosu, iplos, npkon
