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

include(dirname(@__FILE__)*"/src/ITDONM/helpers.jl")
include(dirname(@__FILE__)*"/src/ITDONM/ravens2math-itd.jl")
include(dirname(@__FILE__)*"/src/ITDONM/ravens2math_transmission.jl")
include(dirname(@__FILE__)*"/src/ITDONM/opfitd_restore.jl")
include(dirname(@__FILE__)*"/src/ITDONM/ONM_objective_mod.jl")
include(dirname(@__FILE__)*"/src/ITDONM/units.jl")
include(dirname(@__FILE__)*"/src/ITDONM/math2ravens-transmission.jl")
include(dirname(@__FILE__)*"/src/ITDONM/math2ravens.jl")
include(dirname(@__FILE__)*"/src/ITDONM/math2ravens-itd.jl")


folder = "./"

ravens_input = folder*"CaseName.json"
intermediate_file = folder*"IntFile.json"
ravens_output = folder*"OutputFile.json"


pmitd_type = BFPowerModelITD{_PM.BFAPowerModel, _PMD.LinDist3FlowPowerModel}

using SCIP
# highs=JuMP.optimizer_with_attributes(SCIP.Optimizer, "limits/gap" => 0.0, "limits/absgap" => 0.0, "numerics/epsilon" => 1e-12, "numerics/sumepsilon" => 1e-9, "numerics/checkfeastolfac" => 10.0,"numerics/feastol" => 1e-5, "numerics/dualfeastol" => 1e-5, "presolving/maxrounds" => 0)
# highs=JuMP.optimizer_with_attributes(SCIP.Optimizer, "limits/gap" => 0.0, "limits/absgap" => 0.0, "numerics/epsilon" => 1e-12, "numerics/sumepsilon" => 1e-9, "numerics/checkfeastolfac" => 10.0,"numerics/feastol" => 1e-6, "numerics/dualfeastol" => 1e-6, "presolving/maxrounds" => 0)
highs=JuMP.optimizer_with_attributes(SCIP.Optimizer, "limits/gap" => 0.0001, "limits/absgap" => 0.0001, "presolving/maxrounds" => 0)

# highs = JuMP.optimizer_with_attributes(HiGHS.Optimizer, "presolve"=>"off", "mip_rel_gap"=> 0.001, "mip_abs_gap"=> 0.001, "small_matrix_value"=> 1e-12, "log_to_console"=> true, "mip_feasibility_tolerance"=>1e-4, "primal_feasibility_tolerance"=> 1e-4)#, "dual_feasibility_tolerance"=> tol, "kkt_tolerance" => tol)#, "optimality_tolerance"=>1e-6)
# import Gurobi
# highs = JuMP.optimizer_with_attributes(() -> Gurobi.Optimizer(_ONM.GRB_ENV), "Presolve" => 0, "MIPGap"=>0.0)#, "FeasibilityTol" => 1E-2)

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


for nw in nw_keys
    #open all switches, should close successively
    switch_keys = collect(keys(full_dict["it"]["pmd"]["nw"][nw]["switch"]))
    # sws=["sw1","sw2", "sw3","sw4", "sw5", "sw7", "sw8"]
    sws=[]
    for sw in switch_keys
        if nw == "1" 
            if full_dict["it"]["pmd"]["nw"][nw]["switch"][sw]["name"][end-2:end] in sws
                full_dict["it"]["pmd"]["nw"][nw]["switch"][sw]["state"] = Int(_ONM.CLOSED)
                full_dict["it"]["pmd"]["nw"][nw]["switch"][sw]["dispatchable"] = Int(_ONM.YES)
            else
                full_dict["it"]["pmd"]["nw"][nw]["switch"][sw]["state"] = Int(_ONM.OPEN)
                full_dict["it"]["pmd"]["nw"][nw]["switch"][sw]["dispatchable"] = Int(_ONM.NO)
            end
        else
            if full_dict["it"]["pmd"]["nw"][nw]["switch"][sw]["name"][end-2:end] in sws
                full_dict["it"]["pmd"]["nw"][nw]["switch"][sw]["state"] = Int(_ONM.CLOSED)
                full_dict["it"]["pmd"]["nw"][nw]["switch"][sw]["dispatchable"] = Int(_ONM.YES)
            else
                full_dict["it"]["pmd"]["nw"][nw]["switch"][sw]["state"] = Int(_ONM.OPEN)
                full_dict["it"]["pmd"]["nw"][nw]["switch"][sw]["dispatchable"] = Int(_ONM.YES)
            end
        end
    end
end

bound_switch_closures!(nw_keys, full_dict, close_ub = 1)

create_source_outage!(nw_keys, full_dict, create_outage=true)  

r = solve_mn_opfitd_restore(full_dict, pmitd_type, highs, solution_model="MATH")

create_transmission_settings!(nw_keys, full_dict, r)

math2ravens_itd_setup!(full_dict, r)

sol_ravens = transform_solution_ravens_itd(r, full_dict)

# open(ravens_output,"w") do f
#   JSON.print(f, sol_ravens, 2)
# end

outload=[]
for (k,v) in r["solution"]["it"]["pmd"]["nw"]["2"]["load"]
    if v["status"] == _ONM.DISABLED
        name = full_dict["it"]["pmd"]["nw"]["2"]["load"][k]["name"]
        append!(outload,[split(name,".")[end]])
    end
end

[[full_dict["it"]["pmd"]["nw"]["1"]["switch"][string(k)]["name"], r["solution"]["it"]["pmd"]["nw"]["1"]["switch"][string(k)]["state"], r["solution"]["it"]["pmd"]["nw"]["2"]["switch"][string(k)]["state"]] for k in range(1,7)]





