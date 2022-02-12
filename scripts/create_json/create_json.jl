using Pkg
Pkg.activate(@__DIR__)
using DelimitedFiles
using JSON

include(joinpath(@__DIR__, "parse_presentations.jl"))
include(joinpath(@__DIR__, "smallhyperbolicgrp.jl"))

const DATA_DIR = joinpath(@__DIR__, "..", "..", "data")

function _files_with_extension(dir::AbstractString, ext::AbstractString)
    return [
        joinpath(dir, f) for f in readdir(dir) if
        isfile(joinpath(dir, f)) && endswith(f, '.'*ext)
    ]
end

all_grps_presentations =
    let tables = _files_with_extension(DATA_DIR, "txt")
        mapreduce(parse_grouppresentations_abstract, union, tables) |> Dict
    end

grps =
    let csvs = _files_with_extension(DATA_DIR, "csv")

        trGrps = mapreduce(union, csvs) do file
            m = match(r".*_(\d)_(\d)_(\d).csv", basename(file))
            @assert !isnothing(m)
            type = parse.(Int, tuple(m[1], m[2], m[3]))

            data = readdlm(file, '&')
            labels = Symbol.(replace.(strip.(data[1, :]), ' ' => '_', '-' => '_'))
            groups = data[2:end, :]
            grps = map(enumerate(eachrow(groups))) do (i, props)
                nt = (; (Symbol(l) => v for (l, v) in zip(labels, props))...)
                @debug i, grp_name(nt)
                P = all_grps_presentations[grp_name(nt)]
                grp = TriangleGrp(type, P.generators, P.relations, nt)
            end
        end
    end

open(joinpath(DATA_DIR, "triangle_groups.json"), "w") do io
    f(args...) = show_json(args...; indent = 4)
    s = sprint(f, TriangleGrpSerialization(), grps)
    # JSON.print(io, , 4)
    print(io, s)
end
