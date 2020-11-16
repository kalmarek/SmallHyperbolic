using RamanujanGraphs
using LinearAlgebra
using Arblib
using ArgParse

using Logging
using Dates

import RamanujanGraphs.Primes: isprime

include(joinpath(@__DIR__, "src", "eigen_utils.jl"))

function SL2p_gens(p::Integer)
    @assert isprime(p)
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
            a = SL₂{p}([0 28; 19 35])
            b = SL₂{p}([38 27; 2 9])
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

function adjacency(ϱ, a, b; prec=256)
    order_a = findfirst(i-> isone(a^i), 1:100)
    order_b = findfirst(i-> isone(b^i), 1:100)
    @assert !isnothing(order_a) && order_a > 1
    @assert !isnothing(order_b) && order_b > 1

    k = order_a-1 + order_b-1

    A = AcbMatrix(ϱ(a), prec=prec)
    B = AcbMatrix(ϱ(b), prec=prec)
    res = sum(A^i for i = 1:order_a-1) + sum(B^i for i = 1:order_b-1)
    return Arblib.scalar_div!(res, res, k)
end

function parse_our_args()
    s = ArgParseSettings()
    @add_arg_table! s begin
        "-p"
            help = "the prime p for which to use PSL(2,p)"
            arg_type = Int
            required = true
        "-a"
            help = "generator a (optional)"
        "-b"
            help = "generator b (optional)"
        "--ab"
            help = "array of generators a and b (optional)"
        "--precision"
            help = "set the precision of computations"
            arg_type = Int
            default = 128
    end

    result = parse_args(s)
    for key in ["a", "b", "ab"]
        val = get(result, key, "")
        if val != nothing
            result[key] = eval(Meta.parse(val))
        else
            delete!(result, key)
        end
    end
    val = get(result, "ab", "")
    if val != ""
        result["a"] = val[1]
        result["b"] = val[2]
    end
    result
end

parsed_args = parse_our_args()

const p = let p = parsed_args["p"]
    isprime(p) || @error "You need to provide a prime, ex: `julia adj_psl2_eigvals.jl -p 31`"
    p
end

const PRECISION = parsed_args["precision"]
const LOGFILE = joinpath("log", "SL(2,$p)_eigvals_$(now()).log")

open(LOGFILE, "w") do io
    @info "Logging into $LOGFILE"
    with_logger(SimpleLogger(io)) do

        @info "Arguments:" args=parsed_args

        a,b = SL2p_gens(p)
        a = SL₂{p}(get(parsed_args, "a", a))
        b = SL₂{p}(get(parsed_args, "b", b))
        @info "Generators" a b

        Borel_cosets = let p = p, (a,b) = (a,b)
            SL2p, sizes =
                RamanujanGraphs.generate_balls([a, b, inv(a), inv(b)], radius = 21)
            @assert sizes[end] == RamanujanGraphs.order(SL₂{p})
            RamanujanGraphs.CosetDecomposition(SL2p, Borel(SL₂{p}))
        end

        all_large_evs = Arb[]
        let α = RamanujanGraphs.generator(RamanujanGraphs.GF{p}(0))

            for j = 0:(p-1)÷4
                h = PrincipalRepr(
                    α => unit_root((p - 1) ÷ 2, j, prec=PRECISION),
                    Borel_cosets,
                )

                @time adj = adjacency(h, a, b, prec=PRECISION)

                try
                    @time evs = let evs = safe_eigvals(adj)
                        count_multiplicites(evs)
                    end
                    append!(all_large_evs, [real(first(x)) for x in evs[1:2]])

                    @info "Principal Series Representation $j" evs[1:2] evs[end]
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
                ζ = unit_root((p + 1) ÷ 2, 1, prec=PRECISION)
            else # p % 4 == 3
                ub = (p + 1) ÷ 4
                ζ = unit_root((p + 1), 1, prec=PRECISION)
            end

            for k = 1:ub

                h = DiscreteRepr(
                    RamanujanGraphs.GF{p}(1) => unit_root(p, prec=PRECISION),
                    β => ζ^k,
                )

                @time adj = adjacency(h, a, b, prec=PRECISION)

                try
                    @time evs = let evs = safe_eigvals(adj)
                        count_multiplicites(evs)
                    end
                    append!(all_large_evs, [real(first(x)) for x in evs[1:2]])

                    @info "Discrete Series Representation $k" evs[1:2] evs[end]
                catch ex
                    @error "Discrete Series Representation $k : failed" ex
                    ex isa InterruptException && rethrow(ex)
                end
            end
        end
        all_large_evs = sort(all_large_evs, rev=true)
        λ = all_large_evs[2]
        ε = (λ - 3)/5
        α = acos(ε)
        α_deg = (α/pi)*180
        @info "Certified values:" λ ε α α_deg
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
