"""
    function objective_itd_min_fuel_cost(
        pmitd::AbstractPowerModelITD
    )

Standard fuel cost minimization objective.
"""
function objective_itd_min_fuel_cost(pmitd::AbstractPowerModelITD)

    # Extract the transmission model
    pm_model = _get_powermodel_from_powermodelitd(pmitd)

    # Extract the distribution model
    pmd_model = _get_powermodeldistribution_from_powermodelitd(pmitd)

    # PM cost models
    pm_cost_model = _check_gen_cost_models(pm_model)

    # PMD cost models
    pmd_cost_model = _PMD.check_gen_cost_models(pmd_model)

    # TODO: Revise of there exists the possibility of having Mix (e.g., pm_cost_model=1, pmd_cost_model=2 or pm_cost_model=2, pmd_cost_model=1)
    if pm_cost_model == 1 # && pmd_cost_model == 1 # pmd_cost_model may not be needed (see cases when no gen is in dist. system.)
        return objective_itd_min_fuel_cost_pwl(pmitd, pm_model, pmd_model)
    elseif pm_cost_model == 2 # && pmd_cost_model == 2 # pmd_cost_model may not be needed (see cases when no gen is in dist. system.)
        return objective_itd_min_fuel_cost_polynomial(pmitd, pm_model, pmd_model)
    else
        @error "Only cost models of types 1 and 2 are supported at this time, given cost model type of $(pm_cost_model) and $(pmd_cost_model)"
    end

end


"""
    function objective_itd_min_fuel_cost_pwl(
        pmitd::AbstractPowerModelITD,
        pm::_PM.AbstractPowerModel,
        pmd::_PMD.AbstractUnbalancedPowerModel
    )

Fuel cost minimization objective with piecewise linear terms.
"""
function objective_itd_min_fuel_cost_pwl(pmitd::AbstractPowerModelITD, pm::_PM.AbstractPowerModel, pmd::_PMD.AbstractUnbalancedPowerModel)

    # PM-section part
    _objective_variable_pg_cost(pm)
    _objective_variable_dc_cost(pm)

    # PMD-section part
    objective_mc_variable_pg_cost(pmd)
    # TODO: Cannot use this function from PMD since it produces an error related to calc_pwl_points() function (Future releases may fix this)
    # _PMD.objective_mc_variable_pg_cost(pmd)

    return JuMP.@objective(pmitd.model, Min,
        sum(
            sum( _PM.var(pm, n,   :pg_cost, i) for (i,gen) in nw_ref[:gen]) +
            sum( _PM.var(pm, n, :p_dc_cost, i) for (i,dcline) in nw_ref[:dcline])
        for (n, nw_ref) in _PM.nws(pm))
        + sum(
            sum( _PMD.var(pmd, n, :pg_cost, i) for (i,gen) in nw_ref[:gen])
        for (n, nw_ref) in _PMD.nws(pmd))
    )

end


"""
    function objective_mc_variable_pg_cost(
        pm::_PMD.AbstractUnbalancedPowerModel
    )

Adds pg_cost variables and constraints (Copied from PMD and modified to allow differentiation with TD gens (..._dist)).
"""
function objective_mc_variable_pg_cost(pm::_PMD.AbstractUnbalancedPowerModel; report::Bool=true)
    for (n, nw_ref) in _PMD.nws(pm)
        pg_cost = _PMD.var(pm, n)[:pg_cost] = Dict{Int,Any}()

        for (i,gen) in _PMD.ref(pm, n, :gen)

            points = _PMD.calc_pwl_points(gen["ncost"], gen["cost"], gen["pmin"][1], gen["pmax"][1])

            pg_cost_lambda = JuMP.@variable(pm.model,
                [i in 1:length(points)], base_name="$(n)_pg_cost_lambda_dist",
                lower_bound = 0.0,
                upper_bound = 1.0
            )
            JuMP.@constraint(pm.model, sum(pg_cost_lambda) == 1.0)

            pg_expr = 0.0
            pg_cost_expr = 0.0
            for (i,point) in enumerate(points)
                pg_expr += point.mw*pg_cost_lambda[i]
                pg_cost_expr += point.cost*pg_cost_lambda[i]
            end
            JuMP.@constraint(pm.model, pg_expr == sum(_PMD.var(pm, n, :pg, i)[c] for c in gen["connections"]))
            pg_cost[i] = pg_cost_expr
        end

        report && _IM.sol_component_value(pm, _PMD.pmd_it_sym, n, :gen, :pg_cost, _PMD.ids(pm, n, :gen), pg_cost)
    end
