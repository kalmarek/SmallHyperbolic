function check_propertyT(G::FPGroup, name::AbstractString,
    halfradius::Integer=2, upper_bound=Inf, reduction=KnuthBendix, with_optimizer=with_SCS(), kwargs...)

    @info "GAP code defining group:\n $(GAP_code(G))"
    S = gens(G)
    S = unique([S; inv.(S)])

    sett = PropertyT.Settings(name, G, S, with_optimizer;
            halfradius=halfradius, upper_bound=upper_bound, force_compute=true)

    fp = PropertyT.fullpath(sett)
    isdir(fp) || mkpath(fp)

    # runs kbmag through GAP:
    prepare_pm_delta(reduction, G, PropertyT.prepath(sett), halfradius; kwargs...)

    return check_propertyT(sett)
end

function check_propertyT(sett::PropertyT.Settings)

    @info sett

    fp = PropertyT.fullpath(sett)
    isdir(fp) || mkpath(fp)

    if isfile(PropertyT.filename(sett,:Δ))
        # cached
        @info "Loading precomputed Δ..."
        Δ = PropertyT.loadGRElem(PropertyT.filename(sett,:Δ), sett.G)
    else
        @error "You need to run GAP on your group first, or provide Δ in
    $(PropertyT.filename(sett,:Δ))"
    end

    RG = parent(Δ)

    ELT = Δ^2;
    ELT_NAME = "Δ²"

    λ, P = PropertyT.approximate_by_SOS(sett, ELT, Δ,
        solverlog=PropertyT.filename(sett, :solverlog))

    λ < 0 && @warn "Solver did not produce a valid solution!"

    P .= (P.+P')./2

    Q = real(sqrt(P))
    Q .= (Q.+Q')./2

    save(PropertyT.filename(sett, :solution), "λ", λ, "P", P, "Q", Q)

    certified_λ = PropertyT.certify_SOS_decomposition(ELT, Δ, λ, Q, R=sett.halfradius)

    return PropertyT.interpret_results(sett, certified_λ)
end
