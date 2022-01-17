include("../src/groupparse.jl")

function parse_grouppresentations_abstract(filename::AbstractString)
    lines = strip.(readlines(filename))
    groups = let t = (; generators = String[], relations = String[])
        Dict{String,typeof(t)}()
    end
    group_regex = r"(?<name>\w.*)\s?:=\s?(?<group_str>Group.*)"
    for line in lines
        isempty(line) && continue
        newline = if iscomment(line)
            line[3:end]
        else
            line[1:end]
        end
        m = match(group_regex, newline)
        if isnothing(m)
            @debug "Can't parse line as group presentation \n $line"
            continue
        else
            name = strip(m[:name])
            group_str = m[:group_str]
            gens, rels = split_magma_presentation(group_str)
            groups[name] = (generators = String.(gens), relations = String.(rels))
        end
    end
    return groups
end
