"""
    function _scale_loads!(
        p_data::Dict{String,<:Any},
        scalar::Real
    )

Scales loads based on the scalar passed as second argument. `p_data` is the dictionary that
contains the loads to be scaled. `scalar` is the float value used to scale all the loads in
the `p_data` dictionary.
"""
function _scale_loads!(p_data::Dict{String,<:Any}, scalar::Real)
    for (i, load) in p_data["load"]
        load["pd"] *= scalar
    end
end


"""
    function correct_network_data!(
        data::Dict{String,<:Any};
        multinetwork::Bool=false
    )

Corrects and prepares the data in both pm and pmd dictionaries. Also, assigns the ids given
in the boundary linking data to number buses. `data` is the pmitd dictionary to be corrected
and `multinetwork` is the boolean that defines if there are multinetwork boundary buses to be
assigned.
"""
function correct_network_data!(data::Dict{String,<:Any}; multinetwork::Bool=false)
    # Corrects and prepares boundary linking data.
    assign_boundary_buses!(data; multinetwork=multinetwork)

    # Corrects and prepares power transmission network data.
    # TODO: error: _PM.correct_voltage_angle_differences! does not yet support multinetwork data.
    if !multinetwork
        _PM.correct_network_data!(data["it"][_PM.pm_it_name])
    end

    _PM.simplify_network!(data["it"][_PM.pm_it_name])

    # Corrects and prepares power distribution network data.
    _PMD.correct_network_data!(data["it"][_PMD.pmd_it_name])

end


"""
    function correct_network_data_decomposition!(
        data::Dict{String,<:Any};
        multinetwork::Bool=false
    )

Corrects and prepares the data in both pm and pmd dictionaries. Also, assigns the ids given
in the boundary linking data to number buses. `data` is the pmitd dicitionary with the dictionaries
to be corrected and `multinetwork` is the boolean that defines if there are multinetwork boundary
buses to be assigned.
"""
function correct_network_data_decomposition!(data::Dict{String,<:Any}; multinetwork::Bool=false)

    # Corrects and prepares power transmission network data.
    # TODO: error: _PM.correct_voltage_angle_differences! does not yet support multinetwork data.
    if !multinetwork
        _PM.correct_network_data!(data["it"][_PM.pm_it_name])
    end

    _PM.simplify_network!(data["it"][_PM.pm_it_name])

    # Corrects and prepares power distribution network data (for each ckt).
    for (ckt_name, ckt_data) in data["it"][_PMD.pmd_it_name]
        # transform PMD data (only) from ENG to MATH Model
        if (!_PMD.ismath(ckt_data))
            data["it"][_PMD.pmd_it_name][ckt_name] = _PMD.transform_data_model(ckt_data; multinetwork=multinetwork)
        end

        # Corrects and prepares power distribution network data.
        _PMD.correct_network_data!(data["it"][_PMD.pmd_it_name][ckt_name])
    end

    # Corrects and prepares boundary linking data.
    # NOTE: TODO
    # When using the same distribution system case, assignments may get the same MATH bus number
    # making it very hard to distinguish which bus belongs to which network.
    assign_boundary_buses_decomposition!(data; multinetwork=multinetwork)

end


"""
    function assign_boundary_buses!(
        data::Dict{String,<:Any};
        multinetwork::Bool=false
    )

Assigns the names given in the boundary linking data to number buses in corresponding transmission
and distribution networks. `data` is the pmitd dictionary containing the boundary information and
`multinetwork` is the boolean that defines if there are multinetwork boundary buses to be
assigned.
"""
function assign_boundary_buses!(data::Dict{String,<:Any}; multinetwork::Bool=false)
    if multinetwork
        for (nw, nw_pmitd) in data["it"][pmitd_it_name]["nw"]
            for (key, conn) in nw_pmitd
                _assign_boundary_buses!(data, conn; multinetwork=multinetwork, nw=nw)
            end
        end
    else
        for (key, conn) in data["it"][pmitd_it_name]
            _assign_boundary_buses!(data, conn)
        end
    end
end


