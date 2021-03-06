!**********************************************************************
! This file gives examples of boundary setting for sormpi.
! The bdyset routine can be called anything, and name passed.
      subroutine bdyset(ndims,ifull,iuds,cij,u,q)
      call bdysetnull
!      call bdysetfree
      end
!**********************************************************************
      subroutine bdysetnull()
! (ndims,ifull,iuds,cij,u,q)
!     Null version
      end
!**********************************************************************
      subroutine bdyset3sl(ndims,ifull,iuds,cij,u,q)
      integer ndims,ifull(ndims),iuds(ndims)
      real cij(*),u(*),q(*)
! Specify external the boundary setting routine.
      external bdy3slope 
! sets the derivative to zero on boundaries 3.
      ipoint=0
      call mditerarg(bdy3slope,ndims,ifull,iuds,ipoint,u)
      end
!************************************************************************
      subroutine bdy3slope(inc,ipoint,indi,ndims,iLs,iused,u)
! Version of bdyroutine that sets derivative=0 on 3-boundary.
      integer ipoint,inc
      integer indi(ndims),iused(ndims)
      real u(*)

! Structure vector needed for finding adjacent u values.
      integer iLs(ndims+1)

! Algorithm: take steps of 1 in all cases except
! when on a lower boundary face of dimension 1. 
! There the step is iused(1)-1.
      inc=1
      do n=ndims,1,-1
!------------------------------------------------------------------
! Between here and ^^^ is boundary setting. Adjust upper and lower.
         if(indi(n).eq.0)then
! The exception in step. Do not change!:
            if(n.eq.1)inc=iused(1)-1
! On lower boundary face
            u(ipoint+1)=0.
            if(n.eq.3)then
! First derivative is zero:
               u(ipoint+1)=u(ipoint+1+iLs(n))
            endif
! Second derivative is zero:
!               u(ipoint+1)=2.*u(ipoint+1+iLs(n))-u(ipoint+1+2*iLs(n))
            goto 101
         elseif(indi(n).eq.iused(n)-1)then
! On upper boundary face
            u(ipoint+1)=0.
            if(n.eq.3) u(ipoint+1)=u(ipoint+1-iLs(n))
            goto 101
         endif
!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
      enddo
      write(*,*)'BDY3s Error. We should not be here',n,ipoint,indi
      stop
 101  continue
!      write(*,*)'indi,inc,iused,ipoint',indi,inc,iused,ipoint
      end
!************************************************************************
      subroutine bdyslopeDh(inc,ipoint,indi,ndims,iLs,iused,u)
! Version of bdyroutine that sets logarithmic 'radial' gradient
! equal to D
      integer ipoint,inc
      integer indi(ndims),iused(ndims)
      real u(*)

! Structure vector needed for finding adjacent u values.
      integer iLs(ndims+1)

      include 'meshcom.f'
      common /slpcom/slpD,islp
      D=slpD
! Algorithm: take steps of 1 in all cases except when on a lower
! boundary face of dimension 1 (and not other faces).  There the step is
! iused(1)-1.
!------------------------------------------------------------------
! Between here and ^^^ is boundary setting. Adjust upper and lower.
      r2=0.
      fac=0.
      ipd=ipoint
      do n=1,ndims
! BC is du/dr=D u/r     in the form   (ub-u0)=  D*(ub+u0)*f/(1-f)
! where f = Sum_j[(xb_j+x0_j)dx_j]/(2*rm^2), dx=xb-x0
! Thus ub=u0(1-f-D.f)/(1-f+D.f)
! Here we are using radii from position (0,0,..)
         x=xn(ixnp(n)+1+indi(n))
         r2=r2+x*x
         if(indi(n).eq.0)then
! On lower boundary face
            dx=xn(ixnp(n)+1)-xn(ixnp(n)+2)
            ipd=ipd+iLs(n)
            fac=fac+x*dx
            if(n.eq.1)then
! The exception in step. Do not change!
               inc=iused(1)-1
            else
               inc=1
            endif
         elseif(indi(n).eq.iused(n)-1)then
! On upper boundary face
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
!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
!      write(*,*)'indi,inc,iused,ipoint',indi,inc,iused,ipoint
      end
!**********************************************************************
! Return the radius squared and the vector position of point indexed as
! indi(ndims), relative to the center of the coordinate ranges,
! using information in meshcom.
      function r2indi(ndims,indi,x)
      integer indi(ndims)
      real x(ndims)
      include 'meshcom.f'
      if(ndims.ne.ndims)then
         write(*,*)'rindi dimension mismatch',ndims,ndims
         stop
      endif
      r2indi=0.
      do i=1,ndims
         x(i)=xn(ixnp(i)+indi(i)+1)-(xn(ixnp(i)+1)+xn(ixnp(i+1)))/2.
         r2indi=r2indi+x(i)**2
      enddo
      end
!**********************************************************************
      subroutine orbit3plot()
! Dummy orbit plot routine 
      end
!**********************************************************************
