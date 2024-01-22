"""
    function objective_itd_min_fuel_distribution_load_setpoint_delta(
        pmitd::AbstractPowerModelITD
    )

Standard fuel cost minimization for transmission and minimum load delta objective with storage for distribution objective.
"""
function objective_itd_min_fuel_distribution_load_setpoint_delta(pmitd::AbstractPowerModelITD)

    # Extract the transmission model
    pm_model = _get_powermodel_from_powermodelitd(pmitd)

    # Extract the distribution model
    pmd_model = _get_powermodeldistribution_from_powermodelitd(pmitd)

    # PM cost models
    pm_cost_model = _check_cost_models(pm_model)

    # PMD cost models
    pmd_cost_model = _PMD.check_gen_cost_models(pmd_model)

    if pm_cost_model == 1
        return objective_itd_min_fuel_pwl_distribution_load_setpoint_delta(pmitd, pm_model, pmd_model)
    elseif pm_cost_model == 2
        return objective_itd_min_fuel_polynomial_distribution_load_setpoint_delta(pmitd, pm_model, pmd_model)
    else
        @error "Only cost models of types 1 and 2 are supported at this time, given cost model type of $(pm_cost_model) and $(pmd_cost_model)"
    end

end


"""
    function objective_itd_min_fuel_pwl_distribution_load_setpoint_delta(
        pmitd::AbstractPowerModelITD,
        pm::_PM.AbstractPowerModel,
        pmd::_PMD.AbstractUnbalancedPowerModel
    )

Fuel cost minimization objective with piecewise linear terms in transmission and load setpoint delta for distribution.
"""
function objective_itd_min_fuel_pwl_distribution_load_setpoint_delta(pmitd::AbstractPowerModelITD, pm::_PM.AbstractPowerModel, pmd::_PMD.AbstractUnbalancedPowerModel)

    # PM-section part
    _objective_variable_pg_cost(pm)
    _objective_variable_dc_cost(pm)

    # PMD-section part
    for (n, nw_ref) in _PMD.nws(pmd)
        _PMD.var(pmd, n)[:delta_pg] = Dict(i => JuMP.@variable(pmd.model,
                [c in _PMD.ref(pmd, n, :gen, i)["connections"]], base_name="$(n)_$(i)_delta_pg",
                start = 0.0) for i in _PMD.ids(pmd, n, :gen))

        _PMD.var(pmd, n)[:delta_ps] = Dict(i => JuMP.@variable(pmd.model,
                [c in _PMD.ref(pmd, n, :storage, i)["connections"]], base_name="$(n)_$(i)_delta_ps",
                start = 0.0) for i in _PMD.ids(pmd, n, :storage))

        for (i, gen) in nw_ref[:gen]
            for (idx, c) in enumerate(gen["connections"])
                JuMP.@constraint(pmd.model, _PMD.var(pmd, n, :delta_pg, i)[c] >=  (gen["pg"][idx] - _PMD.var(pmd, n, :pg, i)[c]))
                JuMP.@constraint(pmd.model, _PMD.var(pmd, n, :delta_pg, i)[c] >= -(gen["pg"][idx] - _PMD.var(pmd, n, :pg, i)[c]))
            end
        end

        for (i, strg) in nw_ref[:storage]
            for (idx, c) in enumerate(strg["connections"])
                JuMP.@constraint(pmd.model, _PMD.var(pmd, n, :delta_ps, i)[c] >=  (strg["ps"][idx] - _PMD.var(pmd, n, :ps, i)[c]))
                JuMP.@constraint(pmd.model, _PMD.var(pmd, n, :delta_ps, i)[c] >= -(strg["ps"][idx] - _PMD.var(pmd, n, :ps, i)[c]))
            end
        end
    end

    w = Dict(n => Dict(i => 10*get(load, "weight", 1.0) for (i,load) in _PMD.ref(pmd, n, :load)) for n in _PMD.nw_ids(pmd))

    # ITD (Combined objective)
    return JuMP.@objective(pmitd.model, Min,
        sum(
            sum( _PM.var(pm, n,   :pg_cost, i) for (i,gen) in nw_ref[:gen]) +
            sum( _PM.var(pm, n, :p_dc_cost, i) for (i,dcline) in nw_ref[:dcline])
        for (n, nw_ref) in _PM.nws(pm))
        + sum(
            sum(                      10*(1 - _PMD.var(pmd, n, :z_voltage, i)) for (i,bus) in nw_ref[:bus]) +
            sum( w[n][i]*sum(load["pd"])*(1 - _PMD.var(pmd, n, :z_demand, i)) for (i,load) in nw_ref[:load]) +
            sum(        sum(shunt["gs"])*(1 - _PMD.var(pmd, n, :z_shunt, i)) for (i,shunt) in nw_ref[:shunt]) +
            sum( sum(                         _PMD.var(pmd, n, :delta_pg, i)[c] for (idx,c) in enumerate(gen["connections"])) for (i,gen)  in nw_ref[:gen]) +
            sum( sum(                         _PMD.var(pmd, n, :delta_ps, i)[c] for (idx,c) in enumerate(strg["connections"])) for (i,strg) in nw_ref[:storage])
        for (n, nw_ref) in _PMD.nws(pmd))
    )

