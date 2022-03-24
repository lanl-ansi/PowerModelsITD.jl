@info "running integrated transmission-distribution optimal power flow (opfitd) tests for multinetwork (mn)"

@testset "test/opfitd_mn.jl - (multinetwork)" begin

    @testset "solve_mn_opfitd: Multinetwork case5-case3 Without Dist. Generator ACP-ACP" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen_mn.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3.json")
        pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
        result = solve_mn_opfitd(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 71260.5450; atol = 1e-4)
    end

    @testset "solve_mn_opfitd: Multinetwork case5-case3 Without Dist. Generator ACR-ACR" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen_mn.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3.json")
        pmitd_type = NLPowerModelITD{ACRPowerModel, ACRUPowerModel}
        result = solve_mn_opfitd(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 71260.5451; atol = 1e-4)
    end

    @testset "solve_mn_opfitd: Multinetwork case5-case3 Without Dist. Generator NFA-NFA" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen_mn.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3.json")
        pmitd_type = LPowerModelITD{NFAPowerModel, NFAUPowerModel}
        result = solve_mn_opfitd(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 58399.9993; atol = 1e-4)
    end


    @testset "solve_mn_opfitd: Multinetwork case5-case3 x2 Without Dist. Generator ACP-ACP" begin
        pm_file = joinpath(dirname(trans_path), "case5_with2loads.m")
        pmd_file1 = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen_mn.dss")
        pmd_files = [pmd_file1, pmd_file1]
        pmitd_file = joinpath(dirname(bound_path), "case5_case3x2.json")
        pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
        result = solve_mn_opfitd(pm_file, pmd_files, pmitd_file, pmitd_type, ipopt)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 71583.3702; atol = 1e-4)
    end

    @testset "solve_mn_opfitd: Multinetwork case5-case3 x2 Without Dist. Generator ACR-ACR" begin
        pm_file = joinpath(dirname(trans_path), "case5_with2loads.m")
        pmd_file1 = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen_mn.dss")
        pmd_files = [pmd_file1, pmd_file1]
        pmitd_file = joinpath(dirname(bound_path), "case5_case3x2.json")
        pmitd_type = NLPowerModelITD{ACRPowerModel, ACRUPowerModel}
        result = solve_mn_opfitd(pm_file, pmd_files, pmitd_file, pmitd_type, ipopt)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 71583.3702; atol = 1e-4)
    end

    @testset "solve_mn_opfitd: Multinetwork case5-case3 x2 Without Dist. Generator NFA-NFA" begin
        pm_file = joinpath(dirname(trans_path), "case5_with2loads.m")
        pmd_file1 = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen_mn.dss")
        pmd_files = [pmd_file1, pmd_file1]
        pmitd_file = joinpath(dirname(bound_path), "case5_case3x2.json")
        pmitd_type = LPowerModelITD{NFAPowerModel, NFAUPowerModel}
        result = solve_mn_opfitd(pm_file, pmd_files, pmitd_file, pmitd_type, ipopt)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 58759.9993; atol = 1e-4)
    end

    @testset "solve_mn_opfitd: Multinetwork case5-case3 Without Dist. Generator IVR-IVR" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen_mn.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3.json")
        pmitd_type = IVRPowerModelITD{IVRPowerModel, IVRUPowerModel}
        result = solve_mn_opfitd(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 71260.5453; atol = 1e-3)
    end

    @testset "solve_mn_opfitd: Multinetwork case5-case3 x2 Without Dist. Generator IVR-IVR" begin
        pm_file = joinpath(dirname(trans_path), "case5_with2loads.m")
        pmd_file1 = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen_mn.dss")
        pmd_files = [pmd_file1, pmd_file1]
        pmitd_file = joinpath(dirname(bound_path), "case5_case3x2.json")
        pmitd_type = IVRPowerModelITD{IVRPowerModel, IVRUPowerModel}
        result = solve_mn_opfitd(pm_file, pmd_files, pmitd_file, pmitd_type, ipopt)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 71583.3704; atol = 1e-4)
    end

    @testset "solve_mn_opfitd: Multinetwork case5-case3 Without Dist. Generator SOCBF-SOCNLPUBF" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced_notransformer_mn.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3.json")
        pmitd_type = BFPowerModelITD{SOCBFPowerModel, SOCNLPUBFPowerModel}
        result = solve_mn_opfitd(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 58952.6490; atol = 1e-4)
    end

    @testset "solve_mn_opfitd: Multinetwork case5-case3 x2 Without Dist. Generator SOCBF-SOCNLPUBF" begin
        pm_file = joinpath(dirname(trans_path), "case5_with2loads.m")
        pmd_file1 = joinpath(dirname(dist_path), "case3_balanced_notransformer_mn.dss")
        pmd_files = [pmd_file1, pmd_file1]
        pmitd_file = joinpath(dirname(bound_path), "case5_case3x2.json")
        pmitd_type = BFPowerModelITD{SOCBFPowerModel, SOCNLPUBFPowerModel}
        result = solve_mn_opfitd(pm_file, pmd_files, pmitd_file, pmitd_type, ipopt)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 59043.9808; atol = 1e-3)
    end

    @testset "solve_mn_opfitd: Multinetwork case5-case3 Without Dist. Generator ACR-FOTR" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen_mn.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3.json")
        pmitd_type = NLFOTPowerModelITD{ACRPowerModel, FOTRUPowerModel}
        result = solve_mn_opfitd(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 71259.6330; atol = 1e-4)
    end

    @testset "solve_mn_opfitd: Multinetwork case5-case3 Without Dist. Generator ACP-FOTP" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen_mn.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3.json")
        pmitd_type = NLFOTPowerModelITD{ACPPowerModel, FOTPUPowerModel}
        result = solve_mn_opfitd(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 71259.6194; atol = 1e-4)
    end

    @testset "solve_mn_opfitd: Multinetwork case5-case3 Without Dist. Generator SOCBF-LinDist3FlowPowerModel" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen_mn.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3.json")
        pmitd_type = BFPowerModelITD{SOCBFPowerModel, LinDist3FlowPowerModel}
        result = solve_mn_opfitd(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 59221.2594; atol = 1e-4)
    end

    @testset "solve_mn_opfitd: Multinetwork case5-case3 x2 Without Dist. Generator ACR-FOTR" begin
        pm_file = joinpath(dirname(trans_path), "case5_with2loads.m")
        pmd_file1 = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen_mn.dss")
        pmd_files = [pmd_file1, pmd_file1]
        pmitd_file = joinpath(dirname(bound_path), "case5_case3x2.json")
        pmitd_type = NLFOTPowerModelITD{ACRPowerModel, FOTRUPowerModel}
        result = solve_mn_opfitd(pm_file, pmd_files, pmitd_file, pmitd_type, ipopt)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 71581.5425; atol = 1e-4)
    end

    @testset "solve_mn_opfitd: Multinetwork case5-case3 x2 Without Dist. Generator ACP-FOTP" begin
        pm_file = joinpath(dirname(trans_path), "case5_with2loads.m")
        pmd_file1 = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen_mn.dss")
        pmd_files = [pmd_file1, pmd_file1]
        pmitd_file = joinpath(dirname(bound_path), "case5_case3x2.json")
        pmitd_type = NLFOTPowerModelITD{ACPPowerModel, FOTPUPowerModel}
        result = solve_mn_opfitd(pm_file, pmd_files, pmitd_file, pmitd_type, ipopt)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 71581.5153; atol = 1e-4)
    end

    @testset "solve_mn_opfitd: Multinetwork case5-case3 x2 Without Dist. Generator SOCBF-LinDist3FlowPowerModel" begin
        pm_file = joinpath(dirname(trans_path), "case5_with2loads.m")
        pmd_file1 = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen_mn.dss")
        pmd_files = [pmd_file1, pmd_file1]
        pmitd_file = joinpath(dirname(bound_path), "case5_case3x2.json")
        pmitd_type = BFPowerModelITD{SOCBFPowerModel, LinDist3FlowPowerModel}
        result = solve_mn_opfitd(pm_file, pmd_files, pmitd_file, pmitd_type, ipopt)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 59581.2957; atol = 1e-4)
    end

    @testset "solve_mn_opfitd: Multinetwork case5-case3 Without Dist. Generator ACR-FBS" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen_mn.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3.json")
        pmitd_type = NLBFPowerModelITD{ACRPowerModel, FBSUBFPowerModel}
        result = solve_mn_opfitd(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 71259.6179; atol = 1e-4)
    end

    @testset "solve_mn_opfitd: Multinetwork case5-case3 x2 Without Dist. Generator ACR-FBS" begin
        pm_file = joinpath(dirname(trans_path), "case5_with2loads.m")
        pmd_file1 = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen_mn.dss")
        pmd_files = [pmd_file1, pmd_file1]
        pmitd_file = joinpath(dirname(bound_path), "case5_case3x2.json")
        pmitd_type = NLBFPowerModelITD{ACRPowerModel, FBSUBFPowerModel}
        result = solve_mn_opfitd(pm_file, pmd_files, pmitd_file, pmitd_type, ipopt)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 71581.5121; atol = 1e-4)
    end
end
