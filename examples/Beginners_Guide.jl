### A Pluto.jl notebook ###
# v0.18.1

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ f624dbf2-fa1a-11eb-2e96-b92ef538ba6f
begin
	import Pkg
	Pkg.activate(mktempdir())
	Pkg.Registry.update()
	Pkg.add([
			Pkg.PackageSpec(;name="Revise"),
			Pkg.PackageSpec(;name="CodeTracking"),
			Pkg.PackageSpec(;name="PlutoUI"),
			Pkg.PackageSpec(;name="Ipopt", version="1.0.2"),
			Pkg.PackageSpec(;name="JuMP", version="0.23.1"),
			Pkg.PackageSpec(;name="PowerModelsITD", version="0.6.0"),
			])
end

# ╔═╡ 4b293648-92aa-4ebb-9d33-a6707773f0b1
using CodeTracking, Revise, PlutoUI

# ╔═╡ ac8bd5df-5696-4bfc-88f5-01feb8b61f89
begin
	using PowerModelsITD
	import JuMP
	import Ipopt
end

# ╔═╡ ea6bd476-ba83-4b1b-ad70-825b25d15135
md"""
# Introduction to PowerModelsITD

This Notebook was designed for the following versions:

- `julia = "~1.6"`
- `PowerModelsITD = "~0.6.0"`
- `PowerModelsDistribution = "~0.14.2"`
- `PowerModels = "~0.19.4"`

This notebook is a begginer's introduction to PowerModelsITD, an optimization-focused Julia library for steady state integrated power transmission-distribution modeling, based on `PowerModels.jl`, `PowerModelsDistribution.jl`, JuMP.jl, and part of the larger [InfrastructureModels.jl](https://github.com/lanl-ansi/InfrastructureModels.jl) ecosystem, which notably includes: 

- [PowerModels.jl](https://github.com/lanl-ansi/PowerModels.jl) : Transmission (single-phase positive sequence power networks) optimization
- [PowerModelsDistribution.jl](https://github.com/lanl-ansi/PowerModelsDistribution.jl) : Distribution (multi-conductor power networks) optimization
- [GasModels.jl](https://github.com/lanl-ansi/GasModels.jl) : Natural Gas pipeline optimization (includes Steady-state and Transient optimization)
- [WaterModels.jl](https://github.com/lanl-ansi/WaterModels.jl) : Water network steady-state optimization


## Julia Environment Setup

The following code block will setup a Julia environment for you with the correct versions of packages for this Pluto notebook. (**Needs to be updated for the final release**).

"""

# ╔═╡ 36d78d29-1417-4c05-adf3-4560fbc0304e
md"""
The following packages are used for notebook features only and **do not** relate to tutorial content.
"""

# ╔═╡ 6eec60ab-d093-4230-8374-01f6d5799e8d
md"""
This notebook will make use of the following packages in various places, so we will need to import them.
"""

# ╔═╡ cc24ea4a-656f-46aa-93db-2bc27d0e796e
md"""
Now, let's define the optimizer to be used for the rest of this notebook (**IPOPT**).
"""

# ╔═╡ e5c578f1-0c16-4b6c-83fb-045f8f18a8c4
ipopt = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "acceptable_tol"=>1.0e-8, "print_level"=>0, "sb"=>"yes")


# ╔═╡ 39d43eb3-ff43-4ef6-a30d-bd6ef8a632e0
md"""
## Run OPFITD and PFITD using `PowerModelsITD`
"""

