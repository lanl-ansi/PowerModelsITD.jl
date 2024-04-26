# Linear (NFA, DCP) Constraints

"""
    function constraint_transmission_power_balance(
        pmitd::AbstractPowerModelITD,
        pm::_PM.AbstractActivePowerModel,
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

DCP/NFA transmission constraint power balance.
"""
function constraint_transmission_power_balance(pmitd::AbstractPowerModelITD, pm::_PM.AbstractActivePowerModel, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_qd, bus_gs, bus_bs, bus_arcs_boundary_from)

    p    = _PM.get(_PM.var(pm, n),    :p, Dict()); _PM._check_var_keys(p, bus_arcs, "active power", "branch")
    pg   = _PM.get(_PM.var(pm, n),   :pg, Dict()); _PM._check_var_keys(pg, bus_gens, "active power", "generator")
    ps   = _PM.get(_PM.var(pm, n),   :ps, Dict()); _PM._check_var_keys(ps, bus_storage, "active power", "storage")
    psw  = _PM.get(_PM.var(pm, n),  :psw, Dict()); _PM._check_var_keys(psw, bus_arcs_sw, "active power", "switch")
    p_dc = _PM.get(_PM.var(pm, n), :p_dc, Dict()); _PM._check_var_keys(p_dc, bus_arcs_dc, "active power", "dcline")

    # Boundary
    pbound_fr    = get(var(pmitd, n),    :pbound_fr, Dict()); _PM._check_var_keys(pbound_fr, bus_arcs_boundary_from, "active power", "boundary")

    cstr = JuMP.@constraint(pmitd.model,
        sum(p[a] for a in bus_arcs)
        + sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
        + sum(psw[a_sw] for a_sw in bus_arcs_sw)
        + sum(pbound_fr[a_pbound_fr][1] for a_pbound_fr in bus_arcs_boundary_from)
        ==
        sum(pg[g] for g in bus_gens)
        - sum(ps[s] for s in bus_storage)
        - sum(pd for pd in values(bus_pd))
        - sum(gs for gs in values(bus_gs))*1.0^2
    )

    if _IM.report_duals(pmitd)
        sol(pmitd, n, :bus, i)[:lam_kcl_r] = cstr
        sol(pmitd, n, :bus, i)[:lam_kcl_i] = NaN
    end

end


"""
    function constraint_distribution_power_balance(
        pmitd::AbstractPowerModelITD,
        pmd::_PMD.AbstractUnbalancedActivePowerModel,
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

DCPU/NFAU distribution constraint power balance.
"""
function constraint_distribution_power_balance(pmitd::AbstractPowerModelITD, pmd::_PMD.AbstractUnbalancedActivePowerModel, n::Int, i::Int, terminals::Vector{Int}, grounded::Vector{Bool}, bus_arcs::Vector{Tuple{Tuple{Int,Int,Int},Vector{Int}}}, bus_arcs_sw::Vector{Tuple{Tuple{Int,Int,Int},Vector{Int}}}, bus_arcs_trans::Vector{Tuple{Tuple{Int,Int,Int},Vector{Int}}}, bus_gens::Vector{Tuple{Int,Vector{Int}}}, bus_storage::Vector{Tuple{Int,Vector{Int}}}, bus_loads::Vector{Tuple{Int,Vector{Int}}}, bus_shunts::Vector{Tuple{Int,Vector{Int}}}, bus_arcs_boundary_to)
    p    = _PMD.get(_PMD.var(pmd, n),    :p, Dict())#; _PMD._check_var_keys(p, bus_arcs, "active power", "branch")
    pg   = _PMD.get(_PMD.var(pmd, n),   :pg_bus, Dict())#; _PMD._check_var_keys(pg, bus_gens, "active power", "generator")
    ps   = _PMD.get(_PMD.var(pmd, n),   :ps, Dict())#; _PMD._check_var_keys(ps, bus_storage, "active power", "storage")
    psw  = _PMD.get(_PMD.var(pmd, n),  :psw, Dict())#; _PMD._check_var_keys(psw, bus_arcs_sw, "active power", "switch")
    pt   = _PMD.get(_PMD.var(pmd, n),   :pt, Dict())#; _PMD._check_var_keys(pt, bus_arcs_trans, "active power", "transformer")
    pd   = _PMD.get(_PMD.var(pmd, n),   :pd_bus, Dict())#; _PMD._check_var_keys(pg, bus_gens, "active power", "generator")

    # Boundary
    pbound_to    = get(var(pmitd, n),    :pbound_to, Dict()); _PMD._check_var_keys(pbound_to, bus_arcs_boundary_to, "active power", "boundary")

    Gt, Bt = _PMD._build_bus_shunt_matrices(pmd, n, terminals, bus_shunts)

    cstr_p = []

    ungrounded_terminals = [(idx,t) for (idx,t) in enumerate(terminals) if !grounded[idx]]

    for (idx,t) in ungrounded_terminals
        cp = JuMP.@constraint(pmitd.model,
              sum(p[a][t] for (a, conns) in bus_arcs if t in conns)
            + sum(psw[a_sw][t] for (a_sw, conns) in bus_arcs_sw if t in conns)
            + sum(pt[a_trans][t] for (a_trans, conns) in bus_arcs_trans if t in conns)
            + sum(pbound_to[a_pbound_to][t] for a_pbound_to in bus_arcs_boundary_to)
            ==
              sum(pg[g][t] for (g, conns) in bus_gens if t in conns)
            - sum(ps[s][t] for (s, conns) in bus_storage if t in conns)
            - sum(pd[d][t] for (d, conns) in bus_loads if t in conns)
            - LinearAlgebra.diag(Gt)[idx]
        )
        push!(cstr_p, cp)
    end

    # omit reactive constraint

    _PMD.con(pmd, n, :lam_kcl_r)[i] = cstr_p
    _PMD.con(pmd, n, :lam_kcl_i)[i] = []

    if _IM.report_duals(pmitd)
        sol(pmitd, n, :bus, i)[:lam_kcl_r] = cstr_p
        sol(pmitd, n, :bus, i)[:lam_kcl_i] = []
    end
