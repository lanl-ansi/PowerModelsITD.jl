# ACP Constraints & Boundary Linking Vars.

"""
    function constraint_transmission_power_balance(
        pm::_PM.AbstractACPModel,
        n::Int,
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

ACP transmission constraint power balance for decomposition model.
"""
function constraint_transmission_power_balance_stochastic(pm::_PM.AbstractACPModel, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_qd, bus_gs, bus_bs, bus_arcs_boundary_from)

    vm = _PM.var(pm, n, :vm, i)

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
    + pbound_load[bus_arcs_boundary_from[end]][1]
    ==
    sum(pg[g] for g in bus_gens)
    - sum(ps[s] for s in bus_storage)
    - sum(pd for (i,pd) in bus_pd)
    - sum(gs for (i,gs) in bus_gs)*vm^2
    )

    cstr_q = JuMP.@constraint(pm.model,
        sum(q[a] for a in bus_arcs)
        + sum(q_dc[a_dc] for a_dc in bus_arcs_dc)
        + sum(qsw[a_sw] for a_sw in bus_arcs_sw)
        + qbound_load[bus_arcs_boundary_from[end]][1]
        ==
        sum(qg[g] for g in bus_gens)
        - sum(qs[s] for s in bus_storage)
        - sum(qd for (i,qd) in bus_qd)
        + sum(bs for (i,bs) in bus_bs)*vm^2
    )

    # for boundary in bus_arcs_boundary_from

    #     cstr_p = JuMP.@constraint(pm.model,
    #         sum(p[a] for a in bus_arcs)
    #         + sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
    #         + sum(psw[a_sw] for a_sw in bus_arcs_sw)
    #         + pbound_load[boundary][1]
    #         ==
    #         sum(pg[g] for g in bus_gens)
    #         - sum(ps[s] for s in bus_storage)
    #         - sum(pd for (i,pd) in bus_pd)
    #         - sum(gs for (i,gs) in bus_gs)*vm^2
    #     )

    #     cstr_q = JuMP.@constraint(pm.model,
    #         sum(q[a] for a in bus_arcs)
    #         + sum(q_dc[a_dc] for a_dc in bus_arcs_dc)
    #         + sum(qsw[a_sw] for a_sw in bus_arcs_sw)
    #         + qbound_load[boundary][1]
    #         ==
    #         sum(qg[g] for g in bus_gens)
    #         - sum(qs[s] for s in bus_storage)
    #         - sum(qd for (i,qd) in bus_qd)
    #         + sum(bs for (i,bs) in bus_bs)*vm^2
    #     )

    # end

    if _IM.report_duals(pm)
        _PM.sol(pm, n, :bus, i)[:lam_kcl_r] = cstr_p
        _PM.sol(pm, n, :bus, i)[:lam_kcl_i] = cstr_q
    end

end


function constraint_transmission_boundary_power_scaled_equalization_stochastic(pm::_PM.AbstractACPModel, i::Int; nw::Int=nw_id_default)

    boundary = _PM.ref(pm, nw, :boundary, i)
    f_bus = boundary["f_bus"] # convention: from bus Transmission always!
    t_bus = boundary["t_bus"] # convention: to bus Distribution always!

    # Original (1st real connection to transmission)
    f_idx_org = (100001, f_bus, t_bus)
    pbound_load_scaled_org = _PM.var(pm, nw, :pbound_load_scaled, f_idx_org)
    qbound_load_scaled_org = _PM.var(pm, nw, :qbound_load_scaled, f_idx_org)
    pbound_load_org = _PM.var(pm, nw, :pbound_load, f_idx_org)
    qbound_load_org = _PM.var(pm, nw, :qbound_load, f_idx_org)

    # Pbound_load vars
    f_idx = (i, f_bus, t_bus)
    pbound_load_scaled = _PM.var(pm, nw, :pbound_load_scaled, f_idx)
    qbound_load_scaled = _PM.var(pm, nw, :qbound_load_scaled, f_idx)
    pbound_load = _PM.var(pm, nw, :pbound_load, f_idx)
    qbound_load = _PM.var(pm, nw, :qbound_load, f_idx)

    # Add scaling constraint
    JuMP.@constraint(pm.model, pbound_load_scaled[1] == pbound_load_scaled_org[1])
    JuMP.@constraint(pm.model, qbound_load_scaled[1] == qbound_load_scaled_org[1])

    JuMP.@constraint(pm.model, pbound_load[1] == pbound_load_org[1])
    JuMP.@constraint(pm.model, qbound_load[1] == qbound_load_org[1])

end