# ╔═╡ 0c998d8a-8aeb-467a-8000-929b58adc35e
md"""
### Case Section - Selecting Sample Cases 
This notebook can apply to different data sets and you will need to select the compatible **transmission**, **distribution**, and **boundary linking file** that define the Integrated Transmission-Distribution Problem.

**Formulations**:

- `ACP-ACPU`: AC polar (Transmission) - AC polar (Distribution) 
- `ACR-ACRU`: AC rectangular (Transmission) - AC rectangular (Distribution)
- `NFA-NFAU`: Network Active Power Flow (Transmission) - Network Active Power Flow (Distribution)
- `IVR-IVRU`:  IV rectangular(Transmission) - IV rectangular (Distribution)
- `ACR-FOTRU`: AC rectangular (Transmission) - First-Order Taylor rectangular (Distribution)
- `ACP-FOTPU`: AC polar (Transmission) - First-Order Taylor polar (Distribution)
- `ACR-FBSU`: AC rectangular(Transmission) -  Forward-Backward Sweep (Distribution)


**Power Systems**:

- **Case5 - Transmission System**: PJM 5-bus system
- **Case3 - Distribution System**: IEEE 4 Node Test Feeder
- **Case13 - Distribution System**: IEEE 13 bus test system


Below, select the specific files from a few example cases included in the `PMITD` unit testing suite. The compatibility of the files is as follows:

**Case 1**: Case5-Case3 Balanced - 1 Boundary, No Generators in Dist. System. 
- _Transmission System_: "case5\_with\_1\_load\_case3bus" or "case5\_with\_1\_load\_case3bus_psse"
- _Distribution System_: "case3\_balanced\_nogenerators"
- _Boundaries Linking File_: "case5\_case3\_1\_boundary"

**Case 2**: Case5-Case3 Unbalanced - 1 Boundary, No Generators in Dist. System.
- _Transmission System_: "case5\_with\_1\_load\_case3bus" or "case5\_with\_1\_load\_case3bus_psse"
- _Distribution System_: "case3\_unbalanced\_nogenerators"
- _Boundaries Linking File_: "case5\_case3\_1\_boundary"

**Case 3**: Case5-Case3 Balanced - 1 Boundary, 1 Generator in Dist. System. 
- _Transmission System_: "case5\_with\_1\_load\_case3bus" or "case5\_with\_1\_load\_case3bus_psse"
- _Distribution System_: "case3\_balanced\_1generator"
- _Boundaries Linking File_: "case5\_case3\_1\_boundary"


**Case 4**: Case5-Case3 Unbalanced - 1 Boundary, 1 Generator in Dist. System.
- _Transmission System_: "case5\_with\_1\_load\_case3bus" or "case5\_with\_1\_load\_case3bus_psse"
- _Distribution System_: "case3\_unbalanced\_1generator"
- _Boundaries Linking File_: "case5\_case3\_1\_boundary"


**Case 5**: Case5-CaseIEEE13 Balanced - 1 Boundary, No Generators in Dist. System.
- _Transmission System_: "case5\_with\_1\_load_ieee13bus"
- _Distribution System_: "caseIEEE13\_balanced\_nogenerators"
- _Boundaries Linking File_: "case5\_caseIEEE13\_1\_boundary"

**Case 6**: Case5-CaseIEEE13 Unbalanced - 1 Boundary, No Generators in Dist. System.
- _Transmission System_: "case5\_with\_1\_load_ieee13bus"
- _Distribution System_: "caseIEEE13\_unbalanced\_nogenerators"
- _Boundaries Linking File_: "case5\_caseIEEE13\_1\_boundary"
"""

# ╔═╡ e2200c7f-e434-4e38-a990-19761a2c236c
md"""

#### Transmission System File:

"""

# ╔═╡ 564ffa56-50ab-4ed9-ac37-341f633793fb
begin
	pmitd_path = joinpath(dirname(pathof(PowerModelsITD)), "..")
	@bind pm_file Select([
			joinpath(pmitd_path, "test/data/transmission/case5_withload.m") => "case5_with_1_load_case3bus",
			joinpath(pmitd_path, "test/data/transmission/case5_withload_ieee13.m") => "case5_with_1_load_ieee13bus",
			joinpath(pmitd_path, "test/data/transmission/case5_withload.raw") => "case5_with_1_load_case3bus_psse",
		])
end

# ╔═╡ a8a21183-1dce-4503-bce2-6ce7788ef9ee
md"""

#### Distribution System File:

"""

# ╔═╡ b2f5fd5e-2d7f-4cd4-b64f-82fc3bd6ee97
begin
	@bind pmd_file Select([
			joinpath(pmitd_path, "test/data/distribution/case3_balanced_withoutgen.dss") => "case3_balanced_nogenerators",
			joinpath(pmitd_path, "test/data/distribution/case3_unbalanced_withoutgen.dss") => "case3_unbalanced_nogenerators",
			joinpath(pmitd_path, "test/data/distribution/case3_balanced.dss") => "case3_balanced_1generator",
			joinpath(pmitd_path, "test/data/distribution/case3_unbalanced.dss") => "case3_unbalanced_1generator",
			joinpath(pmitd_path, "test/data/distribution/caseIEEE13_balanced_withoutgen.dss") => "caseIEEE13_balanced_nogenerators",
			joinpath(pmitd_path, "test/data/distribution/caseIEEE13_unbalanced_withoutgen.dss") => "caseIEEE13_unbalanced_nogenerators",
		])
end

# ╔═╡ f9bc611f-a8fb-4906-80e0-8cd05f692bd1
md"""

#### Boundary(ies) Linking File:

"""

# ╔═╡ 99a2b324-2caa-42d4-b0e7-eee9c1942bf9
begin
	@bind pmitd_file Select([
			joinpath(pmitd_path, "test/data/json/case5_case3.json") => "case5_case3_1_boundary",
			joinpath(pmitd_path, "test/data/json/case5_case13.json") => "case5_caseIEEE13_1_boundary",
		])
end

# ╔═╡ 1f7e6050-801b-49f6-94bc-87fc93651211
md"""

### Select Type of `PMITD` Formulation

"""

