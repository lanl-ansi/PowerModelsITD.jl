# This file contains useful transformation functions for the solutions (SI or pu) - Decomposition

"""
    function run_decomposition(
        pmitd::DecompositionStruct
    )

Runs decomposition process and returns organized result solution dictionary.
"""
function run_decomposition(pmitd::DecompositionStruct)

    # Calls the _IDEC optimize!(..) function and solves decomposition problem
    _, solve_time, solve_bytes_alloc, sec_in_gc = @timed _IDEC.optimize!(pmitd.optimizer)

    # Build and organize the result dictionary
    result = Dict{String, Any}("solution" => Dict{String, Any}("it" => Dict{String, Any}(_PM.pm_it_name => Dict{String, Any}(), _PMD.pmd_it_name => Dict{String, Any}(), pmitd_it_name => Dict{String, Any}())))
    result["solution"]["it"][_PM.pm_it_name] = _IM.build_result(pmitd.pm, solve_time)
    result["solution"]["it"][pmitd_it_name]["boundary"] = result["solution"]["it"][_PM.pm_it_name]["solution"]["boundary"]

    for (pmd_num, pmd) in enumerate(pmitd.pmd)
        for (_, boundary_data) in pmd.data[pmitd_it_name]

	        pmd.model = pmitd.optimizer.subproblems[pmd_num]
	        ckt_name = boundary_data["ckt_name"]
            result["solution"]["it"][_PMD.pmd_it_name][ckt_name] = build_result_subproblems(pmd, solve_time)

            boundary_key = collect(keys(result["solution"]["it"][_PMD.pmd_it_name][ckt_name]["solution"]["boundary"]))
            boundary_vars = result["solution"]["it"][_PMD.pmd_it_name][ckt_name]["solution"]["boundary"][boundary_key[1]]

            if haskey(boundary_vars, "pbound_aux")
                result["solution"]["it"][pmitd_it_name]["boundary"][boundary_key[1]]["pbound_aux"] = boundary_vars["pbound_aux"]
            end

            if haskey(boundary_vars, "qbound_aux")
                result["solution"]["it"][pmitd_it_name]["boundary"][boundary_key[1]]["qbound_aux"] = boundary_vars["qbound_aux"]
            end

        end
    end

    return result
end

# ----------------- Custom-made build_result and build_solution_values function ------------------------

""
function build_result_subproblems(aim::_IM.AbstractInfrastructureModel, solve_time; solution_processors=[])
    # try-catch is needed until solvers reliably support ResultCount()
    result_count = 1
    try
        result_count = JuMP.result_count(aim.model)
    catch
        @warn("the given optimizer does not provide the ResultCount() attribute, assuming the solver returned a solution which may be incorrect.");
    end

    solution = Dict{String,Any}()

    if result_count > 0
        solution = build_solution_subproblem(aim, post_processors=solution_processors)
    else
        @warn("model has no results, solution cannot be built")
    end

    result = Dict{String,Any}(
        "optimizer" => JuMP.solver_name(aim.model),
        "termination_status" => JuMP.termination_status(aim.model),
        "primal_status" => JuMP.primal_status(aim.model),
        "dual_status" => JuMP.dual_status(aim.model),
        "objective" => _guard_objective_value(aim.model),
        "objective_lb" => _guard_objective_bound(aim.model),
        "solve_time" => solve_time,
        "solution" => solution,
    )

    return result
end


""
function _guard_objective_value(model)
    obj_val = NaN

    try
        obj_val = JuMP.objective_value(model)
    catch
    end

    return obj_val
end


""
function _guard_objective_bound(model)
    obj_lb = -Inf

    try
        obj_lb = JuMP.objective_bound(model)
    catch
    end

    return obj_lb
end



