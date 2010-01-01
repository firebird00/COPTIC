c**********************************************************************
c This file gives examples of boundary and faddu setting for sormpi.
c The bdyset routine can be called anything, and name passed.
c      subroutine bdyset(ndims,ifull,iuds,cij,u,q)
c      call bdysetnull(ndims,ifull,iuds,cij,u,q)
      subroutine bdyset(ndims,ifull,iuds,cij,u,q)
      call bdysetfree
c      call bdysetnull
      end
c**********************************************************************
      subroutine bdysetnull()
c (ndims,ifull,iuds,cij,u,q)
c     Null version
      end
c**********************************************************************
      subroutine bdyset3sl(ndims,ifull,iuds,cij,u,q)
      integer ndims,ifull(ndims),iuds(ndims)
      real cij(*),u(*),q(*)
c Specify external the boundary setting routine.
      external bdy3slope 
c sets the derivative to zero on boundaries 3.
      ipoint=0
      call mditerate(ndims,ifull,iuds,bdy3slope,u,ipoint)

      end
c**********************************************************************
      subroutine bdysetfree(ndims,ifull,iuds,cij,u,q)

      integer ndims,ifull(ndims),iuds(ndims)
      real cij(*),u(*),q(*)
c Specify external the boundary setting routine.
      external bdyslopeDh,bdyslopescreen
      include 'plascom.f'

      common /slpcom/slpD
      ipoint=0
c      slpD=-1.
c      call mditerate(ndims,ifull,iuds,bdyslopeDh,u,ipoint)
c      slpD=debyelen/sqrt(1.+1./(Ti+vd*vd))
c      call mditerate(ndims,ifull,iuds,bdyslopescreen,u,ipoint)
      slpD=1.e-6
      call mditerate(ndims,ifull,iuds,bdyslopeDh,u,ipoint)

      end
c**********************************************************************
c     L(u) + f(u) = q(x,y,...), 
c     where L is a second order elliptical differential operator 
c     represented by a difference stencil of specified coefficients,
c     f is some additional function, and q is the "charge density".
c f is exp(u) here for Boltzmann electrons and densities normalized
c to unity at infinity.
      real function faddu(u,fprime)
      real u,fprime
      fprime=exp(u)
      faddu=fprime
      end
c************************************************************************
      subroutine bdy3slope(inc,ipoint,indi,ndims,iused,u)
c Version of bdyroutine that sets derivative=0 on 3-boundary.
      integer ipoint,inc
      integer indi(ndims),iused(ndims)
      real u(*)

c Structure vector needed for finding adjacent u values.
c Can't be passed here because of mditerate argument conventions.
      parameter (mdims=10)
      integer iLs(mdims+1)
      common /iLscom/iLs

c Algorithm: take steps of 1 in all cases except
c when on a lower boundary face of dimension 1. 
c There the step is iused(1)-1.
      inc=1
      do n=ndims,1,-1
c------------------------------------------------------------------
c Between here and ^^^ is boundary setting. Adjust upper and lower.
         if(indi(n).eq.0)then
c The exception in step. Do not change!:
            if(n.eq.1)inc=iused(1)-1
c On lower boundary face
            u(ipoint+1)=0.
            if(n.eq.3)then
c First derivative is zero:
               u(ipoint+1)=u(ipoint+1+iLs(n))
            endif
c Second derivative is zero:
c               u(ipoint+1)=2.*u(ipoint+1+iLs(n))-u(ipoint+1+2*iLs(n))
            goto 101
         elseif(indi(n).eq.iused(n)-1)then
c On upper boundary face
            u(ipoint+1)=0.
            if(n.eq.3) u(ipoint+1)=u(ipoint+1-iLs(n))
            goto 101
         endif
c^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
      enddo
      write(*,*)'BDY3s Error. We should not be here',n,ipoint,indi
      stop
 101  continue
c      write(*,*)'indi,inc,iused,ipoint',indi,inc,iused,ipoint
      end
c************************************************************************
      subroutine bdyslopeDh(inc,ipoint,indi,ndims,iused,u)
