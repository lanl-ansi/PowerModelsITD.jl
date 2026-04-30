
function _make_curve_data(nws, data_math, path_func)
    curve_data = [Dict(
        "ArCurveData.xvalue" => parse(Float64, nw) * data_math["nw"][nw]["time_elapsed"],
        "ArCurveData.DataValues" => path_func(nw)
    ) for nw in nws]

    return Dict("AnalysisResultCurve.xUnit" => "UnitSymbol.h", "AnalysisResultCurve.CurveDatas" => curve_data)
end

function _get_phases(terminals, phase_mapping)
    return [phase_mapping[x] for x in terminals]
end

function _push_result!(container::Dict, key::String, data::Dict)
    push!(container["AnalysisResult"]["OptimalPowerFlow"][key], data)
end

function _build_voltage_entry(phase, conn_node, data)
    entry = Dict(
        "AnalysisResultData.phase" => phase,
        "ArVoltage.ConnectivityNode" => "ConnectivityNode::'$(conn_node)'",
    )
    merged_entry = merge(entry, data)
    return merged_entry
end

function _build_powerflow_entry(phase, eq_type, eq_name, data)
    entry = Dict(
        "AnalysisResultData.phase" => phase,
        "ArPowerFlow.ConductingEquipment" => "$(eq_type)::'$(eq_name)'",
    )
    merged_entry = merge(entry, data)
    return merged_entry
end

function _build_status_entry(eq_type, eq_name, data)
    entry = Dict(
        "ArStatus.ConductingEquipment" => "$(eq_type)::'$(eq_name)'",
    )
    merged_entry = merge(entry, data)
    return merged_entry
end

function _build_switch_entry(eq_type, eq_name, data)
    entry = Dict(
        "ArSwitch.Switch" => "$(eq_type)::'$(eq_name)'",
    )
    merged_entry = merge(entry, data)
    return merged_entry
end


# -------- FIX States solution from Gurobi ---- Some "state" values for switches are -1.0287133995719573e-10
function _zero_tiny(x; tol=1e-6)
    return abs(x) < tol ? 0.0 : x
end

function _round_almost_integer(x; tol=1e-6)
    # Get the nearest integer to x.
    r = round(Int, x)

    # Check if the absolute difference between x and the nearest integer is within the tolerance.
    # If so, return the integer. Otherwise, return the original floating-point number.
    return abs(x - r) < tol ? r : x
end

function _fix_noninteger_states!(solution_math;  mn_flag::Bool=false)
    if mn_flag
        for (nw_id, nw_data) in solution_math["nw"]
            for (sw_id, sw_sol) in nw_data["switch"]
                sw_sol["state"] = _zero_tiny(sw_sol["state"])
                sw_sol["state"] = _round_almost_integer(sw_sol["state"])
            end
        end
    else
        for (sw_id, sw_sol) in solution_math["switch"]
            sw_sol["state"] = _zero_tiny(sw_sol["state"])
            sw_sol["state"] = _round_almost_integer(sw_sol["state"])
        end
    end
end

#################################


