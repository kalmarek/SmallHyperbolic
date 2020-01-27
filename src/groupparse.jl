function parse_magma_grouppresentation(str::AbstractString)
    m = match(r".*Group<(.*)\|(.*)>", str)
    gens_str = strip.(split(m.captures[1], ", "))
    rels_str = strip.(split(m.captures[2], ", "))
    return parse_magma_grouppresentation(gens_str, rels_str)
end

parse_magma_grouppresentation(gens_str::AbstractString, rels_str::AbstractString) =
    parse_magma_grouppresentation(
        strip.(split(gens_str, ", ")),
        strip.(split(rels_str, ", "))
        )

function parse_magma_grouppresentation(gens_str::AbstractVector{<:AbstractString}, rels_str::AbstractVector{<:AbstractString})
    rels_expr = Meta.parse.(rels_str)
    expr = :([$(rels_expr...)])

    F = FreeGroup(String.(gens_str))
    relations = @eval begin
        a,b,c = AbstractAlgebra.gens($F)
        $expr
    end

    return F/relations
end

function parse_grouppresentations(filename::AbstractString)
    groups_strs = readlines(filename)
    groups = Dict{String, FPGroup}()

    names_idcs = findall(x->startswith(x, "//"), groups_strs)
    push!(names_idcs, length(groups_strs)+1)

    for (first_idx, next_idx) in zip(names_idcs, Iterators.rest(names_idcs, 2))

        m = match(r"//\s?((\d{2}\s?){3}).*", groups_strs[first_idx])
        name = replace(strip(m.captures[1]), " "=>"_")
        for idx in first_idx+1:next_idx-1
            m = match(r"G((_\d\d){3})?_(\d+)\s:=\sGroup<(.*)\|(.*)>", groups_strs[idx])
            if isnothing(m)
                @warn "Can't parse presentation at line $idx:\n $(groups_strs[idx])"
            else
                group_name = "$(name)_$(m.captures[3])"
                G = parse_magma_grouppresentation(m.captures[4], m.captures[5])
                groups[group_name] = G
            end
        end
    end
    return groups
end