# ╔═╡ a4823ff4-cd74-4a7a-b358-228db2ca834e
begin
	@bind pmitd_type_selected Select([
			"ACR-ACRU"=> "ACR-ACR Formulation",
			"ACP-ACPU"=> "ACP-ACP Formulation",
			"IVR-IVRU"=> "IVR-IVR Formulation",
			"NFA-NFAU"=> "NFA-NFA Formulation",
			"ACR-FOTRU"=> "ACR-FOTR Formulation",
			"ACP-FOTPU"=> "ACP-FOTP Formulation",
			"ACR-FBSU"=> "ACP-FBS Formulation",
		])
end

# ╔═╡ e61938ea-2d67-4592-a583-c21194278a2a
if (pmitd_type_selected == "ACR-ACRU")
	pmitd_type = NLPowerModelITD{ACRPowerModel, ACRUPowerModel}
elseif(pmitd_type_selected == "ACP-ACPU")
	pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
elseif(pmitd_type_selected == "ACR-FOTRU")
	pmitd_type = NLFOTPowerModelITD{ACRPowerModel, FOTRUPowerModel}
elseif(pmitd_type_selected == "ACP-FOTPU")
	pmitd_type = NLFOTPowerModelITD{ACPPowerModel, FOTPUPowerModel}
elseif(pmitd_type_selected == "ACR-FBSU")
	pmitd_type = NLBFPowerModelITD{ACRPowerModel, FBSUBFPowerModel}
elseif(pmitd_type_selected == "NFA-NFAU")
	pmitd_type = LPowerModelITD{NFAPowerModel, NFAUPowerModel}
elseif(pmitd_type_selected == "IVR-IVRU")
	pmitd_type = IVRPowerModelITD{IVRPowerModel, IVRUPowerModel}
end

# ╔═╡ 28baca4a-eb1a-440b-882f-4f3ef93ce7ba
md"""
### Run Optimal Power Flow For Integrated Transmission-Distribution (OPFITD) 
"""

# ╔═╡ f25f1f56-a60e-40aa-85f2-8bb73ad41ed7
 result = solve_opfitd(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt)

# ╔═╡ 816424e4-5ec4-4ac2-a94a-41e7e2e7e305
md"""
#### Check the result `termination status` 
"""

# ╔═╡ b81e4bb7-064d-444b-ac37-3bf33a2ab0fb
result["termination_status"] == LOCALLY_SOLVED

# ╔═╡ 31b3eb2c-d4aa-48b3-9a34-3fd9e5d36b28
md"""
#### Check the result `solve_time` 
"""

# ╔═╡ 14e79d84-627c-49fa-a298-b1bed3835773
result["solve_time"]

# ╔═╡ 505b14d0-ddf6-42f6-a813-eee9187719fd
md"""
#### Check the result `objective` 
"""

# ╔═╡ 36098871-82dd-47a4-9e09-0578e7152011
result["objective"]

# ╔═╡ 5efecb35-514c-4b32-a295-0a885355ad7e
md"""
#### Check the result `boundary links variables values` 
"""

# ╔═╡ ef43a249-c744-4a5e-b8c5-143f2c5016fc
result["solution"]["it"]["pmitd"]

# ╔═╡ 81462c83-1869-47b8-b357-a7887960bbfe
md"""
#### Check the result transmission system `results` 
"""

# ╔═╡ 825edcfa-d024-4ebf-97dc-d4c24f2f998d
result["solution"]["it"]["pm"]

# ╔═╡ 3e808aaa-a54d-4ee9-ada8-a8114e8e61bc
md"""
#### Check the result distribution system(s) `results` 
"""

# ╔═╡ acc97ad0-2d10-4b12-915d-ea3cccb8bc14
result["solution"]["it"]["pmd"]

# ╔═╡ 978a92b6-70e6-41f1-b9f4-4a21d7addbb8
md"""
### Run Power Flow For Integrated Transmission-Distribution (PFITD) 
"""

# ╔═╡ 16f7f7d2-054c-409f-88fc-280b8023ade6
 result_pfitd = solve_pfitd(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt)

# ╔═╡ 57657b07-7690-4ff9-86cf-90512d4b7091
md"""
#### Check the result `termination status` 
"""

# ╔═╡ 3cb814b8-a51d-44ac-8e7f-29c9acbd4ba2
result_pfitd["termination_status"] == LOCALLY_SOLVED

# ╔═╡ ab03bc56-9d59-407d-84de-b41ce0ceecd5
md"""
#### Check the result `solve_time` 
"""

# ╔═╡ 0aeceb84-4fc8-400b-beaf-1bbd84c308b9
result_pfitd["solve_time"]

# ╔═╡ fc572c72-bc37-4a06-a79c-21ff6a977104
md"""
#### Check the result `objective` (should be **0** since it is a PF)
"""

# ╔═╡ b5aaa8e2-e768-4f3b-ad6d-370b9ee363f6
result_pfitd["objective"]

# ╔═╡ c6742db0-cfd3-4b2f-b8c3-3226b6017f1a
md"""
#### Check the result `boundary links variables values` 
"""

# ╔═╡ 1bb74657-1ba4-4fb3-9eb0-f2a10056aec1
result_pfitd["solution"]["it"]["pmitd"]

