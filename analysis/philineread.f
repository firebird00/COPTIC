       program philineread

      include 'examdecl.f'

      character*100 filenames(na_m)
      character*50 string
      parameter (nfx=200)
      integer ild,ilinechoice(ndims,nfx),ip(ndims)
      real philine(na_m),xline(na_m),dphidx(na_m),xd(na_m)
      real darray(nfx),pmax(nfx),punscale(nfx),rp(nfx),pp(nfx)
      real tp(nfx),vp(nfx)
      integer ip2(ndims)

! philineread commons
      logical lrange,lwrite,lvd,ldiff,lbva,llout,llw
      integer iover
      character*(100)overfile
      common /linecom/xmin,xmax,ymin,ymax,lrange,lwrite
     $     ,iover,overfile,lvd,ldiff,lbva,llout,llw,diffval
     $     ,xlmin,ylmin


! xfig2trace parameters.
      parameter (np=200,nt=50)
      real xtraces(np,nt), ytraces(np,nt)
      integer nl(nt)
      real xyia(4)
! Specific from IEEE
      parameter (nlin=13)
      real zlin(nlin),plin(nlin)
      data zlin/.7,1.3,1.55,1.72,1.85,2.07,2.25,2.4,2.7,2.85,3.2,3.7
     $     ,5.05/
      data plin/1.24,1.24,1.1,.965,.827,.689,.551,.413,.276,.138,0.,
     $     -.138,-.138/


!      character*100 xfigfile
! 
! silence warnings:
      zp(1,1,1)=0.
      fluxfilename=' '
      overfile=' '
      lvd=.false.
      xmin=0.
      ymin=0.
      xmax=0.
      ymax=0.
      lwrite=.false.
      iover=0
      ild=3
      lbva=.false.

!      write(*,*)nf,idl
      nf=nfx
      call lineargs(filenames,nf,ild,ilinechoice,rp,pp)
      write(*,*)'Filenames',nf

      nplot=0
      do inm=1,nf
         phifilename=filenames(inm)
!         write(*,*)ifull,iuds
         ied=1
         call array3read(phifilename,ifull,iuds,ied,u,ierr)
         if(ierr.eq.1)stop
         do i=1,ndims
            if(iuds(i).gt.na_m) then
               write(*,*)'Data too large for na_m',na_m,iuds(i)
               stop
            endif
         enddo
         
         if(pp(inm).ne.0.)then
            write(*,*)'Scaling internal phip',phip,' by factor ',pp(inm)
            phis=phip*pp(inm)
         else
            phis=phip
         endif
         tp(inm)=Ti
         vp(inm)=vd
         write(*,*)'ild=',ild
! Select the lineout into the plotting arrays.      
!         if(ild.ne.0)then
            write(*,*)'Dim, Mesh-No, Positions, /debye:'
            do k=1,ndims-1
               ik=mod(ild+k-1,ndims)+1
               ip(ik)=ilinechoice(ik,inm)
! implement default here
               if(ip(ik).eq.0)ip(ik)=iuds(ik)/2
               ip2(ik)=1
               write(*,'(2i5,2f10.4)')ik,ip(ik),xn(ixnp(ik)+ip(ik))
     $              ,xn(ixnp(ik)+ip(ik))/debyelen
            enddo
            bv=0.
            if(lbva)then
! Find the average boundary value. 
               do i=1,iuds(ild)
                  ip2(ild)=i
                  bv=bv+ u(ip2(1),ip2(2),ip2(3))
               enddo
               bv=bv/iuds(ild)
            endif
! Get the line out.
!            write(*,*)'ild,ip(ild)',ild,ip(ild)
            if(lwrite)write(*,*)iuds(ild)
            do i=1,iuds(ild)
               ip(ild)=i
               xline(i)=xn(ixnp(ild)+i)/debyelen
               philine(i)=(u(ip(1),ip(2),ip(3))-bv)
     $              /(abs(phis)*(1.+rp(inm)/debyelen)*rp(inm)/debyelen)
               if(lwrite)write(*,'(2f10.5)')xline(i),philine(i)
            enddo
            if(ldiff)then
               call differentiate(iuds(ild),xline,philine,xd,dphidx)
               write(*,*)iuds(ild)-1
               write(*,'(2f10.5)')(xd(k),dphidx(k),k=1,iuds(ild)-1)
               if(diffval.ne.0.)then
