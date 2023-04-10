@info "running integrated transmission-distribution optimal power flow (opfitd) decomposition tests"

@testset "test/opfitd_decomposition.jl" begin

    @testset "solve_model (decomposition): Balanced case5-case3x2 ACP-ACP" begin
        pm_file = joinpath(dirname(trans_path), "case5_with2loads.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3x2.json")
        pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
        pmd_files = [pmd_file, pmd_file]
        pmitd_data = parse_files(pm_file, pmd_files, pmitd_file; auto_rename=true)
        result = solve_model(pmitd_data, pmitd_type, ipopt_decomposition, build_opfitd_decomposition)
        # @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_model (decomposition): Unbalanced case5-case3 Without Dist. Generator NFA-NFAU" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_unbal_nogen.json")
        pmitd_type = LPowerModelITD{NFAPowerModel, NFAUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, ipopt_decomposition, build_opfitd_decomposition)
        # @test result["termination_status"] == LOCALLY_SOLVED
    end


    @testset "solve_model (decomposition): Unbalanced case5-case3 Without Dist. Generator BFA-LinDist3FlowPowerModel" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_unbal_nogen.json")
        pmitd_type = BFPowerModelITD{BFAPowerModel, LinDist3FlowPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, ipopt_decomposition, build_opfitd_decomposition)
        # @test result["termination_status"] == LOCALLY_SOLVED
    end


    # @testset "solve_opfitd_decomposition: Multi-System case500-caseLV (5 ds in ms)" begin
    #     pm_file = joinpath(dirname(trans_path), "pglib_opf_case500_goc.m")
    #     pmd_file = joinpath(dirname(dist_path), "lvtestcase_pmd_template_138kv.dss")
    #     pmd_files = [pmd_file, pmd_file, pmd_file, pmd_file, pmd_file]
    #     pmitd_file = joinpath(dirname(bound_path), "case500_caseLV.json")
    #     pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
    #     result = solve_opfitd_decomposition(pm_file, pmd_files, pmitd_file, pmitd_type, ipopt_decomposition; auto_rename=true)
    #     # @test result["termination_status"] == LOCALLY_SOLVED
    # end

    # @testset "solve_opfitd_decomposition: Balanced case5-case3x2 ACP-ACP" begin
    #     pm_file = joinpath(dirname(trans_path), "case5_with2loads.m")
    #     pmd_file = joinpath(dirname(dist_path), "case3_balanced.dss")
    #     pmitd_file = joinpath(dirname(bound_path), "case5_case3x2.json")
    #     pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
    #     pmd_files = [pmd_file, pmd_file]
    #     result = solve_opfitd_decomposition(pm_file, pmd_files, pmitd_file, pmitd_type, ipopt_decomposition; auto_rename=true)
    #     # @test result["termination_status"] == LOCALLY_SOLVED
    # end

    # @testset "solve_opfitd_decomposition multinetwork: Balanced case5-case3x2 ACP-ACP" begin
    #     pm_file = joinpath(dirname(trans_path), "case5_with2loads.m")
    #     pmd_file1 = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen_mn.dss")
    #     pmd_files = [pmd_file1, pmd_file1]
    #     pmitd_file = joinpath(dirname(bound_path), "case5_case3x2.json")
    #     pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
    #     result = solve_mn_opfitd_decomposition(pm_file, pmd_files, pmitd_file, pmitd_type, ipopt_decomposition; auto_rename=true)
    #     # @test result["termination_status"] == LOCALLY_SOLVED
    # end

end
