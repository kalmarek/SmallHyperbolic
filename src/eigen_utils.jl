function unit_root(order::Integer, pow::Integer = 1; prec = Arblib.DEFAULT_PRECISION[])
    @assert order > 0
    res = Acb(; prec = prec)
    Arblib.unit_root!(res, UInt(order), prec = prec)
    return Arblib.pow!(res, res, pow)
end

similarity_transform(A::AcbMatrix) = similarity_transform!(similar(A), A)

function similarity_transform!(res::AcbMatrix, A::AcbMatrix)
    @assert size(res) == size(A)

    X = similar(A)
    X .= rand(Acb(prec = precision(A)), size(X))

    Arblib.inv!(res, X)
    res = Arblib.mul!(res, A, res)
    res = Arblib.mul!(res, X, res)
    return res
end

function safe_eigvals(A::AcbMatrix)
    λs = Arblib.eig_multiple_rump(similarity_transform(A))
    all(isfinite.(λs)) && return λs
    throw("Eigenvalue computation was not successful: Arblib returned infinite values.")
end

function count_multiplicites(evs)
    λ_m = Vector{Tuple{Acb,Int}}()
    sizehint!(λ_m, length(evs))
    i = 1
    while i <= length(evs)
        m = 0
        v = evs[i]
        while i + m <= length(evs) && isequal(evs[i], evs[i+m])
            m += 1
        end
        @assert m > 0
        push!(λ_m, (evs[i], m))
        i += m
    end
    return sort(λ_m, lt = (a, b) -> (real(first(a)) < real(first(b))), rev = true)
end
