### A Pluto.jl notebook ###
# v0.19.32

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

# ╔═╡ 4b293648-92aa-4ebb-9d33-a6707773f0b1
using PlutoUI

# ╔═╡ 7592c3de-481f-4877-a362-56e0eaaf56b0
using PowerModelsITD

# ╔═╡ e5c578f1-0c16-4b6c-83fb-045f8f18a8c4
using Ipopt # Optimizer

# ╔═╡ ea6bd476-ba83-4b1b-ad70-825b25d15135
md"""
# Introduction to PowerModelsITD

This Notebook was designed for the following versions:

- `julia = "~1.6"`
- `PowerModelsITD = "~0.7.9"`
- `PowerModelsDistribution = "~0.15.1"`
- `PowerModels = "~0.19.9"`

This notebook is a beginner's introduction to [`PowerModelsITD.jl`](https://github.com/lanl-ansi/PowerModelsITD.jl), an optimization-focused Julia library for steady state integrated power transmission-distribution modeling, based on `PowerModels.jl`, `PowerModelsDistribution.jl`, `JuMP.jl`, and part of the larger [`InfrastructureModels.jl`](https://github.com/lanl-ansi/InfrastructureModels.jl) ecosystem, which notably includes:

- [`PowerModels.jl`](https://github.com/lanl-ansi/PowerModels.jl) : Transmission (single-phase positive sequence power networks) optimization
- [`PowerModelsDistribution.jl`](https://github.com/lanl-ansi/PowerModelsDistribution.jl) : Distribution (multi-conductor power networks) optimization
- [`GasModels.jl`](https://github.com/lanl-ansi/GasModels.jl) : Natural Gas pipeline optimization (includes Steady-state and Transient optimization)
- [`WaterModels.jl`](https://github.com/lanl-ansi/WaterModels.jl) : Water network steady-state optimization


## Julia Environment Setup

The following code block will setup a Julia environment for you with the correct versions of packages for this Pluto notebook.

"""

# ╔═╡ 36d78d29-1417-4c05-adf3-4560fbc0304e
md"""
The following packages are used for notebook features only and **do not** relate to tutorial content.
"""

# ╔═╡ 6eec60ab-d093-4230-8374-01f6d5799e8d
md"""
Let's import PowerModelsITD.
"""

# ╔═╡ cc24ea4a-656f-46aa-93db-2bc27d0e796e
md"""
Let's define the optimizer to be used for the rest of this notebook (**IPOPT**).
"""

# ╔═╡ 39d43eb3-ff43-4ef6-a30d-bd6ef8a632e0
md"""
## Run OPFITD and PFITD using `PowerModelsITD`
"""

# ╔═╡ 0c998d8a-8aeb-467a-8000-929b58adc35e
md"""
### Case Section - Selecting Sample Cases
This notebook can apply to different data sets and you will need to select the compatible **transmission**, **distribution**, and **boundary linking file** that define the Integrated Transmission-Distribution Problem.

**Formulations**:

- `ACP-ACPU`: AC polar (Transmission) - AC unbalanced polar (Distribution)
- `ACR-ACRU`: AC rectangular (Transmission) - AC unbalanced rectangular (Distribution)
- `NFA-NFAU`: Network active power flow (Transmission) - Network active unbalanced power flow (Distribution)
- `IVR-IVRU`:  IV rectangular (Transmission) - IV rectangular unbalanced (Distribution)
- `ACR-FOTRU`: AC rectangular (Transmission) - First-Order Taylor rectangular unbalanced (Distribution)
- `ACP-FOTPU`: AC polar (Transmission) - First-Order Taylor polar unbalanced (Distribution)
- `ACR-FBSU`: AC rectangular (Transmission) -  Forward-backward sweep unbalanced (Distribution)


**Power Systems**:

- **Case5 - Transmission System**: PJM 5-bus system
- **Case3 - Distribution System**: IEEE 4 Node Test Feeder
- **Case13 - Distribution System**: IEEE 13 bus test system


Below, select the specific files from a few example cases included in the `PMITD` unit testing suite. The compatibility of the files is as follows:

**Case 1**: Case5-Case3 Balanced - 1 Boundary, No Generators in Dist. System.
- _Transmission System_: "case5\_withload.m" or "case5\_withload.raw" (PSSE)
- _Distribution System_: "case3\_balanced\_withoutgen.dss"
- _Boundaries Linking File_: "case5\_case3\_bal\_nogen.json"

**Case 2**: Case5-Case3 Unbalanced - 1 Boundary, No Generators in Dist. System.
- _Transmission System_: "case5\_withload.m" or "case5\_withload.raw" (PSSE)
- _Distribution System_: "case3\_unbalanced\_withoutgen.dss"
- _Boundaries Linking File_: "case5\_case3\_unbal\_nogen.json"

**Case 3**: Case5-Case3 Balanced - 1 Boundary, 1 Generator in Dist. System.
- _Transmission System_: "case5\_withload.m" or "case5\_withload.raw" (PSSE)
- _Distribution System_: "case3\_balanced.dss"
- _Boundaries Linking File_: "case5\_case3\_bal.json"


**Case 4**: Case5-Case3 Unbalanced - 1 Boundary, 1 Generator in Dist. System.
- _Transmission System_: "case5\_withload.m" or "case5\_withload.raw" (PSSE)
- _Distribution System_: "case3\_unbalanced.dss"
- _Boundaries Linking File_: "case5\_case3\_unbal.json"

**Case 5**: Case5-CaseIEEE13 Balanced - 1 Boundary, No Generators in Dist. System.
- _Transmission System_: "case5\_withload.m" or "case5\_withload.raw" (PSSE)
- _Distribution System_: "caseIEEE13\_balanced\_withoutgen.dss"
- _Boundaries Linking File_: "case5\_case13\_bal\_nogen.json"

**Case 6**: Case5-CaseIEEE13 Unbalanced - 1 Boundary, No Generators in Dist. System.
- _Transmission System_: "case5\_withload.m" or "case5\_withload.raw" (PSSE)
- _Distribution System_: "caseIEEE13\_unbalanced\_withoutgen.dss"
- _Boundaries Linking File_: "case5\_case13\_unbal\_nogen.json"
"""

