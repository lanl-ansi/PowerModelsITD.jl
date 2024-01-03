"""
Checks that all cost models are of the same type

adapted from the implementation in PowerModels <= v0.19
"""
function _check_cost_models(pm::_PM.AbstractPowerModel)
    gen_model = _check_gen_cost_models(pm)
    dcline_model = _check_dcline_cost_models(pm)

    if dcline_model == nothing
        return gen_model
    end

    if gen_model == nothing
        return dcline_model
    end

    if gen_model != dcline_model
        @error "generator and dcline cost models are inconsistent, the generator model is $(gen_model) however dcline model $(dcline_model)"
    end

    return gen_model
end


"""
Checks that all generator cost models are of the same type

adapted from the implementation in PowerModels <= v0.19
"""
function _check_gen_cost_models(pm::_PM.AbstractPowerModel)
    model = nothing

    for (n, nw_ref) in _PM.nws(pm)
        for (i,gen) in nw_ref[:gen]
            if haskey(gen, "cost")
                if model == nothing
                    model = gen["model"]
                else
                    if gen["model"] != model
                        @error "cost models are inconsistent, the typical model is $(model) however model $(gen["model"]) is given on generator $(i)"
                    end
                end
            else
                @error "no cost given for generator $(i)"
            end
        end
    end

    return model
end

"""
Checks that all dcline cost models are of the same type

adapted from the implementation in PowerModels <= v0.19
"""
function _check_dcline_cost_models(pm::_PM.AbstractPowerModel)
    model = nothing

    for (n, nw_ref) in _PM.nws(pm)
        for (i,dcline) in nw_ref[:dcline]
            if haskey(dcline, "model")
                if model == nothing
                    model = dcline["model"]
                else
                    if dcline["model"] != model
                        @error "cost models are inconsistent, the typical model is $(model) however model $(dcline["model"]) is given on dcline $(i)"
                    end
                end
            else
                @error "no cost given for dcline $(i)"
            end
        end
    end

    return model
end

"""
adds pg_cost variables and constraints

adapted from the implementation in PowerModels <= v0.19
"""
function _objective_variable_pg_cost(pm::_PM.AbstractPowerModel, report::Bool=true)
    for (n, nw_ref) in _PM.nws(pm)
        pg_cost = _PM.var(pm, n)[:pg_cost] = Dict{Int,Any}()

        for (i,gen) in _PM.ref(pm, n, :gen)
            pg_var = _PM.var(pm, n, :pg, i)
            pmin = JuMP.lower_bound(pg_var)
            pmax = JuMP.upper_bound(pg_var)

            points = _PM.calc_pwl_points(gen["ncost"], gen["cost"], pmin, pmax)

            pg_cost_lambda = JuMP.@variable(pm.model,
                [i in 1:length(points)], base_name="$(n)_pg_cost_lambda",
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
            JuMP.@constraint(pm.model, pg_expr == pg_var)
            pg_cost[i] = pg_cost_expr
        end

        report && _PM.sol_component_value(pm, n, :gen, :pg_cost, _PM.ids(pm, n, :gen), pg_cost)
    end
end

"""
adds p_dc_cost variables and constraints

adapted from the implementation in PowerModels <= v0.19
"""
function _objective_variable_dc_cost(pm::_PM.AbstractPowerModel, report::Bool=true)
    for (n, nw_ref) in _PM.nws(pm)
        p_dc_cost = _PM.var(pm, n)[:p_dc_cost] = Dict{Int,Any}()

        for (i,dcline) in _PM.ref(pm, n, :dcline)
            arc = (i, dcline["f_bus"], dcline["t_bus"])
            p_dc_var = _PM.var(pm, n, :p_dc)[arc]
            pmin = JuMP.lower_bound(p_dc_var)
            pmax = JuMP.upper_bound(p_dc_var)

            # note pmin/pmax may be different from dcline["pminf"]/dcline["pmaxf"] in the on/off case
            points = _PM.calc_pwl_points(dcline["ncost"], dcline["cost"], pmin, pmax)

            dc_p_cost_lambda = JuMP.@variable(pm.model,
                [i in 1:length(points)], base_name="$(n)_dc_p_cost_lambda",
                lower_bound = 0.0,
                upper_bound = 1.0
            )
            JuMP.@constraint(pm.model, sum(dc_p_cost_lambda) == 1.0)

            dc_p_expr = 0.0
            dc_p_cost_expr = 0.0
            for (i,point) in enumerate(points)
                dc_p_expr += point.mw*dc_p_cost_lambda[i]
                dc_p_cost_expr += point.cost*dc_p_cost_lambda[i]
            end

            JuMP.@constraint(pm.model, dc_p_expr == p_dc_var)
            p_dc_cost[i] = dc_p_cost_expr
        end

        report && _PM.sol_component_value(pm, n, :dcline, :p_dc_cost, _PM.ids(pm, n, :dcline), p_dc_cost)
    end
end

"""
adds pg_cost variables and constraints

adapted from the implementation in PowerModels <= v0.19
"""
function _objective_variable_pg_cost(pm::_PM.AbstractIVRModel; report::Bool=true)
    for (n, nw_ref) in _PM.nws(pm)
        gen_lines = _PM.calc_cost_pwl_lines(nw_ref[:gen])

        #to avoid function calls inside of @NLconstraint
        pg_cost = _PM.var(pm, n)[:pg_cost] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, n, :gen)], base_name="$(n)_pg_cost",
        )
        report && _PM.sol_component_value(pm, n, :gen, :pg_cost, _PM.ids(pm, n, :gen), pg_cost)

        for (i, gen) in nw_ref[:gen]
            pg = _PM.var(pm, n, :pg, i)
            for line in gen_lines[i]
                JuMP.@NLconstraint(pm.model, pg_cost[i] >= line.slope*pg + line.intercept)
            end
        end
    end
