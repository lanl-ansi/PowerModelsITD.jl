# ACR Constraints

"""
    function constraint_transmission_power_balance(
        pmitd::AbstractPowerModelITD,
        pm::_PM.AbstractACRModel,
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

ACR transmission constraint power balance.
"""
function constraint_transmission_power_balance(pmitd::AbstractPowerModelITD, pm::_PM.AbstractACRModel, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_qd, bus_gs, bus_bs, bus_arcs_boundary_from)
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
    pbound_fr    = get(var(pmitd, n),    :pbound_fr, Dict()); _PM._check_var_keys(pbound_fr, bus_arcs_boundary_from, "active power", "boundary")
    qbound_fr    = get(var(pmitd, n),    :qbound_fr, Dict()); _PM._check_var_keys(qbound_fr, bus_arcs_boundary_from, "reactive power", "boundary")


    cstr_p = JuMP.@constraint(pmitd.model,
        sum(p[a] for a in bus_arcs)
        + sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
        + sum(psw[a_sw] for a_sw in bus_arcs_sw)
        + sum(pbound_fr[a_pbound_fr][1] for a_pbound_fr in bus_arcs_boundary_from)
        ==
        sum(pg[g] for g in bus_gens)
        - sum(ps[s] for s in bus_storage)
        - sum(pd for pd in values(bus_pd))
        - sum(gs for gs in values(bus_gs))*(vr^2 + vi^2)
    )
    cstr_q = JuMP.@constraint(pmitd.model,
        sum(q[a] for a in bus_arcs)
        + sum(q_dc[a_dc] for a_dc in bus_arcs_dc)
        + sum(qsw[a_sw] for a_sw in bus_arcs_sw)
        + sum(qbound_fr[a_qbound_fr][1] for a_qbound_fr in bus_arcs_boundary_from)
        ==
        sum(qg[g] for g in bus_gens)
        - sum(qs[s] for s in bus_storage)
        - sum(qd for qd in values(bus_qd))
        + sum(bs for bs in values(bus_bs))*(vr^2 + vi^2)
    )

    if _IM.report_duals(pmitd)
        sol(pmitd, n, :bus, i)[:lam_kcl_r] = cstr_p
        sol(pmitd, n, :bus, i)[:lam_kcl_i] = cstr_q
    end
end


