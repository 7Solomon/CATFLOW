      subroutine disec  (jhd1, jah1, mon1, tag1, std1, min1, sec1, hds1,
     &                   jhd2, jah2, mon2, tag2, std2, min2, sec2, hds2,
     &                   dtsec)
C-----------------------------------------------------------------------
C  Berechne Differenz Datum2-Datum1 in Sekunden
C-----------------------------------------------------------------------
      integer*4 jhd1, jah1, mon1, tag1, std1, min1, sec1, hds1
      integer*4 jhd2, jah2, mon2, tag2, std2, min2, sec2, hds2
      integer*4 nrtag1, nrtag2
      real    rtag1, woj1, taj1
      real    rtag2, woj2, taj2
      real*8  tsec1, tsec2, dtsec
      character*2 ctag1, ctag2


      external uhrsec, julian
      intrinsic dble, int

      call uhrsec (std1, min1, sec1, hds1, tsec1)
      call uhrsec (std2, min2, sec2, hds2, tsec2)
      if (jah1.eq.jah2 .and. mon1.eq.mon2 .and. tag1.eq.tag2) then
        dtsec = tsec2-tsec1
      else
        call julian(tag1, mon1, jhd1, jah1,
     &              rtag1, nrtag1, ctag1, woj1, taj1)
        call julian(tag2, mon2, jhd2, jah2,
     &              rtag2, nrtag2, ctag2, woj2, taj2)
        if (rtag2 .ge. rtag1) then
          if (tsec2 .ge. tsec1) then
            dtsec = tsec2-tsec1+24.*3600.*dble(int(rtag2-rtag1))
          else
            dtsec = 24.*3600.+tsec2-tsec1
            if (dtsec .ge. 24.*3600) then
              dtsec = dtsec+24.*3600.*dble(int(rtag2-rtag1))
            else
              dtsec = dtsec+24.*3600.*dble(int(rtag2-rtag1)-1)
            endif
          endif
        else
          if (tsec1 .gt. tsec2) then
            dtsec = tsec1-tsec2+24.*3600.*dble(int(rtag1-rtag2))
          else
            dtsec = 24.*3600.+tsec1-tsec2
            if (dtsec .ge. 24.*3600) then
              dtsec = dtsec+24.*3600.*dble(int(rtag1-rtag2))
            else
              dtsec = dtsec+24.*3600.*dble(int(rtag1-rtag2)-1)
            endif
          endif
          dtsec = -dtsec
        endif
      endif
      return
      end

      subroutine dzeit  (jhd1, jah1, mon1, tag1, std1, min1, sec1, hds1,
     &                   jhd2, jah2, mon2, tag2, std2, min2, sec2, hds2,
     &                   idtag, idstd, idmin, idsec, idhds, cminus)
C-----------------------------------------------------------------------
C  Berechne Differenz Datum2-Datum1
C    wenn Datum2 vor Datum1 liegt ist
C        idtag < 0
C        idstd < 0
C        cminus = '-'
C-----------------------------------------------------------------------
      integer*4 jhd1, jah1, mon1, tag1, std1, min1, sec1, hds1
      integer*4 jhd2, jah2, mon2, tag2, std2, min2, sec2, hds2
      integer*4 idstd, idmin, idsec, idhds
      integer*4 idtag
      integer*4 nrtag1, nrtag2
      real    rtag1, woj1, taj1
      real    rtag2, woj2, taj2
      real*8  tsec1, tsec2, dtsec
      character*2 ctag1, ctag2
      character*1 cminus

      external uhrsec, secuhr, julian
      intrinsic int

      cminus = ' '
      call uhrsec (std1, min1, sec1, hds1, tsec1)
      call uhrsec (std2, min2, sec2, hds2, tsec2)
      if (jah1.eq.jah2 .and. mon1.eq.mon2 .and. tag1.eq.tag2) then
        if (tsec2 .gt. tsec1) then
          dtsec = tsec2-tsec1
          call secuhr (idstd, idmin, idsec, idhds, dtsec)
          idtag = 0
        else
          dtsec = tsec1-tsec2
          call secuhr (idstd, idmin, idsec, idhds, dtsec)
          idtag = 0
          idstd = -idstd
          cminus = '-'
        endif
      else
        call julian(tag1, mon1, jhd1, jah1,
     &              rtag1, nrtag1, ctag1, woj1, taj1)
        call julian(tag2, mon2, jhd2, jah2,
     &              rtag2, nrtag2, ctag2, woj2, taj2)
        if (rtag2 .ge. rtag1) then
          if (tsec2 .gt. tsec1) then
            dtsec = tsec2-tsec1
            call secuhr (idstd, idmin, idsec, idhds, dtsec)
            idtag = int(rtag2-rtag1)
          else
            dtsec = 24.*3600.+tsec2-tsec1
            call secuhr (idstd, idmin, idsec, idhds, dtsec)
            if (idstd .eq. 24) then
              idstd = 0
              idtag = int(rtag2-rtag1)
            else
              idtag = int(rtag2-rtag1) - 1
            endif
          endif
        else
