c**************************************************************
      program fluxexamine
      include '../3dcom.f'
      include '../plascom.f'
      include '../sectcom.f'

      real plotdata(10000,6),stepdata(10000)
      character*100 filename,argument
      integer iplot,iprint,ifmask,idimf,iomask
      real avefield(ns_ndims),avepress(ns_ndims),avepart(ns_ndims)
      real avetotal(ns_ndims),avecoln(ns_ndims),avesq(ns_ndims)
      real rp,yrange
      intrinsic ibclr
      data iplot/1/iprint/1/
      data ifmask/1023/iomask/0/
      data idimf/3/
      data rp/0./

      fn1=0.5
      fn2=1.
      rview=1.
      iosw=1
      yrange=0.

      filename='T1e0v000r05P02L1e0.flx'
      do i=1,iargc()
         call getarg(i,argument)
         if(argument(1:3).eq.'-n1')
     $        read(argument(4:),'(f10.4)')fn1
         if(argument(1:3).eq.'-n2')
     $        read(argument(4:),'(f10.4)')fn2
         if(argument(1:2).eq.'-f')
     $        read(argument(3:),'(i5)')idimf
c iplot is the quantity number to plot and average.
         if(argument(1:2).eq.'-p')
     $        read(argument(3:),'(i5)')iplot
         if(argument(1:2).eq.'-w')
     $        read(argument(3:),'(i5)')iprint
         if(argument(1:2).eq.'-m')
     $        read(argument(3:),'(i5)')ifmask
         if(argument(1:3).eq.'-rp')then
            read(argument(4:),*)rp
         elseif(argument(1:2).eq.'-r')then
            read(argument(3:),'(f10.4)')rview
         elseif(argument(1:2).eq.'-y')then
            read(argument(3:),'(f10.4)')yrange
         endif
         if(argument(1:2).eq.'-i')
     $        read(argument(3:),'(i5)')iosw
         if(argument(1:3).eq.'-om')
     $        read(argument(4:),'(i5)')iomask
         if(argument(1:2).eq.'-o')then
            read(argument(3:),'(i5)')ims
c set to mask out all objects if we are starting anew:            
c            if(iomask.eq.0)iomask=2*(2**30-1)+1
            if(iomask.eq.0)iomask=65535
            iomask=IBCLR(iomask,ims-1)
         endif
         if(argument(1:2).eq.'-h')goto 201
         if(argument(1:2).eq.'-?')goto 201
         if(argument(1:1).ne.'-') read(argument(1:),'(a)')filename
      enddo

      call readfluxfile(filename,ierr)

c      write(*,*)'found',ff_data(nf_address(nf_flux,1,-1)+1-1)
c     $     ,nf_address(nf_flux,1,-1)

      write(*,*)'   No. objects,   No. steps, dt,   No. quantities(obj)'
      write(*,'(i12,i12,f10.4,20i3)')mf_obj,nf_step,ff_dt(nf_step),
     $     (mf_quant(j),j=1,mf_obj)
c      write(*,*) 'Posn and first 2 step addresses ',
c     $     (((nf_address(i,j,k),i=1,mf_quant(j)),' ,'
c     $     ,j=1,mf_obj),k=1-nf_posdim,2),'...'

c      write(*,*)'geommap for objects',mf_obj,(nf_geommap(k),k=1,mf_obj)


c For all the objects being flux tracked.
      do k=1,mf_obj
         if(k.eq.iprint)then
            if(mf_quant(k).ge.1)then
               write(*,'(a,i3,a,3i4,a,i3)') 'Position data for '
     $              ,nf_posdim,' flux-indices. nf_dimlens='
     $              ,(nf_dimlens(1,k,kd),kd=1,nf_posdim-1),' Object',k
               write(*,'(10f8.4)')((ff_data(nf_address(nf_flux,k,1-j)+i
     $              -1),i=1,nf_posno(1,k)),j=1,nf_posdim)
            endif
            do kk=max(nf_step/5,1),nf_step,max(nf_step/5,1)
               if(mf_quant(k).ge.1)then
                  write(*,'(a,i4,a,f10.4,a)')'Step(',kk,') rho='
     $                 ,ff_rho(kk),'  Flux data'
                  write(*,'(10f8.2)')(ff_data(nf_address(nf_flux,k,kk)+i
     $                 -1),i=1,nf_posno(nf_flux,k))
               endif
               if(mf_quant(k).ge.2)then
                  write(*,'(''x-momentum'',i4)')nf_posno(nf_gx,k)
                  write(*,'(10f8.3)')(ff_data(nf_address(nf_gx,k,kk)+i
     $                 -1),i=1,nf_posno(nf_gx,k))
               endif
               if(mf_quant(k).ge.3)then
                  write(*,'(''y-momentum'',i4)')nf_posno(nf_gy,k)
                  write(*,'(10f8.3)')(ff_data(nf_address(nf_gy,k,kk)+i
     $                 -1),i=1,nf_posno(nf_gy,k))
               endif
               if(mf_quant(k).ge.4)then
                  write(*,'(''z-momentum'',i4)')nf_posno(nf_gz,k)
                  write(*,'(10f8.3)')(ff_data(nf_address(nf_gz,k,kk)+i
     $                 -1),i=1,nf_posno(nf_gz,k))
               endif
            enddo
         endif
         plotdata(i,j)=pressforce(j,k,i)
      
         n1=fn1*nf_step
         n2=fn2*nf_step
c         if(mf_quant(k).ge.iplot)then
c            write(*,*)'Plotting',k,mf_quant(k),iplot
            call fluxave(n1,n2,k,iplot,rhoinf)
c         endif
      enddo

