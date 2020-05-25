const libarb = Nemo.libarb

Base.hash(a::acb, h::UInt) = h
Base.reim(x::acb) = reim(convert(ComplexF64, x))

function root_of_unity(CC::AcbField, p, k = 1)
    @assert p > 0
    res = zero(CC)
    ccall(
        (:acb_unit_root, libarb),
        Cvoid,
        (Ref{acb}, Culong, Clong),
        res,
        p,
        prec(CC),
    )
    return res^k
end

import Base.adjoint
function Base.adjoint(m::acb_mat)
    res = zero(m)
    ccall(
        (:acb_mat_conjugate_transpose, libarb),
        Cvoid,
        (Ref{acb_mat}, Ref{acb_mat}),
        res,
        m,
    )
    return res
end

using Random
import Base.rand

rand(rng::AbstractRNG, rs::Random.SamplerTrivial{AcbField}) =
    (CC = rs[]; CC(rand(Float64), rand(Float64)))


import Nemo.acb_struct

mutable struct AcbVector <: AbstractVector{acb_struct}
    ptr::Ptr{acb_struct}
    length::Int
    precision::Int

    function AcbVector(n::Integer, precision::Integer)
        v = new(
            ccall((:_acb_vec_init, libarb), Ptr{acb_struct}, (Clong,), n),
            n,
            precision,
        )
        finalizer(clear!, v)
        return v
    end
end

Base.cconvert(::Type{Ptr{acb_struct}}, acb_v::AcbVector) = acb_v.ptr
Base.size(acb_v::AcbVector) = (acb_v.length,)
Base.precision(acb_v::AcbVector) = acb_v.precision

function clear!(acb_v::AcbVector)
    ccall(
        (:_acb_vec_clear, libarb),
        Cvoid,
        (Ptr{acb_struct}, Clong),
        acb_v,
        length(acb_v),
    )
end

Base.@propagate_inbounds function Base.getindex(acb_v::AcbVector, i::Integer)
    @boundscheck checkbounds(acb_v, i)
    return unsafe_load(acb_v.ptr, i)
end

_get_ptr(acb_v::AcbVector, i::Int = 1) =
    acb_v.ptr + (i - 1) * sizeof(acb_struct)

function AcbVector(v::AbstractVector{acb}, p = prec(parent(first(v))))
    acb_v = AcbVector(length(v), p)
    for (i, val) in zip(eachindex(acb_v), v)
        ccall(
            (:acb_set, libarb),
            Cvoid,
            (Ptr{acb_struct}, Ref{acb}),
            _get_ptr(acb_v, i),
            val,
        )
    end
    return acb_v
end

function approx_eig_qr!(v::AcbVector, R::acb_mat, A::acb_mat)
    ccall(
        (:acb_mat_approx_eig_qr, libarb),
        Cint,
        (
            Ptr{acb_struct},
            Ptr{Cvoid},
            Ref{acb_mat},
            Ref{acb_mat},
            Ptr{Cvoid},
            Int,
            Int,
        ),
        v,
        C_NULL,
        R,
        A,
        C_NULL,
        0,
        prec(parent(A)),
    )
    return v
end

function (C::AcbField)(z::acb_struct)
    res = zero(C)
    ccall((:acb_set, libarb), Cvoid, (Ref{acb}, Ref{acb_struct}), res, z)
    return res
end

function LinearAlgebra.eigvals(A::acb_mat)
    n = nrows(A)
    CC = base_ring(A)
    p = prec(CC)
    λ_approx = AcbVector(n, p)
    R_approx = similar(A)
    v = approx_eig_qr!(λ_approx, R_approx, A)

    λ = AcbVector(n, p)
    b = ccall(
        (:acb_mat_eig_multiple, libarb),
        Cint,
        (Ptr{acb_struct}, Ref{acb_mat}, Ptr{acb_struct}, Ref{acb_mat}, Int),
        λ,
        A,
        λ_approx,
        R_approx,
        p,
    )

    return CC.(λ)
end

function _count_multiplicites(evs)
    λ_m = Vector{Tuple{acb,Int}}()
    sizehint!(λ_m, length(evs))
    i = 1
    while i <= length(evs)
        m = 0
        v = evs[i]
        while i + m <= length(evs) && isequal(evs[i], evs[i+m])
            m += 1
        end
        push!(λ_m, (evs[i], m))
        i += m
    end
    return sort(
        λ_m,
        lt = (a, b) -> (real(first(a)) < real(first(b))),
        rev = true,
    )
end

function safe_eigvals(m::acb_mat)
    evs = eigvals(m)
    all(isfinite.(evs)) && return evs
    CC = base_ring(m)
    X = matrix(CC, rand(CC, size(m)))
    evs = eigvals(X * m * inv(X))
    return evs
    all(isfinite.(evs)) && return evs
    throw(ArgumentError("Could not compute eigenvalues"))
end
