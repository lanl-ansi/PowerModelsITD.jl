function locate_voltage_source(buses)
	source_ind = -1
	virtual_found = false
	bus_keys = collect(keys(buses))
	for bus in bus_keys
		println(buses[bus])
		bus_id = split(buses[bus]["source_id"], ".")
		source_type = bus_id[1]
		bus_name = bus_id[2]
		if source_type == "EnergySource"
			source_ind = parse(Int64,bus)
			virtual_found = true
		end
		if bus_name == "sourcebus" && virtual_found == false
			source_ind = parse(Int64, bus)
		end
	end
	return source_ind
end

function revise_names_source_ids!(source_ind, nw_keys, full_dict, dc_feeder_name)
	for b in collect(keys((full_dict["it"]["pm"]["bus"])))
		full_dict["it"]["pm"]["bus"][b]["source_id"] = ["bus", parse(Int,b)]
		full_dict["it"]["pm"]["bus"][b]["source_id"] = ["bus", parse(Int,b)]

	end

	for nw in nw_keys
		full_dict["it"]["pmd"]["nw"][nw]["bus"][string(source_ind)]["source_id"] = "voltage_source."*dc_feeder_name*".source"
	end

	full_dict["it"]["pmitd"] = Dict{String,Any}(full_dict["it"]["pmitd"])
	boundary_keys = collect(keys(full_dict["it"]["pmitd"]))
	for bd_key in boundary_keys
		full_dict["it"]["pmitd"][bd_key]["distribution_boundary"] = dc_feeder_name*".voltage_source.source"
	end

	full_dict["it"]["pmd"]["name"] = dc_feeder_name


	d_load_keys = collect(keys((full_dict["it"]["pmd"]["nw"]["1"]["load"])))
	t_load_keys = collect(keys((full_dict["it"]["pm"]["load"])))
	for ld in d_load_keys
		orig_name = full_dict["it"]["pmd"]["nw"]["1"]["load"][ld]["name"]
		for nw in nw_keys
			full_dict["it"]["pmd"]["nw"][nw]["load"][ld]["name"] = dc_feeder_name*"."*orig_name
		end
	end

	for ld in t_load_keys
		full_dict["it"]["pm"]["load"][ld]["index"] = parse(Int,ld)
	end
end

function set_voltage_bounds_math!(full_dict; vmin=0.9, vmax=1.1) 
	for nw in nw_keys
    		for bus in bus_keys
	   		 #if bus != string(source_ind) 
				 full_dict["it"]["pmd"]["nw"][nw]["bus"][bus]["vmin"]= vmin * ones(3)
				 full_dict["it"]["pmd"]["nw"][nw]["bus"][bus]["vmax"]= vmax * ones(3) 
			#else
			#	 full_dict["it"]["pmd"]["nw"][nw]["bus"][bus]["vmin"]= 0.0 * ones(3)
			#	 full_dict["it"]["pmd"]["nw"][nw]["bus"][bus]["vmax"]= [Inf, Inf, Inf] 
			#end
   		 end
	end
end

function bound_switch_closures!(nw_keys, full_dict; close_ub::Int64 = 1)
	for nw in nw_keys
		full_dict["it"]["pmd"]["nw"][nw]["switch_close_actions_ub"] = close_ub
	end
end

function create_dummy_generator!(nw_keys, full_dict,gen_dummy_ind)
# Gotcha #3 -- a dummy generator so the ref has a distribution slack to filter
	gens = full_dict["it"]["pmd"]["nw"]["1"]["gen"]
	gen_keys = collect(keys(gens))
	N_gen = length(gen_keys)
	gen_source_ind = "-1"
	for gen in gen_keys
		gen_id = split(gens[gen]["source_id"], ".")
		gen_type = gen_id[1]
		if gen_type == "EnergySource"
			gen_source_ind = gen
		end
	end
	#gen_dummy_ind = string(N_gen+1)
	for nw in nw_keys
		full_dict["it"]["pmd"]["nw"][nw]["gen"][gen_dummy_ind] = deepcopy(full_dict["it"]["pmd"]["nw"][nw]["gen"][gen_source_ind])
		full_dict["it"]["pmd"]["nw"][nw]["gen"][gen_dummy_ind]["pmin"] = [0.0, 0.0, 0.0]
		full_dict["it"]["pmd"]["nw"][nw]["gen"][gen_dummy_ind]["pmax"] = [0.0, 0.0, 0.0]
		full_dict["it"]["pmd"]["nw"][nw]["gen"][gen_dummy_ind]["qmin"] = [0.0, 0.0, 0.0]
		full_dict["it"]["pmd"]["nw"][nw]["gen"][gen_dummy_ind]["qmax"] = [0.0, 0.0, 0.0]
	end
