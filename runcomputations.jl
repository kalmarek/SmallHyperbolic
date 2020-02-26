using Logging
using PropertyT

using PropertyT.LinearAlgebra
using PropertyT.SparseArrays
using PropertyT.JuMP

using PropertyT.AbstractAlgebra
using PropertyT.Groups
using PropertyT.GroupRings

using PropertyT.JLD

BLAS.set_num_threads(2)
ENV["OMP_NUM_THREADS"] = 2

if !haskey(ENV, "GAP_EXECUTABLE")
    ENV["GAP_EXECUTABLE"] = "/usr/lib/gap/gap"
end

include(joinpath("src", "FPGroups_GAP.jl"))
include(joinpath("src", "groupparse.jl"))
include(joinpath("src", "utils.jl"))

const HALFRADIUS = 1
using SCS

with_SCS(iters=30_000, acceleration=10; eps=1e-10) = with_optimizer(SCS.Optimizer,
    linear_solver=SCS.Direct,
    max_iters=iters,
    eps=eps,
    alpha=(acceleration == 0 ? 1.95 : 1.5),
    acceleration_lookback=acceleration,
    warm_start=true)

groups333 = parse_grouppresentations("data/presentations_3_3_3.txt")
groups334 = parse_grouppresentations("data/presentations_3_3_4.txt")
groups344 = parse_grouppresentations("data/presentations_3_4_4.txt")
groups444 = parse_grouppresentations("data/presentations_4_4_4.txt")
groups555 = parse_grouppresentations("data/presentations_5_5_5.txt")


groups = merge(groups333, groups334, groups344, groups444, groups555)

@assert length(ARGS) == 1

let GROUP = ARGS[1]
    @assert haskey(groups, GROUP)
    group_name = "log/$(GROUP)_r$(HALFRADIUS)"
    mkpath(group_name)
    open(joinpath(group_name, "full.log"), "a+") do logfile
        logger = SimpleLogger(logfile)
        global_logger(logger)

        @info "" group_name
        spectral_gap, λ = check_propertyT(groups[GROUP], group_name,
        HALFRADIUS, Inf, AutomaticStructure, with_SCS(100_000, 50))

        if spectral_gap < 0.0 && λ > 0.01 # there is still a chance to detect spectral gap
            new_λ = round(0.8λ, sigdigits=3)
            new_dir = joinpath(group_name, "$new_λ")
            isdir(new_dir) || mkpath(new_dir)
            cp(joinpath(group_name, "Inf", "warmstart.jld"), joinpath(new_dir, "warmstart.jld"), force=true)

            check_propertyT(groups[GROUP], group_name,
            HALFRADIUS, new_λ, AutomaticStructure, with_SCS(500_000, 0))
        end
    end
end
