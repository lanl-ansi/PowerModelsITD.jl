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
        data::Dict{String,<:Any}, 
        ms::Int
    )

Renames the components given in `data` for multi-system number (`ms`), and adds the renamed components 
to `pmd_base` dictionary structure.
"""
function _rename_components!(pmd_base::Dict{String,<:Any}, data::Dict{String,<:Any}, ms::Int)
   
    bias = BOUNDARY_NUMBER - 1 + ms # Add bias name based on boundary number and multi-system (ms) number

    # Check if multinetwork
    if haskey(pmd_base, "nw")
        for (nw, mn_data) in data["nw"]
            _rename_network_components_network!(pmd_base["nw"][nw], mn_data, bias)
        end
    else
        _rename_network_components_network!(pmd_base, data, bias)
    end
       
end


"""
    function _rename_network_components_network!(
        pmd_base::Dict{String,<:Any}, 
        data::Dict{String,<:Any}, 
        bias::Int
    )

Rename specific components in single network dictionary. `pmd_base` is the dictionary where the renamed
components are to be added, `data` is the dictionary containing the components to be renamed, and `bias` 
is the number bias used as part of the new name of the renamed the components. 
"""
# rename specific components in single network dictionary
function _rename_network_components_network!(pmd_base::Dict{String,<:Any}, data::Dict{String,<:Any}, bias::Int)

    # loop through buses
    if (haskey(data, "bus"))
        for (key, value) in data["bus"]
            new_key = key * "_" * string(bias)
            pmd_base["bus"][new_key] = value
        end
    end

    # loop through lines
    if (haskey(data, "line"))
        for (key, value) in data["line"]
            new_key = key * "_" * string(bias) 
            pmd_base["line"][new_key] = value
            pmd_base["line"][new_key]["source_id"] = pmd_base["line"][new_key]["source_id"] * "_" * string(bias)
            pmd_base["line"][new_key]["f_bus"] = pmd_base["line"][new_key]["f_bus"] * "_" * string(bias)
            pmd_base["line"][new_key]["t_bus"] = pmd_base["line"][new_key]["t_bus"] * "_" * string(bias)
            if (haskey(pmd_base["line"][new_key], "linecode"))
                pmd_base["line"][new_key]["linecode"] = pmd_base["line"][new_key]["linecode"] * "_" * string(bias)
            end
        end
    end

    # loop through switch
    if (haskey(data, "switch"))
        for (key, value) in data["switch"]
            new_key = key * "_" * string(bias) 
            pmd_base["switch"][new_key] = value
            pmd_base["switch"][new_key]["source_id"] = pmd_base["switch"][new_key]["source_id"] * "_" * string(bias)
            pmd_base["switch"][new_key]["f_bus"] = pmd_base["switch"][new_key]["f_bus"] * "_" * string(bias)
            pmd_base["switch"][new_key]["t_bus"] = pmd_base["switch"][new_key]["t_bus"] * "_" * string(bias)
            if (haskey(pmd_base["switch"][new_key], "linecode"))
                pmd_base["switch"][new_key]["linecode"] = pmd_base["switch"][new_key]["linecode"] * "_" * string(bias)
            end
        end
    end
    
    # loop through transformer
    if (haskey(data, "transformer"))
        for (key, value) in data["transformer"]
            new_key = key * "_" * string(bias) 
            pmd_base["transformer"][new_key] = value
            pmd_base["transformer"][new_key]["source_id"] = pmd_base["transformer"][new_key]["source_id"] * "_" * string(bias)
            pmd_base["transformer"][new_key]["bus"][1] = pmd_base["transformer"][new_key]["bus"][1] * "_" * string(bias)
            pmd_base["transformer"][new_key]["bus"][2] = pmd_base["transformer"][new_key]["bus"][2] * "_" * string(bias)
        end
    end

    # loop through load
    if (haskey(data, "load"))
        for (key, value) in data["load"]
            new_key = key * "_" * string(bias) 
            pmd_base["load"][new_key] = value
            pmd_base["load"][new_key]["source_id"] = pmd_base["load"][new_key]["source_id"] * "_" * string(bias)
            pmd_base["load"][new_key]["bus"] = pmd_base["load"][new_key]["bus"] * "_" * string(bias)
        end
    end
    
    # loop through linecode
    if (haskey(data, "linecode"))
        for (key, value) in data["linecode"]
            new_key = key * "_" * string(bias) 
            pmd_base["linecode"][new_key] = value
        end
    end

    # loop through voltage_sources
    if (haskey(data, "voltage_source"))
        for (key, value) in data["voltage_source"]
            new_key = key * "_" * string(bias) 
            pmd_base["voltage_source"][new_key] = value
            pmd_base["voltage_source"][new_key]["source_id"] = pmd_base["voltage_source"][new_key]["source_id"] * "_" * string(bias)
            pmd_base["voltage_source"][new_key]["bus"] = pmd_base["voltage_source"][new_key]["bus"] * "_" * string(bias)
        end
    end

    # loop through generators
    if (haskey(data, "generator"))
        for (key, value) in data["generator"]
            new_key = key * "_" * string(bias) 
            pmd_base["generator"][new_key] = value
            pmd_base["generator"][new_key]["source_id"] = pmd_base["generator"][new_key]["source_id"] * "_" * string(bias)
            pmd_base["generator"][new_key]["bus"] = pmd_base["generator"][new_key]["bus"] * "_" * string(bias)
        end
    end

    # loop through shunts
    if (haskey(data, "shunt"))
        for (key, value) in data["shunt"]
            new_key = key * "_" * string(bias)
            pmd_base["shunt"][new_key] = value
            pmd_base["shunt"][new_key]["source_id"] = pmd_base["shunt"][new_key]["source_id"] * "_" * string(bias)
            pmd_base["shunt"][new_key]["bus"] = pmd_base["shunt"][new_key]["bus"] * "_" * string(bias)
        end
    end

    # loop through solar PV systems
    if (haskey(data, "solar"))
        for (key, value) in data["solar"]
            new_key = key * "_" * string(bias) 
            pmd_base["solar"][new_key] = value
            pmd_base["solar"][new_key]["source_id"] = pmd_base["solar"][new_key]["source_id"] * "_" * string(bias)
            pmd_base["solar"][new_key]["bus"] = pmd_base["solar"][new_key]["bus"] * "_" * string(bias)
        end
    end

    # loop through battery storage systems
    if (haskey(data, "storage"))
        for (key, value) in data["storage"]
            new_key = key * "_" * string(bias)
            pmd_base["storage"][new_key] = value
            pmd_base["storage"][new_key]["source_id"] = pmd_base["storage"][new_key]["source_id"] * "_" * string(bias)
            pmd_base["storage"][new_key]["bus"] = pmd_base["storage"][new_key]["bus"] * "_" * string(bias)
        end
    end

    # add vbases to settings
    # loop through settings
    if (haskey(data, "settings"))
        for (key, value) in data["settings"]["vbases_default"]
            new_key = key * "_" * string(bias) 
            pmd_base["settings"]["vbases_default"][new_key] = value
        end
    end
end