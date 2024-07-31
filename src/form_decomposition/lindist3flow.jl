"""
    function constraint_boundary_voltage_magnitude(
        pmd::_PMD.LPUBFDiagPowerModel,
        i::Int,
        f_idx::Tuple{Int,Int,Int},
        f_connections::Vector{Int},
        t_connections::Vector{Int};
        nw::Int=nw_id_default
    )

LinDist3FlowPowerModel boundary bus voltage magnitude constraints.
"""
function constraint_boundary_voltage_magnitude(pmd::_PMD.LPUBFDiagPowerModel, i::Int, t_bus::Int, f_connections::Vector{Int}, t_connections::Vector{Int}; nw::Int=nw_id_default)

    w_source = _PMD.var(pmd, nw, :w, t_bus)

    # Add constraint(s): m->magnitude
    JuMP.@constraint(pmd.model, w_source[1] == w_source[2])
    JuMP.@constraint(pmd.model, w_source[1] == w_source[3])

end



"""
    function constraint_boundary_voltage_angle(
        pmd::_PMD.LPUBFDiagPowerModel,
        i::Int,
        f_idx::Tuple{Int,Int,Int},
        f_connections::Vector{Int},
        t_connections::Vector{Int};
        nw::Int = nw_id_default
    )

LinDist3FlowPowerModel boundary bus voltage angle constraints.
"""
function constraint_boundary_voltage_angle(pmd::_PMD.LPUBFDiagPowerModel, ::Int, t_bus::Int, ::Vector{Int}, ::Vector{Int}; nw::Int=nw_id_default)
end



"""
    function constraint_transmission_boundary_power_shared_vars_scaled(
        pm::_PM.AbstractBFAModel,
        i::Int;
        nw::Int = nw_id_default
    )

BFA power shared variables scaling constraints.
"""
function constraint_transmission_boundary_power_shared_vars_scaled(pm::_PM.AbstractBFAModel, i::Int; nw::Int=nw_id_default)

    boundary = _PM.ref(pm, nw, :boundary, i)
    f_bus = boundary["f_bus"] # convention: from bus Transmission always!
    t_bus = boundary["t_bus"] # convention: to bus Distribution always!

    # Pbound_load vars
    f_idx = (i, f_bus, t_bus)
    pbound_load = _PM.var(pm, nw, :pbound_load, f_idx)
    qbound_load = _PM.var(pm, nw, :qbound_load, f_idx)

    pbound_load_scaled = _PM.var(pm, nw, :pbound_load_scaled, f_idx)
    qbound_load_scaled = _PM.var(pm, nw, :qbound_load_scaled, f_idx)

    # Get the base power conversion factor for T&D boundary connection
    base_conv_factor = boundary["base_conv_factor"]

    # Add scaling constraint
    JuMP.@constraint(pm.model, pbound_load_scaled[1] == pbound_load[1]*(base_conv_factor))
    JuMP.@constraint(pm.model, qbound_load_scaled[1] == qbound_load[1]*(base_conv_factor))

end


# TODO: multinetwork compatibility by using nw info.
"""
    function generate_boundary_linking_vars(
        pm::_PM.AbstractBFAModel,
        pmd::_PMD.LPUBFDiagPowerModel,
        boundary_number::String;
        nw::Int = nw_id_default,
        export_models::Bool=false
    )

Generates the BFA-LinDistFlow boundary linking vars vector to be used by the StsDOpt Optimizer.
The parameter `export_models` is a boolean that determines if the JuMP models' shared variable indices are exported to the pwd as .txt files.
"""
function generate_boundary_linking_vars(pm::_PM.AbstractBFAModel, pmd::_PMD.LPUBFDiagPowerModel, boundary_number::String; nw::Int=nw_id_default, export_models::Bool=false)

   transmission_linking_vars = generate_boundary_linking_vars_transmission(pm, boundary_number; nw=nw, export_models=export_models)
   distribution_linking_vars = generate_boundary_linking_vars_distribution(pmd, boundary_number; nw=nw, export_models=export_models)

   boundary_linking_vars = [transmission_linking_vars[1], distribution_linking_vars[1]] # use 1 to extract the vector of linking vars - TODO: see if [1] can be removed maintaining compat.

   return boundary_linking_vars

end


"""
    function generate_boundary_linking_vars_transmission(
        pm::_PM.AbstractBFAModel,
        boundary_number::String;
        nw::Int = nw_id_default,
        export_models::Bool=false
    )

Generates the BFA boundary linking vars vector to be used by the StsDOpt Optimizer.
The parameter `export_models` is a boolean that determines if the JuMP models' shared variable indices are exported to the pwd as .txt files.
"""
function generate_boundary_linking_vars_transmission(pm::_PM.AbstractBFAModel, boundary_number::String; nw::Int=nw_id_default, export_models::Bool=false)

    # Parse to Int
    boundary_number = parse(Int64, boundary_number)

    # Get boundary info.
    boundary = _PM.ref(pm, nw, :boundary, boundary_number)

    f_bus = boundary["f_bus"] # convention: from bus Transmission always!
    t_bus = boundary["t_bus"] # convention: to bus Distribution always!
    f_idx = (boundary_number, f_bus, t_bus)

    # Transmission: W (master)
    W = _PM.var(pm, nw, :w, f_bus)

    # Transmission: Pload & Qload (master)
    P_load = _PM.var(pm, nw, :pbound_load_scaled, f_idx)
    Q_load = _PM.var(pm, nw, :qbound_load_scaled, f_idx)

    boundary_linking_vars = [[P_load[1], Q_load[1], W]]

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
        pmd::_PMD.LPUBFDiagPowerModel,
        boundary_number::String;
        nw::Int = nw_id_default,
        export_models::Bool=false
    )

Generates the LinDistFlow boundary linking vars vector to be used by the StsDOpt Optimizer.
The parameter `export_models` is a boolean that determines if the JuMP models' shared variable indices are exported to the pwd as .txt files.
"""
function generate_boundary_linking_vars_distribution(pmd::_PMD.LPUBFDiagPowerModel, boundary_number::String; nw::Int=nw_id_default, export_models::Bool=false)

    # Parse to Int
    boundary_number = parse(Int64, boundary_number)

    # Get boundary info.
    boundary = _PMD.ref(pmd, nw, :boundary, boundary_number)

    f_bus = boundary["f_bus"] # convention: from bus Transmission always!
    t_bus = boundary["t_bus"] # convention: to bus Distribution always!
    f_idx = (boundary_number, f_bus, t_bus)

    # Distribution: Aux vars (subproblem)
    p_aux = _PMD.var(pmd, nw, :pbound_aux, f_idx)
    q_aux = _PMD.var(pmd, nw, :qbound_aux, f_idx)

    # Distribution: w (subproblem)
    w = _PMD.var(pmd, nw, :w, t_bus)

    boundary_linking_vars = [[p_aux[1], q_aux[1], w[1]]]

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
