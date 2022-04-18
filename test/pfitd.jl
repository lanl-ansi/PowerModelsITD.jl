@info "running integrated transmission-distribution power flow (pfitd) tests"

@testset "test/pfitd.jl" begin

    @testset "solve_pfitd (with network inputs): Unbalanced case5-case3 ACR-ACR" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_unbalanced.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_unbal.json")
        pmitd_type = NLPowerModelITD{ACRPowerModel, ACRUPowerModel}
        result = solve_pfitd(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_pfitd (with network inputs): Unbalanced case5-case3 Without Dist. Generator ACR-ACR" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_unbal_nogen.json")
        pmitd_type = NLPowerModelITD{ACRPowerModel, ACRUPowerModel}
        result = solve_pfitd(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_pfitd (with network inputs): Unbalanced case5-case3 ACP-ACP" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_unbalanced.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_unbal.json")
        pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
        result = solve_pfitd(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_pfitd (with network inputs): Unbalanced case5-case3 Without Dist. Generator ACP-ACP" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_unbal_nogen.json")
        pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
        result = solve_pfitd(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_pfitd (with network inputs): Unbalanced case5-case3 Without Dist. Generator IVR-IVR" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_unbal_nogen.json")
        pmitd_type = IVRPowerModelITD{IVRPowerModel, IVRUPowerModel}
        result = solve_pfitd(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt)
        @test result["termination_status"] == LOCALLY_SOLVED
    end


    @testset "solve_pfitd (with network inputs): Unbalanced case5-case3 Without Dist. Generator IVR-IVR" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_unbal_nogen.json")
        pmitd_type = IVRPowerModelITD{IVRPowerModel, IVRUPowerModel}
        result = solve_pfitd(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    ## This unit test has been disabled due to the test failing in all CI macOS-latest runs (only macOS-latest)
    # @testset "solve_pfitd (with network inputs): Unbalanced case5-case13 Without Dist. Generator IVR-IVR" begin
    #     pm_file = joinpath(dirname(trans_path), "case5_withload_ieee13.m")
    #     pmd_file = joinpath(dirname(dist_path), "caseIEEE13_unbalanced_withoutgen.dss")
    #     pmitd_file = joinpath(dirname(bound_path), "case5_case13_unbal_nogen.json")
    #     pmitd_type = IVRPowerModelITD{IVRPowerModel, IVRUPowerModel}
    #     result = solve_pfitd(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt)
    #     @test result["termination_status"] == LOCALLY_SOLVED
    # end


    @testset "solve_pfitd (with network inputs): Unbalanced case5-case3 With Dist. Generator SOCBF-SOCNLPUBF" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_unbalanced_notransformer.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_unbal_notrans.json")
        pmitd_type = BFPowerModelITD{SOCBFPowerModel, SOCNLPUBFPowerModel}
        result = solve_pfitd(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_pfitd (with network inputs): Unbalanced case5-case3 Without Dist. Generator SOCBF-SOCNLPUBF" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_unbalanced_notransformer_withoutgen.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_unbal_notrans_nogen.json")
        pmitd_type = BFPowerModelITD{SOCBFPowerModel, SOCNLPUBFPowerModel}
        result = solve_pfitd(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt)
        @test result["termination_status"] == LOCALLY_SOLVED
    end
end
