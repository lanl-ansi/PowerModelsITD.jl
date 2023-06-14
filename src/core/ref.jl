"""
    function ref_add_core!(ref::Dict{Symbol,Any})

Returns a dict that stores commonly used pre-computed data obtained from the data dictionary,
primarily for converting data-types, filtering out loads in the transmission-side system,
removing slack generators in the distribution-side system, and storing system-wide values that
need to be computed globally.
Some of the common keys include:
* `See ref_add_core!(ref) from PowerModels`),
* `See ref_add_core!(ref) from PowerModelsDistribution`),
* `:boundary` -- the set of boundary elements that are active in the network,
* `:arcs_boundary_from` -- the set `[(i,b["f_bus"],b["t_bus"]) for (i,b) in ref[:boundary]]`,
* `:arcs_boundary_to` -- the set `[(i,b["t_bus"],b["f_bus"]) for (i,b) in ref[:boundary]]`,
* `:arcs_boundary` -- the set of arcs from both `arcs_boundary_from` and `arcs_boundary_to`,
* `:bus_arcs_boundary_from` -- the mapping `Dict(i => [(l,i,j) for (l,i,j) in ref[:arcs_boundary_from]])`,
* `:bus_arcs_boundary_to` -- the mapping `Dict(i => [(l,i,j) for (l,i,j) in ref[:arcs_boundary_to]])`.
"""
function ref_add_core!(ref::Dict{Symbol,<:Any})

    # Populate the PowerModels portion of the `ref` dictionary.
    _PM.ref_add_core!(ref)

    # Populate the PowerModelsDistribution portion of the `ref` dictionary.
    _PMD.ref_add_core!(ref)

    # Truncate load at transmission system refs.
    _ref_filter_transmission_integration_loads!(ref)

    # Truncate/drop out voltage source generators at distribution system refs.
    _ref_filter_distribution_slack_generators!(ref)

    # Empty reference bus :ref_buses from :pmd
    _ref_remove_refbus_distribution!(ref)

    # Create a virtual boundary ref that connects the transmission load bus with distribution slack generator bus.
    _ref_connect_transmission_distribution!(ref)

end


"""
    function _ref_filter_transmission_integration_loads!(
        ref::Dict{Symbol,<:Any}
    )

Removes/filters-out the loads at buses (i.e., boundary buses) where distribution systems are going to be integrated/connected.
"""
function _ref_filter_transmission_integration_loads!(ref::Dict{Symbol,<:Any})
    # Loops over all nws
    for (nw, nw_ref) in ref[:it][:pm][:nw]
        # Filters only the ones that have the "transmission_boundary" key
        for (i, conn) in filter(x -> "transmission_boundary" in keys(x.second), ref[:it][:pmitd][:nw][nw])
            # Get init (start) values before deleting the boundary load info.
            pbound_fr_start = nw_ref[:load][nw_ref[:bus_loads][conn["transmission_boundary"]][1]]["pd"]
            qbound_fr_start = nw_ref[:load][nw_ref[:bus_loads][conn["transmission_boundary"]][1]]["qd"]
            conn["pbound_fr_start"] = pbound_fr_start
            conn["qbound_fr_start"] = qbound_fr_start

            # Remove loads
            nw_ref[:load] = Dict(x for x in nw_ref[:load] if x.second["load_bus"] != conn["transmission_boundary"] )
            nw_ref[:bus_loads][conn["transmission_boundary"]] = []
        end
    end
end


"""
    function _ref_filter_distribution_slack_generators!(
        ref::Dict{Symbol,<:Any}
    )

Removes/filters-out the slack generators at buses/nodes where the transmission system is going to be integrated/connected.
"""
function _ref_filter_distribution_slack_generators!(ref::Dict{Symbol,<:Any})
    # Loops over all nws
    for (nw, nw_ref) in ref[:it][:pmd][:nw]
        # Filters only the ones that have the "distribution_boundary" key
        for (i, conn) in filter(x -> "distribution_boundary" in keys(x.second), ref[:it][:pmitd][:nw][nw])
            # Filters out only the gens connected to the distribution-boundary bus (virtual slack bus from opendss)
            nw_ref[:gen] = Dict(x for x in nw_ref[:gen] if x.second["gen_bus"] != conn["distribution_boundary"] )
            nw_ref[:bus_conns_gen][conn["distribution_boundary"]] = []
            nw_ref[:bus_gens][conn["distribution_boundary"]] = []
            # Unrestrict buspairs connected to reference bus
            for (j, bus_pair) in nw_ref[:buspairs]
                if (bus_pair["vm_fr_min"] == 1.0) # only need to check one
                    bus_pair["vm_fr_min"] = 0.0
                    bus_pair["vm_fr_max"] = Inf
                end
            end
            # Modify v_min and v_max, remove va and vm, and change bus type for reference bus
            nw_ref[:bus][conn["distribution_boundary"]]["vmin"] = [0.0, 0.0, 0.0]
            nw_ref[:bus][conn["distribution_boundary"]]["vmax"] = [Inf, Inf, Inf]
            # nw_ref[:bus][conn["distribution_boundary"]]["va"] = [0.0, -120.0, 120.0]
            # nw_ref[:bus][conn["distribution_boundary"]]["vm"] = [1.0,1.0,1.0]
            nw_ref[:bus][conn["distribution_boundary"]]["bus_type"] = 1
        end
    end
