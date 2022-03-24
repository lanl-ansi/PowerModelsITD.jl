@info "running integrated transmission-distribution optimal power flow with distribution minimum load delta (opfitd_dmld) tests"

@testset "test/opfitd_dmld.jl" begin

    @testset "solve_dmld_opfitd: case5-caseUT Without Dist. Generator ACP-ACP" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "ut_trans_2w_yy_138kv_nosubs.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_caseut_trans_2w.json")
        pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
        result = solve_dmld_opfitd(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt; make_si=true)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_dmld_opfitd: case5-caseUT ACP-ACP with piecewise linear terms" begin
        pm_file = joinpath(dirname(trans_path), "case5_pwlc_withload.m")
        pmd_file = joinpath(dirname(dist_path), "ut_trans_2w_yy_138kv_nosubs.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_caseut_trans_2w.json")
        pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        result = solve_dmld_opfitd(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt; make_si=true)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_dmld_opfitd: case5-caseUT Without Dist. Generator IVR-IVR - Error Not supported" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "ut_trans_2w_yy_138kv_nosubs.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_caseut_trans_2w.json")
        pmitd_type = IVRPowerModelITD{IVRPowerModel, IVRUPowerModel}
        @test_throws ErrorException solve_dmld_opfitd(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt; make_si=true)
    end

    @testset "solve_dmld_opfitd: case5-caseUT Without Dist. Generator SOCBF-LinDist3Flow" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "ut_trans_2w_yy_138kv_nosubs.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_caseut_trans_2w.json")
        pmitd_type = BFPowerModelITD{SOCBFPowerModel, LinDist3FlowPowerModel}
        result = solve_dmld_opfitd(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt; make_si=true)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_mn_dmld_opfitd_simple: Multinetwork case5-caseUT Without Dist. Generator ACP-ACP" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "ut_trans_2w_yy_138kv_nosubs_mn.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_caseut_trans_2w.json")
        pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
        result = solve_mn_dmld_opfitd_simple(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt; make_si=true)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_mn_dmld_opfitd_simple: Multinetwork case5-caseUT Without Dist. Generator SOCBF-LinDist3Flow" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "ut_trans_2w_yy_138kv_nosubs_mn.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_caseut_trans_2w.json")
        pmitd_type = BFPowerModelITD{SOCBFPowerModel, LinDist3FlowPowerModel}
        result = solve_mn_dmld_opfitd_simple(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt; make_si=true)
        @test result["termination_status"] == LOCALLY_SOLVED
    end
end
