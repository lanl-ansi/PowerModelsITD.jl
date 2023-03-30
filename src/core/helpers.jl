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
        base_data::Dict{String,<:Any},
        data::Dict{String,<:Any}
    )

Renames the components given in `data` for new multi-system and adds the renamed components
to `base_data` dictionary structure. cktname.element
"""
function _rename_components!(base_data::Dict{String,<:Any}, data::Dict{String,<:Any})

    # Check if multinetwork
    if haskey(base_data, "nw")
        for (nw, mn_data) in data["nw"]
            _rename_network_components!(base_data["nw"][nw], mn_data, data["name"])
        end
    else
        _rename_network_components!(base_data, data, data["name"])
    end

    # add file name to "files" dictionary in "pmd"
    _add_file_name!(base_data, data)

end


"""
    function _check_and_rename_circuits!(
        base_data::Dict{String,<:Any},
        data::Dict{String,<:Any};
        auto_rename::Bool=false,
        ms_num::Int=1
    )

Checks if the name of the `data` ckt already exists, if so and `auto_rename=false`
an error should be displayed telling the user that they must use the different ckt names
when parsing multiple distribution systems. If `auto_rename=true`, PMITD will rename the
repeated ckt name to `repeatedCktName_(ms_num)`. Finally, adds the ckt name of `data` to
"ckt_names" in the `base_data` dictionary.
"""
function _check_and_rename_circuits!(base_data::Dict{String,<:Any}, data::Dict{String,<:Any}; auto_rename::Bool=false, ms_num::Int=1)

    # check that data ckt name is not repeating, throw error if it is
    if (data["name"] in base_data["ckt_names"])
        if (auto_rename==false)
            @error "Distribution systems have same circuit names! Please use different names for each distribution system. (e.g., New Circuit.NameOfCkt) or use the auto_rename=true option."
            throw(error())
        else
            data["name"] = data["name"] * "_" * string(ms_num)
        end
    end

     # add circuit name to base_data["ckt_names"]
     push!(base_data["ckt_names"], data["name"])

end


"""
    function _correct_boundary_names!(
        pmitd_data::Dict{String,<:Any}
    )

Corrects the names of distribution system boundary buses given in boundary linking file based on the ckt_names
stored in the "pmd"=>"ckt_names". The correction is done sequentially, so each distribution
boundary bus name will be assigned the specific ckt name that exists in the numerical position
of the vector "ckt_names". This process should only be applied when users explicitly use the
option `auto_rename=true`, and a `warning` is displayed warning the user that the boundaries may
not be correct.
"""
function _correct_boundary_names!(pmitd_data::Dict{String,<:Any})

    @warn "auto_rename option is true, so boundary names in 'pmitd=>' will be overwritten sequentially and may not represent the actual wanted boundary connections."

    for (boundary, name) in zip(pmitd_data["it"][pmitd_it_name], pmitd_data["it"][_PMD.pmd_it_name]["ckt_names"])
        # rearrange the name of bus if more than 1 ckts
        old_dist_bus_name_vector = split(boundary[2]["distribution_boundary"], ".")
        if (length(old_dist_bus_name_vector)==3)
            boundary[2]["distribution_boundary"] = name * "." * old_dist_bus_name_vector[2] * "." * old_dist_bus_name_vector[3]
        elseif (length(old_dist_bus_name_vector)==2)
            boundary[2]["distribution_boundary"] = name * "." * old_dist_bus_name_vector[1] * "." * old_dist_bus_name_vector[2]
        else
            @error "One of the 'distribution_boundary' names given in the JSON file is in an incompatible format. Please use the 'object.name' or 'cktName.object.name' formats."
            throw(error())
        end
    end

end


"""
    function _clean_pmd_base_data!(
        base_data::Dict{String,<:Any}
    )

Removes/Cleans components from `base_data` pmd dictionary.
"""
function _clean_pmd_base_data!(base_data::Dict{String,<:Any})

    # Check if multinetwork
    if haskey(base_data, "nw")
        for (nw,_) in base_data["nw"]
            _remove_network_components!(base_data["nw"][nw])
        end
    else
        _remove_network_components!(base_data)
    end

end


"""
    function _remove_network_components!(
        base_data::Dict{String,<:Any}
    )

