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

function TriangleGrp(type::NTuple{3,Int}, generators, relations, nt::NamedTuple)
    # @assert fieldnames(SmallHyperbolicGrp) == propertynames(nt)
    hyperbolic, witness = if hasproperty(nt, :hyperbolic)
        h = _tf_missing(nt.hyperbolic)
        nh_w = nt.witnesses_for_non_hyperbolicity
        w = isempty(strip(nh_w)) ? missing : parse_vec(String, '[' * nh_w * ']')
        h, w
    elseif 1 // nt.order1 + 1 // nt.order2 + 1 // nt.order3 < 1
        true, missing
    else
        missing, missing
    end

    TriangleGrp(
        type,
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


