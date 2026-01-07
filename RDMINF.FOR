c-----------------------------------------------------------------------
c  Lesen der Anzahl der Stofftypen und der Inputmassen mp_inj
c-----------------------------------------------------------------------

      subroutine rdminf(ifl, istac)

      include 'dim.inc'
      include 'pbdry.inc'
      include 'pfest.inc'

      integer*4 i, ifl , istac
	  character*80 cdum
      real*8 calmp
      external maxtst, calmp



      call maxtst('ISTACT ',istact,'MAXSTT  ',maxstt,'RDMINF  ')
c      write(6,*) 'mp_inj einlesen','istac=',istac
      do 100 i = 1,istac
  101   read(iimif(ifl),'(a)',end=900) cdum
c        write(6,*) cdum
        if(cdum(1:1) .eq. '#') goto 101
        read(cdum,*) mp_inj(i,ifl), t_injk
c        m_pt(i,ifl)=calmp(mp_inj(i,ifl),npmax)
c        write(6,*)'mp_inj=', mp_inj(i,ifl)
c        write(6,*)'t_injk',t_injk
  100 continue
      goto 999

  900 stop 'Dateiende in rdminf. Weniger Parameter als Stofftypen?'

  999 continue
      return
      end

c-----------------------------------------
c  Berechnung der Masse der Tracerpartikel
c  Input: m_in gesamte Inputmasse
c         npth maximale Teilchenzahl
c-----------------------------------------

      double precision function calmp(mp_ge, npth)
      real*8 mp_ge
      integer*4 npth
	  intrinsic real

      calmp=mp_ge/real(npth)

      return
      end