# ╔═╡ 5ccbd72d-5d41-4fbd-acab-af029823e409
md"""

------------------------------------------------------------------------------
------------------------------------------------------------------------------

"""

# ╔═╡ e3b81834-117a-436e-8382-040c67399b1a
md"""
## Run OPFITD and PFITD using `PowerModelsITD` (SOC Relaxations)


**Formulations**:

- `SOCBF-SOCUBF`:  Second-Order Cone Branch Flow (Transmission) - Second-Order Cone Unbalanced Branch Flow(Distribution)

"""

# ╔═╡ 123fec4f-46f0-40dc-a6d4-39c7c8d7b0b4
md"""

##### Transmission System File:

"""

# ╔═╡ 40f099f0-c647-4d49-bf45-7bd1357de36e
begin
	@bind pm_file_other Select([
			joinpath(pmitd_path, "test/data/transmission/case5_withload.m") => "case5_with_1_load_case3bus",
			joinpath(pmitd_path, "test/data/transmission/case5_withload.raw") => "case5_with_1_load_case3bus_psse",
		])
end

# ╔═╡ 44856d76-38db-43c4-9572-2982bf6228ee
md"""

##### Boundary(ies) Linking File:

"""

# ╔═╡ af46ddfb-762b-461d-8d45-68eb35e136e7
begin
	@bind pmitd_file_other Select([
			joinpath(pmitd_path, "test/data/json/case5_case3.json") => "case5_case3_1_boundary",
		])
end

# ╔═╡ ef4e1b2d-37ca-49d1-a3df-7bc8e2cdb506
md"""

##### Distribution System File:

"""

# ╔═╡ 7d84f34e-0ea5-4c67-9f09-918ecacf5aff
begin
	@bind pmd_file_soc Select([
			joinpath(pmitd_path, "test/data/distribution/case3_balanced_notransformer_withoutgen.dss") => "case3_balanced_nogenerators_noSubsTransformer_ForSOCFormulation",
			joinpath(pmitd_path, "test/data/distribution/case3_balanced_notransformer.dss") => "case3_balanced_1generator_noSubsTransformer_ForSOCFormulation",
			joinpath(pmitd_path, "test/data/distribution/case3_unbalanced_notransformer_withoutgen.dss") => "case3_unbalanced_nogenerators_noSubsTransformer_ForSOCFormulation",
			joinpath(pmitd_path, "test/data/distribution/case3_unbalanced_notransformer.dss") => "case3_unbalanced_1generator_noSubsTransformer_ForSOCFormulation",
		])
end

# ╔═╡ 1ba2cbdd-204d-4f47-80ab-5e502a27980a
md"""

#### Select Type of `PMITD` Formulation

"""

# ╔═╡ ef921749-a063-43ba-832d-af54fd9d0fab
begin
	@bind pmitd_type_selected_soc Select([
			"SOCBF-SOCUBF"=> "SOCBF-SOCUBF Formulation",
		])
end

# ╔═╡ 633653ba-e6dd-431f-80df-740e8321a515
if(pmitd_type_selected_soc == "SOCBF-SOCUBF")
	pmitd_type_soc = BFPowerModelITD{SOCBFPowerModel, SOCNLPUBFPowerModel}
end

# ╔═╡ 0001a753-de84-45e7-b1d3-394c34596705
result_soc = solve_opfitd(pm_file_other, pmd_file_soc, pmitd_file_other, pmitd_type_soc, ipopt)

# ╔═╡ ac80d9b0-4cde-4b04-a4f0-1346194f6b55
result_soc["solution"]["it"]["pmitd"]

# ╔═╡ 439e5bc6-f7fc-454e-b9d1-0bbb8e5dcb5a
md"""

------------------------------------------------------------------------------
------------------------------------------------------------------------------

"""

# ╔═╡ d2c5610d-2290-4312-ab9d-c6235e82643a
md"""
# Standard use of `PowerModelsITD` (Real Coding Example - No `Selects`)


In this section, we will present how to use PowerModelsITD in an **actual** coding example. For these cases, we will present test cases where **_multiple_** (i.e., 2 distribution systems) distribution systems are connected to different transmission system buses.
"""

# ╔═╡ 42cfff87-bbc9-42ff-827d-054ffa9c0afe
md"""
##### (a) Load transmission system (`pm`) file
"""

# ╔═╡ fe0be741-28fb-477c-bd62-c9711807a598
pm_file_multcase = joinpath(pmitd_path, "test/data/transmission/case5_with2loads.m")

# ╔═╡ 83c617e9-14bb-4aaa-8d8d-9254bff73d5b
begin
	pm_file_multcase_read = open(pm_file_multcase, "r") do l
		join(readlines(l),"\n")
	end

importing_data_md_pm_multcase = """

PMITD supports two input formats for Transmission Systems, __MATPOWER__ and __PSS/E__ input formats.
Below is an example of a __MATPOWER__ specification: $(pm_file_multcase)
```pm_file_multcase
$(pm_file_multcase_read)
```
"""
	importing_data_md_pm_multcase |> Markdown.parse
