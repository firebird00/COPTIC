c********************************************************************
      subroutine spherefsect(npdim,xp1,xp2,iobj,ijbin,sd,fraction)
c Given npdimensional sphere, nf_map infobj, find the intersection of
c the line joining xp1, xp2 with it.  Use the 3dcom.f data to determine
c the flux bin to which that point corresponds and return the bin index
c in ijbin (zero-based), and the direction in which the sphere was
c crossed in sd. If no intersection is found return sd=0. Return
c the fractional position between xp1 and xp2 in frac
      integer npdim
      real xp1(npdim),xp2(npdim)
      integer iobj,ijbin
      real sd,fraction
      real tiny,onemtiny
      parameter (tiny=1.e-5,onemtiny=1.-2.*tiny)
      include '3dcom.f'
c 3D here.
      parameter (nds=3)
      real x12(nds)

      if(npdim.ne.nds)stop 'Wrong dimension number in spherefsect'
      infobj=nf_map(iobj)
      fraction=1.
      ida=0
      call sphereinterp(npdim,ida,xp1,xp2,
     $     obj_geom(ocenter,iobj),obj_geom(oradius,iobj),fraction
     $     ,f2,sd,C,D)
      if(sd.eq.0 .or. fraction-1..ge.tiny .or. fraction.lt.0.)then
c This section can be triggered inappropriately if rounding causes
c fraction to be >=1 when really the point is just outside or on the 
c surface. Then we get a sd problem message.
         fraction=1.
         sd=0.
         return
      endif
c This code decides which of the nf_posno for this object
c to update corresponding to this crossing, and then update it. 
c Calculate normalized intersection coordinates.
      do i=1,npdim
         x12(i)=((1.-fraction)*xp1(i)+fraction*xp2(i)
     $        -obj_geom(ocenter+i-1,iobj))
     $        /obj_geom(oradius+i-1,iobj)
      enddo
c Bin by cos(theta)=x12(3) uniform grid in first nf_dimension. 
c ibin runs from 0 to N-1 cos = -1 to 1.
      ibin=int(nf_dimlens(nf_flux,infobj,1)*(onemtiny*x12(3)+1.)*0.5)
      psi=atan2(x12(2),x12(1))
c jbin runs from 0 to N-1 psi = -pi to pi.
      jbin=int(nf_dimlens(nf_flux,infobj,2)
     $     *(0.999999*psi/3.1415926+1.)*0.5)
      ijbin=ibin+jbin*nf_dimlens(nf_flux,infobj,1)
      if(ijbin.gt.nf_posno(1,infobj))then
         write(*,*)'ijbin error in spherefsect'
         write(*,*)infobj,ijbin,nf_posno(1,infobj),ibin,jbin
     $        ,nf_dimlens(nf_flux,infobj,1),nf_dimlens(nf_flux,infobj,2)
     $        ,x12(3),obj_geom(ocenter+2,iobj),xp1(3),xp2(3)
     $        ,fraction
      endif
      end
c*********************************************************************
      subroutine cubefsect(npdim,xp1,xp2,iobj,ijbin,sd,fraction)
c Given a coordinate-aligned cube object iobj. Find the point of
c intersection of the line joining xp1,xp2, with it, and determine the
c ijbin to which it is therefore assigned, and the direction it is
c crossed (sd=+1 means inward from 1 to 2). 
c Intersection fractional distance from xp1 to xp2 returned.

c The cube is specified by center and radii!=0 (to faces.) which define
c two planes (\pm rc) in each coordinate. Inside corresponds to between
c these two planes, i.e. x-xc < |rc|. We define the facets of the cube
c to be the faces (planes) in the following order:
c +rc_1,+rc_2,+rc_3,-rc_1,-rc_2,-rc_3 which is the order of the
c coefficients of the adjacent vectors. 

      integer npdim,iobj,ijbin
      real xp1(npdim),xp2(npdim)
      real sd
      include '3dcom.f'
      real xn1(ns_ndims),xn2(ns_ndims)
      sd=0.
      ig1=inside_geom(npdim,xp1,iobj)
      ig2=inside_geom(npdim,xp2,iobj)
      if(ig1.eq.1 .and. ig2.eq.0)then
c xp1 inside & 2 outside
         inside=0
      elseif(ig2.eq.1 .and. ig1.eq.0)then
c xp2 inside & 1 outside
         inside=1
      else
c Both inside or outside. (Used to be neither inside). Any intersection
c will be disallowed. This means we cut off any such edges of the
c cube. But actually for coordinate-aligned cube there are no
c problematic non-normal intersections.
         fraction=1.
         return
      endif
