c*****************************************************************
c Initialize with zero 3d objects.
      block data com3dset
      include '3dcom.f'
      data ngeomobj/0/
      end
c**********************************************************************
      subroutine readgeom(filename)
c Read the geometric data about objects from the file filename
      character*(*) filename
      character*128 cline
      include '3dcom.f'
c Common data containing the object geometric information. 
c Each object, i < 64 has: type, data(odata).
c      integer ngeomobjmax,odata,ngeomobj
c      parameter (ngeomobjmax=31,odata=16)
c      real obj_geom(odata,ngeomobjmax)
c      common /objgeomcom/ngeomobj,obj_geom


c Zero the obj_geom data.
      do j=1,odata
         do i=1,ngeomobjmax 
            obj_geom(odata,ngeomobjmax)=0.
         enddo
      enddo
c Read
      open(1,file=filename,status='old',err=101)
      iline=1
c First line must be the number of dimensions.
      read(1,'(a)',end=902)cline
      read(cline,*,err=901)nd

c Loop over lines of the input file.
 1    iline=iline+1
      read(1,'(a)',end=902)cline
      if(cline(1:1).eq.'#') goto 1
      if(cline(1:6).eq.'      ') goto 1

      read(cline,*,err=901)type
c Use only lower byte.
      itype=type
      type=itype - 256*(itype/256)
      ngeomobj=ngeomobj+1
      if(type.eq.1.)then
         read(cline,*,err=901,end=801)
     $        (obj_geom(k,ngeomobj),k=1,1+2*nd+3)
 801     write(*,*)ngeomobj,' Spheroid',
     $        (obj_geom(k,ngeomobj),k=1,1+2*nd+3)
c         write(*,*)
      elseif(type.eq.2.)then
         read(cline,*,err=901,end=802)
     $        (obj_geom(k,ngeomobj),k=1,1+2*nd+3)
 802     write(*,*)ngeomobj,' Cuboid',
     $        (obj_geom(k,ngeomobj),k=1,1+2*nd+3)
      elseif(type.eq.3.)then
         read(cline,*,err=901,end=803)
     $        (obj_geom(k,ngeomobj),k=1,1+2*nd+2+3)
 803     write(*,*)ngeomobj,' Cylinder',
     $        (obj_geom(k,ngeomobj),k=1,1+2*nd+2+3)
      elseif(type.eq.4.)then
         read(cline,*,err=901,end=804)
     $        (obj_geom(k,ngeomobj),k=1,1+nd*(1+nd)+3)
 804     write(*,*)ngeomobj,' General Cuboid/Parallelepiped'
         write(*,*)(obj_geom(k,ngeomobj),k=1,1+nd*(1+nd)+3)
      endif
      goto 1

 901  write(*,*)'Readgeom error reading line',iline,':'
      write(*,*)cline
      
 902  continue
      return

 101  write(*,*) 'Readgeom File ',filename,' could not be opened.'
      stop

      end
c****************************************************************
      subroutine spheresect(id,ipm,ndims,indi,rc,xc,fraction,dp)
c For mesh point indi() find the nearest intersection of the leg from
c this point to the adjacent point in dimension id, direction ipm, with
c the ndims-dimensional spheroid of semi-radii rc(ndims), center xc.
c
c Return the fractional distance in fraction (1 for no intersection),
c and total mesh spacing in dp, so that bdy distance is fraction*dp.
      integer id,ipm,ndims
      integer indi(ndims)
      real xc(ndims),rc(ndims)
      real fraction,dp
      include 'meshcom.f'
      A=0.
      B=0.
      C=-1.
      D=-1.
c x1 and x2 are the coordinates in system in which sphere has radius 1.
      do i=1,ndims
         ix1=indi(i)+ixnp(i)+1
         x1=(xn(ix1)-xc(i))/rc(i)
         x2=x1
         if(i.eq.id)then
            ix2=ix1+ipm
            x2=(xn(ix2)-xc(i))/rc(i)
            A=A+(x2-x1)**2
            B=B+x1*(x2-x1)
            dp=abs(x2-x1)*rc(i)
         endif
         C=C+x1**2
         D=D+x2**2
      enddo
      fraction=1.
c This condition tests for a sphere crossing.
      if(D.ne.0. .and. D*C.le.0.)then
         if(B.ge.0. .and. A*C.le.0) then
            fraction=(-B+sqrt(B*B-A*C))/A
         elseif(B.lt.0. .and. A*C.ge.0)then
            fraction=(-B-sqrt(B*B-A*C))/A
         endif
c That should exhaust the possibilities.
      endif
      end
c****************************************************************
      function insideall(ndims,x)
