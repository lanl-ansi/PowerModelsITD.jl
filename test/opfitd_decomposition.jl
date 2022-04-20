@info "running integrated transmission-distribution optimal power flow (opfitd) tests"

@testset "test/opfitd.jl" begin

    @testset "solve_model (with network inputs): Balanced case5-case3 ACP-ACP" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_bal.json")
        pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        # result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd)
        # result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd_decomposition)
        result = solve_opfitd_decomposition(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt)
        # @test result["termination_status"] == LOCALLY_SOLVED
    end

end
