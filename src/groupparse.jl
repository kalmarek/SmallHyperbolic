comm(a,b) = inv(a)*inv(b)*a*b
comm(a,b,args...) = comm(comm(a,b), args...)

const MAGMA_PRESENTATION_regex = r"Group<\s?(?<gens>.*)\s?\|\s?(?<rels>.*)\s?>"
const COMMUTATOR_regex = r"\((?<comm>[\w](\s?,\s?[\w]){1+})\)"
iscomment(line) = startswith(line, "//")
ismagma_presentation(line) = (m = match(MAGMA_PRESENTATION_regex, line); return !isnothing(m), m)



function split_magma_presentation(str::AbstractString)
    m = match(MAGMA_PRESENTATION_regex, str)
    gens_str = strip.(split(m[:gens], ","))
    rels_str = m[:rels]
    split_indices = [0]
    in_function_call = 0
    for (i, s) in enumerate(rels_str)
        if s == '('
            in_function_call += 1
        elseif s == ')'
            @assert in_function_call > 0
            in_function_call -= 1
        elseif s == ',' && iszero(in_function_call)
            push!(split_indices, i)
        end
    end
    @assert in_function_call == 0
    push!(split_indices, length(rels_str) + 1)

    rels_strs = [
        strip.(String(rels_str[s+1:e-1])) for
        (s, e) in zip(split_indices, Iterators.rest(split_indices, 2))
    ]

    # rels_strs = replace.(rels_strs, COMMUTATOR_regex=> s"comm(\g<comm>)")
    # @show rels_strs
    return gens_str, rels_strs
end

function parse_magma_fpgroup(str::AbstractString)
    gens_str, rels_strs = split_magma_presentation(str)
    return parse_magma_fpgroup(gens_str, rels_strs)
end

function parse_magma_fpgroup(gens_str::AbstractVector{<:AbstractString}, rels_str::AbstractVector{<:AbstractString})

    gens_arr = Symbol.(gens_str)
    gens_expr = Expr(:tuple, gens_arr...)

    rels_arr = Meta.parse.(rels_str)
    rels_expr = :([$(rels_arr...)])

    F = FreeGroup(String.(gens_str))
    relations = @eval begin
        $gens_expr = AbstractAlgebra.gens($F);
        $rels_expr
    end

    return F/relations
end

function parse_grouppresentations(filename::AbstractString)
    lines = strip.(readlines(filename))
    groups = Dict{String, FPGroup}()
    group_regex = r"(?<name>\w.*)\s?:=\s?(?<group_str>Group.*)"
    for line in lines
        isempty(line) && continue
        iscomment(line) && continue
        m = match(group_regex, line)
        if isnothing(m)
            @warn "Can't parse presentation line\n $line"
            continue
        else
            name = strip(m[:name])
            group_str = m[:group_str]
            G = parse_magma_fpgroup(group_str)
            if startswith(name, "G_")
                name = name[3:end]
            end
            groups[name] = G
        end
    end
    return groups
end