c For an ndims-dimensional point x, return the integer insideall
c consisting of bits i=1-31 that are zero or one according to whether
c the point x is outside or inside object i.
      integer ndims
      real x(ndims)
c Common object geometric data.
      include '3dcom.f'
c
      insideall=0
      do i=1,ngeomobj
         ii=inside_geom(ndims,x,i)
         insideall=insideall+ii*2**(i-1)
      enddo
c      if(insideall.ne.0) write(*,*)
c     $     'ngeomobj=',ngeomobj,' insideall=',insideall,x
c Hack for testing
c      insideall=min(insideall,2)

      end
c*****************************************************************
      function inside_geom(ndims,x,i)
c Return integer 0 or 1 according to whether ndims-dimensional point x
c is outside or inside object number i. Return 0 for non-existent object.
      integer ndims,i
      real x(ndims)

c Common object geometric data.
      include '3dcom.f'
      
      inside_geom=0
      if(i.gt.ngeomobj) return

      itype=obj_geom(1,i)
c Use only bottom 8 bits:
      itype=itype-256*(itype/256)
      if(itype.eq.0)then
         return

      elseif(itype.eq.1)then
c Coordinate-Aligned Spheroid data : center(ndims), semi-axes(ndims) 
         r2=0
         do k=1,ndims
            r2=r2+((x(k)-obj_geom(1+k,i))/obj_geom(1+ndims+k,i))**2
         enddo
         if(r2.lt.1.) inside_geom=1

      elseif(itype.eq.2)then
c Coordinate-Aligned Cuboid data: low-corner(ndims), high-corner(ndims)
         do k=1,ndims
            xk=x(k)
            xl=obj_geom(1+k,i)
            xh=obj_geom(1+ndims+k,i)
            if((xk-xl)*(xh-xk).lt.0) return
         enddo
         inside_geom=1

      elseif(itype.eq.3)then
c Coordinate-Aligned Cylinder data:  Face center(ndims), 
c Semi-axes(ndims), Axial coordinate, Signed Axial length.
         ic=obj_geom(1+2*ndims+1,i)
         xa=(x(ic)-obj_geom(1+ic,i))
         if(xa*(obj_geom(1+2*ndims+2,i)-xa).lt.0.) return
         r2=0.
         do k=1,ndims
            if(k.ne.ic)
     $         r2=r2+((x(k)-obj_geom(1+k,i))/obj_geom(1+ndims+k,i))**2
         enddo
c         write(*,*)'Cyl. ic=',ic,' r2=',r2,' x=',x
         if(r2.lt.1.) inside_geom=1

      elseif(itype.eq.4)then
c General Cuboid data: Origin corner(ndims), vectors(ndims,ndims) 
c to adjacent corners. Is equivalent to 
c General Parallelepiped, where vectors are the face normals of
c length equal to the distance to the opposite face.
         do k=1,ndims
            proj=0.
            plen=0
            do j=1,ndims
               proj=proj+(x(j)-obj_geom(1+j,i))*obj_geom(1+ndims*k+j,i)
               plen=plen+obj_geom(1+ndims*k+j,i)**2
            enddo
            if(proj.gt.plen)return
            if(proj.lt.0.)return
         enddo
         inside_geom=1
      endif

      end
c************************************************************
c Specific routine for this problem.
      subroutine potlsect(id,ipm,ndims,indi,fraction,conditions,dp,
     $     iobjno)
c In dimension id, direction ipm, 
c from mesh point at indi(ndims) (zero-based indices, C-style),
c find any intersection of the mesh leg from this point to its neighbor
c with a bounding surface. Return the "fraction" of the leg at which
c the intersection occurs (1 if no intersection), the "conditions" at
c the intersection (irrelevant if fraction=1), the +ve length
c in computational units of the full leg in dp, and the object number
c in iobjno
      integer id,ipm,ndims,iobjno
      integer indi(ndims)
      real fraction,dp
      real conditions(3)
c Equivalence: c1,c2,c3==a,b,c
c The boundary conditions are in the form c1\psi + c2\psi^\prime + c3
c =0.  Where ci=conditions(i).  Thus a fixed potential is (e.g.) c1=1
c c3=-\psi.  A fixed gradient is (e.g.) c2=1 c3=-\psi^\prime. 
c
c In multiple dimensions, if the condition is placed on the gradient
c normal to the surface, in direction n, then for axis direction i
c (assuming an orthogonal set) the value of c2 should become c2_i =
c B/(n.e_i) where e_i is the unit vector in the axis direction.
c
c [If n.e_i=0 this is a pathological intersection.  The mesh leg is
c tangential to the surface, and a normal-gradient BC is irrelevant.
c Therefore, a fraction of 1 should be returned.]
c
c If the surface conditions include non-zero c2, then it is not possible
c to apply the same BC to both sides, without a discontinuity arising.
c Continuity alone should be applied
c on the other (inactive) side of the surface.  A negative value of c2
c is used to indicate that just the appropriate continuity condition is
c to be applied, but c1,c2,c3, should all be returned with the magnitudes
c that are applied to the active side of the surface, with consistently
c reversed signs. (e.g. a=1, b=1, c=-2 -> a=-1, b=-1, c=2)
c
c A fraction of 1 causes all the bounding conditions to be ignored.

      include 'meshcom.f'
      include '3dcom.f'

      real xx(10),xd(10)