# ╔═╡ e2200c7f-e434-4e38-a990-19761a2c236c
md"""

#### Transmission System File:

"""

# ╔═╡ 564ffa56-50ab-4ed9-ac37-341f633793fb
begin
	pmitd_path = joinpath(dirname(pathof(PowerModelsITD)), "..")
	@bind pm_file Select([
			joinpath(pmitd_path, "test/data/transmission/case5_withload.m") => "case5_withload.m",
			joinpath(pmitd_path, "test/data/transmission/case5_withload.raw") => "case5_withload.raw",
		])
end

# ╔═╡ a8a21183-1dce-4503-bce2-6ce7788ef9ee
md"""

#### Distribution System File:

"""

# ╔═╡ b2f5fd5e-2d7f-4cd4-b64f-82fc3bd6ee97
begin
	@bind pmd_file Select([
			joinpath(pmitd_path, "test/data/distribution/case3_balanced_withoutgen.dss") => "case3_balanced_withoutgen.dss",
			joinpath(pmitd_path, "test/data/distribution/case3_unbalanced_withoutgen.dss") => "case3_unbalanced_withoutgen.dss",
			joinpath(pmitd_path, "test/data/distribution/case3_balanced.dss") => "case3_balanced.dss",
			joinpath(pmitd_path, "test/data/distribution/case3_unbalanced.dss") => "case3_unbalanced.dss",
			joinpath(pmitd_path, "test/data/distribution/caseIEEE13_balanced_withoutgen.dss") => "caseIEEE13_balanced_withoutgen.dss",
			joinpath(pmitd_path, "test/data/distribution/caseIEEE13_unbalanced_withoutgen.dss") => "caseIEEE13_unbalanced_withoutgen.dss",
		])
end

# ╔═╡ f9bc611f-a8fb-4906-80e0-8cd05f692bd1
md"""

#### Boundary(ies) Linking File:

"""

# ╔═╡ 99a2b324-2caa-42d4-b0e7-eee9c1942bf9
begin
	@bind pmitd_file Select([
			joinpath(pmitd_path, "test/data/json/case5_case3_bal_nogen.json") => "case5_case3_bal_nogen.json",
			joinpath(pmitd_path, "test/data/json/case5_case3_unbal_nogen.json") => "case5_case3_unbal_nogen.json",
			joinpath(pmitd_path, "test/data/json/case5_case3_bal.json") => "case5_case3_bal.json",
			joinpath(pmitd_path, "test/data/json/case5_case3_unbal.json") => "case5_case3_unbal.json",
			joinpath(pmitd_path, "test/data/json/case5_case13_bal_nogen.json") => "case5_case13_bal_nogen.json",
			joinpath(pmitd_path, "test/data/json/case5_case13_unbal_nogen.json") => "case5_case13_unbal_nogen.json",
		])
end

# ╔═╡ 1f7e6050-801b-49f6-94bc-87fc93651211
md"""

### Select Type of `PMITD` Formulation

"""

