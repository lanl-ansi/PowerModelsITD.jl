# Current-Voltage Rectangular coordinates (IVR) Constraints

"""
    function constraint_transmission_current_balance(
        pmitd::AbstractPowerModelITD,
        pm::_PM.AbstractIVRModel,
        n::Int,
        i::Int,
        bus_arcs,
        bus_arcs_dc,
        bus_gens,
        bus_pd,
        bus_qd,
        bus_gs,
        bus_bs,
        bus_arcs_boundary_from
    )

IVR transmission constraint power balance.
"""
function constraint_transmission_current_balance(pmitd::AbstractPowerModelITD, pm::_PM.AbstractIVRModel, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_gens, bus_pd, bus_qd, bus_gs, bus_bs, bus_arcs_boundary_from)
    vr = _PM.var(pm, n, :vr, i)
    vi = _PM.var(pm, n, :vi, i)

    cr =  _PM.get(_PM.var(pm, n),   :cr, Dict()); _PM._check_var_keys(cr, bus_arcs, "real current", "branch")
    ci =  _PM.get(_PM.var(pm, n),   :ci, Dict()); _PM._check_var_keys(ci, bus_arcs, "imaginary current", "branch")
    crdc = _PM.get(_PM.var(pm, n),  :crdc, Dict()); _PM._check_var_keys(crdc, bus_arcs_dc, "real current", "dcline")
    cidc = _PM.get(_PM.var(pm, n),  :cidc, Dict()); _PM._check_var_keys(cidc, bus_arcs_dc, "imaginary current", "dcline")
    crg = _PM.get(_PM.var(pm, n), :crg, Dict()); _PM._check_var_keys(crg, bus_gens, "real current", "generator")
    cig = _PM.get(_PM.var(pm, n), :cig, Dict()); _PM._check_var_keys(cig, bus_gens, "imaginary current", "generator")

    # Boundary
    crbound_fr    = get(var(pmitd, n),    :crbound_fr, Dict()); _PM._check_var_keys(crbound_fr, bus_arcs_boundary_from, "real current", "boundary")
    cibound_fr    = get(var(pmitd, n),    :cibound_fr, Dict()); _PM._check_var_keys(cibound_fr, bus_arcs_boundary_from, "imaginary current", "boundary")

    JuMP.@constraint(pmitd.model, sum(cr[a] for a in bus_arcs)
        + sum(crdc[d] for d in bus_arcs_dc)
        + sum(crbound_fr[a_crbound_fr][1] for a_crbound_fr in bus_arcs_boundary_from)
        ==
        sum(crg[g] for g in bus_gens)
        - (sum(pd for pd in values(bus_pd))*vr + sum(qd for qd in values(bus_qd))*vi)/(vr^2 + vi^2)
        - sum(gs for gs in values(bus_gs))*vr + sum(bs for bs in values(bus_bs))*vi
    )

    JuMP.@constraint(pmitd.model, sum(ci[a] for a in bus_arcs)
        + sum(cidc[d] for d in bus_arcs_dc)
        + sum(cibound_fr[a_cibound_fr][1] for a_cibound_fr in bus_arcs_boundary_from)
        ==
        sum(cig[g] for g in bus_gens)
        - (sum(pd for pd in values(bus_pd))*vi - sum(qd for qd in values(bus_qd))*vr)/(vr^2 + vi^2)
        - sum(gs for gs in values(bus_gs))*vi - sum(bs for bs in values(bus_bs))*vr
    )

end


