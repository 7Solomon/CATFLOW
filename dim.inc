c-----------------------------------------------------------------------
c  DIM.INC           Dimensions of arrays
c-----------------------------------------------------------------------
      integer*4 maxprt, maxin, maxout
      integer*4 maxnv,maxnl,maxnh
      integer*4 maxtyp, maxeig, maxpbm, maxtab
      integer*4 maxfix, maxwrf, maxuse, maxpft, maxpfp
      integer*4 maxnie, maxkli
      integer*4 maxrbf, maxsnk
      integer*4 maxrbp, maxskp, maxkld
      integer*4 maxgr, maxfil
      integer*4 maxcv
      integer*4 maxnb, maxit, maxgng, maxhor, maxnum, maxero
      integer*4 maxpkt
c----- neue Parameter fuers pt
      integer*4 maxstt, maxmif
      integer*4 npmax
	  integer*4 maxbrf
c-----------------------------------------------------------------------
c  control files
      parameter (maxfil = 220)
c  input files
      parameter (maxin  =   8)
c  output files 
      parameter (maxout =  20)
c  max. number of print-out times
      parameter (maxprt = 100000)
c-----------------------------------------------------------------------
c  max. number of soil layers (eta)
       parameter (maxnv = 42)
c  max. number of soil columns (xsi)
       parameter (maxnl = 1201)
c  max. number of hillslopes
      parameter (maxnh = 1)
c  highest hillslope number (used as a name)
       parameter (maxnum = 30)
c-----------------------------------------------------------------------
c  max. number of soil types (as assigned in soil-parameter file)
      parameter (maxtyp = 35)
c  max. number of soil properties  (columns in soil table)
      parameter (maxeig = 5)
c  max. number of soil specific erosion parameters
      parameter (maxero = 3)
c  max. number of soil parameters of a model of soil hydraulic behaviour
      parameter (maxpbm = 9)
c  max. length of soil table (rows in soil table)
      parameter (maxtab = 1200)
c-----------------------------------------------------------------------
c  max. number of fixed integers to be assigned to a surface node
      parameter (maxfix =  3)
c  max. number of wind direction dependent factors
      parameter (maxwrf =  5)
c  max. number of angle to horizon for a surface node
      parameter (maxhor =  36)
c  max. number of land uses
      parameter (maxuse = 20)
c  max. length of land-use time series (rows in land-use table)
      parameter (maxpft = 25)
c  max. number of land-use parameters  (columns in land-use table)
      parameter (maxpfp = 15)
c  max. number of rainfall time series
      parameter (maxnie = 6)
c  max. number of climate time series
      parameter (maxkli = 4)
c-----------------------------------------------------------------------
c  max. number of boundary condition time series
      parameter (maxrbf = 5)
c  max. number of sink/source time series
      parameter (maxsnk = 2)
c-----------------------------------------------------------------------
c  max. number of boundary condition parameters
      parameter (maxrbp = 5)
c  max. number of sink/source parameters
      parameter (maxskp = 2)
c  max. number of climatic data in climate time series (min. number = 6)
      parameter (maxkld = 6)
c-----------------------------------------------------------------------
c  max. number of classes for time step statistics
      parameter (maxgr = 15)
c-----------------------------------------------------------------------
c  max. number of control volumes for hillslope water balance
      parameter (maxcv = 10)
c-----------------------------------------------------------------------
c  max. number of discrete drainage network reaches
      parameter (maxnb = 1000)
c  max. number of inflows from upstream (confluences)
      parameter (maxit =    3)
c  max. number of output hydrographs for output
      parameter (maxgng=   10)
c  max. number of soil moisture time series for output
      parameter (maxpkt=   70)
c  max. number of particles for particle tracking, global
      parameter (npmax= 25000)
c  max. number of different solute types,
c  must match the maximal number of boundary parameters minus one
      parameter (maxstt =3)
c  max number of mass inputs, must match the max. number of
c  parameter files maxrbf
      parameter (maxmif =5)
c  max number of boundary files for the drainage network
      parameter(maxbrf =3)

c  counter
      integer*4 icf
c  global hillslope surface roughness for one project (can be overriden susequently)
      real*8 kstall
      dimension kstall(maxfil)
      common /ckst/  kstall, icf

c  iteration criteria
      real*8 piceps, cgeps
c  max. number of Picard iterations
c  number of Picard iterations, from which subsequent time step is reduced
      integer*4 it_max, n_gr
      common /cepsi/ it_max, n_gr
      common /cepsr/ piceps, cgeps

c  switch is true, when surface attributes are read
c  switch is true, when land use is considered
      logical lpob, lland
      dimension lpob(maxnh)
      common /catm/ lpob, lland

c  several input/output units
      integer*4 ilok, ipar
      integer*4 io, iin, io_log
      dimension io(maxout), io_log(maxout)
      dimension iin(maxin)
      integer*4 io_act, iin_act
      integer*4 iikli, iinie, iisnk, iirbf, inutz
      dimension iikli(maxkli)
      dimension iinie(maxnie)
      dimension iisnk(maxsnk)
      dimension iirbf(maxrbf)
      common /cio/ io, iin, iikli, iinie, iisnk, iirbf,
     &             ilok, ipar, inutz,
     &             io_act, iin_act, io_log

c  max. and min. soil moisture within a hillslope
      real*8 th_max, th_min
c  max. and min. suction head within a hillslope
      real*8 psi_max, psi_min
c  max. and min. total potential within a hillslope
      real*8 phi_max, phi_min
c  max. flux within a hillslope
c  max. sink/source flux within a hillslope
      real*8 fl_max, sk_max
      dimension th_max(maxnh), th_min(maxnh)
      dimension psi_max(maxnh), psi_min(maxnh)
      dimension phi_max(maxnh), phi_min(maxnh)
      dimension fl_max(maxnh), sk_max(maxnh)

      common /cmima/ th_max, th_min, phi_max, phi_min,
     &               psi_max, psi_min, fl_max, sk_max