Removes components from `base_data` dictionary.
"""
function _remove_network_components!(base_data::Dict{String,<:Any})

    # delete keys
    if (haskey(base_data, "bus"))
        delete!(base_data, "bus")
    end

    if (haskey(base_data, "line"))
        delete!(base_data, "line")
    end

    if (haskey(base_data, "switch"))
        delete!(base_data, "switch")
    end

    if (haskey(base_data, "transformer"))
        delete!(base_data, "transformer")
    end

    if (haskey(base_data, "load"))
        delete!(base_data, "load")
    end

    if (haskey(base_data, "linecode"))
        delete!(base_data, "linecode")
    end

    if (haskey(base_data, "voltage_source"))
        delete!(base_data, "voltage_source")
    end

    if (haskey(base_data, "generator"))
        delete!(base_data, "generator")
    end

    if (haskey(base_data, "shunt"))
        delete!(base_data, "shunt")
    end

    if (haskey(base_data, "solar"))
        delete!(base_data, "solar")
    end

    if (haskey(base_data, "storage"))
        delete!(base_data, "storage")
    end

    if (haskey(base_data, "files"))
        delete!(base_data, "files")
    end

    if (haskey(base_data, "settings"))
        base_data["settings"]["vbases_default"] = Dict{String,Real}() # clean the vbases_default
    end

end


"""
    function _rename_network_components!(
        base_data::Dict{String,<:Any},
        data::Dict{String,<:Any},
        ckt_name::String
    )

