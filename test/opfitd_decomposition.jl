@info "running integrated transmission-distribution optimal power flow (opfitd) decomposition tests"

@testset "test/opfitd_decomposition.jl" begin

# ----------------- Linear NFA Tests ------------------------

    @testset "solve_model (decomposition): Balanced case5-case3 With 2 Dist. Generators NFA-NFAU" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced_2dgs.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_bal_2dgs.json")
        pmitd_type = LPowerModelITD{NFAPowerModel, NFAUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)

        # TODO: WITHOUT MODIFYING COSTS, IT WORKS, IF I MODIFY COSTS THEN I GET TOTALLY DIFFERENT RESULTS WHY?!!
        # # Modify DGs costs
        # gen_cost_1 = [0.0,26.0,0.0]
        # gen_cost_2 = [0.0,15.0,0.0]
        # pmitd_data["it"]["pmd"]["generator"]["3bus_bal2dgs.gen1"]["cost_pg_parameters"] = gen_cost_1 # Units are in $/MW^2, $/MW, and $.
        # pmitd_data["it"]["pmd"]["generator"]["3bus_bal2dgs.gen2"]["cost_pg_parameters"] = gen_cost_2 # Units are in $/MW^2, $/MW, and $.

        # Solve the problem using the two approaches
        pmitd_data_decomposition = deepcopy(pmitd_data)
        pmitd_data_itd = deepcopy(pmitd_data)

        result_itd = solve_model(pmitd_data_decomposition, pmitd_type, ipopt, build_opfitd; make_si=true, solution_model="eng")     # Solve ITD
        result_decomposition = solve_model(pmitd_data_itd, pmitd_type, ipopt_decomposition, build_opfitd_decomposition; make_si=true, solution_model="eng")     # Solve Decomposition

        #  ---- Compare results ----
        @info "------------------------ Objective -----------------------------------"
        # 1. Objective
        @info "objective (ITD): $(result_itd["objective"])"
        @info "objective (DECOMPOSITION): $(result_decomposition["solution"]["it"]["pm"]["objective"])"
        @info "--------------------------- Boundary flows --------------------------------"
        # 2. Boundary flows
        @info "Boundary Flow (ITD): Pbound_fr = $(result_itd["solution"]["it"]["pmitd"]["boundary"]["(100001, 5, voltage_source.3bus_bal2dgs.source)"]["pbound_fr"])"
        @info "Boundary Flows (DECOMPOSITION): Pload = $(result_decomposition["solution"]["it"]["pmitd"]["boundary"]["(100001, 5, voltage_source.3bus_bal2dgs.source)"]["pbound_load"]) and Paux = $(result_decomposition["solution"]["it"]["pmitd"]["boundary"]["(100001, 5, voltage_source.3bus_bal2dgs.source)"]["pbound_aux"])"
        @info "------------------ Generator Dispatches - Transmission --------------------"
        # 3. Generator Dispatches - Transmission
        @info "Gen Dispatches (ITD) - Transmission: $(result_itd["solution"]["it"]["pm"]["gen"])"
        @info "Gen Dispatches (DECOMPOSITION) - Transmission: $(result_decomposition["solution"]["it"]["pm"]["solution"]["gen"])"
        @info "-----------------Branch Power Flows - Transmission -----------------------"
        # 4. Branch Power Flows - Transmission
        @info "Branch Power Flows (ITD) - Transmission: $(result_itd["solution"]["it"]["pm"]["branch"])"
        @info "Branch Power Flows (DECOMPOSITION) - Transmission: $(result_decomposition["solution"]["it"]["pm"]["solution"]["branch"])"
        @info "------------------- Generator Dispatches - Distribution ----------------------------------------"
        # 5. Generator Dispatches - Distribution
        @info "Gen Dispatches (ITD) - Distribution: $(result_itd["solution"]["it"]["pmd"]["generator"])"
        @info "Gen Dispatches (DECOMPOSITION) - Distribution: $(result_decomposition["solution"]["it"]["pmd"]["3bus_bal2dgs"]["solution"]["generator"])"
        @info "------------------- Branch Power Flows - Distribution ----------------------------------------"
        # 6. Branch Power Flows - Distribution
        @info "Branch Power Flows (ITD) - Distribution: $(result_itd["solution"]["it"]["pmd"]["line"])"
        @info "Branch Power Flows (DECOMPOSITION) - Distribution: $(result_decomposition["solution"]["it"]["pmd"]["3bus_bal2dgs"]["solution"]["line"])"
        @info "-----------------------------------------------------------"
    end

    # @testset "solve_model (decomposition): Balanced case5-case3x2 with 2 DGs NFA-NFAU" begin
    #     pm_file = joinpath(dirname(trans_path), "case5_with2loads.m")
    #     pmd_file1 = joinpath(dirname(dist_path), "case3_balanced_2dgs.dss")
    #     pmd_file2 = joinpath(dirname(dist_path), "case3_unbalanced_2dgs.dss")
    #     pmitd_file = joinpath(dirname(bound_path), "case5_case3x2.json")
    #     pmitd_type = LPowerModelITD{NFAPowerModel, NFAUPowerModel}
    #     pmd_files = [pmd_file1, pmd_file2]
    #     pmitd_data = parse_files(pm_file, pmd_files, pmitd_file; auto_rename=true)

    #     # TODO: WITHOUT MODIFYING COSTS, IT WORKS, IF I MODIFY COSTS THEN I GET TOTALLY DIFFERENT RESULTS WHY?!!
    #     # Modify DGs costs
    #     # gen_cost_1 = [0.0,26.0,0.0]
    #     # gen_cost_2 = [0.0,15.0,0.0]
    #     # pmitd_data["it"]["pmd"]["generator"]["3bus_bal2dgs.gen1"]["cost_pg_parameters"] = gen_cost_1 # Units are in $/MW^2, $/MW, and $.
    #     # pmitd_data["it"]["pmd"]["generator"]["3bus_bal2dgs.gen2"]["cost_pg_parameters"] = gen_cost_2 # Units are in $/MW^2, $/MW, and $.

    #     # pmitd_data["it"]["pmd"]["generator"]["3bus_unbal2dgs.gen1"]["cost_pg_parameters"] = gen_cost_2 # Units are in $/MW^2, $/MW, and $.
    #     # pmitd_data["it"]["pmd"]["generator"]["3bus_unbal2dgs.gen2"]["cost_pg_parameters"] = gen_cost_1 # Units are in $/MW^2, $/MW, and $.

    #    # Solve the problem using the two approaches
    #    pmitd_data_decomposition = deepcopy(pmitd_data)
    #    pmitd_data_itd = deepcopy(pmitd_data)

    #    result_itd = solve_model(pmitd_data_decomposition, pmitd_type, ipopt, build_opfitd; make_si=true, solution_model="eng")     # Solve ITD
    #    result_decomposition = solve_model(pmitd_data_itd, pmitd_type, ipopt_decomposition, build_opfitd_decomposition; make_si=true, solution_model="eng")     # Solve Decomposition

    #     #  ---- Compare results ----
    #     @info "------------------------ Objective -----------------------------------"
    #     # 1. Objective
    #     @info "objective (ITD): $(result_itd["objective"])"
    #     @info "objective (DECOMPOSITION): $(result_decomposition["solution"]["it"]["pm"]["objective"])"
    #     @info "--------------------------- Boundary flows --------------------------------"
    #     # 2. Boundary flows
    #     @info "Boundary Flow (ITD) 3bus_bal2dgs: Pbound_fr = $(result_itd["solution"]["it"]["pmitd"]["boundary"]["(100001, 5, voltage_source.3bus_bal2dgs.source)"]["pbound_fr"])"
    #     @info "Boundary Flow (ITD) 3bus_unbal2dgs: Pbound_fr = $(result_itd["solution"]["it"]["pmitd"]["boundary"]["(100002, 6, voltage_source.3bus_unbal2dgs.source)"]["pbound_fr"])"
    #     @info "Boundary Flows (DECOMPOSITION): Pload = $(result_decomposition["solution"]["it"]["pmitd"]["boundary"]["(100001, 5, voltage_source.3bus_bal2dgs.source)"]["pbound_load"]) and Paux = $(result_decomposition["solution"]["it"]["pmitd"]["boundary"]["(100001, 5, voltage_source.3bus_bal2dgs.source)"]["pbound_aux"])"
    #     @info "Boundary Flows (DECOMPOSITION): Pload = $(result_decomposition["solution"]["it"]["pmitd"]["boundary"]["(100002, 6, voltage_source.3bus_unbal2dgs.source)"]["pbound_load"]) and Paux = $(result_decomposition["solution"]["it"]["pmitd"]["boundary"]["(100002, 6, voltage_source.3bus_unbal2dgs.source)"]["pbound_aux"])"
    #     @info "------------------ Generator Dispatches - Transmission --------------------"
    #     # 3. Generator Dispatches - Transmission
    #     @info "Gen Dispatches (ITD) - Transmission: $(result_itd["solution"]["it"]["pm"]["gen"])"
    #     @info "Gen Dispatches (DECOMPOSITION) - Transmission: $(result_decomposition["solution"]["it"]["pm"]["solution"]["gen"])"
    #     @info "-----------------Branch Power Flows - Transmission -----------------------"
    #     # 4. Branch Power Flows - Transmission
    #     @info "Branch Power Flows (ITD) - Transmission: $(result_itd["solution"]["it"]["pm"]["branch"])"
    #     @info "Branch Power Flows (DECOMPOSITION) - Transmission: $(result_decomposition["solution"]["it"]["pm"]["solution"]["branch"])"
    #     @info "------------------- Generator Dispatches - Distribution ----------------------------------------"
    #     # 5. Generator Dispatches - Distribution
    #     @info "Gen Dispatches (ITD) - Distribution: $(result_itd["solution"]["it"]["pmd"]["generator"])"
    #     @info "Gen Dispatches (DECOMPOSITION) - Distribution 3bus_bal2dgs: $(result_decomposition["solution"]["it"]["pmd"]["3bus_bal2dgs"]["solution"]["generator"])"
    #     @info "Gen Dispatches (DECOMPOSITION) - Distribution 3bus_unbal2dgs: $(result_decomposition["solution"]["it"]["pmd"]["3bus_unbal2dgs"]["solution"]["generator"])"
    #     @info "------------------- Branch Power Flows - Distribution ----------------------------------------"
    #     # 6. Branch Power Flows - Distribution
    #     @info "Branch Power Flows (ITD) - Distribution: $(result_itd["solution"]["it"]["pmd"]["line"])"
    #     @info "Branch Power Flows (DECOMPOSITION) - Distribution 3bus_bal2dgs: $(result_decomposition["solution"]["it"]["pmd"]["3bus_bal2dgs"]["solution"]["line"])"
    #     @info "Branch Power Flows (DECOMPOSITION) - Distribution 3bus_unbal2dgs: $(result_decomposition["solution"]["it"]["pmd"]["3bus_unbal2dgs"]["solution"]["line"])"
    #     @info "-----------------------------------------------------------"
    # end

    # @testset "solve_opfitd_decomposition: Multi-System case500-caseLV (5 ds in ms) with 3 DGs NFA-NFAU" begin
    #     pm_file = joinpath(dirname(trans_path), "pglib_opf_case500_goc.m")
    #     pmd_file = joinpath(dirname(dist_path), "lvtestcase_pmd_template_138kv_reduced_3dgs.dss")
    #     # pmd_files = [pmd_file, pmd_file]
    #     # pmitd_file = joinpath(dirname(bound_path), "case500_caseLV_2.json")
    #     pmd_files = [pmd_file, pmd_file, pmd_file, pmd_file, pmd_file]
    #     pmitd_file = joinpath(dirname(bound_path), "case500_caseLV.json")
    #     pmitd_type = LPowerModelITD{NFAPowerModel, NFAUPowerModel}
    #     pmitd_data = parse_files(pm_file, pmd_files, pmitd_file; auto_rename=true)

    #     # TODO: WITHOUT MODIFYING COSTS, IT WORKS, IF I MODIFY COSTS THEN I GET TOTALLY DIFFERENT RESULTS WHY?!!
    #     # # Modify DGs costs
    #     # gen_cost_1 = [0.0,26.0,0.0]
    #     # gen_cost_2 = [0.0,15.0,0.0]
    #     # gen_cost_3 = [0.0,18.0,0.0]

    #     # pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs.gen1"]["cost_pg_parameters"] = gen_cost_1 # Units are in $/MW^2, $/MW, and $.
    #     # pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs.gen2"]["cost_pg_parameters"] = gen_cost_2 # Units are in $/MW^2, $/MW, and $.
    #     # pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs.gen3"]["cost_pg_parameters"] = gen_cost_3 # Units are in $/MW^2, $/MW, and $.

    #     # pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_2.gen1"]["cost_pg_parameters"] = gen_cost_3 # Units are in $/MW^2, $/MW, and $.
    #     # pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_2.gen2"]["cost_pg_parameters"] = gen_cost_1 # Units are in $/MW^2, $/MW, and $.
    #     # pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_2.gen3"]["cost_pg_parameters"] = gen_cost_2 # Units are in $/MW^2, $/MW, and $.

    #     # pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_3.gen1"]["cost_pg_parameters"] = gen_cost_1 # Units are in $/MW^2, $/MW, and $.
    #     # pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_3.gen2"]["cost_pg_parameters"] = gen_cost_3 # Units are in $/MW^2, $/MW, and $.
    #     # pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_3.gen3"]["cost_pg_parameters"] = gen_cost_2 # Units are in $/MW^2, $/MW, and $.

    #     # pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_4.gen1"]["cost_pg_parameters"] = gen_cost_2 # Units are in $/MW^2, $/MW, and $.
    #     # pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_4.gen2"]["cost_pg_parameters"] = gen_cost_1 # Units are in $/MW^2, $/MW, and $.
    #     # pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_4.gen3"]["cost_pg_parameters"] = gen_cost_3 # Units are in $/MW^2, $/MW, and $.

    #     # pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_5.gen1"]["cost_pg_parameters"] = gen_cost_2 # Units are in $/MW^2, $/MW, and $.
    #     # pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_5.gen2"]["cost_pg_parameters"] = gen_cost_3 # Units are in $/MW^2, $/MW, and $.
    #     # pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_5.gen3"]["cost_pg_parameters"] = gen_cost_1 # Units are in $/MW^2, $/MW, and $.

    #     # Solve the problem using the two approaches
    #     pmitd_data_decomposition = deepcopy(pmitd_data)
    #     pmitd_data_itd = deepcopy(pmitd_data)

    #     result_itd = solve_model(pmitd_data_decomposition, pmitd_type, ipopt, build_opfitd; make_si=true, solution_model="eng")     # Solve ITD
    #     result_decomposition = solve_model(pmitd_data_itd, pmitd_type, ipopt_decomposition, build_opfitd_decomposition; make_si=true, solution_model="eng")     # Solve Decomposition

    #     #  ---- Compare results ----
    #     @info "------------------------ Objective -----------------------------------"
    #     # 1. Objective
    #     @info "objective (ITD): $(result_itd["objective"])"
    #     @info "objective (DECOMPOSITION): $(result_decomposition["solution"]["it"]["pm"]["objective"])"
    #     @info "--------------------------- Boundary flows --------------------------------"
    #     # 2. Boundary flows
    #     @info "Boundary Flow (ITD) lv_138kv_10kw_3dgs_3: Pbound_fr = $(result_itd["solution"]["it"]["pmitd"]["boundary"]["(100001, 11, voltage_source.lv_138kv_10kw_3dgs_3.source)"]["pbound_fr"])"
    #     @info "Boundary Flow (ITD) lv_138kv_10kw_3dgs_4: Pbound_fr = $(result_itd["solution"]["it"]["pmitd"]["boundary"]["(100002, 323, voltage_source.lv_138kv_10kw_3dgs_4.source)"]["pbound_fr"])"
    #     @info "Boundary Flow (ITD) lv_138kv_10kw_3dgs_2: Pbound_fr = $(result_itd["solution"]["it"]["pmitd"]["boundary"]["(100003, 337, voltage_source.lv_138kv_10kw_3dgs_2.source)"]["pbound_fr"])"
    #     @info "Boundary Flow (ITD) lv_138kv_10kw_3dgs_5: Pbound_fr = $(result_itd["solution"]["it"]["pmitd"]["boundary"]["(100004, 353, voltage_source.lv_138kv_10kw_3dgs_5.source)"]["pbound_fr"])"
    #     @info "Boundary Flow (ITD) lv_138kv_10kw_3dgs: Pbound_fr = $(result_itd["solution"]["it"]["pmitd"]["boundary"]["(100005, 366, voltage_source.lv_138kv_10kw_3dgs.source)"]["pbound_fr"])"
    #     @info "Boundary Flows (DECOMPOSITION): Pload = $(result_decomposition["solution"]["it"]["pmitd"]["boundary"]["(100001, 11, voltage_source.lv_138kv_10kw_3dgs_3.source)"]["pbound_load"]) and Paux = $(result_decomposition["solution"]["it"]["pmitd"]["boundary"]["(100001, 11, voltage_source.lv_138kv_10kw_3dgs_3.source)"]["pbound_aux"])"
    #     @info "Boundary Flows (DECOMPOSITION): Pload = $(result_decomposition["solution"]["it"]["pmitd"]["boundary"]["(100002, 323, voltage_source.lv_138kv_10kw_3dgs_4.source)"]["pbound_load"]) and Paux = $(result_decomposition["solution"]["it"]["pmitd"]["boundary"]["(100002, 323, voltage_source.lv_138kv_10kw_3dgs_4.source)"]["pbound_aux"])"
    #     @info "Boundary Flows (DECOMPOSITION): Pload = $(result_decomposition["solution"]["it"]["pmitd"]["boundary"]["(100003, 337, voltage_source.lv_138kv_10kw_3dgs_2.source)"]["pbound_load"]) and Paux = $(result_decomposition["solution"]["it"]["pmitd"]["boundary"]["(100003, 337, voltage_source.lv_138kv_10kw_3dgs_2.source)"]["pbound_aux"])"
    #     @info "Boundary Flows (DECOMPOSITION): Pload = $(result_decomposition["solution"]["it"]["pmitd"]["boundary"]["(100004, 353, voltage_source.lv_138kv_10kw_3dgs_5.source)"]["pbound_load"]) and Paux = $(result_decomposition["solution"]["it"]["pmitd"]["boundary"]["(100004, 353, voltage_source.lv_138kv_10kw_3dgs_5.source)"]["pbound_aux"])"
    #     @info "Boundary Flows (DECOMPOSITION): Pload = $(result_decomposition["solution"]["it"]["pmitd"]["boundary"]["(100005, 366, voltage_source.lv_138kv_10kw_3dgs.source)"]["pbound_load"]) and Paux = $(result_decomposition["solution"]["it"]["pmitd"]["boundary"]["(100005, 366, voltage_source.lv_138kv_10kw_3dgs.source)"]["pbound_aux"])"

    #     @info "------------------ Generator Dispatches - Transmission --------------------"
    #     # 3. Generator Dispatches - Transmission
    #     @info "Gen Dispatches (ITD) - Transmission: $(result_itd["solution"]["it"]["pm"]["gen"])"
    #     @info "Gen Dispatches (DECOMPOSITION) - Transmission: $(result_decomposition["solution"]["it"]["pm"]["solution"]["gen"])"
    #     @info "-----------------Branch Power Flows - Transmission -----------------------"
    #     # 4. Branch Power Flows - Transmission
    #     @info "Branch Power Flows (ITD) - Transmission: $(result_itd["solution"]["it"]["pm"]["branch"])"
    #     @info "Branch Power Flows (DECOMPOSITION) - Transmission: $(result_decomposition["solution"]["it"]["pm"]["solution"]["branch"])"
    #     @info "------------------- Generator Dispatches - Distribution ----------------------------------------"
    #     # 5. Generator Dispatches - Distribution
    #     @info "Gen Dispatches (ITD) - Distribution: $(result_itd["solution"]["it"]["pmd"]["generator"])"
    #     @info "Gen Dispatches (DECOMPOSITION) - Distribution lv_138kv_10kw_3dgs_3: $(result_decomposition["solution"]["it"]["pmd"]["lv_138kv_10kw_3dgs_3"]["solution"]["generator"])"
    #     @info "Gen Dispatches (DECOMPOSITION) - Distribution lv_138kv_10kw_3dgs_4: $(result_decomposition["solution"]["it"]["pmd"]["lv_138kv_10kw_3dgs_4"]["solution"]["generator"])"
    #     @info "Gen Dispatches (DECOMPOSITION) - Distribution lv_138kv_10kw_3dgs_2: $(result_decomposition["solution"]["it"]["pmd"]["lv_138kv_10kw_3dgs_2"]["solution"]["generator"])"
    #     @info "Gen Dispatches (DECOMPOSITION) - Distribution lv_138kv_10kw_3dgs_5: $(result_decomposition["solution"]["it"]["pmd"]["lv_138kv_10kw_3dgs_5"]["solution"]["generator"])"
    #     @info "Gen Dispatches (DECOMPOSITION) - Distribution lv_138kv_10kw_3dgs: $(result_decomposition["solution"]["it"]["pmd"]["lv_138kv_10kw_3dgs"]["solution"]["generator"])"
    #     @info "------------------- Branch Power Flows - Distribution ----------------------------------------"
    #     # 6. Branch Power Flows - Distribution
    #     @info "Branch Power Flows (ITD) - Distribution: $(result_itd["solution"]["it"]["pmd"]["line"])"
    #     @info "Branch Power Flows (DECOMPOSITION) - Distribution lv_138kv_10kw_3dgs_3: $(result_decomposition["solution"]["it"]["pmd"]["lv_138kv_10kw_3dgs_3"]["solution"]["line"])"
    #     @info "Branch Power Flows (DECOMPOSITION) - Distribution lv_138kv_10kw_3dgs_4: $(result_decomposition["solution"]["it"]["pmd"]["lv_138kv_10kw_3dgs_4"]["solution"]["line"])"
    #     @info "Branch Power Flows (DECOMPOSITION) - Distribution lv_138kv_10kw_3dgs_2: $(result_decomposition["solution"]["it"]["pmd"]["lv_138kv_10kw_3dgs_2"]["solution"]["line"])"
    #     @info "Branch Power Flows (DECOMPOSITION) - Distribution lv_138kv_10kw_3dgs_5: $(result_decomposition["solution"]["it"]["pmd"]["lv_138kv_10kw_3dgs_5"]["solution"]["line"])"
    #     @info "Branch Power Flows (DECOMPOSITION) - Distribution lv_138kv_10kw_3dgs: $(result_decomposition["solution"]["it"]["pmd"]["lv_138kv_10kw_3dgs"]["solution"]["line"])"
    #     @info "-----------------------------------------------------------"

    #     # # If you want to save the entire results dictionary in a file.
    #     # open("result_itd.txt", "w") do file
    #     #     write(file, "$(result_itd)")
    #     # end

    #     # # If you want to save the entire results dictionary in a file.
    #     # open("result_decomposition.txt", "w") do file
    #     #     write(file, "$(result_decomposition)")
    #     # end

    # end

