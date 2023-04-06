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


# TODO: multinetwork compatibility by using nw info.
"""
    function generate_boundary_linking_vars(
        pm::_PM.AbstractBFAModel,
        pmd::_PMD.LPUBFDiagPowerModel,
        boundary_number::String;
        nw::Int = nw_id_default

    )

Generates the BFA-LPUBFDiagPowerModel boundary linking vars vector to be used by the IDEC Optimizer.
"""
function generate_boundary_linking_vars(pm::_PM.AbstractBFAModel, pmd::_PMD.LPUBFDiagPowerModel, boundary_number::String; nw::Int=nw_id_default)

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

    # Distribution: w (subproblem)
    w = _PMD.var(pmd, nw, :w, t_bus)

    # Transmission: W (master)
    W = _PM.var(pm, nw, :w, f_bus)

    # Transmission: Pload & Qload (master)
    P_load = _PM.var(pm, nw, :pbound_load, f_idx)
    Q_load = _PM.var(pm, nw, :qbound_load, f_idx)

    boundary_linking_vars = [[P_load[1], Q_load[1], W], [p_aux[1], q_aux[1], w[1]]]

    return boundary_linking_vars

end