end


"""
    function objective_mc_variable_pg_cost(
        pm::_PMD.AbstractUnbalancedIVRModel
    )

Adds pg_cost variables and constraints (IVR formulation) (Copied from PMD and modified to allow differentiation with TD gens (..._dist)).
"""
function objective_mc_variable_pg_cost(pm::_PMD.AbstractUnbalancedIVRModel; report::Bool=true)
    for (n, nw_ref) in _PMD.nws(pm)
        pg_cost = _PMD.var(pm, n)[:pg_cost] = Dict{Int,Any}()

        for (i,gen) in _PMD.ref(pm, n, :gen)

            points = _PMD.calc_pwl_points(gen["ncost"], gen["cost"], gen["pmin"][1], gen["pmax"][1])

            pg_cost_lambda = JuMP.@variable(pm.model,
                [i in 1:length(points)], base_name="$(n)_pg_cost_lambda_dist",
                lower_bound = 0.0,
                upper_bound = 1.0
            )

            JuMP.@constraint(pm.model, sum(pg_cost_lambda) == 1.0)

            pg_expr = 0.0
            pg_cost_expr = 0.0
            for (i,point) in enumerate(points)
                pg_expr += point.mw*pg_cost_lambda[i]
                pg_cost_expr += point.cost*pg_cost_lambda[i]
            end
            # Important: This constraint had to be changed to a Non-linear constraint
            JuMP.@constraint(pm.model, pg_expr == sum(_PMD.var(pm, n, :pg, i)[c] for c in gen["connections"]))
            pg_cost[i] = pg_cost_expr
        end
        report && _IM.sol_component_value(pm, _PMD.pmd_it_sym, n, :gen, :pg_cost, _PMD.ids(pm, n, :gen), pg_cost)
    end
end


"""
    function objective_itd_min_fuel_cost_polynomial(
        pmitd::AbstractPowerModelITD,
        pm::_PM.AbstractPowerModel,
        pmd::_PMD.AbstractUnbalancedPowerModel
    )

Fuel cost minimization objective for polynomial terms.
"""
function objective_itd_min_fuel_cost_polynomial(pmitd::AbstractPowerModelITD, pm::_PM.AbstractPowerModel, pmd::_PMD.AbstractUnbalancedPowerModel)

    # Extract the specific dictionary
    pm_data = pmitd.data["it"]["pm"]
    pmd_data = pmitd.data["it"]["pmd"]

    # PM
    pm_order = _PM.calc_max_cost_index(pm_data)-1
    # PMD
    pmd_order = _PMD.calc_max_cost_index(pmd_data)-1


    if pm_order <= 2 && pmd_order <= 2
        return _objective_itd_min_fuel_cost_polynomial_linquad(pmitd, pm, pmd)
    else
        return _objective_itd_min_fuel_cost_polynomial_nl(pmitd, pm, pmd)
    end

end