"""
    function constraint_distribution_current_balance(
        pmitd::AbstractPowerModelITD,
        pmd::_PMD.AbstractUnbalancedIVRModel,
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

IVRU distribution constraint power balance.
"""
function constraint_distribution_current_balance(pmitd::AbstractPowerModelITD, pmd::_PMD.AbstractUnbalancedIVRModel, n::Int, i::Int, terminals::Vector{Int}, grounded::Vector{Bool}, bus_arcs::Vector{Tuple{Tuple{Int,Int,Int},Vector{Int}}}, bus_arcs_sw::Vector{Tuple{Tuple{Int,Int,Int},Vector{Int}}}, bus_arcs_trans::Vector{Tuple{Tuple{Int,Int,Int},Vector{Int}}}, bus_gens::Vector{Tuple{Int,Vector{Int}}}, bus_storage::Vector{Tuple{Int,Vector{Int}}}, bus_loads::Vector{Tuple{Int,Vector{Int}}}, bus_shunts::Vector{Tuple{Int,Vector{Int}}}, bus_arcs_boundary_to)
    vr = _PMD.var(pmd, n, :vr, i)
    vi = _PMD.var(pmd, n, :vi, i)

    cr    = _PMD.get(_PMD.var(pmd, n),    :cr, Dict()); _PMD._check_var_keys(cr, bus_arcs, "real current", "branch")
    ci    = _PMD.get(_PMD.var(pmd, n),    :ci, Dict()); _PMD._check_var_keys(ci, bus_arcs, "imaginary current", "branch")
    crd   = _PMD.get(_PMD.var(pmd, n),   :crd_bus, Dict()); _PMD._check_var_keys(crd, bus_loads, "real current", "load")
    cid   = _PMD.get(_PMD.var(pmd, n),   :cid_bus, Dict()); _PMD._check_var_keys(cid, bus_loads, "imaginary current", "load")
    crg   = _PMD.get(_PMD.var(pmd, n),   :crg_bus, Dict()); _PMD._check_var_keys(crg, bus_gens, "real current", "generator")
    cig   = _PMD.get(_PMD.var(pmd, n),   :cig_bus, Dict()); _PMD._check_var_keys(cig, bus_gens, "imaginary current", "generator")
    crs   = _PMD.get(_PMD.var(pmd, n),   :crs, Dict()); _PMD._check_var_keys(crs, bus_storage, "real currentr", "storage")
    cis   = _PMD.get(_PMD.var(pmd, n),   :cis, Dict()); _PMD._check_var_keys(cis, bus_storage, "imaginary current", "storage")
    crsw  = _PMD.get(_PMD.var(pmd, n),  :crsw, Dict()); _PMD._check_var_keys(crsw, bus_arcs_sw, "real current", "switch")
    cisw  = _PMD.get(_PMD.var(pmd, n),  :cisw, Dict()); _PMD._check_var_keys(cisw, bus_arcs_sw, "imaginary current", "switch")
    crt   = _PMD.get(_PMD.var(pmd, n),   :crt, Dict()); _PMD._check_var_keys(crt, bus_arcs_trans, "real current", "transformer")
    cit   = _PMD.get(_PMD.var(pmd, n),   :cit, Dict()); _PMD._check_var_keys(cit, bus_arcs_trans, "imaginary current", "transformer")

    Gt, Bt = _PMD._build_bus_shunt_matrices(pmd, n, terminals, bus_shunts)

    # Boundary
    crbound_to    = get(var(pmitd, n),    :crbound_to, Dict()); _PMD._check_var_keys(crbound_to, bus_arcs_boundary_to, "real current", "boundary")
    cibound_to    = get(var(pmitd, n),    :cibound_to, Dict()); _PMD._check_var_keys(cibound_to, bus_arcs_boundary_to, "imaginary current", "boundary")

    ungrounded_terminals = [(idx,t) for (idx,t) in enumerate(terminals) if !grounded[idx]]

    for (idx, t) in ungrounded_terminals
        JuMP.@constraint(pmitd.model,
            sum(cr[a][t] for (a, conns) in bus_arcs if t in conns)
            + sum(crsw[a_sw][t] for (a_sw, conns) in bus_arcs_sw if t in conns)
            + sum(crt[a_trans][t] for (a_trans, conns) in bus_arcs_trans if t in conns)
            + sum(crbound_to[a_crbound_to][t] for a_crbound_to in bus_arcs_boundary_to)
            ==
                sum(crg[g][t]         for (g, conns) in bus_gens if t in conns)
            - sum(crs[s][t]         for (s, conns) in bus_storage if t in conns)
            - sum(crd[d][t]         for (d, conns) in bus_loads if t in conns)
            - sum( Gt[idx,jdx]*vr[u] -Bt[idx,jdx]*vi[u] for (jdx,u) in ungrounded_terminals) # shunts
        )

        JuMP.@constraint(pmitd.model,
            sum(ci[a][t] for (a, conns) in bus_arcs if t in conns)
            + sum(cisw[a_sw][t] for (a_sw, conns) in bus_arcs_sw if t in conns)
            + sum(cit[a_trans][t] for (a_trans, conns) in bus_arcs_trans if t in conns)
            + sum(cibound_to[a_cibound_to][t] for a_cibound_to in bus_arcs_boundary_to)
            ==
                sum(cig[g][t]         for (g, conns) in bus_gens if t in conns)
            - sum(cis[s][t]         for (s, conns) in bus_storage if t in conns)
            - sum(cid[d][t]         for (d, conns) in bus_loads if t in conns)
            - sum( Gt[idx,jdx]*vi[u] +Bt[idx,jdx]*vr[u] for (jdx,u) in ungrounded_terminals) # shunts
        )
    end
end


"""
    function constraint_boundary_voltage_magnitude(
        pm::_PM.IVRPowerModel,
        pmd::_PMD.IVRUPowerModel,
        i::Int,
        f_idx::Tuple{Int,Int,Int},
        f_connections::Vector{Int},
        t_connections::Vector{Int};
        nw::Int = nw_id_default
    )

IVR-IVRU boundary bus voltage magnitude constraints.
"""
function constraint_boundary_voltage_magnitude(pm::_PM.IVRPowerModel, pmd::_PMD.IVRUPowerModel, i::Int, f_idx::Tuple{Int,Int,Int}, f_connections::Vector{Int}, t_connections::Vector{Int}; nw::Int = nw_id_default)
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
        pm::_PM.IVRPowerModel,
        pmd::_PMD.IVRUPowerModel,
        i::Int,
        f_idx::Tuple{Int,Int,Int},
        f_connections::Vector{Int},
        t_connections::Vector{Int};
        nw::Int = nw_id_default
    )

IVR-IVRU boundary bus voltage angle constraints.
"""
function constraint_boundary_voltage_angle(pm::_PM.IVRPowerModel, pmd::_PMD.IVRUPowerModel, i::Int, f_idx::Tuple{Int,Int,Int}, f_connections::Vector{Int}, t_connections::Vector{Int}; nw::Int = nw_id_default)
    i, f_bus, t_bus = f_idx

    vi_fr = _PM.var(pm, nw, :vi, f_bus)
    vr_to = _PMD.var(pmd, nw, :vr, t_bus)
    vi_to = _PMD.var(pmd, nw, :vi, t_bus)

    # Add constraint(s): r->real, i->imaginary
    JuMP.@constraint(pm.model, vi_fr[1] == vi_to[1])

    # Add constraints related to 120 degrees offset for the distribution b and c phases
    shift_120degs_rad = deg2rad(120)

    # TODO: These are non-linear constraints due to transformation to degrees of phase a angle (another way - non-linear may be possible)
    JuMP.@constraint(pm.model, vi_to[2] == tan(atan(vi_to[1]/vr_to[1]) - shift_120degs_rad)*vr_to[2])
    JuMP.@constraint(pm.model, vi_to[3] == tan(atan(vi_to[1]/vr_to[1]) + shift_120degs_rad)*vr_to[3])
end
