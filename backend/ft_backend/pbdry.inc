c---------------------------------------------------------------
c pbdry.inc boundary conditions for solute transport
c-------------------------------------------------------------- 

      real*8 mp_inj, c_inj, cil_o, t_inj, t_injk
      real*8 mp_ini, m_ges, cil_r, cil_u, cil_l
      integer*4 npact,npalt, ninpot, ninact, np_ofl
      integer*4  nposum, iinj, iinj1(maxnh)
      integer*4 iseed
      integer*4 iimif, iacmif,istact,imf
      character*30 minfil
      character*8 strand
c input mass and concentration
      dimension mp_inj(maxstt,maxrbf), c_inj(2,maxstt,maxrbf)
c  initial solute mass in a hillslope
       dimension mp_ini(maxstt,maxnh)
c injected number of particles , actual and old number of particles in a hillslope
      dimension npact(maxstt,maxnh), npalt(maxstt,maxnh)
c number of particles locally injected at a grid node
      dimension ninact(maxstt,maxnl), ninpot(maxstt,maxnl)
c cumulative solute loss with surface runoff
      dimension np_ofl(maxstt,maxnh), nposum(maxstt,maxnh)
c counter of  inputmass files
      dimension iimif(maxmif)
c name of inputmass files
      dimension minfil(maxmif)
c input concentration locally injected at a grid node at the upper boundary
      dimension cil_o(maxstt,maxnl,maxnh)
c input concentration locally injected at a grid node at the lower boundary
      dimension cil_u(maxstt,maxnl,maxnh)
c input concentration locally injected at a grid node at the left boundary
      dimension cil_l(maxstt,maxnv,maxnh)
c input concentration locally injected at a grid node at the right boundary
      dimension cil_r(maxstt,maxnv,maxnh)
c --- time increment for solute injection
      dimension t_inj(0:30000)
c total solute mass in a hillslope
      dimension m_ges(maxstt,maxnh)
c Pointer to relate in Massinputfile to hillslope
      dimension imf(maxnh) 

      common /pbo1/ mp_inj, c_inj, cil_o, t_inj, t_injk, mp_ini,
     &         m_ges, cil_r, cil_l, cil_u
      common /pbo2/ npact, npalt, istact, iimif, iacmif,imf,
     &        np_ofl, ninpot, ninact, nposum,iinj,iinj1, iseed
      common /pbo3/ minfil, strand
