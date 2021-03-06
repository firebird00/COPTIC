c Test alltoallw
      include 'mpif.h'
      parameter (nproc=3,iblen=10)
      real u(iblen),v(iblen)
      integer isc(nproc),isd(nproc),ist(nproc)
      integer irc(nproc),ird(nproc),irt(nproc)
      
      call MPI_INIT(ierr)

      call MPI_COMM_RANK( MPI_COMM_WORLD, myid, ierr )
      call MPI_COMM_SIZE( MPI_COMM_WORLD, numprocs, ierr )


      if(nproc.gt.numprocs)then
         write(*,*)'Too few of processes.',numprocs,' I need',nproc
      endif
c initialize
      do i=1,nproc
         isc(i)=0
         isd(i)=(i-1)*4
         ist(i)=MPI_REAL
         irc(i)=0
c        ird(i)=(nproc+i)*4
         ird(i)=(i-1)*4
         irt(i)=MPI_REAL
      enddo

      do i=1,iblen
         u(i)=myid*10+i
         v(i)=myid*10+i
      enddo

c copy from 0 to 1, and from 1 to 0 
      if(myid.eq.0)then
         isc(2)=1
         irc(2)=2
      endif
      if(myid.eq.1)then
         irc(1)=1
         isc(1)=2
      endif


c      write(*,101)(i,isc(i),isd(i),mod(ist(i),10000),
c     $     irc(i),ird(i),mod(irt(i),10000),i=1,nproc)

c The jth block sent by process i is received by process j and placed
c in the ith block of recvbuf. 
      call MPI_ALLTOALLW(u,isc,isd,ist,v,irc,ird,irt,
     $     MPI_COMM_WORLD,ierr)

 101  format(7i8)
c      write(*,101)(isc(i),isd(i),mod(ist(i),10000),
c     $     irc(i),ird(i),mod(irt(i),1000),i=1,nproc)
      write(*,'(a,10f7.1)')'u',u
      write(*,'(a,10f7.1)')'v',v

      call MPI_FINALIZE()
      end
