@info "running integrated transmission-distribution power flow (pfitd) tests for multi-systems (ms)"

@testset "test/pfitd_ms.jl - (multi-systems)" begin

    @testset "solve_model pfitd (with network inputs): Multi-System Unbalanced case5-case3x2 Without Dist. Generator ACR-ACR" begin
        pm_file = joinpath(dirname(trans_path), "case5_with2loads.m")
        pmd_file1 = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen.dss")
        pmd_file2 = joinpath(dirname(dist_path), "case3_balanced_withoutgen.dss")
        pmd_files = [pmd_file1, pmd_file2]
        pmitd_file = joinpath(dirname(bound_path), "case5_case3x2_unbal_bal_nogen.json")
        pmitd_type = NLPowerModelITD{ACRPowerModel, ACRUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_files, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_pfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_model pfitd (with network inputs): Multi-System Unbalanced case5-case3x2 Without Dist. Generator ACP-ACP" begin
        pm_file = joinpath(dirname(trans_path), "case5_with2loads.m")
        pmd_file1 = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen.dss")
        pmd_file2 = joinpath(dirname(dist_path), "case3_balanced_withoutgen.dss")
        pmd_files = [pmd_file1, pmd_file2]
        pmitd_file = joinpath(dirname(bound_path), "case5_case3x2_unbal_bal_nogen.json")
        pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_files, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_pfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_model pfitd (with network inputs): Multi-System Unbalanced case5-case3x2 Without Dist. Generator IVR-IVR" begin
        pm_file = joinpath(dirname(trans_path), "case5_with2loads.m")
        pmd_file1 = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen.dss")
        pmd_file2 = joinpath(dirname(dist_path), "case3_balanced_withoutgen.dss")
        pmd_files = [pmd_file1, pmd_file2]
        pmitd_file = joinpath(dirname(bound_path), "case5_case3x2_unbal_bal_nogen.json")
        pmitd_type = IVRPowerModelITD{IVRPowerModel, IVRUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_files, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_pfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_model pfitd (with network inputs): Multi-System Unbalanced case5-case3x2 Without Dist. Generator SOCBF-SOCNLPUB" begin
        pm_file = joinpath(dirname(trans_path), "case5_with2loads.m")
        pmd_file1 = joinpath(dirname(dist_path), "case3_unbalanced_notransformer.dss")
        pmd_file2 = joinpath(dirname(dist_path), "case3_balanced_notransformer.dss")
        pmd_files = [pmd_file1, pmd_file2]
        pmitd_file = joinpath(dirname(bound_path), "case5_case3x2_unbal_bal_notrans.json")
        pmitd_type = BFPowerModelITD{SOCBFPowerModel, SOCNLPUBFPowerModel}
        pmitd_data = parse_files(pm_file, pmd_files, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_pfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
    end
end