end


"""
    function _ref_connect_transmission_distribution!(
        ref::Dict{Symbol,<:Any}
    )

Creates the boundary `refs` that integrate/connect the transmission and distribution system bus(es).
"""
function _ref_connect_transmission_distribution!(ref::Dict{Symbol,<:Any})
    # Loops over all nws
    for (nw, nw_ref) in ref[:it][:pmd][:nw]
        # get the specific nw pmitd data
        nw_ref_it = ref[:it][:pmitd][:nw][nw]
        # Loops over all boundary objects
        for i in 1:length(nw_ref_it)
            # boundary number index
            boundary_number = BOUNDARY_NUMBER - 1 + i

            # create :boundary structure if does not exists; inserts to dictionary if it already exists
            if !haskey(nw_ref_it, :boundary)
                nw_ref_it[:boundary] = Dict(boundary_number => Dict("f_bus" => 0, "t_bus" => 0, "index" => 0, "name" => "empty", "f_connections" => [1], "t_connections" => [1, 2, 3], "pbound_fr_start" => 0, "qbound_fr_start" => 0, "pbound_to_start" => 0, "qbound_to_start" => 0))
            else
                nw_ref_it[:boundary][boundary_number] = Dict("f_bus" => 0, "t_bus" => 0, "index" => 0, "name" => "empty", "f_connections" => [1], "t_connections" => [1, 2, 3], "pbound_fr_start" => 0, "qbound_fr_start" => 0, "pbound_to_start" => 0, "qbound_to_start" => 0)
            end

            # modify default values with actual values coming from linking file information
            nw_ref_it[:boundary][boundary_number]["f_bus"] = nw_ref_it[Symbol(boundary_number)]["transmission_boundary"]
            nw_ref_it[:boundary][boundary_number]["t_bus"] = nw_ref_it[Symbol(boundary_number)]["distribution_boundary"]
            nw_ref_it[:boundary][boundary_number]["index"] = boundary_number
            nw_ref_it[:boundary][boundary_number]["name"] = "_itd_boundary_$boundary_number"
            nw_ref_it[:boundary][boundary_number]["pbound_fr_start"] = nw_ref_it[Symbol(boundary_number)]["pbound_fr_start"]
            nw_ref_it[:boundary][boundary_number]["qbound_fr_start"] = nw_ref_it[Symbol(boundary_number)]["qbound_fr_start"]

            # Compute pbound_to and qbound_to start values for specific nw
            pload_totals = _compute_boundary_active_power_start_values_distribution(nw_ref)
            qload_totals = _compute_boundary_reactive_power_start_values_distribution(nw_ref)
            # Get the ckt_name related to the boundary number
            source_id = nw_ref[:bus][nw_ref_it[:boundary][boundary_number]["t_bus"]]["source_id"]
            ckt_name = split(source_id, ".")[2]
            # Assumes balance power initiliazation
            nw_ref_it[:boundary][boundary_number]["pbound_to_start"] = pload_totals[ckt_name][1]/3
            nw_ref_it[:boundary][boundary_number]["qbound_to_start"] = qload_totals[ckt_name][1]/3

            # Add bus reference from transmission (pm)
            # The dictionary represents Dict(original bus_index => boundary # that belongs to)
            trans_bus = nw_ref_it[Symbol(boundary_number)]["transmission_boundary"]
            if !haskey(nw_ref_it, :bus_from)
                nw_ref_it[:bus_from] = Dict(trans_bus => Dict("boundary" => boundary_number))
            else
                nw_ref_it[:bus_from][trans_bus] = Dict("boundary" => boundary_number)
            end

            # Add bus reference from distribution (pmd)
            # The dictionary represents Dict(original bus_index => boundary # that belongs to)
            dist_bus = nw_ref_it[Symbol(boundary_number)]["distribution_boundary"]
            if !haskey(nw_ref_it, :bus_to)
                nw_ref_it[:bus_to] = Dict(dist_bus => Dict("boundary" => boundary_number))
            else
                nw_ref_it[:bus_to][dist_bus] = Dict("boundary" => boundary_number)
            end

            # :arcs_boundary_from for boundary
            nw_ref_it[:arcs_boundary_from] = [(boundary_number,boundary["f_bus"],boundary["t_bus"]) for (boundary_number,boundary) in nw_ref_it[:boundary]]
            # :arcs_boundary_to for boundary
            nw_ref_it[:arcs_boundary_to]   = [(boundary_number,boundary["t_bus"],boundary["f_bus"]) for (boundary_number,boundary) in nw_ref_it[:boundary]]
            # :arcs_boundary
            nw_ref_it[:arcs_boundary] = [nw_ref_it[:arcs_boundary_from]; nw_ref_it[:arcs_boundary_to]]

            # bus_arcs for boundary connections
            type = "boundary"

            # bus_arcs_from for boundary objects
            bus_arcs_from = Dict((i, Tuple{Int,Int,Int}[]) for (i,bus) in nw_ref_it[:bus_from])
            for (l,i,j) in nw_ref_it[Symbol("arcs_$(type)_from")]
                push!(bus_arcs_from[i], (l,i,j))
            end
            nw_ref_it[Symbol("bus_arcs_$(type)_from")] = bus_arcs_from

            # bus_arcs_to for boundary objects
            bus_arcs_to = Dict((i, Tuple{Int,Int,Int}[]) for (i,bus) in nw_ref_it[:bus_to])
            for (l,i,j) in nw_ref_it[Symbol("arcs_$(type)_to")]
                push!(bus_arcs_to[i], (l,i,j))
            end
            nw_ref_it[Symbol("bus_arcs_$(type)_to")] = bus_arcs_to

            # branch boundary connections (by the number of connections, you can distinguish if is transmission (1phase) or distribution (3phase))
            conns_from = Dict{Int,Vector{Tuple{Tuple{Int,Int,Int},Vector{Int}}}}([(i, []) for (i, bus) in nw_ref_it[:bus_from]])
            conns_to = Dict{Int,Vector{Tuple{Tuple{Int,Int,Int},Vector{Int}}}}([(i, []) for (i, bus) in nw_ref_it[:bus_to]])
            for (i, obj) in nw_ref_it[Symbol(type)]
                push!(conns_from[obj["f_bus"]], ((obj["index"], obj["f_bus"], obj["t_bus"]), obj["f_connections"]))
                push!(conns_to[obj["t_bus"]], ((obj["index"], obj["t_bus"], obj["f_bus"]), obj["t_connections"]))
            end
            nw_ref_it[Symbol("bus_arcs_conns_$(type)_from")] = conns_from
            nw_ref_it[Symbol("bus_arcs_conns_$(type)_to")] = conns_to
        end
    end
