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
    push!(names_idcs, names_idcs[end]+1)

    for (first_idx, next_idx) in zip(names_idcs, Iterators.rest(names_idcs, 2))

        m = match(r"//\s?((\d{2}\s){2}\d\d).*", groups_strs[first_idx])

        name = replace(m.captures[1], " "=>"_")
        for idx in first_idx+1:next_idx-1
            m = match(r"(.*)\s:=\sGroup<(.*)\|(.*)>", groups_strs[idx])
            if isnothing(m)
                @warn "Can't parse presentation at line $idx:\n $(str[idx])"
            else
                group_name = "$(name)_$(m.captures[1])"
                G = parse_magma_grouppresentation(m.captures[2], m.captures[3])
                groups[group_name] = G
            end
        end
    end
    return groups
end