""
function build_solution_subproblem(aim::_IM.AbstractInfrastructureModel; post_processors=[])

    sol = Dict{String, Any}("it" => Dict{String, Any}())
    sol["multiinfrastructure"] = true

    for it in  _IM.it_ids(aim)
        sol["it"][string(it)] = build_solution_values_subproblem(aim.model, aim.sol[:it][it])
        sol["it"][string(it)]["multinetwork"] = true
    end

    _IM.solution_preprocessor(aim, sol)

    for post_processor in post_processors
        post_processor(aim, sol)
    end

    for it in _IM.it_ids(aim)
        it_str = string(it)
        data_it = _IM.ismultiinfrastructure(aim) ? aim.data["it"][it_str] : aim.data

        if _IM.ismultinetwork(data_it)
            sol["it"][it_str]["multinetwork"] = true
        else
            for (k, v) in sol["it"][it_str]["nw"]["$(nw_id_default)"]
                sol["it"][it_str][k] = v
            end

            sol["it"][it_str]["multinetwork"] = false
            delete!(sol["it"][it_str], "nw")
        end

        if !_IM.ismultiinfrastructure(aim)
            for (k, v) in sol["it"][it_str]
                sol[k] = v
            end

            delete!(sol["it"], it_str)
        end
    end

    if !_IM.ismultiinfrastructure(aim)
        sol["multiinfrastructure"] = false
        delete!(sol, "it")
    end

    return sol
end


""
function build_solution_values_subproblem(model::JuMP.Model, var::Dict)
    return build_solution_values(model, var)
end


""
function build_solution_values(model::JuMP.Model, var::Dict)
    sol = Dict{String, Any}()
    for (key, val) in var
        sol[string(key)] = build_solution_values(model, val)
    end
    return sol
end

""
function build_solution_values(model::JuMP.Model, var::JuMP.Containers.DenseAxisArray)
    sol_tmp = []
    for val in eachindex(var)
        push!(sol_tmp, build_solution_values(model, var[val]))
    end
    return sol_tmp
end


""
function build_solution_values(model::JuMP.Model, var::Array{<:Any,1})
    return [build_solution_values(val) for val in var]
end

""
function build_solution_values(model::JuMP.Model, var::Array{<:Any,2})
    return [build_solution_values(var[i, j]) for i in 1:size(var, 1), j in 1:size(var, 2)]
end

""
function build_solution_values(model::JuMP.Model, var::Number)
    return var
end

""
function build_solution_values(model::JuMP.Model, var::JuMP.VariableRef)
    var_fr_model = JuMP.variable_by_name(model, string(var))
    return JuMP.value(var_fr_model)
end

""
function build_solution_values(model::JuMP.Model, var::JuMP.GenericAffExpr)
    var_terms = var.terms           # Get variable terms OrderedDict: (var => coeff)
    var_keys = keys(var.terms)      # Get the JuMP.VariableRef as keys
    var_vector = collect(var_keys)  # Collect the JuMP.VariableRef keys in a vector

    cmp_terms = []              # vector used to store the final computed terms (i.e., coeff*value)
    for v in var_vector
        v_name = string(v)      # convert JuMP.VariableRef to string (for searching the value in the model)
        v_coeff = var_terms[v]  # get the coefficient from the OrderedDict of var_terms
        v_model = JuMP.variable_by_name(model, v_name)  # get the new value from the JuMP model.
        push!(cmp_terms, v_coeff*JuMP.value(v_model))   # multiply the value obtained with the corresponding coefficient - add to vector of computed terms
    end

    return sum(cmp_terms) # sum all the computed terms (coeff*value) - return the value
end

""
function build_solution_values(model::JuMP.Model, var::JuMP.GenericQuadExpr)
    var_terms = var.terms           # Get variable terms OrderedDict: (var => coeff)
    var_keys = keys(var.terms)      # Get the JuMP.VariableRef as keys
    var_vector = collect(var_keys)  # Collect the JuMP.VariableRef keys in a vector

    cmp_terms = []              # vector used to store the final computed terms (i.e., coeff*value)
    for v in var_vector
        v_name = string(v)      # convert JuMP.VariableRef to string (for searching the value in the model)
        v_coeff = var_terms[v]  # get the coefficient from the OrderedDict of var_terms
        v_model = JuMP.variable_by_name(model, v_name)  # get the new value from the JuMP model.
        push!(cmp_terms, v_coeff*JuMP.value(v_model))   # multiply the value obtained with the corresponding coefficient - add to vector of computed terms
    end

    return sum(cmp_terms) # sum all the computed terms (coeff*value) - return the value
end

""
function build_solution_values(model::JuMP.Model, var::JuMP.NonlinearExpression)
    var_terms = var.terms           # Get variable terms OrderedDict: (var => coeff)
    var_keys = keys(var.terms)      # Get the JuMP.VariableRef as keys
    var_vector = collect(var_keys)  # Collect the JuMP.VariableRef keys in a vector

    cmp_terms = []              # vector used to store the final computed terms (i.e., coeff*value)
    for v in var_vector
        v_name = string(v)      # convert JuMP.VariableRef to string (for searching the value in the model)
        v_coeff = var_terms[v]  # get the coefficient from the OrderedDict of var_terms
        v_model = JuMP.variable_by_name(model, v_name)  # get the new value from the JuMP model.
        push!(cmp_terms, v_coeff*JuMP.value(v_model))   # multiply the value obtained with the corresponding coefficient - add to vector of computed terms
    end

    return sum(cmp_terms) # sum all the computed terms (coeff*value) - return the value
