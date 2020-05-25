using Nemo
using DelimitedFiles
using LinearAlgebra

include("src/nemo_utils.jl")

const PRECISION = 256

function parse_eval(expr_str, value, var_name)
    ex = Meta.parse(expr_str)
    svar = :($var_name)
    return @eval begin
        let $svar = $value
            $ex
        end
    end
end

function read_eval(fname, var_name, value)
    a = readdlm(fname, ',', String)
    a .= replace.(a, '/' => "//")
    return parse_eval.(a, value, var_name)
end

function load_discrete_repr(i, q = 109; CC = AcbField(PRECISION))
    ζ = root_of_unity(CC, (q + 1) ÷ 2)
    degree = q - 1

    ra = read_eval(
        "data/Discrete reps PSL(2, $q)/discrete_rep_$(i)_a.txt",
        :Z,
        ζ,
    )
    a = matrix(CC, [CC(s) for s in ra[1:degree, 1:degree]])

    rb = read_eval(
        "data/Discrete reps PSL(2, $q)/discrete_rep_$(i)_b.txt",
        :Z,
        ζ,
    )
    b = matrix(CC, [CC(s) for s in rb[1:degree, 1:degree]])
    @assert contains(det(a), 1)
    @assert contains(det(b), 1)

    return a, b
end

function load_principal_repr(i, q = 109; CC = AcbField(PRECISION))
    ζ = root_of_unity(CC, (q - 1) ÷ 2)
    degree = q + 1

    ra = read_eval(
        "data/Principal reps PSL(2, $q)/principal_rep_$(i)_a.txt",
        :zz,
        ζ,
    )
    a = matrix(CC, [CC(z) for z in ra[1:degree, 1:degree]])

    rb = read_eval(
        "data/Principal reps PSL(2, $q)/principal_rep_$(i)_b.txt",
        :zz,
        ζ,
    )
    b = matrix(CC, [CC(z) for z in rb[1:degree, 1:degree]])
    @assert contains(det(a), 1)
    @assert contains(det(b), 1)

    return a, b
end

if !isinteractive()

    for i = 0:27
        try
            a, b = load_principal_repr(i)
            adjacency = sum(a^i for i = 1:4) + sum(b^i for i = 1:4)
            @time ev = let evs = safe_eigvals(adjacency)
                _count_multiplicites(evs)
            end

            @info "Principal Series Representation $i" ev[1:2] ev[end]
        catch ex
            @error "Principal Series Representation $i failed" ex
            ex isa InterruptException && throw(ex)
        end
    end

    for i = 1:27
        try
            a, b = load_discrete_repr(i)
            adjacency = sum(a^i for i = 1:4) + sum(b^i for i = 1:4)
            @time ev = let evs = safe_eigvals(adjacency)
                _count_multiplicites(evs)
            end

            @info "Discrete Series Representation $i" ev[1:2] ev[end]
        catch ex
            @error "Discrete Series Representation $i : failed" ex
            ex isa InterruptException && rethrow(ex)
        end
    end
end