"""
    function _assign_boundary_buses!(
        data::Dict{String,<:Any},
        conn;
        multinetwork::Bool=false,
        nw::String="0"
    )

Helper function for assigning boundary buses. `data` is the pmitd dictionary containing the boundary information,
`conn` is the boundary connection information, `multinetwork` is the boolean that defines if there are multinetwork
boundary buses to be assigned, and `nw` is the network number.
"""
function _assign_boundary_buses!(data::Dict{String,<:Any}, conn; multinetwork::Bool=false, nw::String="0")

    tran_bus_name, dist_bus_name = conn["transmission_boundary"], conn["distribution_boundary"]

    if multinetwork
        tran_buses, dist_buses = data["it"][_PM.pm_it_name]["nw"][nw]["bus"], data["it"][_PMD.pmd_it_name]["nw"][nw]["bus"]
    else
        tran_buses, dist_buses = data["it"][_PM.pm_it_name]["bus"], data["it"][_PMD.pmd_it_name]["bus"]
    end

    tran_bus_name = typeof(tran_bus_name) == String ? tran_bus_name : string(tran_bus_name)
    dist_bus_name = typeof(dist_bus_name) == String ? dist_bus_name : string(dist_bus_name)

    try
        tran_bus = tran_buses[findfirst(x -> tran_bus_name == string(x["source_id"][2]), tran_buses)]
        conn["transmission_boundary"] = tran_bus["bus_i"]
    catch e
        @error "The transmission bus specified in the JSON file does not exists. Please input an existing bus!"
        throw(error())
    end

    # rearrange the name of ditro. bus: cktname.voltage_source.source -> voltage_source.cktname.source (PMD MATH model format)
    dist_bus_name_vector = split(dist_bus_name, ".")
    if (length(dist_bus_name_vector)>2)
        dist_bus_name = dist_bus_name_vector[2] * "." * dist_bus_name_vector[1] * "." * dist_bus_name_vector[3]
    end

    try
        dist_bus = dist_buses[findfirst(x -> dist_bus_name == x["source_id"], dist_buses)]
        conn["distribution_boundary"] = dist_bus["bus_i"]
    catch e
        @error "The distribution bus/source specified in the JSON file does not exists. Please input an existing bus/source!"
        throw(error())
    end
end


"""
    function assign_boundary_buses_decomposition!(
        data::Dict{String,<:Any};
        multinetwork::Bool=false
    )

Assigns the names given in the boundary linking data to number buses in corresponding transmission
and distribution networks. `data` is the pmitd dictionary containing the boundary information and
`multinetwork` is the boolean that defines if there are multinetwork boundary buses to be
assigned.
"""
function assign_boundary_buses_decomposition!(data::Dict{String,<:Any}; multinetwork::Bool=false)
    if multinetwork
        for (nw, nw_pmitd) in data["it"][pmitd_it_name]["nw"]
            for (key, conn) in nw_pmitd
                _assign_boundary_buses_decomposition!(data, conn; multinetwork=multinetwork, nw=nw)

                # check if the assignment failed
                if (typeof(conn["distribution_boundary"]) != Int)
                    @error "The distribution bus/source specified in the JSON file does not exists. Please input an existing bus/source!"
                    throw(error())
                end
            end
        end
    else
        for (key, conn) in data["it"][pmitd_it_name]
            _assign_boundary_buses_decomposition!(data, conn)

            # check if the assignment failed
            if (typeof(conn["distribution_boundary"]) != Int)
                @error "The distribution bus/source specified in the JSON file does not exists. Please input an existing bus/source!"
                throw(error())
            end
        end
    end
end


