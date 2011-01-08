c Common data containing the object geometry information. 
c Each object, i < 31 has: type, data(odata).
      integer ngeomobjmax,odata,ngeomobj
      parameter (ngeomobjmax=31)
c Reference to the index of certain object parameters:
      integer otype,ocenter,oradius,oabc,ocylaxis,ovec,ocontra
      parameter (otype=1,oabc=2,ocenter=5,oradius=8,ocylaxis=11)
c   parallelopiped vectors start at oradius, contravariant +9
      parameter (ovec=oradius,ocontra=oradius+9)
c Fluxes for spheres only at the moment
      integer ofluxtype,ofn1,ofn2,ofn3,offc,omag
      parameter (ofluxtype=ocontra+9)
      parameter (ofn1=ofluxtype+1,ofn2=ofluxtype+2,ofn3=ofluxtype+3)
      parameter (omag=ofluxtype+1,offc=ofluxtype+4)
      parameter (odata=offc)
c The parallelopiped data structure in ppcom.f consists of
c 1 pp_orig : origin x_0 (3) which points to ocenter
c 4 pp_vec : 3 (covariant) vectors v_p equal half the edges.(3x3)
c 13 pp_contra : 3 contravariant vectors v^q such that v_p.v^q =
c \delta_{pq} (3x3)
c A pp_total of 21 reals (in 3-D), of which the last 9 can be calculated
c from the first 12, but must have been set prior to the call. 
c A point is inside the pp if |Sum_i(x_i-xc_i).v^p_i|<1 for all p.
c A point is on the surface if, in addition, equality holds in at least
c one of the (6) relations. 
c [i-k refers to cartesian components, p-r to pp basis.] 
      integer pp_ndims,pp_orig,pp_vec,pp_contra,pp_total
      parameter (pp_ndims=3,pp_orig=ocenter)
      parameter (pp_vec=pp_orig+pp_ndims)
      parameter (pp_contra=pp_vec+pp_ndims*pp_ndims)
      parameter (pp_total=pp_contra+pp_ndims*pp_ndims-1)

      real obj_geom(odata,ngeomobjmax)
c
c Mapping from obj_geom object number to nf_flux object (many->fewer)
c Zero indicates no flux tracking for this object.
      integer nf_map(ngeomobjmax)

c Ibool defining region of particles.
      integer ibtotal_part
      parameter (ibtotal_part=100)
      integer ibool_part(ibtotal_part)
c Mask defining the objects (bits) relevant to field regions.
      integer ifield_mask
c Mask defining objects that are of special point-charge type.
      integer iptch_mask
c Has the particle region got an enclosed region
      logical lboundp
c What is the reinjection scheme?
      character*50 rjscheme

      common /objgeomcom/ngeomobj,obj_geom,nf_map
     $     ,ibool_part,ifield_mask,iptch_mask,lboundp,rjscheme
c
c Data that describes the flux to positions on the objects:
      integer nf_quant,nf_obj,nf_maxsteps,nf_datasize
c Number of dimensions needed for position descriptors
c      parameter (nf_posdim=2)
      parameter (nf_posdim=3)
c Maximum (i.e. storage size) of array 
      parameter (nf_quant=5,nf_obj=5,nf_maxsteps=3000)
      parameter (nf_datasize=10000000)
c Mnemonics for quantities:
      parameter (nf_flux=1,nf_gx=2,nf_gy=3,nf_gz=4,nf_heat=5)
c Actual numbers of quantities, objects and steps <= maxes.
      integer nf_step,mf_quant(nf_obj),mf_obj
c The number of positions at which this quantity is measured:
      integer nf_posno(nf_quant,nf_obj)
c The dimensional structure of these: nf_posno = prod nf_dimlens
      integer nf_dimlens(nf_quant,nf_obj,nf_posdim)
c The offset index to the start of cube faces
      integer nf_faceind(nf_quant,nf_obj,2*nf_posdim)
c Reverse mapping to the geomobj number from nf_obj number
      integer nf_geommap(nf_obj)
c The address of the data-start for the quantity, obj, step.
      integer nf_address(nf_quant,nf_obj,1-nf_posdim:nf_maxsteps)
c The heap where the data actually lies.
      real ff_data(nf_datasize)
c The rhoinfin for each step 
      real ff_rho(nf_maxsteps)
c The dt for each step
      real ff_dt(nf_maxsteps)

      common /fluxdata/nf_step,ff_rho,ff_dt,mf_quant,mf_obj,nf_posno
     $     ,nf_dimlens,nf_faceind,nf_geommap,nf_address,ff_data


c Flux explanation:
c There are 
c   mf_quant quantities to be recorded for each of
c   mf_obj objects, for each of
c   nf_step steps
c   nf_address points to the start of data for quant, obj, step.
c     the value of nf_address(1,1,1-nf_posdim) is 1
c     i.e. the address is 1-based, not 0-based.
c   For each step, there are 
c     nf_posno positions on the object where quantities are recorded.
c ff_data is the heap of data.
c
c Steps 1-nf_posdim:0 stores the quantitative position information. 
c where nf_posdim is the number of dimensions in position info.


c Data for storing integrated field quantities such as forces.
      integer ns_ndims
      parameter (ns_ndims=3)
      integer ns_nt,ns_np
c the size of the stress-calculating mesh in theta and psi directions
      parameter (ns_nt=6,ns_np=6)
      integer ns_flags(nf_obj)
      real fieldforce(ns_ndims,nf_obj,nf_maxsteps)
      real pressforce(ns_ndims,nf_obj,nf_maxsteps)
      real partforce(ns_ndims,nf_obj,nf_maxsteps)
      real charge_ns(nf_obj,nf_maxsteps)
      real surfobj(2*ns_ndims,ns_nt,ns_np,nf_obj)
      common /stress/ns_flags,surfobj,fieldforce,pressforce
     $     ,partforce,charge_ns

c External field data (when used)
      logical lextfield
      real extfield(ns_ndims)
      common /extfieldcom/lextfield,extfield
