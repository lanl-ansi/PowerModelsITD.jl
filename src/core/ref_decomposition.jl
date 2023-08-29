"""
    function ref_add_core_decomposition_transmission!(ref::Dict{Symbol,Any})

Returns a dict that stores commonly used pre-computed data obtained from the data dictionary,
primarily for converting data-types, filtering load variables related to distribution systems,
and storing system-wide values that need to be computed globally.
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
function ref_add_core_decomposition_transmission!(ref::Dict{Symbol,<:Any})

    # Populate the PowerModels portion of the `ref` dictionary.
    _PM.ref_add_core!(ref)

    # Truncate load at transmission system refs.
    _ref_filter_transmission_integration_loads_decomposition!(ref)

    # Create a virtual boundary ref that connects the transmission load bus with distribution slack generator bus.
    _ref_connect_transmission_distribution_decomposition!(ref)

end


"""
    function _ref_filter_transmission_integration_loads_decomposition!(
        ref::Dict{Symbol,<:Any}
    )

Removes/filters-out the loads at buses (i.e., boundary buses) where distribution systems are going to be integrated/connected.
"""
function _ref_filter_transmission_integration_loads_decomposition!(ref::Dict{Symbol,<:Any})
    # Loops over all nws
    for (nw, nw_ref) in ref[:it][:pm][:nw]
        # boundary info.
        boundaries = nw_ref[:pmitd]
        # Filters only the ones that have the "transmission_boundary" key
        for (i, conn) in filter(x -> "transmission_boundary" in keys(x.second), boundaries)
            # Get init (start) values before deleting the boundary load info.
            pd_start = nw_ref[:load][nw_ref[:bus_loads][conn["transmission_boundary"]][1]]["pd"]
            qd_start = nw_ref[:load][nw_ref[:bus_loads][conn["transmission_boundary"]][1]]["qd"]
            conn["pbound_load_start"] = pd_start
            conn["qbound_load_start"] = qd_start

            nw_ref[:load] = Dict(x for x in nw_ref[:load] if x.second["load_bus"] != conn["transmission_boundary"] )
            nw_ref[:bus_loads][conn["transmission_boundary"]] = []
        end
    end
end


"""
    function ref_add_core_decomposition_distribution!(ref::Dict{Symbol,Any})

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
function ref_add_core_decomposition_distribution!(ref::Dict{Symbol,<:Any})

    # Populate the PowerModelsDistribution portion of the `ref` dictionary.
    _PMD.ref_add_core!(ref)

    # Modifies the voltage source generators at distribution system refs.
    _ref_filter_distribution_slack_generators_decomposition!(ref)

    # Create a virtual boundary ref that connects the transmission load bus with distribution slack generator bus.
    _ref_connect_distribution_transmission_decomposition!(ref)

end


"""
    function _ref_filter_distribution_slack_generators_decomposition!(
        ref::Dict{Symbol,<:Any}
    )

Unrestricts the slack generator.
"""
function _ref_filter_distribution_slack_generators_decomposition!(ref::Dict{Symbol,<:Any})

    # Loops over all nws
    for (nw, nw_ref) in ref[:it][:pmd][:nw]
        # Unrestrict buspairs connected to reference bus
        for (j, bus_pair) in nw_ref[:buspairs]
            if (bus_pair["vm_fr_min"] == 1.0) # only need to check one
                bus_pair["vm_fr_min"] = 0.0
                bus_pair["vm_fr_max"] = Inf
            end
        end

        # Modify v_min and v_max, remove va and vm, and change bus type for reference bus
        boundary = nw_ref[:pmitd]   # boundary info.

        # get boundary number
        boundary_keys = collect(keys(boundary))
        boundary_number = boundary_keys[1]
        boundary_data = boundary[boundary_number]

        nw_ref[:bus][boundary_data["distribution_boundary"]]["vmin"] = [0.0, 0.0, 0.0]
        nw_ref[:bus][boundary_data["distribution_boundary"]]["vmax"] = [Inf, Inf, Inf]
        # nw_ref[:bus][boundary_data["distribution_boundary"]]["bus_type"] = 1 # 3: slack, 1: load, 2: gen. bus

        # Modify slack gen cost & other parameters.
        for (gen_indx, gen_data) in  nw_ref[:gen]
            if (gen_data["gen_bus"] == boundary_data["distribution_boundary"])
                cost_length = length(gen_data["cost"])
                gen_data["cost"] = zeros(cost_length)
                # modify the control mode of the slack gen (not penalty related)
                # gen_data["control_mode"] = 1 # TODO: this may be needed.
            end
        end
    end