function transform_solution_ravens_transmission(
    solution_math::Dict{String,<:Any},
    data_math::Dict{String,<:Any};
    map::Union{Vector{<:Dict{String,<:Any}},Missing}=missing,
    make_si::Bool=true,
    convert_rad2deg::Bool=true,
    map_math2eng_extensions::Dict{String,<:Function}=Dict{String,Function}(),
    make_si_extensions::Vector{<:Function}=Function[],
    dimensionalize_math_extensions::Dict{String,<:Dict{String,<:Vector{<:String}}}=Dict{String,Dict{String,Vector{String}}}(),
    fix_switch_states::Bool=false,
    phase::String="SinglePhaseKind.A"
)::Dict{String,Any}

    #@assert ismath(data_math) "cannot be converted. Not a MATH model."

    # convert solution to si
    

    solution_math = solution_make_si(
        solution_math,
        data_math;
        mult_vbase=make_si,
        mult_sbase=make_si,
        convert_rad2deg=convert_rad2deg,
        make_si_extensions=make_si_extensions,
        dimensionalize_math_extensions=dimensionalize_math_extensions
    )

    mn_flag = _PMD.ismultinetwork(data_math)
    nws = mn_flag ? sort(collect(keys(solution_math["nw"])), by = x -> parse(Int, x)) : []
    nw_data = mn_flag ? data_math["nw"]["1"] : data_math
    sol = mn_flag ? solution_math["nw"]["1"] : solution_math
    time_elapsed = get(data_math, "time_elapsed", 1.0)

    # Fix Switch states -  "state" values for switches are -1.0287133995719573e-10 coming from some solvers
    if fix_switch_states
        _fix_noninteger_states!(solution_math; mn_flag=mn_flag)
    end

    # PowerFlow solutions for Transformers elements
    seen_xfrmrs = Set{String}()     # Set to save xfrmr names

    # Phase mapping
    phase_mapping = Dict(1 => "SinglePhaseKind.A", 2 => "SinglePhaseKind.B", 3 => "SinglePhaseKind.C")

    solution_ravens = Dict(
        "AnalysisResult" => Dict(
            "OptimalPowerFlow" => Dict(
                "Ravens.cimObjectType" => "OperationsResult",
                "IdentifiedObject.name" => "OptimalPowerFlow",
                "IdentifiedObject.mRID" => "#_$(uppercase(string(UUIDs.uuid4())))",
                "OperationsResult.Voltages" => [],
                "OperationsResult.PowerFlows" => [],
                "OperationsResult.Statuses" => [],
                "OperationsResult.Switches" => []
            )
        )
    )

    # --- Voltages ---
    for (bus_id, bus_data) in sol["bus"]
        #terminals = nw_data["bus"][bus_id]["terminals"]
        conn_node = nw_data["bus"][bus_id]["bus_i"]

            if mn_flag
                data = Dict("AnalysisResultData.Curve" => _make_curve_data(nws, data_math, nw ->
                        begin
                            nw_bus = solution_math["nw"][nw]["bus"][bus_id]
                            v_info = Dict(
                                "AvVoltage.v" => sqrt(nw_bus["w"]) * solution_math["nw"][nw]["settings"]["voltage_scale_factor"],
                                "Ravens.cimObjectType" => "AvVoltage"
                            )
                            # Conditionally add the angle (some do not have it)
                            if haskey(nw_bus, "va")
                                v_info["AvVoltage.angle"] = nw_bus["va"]
                            end
                            return v_info
                        end
                    )
                )
            else
                data = Dict("AnalysisResultData.DataValues" => Dict(
                    "AvVoltage.v" => sqrt(bus_data["w"]) * solution_math["nw"][nw]["settings"]["voltage_scale_factor"],
                    "AvVoltage.angle" => bus_data["va"][i],
                    "Ravens.cimObjectType" => "AvVoltage"
                    )
                )
            end
            _push_result!(solution_ravens, "OperationsResult.Voltages", _build_voltage_entry(phase, conn_node, data))
        end


    # --- Transformers ---
    for (tr_id, tr_data) in get(sol, "transformer", Dict{Any,Dict{String,Any}}())
        # Get xfrmr data
        #terminals = nw_data["transformer"][tr_id]["f_connections"]
        source_id_vect = split(nw_data["transformer"][tr_id]["source_id"], '.')
        cond_eq_type = source_id_vect[2]
        cond_eq_name = source_id_vect[3]
        end_n = parse(Int, source_id_vect[4])

        # PowerFlow
            if mn_flag
                data = Dict("AnalysisResultData.Curve" => _make_curve_data(nws, data_math, nw ->
                        begin
                            nw_tr = solution_math["nw"][nw]["transformer"][tr_id]
                            Dict(
                                "AvPowerFlow.p" => nw_tr["pf"]*solution_math["nw"][nw]["settings"]["power_scale_factor"],
                                "AvPowerFlow.q" => nw_tr["qf"]*solution_math["nw"][nw]["settings"]["power_scale_factor"],
                                "AvPowerFlow.endNumber" => end_n,
                                "Ravens.cimObjectType" => "AvPowerFlow"
                            )
                        end
                    )
                )
            else
                data = Dict("AnalysisResultData.DataValues" => Dict(
                    "AvPowerFlow.p" => tr_data["pf"]*solution_math["nw"][nw]["settings"]["power_scale_factor"],
                    "AvPowerFlow.q" => tr_data["qf"]*solution_math["nw"][nw]["settings"]["power_scale_factor"],
                    "AvPowerFlow.endNumber" => end_n,
                    "Ravens.cimObjectType" => "AvPowerFlow"
                    )
                )
            end
            _push_result!(solution_ravens, "OperationsResult.PowerFlows", _build_powerflow_entry(phase, cond_eq_type, cond_eq_name, data))

        # Status
        if !(cond_eq_name in seen_xfrmrs)
            # Original status from data_math
            tr_status = nw_data["transformer"][tr_id]["status"] == 1 ? true : false
            if mn_flag
                data = Dict("AnalysisResultData.Curve" => _make_curve_data(nws, data_math,nw ->
                        begin
                            if haskey(solution_math["nw"][nw]["transformer"][tr_id], "status")
                                tr_status = Int(solution_math["nw"][nw]["transformer"][tr_id]["status"]) == 1 ? true : false
                            end
                            Dict("AvStatus.inService" => tr_status)
                        end
                    )
                )
            else
                data = Dict("AnalysisResultData.DataValues" => Dict("AvStatus.inService" => tr_status))
            end
            _push_result!(solution_ravens, "OperationsResult.Statuses", _build_status_entry(cond_eq_type, cond_eq_name, data))
        end
        # Store the xfrmr name
        push!(seen_xfrmrs, "$(cond_eq_name)")
    end

    # --- Edge elements (branches, switches, etc.) ---
	edge_elements = ["branch", "switch"]
    for ed in edge_elements
        #println(get(sol, ed, Dict{Any,Dict{String,Any}}()))
        for (ed_id, ed_data) in get(sol, ed, Dict{Any,Dict{String,Any}}())
            # Filter virtual elements that exist in the MATH model
            #if haskey(nw_data[ed][ed_id], "name")
            #if !occursin("virtual", nw_data[ed][ed_id]["name"])
                cond_eq_type = split(nw_data[ed][ed_id]["source_id"], '.')[1]
                cond_eq_name = split(nw_data[ed][ed_id]["source_id"], '.')[2]
                #println(cond_eq_name)
                #cond_eq_type = ed
                #cond_eq_name = ed_id
				# ---- EXCLUSIVE state for Switches ----
				if ed == "switch"
					# initial state from math network data
					sw_state = nw_data[ed][ed_id]["state"] == 1 ? false : true
					if mn_flag
                        data = Dict("AnalysisResultData.Curve" => _make_curve_data(nws, data_math, nw ->
                                begin
                                    nw_ed = solution_math["nw"][nw][ed][ed_id]
                                    if haskey(nw_ed, "state")
                                        sw_state = Int(nw_ed["state"]) == 0 ? true : false
                                    end
                                    Dict("AvSwitch.open" => sw_state)
                                end
                            )
                        )
                    else
                        data = Dict("AnalysisResultData.DataValues" => Dict("AvSwitch.open" => sw_state))
                    end
                    _push_result!(solution_ravens, "OperationsResult.Switches", _build_switch_entry(cond_eq_type, cond_eq_name, data))
		        end

				# --- PowerFlow ---
				num_ends = 1 # TODO: (Optional) Change to 2 if you would like to get both 'to' and 'from' flows for edge elements
				for end_n in 1:num_ends
                    # information related to direction flow, terminals, and phases
                    #if end_n == 1
                        p_flow, q_flow = ("pf", "qf")
                    #else
                        p_flow, q_flow = ("pt", "qt")
					#conn_flow, p_flow, q_flow = end_n == 1 ? ("f_connections", "pf", "qf") : ("t_connections", "pt", "qt")
					#terminals = nw_data[ed][ed_id][conn_flow]
                        if mn_flag
                            data = Dict("AnalysisResultData.Curve" => _make_curve_data(nws, data_math, nw ->
                                    begin
                                        nw_ed = solution_math["nw"][nw][ed][ed_id]
                                        Dict(
                                            "AvPowerFlow.p" => nw_ed[p_flow]*solution_math["nw"][nw]["settings"]["power_scale_factor"],
                                            "AvPowerFlow.q" => nw_ed[q_flow]*solution_math["nw"][nw]["settings"]["power_scale_factor"],
                                            "AvPowerFlow.endNumber" => end_n,
                                            "Ravens.cimObjectType" => "AvPowerFlow"
                                        )
                                    end
                                )
                            )
                            #println(data)
                        else
                            data = Dict(
                                "AnalysisResultData.DataValues" => Dict(
                                "AvPowerFlow.p" => ed_data[p_flow]*solution_math["nw"][nw]["settings"]["power_scale_factor"],
                                "AvPowerFlow.q" => ed_data[q_flow]*solution_math["nw"][nw]["settings"]["power_scale_factor"],
                                "AvPowerFlow.endNumber" => end_n,
                                "Ravens.cimObjectType" => "AvPowerFlow"
                                )
                            )
                        end
					  _push_result!(solution_ravens, "OperationsResult.PowerFlows", _build_powerflow_entry(phase, cond_eq_type, cond_eq_name, data))
				  #end

                # --- Statuses ----
                obj_prfx = ""
                if ed == "branch"
                    obj_prfx = "br_"
                end

                ed_status = nw_data[ed][ed_id]["$(obj_prfx)status"] == 1 ? true : false
                if mn_flag
                    data = Dict("AnalysisResultData.Curve" => _make_curve_data(nws, data_math, nw ->
                            begin
                                #nw_ed = solution_math["nw"][nw][ed][ed_id]
                                if haskey(solution_math["nw"][nw][ed][ed_id], "status")
                                    ed_status = Int(solution_math["nw"][nw][ed][ed_id]["status"]) == 1 ? true : false
                                end
                                Dict("AvStatus.inService" => ed_status)
                            end
                        )
                    )
                else
                    data = Dict("AnalysisResultData.DataValues" => Dict("AvStatus.inService" => ed_status))
                end
                _push_result!(solution_ravens, "OperationsResult.Statuses", _build_status_entry(cond_eq_type, cond_eq_name, data))
            end

            #end
        #end
    end
    #println(solution_ravens)

    # --- Node elements (gens, loads, storage) ---
    node_elements = ["gen", "load"]
    for nd in node_elements        #println(get(sol, nd, Dict{Any,Dict{String,Any}}()))
        for (nd_id, nd_data) in get(sol, nd, Dict{Any,Dict{String,Any}}())
                cond_eq_type = split(nw_data[nd][nd_id]["source_id"], '.')[1]
                cond_eq_name = split(nw_data[nd][nd_id]["source_id"], '.')[2]
                #terminals = nw_data[nd][nd_id]["connections"]

                if nd == "load"
                    p_key = "pd"
                    q_key = "qd"
                elseif nd == "gen"
                    p_key = "pg"
                    q_key = "qg"
                elseif nd == "storage"
                    p_key = "ps"
                    q_key = "qs"
                else
                    p_key = "p"
                    q_key = "q"
                end

                # PowerFlow
                     if mn_flag
                        data = Dict("AnalysisResultData.Curve" => _make_curve_data(nws, data_math, nw ->
                                begin
                                    nw_nd = solution_math["nw"][nw][nd][nd_id]
                                    Dict(
                                        "AvPowerFlow.p" => nw_nd[p_key]*solution_math["nw"][nw]["settings"]["power_scale_factor"],
                                        "AvPowerFlow.q" => nw_nd[q_key]*solution_math["nw"][nw]["settings"]["power_scale_factor"],
                                        "Ravens.cimObjectType" => "AvPowerFlow"
                                    )
                                end
                            )
                        )
                    else
                        data = Dict("AnalysisResultData.DataValues" => Dict(
                            "AvPowerFlow.p" => nd_data[p_key]*solution_math["nw"][nw]["settings"]["power_scale_factor"],
                            "AvPowerFlow.q" => nd_data[q_key]*solution_math["nw"][nw]["settings"]["power_scale_factor"],
                            "Ravens.cimObjectType" => "AvPowerFlow"
                            )
                        )
                    end
                    #println(cond_eq_name)
                    #println(data)
                    _push_result!(solution_ravens, "OperationsResult.PowerFlows", _build_powerflow_entry(phase, cond_eq_type, cond_eq_name, data))
                end
        end
    end

    return solution_ravens

end


