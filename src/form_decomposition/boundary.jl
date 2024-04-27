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
        pmd::_PMD.IVRUPowerModel,
        i::Int;
        nw::Int=nw_id_default
    )

Boundary power constraints for _PMD.IVRUPowerModel.
"""
function constraint_boundary_power(pmd::_PMD.IVRUPowerModel, i::Int; nw::Int=nw_id_default)

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

    JuMP.@NLconstraint(pmd.model, p_aux[1] == sum(spg[phase] for phase in boundary["t_connections"]))
    JuMP.@NLconstraint(pmd.model, q_aux[1] == sum(sqg[phase] for phase in boundary["t_connections"]))

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


"""
    function constraint_boundary_voltage_angle(
        pmd::_PMD.AbstractUnbalancedPowerModel,
        i::Int;
        nw::Int=nw_id_default
    )

General voltage angle boundary constraint.
"""
function constraint_boundary_voltage_angle(pmd::_PMD.AbstractUnbalancedPowerModel, i::Int; nw::Int=nw_id_default)

    boundary = _PMD.ref(pmd, nw, :boundary, i)
    t_bus = boundary["t_bus"] # convention: to bus Distribution always!

    constraint_boundary_voltage_angle(pmd, i, t_bus, boundary["f_connections"], boundary["t_connections"]; nw=nw)

end


"""
    function constraint_transmission_power_balance_boundary(
        pm::_PM.AbstractPowerModel,
        i::Int;
        nw_pm::Int=nw_id_default
    )

General power balance contraints for boundary buses in the transmission system-side for decomposition.
"""
function constraint_transmission_power_balance_boundary(pm::_PM.AbstractPowerModel, i::Int; nw_pm::Int=nw_id_default)

    bus_arcs = _PM.ref(pm, nw_pm, :bus_arcs, i)
    bus_arcs_dc = _PM.ref(pm, nw_pm, :bus_arcs_dc, i)
    bus_arcs_sw = _PM.ref(pm, nw_pm, :bus_arcs_sw, i)
    bus_gens = _PM.ref(pm, nw_pm, :bus_gens, i)
    bus_loads = _PM.ref(pm, nw_pm, :bus_loads, i)
    bus_shunts = _PM.ref(pm, nw_pm, :bus_shunts, i)
    bus_storage = _PM.ref(pm, nw_pm, :bus_storage, i)

    bus_pd = Dict(k => _PM.ref(pm, nw_pm, :load, k, "pd") for k in bus_loads)
    bus_qd = Dict(k => _PM.ref(pm, nw_pm, :load, k, "qd") for k in bus_loads)

    bus_gs = Dict(k => _PM.ref(pm, nw_pm, :shunt, k, "gs") for k in bus_shunts)
    bus_bs = Dict(k => _PM.ref(pm, nw_pm, :shunt, k, "bs") for k in bus_shunts)

    bus_arcs_boundary_from = _PM.ref(pm, nw_pm, :bus_arcs_boundary_from, i)
    constraint_transmission_power_balance(pm, nw_pm, i, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_qd, bus_gs, bus_bs, bus_arcs_boundary_from)

end



"""
    function constraint_transmission_current_balance_boundary(
        pm::_PM.AbstractIVRModel,
        i::Int;
        nw_pm::Int=nw_id_default
    )

General current balance contraints for boundary buses in the transmission system-side for decomposition.
"""
function constraint_transmission_current_balance_boundary(pm::_PM.AbstractIVRModel, i::Int; nw_pm::Int=nw_id_default)

    if !haskey(_PM.con(pm, nw_pm), :kcl_cr)
        _PM.con(pm, nw_pm)[:kcl_cr] = Dict{Int,JuMP.ConstraintRef}()
    end
    if !haskey(_PM.con(pm, nw_pm), :kcl_ci)
        _PM.con(pm, nw_pm)[:kcl_ci] = Dict{Int,JuMP.ConstraintRef}()
    end

    bus_arcs = _PM.ref(pm, nw_pm, :bus_arcs, i)
    bus_arcs_dc = _PM.ref(pm, nw_pm, :bus_arcs_dc, i)
    bus_gens = _PM.ref(pm, nw_pm, :bus_gens, i)
    bus_loads = _PM.ref(pm, nw_pm, :bus_loads, i)
    bus_shunts = _PM.ref(pm, nw_pm, :bus_shunts, i)

    bus_pd = Dict(k => _PM.ref(pm, nw_pm, :load, k, "pd") for k in bus_loads)
    bus_qd = Dict(k => _PM.ref(pm, nw_pm, :load, k, "qd") for k in bus_loads)

    bus_gs = Dict(k => _PM.ref(pm, nw_pm, :shunt, k, "gs") for k in bus_shunts)
    bus_bs = Dict(k => _PM.ref(pm, nw_pm, :shunt, k, "bs") for k in bus_shunts)

    bus_arcs_boundary_from = _PM.ref(pm, nw_pm, :bus_arcs_boundary_from, i)
    constraint_transmission_current_balance(pm, nw_pm, i, bus_arcs, bus_arcs_dc, bus_gens, bus_pd, bus_qd, bus_gs, bus_bs, bus_arcs_boundary_from)

end
