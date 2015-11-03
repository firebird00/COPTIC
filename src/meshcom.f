      include 'griddecl.f'
c Mesh specification data that get translated into the position data below
      integer nspec_mesh
      parameter (nspec_mesh=10)
      integer imeshstep(ndims,nspec_mesh)
      real xmeshpos(ndims,nspec_mesh)
      common /meshspec/imeshstep,xmeshpos
c Mesh position data needed for non-uniform meshes to calculate cij
c inline x(iused(1)),y(iused(2)), etc. Specify sufficient length,
c at least the sum of the dimension lengths.
      integer ixnlength
c      parameter (ixnlength=1000)
      parameter (ixnlength=na_i+na_j+na_k+1)
      real xn(ixnlength)
c Pointer to the start of the dimension vector, which is xn(ixnp(id)+1)
c ixnp(id)+1 is the start of each dimension vector.
c ixnp(id+1)-ixnp(id) is the length of dimension id.
c Last element points to the last element of the last dimension, which
c is equal to the total length used of xn.
      integer ixnp(ndims+1)
      real xmeshstart(ndims),xmeshend(ndims)
      integer ipilen
      parameter (ipilen=200)
      integer iposindex(ipilen,ndims)
      common /sormesh/ixnp,xn,xmeshstart,xmeshend,iposindex
