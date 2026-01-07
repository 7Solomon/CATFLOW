c-----------------------------------------------------------------------
c  EROSION.INC            erosion
c-----------------------------------------------------------------------
      real*8 abtrag, ab_alt, absum, ab_mit
      real*8 qe, qemax

c erosion mass [kg/m/m]
      dimension  abtrag(maxnl)
c erosion mass [kg/m/m]  (saving old state variable)
      dimension  ab_alt(maxnl,maxnh)
c cumulative erosion from hillslope [kg] (inflow to channel)
      dimension  absum(maxnh)
c old and new mean erosion mass (mean of hillslope surface)
      dimension  ab_mit(2,maxnh)
c erosion flux along hillslope [kg/s], integrated over wet cross-section
      dimension  qe(maxnl,maxnh)
c max. erosion flux at hillfoot [kg/s]
      dimension  qemax(maxnh)

      common /erosion/
     &        abtrag, ab_alt, absum, ab_mit,
     &        qe, qemax
