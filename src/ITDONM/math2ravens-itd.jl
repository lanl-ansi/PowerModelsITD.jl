function transform_solution_ravens_itd(res, full_nw_math)
    sol_t_r = transform_solution_ravens_transmission(r["solution"]["it"]["pm"], full_nw_math["it"]["pm"])["AnalysisResult"]

    res_d = res["solution"]["it"]["pmd"]
    sol_d_rv = transform_solution_ravens(res_d, full_nw_math["it"]["pmd"])["AnalysisResult"]

    bd_keys = collect(keys(res["solution"]["it"]["pmitd"]["nw"]["1"]["boundary"]))

    # record boundary flows -- this part is very messy and relies on the specific way I named the boundary. Will need to be revisited. resolved 03.26
    nw_keys_math = keys(res["solution"]["it"]["pmitd"]["nw"])
    phases = ["SinglePhaseKind.A", "SinglePhaseKind.B", "SinglePhaseKind.C"]
    bd_count = 0
    for k in 1:Int(length(bd_keys)/2)
        bd_count += 1
        bd_ind = extract_first_number(bd_keys[bd_count]) - 100000
	from_ind = "-1"
	to_ind = "-1"
	# this if-else is a safeguard against the bidirectional flow being reversed (it does happen)
	if haskey(res["solution"]["it"]["pmitd"]["nw"]["1"]["boundary"][bd_keys[2*bd_count-1]],"pbound_fr")
        	from_ind = bd_keys[2*bd_count-1]
        	to_ind = bd_keys[2*bd_count]
	else
		from_ind = bd_keys[2*bd_count]
		to_ind = bd_keys[2*bd_count-1]
	end
	line_bd_key = split(full_nw_math["it"]["pmitd"]["nw"]["1"][string(100000 + k)]["source_id"],".")
	line_bd_name = line_bd_key[2]
        for phase in 1:length(phases)
        data1 = Dict(
                "AnalysisResultData.Curve" => 
                _make_curve_data(nw_keys_math, full_nw_math["it"]["pmitd"], nw -> 
                    begin
                    Dict("AvPowerFlow.p" => res["solution"]["it"]["pmitd"]["nw"][nw]["boundary"][from_ind]["pbound_fr"][1]*res["solution"]["it"]["pm"]["nw"][nw]["settings"]["power_scale_factor"],
                                    "AvPowerFlow.q" => res["solution"]["it"]["pmitd"]["nw"][nw]["boundary"][from_ind]["qbound_fr"][1]*res["solution"]["it"]["pm"]["nw"][nw]["settings"]["power_scale_factor"])
        
                    end
                ),
                 "ArPowerFlow.ConductingEquipment" => "ACLineSegment::'"*line_bd_name*"'",
                 "AnalysisResultData.phase"        => phases[phase]
                
        )
        data2 = Dict(
                "AnalysisResultData.Curve" => 
                _make_curve_data(nw_keys_math, full_nw_math["it"]["pmitd"], nw -> 
                    begin
                    Dict("AvPowerFlow.p" => res["solution"]["it"]["pmitd"]["nw"][nw]["boundary"][to_ind]["pbound_to"][phase]*res["solution"]["it"]["pmd"]["nw"][nw]["settings"]["power_scale_factor"],
                                    "AvPowerFlow.q" => res["solution"]["it"]["pmitd"]["nw"][nw]["boundary"][to_ind]["qbound_to"][phase]*res["solution"]["it"]["pmd"]["nw"][nw]["settings"]["power_scale_factor"], "AnalysisResultData.Phase" => phases[phase])
                    end
                ),
                 "ArPowerFlow.ConductingEquipment" => "ACLineSegment::'"*line_bd_name*"'",
                 "AnalysisResultData.phase"        => phases[phase]
                
        )
        push!(sol_t_r["OptimalPowerFlow"]["OperationsResult.PowerFlows"], data1, data2)
        end
    end

    # add everything to the transmission solution
    for k in collect(keys(sol_d_rv["OptimalPowerFlow"]["OperationsResult.Voltages"]))
        push!(sol_t_r["OptimalPowerFlow"]["OperationsResult.Voltages"], sol_d_rv["OptimalPowerFlow"]["OperationsResult.Voltages"][k])
    end
    for k in collect(keys(sol_d_rv["OptimalPowerFlow"]["OperationsResult.PowerFlows"]))
        push!(sol_t_r["OptimalPowerFlow"]["OperationsResult.PowerFlows"], sol_d_rv["OptimalPowerFlow"]["OperationsResult.PowerFlows"][k])
    end    
    sol_t_r["OptimalPowerFlow"]["OperationsResult.Statuses"] = deepcopy(sol_d_rv["OptimalPowerFlow"]["OperationsResult.Statuses"])
    sol_t_r["OptimalPowerFlow"]["OperationsResult.Switches"] = deepcopy(sol_d_rv["OptimalPowerFlow"]["OperationsResult.Switches"])

    return sol_t_r


end