c          stop 'T1 > T2'
          if (tsec1 .gt. tsec2) then
            dtsec = tsec1-tsec2
            call secuhr (idstd, idmin, idsec, idhds, dtsec)
            idtag = int(rtag1-rtag2)
          else
            dtsec = 24.*3600.+tsec1-tsec2
            call secuhr (idstd, idmin, idsec, idhds, dtsec)
            if (idstd .eq. 24) then
              idstd = 0
              idtag = int(rtag1-rtag2)
            else
              idtag = int(rtag1-rtag2) - 1
            endif
          endif
          idtag = - idtag
          idstd = - idstd
          cminus = '-'
        endif
      endif
      return
      end

      subroutine plsec  (jhd1, jah1, mon1, tag1, std1, min1, sec1, hds1,
     &                   asec,
     &                   jhd2, jah2, mon2, tag2, std2, min2, sec2, hds2)
C-----------------------------------------------------------------------
C  Datum1 + sec  ergibt Datum2
C-----------------------------------------------------------------------
      integer*4 jhd1, jah1, mon1, tag1, std1, min1, sec1, hds1
      integer*4 jhd2, jah2, mon2, tag2, std2, min2, sec2, hds2
      real*8 asec, addsec, dsec1, hlp, tagsec
      integer*4 idtag

      external uhrsec, secuhr, addtag
      intrinsic nint, dmod

      addsec=asec
      jhd2 = jhd1
      tagsec = 24.*3600.
      addsec = dmod(addsec,tagsec)
      idtag = nint((asec-addsec)/tagsec)
      call uhrsec (std1, min1, sec1, hds1, dsec1)
      hlp = dsec1 + addsec
      if (hlp .gt. tagsec) then
        addsec = hlp - tagsec
        idtag  = idtag + 1
      elseif (hlp .lt. 0.) then
        addsec = hlp + tagsec
        idtag  = idtag - 1
      else
        addsec = hlp
      endif
      call addtag(jhd1, jah1, mon1, tag1, idtag, jhd2, jah2, mon2, tag2)
      call secuhr(std2, min2, sec2, hds2, addsec)
      return
      end

      subroutine pzeit  (jhd1, jah1, mon1, tag1, std1, min1, sec1, hds1,
     &                   idtag, idstd, idmin, idsec, idhds,
     &                   jhd2, jah2, mon2, tag2, std2, min2, sec2, hds2)
C-----------------------------------------------------------------------
C  Datum1 + Zeit ergibt Datum2
C-----------------------------------------------------------------------
      integer*4 jhd1, jah1, mon1, tag1, std1, min1, sec1, hds1
      integer*4 jhd2, jah2, mon2, tag2, std2, min2, sec2, hds2
      integer*4 idstd, idmin, idsec, idhds
      integer*4 idtag
      real*8 addsec, dsec1, hlp, tagsec

      external uhrsec, secuhr, addtag

      jhd2 = jhd1
      tagsec = 24.*3600.
      call uhrsec (idstd, idmin, idsec, idhds, addsec)
      call uhrsec (std1, min1, sec1, hds1, dsec1)
      hlp = dsec1 + addsec
      if (hlp .gt. tagsec) then
        addsec = hlp - tagsec
        idtag  = idtag + 1
      else
        addsec = hlp
      endif
      call addtag(jhd1, jah1, mon1, tag1, idtag, jhd2, jah2, mon2, tag2)
      call secuhr(std2, min2, sec2, hds2, addsec)
      return
      end

      subroutine addtag (ih1,ij1,im1,it1,idtag,ih2,ij2,im2,it2)

