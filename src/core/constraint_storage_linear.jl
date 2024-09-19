"""
    constraint_storage_losses_linear(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)

Template function for storage loss constraints for linear model - transmission.
"""
function constraint_storage_losses_linear(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    storage = _PM.ref(pm, nw, :storage, i)

    # force storage model to be linear
    storage["r"] = 0.0
    storage["x"] = 0.0

    _PM.constraint_storage_losses(pm, nw, i, storage["storage_bus"], storage["r"], storage["x"], storage["p_loss"], storage["q_loss"])
end


"""
    constraint_mc_storage_losses_linear(pm::_PMD.AbstractUnbalancedPowerModel, i::Int; nw::Int=_PMD.nw_id_default)::Nothing

Template function for storage loss constraints for linear model - distribution.
"""
function constraint_mc_storage_losses_linear(pmd::_PMD.AbstractUnbalancedPowerModel, i::Int; nw::Int=_PMD.nw_id_default)::Nothing
    storage = _PMD.ref(pmd, nw, :storage, i)

    # force storage model to be linear in nonlinear formulations
    storage["r"] = 0.0
    storage["x"] = 0.0

    _PMD.constraint_mc_storage_losses(pmd, nw, i, storage["storage_bus"], storage["connections"], storage["r"], storage["x"], storage["p_loss"], storage["q_loss"])
    nothing
end


""
function constraint_mc_storage_losses_linear(pmd::_PMD.AbstractUBFModels, i::Int; nw::Int=_PMD.nw_id_default)::Nothing
    _PMD.constraint_mc_storage_losses(pmd, i; nw=nw)
    nothing
end