end


"""
    function constraint_boundary_voltage_magnitude(
        pm::_PM.DCPPowerModel,
        pmd::_PMD.DCPUPowerModel,
        i::Int,
        f_idx::Tuple{Int,Int,Int},
        f_connections::Vector{Int},
        t_connections::Vector{Int};
        nw::Int = nw_id_default
    )

DCP-DCPU boundary bus voltage magnitude constraints: empty since DC keeps vm = 1 for all.
"""
function constraint_boundary_voltage_magnitude(pm::_PM.DCPPowerModel, pmd::_PMD.DCPUPowerModel, i::Int, f_idx::Tuple{Int,Int,Int}, f_connections::Vector{Int}, t_connections::Vector{Int}; nw::Int = nw_id_default)
end


"""
    function constraint_boundary_voltage_magnitude(
        pm::_PM.NFAPowerModel,
        pmd::_PMD.NFAUPowerModel,
        i::Int,
        f_idx::Tuple{Int,Int,Int},
        f_connections::Vector{Int},
        t_connections::Vector{Int};
        nw::Int = nw_id_default
    )

NFA-NFAU boundary bus voltage magnitude constraints: empty NFA.
"""
function constraint_boundary_voltage_magnitude(pm::_PM.NFAPowerModel, pmd::_PMD.NFAUPowerModel, i::Int, f_idx::Tuple{Int,Int,Int}, f_connections::Vector{Int}, t_connections::Vector{Int}; nw::Int = nw_id_default)
end


"""
    function constraint_boundary_voltage_angle(
        pm::_PM.NFAPowerModel,
        pmd::_PMD.NFAUPowerModel,
        i::Int,
        f_idx::Tuple{Int,Int,Int},
        f_connections::Vector{Int},
        t_connections::Vector{Int};
        nw::Int = nw_id_default
    )

NFA-NFAU boundary bus voltage angle constraints: empty NFA angle.
"""
function constraint_boundary_voltage_angle(pm::_PM.NFAPowerModel, pmd::_PMD.NFAUPowerModel, i::Int, f_idx::Tuple{Int,Int,Int}, f_connections::Vector{Int}, t_connections::Vector{Int}; nw::Int = nw_id_default)
end


"""
    function constraint_boundary_voltage_angle(
        pm::_PM.DCPPowerModel,
        pmd::_PMD.DCPUPowerModel,
        i::Int,
        f_idx::Tuple{Int,Int,Int},
        f_connections::Vector{Int},
        t_connections::Vector{Int};
        nw::Int = nw_id_default
    )

DCP-DCPU boundary bus voltage angle constraints: DCP angle.
"""
function constraint_boundary_voltage_angle(pm::_PM.DCPPowerModel, pmd::_PMD.DCPUPowerModel, i::Int, f_idx::Tuple{Int,Int,Int}, f_connections::Vector{Int}, t_connections::Vector{Int}; nw::Int = nw_id_default)
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
