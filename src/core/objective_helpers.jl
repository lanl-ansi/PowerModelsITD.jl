"""
    function _check_cost_models(
        pm::_PM.AbstractPowerModel
    )

Checks that all cost models are of the same type.
Adapted from the implementation in PowerModels <= v0.19.
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
    function _check_gen_cost_models(
        pm::_PM.AbstractPowerModel
    )

Checks that all generator cost models are of the same type.
Adapted from the implementation in PowerModels <= v0.19.
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
    function _check_dcline_cost_models(
        pm::_PM.AbstractPowerModel
    )

Checks that all dcline cost models are of the same type.
Adapted from the implementation in PowerModels <= v0.19.
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
    function _objective_variable_pg_cost(
        pm::_PM.AbstractPowerModel,
        report::Bool=true
    )

Adds pg_cost variables and constraints.
Adapted from the implementation in PowerModels <= v0.19.
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
    function _objective_variable_dc_cost(
        pm::_PM.AbstractPowerModel,
        report::Bool=true
    )

Adds p_dc_cost variables and constraints.
Adapted from the implementation in PowerModels <= v0.19.
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
    function _objective_variable_pg_cost(
        pm::_PM.AbstractIVRModel,
        report::Bool=true
    )

Adds pg_cost variables and constraints for IVR Model.
Adapted from the implementation in PowerModels <= v0.19.
"""
function _objective_variable_pg_cost(pm::_PM.AbstractIVRModel; report::Bool=true)
    for (n, nw_ref) in _PM.nws(pm)
        gen_lines = _PM.calc_cost_pwl_lines(nw_ref[:gen])

        #to avoid function calls inside of @constraint
        pg_cost = _PM.var(pm, n)[:pg_cost] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, n, :gen)], base_name="$(n)_pg_cost",
        )
        report && _PM.sol_component_value(pm, n, :gen, :pg_cost, _PM.ids(pm, n, :gen), pg_cost)

        for (i, gen) in nw_ref[:gen]
            pg = _PM.var(pm, n, :pg, i)
            for line in gen_lines[i]
                JuMP.@constraint(pm.model, pg_cost[i] >= line.slope*pg + line.intercept)
            end
        end
    end
end


"""
    function _objective_variable_dc_cost(
        pm::_PM.AbstractIVRModel,
        report::Bool=true
    )

Adds p_dc_cost variables and constraints for IVR Model.
Added for compat with PowerModels <= v0.19 implementation.
"""
function _objective_variable_dc_cost(pm::_PM.AbstractIVRModel, report::Bool=true)
    for (n, nw_ref) in _PM.nws(pm)
        dcline_lines = _PM.calc_cost_pwl_lines(nw_ref[:dcline])

        #to avoid function calls inside of @constraint
        p_dc_cost = _PM.var(pm, n)[:p_dc_cost] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, n, :dcline)], base_name="$(n)_p_dc_cost",
        )
        report && _PM.sol_component_value(pm, n, :dcline, :p_dc_cost, _PM.ids(pm, n, :dcline), p_dc_cost)

        for (i, dcline) in nw_ref[:dcline]
            arc = (i, dcline["f_bus"], dcline["t_bus"])
            p_dc_var = _PM.var(pm, n, :p_dc)[arc]
            for line in dcline_lines[i]
                JuMP.@constraint(pm.model, p_dc_cost[i] >= line.slope*p_dc_var + line.intercept)
            end
        end
    end
end
