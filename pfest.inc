c--------------------------------------------------------------------
c  pfest.inc time independent parameters for solute transport
c---------------------------------------------------------------------

c retardation faktor and degradation constant for different solute types,
c partikel mass, dispersion coefficient, global parameters

        real*8  k_sorp, sorp2, m_pt, abbau, d_koef
	integer*4 i_sorp
c       k_sorp is either KD, or KF or K in case of using a linear, Freundlich or Langmuir
c       sorption isotherm, refers to switch i_sorp 1, 2 , 3
c       sorp2 is either n of Freundlich or Maximum concentration of Langmuir model 
        dimension k_sorp(maxstt,maxtyp), sorp2(maxstt,maxtyp) 
c       particle dimension 
        dimension m_pt(maxstt,maxnh)
c       Abbauparameter
        dimension abbau(maxstt,maxtyp)

c dispersivity
        dimension d_koef(maxstt,maxtyp)


      common /pfest/ k_sorp, sorp2, abbau, m_pt, d_koef
      common /pfest2/ i_sorp
