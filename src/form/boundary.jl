# Boundary Constraints

"""
    function constraint_boundary_power(
        pmitd::AbstractPowerModelITD,
        i::Int;
        nw::Int=nw_id_default
    )

Boundary power constraints for AbstractPowerModelITD.
"""
function constraint_boundary_power(pmitd::AbstractPowerModelITD, i::Int; nw::Int=nw_id_default)

    boundary = ref(pmitd, nw, :boundary, i)
    f_bus = boundary["f_bus"] # convention: from bus Transmission always!
    t_bus = boundary["t_bus"] # convention: to bus Distribution always!
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)

    p_fr = var(pmitd, nw, :pbound_fr, f_idx)
    p_to = var(pmitd, nw, :pbound_to, t_idx)

    q_fr = var(pmitd, nw, :qbound_fr, f_idx)
    q_to = var(pmitd, nw, :qbound_to, t_idx)

    JuMP.@constraint(pmitd.model, p_fr[1] == -sum(p_to[phase] for phase in boundary["t_connections"]))
    JuMP.@constraint(pmitd.model, q_fr[1] == -sum(q_to[phase] for phase in boundary["t_connections"]))

end


"""
    function constraint_boundary_power(
        pmitd::LPowerModelITD,
        i::Int;
        nw::Int=nw_id_default
    )

Boundary power constraints for LPowerModelITD (Linear versions - Active P only).
"""
function constraint_boundary_power(pmitd::LPowerModelITD, i::Int; nw::Int=nw_id_default)

    boundary = ref(pmitd, nw, :boundary, i)
    f_bus = boundary["f_bus"] # convention: from bus Transmission always!
    t_bus = boundary["t_bus"] # convention: to bus Distribution always!
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)

    p_fr = var(pmitd, nw, :pbound_fr, f_idx)
    p_to = var(pmitd, nw, :pbound_to, t_idx)

    JuMP.@constraint(pmitd.model, p_fr[1] == -sum(p_to[phase] for phase in boundary["t_connections"]))

end


"""
    function constraint_boundary_current(
        pmitd::AbstractIVRPowerModelITD,
        i::Int;
        nw::Int=nw_id_default
    )

Boundary power constraints based on rectangular currents (I) for AbstractIVRPowerModelITD.
"""
function constraint_boundary_current(pmitd::AbstractIVRPowerModelITD, i::Int; nw::Int=nw_id_default)

    # Extract the transmission model
    pm_model = _get_powermodel_from_powermodelitd(pmitd)
    # Extract the distribution model
    pmd_model = _get_powermodeldistribution_from_powermodelitd(pmitd)

    boundary = ref(pmitd, nw, :boundary, i)
    f_bus = boundary["f_bus"] # convention: from bus Transmission always!
    t_bus = boundary["t_bus"] # convention: to bus Distribution always!
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)

    # Current (Real)
    cr_fr = var(pmitd, nw, :crbound_fr, f_idx)
    cr_to = var(pmitd, nw, :crbound_to, t_idx)

    # Current (Imaginary)
    ci_fr = var(pmitd, nw, :cibound_fr, f_idx)
    ci_to = var(pmitd, nw, :cibound_to, t_idx)

    # voltage vars from transmission boundary bus
    vr_fr = _PM.var(pm_model, nw, :vr, f_idx[2])
    vi_fr = _PM.var(pm_model, nw, :vi, f_idx[2])

    # voltage vars from distribution boundary bus
    vr_to = _PMD.var(pmd_model, nw, :vr, t_idx[2])
    vi_to = _PMD.var(pmd_model, nw, :vi, t_idx[2])

    # Real power constraint
    JuMP.@constraint(pmitd.model, (vr_fr[1]*cr_fr[1] + vi_fr[1]*ci_fr[1]) == -((vr_to[1]*cr_to[1] + vi_to[1]*ci_to[1]) + (vr_to[2]*cr_to[2] + vi_to[2]*ci_to[2]) + (vr_to[3]*cr_to[3] + vi_to[3]*ci_to[3])))
    # Reactive power constraint
    JuMP.@constraint(pmitd.model, (vi_fr[1]*cr_fr[1] - vr_fr[1]*ci_fr[1]) == -((vi_to[1]*cr_to[1] - vr_to[1]*ci_to[1]) + (vi_to[2]*cr_to[2] - vr_to[2]*ci_to[2]) + (vi_to[3]*cr_to[3] - vr_to[3]*ci_to[3])))

end


"""
    function constraint_boundary_voltage_magnitude(
        pmitd::AbstractPowerModelITD,
        i::Int;
        nw::Int=nw_id_default
    )

General voltage magnitude boundary constraint.
"""
function constraint_boundary_voltage_magnitude(pmitd::AbstractPowerModelITD, i::Int; nw::Int=nw_id_default)

     # Extract the transmission model
     pm_model = _get_powermodel_from_powermodelitd(pmitd)

     # Extract the distribution model
     pmd_model = _get_powermodeldistribution_from_powermodelitd(pmitd)

    boundary = ref(pmitd, nw, :boundary, i)
    f_bus = boundary["f_bus"] # convention: from bus Transmission always!
    t_bus = boundary["t_bus"] # convention: to bus Distribution always!
    f_idx = (i, f_bus, t_bus)

    constraint_boundary_voltage_magnitude(pm_model, pmd_model, i, f_idx, boundary["f_connections"], boundary["t_connections"]; nw=nw)

