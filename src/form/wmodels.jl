# W-Models (i.e., SOCBF) Constraints

"""
    function constraint_transmission_power_balance(
        pmitd::AbstractPowerModelITD,
        pm::_PM.AbstractWModels,
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

W Models (e.g., SOCBF) transmission constraint power balance.
"""
function constraint_transmission_power_balance(pmitd::AbstractPowerModelITD, pm::_PM.AbstractWModels, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_qd, bus_gs, bus_bs, bus_arcs_boundary_from)
    w    = _PM.var(pm, n, :w, i)
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
        - sum(gs for gs in values(bus_gs))*w
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
        + sum(bs for bs in values(bus_bs))*w
    )

    if _IM.report_duals(pmitd)
        sol(pmitd, n, :bus, i)[:lam_kcl_r] = cstr_p
        sol(pmitd, n, :bus, i)[:lam_kcl_i] = cstr_q
    end
end


"""
    function constraint_distribution_power_balance(
        pmitd::AbstractPowerModelITD,
        pmd::_PMD.AbstractUnbalancedWModels,
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

Unbalanced W models distribution constraint power balance.
"""
function constraint_distribution_power_balance(pmitd::AbstractPowerModelITD, pmd::_PMD.AbstractUnbalancedWModels, n::Int, i::Int, terminals::Vector{Int}, grounded::Vector{Bool}, bus_arcs::Vector{Tuple{Tuple{Int,Int,Int},Vector{Int}}}, bus_arcs_sw::Vector{Tuple{Tuple{Int,Int,Int},Vector{Int}}}, bus_arcs_trans::Vector{Tuple{Tuple{Int,Int,Int},Vector{Int}}}, bus_gens::Vector{Tuple{Int,Vector{Int}}}, bus_storage::Vector{Tuple{Int,Vector{Int}}}, bus_loads::Vector{Tuple{Int,Vector{Int}}}, bus_shunts::Vector{Tuple{Int,Vector{Int}}}, bus_arcs_boundary_to)
    Wr =  _PMD.var(pmd, n, :Wr, i)
    Wi =  _PMD.var(pmd, n, :Wi, i)
    P =  _PMD.get(_PMD.var(pmd, n), :P, Dict()); _PMD._check_var_keys(P, bus_arcs, "active power", "branch")
    Q =  _PMD.get(_PMD.var(pmd, n), :Q, Dict()); _PMD._check_var_keys(Q, bus_arcs, "reactive power", "branch")
    Psw  =  _PMD.get(_PMD.var(pmd, n),  :Psw, Dict()); _PMD._check_var_keys(Psw, bus_arcs_sw, "active power", "switch")
    Qsw  =  _PMD.get(_PMD.var(pmd, n),  :Qsw, Dict()); _PMD._check_var_keys(Qsw, bus_arcs_sw, "reactive power", "switch")
    Pt   =  _PMD.get(_PMD.var(pmd, n),   :Pt, Dict()); _PMD._check_var_keys(Pt, bus_arcs_trans, "active power", "transformer")
    Qt   =  _PMD.get(_PMD.var(pmd, n),   :Qt, Dict()); _PMD._check_var_keys(Qt, bus_arcs_trans, "reactive power", "transformer")

    pd = _PMD.get(_PMD.var(pmd, n), :pd_bus, Dict()); _PMD._check_var_keys(pd, bus_loads, "active power", "load")
    qd = _PMD.get(_PMD.var(pmd, n), :qd_bus, Dict()); _PMD._check_var_keys(qd, bus_loads, "reactive power", "load")
    pg = _PMD.get(_PMD.var(pmd, n), :pg_bus, Dict()); _PMD._check_var_keys(pg, bus_gens, "active power", "generator")
    qg = _PMD.get(_PMD.var(pmd, n), :qg_bus, Dict()); _PMD._check_var_keys(qg, bus_gens, "reactive power", "generator")
    ps   = _PMD.get(_PMD.var(pmd, n),   :ps, Dict()); _PMD._check_var_keys(ps, bus_storage, "active power", "storage")
    qs   = _PMD.get(_PMD.var(pmd, n),   :qs, Dict()); _PMD._check_var_keys(qs, bus_storage, "reactive power", "storage")

    # Boundary
    pbound_to    = get(var(pmitd, n),    :pbound_to, Dict()); _PMD._check_var_keys(pbound_to, bus_arcs_boundary_to, "active power", "boundary")
    qbound_to    = get(var(pmitd, n),    :qbound_to, Dict()); _PMD._check_var_keys(qbound_to, bus_arcs_boundary_to, "reactive power", "boundary")

    Gt, Bt = _PMD._build_bus_shunt_matrices(pmd, n, terminals, bus_shunts)

    cstr_p = []
    cstr_q = []

    ungrounded_terminals = [(idx,t) for (idx,t) in enumerate(terminals) if !grounded[idx]]

    for (idx,t) in ungrounded_terminals
        cp = JuMP.@constraint(pmitd.model,
            sum(LinearAlgebra.diag(P[a])[findfirst(isequal(t), conns)] for (a, conns) in bus_arcs if t in conns)
            + sum(LinearAlgebra.diag(Psw[a_sw])[findfirst(isequal(t), conns)] for (a_sw, conns) in bus_arcs_sw if t in conns)
            + sum(LinearAlgebra.diag(Pt[a_trans])[findfirst(isequal(t), conns)] for (a_trans, conns) in bus_arcs_trans if t in conns)
            + sum(pbound_to[a_pbound_to][t] for a_pbound_to in bus_arcs_boundary_to)
            ==
            sum(pg[g][t] for (g, conns) in bus_gens if t in conns)
            - sum(ps[s][t] for (s, conns) in bus_storage if t in conns)
            - sum(pd[d][t] for (d, conns) in bus_loads if t in conns)
            - LinearAlgebra.diag(Wr*Gt'+Wi*Bt')[idx]
        )
        push!(cstr_p, cp)

        cq = JuMP.@constraint(pmitd.model,
            sum(LinearAlgebra.diag(Q[a])[findfirst(isequal(t), conns)] for (a, conns) in bus_arcs if t in conns)
            + sum(LinearAlgebra.diag(Qsw[a_sw])[findfirst(isequal(t), conns)] for (a_sw, conns) in bus_arcs_sw if t in conns)
            + sum(LinearAlgebra.diag(Qt[a_trans])[findfirst(isequal(t), conns)] for (a_trans, conns) in bus_arcs_trans if t in conns)
            + sum(qbound_to[a_qbound_to][t] for a_qbound_to in bus_arcs_boundary_to)
            ==
            sum(qg[g][t] for (g, conns) in bus_gens if t in conns)
            - sum(qs[s][t] for (s, conns) in bus_storage if t in conns)
            - sum(qd[d][t] for (d, conns) in bus_loads if t in conns)
            - LinearAlgebra.diag(-Wr*Bt'+Wi*Gt')[idx]
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
        pmd::_PMD.SOCNLPUBFPowerModel,
        i::Int,
        f_idx::Tuple{Int,Int,Int},
        f_connections::Vector{Int},
        t_connections::Vector{Int};
        nw::Int = nw_id_default
    )

