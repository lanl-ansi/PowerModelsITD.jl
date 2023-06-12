# PowerModelsITD.jl Change Log

## staged

- Fixed implementation of polynomial nl costs above quadratic in `objective.jl`.
- Bumped PMITD compatibility of `IM`, `PMD` and `PM` to the latest versions (i.e., V0.7.7, v0.14.9, and v0.19.9).

## v0.7.7

- Bumped PMITD compatibility of `PMD` to the latest versions (i.e., v0.14.7).
- Added journal citing information to `README.md`.
- Added journal citing information to `index` in docs.
- Added ITD boundary network mathematical formulations to `docs`.

## v0.7.6

- Bumped PMITD compatibility of `PMD` and `PM` to the latest versions (i.e., v0.14.5, and v0.19.8).
- Added new unit tests that test SOC-based formulations with transformers (SOC transformers constraints were added to `PMD`).
- Added new function `calc_transmission_branch_flow_ac!` to `data.jl` that computes the branch power flows for transmission system when solving PFITD.
- Refactored SOCBF-SOCNLUBF voltage and angle boundary constraints.
- Refactored SOCBFConic-SOCUBFConic voltage and angle boundary constraints.
- Refactored SOCWRConic-SOCConicUBF voltage and angle boundary constraints.
- Refactored SDPWRM-SOCConicUBF voltage and angle boundary constraints.

## v0.7.5

