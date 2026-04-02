using PowerModelsITD
import PowerModelsONM as _ONM
import PowerModelsDistribution as _PMD
import PowerModels as _PM
import InfrastructureModels as _IM
import JuMP
import HiGHS
import JSON
import PolyhedralRelaxations
using Graphs
using UUIDs

include("helpers.jl")
include("ravens2math-itd.jl")
include("ravens2math_transmission.jl")
include("opfitd_restore.jl")
include("ONM_objective_mod.jl")
include("units.jl")
include("math2ravens-transmission.jl")
include("math2ravens.jl")
include("math2ravens-itd.jl")

folder = "../cases/Case3/case3_with_inv_load_x3/"

ravens_input = folder*"case118_case123_merged_reinforced.json"
intermediate_file = folder*"transmission_Case3_with_inv_load_x3.json"
ravens_output = folder*"solution_case3_with_inv_load_x3.json"


pmitd_type = BFPowerModelITD{_PM.BFAPowerModel, _PMD.LinDist3FlowPowerModel}
highs = JuMP.optimizer_with_attributes(HiGHS.Optimizer, "presolve"=>"off")

nw = JSON.parsefile(ravens_input)


full_dict = transform_data_model_ravens_itd(nw,intermediate_file)
full_dict["it"]["pmd"]["fix-small-numbers"] = true

nw_keys = collect(keys(full_dict["it"]["pmd"]["nw"]))
N_networks = length(nw_keys)


d_buses = full_dict["it"]["pmd"]["nw"]["1"]["bus"]
bus_keys = collect(keys(d_buses))
source_ind = locate_voltage_source(d_buses)

dc_feeder_key = findfirst(x->nw["Group"]["ConnectivityNodeContainer"][x]["Ravens.cimObjectType"]=="Line", collect(keys(nw["Group"]["ConnectivityNodeContainer"])))
dc_feeder_name = collect(keys(nw["Group"]["ConnectivityNodeContainer"]))[dc_feeder_key]    
revise_names_source_ids!(full_dict, dc_feeder_name)


_PM.make_per_unit!(full_dict["it"]["pm"])

full_dict["it"]["pm"]= PowerModelsITD.replicate(full_dict["it"]["pm"],N_networks)
full_dict["it"]["pmitd"] = PowerModelsITD.replicate(full_dict["it"]["pmitd"],N_networks)


#=
for nw in nw_keys
	_PM.make_per_unit!(full_dict["it"]["pm"]["nw"][nw])
end
=#



set_voltage_bounds_math!(full_dict; vmin=0.8, vmax=1.2)

for nw in nw_keys
    #open all switches, should close successively
    switch_keys = collect(keys(full_dict["it"]["pmd"]["nw"][nw]["switch"]))
    for sw in switch_keys
        if nw == "1" 
            full_dict["it"]["pmd"]["nw"][nw]["switch"][sw]["state"] = Int(_ONM.OPEN)
            full_dict["it"]["pmd"]["nw"][nw]["switch"][sw]["dispatchable"] = Int(_ONM.NO)
        else
            full_dict["it"]["pmd"]["nw"][nw]["switch"][sw]["state"] = Int(_ONM.OPEN)
            full_dict["it"]["pmd"]["nw"][nw]["switch"][sw]["dispatchable"] = Int(_ONM.YES)
        end
    end
end

bound_switch_closures!(full_dict)

create_source_outage!(full_dict, create_outage=true)  

r = solve_mn_opfitd_restore(full_dict, pmitd_type, highs, solution_model="MATH")

create_transmission_settings!(full_dict, r)

math2ravens_itd_setup!(full_dict, r)

sol_ravens = transform_solution_ravens_itd(r, full_dict)

open(ravens_output,"w") do f
  JSON.print(f, sol_ravens, 2)
end