end


"""
    function constraint_boundary_voltage_angle(
        pmitd::AbstractPowerModelITD,
        i::Int;
        nw::Int=nw_id_default
    )

General voltage angle boundary constraint.
"""
function constraint_boundary_voltage_angle(pmitd::AbstractPowerModelITD, i::Int; nw::Int=nw_id_default)

    # Extract the transmission model
    pm_model = _get_powermodel_from_powermodelitd(pmitd)

    # Extract the distribution model
    pmd_model = _get_powermodeldistribution_from_powermodelitd(pmitd)

    boundary = ref(pmitd, nw, :boundary, i)
    f_bus = boundary["f_bus"] # convention: from bus Transmission always!
    t_bus = boundary["t_bus"] # convention: to bus Distribution always!
    f_idx = (i, f_bus, t_bus)

    constraint_boundary_voltage_angle(pm_model, pmd_model, i, f_idx, boundary["f_connections"], boundary["t_connections"]; nw=nw)

end


### Bus - KCL Constraints ###
"""
    function constraint_transmission_power_balance_boundary(
        pmitd::AbstractPowerModelITD,
        i::Int;
        nw_pmitd::Int=nw_id_default
    )

General power balance contraints for boundary buses in the transmission system-side.
"""
function constraint_transmission_power_balance_boundary(pmitd::AbstractPowerModelITD, i::Int; nw_pmitd::Int=nw_id_default)

    # Extract the transmission model
    pm_model = _get_powermodel_from_powermodelitd(pmitd)
    bus = _PM.ref(pm_model, nw_pmitd, :bus, i)

    bus_arcs = _PM.ref(pm_model, nw_pmitd, :bus_arcs, i)
    bus_arcs_dc = _PM.ref(pm_model, nw_pmitd, :bus_arcs_dc, i)
    bus_arcs_sw = _PM.ref(pm_model, nw_pmitd, :bus_arcs_sw, i)
    bus_gens = _PM.ref(pm_model, nw_pmitd, :bus_gens, i)
    bus_loads = _PM.ref(pm_model, nw_pmitd, :bus_loads, i)
    bus_shunts = _PM.ref(pm_model, nw_pmitd, :bus_shunts, i)
    bus_storage = _PM.ref(pm_model, nw_pmitd, :bus_storage, i)

    bus_pd = Dict(k => _PM.ref(pm_model, nw_pmitd, :load, k, "pd") for k in bus_loads)
    bus_qd = Dict(k => _PM.ref(pm_model, nw_pmitd, :load, k, "qd") for k in bus_loads)

    bus_gs = Dict(k => _PM.ref(pm_model, nw_pmitd, :shunt, k, "gs") for k in bus_shunts)
    bus_bs = Dict(k => _PM.ref(pm_model, nw_pmitd, :shunt, k, "bs") for k in bus_shunts)

    bus_arcs_boundary_from = ref(pmitd, nw_pmitd, :bus_arcs_boundary_from, i)
    constraint_transmission_power_balance(pmitd, pm_model, nw_pmitd, i, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_qd, bus_gs, bus_bs, bus_arcs_boundary_from)

end


"""
    function constraint_distribution_power_balance_boundary(
        pmitd::AbstractPowerModelITD,
        i::Int;
        nw_pmitd::Int=nw_id_default
    )

General power balance contraints for boundary buses in the distribution system-side.
"""
function constraint_distribution_power_balance_boundary(pmitd::AbstractPowerModelITD, i::Int; nw_pmitd::Int=nw_id_default)

    # Extract the distribution model
    pmd_model = _get_powermodeldistribution_from_powermodelitd(pmitd)
    bus = _PMD.ref(pmd_model, nw_pmitd, :bus, i)

    bus_arcs = _PMD.ref(pmd_model, nw_pmitd, :bus_arcs_conns_branch, i)
    bus_arcs_sw = _PMD.ref(pmd_model, nw_pmitd, :bus_arcs_conns_switch, i)
    bus_arcs_trans = _PMD.ref(pmd_model, nw_pmitd, :bus_arcs_conns_transformer, i)
    bus_gens = _PMD.ref(pmd_model, nw_pmitd, :bus_conns_gen, i)
    bus_storage = _PMD.ref(pmd_model, nw_pmitd, :bus_conns_storage, i)
    bus_loads = _PMD.ref(pmd_model, nw_pmitd, :bus_conns_load, i)
    bus_shunts = _PMD.ref(pmd_model, nw_pmitd, :bus_conns_shunt, i)

    if !haskey(_PMD.con(pmd_model, nw_pmitd), :lam_kcl_r)
        _PMD.con(pmd_model, nw_pmitd)[:lam_kcl_r] = Dict{Int,Array{JuMP.ConstraintRef}}()
    end

    if !haskey(_PMD.con(pmd_model, nw_pmitd), :lam_kcl_i)
        _PMD.con(pmd_model, nw_pmitd)[:lam_kcl_i] = Dict{Int,Array{JuMP.ConstraintRef}}()
    end

    bus_arcs_boundary_to = ref(pmitd, nw_pmitd, :bus_arcs_boundary_to, i)
    constraint_distribution_power_balance(pmitd, pmd_model, nw_pmitd, i, bus["terminals"], bus["grounded"], bus_arcs, bus_arcs_sw, bus_arcs_trans, bus_gens, bus_storage, bus_loads, bus_shunts, bus_arcs_boundary_to)