c In direction sd
      sd=2*inside-1.
c Package from here by converting into normalized position
      do i=1,npdim
         xn1(i)=(xp1(i)-obj_geom(ocenter+i-1,iobj))
     $        /obj_geom(oradius+i-1,iobj)
         xn2(i)=(xp2(i)-obj_geom(ocenter+i-1,iobj))
     $        /obj_geom(oradius+i-1,iobj)
      enddo
c And calling the unit-cube version.
      if(inside.eq.0)then
         call cubeexplt(npdim,xn1,xn2,ijbin,iobj,fraction)
      else
         call cubeexplt(npdim,xn2,xn1,ijbin,iobj,fraction)
         fraction=1.-fraction
      endif
c Code Diagnostic:
c      do i=1,3
c         xd(i)=(1.-fraction)*xp1(i)+ fraction*xp2(i)
c         xd2(i)=(1.-fraction)*xp2(i)+ fraction*xp1(i)
c      enddo
c      write(*,'(7f8.4)')fraction,xp1,xp2,xd,xd2
      end
c*********************************************************************
      subroutine pllelofsect(npdim,xp1,xp2,iobj,ijbin,sd,fraction)
c Given a general parallelopiped object iobj. Find the point
c of intersection of the line joining xp1,xp2, with it, and determine
c the ijbin to which it is therefore assigned, and the direction it is
c crossed (sd=+1 means inward from 1 to 2).

c The object is specified by center and three vectors pqr. Each of npdim
c pairs of parallel planes consists of the points: +-p + c_q q + c_r r.
c Where p is one of the three base (covariant) vectors and qr the
c others, and c_q are real coefficients.  Inside corresponds to between
c these two planes, i.e. contravariant coefficients <1. We define the
c facets of the cube to be the faces (planes) in the following order:
c +v_1,+v_2,+v_3,-v_1,-v_2,-v_3. 
c Then within each face the facet indices are in cyclic order. But that
c is determined by the cubeexplt code.
      integer npdim,iobj,ijbin
      real xp1(npdim),xp2(npdim)
      real sd
      include '3dcom.f'
      real xn1(pp_ndims),xn2(pp_ndims)
      sd=0.

c      write(*,*)'Pllelo',npdim,xp1,xp2,iobj,pp_ndims
      ins1=0
      ins2=0
      do j=1,pp_ndims
         xn1(j)=0.
         xn2(j)=0.
c Contravariant projections.
         do i=1,npdim
c Cartesian coordinates.
            ii=(ocenter+i-1)
            xc=obj_geom(ii,iobj)
c xn1, xn2 are the contravariant coordinates with respect to the center.
            ji=(pp_contra+pp_ndims*(j-1)+i-1)
c            write(*,*)'ji',ji
            xn1(j)=xn1(j)+(xp1(i)-xc)*obj_geom(ji,iobj)
            xn2(j)=xn2(j)+(xp2(i)-xc)*obj_geom(ji,iobj)
         enddo
         if(abs(xn1(j)).ge.1.)ins1=1
         if(abs(xn2(j)).ge.1.)ins2=1
      enddo
c ins1,2 indicate inside (0) or outside (1) for each point. 
c In direction sd
      sd=2*ins1-1.
c And calling the unit-cube version.
c      write(*,*)'Calling cubeexplt',xn1,xn2
      if(ins1.eq.0 .and. ins2.eq.1)then
         call cubeexplt(npdim,xn1,xn2,ijbin,iobj,fraction)
      elseif(ins2.eq.0 .and. ins1.eq.1)then
         call cubeexplt(npdim,xn2,xn1,ijbin,iobj,fraction)
         fraction=1.-fraction
      else
         fraction=1.
         return
      endif
      end
c*********************************************************************
      subroutine cylfsect(npdim,xp1,xp2,iobj,ijbin,sdmin,fmin)
c Master routine for calling cylusect after normalization of cyl.
      integer npdim,iobj,ijbin
      real xp1(npdim),xp2(npdim)
      real sdmin
      include '3dcom.f'
      real xn1(pp_ndims),xn2(pp_ndims)

      ida=int(obj_geom(ocylaxis,iobj))
      do i=1,pp_ndims
         ii=mod(i-ida+2,pp_ndims)+1
         xn1(ii)=(xp1(i)-obj_geom(ocenter+i-1,iobj))
     $        /obj_geom(oradius+i-1,iobj)
         xn2(ii)=(xp2(i)-obj_geom(ocenter+i-1,iobj))
     $        /obj_geom(oradius+i-1,iobj)
      enddo
      call cylusect(npdim,xn1,xn2,iobj,ijbin,sdmin,fmin)
      end
