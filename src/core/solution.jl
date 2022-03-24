# This file contains useful transformation functions for the solutions (SI or pu)

"""
    function _transform_solution_to_pu!(
        result,
        pmitd_data::Dict{String,<:Any};
        make_si::Bool=false,
        multinetwork::Bool=false
    )

Transforms the PM and PMD solutions from SI units to per-unit (pu), and the PMD solution from MATH back to ENG model.
"""
function _transform_solution_to_pu!(result, pmitd_data::Dict{String,<:Any}; make_si::Bool=false, multinetwork::Bool=false)

    if multinetwork
        # Transmission system
        for (nw, nw_pm) in pmitd_data["it"][_PM.pm_it_name]["nw"]
            result["solution"]["it"][_PM.pm_it_name]["nw"][nw]["baseMVA"] = nw_pm["baseMVA"]
        end

        # Distribution system
        for (nw, nw_pmd) in pmitd_data["it"][_PMD.pmd_it_name]["nw"]
            result["solution"]["it"][_PMD.pmd_it_name]["nw"][nw]["settings"] = nw_pmd["settings"]
            result["solution"]["it"][_PMD.pmd_it_name]["nw"][nw]["per_unit"] = pmitd_data["it"][_PMD.pmd_it_name]["nw"][nw]["per_unit"]
        end

    else
        # Transmission system
        result["solution"]["it"][_PM.pm_it_name]["baseMVA"] = pmitd_data["it"][_PM.pm_it_name]["baseMVA"]
        # Distribution system
        result["solution"]["it"][_PMD.pmd_it_name]["settings"] = pmitd_data["it"][_PMD.pmd_it_name]["settings"]
        result["solution"]["it"][_PMD.pmd_it_name]["per_unit"] = pmitd_data["it"][_PMD.pmd_it_name]["per_unit"]
    end

    # per unit specification
    result["solution"]["it"][_PM.pm_it_name]["per_unit"] = pmitd_data["it"][_PM.pm_it_name]["per_unit"]

    # Make mixed units (not per unit)
    _PM.make_per_unit!(result["solution"]["it"][_PM.pm_it_name])

    # Transform pmd MATH result to ENG
    result["solution"]["it"][_PMD.pmd_it_name] = _PMD.transform_solution(
        result["solution"]["it"][_PMD.pmd_it_name],
        pmitd_data["it"][_PMD.pmd_it_name];
        make_si=make_si
    )

    # change PMD dictionary per_unit value (Not done automatically by PMD)
    result["solution"]["it"][_PMD.pmd_it_name]["per_unit"] = true

end


"""
    function _transform_solution_to_si!(
        result,
        pmitd_data::Dict{String,<:Any};
        make_si::Bool=true,
        multinetwork::Bool=false
    )

Transforms the PM and PMD solutions from per-unit (pu) to SI units, and the PMD solution from MATH back to ENG model.
"""
function _transform_solution_to_si!(result, pmitd_data::Dict{String,<:Any}; make_si::Bool=true, multinetwork::Bool=false)

    if multinetwork
        # Transmission system
        for (nw, nw_pm) in pmitd_data["it"][_PM.pm_it_name]["nw"]
            result["solution"]["it"][_PM.pm_it_name]["nw"][nw]["baseMVA"] = nw_pm["baseMVA"]
        end

        # Distribution system
        for (nw, nw_pmd) in pmitd_data["it"][_PMD.pmd_it_name]["nw"]
            result["solution"]["it"][_PMD.pmd_it_name]["nw"][nw]["settings"] = nw_pmd["settings"]
            result["solution"]["it"][_PMD.pmd_it_name]["nw"][nw]["per_unit"] = pmitd_data["it"][_PMD.pmd_it_name]["nw"][nw]["per_unit"]
        end

    else
        # Transmission system
        result["solution"]["it"][_PM.pm_it_name]["baseMVA"] = pmitd_data["it"][_PM.pm_it_name]["baseMVA"]
        # Distribution system
        result["solution"]["it"][_PMD.pmd_it_name]["settings"] = pmitd_data["it"][_PMD.pmd_it_name]["settings"]
        result["solution"]["it"][_PMD.pmd_it_name]["per_unit"] = pmitd_data["it"][_PMD.pmd_it_name]["per_unit"]
    end

    # per unit specification
    result["solution"]["it"][_PM.pm_it_name]["per_unit"] = pmitd_data["it"][_PM.pm_it_name]["per_unit"]

    # Make transmission system mixed units (not per unit)
    _PM.make_mixed_units!(result["solution"]["it"][_PM.pm_it_name])

    # Transform pmd MATH result to ENG
    result["solution"]["it"][_PMD.pmd_it_name] = _PMD.transform_solution(
        result["solution"]["it"][_PMD.pmd_it_name],
        pmitd_data["it"][_PMD.pmd_it_name];
        make_si=make_si
    )

    # Transform pmitd solution to PMD SI
    _transform_pmitd_solution_to_si!(result)

end


"""
    function _transform_pmitd_solution_to_si!(
        result::Dict{String,<:Any}
    )

Transforms the PMITD solution from per-unit (pu) to SI units.
"""
function _transform_pmitd_solution_to_si!(result::Dict{String,<:Any})

    # Obtain rhe solution from result
    solution = result["solution"]["it"]

    # Check for multinetwork
    if haskey(solution[pmitd_it_name], "nw")
        nws_data = solution[pmitd_it_name]["nw"]
        pmd_sbase = solution[_PMD.pmd_it_name]["nw"]["1"]["settings"]["sbase"] # get sbase from pmd
    else
        nws_data = Dict("0" => solution[pmitd_it_name])
        pmd_sbase = solution[_PMD.pmd_it_name]["settings"]["sbase"] # get sbase from pmd
    end

    # Scale respective pmitd boundary
    for (n, nw_data) in nws_data
        if haskey(nw_data, "boundary")
            for (i,boundary) in nw_data["boundary"]
                if haskey(boundary, "pbound_fr")
                    boundary["pbound_fr"] = boundary["pbound_fr"]*pmd_sbase
                end
                if haskey(boundary, "qbound_fr")
                    boundary["qbound_fr"] = boundary["qbound_fr"]*pmd_sbase
                end
                if haskey(boundary, "pbound_to")
                    boundary["pbound_to"] = boundary["pbound_to"].*pmd_sbase
                end
                if haskey(boundary, "qbound_to")
                    boundary["qbound_to"] = boundary["qbound_to"].*pmd_sbase
                end
            end
        end
    end

end


"""
    function sol_data_model!(
        pmitd::AbstractPowerModelITD,
        solution::Dict{String,<:Any}
    )

solution_processor to convert the solution(s) to polar voltage magnitudes and angles.
"""
function sol_data_model!(pmitd::AbstractPowerModelITD, solution::Dict{String,<:Any})

    # Get Models
    pm_model = _get_powermodel_from_powermodelitd(pmitd)
    pmd_model = _get_powermodeldistribution_from_powermodelitd(pmitd)

    _PM.sol_data_model!(pm_model, solution["it"][_PM.pm_it_name]) # convert transmission system solution
    _PMD.sol_data_model!(pmd_model, solution["it"][_PMD.pmd_it_name]) # convert distribution system solution.

end
