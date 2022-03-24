# LinDist3FlowPowerModel Constraints

"""
    function constraint_distribution_power_balance(
        pmitd::AbstractBFPowerModelITD,
        pmd::_PMD.LPUBFDiagPowerModel,
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

LinDist3FlowPowerModel distribution constraint power balance.
"""
function constraint_distribution_power_balance(pmitd::AbstractBFPowerModelITD, pmd::_PMD.LPUBFDiagPowerModel, n::Int, j::Int, i::Int, terminals::Vector{Int}, grounded::Vector{Bool}, bus_arcs::Vector{Tuple{Tuple{Int,Int,Int},Vector{Int}}}, bus_arcs_sw::Vector{Tuple{Tuple{Int,Int,Int},Vector{Int}}}, bus_arcs_trans::Vector{Tuple{Tuple{Int,Int,Int},Vector{Int}}}, bus_gens::Vector{Tuple{Int,Vector{Int}}}, bus_storage::Vector{Tuple{Int,Vector{Int}}}, bus_loads::Vector{Tuple{Int,Vector{Int}}}, bus_shunts::Vector{Tuple{Int,Vector{Int}}}, bus_arcs_boundary_to)
    w = _PMD.var(pmd, n, :w, i)
    p   = _PMD.get(_PMD.var(pmd, n),      :p,   Dict()); _PMD._check_var_keys(p,   bus_arcs, "active power", "branch")
    q   = _PMD.get(_PMD.var(pmd, n),      :q,   Dict()); _PMD._check_var_keys(q,   bus_arcs, "reactive power", "branch")
    psw = _PMD.get(_PMD.var(pmd, n),    :psw, Dict()); _PMD._check_var_keys(psw, bus_arcs_sw, "active power", "switch")
    qsw = _PMD.get(_PMD.var(pmd, n),    :qsw, Dict()); _PMD._check_var_keys(qsw, bus_arcs_sw, "reactive power", "switch")
    pt  = _PMD.get(_PMD.var(pmd, n),     :pt,  Dict()); _PMD._check_var_keys(pt,  bus_arcs_trans, "active power", "transformer")
    qt  = _PMD.get(_PMD.var(pmd, n),     :qt,  Dict()); _PMD._check_var_keys(qt,  bus_arcs_trans, "reactive power", "transformer")
    pg  = _PMD.get(_PMD.var(pmd, n),     :pg,  Dict()); _PMD._check_var_keys(pg,  bus_gens, "active power", "generator")
    qg  = _PMD.get(_PMD.var(pmd, n),     :qg,  Dict()); _PMD._check_var_keys(qg,  bus_gens, "reactive power", "generator")
    ps  = _PMD.get(_PMD.var(pmd, n),     :ps,  Dict()); _PMD._check_var_keys(ps,  bus_storage, "active power", "storage")
    qs  = _PMD.get(_PMD.var(pmd, n),     :qs,  Dict()); _PMD._check_var_keys(qs,  bus_storage, "reactive power", "storage")
    pd  = _PMD.get(_PMD.var(pmd, n), :pd_bus,  Dict()); _PMD._check_var_keys(pd,  bus_loads, "active power", "load")
    qd  = _PMD.get(_PMD.var(pmd, n), :qd_bus,  Dict()); _PMD._check_var_keys(qd,  bus_loads, "reactive power", "load")

    # Boundary
    pbound_to    = get(var(pmitd, n),    :pbound_to, Dict()); _PMD._check_var_keys(pbound_to, bus_arcs_boundary_to, "active power", "boundary")
    qbound_to    = get(var(pmitd, n),    :qbound_to, Dict()); _PMD._check_var_keys(qbound_to, bus_arcs_boundary_to, "reactive power", "boundary")

    cstr_p = []
    cstr_q = []

    ungrounded_terminals = [(idx,t) for (idx,t) in enumerate(terminals) if !grounded[idx]]

    for (idx,t) in ungrounded_terminals
        cp = JuMP.@constraint(pmitd.model,
              sum(  p[a][t] for (a, conns) in bus_arcs if t in conns)
            + sum(psw[a][t] for (a, conns) in bus_arcs_sw if t in conns)
            + sum( pt[a][t] for (a, conns) in bus_arcs_trans if t in conns)
            - sum( pg[g][t] for (g, conns) in bus_gens if t in conns)
            + sum( ps[s][t] for (s, conns) in bus_storage if t in conns)
            + sum( pd[d][t] for (d, conns) in bus_loads if t in conns)
            + sum(diag(ref(pm, nw, :shunt, sh, "gs"))[findfirst(isequal(t), conns)]*w[t] for (sh, conns) in bus_shunts if t in conns)
            + sum(pbound_to[a_pbound_to][t] for a_pbound_to in bus_arcs_boundary_to)
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
            + sum( qd[d][t] for (d, conns) in bus_loads if t in conns)
            - sum(diag(ref(pm, nw, :shunt, sh, "bs"))[findfirst(isequal(t), conns)]*w[t] for (sh, conns) in bus_shunts if t in conns)
            + sum(qbound_to[a_qbound_to][t] for a_qbound_to in bus_arcs_boundary_to)
            ==
            0.0
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
        pm::_PM.AbstractSOCBFModel,
        pmd::_PMD.LPUBFDiagPowerModel,
        i::Int,
        f_idx::Tuple{Int,Int,Int},
        f_connections::Vector{Int},
        t_connections::Vector{Int};
        nw::Int=nw_id_default
    )