c Default no intersection.
      fraction=1
      iobjno=0

c-------------------------------------------------------------
c Process data stored in obj_geom.
      do i=1,ngeomobj
c Currently implemented just for spheres.
         call spheresect(id,ipm,ndims,indi,
     $        obj_geom(oradius,i),obj_geom(ocenter,i)
     $        ,fraction,dp)
         if(fraction.ne.1.)then
            if(obj_geom(oabc+1,i).eq.0)then
c No derivative term. Fixed Potential. No projection needed.
               conditions(1)=obj_geom(oabc,i)
               conditions(2)=obj_geom(oabc+1,i)
               conditions(3)=obj_geom(oabc+2,i)
            else
c Derivative term present. Calculate the projection:
c    Calculate Coordinates of crossing
               do idi=1,ndims
c    Address of mesh point. 
                  ix=indi(idi)+ixnp(idi)+1
                  xx(idi)=xn(ix)
                  if(idi.eq.idi)
     $                 xx(idi)=xx(idi)+fraction*(xn(ix+ipm)-xn(ix))
c    Component of outward vector = Sphere outward normal.
                  xd(idi)=xx(idi)-obj_geom(ocenter+idi-1,i)
               enddo
c    Signed projection cosine:
               projection=ipm*(xd(id)/obj_geom(oradius,i))
               if(projection.eq.0.)then
                  fraction=1.
               else
c    Continuity works for both directions.
                  conditions(1)=sign(obj_geom(oabc,i),projection)
                  conditions(2)=obj_geom(oabc+1,i)/projection
                  conditions(3)=sign(obj_geom(oabc+2,i),projection)
c Special Zero outside, rather than continuity alternative
                  if(int(obj_geom(1,i))/256.eq.1
     $                 .and. projection.lt.0.)then
                     conditions(1)=1.
                     conditions(2)=0.
                     conditions(3)=0.
                  endif
               endif
            endif
c            write(*,*)'ABC,projection',(obj_geom(oabc+k,i),k=0,2)
c     $           ,projection,conditions
            iobjno=i
            return
         endif
      enddo
c----------------------------------------------------------
c Default return for no intersection.
c Address of mesh point. 
      ix=indi(id)+ixnp(id)+1
      dp=abs(xn(ix+ipm)-xn(ix))
      end
c*************************************************************
c Initialize the iregion flags of the existing nodes with boundary
c object data.
      subroutine iregioninit(ndims,ifull)
      integer ifull(ndims)

      include 'objcom.f'
      include 'meshcom.f'

      integer ix(ndims_sor)
      real x(ndims_sor)


      if(ndims.ne.ndims_sor)then 
         write(*,*)'iregioninit error; incorrect dimensions:',
     $        ndims,ndims_sor
         call exit(0)
      endif

c      write(*,*)'Initializing Object Regions: No, index, iregion'
      do i=1,oi_sor
         ipoint=idob_sor(ipoint_sor,i)
c Convert index to multidimensional indices.
         call indexexpand(ndims,ifull,ipoint,ix)
         do k=1,ndims
c Recognize that the reverse pointer is relative to (2,2,2) because
c of the way that cijroutine is called. 
c So add one to ix(k) for proper registration.
c            x(k)=xn(ixnp(k)+ix(k)+1)
c That was for the old scheme. Now we've removed that problem
            x(k)=xn(ixnp(k)+ix(k))
         enddo
c Store in object-data.
         idob_sor(iregion_sor,i)=insideall(ndims,x)

c         write(*,*)i,ipoint,ix,x,idob_sor(iregion_sor,i)
      enddo

      end
c*******************************************************************
      function ireg3(i,j,k,ifull,cij)
      include 'objcom.f'
      integer ifull(3)
      real cij(ndims_sor*2+1,ifull(1),ifull(2),ifull(3))


      ipoint=cij(ndims_sor*2+1,i,j,k)
      if(ipoint.ne.0)then
         ireg3=idob_sor(iregion_sor,ipoint)
      else
         ireg3=99
      endif

      end
