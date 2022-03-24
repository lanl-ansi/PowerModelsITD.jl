# ACP Constraints

"""
    function constraint_transmission_power_balance(
        pmitd::AbstractPowerModelITD,
        pm::_PM.AbstractACPModel,
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

ACP transmission constraint power balance.
"""
function constraint_transmission_power_balance(pmitd::AbstractPowerModelITD, pm::_PM.AbstractACPModel, n::Int, j::Int, i::Int, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_qd, bus_gs, bus_bs, bus_arcs_boundary_from)

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

    # the check "typeof(p[arc]) <: JuMP.NonlinearExpression" is required for the
    # case when p/q are nonlinear expressions instead of decision variables
    # once NLExpressions are first order in JuMP it should be possible to
    # remove this.
    nl_form = length(bus_arcs) > 0 && (typeof(p[iterate(bus_arcs)[1]]) <: JuMP.NonlinearExpression)

    if !nl_form
        cstr_p = JuMP.@constraint(pmitd.model,
            sum(p[a] for a in bus_arcs)
            + sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
            + sum(psw[a_sw] for a_sw in bus_arcs_sw)
            + sum(pbound_fr[a_pbound_fr][1] for a_pbound_fr in bus_arcs_boundary_from)
            ==
            sum(pg[g] for g in bus_gens)
            - sum(ps[s] for s in bus_storage)
            - sum(pd for (i,pd) in bus_pd)
            - sum(gs for (i,gs) in bus_gs)*vm^2
        )
    else
        cstr_p = JuMP.@NLconstraint(pmitd.model,
            sum(p[a] for a in bus_arcs)
            + sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
            + sum(psw[a_sw] for a_sw in bus_arcs_sw)
            + sum(pbound_fr[a_pbound_fr][1] for a_pbound_fr in bus_arcs_boundary_from)
            ==
            sum(pg[g] for g in bus_gens)
            - sum(ps[s] for s in bus_storage)
            - sum(pd for (i,pd) in bus_pd)
            - sum(gs for (i,gs) in bus_gs)*vm^2
        )
    end

    if !nl_form
        cstr_q = JuMP.@constraint(pmitd.model,
            sum(q[a] for a in bus_arcs)
            + sum(q_dc[a_dc] for a_dc in bus_arcs_dc)
            + sum(qsw[a_sw] for a_sw in bus_arcs_sw)
            + sum(qbound_fr[a_qbound_fr][1] for a_qbound_fr in bus_arcs_boundary_from)
            ==
            sum(qg[g] for g in bus_gens)
            - sum(qs[s] for s in bus_storage)
            - sum(qd for (i,qd) in bus_qd)
            + sum(bs for (i,bs) in bus_bs)*vm^2
        )
    else
        cstr_q = JuMP.@NLconstraint(pmitd.model,
            sum(q[a] for a in bus_arcs)
            + sum(q_dc[a_dc] for a_dc in bus_arcs_dc)
            + sum(qsw[a_sw] for a_sw in bus_arcs_sw)
            + sum(qbound_fr[a_qbound_fr][1] for a_qbound_fr in bus_arcs_boundary_from)
            ==
            sum(qg[g] for g in bus_gens)
            - sum(qs[s] for s in bus_storage)
            - sum(qd for (i,qd) in bus_qd)
            + sum(bs for (i,bs) in bus_bs)*vm^2
        )
    end

    if _IM.report_duals(pmitd)
        sol(pmitd, n, :bus, i)[:lam_kcl_r] = cstr_p
        sol(pmitd, n, :bus, i)[:lam_kcl_i] = cstr_q
    end

end


