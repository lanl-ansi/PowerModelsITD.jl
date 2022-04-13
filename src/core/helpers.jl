"""
    function _get_powermodel_from_powermodelitd(
        pm::AbstractPowerModelITD
    )

Gets the PM model from the PMITD model structure.
"""
function _get_powermodel_from_powermodelitd(pm::AbstractPowerModelITD)
    # Determine the PowerModels modeling type.
    pm_type = typeof(pm).parameters[1]

    # Power transmission-only variables and constraints.
    return pm_type(pm.model, pm.data, pm.setting, pm.solution,
        pm.ref, pm.var, pm.con, pm.sol, pm.sol_proc, pm.ext)
end


"""
    function _get_powermodeldistribution_from_powermodelitd(
        pmd::AbstractPowerModelITD
    )

Gets the PMD model from the PMITD model structure.
"""
function _get_powermodeldistribution_from_powermodelitd(pmd::AbstractPowerModelITD)
    # Determine the PowerModelsDistribution modeling type.
    pmd_type = typeof(pmd).parameters[2]

    # Power distribution-only variables and constraints.
    return pmd_type(pmd.model, pmd.data, pmd.setting, pmd.solution,
        pmd.ref, pmd.var, pmd.con, pmd.sol, pmd.sol_proc, pmd.ext)
end


"""
    function _rename_components!(
        pmd_base::Dict{String,<:Any},
        data::Dict{String,<:Any}
    )

Renames the components given in `data` for new multi-system and adds the renamed components
to `pmd_base` dictionary structure. cktname.element
"""
function _rename_components!(pmd_base::Dict{String,<:Any}, data::Dict{String,<:Any})

    # Check if multinetwork
    if haskey(pmd_base, "nw")
        for (nw, mn_data) in data["nw"]
            _rename_network_components!(pmd_base["nw"][nw], mn_data)
        end
    else
        _rename_network_components!(pmd_base, data)
    end

end


function _check_and_rename_circuits!(pmd_base::Dict{String,<:Any}, data::Dict{String,<:Any}; auto_rename::Bool=false, ms_num::Int=1)

    # check that data ckt name is not repeating, throw error if it is
    if (data["name"] in pmd_base["ckt_names"])
        if (auto_rename==false)
            error("Distribution systems have same circuit names! Please use different names for each distribution system. (e.g., New Circuit.NameOfCkt) or use the auto_rename=true option.")
        else
            data["name"] = data["name"] * "_" * string(ms_num)
        end
    end

     # add circuit name to pmd_base["ckt_names"]
     push!(pmd_base["ckt_names"], data["name"])

end


function _correct_boundary_names!(pmitd_data::Dict{String,<:Any})

    @warn "auto_rename option is true, so boundary names in `pmitd=>` will be overwritten sequentially and may not represent actual wanted boundary connection."

    first_boundary = true
    for (boundary, name) in zip(pmitd_data["it"][pmitd_it_name], pmitd_data["it"][_PMD.pmd_it_name]["ckt_names"])
        if !first_boundary
            # rearrange the name of bus if more than 1 ckts
            old_dist_bus_name_vector = split(boundary[2]["distribution_boundary"], ".")
            if (length(old_dist_bus_name_vector)>2)
                boundary[2]["distribution_boundary"] = name * "." * old_dist_bus_name_vector[2] * "." * old_dist_bus_name_vector[3]
            else
                boundary[2]["distribution_boundary"] = name * "." * old_dist_bus_name_vector[1] * "." * old_dist_bus_name_vector[2]
            end
        end
        first_boundary = false
    end

end