c Version of bdyroutine that sets logarithmic 'radial' gradient
c equal to D
      integer ipoint,inc
      integer indi(ndims),iused(ndims)
      real u(*)

c Structure vector needed for finding adjacent u values.
c Can't be passed here because of mditerate argument conventions.
      parameter (mdims=10)
      integer iLs(mdims+1)
      common /iLscom/iLs

      include 'meshcom.f'
      common /slpcom/slpD
      D=slpD
c Algorithm: take steps of 1 in all cases except when on a lower
c boundary face of dimension 1 (and not other faces).  There the step is
c iused(1)-1.
c------------------------------------------------------------------
c Between here and ^^^ is boundary setting. Adjust upper and lower.
      r2=0.
      fac=0.
      ipd=ipoint
      do n=1,ndims
c BC is du/dr=D u/r     in the form   (ub-u0)=  D*(ub+u0)*f/(1-f)
c where f = Sum_j[(xb_j+x0_j)dx_j]/(2*rm^2), dx=xb-x0
c Thus ub=u0(1-f-D.f)/(1-f+D.f)
c Here we are using radii from position (0,0,..)
         x=xn(ixnp(n)+1+indi(n))
         r2=r2+x*x
         if(indi(n).eq.0)then
c On lower boundary face
            dx=xn(ixnp(n)+1)-xn(ixnp(n)+2)
            ipd=ipd+iLs(n)
            fac=fac+x*dx
            if(n.eq.1)then
c The exception in step. Do not change!
               inc=iused(1)-1
            else
               inc=1
            endif
         elseif(indi(n).eq.iused(n)-1)then
c On upper boundary face
            dx=xn(ixnp(n)+1+indi(n))-xn(ixnp(n)+indi(n))
            ipd=ipd-iLs(n)
            fac=fac+x*dx
            inc=1
         endif
      enddo
      if(ipd.eq.ipoint)then
         write(*,*)'BDY function error; we should not be here'
         stop
      else
         fac=fac/(2.*r2)
         u(ipoint+1)=u(ipd+1) *(1.-fac+D*fac)/(1.-fac-D*fac)
      endif
c^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
c      write(*,*)'indi,inc,iused,ipoint',indi,inc,iused,ipoint
      end
c**********************************************************************
c The following is obsolete and (somewhat) incorrect.
c************************************************************************
      subroutine bdyslopeDhold(inc,ipoint,indi,ndims,iused,u)
c Version of bdyroutine that sets logarithmic 'radial' gradient
c equal to D
      integer ipoint,inc
      integer indi(ndims),iused(ndims)
      real u(*)

c Structure vector needed for finding adjacent u values.
c Can't be passed here because of mditerate argument conventions.
      parameter (mdims=10)
      integer iLs(mdims+1)
      common /iLscom/iLs

      real x(mdims)
      include 'meshcom.f'
      common /slpcom/slpD

      r2=r2indi(ndims,indi,x)
      D=slpD

c Algorithm: take steps of 1 in all cases except
c when on a lower boundary face of dimension 1 (and not other faces). 
c There the step is iused(1)-1.
      inc=1
      do n=ndims,1,-1
c------------------------------------------------------------------
c Between here and ^^^ is boundary setting. Adjust upper and lower.
         if(indi(n).eq.0)then
c The exception in step. Do not change!:
            if(n.eq.1)inc=iused(1)-1
c On lower boundary face
c du/dn=u:
c            u(ipoint+1)=.8*u(ipoint+1+iLs(n))
c du/dn=D r.n u/ r^2
            dx=xn(ixnp(n)+2)-xn(ixnp(n)+1)
            fac=(1.+0.5*dx/x(n))*r2*2./(D*x(n)*dx)
c            write(*,*)n,dx,xn(ixnp(n)+1),fac,r2
c Centered BC:
c (u2-u1)/dx=(u2+u1)/2 *D*(x1+x2)/2 /rm^2  put fac=2*rm^2/D xm dx
c  u2(fac-1.)=u1(fac+1)
            u(ipoint+1)=u(ipoint+1+iLs(n))*(fac-1.)/(1.+fac)
            goto 101
         elseif(indi(n).eq.iused(n)-1)then