"""
    function constraint_distribution_power_balance(
        pmitd::AbstractPowerModelITD,
        pmd::_PMD.AbstractUnbalancedACPModel,
        n::Int,
        j::Int,
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

ACPU distribution constraint power balance.
"""
function constraint_distribution_power_balance(pmitd::AbstractPowerModelITD, pmd::_PMD.AbstractUnbalancedACPModel, n::Int, j::Int, i::Int, terminals::Vector{Int}, grounded::Vector{Bool}, bus_arcs::Vector{Tuple{Tuple{Int,Int,Int},Vector{Int}}}, bus_arcs_sw::Vector{Tuple{Tuple{Int,Int,Int},Vector{Int}}}, bus_arcs_trans::Vector{Tuple{Tuple{Int,Int,Int},Vector{Int}}}, bus_gens::Vector{Tuple{Int,Vector{Int}}}, bus_storage::Vector{Tuple{Int,Vector{Int}}}, bus_loads::Vector{Tuple{Int,Vector{Int}}}, bus_shunts::Vector{Tuple{Int,Vector{Int}}}, bus_arcs_boundary_to)
    vm = _PMD.var(pmd, n, :vm, i)
    va = _PMD.var(pmd, n, :va, i)

    p    = _PMD.get(_PMD.var(pmd, n),      :p, Dict()); _PMD._check_var_keys(  p, bus_arcs, "active power", "branch")
    q    = _PMD.get(_PMD.var(pmd, n),      :q, Dict()); _PMD._check_var_keys(  q, bus_arcs, "reactive power", "branch")
    pg   = _PMD.get(_PMD.var(pmd, n), :pg_bus, Dict()); _PMD._check_var_keys( pg, bus_gens, "active power", "generator")
    qg   = _PMD.get(_PMD.var(pmd, n), :qg_bus, Dict()); _PMD._check_var_keys( qg, bus_gens, "reactive power", "generator")
    ps   = _PMD.get(_PMD.var(pmd, n),     :ps, Dict()); _PMD._check_var_keys( ps, bus_storage, "active power", "storage")
    qs   = _PMD.get(_PMD.var(pmd, n),     :qs, Dict()); _PMD._check_var_keys( qs, bus_storage, "reactive power", "storage")
    psw  = _PMD.get(_PMD.var(pmd, n),    :psw, Dict()); _PMD._check_var_keys(psw, bus_arcs_sw, "active power", "switch")
    qsw  = _PMD.get(_PMD.var(pmd, n),    :qsw, Dict()); _PMD._check_var_keys(qsw, bus_arcs_sw, "reactive power", "switch")
    pt   = _PMD.get(_PMD.var(pmd, n),     :pt, Dict()); _PMD._check_var_keys( pt, bus_arcs_trans, "active power", "transformer")
    qt   = _PMD.get(_PMD.var(pmd, n),     :qt, Dict()); _PMD._check_var_keys( qt, bus_arcs_trans, "reactive power", "transformer")
    pd   = _PMD.get(_PMD.var(pmd, n), :pd_bus, Dict()); _PMD._check_var_keys( pd, bus_loads, "active power", "load")
    qd   = _PMD.get(_PMD.var(pmd, n), :qd_bus, Dict()); _PMD._check_var_keys( pd, bus_loads, "reactive power", "load")

    # Boundary
    pbound_to    = get(var(pmitd, n),    :pbound_to, Dict()); _PMD._check_var_keys(pbound_to, bus_arcs_boundary_to, "active power", "boundary")
    qbound_to    = get(var(pmitd, n),    :qbound_to, Dict()); _PMD._check_var_keys(qbound_to, bus_arcs_boundary_to, "reactive power", "boundary")

    Gs, Bs = _PMD._build_bus_shunt_matrices(pmd, n, terminals, bus_shunts)

    cstr_p = []
    cstr_q = []

    ungrounded_terminals = [(idx,t) for (idx,t) in enumerate(terminals) if !grounded[idx]]

    for (idx,t) in ungrounded_terminals
        if any(Bs[idx,jdx] != 0 for (jdx, u) in ungrounded_terminals if idx != jdx) || any(Gs[idx,jdx] != 0 for (jdx, u) in ungrounded_terminals if idx != jdx)
            cp = JuMP.@NLconstraint(pmitd.model,
                  sum(  p[a][t] for (a, conns) in bus_arcs if t in conns)
                + sum(psw[a][t] for (a, conns) in bus_arcs_sw if t in conns)
                + sum( pt[a][t] for (a, conns) in bus_arcs_trans if t in conns)
                - sum( pg[g][t] for (g, conns) in bus_gens if t in conns)
                + sum( ps[s][t] for (s, conns) in bus_storage if t in conns)
                + sum( pd[l][t] for (l, conns) in bus_loads if t in conns)
                + sum(pbound_to[a_pbound_to][t] for a_pbound_to in bus_arcs_boundary_to)
                + ( # shunt
                    +Gs[idx,idx] * vm[t]^2
                    +sum( Gs[idx,jdx] * vm[t]*vm[u] * cos(va[t]-va[u])
                         +Bs[idx,jdx] * vm[t]*vm[u] * sin(va[t]-va[u])
                        for (jdx,u) in ungrounded_terminals if idx != jdx)
                )
                ==
                0.0
            )
            push!(cstr_p, cp)

            cq = JuMP.@NLconstraint(pmitd.model,
                  sum(  q[a][t] for (a, conns) in bus_arcs if t in conns)
                + sum(qsw[a][t] for (a, conns) in bus_arcs_sw if t in conns)
                + sum( qt[a][t] for (a, conns) in bus_arcs_trans if t in conns)
                - sum( qg[g][t] for (g, conns) in bus_gens if t in conns)
                + sum( qs[s][t] for (s, conns) in bus_storage if t in conns)
                + sum( qd[l][t] for (l, conns) in bus_loads if t in conns)
                + sum(qbound_to[a_qbound_to][t] for a_qbound_to in bus_arcs_boundary_to)
                + ( # shunt
                    -Bs[idx,idx] * vm[t]^2
                    -sum( Bs[idx,jdx] * vm[t]*vm[u] * cos(va[t]-va[u])
                         -Gs[idx,jdx] * vm[t]*vm[u] * sin(va[t]-va[u])
                         for (jdx,u) in ungrounded_terminals if idx != jdx)
                )
                ==
                0.0
            )
            push!(cstr_q, cq)
        else
            cp = @smart_constraint(pmitd.model, [p, pg, ps, psw, pt, pd, pbound_to, vm],
                  sum(  p[a][t] for (a, conns) in bus_arcs if t in conns)
                + sum(psw[a][t] for (a, conns) in bus_arcs_sw if t in conns)
                + sum( pt[a][t] for (a, conns) in bus_arcs_trans if t in conns)
                - sum( pg[g][t] for (g, conns) in bus_gens if t in conns)
                + sum( ps[s][t] for (s, conns) in bus_storage if t in conns)
                + sum( pd[l][t] for (l, conns) in bus_loads if t in conns)
                + sum(pbound_to[a_pbound_to][t] for a_pbound_to in bus_arcs_boundary_to)
                + Gs[idx,idx] * vm[t]^2
                ==
                0.0
            )
            push!(cstr_p, cp)

            cq = @smart_constraint(pmitd.model, [q, qg, qs, qsw, qt, qd, qbound_to, vm],
                  sum(  q[a][t] for (a, conns) in bus_arcs if t in conns)
                + sum(qsw[a][t] for (a, conns) in bus_arcs_sw if t in conns)
                + sum( qt[a][t] for (a, conns) in bus_arcs_trans if t in conns)
                - sum( qg[g][t] for (g, conns) in bus_gens if t in conns)
                + sum( qs[s][t] for (s, conns) in bus_storage if t in conns)
                + sum( qd[l][t] for (l, conns) in bus_loads if t in conns)
                + sum(qbound_to[a_qbound_to][t] for a_qbound_to in bus_arcs_boundary_to)
                - Bs[idx,idx] * vm[t]^2
                ==
                0.0
            )
            push!(cstr_q, cq)
        end
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
        pm::_PM.ACPPowerModel,
        pmd::_PMD.ACPUPowerModel,
        i::Int,
        f_idx::Tuple{Int,Int,Int},
        f_connections::Vector{Int},
        t_connections::Vector{Int};
        nw::Int = nw_id_default
    )