"""
    function _assign_boundary_buses_decomposition!(
        data::Dict{String,<:Any},
        conn;
        multinetwork::Bool=false,
        nw::String="0"
    )

Helper function for assigning boundary buses. `data` is the pmitd dictionary containing the boundary information,
`conn` is the boundary connection information, `multinetwork` is the boolean that defines if there are multinetwork
boundary buses to be assigned, and `nw` is the network number.
"""
function _assign_boundary_buses_decomposition!(data::Dict{String,<:Any}, conn; multinetwork::Bool=false, nw::String="0")

    # Get transmission and distribution boundary names
    tran_bus_name, dist_bus_name = conn["transmission_boundary"], conn["distribution_boundary"]

    # Transmission part
    if multinetwork
        tran_buses = data["it"][_PM.pm_it_name]["nw"][nw]["bus"]
    else
        tran_buses = data["it"][_PM.pm_it_name]["bus"]
    end

    tran_bus_name = typeof(tran_bus_name) == String ? tran_bus_name : string(tran_bus_name)

    try
        tran_bus = tran_buses[findfirst(x -> tran_bus_name == string(x["source_id"][2]), tran_buses)]
        conn["transmission_boundary"] = tran_bus["bus_i"]
    catch e
        @error "The transmission bus specified in the JSON file does not exists. Please input an existing bus!"
        throw(error())
    end

    # Distribution part
    dist_bus_name = typeof(dist_bus_name) == String ? dist_bus_name : string(dist_bus_name)

    # rearrange the name of ditro. bus: cktname.voltage_source.source -> voltage_source.cktname.source (PMD MATH model format)
    dist_bus_name_vector = split(dist_bus_name, ".")
    if (length(dist_bus_name_vector)>2)
        dist_bus_name = dist_bus_name_vector[2] * "." * dist_bus_name_vector[1] * "." * dist_bus_name_vector[3]
    end

    for (ckt_name, ckt_data) in data["it"][_PMD.pmd_it_name]
        if multinetwork
            dist_buses = ckt_data["nw"][nw]["bus"]
        else
            dist_buses = ckt_data["bus"]
        end

        # not fail, if search is unsuccesful.
        try
            dist_bus = dist_buses[findfirst(x -> dist_bus_name == x["source_id"], dist_buses)]
            conn["distribution_boundary"] = dist_bus["bus_i"]
        catch
            # do nothing
        end
    end

    # add ckt_name info (very important for ref_add_core_decomposition_distribution).
    conn["ckt_name"] = dist_bus_name_vector[1]

    # add transmission to distribution power base conversion factor to the specific T&D connection (very important for allowing different bases between transmission and distribution systems)
    conn["base_conv_factor"] = 1000.0*(data["it"][_PM.pm_it_name]["baseMVA"]/data["it"][_PMD.pmd_it_name][dist_bus_name_vector[1]]["settings"]["sbase_default"])

end


"""
    function resolve_units!(
        data::Dict{String,<:Any};
        multinetwork::Bool=false,
        number_multinetworks::Int=0
    )

Resolve the units used throughout the disparate datasets by setting the same settings bases. `data` is the pmitd
dictionary to be corrected by resolving units, `multinetwork` is the boolean that defines if there are multiple
networks that need to be corrected, and `number_multinetworks` defines the number of multinetworks.
"""
function resolve_units!(data::Dict{String,<:Any}; multinetwork::Bool=false, number_multinetworks::Int=0)
    # Change (if needed) the sbase_default based on the transmission system baseMVA
    if (multinetwork)
        for i in 1:number_multinetworks
            data["it"][_PMD.pmd_it_name]["nw"][string(i)]["settings"]["sbase_default"] = data["it"][_PM.pm_it_name]["nw"][string(i)]["baseMVA"]*data["it"][_PMD.pmd_it_name]["nw"][string(i)]["settings"]["power_scale_factor"]
        end
    else
        data["it"][_PMD.pmd_it_name]["settings"]["sbase_default"] = data["it"][_PM.pm_it_name]["baseMVA"]*data["it"][_PMD.pmd_it_name]["settings"]["power_scale_factor"]
    end
end

"""
    function resolve_units_decomposition!(
        data::Dict{String,<:Any},
        distribution_basekva::Float64;
        multinetwork::Bool=false,
        number_multinetworks::Int=0,
    )

Resolve the units to be used for the distribution system(s) based on the distribution_basekva parameter.
`data` is the pmitd dictionary to be corrected by resolving units, `multinetwork` is the boolean that defines if there are multiple
networks that need to be corrected, and `number_multinetworks` defines the number of multinetworks.
"""
function resolve_units_decomposition!(data::Dict{String,<:Any}, distribution_basekva::Float64; multinetwork::Bool=false, number_multinetworks::Int=0)
    # Change (if needed) the sbase_default based on the transmission system baseMVA
    if (multinetwork)
        for i in 1:number_multinetworks
            data["it"][_PMD.pmd_it_name]["nw"][string(i)]["settings"]["sbase_default"] = distribution_basekva
        end
    else
        data["it"][_PMD.pmd_it_name]["settings"]["sbase_default"] = distribution_basekva
    end

end


