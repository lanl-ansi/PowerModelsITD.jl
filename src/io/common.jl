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
            data_structured["it"]["pmitd"][bound_num]["distribution_boundary"] = data_structured["it"]["pmitd"][bound_num]["distribution_boundary"]*"_"*string(bound_num)  # change name of distribution system boundary bus after first one.
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

    # replicate if multinetwork
    if multinetwork
        data = _PM.replicate(data, number_multinetworks)
    end

    return _IM.ismultiinfrastructure(data) ? data : Dict("multiinfrastructure" => true, "it" => Dict(_PM.pm_it_name => data), "per_unit" => false)
end


"""
    function parse_power_distribution_file(
        pmd_file::String,
        pmd_base::Dict{String,<:Any}=Dict{String, Any}(),
        ms_num::Int=1;
        unique::Bool=true,
        multinetwork::Bool=false)
    )

Parses power distribution files from the file `pmd_file` depending on the file extension.
`pmd_base` represents a dictionary that contains data from other pmd systems, `ms_num` is the
multi-system number (current distribution system number) and `unique` represents if the pmd data provided
is the first one passed or unique. If it is not `unique`, then the components need to be renamed before being added.
Returns a PowerModelsDistribution data structured pmd network (a dictionary) with renamed components (if applicable).
"""
function parse_power_distribution_file(pmd_file::String, pmd_base::Dict{String,<:Any}=Dict{String, Any}(), ms_num::Int=1; unique::Bool=true, multinetwork::Bool=false)
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

    if (unique == false)
        # change the name of all components in data using the Engineering model
        _rename_components!(pmd_base, data, ms_num)
        return pmd_base
    else
        pmd_base = data
        return pmd_base
    end
end


"""
    function parse_files(
        pm_file::String,
        pmd_file::String,
        pmitd_file::String;
        multinetwork::Bool=false
    )

Parses PowerModels, PowerModelsDistribution, and PowerModelsITD boundary linkage input files and returns a data dictionary
with the combined information of the inputted dictionaries.
"""
function parse_files(pm_file::String, pmd_file::String, pmitd_file::String; multinetwork::Bool=false)
    pmd_files = [pmd_file] # convert to vector
    return parse_files(pm_file, pmd_files, pmitd_file; multinetwork=multinetwork)
end


"""
    function parse_files(
        pm_file::String,
        pmd_files::Vector,
        pmitd_file::String;
        multinetwork::Bool=false
    )

Parses PowerModels, PowerModelsDistribution vector, and PowerModelsITD linkage input files and returns a data dictionary
with the combined information of the inputted dictionaries.
"""
function parse_files(pm_file::String, pmd_files::Vector, pmitd_file::String; multinetwork::Bool=false)
    pmitd_data = parse_link_file(pmitd_file)                              # Parse linking file
    pmitd_data["per_unit"] = false                                        # Add default per_unit field

    # parse multi-systems (multiple distribution systems)
    ms_data = Dict{String, Any}()  # initialize empty pmd dictionary
    num_ms = size(pmd_files)[1] # number of distribution systems (ms: multi-systems )
    unique_flag = true # flag to know if it is the first pmd structure
    for ms in 1:num_ms
        if (unique_flag == false) # pmd already exists
            ms_data = parse_power_distribution_file(pmd_files[ms], ms_data, ms; unique=unique_flag, multinetwork=multinetwork)
        else
            ms_data = parse_power_distribution_file(pmd_files[ms], ms_data, ms; multinetwork=multinetwork)
            unique_flag = false
        end
    end

    # create the entire it=>pmd=>data dictionary structure
    pmd_combined_data = Dict("multiinfrastructure" => true, "it" => Dict(_PMD.pmd_it_name => ms_data), "per_unit" => false)

    # Apply update_data at the end after the entire ms dictionary is created
    _IM.update_data!(pmitd_data, pmd_combined_data) # Update data with distribution data

    # get the multinetwork number from pmd (.csv file data)
    number_multinetworks = 0 # initialize number of multinetworks var
    if multinetwork
        number_multinetworks = length(pmd_combined_data["it"][_PMD.pmd_it_name]["mn_lookup"])
    end

    # Update data with transmission system data
    _IM.update_data!(pmitd_data, parse_power_transmission_file(pm_file, skip_correct=false; multinetwork=multinetwork, number_multinetworks=number_multinetworks))

    # Ensure all datasets use the same unit bases.
    resolve_units!(pmitd_data; multinetwork=multinetwork, number_multinetworks=number_multinetworks)

    # convert pmitd data to multinetwork (based on the number of multinetworks)
    if multinetwork
        pmitd_data["it"][pmitd_it_name] = replicate(pmitd_data["it"][pmitd_it_name], number_multinetworks)
    end

    # Return the complete ITD data dictionary.
    return pmitd_data
end
