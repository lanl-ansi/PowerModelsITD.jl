function retrieve_bus_from_string(string)
    strs = split(string, "'")
    bus_str = strs[2]
    bus_int = parse(Int64, bus_str)
    return bus_int
end

function retrieve_basev_from_string(string)
    strs = split(string, "'")
    mva_str = strs[2]
    return mva_str
end

#=function get_gen_buses(gens_rv)
    gen_buses = []
    gens = []
    for g in 1:length(gens_rv)
        gb = retrieve_bus_from_string(gens_rv["gen"*string(g)]["ConductingEquipment.Terminals"][1]["Terminal.ConnectivityNode"])
        push!(gen_buses, gb)
        push!(gens, g)
    end
    return gens,gen_buses
end
=#

#=function get_load_buses(loads_rv)
    ldld = collect(keys(loads_rv))
    present_loads = [ldld[i] for i in 1:length(ldld) if isassigned(ldld, i)]
    load_buses = []
    loads = []
    for ld in present_loads
        lb = retrieve_bus_from_string(loads_rv[ld]["ConductingEquipment.Terminals"][1]["Terminal.ConnectivityNode"])
        push!(loads, ld)
        push!(load_buses, lb)
    end
    return loads, load_buses
end=#

function get_gen_buses(gens_rv)
    gg = sort(collect(keys(gens_rv)))  # ADD sort()
    present_gens = [gg[i] for i in 1:length(gg) if isassigned(gg, i)]
    gen_buses = []
    gens = []
    for g in present_gens
        gb = gens_rv[g]["ConductingEquipment.Terminals"][1]["Terminal.ConnectivityNode"]
        push!(gen_buses, gb)
        push!(gens, g)
    end
    return gens, gen_buses
end

function get_load_buses(loads_rv)
    ldld = sort(collect(keys(loads_rv)))  # ADD sort()
    present_loads = [ldld[i] for i in 1:length(ldld) if isassigned(ldld, i)]
    load_buses = []
    loads = []
    for ld in present_loads
        lb = loads_rv[ld]["ConductingEquipment.Terminals"][1]["Terminal.ConnectivityNode"]
        push!(loads, ld)
        push!(load_buses, lb)
    end
    return loads, load_buses
end

function _get_id_from_key(key)
    return parse(Int, replace(key, r"\D" => "")) 
end

function _extract_name(element)

    name = replace(split(element, "::")[2], "'" => "")
    return name
end

