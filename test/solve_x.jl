@info "running ITD solve x - parsing first tests"

@testset "test/solve_x.jl" begin

    @testset "solve pfitd" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_unbalanced.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_unbal.json")
        pmitd_type = NLPowerModelITD{ACRPowerModel, ACRUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        result = solve_pfitd(pmitd_data, pmitd_type, ipopt)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve opfitd" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_unbalanced.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_unbal.json")
        pmitd_type = NLPowerModelITD{ACRPowerModel, ACRUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        result = solve_opfitd(pmitd_data, pmitd_type, ipopt)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve opfitd oltc" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced_oltc.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_bal_oltc.json")
        pmitd_type = NLPowerModelITD{ACRPowerModel, ACRUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        result = solve_opfitd_oltc(pmitd_data, pmitd_type, ipopt)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve opfitd dmld" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "ut_trans_2w_yy_138kv_nosubs.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_caseut_trans_2w.json")
        pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        result = solve_dmld_opfitd(pmitd_data, pmitd_type, ipopt)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve opfitd multinetwork" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen_mn.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_unbal_nogen_mn.json")
        pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file; multinetwork=true)
        result = solve_mn_opfitd(pmitd_data, pmitd_type, ipopt)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve opfitd oltc multinetwork" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced_oltc_mn.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_bal_oltc_mn.json")
        pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file; multinetwork=true)
        result = solve_mn_opfitd(pmitd_data, pmitd_type, ipopt)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve opfitd dmld multinetwork" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "ut_trans_2w_yy_138kv_nosubs_mn.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_caseut_trans_2w_mn.json")
        pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file; multinetwork=true)
        result = solve_mn_dmld_opfitd_simple(pmitd_data, pmitd_type, ipopt; make_si=true)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve opfitd multinetwork multisystem" begin
        pm_file = joinpath(dirname(trans_path), "case5_with2loads.m")
        pmd_file = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen_mn.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_unbal_nogen_mn.json")
        pmd_files = [pmd_file, pmd_file]
        pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_files, pmitd_file; auto_rename=true, multinetwork=true)
        result = solve_mn_opfitd(pmitd_data, pmitd_type, ipopt)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

end