end


"""
    function _ref_connect_transmission_distribution_decomposition!(
        ref::Dict{Symbol,<:Any}
    )

Creates the boundary `refs` that integrate/connect the transmission and distribution system(s) bus.
"""
function _ref_connect_transmission_distribution_decomposition!(ref::Dict{Symbol,<:Any})

    # Loops over all T-D pmitd available
    for (nw, nw_ref) in ref[:it][:pm][:nw]

        # boundary info.
        boundaries = nw_ref[:pmitd]

        for i in 1:length(boundaries)   # loop through all boundary objects
            boundary_number = BOUNDARY_NUMBER - 1 + i # boundary number index

            # create :boundary structure if does not exists; inserts to dictionary if it already exists
            if !haskey(nw_ref, :boundary)
                nw_ref[:boundary] = Dict(boundary_number => Dict("f_bus" => 0, "t_bus" => 0, "index" => 0, "name" => "empty", "f_connections" => [1], "t_connections" => [1, 2, 3], "ckt_name" => "empty", "pbound_load_start" => 0, "qbound_load_start" => 0))
            else
                nw_ref[:boundary][boundary_number] = Dict("f_bus" => 0, "t_bus" => 0, "index" => 0, "name" => "empty", "f_connections" => [1], "t_connections" => [1, 2, 3], "ckt_name" => "empty", "pbound_load_start" => 0, "qbound_load_start" => 0)
            end

            # modify default values with actual values coming from linking file information
            nw_ref[:boundary][boundary_number]["f_bus"] = boundaries[boundary_number]["transmission_boundary"]
            nw_ref[:boundary][boundary_number]["t_bus"] = boundaries[boundary_number]["distribution_boundary"]
            nw_ref[:boundary][boundary_number]["index"] = boundary_number
            nw_ref[:boundary][boundary_number]["ckt_name"] = boundaries[boundary_number]["ckt_name"]
            nw_ref[:boundary][boundary_number]["name"] = "_itd_boundary_$boundary_number"
            nw_ref[:boundary][boundary_number]["pbound_load_start"] = boundaries[boundary_number]["pbound_load_start"]
            nw_ref[:boundary][boundary_number]["qbound_load_start"] = boundaries[boundary_number]["qbound_load_start"]

            # Add bus reference from transmission (pm)
            # The dictionary represents Dict(original bus_index => boundary # that belongs to)
            trans_bus = boundaries[boundary_number]["transmission_boundary"]
            if !haskey(nw_ref, :boundary_bus_from)
                nw_ref[:boundary_bus_from] = Dict(trans_bus => Dict("boundary" => boundary_number))
            else
                nw_ref[:boundary_bus_from][trans_bus] = Dict("boundary" => boundary_number)
            end

            # Add bus reference from distribution (pmd)
            # The dictionary represents Dict(original bus_index => boundary # that belongs to)
            dist_bus = boundaries[boundary_number]["distribution_boundary"]
            if !haskey(nw_ref, :boundary_bus_to)
                nw_ref[:boundary_bus_to] = Dict(dist_bus => Dict("boundary" => boundary_number))
            else
                nw_ref[:boundary_bus_to][dist_bus] = Dict("boundary" => boundary_number)
            end

            # :arcs_boundary_from for boundary
            nw_ref[:arcs_boundary_from] = [(boundary_number, boundary["f_bus"], boundary["t_bus"]) for (boundary_number, boundary) in nw_ref[:boundary]]
            # :arcs_boundary_to for boundary
            nw_ref[:arcs_boundary_to]   = [(boundary_number, boundary["t_bus"], boundary["f_bus"]) for (boundary_number, boundary) in nw_ref[:boundary]]
            # :arcs_boundary
            nw_ref[:arcs_boundary] = [nw_ref[:arcs_boundary_from]; nw_ref[:arcs_boundary_to]]

            # bus_arcs for boundary connections
            type = "boundary"

            # bus_arcs_from for boundary objects
            bus_arcs_from = Dict((i, Tuple{Int,Int,Int}[]) for (i,bus) in nw_ref[:boundary_bus_from])
            for (l,i,j) in nw_ref[Symbol("arcs_$(type)_from")]
                push!(bus_arcs_from[i], (l,i,j))
            end
            nw_ref[Symbol("bus_arcs_$(type)_from")] = bus_arcs_from

            # bus_arcs_to for boundary objects
            bus_arcs_to = Dict((i, Tuple{Int,Int,Int}[]) for (i,bus) in nw_ref[:boundary_bus_to])
            for (l,i,j) in nw_ref[Symbol("arcs_$(type)_to")]
                push!(bus_arcs_to[i], (l,i,j))
            end
            nw_ref[Symbol("bus_arcs_$(type)_to")] = bus_arcs_to

            # branch boundary connections (by the number of connections, you can distinguish if is transmission (1phase) or distribution (3phase))
            conns_from = Dict{Int,Vector{Tuple{Tuple{Int,Int,Int},Vector{Int}}}}([(i, []) for (i, bus) in nw_ref[:boundary_bus_from]])
            conns_to = Dict{Int,Vector{Tuple{Tuple{Int,Int,Int},Vector{Int}}}}([(i, []) for (i, bus) in nw_ref[:boundary_bus_to]])
            for (i, obj) in nw_ref[Symbol(type)]
                push!(conns_from[obj["f_bus"]], ((obj["index"], obj["f_bus"], obj["t_bus"]), obj["f_connections"]))
                push!(conns_to[obj["t_bus"]], ((obj["index"], obj["t_bus"], obj["f_bus"]), obj["t_connections"]))
            end
            nw_ref[Symbol("bus_arcs_conns_$(type)_from")] = conns_from
            nw_ref[Symbol("bus_arcs_conns_$(type)_to")] = conns_to
        end
    end