c Plots if 
      if(rp.ne.0.)write(*,'(a,f10.4,a,f10.4)')
     $     'Radius',rp,' Potential',phip
      write(*,*)'   Field,       part,       press,'
     $     ,'     collision,    total,  steps ave',n1,n2
      nplot=0
      do k=1,mf_obj
         imk=ifmask/2**(k-1)
         imk=imk-2*(imk/2)
c         write(*,*)'ifmask=',ifmask,' k=',k,' imk=',imk

         do j=1,ns_ndims
            avefield(j)=0.
            avepart(j)=0.
            avepress(j)=0.
            avecoln(j)=0.
            avesq(j)=0.
         enddo
         avecharge=0.
         iavenum=0
         do i=1,nf_step
            plotdata(i,1)=fieldforce(idimf,k,i)*debyelen**2
            plotdata(i,2)=pressforce(idimf,k,i)
            plotdata(i,3)=partforce(idimf,k,i)               
            plotdata(i,4)=plotdata(i,1)+plotdata(i,2)+plotdata(i,3)
            plotdata(i,5)=charge_ns(k,i)
            plotdata(i,6)=colnforce(idimf,k,i)               
            stepdata(i)=i
            if(i.ge.n1 .and. i.le.n2)then
               iavenum=iavenum+1
               do j=1,ns_ndims
                  avefield(j)=avefield(j)+fieldforce(j,k,i)
                  avepress(j)=avepress(j)+pressforce(j,k,i)
                  avepart(j)=avepart(j)+partforce(j,k,i)
                  avecoln(j)=avecoln(j)+colnforce(j,k,i)
                  avesq(j)=avesq(j)+(fieldforce(j,k,i)+pressforce(j,k,i)
     $                 +partforce(j,k,i)+colnforce(j,k,i))**2
               enddo
               avecharge=avecharge+charge_ns(k,i)
            endif
         enddo
         do j=1,ns_ndims
            avefield(j)=debyelen**2*avefield(j)/float(iavenum)
            avepress(j)=avepress(j)/float(iavenum)
            avepart(j)=avepart(j)/float(iavenum)
            avecoln(j)=avecoln(j)/float(iavenum)
            avesq(j)=sqrt(avesq(j)/float(iavenum))
            avetotal(j)=avefield(j)+avepart(j)+avepress(j)
         enddo
         avecharge=avecharge/float(iavenum)
         if(iplot.ne.0)then
            if(k.eq.1)then
               if(yrange.eq.0.)yrange=avesq(idimf)
               call pltinit(1.,float(nf_step)
     $              ,-yrange,1.5*yrange)
               call axis()
               call iwrite(idimf,iwr,argument)
               call axlabels('step','Force-'//argument)
               call winset(.true.)
            endif
         if(imk.ne.0)then
            nplot=nplot+1
            call color(k)
            call dashset(4)
            call iwrite(k,iwd,argument)
            call polyline(stepdata,plotdata(1,3),nf_step)
            call legendline(.1+.4*(nplot-1),.2,0,
     $        'partforce '//argument(1:iwd))
            call dashset(1)
            call polyline(stepdata,plotdata(1,1),nf_step)
            call legendline(.1+.4*(nplot-1),.15,0,
     $        'fieldforce '//argument(1:iwd))
            call dashset(2)
            call polyline(stepdata,plotdata(1,2),nf_step)
            call legendline(.1+.4*(nplot-1),.1,0,
     $           'pressforce '//argument(1:iwd))
            if(avecoln(1).ne.0)then
               call dashset(3)
               call polyline(stepdata,plotdata(1,6),nf_step)
               call legendline(.1+.4*(nplot-1),.05,0,
     $              'collisions '//argument(1:iwd))
            endif
            call dashset(0)
            call polyline(stepdata,plotdata(1,4),nf_step)
            call legendline(.1+.4*(nplot-1),.25,0,
     $           'total '//argument(1:iwd))
         endif
         endif
         write(*,101)k,nf_geommap(k),obj_geom(oradius,nf_geommap(k))
     $        ,obj_geom(ocenter+2,nf_geommap(k)),avecharge
 101     format('===== Object',i2,' ->'
     $        ,i3,' radius=',f7.3,' zcenter=',f7.3,' Charge='
     $        ,f10.4,' =====')
         do j=1,ns_ndims            
            write(*,'(5f12.5  )')
     $           avefield(j),avepart(j),avepress(j),avecoln(j),
     $           avefield(j)+avepart(j)+avepress(j)+avecoln(j)
         enddo
      enddo

      write(*,*)'iomask=',iomask,' iosw=',iosw,' iplot=',iplot
      if(iplot.ne.0)then
         call pltend()
c         if(iplot.eq.1)
         call objplot(abs(iplot),rview,iosw,iomask)
      endif

      call exit(1)
 201  write(*,*)'Usage: fluxexamine [filename '//
     $     '-n1fff -n2fff -piii -wiii -rfff -iiii ...]'
      write(*,*)'Read back flux data from file and display.'
      write(*,*)'-n1,-n2 fractional step range over which to average.'
      write(*,*)'-p set quantity to average and plot.'
     $     ,' Default -p1. Non-positive no plot'
      write(*,*)'-w set object whose data is to be written, or none.'
      write(*,*)'-m mask objects whose force is to be plotted'
      write(*,*)'-r set size of plot window'
      write(*,*)'-i set iosw for objplot:'
     $     ,' Coloring 0 position, 1 flux, 2 flux-density.'
      write(*,*)'-oiii add object iii to 3D objects to plot'
     $     ,' (first time masking all others).'
      write(*,*)'-omiii set full mask of 3D objects not to plot.'
      write(*,*)'-f<id> set dimension whose force to plot'
      write(*,*)'-yfff set range of force plot'

      end
c******************************************************************