end


"""
    function objective_itd_min_fuel_polynomial_distribution_load_setpoint_delta(
        pmitd::AbstractPowerModelITD,
        pm::_PM.AbstractPowerModel,
        pmd::_PMD.AbstractUnbalancedPowerModel
    )

Fuel cost minimization objective for polynomial terms in transmission and load setpoint delta for distribution.
"""
function objective_itd_min_fuel_polynomial_distribution_load_setpoint_delta(pmitd::AbstractPowerModelITD, pm::_PM.AbstractPowerModel, pmd::_PMD.AbstractUnbalancedPowerModel)

    # Extract the specific dictionary
    pm_data = pmitd.data["it"]["pm"]

    # PM
    pm_order = _PM.calc_max_cost_index(pm_data)-1

    if pm_order <= 2
        return _objective_itd_min_fuel_polynomial_linquad_distribution_load_setpoint_delta(pmitd, pm, pmd)
    else
        return _objective_itd_min_fuel_polynomial_nl_distribution_load_setpoint_delta(pmitd, pm, pmd)
    end

end


"""
    function _objective_itd_min_fuel_polynomial_linquad_distribution_load_setpoint_delta(
        pmitd::AbstractPowerModelITD,
        pm::_PM.AbstractPowerModel,
        pmd::_PMD.AbstractUnbalancedPowerModel
    )

Fuel cost minimization objective for polynomial terms linear-quadratic for transmission and load setpoint delta for distribution.
"""
function _objective_itd_min_fuel_polynomial_linquad_distribution_load_setpoint_delta(pmitd::AbstractPowerModelITD, pm::_PM.AbstractPowerModel, pmd::_PMD.AbstractUnbalancedPowerModel)

    # PM
    pm_gen_cost = Dict()

    for (n, nw_ref) in _PM.nws(pm)
        for (i,gen) in nw_ref[:gen]
            pg = _PM.var(pm, n, :pg, i)

            if length(gen["cost"]) == 1
                pm_gen_cost[(n,i)] = gen["cost"][1]
            elseif length(gen["cost"]) == 2
                pm_gen_cost[(n,i)] = gen["cost"][1]*pg + gen["cost"][2]
            elseif length(gen["cost"]) == 3
                pm_gen_cost[(n,i)] = gen["cost"][1]*pg^2 + gen["cost"][2]*pg + gen["cost"][3]
            else
                pm_gen_cost[(n,i)] = 0.0
            end
        end
    end


    # PMD
    for (n, nw_ref) in _PMD.nws(pmd)
        _PMD.var(pmd, n)[:delta_pg] = Dict(i => JuMP.@variable(pmd.model,
                [c in _PMD.ref(pmd, n, :gen, i)["connections"]], base_name="$(n)_$(i)_delta_pg",
                start = 0.0) for i in _PMD.ids(pmd, n, :gen))

        _PMD.var(pmd, n)[:delta_ps] = Dict(i => JuMP.@variable(pmd.model,
                [c in _PMD.ref(pmd, n, :storage, i)["connections"]], base_name="$(n)_$(i)_delta_ps",
                start = 0.0) for i in _PMD.ids(pmd, n, :storage))

        for (i, gen) in nw_ref[:gen]
            for (idx, c) in enumerate(gen["connections"])
                JuMP.@constraint(pmd.model, _PMD.var(pmd, n, :delta_pg, i)[c] >=  (gen["pg"][idx] - _PMD.var(pmd, n, :pg, i)[c]))
                JuMP.@constraint(pmd.model, _PMD.var(pmd, n, :delta_pg, i)[c] >= -(gen["pg"][idx] - _PMD.var(pmd, n, :pg, i)[c]))
            end
        end

        for (i, strg) in nw_ref[:storage]
            for (idx, c) in enumerate(strg["connections"])
                JuMP.@constraint(pmd.model, _PMD.var(pmd, n, :delta_ps, i)[c] >=  (strg["ps"][idx] - _PMD.var(pmd, n, :ps, i)[c]))
                JuMP.@constraint(pmd.model, _PMD.var(pmd, n, :delta_ps, i)[c] >= -(strg["ps"][idx] - _PMD.var(pmd, n, :ps, i)[c]))
            end
        end
    end

    w = Dict(n => Dict(i => 10*get(load, "weight", 1.0) for (i,load) in _PMD.ref(pmd, n, :load)) for n in _PMD.nw_ids(pmd))

    # ITD (Combined objective)
    return JuMP.@objective(pmitd.model, Min,
        sum(
            sum( pm_gen_cost[(n,i)] for (i,gen) in nw_ref[:gen] )
        for (n, nw_ref) in _PM.nws(pm))

        + sum(
            sum(                      10*(1 - _PMD.var(pmd, n, :z_voltage, i)) for (i,bus) in nw_ref[:bus]) +
            sum( w[n][i]*sum(load["pd"])*(1 - _PMD.var(pmd, n, :z_demand, i)) for (i,load) in nw_ref[:load]) +
            sum(        sum(shunt["gs"])*(1 - _PMD.var(pmd, n, :z_shunt, i)) for (i,shunt) in nw_ref[:shunt]) +
            sum( sum(                         _PMD.var(pmd, n, :delta_pg, i)[c] for (idx,c) in enumerate(gen["connections"])) for (i,gen)  in nw_ref[:gen]) +
            sum( sum(                         _PMD.var(pmd, n, :delta_ps, i)[c] for (idx,c) in enumerate(strg["connections"])) for (i,strg) in nw_ref[:storage])
        for (n, nw_ref) in _PMD.nws(pmd))
    )