end

# ╔═╡ 9ec8d9a5-595d-4124-a73b-5f29b6d6b564
md"""
##### (b) Load distribution system (`pmd`) files
"""

# ╔═╡ dfa54ef4-4571-4195-9bad-5fd6905136b4
pmd_file1 = joinpath(pmitd_path, "test/data/distribution/case3_balanced_withoutgen.dss")

# ╔═╡ 34b0b912-255c-4275-9e95-d18e67c91991
pmd_file2 = joinpath(pmitd_path, "test/data/distribution/case3_unbalanced_withoutgen.dss")

# ╔═╡ 21af3cf3-80dc-431a-b877-b5b65295b80e
md"""
###### **IMPORTANT**: Multiple distribution system files need to passed to `PowerModelsITD` as a **_Vector_** of files (As seen below).
"""

# ╔═╡ 0439a5a5-fde3-46df-81f3-d66c60583ed3
pmd_files_multcase = [pmd_file1, pmd_file2]

# ╔═╡ 86649d64-fcb0-414b-923d-f4491e1af1fd
begin
	pmd_file1_read = open(pmd_file1, "r") do g
		join(readlines(g),"\n")
	end

importing_data_md_pmd1 = """

PMITD supports the __OpenDSS__ input format for Distribution Systems, 
Below is an example of a __OpenDSS__ specification: $(pmd_file1) **and** $(pmd_file2)
```pmd_file1
$(pmd_file1_read)
```
"""
	importing_data_md_pmd1 |> Markdown.parse
end

# ╔═╡ 58fc5570-85ed-4896-8e2a-cf14e2ec16f5
begin
	pmd_file2_read = open(pmd_file2, "r") do h
		join(readlines(h),"\n")
	end

importing_data_md_pmd2 = """

```pmd_file2
$(pmd_file2_read)
```
"""
	importing_data_md_pmd2 |> Markdown.parse
end

# ╔═╡ 5f616149-5d33-42ec-b6a5-2271a044de95
md"""
##### (c) Load boundary links system (`pmitd`) files

**IMPORTANT**: This file must contain all the boundary links for the PMITD system.
"""

# ╔═╡ 45e850da-e8b8-4b4b-983e-1ae95a381ee7
pmitd_file_multcase = joinpath(pmitd_path, "test/data/json/case5_case3x2.json")

# ╔═╡ ac629674-a504-461a-80c9-feaabcec12d5
begin
	pmitd_file_multcase_read = open(pmitd_file_multcase, "r") do f
		join(readlines(f),"\n")
	end

importing_data_md = """

PMITD supports the __JSON__ input format for `boundary links` files.
Below is an example of a __JSON__ specification for multiple distribution systems: $(pmitd_file_multcase):
```pmitd_file_multcase
$(pmitd_file_multcase_read)
```
Data is imported via the `parse_file` command, which we will use further down in the tutorial.
"""
	importing_data_md |> Markdown.parse
end

# ╔═╡ e5348961-2cda-4d2a-a658-4427b9c60237
md"""
##### (d) Define the **formulation** `type` for the ITD problem.

"""

# ╔═╡ c8847ff3-ef6f-463f-b5e7-05bab3c79473
# pmitd_type_multcase = NLPowerModelITD{ACRPowerModel, ACRUPowerModel} 
pmitd_type_multcase = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
# pmitd_type_multcase = LPowerModelITD{NFAPowerModel, NFAUPowerModel}

# ╔═╡ 4ef506b4-fc89-4757-ba14-a40762bf1889
md"""
##### (e) Parse the files for the ITD problem.

**Note**: At this point, you can call the function `solve_opfitd(...)` or `solve_pfitd(...)`, as shown in previous sections. These functions take care of parsing the files and running the model. However, in this case we will do the entire process of parsing the files and then running the model with the parsed files 'manually'. 

"""

# ╔═╡ 7c9244c9-b0e8-46d9-8400-673d52cf78fa
pmitd_data_multcase = parse_files(pm_file_multcase, pmd_files_multcase, pmitd_file_multcase)

# ╔═╡ 6039d564-1d21-4a04-9a81-69aec6eb0313
md"""
##### (f) Run the model (OPFITD Model).

**Note**: `build_opfitd`

"""

# ╔═╡ 5793e46b-c702-4f38-b1a8-c3fcb7778ec0
result_multcase = solve_model(pmitd_data_multcase, pmitd_type_multcase, ipopt, build_opfitd)

# ╔═╡ 8a3156df-f4a8-4872-9eae-8453f128b642
result_multcase["solution"]["it"]["pmitd"]

# ╔═╡ 84bc2e2b-6dec-462d-ba9a-fe22e1076da9
md"""

------------------------------------------------------------------------------
------------------------------------------------------------------------------

"""