end

"""
added for compat with PowerModels <= v0.19 implementation
"""
function _objective_variable_dc_cost(pm::_PM.AbstractIVRModel, report::Bool=true)
    for (n, nw_ref) in _PM.nws(pm)
        dcline_lines = _PM.calc_cost_pwl_lines(nw_ref[:dcline])

        #to avoid function calls inside of @NLconstraint
        p_dc_cost = _PM.var(pm, n)[:p_dc_cost] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, n, :dcline)], base_name="$(n)_p_dc_cost",
        )
        report && _PM.sol_component_value(pm, n, :dcline, :p_dc_cost, _PM.ids(pm, n, :dcline), p_dc_cost)

        for (i, dcline) in nw_ref[:dcline]
            arc = (i, dcline["f_bus"], dcline["t_bus"])
            p_dc_var = _PM.var(pm, n, :p_dc)[arc]
            for line in dcline_lines[i]
                JuMP.@NLconstraint(pm.model, p_dc_cost[i] >= line.slope*p_dc_var + line.intercept)
            end
        end
    end
end


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
            JuMP.@NLconstraint(pm.model, pg_expr == sum(_PMD.var(pm, n, :pg, i)[c] for c in gen["connections"]))
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

            #to avoid function calls inside of @NLconstraint:
            pg = _PM.var(pm, n, :pg, i)
            if length(gen["cost"]) == 1
                pm_gen_cost[(n,i)] = gen["cost"][1]
            elseif length(gen["cost"]) == 2
                pm_gen_cost[(n,i)] = JuMP.@NLexpression(pm.model, gen["cost"][1]*pg + gen["cost"][2])
            elseif length(gen["cost"]) == 3
                pm_gen_cost[(n,i)] = JuMP.@NLexpression(pm.model, gen["cost"][1]*pg^2 + gen["cost"][2]*pg + gen["cost"][3])
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

            #to avoid function calls inside of @NLconstraint:
            pg = _PMD.var(pmd, n, :pg, i)
            if length(gen["cost"]) == 1
                pmd_gen_cost[(n,i)] = gen["cost"][1]
            elseif length(gen["cost"]) == 2
                pmd_gen_cost[(n,i)] = JuMP.@NLexpression(pmd.model, gen["cost"][1]*sum(pg[c] for c in gen["connections"]) + gen["cost"][2])
            elseif length(gen["cost"]) == 3
                pmd_gen_cost[(n,i)] = JuMP.@NLexpression(pmd.model, gen["cost"][1]*sum(pg[c] for c in gen["connections"])^2 + gen["cost"][2]*sum(pg[c] for c in gen["connections"]) + gen["cost"][3])
            else
                pmd_gen_cost[(n,i)] = 0.0
            end
        end
    end


    # ITD (Combined objective)
    return JuMP.@NLobjective(pmitd.model, Min,
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

            #to avoid function calls inside of @NLconstraint:
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
                pm_gen_cost[(n,i)] = JuMP.@NLexpression(pmitd.model, cost_rev[1] + cost_rev[2]*pg + cost_rev[3]*pg^2 + sum( v*pg^(d+2) for (d,v) in enumerate(cost_rev_nl)) )
            else
                pm_gen_cost[(n,i)] = JuMP.@NLexpression(pmitd.model, 0.0)
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
                pmd_gen_cost[(n,i)] = JuMP.@NLexpression(pmitd.model, cost_rev[1])
            elseif length(cost_rev) == 2
                pmd_gen_cost[(n,i)] = JuMP.@NLexpression(pmitd.model, cost_rev[1] + cost_rev[2]*sum(pg[c] for c in gen["connections"]))
            elseif length(cost_rev) == 3
                pmd_gen_cost[(n,i)] = JuMP.@NLexpression(pmitd.model, cost_rev[1] + cost_rev[2]*sum(pg[c] for c in gen["connections"]) + cost_rev[3]*sum(pg[c] for c in gen["connections"])^2)
            elseif length(cost_rev) >= 4
                cost_rev_nl = cost_rev[4:end]
                pmd_gen_cost[(n,i)] = JuMP.@NLexpression(pmitd.model, cost_rev[1] + cost_rev[2]*sum(pg[c] for c in gen["connections"]) + cost_rev[3]*sum(pg[c] for c in gen["connections"])^2 + sum( v*sum(pg[c] for c in gen["connections"])^(d+2) for (d,v) in enumerate(cost_rev_nl)) )
            else
                pmd_gen_cost[(n,i)] = JuMP.@NLexpression(pmitd.model, 0.0)
            end
        end
    end

    # ITD (Combined objective)
    return JuMP.@NLobjective(pmitd.model, Min,
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
                pm_gen_cost[(n,i)] = JuMP.@NLexpression(pmitd.model, cost_rev[1])
            elseif length(cost_rev) == 2
                pm_gen_cost[(n,i)] = JuMP.@NLexpression(pmitd.model, cost_rev[1] + cost_rev[2]*pg)
            elseif length(cost_rev) == 3
                pm_gen_cost[(n,i)] = JuMP.@NLexpression(pmitd.model, cost_rev[1] + cost_rev[2]*pg + cost_rev[3]*pg^2)
            elseif length(cost_rev) >= 4
                cost_rev_nl = cost_rev[4:end]
                pm_gen_cost[(n,i)] = JuMP.@NLexpression(pmitd.model, cost_rev[1] + cost_rev[2]*pg + cost_rev[3]*pg^2 + sum( v*pg^(d+2) for (d,v) in enumerate(cost_rev_nl)) )
            else
                pm_gen_cost[(n,i)] = JuMP.@NLexpression(pmitd.model, 0.0)
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
                pmd_gen_cost[(n,i)] = JuMP.@NLexpression(pmitd.model, cost_rev[1])
            elseif length(cost_rev) == 2
                pmd_gen_cost[(n,i)] = JuMP.@NLexpression(pmitd.model, cost_rev[1] + cost_rev[2]*pg_aux)
            elseif length(cost_rev) == 3
                pmd_gen_cost[(n,i)] = JuMP.@NLexpression(pmitd.model, cost_rev[1] + cost_rev[2]*pg_aux + cost_rev[3]*pg_aux^2)
            elseif length(cost_rev) >= 4
                cost_rev_nl = cost_rev[4:end]
                pmd_gen_cost[(n,i)] = JuMP.@NLexpression(pmitd.model, cost_rev[1] + cost_rev[2]*pg_aux + cost_rev[3]*pg_aux^2 + sum( v*pg_aux^(d+2) for (d,v) in enumerate(cost_rev_nl)) )
            else
                pmd_gen_cost[(n,i)] = JuMP.@NLexpression(pmitd.model, 0.0)
            end
        end
    end

    # ITD (Combined objective)
    return JuMP.@NLobjective(pmitd.model, Min,
        sum(
            sum( pm_gen_cost[(n,i)] for (i,gen) in nw_ref[:gen] )
        for (n, nw_ref) in _PM.nws(pm))
        + sum(
            sum( pmd_gen_cost[(n,i)] for (i,gen) in nw_ref[:gen] )
        for (n, nw_ref) in _PMD.nws(pmd))
    )

end
