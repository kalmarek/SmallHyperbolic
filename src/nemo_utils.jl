import Base.reim
reim(x::Nemo.acb) = reim(convert(ComplexF64, x))

function root_of_unity(CC::AcbField, p, k=1)
    @assert p > 0
    res = zero(CC)
    ccall((:acb_unit_root, Nemo.libarb), Cvoid, (Ref{acb}, Culong, Clong), res, p, prec(CC))
    return res^k
end

import Base.adjoint
function Base.adjoint(m::acb_mat)
    res = zero(m)
    ccall((:acb_mat_conjugate_transpose, Nemo.libarb),
        Cvoid, (Ref{acb_mat}, Ref{acb_mat}), res, m)
    return res
end

using Random
import Base.rand

rand(rng::AbstractRNG, rs::Random.SamplerTrivial{AcbField}) = (CC = rs[]; CC(rand(Float64), rand(Float64)))
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

