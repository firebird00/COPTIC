c**********************************************************************
c Do a single relaxation.
c Attempt to make this of general dimension. Not yet finished.
      subroutine sorrelaxgen(isor_k,ndims,iLs,idims,iuds,cij,u,q,
     $     laddu,faddu,oaddu,relax,rdelta,umin,umax)
c General number of dimensions ndims call.
c iLs is dimensions structure, cij is really (2*ndims,idims(1),...)
      integer ndims
      integer iLs(ndims+1),idims(ndims),iuds(ndims)
      real cij(*),u(*),q(*)
      parameter (imds=10,imds2=2*imds)
c Offset to adjacent points in stencil.
      integer iind(imds2)
c laddu true if there's additional function faddu
      logical laddu
c oaddu is maximum relative weight of faddu term
      real oaddu

      integer indi(imds),ind1(imds),iused(imds)
      logical lfirst
      data lfirst/.true./
      save

      if(ndims.gt.imds)then
         write(*,*)'sorrelax error: too many dimensions',ndims
         return
      endif
      if(lfirst)then
         do i=1,ndims
            do j=1,2
               iind(i+j-1)=(1.-2.*mod(j+1,2))*iLs(i)
            enddo
         enddo
      endif


      addu=0.
      daddu=0.

c Cell step.
      inc=2
c We exclude the outer boundary by decreasing used length and offsetting.
      ipoint=0
      do id=1,ndims
         iused(id)=iuds(id)-2
         ipoint=ipoint+iLs(id)
         indi(id)=0
      enddo
c Hard-wired red-black relaxation order. isor_k odd => block is odd;
c odd meaning that (1,1,...) is active. 
      km=mod(isor_k+1,2)
      if(km.eq.0)then
c Odd start
      else
c Even start
         ipoint=ipoint+1
         indi(1)=indi(1)+1
      endif

c Starting dimension
      n=1
c Iteration over the multidimensional array. 
 101  continue
c      write(*,'(''('',i1,i4,'') '',$)')n,indi(n)
      if(indi(n).gt.iused(n)-1)then
c     Overflow. Subtract off enough (inm) of next dimension.
         inm=0
 102     inm=inm+1
         ipoint=ipoint+iLs(n+1)-iused(n)*iLs(n)
         indi(n)=indi(n)-iused(n)
         if(indi(n).gt.iused(n)-1)goto 102
c Increment the next level.
 103     n=n+1
         if(n.gt.ndims)goto 201
         indi(n)=indi(n)+inm
         goto 101
      elseif(n.gt.1)then
c We've carried and cleared an increment.
c Return stepwise to base level
         n=n-1
         goto 101
      else
c We're at the base level and have succeeded in incrementing.
c Do whatever we need to and increment indi(1) and ipoint
c         write(*,'(a,8i8)')'ipoint=',ipoint,(indi(i),i=1,ndims)

c We build in correction of the increment here for red-black
c to change the parity. We have to remember the previous indis.
         ic=0
         do i=ndims,2,-1
            if(indi(i).gt.ind1(i))then
c     we've carried
               ic=ic+(i-1)
c     write(*,*)'increment',ic
            endif
c     Remember prior.
            ind1(i)=indi(i)
         enddo
         if(mod(ic,2).ne.0) then
            iaj=(1-2*mod(indi(1),2))
            indi(1)=indi(1)+iaj
            ipoint=ipoint+iaj
         endif

c Start of treatment
         dnum=q(ipoint+1)
         dden=0.
         do ic=1,2*ndims
            icind=2*ndims*ipoint+ic
            dden=dden+cij(icind)
            dnum=dnum+cij(icind)*u(ipoint+1+iind(ic))
         enddo
         if(dden.eq.0)then
            write(*,*)'sorelax error: i,j,dden,cij',i,j,dden,
     $           (cij(2*ndims*ipoint+ic),ic=1,2*ndims)
            stop
         endif
         if(laddu) then
            addu=faddu(u(ipoint+1),daddu)
c     relative weight of f term versus L term. Use max for next iteration.
            raddu=abs(daddu/dden)
            if(raddu.gt.oaddu) oaddu=5.*raddu
            dden=dden+daddu
            dnum=dnum-addu
         endif
         delta=relax*(dnum/dden-u(ipoint+1))
         if(abs(delta).gt.abs(rdelta))rdelta=delta
         uij=u(ipoint+1)+delta
         u(ipoint+1)=uij
         if(uij.lt.umin)umin=uij
         if(uij.gt.umax)umax=uij
c End of treatment.

         indi(1)=indi(1)+inc
         ipoint=ipoint+inc
         goto 101
      endif

 201  continue
c Reached the end.


      end
