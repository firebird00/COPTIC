c**********************************************************************
c Boxcar average a trace.
c Make the traceave(i) equal to the average from i-nb to i+nb of trace.
c If nb=0, just transfer
      subroutine boxcarave(nt,nb,trace,traceave)
      integer nt,nb
      real trace(nt),traceave(nt)

      if(nb.lt.0)return
      do i=1,nt
         accum=0.
         nac=0
         nr=min(abs(i-1),abs(nt-i))
         nr=min(nr,nb)
         do j=i-nr,i+nr
            accum=accum+trace(j)
            nac=nac+1
         enddo
         traceave(i)=accum/nac
c         write(*,*)'Boxcar',i,nr,nac,accum
      enddo
      end
c**********************************************************************
c Triangular average a trace.  Make the traceave(i) equal to the
c triangular weighted average from i-nb to i+nb of trace.  If nb=0, just
c transfer
      subroutine triangave(nt,nb,trace,traceave)
      integer nt,nb
      real trace(nt),traceave(nt)

      if(nb.lt.0)return
      do i=1,nt
         accum=0.
         wtt=0
         nr=min(abs(i-1),abs(nt-i))
         nr=min(nr,nb)
         do j=-nr,+nr
            wt=1.-abs(j)/(nr+1.)
            accum=accum+wt*trace(j+i)
            wtt=wtt+wt
c            write(*,*)i,j,i+j,wt,wtt
         enddo
         traceave(i)=accum/wtt
      enddo
      end
c**********************************************************************
c**********************************************************************
c Boxcar average a trace that is strided by istride
c This version for averaging over dimensions other than the first.
c Make the traceave(i) equal to the average from i-nb to i+nb of trace.
c If nb=0, just transfer
      subroutine boxcarstride(nt,nb,trace,traceave,istride)
      integer nt,nb,istride
      real trace(nt),traceave(nt)

      if(nb.lt.0)return
      do i=1,nt
         accum=0.
         nac=0
         nr=min(abs(i-1),abs(nt-i))
         nr=min(nr,nb)
         do j=i-nr,i+nr
            accum=accum+trace((j-1)*istride+1)
            nac=nac+1
         enddo
         traceave((i-1)*istride+1)=accum/nac
      enddo
      end