c On upper boundary face
c du/dn=u:
c            u(ipoint+1)=.8*u(ipoint+1-iLs(n))
c du/dn=D r.n u/ r^2
            dx=-(xn(ixnp(n)+1+indi(n))-xn(ixnp(n)+indi(n)))
            fac=(1.+0.5*dx/x(n))*r2*2./(D*x(n)*dx)
            u(ipoint+1)=u(ipoint+1-iLs(n))*(fac-1.)/(1.+fac)
            goto 101
         endif
c^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
      enddo
      write(*,*)'BDY Error. We should not be here',n,ipoint,indi
      stop
 101  continue
c      write(*,*)'indi,inc,iused,ipoint',indi,inc,iused,ipoint
      end
c**********************************************************************
c************************************************************************
      subroutine bdyslopescreen(inc,ipoint,indi,ndims,iused,u)
c Version of bdyroutine that sets logarithmic 'radial' gradient
c equal to that for a Debye screened potential: -(1+r/lambdas)
      integer ipoint,inc
      integer indi(ndims),iused(ndims)
      real u(*)

c Structure vector needed for finding adjacent u values.
c Can't be passed here because of mditerate argument conventions.
      parameter (mdims=10)
      integer iLs(mdims+1)
      common /iLscom/iLs

      real x(mdims)
      include 'meshcom.f'
      common /slpcom/slpD

      r2=r2indi(ndims,indi,x)
      r1=sqrt(r2)
      D=slpD

c Algorithm: take steps of 1 in all cases except
c when on a lower boundary face of dimension 1. 
c There the step is iused(1)-1.
      inc=1
      do n=ndims,1,-1
c------------------------------------------------------------------
c Between here and ^^^ is boundary setting. Adjust upper and lower.
         if(indi(n).eq.0)then
c The exception in step. Do not change!:
            if(n.eq.1)inc=iused(1)-1
c On lower boundary face
c du/dn= -(1.+r/D) r.n u/ r^2
            dx=xn(ixnp(n)+2)-xn(ixnp(n)+1)
            fac=(1.+0.5*dx/x(n))*r2*2./(-(1.+r1/D)*x(n)*dx)
c            write(*,*)n,dx,xn(ixnp(n)+1),fac,r2
c Centered BC:
c (u2-u1)/dx=(u2+u1)/2 *S*(x1+x2)/2 /rm^2  put fac=2*rm^2/S xm dx
c  u2(fac-1.)=u1(fac+1)
            u(ipoint+1)=u(ipoint+1+iLs(n))*(fac-1.)/(1.+fac)
            goto 101
         elseif(indi(n).eq.iused(n)-1)then
c On upper boundary face
c du/dn=-(1.+r/D) r.n u/ r^2
            dx=-(xn(ixnp(n)+1+indi(n))-xn(ixnp(n)+indi(n)))
            fac=(1.+0.5*dx/x(n))*r2*2./(-(1.+r1/D)*x(n)*dx)
            u(ipoint+1)=u(ipoint+1-iLs(n))*(fac-1.)/(1.+fac)
            goto 101
         endif
c^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
      enddo
      write(*,*)'BDY Error. We should not be here',n,ipoint,indi
      stop
 101  continue
c      write(*,*)'indi,inc,iused,ipoint',indi,inc,iused,ipoint
      end
c**********************************************************************
c Return the radius squared and the vector position of point indexed as
c indi(ndims), relative to the center of the coordinate ranges,
c using information in meshcom.
      function r2indi(ndims,indi,x)
      integer indi(ndims)
      real x(ndims)
      include 'meshcom.f'
      if(ndims.ne.ndims_mesh)then
         write(*,*)'rindi dimension mismatch',ndims,ndims_mesh
         stop
      endif
      r2indi=0.
      do i=1,ndims
         x(i)=xn(ixnp(i)+indi(i)+1)-(xn(ixnp(i)+1)+xn(ixnp(i+1)))/2.
         r2indi=r2indi+x(i)**2
      enddo
      end