ACP-ACPU boundary bus voltage magnitude constraints.
"""
function constraint_boundary_voltage_magnitude(pm::_PM.ACPPowerModel, pmd::_PMD.ACPUPowerModel, ::Int, f_idx::Tuple{Int,Int,Int}, ::Vector{Int}, ::Vector{Int}; nw::Int=nw_id_default)

    i, f_bus, t_bus = f_idx

    vm_fr = _PM.var(pm, nw, :vm, f_bus)
    vm_to = _PMD.var(pmd, nw, :vm, t_bus)

    # Add constraint(s): m->magnitude
    JuMP.@constraint(pm.model, vm_fr[1] == vm_to[1])
    JuMP.@constraint(pm.model, vm_fr[1] == vm_to[2])
    JuMP.@constraint(pm.model, vm_fr[1] == vm_to[3])

end


"""
    function constraint_boundary_voltage_angle(
        pm::_PM.ACPPowerModel,
        pmd::_PMD.ACPUPowerModel,
        i::Int,
        f_idx::Tuple{Int,Int,Int},
        f_connections::Vector{Int},
        t_connections::Vector{Int};
        nw::Int = nw_id_default
    )

ACP-ACPU boundary bus voltage angle constraints.
"""
function constraint_boundary_voltage_angle(pm::_PM.ACPPowerModel, pmd::_PMD.ACPUPowerModel, ::Int, f_idx::Tuple{Int,Int,Int}, ::Vector{Int}, ::Vector{Int}; nw::Int=nw_id_default)
    i, f_bus, t_bus = f_idx

    va_fr = _PM.var(pm, nw, :va, f_bus)
    va_to = _PMD.var(pmd, nw, :va, t_bus)

    # Add constraint(s): a->angle
    JuMP.@constraint(pm.model, va_fr[1] == va_to[1])

    # Add constraints related to 120 degrees offset for the distribution b and c phases
    shift_120degs_rad = deg2rad(120)

    # Offset constraints for other phases (-+120 degrees)
    JuMP.@constraint(pm.model, va_to[2] == (va_to[1] - shift_120degs_rad))
    JuMP.@constraint(pm.model, va_to[3] == (va_to[1] + shift_120degs_rad))
end
