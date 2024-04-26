# First-Order Taylor Polar coordinates (FOTP) Constraints

"""
    function constraint_distribution_power_balance(
        pmitd::AbstractPowerModelITD,
        pmd::_PMD.FOTPUPowerModel,
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

FOTPU distribution constraint power balance.
"""
function constraint_distribution_power_balance(pmitd::AbstractPowerModelITD, pmd::_PMD.FOTPUPowerModel, n::Int, i::Int, terminals::Vector{Int}, grounded::Vector{Bool}, bus_arcs::Vector{Tuple{Tuple{Int,Int,Int},Vector{Int}}}, bus_arcs_sw::Vector{Tuple{Tuple{Int,Int,Int},Vector{Int}}}, bus_arcs_trans::Vector{Tuple{Tuple{Int,Int,Int},Vector{Int}}}, bus_gens::Vector{Tuple{Int,Vector{Int}}}, bus_storage::Vector{Tuple{Int,Vector{Int}}}, bus_loads::Vector{Tuple{Int,Vector{Int}}}, bus_shunts::Vector{Tuple{Int,Vector{Int}}}, bus_arcs_boundary_to)

    vm   = _PMD.var(pmd, n, :vm, i)
    va   = _PMD.var(pmd, n, :va, i)
    vm0   = _PMD.var(pmd, n, :vm0, i)
    va0   = _PMD.var(pmd, n, :va0, i)

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

    Gs, Bs = _PMD._build_bus_shunt_matrices(pmd, n, terminals, bus_shunts)

    # Boundary
    pbound_to    = get(var(pmitd, n),    :pbound_to, Dict()); _PMD._check_var_keys(pbound_to, bus_arcs_boundary_to, "active power", "boundary")
    qbound_to    = get(var(pmitd, n),    :qbound_to, Dict()); _PMD._check_var_keys(qbound_to, bus_arcs_boundary_to, "reactive power", "boundary")


    cstr_p = []
    cstr_q = []

    ungrounded_terminals = [(idx,t) for (idx,t) in enumerate(terminals) if !grounded[idx]]

    for (idx,t) in ungrounded_terminals
        if any(Bs[idx,jdx] != 0 for (jdx, u) in ungrounded_terminals if idx != jdx) || any(Gs[idx,jdx] != 0 for (jdx, u) in ungrounded_terminals if idx != jdx)
            cp = JuMP.@constraint(pmitd.model,
                  sum(  p[a][t] for (a, conns) in bus_arcs if t in conns)
                + sum(psw[a][t] for (a, conns) in bus_arcs_sw if t in conns)
                + sum( pt[a][t] for (a, conns) in bus_arcs_trans if t in conns)
                - sum( pg[g][t] for (g, conns) in bus_gens if t in conns)
                + sum( ps[s][t] for (s, conns) in bus_storage if t in conns)
                + sum( pd[l][t] for (l, conns) in bus_loads if t in conns)
                + sum(pbound_to[a_pbound_to][t] for a_pbound_to in bus_arcs_boundary_to)
                + ( Gs[idx,idx]*(vm0[t]^2+2*vm0[t]*(vm[t]-vm0[t]))
                    +sum( Gs[idx,jdx] * vm0[t]*vm0[u] * cos(va0[t]-va0[u])
                         +Bs[idx,jdx] * vm0[t]*vm0[u] * sin(va0[t]-va0[u])
                         +[Gs[idx,jdx]*vm0[u]*cos(va0[t]-va0[u]) Gs[idx,jdx]*vm0[t]*cos(va0[t]-va0[u]) -Gs[idx,jdx]*vm0[t]*vm0[u]*sin(va0[t]-va0[u])  Gs[idx,jdx]*vm0[t]*vm0[u]*sin(va0[t]-va0[u])]*[vm[t]-vm0[t];vm[u]-vm0[u];va[t]-va0[t];va[u]-va0[u]]
                         +[Bs[idx,jdx]*vm0[u]*sin(va0[t]-va0[u]) Bs[idx,jdx]*vm0[t]*sin(va0[t]-va0[u])  Bs[idx,jdx]*vm0[t]*vm0[u]*cos(va0[t]-va0[u]) -Bs[idx,jdx]*vm0[t]*vm0[u]*cos(va0[t]-va0[u])]*[vm[t]-vm0[t];vm[u]-vm0[u];va[t]-va0[t];va[u]-va0[u]]
                        for (jdx,u) in ungrounded_terminals if idx != jdx)
                )
                ==
                0.0
            )
            push!(cstr_p, cp)

            cq = JuMP.@constraint(pmitd.model,
                  sum(  q[a][t] for (a, conns) in bus_arcs if t in conns)
                + sum(qsw[a][t] for (a, conns) in bus_arcs_sw if t in conns)
                + sum( qt[a][t] for (a, conns) in bus_arcs_trans if t in conns)
                - sum( qg[g][t] for (g, conns) in bus_gens if t in conns)
                + sum( qs[s][t] for (s, conns) in bus_storage if t in conns)
                + sum( qd[l][t] for (l, conns) in bus_loads if t in conns)
                + sum(qbound_to[a_qbound_to][t] for a_qbound_to in bus_arcs_boundary_to)
                + ( -Bs[idx,idx]*(vm0[t]^2+2*vm0[t]*(vm[t]-vm0[t]))
                    -sum( Bs[idx,jdx] * vm0[t]*vm0[u] * cos(va0[t]-va0[u])
                         -Gs[idx,jdx] * vm0[t]*vm0[u] * sin(va0[t]-va0[u])
                         +[Bs[idx,jdx]*vm0[u]*cos(va0[t]-va0[u])   Bs[idx,jdx]*vm0[t]*cos(va0[t]-va0[u]) -Bs[idx,jdx]*vm0[t]*vm0[u]*sin(va0[t]-va0[u]) Bs[idx,jdx]*vm0[t]*vm0[u]*sin(va0[t]-va0[u])]*[vm[t]-vm0[t];vm[u]-vm0[u];va[t]-va0[t];va[u]-va0[u]]
                         +[-Gs[idx,jdx]*vm0[u]*sin(va0[t]-va0[u]) -Gs[idx,jdx]*vm0[t]*sin(va0[t]-va0[u]) -Gs[idx,jdx]*vm0[t]*vm0[u]*cos(va0[t]-va0[u]) Gs[idx,jdx]*vm0[t]*vm0[u]*cos(va0[t]-va0[u])]*[vm[t]-vm0[t];vm[u]-vm0[u];va[t]-va0[t];va[u]-va0[u]]
                         for (jdx,u) in ungrounded_terminals if idx != jdx)
                )
                ==
                0.0
            )
            push!(cstr_q, cq)
        else
            cp = JuMP.@constraint(pmitd.model,
                  sum(  p[a][t] for (a, conns) in bus_arcs if t in conns)
                + sum(psw[a][t] for (a, conns) in bus_arcs_sw if t in conns)
                + sum( pt[a][t] for (a, conns) in bus_arcs_trans if t in conns)
                - sum( pg[g][t] for (g, conns) in bus_gens if t in conns)
                + sum( ps[s][t] for (s, conns) in bus_storage if t in conns)
                + sum( pd[l][t] for (l, conns) in bus_loads if t in conns)
                + sum(pbound_to[a_pbound_to][t] for a_pbound_to in bus_arcs_boundary_to)
                + Gs[idx,idx]*(vm0[t]^2+2*vm0[t]*(vm[t]-vm0[t]))
                ==
                0.0
            )
            push!(cstr_p, cp)

            cq = JuMP.@constraint(pmitd.model,
                  sum(  q[a][t] for (a, conns) in bus_arcs if t in conns)
                + sum(qsw[a][t] for (a, conns) in bus_arcs_sw if t in conns)
                + sum( qt[a][t] for (a, conns) in bus_arcs_trans if t in conns)
                - sum( qg[g][t] for (g, conns) in bus_gens if t in conns)
                + sum( qs[s][t] for (s, conns) in bus_storage if t in conns)
                + sum( qd[l][t] for (l, conns) in bus_loads if t in conns)
                + sum(qbound_to[a_qbound_to][t] for a_qbound_to in bus_arcs_boundary_to)
                - Bs[idx,idx]*(vm0[t]^2+2*vm0[t]*(vm[t]-vm0[t]))
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
        pmd::_PMD.FOTPUPowerModel,
        i::Int,
        f_idx::Tuple{Int,Int,Int},
        f_connections::Vector{Int},
        t_connections::Vector{Int};
        nw::Int=nw_id_default
    )

ACP-FOTPU boundary bus voltage magnitude constraints.
"""
function constraint_boundary_voltage_magnitude(pm::_PM.ACPPowerModel, pmd::_PMD.FOTPUPowerModel, i::Int, f_idx::Tuple{Int,Int,Int}, f_connections::Vector{Int}, t_connections::Vector{Int}; nw::Int=nw_id_default)

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
        pmd::_PMD.FOTPUPowerModel,
        i::Int,
        f_idx::Tuple{Int,Int,Int},
        f_connections::Vector{Int},
        t_connections::Vector{Int};
        nw::Int=nw_id_default
    )

ACP-FOTPU boundary bus voltage angle constraints.
"""
function constraint_boundary_voltage_angle(pm::_PM.ACPPowerModel, pmd::_PMD.FOTPUPowerModel, i::Int, f_idx::Tuple{Int,Int,Int}, f_connections::Vector{Int}, t_connections::Vector{Int}; nw::Int=nw_id_default)

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
