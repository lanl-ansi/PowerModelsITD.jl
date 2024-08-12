@info "running integrated transmission-distribution power flow (pfitd) tests for multinetwork (mn)"

@testset "test/pfitd_mn.jl - (multinetwork)" begin

    @testset "solve_mn_pfitd: Multinetwork case5-case3 Without Dist. Generator ACP-ACP" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen_mn.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_unbal_nogen_mn.json")
        pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
        result = solve_mn_pfitd(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_mn_pfitd: Multinetwork case5-case3 Without Dist. Generator ACR-ACR" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen_mn.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_unbal_nogen_mn.json")
        pmitd_type = NLPowerModelITD{ACRPowerModel, ACRUPowerModel}
        result = solve_mn_pfitd(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_mn_pfitd: Multinetwork case5-case3 x2 Without Dist. Generator ACP-ACP" begin
        pm_file = joinpath(dirname(trans_path), "case5_with2loads.m")
        pmd_file1 = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen_mn.dss")
        pmd_files = [pmd_file1, pmd_file1]
        pmitd_file = joinpath(dirname(bound_path), "case5_case3x2.json")
        pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
        result = solve_mn_pfitd(pm_file, pmd_files, pmitd_file, pmitd_type, ipopt; auto_rename=true)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_mn_pfitd: Multinetwork case5-case3 x2 Without Dist. Generator ACR-ACR" begin
        pm_file = joinpath(dirname(trans_path), "case5_with2loads.m")
        pmd_file1 = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen_mn.dss")
        pmd_files = [pmd_file1, pmd_file1]
        pmitd_file = joinpath(dirname(bound_path), "case5_case3x2.json")
        pmitd_type = NLPowerModelITD{ACRPowerModel, ACRUPowerModel}
        result = solve_mn_pfitd(pm_file, pmd_files, pmitd_file, pmitd_type, ipopt; auto_rename=true)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_mn_pfitd: Multinetwork case5-case3 Without Dist. Generator IVR-IVR" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen_mn.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_unbal_nogen_mn.json")
        pmitd_type = IVRPowerModelITD{IVRPowerModel, IVRUPowerModel}
        result = solve_mn_pfitd(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_mn_pfitd: Multinetwork case5-case3 x2 Without Dist. Generator IVR-IVR" begin
        pm_file = joinpath(dirname(trans_path), "case5_with2loads.m")
        pmd_file1 = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen_mn.dss")
        pmd_files = [pmd_file1, pmd_file1]
        pmitd_file = joinpath(dirname(bound_path), "case5_case3x2.json")
        pmitd_type = IVRPowerModelITD{IVRPowerModel, IVRUPowerModel}
        result = solve_mn_pfitd(pm_file, pmd_files, pmitd_file, pmitd_type, ipopt; auto_rename=true)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_mn_pfitd: Multinetwork case5-case3 Without Dist. Generator SOCBF-SOCNLPUBF" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced_notransformer_mn.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_bal_notrans_mn.json")
        pmitd_type = BFPowerModelITD{SOCBFPowerModel, SOCNLPUBFPowerModel}
        result = solve_mn_pfitd(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_mn_pfitd: Multinetwork case5-case3 x2 Without Dist. Generator SOCBF-SOCNLPUBF" begin
        pm_file = joinpath(dirname(trans_path), "case5_with2loads.m")
        pmd_file1 = joinpath(dirname(dist_path), "case3_balanced_notransformer_mn.dss")
        pmd_files = [pmd_file1, pmd_file1]
        pmitd_file = joinpath(dirname(bound_path), "case5_case3x2.json")
        pmitd_type = BFPowerModelITD{SOCBFPowerModel, SOCNLPUBFPowerModel}
        result = solve_mn_pfitd(pm_file, pmd_files, pmitd_file, pmitd_type, ipopt; auto_rename=true)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_mn_pfitd: Multinetwork case5-case3 Without Dist. Generator ACR-FOTR" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen_mn.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_unbal_nogen_mn.json")
        pmitd_type = NLFOTPowerModelITD{ACRPowerModel, FOTRUPowerModel}
        result = solve_mn_pfitd(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_mn_pfitd: Multinetwork case5-case3 Without Dist. Generator ACP-FOTP" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen_mn.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_unbal_nogen_mn.json")
        pmitd_type = NLFOTPowerModelITD{ACPPowerModel, FOTPUPowerModel}
        result = solve_mn_pfitd(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_mn_pfitd: Multinetwork case5-case3 Without Dist. Generator SOCBF-LinDist3FlowPowerModel" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen_mn.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_unbal_nogen_mn.json")
        pmitd_type = BFPowerModelITD{SOCBFPowerModel, LinDist3FlowPowerModel}
        result = solve_mn_pfitd(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_mn_pfitd: Multinetwork case5-case3 x2 Without Dist. Generator ACR-FOTR" begin
        pm_file = joinpath(dirname(trans_path), "case5_with2loads.m")
        pmd_file1 = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen_mn.dss")
        pmd_files = [pmd_file1, pmd_file1]
        pmitd_file = joinpath(dirname(bound_path), "case5_case3x2.json")
        pmitd_type = NLFOTPowerModelITD{ACRPowerModel, FOTRUPowerModel}
        result = solve_mn_pfitd(pm_file, pmd_files, pmitd_file, pmitd_type, ipopt; auto_rename=true)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_mn_pfitd: Multinetwork case5-case3 x2 Without Dist. Generator ACP-FOTP" begin
        pm_file = joinpath(dirname(trans_path), "case5_with2loads.m")
        pmd_file1 = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen_mn.dss")
        pmd_files = [pmd_file1, pmd_file1]
        pmitd_file = joinpath(dirname(bound_path), "case5_case3x2.json")
        pmitd_type = NLFOTPowerModelITD{ACPPowerModel, FOTPUPowerModel}
        result = solve_mn_pfitd(pm_file, pmd_files, pmitd_file, pmitd_type, ipopt; auto_rename=true)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_mn_pfitd: Multinetwork case5-case3 Without Dist. Generator ACR-FBS" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen_mn.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_unbal_nogen_mn.json")
        pmitd_type = NLBFPowerModelITD{ACRPowerModel, FBSUBFPowerModel}
        result = solve_mn_pfitd(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_mn_pfitd: Multinetwork case5-case3 x2 Without Dist. Generator ACR-FBS" begin
        pm_file = joinpath(dirname(trans_path), "case5_with2loads.m")
        pmd_file1 = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen_mn.dss")
        pmd_files = [pmd_file1, pmd_file1]
        pmitd_file = joinpath(dirname(bound_path), "case5_case3x2.json")
        pmitd_type = NLBFPowerModelITD{ACRPowerModel, FBSUBFPowerModel}
        result = solve_mn_pfitd(pm_file, pmd_files, pmitd_file, pmitd_type, ipopt; auto_rename=true)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_mn_pfitd: Multinetwork case5-case3 Without Dist. Generator ACP-ACP diff. loading" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen_mn_diff.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_unbal_nogen_mn_diff.json")
        pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
        result = solve_mn_pfitd(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt)
        @test result["termination_status"] == LOCALLY_SOLVED
    end
end