"""
    function _objective_itd_min_fuel_cost_polynomial_linquad(
        pmitd::AbstractPowerModelITD,
        pm::_PM.AbstractPowerModel,
        pmd::_PMD.AbstractUnbalancedPowerModel
    )

Fuel cost minimization objective for polynomial terms linear-quadratic.
"""
function _objective_itd_min_fuel_cost_polynomial_linquad(pmitd::AbstractPowerModelITD, pm::_PM.AbstractPowerModel, pmd::_PMD.AbstractUnbalancedPowerModel)

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
    pmd_gen_cost = Dict()

    for (n, nw_ref) in _PMD.nws(pmd)
        for (i,gen) in nw_ref[:gen]
            pg = sum( _PMD.var(pmd, n, :pg, i)[c] for c in gen["connections"] )

            if length(gen["cost"]) == 1
                pmd_gen_cost[(n,i)] = gen["cost"][1]
            elseif length(gen["cost"]) == 2
                pmd_gen_cost[(n,i)] = gen["cost"][1]*pg + gen["cost"][2]
            elseif length(gen["cost"]) == 3
                pmd_gen_cost[(n,i)] = gen["cost"][1]*pg^2 + gen["cost"][2]*pg + gen["cost"][3]
            else
                pmd_gen_cost[(n,i)] = 0.0
            end
        end
    end


    # ITD (Combined objective)
    return JuMP.@objective(pmitd.model, Min,
        sum(
            sum( pm_gen_cost[(n,i)] for (i,gen) in nw_ref[:gen] )
        for (n, nw_ref) in _PM.nws(pm))
        + sum(
            sum( pmd_gen_cost[(n,i)] for (i,gen) in nw_ref[:gen] )
        for (n, nw_ref) in _PMD.nws(pmd))
    )

end


"""
    function _objective_itd_min_fuel_cost_polynomial_linquad(
        pmitd::AbstractIVRPowerModelITD,
        pm::_PM.AbstractIVRModel,
        pmd::_PMD.AbstractUnbalancedIVRModel
    )

Fuel cost minimization objective for polynomial terms linear-quadratic (IVR formulation).
"""
function _objective_itd_min_fuel_cost_polynomial_linquad(pmitd::AbstractIVRPowerModelITD, pm::_PM.AbstractIVRModel, pmd::_PMD.AbstractUnbalancedIVRModel)

    # PM
    pm_gen_cost = Dict()

    for (n, nw_ref) in _PM.nws(pm)
        for (i,gen) in nw_ref[:gen]
            bus = gen["gen_bus"]

            #to avoid function calls inside of @constraint:
            pg = _PM.var(pm, n, :pg, i)
            if length(gen["cost"]) == 1
                pm_gen_cost[(n,i)] = gen["cost"][1]
            elseif length(gen["cost"]) == 2
                pm_gen_cost[(n,i)] = JuMP.@expression(pm.model, gen["cost"][1]*pg + gen["cost"][2])
            elseif length(gen["cost"]) == 3
                pm_gen_cost[(n,i)] = JuMP.@expression(pm.model, gen["cost"][1]*pg^2 + gen["cost"][2]*pg + gen["cost"][3])
            else
                pm_gen_cost[(n,i)] = 0.0
            end
        end
    end

    # PMD
    pmd_gen_cost = Dict()

    for (n, nw_ref) in _PMD.nws(pmd)
        for (i,gen) in nw_ref[:gen]
            bus = gen["gen_bus"]

            #to avoid function calls inside of @constraint:
            pg = _PMD.var(pmd, n, :pg, i)
            if length(gen["cost"]) == 1
                pmd_gen_cost[(n,i)] = gen["cost"][1]
            elseif length(gen["cost"]) == 2
                pmd_gen_cost[(n,i)] = JuMP.@expression(pmd.model, gen["cost"][1]*sum(pg[c] for c in gen["connections"]) + gen["cost"][2])
            elseif length(gen["cost"]) == 3
                pmd_gen_cost[(n,i)] = JuMP.@expression(pmd.model, gen["cost"][1]*sum(pg[c] for c in gen["connections"])^2 + gen["cost"][2]*sum(pg[c] for c in gen["connections"]) + gen["cost"][3])
            else
                pmd_gen_cost[(n,i)] = 0.0
            end
        end
    end


    # ITD (Combined objective)
    return JuMP.@objective(pmitd.model, Min,
        sum(
            sum( pm_gen_cost[(n,i)] for (i,gen) in nw_ref[:gen] )
        for (n, nw_ref) in _PM.nws(pm))
        + sum(
            sum( pmd_gen_cost[(n,i)] for (i,gen) in nw_ref[:gen] )
        for (n, nw_ref) in _PMD.nws(pmd))
    )

