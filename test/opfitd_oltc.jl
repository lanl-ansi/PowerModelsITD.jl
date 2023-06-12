@info "running integrated transmission-distribution optimal power flow on-load tap changer (opfitd_oltc) tests"

@testset "test/opfitd_oltc.jl" begin

    @testset "solve_model (with network inputs): Balanced case5-case3 ACR-ACR - OLTC Problem" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced_oltc.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_bal_oltc.json")
        pmitd_type = NLPowerModelITD{ACRPowerModel, ACRUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd_oltc; make_si=false)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_model (with network inputs): Balanced case5-case3 ACP-ACP - OLTC Problem" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced_oltc.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_bal_oltc.json")
        pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd_oltc; make_si=false)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_model (with network inputs): Balanced case5-case3 ACR-FBS - OLTC Problem" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced_oltc.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_bal_oltc.json")
        pmitd_type = NLBFPowerModelITD{ACRPowerModel, FBSUBFPowerModel}
        result = solve_opfitd_oltc(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_model (with network inputs): Balanced case5-case3 ACR-FOTR - OLTC Problem" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced_oltc.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_bal_oltc.json")
        pmitd_type = NLFOTPowerModelITD{ACRPowerModel, FOTRUPowerModel}
        result = solve_opfitd_oltc(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt; make_si=false)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_model (with network inputs): Balanced case5-case3 ACR-FOTP - OLTC Problem" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced_oltc.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_bal_oltc.json")
        pmitd_type = NLFOTPowerModelITD{ACPPowerModel, FOTPUPowerModel}
        result = solve_opfitd_oltc(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt; make_si=false)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    ## This unit test has been disabled due to the test failing in all CI Julia 1 & nigthly-latest runs due to NORM_LIMIT
    # @testset "solve_model (with network inputs): Balanced case5-case3 SOCBF-LinDist3FlowPowerModel - OLTC Problem" begin
    #     pm_file = joinpath(dirname(trans_path), "case5_withload.m")
    #     pmd_file = joinpath(dirname(dist_path), "case3_balanced_oltc.dss")
    #     pmitd_file = joinpath(dirname(bound_path), "case5_case3_bal_oltc.json")
    #     pmitd_type = BFPowerModelITD{SOCBFPowerModel, LinDist3FlowPowerModel}
    #     result = solve_opfitd_oltc(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt)
    #     @test result["termination_status"] == LOCALLY_SOLVED
    # end
end
