@info "running integrated transmission-distribution optimal power flow (opfitd) for Hybrid formulations tests"

@testset "test/opfitd_hybrids.jl" begin

    @testset "solve_model (with network inputs): Unbalanced case5-case3 Without Dist. Generator ACR-FBS" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_unbal_nogen.json")
        pmitd_type = NLBFPowerModelITD{ACRPowerModel, FBSUBFPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_model (with network inputs): Unbalanced case5-case3 Without Dist. Generator ACR-FOTR" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_unbal_nogen.json")
        pmitd_type = NLFOTPowerModelITD{ACRPowerModel, FOTRUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_model (with network inputs): Unbalanced case5-case3 Without Dist. Generator ACP-FOTP" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_unbal_nogen.json")
        pmitd_type = NLFOTPowerModelITD{ACPPowerModel, FOTPUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_model (with network inputs): Unbalanced case5-case3 Without Dist. Generator SOCBF-LinDist3FlowPowerModel" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_unbal_nogen.json")
        pmitd_type = BFPowerModelITD{SOCBFPowerModel, LinDist3FlowPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_model (with network inputs): Unbalanced case5-case3 Without Dist. Generator BFA-LinDist3FlowPowerModel" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_unbal_nogen.json")
        pmitd_type = BFPowerModelITD{BFAPowerModel, LinDist3FlowPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_model (with network inputs): Balanced case5-case3 Without Dist. Generator SOCWRConic-SOCConicUBF" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced_notransformer_withoutgen.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_bal_notrans_nogen.json")
        pmitd_type = WRBFPowerModelITD{SOCWRConicPowerModel, SOCConicUBFPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, scs_solver, build_opfitd)
        @test result["termination_status"] == OPTIMAL
    end

    @testset "solve_model (with network inputs): Balanced case5-case3 Without Dist. Generator SDPWRM-SOCConicUBF" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced_notransformer_withoutgen.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_bal_notrans_nogen.json")
        pmitd_type = WRBFPowerModelITD{SDPWRMPowerModel, SOCConicUBFPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, scs_solver, build_opfitd)
        @test result["termination_status"] == OPTIMAL || result["termination_status"] == ALMOST_OPTIMAL
    end
end