end


"""
    function _objective_itd_min_fuel_cost_polynomial_nl(
        pmitd::AbstractIVRPowerModelITD,
        pm::_PM.AbstractIVRModel,
        pmd::_PMD.AbstractUnbalancedIVRModel
    )

Fuel cost minimization objective for polynomial terms non-linear (IVR formulation).
"""
function _objective_itd_min_fuel_cost_polynomial_nl(pmitd::AbstractIVRPowerModelITD, pm::_PM.AbstractIVRModel, pmd::_PMD.AbstractUnbalancedIVRModel)

    # PM
    pm_gen_cost = Dict()
    for (n, nw_ref) in _PM.nws(pm)
        for (i,gen) in nw_ref[:gen]
            bus = gen["gen_bus"]

            #to avoid function calls inside of @constraint:
            pg = _PM.var(pm, n, :pg, i)
            cost_rev = reverse(gen["cost"])
            if length(cost_rev) == 1
                pm_gen_cost[(n,i)] = JuMP.@expression(pmitd.model, cost_rev[1])
            elseif length(cost_rev) == 2
                pm_gen_cost[(n,i)] = JuMP.@expression(pmitd.model, cost_rev[1] + cost_rev[2]*pg)
            elseif length(cost_rev) == 3
                pm_gen_cost[(n,i)] = JuMP.@expression(pmitd.model, cost_rev[1] + cost_rev[2]*pg + cost_rev[3]*pg^2)
            elseif length(cost_rev) >= 4
                cost_rev_nl = cost_rev[4:end]
                pm_gen_cost[(n,i)] = JuMP.@expression(pmitd.model, cost_rev[1] + cost_rev[2]*pg + cost_rev[3]*pg^2 + sum( v*pg^(d+2) for (d,v) in enumerate(cost_rev_nl)) )
            else
                pm_gen_cost[(n,i)] = JuMP.@expression(pmitd.model, 0.0)
            end
        end
    end


    # PMD
    pmd_gen_cost = Dict()
    for (n, nw_ref) in _PMD.nws(pmd)
        for (i,gen) in nw_ref[:gen]

            pg = _PMD.var(pmd, n, :pg, i)
            cost_rev = reverse(gen["cost"])

            if length(cost_rev) == 1
                pmd_gen_cost[(n,i)] = JuMP.@expression(pmitd.model, cost_rev[1])
            elseif length(cost_rev) == 2
                pmd_gen_cost[(n,i)] = JuMP.@expression(pmitd.model, cost_rev[1] + cost_rev[2]*sum(pg[c] for c in gen["connections"]))
            elseif length(cost_rev) == 3
                pmd_gen_cost[(n,i)] = JuMP.@expression(pmitd.model, cost_rev[1] + cost_rev[2]*sum(pg[c] for c in gen["connections"]) + cost_rev[3]*sum(pg[c] for c in gen["connections"])^2)
            elseif length(cost_rev) >= 4
                cost_rev_nl = cost_rev[4:end]
                pmd_gen_cost[(n,i)] = JuMP.@expression(pmitd.model, cost_rev[1] + cost_rev[2]*sum(pg[c] for c in gen["connections"]) + cost_rev[3]*sum(pg[c] for c in gen["connections"])^2 + sum( v*sum(pg[c] for c in gen["connections"])^(d+2) for (d,v) in enumerate(cost_rev_nl)) )
            else
                pmd_gen_cost[(n,i)] = JuMP.@expression(pmitd.model, 0.0)
            end
        end
    end

    # ITD (Combined objective)
    return JuMP.@objective(pmitd.model, Min,
        sum(
            sum( pm_gen_cost[(n,i)] for (i,gen) in nw_ref[:gen] )
        for (n, nw_ref) in _PM.nws(pm))
        + sum(
            sum( pmd_gen_cost[(n,i)] for (i,gen) in nw_ref[:gen] )
        for (n, nw_ref) in _PMD.nws(pmd))
    )

