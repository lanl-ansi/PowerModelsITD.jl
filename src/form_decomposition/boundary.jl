# Boundary Constraints Decomposition

"""
    function constraint_boundary_power(
        pmd::_PMD.AbstractUnbalancedPowerModel,
        i::Int;
        nw::Int=nw_id_default
    )

Boundary power constraints for _PMD.AbstractUnbalancedPowerModel.
"""
function constraint_boundary_power(pmd::_PMD.AbstractUnbalancedPowerModel, i::Int; nw::Int=nw_id_default)

    boundary = _PMD.ref(pmd, nw, :boundary, i)
    f_bus = boundary["f_bus"] # convention: from bus Transmission always!
    t_bus = boundary["t_bus"] # convention: to bus Distribution always!

    # Aux vars
    f_idx = (i, f_bus, t_bus)
    p_aux = _PMD.var(pmd, nw, :pbound_aux, f_idx)
    q_aux = _PMD.var(pmd, nw, :qbound_aux, f_idx)

    # Get pg vars from slack gen
    slack_gen_data = Dict(x for x in _PMD.ref(pmd, nw, :gen) if x.second["gen_bus"] == t_bus)
    slack_gen_keys = collect(keys(slack_gen_data))
    slack_gen_number = slack_gen_keys[1]
    spg = _PMD.var(pmd, nw, :pg, slack_gen_number)
    sqg = _PMD.var(pmd, nw, :qg, slack_gen_number)

    JuMP.@constraint(pmd.model, p_aux[1] == sum(spg[phase] for phase in boundary["t_connections"]))
    JuMP.@constraint(pmd.model, q_aux[1] == sum(sqg[phase] for phase in boundary["t_connections"]))

end


"""
    function constraint_boundary_power(
        pmd::_PMD.AbstractUnbalancedNFAModel,
        i::Int;
        nw::Int=nw_id_default
    )

Boundary power constraints for _PMD.AbstractUnbalancedNFAModel (NFA versions - Active P only).
"""
function constraint_boundary_power(pmd::_PMD.AbstractUnbalancedNFAModel, i::Int; nw::Int=nw_id_default)

    boundary = _PMD.ref(pmd, nw, :boundary, i)
    f_bus = boundary["f_bus"] # convention: from bus Transmission always!
    t_bus = boundary["t_bus"] # convention: to bus Distribution always!

    # Aux vars
    f_idx = (i, f_bus, t_bus)
    p_aux = _PMD.var(pmd, nw, :pbound_aux, f_idx)

    # Get pg vars from slack gen
    slack_gen_data = Dict(x for x in _PMD.ref(pmd, nw, :gen) if x.second["gen_bus"] == t_bus)
    slack_gen_keys = collect(keys(slack_gen_data))
    slack_gen_number = slack_gen_keys[1]
    spg = _PMD.var(pmd, nw, :pg, slack_gen_number)

    JuMP.@constraint(pmd.model, p_aux[1] == sum(spg[phase] for phase in boundary["t_connections"]))

end


"""
    function constraint_boundary_voltage_magnitude(
        pmd::_PMD.AbstractUnbalancedPowerModel,
        i::Int;
        nw::Int=nw_id_default
    )

General voltage magnitude boundary constraint.
"""
function constraint_boundary_voltage_magnitude(pmd::_PMD.AbstractUnbalancedPowerModel, i::Int; nw::Int=nw_id_default)

    boundary = _PMD.ref(pmd, nw, :boundary, i)
    t_bus = boundary["t_bus"] # convention: to bus Distribution always!

    constraint_boundary_voltage_magnitude(pmd, i, t_bus, boundary["f_connections"], boundary["t_connections"]; nw=nw)

end
