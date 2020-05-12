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
