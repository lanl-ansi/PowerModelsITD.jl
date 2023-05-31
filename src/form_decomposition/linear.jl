# Linear (NFA, DCP) Constraints

"""
    function constraint_transmission_power_balance(
        pm::_PM.AbstractActivePowerModel,
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

NFA transmission constraint power balance for decomposition.
"""
function constraint_transmission_power_balance(pm::_PM.AbstractActivePowerModel, n::Int, j::Int, i::Int, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_qd, bus_gs, bus_bs, bus_arcs_boundary_from)

    p    = _PM.get(_PM.var(pm, n),    :p, Dict()); _PM._check_var_keys(p, bus_arcs, "active power", "branch")
    pg   = _PM.get(_PM.var(pm, n),   :pg, Dict()); _PM._check_var_keys(pg, bus_gens, "active power", "generator")
    ps   = _PM.get(_PM.var(pm, n),   :ps, Dict()); _PM._check_var_keys(ps, bus_storage, "active power", "storage")
    psw  = _PM.get(_PM.var(pm, n),  :psw, Dict()); _PM._check_var_keys(psw, bus_arcs_sw, "active power", "switch")
    p_dc = _PM.get(_PM.var(pm, n), :p_dc, Dict()); _PM._check_var_keys(p_dc, bus_arcs_dc, "active power", "dcline")

    # Boundary
    pbound_load    = get(_PM.var(pm, n),    :pbound_load, Dict()); _PM._check_var_keys(pbound_load, bus_arcs_boundary_from, "active power", "boundary")

    cstr = JuMP.@constraint(pm.model,
        sum(p[a] for a in bus_arcs)
        + sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
        + sum(psw[a_sw] for a_sw in bus_arcs_sw)
        + sum(pbound_load[a_pbound_load][1] for a_pbound_load in bus_arcs_boundary_from)
        ==
        sum(pg[g] for g in bus_gens)
        - sum(ps[s] for s in bus_storage)
        - sum(pd for pd in values(bus_pd))
        - sum(gs for gs in values(bus_gs))*1.0^2
    )

    if _IM.report_duals(pm)
        _PM.sol(pm, n, :bus, i)[:lam_kcl_r] = cstr
        _PM.sol(pm, n, :bus, i)[:lam_kcl_i] = NaN
    end

end


"""
    function constraint_boundary_voltage_magnitude(
        pmd::_PMD.DCPUPowerModel,
        i::Int,
        f_idx::Tuple{Int,Int,Int},
        f_connections::Vector{Int},
        t_connections::Vector{Int};
        nw::Int = nw_id_default
    )

DCPU boundary bus voltage magnitude constraints: empty since DC keeps vm = 1 for all.
"""
function constraint_boundary_voltage_magnitude(pmd::_PMD.DCPUPowerModel, i::Int, t_bus::Int, f_connections::Vector{Int}, t_connections::Vector{Int}; nw::Int = nw_id_default)
end


"""
    function constraint_boundary_voltage_magnitude(
        pmd::_PMD.NFAUPowerModel,
        i::Int,
        f_idx::Tuple{Int,Int,Int},
        f_connections::Vector{Int},
        t_connections::Vector{Int};
        nw::Int = nw_id_default
    )

NFAU boundary bus voltage magnitude constraints: empty NFA.
"""
function constraint_boundary_voltage_magnitude(pmd::_PMD.NFAUPowerModel, i::Int, t_bus::Int, f_connections::Vector{Int}, t_connections::Vector{Int}; nw::Int = nw_id_default)
end


# TODO: multinetwork compatibility by using nw info.
"""
    function generate_boundary_linking_vars(
        pm::_PM.NFAPowerModel,
        pmd::_PMD.NFAUPowerModel,
        boundary_number::String;
        nw::Int = nw_id_default

    )

Generates the NFA-NFAU boundary linking vars vector to be used by the IDEC Optimizer.
"""
function generate_boundary_linking_vars(pm::_PM.NFAPowerModel, pmd::_PMD.NFAUPowerModel, boundary_number::String; nw::Int=nw_id_default)

    # Parse to Int
    boundary_number = parse(Int64, boundary_number)

    # Get boundary info.
    boundary = _PMD.ref(pmd, nw, :boundary, boundary_number)

    f_bus = boundary["f_bus"] # convention: from bus Transmission always!
    t_bus = boundary["t_bus"] # convention: to bus Distribution always!

    # Distribution: Aux vars (subproblem)
    f_idx = (boundary_number, f_bus, t_bus)
    p_aux = _PMD.var(pmd, nw, :pbound_aux, f_idx)

    # Transmission: Pload & Qload (master)
    P_load = _PM.var(pm, nw, :pbound_load, f_idx)

    boundary_linking_vars = [[P_load[1]], [p_aux[1]]]

    return boundary_linking_vars

end
