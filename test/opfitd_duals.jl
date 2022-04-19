@info "running integrated transmission-distribution optimal power flow (opfitd) tests with duals given in the solution"

@testset "test/opfitd_duals.jl" begin

    @testset "solve_model (with network inputs) with duals: Balanced case5-case3 Without Dist. Generator ACR-ACR" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced_withoutgen.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_bal_nogen.json")
        pmitd_type = NLPowerModelITD{ACRPowerModel, ACRUPowerModel}
        # add settings to IM structure
        settings = Dict("output" => Dict("duals" => true))
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd; setting=settings)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 17978.85605; atol = 1e-4)
        @test isapprox(result["solution"]["it"]["pmitd"]["bus"]["5"]["lam_kcl_r"], -2672.52660; atol = 1e-4)
    end

    @testset "solve_opfitd with duals: Unbalanced case5-case3 ACP-ACP" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_unbalanced.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_unbal.json")
        pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
        # add settings to IM structure
        settings = Dict("output" => Dict("duals" => true))
        result = solve_opfitd(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt; setting=settings)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 17953.7465; atol = 1e-4)
        @test isapprox(result["solution"]["it"]["pmitd"]["bus"]["5"]["lam_kcl_r"], -2672.26032; atol = 1e-4)
    end

    @testset "solve_opfitd with duals: Multi-System Balanced case5-case3x2 With Switch ACP-ACP" begin
        pm_file = joinpath(dirname(trans_path), "case5_with2loads.m")
        pmd_file1 = joinpath(dirname(dist_path), "case3_balanced_withSwitch.dss")
        pmd_file2 = joinpath(dirname(dist_path), "case3_balanced_withSwitch.dss")
        pmd_files = [pmd_file1, pmd_file2]
        pmitd_file = joinpath(dirname(bound_path), "case5_case3x2_bal_switch.json")
        pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
        # add settings to IM structure
        settings = Dict("output" => Dict("duals" => true))
        result = solve_opfitd(pm_file, pmd_files, pmitd_file, pmitd_type, ipopt; setting=settings, auto_rename=true)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["solution"]["it"]["pmitd"]["bus"]["5"]["lam_kcl_r"], -2674.82812; atol = 1e-4)
        @test isapprox(result["solution"]["it"]["pmitd"]["bus"]["6"]["lam_kcl_r"], -2676.75099; atol = 1e-4)
    end
end
