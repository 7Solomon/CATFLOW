      subroutine ggcross(x0,y0,x1,y1,x2,y2,x3,y3,x,y)
c
c    x,y ist der Schnittpunkt zweier Geraden P0-P1 und P2-P3
c    (die nicht parallel/identisch sein duerfen!!)
c
      real*8 x0,y0,x1,y1,x2,y2,x3,y3,x,y,eps

      intrinsic abs

      eps = 0.0001

      if ((abs(x0-x1).lt.eps).or.(abs(x2-x3).lt.eps).or.
     &    (abs(y0-y1).lt.eps).or.(abs(y2-y3).lt.eps)) then
        if (abs(x0-x1).lt.eps) then
          x = x0
          if (abs(y2-y3).lt.eps) then
            y = y2
          else
            y = (x-x2)*(y2-y3)/(x2-x3)+y2
          endif
        endif
        if (abs(y0-y1).lt.eps) then
          y = y0
          if (abs(x2-x3).lt.eps) then
            x = x2
          else
            x = (y-y2)*(x2-x3)/(y2-y3)+x2
          endif
        endif
        if (abs(x2-x3).lt.eps) then
          x = x2
          if (abs(y0-y1).lt.eps) then
            y = y1
          else
            y = (x-x0)*(y0-y1)/(x0-x1)+y0
          endif
        endif
        if (abs(y2-y3).lt.eps) then
          y = y2
          if (abs(x0-x1).lt.eps) then
            x = x0
          else
            x = (y-y0)*(x0-x1)/(y0-y1)+x0
          endif
        endif
      else
        y = ( y0+ (x2-x0-y2*(x2-x3)/(y2-y3)) *(y0-y1)/(x0-x1) )/
     &      (1-(x2-x3)/(y2-y3)*(y0-y1)/(x0-x1))
        x = ( x0+ (y2-y0-x2*(y2-y3)/(x2-x3)) *(x0-x1)/(y0-y1) )/
     &      (1-(y2-y3)/(x2-x3)*(x0-x1)/(y0-y1))
      endif

      return
      end

      double precision function strahl(x1,x2,s1,s2,s)
C-----------------------------------------------------------------------
      real*8 x1,x2,s1,s2,s 
 	strahl = x1 + (s-s1)/(s2-s1)*(x2-x1)
      return
      end


      double precision function strahl2(x1,x2,s1,s2,s,s_b)
C-----------------------------------------------------------------------
      real*8 x1,x2,s1,s2,s, s_b
      strahl2 = x1 + ((s-s1)/(s2-s1))**s_b*(x2-x1)
      return
      end