# ╔═╡ 8b0dd87c-623b-4a2c-9c91-5736cd9ca993
md"""
# Running Multinetwork (Time-series) Multisystem (Multiple Distribution Systems) OPFITD using `PowerModelsITD`


In this section, we will present how to run a **Multinetwork** OPFITD with **multiple distribution systems** connected to different transmission system buses. 

As seen previously, the distribution system files need to be passed as a `Vector` of files, and the corresponding boundaries are defined in the boundary linking file. 

To run a **multinetwork** problem, time series values can be defined inside the _opendss_ file(s) that represent the distribution system(s). Some important things to remember are: 

- The time series values can be defined in a `.csv` file that is called inside the _opendss_ file(s).

- When the data is parsed, the transmission system will be automatically **replicated** to the number of time series values available in the _opendss_ file(s). 
    
- If data in the transmission system need to be modified for different time steps, the data can be modified after the parsing process is done.

- Remember to run the special multinetwork function or build function [i.e., `solve_mn_opfitd(...)` or `solve_model(..., build_mn_opfitd)`].

"""

# ╔═╡ c96945f8-4680-4b45-a6ee-b15ccb44104e
begin
	# load files
	pm_file_mn = joinpath(pmitd_path, "test/data/transmission/case5_with2loads.m")
	pmd_file1_mn = joinpath(pmitd_path, 
						"test/data/distribution/case3_unbalanced_withoutgen_mn.dss")
	pmitd_file_mn = joinpath(pmitd_path, "test/data/json/case5_case3x2.json")

	# create a vector of distribution system files.
	pmd_files_mn = [pmd_file1_mn, pmd_file1_mn] 

	# define the formulation type.
	pmitd_type_mn = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
	# pmitd_type_mn = NLPowerModelITD{ACRPowerModel, ACRUPowerModel}
	# pmitd_type_mn = IVRPowerModelITD{IVRPowerModel, IVRUPowerModel}
	# pmitd_type_mn = NLFOTPowerModelITD{ACRPowerModel, FOTRUPowerModel}
	# pmitd_type_mn = NLFOTPowerModelITD{ACPPowerModel, FOTPUPowerModel}
	# pmitd_type_mn = BFPowerModelITD{SOCBFPowerModel, LinDist3FlowPowerModel}
	# pmitd_type_mn = NLBFPowerModelITD{ACRPowerModel, FBSUBFPowerModel}
	

	# run multinetwork opfitd.
	result_mn = solve_mn_opfitd(pm_file_mn, pmd_files_mn, pmitd_file_mn, 
															pmitd_type_mn, ipopt)

end

# ╔═╡ 8e81fb77-f724-4e8b-9ebd-1870d1661607
md"""
##### The `csv` file that defines the load power time series values for the previous test can be seen below.
"""

# ╔═╡ 26454115-136f-4c68-9895-f51b376f3b74
begin

	csv_file = joinpath(pmitd_path, "test/data/distribution/load_profile.csv")
	
	csv_file_read = open(csv_file, "r") do f
		join(readlines(f),"\n")
	end

importing_data_md_csv = """

Time series values defined in the `csv` file: $(csv_file):
```csv_file
$(csv_file_read)
```
"""
	importing_data_md_csv |> Markdown.parse
end

# ╔═╡ 1fc25dd0-3763-44c1-b4f7-9a387718517d
md"""

------------------------------------------------------------------------------
------------------------------------------------------------------------------

"""

# ╔═╡ 102e7f3c-f7b1-46e7-b4bb-cededa838fc6
md"""
# Support for `PowerModelsDistribution` (`PMD`) Transformations

In this section, we will present some of the `PMD` transformations available in `PowerModelsITD` (`PMITD`). We will demonstrate how these transformations can be applied in `PMITD`.

The **transformations** currently available in `PMITD` are:

- `apply_voltage_bounds!(...)`
- `apply_voltage_angle_difference_bounds!(...)`
- `remove_all_bounds!(...)`
- `make_lossless!(...)`
- `apply_kron_reduction!(...)`
- `apply_phase_projection!(...)`
- `apply_phase_projection_delta!(...)`

Below, we will present how to use (apply) some of these transformations from `PMITD`.

"""

# ╔═╡ 8304e3a9-2ef0-41c5-b96b-a280fdda3bbc
md"""
### 'Apply **bounds**' Transformations

In order to apply any transformation, we need to pass in the parsed data to the corresponding transformations/bounds functions. The same procedure from `PowerModelsDistribution` is mantained.  

Below, we can observe an example where **voltage bounds** and **voltage angle difference bounds** are applied to a test case study.
"""

# ╔═╡ 69d1f6cd-4ef5-475a-9706-f55db074c942
begin
	# parse files
	pmitd_data_b = parse_files(pm_file_multcase, pmd_files_multcase, 														pmitd_file_multcase)
	# apply transformations
	apply_voltage_bounds!(pmitd_data_b; vm_lb=0.99, vm_ub=1.01)
	apply_voltage_angle_difference_bounds!(pmitd_data_b, 1)
	# run opftid
	result_opfitd_b = solve_model(pmitd_data_b, pmitd_type_multcase, ipopt, 																				build_opfitd)
