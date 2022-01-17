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

        trGrps = map(csvs) do file
            data = readdlm(file, '&')
            labels = Symbol.(replace.(strip.(data[1, :]), ' ' => '_', '-' => '_'))
            groups = data[2:end, :]
            grps = map(enumerate(eachrow(groups))) do (i, props)
                nt = (; (Symbol(l) => v for (l, v) in zip(labels, props))...)
                @debug i, grp_name(nt)
                P = all_grps_presentations[grp_name(nt)]
                grp = TriangleGrp(P.generators, P.relations, nt)
                latex_name(grp) => grp
            end |> Dict

            m = match(r".*_(\d)_(\d)_(\d).csv", basename(file))
            @assert !isnothing(m)
            type = parse.(Int, tuple(m[1], m[2], m[3]))
            type => grps
        end |> Dict
        # Dict(name(G) => G for G in trGrps)
    end

open(joinpath(@__DIR__, "triangle_groups.json"), "w") do io
    JSON.print(io, tr_grps, 4)
end