- Fixed issue that caused `crbound_fr`, `cibound_fr`, `cibound_to`, and `crbound_to` values to not be shown in the `results["solution"]["it"]["pmitd"]` dictionary.(Issue: #8)
- Updated `PowerModels` and `InfrastructureModels` dependencies versions.

## v0.7.4

- Fixed issue caused by JuMP+ v1.2.1 where non-linear (NL) objectives in `objective_dmld.jl` and `objective_dmld_simple.jl` were causing a major error. Changed to `@objective`.

## v0.7.3

- Added `PowerModelsITD` logo.
- Revised `README.md`.

## v0.7.2

- Fixed issue in function `_rename_network_components!(...)` that was not allowing problems where transformers have multiple windings connections to be solved. (Issue: #6)
- Updated `PowerModels`, `PowerModelsDistribution`, and `InfrastructureModels` dependencies versions.
- Disabled large scale unit test case due to the test failing in CI nightly windows-latest run (ipopt memory fail: Problem with integer stack size).
- Updated `PowerModelsITD.jl` version in `Beginners Guide.jl` Pluto notebook available in `/examples`

## v0.7.1

- Added `Issue` and `Feature` request templates to `.github`.
- Added `Pull` request template to  `.github`.
- Fixed major bug in `transform_pmitd_solution_to_eng!` function that was causing boundary power flow values to be the same for all nw in multinetwork problems.
- Added unit test to `opfitd_mn` (and new data files) that test that boundary power flow solution values differ when solving a multinetwork problem with different loading conditions.

## v0.7.0

- Refactored the renaming function `_rename_network_components!` to rename components of a distribution system based on the name of the circuit (ckt).
- Added new renaming structure `cktname.element`.
- Changed names of circuits in distribution system test cases (OpenDSS files) to avoid collisions and test new renaming function.
- Refactored function `_assign_boundary_buses` in `data.jl` such that boundary buses can be assigned using the new naming convention.
- Added error message alerting the user that distribution system names must be unique to avoid name collisions.
- Added option for user to allow the automatic renaming `auto_rename=true` of the circuits (for cases when the user wants PowerModelsITD.jl to handle the renaming sequentially).
- Added new function `_check_and_rename_circuits!` that checks that the names of distribution system circuits are unique when passing multiple distribution systems. If `auto_rename=true` is not specified, an `error` will be displayed.
- Added new function `_correct_boundary_names!` that corrects the boundary names passed in the JSON file based on the auto generated circuit names. A warning is displayed informing the user that the naming will be done sequentially (in case this may not be what the user wants).
- Added new function `_clean_pmd_base_data!` that removes/cleans components from `pmd` dictionary for its subsequent renaming.
- Added new function `_remove_network_components!` that performs the removal of dictionary keys needed by the `_clean_pmd_base_data!` function.
- Added descriptive docstrings to newly added functions.
- Refactored `parse_files` and `parse_power_distribution_file` to support new naming conventions for `pmd` data.
- Added `auto_rename` option to all `solve_X` functions that require the option.
- Added a new dictionary key `"belongs_to_ckt"` to every component renamed by the `_rename_network_components!` function. This will help knowing (and mapping back) to what circuit(network) each component in `pmd` belongs to.
- Added new function `_add_file_name!` that makes sure that the file path/name of the distribution system being parsed-in is added to the "files" dictionary of "pmd".
- Fixed issues identified by unit tests related to new naming format for JSON files.
- Added new JSON files with specific distribution system names to `test/json` folder.
- Added `autorename.jl` unit tests designed to test errors that must appear when the new naming convention is not followed and `auto_rename=false`.
- Added documentation to `/docs` that explains in detail the new 'ideal' format for the boundary linking JSON files.
- Updated documentation guides and README.
- Added a new transformation function to `solution.jl` called `transform_pmitd_solution_to_eng!` in charge of converting the `pmitd` solution from MATH to ENG model.
- Added option `solution_model="eng"` and `solution_model="math"` to all `solve_X` functions that allows the user to get the solution in either ENG or MATH models.
- Refactored `examples/Beginners Guide.jl` to be compatible with the new version of PowerModelsITD.jl.

## v0.6.1

- Added Pluto Notebook `Beginners Guide.jl` to Docs based on Pluto v0.15.1 (Note: Higher Pluto versions break the integration).
- Removed `@smart_constraint` from docs.
- Added support for JuMP v1.0

## v0.6.0

- First released version.

## v0.5.9

- Performed file formatting that trims trailing whitespaces and inserts a final newline to all files.
- Removed `@smart_constraint` and `_has_nl_expressions` functions. These are now being imported from PMD.
- Added `LinearAlgebra` package as dependency.
- Refactored import statements in `src/PowerModelsITD.jl`.
- Refactored `Float64` type in `_scale_loads` function to `Real` type.
- Refactored `Dict{String,Any} -> Dict{String,<:Any}`.
- Refactored `Vector{Function}([]) -> Function[]`.
- Fixed Doc problem in reference of the paper.
- Removed unnecessary `kwargs` from `variable.jl`
- Removed unnecessary `kwargs` from `objective_X.jl`
- Refactored `solve_model` and problem specification functions to receive explicit parameters instead of `kwargs`.
- Fixed bug related to `make_si` not being propagated through `solve_model` functions.

## v0.5.8

- Fixed problem related to private functions being displayed in the Documentation in `docs/`.
- Fixed problem related to `run_` functions not updated to `solve_` when being displayed in the Documentation in `docs/`.
- Added reference to `sol_data_model!` function to the Documentation.

## v0.5.7

- Updated `Project.toml` by replacing `>=` with `~`.
- Updated `Project.toml` by moving `Ipopt` and `SCS` from `deps` to `extras`.
- Moved `transformations.jl` to a new folder `src/data_model`.
- Replaced all references to `master` branch with `main` branch.
- Updated paper information and License in `index.md`.
- Updated `README.md` and `index.md` with License and Acknowledgments.
- Updated `Beginners_Guide.jl` with the release version of PMITD.
- Replaced all explicit paths in `/test`files with pre-defined paths in `runtests.jl`.
- Fixed issue with new path of `transformations.jl` (`src/data_model`) in `PowerModelsITD.jl` file.
- Removed unnecessary comments.
- Added function signatures to all public and private functions inside `src/core`.
- Added function signatures to all public and private functions inside `src/data_model`.
- Added function signatures to all public and private functions inside `src/io`.
- Added function signatures to all public and private functions inside `src/form`.
- Refactored `constraint_transmission_power_balance` and `constraint_distribution_power_balance` in `linear.jl` to receive `_PM.AbstractActivePowerModel` and `_PMD.AbstractUnbalancedActivePowerModel` respectively, instead of DCP and DCPU.
- Added function signatures to all public and private functions inside `src/prob`.
- Refactored `README.md` and added Github badges (Badges may not work in Gitlab).
- Added `ci.yml` and `documentation.yml` to `.github/workflows`. (Need to be checked when deployed to Github)

## v0.5.6

- Bumped PMITD compatibility of `IM`, `PMD`, and `PM` to the latest versions (i.e., v0.7.3, v0.14.2, and v0.19.4). (Issue: #60)
- Bumped PMITD compatibility of `JuMP` to version >= v0.23. (Issue: #60)
- Bumped PMITD compatibility of `Ipopt` to version >= v1.0.1. (Issue: #60)
- Bumped PMITD compatibility of `SCS` to version >= v1.1.0. (Issue: #60)
- Increased Julia lower bound to v1.6. (Issue: #60)
- Changed all instances of `Int64` to `Int` for better compatibility. (Issue: #60)
- Updated versions of Packages used in `Beginners_Guide.jl`.

## v0.5.5

- Refactored `run_model(...)` (new `solve_model(...)`) functions in `base.jl` to support `solution_processors`. (Issue: #58)
- Added function `sol_data_model!(...)` processor in `solution.jl` that converts both transmission and distribution system(s) solutions. (Issue: #58)
- Added new unit tests to `opfitd_solution.jl` that evaluate the new `sol_data_model!(...)` processor.
- Corrected `testset` names for `runtests.jl`.
- Renamed `run_*` methods to `solve_*`. (Issue: #59)

## v0.5.4

- Added support SCS solver (as dependency for conic formulations).
- Added support for `SOCBFConic-SOCConicUBFPowerModel` model.
- Added support for `SOCWRConic-SOCConicUBFPowerModel` model.
- Added support for `SDPWRM-SOCConicUBFPowerModel` model.
- Refactored models passed in as parameters in `wmodels.jl` to cover all W models.
- IMPORTANT: The voltage (`w`) boundary constraints of the three new formulations (on `wmodels.jl`) have not been thoroughly verified as correct. Future work will explore the correct voltage (`w`) boundary constraints.
- Added new unit tests (`opfitd.jl` and `opfitd_hybrids`) that evaluate the solution for the three new formulations.

## v0.5.3

- Add support for `BFA-LinDist3FlowPowerModel` model. (Issue: #57)
- Added new type to `BFPowerModels` Union in `types.jl`.
- Added new `w` voltage constraints to `lindist3flow.jl`.
- Added new unit tests (pfitd and opfitd) that evaluate the solution for the new `BFA-LinDist3FlowPowerModel` formulation.
- Fixed issue related to not needing `w` variables boundary voltage constraints for `SOCBF-LinDist3FlowPowerModel` formulation (see `lindist3flow.jl`). (Issue: #43)
- Added new formulation type to `README.md`.
- Fixed multinetwork unit tests related to `SOCBF-LinDist3FlowPowerModel` that changed objective cost value when the new `w` variables boundary voltage constraints were introduced.

## v0.5.2

- Remove `MathOptInterface` dependency.
- Bumped PMITD compatibility of `PMD`, and `IM` to the latest versions (i.e., v0.14.0 and v0.7.2).

## v0.5.1

- Added multinetwork multisystem opfitd example to `Beginners_Guide.jl`.
- Added CaseLV reduced version and 1kw loads version. The reduced version gives same results (x10e-4) with around 80 percent less computational time resources.
- Bumped PMITD compatibility of `PM` and `PMD` to the latest versions (i.e., v0.19.1 and v0.13.1+). Other dependencies such as `Ipopt` were also updated.
- Refactored `solution.jl` functions for compatibility with new PMD version.
- Fixed `isapprox(...)` solutions for many unit test cases. Some results slightly changed due to new PMD version.
- Added back the duals unit test (in `opfitd_duals.jl`) that was failing in previous versions. This was fixed in the PMD version.
- Removed ACR-ACR and ACP-ACP pfitd unit test cases for IEEE-13 bus, since they are not FEASIBLE (problem that comes from the new version of PMD).
- Added support for `opfitd_dmld` (optimal power flow at transmission and minimum load delta at distribution system(s)). (Issue: #54, #55)
- Added objectives for `OPF-dmld` and `OPF-dmld_simple` in `src/core/objective_dmld.jl` and `src/core/objective_dmld_simple.jl`
- The added objectives support pwl, linquad, and non-linear objectives in the transmission side.
- **Important Notice**: a version of the `constraint_mc_power_balance_shed(...)` as `constraint_distribution_power_balance_boundary_shed(...)` is not implemented because having sheddable loads at the boundary between T&Ds may not make much sense. Buses at the boundary are not allowed to shed specific loads.
- Current PMD formulations not supported by `dmld` (distribution-only): FOTP, FOTR, FBS, IVR, SOCBF.
- Added multinetwork support to `opfitd_dmld.jl` by adding the respective problem specifications. (Issue: #54)

## v0.5.0

- Added `multinetwork` (mn) support to `PMITD`. (Issue: #53)
- Refactored functions to support the `multinetwork` parameter in `base.jl`, `solution.jl`, `data.jl`, among others.
- Added `run_mn_opfitd()` function to run `PMITD` multinetwork problems.
- Added `build_mn_opfitd()` functions for the ACR-ACR, ACP-ACP, and NFA-NFA formulations.
- Added unit tests to `/test/opfitd_mn.jl` that validate running multinetwork problems.
- Fixed issue related to PMITD multinetwork problems not being feasible. Fixed by validating `_PM.parse_file(pm_file; validate = true)`.
- Fixed/Added support for multinetwork (mn) multisystem (ms) test cases. Function `_rename_components!()` in `helpers.jl` was modified to support multinetwork structures.
- Added a new helper function for renaming components called `_rename_network_components_network!()` in `helpers.jl`.
- Added unit tests to `/test/opfitd_mn.jl` that validate running multinetwork multisystem problems.
- Added `build_mn_opfitd()` function for the IVR-IVR formulation.
- Added unit tests that validate the solution of the IVR-IVR multinetwork formulation.
- Added `build_mn_opfitd()` function for the SOCBF-SOCUBF formulation (BF types).
- Added unit tests that validate the solution of the SOCBF-SOCUBF multinetwork formulation.
- Added unit tests that validate the solution of the ACR-FOTR, ACP-FOTP, and SOCBF-LinDist3Flow multinetwork formulations.
- Added `build_mn_opfitd()` function for the L/NL-BF type formulations.
- Added unit tests that validate the solution of the L/NL-BF type multinetwork formulations.
- Added `build_mn_opfitd_oltc()` functions for the ACR-ACR, ACP-ACP, NFA-NFA, ACR-FOTR, ACP-FOTP, ACR-FBS, and SOCBF-LinDist3Flow formulations.
- Added unit tests that validate the solution of all the supported multinetwork opfitd oltc formulations.
- Added new constraints from PMD (`constraint_mc_ampacity_from`, `constraint_mc_ampacity_to`, and `constraint_mc_switch_ampacity`) to respective build problem specifications.
- Modified some test cases to increase line capacities so they are feasible. The new `ampacity` constraints made some cases unfeasible.
- Added silence function description to docs.
- Updated `Beginners_Guide.jl` to the latest version.
- Updated `docs/manual/quickguide.md` to include example case that explains how to run multinetwork multisystem opfitd.

## v0.4.3

- Added `silence!()` function that suppresses information and warning messages output by `PowerModels` and `PowerModelsDistribution`. (Issue: #51)
- Removed the warning messages from test cases (i.e., `runtests.jl`) using the newly created `silence!()` function.
- Replaced docstrings of non-accessible functions (e.g., `_funcname`) with comments to avoid warnings when creating documentation with Documenter.jl.
- Bumped PMITD compatibility of IM, PM, and PMD to the latest versions (i.e., v0.6.1, v0.18.3, and v0.12.0).
- Fixed breaking problem related to the SOCBF-LinDist3FlowPowerModel, where 'KeyError: key :Wr not found'. Problem related to Lin3DistFlow and definitions of constraints. (Issue: #52)
- Refactor types used in `lindist3flow.jl` and `wmodels.jl` constraints to avoid confusion between different formulations. (Issue: #52)

## v0.4.2

- Added documentation for `PowerModelsITD` package generated by `Documenter.jl`. (Issue: #49)
- Modified/Added a few docstrings that were missing.
- Renamed many test cases data files to make them simpler. Mostly removed strings such as `_mod_`, `_modmw_`, `_balanced_`. Changes reflected in unit test cases.
- Removed redundant unit test cases that were not needed to test the operation of PMITD. These test cases were making the unit test case process to last too long.
- Commented out lines in `.dss` files that were generating unnecessary `warning` messages. (Issue: #50)
- Modified the initial voltage setpoints for all the `case5` test cases in order to avoid PowerModels warning related to setpoint mismatch in unit test cases. (Issue: #50)
- Refactored `io/common.jl` so that the `per_unit=false` field is added as default to data being updated by the function `_IM.update_data(...)` from `InfrastructureModels.jl`. This refactor removes unnecessary warning message from IM.

## v0.4.1

- Fixed breaking issue with IVR-IVR formulation. The IVR-IVR boundary current equality constraint is incorrect. (Issue: #46)
- Added support to make sure both `pm` and `pmd` are in the same per unit bases. function: `resolve_units!(...)`. (Issue: #1)
- Added support to make results in `PMITD` solution structure not to be presented in pu when nothing is specified (i.e., make_si=true). (Issue: #47)
- Added support for reporting `duals` in the results/solutions (`pm`, `pmd` and `pmitd` buses). (Issue: #23)

## v0.4.0

- Refactored/Removed not needed multi-network code (i.e., `n1` and `n2`) in boundary constraints functions. Only `n` is needed for the pmitd model.
- Refactored/Changed the names `pm_type` and `pmd_type` to `pm_model` and `pmd_model`. Code is clearer to read.
- Refactored/Change the names `pm_model` to `pm_cost_model` and `pmd_model` to `pmd_cost_model` in `objective.jl`. Code is clearer to read.
- Removed other unnecessary code.
- Removed need to define PowerModels and PowerModelsDistribution modeling types in `pmitd_type` as `NLPowerModelITD{_PM.ACRPowerModel, _PMD.ACRUPowerModel}`, by exporting the modeling types in `export.jl`. Now the type can be defined as `NLPowerModelITD{ACRPowerModel, ACRUPowerModel}` (i.e., without `_PM.` and `_PMD.`).
- Bump compatibility requirements for PowerModels (>=v0.18.2) and PowerModelsDistribution (>=v0.11.7).

## v0.3.8

- Added oltc test case and unit test cases for 500bus-caseLV in `src/core/opfitd_oltc.jl`.
- Added new types (i.e., `ACR-FBS`, `ACR-FOTR`, `ACP-FOTP`) to `Beginners_Guide.jl`.
- Minor fixes in functions docstrings (left aligned).

## v0.3.7

- Added Integrated T&D Optimal Power Flow with on-load tap-changer (`opfitd_oltc`) problem specification. (Issue: #44)
- Added unit test cases for `opfitd_oltc` in `src/core/opfitd_oltc.jl` and added the test case file for oltc distribution test system `test/data/distribution/case3_balanced_modmw_oltc.dss`.
- Added descriptive documentation info. to functions that did not had appropriate string docs.
- Fixed minor typos in CHANGELOG.md.

## v0.3.6

- Fixed breaking compatibility issue of PMITD ACP solver(s) (for PMD section) and the new version of PMD (`v0.11.6`). (Issue: #42)
- The fixed breaking issue was related to problems related on how the slack bus was being modified in the function `_ref_filter_distribution_slack_generators!()`. The `va` and `vm` vectors have been commented out and the problem was solved.
- Renamed `types` in `types.jl`. `RelaxedPowerModelITD` was renamed to `BFPowerModelITD`. (Breaking change)
- Added new 'hybrid' types designed to represent different types of formulations that combine Linear (L), Non-linear(NL), Branch-Flow (BF), Current-Voltage rectangular (IVR) formulations.
- Added ACR-FBS formulation. (Issue: #41)
- Added First-order Taylor (FOT) rectangular and polar formulations pairs with respective non-linear formulations (ACR-FOTR, ACP-FOTP). (Issue: #41)
- Added SOCBF-LinDist3Flow formulation. (Issue: #41)

## v0.3.5

- Added support to specify if solution for both transmission and distribution system(s) are to be given in pu or SI units. (Issue: #40)
- Support for units specification added via the use of `make_si=false/true(default)`.
- Added unit tests to `opfitd.jl` and `opfitd_ms.jl` that demonstrate how to use this new feature, while evaluating the solutions outputted.
- All internal functions described has been added to `src/core/solution.jl`.
- Added support for renaming missing components (storage, switch, solar, generators, shunts) in function `_rename_components!(...)` that exists in `helpers.jl`. (Issue: #31)
- Fixed issue were `linecode` for lines renamed was not being renamed, and in cases with lines without linecode and error was presented.
- Added unit tests (and respective .dss file cases) where the new added components (switch, solar, etc) exist in the distribution systems solved as a multi-system (`opfitd_ms.jl`).
- Modified `case500_case34.json` and unit tests so that they support renaming capacitors (previously, it was not being solved with capacitors correctly in all distribution systems).

## v0.3.4

- Added support for transforming the PMD result "solution" from MATH to ENG. (Issue: #39)
- The transformation is facilitated by the PMD function: `_PMD.transform_solution(...)`. See `src/core/base.jl` - `run_model(...)`

## v0.3.3

- Added Unit test cases for test cases with 500+ nodes in transmission-side and 1200+ nodes in distribution-side. (Issue: #36).
- Added test cases: pglib_opf_500_goc, pglib_opf_case118_ieee, case3, case30, caseieee34, LVTestcase (and modified versions),
- Added multiple boundary linking files, to test/data/json, that link some of the T and D files added.
- Added unit tests to test/largescale_opfitd.jl that test ACR-ACR, ACP-ACP, IVR-IVR, and NFA-NFA formulations with 5+ distribution systems.
- Refactored parse_files() function so that PMD data is given as ENG model and not MATH model (as previously was given) (Issue: #37).
- Transformation to MATH model now occurs in instantiate_model() just before instantiation and running. User can now interact with ENG model for PMDs.
- Quality of life update of boundaries linking files format (JSON files), where distribution boundary only needs the name source and not voltage_source.source.
- Updated all JSON boundary linking files with new format.
- Updated some unit tests that needed to comply with the new format.
- The procedure to apply transformations and bounds to the combined pmd structure has been refactored so that it is the same procedure as the one existing in PMD. (Issue: #38).
- The new procedure for applying transformations/bounds is the same procedure that exists in PMD, i.e., just pass in the parsed data to the corresponding transformation functions.
- The Beginners_Guide.jl has been updated to reflect the new changes.
- README.md has been updated.

## v0.3.2

- Added support for adding voltage bounds and performing certain transformations to pmd file(s) provided by the user. (Issue: #34).
- Added function to apply voltage bounds to all buses in pmd file(s) provided by the user. Function apply_voltage_bounds()
- Added function to apply voltage angle difference bounds to all buses in pmd file(s) provided by the user. Function apply_voltage_angle_difference_bounds()
- Added function to remove all bounds to all buses in pmd file(s) provided by the user. Function remove_all_bounds()
- Added function to apply kron reduction to distribution system(s) provided in pmd file(s). Function apply_kron_reduction()
- Added function to apply phase projection to provided pmd file(s). Function apply_phase_projection()
- Added function to apply phase projection delta to provided pmd file(s). Function apply_phase_projection_delta()
- Added function to make distribution system(s) provided in pmd file(s) lossless. Function make_lossless().
- Important: all the previously described functions require an empty config dictionary that will be filled with the provided options that then needs to be passed in when parsing or running the models.
- Added function \_apply_pmd_transformations() to core/transformations.jl that is in charge of applying all required transformations.
- Modified all parse_files(), run_model(), run_pfitd(), and run_opfitd(), etc. functions so now they can accept an optional Dictionary parameter that specifies which transformations/bounds need to be applied to the pmd model(s).
- Added unit test cases to transformations_opfitd.jl that demonstrate how to use these new features (i.e., transformations, bounds, etc.) and then running opfitd studies.

## v0.3.1

- Added support for PSSE raw files (Issue: #33).
- Added case5 as PSSE raw file format to /test/data/transmission folder.
- Added unit test cases for ACR-ACR and ACP-ACP formulations using PSSE file (cost is different from .m due to PSSE file not having gen costs).
- Added Pluto.jl `Beginners_Guide.jl` notebook that explains how to use the current version of `PowerModelsITD.jl`. (Issue: #32).

## v0.3.0

- Added to support to handle multiple distribution systems at different transmission-system buses. (multiple-systems: ms) (Issue: #25)
- Added support for parsing multiple distribution system files (dss or m files) in common.jl
- Modified the function parse_power_distribution_file(...) to allow it to rename components of distribution systems that are not the first distribution system inputted.
- Modified parse_files(...) to allow the combination of multiple distribution systems under the same it=>pmd=>data structure.
- Created helper function \_rename_components!(...) in helpers.jl that renames all the components of additional distribution systems that need to be added to the pmd structure.
- Fixed major issues in _ref_connect_transmission_distribution!(...) - (ref.jl) that were not allowing the creation of multiple arcs_... references for all boundary connections.
- Added new instantiate_model() function that can handle a vector of multiple distribution system files.
- Added support for handling a single distribution system file in instantiate_model() function (maintain support for previous input format).
- Added support for handling a multiple distribution system files in run_model() function (also maintain support for previous input format of a single file).
- Modified opfitd.jl and pfitd.jl problem formulations so that they are able to handle multiple distribution systems connected at different transmission system buses.
- Fixed issues related to constraints being repeated for buses that were both in the boundary and transmission/distribution sets.
- Modified Bus KCL Constraints (current and power) at both transmission and distribution system levels so that they comply with the new format.
- Added unit test cases for a 1 transmission - 2 distribution systems test case. The unit test cases test both balance and unbalanced scenarios. They can be found at opfitd_ms.jl and pfitd_ms.jl.
- Minor modifications to the json file data to comply with the new input formats.
- Added case5_mod_with2loads.m transmission system test case data.
- Removed some unit test cases (DCP-DCP and ACR) that failed due to issues in PMD. In the future, unit test cases for these formulations will be included.
- Moved to version to 0.3.0 of PMITD.

## v0.2.6

- Added Second Order Cone (SOC-SOC) Relaxation formulation and the corresponding boundary constraints and models for the Optimal Power Flow ITD (opfitd) problem. (Issue: #28)
- Added Power Flow ITD (pfitd) problem for SOC-SOC formulation and corresponding unit tests.

## v0.2.5

- Added unit tests for opfitd that test the approximation to the individual PM-PMD optimal solution for the IVR, ACP, ACR, and NFA formulations.
- Corrected some small errors (deprecated) code that was introducing a very small dist. generator. The corrections were made in dss files. All unit tests objective values have been corrected.
- Corrected major bug in ivr.jl related to the constraint_boundary_voltage_magnitude() function. (Issue: #27)

## v0.2.4

- Added lambda values for boundary buses both at the Transmission and Distribution levels. These values are saved in pmitd structure. (Issue: #13)
- Fixed issue related to constraint_boundary_power() for LPowerModelITD. (Issue: #24)
- Fixed issue related to constraint_boundary_voltage_magnitude() for ACR models. (Issue: #26)

## v0.2.3

- Fixed issues related to (some) ACP models not being able to be solved. (Issue: #22)

## v0.2.2

- Added power flow ITD (pfitd) problem formulations.
- Added the build_pfitd() function problem formulation for AbstractPowerModelITD.
- Added the build_pfitd() function problem formulation for AbstractIVRPowerModelITD.
- Added unit test cases for different formulations (i.e., ACR, ACP, IVR, etc.) solving the pfitd problem.

## v0.2.1

- Added abstract types and PowerModelsITD types (types.jl) (Issue: #16).
- New abstract types: AbstractNLPowerModelITD (Non-linear), AbstractLPowerModelITD (Linear), AbstractIVRPowerModelITD (IVR), and AbstractRelaxedPowerModelITD (Relaxations).
- New PowerModelsITD types: NLPowerModelITD (Non-linear), LPowerModelITD (Linear), IVRPowerModelITD (IVR), RelaxedPowerModelITD (Relaxations).
- Added NFA Formulation (Issue: #17).
- Added IVR Formulation (Issue: #18).
- Added DCP Formulation (has problems getting a correct result that may be related to PMD issue) (Issue: #19).
- Added balanced and unbalanced unit test cases for all formulations currently available. (with and without distributed generators and different cost models).
- Renamed a few files to make them more general (for example relaxed.jl became boundary.jl)

## v0.2.0

- Added new test cases, both balanced and unbalanced - with and without distributed generation. Only balanced cases are currently being solved correctly.
- Added Integrated Transmission-Distribution (ITD) Optimal Power Flow (OPF) for ACP-ACP formulation
- Fixed issues related to boundary power constraints (not being negative) and cases when no gen is in dist. system and no objective function was being referenced (Issues: #15, #11).
- Version 0.2.+ will reflect all original formulations additions to PMITD.

## v0.1.1

- Initial working 1 Transmission- 1 Distribution release
- Added Integrated Transmission-Distribution (ITD) Optimal Power Flow (OPF) for ACR-ACR formulation
- Created base concept of the PMITD (PowerModelsIntegratedTransmissionDistribution) Package
- Created first ITD test case by combining case5 single-phase (T) with balanced three-phase case3 (D).

## v0.1.0

- Initial release
