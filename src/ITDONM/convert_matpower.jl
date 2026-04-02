using PowerModels
using JSON


folder = "../cases/Case3/case3_with_inv_load_x4/"
name_string = "transmission_Case3_with_inv_load_x4"
name = folder*name_string
intermediate_file = name*".json"

nw = JSON.parsefile(intermediate_file)
nw["name"] = name_string
mp = export_matpower(name*".m", nw)
