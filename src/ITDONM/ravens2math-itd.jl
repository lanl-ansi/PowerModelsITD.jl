function peel_off_feeder!(nw_t, nw_d, feeder_name)

    buses = nw[feeder_name]["ConnectivityNodeContainer.ConnectivityNodes"]
    buses_d = [split.(nw[feeder_name]["ConnectivityNodeContainer.ConnectivityNodes"], ''')[k][2] for k in 1:length(buses)]

	for b in collect(keys(nw["ConnectivityNode"]))
		if b in buses_d
			pop!(nw_t["ConnectivityNode"], b) # remove dist bus from tran nw
		else
			pop!(nw_d["ConnectivityNode"], b) # remove tran bus from dist nw
		end
	end

	equips = nw[feeder_name]["EquipmentContainer.Equipments"]

	equips_d = [split.(nw[feeder_name]["EquipmentContainer.Equipments"], ''')[k][2] for k in 1:length(equips)]

	for eq in collect(keys(nw["PowerSystemResource"]["Equipment"]["ConductingEquipment"]["EnergyConnection"]["EnergyConsumer"]))
		if eq in equips_d
			pop!(nw_t["PowerSystemResource"]["Equipment"]["ConductingEquipment"]["EnergyConnection"]["EnergyConsumer"], eq)
		else
			pop!(nw_d["PowerSystemResource"]["Equipment"]["ConductingEquipment"]["EnergyConnection"]["EnergyConsumer"], eq)
		end
	end

	for eq in collect(keys(nw["PowerSystemResource"]["Equipment"]["ConductingEquipment"]["EnergyConnection"]["EnergySource"]))
		if eq in equips_d
			pop!(nw_t["PowerSystemResource"]["Equipment"]["ConductingEquipment"]["EnergyConnection"]["EnergySource"], eq)
		else
			pop!(nw_d["PowerSystemResource"]["Equipment"]["ConductingEquipment"]["EnergyConnection"]["EnergySource"], eq)
		end
	end


	for eq in collect(keys(nw["PowerSystemResource"]["Equipment"]["ConductingEquipment"]["Conductor"]["ACLineSegment"]))
		if eq in equips_d
			pop!(nw_t["PowerSystemResource"]["Equipment"]["ConductingEquipment"]["Conductor"]["ACLineSegment"], eq)
		else
			pop!(nw_d["PowerSystemResource"]["Equipment"]["ConductingEquipment"]["Conductor"]["ACLineSegment"], eq)
		end
	end

	for eq in collect(keys(nw["PowerSystemResource"]["Equipment"]["ConductingEquipment"]["PowerTransformer"]))
		if eq in equips_d
			pop!(nw_t["PowerSystemResource"]["Equipment"]["ConductingEquipment"]["PowerTransformer"], eq)
		else
			pop!(nw_d["PowerSystemResource"]["Equipment"]["ConductingEquipment"]["PowerTransformer"], eq)
		end
	end

	for eq in collect(keys(nw["PowerSystemResource"]["Equipment"]["ConductingEquipment"]["EnergyConnection"]["RegulatingCondEq"]["RotatingMachine"]))
		if eq in equips_d
			pop!(nw_t["PowerSystemResource"]["Equipment"]["ConductingEquipment"]["EnergyConnection"]["RegulatingCondEq"]["RotatingMachine"], eq)
		else
			pop!(nw_d["PowerSystemResource"]["Equipment"]["ConductingEquipment"]["EnergyConnection"]["RegulatingCondEq"]["RotatingMachine"], eq)
		end
	end

	for eq in collect(keys(nw["PowerSystemResource"]["Equipment"]["ConductingEquipment"]["Switch"]))
		if eq in equips_d
			pop!(nw_t["PowerSystemResource"]["Equipment"]["ConductingEquipment"]["Switch"], eq)
		else
			pop!(nw_d["PowerSystemResource"]["Equipment"]["ConductingEquipment"]["Switch"], eq)
		end
	end

	for eq in collect(keys(nw["PowerSystemResource"]["Equipment"]["ConductingEquipment"]["EnergyConnection"]["RegulatingCondEq"]["ShuntCompensator"]))
		if eq in equips_d
			pop!(nw_t["PowerSystemResource"]["Equipment"]["ConductingEquipment"]["EnergyConnection"]["RegulatingCondEq"]["ShuntCompensator"], eq)
		else
			pop!(nw_d["PowerSystemResource"]["Equipment"]["ConductingEquipment"]["EnergyConnection"]["RegulatingCondEq"]["ShuntCompensator"], eq)
		end
	end

	pop!(nw_t, feeder_name)
	pop!(nw_d, feeder_name)
