@info "running integrated transmission-distribution optimal power flow (opfitd) decomposition tests"

@testset "test/opfitd_decomposition.jl" begin

    # @testset "solve_model (decomposition): Balanced case5-case3 With 2 Dist. Generators ACP-ACPU" begin
    #     pm_file = joinpath(dirname(trans_path), "case5_withload.m")
    #     pmd_file = joinpath(dirname(dist_path), "case3_balanced_2dgs.dss")
    #     pmitd_file = joinpath(dirname(bound_path), "case5_case3_bal_2dgs.json")
    #     pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
    #     pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)

    #      # Modify DGs costs
    #      gen_cost_1 = [0.0,26.0,0.0]
    #      gen_cost_2 = [0.0,15.0,0.0]
    #      pmitd_data["it"]["pmd"]["generator"]["3bus_bal2dgs.gen1"]["cost_pg_parameters"] = gen_cost_1 # Units are in $/MW^2, $/MW, and $.
    #      pmitd_data["it"]["pmd"]["generator"]["3bus_bal2dgs.gen2"]["cost_pg_parameters"] = gen_cost_2 # Units are in $/MW^2, $/MW, and $.

    #     result = solve_model(pmitd_data, pmitd_type, ipopt_decomposition, build_opfitd_decomposition)               # Solve Decomposition
    #     # result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd; make_si=false, solution_model="math")     # Solve ITD
    #     # @info "$(result["solution"]["it"]["pmitd"])"                                                                # This prints the power flows at the boundary of the ITD problem
    # end

    # @testset "solve_model (decomposition): Balanced case5-case3 With 2 Dist. Generators NFA-NFAU" begin
    #     pm_file = joinpath(dirname(trans_path), "case5_withload.m")
    #     pmd_file = joinpath(dirname(dist_path), "case3_balanced_2dgs.dss")
    #     pmitd_file = joinpath(dirname(bound_path), "case5_case3_bal_2dgs.json")
    #     pmitd_type = LPowerModelITD{NFAPowerModel, NFAUPowerModel}
    #     pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)

    #      # Modify DGs costs
    #      gen_cost_1 = [0.0,26.0,0.0]
    #      gen_cost_2 = [0.0,15.0,0.0]
    #      pmitd_data["it"]["pmd"]["generator"]["3bus_bal2dgs.gen1"]["cost_pg_parameters"] = gen_cost_1 # Units are in $/MW^2, $/MW, and $.
    #      pmitd_data["it"]["pmd"]["generator"]["3bus_bal2dgs.gen2"]["cost_pg_parameters"] = gen_cost_2 # Units are in $/MW^2, $/MW, and $.

    #     result = solve_model(pmitd_data, pmitd_type, ipopt_decomposition, build_opfitd_decomposition)               # Solve Decomposition
    #     # result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd; make_si=false, solution_model="eng")     # Solve ITD
    #     @info "$(result)"
    # end

    # @testset "solve_model (decomposition): Balanced case5-case3 With 2 Dist. Generators BFA-LinDist3FlowPowerModel" begin
    #     pm_file = joinpath(dirname(trans_path), "case5_withload.m")
    #     pmd_file = joinpath(dirname(dist_path), "case3_balanced_2dgs.dss")
    #     pmitd_file = joinpath(dirname(bound_path), "case5_case3_bal_2dgs.json")
    #     pmitd_type = BFPowerModelITD{BFAPowerModel, LinDist3FlowPowerModel}
    #     pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)

    #     # Modify DGs costs
    #     gen_cost_1 = [0.0,26.0,0.0]
    #     gen_cost_2 = [0.0,15.0,0.0]
    #     pmitd_data["it"]["pmd"]["generator"]["3bus_bal2dgs.gen1"]["cost_pg_parameters"] = gen_cost_1 # Units are in $/MW^2, $/MW, and $.
    #     pmitd_data["it"]["pmd"]["generator"]["3bus_bal2dgs.gen2"]["cost_pg_parameters"] = gen_cost_2 # Units are in $/MW^2, $/MW, and $.

    #     result = solve_model(pmitd_data, pmitd_type, ipopt_decomposition, build_opfitd_decomposition)               # Solve Decomposition
    #     # result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd; make_si=false, solution_model="eng")     # Solve ITD
    #     # @info "Power Flows at Boundary (look for the one that says pbound_fr => and  qbound_fr): $(result["solution"]["it"]["pmitd"])"                                                              # This prints the power flows at the boundary of the ITD problem
    #     # @info "Voltage: $(result["solution"]["it"]["pm"]["bus"]["5"])"
    # end


    # @testset "solve_model (decomposition): Balanced case5-case3x2 with 2 DGs ACP-ACPU" begin
    #     pm_file = joinpath(dirname(trans_path), "case5_with2loads.m")
    #     pmd_file = joinpath(dirname(dist_path), "case3_balanced_2dgs.dss")
    #     pmitd_file = joinpath(dirname(bound_path), "case5_case3x2.json")
    #     pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
    #     pmd_files = [pmd_file, pmd_file]
    #     pmitd_data = parse_files(pm_file, pmd_files, pmitd_file; auto_rename=true)

    #     # Modify DGs costs
    #     gen_cost_1 = [0.0,26.0,0.0]
    #     gen_cost_2 = [0.0,15.0,0.0]
    #     pmitd_data["it"]["pmd"]["generator"]["3bus_bal2dgs.gen1"]["cost_pg_parameters"] = gen_cost_1 # Units are in $/MW^2, $/MW, and $.
    #     pmitd_data["it"]["pmd"]["generator"]["3bus_bal2dgs.gen2"]["cost_pg_parameters"] = gen_cost_2 # Units are in $/MW^2, $/MW, and $.

    #     pmitd_data["it"]["pmd"]["generator"]["3bus_bal2dgs_2.gen1"]["cost_pg_parameters"] = gen_cost_2 # Units are in $/MW^2, $/MW, and $.
    #     pmitd_data["it"]["pmd"]["generator"]["3bus_bal2dgs_2.gen2"]["cost_pg_parameters"] = gen_cost_1 # Units are in $/MW^2, $/MW, and $.

    #     result = solve_model(pmitd_data, pmitd_type, ipopt_decomposition, build_opfitd_decomposition)         # Solve Decomposition
    #     # result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd; make_si=false, solution_model="eng")  # Solve ITD

    # end


    # @testset "solve_opfitd_decomposition: Multi-System case500-caseLV (5 ds in ms) with 3 DGs BFA-LinDist3Flow" begin
    #     pm_file = joinpath(dirname(trans_path), "pglib_opf_case500_goc.m")
    #     pmd_file = joinpath(dirname(dist_path), "lvtestcase_pmd_template_138kv_reduced_3dgs.dss")
    #     pmd_files = [pmd_file, pmd_file, pmd_file, pmd_file, pmd_file]
    #     pmitd_file = joinpath(dirname(bound_path), "case500_caseLV.json")
    #     pmitd_type = BFPowerModelITD{BFAPowerModel, LinDist3FlowPowerModel}
    #     pmitd_data = parse_files(pm_file, pmd_files, pmitd_file; auto_rename=true)

    #     # Modify DGs costs
    #     gen_cost_1 = [0.0,26.0,0.0]
    #     gen_cost_2 = [0.0,15.0,0.0]
    #     gen_cost_3 = [0.0,18.0,0.0]

    #     pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs.gen1"]["cost_pg_parameters"] = gen_cost_1 # Units are in $/MW^2, $/MW, and $.
    #     pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs.gen2"]["cost_pg_parameters"] = gen_cost_2 # Units are in $/MW^2, $/MW, and $.
    #     pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs.gen3"]["cost_pg_parameters"] = gen_cost_3 # Units are in $/MW^2, $/MW, and $.

    #     pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_2.gen1"]["cost_pg_parameters"] = gen_cost_3 # Units are in $/MW^2, $/MW, and $.
    #     pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_2.gen2"]["cost_pg_parameters"] = gen_cost_1 # Units are in $/MW^2, $/MW, and $.
    #     pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_2.gen3"]["cost_pg_parameters"] = gen_cost_2 # Units are in $/MW^2, $/MW, and $.

    #     pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_3.gen1"]["cost_pg_parameters"] = gen_cost_1 # Units are in $/MW^2, $/MW, and $.
    #     pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_3.gen2"]["cost_pg_parameters"] = gen_cost_3 # Units are in $/MW^2, $/MW, and $.
    #     pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_3.gen3"]["cost_pg_parameters"] = gen_cost_2 # Units are in $/MW^2, $/MW, and $.

    #     pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_4.gen1"]["cost_pg_parameters"] = gen_cost_2 # Units are in $/MW^2, $/MW, and $.
    #     pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_4.gen2"]["cost_pg_parameters"] = gen_cost_1 # Units are in $/MW^2, $/MW, and $.
    #     pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_4.gen3"]["cost_pg_parameters"] = gen_cost_3 # Units are in $/MW^2, $/MW, and $.

    #     pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_5.gen1"]["cost_pg_parameters"] = gen_cost_2 # Units are in $/MW^2, $/MW, and $.
    #     pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_5.gen2"]["cost_pg_parameters"] = gen_cost_3 # Units are in $/MW^2, $/MW, and $.
    #     pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_5.gen3"]["cost_pg_parameters"] = gen_cost_1 # Units are in $/MW^2, $/MW, and $.

    #    # result = solve_model(pmitd_data, pmitd_type, ipopt_decomposition, build_opfitd_decomposition)         # Solve Decomposition
    #    result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd; make_si=false, solution_model="eng")  # Solve ITD

    # end


    @testset "solve_opfitd_decomposition: Multi-System case500-caseLV (5 ds in ms) with 3 DGs NFA-NFAU" begin
        pm_file = joinpath(dirname(trans_path), "pglib_opf_case500_goc.m")
        pmd_file = joinpath(dirname(dist_path), "lvtestcase_pmd_template_138kv_reduced_3dgs.dss")
        pmd_files = [pmd_file, pmd_file]
        # pmd_files = [pmd_file, pmd_file, pmd_file, pmd_file, pmd_file]
        pmitd_file = joinpath(dirname(bound_path), "case500_caseLV_2.json")
        pmitd_type = LPowerModelITD{NFAPowerModel, NFAUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_files, pmitd_file; auto_rename=true)

        # Modify DGs costs
        gen_cost_1 = [0.0,26.0,0.0]
        gen_cost_2 = [0.0,15.0,0.0]
        gen_cost_3 = [0.0,18.0,0.0]

        pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs.gen1"]["cost_pg_parameters"] = gen_cost_1 # Units are in $/MW^2, $/MW, and $.
        pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs.gen2"]["cost_pg_parameters"] = gen_cost_2 # Units are in $/MW^2, $/MW, and $.
        pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs.gen3"]["cost_pg_parameters"] = gen_cost_3 # Units are in $/MW^2, $/MW, and $.

        pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_2.gen1"]["cost_pg_parameters"] = gen_cost_3 # Units are in $/MW^2, $/MW, and $.
        pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_2.gen2"]["cost_pg_parameters"] = gen_cost_1 # Units are in $/MW^2, $/MW, and $.
        pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_2.gen3"]["cost_pg_parameters"] = gen_cost_2 # Units are in $/MW^2, $/MW, and $.

        # pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_3.gen1"]["cost_pg_parameters"] = gen_cost_1 # Units are in $/MW^2, $/MW, and $.
        # pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_3.gen2"]["cost_pg_parameters"] = gen_cost_3 # Units are in $/MW^2, $/MW, and $.
        # pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_3.gen3"]["cost_pg_parameters"] = gen_cost_2 # Units are in $/MW^2, $/MW, and $.

        # pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_4.gen1"]["cost_pg_parameters"] = gen_cost_2 # Units are in $/MW^2, $/MW, and $.
        # pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_4.gen2"]["cost_pg_parameters"] = gen_cost_1 # Units are in $/MW^2, $/MW, and $.
        # pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_4.gen3"]["cost_pg_parameters"] = gen_cost_3 # Units are in $/MW^2, $/MW, and $.

        # pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_5.gen1"]["cost_pg_parameters"] = gen_cost_2 # Units are in $/MW^2, $/MW, and $.
        # pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_5.gen2"]["cost_pg_parameters"] = gen_cost_3 # Units are in $/MW^2, $/MW, and $.
        # pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_5.gen3"]["cost_pg_parameters"] = gen_cost_1 # Units are in $/MW^2, $/MW, and $.

       result = solve_model(pmitd_data, pmitd_type, ipopt_decomposition, build_opfitd_decomposition)         # Solve Decomposition
    #    result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd; make_si=false, solution_model="eng")  # Solve ITD
    #    @info "$(result)"                                                              # This prints the power flows at the boundary of the ITD problem

        open("result.txt", "w") do file
            write(file, "$(result)")
        end

    end


    # @testset "solve_opfitd_decomposition: Multi-System case500-caseLV (5 ds in ms) with 3 DGs ACP-ACPU" begin
    #     pm_file = joinpath(dirname(trans_path), "pglib_opf_case500_goc.m")
    #     pmd_file = joinpath(dirname(dist_path), "lvtestcase_pmd_template_138kv_reduced_3dgs.dss")
    #     pmd_files = [pmd_file, pmd_file, pmd_file, pmd_file, pmd_file]
    #     pmitd_file = joinpath(dirname(bound_path), "case500_caseLV.json")
    #     pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
    #     pmitd_data = parse_files(pm_file, pmd_files, pmitd_file; auto_rename=true)

    #     # Modify DGs costs
    #     gen_cost_1 = [0.0,26.0,0.0]
    #     gen_cost_2 = [0.0,15.0,0.0]
    #     gen_cost_3 = [0.0,18.0,0.0]

    #     pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs.gen1"]["cost_pg_parameters"] = gen_cost_1 # Units are in $/MW^2, $/MW, and $.
    #     pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs.gen2"]["cost_pg_parameters"] = gen_cost_2 # Units are in $/MW^2, $/MW, and $.
    #     pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs.gen3"]["cost_pg_parameters"] = gen_cost_3 # Units are in $/MW^2, $/MW, and $.

    #     pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_2.gen1"]["cost_pg_parameters"] = gen_cost_3 # Units are in $/MW^2, $/MW, and $.
    #     pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_2.gen2"]["cost_pg_parameters"] = gen_cost_1 # Units are in $/MW^2, $/MW, and $.
    #     pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_2.gen3"]["cost_pg_parameters"] = gen_cost_2 # Units are in $/MW^2, $/MW, and $.

    #     pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_3.gen1"]["cost_pg_parameters"] = gen_cost_1 # Units are in $/MW^2, $/MW, and $.
    #     pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_3.gen2"]["cost_pg_parameters"] = gen_cost_3 # Units are in $/MW^2, $/MW, and $.
    #     pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_3.gen3"]["cost_pg_parameters"] = gen_cost_2 # Units are in $/MW^2, $/MW, and $.

    #     pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_4.gen1"]["cost_pg_parameters"] = gen_cost_2 # Units are in $/MW^2, $/MW, and $.
    #     pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_4.gen2"]["cost_pg_parameters"] = gen_cost_1 # Units are in $/MW^2, $/MW, and $.
    #     pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_4.gen3"]["cost_pg_parameters"] = gen_cost_3 # Units are in $/MW^2, $/MW, and $.

    #     pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_5.gen1"]["cost_pg_parameters"] = gen_cost_2 # Units are in $/MW^2, $/MW, and $.
    #     pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_5.gen2"]["cost_pg_parameters"] = gen_cost_3 # Units are in $/MW^2, $/MW, and $.
    #     pmitd_data["it"]["pmd"]["generator"]["lv_138kv_10kw_3dgs_5.gen3"]["cost_pg_parameters"] = gen_cost_1 # Units are in $/MW^2, $/MW, and $.

    # #    result = solve_model(pmitd_data, pmitd_type, ipopt_decomposition, build_opfitd_decomposition)         # Solve Decomposition
    #    result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd; make_si=false, solution_model="eng")  # Solve ITD

    # end


end
