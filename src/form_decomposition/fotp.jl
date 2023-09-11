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

# TODO: multinetwork compatibility by using nw info.
"""
    function generate_boundary_linking_vars(
        pm::_PM.ACPPowerModel,
        pmd::_PMD.FOTPUPowerModel,
        boundary_number::String;
        nw::Int = nw_id_default

    )

Generates the ACP-FOTPU boundary linking vars vector to be used by the IDEC Optimizer.
"""
function generate_boundary_linking_vars(pm::_PM.ACPPowerModel, pmd::_PMD.FOTPUPowerModel, boundary_number::String; nw::Int=nw_id_default)

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

    # Transmission: Vm (master)
    Vm = _PM.var(pm, nw, :vm, f_bus)

    # Transmission: Pload & Qload (master)
    P_load = _PM.var(pm, nw, :pbound_load, f_idx)
    Q_load = _PM.var(pm, nw, :qbound_load, f_idx)

    boundary_linking_vars = [[P_load[1], Q_load[1], Vm], [p_aux[1], q_aux[1], vm[1]]]

    return boundary_linking_vars

end