! Find the mesh position                  
                  ixi=interp(xd,iuds(ild)-1,diffval,xi)
                  if(ixi.ne.0)then
                     xf=xi-ixi
                     val=dphidx(ixi)*(1-xf)+dphidx(ixi+1)*xf
                     write(*,'(a,f10.5,a,f10.5)')'Position:',diffval
     $                    ,'  Derivative Value:',val
                  else
                     write(*,*)'Fixed value outside range.'
                  endif
               endif
            endif
            call minmax(philine,iuds(ild),pmin,pa)
            pmax(inm)=pa
            punscale(inm)=pmax(inm)*abs(phis)*(1.+rp(inm)/debyelen)
     $           *(rp(inm)/debyelen)
            darray(inm)=abs(rp(inm)*(1.+rp(inm)/debyelen)*phis/debyelen)

            write(*,*)'inm,rp,pp,phis',inm,rp(inm),pp(inm),phis
            call winset(.true.)
            call pfset(3)
            if(inm.eq.1)then
               if(lrange)then
                  if(xmin-xmax.eq.0.)then
                     call minmax(xline,iuds(ild),xmin,xmax)
                  endif
                  if(ymin-ymax.eq.0.)then
                     call minmax(philine,iuds(ild),ymin,ymax)
                  endif
                  call pltinit(xmin,xmax,ymin,ymax)
                  call axis()
                  if(ild.eq.3)then
                     call axlabels('z/!Al!@',
     $                 '!Af!@/(|!Af!@!dp!d|r!dp!d/!Al!@)')
                  elseif(ild.eq.2)then
                     call axlabels('y/!Al!@',
     $                 '!Af!@/(|!Af!@!dp!d|r!dp!d/!Al!@)')
                  else
                     call axlabels('x/!Al!@',
     $                 '!Af!@/(|!Af!@!dp!d|r!dp!d/!Al!@)')
                  endif
                  call winset(.true.)
                  call polyline(xline,philine,iuds(ild))
                  if(ldiff)then
                     call dashset(2)
                     call polyline(xd,dphidx,iuds(ild)-1)
                     call dashset(0)
                  endif
               else
                  call autoplot(xline,philine,iuds(ild))
                  if(ldiff)call polyline(xd,dphidx,iuds(ild)-1)
               endif
               call axis2()
            else
               call color(inm)
!               call iwrite(inm,iwd,string)
!               call labeline(xline,philine,iuds(ild),string,iwd)
               call dashset(inm)
               call polyline(xline,philine,iuds(ild))
               if(ldiff)call polyline(xd,dphidx,iuds(ild)-1)
            endif
            if(lvd)then
               string=' M='
               call fwrite(vd,iwd,2,string(lentrim(string)+1:))
               if(llw)then
                  call winset(.false.)
                  call legendline(xlmin,(ylmin+.01+inm*.05),0,
     $                 string(1:lentrim(string)))
                  call winset(.true.)
               endif
            else
               string=' !Af!@!dp!d='
               call fwrite(phis,iwd,2,string(lentrim(string)+1:))
               string(lentrim(string):)='@'
               call fwrite(rp(inm)/debyelen,iwd,2,
     $              string(lentrim(string)+1:))
               string(lentrim(string):)='!Al!@'
               if(rp(inm)/debyelen.ge.0.01)
     $              call legendline(.5,(.01+inm*.05),0,
     $              string(1:lentrim(string)))
            endif
            nplot=nplot+1
!         endif

         write(*,'(a,3i4,$)')'On grid',iuds
         write(*,*)(',',xn(ixnp(kk)+1),xn(ixnp(kk+1)),kk=1,3)
     $        ,ip
!         write(*,*)ild,ilinechoice
      enddo
      if(iover.gt.0)then
