@info "running base.jl function tests with balanced test systems (instantiate_model + solve_model functions)"

@testset "src/core/base.jl" begin
    pm_file = joinpath(dirname(trans_path), "case5_withload.m")
    pmd_file = joinpath(dirname(dist_path), "case3_balanced.dss")
    pmitd_file = joinpath(dirname(bound_path), "case5_case3.json")

    @testset "instantiate_model (with file inputs)" begin
        pmitd_type = NLPowerModelITD{ACRPowerModel, ACRUPowerModel}
        pmitd = instantiate_model(pm_file, pmd_file, pmitd_file, pmitd_type, build_opfitd)
        @test haskey(pmitd.data["it"], "pmitd") == true
        @test haskey(pmitd.data["it"], _PM.pm_it_name) == true
        @test haskey(pmitd.data["it"], _PMD.pmd_it_name) == true
    end

    @testset "instantiate_model (with network inputs)" begin
        pmitd_type = NLPowerModelITD{ACRPowerModel, ACRUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        pmitd = instantiate_model(pmitd_data, pmitd_type, build_opfitd)
        @test haskey(pmitd.data["it"], "pmitd") == true
        @test haskey(pmitd.data["it"], _PM.pm_it_name) == true
        @test haskey(pmitd.data["it"], _PMD.pmd_it_name) == true
    end

    @testset "solve_model (with file inputs): Balanced case5-case3 ACR-ACR" begin
        pmitd_type = NLPowerModelITD{ACRPowerModel, ACRUPowerModel}
        result = solve_model(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt, build_opfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_model (with network inputs): Balanced case5-case3 ACR-ACR" begin
        pmitd_type = NLPowerModelITD{ACRPowerModel, ACRUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
    end
end