SOCBF-SOCNLUBF boundary bus voltage magnitude (W variables) constraints.
"""
function constraint_boundary_voltage_magnitude(pm::_PM.AbstractSOCBFModel, pmd::_PMD.SOCNLPUBFPowerModel, i::Int, f_idx::Tuple{Int,Int,Int}, f_connections::Vector{Int}, t_connections::Vector{Int}; nw::Int = nw_id_default)
    i, f_bus, t_bus = f_idx

    w_fr = _PM.var(pm, nw, :w, f_bus)
    wr_to = _PMD.var(pmd, nw, :w, t_bus)

    JuMP.@constraint(pm.model, w_fr == wr_to[1])
    JuMP.@constraint(pm.model, wr_to[1] == wr_to[2])
    JuMP.@constraint(pm.model, wr_to[1] == wr_to[3])

end


"""
    function constraint_boundary_voltage_angle(
        pm::_PM.AbstractSOCBFModel,
        pmd::_PMD.SOCNLPUBFPowerModel,
        i::Int,
        f_idx::Tuple{Int,Int,Int},
        f_connections::Vector{Int},
        t_connections::Vector{Int};
        nw::Int = nw_id_default
    )

SOCBF-SOCNLUBF boundary bus voltage angle constraints.
"""
function constraint_boundary_voltage_angle(pm::_PM.AbstractSOCBFModel, pmd::_PMD.SOCNLPUBFPowerModel, i::Int, f_idx::Tuple{Int,Int,Int}, f_connections::Vector{Int}, t_connections::Vector{Int}; nw::Int = nw_id_default)
    i, f_bus, t_bus = f_idx

    Wr_to = _PMD.var(pmd, nw, :Wr, t_bus)
    Wi_to = _PMD.var(pmd, nw, :Wi, t_bus)

    shift_120degs_rad = deg2rad(120)

    # These constraints assume angles at the T&D boundary are 0, -120, 120.
    JuMP.@constraint(pm.model, Wi_to[1,2] == (Wr_to[1,2]*tan(shift_120degs_rad)))
    JuMP.@constraint(pm.model, Wi_to[1,3] == (Wr_to[1,3]*tan(-shift_120degs_rad)))
    JuMP.@constraint(pm.model, Wi_to[2,3] == (Wr_to[2,3]*tan(shift_120degs_rad)))
end


"""
    function constraint_boundary_voltage_magnitude(
        pm::_PM.AbstractSOCBFConicModel,
        pmd::_PMD.SOCConicUBFPowerModel,
        i::Int,
        f_idx::Tuple{Int,Int,Int},
        f_connections::Vector{Int},
        t_connections::Vector{Int};
        nw::Int = nw_id_default
    )