Rename specific components in single network dictionary. `base_data` is the dictionary where the renamed
components are to be added, `data` is the dictionary containing the components to be renamed.
`ckt_name` is the circuit name of `data`.
"""
function _rename_network_components!(base_data::Dict{String,<:Any}, data::Dict{String,<:Any}, ckt_name::String)

    # loop through buses
    if (haskey(data, "bus"))
        for (key, value) in data["bus"]
            new_key = ckt_name * "." * key
            # if key does not exists in base_data, add an empty Dict
            if !(haskey(base_data, "bus"))
                base_data["bus"] = Dict()
            end
            base_data["bus"][new_key] = value
            base_data["bus"][new_key]["belongs_to_ckt"] = ckt_name  # add new category "belongs_to_ckt" to every component
        end
    end

    # loop through lines
    if (haskey(data, "line"))
        for (key, value) in data["line"]
            new_key = ckt_name * "." * key
            # if key does not exists in base_data, add an empty Dict
            if !(haskey(base_data, "line"))
                base_data["line"] = Dict()
            end
            base_data["line"][new_key] = value
            base_data["line"][new_key]["source_id"] = ckt_name * "." * base_data["line"][new_key]["source_id"]
            base_data["line"][new_key]["f_bus"] = ckt_name * "." * base_data["line"][new_key]["f_bus"]
            base_data["line"][new_key]["t_bus"] = ckt_name * "." * base_data["line"][new_key]["t_bus"]
            if (haskey(base_data["line"][new_key], "linecode"))
                base_data["line"][new_key]["linecode"] = ckt_name * "." * base_data["line"][new_key]["linecode"]
            end
            base_data["line"][new_key]["belongs_to_ckt"] = ckt_name  # add new category "belongs_to_ckt" to every component
        end
    end

    # loop through switch
    if (haskey(data, "switch"))
        for (key, value) in data["switch"]
            new_key = ckt_name * "." * key
            # if key does not exists in base_data, add an empty Dict
            if !(haskey(base_data, "switch"))
                base_data["switch"] = Dict()
            end
            base_data["switch"][new_key] = value
            base_data["switch"][new_key]["source_id"] = ckt_name * "." * base_data["switch"][new_key]["source_id"]
            base_data["switch"][new_key]["f_bus"] = ckt_name * "." * base_data["switch"][new_key]["f_bus"]
            base_data["switch"][new_key]["t_bus"] = ckt_name * "." * base_data["switch"][new_key]["t_bus"]
            if (haskey(base_data["switch"][new_key], "linecode"))
                base_data["switch"][new_key]["linecode"] = ckt_name * "." * base_data["switch"][new_key]["linecode"]
            end
            base_data["switch"][new_key]["belongs_to_ckt"] = ckt_name  # add new category "belongs_to_ckt" to every component
        end
    end

    # loop through transformer
    if (haskey(data, "transformer"))
        for (key, value) in data["transformer"]
            new_key = ckt_name * "." * key
            # if key does not exists in base_data, add an empty Dict
            if !(haskey(base_data, "transformer"))
                base_data["transformer"] = Dict()
            end
            base_data["transformer"][new_key] = value
            base_data["transformer"][new_key]["source_id"] = ckt_name * "." * base_data["transformer"][new_key]["source_id"]
            for t in 1:1:length(base_data["transformer"][new_key]["bus"])
                base_data["transformer"][new_key]["bus"][t] = ckt_name * "." * base_data["transformer"][new_key]["bus"][t]
            end
            base_data["transformer"][new_key]["belongs_to_ckt"] = ckt_name  # add new category "belongs_to_ckt" to every component
        end
    end

    # loop through load
    if (haskey(data, "load"))
        for (key, value) in data["load"]
            new_key = ckt_name * "." * key
            # if key does not exists in base_data, add an empty Dict
            if !(haskey(base_data, "load"))
                base_data["load"] = Dict()
            end
            base_data["load"][new_key] = value
            base_data["load"][new_key]["source_id"] = ckt_name * "." * base_data["load"][new_key]["source_id"]
            base_data["load"][new_key]["bus"] = ckt_name * "." * base_data["load"][new_key]["bus"]
            base_data["load"][new_key]["belongs_to_ckt"] = ckt_name  # add new category "belongs_to_ckt" to every component
        end
    end

    # loop through linecode
    if (haskey(data, "linecode"))
        for (key, value) in data["linecode"]
            new_key = ckt_name * "." * key
            # if key does not exists in base_data, add an empty Dict
            if !(haskey(base_data, "linecode"))
                base_data["linecode"] = Dict()
            end
            base_data["linecode"][new_key] = value
            base_data["linecode"][new_key]["belongs_to_ckt"] = ckt_name  # add new category "belongs_to_ckt" to every component
        end
    end

    # loop through voltage_sources
    if (haskey(data, "voltage_source"))
        for (key, value) in data["voltage_source"]
            new_key = ckt_name * "." * key
             # if key does not exists in base_data, add an empty Dict
             if !(haskey(base_data, "voltage_source"))
                base_data["voltage_source"] = Dict()
            end
            base_data["voltage_source"][new_key] = value
            base_data["voltage_source"][new_key]["source_id"] = ckt_name * "." * base_data["voltage_source"][new_key]["source_id"]
            base_data["voltage_source"][new_key]["bus"] = ckt_name * "." * base_data["voltage_source"][new_key]["bus"]
            base_data["voltage_source"][new_key]["belongs_to_ckt"] = ckt_name  # add new category "belongs_to_ckt" to every component
        end
    end

    # loop through generators
    if (haskey(data, "generator"))
        for (key, value) in data["generator"]
            new_key = ckt_name * "." * key
            # if key does not exists in base_data, add an empty Dict
            if !(haskey(base_data, "generator"))
                base_data["generator"] = Dict()
            end
            base_data["generator"][new_key] = value
            base_data["generator"][new_key]["source_id"] = ckt_name * "." * base_data["generator"][new_key]["source_id"]
            base_data["generator"][new_key]["bus"] = ckt_name * "." * base_data["generator"][new_key]["bus"]
            base_data["generator"][new_key]["belongs_to_ckt"] = ckt_name  # add new category "belongs_to_ckt" to every component
        end
    end

    # loop through shunts
    if (haskey(data, "shunt"))
        for (key, value) in data["shunt"]
            new_key = ckt_name * "." * key
            # if key does not exists in base_data, add an empty Dict
            if !(haskey(base_data, "shunt"))
                base_data["shunt"] = Dict()
            end
            base_data["shunt"][new_key] = value
            base_data["shunt"][new_key]["source_id"] = ckt_name * "." * base_data["shunt"][new_key]["source_id"]
            base_data["shunt"][new_key]["bus"] = ckt_name * "." * base_data["shunt"][new_key]["bus"]
            base_data["shunt"][new_key]["belongs_to_ckt"] = ckt_name  # add new category "belongs_to_ckt" to every component
        end
    end

    # loop through solar PV systems
    if (haskey(data, "solar"))
        for (key, value) in data["solar"]
            new_key = ckt_name * "." * key
            # if key does not exists in base_data, add an empty Dict
            if !(haskey(base_data, "solar"))
                base_data["solar"] = Dict()
            end
            base_data["solar"][new_key] = value
            base_data["solar"][new_key]["source_id"] = ckt_name * "." * base_data["solar"][new_key]["source_id"]
            base_data["solar"][new_key]["bus"] = ckt_name * "." * base_data["solar"][new_key]["bus"]
            base_data["solar"][new_key]["belongs_to_ckt"] = ckt_name  # add new category "belongs_to_ckt" to every component
        end
    end

    # loop through battery storage systems
    if (haskey(data, "storage"))
        for (key, value) in data["storage"]
            new_key = ckt_name * "." * key
            # if key does not exists in base_data, add an empty Dict
            if !(haskey(base_data, "storage"))
                base_data["storage"] = Dict()
            end
            base_data["storage"][new_key] = value
            base_data["storage"][new_key]["source_id"] = ckt_name * "." * base_data["storage"][new_key]["source_id"]
            base_data["storage"][new_key]["bus"] = ckt_name * "." * base_data["storage"][new_key]["bus"]
            base_data["storage"][new_key]["belongs_to_ckt"] = ckt_name  # add new category "belongs_to_ckt" to every component
        end
    end

    # add vbases to settings
    # loop through settings
    if (haskey(data, "settings"))
        for (key, value) in data["settings"]["vbases_default"]
            new_key = ckt_name * "." * key
            base_data["settings"]["vbases_default"][new_key] = value
        end
    end

end


"""
    function _add_file_name!(
        base_data::Dict{String,<:Any},
        data::Dict{String,<:Any}
    )

