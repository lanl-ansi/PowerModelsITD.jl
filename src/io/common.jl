"""
    function parse_json(
        path::String
    )

Parses a JavaScript Object Notation (JSON) file from the file path `path` and returns a
dictionary containing the corresponding parsed data. Primarily used for boundry linkage files.
"""
function parse_json(path::String)
    return JSON.parsefile(path)
end


"""
    function _convert_to_pmitd_structure(
        data::Vector{Any}
    )

Converts json data parsed into the required pmitd structure.
Returns the new data structure with necessary information and compatible names.
"""
function _convert_to_pmitd_structure(data::Vector{Any})

    data_structured = Dict{String, Any}() # initialize Dict structure

    number_of_links = 0 # number of boundary links
    for i in data
        bound_num = string(BOUNDARY_NUMBER+number_of_links)
        if !haskey(data_structured, "it")
            data_structured = Dict{String, Any}("it"=> Dict{String, Any}("pmitd"=>Dict{String, Any}(bound_num=>Dict(i))))
        else
            data_structured["it"]["pmitd"][bound_num] = i
        end
        # add 1 to the number of links in the vector provided
        number_of_links += 1
    end

    return data_structured
end


"""
    function parse_link_file(
        pmitd_file::String
    )

Parses a linking file from the file `pmitd_file` and returns a PowerModelsITD data
structured linking network dictionary.
"""
function parse_link_file(pmitd_file::String)
    # Exception if pmitd file is not compatible
    try
        if split(pmitd_file, ".")[end] != "json" # If not reading a JSON.
            throw(error())
        end
    catch e
        @error "Linkage file not compatible. Please input a .json file!"
        throw(error())
    end

    # Transmission + Distribution network linkage data.
    data = parse_json(pmitd_file)

    # converts received simple structure into necessary pmitd structure
    data_structured = _convert_to_pmitd_structure(data)

    return data_structured
end


"""
    function parse_power_transmission_file(
        pm_file::String;
        skip_correct::Bool = true,
        multinetwork::Bool=false,
        number_multinetworks::Int=0
    )

Parses a power transmission file from the file `pm_file` and returns a PowerModels data
structured pm network dictionary.
"""
function parse_power_transmission_file(pm_file::String; skip_correct::Bool=true, multinetwork::Bool=false, number_multinetworks::Int=0)
    # Exception if pm file is not compatible
    try
        if ((split(pm_file, ".")[end] != "m") && (split(pm_file, ".")[end] != "raw")) # If not reading a MATPOWER or PSSE raw file.
            throw(error())
        end
    catch e
        @error "Transmission System (PowerModels) file not compatible. Please input an .m or a .raw (PSSE) file!"
        throw(error())
    end

    # Parse file
    data = _PM.parse_file(pm_file; validate = !skip_correct)

    # Add default cost to storage devices in transmission.
    # (Users can assign their own cost values by modifying these costs from the dictionary).
    if haskey(data, "storage")
        for (strg_name, strg_data) in data["storage"]
            strg_data["cost"] = _compute_default_strg_cost_transmission(strg_data, data["baseMVA"])
        end
    end

    # replicate if multinetwork
    if multinetwork
        data = _PM.replicate(data, number_multinetworks)
    end

    return _IM.ismultiinfrastructure(data) ? data : Dict("multiinfrastructure" => true, "it" => Dict(_PM.pm_it_name => data), "per_unit" => false)
end


"""
    function parse_power_distribution_file(
        pmd_file::String,
        base_data::Dict{String,<:Any}=Dict{String, Any}();
        unique::Bool=true,
        multinetwork::Bool=false,
        auto_rename::Bool=false,
        ms_num::Int=1
    )

Parses power distribution files from the file `pmd_file` depending on the file extension.
`base_data` represents a dictionary that contains data from other pmd systems (serving as
the base where all data will be combined), `unique` represents if the pmd data provided is
the first one passed or unique. If it is not `unique`, then the components need to be renamed before being added.
Returns a PowerModelsDistribution data structured pmd network (a dictionary) with renamed components (if applicable).
"""
function parse_power_distribution_file(pmd_file::String, base_data::Dict{String,<:Any}=Dict{String, Any}(); unique::Bool=true, multinetwork::Bool=false, auto_rename::Bool=false, ms_num::Int=1)

    # Exception if pmd file is not compatible
    try
        if split(pmd_file, ".")[end] != "m" && split(pmd_file, ".")[end] != "dss" # If not reading a MATPOWER or DSS file.
            throw(error())
        end
    catch e
        @error "Distribution System (PowerModelsDistribution) file not compatible. Please input an .m or .dss file!"
        throw(error())
    end

    # Read distribution network data.
    if split(pmd_file, ".")[end] == "m" # If reading a MATPOWER file.
        data = _PM.parse_file(pmd_file)
        _scale_loads!(data, inv(3.0))
        _PMD.make_multiconductor!(data, real(3))
    else # Otherwise, use the PowerModelsDistribution parser.
        data = _PMD.parse_file(pmd_file; multinetwork=multinetwork)
    end

    # Add default cost to storage devices in distribution.
    # (Users can assign their own cost values by modifying these costs from the dictionary).
    if multinetwork
        for (nw_id, nw_data) in data["nw"]
            if haskey(nw_data, "storage")
                for (strg_name, strg_data) in nw_data["storage"]
                    strg_data["cost"] = _compute_default_strg_cost_distribution(strg_data)
                end
            end
        end
    else
        if haskey(data, "storage")
            for (strg_name, strg_data) in data["storage"]
                strg_data["cost"] = _compute_default_strg_cost_distribution(strg_data)
            end
        end
    end

    if (unique == false)

        # checks the circuit names are not the same, and rename them only if auto_rename=true
        _check_and_rename_circuits!(base_data, data; auto_rename=auto_rename, ms_num=ms_num)

        # change the name of all components in data using the Engineering model
        _rename_components!(base_data, data)

        return base_data
    else
        base_data = deepcopy(data)           # deepcopy of data (avoid referencing when deleting)
        _clean_pmd_base_data!(base_data)     # removes components to be renamed
        _rename_components!(base_data, data) # adds back renamed components

        # Check if base_data has the "ckt_names" keys, if not add it
        if !(haskey(base_data, "ckt_names"))
            base_data["ckt_names"] = [base_data["name"]]
        end

        return base_data
    end