SOCBFConic-SOCUBFConic boundary bus voltage magnitude (W variables) constraints.
"""
function constraint_boundary_voltage_magnitude(pm::_PM.AbstractSOCBFConicModel, pmd::_PMD.SOCConicUBFPowerModel, i::Int, f_idx::Tuple{Int,Int,Int}, f_connections::Vector{Int}, t_connections::Vector{Int}; nw::Int = nw_id_default)
    i, f_bus, t_bus = f_idx

    w_fr = _PM.var(pm, nw, :w, f_bus)
    wr_to = _PMD.var(pmd, nw, :w, t_bus)

    JuMP.@constraint(pm.model, w_fr == wr_to[1])
    JuMP.@constraint(pm.model, wr_to[1] == wr_to[2])
    JuMP.@constraint(pm.model, wr_to[1] == wr_to[3])
end


"""
    function constraint_boundary_voltage_angle(
        pm::_PM.AbstractSOCBFConicModel,
        pmd::_PMD.SOCConicUBFPowerModel,
        i::Int,
        f_idx::Tuple{Int,Int,Int},
        f_connections::Vector{Int},
        t_connections::Vector{Int};
        nw::Int = nw_id_default
    )

SOCBFConic-SOCUBFConic boundary bus voltage angle constraints.
"""
function constraint_boundary_voltage_angle(pm::_PM.AbstractSOCBFConicModel, pmd::_PMD.SOCConicUBFPowerModel, i::Int, f_idx::Tuple{Int,Int,Int}, f_connections::Vector{Int}, t_connections::Vector{Int}; nw::Int = nw_id_default)
    i, f_bus, t_bus = f_idx

    Wr_to = _PMD.var(pmd, nw, :Wr, t_bus)
    Wi_to = _PMD.var(pmd, nw, :Wi, t_bus)

    shift_120degs_rad = deg2rad(120)

    # These constraints assume angles at the T&D boundary are 0, -120, 120.
    JuMP.@constraint(pm.model, Wi_to[1,2] == (Wr_to[1,2]*tan(shift_120degs_rad)))
    JuMP.@constraint(pm.model, Wi_to[1,3] == (Wr_to[1,3]*tan(-shift_120degs_rad)))
    JuMP.@constraint(pm.model, Wi_to[2,3] == (Wr_to[2,3]*tan(shift_120degs_rad)))
end


"""
    function constraint_boundary_voltage_magnitude(
        pm::_PM.AbstractSOCWRConicModel,
        pmd::_PMD.SOCConicUBFPowerModel,
        i::Int,
        f_idx::Tuple{Int,Int,Int},
        f_connections::Vector{Int},
        t_connections::Vector{Int};
        nw::Int = nw_id_default
    )

SOCWRConic-SOCConicUBF boundary bus voltage magnitude (W variables) constraints.
"""
function constraint_boundary_voltage_magnitude(pm::_PM.AbstractSOCWRConicModel, pmd::_PMD.SOCConicUBFPowerModel, i::Int, f_idx::Tuple{Int,Int,Int}, f_connections::Vector{Int}, t_connections::Vector{Int}; nw::Int = nw_id_default)
    i, f_bus, t_bus = f_idx

    w_fr = _PM.var(pm, nw, :w, f_bus)
    wr_to = _PMD.var(pmd, nw, :w, t_bus)

    JuMP.@constraint(pm.model, w_fr == wr_to[1])
    JuMP.@constraint(pm.model, wr_to[1] == wr_to[2])
    JuMP.@constraint(pm.model, wr_to[1] == wr_to[3])
end


"""
    function constraint_boundary_voltage_angle(
        pm::_PM.AbstractSOCWRConicModel,
        pmd::_PMD.SOCConicUBFPowerModel,
        i::Int,
        f_idx::Tuple{Int,Int,Int},
        f_connections::Vector{Int},
        t_connections::Vector{Int};
        nw::Int = nw_id_default
    )