Adds filename from `data` to "files" dictionary in pmd (`base_data`).
"""
function _add_file_name!(base_data::Dict{String,<:Any}, data::Dict{String,<:Any})

    # add file name to "files" vector
    if (haskey(data, "files"))
        for file_name in data["files"]
            if !(haskey(base_data, "files"))
                base_data["files"] = Vector{String}()
            end
            push!(base_data["files"], file_name)
        end
    end

end



"""
    function _separate_pmd_circuits(
        pmd_data::Dict{String,<:Any};
        multinetwork::Bool=false
    )

Separates pmd_data into their respective independent pmd circuits.
`multinetwork` is the boolean that defines if the separation must be done as multinetwork.
Returns the pmd_data separated.
"""
function _separate_pmd_circuits(pmd_data::Dict{String,<:Any}; multinetwork::Bool=false)

    # initialize Dict() to store separated ckts
    pmd_data_separated = Dict{String,Any}()

    if multinetwork
        # loop on all ckt names
        for ckt_name in pmd_data["ckt_names"]

            # initialize the ckt dictionary
            pmd_data_separated[ckt_name] = Dict("nw" => Dict{String,Any}(), "multinetwork" => true)

            # loop over all external components that are not in 'nw' in the pmd data dictionary
            for (c_name, c_data) in pmd_data
                if (c_name != "nw") && (c_name != "files") && (c_name != "ckt_names") && (c_name != "name")
                    pmd_data_separated[ckt_name][c_name] = c_data
                end
            end

            # loop through nws
            for (nw, nw_pmd) in pmd_data["nw"]

                # initialize the [ckt]["nw"][nw] dictionary
                pmd_data_separated[ckt_name]["nw"][nw] = Dict{String,Any}()

                # loop over all components in the pmd data dictionary
                for (component_name, component_data) in nw_pmd

                    # if type of dictioary is not Dict{Any,Any, then add it directly to the ckt dict.
                    if !(typeof(component_data)==Dict{Any,Any})
                        pmd_data_separated[ckt_name]["nw"][nw][component_name] = deepcopy(component_data)
                    else
                        # filter components that have the belongs_to_ckt==ckt_name condition
                        filtered_components = filter(x -> (x.second["belongs_to_ckt"] == ckt_name), pmd_data["nw"][nw][component_name])

                        # add filtered component to respective ckt dict inside pmd_data_separated
                        pmd_data_separated[ckt_name]["nw"][nw][component_name] = filtered_components
                    end

                    # 'manually' fix the settings for individual ckts
                    if (component_name=="settings")
                        vbases_default_name = ckt_name*"."*"sourcebus"
                        empty!(pmd_data_separated[ckt_name]["nw"][nw][component_name]["vbases_default"])
                        pmd_data_separated[ckt_name]["nw"][nw][component_name]["vbases_default"][vbases_default_name] = pmd_data["nw"][nw]["settings"]["vbases_default"][vbases_default_name]
                    end
                end
            end
        end
    else
        # loop on all ckt names
        for ckt_name in pmd_data["ckt_names"]

            # initialize the ckt dictionary
            pmd_data_separated[ckt_name] = Dict{String,Any}()

            # loop over all components in the pmd data dictionary
            for (component_name, component_data) in pmd_data

                # if type of dictioary is not Dict{Any,Any, then add it directly to the ckt dict.
                if !(typeof(component_data)==Dict{Any,Any})
                    pmd_data_separated[ckt_name][component_name] = deepcopy(component_data)
                else
                    # filter components that have the belongs_to_ckt==ckt_name condition
                    filtered_components = filter(x -> (x.second["belongs_to_ckt"] == ckt_name), pmd_data[component_name])

                    # add filtered component to respective ckt dict inside pmd_data_separated
                    pmd_data_separated[ckt_name][component_name] = filtered_components
                end

                # 'manually' fix the settings for individual ckts
                if (component_name=="settings")
                    vbases_default_name = ckt_name*"."*"sourcebus"
                    empty!(pmd_data_separated[ckt_name][component_name]["vbases_default"])
                    pmd_data_separated[ckt_name][component_name]["vbases_default"][vbases_default_name] = pmd_data["settings"]["vbases_default"][vbases_default_name]
                end
            end
        end
    end

    return pmd_data_separated

end
