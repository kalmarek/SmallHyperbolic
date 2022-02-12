include(joinpath(@__DIR__, "..", "..", "src", "groupparse.jl"))

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

# parse_grouppresentations_abstract("./data/presentations_2_4_4.txt")

function _tf_missing(x::AbstractString)
    s = strip(x)
    yes = !isnothing(match(r"yes"i, s))
    no = !isnothing(match(r"no"i, s))
    mis = !isnothing(match(r"(\?)+", s))
    @debug "string for true/false/missing : $s" parsed=(yes, no, mis)
    yes && !no && !mis && return true
    !yes && no && !mis && return false
    !yes && !no && mis && return missing
    throw(ArgumentError("Unrecognized string as true/false/missing: $x"))
end

function parse_vec(s::AbstractString)
    m = match(r"^\s*\[(.*)\]\s*$", s)
    isnothing(m) && throw("String does not seem to represent a vector: $s")
    content = m[1]
    return strip.(split(content, ','))
end

parse_vec(T::Type{<:AbstractString}, s::AbstractString) = T.(parse_vec(s))
function parse_vec(::Type{T}, s::AbstractString) where {T<:Number}
    v = parse_vec(String, s)
    isempty(v) && return T[]
    length(v) == 1 && isempty(first(v)) && return T[]
    return parse.(T, parse_vec(String, s))
end

function parse_vec(
    ::Type{T},
    s::AbstractString,
) where {A<:AbstractString,B<:Number,T<:Tuple{A,B}}
    v = parse_vec(s)
    if length(v) == 1
        @assert isempty(first(v))
        return Tuple{A,B}[]
    end
    @assert iseven(length(v))
    return map(1:2:length(v)) do i
        @assert first(v[i]) == '(' && last(v[i+1]) == ')'
        key = v[i][begin+1:end]
        val = v[i+1][begin:end-1]
        (A(key), parse(B, val))
    end
end
