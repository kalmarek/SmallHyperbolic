using RamanujanGraphs
using LinearAlgebra
using Nemo

using Logging
using Dates

include("src/nemo_utils.jl")

function SL2p_gens(p)
    if p == 31
        a, b = let
            a = SL₂{p}([8 14; 4 11])
            b = SL₂{p}([23 0; 14 27])
            @assert isone(a^10)
            @assert isone(b^10)

            a, b
        end
    elseif p == 41
        a, b = let
            a = SL₂{p}([19 26; 29 16])
            b = SL₂{p}([0 20; 2 6])
            @assert isone(a^10)
            @assert isone(b^10)

            a, b
        end
    elseif p == 59
        a, b = let
            a = SL₂{p}([32 12; 20 2])
            b = SL₂{p}([14 18; 45 20])
            @assert isone(a^10)
            @assert isone(b^10)

            a, b
        end
    elseif p == 109
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

    return a,b
end

function adjacency(ϱ, CC, a, b)
    A = matrix(CC, ϱ(a))
    B = matrix(CC, ϱ(b))

    return sum(A^i for i = 1:4) + sum(B^i for i = 1:4)
end

const p = try
    @assert length(ARGS) == 2 && ARGS[1] == "-p"
    p = parse(Int, ARGS[2])
    RamanujanGraphs.Primes.isprime(p)
    p
catch ex
    @error "You need to provide a prime, ex: `julia adj_psl2_eigvals.jl -p 31`"
    rethrow(ex)
end

const LOGFILE = "SL(2,$p)_eigvals_$(now()).log"

open(joinpath("log", LOGFILE), "w") do io
    with_logger(SimpleLogger(io)) do

        CC = AcbField(128)

        a,b = SL2p_gens(p)

        Borel_cosets = let p = p, (a,b) = (a,b)
            SL2p, sizes =
                RamanujanGraphs.generate_balls([a, b, inv(a), inv(b)], radius = 21)
            @assert sizes[end] == RamanujanGraphs.order(SL₂{p})
            RamanujanGraphs.CosetDecomposition(SL2p, Borel(SL₂{p}))
        end

        all_large_ev = []

        let α = RamanujanGraphs.generator(RamanujanGraphs.GF{p}(0))

            for j = 0:(p-1)÷4
                h = PrincipalRepr(
                    α => root_of_unity(CC, (p - 1) ÷ 2, j),
                    Borel_cosets,
                )

                @time adj = adjacency(h, CC, a, b)

                try
                    @time ev = let evs = safe_eigvals(adj)
                        _count_multiplicites(evs)
                    end

                    @info "Principal Series Representation $j" ev[1:2] ev[end]
                    all_large_ev = vcat(all_large_ev, ev[1:2])
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
                ζ = root_of_unity(CC, (p + 1) ÷ 2, 1)
            else # p % 4 == 3
                ub = (p + 1) ÷ 4
                ζ = root_of_unity(CC, (p + 1), 1)
            end

            for k = 1:ub

                h = DiscreteRepr(
                    RamanujanGraphs.GF{p}(1) => root_of_unity(CC, p),
                    β => ζ^k,
                )

                @time adj = adjacency(h, CC, a, b)

                try
                    @time ev = let evs = safe_eigvals(adj)
                        _count_multiplicites(evs)
                    end

                    @info "Discrete Series Representation $k" ev[1:2] ev[end]
                    all_large_ev = vcat(all_large_ev, ev[1:2])
                catch ex
                    @error "Discrete Series Representation $k : failed" ex
                    ex isa InterruptException && rethrow(ex)
                end
            end
            print(all_large_ev)
#            all_large_ev = sort(all_large_ev, rev=true)
#            lambda = all_large_ev[2]
#            print(lambda, " ", (lambda - 3)/5, " ", acos((lambda-3)/5), " ", acos((lambda-3)/5)/pi*180)
        end
    end # with_logger
end # open(logfile)

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