end


"""
    function _ref_remove_refbus_distribution!(
        ref::Dict{Symbol,<:Any}
    )

Removes the reference(slack) bus in the distribution system(s).
"""
function _ref_remove_refbus_distribution!(ref::Dict{Symbol,<:Any})
    # make the :ref_buses dictionary empty on pmd
    for (nw, nw_ref) in ref[:it][:pmd][:nw]
        nw_ref[:ref_buses] = Dict{Int,Any}()
    end
end


"""
    function _compute_boundary_active_power_start_values_distribution(
        nw_ref::Dict{Symbol,<:Any}
    )

Computes the starting values for `pbound_to` variables. Returns dictionary with summation of the activate power loads.
Returns dictionary with the summation of the active power loads for each dist. system.
"""
function _compute_boundary_active_power_start_values_distribution(nw_ref::Dict{Symbol,<:Any})

    # Dicts to store summation of total load in dist. system
    pload_totals = Dict()

    # loop through all loads to add them up
    for (_, load_info) in nw_ref[:load]
        load_name = load_info["name"]
        ckt_name = split(load_name, ".")
        pd = load_info["pd"]

        if !haskey(pload_totals, ckt_name[1])
            pload_totals[ckt_name[1]] = sum(pd)
        else
            pload_totals[ckt_name[1]] += sum(pd)
        end
    end

    return pload_totals
end


"""
    function _compute_boundary_reactive_power_start_values_distribution(
        nw_ref::Dict{Symbol,<:Any}
    )

Computes the starting values for `qbound_to` and adds them to `ref`.
Returns dictionary with the summation of the reactive power loads for each dist. system.
"""
function _compute_boundary_reactive_power_start_values_distribution(nw_ref::Dict{Symbol,<:Any})

    # Dicts to store summation of total load in dist. system
    qload_totals = Dict()

    # loop through all loads to add them up
    for (_, load_info) in nw_ref[:load]
        load_name = load_info["name"]
        ckt_name = split(load_name, ".")
        qd = load_info["qd"]

        if !haskey(qload_totals, ckt_name[1])
            qload_totals[ckt_name[1]] = sum(qd)
        else
            qload_totals[ckt_name[1]] += sum(qd)
        end
    end

    return qload_totals
end
