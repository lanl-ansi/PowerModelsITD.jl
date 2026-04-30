using PowerModelsITD
import PowerModelsONM as _ONM
import PowerModelsDistribution as _PMD
import PowerModels as _PM
import InfrastructureModels as _IM
import JuMP
# import HiGHS
import JSON
import PolyhedralRelaxations
using Graphs
using UUIDs
using SCIP

include(dirname(@__FILE__)*"/src/ITDONM/helpers.jl")
include(dirname(@__FILE__)*"/src/ITDONM/ravens2math-itd.jl")
include(dirname(@__FILE__)*"/src/ITDONM/ravens2math_transmission.jl")
include(dirname(@__FILE__)*"/src/ITDONM/opfitd_restore.jl")
include(dirname(@__FILE__)*"/src/ITDONM/ONM_objective_mod.jl")
include(dirname(@__FILE__)*"/src/ITDONM/units.jl")
include(dirname(@__FILE__)*"/src/ITDONM/math2ravens-transmission.jl")
include(dirname(@__FILE__)*"/src/ITDONM/math2ravens.jl")
include(dirname(@__FILE__)*"/src/ITDONM/math2ravens-itd.jl")


function ITDRestore()
    pmitd_type = BFPowerModelITD{_PM.BFAPowerModel, _PMD.LinDist3FlowPowerModel}
    # highs = JuMP.optimizer_with_attributes(HiGHS.Optimizer, "presolve"=>"on")
    # import Gurobi
    # highs = JuMP.optimizer_with_attributes(() -> Gurobi.Optimizer(_ONM.GRB_ENV), "Presolve" => 0, "MIPGap"=>0.0)#, "FeasibilityTol" => 1E-2)
    scip_o=JuMP.optimizer_with_attributes(SCIP.Optimizer, "limits/gap" => 0.0001, "limits/absgap" => 0.0001, "presolving/maxrounds" => 0)

    # nw = JSON.parsefile(ravens_input)
    nw = JSON.parsefile("./data/ravensinput.json")


    full_dict = transform_data_model_ravens_itd(nw,"./data/intermediatefile.json")
    full_dict["it"]["pmd"]["fix-small-numbers"] = true


    nw_keys = collect(keys(full_dict["it"]["pmd"]["nw"]))
    N_networks = length(nw_keys)

    d_buses = full_dict["it"]["pmd"]["nw"]["1"]["bus"]
    bus_keys = collect(keys(d_buses))
    source_ind = locate_voltage_source(d_buses)

    dc_feeder_key = findfirst(x->nw["Group"]["ConnectivityNodeContainer"][x]["Ravens.cimObjectType"]=="Line", collect(keys(nw["Group"]["ConnectivityNodeContainer"])))
    dc_feeder_name = collect(keys(nw["Group"]["ConnectivityNodeContainer"]))[dc_feeder_key]    
    revise_names_source_ids!(source_ind, nw_keys, full_dict, dc_feeder_name)


    _PM.make_per_unit!(full_dict["it"]["pm"])


    full_dict["it"]["pm"]= replicate(full_dict["it"]["pm"],N_networks)
    full_dict["it"]["pmitd"] = replicate(full_dict["it"]["pmitd"],N_networks)

    resolve_units!(full_dict; multinetwork=true, number_multinetworks=N_networks)


    for nwi in nw_keys
        #open all switches, should close successively
        switch_keys = collect(keys(full_dict["it"]["pmd"]["nw"][nwi]["switch"]))
        # sws=["sw1","sw2", "sw3","sw4", "sw5", "sw7", "sw8"]
        # sws=["sw1","sw3","sw7","sw5"]
        for sw in switch_keys
            swname=full_dict["it"]["pmd"]["nw"][nwi]["switch"][sw]["name"]
            if nwi == "1" 
                # if full_dict["it"]["pmd"]["nw"][nwi]["switch"][sw]["name"][end-2:end] in sws
                # println(typeof(nw["PowerSystemResource"]["Equipment"]["ConductingEquipment"]["Switch"][swname]["Switch.open"]))
                # println(nw["PowerSystemResource"]["Equipment"]["ConductingEquipment"]["Switch"][swname]["Switch.open"]=="True")
                # println(nw["PowerSystemResource"]["Equipment"]["ConductingEquipment"]["Switch"][swname]["Switch.open"]==true)
                if nw["PowerSystemResource"]["Equipment"]["ConductingEquipment"]["Switch"][swname]["Switch.open"] == false
                    full_dict["it"]["pmd"]["nw"][nwi]["switch"][sw]["state"] = Int(_ONM.CLOSED)
                    full_dict["it"]["pmd"]["nw"][nwi]["switch"][sw]["dispatchable"] = Int(_ONM.YES)
                else
                    full_dict["it"]["pmd"]["nw"][nwi]["switch"][sw]["state"] = Int(_ONM.OPEN)
                    full_dict["it"]["pmd"]["nw"][nwi]["switch"][sw]["dispatchable"] = Int(_ONM.NO)
                end
            else
                if nw["PowerSystemResource"]["Equipment"]["ConductingEquipment"]["Switch"][swname]["Switch.open"] == false
                    full_dict["it"]["pmd"]["nw"][nwi]["switch"][sw]["state"] = Int(_ONM.CLOSED)
                    full_dict["it"]["pmd"]["nw"][nwi]["switch"][sw]["dispatchable"] = Int(_ONM.YES)
                else
                    full_dict["it"]["pmd"]["nw"][nwi]["switch"][sw]["state"] = Int(_ONM.OPEN)
                    full_dict["it"]["pmd"]["nw"][nwi]["switch"][sw]["dispatchable"] = Int(_ONM.YES)
                end
            end
        end
    end

    bound_switch_closures!(nw_keys, full_dict, close_ub = 1)

    create_source_outage!(nw_keys, full_dict, create_outage=true)  

    r = solve_mn_opfitd_restore(full_dict, pmitd_type, scip_o, solution_model="MATH")

    create_transmission_settings!(nw_keys, full_dict, r)

    math2ravens_itd_setup!(full_dict, r)

    sol_ravens = transform_solution_ravens_itd(r, full_dict)

    return sol_ravens
end





