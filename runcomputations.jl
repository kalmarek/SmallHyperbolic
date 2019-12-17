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

const HALFRADIUS = 3
using SCS
with_SCS() = with_optimizer(SCS.Optimizer,
    linear_solver=SCS.Direct,
    max_iters=100_000,
    eps=1e-9,
    alpha=1.5,
    acceleration_lookback=10,
    warm_start=true)

groups = parse_grouppresentations("data/presentations_4_4_4.txt")
groups = parse_grouppresentations("data/presentations_3_3_4.txt")

for (group_name, G) in groups
    @info "" group_name
    check_propertyT(G, "log/$(group_name)_r$HALFRADIUS",
    HALFRADIUS, Inf, AutomaticStructure)
end
