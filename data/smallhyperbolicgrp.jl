struct TriangleGrp
    type::NTuple{3,Int}
    generators::Vector{String}
    relations::Vector{String}
    order1::Int
    order2::Int
    order3::Int
    index::Int
    presentation_length::Int
    hyperbolic::Union{Missing,Bool}
    witnesses_non_hyperbolictity::Union{Missing,Vector{String}}
    virtually_torsion_free::Union{Missing,Bool}
    Kazdhdan_property_T::Union{Missing,Bool}
    abelianization_dimension::Int
    L2_quotients::Vector{String}
    quotients::Vector{Pair{String,Int}}
    alternating_quotients::Vector{Int}
    maximal_order_alt_quo::Int
end

_name(G) = "G_$(G.order1)_$(G.order2)_$(G.order3)_$(G.index)"
name(G::TriangleGrp) = _name(G)
grp_name(nt::NamedTuple) = _name(nt)

latex_name(G::TriangleGrp) = "\$G^{$(G.order1),$(G.order2),$(G.order3)}_$(G.index)"

function _ishyperbolic(half_girth_type, nt::NamedTuple)
    a, b, c = half_girth_type
    if 1 // a + 1 // b + 1 // c < 1
        return true, missing
    elseif hasproperty(nt, :hyperbolic)
        hyperbolic = _tf_missing(nt.hyperbolic)
        nh_witnesses = let w = strip(nt.witnesses_for_non_hyperbolicity)
            isempty(w) ? missing : parse_vec(String, '[' * w * ']')
        end
        @debug "$(nt.hyperbolic) was parsed as $hyperbolic" nh_witnesses
        if hyperbolic isa Bool && hyperbolic
            @assert ismissing(nh_witnesses)
        end
        if !ismissing(nh_witnesses)
            @assert !hyperbolic
        end
        return hyperbolic, nh_witnesses
    else
        return missing, missing
    end
end

function TriangleGrp(half_girth_type::NTuple{3,Int}, generators, relations, nt::NamedTuple)
    # @assert fieldnames(SmallHyperbolicGrp) == propertynames(nt)
    hyperbolic, witness = _ishyperbolic(half_girth_type, nt)

    TriangleGrp(
        half_girth_type,
        convert(Vector{String}, generators),
        convert(Vector{String}, relations),
        convert(Int, nt.order1),
        convert(Int, nt.order2),
        convert(Int, nt.order3),
        convert(Int, nt.index),
        convert(Int, nt.presentation_length),
        hyperbolic,
        witness,
        _tf_missing(nt.virtually_torsion_free),
        _tf_missing(nt.Kazhdan),
        convert(Int, nt.abelianization_dimension),
        parse_vec(String, nt.L2_quotients),
        [Pair(p...) for p in parse_vec(Tuple{String,Int}, nt.quotients)],
        parse_vec(Int, nt.alternating_quotients),
        convert(Int, nt.maximal_order_for_alternating_quotients),
    )
end

import DataStructures

import JSON.Serializations: CommonSerialization, StandardSerialization
import JSON.Writer: StructuralContext, show_json
struct TriangleGrpSerialization <: CommonSerialization end

function show_json(io::StructuralContext, ::TriangleGrpSerialization, G::TriangleGrp)
    D = DataStructures.OrderedDict{Symbol,Any}(:name => latex_name(G))
    for fname in fieldnames(TriangleGrp)
        D[fname] = getfield(G, fname)
    end
    return show_json(io, StandardSerialization(), D)
end
