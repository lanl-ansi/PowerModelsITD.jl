# ACP Constraints

"""
    function constraint_transmission_power_balance(
        pmitd::AbstractPowerModelITD,
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

ACP transmission constraint power balance.
"""
function constraint_transmission_power_balance_stochastic(pmitd::AbstractPowerModelITD, pm::_PM.AbstractACPModel, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_qd, bus_gs, bus_bs, bus_arcs_boundary_from)

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
    pbound_fr    = get(var(pmitd, n),    :pbound_fr, Dict()); _PM._check_var_keys(pbound_fr, bus_arcs_boundary_from, "active power", "boundary")
    qbound_fr    = get(var(pmitd, n),    :qbound_fr, Dict()); _PM._check_var_keys(qbound_fr, bus_arcs_boundary_from, "reactive power", "boundary")

    cstr_p = JuMP.@constraint(pmitd.model,
        sum(p[a] for a in bus_arcs)
        + sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
        + sum(psw[a_sw] for a_sw in bus_arcs_sw)
        + pbound_fr[bus_arcs_boundary_from[1]][1]
        ==
        sum(pg[g] for g in bus_gens)
        - sum(ps[s] for s in bus_storage)
        - sum(pd for (i,pd) in bus_pd)
        - sum(gs for (i,gs) in bus_gs)*vm^2
    )

    cstr_q = JuMP.@constraint(pmitd.model,
        sum(q[a] for a in bus_arcs)
        + sum(q_dc[a_dc] for a_dc in bus_arcs_dc)
        + sum(qsw[a_sw] for a_sw in bus_arcs_sw)
        + qbound_fr[bus_arcs_boundary_from[1]][1]
        ==
        sum(qg[g] for g in bus_gens)
        - sum(qs[s] for s in bus_storage)
        - sum(qd for (i,qd) in bus_qd)
        + sum(bs for (i,bs) in bus_bs)*vm^2
    )

    if _IM.report_duals(pmitd)
        sol(pmitd, n, :bus, i)[:lam_kcl_r] = cstr_p
        sol(pmitd, n, :bus, i)[:lam_kcl_i] = cstr_q
    end

end