end

# ╔═╡ d3165f27-4c14-417f-93da-a78f574263c3
md"""
### 'Apply **remove all bounds**' Transformations

Similar to the previously applied transformations, to apply the `remove_all_bounds!(...)` transformation, we just need to call the corresponding transformation function.

Below, we can observe an example where the **remove all bounds** transformation is applied to a test case study.
"""

# ╔═╡ 76ae34ba-5017-4be2-bf4c-8e5e1d53c3a0
begin
	# parse files
	pmitd_data_rab = parse_files(pm_file_multcase, pmd_files_multcase, 														pmitd_file_multcase)
	# apply transformations
    remove_all_bounds!(pmitd_data_rab)
	# run opftid
	result_rab = solve_model(pmitd_data_rab, pmitd_type_multcase, ipopt, 																				build_opfitd)
end

# ╔═╡ f4f05958-fad6-4cbd-a1e8-19e35256df02
md"""
### 'Apply **kron reduction**' Transformations

Similar to the previously applied transformations, to apply the `apply_kron_reduction!(...)` transformation, we just need to call the corresponding transformation function.

Below, we can observe an example where the **apply kron reduction** transformation is applied to a test case study.
"""

# ╔═╡ c910cc49-e7ed-45cd-bc69-bb34fc24a666
begin
	# parse files
	pmitd_data_kron = parse_files(pm_file_multcase, pmd_files_multcase, 														pmitd_file_multcase)
	# apply transformations
    apply_kron_reduction!(pmitd_data_kron)
	# run opftid
	result_kron = solve_model(pmitd_data_kron, pmitd_type_multcase, ipopt, 																				build_opfitd)
end

# ╔═╡ f1553ee5-083f-4264-8e80-d31c475cc269
md"""

------------------------------------------------------------------------------
------------------------------------------------------------------------------

"""

# ╔═╡ 8bf07b81-107c-4b16-8d46-02bfff44e42b
md"""
# Development
**PowerModelsITD** is currently subject to active, ongoing development, and is used internally by various high-profile projects, making its improvement and maintanence high priority.
"""