# ╔═╡ a4823ff4-cd74-4a7a-b358-228db2ca834e
begin
	@bind pmitd_type_selected Select([
			"ACR-ACRU"=> "ACR-ACRU Formulation",
			"ACP-ACPU"=> "ACP-ACPU Formulation",
			"IVR-IVRU"=> "IVR-IVRU Formulation",
			"NFA-NFAU"=> "NFA-NFAU Formulation",
			"ACR-FOTRU"=> "ACR-FOTRU Formulation",
			"ACP-FOTPU"=> "ACP-FOTPU Formulation",
			"ACR-FBSU"=> "ACP-FBSU Formulation",
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
 result = solve_opfitd(pm_file, pmd_file, pmitd_file, pmitd_type, Ipopt.Optimizer)

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
 result_pfitd = solve_pfitd(pm_file, pmd_file, pmitd_file, pmitd_type, Ipopt.Optimizer)

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

- `SOCBF-SOCUBF`:  Second-Order Cone Branch Flow (Transmission) - Second-Order Cone Unbalanced Branch Flow (Distribution)

"""

# ╔═╡ 123fec4f-46f0-40dc-a6d4-39c7c8d7b0b4
md"""

##### Transmission System File:

"""

# ╔═╡ 40f099f0-c647-4d49-bf45-7bd1357de36e
begin
	@bind pm_file_other Select([
			joinpath(pmitd_path, "test/data/transmission/case5_withload.m") => "case5_withload.m",
			joinpath(pmitd_path, "test/data/transmission/case5_withload.raw") => "case5_withload.raw",
		])
end

# ╔═╡ 44856d76-38db-43c4-9572-2982bf6228ee
md"""

##### Boundary(ies) Linking File:

"""

# ╔═╡ af46ddfb-762b-461d-8d45-68eb35e136e7
begin
	@bind pmitd_file_soc Select([
			joinpath(pmitd_path, "test/data/json/case5_case3_bal_notrans_nogen.json") => "case5_case3_bal_notrans_nogen.json",
			joinpath(pmitd_path, "test/data/json/case5_case3_bal_notrans.json") => "case5_case3_bal_notrans.json",
			joinpath(pmitd_path, "test/data/json/case5_case3_unbal_notrans_nogen.json") => "case5_case3_unbal_notrans_nogen.json",
			joinpath(pmitd_path, "test/data/json/case5_case3_unbal_notrans.json") => "case5_case3_unbal_notrans.json",
		])
end

# ╔═╡ ef4e1b2d-37ca-49d1-a3df-7bc8e2cdb506
md"""

##### Distribution System File:

"""

# ╔═╡ 7d84f34e-0ea5-4c67-9f09-918ecacf5aff
begin
	@bind pmd_file_soc Select([
			joinpath(pmitd_path, "test/data/distribution/case3_balanced_notransformer_withoutgen.dss") => "case3_balanced_notransformer_withoutgen.dss",
			joinpath(pmitd_path, "test/data/distribution/case3_balanced_notransformer.dss") => "case3_balanced_notransformer.dss",
			joinpath(pmitd_path, "test/data/distribution/case3_unbalanced_notransformer_withoutgen.dss") => "case3_unbalanced_notransformer_withoutgen.dss",
			joinpath(pmitd_path, "test/data/distribution/case3_unbalanced_notransformer.dss") => "case3_unbalanced_notransformer.dss",
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
result_soc = solve_opfitd(pm_file_other,
							pmd_file_soc,
							pmitd_file_soc,
							pmitd_type_soc,
							Ipopt.Optimizer)

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
pmd_file1 = joinpath(pmitd_path,
						"test/data/distribution/case3_unbalanced_withoutgen.dss")

# ╔═╡ 34b0b912-255c-4275-9e95-d18e67c91991
pmd_file2 = joinpath(pmitd_path,
						"test/data/distribution/case3_balanced_withoutgen.dss")

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
##### (c) Load boundary links system (`pmitd`) file

**IMPORTANT**: This file must contain all the boundary links for the PMITD system.
"""

# ╔═╡ 45e850da-e8b8-4b4b-983e-1ae95a381ee7
pmitd_file_multcase = joinpath(pmitd_path,
								"test/data/json/case5_case3x2_unbal_bal_nogen.json")

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
pmitd_data_multcase = parse_files(pm_file_multcase,
									pmd_files_multcase,
									pmitd_file_multcase)

# ╔═╡ 6039d564-1d21-4a04-9a81-69aec6eb0313
md"""
##### (f) Run the model (OPFITD Model).

**Note**: `build_opfitd`

"""

# ╔═╡ 5793e46b-c702-4f38-b1a8-c3fcb7778ec0
result_multcase = solve_model(pmitd_data_multcase,
								pmitd_type_multcase,
								Ipopt.Optimizer,
								build_opfitd)

# ╔═╡ 8a3156df-f4a8-4872-9eae-8453f128b642
result_multcase["solution"]["it"]["pmitd"]

# ╔═╡ 84bc2e2b-6dec-462d-ba9a-fe22e1076da9
md"""

------------------------------------------------------------------------------
------------------------------------------------------------------------------

"""

# ╔═╡ 8b0dd87c-623b-4a2c-9c91-5736cd9ca993
md"""
# Running Multinetwork (Time-series) Multisystem (Multiple Distribution Systems) OPFITD using `PowerModelsITD.jl`


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
	pm_file_mn = joinpath(pmitd_path,
						"test/data/transmission/case5_with2loads.m")

	pmd_file1_mn = joinpath(pmitd_path,
						"test/data/distribution/case3_unbalanced_withoutgen_mn.dss")

	pmitd_file_mn = joinpath(pmitd_path, "test/data/json/case5_case3x2.json")

	# create a vector of distribution system files
	pmd_files_mn = [pmd_file1_mn, pmd_file1_mn]

	# define the formulation type.
	pmitd_type_mn = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}


	# solve multinetwork opfitd.
	result_mn = solve_mn_opfitd(pm_file_mn, pmd_files_mn, pmitd_file_mn,
															pmitd_type_mn, Ipopt.Optimizer; 																auto_rename=true)

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
	pmitd_data_vbounds = parse_files(pm_file_multcase,
							   pmd_files_multcase,
							   pmitd_file_multcase)
	# apply transformations
	apply_voltage_bounds!(pmitd_data_vbounds; vm_lb=0.99, vm_ub=1.01)
	apply_voltage_angle_difference_bounds!(pmitd_data_vbounds, 1)

	# run opftid
	result_opfitd_b = solve_model(pmitd_data_vbounds,
								  pmitd_type_multcase,
								  Ipopt.Optimizer,
								  build_opfitd)
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
	pmitd_data_rab = parse_files(pm_file_multcase,
								 pmd_files_multcase, 																 pmitd_file_multcase)
	# apply transformations
    remove_all_bounds!(pmitd_data_rab)

	# run opftid
	result_rab = solve_model(pmitd_data_rab,
							 pmitd_type_multcase,
							 Ipopt.Optimizer,
							 build_opfitd)
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
	pmitd_data_kron = parse_files(pm_file_multcase,
								  pmd_files_multcase,
								  pmitd_file_multcase)
	# apply transformations
    apply_kron_reduction!(pmitd_data_kron)

	# run opftid
	result_kron = solve_model(pmitd_data_kron,
							  pmitd_type_multcase,
							  Ipopt.Optimizer,
							  build_opfitd)
end

# ╔═╡ 7d3604d9-cd58-4528-b013-f614808fee1b
md"""

------------------------------------------------------------------------------
------------------------------------------------------------------------------

"""

# ╔═╡ e7de0402-98fe-459c-aa23-79639f6e3f2c
md"""
# Apply Solution Processors
In this section, we will explore how to apply a `solution_processor` to the `result` obtained from `PowerModelsITD.jl`. Results in **rectangular** coordinates can be transformed to **polar** coordinates.
"""

# ╔═╡ b004d3f4-bb7b-4087-9983-af1783c2d31a
md"""
Let's us start with an ACR-ACRU problem, where we want to analyze the results in polar coordinates.
"""

# ╔═╡ a9ccc7db-26ad-445a-adce-6b3f138db387
begin
	pm_file_sol = joinpath(pmitd_path, "test/data/transmission/case5_withload.m")
	pmd_file_sol = joinpath(pmitd_path, "test/data/distribution/case3_unbalanced.dss")
	boundary_file_sol = joinpath(pmitd_path, "test/data/json/case5_case3_unbal.json")

	# ACR-ACRU (rectangular coordinates)
	pmitd_type_sol = NLPowerModelITD{ACRPowerModel, ACRUPowerModel}

	result_polar = solve_opfitd(pm_file_sol,
								pmd_file_sol,
								boundary_file_sol,
								pmitd_type_sol,
								Ipopt.Optimizer;
								make_si=false,
								solution_processors=[sol_data_model!])

end

# ╔═╡ f81b870e-eec7-4342-99c0-197946e3cd34
md"""
Now, we can check the voltage magnitudes and angles for each bus in the distribution system (_in polar coordinates instead of the default rectangular coordinates_):
"""

# ╔═╡ e3a6b84d-0170-45fd-9b9c-1e5e9ff93dfe
result_polar["solution"]["it"]["pmd"]["bus"]

# ╔═╡ f1553ee5-083f-4264-8e80-d31c475cc269
md"""

------------------------------------------------------------------------------
------------------------------------------------------------------------------

"""

# ╔═╡ 1c5afd45-1dc9-4a40-b4c4-8adc40eb5def
md"""
# Getting results in **MATH** model (instead of **ENG** default model)
In this section, we will explore how users can obtain results in MATH model instead of ENG model.

The main difference between the **MATH** and **ENG** models is the way the data is presented to the user. The **ENG** model is designed to present data in a 'human-friendly' format where components (e.g., buses, lines, etc.) can be identified by their names. On the other hand, in the **MATH** model, all components are assigned a numerical value that is needed for building and solving the optimization problem.

Please refer to [PoweModelsDistribution.jl ENG data model](https://lanl-ansi.github.io/PowerModelsDistribution.jl/stable/manual/eng-data-model.html) if you want more details about the differences between the **ENG** and **MATH** models.


**Important Note**: PowerModelsITD.jl presents parsed data using the **ENG** model. Internally, when the model is being instantiated, the data is transformed to the **MATH** model.

Below, we will present two examples where results are presented in the **MATH** and **ENG**. Users have the option to select whichever model they want the results to be presented. However, the **default** is the **ENG** model since it is the one we recommend.

"""

# ╔═╡ c7672b28-9504-4a2e-b307-ec9671b7c267
md"""
## **MATH** model
Let's start with the **MATH** model. To obtain the results using the **MATH** model, we just need to specify the optional parameter `solution_model="math"` when solving the problem. See an example below.

"""

# ╔═╡ afd40ab1-b079-4767-a964-78bfe6ec5241
begin
	pm_file_math = joinpath(pmitd_path,
							"test/data/transmission/case5_withload.m")
	pmd_file_math = joinpath(pmitd_path,
							"test/data/distribution/case3_balanced_withoutgen.dss")
	pmitd_file_math = joinpath(pmitd_path,
							"test/data/json/case5_case3_bal_nogen.json")

	pmitd_type_math = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}


	result_math = solve_opfitd(pm_file_math,
								pmd_file_math,
								pmitd_file_math,
								pmitd_type_math,
								Ipopt.Optimizer;
								make_si=false,
								solution_model="math")
end

# ╔═╡ 7954e685-7545-4a09-b54d-1d9907d0efb3
md"""
## **ENG** model
For comparison purposes, let's solve the same problem, with the difference that this time we will explicitly ask for the **ENG** model by adding `solution_model="eng"`. However, remember that adding the `solution_model="eng"` is **not required** since by **default**, PowerModelsITD.jl provides the result using the **ENG** model.

"""

# ╔═╡ 4e51edec-f81b-406c-8484-2bdeb5680522
begin
	pm_file_eng = joinpath(pmitd_path,
							"test/data/transmission/case5_withload.m")
	pmd_file_eng = joinpath(pmitd_path,
							"test/data/distribution/case3_balanced_withoutgen.dss")
	pmitd_file_eng = joinpath(pmitd_path,
							"test/data/json/case5_case3_bal_nogen.json")

	pmitd_type_eng = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}


	result_eng = solve_opfitd(pm_file_eng,
								pmd_file_eng,
								pmitd_file_eng,
								pmitd_type_eng,
								Ipopt.Optimizer;
								make_si=false,
								solution_model="eng")
end

# ╔═╡ 311147cd-dd09-44be-9b1b-cc860ecf1894
md"""

------------------------------------------------------------------------------
------------------------------------------------------------------------------

"""

# ╔═╡ 8bf07b81-107c-4b16-8d46-02bfff44e42b
md"""
# Development
**PowerModelsITD.jl** is currently subject to active, ongoing development, and is used internally by various high-profile projects, making its improvement and maintenance a high priority.
"""

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Ipopt = "b6b21f68-93f8-5de0-b562-5493be1d77c9"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
PowerModelsITD = "615c3f80-b0cb-4ecd-88fe-27bee056c380"

[compat]
Ipopt = "~1.0.2"
PlutoUI = "~0.7.39"
PowerModelsITD = "~0.7.1"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.9.1"
manifest_format = "2.0"
project_hash = "01fded79dcdc95cb80b44cd3c643000d0454af75"

[[deps.ASL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "6252039f98492252f9e47c312c8ffda0e3b9e78d"
uuid = "ae81ac8f-d209-56e5-92de-9978fef736f9"
version = "0.1.3+0"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "91bd53c39b9cbfb5ef4b015e8b582d344532bd0a"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.2.0"

[[deps.Adapt]]
deps = ["LinearAlgebra", "Requires"]
git-tree-sha1 = "02f731463748db57cc2ebfbd9fbc9ce8280d3433"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "3.7.1"

    [deps.Adapt.extensions]
    AdaptStaticArraysExt = "StaticArrays"

    [deps.Adapt.weakdeps]
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[deps.ArrayInterface]]
deps = ["Adapt", "LinearAlgebra", "Requires", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "16267cf279190ca7c1b30d020758ced95db89cd0"
uuid = "4fba245c-0d91-5ea0-9b3e-6abc04ee57a9"
version = "7.5.1"

    [deps.ArrayInterface.extensions]
    ArrayInterfaceBandedMatricesExt = "BandedMatrices"
    ArrayInterfaceBlockBandedMatricesExt = "BlockBandedMatrices"
    ArrayInterfaceCUDAExt = "CUDA"
    ArrayInterfaceGPUArraysCoreExt = "GPUArraysCore"
    ArrayInterfaceStaticArraysCoreExt = "StaticArraysCore"
    ArrayInterfaceTrackerExt = "Tracker"

    [deps.ArrayInterface.weakdeps]
    BandedMatrices = "aae01518-5342-5314-be14-df237901396f"
    BlockBandedMatrices = "ffab5731-97b5-5995-9138-79e8c1846df0"
    CUDA = "052768ef-5323-5732-b1bb-66c8b64840ba"
    GPUArraysCore = "46192b85-c4d5-4398-a991-12ede77f4527"
    StaticArraysCore = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
    Tracker = "9f7883ad-71c0-57eb-9f7f-b5c9e6d3789c"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.BenchmarkTools]]
deps = ["JSON", "Logging", "Printf", "Profile", "Statistics", "UUIDs"]
git-tree-sha1 = "d9a9701b899b30332bbcb3e1679c41cce81fb0e8"
uuid = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
version = "1.3.2"

[[deps.Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "19a35467a82e236ff51bc17a3a44b69ef35185a2"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.8+0"

[[deps.CSV]]
deps = ["CodecZlib", "Dates", "FilePathsBase", "InlineStrings", "Mmap", "Parsers", "PooledArrays", "PrecompileTools", "SentinelArrays", "Tables", "Unicode", "WeakRefStrings", "WorkerUtilities"]
git-tree-sha1 = "44dbf560808d49041989b8a96cae4cffbeb7966a"
uuid = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
version = "0.10.11"

[[deps.Calculus]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "f641eb0a4f00c343bbc32346e1217b86f3ce9dad"
uuid = "49dc2e85-a5d0-5ad3-a950-438e2897f1b9"
version = "0.5.1"

[[deps.CodecBzip2]]
deps = ["Bzip2_jll", "Libdl", "TranscodingStreams"]
git-tree-sha1 = "c0ae2a86b162fb5d7acc65269b469ff5b8a73594"
uuid = "523fee87-0ab8-5b00-afb7-3ecf72e48cfd"
version = "0.8.1"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "cd67fc487743b2f0fd4380d4cbd3a24660d0eec8"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.3"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "eb7f0f8307f71fac7c606984ea5fb2817275d6e4"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.4"

[[deps.CommonSubexpressions]]
deps = ["MacroTools", "Test"]
git-tree-sha1 = "7b8a93dba8af7e3b42fecabf646260105ac373f7"
uuid = "bbf7d656-a473-5ed7-a52c-81e309532950"
version = "0.3.0"

[[deps.Compat]]
deps = ["UUIDs"]
git-tree-sha1 = "8a62af3e248a8c4bad6b32cbbe663ae02275e32c"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.10.0"
weakdeps = ["Dates", "LinearAlgebra"]

    [deps.Compat.extensions]
    CompatLinearAlgebraExt = "LinearAlgebra"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.0.2+0"

[[deps.ConstructionBase]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "c53fc348ca4d40d7b371e71fd52251839080cbc9"
uuid = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
version = "1.5.4"

    [deps.ConstructionBase.extensions]
    ConstructionBaseIntervalSetsExt = "IntervalSets"
    ConstructionBaseStaticArraysExt = "StaticArrays"

    [deps.ConstructionBase.weakdeps]
    IntervalSets = "8197267c-284f-5f27-9208-e0e47529a953"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"

[[deps.DataAPI]]
git-tree-sha1 = "8da84edb865b0b5b0100c0666a9bc9a0b71c553c"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.15.0"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "3dbd312d370723b6bb43ba9d02fc36abade4518d"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.15"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.DiffResults]]
deps = ["StaticArraysCore"]
git-tree-sha1 = "782dd5f4561f5d267313f23853baaaa4c52ea621"
uuid = "163ba53b-c6d8-5494-b064-1a9d43ac40c5"
version = "1.1.0"

[[deps.DiffRules]]
deps = ["IrrationalConstants", "LogExpFunctions", "NaNMath", "Random", "SpecialFunctions"]
git-tree-sha1 = "23163d55f885173722d1e4cf0f6110cdbaf7e272"
uuid = "b552c78f-8df3-52c6-915a-8e097449b14b"
version = "1.15.1"

[[deps.Distances]]
deps = ["LinearAlgebra", "Statistics", "StatsAPI"]
git-tree-sha1 = "5225c965635d8c21168e32a12954675e7bea1151"
uuid = "b4f34e82-e78d-54a5-968a-f98e89d6e8f7"
version = "0.10.10"

    [deps.Distances.extensions]
    DistancesChainRulesCoreExt = "ChainRulesCore"
    DistancesSparseArraysExt = "SparseArrays"

    [deps.Distances.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "2fb1e02f2b635d0845df5d7c167fec4dd739b00d"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.3"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.FilePaths]]
deps = ["FilePathsBase", "MacroTools", "Reexport", "Requires"]
git-tree-sha1 = "919d9412dbf53a2e6fe74af62a73ceed0bce0629"
uuid = "8fc22ac5-c921-52a6-82fd-178b2807b824"
version = "0.8.3"

[[deps.FilePathsBase]]
deps = ["Compat", "Dates", "Mmap", "Printf", "Test", "UUIDs"]
git-tree-sha1 = "9f00e42f8d99fdde64d40c8ea5d14269a2e2c1aa"
uuid = "48062228-2e41-5def-b9a4-89aafe57970f"
version = "0.9.21"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.FiniteDiff]]
deps = ["ArrayInterface", "LinearAlgebra", "Requires", "Setfield", "SparseArrays"]
git-tree-sha1 = "c6e4a1fbe73b31a3dea94b1da449503b8830c306"
uuid = "6a86dc24-6348-571c-b903-95158fe2bd41"
version = "2.21.1"

    [deps.FiniteDiff.extensions]
    FiniteDiffBandedMatricesExt = "BandedMatrices"
    FiniteDiffBlockBandedMatricesExt = "BlockBandedMatrices"
    FiniteDiffStaticArraysExt = "StaticArrays"

    [deps.FiniteDiff.weakdeps]
    BandedMatrices = "aae01518-5342-5314-be14-df237901396f"
    BlockBandedMatrices = "ffab5731-97b5-5995-9138-79e8c1846df0"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[deps.ForwardDiff]]
deps = ["CommonSubexpressions", "DiffResults", "DiffRules", "LinearAlgebra", "LogExpFunctions", "NaNMath", "Preferences", "Printf", "Random", "SpecialFunctions"]
git-tree-sha1 = "cf0fe81336da9fb90944683b8c41984b08793dad"
uuid = "f6369f11-7733-5829-9624-2563aa707210"
version = "0.10.36"

    [deps.ForwardDiff.extensions]
    ForwardDiffStaticArraysExt = "StaticArrays"

    [deps.ForwardDiff.weakdeps]
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[deps.Glob]]
git-tree-sha1 = "97285bbd5230dd766e9ef6749b80fc617126d496"
uuid = "c27321d9-0574-5035-807b-f59d2c89b15c"
version = "1.3.1"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "8d511d5b81240fc8e6802386302675bdf47737b9"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.4"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "7134810b1afce04bbc1045ca1985fbe81ce17653"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.5"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "d75853a0bdbfb1ac815478bacd89cd27b550ace6"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.3"

[[deps.InfrastructureModels]]
deps = ["JuMP", "Memento"]
git-tree-sha1 = "f9c1f6bdac8ad3fca6fc24fcf68256958ad84c28"
uuid = "2030c09a-7f63-5d83-885d-db604e0e9cc0"
version = "0.7.8"

[[deps.InlineStrings]]
deps = ["Parsers"]
git-tree-sha1 = "9cc2baf75c6d09f9da536ddf58eb2f29dedaf461"
uuid = "842dd82b-1e85-43dc-bf29-5d0ee9dffc48"
version = "1.4.0"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.Ipopt]]
deps = ["Ipopt_jll", "MathOptInterface"]
git-tree-sha1 = "6d4c0cec91619b7c44ed9d4f9d021ce053019e15"
uuid = "b6b21f68-93f8-5de0-b562-5493be1d77c9"
version = "1.0.4"

[[deps.Ipopt_jll]]
deps = ["ASL_jll", "Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "MUMPS_seq_jll", "OpenBLAS32_jll", "Pkg"]
git-tree-sha1 = "e3e202237d93f18856b6ff1016166b0f172a49a8"
uuid = "9cc047cb-c261-5740-88fc-0cf96f7bdcc7"
version = "300.1400.400+0"

[[deps.IrrationalConstants]]
git-tree-sha1 = "630b497eafcc20001bba38a4651b327dcfc491d2"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.2.2"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLLWrappers]]
deps = ["Artifacts", "Preferences"]
git-tree-sha1 = "7e5d6779a1e09a36db2a7b6cff50942a0a7d0fca"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.5.0"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "31e996f0a15c7b280ba9f76636b3ff9e2ae58c9a"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.4"

[[deps.JuMP]]
deps = ["Calculus", "DataStructures", "ForwardDiff", "LinearAlgebra", "MathOptInterface", "MutableArithmetics", "NaNMath", "OrderedCollections", "Printf", "SparseArrays", "SpecialFunctions"]
git-tree-sha1 = "936e7ebf6c84f0c0202b83bb22461f4ebc5c9969"
uuid = "4076af6c-e467-56ae-b986-b466b2749572"
version = "1.0.0"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.3"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "7.84.0+0"

[[deps.LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.10.2+0"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.LineSearches]]
deps = ["LinearAlgebra", "NLSolversBase", "NaNMath", "Parameters", "Printf"]
git-tree-sha1 = "7bbea35cec17305fc70a0e5b4641477dc0789d9d"
uuid = "d3d80556-e9d4-5f37-9878-2ab0fcc64255"
version = "7.2.0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.LogExpFunctions]]
deps = ["DocStringExtensions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "7d6dd4e9212aebaeed356de34ccf262a3cd415aa"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.26"

    [deps.LogExpFunctions.extensions]
    LogExpFunctionsChainRulesCoreExt = "ChainRulesCore"
    LogExpFunctionsChangesOfVariablesExt = "ChangesOfVariables"
    LogExpFunctionsInverseFunctionsExt = "InverseFunctions"

    [deps.LogExpFunctions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    ChangesOfVariables = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.LoggingExtras]]
deps = ["Dates", "Logging"]
git-tree-sha1 = "5d4d2d9904227b8bd66386c1138cf4d5ffa826bf"
uuid = "e6f89c97-d47a-5376-807f-9c37f3926c36"
version = "0.4.9"

[[deps.METIS_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "1fd0a97409e418b78c53fac671cf4622efdf0f21"
uuid = "d00139f3-1899-568f-a2f0-47f597d42d70"
version = "5.1.2+0"

[[deps.MIMEs]]
git-tree-sha1 = "65f28ad4b594aebe22157d6fac869786a255b7eb"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "0.1.4"

[[deps.MUMPS_seq_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "METIS_jll", "OpenBLAS32_jll", "Pkg"]
git-tree-sha1 = "29de2841fa5aefe615dea179fcde48bb87b58f57"
uuid = "d7ed1dd3-d0ae-5e8e-bfb4-87a502085b8d"
version = "5.4.1+0"

[[deps.MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "9ee1618cbf5240e6d4e0371d6f24065083f60c48"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.11"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MathOptInterface]]
deps = ["BenchmarkTools", "CodecBzip2", "CodecZlib", "DataStructures", "ForwardDiff", "JSON", "LinearAlgebra", "MutableArithmetics", "NaNMath", "OrderedCollections", "PrecompileTools", "Printf", "SparseArrays", "SpecialFunctions", "Test", "Unicode"]
git-tree-sha1 = "70ea2892b8bfffecc0387ba1a6a21192814f120c"
uuid = "b8f27783-ece8-5eb3-8dc8-9495eed66fee"
version = "1.22.0"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.2+0"

[[deps.Memento]]
deps = ["Dates", "Distributed", "Requires", "Serialization", "Sockets", "Test", "UUIDs"]
git-tree-sha1 = "bb2e8f4d9f400f6e90d57b34860f6abdc51398e5"
uuid = "f28f55f0-a522-5efc-85c2-fe41dfb9b2d9"
version = "1.4.1"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2022.10.11"

[[deps.MutableArithmetics]]
deps = ["LinearAlgebra", "SparseArrays", "Test"]
git-tree-sha1 = "6985021d02ab8c509c841bb8b2becd3145a7b490"
uuid = "d8a4904e-b15c-11e9-3269-09a3773c0cb0"
version = "1.3.3"

[[deps.NLSolversBase]]
deps = ["DiffResults", "Distributed", "FiniteDiff", "ForwardDiff"]
git-tree-sha1 = "a0b464d183da839699f4c79e7606d9d186ec172c"
uuid = "d41bc354-129a-5804-8e4c-c37616107c6c"
version = "7.8.3"

[[deps.NLsolve]]
deps = ["Distances", "LineSearches", "LinearAlgebra", "NLSolversBase", "Printf", "Reexport"]
git-tree-sha1 = "019f12e9a1a7880459d0173c182e6a99365d7ac1"
uuid = "2774e3e8-f4cf-5e23-947b-6d7e65073b56"
version = "4.5.1"

[[deps.NaNMath]]
deps = ["OpenLibm_jll"]
git-tree-sha1 = "0877504529a3e5c3343c6f8b4c0381e57e4387e4"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "1.0.2"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.OpenBLAS32_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "2fb9ee2dc14d555a6df2a714b86b7125178344c2"
uuid = "656ef2d0-ae68-5445-9ca0-591084a874a2"
version = "0.3.21+0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.21+4"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"
version = "0.8.1+0"

[[deps.OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "13652491f6856acfd2db29360e1bbcd4565d04f1"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.5+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "2e73fe17cac3c62ad1aebe70d44c963c3cfdc3e3"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.6.2"

[[deps.Parameters]]
deps = ["OrderedCollections", "UnPack"]
git-tree-sha1 = "34c0e9ad262e5f7fc75b10a9952ca7692cfc5fbe"
uuid = "d96e819e-fc66-5662-9728-84c9c7592b0a"
version = "0.12.3"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "a935806434c9d4c506ba941871b327b96d41f2bf"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.8.0"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.9.0"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "db8ec28846dbf846228a32de5a6912c63e2052e3"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.53"

[[deps.PolyhedralRelaxations]]
deps = ["DataStructures", "ForwardDiff", "JuMP", "Logging", "LoggingExtras"]
git-tree-sha1 = "05f2adc696ae9a99be3de99dd8970d00a4dccefe"
uuid = "2e741578-48fa-11ea-2d62-b52c946f73a0"
version = "0.3.5"

[[deps.PooledArrays]]
deps = ["DataAPI", "Future"]
git-tree-sha1 = "36d8b4b899628fb92c2749eb488d884a926614d3"
uuid = "2dfb63ee-cc39-5dd5-95bd-886bf059d720"
version = "1.4.3"

[[deps.PowerModels]]
deps = ["InfrastructureModels", "JSON", "JuMP", "LinearAlgebra", "Memento", "NLsolve", "SparseArrays"]
git-tree-sha1 = "1e4bd5e4dfe3d9677ff17c42dd77bf17da269cc0"
uuid = "c36e90e8-916a-50a6-bd94-075b64ef4655"
version = "0.19.9"

[[deps.PowerModelsDistribution]]
deps = ["CSV", "Dates", "FilePaths", "Glob", "InfrastructureModels", "JSON", "JuMP", "LinearAlgebra", "Logging", "LoggingExtras", "PolyhedralRelaxations", "SparseArrays", "SpecialFunctions", "Statistics"]
git-tree-sha1 = "c474857308af49d155d67352a42b523203ee7d9c"
uuid = "d7431456-977f-11e9-2de3-97ff7677985e"
version = "0.15.1"

[[deps.PowerModelsITD]]
deps = ["InfrastructureModels", "JSON", "JuMP", "LinearAlgebra", "PowerModels", "PowerModelsDistribution"]
git-tree-sha1 = "2119baa316e80d23c87413c30e1e6ce745985da2"
uuid = "615c3f80-b0cb-4ecd-88fe-27bee056c380"
version = "0.7.9"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "03b4c25b43cb84cee5c90aa9b5ea0a78fd848d2f"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.2.0"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "00805cd429dcb4870060ff49ef443486c262e38e"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.4.1"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.Profile]]
deps = ["Printf"]
uuid = "9abbd945-dff8-562f-b5e8-e1ebf5ef1b79"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "838a3a4188e2ded87a4f9f184b4b0d78a1e91cb7"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.SentinelArrays]]
deps = ["Dates", "Random"]
git-tree-sha1 = "0e7508ff27ba32f26cd459474ca2ede1bc10991f"
uuid = "91c51154-3ec4-41a3-a24f-3f23e20d615c"
version = "1.4.1"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.Setfield]]
deps = ["ConstructionBase", "Future", "MacroTools", "StaticArraysCore"]
git-tree-sha1 = "e2cc6d8c88613c05e1defb55170bf5ff211fbeac"
uuid = "efcf1570-3423-57d1-acb7-fd33fddbac46"
version = "1.1.1"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.SpecialFunctions]]
deps = ["IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "e2cfc4012a19088254b3950b85c3c1d8882d864d"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.3.1"

    [deps.SpecialFunctions.extensions]
    SpecialFunctionsChainRulesCoreExt = "ChainRulesCore"

    [deps.SpecialFunctions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"

[[deps.StaticArraysCore]]
git-tree-sha1 = "36b3d696ce6366023a0ea192b4cd442268995a0d"
uuid = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
version = "1.4.2"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.9.0"

[[deps.StatsAPI]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1ff449ad350c9c4cbc756624d6f8a8c3ef56d3ed"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.7.0"

[[deps.SuiteSparse]]
deps = ["Libdl", "LinearAlgebra", "Serialization", "SparseArrays"]
uuid = "4607b0f0-06f3-5cda-b6b1-a6196a1729e9"

[[deps.SuiteSparse_jll]]
deps = ["Artifacts", "Libdl", "Pkg", "libblastrampoline_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"
version = "5.10.1+6"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "OrderedCollections", "TableTraits"]
git-tree-sha1 = "cb76cf677714c095e535e3501ac7954732aeea2d"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.11.1"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.TranscodingStreams]]
git-tree-sha1 = "1fbeaaca45801b4ba17c251dd8603ef24801dd84"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.10.2"
weakdeps = ["Random", "Test"]

    [deps.TranscodingStreams.extensions]
    TestExt = ["Test", "Random"]

[[deps.Tricks]]
git-tree-sha1 = "eae1bb484cd63b36999ee58be2de6c178105112f"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.8"

[[deps.URIs]]
git-tree-sha1 = "67db6cc7b3821e19ebe75791a9dd19c9b1188f2b"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.5.1"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.UnPack]]
git-tree-sha1 = "387c1f73762231e86e0c9c5443ce3b4a0a9a0c2b"
uuid = "3a884ed6-31ef-47d7-9d2a-63182c4928ed"
version = "1.0.2"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.WeakRefStrings]]
deps = ["DataAPI", "InlineStrings", "Parsers"]
git-tree-sha1 = "b1be2855ed9ed8eac54e5caff2afcdb442d52c23"
uuid = "ea10d353-3f73-51f8-a26c-33c1cb351aa5"
version = "1.4.2"

[[deps.WorkerUtilities]]
git-tree-sha1 = "cd1659ba0d57b71a464a29e64dbc67cfe83d54e7"
uuid = "76eceee3-57b5-4d4a-8e66-0e911cebbf60"
version = "1.6.1"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.13+0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.8.0+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.48.0+0"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+0"
"""

# ╔═╡ Cell order:
# ╟─ea6bd476-ba83-4b1b-ad70-825b25d15135
# ╟─36d78d29-1417-4c05-adf3-4560fbc0304e
# ╠═4b293648-92aa-4ebb-9d33-a6707773f0b1
# ╟─6eec60ab-d093-4230-8374-01f6d5799e8d
# ╟─7592c3de-481f-4877-a362-56e0eaaf56b0
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
# ╟─7d3604d9-cd58-4528-b013-f614808fee1b
# ╟─e7de0402-98fe-459c-aa23-79639f6e3f2c
# ╟─b004d3f4-bb7b-4087-9983-af1783c2d31a
# ╠═a9ccc7db-26ad-445a-adce-6b3f138db387
# ╟─f81b870e-eec7-4342-99c0-197946e3cd34
# ╠═e3a6b84d-0170-45fd-9b9c-1e5e9ff93dfe
# ╟─f1553ee5-083f-4264-8e80-d31c475cc269
# ╟─1c5afd45-1dc9-4a40-b4c4-8adc40eb5def
# ╟─c7672b28-9504-4a2e-b307-ec9671b7c267
# ╠═afd40ab1-b079-4767-a964-78bfe6ec5241
# ╟─7954e685-7545-4a09-b54d-1d9907d0efb3
# ╠═4e51edec-f81b-406c-8484-2bdeb5680522
# ╟─311147cd-dd09-44be-9b1b-cc860ecf1894
# ╟─8bf07b81-107c-4b16-8d46-02bfff44e42b
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