C-----------------------------------------------------------------------
C Berechnet  Datum2=Datum1+Tagesanzahl (idtag)
C-----------------------------------------------------------------------
      integer*4   ih1,ij1,im1,it1
      integer*4 jh2,jj2,jm2,jt2
      integer*4   ih2,ij2,im2,it2
      integer*4 IDTAG
      integer*4 JULDAY, jd

      external julday, caldat
      intrinsic int

      jh2=0
      jj2=0
      jm2=0
      jt2=0
      jd=julday(ih1,ij1,im1,it1)
     &   +int(idtag)
      call caldat(jd,jh2,jj2,jm2,jt2)
      ih2=int(jh2)
      ij2=int(jj2)
      im2=int(jm2)
      it2=int(jt2)
      return
      end

      subroutine uhrsec (std, min, sec, hds, tagsec)
C-----------------------------------------------------------------------
C  Umrechnung in sec (double precision!!)
C-----------------------------------------------------------------------
      integer*4 std, min, sec, hds
      real*8 tagsec

      intrinsic dble

      tagsec = dble(std)*3600.
      tagsec = tagsec + dble(min*60)
      tagsec = tagsec + dble(sec)
      tagsec = tagsec + dble(hds)/100.
      return
      end

      subroutine secuhr (std, min, sec, hds, tagsec)
C-----------------------------------------------------------------------
C  Umrechnung sec (double precision!!) in std, min, sec, hds
C-----------------------------------------------------------------------
      integer*4 std, min, sec, hds
      real*8 tagsec, hlp

      intrinsic aint, dble, nint

      hlp = tagsec/3600.
      std = aint(hlp)

      tagsec = tagsec - dble(std)*3600.
      hlp = tagsec/60.
      min = aint(hlp)

      tagsec = tagsec - dble(min)*60.
      hlp = tagsec
      sec = aint(hlp)

      tagsec = tagsec - dble(sec)
c     hds = nint(tagsec*100.)
      hds = aint(tagsec*100.)
      return
      end

      subroutine dat2str(jhd1, jah1, mon1, tag1, std1, min1, sec1, hds1,
     &                   outstr)
C-----------------------------------------------------------------------
      integer*4 jhd1, jah1, mon1, tag1, std1, min1, sec1, hds1
c laenger als 22 Stellen
      character*(*) outstr

      write(outstr(1:22),100)
  100 format ('  .  .       :  :  .  ')
  101   format('0',i1)
  102   format(i2)

      if (tag1 .lt. 10) then
        write(outstr(1:2),101) tag1
      else
        write(outstr(1:2),102) tag1
      endif
      if (mon1 .lt. 10) then
        write(outstr(4:5),101) mon1
      else
        write(outstr(4:5),102) mon1
      endif
      if (jhd1 .lt. 10) then
        write(outstr(7:8),101) jhd1
      else
        write(outstr(7:8),102) jhd1
      endif
      if (jah1 .lt. 10) then
        write(outstr(9:10),101) jah1
      else
        write(outstr(9:10),102) jah1
      endif
      if (std1 .lt. 10) then
        write(outstr(12:13),101) std1
      else
        write(outstr(12:13),102) std1
      endif
      if (min1 .lt. 10) then
        write(outstr(15:16),101) min1
      else
        write(outstr(15:16),102) min1
      endif
      if (sec1 .lt. 10) then
        write(outstr(18:19),101) sec1
      else
        write(outstr(18:19),102) sec1
      endif
      if (hds1 .lt. 10) then
        write(outstr(21:22),101) hds1
      else
        write(outstr(21:22),102) hds1
      endif
      return
      end

      subroutine str2dat(jhd1, jah1, mon1, tag1, std1, min1, sec1, hds1,
     &                   outstr)
C-----------------------------------------------------------------------
      integer*4 jhd1, jah1, mon1, tag1, std1, min1, sec1, hds1
c laenger als 22 Stellen
      character*(*) outstr

      read(outstr(1:22),100) tag1,mon1,jhd1,jah1,std1,min1,sec1,hds1
  100 format (i2,1x,i2,1x,i2,i2,1x,i2,1x,i2,1x,i2,1x,i2)
      return
      end


      subroutine dps2str(jhds, jahs, mons, tags, stds, mins, secs, hdss,
     &                   addsec, datstr)
c-----------------------------------------------------------------------
c   Datum plus Sekunden zu Datumsstring
c-----------------------------------------------------------------------
      integer*4 jhds, jahs, mons, tags, stds, mins, secs, hdss
      integer*4 jhda, jaha, mona, taga, stda, mina, seca, hdsa
      real*8 addsec
