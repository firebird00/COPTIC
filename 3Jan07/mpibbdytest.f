c********************************************************************
c*********************************************************************
c Example of advance program. Just sets id. Up to 3d specified.
      subroutine blockadvance3d(u123,nrd,iLs,iuds,
     $     iorig,iol1,iol2,iol3,
     $     icoords,myid)
      real u123(*)
      integer nrd
      integer iLs(nrd+1),iuds(nrd)
c iorig(idims(1)+1,idims(2)+1,...) provides origin of block(i,j,..) 
      integer iorig(iol1,iol2,iol3)
      integer icoords(3)

      integer iocn(3)
      integer kstart(3)

c            write(*,*)'icoords',icoords
         ioc =iorig(icoords(1)+1,icoords(2)+1,icoords(3)+1)
         iocn(1)=iorig(icoords(1)+2,icoords(2)+1,icoords(3)+1)
         iocn(2)=iorig(icoords(1)+1,icoords(2)+2,icoords(3)+1)
         iocn(3)=iorig(icoords(1)+1,icoords(2)+1,icoords(3)+2)
         do i=1,3
            kstart(i)=iLs(i)
c Deal with the k possibly null dimensions
            if(i.gt.nrd)then
               iocn(i)=ioc
               kstart(i)=0
            endif
         enddo
c         write(*,*)'nrd,ioc,ioc1,ioc2,ioc3 ',nrd,ioc,iocn
c Do only the inner cells, hence start at 1.
         do k=kstart(3),iocn(3)-ioc,iLs(3)
            do j=kstart(2),iocn(2)-ioc,iLs(2)
               do i=kstart(1),iocn(1)-ioc,iLs(1)
c                  write(*,*)'ioc,i,j,k',ioc,i,j,k,(ioc+i+j+k),myid
                  u123(ioc+i+j+k)=myid
               enddo
            enddo
         enddo
         end
c*************************************************************
c Example of advance program. Just sets id. 2d hardwired.
      subroutine blockadvance(u,iL,iu,ju,mycartid)
      real u(iL,ju)
      do j=2,ju-1
         do i=2,iu-1
            u(i,j)=mycartid
         enddo
      enddo
      end
c*************************************************************
c*************************************************************
c*************************************************************
      program bbdytest
      parameter (ndims=3,idim1=1,idim2=1,idim3=2)
      integer iorig(idim1+1,idim2+1,idim3+1)
      include 'bbdydecl.f'

      parameter (ifd1=40,ifd2=20,ifd12=ifd1*ifd2)
      parameter (ifd3=20,ifd123=ifd12*ifd3)
      real u(ifd1,ifd2,ifd3)
      real u123(ifd123)
      equivalence (u,u123)
c ifull full dimensions of u
      integer ifull(ndims)
      data ifull/ifd1,ifd2,ifd3/

c Set key data in the arrays declared in bbdydecl
      data lperiod/ndims*.false./
      data idims/idim1,idim2,idim3/
c
c Setup the used block geometry for nrd dimensions.
      data iuds/10,10,6/
      data nrd/3/
c Initialize icoords just in case
      data icoords/ndims*0/
c  Initialize u [gives a g77 warning if large]
      data u/ifd123*1000./
c So do it explicitly if it is large.
c      do k=1,ifd3
c         do j=1,ifd2
c            do i=1,ifd1
c               u(i,j,k)=1000
c            enddo
c         enddo
c      enddo

      myid=0
c Define the block arrays origins iorig, and full structure iLs.
      call bbdydefine(nrd,idims,ifull,iuds,iorig,iLs)
c Loop over iterations
      do nk=1,2
c First time, set up the boundary data, and get my icoords, myside
c Then do the boundary communication.
         call bbdy(iLs,iuds,u,nk,iorig,nrd,idims,lperiod,
     $        icoords,iLcoords,myside,myorig,
     $        icommcart,mycartid,myid)
c Set this block value to id
         call blockadvance3d(u123,nrd,iLs,iuds,
     $           iorig,idims(1)+1,idims(2)+1,idims(3)+1,
     $           icoords,myid)
c         call blockadvance(u123(iorig(icoords(1)+1,icoords(2)+1,1)),
c     $        iLs(2),myside(1),myside(2),mycartid)
         call udisplay(nrd,u,ifull,iuds,1,1.)
      enddo
      write(*,*)'End of iterations'

c Gather back all the data
      nk=-1
      call bbdy(iLs,iuds,u,nk,iorig,nrd,idims,lperiod,
     $        icoords,iLcoords,myside,myorig,
     $        icommcart,mycartid,myid)
      call udisplay(nrd,u,ifull,iuds,2,1.)

      write(*,*)'DONE mycartid,myid',mycartid,myid
 999  call MPI_FINALIZE()

      end
c**************************************************************
