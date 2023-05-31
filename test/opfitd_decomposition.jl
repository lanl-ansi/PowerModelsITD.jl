@info "running integrated transmission-distribution optimal power flow (opfitd) decomposition tests"

@testset "test/opfitd_decomposition.jl" begin


# ----------------- Linear NFA Tests ------------------------

  @testset "solve_model (decomposition): Balanced case5-case3 With 2 Dist. Generators NFA-NFAU" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced_2dgs.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_bal_2dgs.json")
        pmitd_type = LPowerModelITD{NFAPowerModel, NFAUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)

        # Modify DGs costs
        gen_cost_1 = [0.0,26.0,0.0]
        gen_cost_2 = [0.0,15.0,0.0]
        pmitd_data["it"]["pmd"]["generator"]["3bus_bal2dgs.gen1"]["cost_pg_parameters"] = gen_cost_1 # Units are in $/MW^2, $/MW, and $.
        pmitd_data["it"]["pmd"]["generator"]["3bus_bal2dgs.gen2"]["cost_pg_parameters"] = gen_cost_2 # Units are in $/MW^2, $/MW, and $.

        # Solve the problem using the two approaches
        pmitd_data_decomposition = deepcopy(pmitd_data)
        pmitd_data_itd = deepcopy(pmitd_data)

        result_itd = solve_model(pmitd_data_decomposition, pmitd_type, ipopt, build_opfitd; make_si=false, solution_model="math")     # Solve ITD
        result_decomposition = solve_model(pmitd_data_itd, pmitd_type, ipopt_decomposition, build_opfitd_decomposition)     # Solve Decomposition

        #  ---- Compare results ----
        @info "------------------------ Objective -----------------------------------"
        # 1. Objective
        @info "objective (ITD): $(result_itd["objective"])"
        @info "objective (DECOMPOSITION): READ FROM SCREEN OUTPUT (need to fix this!)"
        @info "--------------------------- Boundary flows --------------------------------"
        # 2. Boundary flows
        @info "Boundary Flow (ITD): $(result_itd["solution"]["it"]["pmitd"]["boundary"]["(100001, 5, 9)"]["pbound_fr"])"
        @info "Boundary Flows (DECOMPOSITION): Pload = $(result_decomposition["it"]["pm"]["solution"]["boundary"]["(100001, 5, 9)"]["pbound_load"]) and Paux = $(result_decomposition["it"]["pmd"]["ckt_1"]["solution"]["boundary"]["(100001, 5, 9)"]["pbound_aux"])"
        @info "------------------ Generator Dispatches - Transmission --------------------"
        # 3. Generator Dispatches - Transmission
        @info "Gen Dispatches (ITD) - Transmission: $(result_itd["solution"]["it"]["pm"]["gen"])"
        @info "Gen Dispatche (DECOMPOSITION) - Transmission: $(result_decomposition["it"]["pm"]["solution"]["gen"])"
        @info "-----------------Branch Power Flows - Transmission -----------------------"
        # 4. Branch Power Flows - Transmission
        @info "Branch Power Flows (ITD) - Transmission: $(result_itd["solution"]["it"]["pm"]["branch"])"
        @info "Branch Power Flows (DECOMPOSITION) - Transmission: $(result_decomposition["it"]["pm"]["solution"]["branch"])"
        @info "------------------- Generator Dispatches - Distribution ----------------------------------------"
        # 5. Generator Dispatches - Distribution
        @info "Gen Dispatches (ITD) - Distribution: $(result_itd["solution"]["it"]["pmd"]["gen"])"
        @info "Gen Dispatches (DECOMPOSITION) - Distribution (THIRD ONE IS THE SLACK): $(result_decomposition["it"]["pmd"]["ckt_1"]["solution"]["gen"])"
        @info "------------------- Branch Power Flows - Distribution ----------------------------------------"
        # 6. Branch Power Flows - Distribution
        @info "Branch Power Flows (ITD) - Distribution: $(result_itd["solution"]["it"]["pmd"]["branch"])"
        @info "Branch Power Flows (DECOMPOSITION) - Distribution: $(result_decomposition["it"]["pmd"]["ckt_1"]["solution"]["branch"])"
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

    #    result_itd = solve_model(pmitd_data_decomposition, pmitd_type, ipopt, build_opfitd; make_si=false, solution_model="math")     # Solve ITD
    #    result_decomposition = solve_model(pmitd_data_itd, pmitd_type, ipopt_decomposition, build_opfitd_decomposition)     # Solve Decomposition

    #     #  ---- Compare results ----
    #     @info "------------------------ Objective -----------------------------------"
    #     # 1. Objective
    #     @info "objective (ITD): $(result_itd["objective"])"
    #     @info "objective (DECOMPOSITION): READ FROM SCREEN OUTPUT (need to fix this!)"
    #     @info "--------------------------- Boundary flows --------------------------------"
    #     # 2. Boundary flows
    #     @info "Boundary Flow (ITD) ckt 1: $(result_itd["solution"]["it"]["pmitd"]["boundary"]["(100001, 5, 17)"]["pbound_fr"])"
    #     @info "Boundary Flow (ITD) ckt 2: $(result_itd["solution"]["it"]["pmitd"]["boundary"]["(100002, 6, 18)"]["pbound_fr"])"
    #     @info "Boundary Flows (DECOMPOSITION) ckt 1: Pload = $(result_decomposition["it"]["pm"]["solution"]["boundary"]["(100001, 5, 9)"]["pbound_load"]) and Paux = $(result_decomposition["it"]["pmd"]["ckt_1"]["solution"]["boundary"]["(100001, 5, 9)"]["pbound_aux"])"
    #     @info "Boundary Flows (DECOMPOSITION) ckt 2: Pload = $(result_decomposition["it"]["pm"]["solution"]["boundary"]["(100002, 6, 9)"]["pbound_load"]) and Paux = $(result_decomposition["it"]["pmd"]["ckt_2"]["solution"]["boundary"]["(100002, 6, 9)"]["pbound_aux"])"
    #     @info "------------------ Generator Dispatches - Transmission --------------------"
    #     # 3. Generator Dispatches - Transmission
    #     @info "Gen Dispatches (ITD) - Transmission: $(result_itd["solution"]["it"]["pm"]["gen"])"
    #     @info "Gen Dispatches (DECOMPOSITION) - Transmission: $(result_decomposition["it"]["pm"]["solution"]["gen"])"
    #     @info "-----------------Branch Power Flows - Transmission -----------------------"
    #     # 4. Branch Power Flows - Transmission
    #     @info "Branch Power Flows (ITD) - Transmission: $(result_itd["solution"]["it"]["pm"]["branch"])"
    #     @info "Branch Power Flows (DECOMPOSITION) - Transmission: $(result_decomposition["it"]["pm"]["solution"]["branch"])"
    #     @info "------------------- Generator Dispatches - Distribution ----------------------------------------"
    #     # 5. Generator Dispatches - Distribution
    #     @info "Gen Dispatches (ITD) - Distribution: $(result_itd["solution"]["it"]["pmd"]["gen"])"
    #     @info "Gen Dispatches (DECOMPOSITION) - Distribution ckt 1: $(result_decomposition["it"]["pmd"]["ckt_1"]["solution"]["gen"])"
    #     @info "Gen Dispatches (DECOMPOSITION) - Distribution ckt 2: $(result_decomposition["it"]["pmd"]["ckt_2"]["solution"]["gen"])"
    #     @info "------------------- Branch Power Flows - Distribution ----------------------------------------"
    #     # 6. Branch Power Flows - Distribution
    #     @info "Branch Power Flows (ITD) - Distribution: $(result_itd["solution"]["it"]["pmd"]["branch"])"
    #     @info "Branch Power Flows (DECOMPOSITION) - Distribution ckt 1: $(result_decomposition["it"]["pmd"]["ckt_1"]["solution"]["branch"])"
    #     @info "Branch Power Flows (DECOMPOSITION) - Distribution ckt 2: $(result_decomposition["it"]["pmd"]["ckt_2"]["solution"]["branch"])"
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

    #     result_itd = solve_model(pmitd_data_decomposition, pmitd_type, ipopt, build_opfitd; make_si=false, solution_model="math")     # Solve ITD
    #     result_decomposition = solve_model(pmitd_data_itd, pmitd_type, ipopt_decomposition, build_opfitd_decomposition)     # Solve Decomposition

    #     #  ---- Compare results ----
    #     @info "------------------------ Objective -----------------------------------"
    #     # 1. Objective
    #     @info "objective (ITD): $(result_itd["objective"])"
    #     @info "objective (DECOMPOSITION): READ FROM SCREEN OUTPUT (need to fix this!)"
    #     @info "--------------------------- Boundary flows --------------------------------"
    #     # 2. Boundary flows
    #     @info "Boundary Flow (ITD) ckt 1: $(result_itd["solution"]["it"]["pmitd"]["boundary"]["(100001, 11, 633)"]["pbound_fr"])"
    #     @info "Boundary Flow (ITD) ckt 2: $(result_itd["solution"]["it"]["pmitd"]["boundary"]["(100002, 323, 634)"]["pbound_fr"])"
    #     @info "Boundary Flow (ITD) ckt 3: $(result_itd["solution"]["it"]["pmitd"]["boundary"]["(100003, 337, 632)"]["pbound_fr"])"
    #     @info "Boundary Flow (ITD) ckt 4: $(result_itd["solution"]["it"]["pmitd"]["boundary"]["(100004, 353, 635)"]["pbound_fr"])"
    #     @info "Boundary Flow (ITD) ckt 5: $(result_itd["solution"]["it"]["pmitd"]["boundary"]["(100005, 366, 631)"]["pbound_fr"])"

    #     @info "Boundary Flows (DECOMPOSITION): Pload = $(result_decomposition["it"]["pm"]["solution"]["boundary"]["(100001, 11, 127)"]["pbound_load"])"
    #     @info "Boundary Flows (DECOMPOSITION): Pload = $(result_decomposition["it"]["pm"]["solution"]["boundary"]["(100002, 323, 127)"]["pbound_load"])"
    #     @info "Boundary Flows (DECOMPOSITION): Pload = $(result_decomposition["it"]["pm"]["solution"]["boundary"]["(100003, 337, 127)"]["pbound_load"])"
    #     @info "Boundary Flows (DECOMPOSITION): Pload = $(result_decomposition["it"]["pm"]["solution"]["boundary"]["(100004, 353, 127)"]["pbound_load"])"
    #     @info "Boundary Flows (DECOMPOSITION): Pload = $(result_decomposition["it"]["pm"]["solution"]["boundary"]["(100005, 366, 127)"]["pbound_load"])"

    #     @info "Boundary Flows (DECOMPOSITION): Paux = $(result_decomposition["it"]["pmd"]["ckt_5"]["solution"]["boundary"])"
    #     @info "Boundary Flows (DECOMPOSITION): Paux = $(result_decomposition["it"]["pmd"]["ckt_3"]["solution"]["boundary"])"
    #     @info "Boundary Flows (DECOMPOSITION): Paux = $(result_decomposition["it"]["pmd"]["ckt_1"]["solution"]["boundary"])"
    #     @info "Boundary Flows (DECOMPOSITION): Paux = $(result_decomposition["it"]["pmd"]["ckt_4"]["solution"]["boundary"])"
    #     @info "Boundary Flows (DECOMPOSITION): Paux = $(result_decomposition["it"]["pmd"]["ckt_2"]["solution"]["boundary"])"

    #     # @info "------------------ Generator Dispatches - Transmission --------------------"
    #     # # 3. Generator Dispatches - Transmission
    #     # @info "Gen Dispatches (ITD) - Transmission: $(result_itd["solution"]["it"]["pm"]["gen"])"
    #     # @info "Gen Dispatches (DECOMPOSITION) - Transmission: $(result_decomposition["it"]["pm"]["solution"]["gen"])"
    #     # @info "-----------------Branch Power Flows - Transmission -----------------------"
    #     # # 4. Branch Power Flows - Transmission
    #     # @info "Branch Power Flows (ITD) - Transmission: $(result_itd["solution"]["it"]["pm"]["branch"])"
    #     # @info "Branch Power Flows (DECOMPOSITION) - Transmission: $(result_decomposition["it"]["pm"]["solution"]["branch"])"
    #     # @info "------------------- Generator Dispatches - Distribution ----------------------------------------"
    #     # # 5. Generator Dispatches - Distribution
    #     # @info "Gen Dispatches (ITD) - Distribution: $(result_itd["solution"]["it"]["pmd"]["gen"])"
    #     # @info "Gen Dispatches (DECOMPOSITION) - Distribution ckt 1: $(result_decomposition["it"]["pmd"]["ckt_5"]["solution"]["gen"])"
    #     # @info "Gen Dispatches (DECOMPOSITION) - Distribution ckt 2: $(result_decomposition["it"]["pmd"]["ckt_3"]["solution"]["gen"])"
    #     # @info "Gen Dispatches (DECOMPOSITION) - Distribution ckt 3: $(result_decomposition["it"]["pmd"]["ckt_1"]["solution"]["gen"])"
    #     # @info "Gen Dispatches (DECOMPOSITION) - Distribution ckt 4: $(result_decomposition["it"]["pmd"]["ckt_4"]["solution"]["gen"])"
    #     # @info "Gen Dispatches (DECOMPOSITION) - Distribution ckt 5: $(result_decomposition["it"]["pmd"]["ckt_2"]["solution"]["gen"])"
    #     # @info "------------------- Branch Power Flows - Distribution ----------------------------------------"
    #     # # 6. Branch Power Flows - Distribution
    #     # @info "Branch Power Flows (ITD) - Distribution: $(result_itd["solution"]["it"]["pmd"]["branch"])"
    #     # @info "Branch Power Flows (DECOMPOSITION) - Distribution ckt 1: $(result_decomposition["it"]["pmd"]["ckt_5"]["solution"]["branch"])"
    #     # @info "Branch Power Flows (DECOMPOSITION) - Distribution ckt 2: $(result_decomposition["it"]["pmd"]["ckt_3"]["solution"]["branch"])"
    #     # @info "Branch Power Flows (DECOMPOSITION) - Distribution ckt 3: $(result_decomposition["it"]["pmd"]["ckt_1"]["solution"]["branch"])"
    #     # @info "Branch Power Flows (DECOMPOSITION) - Distribution ckt 4: $(result_decomposition["it"]["pmd"]["ckt_4"]["solution"]["branch"])"
    #     # @info "Branch Power Flows (DECOMPOSITION) - Distribution ckt 5: $(result_decomposition["it"]["pmd"]["ckt_2"]["solution"]["branch"])"
    #     # @info "-----------------------------------------------------------"

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

    #     # Solve the problem using the two approaches
    #     pmitd_data_decomposition = deepcopy(pmitd_data)
    #     pmitd_data_itd = deepcopy(pmitd_data)

    #     result_itd = solve_model(pmitd_data_decomposition, pmitd_type, ipopt, build_opfitd; make_si=false, solution_model="math")     # Solve ITD
    #     # result_decomposition = solve_model(pmitd_data_itd, pmitd_type, ipopt_decomposition, build_opfitd_decomposition)     # Solve Decomposition

    #     #  ---- Compare results ----
    #     @info "------------------------ Objective -----------------------------------"
    #     # 1. Objective
    #     @info "objective (ITD): $(result_itd["objective"])"
    #     # @info "objective (DECOMPOSITION): READ FROM SCREEN OUTPUT (need to fix this!)"
    #     # @info "--------------------------- Boundary flows --------------------------------"
    #     # # 2. Boundary flows
    #     @info "Boundary Flow (ITD) - P: $(result_itd["solution"]["it"]["pmitd"]["boundary"]["(100001, 5, 9)"]["pbound_fr"])"
    #     @info "Boundary Flow (ITD) - Q: $(result_itd["solution"]["it"]["pmitd"]["boundary"]["(100001, 5, 9)"]["qbound_fr"])"
    #     @info "Boundary Voltage (ITD) - V: $(result_itd["solution"]["it"]["pm"]["bus"]["5"]["vm"])"
    #     # @info "Boundary Flows (DECOMPOSITION): Pload = $(result_decomposition["it"]["pm"]["solution"]["boundary"]["(100001, 5, 9)"]["pbound_load"]) and Paux = $(result_decomposition["it"]["pmd"]["ckt_1"]["solution"]["boundary"]["(100001, 5, 9)"]["pbound_aux"])"
    #     # @info "Boundary Flows (DECOMPOSITION): Qload = $(result_decomposition["it"]["pm"]["solution"]["boundary"]["(100001, 5, 9)"]["qbound_load"]) and Qaux = $(result_decomposition["it"]["pmd"]["ckt_1"]["solution"]["boundary"]["(100001, 5, 9)"]["qbound_aux"])"
    #     # @info "------------------ Generator Dispatches - Transmission --------------------"
    #     # # 3. Generator Dispatches - Transmission
    #     # @info "Gen Dispatches (ITD) - Transmission: $(result_itd["solution"]["it"]["pm"]["gen"])"
    #     # @info "Gen Dispatche (DECOMPOSITION) - Transmission: $(result_decomposition["it"]["pm"]["solution"]["gen"])"
    #     # @info "-----------------Branch Power Flows - Transmission -----------------------"
    #     # # 4. Branch Power Flows - Transmission
    #     # @info "Branch Power Flows (ITD) - Transmission: $(result_itd["solution"]["it"]["pm"]["branch"])"
    #     # @info "Branch Power Flows (DECOMPOSITION) - Transmission: $(result_decomposition["it"]["pm"]["solution"]["branch"])"
    #     # @info "------------------- Generator Dispatches - Distribution ----------------------------------------"
    #     # # 5. Generator Dispatches - Distribution
    #     # @info "Gen Dispatches (ITD) - Distribution: $(result_itd["solution"]["it"]["pmd"]["gen"])"
    #     # @info "Gen Dispatches (DECOMPOSITION) - Distribution (THIRD ONE IS THE SLACK): $(result_decomposition["it"]["pmd"]["ckt_1"]["solution"]["gen"])"
    #     # @info "------------------- Branch Power Flows - Distribution ----------------------------------------"
    #     # # 6. Branch Power Flows - Distribution
    #     # @info "Branch Power Flows (ITD) - Distribution: $(result_itd["solution"]["it"]["pmd"]["branch"])"
    #     # @info "Branch Power Flows (DECOMPOSITION) - Distribution: $(result_decomposition["it"]["pmd"]["ckt_1"]["solution"]["branch"])"
    #     # @info "-----------------------------------------------------------"
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

    #    result_itd = solve_model(pmitd_data_decomposition, pmitd_type, ipopt, build_opfitd; make_si=false, solution_model="math")     # Solve ITD
    # #    result_decomposition = solve_model(pmitd_data_itd, pmitd_type, ipopt_decomposition, build_opfitd_decomposition)     # Solve Decomposition

    #     #  ---- Compare results ----
    #     @info "------------------------ Objective -----------------------------------"
    #     # 1. Objective
    #     @info "objective (ITD): $(result_itd["objective"])"
    #     @info "objective (DECOMPOSITION): READ FROM SCREEN OUTPUT (need to fix this!)"
    #     @info "--------------------------- Boundary flows --------------------------------"
    #     # 2. Boundary flows
    #     @info "Boundary Flow (ITD) ckt 1 - P: $(result_itd["solution"]["it"]["pmitd"]["boundary"]["(100001, 5, 17)"]["pbound_fr"])"
    #     @info "Boundary Flow (ITD) ckt 2 - P: $(result_itd["solution"]["it"]["pmitd"]["boundary"]["(100002, 6, 18)"]["pbound_fr"])"
    #     @info "Boundary Flow (ITD) ckt 1 - Q: $(result_itd["solution"]["it"]["pmitd"]["boundary"]["(100001, 5, 17)"]["qbound_fr"])"
    #     @info "Boundary Flow (ITD) ckt 2 - Q: $(result_itd["solution"]["it"]["pmitd"]["boundary"]["(100002, 6, 18)"]["qbound_fr"])"
    #     # @info "Boundary Flows (DECOMPOSITION) ckt 1: Pload = $(result_decomposition["it"]["pm"]["solution"]["boundary"]["(100001, 5, 9)"]["pbound_load"]) and Paux = $(result_decomposition["it"]["pmd"]["ckt_1"]["solution"]["boundary"]["(100001, 5, 9)"]["pbound_aux"])"
    #     # @info "Boundary Flows (DECOMPOSITION) ckt 2: Pload = $(result_decomposition["it"]["pm"]["solution"]["boundary"]["(100002, 6, 9)"]["pbound_load"]) and Paux = $(result_decomposition["it"]["pmd"]["ckt_2"]["solution"]["boundary"]["(100002, 6, 9)"]["pbound_aux"])"
    #     # @info "Boundary Flows (DECOMPOSITION) ckt 1: Qload = $(result_decomposition["it"]["pm"]["solution"]["boundary"]["(100001, 5, 9)"]["qbound_load"]) and Qaux = $(result_decomposition["it"]["pmd"]["ckt_1"]["solution"]["boundary"]["(100001, 5, 9)"]["qbound_aux"])"
    #     # @info "Boundary Flows (DECOMPOSITION) ckt 2: Qload = $(result_decomposition["it"]["pm"]["solution"]["boundary"]["(100002, 6, 9)"]["qbound_load"]) and Qaux = $(result_decomposition["it"]["pmd"]["ckt_2"]["solution"]["boundary"]["(100002, 6, 9)"]["qbound_aux"])"
    #     # @info "------------------ Generator Dispatches - Transmission --------------------"
    #     # # 3. Generator Dispatches - Transmission
    #     # @info "Gen Dispatches (ITD) - Transmission: $(result_itd["solution"]["it"]["pm"]["gen"])"
    #     # @info "Gen Dispatches (DECOMPOSITION) - Transmission: $(result_decomposition["it"]["pm"]["solution"]["gen"])"
    #     # @info "-----------------Branch Power Flows - Transmission -----------------------"
    #     # # 4. Branch Power Flows - Transmission
    #     # @info "Branch Power Flows (ITD) - Transmission: $(result_itd["solution"]["it"]["pm"]["branch"])"
    #     # @info "Branch Power Flows (DECOMPOSITION) - Transmission: $(result_decomposition["it"]["pm"]["solution"]["branch"])"
    #     # @info "------------------- Generator Dispatches - Distribution ----------------------------------------"
    #     # # 5. Generator Dispatches - Distribution
    #     # @info "Gen Dispatches (ITD) - Distribution: $(result_itd["solution"]["it"]["pmd"]["gen"])"
    #     # @info "Gen Dispatches (DECOMPOSITION) - Distribution ckt 1: $(result_decomposition["it"]["pmd"]["ckt_1"]["solution"]["gen"])"
    #     # @info "Gen Dispatches (DECOMPOSITION) - Distribution ckt 2: $(result_decomposition["it"]["pmd"]["ckt_2"]["solution"]["gen"])"
    #     # @info "------------------- Branch Power Flows - Distribution ----------------------------------------"
    #     # # 6. Branch Power Flows - Distribution
    #     # @info "Branch Power Flows (ITD) - Distribution: $(result_itd["solution"]["it"]["pmd"]["branch"])"
    #     # @info "Branch Power Flows (DECOMPOSITION) - Distribution ckt 1: $(result_decomposition["it"]["pmd"]["ckt_1"]["solution"]["branch"])"
    #     # @info "Branch Power Flows (DECOMPOSITION) - Distribution ckt 2: $(result_decomposition["it"]["pmd"]["ckt_2"]["solution"]["branch"])"
    #     # @info "-----------------------------------------------------------"

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

    #     result_itd = solve_model(pmitd_data_decomposition, pmitd_type, ipopt, build_opfitd; make_si=false, solution_model="math")     # Solve ITD
    #     # result_decomposition = solve_model(pmitd_data_itd, pmitd_type, ipopt_decomposition, build_opfitd_decomposition)     # Solve Decomposition

    #     #  ---- Compare results ----
    #     @info "------------------------ Objective -----------------------------------"
    #     # 1. Objective
    #     @info "objective (ITD): $(result_itd["objective"])"
    #     @info "objective (DECOMPOSITION): READ FROM SCREEN OUTPUT (need to fix this!)"
    #     @info "--------------------------- Boundary flows --------------------------------"
    #     # 2. Boundary flows
    #     @info "Boundary Flow (ITD) ckt 1 - P: $(result_itd["solution"]["it"]["pmitd"]["boundary"]["(100001, 11, 633)"]["pbound_fr"])"
    #     @info "Boundary Flow (ITD) ckt 2 - P: $(result_itd["solution"]["it"]["pmitd"]["boundary"]["(100002, 323, 634)"]["pbound_fr"])"
    #     @info "Boundary Flow (ITD) ckt 3 - P: $(result_itd["solution"]["it"]["pmitd"]["boundary"]["(100003, 337, 632)"]["pbound_fr"])"
    #     @info "Boundary Flow (ITD) ckt 4 - P: $(result_itd["solution"]["it"]["pmitd"]["boundary"]["(100004, 353, 635)"]["pbound_fr"])"
    #     @info "Boundary Flow (ITD) ckt 5 - P: $(result_itd["solution"]["it"]["pmitd"]["boundary"]["(100005, 366, 631)"]["pbound_fr"])"

    #     @info "Boundary Flow (ITD) ckt 1 - Q: $(result_itd["solution"]["it"]["pmitd"]["boundary"]["(100001, 11, 633)"]["qbound_fr"])"
    #     @info "Boundary Flow (ITD) ckt 2 - Q: $(result_itd["solution"]["it"]["pmitd"]["boundary"]["(100002, 323, 634)"]["qbound_fr"])"
    #     @info "Boundary Flow (ITD) ckt 3 - Q: $(result_itd["solution"]["it"]["pmitd"]["boundary"]["(100003, 337, 632)"]["qbound_fr"])"
    #     @info "Boundary Flow (ITD) ckt 4 - Q: $(result_itd["solution"]["it"]["pmitd"]["boundary"]["(100004, 353, 635)"]["qbound_fr"])"
    #     @info "Boundary Flow (ITD) ckt 5 - Q: $(result_itd["solution"]["it"]["pmitd"]["boundary"]["(100005, 366, 631)"]["qbound_fr"])"

    #     # @info "Boundary Flows (DECOMPOSITION): Pload = $(result_decomposition["it"]["pm"]["solution"]["boundary"]["(100001, 11, 127)"]["pbound_load"])"
    #     # @info "Boundary Flows (DECOMPOSITION): Pload = $(result_decomposition["it"]["pm"]["solution"]["boundary"]["(100002, 323, 127)"]["pbound_load"])"
    #     # @info "Boundary Flows (DECOMPOSITION): Pload = $(result_decomposition["it"]["pm"]["solution"]["boundary"]["(100003, 337, 127)"]["pbound_load"])"
    #     # @info "Boundary Flows (DECOMPOSITION): Pload = $(result_decomposition["it"]["pm"]["solution"]["boundary"]["(100004, 353, 127)"]["pbound_load"])"
    #     # @info "Boundary Flows (DECOMPOSITION): Pload = $(result_decomposition["it"]["pm"]["solution"]["boundary"]["(100005, 366, 127)"]["pbound_load"])"

    #     # @info "Boundary Flows (DECOMPOSITION): Qload = $(result_decomposition["it"]["pm"]["solution"]["boundary"]["(100001, 11, 127)"]["qbound_load"])"
    #     # @info "Boundary Flows (DECOMPOSITION): Qload = $(result_decomposition["it"]["pm"]["solution"]["boundary"]["(100002, 323, 127)"]["qbound_load"])"
    #     # @info "Boundary Flows (DECOMPOSITION): Qload = $(result_decomposition["it"]["pm"]["solution"]["boundary"]["(100003, 337, 127)"]["qbound_load"])"
    #     # @info "Boundary Flows (DECOMPOSITION): Qload = $(result_decomposition["it"]["pm"]["solution"]["boundary"]["(100004, 353, 127)"]["qbound_load"])"
    #     # @info "Boundary Flows (DECOMPOSITION): Qload = $(result_decomposition["it"]["pm"]["solution"]["boundary"]["(100005, 366, 127)"]["qbound_load"])"

    #     # @info "Boundary Flows (DECOMPOSITION): Paux and Qaux = $(result_decomposition["it"]["pmd"]["ckt_5"]["solution"]["boundary"])"
    #     # @info "Boundary Flows (DECOMPOSITION): Paux and Qaux = $(result_decomposition["it"]["pmd"]["ckt_3"]["solution"]["boundary"])"
    #     # @info "Boundary Flows (DECOMPOSITION): Paux and Qaux = $(result_decomposition["it"]["pmd"]["ckt_1"]["solution"]["boundary"])"
    #     # @info "Boundary Flows (DECOMPOSITION): Paux and Qaux = $(result_decomposition["it"]["pmd"]["ckt_4"]["solution"]["boundary"])"
    #     # @info "Boundary Flows (DECOMPOSITION): Paux and Qaux = $(result_decomposition["it"]["pmd"]["ckt_2"]["solution"]["boundary"])"

    #     # @info "------------------ Generator Dispatches - Transmission --------------------"
    #     # # 3. Generator Dispatches - Transmission
    #     # @info "Gen Dispatches (ITD) - Transmission: $(result_itd["solution"]["it"]["pm"]["gen"])"
    #     # @info "Gen Dispatches (DECOMPOSITION) - Transmission: $(result_decomposition["it"]["pm"]["solution"]["gen"])"
    #     # @info "-----------------Branch Power Flows - Transmission -----------------------"
    #     # # 4. Branch Power Flows - Transmission
    #     # @info "Branch Power Flows (ITD) - Transmission: $(result_itd["solution"]["it"]["pm"]["branch"])"
    #     # @info "Branch Power Flows (DECOMPOSITION) - Transmission: $(result_decomposition["it"]["pm"]["solution"]["branch"])"
    #     # @info "------------------- Generator Dispatches - Distribution ----------------------------------------"
    #     # # 5. Generator Dispatches - Distribution
    #     # @info "Gen Dispatches (ITD) - Distribution: $(result_itd["solution"]["it"]["pmd"]["gen"])"
    #     # @info "Gen Dispatches (DECOMPOSITION) - Distribution ckt 1: $(result_decomposition["it"]["pmd"]["ckt_5"]["solution"]["gen"])"
    #     # @info "Gen Dispatches (DECOMPOSITION) - Distribution ckt 2: $(result_decomposition["it"]["pmd"]["ckt_3"]["solution"]["gen"])"
    #     # @info "Gen Dispatches (DECOMPOSITION) - Distribution ckt 3: $(result_decomposition["it"]["pmd"]["ckt_1"]["solution"]["gen"])"
    #     # @info "Gen Dispatches (DECOMPOSITION) - Distribution ckt 4: $(result_decomposition["it"]["pmd"]["ckt_4"]["solution"]["gen"])"
    #     # @info "Gen Dispatches (DECOMPOSITION) - Distribution ckt 5: $(result_decomposition["it"]["pmd"]["ckt_2"]["solution"]["gen"])"
    #     # @info "------------------- Branch Power Flows - Distribution ----------------------------------------"
    #     # # 6. Branch Power Flows - Distribution
    #     # @info "Branch Power Flows (ITD) - Distribution: $(result_itd["solution"]["it"]["pmd"]["branch"])"
    #     # @info "Branch Power Flows (DECOMPOSITION) - Distribution ckt 1: $(result_decomposition["it"]["pmd"]["ckt_5"]["solution"]["branch"])"
    #     # @info "Branch Power Flows (DECOMPOSITION) - Distribution ckt 2: $(result_decomposition["it"]["pmd"]["ckt_3"]["solution"]["branch"])"
    #     # @info "Branch Power Flows (DECOMPOSITION) - Distribution ckt 3: $(result_decomposition["it"]["pmd"]["ckt_1"]["solution"]["branch"])"
    #     # @info "Branch Power Flows (DECOMPOSITION) - Distribution ckt 4: $(result_decomposition["it"]["pmd"]["ckt_4"]["solution"]["branch"])"
    #     # @info "Branch Power Flows (DECOMPOSITION) - Distribution ckt 5: $(result_decomposition["it"]["pmd"]["ckt_2"]["solution"]["branch"])"
    #     # @info "-----------------------------------------------------------"

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