! Overplot traces from specified file.
         write(*,*)iover,' Overplot ',overfile(1:40)
         call xfig2trace(np,nt,xtraces,ytraces,il,nl,xyia,overfile)
         write(*,*)'Return from xfig2',il,(nl(k),k=1,il),xyia
         if(il.gt.0)then
            do k=1,il
               call dashset(2)
               call color(4)
               call polyline(xtraces(1,k),ytraces(1,k),nl(k))
            enddo
         else
! No valid file overplot built in.
            write(*,*)'Plotting internal comparison',nlin
            write(*,*)zlin
            write(*,*)plin
            call dashset(0)
            call color(13)
            call polyline(zlin,plin,nlin)
         endif
      endif
      if(nplot.gt.0)then
         call pltend()
         call dashset(0)
         call charsize(.02,.02)
         call lautomark(darray,pmax,nplot,.true.,.true.,0)
         imark=1
         do k=1,nplot
!            itc=int(tp(k)/0.0049
            itc=int(vp(k)*4.001)
            call color(itc)
            if(lvd)then
               string=' M='
               call fwrite(vp(k),iwd,2,string(4:))
               if(k.eq.1)then
                  call legendline(.0,.02+.05*imark,imark,string)
               elseif(vp(k).ne.vp(k-1))then
                  imark=imark+1
                  call legendline(.0,.02+.05*imark,imark,string)
               endif
            else
               string=' r!dp!d/!Al!@='
               call fwrite(rp(k)/debyelen,iwd,2,string(15:))
               if(k.eq.1)then
                  call legendline(.0,.02+.05*imark,imark,string)
               elseif(rp(k).ne.rp(k-1))then
                  imark=imark+1
                  call legendline(.0,.02+.05*imark,imark,string)
               endif
            endif
            call polymark(darray(k),pmax(k),1,imark)
         enddo
         call color(15)
         call axlabels('|!Af!@!dp!d|r!dp!d(1+r!dp!d/!Al!@)/!Al!@'
     $        //' = Q/4!Ape!@!d0!d!Al!@',
     $        '!Af!@!dmax!d/( Q/4!Ape!@!d0!d!Al!@)')
!     $        '!Af!@!dmax!d/(|!Af!@!dp!d|r!dp!d/!Al!@)')
!         call vecw(0.04,3.,0)
!         call vecw(1.,.12,1)
!         call vecw(0.01,2.,0)
!         call vecw(0.1,2.,1)
         call pltend()
!         call ticset(.015,.015,-.03,-.02,4,4,1,1) 
         call ticset(.015,.015,-.03,-.025,4,4,1,1) 
         call lautomark(darray,punscale,nplot,.true.,.true.,0)
         call color(imark)
         imark=1
         do k=1,nplot
!            itc=int(tp(k)/0.0049)
            itc=int(vp(k)*4.001)
            call color(itc)
            if(lvd)then
               string=' M='
               call fwrite(vp(k),iwd,2,string(4:))
               if(k.eq.1)then
                  call legendline(.3,.02+.05*imark,imark,string)
               elseif(vp(k).ne.vp(k-1))then
                  imark=imark+1
                  call legendline(.3,.02+.05*imark,imark,string)
               endif
            else
               string=' r!dp!d/!Al!@='
               call fwrite(rp(k)/debyelen,iwd,2,string(15:))
               if(k.eq.1)then
                  call legendline(.3,.02+.05*imark,imark,string)
               elseif(rp(k).ne.rp(k-1))then
                  imark=imark+1
                  call legendline(.3,.02+.05*imark,imark,string)
               endif
            endif
            call polymark(darray(k),punscale(k),1,imark)
         enddo
         call color(15)
         write(*,*)'punscale',(punscale(k),k=1,nplot)
         call axlabels('|!Af!@!dp!d|r!dp!d(1+r!dp!d/!Al!@)/!Al!@'
     $        //' = Q/4!Ape!@!d0!d!Al!@',
     $        '!Af!@!dmax!d')
!'|!Af!@!dp!d|r!dp!d/!Al!@'
!     $        //'!A ~ !@Q/4!Ape!@!d0!d!Al!@',
         call pltend()
      endif


      end