end


"""
    function _objective_itd_min_fuel_polynomial_nl_distribution_load_setpoint_delta(
        pmitd::AbstractPowerModelITD,
        pm::_PM.AbstractPowerModel,
        pmd::_PMD.AbstractUnbalancedPowerModel
    )

Fuel cost minimization objective for polynomial terms non-linear for transmission and load setpoint delta for distribution.
"""
function _objective_itd_min_fuel_polynomial_nl_distribution_load_setpoint_delta(pmitd::AbstractPowerModelITD, pm::_PM.AbstractPowerModel, pmd::_PMD.AbstractUnbalancedPowerModel)

    # PM
    pm_gen_cost = Dict()
    for (n, nw_ref) in _PM.nws(pm)
        for (i,gen) in nw_ref[:gen]
            pg = _PM.var(pm, n, :pg, i)

            cost_rev = reverse(gen["cost"])
            if length(cost_rev) == 1
                pm_gen_cost[(n,i)] = JuMP.@NLexpression(pmitd.model, cost_rev[1])
            elseif length(cost_rev) == 2
                pm_gen_cost[(n,i)] = JuMP.@NLexpression(pmitd.model, cost_rev[1] + cost_rev[2]*pg)
            elseif length(cost_rev) == 3
                pm_gen_cost[(n,i)] = JuMP.@NLexpression(pmitd.model, cost_rev[1] + cost_rev[2]*pg + cost_rev[3]*pg^2)
            elseif length(cost_rev) >= 4
                cost_rev_nl = cost_rev[4:end]
                pm_gen_cost[(n,i)] = JuMP.@NLexpression(pmitd.model, cost_rev[1] + cost_rev[2]*pg + cost_rev[3]*pg^2 + sum( v*pg^(d+3) for (d,v) in enumerate(cost_rev_nl)) )
            else
                pm_gen_cost[(n,i)] = JuMP.@NLexpression(pmitd.model, 0.0)
            end
        end
    end


    # PMD
    for (n, nw_ref) in _PMD.nws(pmd)
        _PMD.var(pmd, n)[:delta_pg] = Dict(i => JuMP.@variable(pmd.model,
                [c in _PMD.ref(pmd, n, :gen, i)["connections"]], base_name="$(n)_$(i)_delta_pg",
                start = 0.0) for i in _PMD.ids(pmd, n, :gen))

        _PMD.var(pmd, n)[:delta_ps] = Dict(i => JuMP.@variable(pmd.model,
                [c in _PMD.ref(pmd, n, :storage, i)["connections"]], base_name="$(n)_$(i)_delta_ps",
                start = 0.0) for i in _PMD.ids(pmd, n, :storage))

        for (i, gen) in nw_ref[:gen]
            for (idx, c) in enumerate(gen["connections"])
                JuMP.@constraint(pmd.model, _PMD.var(pmd, n, :delta_pg, i)[c] >=  (gen["pg"][idx] - _PMD.var(pmd, n, :pg, i)[c]))
                JuMP.@constraint(pmd.model, _PMD.var(pmd, n, :delta_pg, i)[c] >= -(gen["pg"][idx] - _PMD.var(pmd, n, :pg, i)[c]))
            end
        end

        for (i, strg) in nw_ref[:storage]
            for (idx, c) in enumerate(strg["connections"])
                JuMP.@constraint(pmd.model, _PMD.var(pmd, n, :delta_ps, i)[c] >=  (strg["ps"][idx] - _PMD.var(pmd, n, :ps, i)[c]))
                JuMP.@constraint(pmd.model, _PMD.var(pmd, n, :delta_ps, i)[c] >= -(strg["ps"][idx] - _PMD.var(pmd, n, :ps, i)[c]))
            end
        end
    end

    w = Dict(n => Dict(i => 10*get(load, "weight", 1.0) for (i,load) in _PMD.ref(pmd, n, :load)) for n in _PMD.nw_ids(pmd))

    # ITD (Combined objective)
    return JuMP.@objective(pmitd.model, Min,
        sum(
            sum( pm_gen_cost[(n,i)] for (i,gen) in nw_ref[:gen] )
        for (n, nw_ref) in _PM.nws(pm))
        + sum(
            sum(                      10*(1 - _PMD.var(pmd, n, :z_voltage, i)) for (i,bus) in nw_ref[:bus]) +
            sum( w[n][i]*sum(load["pd"])*(1 - _PMD.var(pmd, n, :z_demand, i)) for (i,load) in nw_ref[:load]) +
            sum(        sum(shunt["gs"])*(1 - _PMD.var(pmd, n, :z_shunt, i)) for (i,shunt) in nw_ref[:shunt]) +
            sum( sum(                         _PMD.var(pmd, n, :delta_pg, i)[c] for (idx,c) in enumerate(gen["connections"])) for (i,gen)  in nw_ref[:gen]) +
            sum( sum(                         _PMD.var(pmd, n, :delta_ps, i)[c] for (idx,c) in enumerate(strg["connections"])) for (i,strg) in nw_ref[:storage])
        for (n, nw_ref) in _PMD.nws(pmd))
    )

end

