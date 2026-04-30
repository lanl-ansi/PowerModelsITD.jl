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

function get_gen_buses(gens_rv)
    gen_buses = []
    gens = []
    for g in 1:length(gens_rv)
        gb = retrieve_bus_from_string(gens_rv["gen"*string(g)]["ConductingEquipment.Terminals"][1]["Terminal.ConnectivityNode"])
        push!(gen_buses, gb)
        push!(gens, g)
    end
    return gens,gen_buses
end

function get_load_buses(loads_rv)
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

    bb = collect(keys(buses_rv))
    present_buses = [bb[i] for i in 1:length(bb) if isassigned(bb, i)]



    # prepare buses
    bus_dict = Dict()
    for b in parse.(Int64, present_buses)
        push!(bus_dict, b  => Dict{String, Any}())
        zone = 1
        bus_i = b
        gs = get_gen_buses(gens_rv)[1]
        lds = get_load_buses(loads_rv)[1]
        gbs = get_gen_buses(gens_rv)[2]
        lbs = get_load_buses(loads_rv)[2]
        base_kv = 0
        if length(oplims_rv["OpLimVbus"*string(b)]["OperationalLimitSet.OperationalLimitValue"]) == 3
            bus_type = 3 # slack bus
            vmax = oplims_rv["OpLimVbus"*string(b)]["OperationalLimitSet.OperationalLimitValue"][3]["VoltageLimit.value"]
            vmin = oplims_rv["OpLimVbus"*string(b)]["OperationalLimitSet.OperationalLimitValue"][2]["VoltageLimit.value"]
        else
            vmax = oplims_rv["OpLimVbus"*string(b)]["OperationalLimitSet.OperationalLimitValue"][2]["VoltageLimit.value"]
            vmin = oplims_rv["OpLimVbus"*string(b)]["OperationalLimitSet.OperationalLimitValue"][1]["VoltageLimit.value"]
            # need to search for generators
            if b in gbs
                bus_type = 2
            else
                bus_type = 1
            end
        end     
        name = b
        area = 1
        index = b
        va = buses_rv[string(b)]["ConnectivityNode.SvVoltage"][1]["SvVoltage.angle"]
        vm = buses_rv[string(b)]["ConnectivityNode.SvVoltage"][1]["SvVoltage.v"]
        if b in lbs
            basev = retrieve_basev_from_string(loads_rv["load"*string(b)]["ConductingEquipment.BaseVoltage"])
            base_kv = basev_rv[string(basev)]["BaseVoltage.nominalVoltage"] / 1000
        elseif b in gbs
            gen = findfirst(x->x==b, gbs)
            basev = retrieve_basev_from_string(gens_rv["gen"*string(gs[gen])]["ConductingEquipment.BaseVoltage"])
            base_kv = basev_rv[string(basev)]["BaseVoltage.nominalVoltage"] / 1000
        end
        voltage_divider = base_kv * 1000
        push!(bus_dict[b], "zone" => zone, 
            "bus_i" => bus_i,
            "bus_type" => bus_type,
            "source_id" => "ConnectivityNode."*string(name),
            "vmax" => vmax / voltage_divider,
            "area" => area,
            "vmin" => vmin / voltage_divider,
            "index" => index,
            "va" => va,# * (180 / π),
            "vm" => vm / voltage_divider,
            "base_kv" => base_kv
        )
    end

    # prepare loads
    load_dict = Dict()
    ind = 0
    x = collect(keys(loads_rv))
    present_loads = [x[i] for i in 1:length(x) if isassigned(x, i)]
    watt_divider = 1E6
    for ld in parse.(Int64, present_buses)
        if "load"*string(ld) in present_loads
            ind += 1
            push!(load_dict, ind  => Dict{String, Any}())
            load_bus = retrieve_bus_from_string(loads_rv["load"*string(ld)]["ConductingEquipment.Terminals"][1]["Terminal.ConnectivityNode"])
            status = 1
            qd = loads_rv["load"*string(ld)]["EnergyConsumer.q"]
            pd = loads_rv["load"*string(ld)]["EnergyConsumer.p"]
            push!(load_dict[ind], "load_bus" => load_bus,
                "status" => status, 
                "qd" => qd / watt_divider,
                "pd" => pd / watt_divider,
                "source_id" => "EnergyConsumer.load"*string(load_bus)
                )
        end
    end

  # prepare gens (quadratic costs only)

    gen_dict = Dict()
    for g in 1:length(gens_rv)
        push!(gen_dict, g => Dict{String, Any}())
        ncost = 3 #quadratic costs always assumed for now
        qc1max = 0
        pg = gens_rv["gen"*string(g)]["RotatingMachine.p"]
        model = 2 # polynomial cost function
        startup = gencosts_rv["cost_gen"*string(g)]["ProducerCostFunction.startupCost"]
        shutdown = gencosts_rv["cost_gen"*string(g)]["ProducerCostFunction.shutdownCost"]
        qc2max = 0
        ramp_agc = 0
        qg = gens_rv["gen"*string(g)]["RotatingMachine.q"]
        gen_bus = retrieve_bus_from_string(gens_rv["gen"*string(g)]["ConductingEquipment.Terminals"][1]["Terminal.ConnectivityNode"])
        pmax = gens_rv["gen"*string(g)]["RotatingMachine.GeneratingUnit"]["GeneratingUnit.maxOperatingP"]
        ramp_10 = 0
        mbase = basemva_rv
        pc2 = 0
        index = g
        cost_0 = gencosts_rv["cost_gen"*string(g)]["ProducerCostFunction.CostParameters"][1]["PolynomialCostParameter.costCoefficient"]
        cost_1 = gencosts_rv["cost_gen"*string(g)]["ProducerCostFunction.CostParameters"][2]["PolynomialCostParameter.costCoefficient"]
        cost_2 = gencosts_rv["cost_gen"*string(g)]["ProducerCostFunction.CostParameters"][3]["PolynomialCostParameter.costCoefficient"]
        qmax = gens_rv["gen"*string(g)]["SynchronousMachine.maxQ"]
        gen_status = Int(gens_rv["gen"*string(g)]["Equipment.inService"])
        qmin = gens_rv["gen"*string(g)]["SynchronousMachine.minQ"]
        vg = bus_dict[gen_bus]["vm"] # note this is already converted out of SI
        qc1min = 0
        qc2min = 0
        pc1 = 0
        ramp_q = 0
        ramp_30 = 0
        pmin = gens_rv["gen"*string(g)]["RotatingMachine.GeneratingUnit"]["GeneratingUnit.minOperatingP"]
        apf = 0
        push!(gen_dict[g], "ncost" => ncost,
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
            "source_id" => "RotatingMachine.gen"*string(g))
    end

    # prepare branches - note lines and transformers handled separately

    branch_dict = Dict()
    y = collect(keys(lines_rv))
    present_lines = [y[i] for i in 1:length(y) if isassigned(y, i)]
    z = collect(keys(trnfmrs_rv))
    present_trnfmrs = [z[i] for i in 1:length(z) if isassigned(z, i)]
    branch_ind = 0
    for k in 1:(length(lines_rv) + length(trnfmrs_rv))
        if "line"*string(k) in present_lines
            branch_ind += 1
            push!(branch_dict, branch_ind => Dict{String, Any}())
            ind = k
            br_r = lines_rv["line"*string(k)]["ACLineSegment.r"]
            shift = 0
            br_x = lines_rv["line"*string(k)]["ACLineSegment.x"]
            b =  lines_rv["line"*string(k)]["ACLineSegment.bch"]
            b_fr = b/2
            b_to = b/2
            #g = br_r / (br_r^2 + br_x^2)
            g = 0.0
            g_fr = g/2
            g_to = g/2
            f_bus = retrieve_bus_from_string(lines_rv["line"*string(k)]["ConductingEquipment.Terminals"][1]["Terminal.ConnectivityNode"])
            t_bus = retrieve_bus_from_string(lines_rv["line"*string(k)]["ConductingEquipment.Terminals"][2]["Terminal.ConnectivityNode"])
            br_status = Int(lines_rv["line"*string(k)]["Equipment.inService"])
            index = ind
            angmin = oplims_rv["OpLimbranch"*string(k)]["OperationalLimitSet.OperationalLimitValue"][3]["VoltageLimit.value"]
            angmax = oplims_rv["OpLimbranch"*string(k)]["OperationalLimitSet.OperationalLimitValue"][4]["VoltageLimit.value"]
            transformer = false
            tap = 1
            rate_a = oplims_rv["OpLimbranch"*string(k)]["OperationalLimitSet.OperationalLimitValue"][1]["ActivePowerLimit.value"]
            rate_b = oplims_rv["OpLimbranch"*string(k)]["OperationalLimitSet.OperationalLimitValue"][2]["ActivePowerLimit.value"]
            v_base = bus_dict[t_bus]["base_kv"]
            s_base = basemva_rv
            r_x_div = v_base^2 / s_base
            g_b_div = s_base / v_base^2
            push!(branch_dict[branch_ind],
                "shift" => shift,# * (180 / π),
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
                "angmin" => angmin,# * (180 / π),
                "angmax" => angmax,# * (180 / π),
                "transformer" => transformer,
                "tap" => tap,
                "rate_a" => rate_a / watt_divider,
                "rate_b" => rate_b / watt_divider,
                "source_id" => "ACLineSegment.line"*string(k)
                )
        end
    end
    for k in 1:(length(lines_rv) + length(trnfmrs_rv))
        if "transformer"*string(k) in present_trnfmrs
            branch_ind += 1
            push!(branch_dict, branch_ind => Dict{String, Any}())
            ind = k
            br_r = trnfmrs_rv["transformer"*string(k)]["PowerTransformer.PowerTransformerEnd"][2]["PowerTransformerEnd.r"]
            shift = shifts_rv["shift"*string(k)]["TapChanger.TapChangerRatio"]["TapChangerRatio.ptRatio"]
            br_x = trnfmrs_rv["transformer"*string(k)]["PowerTransformer.PowerTransformerEnd"][2]["PowerTransformerEnd.x"]
            b =  trnfmrs_rv["transformer"*string(k)]["PowerTransformer.PowerTransformerEnd"][2]["PowerTransformerEnd.b"]
            b_fr = b/2
            b_to = b/2
            g = 0.0
            g_fr = g/2
            g_to = g/2
            f_bus = retrieve_bus_from_string(trnfmrs_rv["transformer"*string(k)]["PowerTransformer.PowerTransformerEnd"][1]["ConductingEquipment.Terminals"][1]["Terminal.ConnectivityNode"])
            t_bus = retrieve_bus_from_string(trnfmrs_rv["transformer"*string(k)]["PowerTransformer.PowerTransformerEnd"][2]["ConductingEquipment.Terminals"][1]["Terminal.ConnectivityNode"])
            br_status = Int(trnfmrs_rv["transformer"*string(k)]["Equipment.inService"])
            index = ind
            angmin = oplims_rv["OpLimbranch"*string(k)]["OperationalLimitSet.OperationalLimitValue"][3]["VoltageLimit.value"]
            angmax = oplims_rv["OpLimbranch"*string(k)]["OperationalLimitSet.OperationalLimitValue"][4]["VoltageLimit.value"]
            transformer = true
            tap = taps_rv["tap"*string(k)]["TapChanger.TapChangerRatio"]["TapChangerRatio.ptRatio"]
            rate_a = oplims_rv["OpLimbranch"*string(k)]["OperationalLimitSet.OperationalLimitValue"][1]["ActivePowerLimit.value"]
            rate_b = oplims_rv["OpLimbranch"*string(k)]["OperationalLimitSet.OperationalLimitValue"][2]["ActivePowerLimit.value"]
            v_base = bus_dict[f_bus]["base_kv"]
            s_base = basemva_rv
            r_x_div = v_base^2 / s_base
            g_b_div = s_base / v_base^2
            push!(branch_dict[branch_ind], "br_r" => br_r,
                "shift" => shift,# * (180 / π),
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
                "angmin" => angmin,# * (180 / π),
                "angmax" => angmax,# * (180 / π),
                "transformer" => transformer,
                "tap" => tap,
                "rate_a" => rate_a / watt_divider,
                "rate_b" => rate_b / watt_divider,
                "source_id" => "PowerTransformer.transformer"*string(k)
                )
        end
    end

    # prepare shunts_rv

    shunt_dict = Dict()
    shsh = collect(keys(shunts_rv))
    present_shunts = [shsh[i] for i in 1:length(shsh) if isassigned(shsh, i)]
    shind = 0
    for sh in present_shunts
        shunt_bus = retrieve_bus_from_string(shunts_rv[sh]["ConductingEquipment.Terminals"][1]["Terminal.ConnectivityNode"])
        gs = shunts_rv[sh]["LinearShuntCompensator.gPerSection"]
        bs = shunts_rv[sh]["LinearShuntCompensator.bPerSection"]
        v_base = bus_dict[shunt_bus]["base_kv"]
        s_base = basemva_rv
        g_b_div = s_base / v_base^2
        shind += 1
        push!(shunt_dict, shind => Dict{String, Any}())
        push!(shunt_dict[shind], "shunt_bus" => shunt_bus, "gs" => gs / g_b_div, "bs" => bs / g_b_div, "status" => 1)
    end


    # TODO add storage and dclines

    PMcase = Dict("bus" => bus_dict, "gen" => gen_dict, "branch" => branch_dict, "load" => load_dict, "source_type" => "RAVENS",
    "baseMVA" => basemva_rv, "per_unit" => false, "storage" => Dict(), "switch" => Dict(), "shunt" => shunt_dict, "dcline" => Dict())

    return PMcase

end
