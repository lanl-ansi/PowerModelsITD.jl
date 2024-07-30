# This file contains useful transformation functions for the solutions (SI or pu) - Decomposition

"""
    function build_pm_decomposition_solution(
        pm,
        solve_time
    )

Runs decomposition process and returns organized result solution dictionary.
"""
function build_pm_decomposition_solution(pm, solve_time::Float64=0.0)

    # Build and organize the result dictionary
    result = Dict{String, Any}("solution" => Dict{String, Any}("it" => Dict{String, Any}(_PM.pm_it_name => Dict{String, Any}(), pmitd_it_name => Dict{String, Any}())))
    result["solution"]["it"][_PM.pm_it_name] = _IM.build_result(pm, solve_time)
    result["solution"]["it"][pmitd_it_name]["boundary"] = result["solution"]["it"][_PM.pm_it_name]["solution"]["boundary"]

    return result
end


function build_pmd_decomposition_solution(pmd, solve_time::Float64=0.0)

    # Build and organize the result dictionary
    result = Dict{String, Any}("solution" => Dict{String, Any}("it" => Dict{String, Any}(_PMD.pmd_it_name => Dict{String, Any}(), pmitd_it_name => Dict{String, Any}())))
    result["solution"]["it"][_PMD.pmd_it_name] = _IM.build_result(pmd, solve_time)
    result["solution"]["it"][pmitd_it_name]["boundary"] = result["solution"]["it"][_PMD.pmd_it_name]["solution"]["boundary"]

    return result
end


# ----------------- Custom-made parallelize multiprocessing function ------------------------
# TODO: Move this function to its own file
# TODO: add export_models=true option to export models
function optimize_subproblem_multiprocessing(
    data::Dict{String, Any},
    type,
    build_method,
    status_signal::Distributed.RemoteChannel,
    mp_string_rc::Distributed.RemoteChannel,
    sp_string_rc::Distributed.RemoteChannel,
    i::Int,
    number_of_subprobs::Int
)

    # Instantiate the PMD model
    subproblem_instantiated = _IM.instantiate_model(data,
                                    type,
                                    build_method,
                                    ref_add_core_decomposition_distribution!,
                                    _PMD._pmd_global_keys,
                                    _PMD.pmd_it_sym
    )


    # Set the optimizer to the instantiated subproblem JuMP model
    JuMP.set_optimizer(subproblem_instantiated.model, _SDO.Optimizer; add_bridges = true)

    # Assign the type of the problem
    subproblem_instantiated.model.moi_backend.optimizer.model.type = "Subproblem"

    # Obtain ckt boundary data
    boundary_number = first(keys(data[pmitd_it_name]))
    # Get vector of boundary linking vars
    subprob_linking_vars_vector = generate_boundary_linking_vars_distribution(subproblem_instantiated, boundary_number)
    # Assign the list of linking vars
    subproblem_instantiated.model.moi_backend.optimizer.model.list_linking_vars = [subprob_linking_vars_vector]

    # Setup and initilize the subproblem
    JuMP.optimize!(subproblem_instantiated.model) # Setup the Subproblem model

    # Solve the subproblem
    _SDO.solve_subproblem!(subproblem_instantiated.model,
                        status_signal,
                        mp_string_rc,
                        sp_string_rc,
                        i,
                        number_of_subprobs
    )

    # Build, transform, and write result to file
    result = build_pmd_decomposition_solution(subproblem_instantiated)

    result_json = JSON.json(result)
    open("subproblem_$(i)_boundary_$(boundary_number).txt", "w") do file
        write(file, result_json)
    end

    # Close RemoteChannels
    close(status_signal)
    close(mp_string_rc)
    close(sp_string_rc)

    # Clean everything before leaving process
    GC.gc()

end

### ------ Transform solution functions -----

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
            result["solution"]["it"][_PMD.pmd_it_name][ckt_name] = _PMD.transform_solution(
                result["solution"]["it"][_PMD.pmd_it_name][ckt_name],
                pmitd_data["it"][_PMD.pmd_it_name][ckt_name];
                make_si=make_si
            )

            # Change PMD dictionary per_unit value (Not done automatically by PMD)
            result["solution"]["it"][_PMD.pmd_it_name][ckt_name]["per_unit"] = true
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
            result["solution"]["it"][_PMD.pmd_it_name][ckt_name] = _PMD.transform_solution(
                result["solution"]["it"][_PMD.pmd_it_name][ckt_name],
                pmitd_data["it"][_PMD.pmd_it_name][ckt_name];
                make_si=make_si
            )

            # Change PMD dictionary per_unit value (Not done automatically by PMD)
            result["solution"]["it"][_PMD.pmd_it_name][ckt_name]["per_unit"] = false
        end

        # Transform pmitd MATH result ref to ENG result ref
        transform_pmitd_decomposition_solution_to_eng!(result, pmitd_data)

    elseif (solution_model=="math") || (solution_model=="MATH")

        for (ckt_name, ckt_data) in pmitd_data["it"][_PMD.pmd_it_name]
            result["solution"]["it"][_PMD.pmd_it_name][ckt_name] = _PMD.solution_make_si(
                result["solution"]["it"][_PMD.pmd_it_name][ckt_name],
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
                if haskey(boundary, "pbound_load_scaled")
                    boundary["pbound_load_scaled"] = boundary["pbound_load_scaled"]*pmd_sbase
                end
                if haskey(boundary, "qbound_load_scaled")
                    boundary["qbound_load_scaled"] = boundary["qbound_load_scaled"]*pmd_sbase
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
