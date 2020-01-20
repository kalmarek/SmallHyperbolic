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

with_SCS(iters=30_000, acceleration=10) = with_optimizer(SCS.Optimizer,
    linear_solver=SCS.Direct,
    max_iters=iters,
    eps=1e-9,
    alpha=(acceleration == 0 ? 1.95 : 1.5),
    acceleration_lookback=acceleration,
    warm_start=true)

groups334 = parse_grouppresentations("data/presentations_3_3_4.txt")
groups344 = parse_grouppresentations("data/presentations_3_4_4.txt")
groups444 = parse_grouppresentations("data/presentations_4_4_4.txt")

groups = merge(groups334, groups344, groups444)

@assert length(ARGS) == 1

let GROUP = ARGS[1]
    @assert haskey(groups, GROUP)
    group_name = "log2/$(GROUP)_r$(HALFRADIUS)"
    open(joinpath(group_name, "full.log"), "a+") do logfile
        logger = SimpleLogger(logfile)
        global_logger(logger)

        @info "" group_name
        check_propertyT(groups[GROUP], group_name,
        HALFRADIUS, Inf, AutomaticStructure, with_SCS(100_000, 50))

        check_propertyT(groups[GROUP], group_name,
        HALFRADIUS, Inf, AutomaticStructure, with_SCS(1_000_000, 0))
    end
    true # to keep make happy
end
