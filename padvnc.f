c Particle advancing routine
      subroutine padvnc(ndims,cij,u,iLs)
c If ninjcomp (in partcom) is non-zero, then we are operating in a mode
c where the number of reinjections at each timestep is prescribed.
c Otherwise we are using a fixed number npart of particles.
c
c Number of dimensions: ndims
      integer ndims
c Storage size of the mesh arrays.
c      real cij(2*ndims+1,nx,ny,nz)
c      real u(nx,ny,nz)
      real cij(*),u(*)

c Array structure vectors: (1,nx,nx*ny,nx*ny*nz)
      integer iLs(ndims+1)

c sormesh provides ixnp, xn, the mesh spacings. (+ndims_mesh)
      include 'meshcom.f'
c Alternatively they could be passed, but we'd then need parameter.
      include 'myidcom.f'
      include '3dcom.f'
c Include this only for testing with Coulomb field.
      include 'plascom.f'
c Local storage
      integer ixp(ndims_mesh)
      real field(ndims_mesh)
      real xfrac(ndims_mesh)
c Make this always last to use the checks.
      include 'partcom.f'

      if(ndims.ne.ndims_mesh)
     $        stop 'Padvnc incorrect ndims number of dimensions'
      ic1=2*ndims+1
      ndimsx2=2*ndims
c Initialize. Set reinjection potential. We start with zero reinjections.
c      write(*,*)'Setting averein in padvnc.',phirein
      call avereinset(phirein)
      phirein=0
      nrein=0
      nlost=0
c      ninner=0
      iocthis=0
c Get rid of usage of iregion_part.
c      iregion=iregion_part
      n_part=0
c At most do over all particle slots. But generally we break earlier.
      do i=1,n_partmax
         dtprec=dt
         dtpos=dt
 100     continue
c If this particle slot is occupied.
         if(if_part(i).ne.0)then
c Disentangle from old approach (inefficiently).
            iregion=insideall(ndims,x_part(1,i))
c            iregion=insidemask(ndims,x_part(1,i))
c Subcycle start.
 101        continue
c Use dtaccel for acceleration. May be different from dt if there was
c a reinjection (or collision).
            dtaccel=0.5*(dt+dtprec)
c Check the fraction data is not stupid and complain if it is.
            if(x_part(ndimsx2+1,i).eq.0. .and.
     $           x_part(ndimsx2+2,i).eq.0. .and.
     $           x_part(ndimsx2+3,i).eq.0.) then
               write(*,*)'Zero fractions',i,ioc_part,if_part(i)
     $              ,nrein,ninjcomp
            endif
c---------------------------------
            if(.true.)then
c Get the ndims field components at this point. 
c We only use x_part information for location. So we need to pass
c the region information.
            do idf=1,ndims
               call getfield(
     $              ndims,cij(ic1),u,iLs
     $              ,xn(ixnp(idf)+1)
     $              ,idf
     $              ,x_part(ndimsx2+1,i)
     $              ,imaskregion(iregion),field(idf))
            enddo
c--------------------------------
            else
c Testing with pure coulomb field from phip potential at r=1.
               r2=0.
               do idf=1,ndims
                  r2=r2+x_part(idf,i)**2
               enddo
               r3=sqrt(r2)**3
               do idf=1,ndims
                  field(idf)=x_part(idf,i)*phip/r3
               enddo
            endif
c--------------------------------
c Accelerate          
            do j=4,6
               x_part(j,i)=x_part(j,i)+field(j-3)*dtaccel
            enddo
c Move
            do j=1,3
               x_part(j,i)=x_part(j,i)+x_part(j+3,i)*dtpos
            enddo          

            inewregion=insideall(ndims,x_part(1,i))
c            if(inewregion.ne.iregion) then
            if(.not.linregion(ibool_part,ndims,x_part(1,i)))then
c We left the region. 
c Testing only:
c               if(inewregion.eq.3)ninner=ninner+1
               call tallyexit(i,inewregion-iregion)
c Reinject if we haven't exhausted complement.
               if(ninjcomp.eq.0 .or. nrein.lt.ninjcomp)then
                  call reinject(x_part(1,i),ilaunch)
                  if_part(i)=1
