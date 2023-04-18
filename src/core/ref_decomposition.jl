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

        # Dictionary (temporary) to store the boundary buses transmission where loads have already been removed
        boundary_buses_transmission = Dict{String, Any}()

        # Filters only the ones that have the "transmission_boundary" key
        for (i, conn) in filter(x -> "transmission_boundary" in keys(x.second), boundaries)

            if !haskey(boundary_buses_transmission, string(conn["transmission_boundary"]))
                # Get init (start) values before deleting the boundary load info.
                pd_start = nw_ref[:load][nw_ref[:bus_loads][conn["transmission_boundary"]][1]]["pd"]
                qd_start = nw_ref[:load][nw_ref[:bus_loads][conn["transmission_boundary"]][1]]["qd"]
                conn["pbound_load_start"] = pd_start
                conn["qbound_load_start"] = qd_start
                conn["pbound_load_scaled_start"] = pd_start*(conn["base_conv_factor"])
                conn["qbound_load_scaled_start"] = qd_start*(conn["base_conv_factor"])

                # Add start values to local dict to use only when a conn (boundary) is repeated
                boundary_buses_transmission[string(conn["transmission_boundary"])] = Dict("pbound_load_start" => pd_start,
                                                                                        "qbound_load_start" => qd_start,
                                                                                        "pbound_load_scaled_start" => conn["pbound_load_scaled_start"],
                                                                                        "qbound_load_scaled_start" => conn["qbound_load_scaled_start"]
                                                                                    )

                # Remove loads - Delete the boundary load info.
                nw_ref[:load] = Dict(x for x in nw_ref[:load] if x.second["load_bus"] != conn["transmission_boundary"] )
                nw_ref[:bus_loads][conn["transmission_boundary"]] = []
            else
                conn["pbound_load_start"] = boundary_buses_transmission[string(conn["transmission_boundary"])]["pbound_load_start"]
                conn["qbound_load_start"] = boundary_buses_transmission[string(conn["transmission_boundary"])]["qbound_load_start"]
                conn["pbound_load_scaled_start"] = boundary_buses_transmission[string(conn["transmission_boundary"])]["pbound_load_scaled_start"]
                conn["qbound_load_scaled_start"] = boundary_buses_transmission[string(conn["transmission_boundary"])]["qbound_load_scaled_start"]
            end
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

        # Modify v_min and v_max, remove va and vm, and change bus type for reference bus
        boundary = nw_ref[:pmitd]   # boundary info.

        # get boundary number
        boundary_keys = collect(keys(boundary))
        boundary_number = boundary_keys[1]
        boundary_data = boundary[boundary_number]

        # These limits are extremely important. If not present, subproblems has a lot of problems converging
        nw_ref[:bus][boundary_data["distribution_boundary"]]["vmin"] = [0.9, 0.9, 0.9]
        nw_ref[:bus][boundary_data["distribution_boundary"]]["vmax"] = [1.5, 1.5, 1.5]

        # Modify slack gen cost.
        for (gen_indx, gen_data) in  nw_ref[:gen]
            if (gen_data["gen_bus"] == boundary_data["distribution_boundary"])
                cost_length = length(gen_data["cost"])
                gen_data["cost"] = zeros(cost_length)
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

    boundary_keys = ["f_bus", "t_bus", "index", "name", "f_connections", "t_connections",
                        "ckt_name", "pbound_load_start", "qbound_load_start", "base_conv_factor",
                        "pbound_load_scaled_start", "qbound_load_scaled_start"
    ]
    boundary_defaults = [0, 0, 0, "empty", [1], [1, 2, 3], "empty", 0, 0, 0, 0, 0]

    for (_, nw_ref) in ref[:it][:pm][:nw]

        boundaries = nw_ref[:pmitd]

        for i in 1:length(boundaries)
            boundary_number = BOUNDARY_NUMBER - 1 + i

            if !haskey(nw_ref, :boundary)
                nw_ref[:boundary] = Dict(boundary_number => Dict(boundary_keys .=> boundary_defaults))
            else
                nw_ref[:boundary][boundary_number] = Dict(boundary_keys .=> boundary_defaults)
            end

            boundary = nw_ref[:boundary][boundary_number]
            boundary_info = boundaries[boundary_number]

            boundary["f_bus"] = get(boundary_info, "transmission_boundary", 0)
            boundary["t_bus"] = get(boundary_info, "distribution_boundary", 0)
            boundary["index"] = boundary_number
            boundary["ckt_name"] = get(boundary_info, "ckt_name", "empty")
            boundary["name"] = "_itd_boundary_$boundary_number"
            boundary["pbound_load_start"] = get(boundary_info, "pbound_load_start", 0)
            boundary["qbound_load_start"] = get(boundary_info, "qbound_load_start", 0)
            boundary["pbound_load_scaled_start"] = get(boundary_info, "pbound_load_scaled_start", 0)
            boundary["qbound_load_scaled_start"] = get(boundary_info, "qbound_load_scaled_start", 0)
            boundary["base_conv_factor"] = get(boundary_info, "base_conv_factor", 0)

            trans_bus = boundary["f_bus"]
            dist_bus = boundary["t_bus"]

            if !haskey(nw_ref, :boundary_bus_from)
                nw_ref[:boundary_bus_from] = Dict(trans_bus => Dict("boundary" => boundary_number))
            else
                nw_ref[:boundary_bus_from][trans_bus] = Dict("boundary" => boundary_number)
            end

            if !haskey(nw_ref, :boundary_bus_to)
                nw_ref[:boundary_bus_to] = Dict(dist_bus => Dict("boundary" => boundary_number))
            else
                nw_ref[:boundary_bus_to][dist_bus] = Dict("boundary" => boundary_number)
            end

            arcs_boundary_from = Vector{Tuple{Int, Int, Int}}(undef, length(nw_ref[:boundary]))
            arcs_boundary_to = Vector{Tuple{Int, Int, Int}}(undef, length(nw_ref[:boundary]))

            i = 1
            for (num, b) in nw_ref[:boundary]
                arcs_boundary_from[i] = (num, b["f_bus"], b["t_bus"])
                arcs_boundary_to[i] = (num, b["t_bus"], b["f_bus"])
                i += 1
            end

            nw_ref[:arcs_boundary_from] = arcs_boundary_from
            nw_ref[:arcs_boundary_to] = arcs_boundary_to
            nw_ref[:arcs_boundary] = vcat(arcs_boundary_from, arcs_boundary_to)

            type = "boundary"

            bus_arcs_from = Dict{Int, Vector{Tuple{Int, Int, Int}}}()
            bus_arcs_to = Dict{Int, Vector{Tuple{Int, Int, Int}}}()

            for (l, i, j) in arcs_boundary_from
                if !haskey(bus_arcs_from, i)
                    bus_arcs_from[i] = Tuple{Int, Int, Int}[]
                end
                push!(bus_arcs_from[i], (l, i, j))
            end
            nw_ref[Symbol("bus_arcs_$(type)_from")] = bus_arcs_from

            for (l, i, j) in arcs_boundary_to
                if !haskey(bus_arcs_to, i)
                    bus_arcs_to[i] = Tuple{Int, Int, Int}[]
                end
                push!(bus_arcs_to[i], (l, i, j))
            end
            nw_ref[Symbol("bus_arcs_$(type)_to")] = bus_arcs_to

            conns_from = Dict{Int, Vector{Tuple{Tuple{Int, Int, Int}, Vector{Int}}}}()
            conns_to = Dict{Int, Vector{Tuple{Tuple{Int, Int, Int}, Vector{Int}}}}()

            for obj in values(nw_ref[:boundary])
                f_bus = obj["f_bus"]
                t_bus = obj["t_bus"]
                if !haskey(conns_from, f_bus)
                    conns_from[f_bus] = []
                end
                if !haskey(conns_to, t_bus)
                    conns_to[t_bus] = []
                end
                push!(conns_from[f_bus], ((obj["index"], f_bus, t_bus), obj["f_connections"]))
                push!(conns_to[t_bus], ((obj["index"], t_bus, f_bus), obj["t_connections"]))
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
    for (_, nw_ref) in ref[:it][:pmd][:nw]
        boundaries = nw_ref[:pmitd]
        boundary_number = first(keys(boundaries))

        if !haskey(nw_ref, :boundary)
            nw_ref[:boundary] = Dict(boundary_number => Dict(
                "f_bus" => 0, "t_bus" => 0, "index" => boundary_number,
                "name" => "empty", "f_connections" => [1],
                "t_connections" => [1, 2, 3], "ckt_name" => "empty",
                "pbound_aux_start" => 0, "qbound_aux_start" => 0))
        else
            nw_ref[:boundary][boundary_number] = Dict(
                "f_bus" => 0, "t_bus" => 0, "index" => boundary_number,
                "name" => "empty", "f_connections" => [1],
                "t_connections" => [1, 2, 3], "ckt_name" => "empty",
                "pbound_aux_start" => 0, "qbound_aux_start" => 0)
        end

        _compute_boundary_power_start_values_distribution!(nw_ref)

        boundary = nw_ref[:boundary][boundary_number]
        boundary_info = boundaries[boundary_number]

        boundary["f_bus"] = get(boundary_info, "transmission_boundary", 0)
        boundary["t_bus"] = get(boundary_info, "distribution_boundary", 0)
        boundary["ckt_name"] = get(boundary_info, "ckt_name", "empty")
        boundary["name"] = "_itd_boundary_$boundary_number"
        boundary["pbound_aux_start"] = get(boundary_info, "pbound_aux_start", 0)
        boundary["qbound_aux_start"] = get(boundary_info, "qbound_aux_start", 0)

        trans_bus = boundary["f_bus"]
        dist_bus = boundary["t_bus"]

        if !haskey(nw_ref, :boundary_bus_from)
            nw_ref[:boundary_bus_from] = Dict(trans_bus => Dict("boundary" => boundary_number))
        else
            nw_ref[:boundary_bus_from][trans_bus] = Dict("boundary" => boundary_number)
        end

        if !haskey(nw_ref, :boundary_bus_to)
            nw_ref[:boundary_bus_to] = Dict(dist_bus => Dict("boundary" => boundary_number))
        else
            nw_ref[:boundary_bus_to][dist_bus] = Dict("boundary" => boundary_number)
        end

        arcs_boundary_from = Vector{Tuple{Int, Int, Int}}(undef, length(nw_ref[:boundary]))
        arcs_boundary_to = Vector{Tuple{Int, Int, Int}}(undef, length(nw_ref[:boundary]))

        i = 1
        for (num, b) in nw_ref[:boundary]
            arcs_boundary_from[i] = (num, b["f_bus"], b["t_bus"])
            arcs_boundary_to[i] = (num, b["t_bus"], b["f_bus"])
            i += 1
        end

        nw_ref[:arcs_boundary_from] = arcs_boundary_from
        nw_ref[:arcs_boundary_to] = arcs_boundary_to
        nw_ref[:arcs_boundary] = vcat(arcs_boundary_from, arcs_boundary_to)

        type = "boundary"

        bus_arcs_from = Dict{Int, Vector{Tuple{Int, Int, Int}}}()
        bus_arcs_to = Dict{Int, Vector{Tuple{Int, Int, Int}}}()

        for (l, i, j) in arcs_boundary_from
            if !haskey(bus_arcs_from, i)
                bus_arcs_from[i] = Tuple{Int, Int, Int}[]
            end
            push!(bus_arcs_from[i], (l, i, j))
        end
        nw_ref[Symbol("bus_arcs_$(type)_from")] = bus_arcs_from

        for (l, i, j) in arcs_boundary_to
            if !haskey(bus_arcs_to, i)
                bus_arcs_to[i] = Tuple{Int, Int, Int}[]
            end
            push!(bus_arcs_to[i], (l, i, j))
        end
        nw_ref[Symbol("bus_arcs_$(type)_to")] = bus_arcs_to

        conns_from = Dict{Int, Vector{Tuple{Tuple{Int, Int, Int}, Vector{Int}}}}()
        conns_to = Dict{Int, Vector{Tuple{Tuple{Int, Int, Int}, Vector{Int}}}}()

        for obj in values(nw_ref[:boundary])
            f_bus = obj["f_bus"]
            t_bus = obj["t_bus"]
            if !haskey(conns_from, f_bus)
                conns_from[f_bus] = []
            end
            if !haskey(conns_to, t_bus)
                conns_to[t_bus] = []
            end
            push!(conns_from[f_bus], ((obj["index"], f_bus, t_bus), obj["f_connections"]))
            push!(conns_to[t_bus], ((obj["index"], t_bus, f_bus), obj["t_connections"]))
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
