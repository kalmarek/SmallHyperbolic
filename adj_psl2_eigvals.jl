using RamanujanGraphs
using LinearAlgebra
using Nemo

include("src/nemo_utils.jl")

const p = try
    @assert length(ARGS) == 2 && ARGS[1] == "-p"
    p = parse(Int, ARGS[2])
    RamanujanGraphs.Primes.isprime(p)
    p
catch ex
    @error "You need to provide a prime `-p` which is congruent to 1 mod 4."
    rethrow(ex)
end

const CC = AcbField(256)

SL2p = let
    if p == 109
        a, b = let
            a = SL₂{p}([0 1; 108 11])
            b = SL₂{p}([57 2; 52 42])
            @assert isone(a^10)
            @assert isone(b^10)

            a, b
        end
    elseif p == 131
        a, b = let
            a = SL₂{p}([-58 -24; -58 46])
            b = SL₂{p}([0 -3; 44 -12])
            @assert isone(a^10)
            @assert isone(b^10)

            a, b
        end
    else
        @warn "no special set of generators for prime $p"
        a, b = let
            a = SL₂{p}(1, 0, 1, 1)
            b = SL₂{p}(1, 1, 0, 1)
            a, b
        end
    end

    E, sizes =
        RamanujanGraphs.generate_balls([a, b, inv(a), inv(b)], radius = 21)
    @assert sizes[end] == RamanujanGraphs.order(SL₂{p})
    E
end

let Borel_cosets = Bcosets = RamanujanGraphs.CosetDecomposition(SL2p, Borel(SL₂{p})),
    α = RamanujanGraphs.generator(RamanujanGraphs.GF{p}(0))

    for j in 0:(p-1)÷4
        try
            h = PrincipalRepr(
                α => root_of_unity(CC, (p-1)÷2, j),
                Borel_cosets)

            @time adjacency = let
                A = matrix(CC, h(SL2p[2]))
                B = matrix(CC, h(SL2p[3]))
                sum(A^i for i in 1:4) + sum(B^i for i in 1:4)
            end

            @time ev = let evs = safe_eigvals(adjacency)
                _count_multiplicites(evs)
            end
            if length(ev) == 1
                @info "Principal Series Representation $j" ev[1]
            else
                @info "Principal Series Representation $j" ev[1:2] ev[end]
            end
        catch ex
            @error "Principal Series Representation $j failed" ex
            ex isa InterruptException && rethrow(ex)
        end
    end
end

let α = RamanujanGraphs.generator(RamanujanGraphs.GF{p}(0)),
    β = RamanujanGraphs.generator_min(QuadraticExt(α))

    if p % 4 == 1
        ub = (p - 1) ÷ 4
        ζ = root_of_unity(CC, (p + 1) ÷ 2, (p - 1) ÷ 4)
    else # p % 4 == 3
        ub = (p + 1) ÷ 4
        ζ = root_of_unity(CC, (p + 1), 1)
    end

    for k = 1:ub
        try
            h = DiscreteRepr(
                RamanujanGraphs.GF{p}(1) => root_of_unity(CC, p),
                β => ζ^k,
            )

            @time adjacency = let
                A = matrix(CC, h(SL2p[2]))
                B = matrix(CC, h(SL2p[3]))
                sum(A^i for i = 1:4) + sum(B^i for i = 1:4)
            end

            @time ev = let evs = safe_eigvals(adjacency)
                _count_multiplicites(evs)
            end

            @info "Discrete Series Representation $k" ev[1:2] ev[end]
        catch ex
            @error "Discrete Series Representation $k : failed" ex
            ex isa InterruptException && rethrow(ex)
        end
    end
end

#
# using RamanujanGraphs.LightGraphs
# using Arpack
#
# Γ, eigenvalues = let p = 109,
#     a = PSL₂{p}([  0  1; 108  11]),
#     b = PSL₂{p}([ 57  2;  52  42])
#
#     S = unique([[a^i for i in 1:4]; [b^i for i in 1:4]])
#
#     @info "Generating set S of $(eltype(S))" S
#     @time Γ, verts, vlabels, elabels =
#         RamanujanGraphs.cayley_graph(RamanujanGraphs.order(PSL₂{p}), S)
#
#     @assert all(LightGraphs.degree(Γ,i) == length(S) for i in vertices(Γ))
#     @assert LightGraphs.nv(Γ) == RamanujanGraphs.order(PSL₂{p})
#     A = adjacency_matrix(Γ)
#     @time eigenvalues, _ = eigs(A, nev=5)
#     @show Γ eigenvalues
#     Γ, eigenvalues
# end
#
# let p = 131,
#     a = PSL₂{p}([-58 -24; -58 46]),
#     b = PSL₂{p}([0 -3; 44 -12])
#
#     S = unique([[a^i for i in 1:4]; [b^i for i in 1:4]])
#
#     @info "Generating set S of $(eltype(S))" S
#     @time Γ, verts, vlabels, elabels =
#         RamanujanGraphs.cayley_graph(RamanujanGraphs.order(PSL₂{p}), S)
#
#     @assert all(LightGraphs.degree(Γ,i) == length(S) for i in vertices(Γ))
#     @assert LightGraphs.nv(Γ) == RamanujanGraphs.order(PSL₂{p})
#     A = adjacency_matrix(Γ)
#     @time eigenvalues, _ = eigs(A, nev=5)
#     @show Γ eigenvalues
#     Γ, eigenvalues
# end
