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
    load_basis!(RG, sett)
    @assert iszero(aug(Δ))

    ELT = Δ^2;
    ELT_NAME = "Δ²"

    λ, P = PropertyT.approximate_by_SOS(sett, ELT, Δ,
        solverlog=PropertyT.filename(sett, :solverlog))

    P .= (P.+P')./2

    Q = real(sqrt(P))
    Q .= (Q.+Q')./2

    save(PropertyT.filename(sett, :solution), "λ", λ, "P", P, "Q", Q)

    certified_λ = PropertyT.certify_SOS_decomposition(ELT, Δ, λ, Q, R=sett.halfradius)

    return PropertyT.interpret_results(sett, certified_λ)
end

function load_basis!(RG::GroupRing, sett::PropertyT.Settings)
    basis_fn = joinpath(PropertyT.prepath(sett), "B_$(2sett.halfradius).csv")
    return load_basis!(RG, basis_fn)
end

function load_basis!(RG::GroupRing, basis_file)
    G = RG.group;
    words = split(readline(basis_file), ", ")[2:end]

    basis_ex = [Meta.parse(w) for w in words]
    basis = [@eval begin a,b,c = $(gens(G)); $b_ex end for b_ex in basis_ex]
    basis = pushfirst!(basis, one(G))
    basis_dict = GroupRings.reverse_dict(basis)

    RG.basis = basis
    RG.basis_dict = basis_dict

    return RG
end