end


"""
    function constraint_transmission_current_balance_boundary(
        pmitd::AbstractIVRPowerModelITD,
        i::Int;
        nw_pmitd::Int=nw_id_default
    )

General current balance contraints for boundary buses in the transmission system-side.
"""
function constraint_transmission_current_balance_boundary(pmitd::AbstractIVRPowerModelITD, i::Int; nw_pmitd::Int=nw_id_default)

    # Extract the transmission model
    pm_model = _get_powermodel_from_powermodelitd(pmitd)
    bus = _PM.ref(pm_model, nw_pmitd, :bus, i)

    if !haskey(_PM.con(pm_model, nw_pmitd), :kcl_cr)
        _PM.con(pm_model, nw_pmitd)[:kcl_cr] = Dict{Int,JuMP.ConstraintRef}()
    end
    if !haskey(_PM.con(pm_model, nw_pmitd), :kcl_ci)
        _PM.con(pm_model, nw_pmitd)[:kcl_ci] = Dict{Int,JuMP.ConstraintRef}()
    end

    bus_arcs = _PM.ref(pm_model, nw_pmitd, :bus_arcs, i)
    bus_arcs_dc = _PM.ref(pm_model, nw_pmitd, :bus_arcs_dc, i)
    bus_gens = _PM.ref(pm_model, nw_pmitd, :bus_gens, i)
    bus_loads = _PM.ref(pm_model, nw_pmitd, :bus_loads, i)
    bus_shunts = _PM.ref(pm_model, nw_pmitd, :bus_shunts, i)

    bus_pd = Dict(k => _PM.ref(pm_model, nw_pmitd, :load, k, "pd") for k in bus_loads)
    bus_qd = Dict(k => _PM.ref(pm_model, nw_pmitd, :load, k, "qd") for k in bus_loads)

    bus_gs = Dict(k => _PM.ref(pm_model, nw_pmitd, :shunt, k, "gs") for k in bus_shunts)
    bus_bs = Dict(k => _PM.ref(pm_model, nw_pmitd, :shunt, k, "bs") for k in bus_shunts)

    bus_arcs_boundary_from = ref(pmitd, nw_pmitd, :bus_arcs_boundary_from, i)
    constraint_transmission_current_balance(pmitd, pm_model, nw_pmitd, i, bus_arcs, bus_arcs_dc, bus_gens, bus_pd, bus_qd, bus_gs, bus_bs, bus_arcs_boundary_from)

end


"""
    function constraint_distribution_current_balance_boundary(
        pmitd::AbstractIVRPowerModelITD,
        i::Int;
        nw_pmitd::Int=nw_id_default
    )

General current balance contraints for boundary buses in the distribution system-side.
"""
function constraint_distribution_current_balance_boundary(pmitd::AbstractIVRPowerModelITD, i::Int; nw_pmitd::Int=nw_id_default)

    # Extract the distribution model
    pmd_model = _get_powermodeldistribution_from_powermodelitd(pmitd)
    bus = _PMD.ref(pmd_model, nw_pmitd, :bus, i)

    bus_arcs = _PMD.ref(pmd_model, nw_pmitd, :bus_arcs_conns_branch, i)
    bus_arcs_sw = _PMD.ref(pmd_model, nw_pmitd, :bus_arcs_conns_switch, i)
    bus_arcs_trans = _PMD.ref(pmd_model, nw_pmitd, :bus_arcs_conns_transformer, i)
    bus_gens = _PMD.ref(pmd_model, nw_pmitd, :bus_conns_gen, i)
    bus_storage = _PMD.ref(pmd_model, nw_pmitd, :bus_conns_storage, i)
    bus_loads = _PMD.ref(pmd_model, nw_pmitd, :bus_conns_load, i)
    bus_shunts = _PMD.ref(pmd_model, nw_pmitd, :bus_conns_shunt, i)

    bus_arcs_boundary_to = ref(pmitd, nw_pmitd, :bus_arcs_boundary_to, i)
    constraint_distribution_current_balance(pmitd, pmd_model, nw_pmitd, i, bus["terminals"], bus["grounded"], bus_arcs, bus_arcs_sw, bus_arcs_trans, bus_gens, bus_storage, bus_loads, bus_shunts, bus_arcs_boundary_to)

end
