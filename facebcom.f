c Common data for specification of potential boundary conditions on the 
c faces of the box.
c  LF whether we are using face boundary conditions.
c  LPF whether the condition is periodic in this dimension.
c  LCF whether for a non-periodic face, the coefficient C of the BC varies 
c      with position. If so, then 
c  CxyzF are the coefficients such that 
c  C = C0F + Sum_id CxyzF(id,idn)*xn(ixnp(id)+indi(id)+1)
c  AF BF are the other coefficients AF phi + BF dphi/dn + C =0
c  If BF=0, then A is assumed =1. Otherwise precalculated coeffs are used
c  AmBF= (A/2-B/dn), ApBF= (A/2+B/dn) where dn is the outward mesh step. 
c  The precalculations are done in bdyfaceinit. 
c  AmBF ApBF are internal and ought not to be altered.

c Requires ndimsdecl.f
      logical LF,LCF(2*ndims),LPF(ndims)
      real AF(2*ndims),BF(2*ndims)
      real C0F(2*ndims),CxyzF(ndims,2*ndims)
      real ApBF(2*ndims),AmBF(2*ndims)
      common /FaceBC/LF,LCF,LPF,AF,BF,C0F,CxyzF,ApBF,AmBF
