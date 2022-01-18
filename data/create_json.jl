using Pkg
Pkg.activate(@__DIR__)
using DelimitedFiles
using JSON

include(joinpath(@__DIR__, "parse_presentations.jl"))
include(joinpath(@__DIR__, "smallhyperbolicgrp.jl"))

all_grps_presentations =
    let tables = [
            joinpath(@__DIR__, f) for f in readdir(@__DIR__) if
            isfile(joinpath(@__DIR__, f)) && endswith(f, ".txt")
        ]
        mapreduce(parse_grouppresentations_abstract, union, tables) |> Dict
    end

tr_grps =
    let csvs = [
            joinpath(@__DIR__, f) for f in readdir(@__DIR__) if
            isfile(joinpath(@__DIR__, f)) && endswith(f, ".csv")
        ]

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

open(joinpath(@__DIR__, "triangle_groups.json"), "w") do io
    f(args...) = show_json(args...; indent = 4)
    s = sprint(f, TriangleGrpSerialization(), tr_grps)
    # JSON.print(io, , 4)
    print(io, s)
end
