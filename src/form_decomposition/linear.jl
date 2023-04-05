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