"""
    function replicate(
        sn_data::Dict{String,<:Any},
        count::Int;
        global_keys::Set{String}=Set{String}()
    )

Turns in given single network pmitd data in multinetwork data with a `count` replicate of the given network.
Note that this function performs a deepcopy of the network data. Significant multinetwork space savings can
often be achieved by building application specific methods of building multinetwork with minimal data replication.
`sn_data` is the data to be replicated, `count` is the number of networks to be replicated.
"""
function replicate(sn_data::Dict{String,<:Any}, count::Int; global_keys::Set{String}=Set{String}())
    return _IM.replicate(sn_data, count, union(global_keys, _pmitd_global_keys))
end


"""
    function calc_transmission_branch_flow_ac!(
        result::Dict{String,<:Any},
        pmitd_data::Dict{String,<:Any};
    )

Assumes a valid ac solution is included in the result and computes the branch flow values.
Returns the pf solution inside the `pmitd_data` dictionary (not the `result` dictionary).
Replicates the _PM function but compatible with PMITD dicitionary.
"""
function calc_transmission_branch_flow_ac!(result::Dict{String,<:Any}, pmitd_data::Dict{String,<:Any})
    # updates network data with solution data
    _IM.update_data!(pmitd_data, result["solution"])

    # calculates the transmission power flows
    flows = _PM._calc_branch_flow_ac(pmitd_data["it"]["pm"])

    # updates the network data with transmission power flows calculated
    _IM.update_data!(pmitd_data["it"]["pm"], flows)
end


"""
    function _compute_default_strg_cost_transmission(
        strg_data::Dict{String,<:Any},
        baseMVA::Float64
    )

Computes a default cost for the energy storage (transmission).
Returns the default storage cost to be added to the data dictionary.
"""
function _compute_default_strg_cost_transmission(strg_data::Dict{String,<:Any}, baseMVA::Float64)

    # Obtained from 2019 U.S. utility-scale storage NREL data ($/MWh of energy rating).
    cost_utility_scale_strg_dollar_per_mwh = 345000

    # Calculate cost in $ for entire strg system
    cost_strg_system_dollars = cost_utility_scale_strg_dollar_per_mwh*strg_data["energy_rating"]*baseMVA

    # Calculate cost to be used in optimization (in $/MWh)
    cycles = 2000   # Total number of cycles under warranty (default value)
    DoD = 1.0       # Default Depth of Discharge (100%)
    cost_strg_dollars_per_MWh = cost_strg_system_dollars/(cycles*(strg_data["energy_rating"]*baseMVA)*DoD*(strg_data["charge_efficiency"]*strg_data["discharge_efficiency"]))

    # Convert cost from $/MWh -> $/pu: to convert from $/MWh to $/pu just multiply by MVA Base (e.g., 2.5 $/MWh x 100 MWh/1pu = 250 $/pu)
    cost_strg_dollars_per_pu = cost_strg_dollars_per_MWh*baseMVA

    # Round to 4 digits the strg cost
    cost_strg_dollars_per_pu = round(cost_strg_dollars_per_pu, digits=4)

    return cost_strg_dollars_per_pu

end


"""
    function _compute_default_strg_cost_distribution(
        strg_data::Dict{String,<:Any}
    )

Computes a default cost for the energy storage (distribution).
Returns the default storage cost to be added to the data dictionary.
"""
function _compute_default_strg_cost_distribution(strg_data::Dict{String,<:Any})

    # Obtained from 2019 U.S. residential-scale storage NREL data ($/kWh of energy rating).
    cost_utility_scale_strg_dollar_per_kwh = 1100

    # Calculate cost in $ for entire strg system
    cost_strg_system_dollars = cost_utility_scale_strg_dollar_per_kwh*strg_data["energy_ub"]

    # Calculate cost to be used in optimization (in $/kWh)
    cycles = 2000   # Total number of cycles under warranty (default value)
    DoD = 1.0       # Default Depth of Discharge (100%)
    cost_strg_dollars_per_kWh = cost_strg_system_dollars/(cycles*strg_data["energy_ub"]*DoD*((strg_data["charge_efficiency"]/100)*(strg_data["discharge_efficiency"]/100)))

    # Round to 4 digits the strg cost
    cost_strg_dollars_per_kWh = round(cost_strg_dollars_per_kWh, digits=4)

    return cost_strg_dollars_per_kWh

end