end


"""
    function _objective_itd_min_fuel_cost_polynomial_nl(
        pmitd::AbstractPowerModelITD,
        pm::_PM.AbstractPowerModel,
        pmd::_PMD.AbstractUnbalancedPowerModel
    )

Fuel cost minimization objective for polynomial terms non-linear.
"""
function _objective_itd_min_fuel_cost_polynomial_nl(pmitd::AbstractPowerModelITD, pm::_PM.AbstractPowerModel, pmd::_PMD.AbstractUnbalancedPowerModel)

    # PM
    pm_gen_cost = Dict()
    for (n, nw_ref) in _PM.nws(pm)
        for (i,gen) in nw_ref[:gen]
            pg = _PM.var(pm, n, :pg, i)

            cost_rev = reverse(gen["cost"])
            if length(cost_rev) == 1
                pm_gen_cost[(n,i)] = JuMP.@expression(pmitd.model, cost_rev[1])
            elseif length(cost_rev) == 2
                pm_gen_cost[(n,i)] = JuMP.@expression(pmitd.model, cost_rev[1] + cost_rev[2]*pg)
            elseif length(cost_rev) == 3
                pm_gen_cost[(n,i)] = JuMP.@expression(pmitd.model, cost_rev[1] + cost_rev[2]*pg + cost_rev[3]*pg^2)
            elseif length(cost_rev) >= 4
                cost_rev_nl = cost_rev[4:end]
                pm_gen_cost[(n,i)] = JuMP.@expression(pmitd.model, cost_rev[1] + cost_rev[2]*pg + cost_rev[3]*pg^2 + sum( v*pg^(d+2) for (d,v) in enumerate(cost_rev_nl)) )
            else
                pm_gen_cost[(n,i)] = JuMP.@expression(pmitd.model, 0.0)
            end
        end
    end


    # PMD
    pmd_gen_cost = Dict()
    for (n, nw_ref) in _PMD.nws(pmd)
        for (i,gen) in nw_ref[:gen]
            pg = sum( _PMD.var(pmd, n, :pg, i)[c] for c in gen["connections"] )

            cost_rev = reverse(gen["cost"])

            # This is needed to get around error: "unexpected affine expression in nl objective", See JuMP Documentation: 'AffExpr and QuadExpr cannot be used'
            pg_aux = JuMP.@variable(pmitd.model, base_name="$(n)_pg_aux_dist_$(i)")
            JuMP.@constraint(pmitd.model, pg_aux == pg)

            if length(cost_rev) == 1
                pmd_gen_cost[(n,i)] = JuMP.@expression(pmitd.model, cost_rev[1])
            elseif length(cost_rev) == 2
                pmd_gen_cost[(n,i)] = JuMP.@expression(pmitd.model, cost_rev[1] + cost_rev[2]*pg_aux)
            elseif length(cost_rev) == 3
                pmd_gen_cost[(n,i)] = JuMP.@expression(pmitd.model, cost_rev[1] + cost_rev[2]*pg_aux + cost_rev[3]*pg_aux^2)
            elseif length(cost_rev) >= 4
                cost_rev_nl = cost_rev[4:end]
                pmd_gen_cost[(n,i)] = JuMP.@expression(pmitd.model, cost_rev[1] + cost_rev[2]*pg_aux + cost_rev[3]*pg_aux^2 + sum( v*pg_aux^(d+2) for (d,v) in enumerate(cost_rev_nl)) )
            else
                pmd_gen_cost[(n,i)] = JuMP.@expression(pmitd.model, 0.0)
            end
        end
    end

    # ITD (Combined objective)
    return JuMP.@objective(pmitd.model, Min,
        sum(
            sum( pm_gen_cost[(n,i)] for (i,gen) in nw_ref[:gen] )
        for (n, nw_ref) in _PM.nws(pm))
        + sum(
            sum( pmd_gen_cost[(n,i)] for (i,gen) in nw_ref[:gen] )
        for (n, nw_ref) in _PMD.nws(pmd))
    )

end
