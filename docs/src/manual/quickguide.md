# Quick Start Guide

## Running Integrated Transmission-Distribution Optimal Power Flow (OPFITD)

Once PowerModelsITD.jl is installed, Ipopt is installed, and network data files for the transmission system, distribution system(s), and boundary linking (_e.g._, `"case5_withload.m"`, `"case3_unbalanced.dss`, `"case5_case3_unbal.json"` in the package folder under `./test/data`) have been acquired, an Integrated Transmission-Distribution (ITD) AC Optimal Power Flow can be executed as follows,

```julia
using PowerModelsITD
using Ipopt

pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel} # define the formulation type.

result = solve_opfitd("case5_withload.m", "case3_unbalanced.dss", "case5_case3_unbal.json", pmitd_type, Ipopt.Optimizer)
```

## Running Integrated Transmission-Distribution Optimal Power Flow (OPFITD) with Multiple Distribution Systems

The snippet shown below demonstrates how to run an OPFITD with multiple (different) distribution systems connected to different transmission system buses. In summary, the distribution system files need to be passed as a `Vector` of files, and the corresponding boundaries must be defined in the boundary linking file. For the following snippet, assume we have access to `./test/data` to get the respective files.

```julia
using PowerModelsITD
using Ipopt

# Files
pm_file = "case5_with2loads.m"
pmd_file1 = "case3_unbalanced.dss"
pmd_file2 = "case3_balanced.dss"
boundary_file = "case5_case3x2_unbal_bal.json"

pmd_files = [pmd_file1, pmd_file2] # create a vector of distribution system files.

pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel} # define the formulation type.

result = solve_opfitd(pm_file, pmd_files, boundary_file, pmitd_type, Ipopt.Optimizer)
```

## Parsing files

To parse the respective files into PowerModelsITD.jl, use the [`parse_files`](@ref parse_files) command

```julia
pmitd_data = parse_files(pm_file, pmd_file, boundary_file) # single distribution system file.
```

To parse for a model with multiple distribution system files, just pass the distribution system argument as a vector of files, as seen below.

```julia
pmd_files = [pmd_file1, pmd_file2]
pmitd_data = parse_files(pm_file, pmd_files, boundary_file) # vector of multiple distribution system files.
```

## Getting Results

The `solve_` commands in PowerModelsITD.jl return detailed results data in the form of a dictionary. This dictionary can be saved for further processing as follows,

```julia
result = solve_opfitd(pmitd_data, NLPowerModelITD{ACPPowerModel, ACPUPowerModel}, Ipopt.Optimizer)
```

**Note**: the function `solve_opfitd(...)` does **not** neccessarily needs for the data to be parsed (i.e., `parse_files(...)`). The user can pass directly the files of the problem to the `solve_opfitd(...)` function, as seen previously.

Alternatively, you can use the function `solve_model(...)` and specify the build method, in this case `build_opfitd`:

```julia
result = solve_model(pmitd_data, NLPowerModelITD{ACPPowerModel, ACPUPowerModel}, Ipopt.Optimizer, build_opfitd)
```

## Running Multinetwork (mn) Integrated Transmission-Distribution Optimal Power Flow (OPFITD) with Multiple Distribution Systems (ms)

The snippet shown below demonstrates how to run a multinetwork (mn) OPFITD with multiple distribution systems (ms) connected to different transmission system buses. As seen previously, the distribution system files need to be passed as a `Vector` of files, and the corresponding boundaries are defined in the boundary linking file. To run a **multinetwork** problem, time series values can be defined inside the _opendss_ file(s) that represent the distribution system(s). Some important things to remember are:

- The time series values can be defined in a `.csv` file that is called inside the _opendss_ file(s).

- When the data is parsed, the transmission system will be automatically **replicated** to the number of time series values available in the _opendss_ file(s).
- If data in the transmission system need to be modified for different time steps, the data can be modified after the parsing process is done.

- Remember to run the special multinetwork function or build function (i.e., `solve_mn_opfitd(...)` or `solve_model(..., build_mn_opfitd)`).

For the following snippet, assume we have access to `./test/data` to get the respective files.

```julia
using PowerModelsITD
using Ipopt

# Files
pm_file = "case5_with2loads.m"
pmd_file = "case3_unbalanced_withoutgen_mn.dss"
boundary_file = "case5_case3x2.json"

pmd_files = [pmd_file, pmd_file] # create a vector of distribution system files.

pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel} # define the formulation type.

result = solve_mn_opfitd(pm_file, pmd_files, boundary_file, pmitd_type, Ipopt.Optimizer; auto_rename=true)

```

**_Important Note_**: If you examine the file `case3_unbalanced_withoutgen_mn.dss` in detail, you will notice how time series power values are defined inside the _opendss_ file as `New Loadshape.ls1 pmult=(file=load_profile.csv)`, and then the load models are defined with parameters `model=1 daily=ls1`. This definition is sufficient for PowerModelsITD.jl to understand that this is a multinetwork problem. If you examine the content of the `load_profile.csv` file, you will notice that there are 4 time steps. This will cause the transmission, distribution, and boundary data to be replicated x4 (i.e., 4 times) while it is parsed to represent the overall problem.

**_Note_**: The `auto_rename=true` option used in this example will be explained in later documentation.

## Accessing Different Formulations

There is a diverse number of formulations that can be used to solve the `OPFITD`, `PFITD`, and other problem specifications. These can be found in `types.jl`. A non-exhaustive list of the supported formulations is presented below.

- [`NLPowerModelITD{ACPPowerModel, ACPUPowerModel}`](@ref NLPowerModelITD) indicates an AC to AC formulation in polar coordinates.
- [`NLPowerModelITD{ACRPowerModel, ACRUPowerModel}`](@ref NLPowerModelITD) indicates an AC to AC formulation in rectangular coordinates.
- [`LPowerModelITD{NFAPowerModel, NFAUPowerModel}`](@ref LPowerModelITD) indicates a linear network active power flow to network active power flow formulation.
- [`IVRPowerModelITD{IVRPowerModel, IVRUPowerModel}`](@ref IVRPowerModelITD) indicates an AC current-voltage to AC current-voltage formulation.
- [`BFPowerModelITD{SOCBFPowerModel, SOCNLPUBFPowerModel}`](@ref BFPowerModelITD) indicates an SOC branch-flow to SOC branch-flow formulation.
- [`NLBFPowerModelITD{ACRPowerModel, FBSUBFPowerModel}`](@ref NLBFPowerModelITD) indicates an AC in rectangular coordinates to forward-backward sweep formulation.
- [`NLFOTPowerModelITD{ACRPowerModel, FOTRUPowerModel}`](@ref NLFOTPowerModelITD) indicates an AC in rectangular coordinates to first-order Taylor in rectangular coordinates formulation.
- [`NLFOTPowerModelITD{ACPPowerModel, FOTPUPowerModel}`](@ref NLFOTPowerModelITD) indicates an AC in polar coordinates to first-order Taylor in polar coordinates formulation.

## Examples

More examples of working with the engineering data model can be found in the `/examples` folder of the PowerModelsITD.jl repository. These are Pluto Notebooks; instructions for running them can be found in the [Pluto documentation](https://github.com/fonsp/Pluto.jl#readme).
