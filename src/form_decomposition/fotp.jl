# FOTP Constraints & Boundary Linking Vars.

"""
    function constraint_boundary_voltage_magnitude(
        pmd::_PMD.FOTPUPowerModel,
        i::Int,
        f_idx::Tuple{Int,Int,Int},
        f_connections::Vector{Int},
        t_connections::Vector{Int};
        nw::Int = nw_id_default
    )

FOTPU boundary bus voltage magnitude constraints.
"""
function constraint_boundary_voltage_magnitude(pmd::_PMD.FOTPUPowerModel, ::Int, t_bus::Int, ::Vector{Int}, ::Vector{Int}; nw::Int=nw_id_default)

    vm_source = _PMD.var(pmd, nw, :vm, t_bus)

    # Add constraint(s): m->magnitude
    JuMP.@constraint(pmd.model, vm_source[1] == vm_source[2])
    JuMP.@constraint(pmd.model, vm_source[1] == vm_source[3])

end


"""
    function constraint_boundary_voltage_angle(
        pmd::_PMD.FOTPUPowerModel,
        i::Int,
        f_idx::Tuple{Int,Int,Int},
        f_connections::Vector{Int},
        t_connections::Vector{Int};
        nw::Int = nw_id_default
    )

FOTPU boundary bus voltage angle constraints.
"""
function constraint_boundary_voltage_angle(pmd::_PMD.FOTPUPowerModel, ::Int, t_bus::Int, ::Vector{Int}, ::Vector{Int}; nw::Int=nw_id_default)

    ## --- NOTE: These constraints seem to make ACP-FOTPU decomposition formulation harder to solve
    ## if the  _PMD.constraint_mc_theta_ref(pmd_model, i) is kept ---

    # --- Either this constraint ---
    # _PMD.constraint_mc_theta_ref(pmd, t_bus)

    # --- Or these constraints ---.

    va_source = _PMD.var(pmd, nw, :va, t_bus)
    # Add constraint(s): angles
    # JuMP.@constraint(pmd.model, va_source[1] == 0.0)
    # Add constraints related to 120 degrees offset for the distribution b and c phases
    shift_120degs_rad = deg2rad(120)
    # Offset constraints for other phases (-+120 degrees)
    JuMP.@constraint(pmd.model, va_source[2] == (va_source[1] - shift_120degs_rad))
    JuMP.@constraint(pmd.model, va_source[3] == (va_source[1] + shift_120degs_rad))

end



# TODO: multinetwork compatibility by using nw info.
"""
    function generate_boundary_linking_vars(
        pm::_PM.ACPPowerModel,
        pmd::_PMD.FOTPUPowerModel,
        boundary_number::String;
        nw::Int = nw_id_default

    )

Generates the ACP-FOTPU boundary linking vars vector to be used by the IDEC Optimizer.
The parameter `export_models` is a boolean that determines if the JuMP models' shared variable indices are exported to the pwd as `.nl` files.
"""
function generate_boundary_linking_vars(pm::_PM.ACPPowerModel, pmd::_PMD.FOTPUPowerModel, boundary_number::String; nw::Int=nw_id_default, export_models::Bool=false)

    # Parse to Int
    boundary_number = parse(Int64, boundary_number)

    # Get boundary info.
    boundary = _PMD.ref(pmd, nw, :boundary, boundary_number)

    f_bus = boundary["f_bus"] # convention: from bus Transmission always!
    t_bus = boundary["t_bus"] # convention: to bus Distribution always!

    # Distribution: Aux vars (subproblem)
    f_idx = (boundary_number, f_bus, t_bus)
    p_aux = _PMD.var(pmd, nw, :pbound_aux, f_idx)
    q_aux = _PMD.var(pmd, nw, :qbound_aux, f_idx)

    # Distribution: vm (subproblem)
    vm = _PMD.var(pmd, nw, :vm, t_bus)
    va = _PMD.var(pmd, nw, :va, t_bus)

    # Transmission: Vm (master)
    Vm = _PM.var(pm, nw, :vm, f_bus)
    Va = _PM.var(pm, nw, :va, f_bus)

    # Transmission: Pload & Qload (master)
    P_load = _PM.var(pm, nw, :pbound_load_scaled, f_idx)
    Q_load = _PM.var(pm, nw, :qbound_load_scaled, f_idx)

    # boundary_linking_vars = [[P_load[1], Q_load[1], Vm], [p_aux[1], q_aux[1], vm[1]]]
    boundary_linking_vars = [[P_load[1], Q_load[1], Vm, Va], [p_aux[1], q_aux[1], vm[1], va[1]]]

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