function transform_data_model_ravens_transmission(nw)

    watt_divider = 1E6

    # pull everything
    buses_rv = nw["ConnectivityNode"]
    loads_rv = nw["PowerSystemResource"]["Equipment"]["ConductingEquipment"]["EnergyConnection"]["EnergyConsumer"]
    oplims_rv = nw["OperationalLimitSet"]
    gens_rv = nw["PowerSystemResource"]["Equipment"]["ConductingEquipment"]["EnergyConnection"]["RegulatingCondEq"]["RotatingMachine"]
    gencosts_rv = nw["ProducerCostFunction"]
    basemva_rv = nw["MySettings"]["ApplicationSettings.Settings"][1]["value"]
    basev_rv = nw["BaseVoltage"]
    lines_rv = nw["PowerSystemResource"]["Equipment"]["ConductingEquipment"]["Conductor"]["ACLineSegment"]
    trnfmrs_rv = nw["PowerSystemResource"]["Equipment"]["ConductingEquipment"]["PowerTransformer"]
    taps_rv = nw["PowerSystemResource"]["TapChanger"]["RatioTapChanger"]
    shunts_rv = nw["PowerSystemResource"]["Equipment"]["ConductingEquipment"]["EnergyConnection"]["RegulatingCondEq"]["ShuntCompensator"]
    shifts_rv = nw["PowerSystemResource"]["TapChanger"]["PhaseTapChanger"]

    bb = sort(collect(keys(buses_rv)))
    present_buses = [bb[i] for i in 1:length(bb) if isassigned(bb, i)]
    #present_buses = sort(collect(string.(1:118)))

    # prepare buses
    bus_dict = Dict()
    for xx in present_buses
        freeze_bus_type = false
        bus_key = xx
        b = findfirst(z->z==xx, present_buses)
        push!(bus_dict, b  => Dict{String, Any}())
        zone = 1
        bus_i = b
        gs = get_gen_buses(gens_rv)[1]
        lds = get_load_buses(loads_rv)[1]
        gbs = get_gen_buses(gens_rv)[2]
        lbs = get_load_buses(loads_rv)[2]
        base_kv = 0
        oplim = buses_rv[bus_key]["ConnectivityNode.OperationalLimitSet"]
        oplim_key = _extract_name(oplim)
        bus_id = bus_key
        if length(oplims_rv[oplim_key]["OperationalLimitSet.OperationalLimitValue"]) == 3
            println("found slack bus")
            bus_type = 3 # slack bus
            freeze_bus_type = true
            vmax = oplims_rv[oplim_key]["OperationalLimitSet.OperationalLimitValue"][3]["VoltageLimit.value"]
            vmin = oplims_rv[oplim_key]["OperationalLimitSet.OperationalLimitValue"][2]["VoltageLimit.value"]
        else
            vmax = oplims_rv[oplim_key]["OperationalLimitSet.OperationalLimitValue"][2]["VoltageLimit.value"]
            vmin = oplims_rv[oplim_key]["OperationalLimitSet.OperationalLimitValue"][1]["VoltageLimit.value"]
            # need to search for generators
            #=if bus_id in gbs
                bus_type = 2
            else
                bus_type = 1
            end=#
        end     
        name = b
        area = 1
        index = b
        va = buses_rv[bus_key]["ConnectivityNode.SvVoltage"][1]["SvVoltage.angle"]
        vm = buses_rv[bus_key]["ConnectivityNode.SvVoltage"][1]["SvVoltage.v"]
        if "ConnectivityNode::'"*bus_key*"'" in lbs
            ld_ind = findfirst(x->x=="ConnectivityNode::'"*bus_key*"'", lbs)
            basev = retrieve_basev_from_string(loads_rv[lds[ld_ind]]["ConductingEquipment.BaseVoltage"])
            base_kv = basev_rv[string(basev)]["BaseVoltage.nominalVoltage"] / 1000
            if freeze_bus_type == false
                bus_type = 1
            end
        end
        if "ConnectivityNode::'"*bus_key*"'" in gbs
            gen_ind = findfirst(x->x=="ConnectivityNode::'"*bus_key*"'", gbs)
            basev = retrieve_basev_from_string(gens_rv[gs[gen_ind]]["ConductingEquipment.BaseVoltage"])
            base_kv = basev_rv[string(basev)]["BaseVoltage.nominalVoltage"] / 1000
            if freeze_bus_type == false
                bus_type = 2
            end
        end
        voltage_divider = base_kv * 1000
        push!(bus_dict[b], "zone" => zone, 
            "bus_i" => bus_i,
            "bus_type" => bus_type,
            "source_id" => "ConnectivityNode."*bus_key,
            "vmax" => vmax / voltage_divider,
            "area" => area,
            "vmin" => vmin / voltage_divider,
            "index" => index,
            "va" => va,# * (180 / pi),
            "vm" => vm / voltage_divider,
            "base_kv" => base_kv
        )
    end

    # prepare loads
    load_dict = Dict()
    ind = 0
    x = sort(collect(keys(loads_rv)))
    present_loads = [x[i] for i in 1:length(x) if isassigned(x, i)]
    watt_divider = 1E6
    lds = get_load_buses(loads_rv)[1]
    lbs = get_load_buses(loads_rv)[2]
    for xx in present_buses
        ld = xx
        if "ConnectivityNode::'"*ld*"'" in lbs
            #ld_ind = findfirst(x->x==b, _get_id_from_key.(lbs))
            ld_ind = findfirst(x->x=="ConnectivityNode::'"*ld*"'", lbs)
            load_key = lds[ld_ind]
            pre_load_bus = _extract_name(loads_rv[load_key]["ConductingEquipment.Terminals"][1]["Terminal.ConnectivityNode"])
            load_bus = findfirst(z->z==pre_load_bus, present_buses)
            status = 1
            qd = loads_rv[load_key]["EnergyConsumer.q"]
            pd = loads_rv[load_key]["EnergyConsumer.p"]
            if qd != 0.0 || pd != 0.0
            ind += 1
                push!(load_dict, ind  => Dict{String, Any}())
                push!(load_dict[ind], "load_bus" => load_bus,
                    "status" => status, 
                    "qd" => qd / watt_divider,
                    "pd" => pd / watt_divider,
                    "source_id" => "EnergyConsumer."*load_key
                    )
            end
        end
    end

  # prepare gens (quadratic costs only)

    gen_dict = Dict()
    q = sort(collect(keys(gens_rv)))
    present_gens = [q[i] for i in 1:length(q) if isassigned(q, i)]
    gen_k = 0
    for gen_key in present_gens
        gen_k += 1
        push!(gen_dict, gen_k => Dict{String, Any}())
        ncost = 3 #quadratic costs always assumed for now
        qc1max = 0
        pg = gens_rv[gen_key]["RotatingMachine.p"]
        model = 2 # polynomial cost function
        gencost_key = _extract_name(gens_rv[gen_key]["RotatingMachine.CostFunction"])
        startup = gencosts_rv[gencost_key]["ProducerCostFunction.startupCost"]
        shutdown = gencosts_rv[gencost_key]["ProducerCostFunction.shutdownCost"]
        qc2max = 0
        ramp_agc = 0
        qg = gens_rv[gen_key]["RotatingMachine.q"]
        pre_gen_bus = _extract_name(gens_rv[gen_key]["ConductingEquipment.Terminals"][1]["Terminal.ConnectivityNode"])
        gen_bus = findfirst(z->z==pre_gen_bus, present_buses)
        pmax = gens_rv[gen_key]["RotatingMachine.GeneratingUnit"]["GeneratingUnit.maxOperatingP"]
        ramp_10 = 0
        mbase = basemva_rv
        pc2 = 0
        index = gen_k
        cost_0 = gencosts_rv[gencost_key]["ProducerCostFunction.CostParameters"][1]["PolynomialCostParameter.costCoefficient"]
        cost_1 = gencosts_rv[gencost_key]["ProducerCostFunction.CostParameters"][2]["PolynomialCostParameter.costCoefficient"]
        cost_2 = gencosts_rv[gencost_key]["ProducerCostFunction.CostParameters"][3]["PolynomialCostParameter.costCoefficient"]
        qmax = gens_rv[gen_key]["SynchronousMachine.maxQ"]
        gen_status = Int(gens_rv[gen_key]["Equipment.inService"])
        qmin = gens_rv[gen_key]["SynchronousMachine.minQ"]
        vg = bus_dict[gen_bus]["vm"] # note this is already converted out of SI
        qc1min = 0
        qc2min = 0
        pc1 = 0
        ramp_q = 0
        ramp_30 = 0
        pmin = gens_rv[gen_key]["RotatingMachine.GeneratingUnit"]["GeneratingUnit.minOperatingP"]
        apf = 0
        push!(gen_dict[gen_k], "ncost" => ncost,
            "qc1max" => qc1max,
            "pg" => -pg / watt_divider,
            "model" => model,
            "startup" => startup,
            "shutdown" => shutdown,
            "qc2max" => qc2max,
            "ramp_agc" => ramp_agc,
            "qg" => -qg / watt_divider,
            "gen_bus" => gen_bus,
            "pmax" => pmax / watt_divider,
            "ramp_10" => ramp_10,
            "mbase" => mbase,
            "pc2" => pc2,
            "index" => index,
            "cost" => [cost_2, cost_1, cost_0],
            "qmax" => qmax / watt_divider,
            "gen_status" => gen_status,
            "qmin" => qmin / watt_divider,
            "vg" => vg,
            "qc1min" => qc1min,
            "qc2min" => qc2min,
            "pc1" => pc1,
            "ramp_q" => ramp_q,
            "ramp_30" => ramp_30,
            "pmin" => pmin / watt_divider,
            "apf" => apf,
            "source_id" => "RotatingMachine."*gen_key)
    end

    # prepare branches - note lines and transformers handled separately

    branch_dict = Dict()
    y = sort(collect(keys(lines_rv)))
    present_lines = [y[i] for i in 1:length(y) if isassigned(y, i)]
    z = sort(collect(keys(trnfmrs_rv)))
    present_trnfmrs = [z[i] for i in 1:length(z) if isassigned(z, i)]
    branch_keys = sort(collect(Iterators.flatten([y, z])))
    branch_ind = 0
    for k in 1:length(branch_keys)
        if branch_keys[k] in present_lines
            branch_ind += 1
            push!(branch_dict, branch_ind => Dict{String, Any}())
            ind = k
            branch_key = branch_keys[k]
            br_r = lines_rv[branch_key]["ACLineSegment.r"]
            shift = 0.0
            br_x = lines_rv[branch_key]["ACLineSegment.x"]
            b =  lines_rv[branch_key]["ACLineSegment.bch"]
            b_fr = b/2
            b_to = b/2
            #g = br_r / (br_r^2 + br_x^2)
            g = 0.0
            g_fr = g/2
            g_to = g/2
            f_bus_name = _extract_name(lines_rv[branch_key]["ConductingEquipment.Terminals"][1]["Terminal.ConnectivityNode"])
            t_bus_name = _extract_name(lines_rv[branch_key]["ConductingEquipment.Terminals"][2]["Terminal.ConnectivityNode"])
            f_bus = findfirst(z->z==f_bus_name, present_buses)
            t_bus = findfirst(z->z==t_bus_name, present_buses)
            br_status = Int(lines_rv[branch_key]["Equipment.inService"])
            index = ind
            oplim = lines_rv[branch_key]["Equipment.OperationalLimitSet"]
            oplim_key = _extract_name(oplim)
            angmin = oplims_rv[oplim_key]["OperationalLimitSet.OperationalLimitValue"][3]["VoltageLimit.value"]
            angmax = oplims_rv[oplim_key]["OperationalLimitSet.OperationalLimitValue"][4]["VoltageLimit.value"]
            transformer = false
            tap = 1
            rate_a = oplims_rv[oplim_key]["OperationalLimitSet.OperationalLimitValue"][1]["ActivePowerLimit.value"]
            rate_b = oplims_rv[oplim_key]["OperationalLimitSet.OperationalLimitValue"][2]["ActivePowerLimit.value"]
            v_base = bus_dict[f_bus]["base_kv"]
            s_base = basemva_rv
            r_x_div = v_base^2 / s_base
            g_b_div = s_base / v_base^2
            push!(branch_dict[branch_ind], "br_r" => br_r,
                "shift" => shift * (180 / pi),
                "br_r" => br_r / r_x_div,
                "br_x" => br_x / r_x_div,
                "b_fr" => b_fr / g_b_div,
                "b_to" => b_to / g_b_div,
                "g_fr" => g_fr / g_b_div,
                "g_to" => g_to / g_b_div,
                "f_bus" => f_bus,
                "t_bus" => t_bus,
                "br_status" => br_status,
                "index" => index,
                "angmin" => angmin* (180 / pi),
                "angmax" => angmax * (180 / pi),
                "transformer" => transformer,
                "tap" => tap,
                "rate_a" => rate_a / watt_divider,
                "rate_b" => rate_b / watt_divider,
                "source_id" => "ACLineSegment."*branch_key
                )
        end
    end
    for k in 1:(length(lines_rv) + length(trnfmrs_rv))
        if branch_keys[k] in present_trnfmrs
            branch_ind += 1
            push!(branch_dict, branch_ind => Dict{String, Any}())
            ind = k
            branch_key = branch_keys[k]
            br_r = trnfmrs_rv[branch_key]["PowerTransformer.PowerTransformerEnd"][2]["PowerTransformerEnd.r"]
            shift_key = _extract_name(trnfmrs_rv[branch_key]["PowerTransformer.PowerTransformerEnd"][1]["TransformerEnd.PhaseTapChanger"])
            shift = shifts_rv[shift_key]["TapChanger.TapChangerRatio"]["TapChangerRatio.ptRatio"]
            br_x = trnfmrs_rv[branch_key]["PowerTransformer.PowerTransformerEnd"][2]["PowerTransformerEnd.x"]
            b =  trnfmrs_rv[branch_key]["PowerTransformer.PowerTransformerEnd"][2]["PowerTransformerEnd.b"]
            b_fr = b/2
            b_to = b/2
            g = 0.0
            g_fr = g/2
            g_to = g/2
            f_bus_name = _extract_name(trnfmrs_rv[branch_key]["PowerTransformer.PowerTransformerEnd"][1]["ConductingEquipment.Terminals"][1]["Terminal.ConnectivityNode"])
            t_bus_name = _extract_name(trnfmrs_rv[branch_key]["PowerTransformer.PowerTransformerEnd"][2]["ConductingEquipment.Terminals"][1]["Terminal.ConnectivityNode"])
            f_bus = findfirst(z->z==f_bus_name, present_buses)
            t_bus = findfirst(z->z==t_bus_name, present_buses)
            br_status = Int(trnfmrs_rv[branch_key]["Equipment.inService"])
            index = ind
            oplim = trnfmrs_rv[branch_key]["Equipment.OperationalLimitSet"]
            oplim_key = _extract_name(oplim)
            angmin = oplims_rv[oplim_key]["OperationalLimitSet.OperationalLimitValue"][3]["VoltageLimit.value"]
            angmax = oplims_rv[oplim_key]["OperationalLimitSet.OperationalLimitValue"][4]["VoltageLimit.value"]
            transformer = true
            tap_key = _extract_name(trnfmrs_rv[branch_key]["PowerTransformer.PowerTransformerEnd"][1]["TransformerEnd.RatioTapChanger"])
            tap = taps_rv[tap_key]["TapChanger.TapChangerRatio"]["TapChangerRatio.ptRatio"]
            rate_a = oplims_rv[oplim_key]["OperationalLimitSet.OperationalLimitValue"][1]["ActivePowerLimit.value"]
            rate_b = oplims_rv[oplim_key]["OperationalLimitSet.OperationalLimitValue"][2]["ActivePowerLimit.value"]
            v_base = bus_dict[f_bus]["base_kv"]
            s_base = basemva_rv
            r_x_div = v_base^2 / s_base
            g_b_div = s_base / v_base^2
            push!(branch_dict[branch_ind], "br_r" => br_r,
                "shift" => shift* (180 / pi),
                "br_r" => br_r / r_x_div,
                "br_x" => br_x / r_x_div,
                "b_fr" => b_fr / g_b_div,
                "b_to" => b_to / g_b_div,
                "g_fr" => g_fr / g_b_div,
                "g_to" => g_to / g_b_div,
                "f_bus" => f_bus,
                "t_bus" => t_bus,
                "br_status" => br_status,
                "index" => index,
                "angmin" => angmin * (180 / pi),
                "angmax" => angmax * (180 / pi),
                "transformer" => transformer,
                "tap" => tap,
                "rate_a" => rate_a / watt_divider,
                "rate_b" => rate_b / watt_divider,
                "source_id" => "PowerTransformer."*branch_key
                )
        end
    end

    # prepare shunts_rv

    shunt_dict = Dict()
    shsh = sort(collect(keys(shunts_rv)))
    present_shunts = [shsh[i] for i in 1:length(shsh) if isassigned(shsh, i)]
    shind = 0
    for sh in present_shunts
        pre_shunt_bus = _extract_name(shunts_rv[sh]["ConductingEquipment.Terminals"][1]["Terminal.ConnectivityNode"])
        shunt_bus = findfirst(z->z==pre_shunt_bus, present_buses)
        gs = shunts_rv[sh]["LinearShuntCompensator.gPerSection"]
        bs = shunts_rv[sh]["LinearShuntCompensator.bPerSection"]
        v_base = bus_dict[shunt_bus]["base_kv"]
        s_base = basemva_rv
        g_b_div = s_base / v_base^2
        shind += 1
        push!(shunt_dict, shind => Dict{String, Any}())
        push!(shunt_dict[shind], "shunt_bus" => shunt_bus, "gs" => gs / g_b_div, "bs" => bs / g_b_div, "status" => 1, "index" => shind)
    end


    # TODO add storage and dclines

    PMcase = Dict("bus" => bus_dict, "gen" => gen_dict, "branch" => branch_dict, "load" => load_dict, "source_type" => "RAVENS",
    "baseMVA" => basemva_rv, "per_unit" => false, "storage" => Dict(), "switch" => Dict(), "shunt" => shunt_dict, "dcline" => Dict())

    return PMcase

end