end


"""
    function _ref_connect_distribution_transmission_decomposition!(
        ref::Dict{Symbol,<:Any}
    )

Creates the boundary `refs` that integrate/connect the distribution system bus with the transmission system bus.
"""
function _ref_connect_distribution_transmission_decomposition!(ref::Dict{Symbol,<:Any})

    # Loops over all T-D pmitd available
    for (nw, nw_ref) in ref[:it][:pmd][:nw]

        # boundary info.
        boundaries = nw_ref[:pmitd]

        # get boundary number
        boundary_keys = collect(keys(boundaries))
        boundary_number = parse(Int64, boundary_keys[1])

        # create :boundary structure if does not exists; inserts to dictionary if it already exists
        if !haskey(nw_ref, :boundary)
            nw_ref[:boundary] = Dict(boundary_number => Dict("f_bus" => 0, "t_bus" => 0, "index" => 0, "name" => "empty", "f_connections" => [1], "t_connections" => [1, 2, 3], "ckt_name" => "empty", "pbound_aux_start" => 0, "qbound_aux_start" => 0))
        else
            nw_ref[:boundary][boundary_number] = Dict("f_bus" => 0, "t_bus" => 0, "index" => 0, "name" => "empty", "f_connections" => [1], "t_connections" => [1, 2, 3], "ckt_name" => "empty", "pbound_aux_start" => 0, "qbound_aux_start" => 0)
        end

        # Compute pbound_aux and qbound_aux start values and adds them to [:pmitd]
        _compute_boundary_power_start_values_distribution!(nw_ref)

        # modify default values with actual values coming from linking file information
        nw_ref[:boundary][boundary_number]["f_bus"] = boundaries[string(boundary_number)]["transmission_boundary"]
        nw_ref[:boundary][boundary_number]["t_bus"] = boundaries[string(boundary_number)]["distribution_boundary"]
        nw_ref[:boundary][boundary_number]["index"] = boundary_number
        nw_ref[:boundary][boundary_number]["ckt_name"] = boundaries[string(boundary_number)]["ckt_name"]
        nw_ref[:boundary][boundary_number]["name"] = "_itd_boundary_$boundary_number"
        nw_ref[:boundary][boundary_number]["pbound_aux_start"] = boundaries[string(boundary_number)]["pbound_aux_start"]
        nw_ref[:boundary][boundary_number]["qbound_aux_start"] = boundaries[string(boundary_number)]["qbound_aux_start"]

        # Add bus reference from transmission (pm)
        # The dictionary represents Dict(original bus_index => boundary # that belongs to)
        trans_bus = boundaries[string(boundary_number)]["transmission_boundary"]
        if !haskey(nw_ref, :boundary_bus_from)
            nw_ref[:boundary_bus_from] = Dict(trans_bus => Dict("boundary" => boundary_number))
        else
            nw_ref[:boundary_bus_from][trans_bus] = Dict("boundary" => boundary_number)
        end

        # Add bus reference from distribution (pmd)
        # The dictionary represents Dict(original bus_index => boundary # that belongs to)
        dist_bus = boundaries[string(boundary_number)]["distribution_boundary"]
        if !haskey(nw_ref, :boundary_bus_to)
            nw_ref[:boundary_bus_to] = Dict(dist_bus => Dict("boundary" => boundary_number))
        else
            nw_ref[:boundary_bus_to][dist_bus] = Dict("boundary" => boundary_number)
        end

        # :arcs_boundary_from for boundary
        nw_ref[:arcs_boundary_from] = [(boundary_number, boundary["f_bus"], boundary["t_bus"]) for (boundary_number, boundary) in nw_ref[:boundary]]
        # :arcs_boundary_to for boundary
        nw_ref[:arcs_boundary_to]   = [(boundary_number, boundary["t_bus"], boundary["f_bus"]) for (boundary_number, boundary) in nw_ref[:boundary]]
        # :arcs_boundary
        nw_ref[:arcs_boundary] = [nw_ref[:arcs_boundary_from]; nw_ref[:arcs_boundary_to]]

        # bus_arcs for boundary connections
        type = "boundary"

        # bus_arcs_from for boundary objects
        bus_arcs_from = Dict((i, Tuple{Int,Int,Int}[]) for (i,bus) in nw_ref[:boundary_bus_from])
        for (l,i,j) in nw_ref[Symbol("arcs_$(type)_from")]
            push!(bus_arcs_from[i], (l,i,j))
        end
        nw_ref[Symbol("bus_arcs_$(type)_from")] = bus_arcs_from

        # bus_arcs_to for boundary objects
        bus_arcs_to = Dict((i, Tuple{Int,Int,Int}[]) for (i,bus) in nw_ref[:boundary_bus_to])
        for (l,i,j) in nw_ref[Symbol("arcs_$(type)_to")]
            push!(bus_arcs_to[i], (l,i,j))
        end
        nw_ref[Symbol("bus_arcs_$(type)_to")] = bus_arcs_to

        # branch boundary connections (by the number of connections, you can distinguish if is transmission (1phase) or distribution (3phase))
        conns_from = Dict{Int,Vector{Tuple{Tuple{Int,Int,Int},Vector{Int}}}}([(i, []) for (i, bus) in nw_ref[:boundary_bus_from]])
        conns_to = Dict{Int,Vector{Tuple{Tuple{Int,Int,Int},Vector{Int}}}}([(i, []) for (i, bus) in nw_ref[:boundary_bus_to]])
        for (i, obj) in nw_ref[Symbol(type)]
            push!(conns_from[obj["f_bus"]], ((obj["index"], obj["f_bus"], obj["t_bus"]), obj["f_connections"]))
            push!(conns_to[obj["t_bus"]], ((obj["index"], obj["t_bus"], obj["f_bus"]), obj["t_connections"]))
        end
        nw_ref[Symbol("bus_arcs_conns_$(type)_from")] = conns_from
        nw_ref[Symbol("bus_arcs_conns_$(type)_to")] = conns_to

    end
end


"""
    function _compute_boundary_power_start_values_distribution!(
        ref::Dict{Symbol,<:Any}
    )

Computes the starting values for `pbound_aux` and `qbound_aux` variables and adds them to `ref`.
"""
function _compute_boundary_power_start_values_distribution!(nw_ref::Dict{Symbol,<:Any})

    # Vars to store summation of load
    pload_total = 0
    qload_total = 0

    # loop thorugh all loads to add them up.
    for (_, load) in nw_ref[:load]
        pload_total = pload_total + sum(load["pd"])
        qload_total = qload_total + sum(load["qd"])
    end

    # Filters only the ones that have the "distribution_boundary" key. Add start value.
    for (_, conn) in filter(x -> "distribution_boundary" in keys(x.second), nw_ref[:pmitd])
        conn["pbound_aux_start"] = round(pload_total; digits=5)
        conn["qbound_aux_start"] = round(qload_total; digits=5)
    end

end