end

""
function build_solution_values(model::JuMP.Model, var::JuMP.ConstraintRef)
    return JuMP.dual(var)
end

""
function build_solution_values(var::Any)
    @warn("build_solution_values found unknown type $(typeof(var))")
    return var
end

# ---------------------------------------------------------------------------------

"""
    function _transform_decomposition_solution_to_pu!(
        result,
        pmitd_data::Dict{String,<:Any};
        make_si::Bool=false,
        multinetwork::Bool=false,
        solution_model::String="eng"
    )

Transforms the decomposition PM and PMD solutions from SI units to per-unit (pu), and the PMD solution from MATH back to ENG model.
"""
function _transform_decomposition_solution_to_pu!(result, pmitd_data::Dict{String,<:Any}; make_si::Bool=false, multinetwork::Bool=false, solution_model::String="eng")

    if multinetwork
        # Transmission system
        for (nw, nw_pm) in pmitd_data["it"][_PM.pm_it_name]["nw"]
            result["solution"]["it"][_PM.pm_it_name]["solution"]["nw"][nw]["baseMVA"] = nw_pm["baseMVA"]
        end

        # Distribution system
        for (ckt_name, ckt_data) in pmitd_data["it"][_PMD.pmd_it_name]
            for (nw, nw_pmd) in pmitd_data["it"][_PMD.pmd_it_name][ckt_name]["nw"]
                result["solution"]["it"][_PMD.pmd_it_name][ckt_name]["nw"][nw]["settings"] = nw_pmd["settings"]
                result["solution"]["it"][_PMD.pmd_it_name][ckt_name]["nw"][nw]["per_unit"] = pmitd_data["it"][_PMD.pmd_it_name][ckt_name]["nw"][nw]["per_unit"]
            end
        end

    else
        # Transmission system
        result["solution"]["it"][_PM.pm_it_name]["solution"]["baseMVA"] = pmitd_data["it"][_PM.pm_it_name]["baseMVA"]
        # Distribution system
        for (ckt_name, ckt_data) in pmitd_data["it"][_PMD.pmd_it_name]
            result["solution"]["it"][_PMD.pmd_it_name][ckt_name]["settings"] = pmitd_data["it"][_PMD.pmd_it_name][ckt_name]["settings"]
            result["solution"]["it"][_PMD.pmd_it_name][ckt_name]["per_unit"] = pmitd_data["it"][_PMD.pmd_it_name][ckt_name]["per_unit"]
        end
    end

    # per unit specification
    result["solution"]["it"][_PM.pm_it_name]["solution"]["per_unit"] = pmitd_data["it"][_PM.pm_it_name]["per_unit"]

    # Make per unit
    _PM.make_per_unit!(result["solution"]["it"][_PM.pm_it_name]["solution"])

    # Convert to ENG or MATH models
    if (solution_model=="eng") || (solution_model=="ENG")

        for (ckt_name, ckt_data) in pmitd_data["it"][_PMD.pmd_it_name]
            # Transform pmd MATH result to ENG
            result["solution"]["it"][_PMD.pmd_it_name][ckt_name]["solution"] = _PMD.transform_solution(
                result["solution"]["it"][_PMD.pmd_it_name][ckt_name]["solution"],
                pmitd_data["it"][_PMD.pmd_it_name][ckt_name];
                make_si=make_si
            )

            # Change PMD dictionary per_unit value (Not done automatically by PMD)
            result["solution"]["it"][_PMD.pmd_it_name][ckt_name]["solution"]["per_unit"] = true
        end

        # Transform pmitd MATH result ref to ENG result ref
        transform_pmitd_decomposition_solution_to_eng!(result, pmitd_data)

    elseif !(solution_model=="eng") && !(solution_model=="ENG") && !(solution_model=="math") && !(solution_model=="MATH")
        @error "The solution_model $(solution_model) does not exists, please input 'eng' or 'math'"
        throw(error())
    end

end