c Find where we are, since we don't yet know?
c Might not be needed if we insert needed information in reinject,
c which might be less costly. (Should be something other than iregion?)
                  call partlocate(i,iLs,iu,ixp,xfrac,irg)
                  dtpos=dtpos*ran1(myid)
                  dtprec=0.
                  nlost=nlost+1
                  nrein=nrein+ilaunch
                  phi=getpotential(u,cij,iLs,x_part(2*ndims+1,i)
     $                 ,imaskregion(irg),2)
                  phirein=phirein+ilaunch*phi
                  call diaginject(x_part(1,i))
c Complete reinjection by advancing by random remaining.
                  goto 101
               else
                  if_part(i)=0
               endif
            else
c The standard exit point for a particle that is active
               iocthis=i
               n_part=n_part+1
            endif
         elseif(ninjcomp.ne.0.and.nrein.lt.ninjcomp)then
c An unfilled slot. Fill it if we need to.
               call reinject(x_part(1,i),ilaunch)
               if_part(i)=1
c Find where we are, since we don't yet know?
c Might not be needed if we insert needed information in reinject,
               call partlocate(i,iLs,iu,ixp,xfrac,irg)
               dtpos=dtpos*ran1(myid)
               dtprec=0.
               nlost=nlost+1
               nrein=nrein+ilaunch
               phi=getpotential(u,cij,iLs,x_part(2*ndims+1,i)
     $                 ,imaskregion(irg),2)
               phirein=phirein+ilaunch*phi
               call diaginject(x_part(1,i))
c Complete reinjection by advancing by random remaining.
c               goto 101
c Silence warning of jump to different block by jumping outside instead
c gives the same result as 101.
               goto 100
         elseif(i.ge.ioc_part)then
c We do not need to reinject new particles, and
c this slot is higher than all previously handled. There are no
c more active particles above it. So break
            goto 102
         endif
c 
         if(i.le.norbits.and. if_part(i).ne.0)then
            iorbitlen(i)=iorbitlen(i)+1
            xorbit(iorbitlen(i),i)=x_part(1,i)
            yorbit(iorbitlen(i),i)=x_part(2,i)
            zorbit(iorbitlen(i),i)=x_part(3,i)
         endif
      enddo
 102  continue
      if(ninjcomp.ne.0 .and. nrein.lt.ninjcomp)then
         write(*,*)'WARNING: Exhausted n_partmax=',n_partmax,
     $        '  before ninjcomp=',ninjcomp,' . Increase n_partmax?'
      endif
      ioc_part=iocthis
c      write(*,*)'iocthis=',iocthis

c Finished this particle step. Calculate the average reinjection 
c potential
      if(nrein.gt.0)then
         phirein=phirein/nrein
c         if(myid.eq.0)
c         write(*,'(a,f12.6,$)')' Phirein=',phirein
c         write(*,*)' nlost=',nlost,' nrein=',nrein,' ninner=',ninner
         if(phirein.gt.0.)then
c            if(myid.eq.0)write(*,*)'PROBLEM: phirein>0:',phirein
            phirein=0.
         endif
      else
         write(*,*)'No reinjections'
      endif
      end
c***********************************************************************
      subroutine partlocate(i,iLs,iu,ixp,xfrac,iregion)

c Locate the particle numbered i (from common partcom) 
c in the mesh (from common meshcom).
c Return the offset of the base of its cell in iu.
c Return the integer cell-base coordinates in ixp(ndims)
c Return the fractions of cell width at which located in xfrac(ndims)
c Return the region identifier in iregion.
c Store the mesh position into common partcom (x_part).

c meshcom provides ixnp, xn, the mesh spacings. (+ndims_mesh)
      include 'meshcom.f'
      parameter (ndimsx2=ndims_mesh*2)
      integer i,iu,iregion
      integer iLs(ndims_mesh+1)
      integer ixp(ndims_mesh)
      real xfrac(ndims_mesh)

      include 'partcom.f'

      iregion=insideall(ndims_mesh,x_part(1,i))
      iu=0
      do id=1,ndims_mesh
c Offset to start of dimension-id-position array.
         ioff=ixnp(id)
c xn is the position array for each dimension arranged linearly.
c Find the index of xprime in the array xn:
         ix=interp(xn(ioff+1),ixnp(id+1)-ioff,x_part(id,i),xm)
         xfrac(id)=xm-ix
         x_part(ndimsx2+id,i)=xm
         ixp(id)=ix
c should be ix-1
         iu=iu+(ix-1)*iLs(id)
      enddo
      
      end
c***************************************************************
      real function getnullpot()
      getnullpot=0.
      end