!*************************************************************
      subroutine lineargs(filenames,nf,ild,ilinechoice,rp,pp)
! Deal with command line arguments.

! Non-switch arguments are the names of files to read from. For each of
! those, return the name in filename, the choice of line in ilinechoice,
! and the radius of object in rp. 
! On entry nf is array dimension. (IN)
! On exit nf is the number of files read. (OUT)
! Switch arguments set -x(min,max) -y(min,max) -l(linechoice for the
! subsequent files) -r radius (subsequent) -w writing to true. 
! -o overplot file (xfig with scaling). 

! ild is the dimension that is fixed, and must be the same for all files.
! the logic will break if it is changed by -l in the middle.

      include 'examdecl.f'
      integer nf
      character*100 filenames(na_m)
      real rp(nf),pp(nf)
      integer ild,ilinechoice(ndims,nf)
      integer idj(ndims)

      logical lrange,lwrite,lvd,ldiff,lbva,llout,llw
      integer iover
      character*(100) overfile
      common /linecom/xmin,xmax,ymin,ymax,lrange,lwrite
     $     ,iover,overfile,lvd,ldiff,lbva,llout,llw,diffval
     $     ,xlmin,ylmin

      ifull(1)=na_i
      ifull(2)=na_j
      ifull(3)=na_k
! Passed in array dimension
      nfx=nf

! Defaults and silence warnings.
      phifilename=' '
      fluxfilename=' '
      nf=1
      zp(1,1,1)=0.
      lrange=.false.
      do id=1,ndims
         idj(id)=0
         ilinechoice(id,1)=0
      enddo
      rread=1.
      iover=0
      phiread=0.
      diffval=0.
      llout=.false.
      ldiff=.false.
      llw=.true.
      xlmin=0.5
      ylmin=0.

! Deal with arguments
      if(iargc().eq.0) goto 201
      do i=1,iargc()
         call getarg(i,argument)
         if(argument(1:1).eq.'-')then
            if(argument(1:2).eq.'-l')then
               read(argument(3:),*,end=11)ild,(idj(k),k=1,ndims-1)
 11            continue
            endif
            if(argument(1:2).eq.'-y')then
               read(argument(3:),*,end=12)ymin,ymax
               lrange=.true.
 12            continue
            endif
            if(argument(1:2).eq.'-x')then
               read(argument(3:),*,end=13)xmin,xmax
               lrange=.true.
 13            continue
            endif
            if(argument(1:2).eq.'-o')then
               read(argument(3:),*,end=14,err=14)overfile
               iover=1
 14            continue
            endif
            if(argument(1:2).eq.'-g')then
               read(argument(3:),*,end=15)xlmin,ylmin
 15            continue
               write(*,*)'xlmin,ylmin',xlmin,ylmin
            endif
            if(argument(1:2).eq.'-b')lbva=.not.lbva
            if(argument(1:2).eq.'-v')lvd=.true.
            if(argument(1:2).eq.'-m')xlmin=-xlmin
            if(argument(1:2).eq.'-a')llw=.not.llw
            if(argument(1:2).eq.'-w')lwrite=.true.
            if(argument(1:2).eq.'-d')ldiff=.true.
            if(argument(1:3).eq.'-dv')
     $           read(argument(4:),*,err=201)diffval
            if(argument(1:13).eq.'--objfilename')
     $           read(argument(14:),'(a)',err=201)objfilename 
           if(argument(1:2).eq.'-r')
     $           read(argument(3:),*,err=201)rread
            if(argument(1:2).eq.'-p')then
               read(argument(3:),*,err=201)phiread
               write(*,*)'phi scaling factor',phiread
            endif
            if(argument(1:2).eq.'-h')goto 203
            if(argument(1:2).eq.'-?')goto 203
!            if(argument(1:2).eq.'-f')goto 204
         else
            read(argument(1:),'(a)',err=201)phifilename
!               write(*,*)ild, idj
            do k=1,ndims-1
               ilinechoice(mod(ild+k-1,ndims)+1,nf)=idj(k)
