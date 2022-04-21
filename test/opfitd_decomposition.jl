@info "running integrated transmission-distribution optimal power flow (opfitd) tests"

@testset "test/opfitd.jl" begin

    @testset "solve_model (decomposition): Balanced case5-case3x2 ACP-ACP" begin
        pm_file = joinpath(dirname(trans_path), "case5_with2loads.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3x2.json")
        pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
        pmd_files = [pmd_file, pmd_file]
        pmitd_data = parse_files(pm_file, pmd_files, pmitd_file; auto_rename=true)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd_decomposition)
        # @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_opfitd_decomposition: Balanced case5-case3x2 ACP-ACP" begin
        pm_file = joinpath(dirname(trans_path), "case5_with2loads.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3x2.json")
        pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
        pmd_files = [pmd_file, pmd_file]
        result = solve_opfitd_decomposition(pm_file, pmd_files, pmitd_file, pmitd_type, ipopt; auto_rename=true)
        # @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_opfitd_decomposition multinetwork: Balanced case5-case3x2 ACP-ACP" begin
        pm_file = joinpath(dirname(trans_path), "case5_with2loads.m")
        pmd_file1 = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen_mn.dss")
        pmd_files = [pmd_file1, pmd_file1]
        pmitd_file = joinpath(dirname(bound_path), "case5_case3x2.json")
        pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
        result = solve_mn_opfitd_decomposition(pm_file, pmd_files, pmitd_file, pmitd_type, ipopt; auto_rename=true)
        # @test result["termination_status"] == LOCALLY_SOLVED
    end

end