# ----------------- NonLinear ACP Tests ------------------------

    # @testset "solve_model (decomposition): Balanced case5-case3 With 2 Dist. Generators ACP-ACPU" begin
    #     pm_file = joinpath(dirname(trans_path), "case5_withload.m")
    #     pmd_file = joinpath(dirname(dist_path), "case3_balanced_2dgs.dss")
    #     pmitd_file = joinpath(dirname(bound_path), "case5_case3_bal_2dgs.json")
    #     pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
    #     pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)

    #     # TODO: WITHOUT MODIFYING COSTS, IT WORKS (ACP gets very close but MAX ITERS error), IF I MODIFY COSTS THEN I GET TOTALLY DIFFERENT RESULTS WHY?!!
    #     # # Modify DGs costs
    #     # gen_cost_1 = [0.0,26.0,0.0]
    #     # gen_cost_2 = [0.0,15.0,0.0]
    #     # pmitd_data["it"]["pmd"]["generator"]["3bus_bal2dgs.gen1"]["cost_pg_parameters"] = gen_cost_1 # Units are in $/MW^2, $/MW, and $.
    #     # pmitd_data["it"]["pmd"]["generator"]["3bus_bal2dgs.gen2"]["cost_pg_parameters"] = gen_cost_2 # Units are in $/MW^2, $/MW, and $.

    #     # apply_voltage_bounds!(pmitd_data; vm_lb=0.95, vm_ub=1.2)

    #     # Solve the problem using the two approaches
    #     pmitd_data_decomposition = deepcopy(pmitd_data)
    #     pmitd_data_itd = deepcopy(pmitd_data)

    #     # result_itd = solve_model(pmitd_data_decomposition, pmitd_type, ipopt, build_opfitd; make_si=true, solution_model="eng")     # Solve ITD
    #     result_decomposition = solve_model(pmitd_data_itd, pmitd_type, ipopt_decomposition, build_opfitd_decomposition; make_si=true, solution_model="eng")     # Solve Decomposition

    #     #  ---- Compare results ----
    #     @info "------------------------ Objective -----------------------------------"
    #     # 1. Objective
    #     @info "objective (ITD): $(result_itd["objective"])"
    #     @info "objective (DECOMPOSITION): $(result_decomposition["solution"]["it"]["pm"]["objective"])"
    #     @info "--------------------------- Boundary flows --------------------------------"
    #     # 2. Boundary flows
    #     @info "Boundary Flow (ITD): Pbound_fr = $(result_itd["solution"]["it"]["pmitd"]["boundary"]["(100001, 5, voltage_source.3bus_bal2dgs.source)"]["pbound_fr"])"
    #     @info "Boundary Flow (ITD): Qbound_fr = $(result_itd["solution"]["it"]["pmitd"]["boundary"]["(100001, 5, voltage_source.3bus_bal2dgs.source)"]["qbound_fr"])"
    #     @info "Boundary Voltage (ITD): Vmag = $(result_itd["solution"]["it"]["pm"]["bus"]["5"]["vm"])"
    #     @info "Boundary Flows (DECOMPOSITION): Pload = $(result_decomposition["solution"]["it"]["pmitd"]["boundary"]["(100001, 5, voltage_source.3bus_bal2dgs.source)"]["pbound_load"]) and Paux = $(result_decomposition["solution"]["it"]["pmitd"]["boundary"]["(100001, 5, voltage_source.3bus_bal2dgs.source)"]["pbound_aux"])"
    #     @info "Boundary Flows (DECOMPOSITION): Qload = $(result_decomposition["solution"]["it"]["pmitd"]["boundary"]["(100001, 5, voltage_source.3bus_bal2dgs.source)"]["qbound_load"]) and Qaux = $(result_decomposition["solution"]["it"]["pmitd"]["boundary"]["(100001, 5, voltage_source.3bus_bal2dgs.source)"]["qbound_aux"])"
    #     @info "Boundary Voltage (DECOMPOSITION): Vmag = $(result_decomposition["solution"]["it"]["pm"]["solution"]["bus"]["5"]["vm"])"
    #     @info "------------------ Generator Dispatches - Transmission --------------------"
    #     # 3. Generator Dispatches - Transmission
    #     @info "Gen Dispatches (ITD) - Transmission: $(result_itd["solution"]["it"]["pm"]["gen"])"
    #     @info "Gen Dispatches (DECOMPOSITION) - Transmission: $(result_decomposition["solution"]["it"]["pm"]["solution"]["gen"])"
    #     @info "-----------------Branch Power Flows - Transmission -----------------------"
    #     # 4. Branch Power Flows - Transmission
    #     @info "Branch Power Flows (ITD) - Transmission: $(result_itd["solution"]["it"]["pm"]["branch"])"
    #     @info "Branch Power Flows (DECOMPOSITION) - Transmission: $(result_decomposition["solution"]["it"]["pm"]["solution"]["branch"])"
    #     @info "------------------- Generator Dispatches - Distribution ----------------------------------------"
    #     # 5. Generator Dispatches - Distribution
    #     @info "Gen Dispatches (ITD) - Distribution: $(result_itd["solution"]["it"]["pmd"]["generator"])"
    #     @info "Gen Dispatches (DECOMPOSITION) - Distribution: $(result_decomposition["solution"]["it"]["pmd"]["3bus_bal2dgs"]["solution"]["generator"])"
    #     @info "------------------- Branch Power Flows - Distribution ----------------------------------------"
    #     # 6. Branch Power Flows - Distribution
    #     @info "Branch Power Flows (ITD) - Distribution: $(result_itd["solution"]["it"]["pmd"]["line"])"
    #     @info "Branch Power Flows (DECOMPOSITION) - Distribution: $(result_decomposition["solution"]["it"]["pmd"]["3bus_bal2dgs"]["solution"]["line"])"
    #     @info "-----------------------------------------------------------"
    # end

    # @testset "solve_model (decomposition): Balanced case5-case3x2 with 2 DGs ACP-ACPU" begin
    #     pm_file = joinpath(dirname(trans_path), "case5_with2loads.m")
    #     pmd_file1 = joinpath(dirname(dist_path), "case3_balanced_2dgs.dss")
    #     pmd_file2 = joinpath(dirname(dist_path), "case3_unbalanced_2dgs.dss")
    #     pmitd_file = joinpath(dirname(bound_path), "case5_case3x2.json")
    #     pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
    #     pmd_files = [pmd_file1, pmd_file2]
    #     pmitd_data = parse_files(pm_file, pmd_files, pmitd_file; auto_rename=true)

    #     # TODO: WITHOUT MODIFYING COSTS, IT WORKS, IF I MODIFY COSTS THEN I GET TOTALLY DIFFERENT RESULTS WHY?!!
    #     # # Modify DGs costs
    #     # gen_cost_1 = [0.0,26.0,0.0]
    #     # gen_cost_2 = [0.0,15.0,0.0]
    #     # pmitd_data["it"]["pmd"]["generator"]["3bus_bal2dgs.gen1"]["cost_pg_parameters"] = gen_cost_1 # Units are in $/MW^2, $/MW, and $.
    #     # pmitd_data["it"]["pmd"]["generator"]["3bus_bal2dgs.gen2"]["cost_pg_parameters"] = gen_cost_2 # Units are in $/MW^2, $/MW, and $.

    #     # pmitd_data["it"]["pmd"]["generator"]["3bus_unbal2dgs.gen1"]["cost_pg_parameters"] = gen_cost_2 # Units are in $/MW^2, $/MW, and $.
    #     # pmitd_data["it"]["pmd"]["generator"]["3bus_unbal2dgs.gen2"]["cost_pg_parameters"] = gen_cost_1 # Units are in $/MW^2, $/MW, and $.

    #    # Solve the problem using the two approaches
    #    pmitd_data_decomposition = deepcopy(pmitd_data)
    #    pmitd_data_itd = deepcopy(pmitd_data)

    #    result_itd = solve_model(pmitd_data_decomposition, pmitd_type, ipopt, build_opfitd; make_si=true, solution_model="eng")     # Solve ITD
    #    result_decomposition = solve_model(pmitd_data_itd, pmitd_type, ipopt_decomposition, build_opfitd_decomposition; make_si=true, solution_model="eng")     # Solve Decomposition

    #     #  ---- Compare results ----
    #     @info "------------------------ Objective -----------------------------------"
    #     # 1. Objective
    #     @info "objective (ITD): $(result_itd["objective"])"
    #     @info "objective (DECOMPOSITION): $(result_decomposition["solution"]["it"]["pm"]["objective"])"
    #     @info "--------------------------- Boundary flows --------------------------------"
    #     # 2. Boundary flows
    #     @info "Boundary Flow (ITD) 3bus_bal2dgs: Pbound_fr = $(result_itd["solution"]["it"]["pmitd"]["boundary"]["(100001, 5, voltage_source.3bus_bal2dgs.source)"]["pbound_fr"])"
    #     @info "Boundary Flow (ITD) 3bus_unbal2dgs: Pbound_fr = $(result_itd["solution"]["it"]["pmitd"]["boundary"]["(100002, 6, voltage_source.3bus_unbal2dgs.source)"]["pbound_fr"])"
    #     @info "Boundary Flow (ITD) 3bus_bal2dgs: Qbound_fr = $(result_itd["solution"]["it"]["pmitd"]["boundary"]["(100001, 5, voltage_source.3bus_bal2dgs.source)"]["qbound_fr"])"
    #     @info "Boundary Flow (ITD) 3bus_unbal2dgs: Qbound_fr = $(result_itd["solution"]["it"]["pmitd"]["boundary"]["(100002, 6, voltage_source.3bus_unbal2dgs.source)"]["qbound_fr"])"
    #     @info "Boundary Voltage (ITD) - Vmag bus 5: $(result_itd["solution"]["it"]["pm"]["bus"]["5"]["vm"])"
    #     @info "Boundary Voltage (ITD) - Vmag bus 6: $(result_itd["solution"]["it"]["pm"]["bus"]["6"]["vm"])"
    #     @info "Boundary Flows (DECOMPOSITION) 3bus_bal2dgs: Pload = $(result_decomposition["solution"]["it"]["pmitd"]["boundary"]["(100001, 5, voltage_source.3bus_bal2dgs.source)"]["pbound_load"]) and Paux = $(result_decomposition["solution"]["it"]["pmitd"]["boundary"]["(100001, 5, voltage_source.3bus_bal2dgs.source)"]["pbound_aux"])"
    #     @info "Boundary Flows (DECOMPOSITION) 3bus_unbal2dgs: Pload = $(result_decomposition["solution"]["it"]["pmitd"]["boundary"]["(100002, 6, voltage_source.3bus_unbal2dgs.source)"]["pbound_load"]) and Paux = $(result_decomposition["solution"]["it"]["pmitd"]["boundary"]["(100002, 6, voltage_source.3bus_unbal2dgs.source)"]["pbound_aux"])"
    #     @info "Boundary Flows (DECOMPOSITION) 3bus_bal2dgs: Qload = $(result_decomposition["solution"]["it"]["pmitd"]["boundary"]["(100001, 5, voltage_source.3bus_bal2dgs.source)"]["qbound_load"]) and Qaux = $(result_decomposition["solution"]["it"]["pmitd"]["boundary"]["(100001, 5, voltage_source.3bus_bal2dgs.source)"]["qbound_aux"])"
    #     @info "Boundary Flows (DECOMPOSITION) 3bus_unbal2dgs: Qload = $(result_decomposition["solution"]["it"]["pmitd"]["boundary"]["(100002, 6, voltage_source.3bus_unbal2dgs.source)"]["qbound_load"]) and Qaux = $(result_decomposition["solution"]["it"]["pmitd"]["boundary"]["(100002, 6, voltage_source.3bus_unbal2dgs.source)"]["qbound_aux"])"
    #     @info "Boundary Voltage (DECOMPOSITION) - Vmag bus 5: $(result_decomposition["solution"]["it"]["pm"]["solution"]["bus"]["5"]["vm"])"
    #     @info "Boundary Voltage (DECOMPOSITION) - Vmag bus 6: $(result_decomposition["solution"]["it"]["pm"]["solution"]["bus"]["6"]["vm"])"
    #     @info "------------------ Generator Dispatches - Transmission --------------------"
    #     # 3. Generator Dispatches - Transmission
    #     @info "Gen Dispatches (ITD) - Transmission: $(result_itd["solution"]["it"]["pm"]["gen"])"
    #     @info "Gen Dispatches (DECOMPOSITION) - Transmission: $(result_decomposition["solution"]["it"]["pm"]["solution"]["gen"])"
    #     @info "-----------------Branch Power Flows - Transmission -----------------------"
    #     # 4. Branch Power Flows - Transmission
    #     @info "Branch Power Flows (ITD) - Transmission: $(result_itd["solution"]["it"]["pm"]["branch"])"
    #     @info "Branch Power Flows (DECOMPOSITION) - Transmission: $(result_decomposition["solution"]["it"]["pm"]["solution"]["branch"])"
    #     @info "------------------- Generator Dispatches - Distribution ----------------------------------------"
    #     # 5. Generator Dispatches - Distribution
    #     @info "Gen Dispatches (ITD) - Distribution: $(result_itd["solution"]["it"]["pmd"]["generator"])"
    #     @info "Gen Dispatches (DECOMPOSITION) - Distribution 3bus_bal2dgs: $(result_decomposition["solution"]["it"]["pmd"]["3bus_bal2dgs"]["solution"]["generator"])"
    #     @info "Gen Dispatches (DECOMPOSITION) - Distribution 3bus_unbal2dgs: $(result_decomposition["solution"]["it"]["pmd"]["3bus_unbal2dgs"]["solution"]["generator"])"
    #     @info "------------------- Branch Power Flows - Distribution ----------------------------------------"
    #     # 6. Branch Power Flows - Distribution
    #     @info "Branch Power Flows (ITD) - Distribution: $(result_itd["solution"]["it"]["pmd"]["line"])"
    #     @info "Branch Power Flows (DECOMPOSITION) - Distribution 3bus_bal2dgs: $(result_decomposition["solution"]["it"]["pmd"]["3bus_bal2dgs"]["solution"]["line"])"
    #     @info "Branch Power Flows (DECOMPOSITION) - Distribution 3bus_unbal2dgs: $(result_decomposition["solution"]["it"]["pmd"]["3bus_unbal2dgs"]["solution"]["line"])"
    #     @info "-----------------------------------------------------------"
    # end

    # @testset "solve_opfitd_decomposition: Multi-System case500-caseLV (5 ds in ms) with 3 DGs ACP-ACPU" begin
    #     pm_file = joinpath(dirname(trans_path), "pglib_opf_case500_goc.m")
    #     pmd_file = joinpath(dirname(dist_path), "lvtestcase_pmd_template_138kv_reduced_3dgs.dss")
    #     # pmd_files = [pmd_file, pmd_file]
    #     # pmitd_file = joinpath(dirname(bound_path), "case500_caseLV_2.json")
    #     pmd_files = [pmd_file, pmd_file, pmd_file, pmd_file, pmd_file]
    #     pmitd_file = joinpath(dirname(bound_path), "case500_caseLV.json")
    #     pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
    #     pmitd_data = parse_files(pm_file, pmd_files, pmitd_file; auto_rename=true)

    #     # TODO: WITHOUT MODIFYING COSTS, IT WORKS, IF I MODIFY COSTS THEN I GET TOTALLY DIFFERENT RESULTS WHY?!!
    #     # # Modify DGs costs
    #     # gen_cost_1 = [0.0,26.0,0.0]
    #     # gen_cost_2 = [0.0,15.0,0.0]
    #     # gen_cost_3 = [0.0,18.0,0.0]

    #     # pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs.gen1"]["cost_pg_parameters"] = gen_cost_1 # Units are in $/MW^2, $/MW, and $.
    #     # pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs.gen2"]["cost_pg_parameters"] = gen_cost_2 # Units are in $/MW^2, $/MW, and $.
    #     # pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs.gen3"]["cost_pg_parameters"] = gen_cost_3 # Units are in $/MW^2, $/MW, and $.

    #     # pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_2.gen1"]["cost_pg_parameters"] = gen_cost_3 # Units are in $/MW^2, $/MW, and $.
    #     # pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_2.gen2"]["cost_pg_parameters"] = gen_cost_1 # Units are in $/MW^2, $/MW, and $.
    #     # pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_2.gen3"]["cost_pg_parameters"] = gen_cost_2 # Units are in $/MW^2, $/MW, and $.

    #     # pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_3.gen1"]["cost_pg_parameters"] = gen_cost_1 # Units are in $/MW^2, $/MW, and $.
    #     # pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_3.gen2"]["cost_pg_parameters"] = gen_cost_3 # Units are in $/MW^2, $/MW, and $.
    #     # pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_3.gen3"]["cost_pg_parameters"] = gen_cost_2 # Units are in $/MW^2, $/MW, and $.

    #     # pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_4.gen1"]["cost_pg_parameters"] = gen_cost_2 # Units are in $/MW^2, $/MW, and $.
    #     # pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_4.gen2"]["cost_pg_parameters"] = gen_cost_1 # Units are in $/MW^2, $/MW, and $.
    #     # pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_4.gen3"]["cost_pg_parameters"] = gen_cost_3 # Units are in $/MW^2, $/MW, and $.

    #     # pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_5.gen1"]["cost_pg_parameters"] = gen_cost_2 # Units are in $/MW^2, $/MW, and $.
    #     # pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_5.gen2"]["cost_pg_parameters"] = gen_cost_3 # Units are in $/MW^2, $/MW, and $.
    #     # pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_5.gen3"]["cost_pg_parameters"] = gen_cost_1 # Units are in $/MW^2, $/MW, and $.

    #     # Solve the problem using the two approaches
    #     pmitd_data_decomposition = deepcopy(pmitd_data)
    #     pmitd_data_itd = deepcopy(pmitd_data)

    #     result_itd = solve_model(pmitd_data_decomposition, pmitd_type, ipopt, build_opfitd; make_si=true, solution_model="eng")     # Solve ITD
    #     result_decomposition = solve_model(pmitd_data_itd, pmitd_type, ipopt_decomposition, build_opfitd_decomposition; make_si=true, solution_model="eng")     # Solve Decomposition

    #     #  ---- Compare results ----
    #     @info "------------------------ Objective -----------------------------------"
    #     # 1. Objective
    #     @info "objective (ITD): $(result_itd["objective"])"
    #     @info "objective (DECOMPOSITION): $(result_decomposition["solution"]["it"]["pm"]["objective"])"
    #     @info "--------------------------- Boundary flows --------------------------------"
    #     # 2. Boundary flows
    #     @info "Boundary Flow (ITD) lv_138kv_10kw_3dgs_3: Pbound_fr = $(result_itd["solution"]["it"]["pmitd"]["boundary"]["(100001, 11, voltage_source.lv_138kv_10kw_3dgs_3.source)"]["pbound_fr"])"
    #     @info "Boundary Flow (ITD) lv_138kv_10kw_3dgs_4: Pbound_fr = $(result_itd["solution"]["it"]["pmitd"]["boundary"]["(100002, 323, voltage_source.lv_138kv_10kw_3dgs_4.source)"]["pbound_fr"])"
    #     @info "Boundary Flow (ITD) lv_138kv_10kw_3dgs_2: Pbound_fr = $(result_itd["solution"]["it"]["pmitd"]["boundary"]["(100003, 337, voltage_source.lv_138kv_10kw_3dgs_2.source)"]["pbound_fr"])"
    #     @info "Boundary Flow (ITD) lv_138kv_10kw_3dgs_5: Pbound_fr = $(result_itd["solution"]["it"]["pmitd"]["boundary"]["(100004, 353, voltage_source.lv_138kv_10kw_3dgs_5.source)"]["pbound_fr"])"
    #     @info "Boundary Flow (ITD) lv_138kv_10kw_3dgs: Pbound_fr = $(result_itd["solution"]["it"]["pmitd"]["boundary"]["(100005, 366, voltage_source.lv_138kv_10kw_3dgs.source)"]["pbound_fr"])"

    #     @info "Boundary Flow (ITD) lv_138kv_10kw_3dgs_3: Qbound_fr = $(result_itd["solution"]["it"]["pmitd"]["boundary"]["(100001, 11, voltage_source.lv_138kv_10kw_3dgs_3.source)"]["qbound_fr"])"
    #     @info "Boundary Flow (ITD) lv_138kv_10kw_3dgs_4: Qbound_fr = $(result_itd["solution"]["it"]["pmitd"]["boundary"]["(100002, 323, voltage_source.lv_138kv_10kw_3dgs_4.source)"]["qbound_fr"])"
    #     @info "Boundary Flow (ITD) lv_138kv_10kw_3dgs_2: Qbound_fr = $(result_itd["solution"]["it"]["pmitd"]["boundary"]["(100003, 337, voltage_source.lv_138kv_10kw_3dgs_2.source)"]["qbound_fr"])"
    #     @info "Boundary Flow (ITD) lv_138kv_10kw_3dgs_5: Qbound_fr = $(result_itd["solution"]["it"]["pmitd"]["boundary"]["(100004, 353, voltage_source.lv_138kv_10kw_3dgs_5.source)"]["qbound_fr"])"
    #     @info "Boundary Flow (ITD) lv_138kv_10kw_3dgs: Qbound_fr = $(result_itd["solution"]["it"]["pmitd"]["boundary"]["(100005, 366, voltage_source.lv_138kv_10kw_3dgs.source)"]["qbound_fr"])"

    #     @info "Boundary Voltage (ITD) - Vmag bus 11: $(result_itd["solution"]["it"]["pm"]["bus"]["11"]["vm"])"
    #     @info "Boundary Voltage (ITD) - Vmag bus 323: $(result_itd["solution"]["it"]["pm"]["bus"]["323"]["vm"])"
    #     @info "Boundary Voltage (ITD) - Vmag bus 337: $(result_itd["solution"]["it"]["pm"]["bus"]["337"]["vm"])"
    #     @info "Boundary Voltage (ITD) - Vmag bus 353: $(result_itd["solution"]["it"]["pm"]["bus"]["353"]["vm"])"
    #     @info "Boundary Voltage (ITD) - Vmag bus 366: $(result_itd["solution"]["it"]["pm"]["bus"]["366"]["vm"])"

    #     @info "Boundary Flows (DECOMPOSITION): Pload = $(result_decomposition["solution"]["it"]["pmitd"]["boundary"]["(100001, 11, voltage_source.lv_138kv_10kw_3dgs_3.source)"]["pbound_load"]) and Paux = $(result_decomposition["solution"]["it"]["pmitd"]["boundary"]["(100001, 11, voltage_source.lv_138kv_10kw_3dgs_3.source)"]["pbound_aux"])"
    #     @info "Boundary Flows (DECOMPOSITION): Pload = $(result_decomposition["solution"]["it"]["pmitd"]["boundary"]["(100002, 323, voltage_source.lv_138kv_10kw_3dgs_4.source)"]["pbound_load"]) and Paux = $(result_decomposition["solution"]["it"]["pmitd"]["boundary"]["(100002, 323, voltage_source.lv_138kv_10kw_3dgs_4.source)"]["pbound_aux"])"
    #     @info "Boundary Flows (DECOMPOSITION): Pload = $(result_decomposition["solution"]["it"]["pmitd"]["boundary"]["(100003, 337, voltage_source.lv_138kv_10kw_3dgs_2.source)"]["pbound_load"]) and Paux = $(result_decomposition["solution"]["it"]["pmitd"]["boundary"]["(100003, 337, voltage_source.lv_138kv_10kw_3dgs_2.source)"]["pbound_aux"])"
    #     @info "Boundary Flows (DECOMPOSITION): Pload = $(result_decomposition["solution"]["it"]["pmitd"]["boundary"]["(100004, 353, voltage_source.lv_138kv_10kw_3dgs_5.source)"]["pbound_load"]) and Paux = $(result_decomposition["solution"]["it"]["pmitd"]["boundary"]["(100004, 353, voltage_source.lv_138kv_10kw_3dgs_5.source)"]["pbound_aux"])"
    #     @info "Boundary Flows (DECOMPOSITION): Pload = $(result_decomposition["solution"]["it"]["pmitd"]["boundary"]["(100005, 366, voltage_source.lv_138kv_10kw_3dgs.source)"]["pbound_load"]) and Paux = $(result_decomposition["solution"]["it"]["pmitd"]["boundary"]["(100005, 366, voltage_source.lv_138kv_10kw_3dgs.source)"]["pbound_aux"])"

    #     @info "Boundary Flows (DECOMPOSITION): Qload = $(result_decomposition["solution"]["it"]["pmitd"]["boundary"]["(100001, 11, voltage_source.lv_138kv_10kw_3dgs_3.source)"]["qbound_load"]) and Qaux = $(result_decomposition["solution"]["it"]["pmitd"]["boundary"]["(100001, 11, voltage_source.lv_138kv_10kw_3dgs_3.source)"]["qbound_aux"])"
    #     @info "Boundary Flows (DECOMPOSITION): Qload = $(result_decomposition["solution"]["it"]["pmitd"]["boundary"]["(100002, 323, voltage_source.lv_138kv_10kw_3dgs_4.source)"]["qbound_load"]) and Qaux = $(result_decomposition["solution"]["it"]["pmitd"]["boundary"]["(100002, 323, voltage_source.lv_138kv_10kw_3dgs_4.source)"]["qbound_aux"])"
    #     @info "Boundary Flows (DECOMPOSITION): Qload = $(result_decomposition["solution"]["it"]["pmitd"]["boundary"]["(100003, 337, voltage_source.lv_138kv_10kw_3dgs_2.source)"]["qbound_load"]) and Qaux = $(result_decomposition["solution"]["it"]["pmitd"]["boundary"]["(100003, 337, voltage_source.lv_138kv_10kw_3dgs_2.source)"]["qbound_aux"])"
    #     @info "Boundary Flows (DECOMPOSITION): Qload = $(result_decomposition["solution"]["it"]["pmitd"]["boundary"]["(100004, 353, voltage_source.lv_138kv_10kw_3dgs_5.source)"]["qbound_load"]) and Qaux = $(result_decomposition["solution"]["it"]["pmitd"]["boundary"]["(100004, 353, voltage_source.lv_138kv_10kw_3dgs_5.source)"]["qbound_aux"])"
    #     @info "Boundary Flows (DECOMPOSITION): Qload = $(result_decomposition["solution"]["it"]["pmitd"]["boundary"]["(100005, 366, voltage_source.lv_138kv_10kw_3dgs.source)"]["qbound_load"]) and Qaux = $(result_decomposition["solution"]["it"]["pmitd"]["boundary"]["(100005, 366, voltage_source.lv_138kv_10kw_3dgs.source)"]["qbound_aux"])"

    #     @info "Boundary Voltage (DECOMPOSITION) - Vmag bus 11: $(result_decomposition["solution"]["it"]["pm"]["solution"]["bus"]["11"]["vm"])"
    #     @info "Boundary Voltage (DECOMPOSITION) - Vmag bus 323: $(result_decomposition["solution"]["it"]["pm"]["solution"]["bus"]["323"]["vm"])"
    #     @info "Boundary Voltage (DECOMPOSITION) - Vmag bus 337: $(result_decomposition["solution"]["it"]["pm"]["solution"]["bus"]["337"]["vm"])"
    #     @info "Boundary Voltage (DECOMPOSITION) - Vmag bus 353: $(result_decomposition["solution"]["it"]["pm"]["solution"]["bus"]["353"]["vm"])"
    #     @info "Boundary Voltage (DECOMPOSITION) - Vmag bus 366: $(result_decomposition["solution"]["it"]["pm"]["solution"]["bus"]["366"]["vm"])"

    #     @info "------------------ Generator Dispatches - Transmission --------------------"
    #     # 3. Generator Dispatches - Transmission
    #     @info "Gen Dispatches (ITD) - Transmission: $(result_itd["solution"]["it"]["pm"]["gen"])"
    #     @info "Gen Dispatches (DECOMPOSITION) - Transmission: $(result_decomposition["solution"]["it"]["pm"]["solution"]["gen"])"
    #     @info "-----------------Branch Power Flows - Transmission -----------------------"
    #     # 4. Branch Power Flows - Transmission
    #     @info "Branch Power Flows (ITD) - Transmission: $(result_itd["solution"]["it"]["pm"]["branch"])"
    #     @info "Branch Power Flows (DECOMPOSITION) - Transmission: $(result_decomposition["solution"]["it"]["pm"]["solution"]["branch"])"
    #     @info "------------------- Generator Dispatches - Distribution ----------------------------------------"
    #     # 5. Generator Dispatches - Distribution
    #     @info "Gen Dispatches (ITD) - Distribution: $(result_itd["solution"]["it"]["pmd"]["generator"])"
    #     @info "Gen Dispatches (DECOMPOSITION) - Distribution lv_138kv_10kw_3dgs_3: $(result_decomposition["solution"]["it"]["pmd"]["lv_138kv_10kw_3dgs_3"]["solution"]["generator"])"
    #     @info "Gen Dispatches (DECOMPOSITION) - Distribution lv_138kv_10kw_3dgs_4: $(result_decomposition["solution"]["it"]["pmd"]["lv_138kv_10kw_3dgs_4"]["solution"]["generator"])"
    #     @info "Gen Dispatches (DECOMPOSITION) - Distribution lv_138kv_10kw_3dgs_2: $(result_decomposition["solution"]["it"]["pmd"]["lv_138kv_10kw_3dgs_2"]["solution"]["generator"])"
    #     @info "Gen Dispatches (DECOMPOSITION) - Distribution lv_138kv_10kw_3dgs_5: $(result_decomposition["solution"]["it"]["pmd"]["lv_138kv_10kw_3dgs_5"]["solution"]["generator"])"
    #     @info "Gen Dispatches (DECOMPOSITION) - Distribution lv_138kv_10kw_3dgs: $(result_decomposition["solution"]["it"]["pmd"]["lv_138kv_10kw_3dgs"]["solution"]["generator"])"
    #     @info "------------------- Branch Power Flows - Distribution ----------------------------------------"
    #     # 6. Branch Power Flows - Distribution
    #     @info "Branch Power Flows (ITD) - Distribution: $(result_itd["solution"]["it"]["pmd"]["line"])"
    #     @info "Branch Power Flows (DECOMPOSITION) - Distribution lv_138kv_10kw_3dgs_3: $(result_decomposition["solution"]["it"]["pmd"]["lv_138kv_10kw_3dgs_3"]["solution"]["line"])"
    #     @info "Branch Power Flows (DECOMPOSITION) - Distribution lv_138kv_10kw_3dgs_4: $(result_decomposition["solution"]["it"]["pmd"]["lv_138kv_10kw_3dgs_4"]["solution"]["line"])"
    #     @info "Branch Power Flows (DECOMPOSITION) - Distribution lv_138kv_10kw_3dgs_2: $(result_decomposition["solution"]["it"]["pmd"]["lv_138kv_10kw_3dgs_2"]["solution"]["line"])"
    #     @info "Branch Power Flows (DECOMPOSITION) - Distribution lv_138kv_10kw_3dgs_5: $(result_decomposition["solution"]["it"]["pmd"]["lv_138kv_10kw_3dgs_5"]["solution"]["line"])"
    #     @info "Branch Power Flows (DECOMPOSITION) - Distribution lv_138kv_10kw_3dgs: $(result_decomposition["solution"]["it"]["pmd"]["lv_138kv_10kw_3dgs"]["solution"]["line"])"
    #     @info "-----------------------------------------------------------"

    #     # # If you want to save the entire results dictionary in a file.
    #     # open("result_itd.txt", "w") do file
    #     #     write(file, "$(result_itd)")
    #     # end

    #     # # If you want to save the entire results dictionary in a file.
    #     # open("result_decomposition.txt", "w") do file
    #     #     write(file, "$(result_decomposition)")
    #     # end
    # end

end