"""
    function _rename_network_components!(
        pmd_base::Dict{String,<:Any},
        data::Dict{String,<:Any}
    )

Rename specific components in single network dictionary. `pmd_base` is the dictionary where the renamed
components are to be added, `data` is the dictionary containing the components to be renamed.
"""
# rename specific components in single network dictionary
function _rename_network_components!(pmd_base::Dict{String,<:Any}, data::Dict{String,<:Any})

    # loop through buses
    if (haskey(data, "bus"))
        for (key, value) in data["bus"]
            new_key = data["name"] * "." * key
            # if key does not exists in pmd_base, add an empty Dict
            if !(haskey(pmd_base, "bus"))
                pmd_base["bus"] = Dict()
            end
            pmd_base["bus"][new_key] = value
        end
    end

    # loop through lines
    if (haskey(data, "line"))
        for (key, value) in data["line"]
            new_key = data["name"] * "." * key
            # if key does not exists in pmd_base, add an empty Dict
            if !(haskey(pmd_base, "line"))
                pmd_base["line"] = Dict()
            end
            pmd_base["line"][new_key] = value
            pmd_base["line"][new_key]["source_id"] = data["name"] * "." * pmd_base["line"][new_key]["source_id"]
            pmd_base["line"][new_key]["f_bus"] = data["name"] * "." * pmd_base["line"][new_key]["f_bus"]
            pmd_base["line"][new_key]["t_bus"] = data["name"] * "." * pmd_base["line"][new_key]["t_bus"]
            if (haskey(pmd_base["line"][new_key], "linecode"))
                pmd_base["line"][new_key]["linecode"] = data["name"] * "." * pmd_base["line"][new_key]["linecode"]
            end
        end
    end

    # loop through switch
    if (haskey(data, "switch"))
        for (key, value) in data["switch"]
            new_key = data["name"] * "." * key
            # if key does not exists in pmd_base, add an empty Dict
            if !(haskey(pmd_base, "switch"))
                pmd_base["switch"] = Dict()
            end
            pmd_base["switch"][new_key] = value
            pmd_base["switch"][new_key]["source_id"] = data["name"] * "." * pmd_base["switch"][new_key]["source_id"]
            pmd_base["switch"][new_key]["f_bus"] = data["name"] * "." * pmd_base["switch"][new_key]["f_bus"]
            pmd_base["switch"][new_key]["t_bus"] = data["name"] * "." * pmd_base["switch"][new_key]["t_bus"]
            if (haskey(pmd_base["switch"][new_key], "linecode"))
                pmd_base["switch"][new_key]["linecode"] = data["name"] * "." * pmd_base["switch"][new_key]["linecode"]
            end
        end
    end

    # loop through transformer
    if (haskey(data, "transformer"))
        for (key, value) in data["transformer"]
            new_key = data["name"] * "." * key
            # if key does not exists in pmd_base, add an empty Dict
            if !(haskey(pmd_base, "transformer"))
                pmd_base["transformer"] = Dict()
            end
            pmd_base["transformer"][new_key] = value
            pmd_base["transformer"][new_key]["source_id"] = data["name"] * "." * pmd_base["transformer"][new_key]["source_id"]
            pmd_base["transformer"][new_key]["bus"][1] = data["name"] * "." * pmd_base["transformer"][new_key]["bus"][1]
            pmd_base["transformer"][new_key]["bus"][2] = data["name"] * "." * pmd_base["transformer"][new_key]["bus"][2]
        end
    end

    # loop through load
    if (haskey(data, "load"))
        for (key, value) in data["load"]
            new_key = data["name"] * "." * key
            # if key does not exists in pmd_base, add an empty Dict
            if !(haskey(pmd_base, "load"))
                pmd_base["load"] = Dict()
            end
            pmd_base["load"][new_key] = value
            pmd_base["load"][new_key]["source_id"] = data["name"] * "." * pmd_base["load"][new_key]["source_id"]
            pmd_base["load"][new_key]["bus"] = data["name"] * "." * pmd_base["load"][new_key]["bus"]
        end
    end

    # loop through linecode
    if (haskey(data, "linecode"))
        for (key, value) in data["linecode"]
            new_key = data["name"] * "." * key
            # if key does not exists in pmd_base, add an empty Dict
            if !(haskey(pmd_base, "linecode"))
                pmd_base["linecode"] = Dict()
            end
            pmd_base["linecode"][new_key] = value
        end
    end

    # loop through voltage_sources
    if (haskey(data, "voltage_source"))
        for (key, value) in data["voltage_source"]
            new_key = data["name"] * "." * key
             # if key does not exists in pmd_base, add an empty Dict
             if !(haskey(pmd_base, "voltage_source"))
                pmd_base["voltage_source"] = Dict()
            end
            pmd_base["voltage_source"][new_key] = value
            pmd_base["voltage_source"][new_key]["source_id"] = data["name"] * "." * pmd_base["voltage_source"][new_key]["source_id"]
            pmd_base["voltage_source"][new_key]["bus"] = data["name"] * "." * pmd_base["voltage_source"][new_key]["bus"]
        end
    end

    # loop through generators
    if (haskey(data, "generator"))
        for (key, value) in data["generator"]
            new_key = data["name"] * "." * key
            # if key does not exists in pmd_base, add an empty Dict
            if !(haskey(pmd_base, "generator"))
                pmd_base["generator"] = Dict()
            end
            pmd_base["generator"][new_key] = value
            pmd_base["generator"][new_key]["source_id"] = data["name"] * "." * pmd_base["generator"][new_key]["source_id"]
            pmd_base["generator"][new_key]["bus"] = data["name"] * "." * pmd_base["generator"][new_key]["bus"]
        end
    end

    # loop through shunts
    if (haskey(data, "shunt"))
        for (key, value) in data["shunt"]
            new_key = data["name"] * "." * key
            # if key does not exists in pmd_base, add an empty Dict
            if !(haskey(pmd_base, "shunt"))
                pmd_base["shunt"] = Dict()
            end
            pmd_base["shunt"][new_key] = value
            pmd_base["shunt"][new_key]["source_id"] = data["name"] * "." * pmd_base["shunt"][new_key]["source_id"]
            pmd_base["shunt"][new_key]["bus"] = data["name"] * "." * pmd_base["shunt"][new_key]["bus"]
        end
    end

    # loop through solar PV systems
    if (haskey(data, "solar"))
        for (key, value) in data["solar"]
            new_key = data["name"] * "." * key
            # if key does not exists in pmd_base, add an empty Dict
            if !(haskey(pmd_base, "solar"))
                pmd_base["solar"] = Dict()
            end
            pmd_base["solar"][new_key] = value
            pmd_base["solar"][new_key]["source_id"] = data["name"] * "." * pmd_base["solar"][new_key]["source_id"]
            pmd_base["solar"][new_key]["bus"] = data["name"] * "." * pmd_base["solar"][new_key]["bus"]
        end
    end

    # loop through battery storage systems
    if (haskey(data, "storage"))
        for (key, value) in data["storage"]
            new_key = data["name"] * "." * key
            # if key does not exists in pmd_base, add an empty Dict
            if !(haskey(pmd_base, "storage"))
                pmd_base["storage"] = Dict()
            end
            pmd_base["storage"][new_key] = value
            pmd_base["storage"][new_key]["source_id"] = data["name"] * "." * pmd_base["storage"][new_key]["source_id"]
            pmd_base["storage"][new_key]["bus"] = data["name"] * "." * pmd_base["storage"][new_key]["bus"]
        end
    end

    # add vbases to settings
    # loop through settings
    if (haskey(data, "settings"))
        for (key, value) in data["settings"]["vbases_default"]
            new_key = data["name"] * "." * key
            pmd_base["settings"]["vbases_default"][new_key] = value
        end
    end

end