!                  write(*,*)'nf,k,idj(k)',nf,k,idj(k)
            enddo
            filenames(nf)(1:)=phifilename
            rp(nf)=rread
            pp(nf)=phiread
            if(nf.eq.nfx)then
               write(*,*)'Exhausted file dimension',nf
               return
            endif
            nf=nf+1
         endif
      enddo
      nf=nf-1

!      write(*,*)ild,
!     $     (ilinechoice(2,i),' ',rp(i),' ',filenames(i)(1:30),i=1,nf)
      goto 202
!------------------------------------------------------------
! Help text
 201  continue
      write(*,*)'=====Error reading command line argument'
 203  continue
 301  format(a,3i5)
 302  format(a,3f8.3)
      write(*,301)'Usage: philineread [switches] <phifile>'//
     $     ' [<phifile2> ...]'
!      write(*,301)' --objfile<filename>  set name of object data file.'
!     $     //' [ccpicgeom.dat'
      write(*,301)' -l<idim>,<irow1>,<irow2> set fixed dimension [',ild
      if(idj(1).eq.0)then
         write(*,301)
     $        '    and row position in other dimensions. [ 3,n/2,n/2'
      else
         write(*,301)'    and row position in other dimensions. ['
     $        ,ild,idj(1),idj(2)
      endif
      write(*,301)' -y<min>,<max>   -x<min>,<max>  set plot ranges'
      write(*,301)' -o<figfile> overplot traces using xfig2trace.'
      write(*,302)' -r<r> set radius [',rread
      write(*,302)' -p<p> set phiparticle scaling factor [',phiread
      write(*,*)'  Use <r>=1/<p>=tiny for point charges'
      write(*,*)'-w  write out the line data'
      write(*,301)' -v sort/mark by vd, not radius.'
      write(*,301)' -d plot the derivative of potential as well'
      write(*,*)'-dv specify coord-value at which to print'
     $     ,' derivative.' 
      write(*,301)' -b subtract boundary value of phi'
      write(*,*)'-m move legend outside box  [',llout
      write(*,*)'-g<xl,yl> set box position of legend start.'
      write(*,*)'-a toggle legend on/off     [',llw
      write(*,301)' -h -?   Print usage.'
      call exit(0)
 202  continue
      if(lentrim(partfilename).lt.5)goto 203
      end
!*****************************************************************

!***********************************************************************
      subroutine xfig2trace(np,nt,xtraces,ytraces,il,nl,xyia,filename)

! Read up to nt traces each of length up to np (IN)
! from xfig format plot file filename (IN).
! Return il traces of lengths nl(il) in xtraces, ytraces (OUT).
! Use the optionally updated box xyia(4) (INOUT) to scale them.

! Read polylines in filename as traces. 
! Use the last rectangle in file as the corners of the plotted region,
! corresponding to xmin, xmax, ymin, ymax = xyia(4).

! If a comment exists in the xfig file starting "Box:" 
! (entered by doing an xfig edit of an object and typing it in)
! then read 4 values from this comment into xyia. 
! Otherwise use input values.

! For each comment starting "Scale:" read 1 value 
! and multiply the xyia y-values by it.
! For each comment starting "XScale:" read 1 value 
! and multiply the xyia x-values by it.
! (Must occur *after* any Box: comment to be effective. Can be 
! ensured by using the same xfig comment box with a new line.)

! Abnormal returns are indicated by il. il>=1000 (too many lines)
! il=-1 (no file) il=0 (no traces) il=-2 (box reading error).

      real xtraces(np,nt),ytraces(np,nt)
      integer il,nl(nt)
      real xyia(4)
      character*(*) filename

      real xrect(5),yrect(5)
      character*100 line
      real pvalues(16)

!      write(*,'(a,4f8.3)')'xmin,xmax,ymin,ymax'
!     $     ,xyia(1),xyia(2),xyia(3),xyia(4)
      il=1
      open(10,file=filename,status='old',err=304)
      do i=1,200
         read(10,'(a)',end=302,err=301)line