c laenger als 22 Stellen
      character*(*) datstr

      external plsec, dat2str

      call plsec   (jhds, jahs, mons, tags, stds, mins, secs, hdss,
     &              addsec,
     &              jhda, jaha, mona, taga, stda, mina, seca, hdsa)
      call dat2str (jhda, jaha, mona, taga, stda, mina, seca, hdsa,
     &              datstr)
      return
      end

      subroutine dsps2ds(dstrs, addsec, dstra)
c-----------------------------------------------------------------------
c   Datumstring plus Sekunden zu Datumsstring
c-----------------------------------------------------------------------
      integer*4 jhds, jahs, mons, tags, stds, mins, secs, hdss
      integer*4 jhda, jaha, mona, taga, stda, mina, seca, hdsa
      real*8 addsec
c laenger als 22 Stellen
      character*(*) dstrs, dstra

      external plsec, dat2str, str2dat

      call str2dat (jhds, jahs, mons, tags, stds, mins, secs, hdss,
     &              dstrs)
      call plsec   (jhds, jahs, mons, tags, stds, mins, secs, hdss,
     &              addsec,
     &              jhda, jaha, mona, taga, stda, mina, seca, hdsa)
      call dat2str (jhda, jaha, mona, taga, stda, mina, seca, hdsa,
     &              dstra)
      return
      end

      subroutine str2sad(jhds, jahs, mons, tags, stds, mins, secs, hdss,
     &                   datstr, dsec)
c-----------------------------------------------------------------------
c  Datumsstring zu Sekunden ab einem Datum
c-----------------------------------------------------------------------
      integer*4 jhds, jahs, mons, tags, stds, mins, secs, hdss
      integer*4 jhda, jaha, mona, taga, stda, mina, seca, hdsa
      real*8 dsec
c laenger als 22 Stellen
      character*(*) datstr

      external disec, str2dat

      call str2dat(jhda, jaha, mona, taga, stda, mina, seca, hdsa,
     &             datstr)
      call disec  (jhds, jahs, mons, tags, stds, mins, secs, hdss,
     &             jhda, jaha, mona, taga, stda, mina, seca, hdsa,
     &             dsec)
      return
      end

      subroutine dsds2ds(dstra, dstrs, dsec)
c-----------------------------------------------------------------------
c  Differenz in Sekunden zwischen zwei Datumsstrings (dstra-dstrs)
c-----------------------------------------------------------------------
      integer*4 jhds, jahs, mons, tags, stds, mins, secs, hdss
      integer*4 jhda, jaha, mona, taga, stda, mina, seca, hdsa
      real*8 dsec
c laenger als 22 Stellen
      character*(*) dstrs, dstra

      external disec, str2dat

      call str2dat(jhds, jahs, mons, tags, stds, mins, secs, hdss,
     &             dstrs)
      call str2dat(jhda, jaha, mona, taga, stda, mina, seca, hdsa,
     &             dstra)
      call disec  (jhds, jahs, mons, tags, stds, mins, secs, hdss,
     &             jhda, jaha, mona, taga, stda, mina, seca, hdsa,
     &             dsec)
      return
      end

      subroutine dayyear(jhds, jahs, mons, tags, stds, mins, secs, hdss,
     &                   addsec, tagnr)
c-----------------------------------------------------------------------
c   Datum plus Sekunden zu Tag im Jahr
c-----------------------------------------------------------------------
      integer*4 jhds, jahs, mons, tags, stds, mins, secs, hdss
      integer*4 jhda, jaha, mona, taga, stda, mina, seca, hdsa
      real*8 addsec
      integer*4 wochtag
      real jultag, wochnr, tagnr
      character*2 tagnam

      external plsec, julian

      call plsec   (jhds, jahs, mons, tags, stds, mins, secs, hdss,
     &              addsec,
     &              jhda, jaha, mona, taga, stda, mina, seca, hdsa)
      call julian(taga, mona, jhda, jaha,
     &            jultag, wochtag, tagnam, wochnr, tagnr)
      return
      end

      subroutine ds2diny(datstr,tagnr,tagstd)
c-----------------------------------------------------------------------
c   Datumstring zu Tag im Jahr
c-----------------------------------------------------------------------
      integer*4 jhda, jaha, mona, taga, stda, mina, seca, hdsa
      integer*4 wochtag
      real jultag, wochnr, tagnr, tagstd
      character*2 tagnam