# ╔═╡ Cell order:
# ╟─ea6bd476-ba83-4b1b-ad70-825b25d15135
# ╠═f624dbf2-fa1a-11eb-2e96-b92ef538ba6f
# ╟─36d78d29-1417-4c05-adf3-4560fbc0304e
# ╠═4b293648-92aa-4ebb-9d33-a6707773f0b1
# ╟─6eec60ab-d093-4230-8374-01f6d5799e8d
# ╠═ac8bd5df-5696-4bfc-88f5-01feb8b61f89
# ╟─cc24ea4a-656f-46aa-93db-2bc27d0e796e
# ╠═e5c578f1-0c16-4b6c-83fb-045f8f18a8c4
# ╟─39d43eb3-ff43-4ef6-a30d-bd6ef8a632e0
# ╟─0c998d8a-8aeb-467a-8000-929b58adc35e
# ╟─e2200c7f-e434-4e38-a990-19761a2c236c
# ╟─564ffa56-50ab-4ed9-ac37-341f633793fb
# ╟─a8a21183-1dce-4503-bce2-6ce7788ef9ee
# ╟─b2f5fd5e-2d7f-4cd4-b64f-82fc3bd6ee97
# ╟─f9bc611f-a8fb-4906-80e0-8cd05f692bd1
# ╟─99a2b324-2caa-42d4-b0e7-eee9c1942bf9
# ╟─1f7e6050-801b-49f6-94bc-87fc93651211
# ╟─a4823ff4-cd74-4a7a-b358-228db2ca834e
# ╟─e61938ea-2d67-4592-a583-c21194278a2a
# ╟─28baca4a-eb1a-440b-882f-4f3ef93ce7ba
# ╠═f25f1f56-a60e-40aa-85f2-8bb73ad41ed7
# ╟─816424e4-5ec4-4ac2-a94a-41e7e2e7e305
# ╠═b81e4bb7-064d-444b-ac37-3bf33a2ab0fb
# ╟─31b3eb2c-d4aa-48b3-9a34-3fd9e5d36b28
# ╠═14e79d84-627c-49fa-a298-b1bed3835773
# ╟─505b14d0-ddf6-42f6-a813-eee9187719fd
# ╠═36098871-82dd-47a4-9e09-0578e7152011
# ╟─5efecb35-514c-4b32-a295-0a885355ad7e
# ╠═ef43a249-c744-4a5e-b8c5-143f2c5016fc
# ╟─81462c83-1869-47b8-b357-a7887960bbfe
# ╠═825edcfa-d024-4ebf-97dc-d4c24f2f998d
# ╟─3e808aaa-a54d-4ee9-ada8-a8114e8e61bc
# ╠═acc97ad0-2d10-4b12-915d-ea3cccb8bc14
# ╟─978a92b6-70e6-41f1-b9f4-4a21d7addbb8
# ╠═16f7f7d2-054c-409f-88fc-280b8023ade6
# ╟─57657b07-7690-4ff9-86cf-90512d4b7091
# ╠═3cb814b8-a51d-44ac-8e7f-29c9acbd4ba2
# ╟─ab03bc56-9d59-407d-84de-b41ce0ceecd5
# ╠═0aeceb84-4fc8-400b-beaf-1bbd84c308b9
# ╟─fc572c72-bc37-4a06-a79c-21ff6a977104
# ╠═b5aaa8e2-e768-4f3b-ad6d-370b9ee363f6
# ╟─c6742db0-cfd3-4b2f-b8c3-3226b6017f1a
# ╠═1bb74657-1ba4-4fb3-9eb0-f2a10056aec1
# ╟─5ccbd72d-5d41-4fbd-acab-af029823e409
# ╟─e3b81834-117a-436e-8382-040c67399b1a
# ╟─123fec4f-46f0-40dc-a6d4-39c7c8d7b0b4
# ╟─40f099f0-c647-4d49-bf45-7bd1357de36e
# ╟─44856d76-38db-43c4-9572-2982bf6228ee
# ╟─af46ddfb-762b-461d-8d45-68eb35e136e7
# ╟─ef4e1b2d-37ca-49d1-a3df-7bc8e2cdb506
# ╟─7d84f34e-0ea5-4c67-9f09-918ecacf5aff
# ╟─1ba2cbdd-204d-4f47-80ab-5e502a27980a
# ╟─ef921749-a063-43ba-832d-af54fd9d0fab
# ╟─633653ba-e6dd-431f-80df-740e8321a515
# ╠═0001a753-de84-45e7-b1d3-394c34596705
# ╠═ac80d9b0-4cde-4b04-a4f0-1346194f6b55
# ╟─439e5bc6-f7fc-454e-b9d1-0bbb8e5dcb5a
# ╟─d2c5610d-2290-4312-ab9d-c6235e82643a
# ╟─42cfff87-bbc9-42ff-827d-054ffa9c0afe
# ╠═fe0be741-28fb-477c-bd62-c9711807a598
# ╟─83c617e9-14bb-4aaa-8d8d-9254bff73d5b
# ╟─9ec8d9a5-595d-4124-a73b-5f29b6d6b564
# ╠═dfa54ef4-4571-4195-9bad-5fd6905136b4
# ╠═34b0b912-255c-4275-9e95-d18e67c91991
# ╟─21af3cf3-80dc-431a-b877-b5b65295b80e
# ╠═0439a5a5-fde3-46df-81f3-d66c60583ed3
# ╟─86649d64-fcb0-414b-923d-f4491e1af1fd
# ╟─58fc5570-85ed-4896-8e2a-cf14e2ec16f5
# ╟─5f616149-5d33-42ec-b6a5-2271a044de95
# ╠═45e850da-e8b8-4b4b-983e-1ae95a381ee7
# ╟─ac629674-a504-461a-80c9-feaabcec12d5
# ╟─e5348961-2cda-4d2a-a658-4427b9c60237
# ╠═c8847ff3-ef6f-463f-b5e7-05bab3c79473
# ╟─4ef506b4-fc89-4757-ba14-a40762bf1889
# ╠═7c9244c9-b0e8-46d9-8400-673d52cf78fa
# ╟─6039d564-1d21-4a04-9a81-69aec6eb0313
# ╠═5793e46b-c702-4f38-b1a8-c3fcb7778ec0
# ╠═8a3156df-f4a8-4872-9eae-8453f128b642
# ╟─84bc2e2b-6dec-462d-ba9a-fe22e1076da9
# ╟─8b0dd87c-623b-4a2c-9c91-5736cd9ca993
# ╠═c96945f8-4680-4b45-a6ee-b15ccb44104e
# ╟─8e81fb77-f724-4e8b-9ebd-1870d1661607
# ╟─26454115-136f-4c68-9895-f51b376f3b74
# ╟─1fc25dd0-3763-44c1-b4f7-9a387718517d
# ╟─102e7f3c-f7b1-46e7-b4bb-cededa838fc6
# ╟─8304e3a9-2ef0-41c5-b96b-a280fdda3bbc
# ╠═69d1f6cd-4ef5-475a-9706-f55db074c942
# ╟─d3165f27-4c14-417f-93da-a78f574263c3
# ╠═76ae34ba-5017-4be2-bf4c-8e5e1d53c3a0
# ╟─f4f05958-fad6-4cbd-a1e8-19e35256df02
# ╠═c910cc49-e7ed-45cd-bc69-bb34fc24a666
# ╟─f1553ee5-083f-4264-8e80-d31c475cc269
# ╟─8bf07b81-107c-4b16-8d46-02bfff44e42b
