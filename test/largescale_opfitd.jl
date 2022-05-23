@info "running integrated transmission-distribution optimal power flow (opfitd) tests for large-scale multi-systems (ms)"

@testset "test/largescale_opfitd.jl - (large-scale multi-systems)" begin

    @testset "solve_model opfitd (with network inputs): Multi-System case500-case30 (6 ds in ms) ACR-ACR" begin
        pm_file = joinpath(dirname(trans_path), "pglib_opf_case500_goc.m")
        pmd_file1 = joinpath(dirname(dist_path), "case30_138kv.dss")
        pmd_files = [pmd_file1, pmd_file1, pmd_file1, pmd_file1, pmd_file1, pmd_file1]
        pmitd_file = joinpath(dirname(bound_path), "case500_case30.json")
        pmitd_type = NLPowerModelITD{ACRPowerModel, ACRUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_files, pmitd_file; auto_rename=true)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_model opfitd (with network inputs): Multi-System case500-case30 (6 ds in ms) ACP-ACP" begin
        pm_file = joinpath(dirname(trans_path), "pglib_opf_case500_goc.m")
        pmd_file1 = joinpath(dirname(dist_path), "case30_138kv.dss")
        pmd_files = [pmd_file1, pmd_file1, pmd_file1, pmd_file1, pmd_file1, pmd_file1]
        pmitd_file = joinpath(dirname(bound_path), "case500_case30.json")
        pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_files, pmitd_file; auto_rename=true)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_model opfitd (with network inputs): Multi-System case500-case30 (6 ds in ms) IVR-IVR" begin
        pm_file = joinpath(dirname(trans_path), "pglib_opf_case500_goc.m")
        pmd_file1 = joinpath(dirname(dist_path), "case30_138kv.dss")
        pmd_files = [pmd_file1, pmd_file1, pmd_file1, pmd_file1, pmd_file1, pmd_file1]
        pmitd_file = joinpath(dirname(bound_path), "case500_case30.json")
        pmitd_type = IVRPowerModelITD{IVRPowerModel, IVRUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_files, pmitd_file; auto_rename=true)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_model opfitd (with network inputs): Multi-System case500-case30 (6 ds in ms) NFA-NFA" begin
        pm_file = joinpath(dirname(trans_path), "pglib_opf_case500_goc.m")
        pmd_file1 = joinpath(dirname(dist_path), "case30_138kv.dss")
        pmd_files = [pmd_file1, pmd_file1, pmd_file1, pmd_file1, pmd_file1, pmd_file1]
        pmitd_file = joinpath(dirname(bound_path), "case500_case30.json")
        pmitd_type = LPowerModelITD{NFAPowerModel, NFAUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_files, pmitd_file; auto_rename=true)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_model opfitd (with network inputs): Multi-System case500-case34 (5 ds in ms) ACR-ACR" begin
        pm_file = joinpath(dirname(trans_path), "pglib_opf_case500_goc.m")
        pmd_file1 = joinpath(dirname(dist_path), "caseieee34bus_138kv.dss")
        pmd_files = [pmd_file1, pmd_file1, pmd_file1, pmd_file1, pmd_file1]
        pmitd_file = joinpath(dirname(bound_path), "case500_case34.json")
        pmitd_type = NLPowerModelITD{ACRPowerModel, ACRUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_files, pmitd_file; auto_rename=true)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_model opfitd (with network inputs): Multi-System case500-case34 (5 ds in ms) IVR-IVR" begin
        pm_file = joinpath(dirname(trans_path), "pglib_opf_case500_goc.m")
        pmd_file1 = joinpath(dirname(dist_path), "caseieee34bus_138kv.dss")
        pmd_files = [pmd_file1, pmd_file1, pmd_file1, pmd_file1, pmd_file1]
        pmitd_file = joinpath(dirname(bound_path), "case500_case34.json")
        pmitd_type = IVRPowerModelITD{IVRPowerModel, IVRUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_files, pmitd_file; auto_rename=true)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_model opfitd (with network inputs): Multi-System case500-case34 (5 ds in ms) NFA-NFA" begin
        pm_file = joinpath(dirname(trans_path), "pglib_opf_case500_goc.m")
        pmd_file1 = joinpath(dirname(dist_path), "caseieee34bus_138kv.dss")
        pmd_files = [pmd_file1, pmd_file1, pmd_file1, pmd_file1, pmd_file1]
        pmitd_file = joinpath(dirname(bound_path), "case500_case34.json")
        pmitd_type = LPowerModelITD{NFAPowerModel, NFAUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_files, pmitd_file; auto_rename=true)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    ## This unit test has been disabled due to the test failing in CI nightly windows-latest run (ipopt memory fail: Problem with integer stack size).
    # @testset "solve_model opfitd (with network inputs): Multi-System case500-caseLV (5 ds in ms) ACP-ACP" begin
    #     pm_file = joinpath(dirname(trans_path), "pglib_opf_case500_goc.m")
    #     pmd_file1 = joinpath(dirname(dist_path), "lvtestcase_pmd_template_138kv.dss")
    #     pmd_files = [pmd_file1, pmd_file1, pmd_file1, pmd_file1, pmd_file1]
    #     pmitd_file = joinpath(dirname(bound_path), "case500_caseLV.json")
    #     pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
    #     pmitd_data = parse_files(pm_file, pmd_files, pmitd_file; auto_rename=true)
    #     result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd)
    #     @test result["termination_status"] == LOCALLY_SOLVED
    # end

    @testset "solve_model opfitd (with network inputs): Multi-System case500-caseLV (5 ds in ms) NFA-NFA" begin
        pm_file = joinpath(dirname(trans_path), "pglib_opf_case500_goc.m")
        pmd_file1 = joinpath(dirname(dist_path), "lvtestcase_pmd_template_138kv.dss")
        pmd_files = [pmd_file1, pmd_file1, pmd_file1, pmd_file1, pmd_file1]
        pmitd_file = joinpath(dirname(bound_path), "case500_caseLV.json")
        pmitd_type = LPowerModelITD{NFAPowerModel, NFAUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_files, pmitd_file; auto_rename=true)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
    end
end