SOCWRConic-SOCConicUBF boundary bus voltage angle constraints.
"""
function constraint_boundary_voltage_angle(pm::_PM.AbstractSOCWRConicModel, pmd::_PMD.SOCConicUBFPowerModel, i::Int, f_idx::Tuple{Int,Int,Int}, f_connections::Vector{Int}, t_connections::Vector{Int}; nw::Int = nw_id_default)

    i, f_bus, t_bus = f_idx

    Wr_to = _PMD.var(pmd, nw, :Wr, t_bus)
    Wi_to = _PMD.var(pmd, nw, :Wi, t_bus)

    shift_120degs_rad = deg2rad(120)

    # These constraints assume angles at the T&D boundary are 0, -120, 120.
    JuMP.@constraint(pm.model, Wi_to[1,2] == (Wr_to[1,2]*tan(shift_120degs_rad)))
    JuMP.@constraint(pm.model, Wi_to[1,3] == (Wr_to[1,3]*tan(-shift_120degs_rad)))
    JuMP.@constraint(pm.model, Wi_to[2,3] == (Wr_to[2,3]*tan(shift_120degs_rad)))
end



"""
    function constraint_boundary_voltage_magnitude(
        pm::_PM.AbstractSDPWRMModel,
        pmd::_PMD.SOCConicUBFPowerModel,
        i::Int,
        f_idx::Tuple{Int,Int,Int},
        f_connections::Vector{Int},
        t_connections::Vector{Int};
        nw::Int = nw_id_default
    )

SDPWRM-SOCConicUBF boundary bus voltage magnitude (W variables) constraints.
"""
function constraint_boundary_voltage_magnitude(pm::_PM.AbstractSDPWRMModel, pmd::_PMD.SOCConicUBFPowerModel, i::Int, f_idx::Tuple{Int,Int,Int}, f_connections::Vector{Int}, t_connections::Vector{Int}; nw::Int = nw_id_default)
    i, f_bus, t_bus = f_idx

    w_fr = _PM.var(pm, nw, :w, f_bus)
    wr_to = _PMD.var(pmd, nw, :w, t_bus)

    JuMP.@constraint(pm.model, w_fr == wr_to[1])
    JuMP.@constraint(pm.model, wr_to[1] == wr_to[2])
    JuMP.@constraint(pm.model, wr_to[1] == wr_to[3])
end


"""
    function constraint_boundary_voltage_angle(
        pm::_PM.AbstractSDPWRMModel,
        pmd::_PMD.SOCConicUBFPowerModel,
        i::Int,
        f_idx::Tuple{Int,Int,Int},
        f_connections::Vector{Int},
        t_connections::Vector{Int};
        nw::Int = nw_id_default
    )

SDPWRM-SOCConicUBF boundary bus voltage angle constraints.
"""
function constraint_boundary_voltage_angle(pm::_PM.AbstractSDPWRMModel, pmd::_PMD.SOCConicUBFPowerModel, i::Int, f_idx::Tuple{Int,Int,Int}, f_connections::Vector{Int}, t_connections::Vector{Int}; nw::Int = nw_id_default)
    i, f_bus, t_bus = f_idx

    Wr_to = _PMD.var(pmd, nw, :Wr, t_bus)
    Wi_to = _PMD.var(pmd, nw, :Wi, t_bus)

    shift_120degs_rad = deg2rad(120)

    # These constraints assume angles at the T&D boundary are 0, -120, 120.
    JuMP.@constraint(pm.model, Wi_to[1,2] == (Wr_to[1,2]*tan(shift_120degs_rad)))
    JuMP.@constraint(pm.model, Wi_to[1,3] == (Wr_to[1,3]*tan(-shift_120degs_rad)))
    JuMP.@constraint(pm.model, Wi_to[2,3] == (Wr_to[2,3]*tan(shift_120degs_rad)))
end
