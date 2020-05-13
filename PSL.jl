using Nemo
using DelimitedFiles

include("src/nemo_utils.jl")

function parse_evalZ(arg, expr_str)
    ex = Meta.parse(expr_str)
    return @eval begin
        let Z=$arg
	    $ex
	end
    end
end

function parse_evalzz(arg, expr_str)
    ex = Meta.parse(expr_str)
    return @eval begin
        let zz=$arg
	    $ex
	end
    end
end

function load_discrete_repr(i, q=109; CC=AcbField(512))
    ζ = root_of_unity(CC, (q-1)÷2)
	degree = q-1

	ra = readdlm("data/Discrete reps PSL(2, $q)/discrete_rep_$(i)_a.txt", ',', String)
	a = matrix(CC, [CC(parse_evalZ(ζ, s)) for s in ra[1:degree, 1:degree]])

	rb = readdlm("data/Discrete reps PSL(2, $q)/discrete_rep_$(i)_b.txt", ',', String)
    b = matrix(CC, [CC(parse_evalZ(ζ, s)) for s in rb[1:degree, 1:degree]])

    return a,b
end

function load_principal_repr(i, q=109; CC=AcbField(512))
    ζ = root_of_unity(CC, (q-1)÷2)
	degree = q+1

	ra = readdlm("data/Principal reps PSL(2, $q)/principal_rep_$(i)_a.txt", ',', String)
    a = matrix(CC, [CC(parse_evalzz(ζ, s)) for s in ra[1:degree, 1:degree]])

	rb = readdlm("data/Principal reps PSL(2, $q)/principal_rep_$(i)_b.txt", ',', String)
	b = matrix(CC, [CC(parse_evalzz(ζ, s)) for s in rb[1:degree, 1:degree]])

    return a,b
end

function safe_eigvals(m::acb_mat)
	CC = base_ring(m)
	X = matrix(CC, rand(CC, size(m)))
	return eigvals(X*m*inv(X))
end

for i in 0:27
	try
		a,b = load_principal_repr(i)
		adjacency = sum([[a^i for i in 1:4]; [b^i for i in 1:4]])
		@time evc = safe_eigvals(adjacency)
		ev = sort(real.(first.(evc)), lt=<, rev=true)
		@info "Principal Series Representation $i" ev[1:2]
	catch ex
		@error "Principal Series Representation $i failed"
		ex isa InterruptException && throw(ex)
	end
end

for i in 1:27
	try
		a,b = load_discrete_repr(i)
		adjacency = sum([[a^i for i in 1:4]; [b^i for i in 1:4]])
		@time evc = safe_eigvals(adjacency)
		ev = sort(real.(first.(evc)), lt=<, rev=true)
		@info "Discrete Series Representation $i" ev[1:2]
	catch ex
		@error "Discrete Series Representation $i : failed"
		ex isa InterruptException && rethrow(ex)
	end
end
