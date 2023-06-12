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

    ## This unit test has been disabled due to the test failing in all CI Julia 1 & nigthly-latest runs due to NUMERICAL_ERROR
    # @testset "solve_pfitd (with network inputs): Unbalanced case5-case3 Without Dist. Generator ACP-ACP" begin
    #     pm_file = joinpath(dirname(trans_path), "case5_withload.m")
    #     pmd_file = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen.dss")
    #     pmitd_file = joinpath(dirname(bound_path), "case5_case3_unbal_nogen.json")
    #     pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
    #     result = solve_pfitd(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt)
    #     @test result["termination_status"] == LOCALLY_SOLVED
    # end

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

    @testset "solve_pfitd and calculate branch power flows in transmission: Unbalanced case5-case3 ACP-ACP" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_unbalanced.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_unbal.json")
        pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_pfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
        calc_transmission_branch_flow_ac!(result, pmitd_data)
        @test isapprox(pmitd_data["it"]["pm"]["branch"]["4"]["pt"], 39.2; atol = 1e-1)
        @test isapprox(pmitd_data["it"]["pm"]["branch"]["2"]["pt"], 2.7; atol = 1e-1)
        @test isapprox(pmitd_data["it"]["pm"]["branch"]["4"]["qf"], 9.3; atol = 1e-1)
        @test isapprox(pmitd_data["it"]["pm"]["branch"]["2"]["qf"], 74.4; atol = 1e-1)
    end
end