c*********************************************************************
      subroutine cylgfsect(npdim,xp1,xp2,iobj,ijbin,sd,fraction)
c Given a general cylinder object iobj. Find the point
c of intersection of the line joining xp1,xp2, with it, and determine
c the ijbin to which it is therefore assigned, and the direction it is
c crossed (sd=+1 means inward from 1 to 2).

c The object is specified by center and three contravariant vectors.
c When the position relative to the center is dotted into the contra
c variant vector it yields the coordinate relative to the unit cylinder,
c whose third component is the axial direction. 

      integer npdim,iobj,ijbin
      real xp1(npdim),xp2(npdim)
      real sd
      include '3dcom.f'
      real xn1(pp_ndims),xn2(pp_ndims)

c j refers to transformed coordinates in which it is unit cyl
      do j=1,pp_ndims
         xn1(j)=0.
         xn2(j)=0.
c Contravariant projections.
         do i=1,npdim
c i refers to the Cartesian coordinates.
            xc=obj_geom(ocenter+i-1,iobj)
c xn1, xn2 are the contravariant coordinates with respect to the center.
            ji=(pp_contra+pp_ndims*(j-1)+i-1)
c            write(*,*)'ji',ji
            xn1(j)=xn1(j)+(xp1(i)-xc)*obj_geom(ji,iobj)
            xn2(j)=xn2(j)+(xp2(i)-xc)*obj_geom(ji,iobj)
         enddo
      enddo
c Now xn1,2 are the coordinates relative to the unit cylinder.      
      fraction=1.
c Shortcut
      z1=xn1(pp_ndims)
      z2=xn2(pp_ndims)
      if((z1.ge.1..and.z2.ge.1).or.(z1.le.-1..and.z2.le.-1.))return
c Call the unit-cylinder code.
      call cylusect(npdim,xn1,xn2,iobj,ijbin,sd,fraction)
c      write(*,*)'cylusect return',ijbin,fraction

      end
c*********************************************************************
c*********************************************************************
      subroutine sphereinterp(npdim,ida,xp1,xp2,xc,rc,f1,f2,sd,C,D)
c Given two different npdim dimensioned vectors xp1,xp2,and a sphere
c center xc radius rc, find the intersection of the line joining x1,x2,
c with the sphere and return it as the value of the fraction f1 of
c x1->x2 to which this corresponds, chosen always positive if possible, 
c and closest to 0. The other intersection fraction in f2.
c Also return the direction of crossing in sd, and the fractional
c radial distance^2 outside the sphere of the two points in C and D. 
c (positive means inward from x1 to x2). If there is no intersection,
c return fraction=1., sd=0.  If ida is non-zero then form the radius
c only over the other dimensions.  In that case the subsurface (circle)
c is the figure whose intersection is sought.
      integer npdim,ida
      real xp1(npdim),xp2(npdim),xc(npdim),rc(npdim)
      real sd,f1,f2,C,D
c
      real x1,x2,A,B
c Prevent a singularity if the vectors coincide.
      A=1.e-25
      B=0.
      C=-1.
      D=-1.
c x1 and x2 are the coordinates in system in which sphere 
c has center 0 and radius 1.
      ni=npdim
      if(ida.ne.0)ni=npdim-1
      do ii=1,ni
         i=mod(ida+ii-1,npdim)+1
         xci=xc(i)
         rci=rc(i)
         x1=(xp1(i)-xci)/rci
         x2=(xp2(i)-xci)/rci
         A=A+(x2-x1)**2
         B=B+x1*(x2-x1)
         C=C+x1**2
         D=D+x2**2
      enddo
c Crossing direction from x1 to intersection
      sd=sign(1.,C)
      disc=B*B-A*C
      if(disc.ge.0.)then
         disc=sqrt(disc)
c (A always positive)
         if(C.gt.0. .and. B.lt.0) then
c Discrim<|B|. Can take minus sign and still get positive. 
            f1=(-B-disc)/A
            f2=(-B+disc)/A
         else
c If B positive or C negative must use plus sign. 
            f1=(-B+disc)/A
            f2=(-B-disc)/A
         endif
      else
c         write(*,*)'Sphere-crossing discriminant negative.',A,B,C
         sd=0.
         f1=1.
         f2=1.
         return
      endif
      end