c laenger als 22 Stellen
      character*(*) datstr

      external str2dat, julian
      intrinsic real

      call str2dat(jhda, jaha, mona, taga, stda, mina, seca, hdsa,
     &                   datstr)
      tagstd=real(stda)+real(mina)/60.+real(seca)/3600.
      call julian(taga, mona, jhda, jaha,
     &            jultag, wochtag, tagnam, wochnr, tagnr)
      return
      end

      SUBROUTINE caldat(julian,jh,yy,mm,id)
C-----------------------------------------------------------------------
C  Aus: Numerical Recipes, veraendert (INTEGER*4, int)
C   int, im Gegensatz zu INT, konvertiert immer in *4, waehrend INT
C   in das Format der Compile-option konvertiert!!!!!
C-----------------------------------------------------------------------
      INTEGER*4 id,iyyy,julian,mm,IGREG,jh,yy
      PARAMETER (IGREG=2299161)
      INTEGER*4 ja,jalpha,jb,jc,jd,je

      intrinsic int

      iyyy = int(jh*100+yy)
      if(julian.ge.IGREG)then
        jalpha=int(((julian-1867216)-0.25)/36524.25)
        ja=julian+1+jalpha-int(0.25*jalpha)
      else
        ja=julian
      endif
      jb=ja+1524
      jc=int(6680.+((jb-2439870)-122.1)/365.25)
      jd=365*jc+int(0.25*jc)
      je=int((jb-jd)/30.6001)
      id=jb-jd-int(30.6001*je)
      mm=je-1
      if(mm.gt.12)mm=mm-12
      iyyy=jc-4715
      if(mm.gt.2)iyyy=iyyy-1
      if(iyyy.le.0)iyyy=iyyy-1
      jh=int(iyyy*0.01+0.01)
      yy=int(iyyy)-jh*100
      return
      END

      FUNCTION julday(jh, yy, mm, id)
C-----------------------------------------------------------------------
C  Aus: Numerical Recipes, veraendert (INTEGER*4, int)
C   int, im Gegensatz zu INT, konvertiert immer in *4, waehrend INT
C   in das Format der Compile-option konvertiert!!!!!
C-----------------------------------------------------------------------
      INTEGER*4 julday,id,iyyy,mm,IGREG, jh, yy
c      PARAMETER (IGREG=15+31*(10+12*1582))
      PARAMETER (IGREG=588829)
      INTEGER*4 ja,jm,jy

      intrinsic int

      iyyy = int(jh*100+yy)
      jy=iyyy
      if (jy.eq.0) pause 'julday: there is no year zero'
      if (jy.lt.0) jy=jy+1
      if (mm.gt.2) then
        jm=mm+1
      else
        jy=jy-1
        jm=mm+13
      endif
      julday=int(365.25*jy)+int(30.6001*jm)+id+1720995
      if (id+31*(mm+12*iyyy).ge.IGREG) then
        ja=int(0.01*jy)
        julday=julday+2-ja+int(0.25*ja)
      endif
      return
      END

      SUBROUTINE JUL(IOP,EV,HO,NAP,ENAP)
C-----------------------------------------------------------------------
C   iop=0:  Eingabe:  EV    year
C                     HO    month
C                     NAP   day
C           Ausgabe:  ENAP  number of day in year
C-----------------------------------------------------------------------
C   Nur fuer ein vorgegebenes Jahr kann das Datum rueckgerechnet werden!
C-----------------------------------------------------------------------
C   iop=1:  Eingabe:  ENAP  number of day in year
C                     EV    year  (!!)
C           Ausgabe:  NAP   day
C                     HO    month
C-----------------------------------------------------------------------
      INTEGER*4 EV, HO, NAP, ENAP, NO(12)
      INTEGER*4 IOP, IN, JNAP, K, J

      intrinsic int, aint, real

      DATA NO/31,28,31,30,31,30,31,31,30,31,30,31/
      IN=INT(AINT(REAL(EV)/4.))*4-EV
      NO(2)=28
      IF(IN.EQ.0) NO(2)=29

      IF (IOP.EQ.1) THEN
        JNAP=ENAP
        DO 2 K=1,12
        JNAP=JNAP-NO(K)
        IF(JNAP.LE.0) GO TO 3