"""
    function _transform_decomposition_solution_to_si!(
        result,
        pmitd_data::Dict{String,<:Any};
        make_si::Bool=true,
        multinetwork::Bool=false,
        solution_model::String="eng"
    )

Transforms the decomposition PM and PMD solutions from per-unit (pu) to SI units, and the PMD solution from MATH back to ENG model.
"""
function _transform_decomposition_solution_to_si!(result, pmitd_data::Dict{String,<:Any}; make_si::Bool=true, multinetwork::Bool=false, solution_model::String="eng")

    if multinetwork
        # Transmission system
        for (nw, nw_pm) in pmitd_data["it"][_PM.pm_it_name]["nw"]
            result["solution"]["it"][_PM.pm_it_name]["solution"]["nw"][nw]["baseMVA"] = nw_pm["baseMVA"]
        end

        # Distribution system
        for (ckt_name, ckt_data) in pmitd_data["it"][_PMD.pmd_it_name]
            for (nw, nw_pmd) in pmitd_data["it"][_PMD.pmd_it_name][ckt_name]["nw"]
                result["solution"]["it"][_PMD.pmd_it_name][ckt_name]["nw"][nw]["settings"] = nw_pmd["settings"]
                result["solution"]["it"][_PMD.pmd_it_name][ckt_name]["nw"][nw]["per_unit"] = pmitd_data["it"][_PMD.pmd_it_name][ckt_name]["nw"][nw]["per_unit"]
            end
        end

    else
        # Transmission system
        result["solution"]["it"][_PM.pm_it_name]["solution"]["baseMVA"] = pmitd_data["it"][_PM.pm_it_name]["baseMVA"]
        # Distribution system
        for (ckt_name, ckt_data) in pmitd_data["it"][_PMD.pmd_it_name]
            result["solution"]["it"][_PMD.pmd_it_name][ckt_name]["settings"] = pmitd_data["it"][_PMD.pmd_it_name][ckt_name]["settings"]
            result["solution"]["it"][_PMD.pmd_it_name][ckt_name]["per_unit"] = pmitd_data["it"][_PMD.pmd_it_name][ckt_name]["per_unit"]
        end
    end

    # per unit specification
    result["solution"]["it"][_PM.pm_it_name]["solution"]["per_unit"] = pmitd_data["it"][_PM.pm_it_name]["per_unit"]

    # Make transmission system mixed units (not per unit)
    _PM.make_mixed_units!(result["solution"]["it"][_PM.pm_it_name]["solution"])

    # Transform pmitd solution to PMD SI
    _transform_pmitd_decomposition_solution_to_si!(result)

    # Convert to ENG or MATH models
    if (solution_model=="eng") || (solution_model=="ENG")

        for (ckt_name, ckt_data) in pmitd_data["it"][_PMD.pmd_it_name]
            # Transform pmd MATH result to ENG
            result["solution"]["it"][_PMD.pmd_it_name][ckt_name]["solution"] = _PMD.transform_solution(
                result["solution"]["it"][_PMD.pmd_it_name][ckt_name]["solution"],
                pmitd_data["it"][_PMD.pmd_it_name][ckt_name];
                make_si=make_si
            )

            # Change PMD dictionary per_unit value (Not done automatically by PMD)
            result["solution"]["it"][_PMD.pmd_it_name][ckt_name]["solution"]["per_unit"] = false
        end

        # Transform pmitd MATH result ref to ENG result ref
        transform_pmitd_decomposition_solution_to_eng!(result, pmitd_data)

    elseif (solution_model=="math") || (solution_model=="MATH")

        for (ckt_name, ckt_data) in pmitd_data["it"][_PMD.pmd_it_name]
            result["solution"]["it"][_PMD.pmd_it_name][ckt_name]["solution"] = _PMD.solution_make_si(
                result["solution"]["it"][_PMD.pmd_it_name][ckt_name]["solution"],
                pmitd_data["it"][_PMD.pmd_it_name][ckt_name]
            )
        end

    elseif !(solution_model=="eng") && !(solution_model=="ENG") && !(solution_model=="math") && !(solution_model=="MATH")
        @error "The solution_model $(solution_model) does not exists, please input 'eng' or 'math'"
        throw(error())
    end

end