c***********************************************************************
      subroutine cubeexplt(npdim,xp1,xp2,ijbin,iobj,fmin)
c For a unit cube, center 0 radii 1, find the intersection of line
c xp1,xp2 with it and return the relevant flux index ijbin.
c xp1 must be always inside the cube.
      real xp1(npdim),xp2(npdim)
      integer ijbin,iobj
      include '3dcom.f'
      integer idebug
      imin=0
      idebug=0

      fn=0.
      fmin=100.
      do i=1,2*npdim
         im=mod(i-1,npdim)+1
c First half of the i's are negative. Second half positive.
         xc1=(((i-1)/npdim)*2-1)
         xd1=(xp1(im)-xc1)
         xd2=(xp2(im)-xc1)
         if(xd1.lt.0. .neqv. xd2.lt.0)then
c Crossed this plane
            fn=xd1/(xd1-xd2)
c At fraction fn (always positive) from the inside point.
            if(fn.lt.fmin)then
               fmin=fn
               imin=i
c         write(*,*)i,xc1,' xd1,xd2=',xd1,xd2,fmin
c     $              ,xp1(im),xp2(im)
c     $        ,(1.-fmin)*xd1+fmin*xd2
c     $        ,(1.-fmin)*xp1(im)+fmin*xp2(im)
            endif
         endif
      enddo
c Now the minimum fraction is in fmin, which is the crossing point.
c imin contains the face-index of this crossing. Indexing within the
c face on equal spaced grid whose numbers have been read into
c obj_geom(ofn.,iobj):
      infobj=nf_map(iobj)
      ibstep=1
      ibin=0
      if(idebug.eq.1)write(*,'(''Position'',$)')
      do i=1,npdim-1
c The following defines the order of indexation. ofn1 is the next highest
c cyclic index following the face index. So on face 1 or 4 the other
c two indices on the face are 2,3. But on face 2,5 they are 3,1.
         k=mod(mod(imin-1,3)+1+i-1,npdim)+1
         xk=(1.-fmin)*xp1(k)+fmin*xp2(k)
c Not sure that this is the best order for the plane. Think! :
c         xcr=(1.-xk)*.5
c This has xcr run from 0 to 1 as xk goes from -1. to +1. :
         xcr=(1.+xk)*.5
         if(idebug.eq.1)write(*,'(i2,f7.2,i5,i5,'',''$)')k,xcr
     $        ,nf_dimlens(nf_flux,infobj,k)
     $        ,int(nf_dimlens(nf_flux,infobj,k)*(0.999999*xcr))
         ibin=ibin+ibstep*
     $        int(nf_dimlens(nf_flux,infobj,k)*(0.999999*xcr))
         ibstep=ibstep*nf_dimlens(nf_flux,infobj,k)
      enddo
c Now we have ibin equal to the face-position index, and ibstep equal
c to the face-position size. Add the face-offset for imin. This is
c tricky for unequal sized faces. So we need to have stored it. 
      ijbin=ibin+nf_faceind(nf_flux,infobj,imin)
      if(idebug.eq.1)write(*,*)'Ending cubeexplt',ijbin
     $     ,nf_faceind(nf_flux,infobj,imin),imin
c That's it.
      end
c*********************************************************************
      subroutine cylusect(npdim,xp1,xp2,iobj,ijbin,sdmin,fmin)
c Find the point of intersection of the line joining xp1,xp2, with the
c UNIT cylinder, and determine the ijbin to which it is therefore
c assigned, and the direction it is crossed (sdmin=+1 means inward from
c 1 to 2). The 1-axis is where theta is measured from and the 3-axis
c is the axial direction.
c The facets of the cylinder are the end faces -xr +xr, and the curved
c side boundary. 3 altogether.  The order of faces is bottom, side, top.
      
      integer npdim,iobj,ijbin
      real xp1(npdim),xp2(npdim)
      real sdmin
      include '3dcom.f'
c 3D here.
      parameter (nds=3)
      real x12(nds)
      real fn(4),zrf(4),sdf(4)
      real xc(nds),rc(nds)
      data xc/0.,0.,0./rc/1.,1.,1./

      ida=3
c First, return if both points are beyond the same axial end.
      z1=xp1(ida)
      z2=xp2(ida)
      xd=z2-z1
      fmin=1.
      sdmin=0.
      if((z1.gt.1. .and. z2.gt.1.).or.
     $     (-z1.gt.1. .and. -z2.gt.1))return
      sds=0.
