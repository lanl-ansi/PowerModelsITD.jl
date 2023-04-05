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
