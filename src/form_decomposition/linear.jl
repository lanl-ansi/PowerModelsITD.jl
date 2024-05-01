# Linear (NFA, DCP) Constraints

"""
    function constraint_transmission_power_balance(
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

NFA transmission constraint power balance for decomposition.
"""
function constraint_transmission_power_balance(pm::_PM.AbstractActivePowerModel, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_qd, bus_gs, bus_bs, bus_arcs_boundary_from)

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


function constraint_distribution_power_balance(pmd::_PMD.AbstractUnbalancedActivePowerModel, n::Int, i::Int, terminals::Vector{Int}, grounded::Vector{Bool}, bus_arcs::Vector{Tuple{Tuple{Int,Int,Int},Vector{Int}}}, bus_arcs_sw::Vector{Tuple{Tuple{Int,Int,Int},Vector{Int}}}, bus_arcs_trans::Vector{Tuple{Tuple{Int,Int,Int},Vector{Int}}}, bus_gens::Vector{Tuple{Int,Vector{Int}}}, bus_storage::Vector{Tuple{Int,Vector{Int}}}, bus_loads::Vector{Tuple{Int,Vector{Int}}}, bus_shunts::Vector{Tuple{Int,Vector{Int}}}, bus_arcs_boundary_to)

    p    = _PMD.get(_PMD.var(pmd, n),    :p, Dict())#; _PMD._check_var_keys(p, bus_arcs, "active power", "branch")
    pg   = _PMD.get(_PMD.var(pmd, n),   :pg_bus, Dict())#; _PMD._check_var_keys(pg, bus_gens, "active power", "generator")
    ps   = _PMD.get(_PMD.var(pmd, n),   :ps, Dict())#; _PMD._check_var_keys(ps, bus_storage, "active power", "storage")
    psw  = _PMD.get(_PMD.var(pmd, n),  :psw, Dict())#; _PMD._check_var_keys(psw, bus_arcs_sw, "active power", "switch")
    pt   = _PMD.get(_PMD.var(pmd, n),   :pt, Dict())#; _PMD._check_var_keys(pt, bus_arcs_trans, "active power", "transformer")
    pd   = _PMD.get(_PMD.var(pmd, n),   :pd_bus, Dict())#; _PMD._check_var_keys(pg, bus_gens, "active power", "generator")

    # Boundary
    pbound_aux_phases    = get(_PMD.var(pmd, n),    :pbound_aux_phases, Dict()); _PMD._check_var_keys(pbound_aux_phases, bus_arcs_boundary_to, "active power", "boundary")

    Gt, Bt = _PMD._build_bus_shunt_matrices(pmd, n, terminals, bus_shunts)

    cstr_p = []

    ungrounded_terminals = [(idx,t) for (idx,t) in enumerate(terminals) if !grounded[idx]]

    for (idx,t) in ungrounded_terminals
        cp = JuMP.@constraint(pmd.model,
              sum(p[a][t] for (a, conns) in bus_arcs if t in conns)
            + sum(psw[a_sw][t] for (a_sw, conns) in bus_arcs_sw if t in conns)
            + sum(pt[a_trans][t] for (a_trans, conns) in bus_arcs_trans if t in conns)
            - sum( pbound_aux_phases[a_pbound_aux][t] for a_pbound_aux in bus_arcs_boundary_to)
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

    if _IM.report_duals(pmd)
        sol(pmd, n, :bus, i)[:lam_kcl_r] = cstr_p
        sol(pmd, n, :bus, i)[:lam_kcl_i] = []
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


"""
    function constraint_boundary_voltage_angle(
        pmd::_PMD.NFAUPowerModel,
        i::Int,
        f_idx::Tuple{Int,Int,Int},
        f_connections::Vector{Int},
        t_connections::Vector{Int};
        nw::Int = nw_id_default
    )

NFAUPowerModel boundary bus voltage angle constraints.
"""
function constraint_boundary_voltage_angle(pmd::_PMD.NFAUPowerModel, ::Int, t_bus::Int, ::Vector{Int}, ::Vector{Int}; nw::Int=nw_id_default)
end


"""
    function constraint_transmission_boundary_power_shared_vars_scaled(
        pm::_PM.NFAPowerModel,
        i::Int;
        nw::Int = nw_id_default
    )

NFAU power shared variables scaling constraints.
"""
function constraint_transmission_boundary_power_shared_vars_scaled(pm::_PM.NFAPowerModel, i::Int; nw::Int=nw_id_default)

    boundary = _PM.ref(pm, nw, :boundary, i)
    f_bus = boundary["f_bus"] # convention: from bus Transmission always!
    t_bus = boundary["t_bus"] # convention: to bus Distribution always!

    # Pbound_load vars
    f_idx = (i, f_bus, t_bus)
    pbound_load = _PM.var(pm, nw, :pbound_load, f_idx)

    pbound_load_scaled = _PM.var(pm, nw, :pbound_load_scaled, f_idx)

    # Get the base power conversion factor for T&D boundary connection
    base_conv_factor = boundary["base_conv_factor"]

    # Add scaling constraint
    JuMP.@constraint(pm.model, pbound_load_scaled[1] == pbound_load[1]*(base_conv_factor))

end



# TODO: multinetwork compatibility by using nw info.
"""
    function generate_boundary_linking_vars(
        pm::_PM.NFAPowerModel,
        pmd::_PMD.NFAUPowerModel,
        boundary_number::String;
        nw::Int = nw_id_default,
        export_models::Bool=false
    )

Generates the NFA-NFAU boundary linking vars vector to be used by the IDEC Optimizer.
The parameter `export_models` is a boolean that determines if the JuMP models' shared variable indices are exported to the pwd as `.nl` files.
"""
function generate_boundary_linking_vars(pm::_PM.NFAPowerModel, pmd::_PMD.NFAUPowerModel, boundary_number::String; nw::Int=nw_id_default, export_models::Bool=false)

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
    P_load = _PM.var(pm, nw, :pbound_load_scaled, f_idx)

    boundary_linking_vars = [[P_load[1]], [p_aux[1]]]

    if (export_models == true)
        # Open file where shared vars indices are going to be written
        file = open("shared_vars.txt", "a")
        # Loop through the vector of shared variables
        for sh_vect in boundary_linking_vars
            for sh_var in sh_vect
                str_to_write = "Shared Variable ($(sh_var)) Index: $(sh_var.index)\n"
                # Write the string to the file
                write(file, str_to_write)
            end
        end
        # Close the file
        close(file)
    end

    return boundary_linking_vars

end