end

function create_source_outage!(nw_keys, full_dict; create_outage=true)
	nw_keys = collect(keys(full_dict["it"]["pmd"]["nw"]))
	gens = full_dict["it"]["pmd"]["nw"]["1"]["gen"]
	gen_keys = collect(keys(gens))
	N_gen = length(gen_keys)
	gen_source_ind = "-1"
	for gen in gen_keys
		gen_id = split(gens[gen]["source_id"], ".")
		gen_type = gen_id[1]
		if gen_type == "EnergySource"
			gen_source_ind = gen
		end
	end
	gen_dummy_ind = string(N_gen+1)

	if create_outage == true
		for nw_k in nw_keys
			full_dict["it"]["pmd"]["nw"][nw_k]["gen"][gen_source_ind]["gen_status"] = Int(_ONM.DISABLED)
			create_dummy_generator!(nw_keys, full_dict,gen_dummy_ind)
			full_dict["it"]["pmd"]["nw"][nw_k]["gen"][gen_dummy_ind]["gen_status"] = Int(_ONM.ENABLED)
		end
	end
end

function create_transmission_settings!(nw_keys, itd_data, r)
    nw_keys = collect(keys(itd_data["it"]["pm"]["nw"]))
    for nw in nw_keys
        itd_data["it"]["pm"]["nw"][nw]["settings"] = deepcopy(itd_data["it"]["pmd"]["nw"][nw]["settings"])
        itd_data["it"]["pm"]["nw"][nw]["settings"]["sbase_default"] = itd_data["it"]["pm"]["nw"][nw]["baseMVA"]
        itd_data["it"]["pm"]["nw"][nw]["settings"]["vbases_default"] = Dict{String, Real}()
        for bus in collect(keys(r["solution"]["it"]["pm"]["nw"][nw]["bus"]))
            push!(itd_data["it"]["pm"]["nw"][nw]["settings"]["vbases_default"], bus => itd_data["it"]["pm"]["nw"][nw]["bus"][bus]["base_kv"])
        end
        itd_data["it"]["pm"]["nw"][nw]["settings"]["voltage_scale_factor"] = 1000.0 # assuming everything is in kV
        itd_data["it"]["pm"]["nw"][nw]["settings"]["sbase"] = itd_data["it"]["pm"]["nw"][nw]["baseMVA"]
        itd_data["it"]["pm"]["nw"][nw]["settings"]["power_scale_factor"] = 1E6 #megawatts to watts
        r["solution"]["it"]["pm"]["nw"][nw]["settings"] = deepcopy(itd_data["it"]["pm"]["nw"][nw]["settings"])
    end
end

function math2ravens_itd_setup!(full_dict, r)
	full_dict["it"]["pm"]["per_unit"] = true
    nw_keys = collect(keys(full_dict["it"]["pmd"]["nw"]))
	for nw in nw_keys
		r["solution"]["it"]["pm"]["nw"][nw]["per_unit"] = true
		full_dict["it"]["pm"]["nw"][nw]["time_elapsed"] = get(full_dict["it"]["pmd"]["nw"][nw], "time_elapsed", 1.0)
		full_dict["it"]["pmitd"]["nw"][nw]["time_elapsed"] = get(full_dict["it"]["pmd"]["nw"][nw], "time_elapsed", 1.0)
	end
end


function extract_first_number(str)
    # Remove the parentheses
    str = strip(str, ['(', ')'])

    # Split the string by the comma
    nums = split(str, ",")

    # Convert the first element to an integer
    num1 = parse(Int, nums[1])

    return num1
end

function _make_curve_data(nws, data_math, path_func)
    curve_data = [Dict(
        "ArCurveData.xvalue" => parse(Float64, nw) * data_math["nw"][nw]["time_elapsed"],
        "ArCurveData.DataValues" => path_func(nw)
    ) for nw in nws]

    return Dict("AnalysisResultCurve.xUnit" => "UnitSymbol.h", "AnalysisResultCurve.CurveDatas" => curve_data)
end
