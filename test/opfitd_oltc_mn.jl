@info "running integrated transmission-distribution optimal power flow on-load tap changer (opfitd_oltc) for multinetwork tests"

@testset "test/opfitd_mn_oltc.jl" begin

    @testset "solve_mn_opfitd_oltc: Multinetwork case5-case3 Without Dist. Generator ACP-ACP - OLTC Problem" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced_oltc_mn.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3.json")
        pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
        result = solve_mn_opfitd_oltc(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 71022.1704; atol = 1e-4)
    end

    @testset "solve_mn_opfitd_oltc: Multinetwork case5-case3 Without Dist. Generator ACR-ACR - OLTC Problem" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced_oltc_mn.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3.json")
        pmitd_type = NLPowerModelITD{ACRPowerModel, ACRUPowerModel}
        result = solve_mn_opfitd_oltc(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 71022.1704; atol = 1e-4)
    end

     @testset "solve_mn_opfitd_oltc: Balanced case5-case3 ACR-FOTR - OLTC Problem" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced_oltc_mn.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3.json")
        pmitd_type = NLFOTPowerModelITD{ACRPowerModel, FOTRUPowerModel}
        result = solve_mn_opfitd_oltc(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 71022.0195; atol = 1e-4)
    end

    @testset "solve_mn_opfitd_oltc: Balanced case5-case3 ACP-FOTP - OLTC Problem" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced_oltc_mn.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3.json")
        pmitd_type = NLFOTPowerModelITD{ACPPowerModel, FOTPUPowerModel}
        result = solve_mn_opfitd_oltc(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 71022.0063; atol = 1e-4)
    end

    @testset "solve_mn_opfitd_oltc: Balanced case5-case3 SOCBF-LinDist3FlowPowerModel - OLTC Problem" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced_oltc_mn.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3.json")
        pmitd_type = BFPowerModelITD{SOCBFPowerModel, LinDist3FlowPowerModel}
        result = solve_mn_opfitd_oltc(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 58953.3914; atol = 1e-4)
    end

    @testset "solve_mn_opfitd_oltc: Balanced case5-case3 ACR-FBS - OLTC Problem" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced_oltc_mn.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3.json")
        pmitd_type = NLBFPowerModelITD{ACRPowerModel, FBSUBFPowerModel}
        result = solve_mn_opfitd_oltc(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 71022.0068; atol = 1e-4)
    end
end
