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

    for pmd in pmitd.pmd
        for (_, boundary_data) in pmd.data[pmitd_it_name]

            ckt_name = boundary_data["ckt_name"]
            result["solution"]["it"][_PMD.pmd_it_name][ckt_name] = _IM.build_result(pmd, solve_time)

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

        ## TODO
        # # Transform pmitd MATH result ref to ENG result ref
        # transform_pmitd_solution_to_eng!(result, pmitd_data)

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

        # # TODO
        # # Transform pmitd MATH result ref to ENG result ref
        # transform_pmitd_decomposition_solution_to_eng!(result, pmitd_data)

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

# # TODO
# """
#     function transform_pmitd_decomposition_solution_to_eng!(
#         result::Dict{String,<:Any},
#         pmitd_data::Dict{String,<:Any}
#     )

# Transforms the decomposition PMITD solution from MATH to ENG model. This transformation
# facilitates the conversion in pmitd_it_name of buses numbers to buses names according to
# the ENG model. Ex: (100002, 9, 6) -> (100002, voltage_source.3bus_unbal_nogen_mn_2.source, 6)
# """
# function transform_pmitd_decomposition_solution_to_eng!(result::Dict{String,<:Any}, pmitd_data::Dict{String,<:Any})

#     # get solutions
#     pmitd_sol = result["solution"]["it"][pmitd_it_name]

#     # Check for multinetwork and get dictionaries with all buses
#     if haskey(pmitd_sol, "nw")
#         pmitd_sol_data = pmitd_sol["nw"]
#     else
#         pmitd_sol_data = Dict("0" => pmitd_sol)
#     end

#     # create empty dict that will replace the math dict in pmitd_sol
#     pmitd_sol_boundary_eng = Dict{String, Any}()

#     # loop through nw
#     for (nw, nw_sol_data) in pmitd_sol_data

#         # get tran. & dist. buses depending on mn parameter
#         if nw == "0"
#             tran_buses, dist_buses = pmitd_data["it"][_PM.pm_it_name]["bus"], pmitd_data["it"][_PMD.pmd_it_name]["bus"]
#         else
#             tran_buses, dist_buses = pmitd_data["it"][_PM.pm_it_name]["nw"][nw]["bus"], pmitd_data["it"][_PMD.pmd_it_name]["nw"][nw]["bus"]
#         end

#         for (boundary_num, boundary_data) in nw_sol_data["boundary"]

#             # parse tuple from string
#             boundary_num = eval(Meta.parse(boundary_num))

#             # transmission
#             if (haskey(boundary_data, "pbound_fr") || haskey(boundary_data, "crbound_fr"))
#                 tran_bus = tran_buses[findfirst(x -> boundary_num[2] == x["bus_i"], tran_buses)]
#                 tran_bus_name = tran_bus["source_id"][2]

#                 dist_bus = dist_buses[findfirst(x -> boundary_num[3] == x["bus_i"], dist_buses)]
#                 dist_bus_name = dist_bus["source_id"]

#                 new_name = "("* string(boundary_num[1]) * ", " * string(tran_bus_name) * ", " * dist_bus_name * ")"
#                 pmitd_sol_boundary_eng[new_name] = boundary_data
#             end

#             # distribution
#             if (haskey(boundary_data, "pbound_to") || haskey(boundary_data, "crbound_to"))
#                 dist_bus = dist_buses[findfirst(x -> boundary_num[2] == x["bus_i"], dist_buses)]
#                 dist_bus_name = dist_bus["source_id"]

#                 tran_bus = tran_buses[findfirst(x -> boundary_num[3] == x["bus_i"], tran_buses)]
#                 tran_bus_name = tran_bus["source_id"][2]

#                 new_name = "("* string(boundary_num[1]) * ", " * dist_bus_name * ", " * string(tran_bus_name) * ")"
#                 pmitd_sol_boundary_eng[new_name] = boundary_data
#             end
#         end

#         # add data to replace to result
#         pmitd_sol_data[string(nw)]["boundary"] = deepcopy(pmitd_sol_boundary_eng)

#     end

# end