c Find the intersection (if any) with the circular surface.
      call sphereinterp(npdim,ida,xp1,xp2,
     $     xc,rc,fn(1),fn(2),sds,d1,d2)
      if(sds.ne.0)then
c Directions are both taken to be that of the closest. 
c A bit inconsistent but probably ok. 
         sdf(1)=sds
         sdf(2)=sds
         zrf(1)=(1.-fn(1))*xp1(ida)+fn(1)*xp2(ida)
         zrf(2)=(1.-fn(2))*xp1(ida)+fn(2)*xp2(ida)
      else
c No radial intersections
         zrf(1)=2.
         zrf(2)=2.
      endif
c Find the axial intersection fractions with the end planes.
      if(xd.ne.0)then
         fn(3)=(1.-z1)/xd
         sdf(3)=-1.
         if(z1.gt.1.)sdf(3)=1.
         fn(4)=(-1.-z1)/xd
         sdf(4)=-1.
         if(z1.lt.-1.)sdf(4)=1.
         zrf(3)=0.
         zrf(4)=0.
         do k=1,npdim
            if(k.ne.ida)then
               xkg1=(1.-fn(3))*xp1(k)+fn(3)*xp2(k)
               zrf(3)=zrf(3)+(xkg1)**2
               xkg2=(1.-fn(4))*xp1(k)+fn(4)*xp2(k)
               zrf(4)=zrf(4)+(xkg2)**2
            endif
         enddo
      else
c Pure radial difference. No end-intersections anywhere.
         zrf(3)=2.
         zrf(4)=2.
      endif
c Now we have 4 possible fractions fn(4). Two or none of those
c are true. Truth is determined by abs(zrf(k))<=1. Choose closest.
      fmin=10.
      kmin=0
      do k=1,4
         if(abs(zrf(k)).le.1)then
            if(fn(k).ge.0. .and. fn(k).lt.fmin)then
               kmin=k 
               fmin=fn(k)
            endif
         endif
      enddo
      if(fmin.gt.1.)then
c No crossing
         sdmin=0.
         fmin=1.
         return
      else
         sdmin=sdf(kmin)
         if(kmin.le.2)then
c radial crossing
            imin=0.
         else
c axial crossing
            imin=-1.
            zida=(1.-fmin)*z1+fmin*z2
            if(zida.gt.0.)imin=1.
         endif
      endif

c Now the minimum fraction is in fmin, which is the crossing point.
c imin contains the face-index of this crossing. -1,0, or +1.
c Calculate normalized intersection coordinates.
      do i=1,npdim
         x12(i)=(1.-fmin)*xp1(i)+fmin*xp2(i)
      enddo
c Calculate r,theta,z (normalized) relative to the ida direction as z.
      z=x12(ida)
      theta=atan2(x12(mod(ida+1,npdim)+1),x12(mod(ida,npdim)+1))
      r2=0.
      do i=1,npdim-1
         k=mod(ida+i-1,npdim)+1
         r2=r2+x12(k)**2
      enddo
c      write(*,'(a,7f7.4,3i3)')'r2,theta,z,x12,fmin,imin'
c     $     ,r2,theta,z,x12,fmin,imin
c End blocks are of size nr x nt, and the curved is nt x nz.
c 3-D only here. 
      infobj=nf_map(iobj)
      ijbin=0.
      if(imin.ne.0)then
c Ends
         if(imin.eq.1)then
c offset by (nr+nz)*nt
            ijbin=(nf_dimlens(nf_flux,infobj,1)
     $           +nf_dimlens(nf_flux,infobj,3))
     $           *nf_dimlens(nf_flux,infobj,2)
         endif
c Uniform mesh in r^2 normalized. 
         ir=int(nf_dimlens(nf_flux,infobj,1)*(0.999999*r2))
         it=int(nf_dimlens(nf_flux,infobj,2)
     $     *(theta/3.1415927+1.)*0.5)
         ijbin=ijbin+ir+it*nf_dimlens(nf_flux,infobj,1)
      else
c Side. Offset to this facet nr*nt:
         ijbin=nf_dimlens(nf_flux,infobj,1)*nf_dimlens(nf_flux,infobj,2)
         it=int(nf_dimlens(nf_flux,infobj,2)
     $     *(theta/3.1415927+1.)*0.5)
         iz=int(nf_dimlens(nf_flux,infobj,3)*(0.999999*z+1.)*0.5)
c Index in order theta,z
         ijbin=ijbin+it+iz*nf_dimlens(nf_flux,infobj,2)
      endif
c      write(*,'(6f8.4,3i3)')xp1,xp2,ir,it,iz
      end