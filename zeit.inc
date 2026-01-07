c-----------------------------------------------------------------------
c  ZEIT.INC           times
c-----------------------------------------------------------------------

c... t_start     global starting point in time [s]
c... t_end       global end point in time [s]
c... t_alt       local starting point in time [s]
c... t_neu       local end point in time [s]
c... t_act       actual simulation point in time [s]
c... dt_exp      max. explicit time step [s]
c... dt_min      global min. time step [s]
c... dt_max      global max. time step [s]
c... dtbach      max. timestep for active drainage network [s]
c... itag        number of day in year [s]
c... stunde      hour of day [s]
c.....dt_mak     max. timestep for active macropore flow

      real*8 t_start, t_end, t_alt, t_neu, t_act
      real*8 dt_exp, dt_min, dt_max, dtbach
      real*8 itag, stunde, dt_mak

c... counter for time steps
      integer*4  izaehl
      dimension  izaehl(maxnh)

c... date strings: start time, end time
      character*22 dstrs, dstre, dstrs2

c... print times
      real*8     t_p
c... counter
      integer*4    ip
c... switch for output control
      integer*4    it_p
      dimension  t_p(maxprt,maxnh), ip(maxnh)
      dimension  it_p(maxprt,maxnh)

c...statistics and histogram of time steps
c... boundary between classes of time step length
      real*8     clgr
c... cumulative time within one time step class
      real*8     cltim
c... cumulative number of timesteps within one time step class
      integer*4  class
c... actual number of time step class boundaries
      integer*4    iacgr
      dimension  clgr(maxgr), cltim(maxgr+1), class(maxgr+1)

      common /czeitr/ t_start, t_end, t_alt, t_neu, t_act,
     &               dt_exp, dt_min, dt_max, dtbach, itag, stunde,
     &               t_p, clgr, cltim,  dt_mak
      common /czeiti/ class, iacgr,it_p, ip, izaehl
      common /czeitl/ dstrs, dstre, dstrs2