end


"""
    function parse_files(
        pm_file::String,
        pmd_file::String,
        pmitd_file::String;
        multinetwork::Bool=false
        auto_rename::Bool=false
    )

Parses PowerModels, PowerModelsDistribution, and PowerModelsITD boundary linkage input files and returns a data dictionary
with the combined information of the inputted dictionaries.
"""
function parse_files(pm_file::String, pmd_file::String, pmitd_file::String; multinetwork::Bool=false, auto_rename::Bool=false)
    pmd_files = [pmd_file] # convert to vector
    return parse_files(pm_file, pmd_files, pmitd_file; multinetwork=multinetwork, auto_rename=auto_rename)
end


"""
    function parse_files(
        pm_file::String,
        pmd_files::Vector,
        pmitd_file::String;
        multinetwork::Bool=false,
        auto_rename::Bool=false
    )

Parses PowerModels, PowerModelsDistribution vector, and PowerModelsITD linkage input files and returns a data dictionary
with the combined information of the inputted dictionaries.
"""
function parse_files(pm_file::String, pmd_files::Vector, pmitd_file::String; multinetwork::Bool=false, auto_rename::Bool=false)

    # parse boundary data
    pmitd_data = parse_link_file(pmitd_file)    # Parse boundary linking file
    pmitd_data["per_unit"] = false              # Add default per_unit field

    # parse multi-systems (multiple distribution systems)
    ms_data = Dict{String, Any}()   # initialize empty pmd dictionary
    num_ms = length(pmd_files)      # number of distribution systems (ms: multi-systems )
    unique_flag = true              # flag to know if it is the first pmd structure
    for ms in 1:1:num_ms
        if (unique_flag == false)   # pmd already exists, so data will be checked, renamed, and added to the dict that already exists
            ms_data = parse_power_distribution_file(pmd_files[ms],
                                                    ms_data;
                                                    unique=unique_flag,
                                                    multinetwork=multinetwork,
                                                    auto_rename=auto_rename,
                                                    ms_num=ms)
        else
            ms_data = parse_power_distribution_file(pmd_files[ms],
                                                    ms_data;
                                                    multinetwork=multinetwork)
            unique_flag = false
        end
    end

    # create the entire it=>pmd=>data dictionary structure
    pmd_combined_data = Dict("multiinfrastructure" => true, "it" => Dict(_PMD.pmd_it_name => ms_data), "per_unit" => false)

    # Apply update_data to combined ms pmd data.
    _IM.update_data!(pmitd_data, pmd_combined_data)

    # get the multinetwork number from pmd (.csv file data)
    number_multinetworks = 0 # initialize number of multinetworks counter
    if multinetwork
        number_multinetworks = length(pmd_combined_data["it"][_PMD.pmd_it_name]["mn_lookup"])
    end

    # Update data with transmission system data
    _IM.update_data!(pmitd_data,
                    parse_power_transmission_file(pm_file,
                                                skip_correct=false;
                                                multinetwork=multinetwork,
                                                number_multinetworks=number_multinetworks
                                                )
                    )

    # Ensure all datasets use the same unit bases.
    resolve_units!(pmitd_data; multinetwork=multinetwork, number_multinetworks=number_multinetworks)

    # correct distribution system names in pmitd data structure if auto_rename=true (correction done sequentially)
    if (auto_rename==true)
        _correct_boundary_names!(pmitd_data)
    end

    # convert pmitd data to multinetwork (based on the number of multinetworks)
    if multinetwork
        pmitd_data["it"][pmitd_it_name] = replicate(pmitd_data["it"][pmitd_it_name], number_multinetworks)
    end

    # Return the complete ITD data dictionary.
    return pmitd_data

end
