# ACR Constraints & Boundary Linking Vars.

"""
    function constraint_transmission_power_balance(
        pm::_PM.AbstractACRModel,
        n::Int,
        j::Int,
        i::Int,
        bus_arcs,
        bus_arcs_dc,
        bus_arcs_sw,
        bus_gens,
        bus_storage,
        bus_pd,
        bus_qd,
        bus_gs,
        bus_bs,
        bus_arcs_boundary_from
    )

ACR transmission constraint power balance for decomposition model.
"""
function constraint_transmission_power_balance(pm::_PM.AbstractACRModel, n::Int, j::Int, i::Int, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_qd, bus_gs, bus_bs, bus_arcs_boundary_from)

    vr = _PM.var(pm, n, :vr, i)
    vi = _PM.var(pm, n, :vi, i)

    p    = _PM.get(_PM.var(pm, n),    :p, Dict()); _PM._check_var_keys(p, bus_arcs, "active power", "branch")
    q    = _PM.get(_PM.var(pm, n),    :q, Dict()); _PM._check_var_keys(q, bus_arcs, "reactive power", "branch")
    pg   = _PM.get(_PM.var(pm, n),   :pg, Dict()); _PM._check_var_keys(pg, bus_gens, "active power", "generator")
    qg   = _PM.get(_PM.var(pm, n),   :qg, Dict()); _PM._check_var_keys(qg, bus_gens, "reactive power", "generator")
    ps   = _PM.get(_PM.var(pm, n),   :ps, Dict()); _PM._check_var_keys(ps, bus_storage, "active power", "storage")
    qs   = _PM.get(_PM.var(pm, n),   :qs, Dict()); _PM._check_var_keys(qs, bus_storage, "reactive power", "storage")
    psw  = _PM.get(_PM.var(pm, n),  :psw, Dict()); _PM._check_var_keys(psw, bus_arcs_sw, "active power", "switch")
    qsw  = _PM.get(_PM.var(pm, n),  :qsw, Dict()); _PM._check_var_keys(qsw, bus_arcs_sw, "reactive power", "switch")
    p_dc = _PM.get(_PM.var(pm, n), :p_dc, Dict()); _PM._check_var_keys(p_dc, bus_arcs_dc, "active power", "dcline")
    q_dc = _PM.get(_PM.var(pm, n), :q_dc, Dict()); _PM._check_var_keys(q_dc, bus_arcs_dc, "reactive power", "dcline")

    # Boundary
    pbound_load    = get(_PM.var(pm, n),    :pbound_load, Dict()); _PM._check_var_keys(pbound_load, bus_arcs_boundary_from, "active power", "boundary")
    qbound_load    = get(_PM.var(pm, n),    :qbound_load, Dict()); _PM._check_var_keys(qbound_load, bus_arcs_boundary_from, "reactive power", "boundary")

    cstr_p = JuMP.@constraint(pm.model,
        sum(p[a] for a in bus_arcs)
        + sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
        + sum(psw[a_sw] for a_sw in bus_arcs_sw)
        + sum(pbound_load[a_pbound_load][1] for a_pbound_load in bus_arcs_boundary_from)
        ==
        sum(pg[g] for g in bus_gens)
        - sum(ps[s] for s in bus_storage)
        - sum(pd for (i,pd) in bus_pd)
        - sum(gs for gs in values(bus_gs))*(vr^2 + vi^2)
    )
    cstr_q = JuMP.@constraint(pm.model,
        sum(q[a] for a in bus_arcs)
        + sum(q_dc[a_dc] for a_dc in bus_arcs_dc)
        + sum(qsw[a_sw] for a_sw in bus_arcs_sw)
        + sum(qbound_load[a_qbound_load][1] for a_qbound_load in bus_arcs_boundary_from)
        ==
        sum(qg[g] for g in bus_gens)
        - sum(qs[s] for s in bus_storage)
        - sum(qd for (i,qd) in bus_qd)
        + sum(bs for bs in values(bus_bs))*(vr^2 + vi^2)
    )

    if _IM.report_duals(pm)
        _PM.sol(pm, n, :bus, i)[:lam_kcl_r] = cstr_p
        _PM.sol(pm, n, :bus, i)[:lam_kcl_i] = cstr_q
    end

end


"""
    function constraint_boundary_voltage_magnitude(
        pmd::_PMD.ACRUPowerModel,
        i::Int,
        f_idx::Tuple{Int,Int,Int},
        f_connections::Vector{Int},
        t_connections::Vector{Int};
        nw::Int = nw_id_default
    )

ACRU boundary bus voltage magnitude constraints.
"""
function constraint_boundary_voltage_magnitude(pmd::_PMD.ACRUPowerModel, ::Int, t_bus::Int, ::Vector{Int}, ::Vector{Int}; nw::Int=nw_id_default)

    vr_source = _PMD.var(pmd, nw, :vr, t_bus)
    vi_source = _PMD.var(pmd, nw, :vi, t_bus)

    # Add constraint(s): r->real, i->imaginary
    JuMP.@constraint(pmd.model, vr_source[1]^2+vi_source[1]^2 == vr_source[2]^2+vi_source[2]^2)
    JuMP.@constraint(pmd.model, vr_source[1]^2+vi_source[1]^2 == vr_source[3]^2+vi_source[3]^2)

end

# TODO: multinetwork compatibility by using nw info.
"""
    function generate_boundary_linking_vars(
        pm::_PM.ACRPowerModel,
        pmd::_PMD.ACRUPowerModel,
        boundary_number::String;
        nw::Int = nw_id_default

    )

Generates the ACR-ACRU boundary linking vars vector to be used by the IDEC Optimizer.
"""
function generate_boundary_linking_vars(pm::_PM.ACRPowerModel, pmd::_PMD.ACRUPowerModel, boundary_number::String; nw::Int=nw_id_default)

    # Parse to Int
    boundary_number = parse(Int64, boundary_number)

    # Get boundary info.
    boundary = _PMD.ref(pmd, nw, :boundary, boundary_number)

    f_bus = boundary["f_bus"] # convention: from bus Transmission always!
    t_bus = boundary["t_bus"] # convention: to bus Distribution always!

    # Distribution: Aux vars (subproblem)
    f_idx = (boundary_number, f_bus, t_bus)
    p_aux = _PMD.var(pmd, nw, :pbound_aux, f_idx)
    q_aux = _PMD.var(pmd, nw, :qbound_aux, f_idx)

    # Distribution: vr and vi (subproblem)
    vr = _PMD.var(pmd, nw, :vr, t_bus)
    vi = _PMD.var(pmd, nw, :vi, t_bus)

    # Transmission: Vr and Vi (master)
    Vr = _PM.var(pm, nw, :vr, f_bus)
    Vi = _PM.var(pm, nw, :vi, f_bus)

    # Transmission: Pload & Qload (master)
    P_load = _PM.var(pm, nw, :pbound_load, f_idx)
    Q_load = _PM.var(pm, nw, :qbound_load, f_idx)

    boundary_linking_vars = [[P_load[1], Q_load[1], Vr, Vi], [p_aux[1], q_aux[1], vr[1], vi[1]]]

    return boundary_linking_vars

end