"""
    function constraint_distribution_power_balance(
        pmitd::AbstractPowerModelITD,
        pmd::_PMD.AbstractUnbalancedACRModel,
        n::Int,
        i::Int,
        terminals::Vector{Int},
        grounded::Vector{Bool},
        bus_arcs::Vector{Tuple{Tuple{Int,Int,Int},Vector{Int}}},
        bus_arcs_sw::Vector{Tuple{Tuple{Int,Int,Int},Vector{Int}}},
        bus_arcs_trans::Vector{Tuple{Tuple{Int,Int,Int},Vector{Int}}},
        bus_gens::Vector{Tuple{Int,Vector{Int}}},
        bus_storage::Vector{Tuple{Int,Vector{Int}}},
        bus_loads::Vector{Tuple{Int,Vector{Int}}},
        bus_shunts::Vector{Tuple{Int,Vector{Int}}},
        bus_arcs_boundary_to
    )

ACRU distribution constraint power balance.
"""
function constraint_distribution_power_balance(pmitd::AbstractPowerModelITD, pmd::_PMD.AbstractUnbalancedACRModel, n::Int, i::Int, terminals::Vector{Int}, grounded::Vector{Bool}, bus_arcs::Vector{Tuple{Tuple{Int,Int,Int},Vector{Int}}}, bus_arcs_sw::Vector{Tuple{Tuple{Int,Int,Int},Vector{Int}}}, bus_arcs_trans::Vector{Tuple{Tuple{Int,Int,Int},Vector{Int}}}, bus_gens::Vector{Tuple{Int,Vector{Int}}}, bus_storage::Vector{Tuple{Int,Vector{Int}}}, bus_loads::Vector{Tuple{Int,Vector{Int}}}, bus_shunts::Vector{Tuple{Int,Vector{Int}}}, bus_arcs_boundary_to)
    vr = _PMD.var(pmd, n, :vr, i)
    vi = _PMD.var(pmd, n, :vi, i)

    p    = _PMD.get(_PMD.var(pmd, n), :p,      Dict()); _PMD._check_var_keys(p,   bus_arcs,       "active power",   "branch")
    q    = _PMD.get(_PMD.var(pmd, n), :q,      Dict()); _PMD._check_var_keys(q,   bus_arcs,       "reactive power", "branch")
    pg   = _PMD.get(_PMD.var(pmd, n), :pg_bus, Dict()); _PMD._check_var_keys(pg,  bus_gens,       "active power",   "generator")
    qg   = _PMD.get(_PMD.var(pmd, n), :qg_bus, Dict()); _PMD._check_var_keys(qg,  bus_gens,       "reactive power", "generator")
    ps   = _PMD.get(_PMD.var(pmd, n), :ps,     Dict()); _PMD._check_var_keys(ps,  bus_storage,    "active power",   "storage")
    qs   = _PMD.get(_PMD.var(pmd, n), :qs,     Dict()); _PMD._check_var_keys(qs,  bus_storage,    "reactive power", "storage")
    psw  = _PMD.get(_PMD.var(pmd, n), :psw,    Dict()); _PMD._check_var_keys(psw, bus_arcs_sw,    "active power",   "switch")
    qsw  = _PMD.get(_PMD.var(pmd, n), :qsw,    Dict()); _PMD._check_var_keys(qsw, bus_arcs_sw,    "reactive power", "switch")
    pt   = _PMD.get(_PMD.var(pmd, n), :pt,     Dict()); _PMD._check_var_keys(pt,  bus_arcs_trans, "active power",   "transformer")
    qt   = _PMD.get(_PMD.var(pmd, n), :qt,     Dict()); _PMD._check_var_keys(qt,  bus_arcs_trans, "reactive power", "transformer")
    pd   = _PMD.get(_PMD.var(pmd, n), :pd_bus, Dict()); _PMD._check_var_keys(pd,  bus_loads,      "active power",   "load")
    qd   = _PMD.get(_PMD.var(pmd, n), :qd_bus, Dict()); _PMD._check_var_keys(pd,  bus_loads,      "reactive power", "load")

    Gt, Bt = _PMD._build_bus_shunt_matrices(pmd, n, terminals, bus_shunts)

    # Boundary
    pbound_to    = get(var(pmitd, n),    :pbound_to, Dict()); _PMD._check_var_keys(pbound_to, bus_arcs_boundary_to, "active power", "boundary")
    qbound_to    = get(var(pmitd, n),    :qbound_to, Dict()); _PMD._check_var_keys(qbound_to, bus_arcs_boundary_to, "reactive power", "boundary")

    cstr_p = []
    cstr_q = []

    ungrounded_terminals = [(idx,t) for (idx,t) in enumerate(terminals) if !grounded[idx]]


    # pd/qd can be NLexpressions, so cannot be vectorized
    for (idx, t) in ungrounded_terminals
        cp = @smart_constraint(pmitd.model, [p, q, pg, qg, ps, qs, psw, qsw, pt, qt, pd, qd, pbound_to, qbound_to, vr, vi],
              sum(  p[arc][t] for (arc, conns) in bus_arcs if t in conns)
            + sum(psw[arc][t] for (arc, conns) in bus_arcs_sw if t in conns)
            + sum( pt[arc][t] for (arc, conns) in bus_arcs_trans if t in conns)
            + sum(pbound_to[a_pbound_to][t] for a_pbound_to in bus_arcs_boundary_to)
            ==
              sum(pg[gen][t] for (gen, conns) in bus_gens if t in conns)
            - sum(ps[strg][t] for (strg, conns) in bus_storage if t in conns)
            - sum(pd[load][t] for (load, conns) in bus_loads if t in conns)
            + ( -vr[t] * sum(Gt[idx,jdx]*vr[u]-Bt[idx,jdx]*vi[u] for (jdx,u) in ungrounded_terminals)
                -vi[t] * sum(Gt[idx,jdx]*vi[u]+Bt[idx,jdx]*vr[u] for (jdx,u) in ungrounded_terminals)
            )
        )
        push!(cstr_p, cp)

        cq = @smart_constraint(pmitd.model, [p, q, pg, qg, ps, qs, psw, qsw, pt, qt, pd, qd, pbound_to, qbound_to, vr, vi],
              sum(  q[arc][t] for (arc, conns) in bus_arcs if t in conns)
            + sum(qsw[arc][t] for (arc, conns) in bus_arcs_sw if t in conns)
            + sum( qt[arc][t] for (arc, conns) in bus_arcs_trans if t in conns)
            + sum(qbound_to[a_qbound_to][t] for a_qbound_to in bus_arcs_boundary_to)
            ==
              sum(qg[gen][t] for (gen, conns) in bus_gens if t in conns)
            - sum(qd[load][t] for (load, conns) in bus_loads if t in conns)
            - sum(qs[strg][t] for (strg, conns) in bus_storage if t in conns)
            + ( vr[t] * sum(Gt[idx,jdx]*vi[u]+Bt[idx,jdx]*vr[u] for (jdx,u) in ungrounded_terminals)
               -vi[t] * sum(Gt[idx,jdx]*vr[u]-Bt[idx,jdx]*vi[u] for (jdx,u) in ungrounded_terminals)
            )
        )
        push!(cstr_q, cq)
    end

    _PMD.con(pmd, n, :lam_kcl_r)[i] = cstr_p
    _PMD.con(pmd, n, :lam_kcl_i)[i] = cstr_q

    if _IM.report_duals(pmitd)
        sol(pmitd, n, :bus, i)[:lam_kcl_r] = cstr_p
        sol(pmitd, n, :bus, i)[:lam_kcl_i] = cstr_q
    end