2       CONTINUE
        K=12
3       HO=K
        NAP=JNAP+NO(K)
      ELSEIF (IOP.EQ.0) THEN
        ENAP=0
        IF (HO .GT. 1) THEN
          DO 1 J=1,HO-1
1         ENAP=ENAP+NO(J)
        ENDIF
        ENAP=ENAP+NAP
      ENDIF
      RETURN
      END

      SUBROUTINE JULIAN(TT,MM,HH,JJ,RNDTT,ITAG,CTAA,WOJ,TAJ)
C     SUBROUTINE JULIAN(TT,MM,HH,JJ)
C
C     JULIANISCHER KALENDER
C
C     TT = TAG; MM = MONAT; JJ = JAHR; HH = VOLLES JAHRHUNDERT
C     AJ = AKTUELLES JAHR
C     LVJ = LETZTES VOLLES JAHR
C     KSJ = ANZAHL SCHALTJAHRE
C     LSJ = LETZTES SCHALTJAHR
C     NSJ = NŽCHSTES SCHALTJAHR
C     RNDLVJ = ANZAHL DER TAGE BIS LVJ
C     LM = LETZTER VOLLER MONAT
C     ML = 1D-FELD MONATSLŽNGEN
C     RNDLM = ANZAHL DER TAGE BIS LM
C     RNDTT = ANZAHL DER TAGE BIS TT
C     TAJ = TAGES-NR. DES AKTUELLEN JAHRES
C     WOJ = WOCHEN-NR. DES AKTUELLEN JAHRES
C     ITAG = NUMMER DES WOCHENTAGS (0-7)
C     CTAG = 1D-FELD WOCHENTAGSNAMEN
C
      INTEGER*4 TT,MM,JJ,HH,AJ,LVJ,KSJ,LSJ,LM,ML(0:12)
      real TAJ
      real WOJ
      integer*4 ITAG, NSJ, L, IWH
      real RNDTT, RNDLVJ, RNDLM, HILF, WH, RH

      CHARACTER*2 CTAG(0:7),CTAA

      intrinsic int, nint, real, amod

      DATA ML/0,31,28,31,30,31,30,31,31,30,31,30,31/
      DATA CTAG/'SA','SO','MO','DI','MI','DO','FR','SA'/
C
      AJ=HH*100 + JJ
      LVJ=AJ-1
      KSJ=INT(LVJ/4)
      LSJ=KSJ*4
      NSJ=LSJ+4
      IF(AJ.EQ.NSJ) THEN
        ML(2)=29
      ELSE
        ML(2)=28
        IF (MM.EQ.2.AND.TT.EQ.29) THEN
           STOP 'UP JULIAN: 29. Februar existiert nicht !'
        END IF
      END IF
      RNDLVJ=REAL(LSJ)*365.25 + REAL(LVJ-LSJ)*365.
      LM=MM-1
      TAJ=0.0
      DO 1 L=0,LM
         TAJ=TAJ+REAL(ML(L))
    1 CONTINUE
      RNDLM=RNDLVJ+TAJ
      TAJ=TAJ+REAL(TT)
      WOJ=INT(TAJ/7.)+1.
      RNDTT=RNDLM+REAL(TT)
      HILF=AMOD(RNDTT,35000.)
      WH=HILF/7.
      IWH=INT(WH)
      RH=WH-REAL(IWH)
      ITAG=NINT(RH*7.)
      CTAA=CTAG(ITAG)
C
c     PRINT '(T2,3(A,I2),I2)','       DATUM: ',TT,'.',MM,'.',HH,JJ
c     PRINT '(T2,A,I4)',' VOLLES JAHR: ',LVJ
c     PRINT '(T2,A,I4)','L.SCHALTJAHR: ',LSJ
c     PRINT '(T2,A,I4)','N.SCHALTJAHR: ',NSJ
c     PRINT '(T2,A,I2)',' VOLLER MON.: ',LM
c     PRINT '(T2,A,F7.0)','TAGE BIS DATUM: ',RNDTT
c     PRINT '(T2,A,I1)',' WOCHENTAG-NR.: ',ITAG
c     PRINT '(T2,A,A2)','  WOCHENTAG : ',CTAA
c     PRINT '(T2,A,F3.0)','WO. IM JAHR : ',WOJ
c     PRINT '(T2,A,F4.0)','TAG IM JAHR : ',TAJ
C
      RETURN
      END
