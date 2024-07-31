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

Generates the NFA-NFAU boundary linking vars vector to be used by the StsDOpt Optimizer.
The parameter `export_models` is a boolean that determines if the JuMP models' shared variable indices are exported to the pwd as .txt files.
"""
function generate_boundary_linking_vars(pm::_PM.NFAPowerModel, pmd::_PMD.NFAUPowerModel, boundary_number::String; nw::Int=nw_id_default, export_models::Bool=false)

   transmission_linking_vars = generate_boundary_linking_vars_transmission(pm, boundary_number; nw=nw, export_models=export_models)
   distribution_linking_vars = generate_boundary_linking_vars_distribution(pmd, boundary_number; nw=nw, export_models=export_models)

   boundary_linking_vars = [transmission_linking_vars[1], distribution_linking_vars[1]] # use 1 to extract the vector of linking vars - TODO: see if [1] can be removed maintaining compat.

   return boundary_linking_vars

end


"""
    function generate_boundary_linking_vars_transmission(
        pm::_PM.NFAPowerModel,
        boundary_number::String;
        nw::Int = nw_id_default,
        export_models::Bool=false
    )

Generates the NFA boundary linking vars vector to be used by the StsDOpt Optimizer.
The parameter `export_models` is a boolean that determines if the JuMP models' shared variable indices are exported to the pwd as .txt files.
"""
function generate_boundary_linking_vars_transmission(pm::_PM.NFAPowerModel, boundary_number::String; nw::Int=nw_id_default, export_models::Bool=false)

    # Parse to Int
    boundary_number = parse(Int64, boundary_number)

    # Get boundary info.
    boundary = _PM.ref(pm, nw, :boundary, boundary_number)

    f_bus = boundary["f_bus"] # convention: from bus Transmission always!
    t_bus = boundary["t_bus"] # convention: to bus Distribution always!
    f_idx = (boundary_number, f_bus, t_bus)

    # Transmission: Pload & Qload (master)
    P_load = _PM.var(pm, nw, :pbound_load_scaled, f_idx)

    boundary_linking_vars = [[P_load[1]]]

    if (export_models == true)
        # Open file where shared vars indices are going to be written
        file = open("shared_vars_transmission.txt", "a")
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


"""
    function generate_boundary_linking_vars_distribution(
        pmd::_PMD.NFAUPowerModel,
        boundary_number::String;
        nw::Int = nw_id_default,
        export_models::Bool=false
    )

Generates the NFAU boundary linking vars vector to be used by the StsDOpt Optimizer.
The parameter `export_models` is a boolean that determines if the JuMP models' shared variable indices are exported to the pwd as .txt files.
"""
function generate_boundary_linking_vars_distribution(pmd::_PMD.NFAUPowerModel, boundary_number::String; nw::Int=nw_id_default, export_models::Bool=false)

    # Parse to Int
    boundary_number = parse(Int64, boundary_number)

    # Get boundary info.
    boundary = _PMD.ref(pmd, nw, :boundary, boundary_number)

    f_bus = boundary["f_bus"] # convention: from bus Transmission always!
    t_bus = boundary["t_bus"] # convention: to bus Distribution always!
    f_idx = (boundary_number, f_bus, t_bus)

    # Distribution: Aux vars (subproblem)
    p_aux = _PMD.var(pmd, nw, :pbound_aux, f_idx)

    boundary_linking_vars = [[p_aux[1]]]

    if (export_models == true)
        # Open file where shared vars indices are going to be written
        file = open("shared_vars_distribution_$(boundary_number).txt", "a")
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
