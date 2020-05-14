import Base.reim
reim(x::Nemo.acb) = reim(convert(ComplexF64, x))

function root_of_unity(CC::AcbField, p, k = 1)
    @assert p > 0
    res = zero(CC)
    ccall(
        (:acb_unit_root, Nemo.libarb),
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
        (:acb_mat_conjugate_transpose, Nemo.libarb),
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
const libarb = Nemo.libarb

mutable struct AcbVector <: AbstractVector{acb_struct}
    ptr::Ptr{acb_struct}
    length::Int

    function AcbVector(n::Int)
        v = new(
            ccall((:_acb_vec_init, libarb), Ptr{acb_struct}, (Clong,), n),
            n,
        )
        finalizer(clear!, v)
        return v
    end
end

Base.cconvert(::Type{Ptr{acb_struct}}, acb_v::AcbVector) = acb_v.ptr
Base.size(acb_v::AcbVector) = (acb_v.length,)

function clear!(acb_v::AcbVector)
    ccall(
        (:_acb_vec_clear, libarb),
        Cvoid,
        (Ptr{acb_struct}, Clong),
        acb_v,
        length(acb_v),
    )
end

function (C::AcbField)(z::acb_struct)
    res = zero(C)
    ccall((:acb_set, libarb), Cvoid, (Ref{acb}, Ref{acb_struct}), res, z)
    return res
end

_get_ptr(acb_v::AcbVector, i::Int = 1) =
    acb_v.ptr + (i - 1) * sizeof(acb_struct)

Base.@propagate_inbounds function Base.getindex(acb_v::AcbVector, i::Integer)
    @boundscheck checkbounds(acb_v, i)
    return unsafe_load(acb_v.ptr, i)
end

function AcbVector(v::AbstractVector{Nemo.acb})
    acb_v = AcbVector(length(v))
    for (i, val) in zip(eachindex(acb_v), v)
        ccall(
            (:acb_set, libarb),
            Cvoid,
            (Ptr{acb_struct}, Ref{Nemo.acb}),
            _get_ptr(acb_v, i),
            val,
        )
    end
    return acb_v
end

function approx_eig_qr!(v::AcbVector, R::acb_mat, A::acb_mat)
    n = nrows(A)
    ccall(
        (:acb_mat_approx_eig_qr, Nemo.libarb),
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

function LinearAlgebra.eigvals(A::Nemo.acb_mat)
    n = nrows(A)
    λ_approx = AcbVector(n)
    R_approx = similar(A)
    v = approx_eig_qr!(λ_approx, R_approx, A)

    λ = AcbVector(n)
    b = ccall(
        (:acb_mat_eig_multiple, Nemo.libarb),
        Cint,
        (Ptr{acb_struct}, Ref{acb_mat}, Ptr{acb_struct}, Ref{acb_mat}, Int),
        λ,
        A,
        λ_approx,
        R_approx,
        prec(base_ring(A)),
    )

    CC = base_ring(A)
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
    return λ_m
end