SOCBF-LinDist3FlowPowerModel boundary bus voltage magnitude constraints.
"""
function constraint_boundary_voltage_magnitude(pm::_PM.AbstractSOCBFModel, pmd::_PMD.LPUBFDiagPowerModel, i::Int, f_idx::Tuple{Int,Int,Int}, f_connections::Vector{Int}, t_connections::Vector{Int}; nw::Int=nw_id_default)
    i, f_bus, t_bus = f_idx
    w_fr = _PM.var(pm, nw, :w, f_bus)
    w_to = _PMD.var(pmd, nw, :w, t_bus)

    JuMP.@constraint(pm.model, w_fr == w_to[1])
    JuMP.@constraint(pm.model, w_fr == w_to[2])
    JuMP.@constraint(pm.model, w_fr == w_to[3])
end


"""
    function constraint_boundary_voltage_angle(
        pm::_PM.AbstractSOCBFModel,
        pmd::_PMD.LPUBFDiagPowerModel,
        i::Int,
        f_idx::Tuple{Int,Int,Int},
        f_connections::Vector{Int},
        t_connections::Vector{Int};
        nw::Int=nw_id_default
    )

SOCBF-LinDist3FlowPowerModel boundary bus voltage angle constraints.
"""
function constraint_boundary_voltage_angle(pm::_PM.AbstractSOCBFModel, pmd::_PMD.LPUBFDiagPowerModel, i::Int, f_idx::Tuple{Int,Int,Int}, f_connections::Vector{Int}, t_connections::Vector{Int}; nw::Int=nw_id_default)
end


"""
    function constraint_boundary_voltage_magnitude(
        pm::_PM.AbstractBFAModel,
        pmd::_PMD.LPUBFDiagPowerModel,
        i::Int,
        f_idx::Tuple{Int,Int,Int},
        f_connections::Vector{Int},
        t_connections::Vector{Int};
        nw::Int=nw_id_default
    )

BFA-LinDist3FlowPowerModel boundary bus voltage magnitude constraints.
"""
function constraint_boundary_voltage_magnitude(pm::_PM.AbstractBFAModel, pmd::_PMD.LPUBFDiagPowerModel, i::Int, f_idx::Tuple{Int,Int,Int}, f_connections::Vector{Int}, t_connections::Vector{Int}; nw::Int=nw_id_default)
    i, f_bus, t_bus = f_idx
    w_fr = _PM.var(pm, nw, :w, f_bus)
    w_to = _PMD.var(pmd, nw, :w, t_bus)

    JuMP.@constraint(pm.model, w_fr == w_to[1])
    JuMP.@constraint(pm.model, w_fr == w_to[2])
    JuMP.@constraint(pm.model, w_fr == w_to[3])
end


"""
    function constraint_boundary_voltage_angle(
        pm::_PM.AbstractBFAModel,
        pmd::_PMD.LPUBFDiagPowerModel,
        i::Int,
        f_idx::Tuple{Int,Int,Int},
        f_connections::Vector{Int},
        t_connections::Vector{Int};
        nw::Int=nw_id_default
    )

BFA-LinDist3FlowPowerModel boundary bus voltage angle constraints.
"""
function constraint_boundary_voltage_angle(pm::_PM.AbstractBFAModel, pmd::_PMD.LPUBFDiagPowerModel, i::Int, f_idx::Tuple{Int,Int,Int}, f_connections::Vector{Int}, t_connections::Vector{Int}; nw::Int=nw_id_default)
end