"""
    function _transform_pmitd_decomposition_solution_to_si!(
        result::Dict{String,<:Any}
    )

Transforms the decomposition PMITD solution from per-unit (pu) to SI units.
"""
function _transform_pmitd_decomposition_solution_to_si!(result::Dict{String,<:Any})

    # Obtain rhe solution from result
    solution = result["solution"]["it"]

    # Check for multinetwork
    if haskey(solution[pmitd_it_name], "nw")
        nws_data = solution[pmitd_it_name]["nw"]
        pmd_sbase = solution[_PMD.pmd_it_name]["nw"]["1"]["settings"]["sbase"] # get sbase from pmd
    else # TODO: Only works when all ckts have the same base, otherwise needs modifications
        nws_data = Dict("0" => solution[pmitd_it_name])
        for (ckt_name, ckt_data) in solution[_PMD.pmd_it_name]
            pmd_sbase = solution[_PMD.pmd_it_name][ckt_name]["settings"]["sbase"] # get sbase from pmd
        end
    end

    # Scale respective pmitd boundary
    for (n, nw_data) in nws_data
        if haskey(nw_data, "boundary")
            for (i,boundary) in nw_data["boundary"]
                if haskey(boundary, "pbound_load")
                    boundary["pbound_load"] = boundary["pbound_load"]*pmd_sbase
                end
                if haskey(boundary, "qbound_load")
                    boundary["qbound_load"] = boundary["qbound_load"]*pmd_sbase
                end
                if haskey(boundary, "pbound_aux")
                    boundary["pbound_aux"] = boundary["pbound_aux"].*pmd_sbase
                end
                if haskey(boundary, "qbound_aux")
                    boundary["qbound_aux"] = boundary["qbound_aux"].*pmd_sbase
                end
            end
        end
    end

end


"""
    function transform_pmitd_decomposition_solution_to_eng!(
        result::Dict{String,<:Any},
        pmitd_data::Dict{String,<:Any}
    )

Transforms the decomposition PMITD solution from MATH to ENG model. This transformation
facilitates the conversion in pmitd_it_name of buses numbers to buses names according to
the ENG model. Ex: (100002, 9, 6) -> (100002, voltage_source.3bus_unbal_nogen_mn_2.source, 6)
"""
function transform_pmitd_decomposition_solution_to_eng!(result::Dict{String,<:Any}, pmitd_data::Dict{String,<:Any})

    # get solutions
    pmitd_sol = result["solution"]["it"][pmitd_it_name]

    # Check for multinetwork and get dictionaries with all buses
    if haskey(pmitd_sol, "nw")
        pmitd_sol_data = pmitd_sol["nw"]
    else
        pmitd_sol_data = Dict("0" => pmitd_sol)
    end

    # create empty dict that will replace the math dict in pmitd_sol
    pmitd_sol_boundary_eng = Dict{String, Any}()

    # loop through nw
    for (nw, nw_sol_data) in pmitd_sol_data

        # get trans. buses depending on mn parameter
        if nw == "0"
            tran_buses = pmitd_data["it"][_PM.pm_it_name]["bus"]
        else
            tran_buses = pmitd_data["it"][_PM.pm_it_name]["nw"][nw]["bus"]
        end

        for (boundary_num, boundary_data) in nw_sol_data["boundary"]

            # parse tuple from string
            boundary_num = eval(Meta.parse(boundary_num))

            # transmission & distribution
            if (haskey(boundary_data, "pbound_load"))
                tran_bus = tran_buses[findfirst(x -> boundary_num[2] == x["bus_i"], tran_buses)]
                tran_bus_name = tran_bus["source_id"][2]

                # get distribution bus name
                dist_bus_name = ""
                for (_, ckt_data) in pmitd_data["it"][_PMD.pmd_it_name]
                    pmd_key = collect(keys(ckt_data["pmitd"]))
                    if (pmd_key[1] == string(boundary_num[1]))

                        # get dist. buses depending on mn parameter
                        if nw == "0"
                            dist_buses = ckt_data["bus"]
                        else
                            dist_buses = ckt_data["nw"][nw]["bus"]
                        end

                        dist_bus = dist_buses[findfirst(x -> boundary_num[3] == x["bus_i"], dist_buses)]
                        dist_bus_name = dist_bus["source_id"]
                    end
                end

                # create new name and add it to solution dict.
                new_name = "("* string(boundary_num[1]) * ", " * string(tran_bus_name) * ", " * dist_bus_name * ")"
                pmitd_sol_boundary_eng[new_name] = boundary_data
            end
        end
        # add data to replace to result
        pmitd_sol_data[string(nw)]["boundary"] = deepcopy(pmitd_sol_boundary_eng)
    end
end