end


"""
    function constraint_boundary_voltage_magnitude(
        pm::_PM.ACRPowerModel,
        pmd::_PMD.ACRUPowerModel,
        i::Int,
        f_idx::Tuple{Int,Int,Int},
        f_connections::Vector{Int},
        t_connections::Vector{Int};
        nw::Int = nw_id_default
    )

ACR-ACRU boundary bus voltage magnitude constraints.
"""
function constraint_boundary_voltage_magnitude(pm::_PM.ACRPowerModel, pmd::_PMD.ACRUPowerModel, ::Int, f_idx::Tuple{Int,Int,Int}, ::Vector{Int}, ::Vector{Int}; nw::Int=nw_id_default)
    i, f_bus, t_bus = f_idx

    vr_fr = _PM.var(pm, nw, :vr, f_bus)
    vr_to = _PMD.var(pmd, nw, :vr, t_bus)
    vi_fr = _PM.var(pm, nw, :vi, f_bus)
    vi_to = _PMD.var(pmd, nw, :vi, t_bus)

    # Add constraint(s): r->real, i->imaginary
    JuMP.@constraint(pm.model, vr_to[1]^2+vi_to[1]^2 == vr_fr[1]^2+vi_fr[1]^2)
    JuMP.@constraint(pm.model, vr_to[2]^2+vi_to[2]^2 == vr_fr[1]^2+vi_fr[1]^2)
    JuMP.@constraint(pm.model, vr_to[3]^2+vi_to[3]^2 == vr_fr[1]^2+vi_fr[1]^2)
end


"""
    function constraint_boundary_voltage_angle(
        pm::_PM.ACRPowerModel,
        pmd::_PMD.ACRUPowerModel,
        i::Int,
        f_idx::Tuple{Int,Int,Int},
        f_connections::Vector{Int},
        t_connections::Vector{Int};
        nw::Int = nw_id_default
    )

ACR-ACRU boundary bus voltage angle constraints.
"""
function constraint_boundary_voltage_angle(pm::_PM.ACRPowerModel, pmd::_PMD.ACRUPowerModel, ::Int, f_idx::Tuple{Int,Int,Int}, ::Vector{Int}, ::Vector{Int}; nw::Int=nw_id_default)
    i, f_bus, t_bus = f_idx

    vi_fr = _PM.var(pm, nw, :vi, f_bus)
    vr_to = _PMD.var(pmd, nw, :vr, t_bus)
    vi_to = _PMD.var(pmd, nw, :vi, t_bus)

    # Add constraint(s): r->real, i->imaginary
    JuMP.@constraint(pm.model, vi_fr[1] == vi_to[1])

    # Add constraints related to 120 degrees offset for the distribution b and c phases
    shift_120degs_rad = deg2rad(120)

    # TODO: These are non-linear constraints due to transformation to degrees of phase a angle (another way - non-linear may be possible)
    JuMP.@NLconstraint(pm.model, vi_to[2] == tan(atan(vi_to[1]/vr_to[1]) - shift_120degs_rad)*vr_to[2])
    JuMP.@NLconstraint(pm.model, vi_to[3] == tan(atan(vi_to[1]/vr_to[1]) + shift_120degs_rad)*vr_to[3])
end
