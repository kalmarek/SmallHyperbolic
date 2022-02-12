struct TriangleGrp
    half_girth_type::NTuple{3,Int}
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
    maximal_degree_alternating_quotients::Int
end

_name(G) = "G_$(G.order1)_$(G.order2)_$(G.order3)_$(G.index)"
name(G::TriangleGrp) = _name(G)
grp_name(nt::NamedTuple) = _name(nt)

latex_name(G::TriangleGrp) = "G^{$(G.order1),$(G.order2),$(G.order3)}_$(G.index)"

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

function _sanitize_group_name(s::AbstractString)
    s = replace(s, '$'=>"")
    s = replace(s, "\\infty"=>"inf")
    s = replace(s, r"\\textrm{(.*?)}"=>s"\1")
    s = replace(s, r"(Alt)_{(\d+)}"=>s"\1(\2)")
    s = replace(s, "_{}"=>"")
    return s
end

function _delatexify(dict)
    map(dict) do (key, val)
        key = _sanitize_group_name(key)
        key = replace(key, r"_{(\d+)}"=>s"\1")
        key = replace(key, "{}^"=>"")
        key => val
    end |> Dict
end

function TriangleGrp(half_girth_type::NTuple{3,Int}, generators, relations, nt::NamedTuple)
    # @assert fieldnames(SmallHyperbolicGrp) == propertynames(nt)
    hyperbolic, witness = _ishyperbolic(half_girth_type, nt)

    l2_quotients = let v = _sanitize_group_name.(parse_vec(String, nt.L2_quotients))
        if isempty(v) || (length(v)==1 && isempty(first(v)))
            Vector{String}()
        else
            String.(v)
        end
    end

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
        l2_quotients,
        [Pair(_sanitize_group_name(p[1]), p[2]) for p in parse_vec(Tuple{String,Int}, nt.quotients)],
        parse_vec(Int, nt.alternating_quotients),
        convert(Int, nt.maximal_order_for_alternating_quotients),
    )
end

import DataStructures

import JSON.Serializations: CommonSerialization, StandardSerialization
import JSON.Writer: StructuralContext, show_json
struct TriangleGrpSerialization <: CommonSerialization end

function subscriptify(n::Integer)
    n, sgn = abs(n), sign(n)
    # Char(0x2080) == '₀'
    s = join(Char(0x2080+d) for d in reverse(digits(n)))
    return sgn >= 0 ? s : "₋"*s
end

function superscriptify(n::Integer)
    n, sgn = abs(n), sign(n);
    # (Char(0x2070), '¹', '²', '³', [Char(0x2070+i) for i in 4:9]...)
    dgts = ('⁰', '¹', '²', '³', '⁴', '⁵', '⁶', '⁷', '⁸', '⁹')
    s = join(dgts[d+1] for d in reverse(digits(n)))
    return sgn >= 0 ? s : "⁻"*s
end

function _to_utf8(s::AbstractString)
    s = _sanitize_group_name(s)
    while (m = match(r"(_{(-?\d+)}|_(\d))", s)) !== nothing
        n = parse(Int, something(m[2], m[3]))
        s = replace(s, m[1]=>subscriptify(n))
    end
    while (m = match(r"(\^{(-?\d+)}|\^(\d))", s)) !== nothing
        n = parse(Int, something(m[2], m[3]))
        s = replace(s, m[1]=>superscriptify(n))
    end
    if (m = match(r"G(\^{(\d+),(\d+),(\d+)})", s)) !== nothing
        i,j,k = superscriptify.(parse.(Int, (m[2], m[3], m[4])))
        s = replace(s, m[1] => "$(i)'$(j)'$(k)")
    end
    s = replace(s, "{}"=>"")
    return s
end

function show_json(io::StructuralContext, ::TriangleGrpSerialization, G::TriangleGrp)
    D = DataStructures.OrderedDict{Symbol,Any}(:name => latex_name(G))
    D[:name_utf8] = _to_utf8(D[:name])
    for fname in fieldnames(TriangleGrp)
        D[fname] = getfield(G, fname)
    end
    D[:L2_quotients_utf8] = _to_utf8.(D[:L2_quotients])
    D[:quotients_utf8] = Dict(_to_utf8(k) => v for (k,v) in D[:quotients])
    D[:quotients_plain] =  _delatexify(D[:quotients])
    D[:quotients] = Dict(D[:quotients])
    return show_json(io, StandardSerialization(), D)
end
