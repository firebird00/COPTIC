c___c___c___c___c___c___c___c___c___c___c___c___c___c___c___c___c___c___
c
c This code is copyright(c) (2003-5) Ian H Hutchinson hutch@psfc.mit.edu
c
c  It may be used freely with the stipulation that any scientific or
c scholarly publication concerning work that uses the code must give an
c acknowledgement referring to the papers I.H.Hutchinson, Plasma Physics
c and Controlled Fusion, vol 44, p 1953 (2002), vol 45, p 1477 (2003).
c  The code may not be redistributed except in its original package.
c
c No warranty, explicit or implied, is given. If you choose to build
c or run the code, you do so at your own risk.
c
c Version 2.6 Aug 2005.
c___c___c___c___c___c___c___c___c___c___c___c___c___c___c___c___c___c___
c***********************************************************************
c Restartable gasdev based on NR.
      FUNCTION gasdev(ireset)
      include 'ran1com.f'
      if(ireset.lt.0) gd_iset=0
      if(gd_iset.ne.1)then
 1       continue
         v1=2.*ran1(1)-1.
         v2=2.*ran1(1)-1.
         r=v1**2+v2**2
        if(r.ge.1..or.r.eq.0.)go to 1
        fac=sqrt(-2.*log(r)/r)
        gd_gset=v1*fac
        gasdev=v2*fac
        gd_iset=1
      else
        gasdev=gd_gset
        gd_iset=0
      endif
      return
      end
c**********************************************************************
c      FUNCTION RAN1(IDUM)
c      ran1=ran0(idum)
c      end
c**********************************************************************
      FUNCTION ran0(IDUM)
      save
c Version of July 06 that removes the argument dependence.
      DIMENSION V(97)
      DATA IFF /0/
      IF(IFF.EQ.0)THEN
        IFF=1
        DO 11 J=1,97
          DUM=RANd()
11      CONTINUE
        DO 12 J=1,97
          V(J)=RANd()
12      CONTINUE
        Y=RANd()
      ENDIF
c IHH hack to prevent errors when Y=1. Was 97.
      J=1+INT(96.9999*Y)
      IF(J.GT.97.OR.J.LT.1)then
         write(*,*)'RAN0 error: j=',j,'  y=',y
c         PAUSE 'RAN0 problem'
         j=1
      endif
      Y=V(J)
      RAN0=Y
      V(J)=RANd()
      RETURN
      END
c**********************************************************************
      real FUNCTION ran1(IDUM)
c Returns a uniform random deviate between 0 and 1.
c Reentrant version of ran1 makes the state visible in common.
c Get explicit 
      implicit none
      real ran1
      integer idum
c Common here requires separation of processes for reentrancy.
c So this is not thread safe.
      include 'ran1com.f'
      real RM1,RM2
      integer M1,M2,M3,ic1,ic2,ic3,ia1,ia2,ia3
      save
c      DIMENSION Rrnd(97)
      PARAMETER (M1=259200,IA1=7141,IC1=54773,RM1=3.8580247E-6)
      PARAMETER (M2=134456,IA2=8121,IC2=28411,RM2=7.4373773E-6)
      PARAMETER (M3=243000,IA3=4561,IC3=51349)
c Can't do auto initialize. Have to do it by hand.
c      DATA IFF /0/
c      IF (IDUM.LT.0.OR.IFF.EQ.0) THEN
      IF (IDUM.LT.0) THEN
c        IFF=1
        IrX1=MOD(IC1-IDUM,M1)
        IrX1=MOD(IA1*IrX1+IC1,M1)
        IrX2=MOD(IrX1,M2)
        IrX1=MOD(IA1*IrX1+IC1,M1)
        IrX3=MOD(IrX1,M3)
        DO 11 JRC=1,97
          IrX1=MOD(IA1*IrX1+IC1,M1)
          IrX2=MOD(IA2*IrX2+IC2,M2)
          Rrnd(JRC)=(FLOAT(IrX1)+FLOAT(IrX2)*RM2)*RM1
 11     CONTINUE
c Tell gasdev to reset.
        gd_iset=0
      ENDIF
      IrX1=MOD(IA1*IrX1+IC1,M1)
      IrX2=MOD(IA2*IrX2+IC2,M2)
      IrX3=MOD(IA3*IrX3+IC3,M3)
      JRC=1+(97*IrX3)/M3
      if(JRC.GT.97.OR.JRC.LT.1)then
         write(*,*)'RAN1 Error!'
      endif
      RAN1=Rrnd(JRC)
      Rrnd(JRC)=(FLOAT(IrX1)+FLOAT(IrX2)*RM2)*RM1
      RETURN
      END
c

c********************************************************************
c Given a monotonic function Q(x) on a 1-D grid x=1..nq, 
c   solve Q(x)=y for x.
c That is, invert Q to give x=Q^-1(y).
      subroutine invtfunc(Q,nq,y,x)
      implicit none
      integer nq
      real Q(nq)
      real y,x
c
      integer iqr,iql,iqx
      real Qx,Qr,Ql
      Ql=Q(1)
      Qr=Q(nq)
      iql=1
      iqr=nq
      if((y-Ql)*(y-Qr).gt.0.) then
c Value is outside the range.
         x=0
         return
      endif
 200  if(iqr-iql.eq.1)goto 210
      iqx=(iqr+iql)/2
      Qx=Q(iqx)
c      write(*,*)y,Ql,Qx,Qr,iql,iqr
c Formerly .lt. which is an error.
      if((Qx-y)*(Qr-y).le.0.) then
         Ql=Qx
         iql=iqx
      else
         Qr=Qx
         iqr=iqx
      endif
      goto 200
 210  continue
c Now iql and iqr, Ql and Qr bracket Q
      x=(y-Ql)/(Qr-Ql)+iql
c      if(x.gt.float(nq))then
c         write(*,*)'invtfn error',x,nq,y,q(1),q(nq),
c     $     ql,qr,iql,iqr,qx,iqx
c         write(*,*)'q=',q
c      endif
      end
c********************************************************************
C complementary error function from NR.
      FUNCTION ERFCC(X)
      Z=ABS(X)      
      T=1./(1.+0.5*Z)
      ERFCC=T*EXP(-Z*Z-1.26551223+T*(1.00002368+T*(.37409196+
     *    T*(.09678418+T*(-.18628806+T*(.27886807+T*(-1.13520398+
     *    T*(1.48851587+T*(-.82215223+T*.17087277)))))))))
      IF (X.LT.0.) ERFCC=2.-ERFCC
      RETURN
      END