end

function transform_data_model_ravens_itd(nw)

    nw_t = deepcopy(nw)
    nw_d = deepcopy(nw)

    # convert RAVENS to MATH
    head_keys = collect(keys(nw))
    feeder_keys = String[]
    for key in head_keys
        if haskey(nw[key], "Ravens.cimObjectType")
            if nw[key]["Ravens.cimObjectType"] == "Feeder"
                push!(feeder_keys, key)
            end
        end
    end

    all_d_buses = []
    for feeder_name in feeder_keys
        buses = nw[feeder_name]["ConnectivityNodeContainer.ConnectivityNodes"]        
        for bus in buses
            push!(all_d_buses, bus)
        end
    end


    for feeder_name in feeder_keys
        peel_off_feeder!(nw_t, nw_d, feeder_name)
    end
    
    rd = _PMD.transform_data_model_ravens(nw_d,multinetwork=true)

    t_bus_keys_rv = collect(keys(nw_t["ConnectivityNode"]))
    itd = Dict{String,Any}()
    dc_feeder_key = findfirst(x->nw_d["Group"]["ConnectivityNodeContainer"][x]["Ravens.cimObjectType"]=="Line", collect(keys(nw_d["Group"]["ConnectivityNodeContainer"])))
    dc_feeder_name = collect(keys(nw_d["Group"]["ConnectivityNodeContainer"]))[dc_feeder_key]    
    # loop through lines, see which ones are part of boundary
    let bd_i = 0
        for line_key in collect(keys(nw["PowerSystemResource"]["Equipment"]["ConductingEquipment"]["Conductor"]["ACLineSegment"]))
            bus1_pointer = nw["PowerSystemResource"]["Equipment"]["ConductingEquipment"]["Conductor"]["ACLineSegment"][line_key]["ConductingEquipment.Terminals"][1]["Terminal.ConnectivityNode"]
            bus2_pointer = nw["PowerSystemResource"]["Equipment"]["ConductingEquipment"]["Conductor"]["ACLineSegment"][line_key]["ConductingEquipment.Terminals"][2]["Terminal.ConnectivityNode"]
        tc_pointer = "-1"
        dc_pointer = "-1"
        if bus2_pointer in all_d_buses
            tc_pointer = bus1_pointer
            dc_pointer = bus2_pointer
        else
            tc_pointer = bus2_pointer
            dc_pointer = bus1_pointer
        end	
        if dc_pointer in all_d_buses && !(tc_pointer in all_d_buses) # this is a boundary connector
                bd_i += 1
                pre_tc = _PMD._extract_name(nw["PowerSystemResource"]["Equipment"]["ConductingEquipment"]["Conductor"]["ACLineSegment"][line_key]["ConductingEquipment.Terminals"][1]["Terminal.ConnectivityNode"])
                tc = findfirst(z->z==pre_tc, t_bus_keys_rv)
                itd[string(100000+bd_i)] = Dict{String,Any}(
                "transmission_boundary" => string(tc),
                "distribution_boundary" => dc_feeder_name*".voltage_source.source",
            "source_id" => "ACLineSegment."*line_key)
                pop!(nw_t["PowerSystemResource"]["Equipment"]["ConductingEquipment"]["Conductor"]["ACLineSegment"], line_key)
            end
        end
    end


    pre_rt = transform_data_model_ravens_transmission(nw_t)
    open("118_peeled_PM_temp_DC.json","w") do f
    JSON.print(f, pre_rt, 2)
    end



    rt = JSON.parsefile("118_peeled_PM_temp_DC.json") 

    full_dict = Dict("multiinfrastructure" => true, "per_unit" => true, "it" => Dict())

    full_dict["it"]["pm"] = rt
    full_dict["it"]["pmd"] = rd
    full_dict["it"]["pmitd"] = itd

    return full_dict

end