!         write(*,'(i4,a)')i,line
         if(line(1:3).eq.'2 1')then
            read(line,*)pvalues
!            write(*,'(a,16f4.0)')'Polyline',pvalues
            nl(il)=int(pvalues(16))
            if(nl(il).gt.np)then
               write(*,*)'Polyline ',il,' too long:',nl(il)
               nl(il)=np
            endif
            read(10,*)(xtraces(j,il),ytraces(j,il),j=1,nl(il))
!            write(*,'(10f7.1)')(xtraces(j,il),j=1,nl(il))
!            write(*,'(10f7.1)')(ytraces(j,il),j=1,nl(il))
            il=il+1
         elseif(line(1:3).eq.'2 2')then
            read(line,*)pvalues
!            write(*,'(a,16f4.0)')'Rectangle',pvalues
            nl(il)=int(pvalues(16))
            if(nl(il).ne.5)then
               write(*,*)'Error. Rectangle has not 5 points',nl(il)
               stop
            endif
            irect=il
            read(10,*)(xrect(j),yrect(j),j=1,nl(il))            
!            write(*,'(10f7.1)')(xrect(j),j=1,nl(il))
!            write(*,'(10f7.1)')(yrect(j),j=1,nl(il))
         elseif(line(1:6).eq.'# Box:')then
            read(line(7:),*,err=303,end=303)(xyia(k),k=1,4)
            write(*,*)'xfig2trace: xyia',(xyia(k),k=1,4)
         elseif(line(1:8).eq.'# Scale:')then
            read(line(9:),*,err=303,end=303)scale
            write(*,*)'xfig2trace: scale',scale
            do k=3,4
               xyia(k)=xyia(k)*scale
            enddo
         elseif(line(1:9).eq.'# XScale:')then
            read(line(10:),*,err=303,end=303)scale
            write(*,*)'xfig2trace: XScale',scale
            do k=1,2
               xyia(k)=xyia(k)*scale
            enddo
         endif
         if(il.gt.nt)goto 300
      enddo
 300  write(*,*)'Too many lines to read',nt
      il=il*1000
      return
 301  write(*,*)'xfig2trace Error reading line ',line
      il=il-1
      return
 303  write(*,*)'xfig2trace Error reading Box/Scale comment',line
      il=-2
      return
 302  continue
      write(*,*)'Completed reading file.'
      il=il-1
!      write(*,*)'il',il,(nl(k),k=1,il)
! Now we transform from xfig coordinates to plot world coordinates.
      xscale=(xyia(2)-xyia(1))/(xrect(2)-xrect(1))
      yscale=(xyia(4)-xyia(3))/(yrect(1)-yrect(4))
      xzero=-(xyia(2)*xrect(1)-xyia(1)*xrect(2))/(xrect(2)-xrect(1))
      yzero=-(xyia(4)*yrect(4)-xyia(3)*yrect(1))/(yrect(1)-yrect(4))

!      write(*,*)'Scalings ',xscale,xzero,yscale,yzero

! Transform to world coordinates.
      do i=1,il
         do j=1,nl(i)
            xtraces(j,i)=xtraces(j,i)*xscale+xzero
            ytraces(j,i)=ytraces(j,i)*yscale+yzero
         enddo
      enddo
      return
      
 304  write(*,*)'xfig2trace: Could not open: ',filename(1:50)
      il=-1

      end
!****************************************************************
      subroutine differentiate(npts,x,y,xd,dydx)
! On entry x,y are arrays of a fuction y(x) of length npts. 
! x is not necessarily uniform.
! On exit the differential dy/dx is in dydx on an x-array xd.
! xd are the center points of the differences, length strictly npts-1
! although the arrays will normally have a total of npts.
      integer npts
      real x(npts),y(npts),dydx(npts),xd(npts)

      do i=1,npts-1
         dx=x(i+1)-x(i)
         dy=y(i+1)-y(i)
         dydx(i)=0.
         if(dx.ne.0.)dydx(i)=dy/dx
         xd(i)=(x(i+1)+x(i))*0.5
      enddo

      end
