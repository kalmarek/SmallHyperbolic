The repository contains code for running experiments for
_Hyperbolic generalized triangle groups_ by
[Pierre-Emmanuel Caprace](https://perso.uclouvain.be/pierre-emmanuel.caprace/),
[Marston Conder](https://www.math.auckland.ac.nz/~conder/),
[Marek Kaluba](https://kalmar.faculty.wmi.amu.edu.pl/) and
[Stefan Witzel](https://www.math.uni-bielefeld.de/~switzel/).

There are two disjoint computations covered in this repository.

## Eigenvalues computations for _PSL₂(p)_

This computations uses package
[RamanujanGraphs.jl](https://github.com/kalmarek/RamanujanGraphs.jl) which
implements (projective, special) linear groups of degree 2 (_PSL₂(p)_, _SL₂(p)_,
_PGL₂(p)_ and _GL₂(p)_) and the irreducible representations for _SL₂(p)_.

The script `adj_psl2_eigvals.jl` computes a subset of irreps of _SL₂(p)_ which
descend to (mostly irreducible) representations of _PSL₂(p)_ in the following
fashion.

### Principal Series

These representations are associated to the induced representations of _B(p)_,
the _Borel subgroup_ (of upper triangular matrices) of _SL₂(p)_.
All representations of the Borel subgroup come from the representations of the
torus inside (i.e. diagonal matrices), hence are _1_-dimensional.

Therefore to define a matrix representation of _SL₂(p)_ one needs to specify:
 * a complex character of 𝔽ₚ (finite field of _p_ elements)
 * an explicit set of representatives of _SL₂(p)/B(p)_.

In code this can be specified by

```julia
p = 109 # our choice of a prime
ζ = root_of_unity((p-1)÷2, ...) # ζ is (p-1)÷2 -th root of unity
# two particular generators of SL₂(109):
a = SL₂{p}([0 1; 108 11])
b = SL₂{p}([57 2; 52 42])

S = [a, b, inv(a), inv(b)] # symmetric generating set
SL2p, _ = RamanujanGraphs.generate_balls(S, radius = 21)

Borel_cosets = RamanujanGraphs.CosetDecomposition(SL2p, Borel(SL₂{p}))
# the generator of 𝔽ₚˣ
α = RamanujanGraphs.generator(RamanujanGraphs.GF{p}(0))

ν₅ = let k = 5 # k runs from 0 to (p-1)÷4, or (p-3)÷4 depending on p (mod 4)
  νₖ = PrincipalRepr(
      α => ζ^k, # character sending α ↦ ζᵏ
      Borel_cosets
    )
end

```

### Discrete Series

These representations are associated with the action of _SL₂(p)_ (or in more
generality of _GL₂(p)_) on ℂ[𝔽ₚ], the vector space of complex valued functions
on 𝔽ₚˣ. There are however multiple choices how to encode such action.

Let _L_ = 𝔽ₚ(√_α_) be the unique quadratic extension of 𝔽ₚ by a square of a
generator _α_ of 𝔽ₚˣ. Comples characters of _Lˣ_ can be separated into
_decomposable_ (the ones that take constant 1 value on the unique cyclic
subgroup of order _(p+1)_ in _Lˣ_) and _nondecomposable_. Each _nondecomposable_
character corresponds to a representation of _SL₂(p)_ in discrete series.

To define matrix representatives one needs to specify
* _χ_:𝔽ₚ⁺ → ℂ, a complex, non-trivial character of the _additive group_ of 𝔽ₚ
* _ν_:_Lˣ_ → ℂ, a complex indecomposable character of _Lˣ_
* a basis for ℂ[𝔽ₚ].

Continuing the snippet above we can write

```julia
α = RamanujanGraphs.generator(RamanujanGraphs.GF{p}(0)) # a generator of 𝔽ₚˣ
β = RamanujanGraphs.generator_min(QuadraticExt(α))
# a generator of _Lˣ_ of minimal "Euclidean norm"

ζₚ = root_of_unity(p, ...)
ζ = root_of_unity(p+1, ...)

ϱ₁₇ = let k = 17 # k runs from 1 to (p-1)÷4 or (p+1)÷4 depending on p (mod 4)
    DiscreteRepr(
    RamanujanGraphs.GF{p}(1) => ζₚ, # character of the additive group of 𝔽ₚ
    β => ζ^k, # character of the multiplicative group of _L_
    basis = [α^i for i in 1:p-1] # our choice for basis: the dual of
)
```

A priori ζ needs to be a complex _(p²-1)_-th root of unity, however one can show
that a reduction to _(p+1)_-th Cyclotomic field is possible.

The script computing eigenvalues should be invoked by running

```bash
julia --project=. adj_psl2_eigvals.jl -p 109
```

The results will be written into `log` directory.

## Sum of squares approach to property (T)

> **NOTE**: This is mostly __unsuccessful computation__ as for none of the groups we examined
the computations returned positive result (with the exception of Ronan's
examples of groups acting on Ã₂-buildings).

We try to find a sum of squares for various finitely presented groups using
julia package [PropertyT.jl](https://github.com/kalmarek/PropertyT.jl). For
full description of the method plesase refer to
[1712.07167](https://arxiv.org/abs/1712.07167).

The groups available are in the `./data` directory in files
`presentations*.txt` files (in Magma format). For example
```
G_8_40_54_2 := Group< a, b, c  |
    a^3, b^3, c^3,
    b*a*b*a,
    (c*b^-1*c*b)^2,
    (c^-1*b^-1*c*b^-1)^2,
    c*a*c^-1*a^-1*c^-1*a*c*a^-1,
    (c*a*c^-1*a)^3>
```
specifies group `G_8_40_54_2` as finitely presented group.

The script needs GAP to be installed on the system (one can set `GAP_EXECUTABLE`
environmental variable to point to `gap` exec). and tries to find both an
automatic structure and a confluent Knuth-Bendix rewriting system on the given
presentation. To attempt sum of squares method for proving property (T) one can
execute
```bash
make 8_40_54_2
```

One can perform those computations in bulk by e.g. calling
```bash
make 2_4_4
```
to run all examples in `presentations_2_4_4.txt` in parallel.
