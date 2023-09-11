# FOTR Constraints & Boundary Linking Vars.

"""
    function constraint_boundary_voltage_magnitude(
        pmd::_PMD.FBSUBFPowerModel,
        i::Int,
        f_idx::Tuple{Int,Int,Int},
        f_connections::Vector{Int},
        t_connections::Vector{Int};
        nw::Int = nw_id_default
    )

FBSUBF boundary bus voltage magnitude constraints.
"""
function constraint_boundary_voltage_magnitude(pmd::_PMD.FBSUBFPowerModel, ::Int, t_bus::Int, ::Vector{Int}, ::Vector{Int}; nw::Int=nw_id_default)

    vr_source = _PMD.var(pmd, nw, :vr, t_bus)
    vi_source = _PMD.var(pmd, nw, :vi, t_bus)

    # Add constraint(s): r->real, i->imaginary
    JuMP.@constraint(pmd.model, vr_source[1]^2+vi_source[1]^2 == vr_source[2]^2+vi_source[2]^2)
    JuMP.@constraint(pmd.model, vr_source[1]^2+vi_source[1]^2 == vr_source[3]^2+vi_source[3]^2)

end

# TODO: multinetwork compatibility by using nw info.
"""
    function generate_boundary_linking_vars(
        pm::_PM.ACRPowerModel,
        pmd::_PMD.FBSUBFPowerModel,
        boundary_number::String;
        nw::Int = nw_id_default

    )

Generates the ACR-FBSUBF boundary linking vars vector to be used by the IDEC Optimizer.
"""
function generate_boundary_linking_vars(pm::_PM.ACRPowerModel, pmd::_PMD.FBSUBFPowerModel, boundary_number::String; nw::Int=nw_id_default)

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

    # Distribution: vr and vi (subproblem)
    vr = _PMD.var(pmd, nw, :vr, t_bus)
    vi = _PMD.var(pmd, nw, :vi, t_bus)

    # Transmission: Vr and Vi (master)
    Vr = _PM.var(pm, nw, :vr, f_bus)
    Vi = _PM.var(pm, nw, :vi, f_bus)

    # Transmission: Pload & Qload (master)
    P_load = _PM.var(pm, nw, :pbound_load, f_idx)
    Q_load = _PM.var(pm, nw, :qbound_load, f_idx)

    boundary_linking_vars = [[P_load[1], Q_load[1], Vr, Vi], [p_aux[1], q_aux[1], vr[1], vi[1]]]

    return boundary_linking_vars

end
