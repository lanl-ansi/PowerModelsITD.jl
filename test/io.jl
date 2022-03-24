@info "running common.jl function tests (parse files functions)"

@testset "src/io/common.jl" begin

    @testset "parse_json" begin
        pmitd_file = joinpath(dirname(bound_path), "case5_case3.json")
        pitd_data = parse_link_file(pmitd_file)
        @test pitd_data["it"]["pmitd"][string(BOUNDARY_NUMBER)]["transmission_boundary"] == "5"
        @test pitd_data["it"]["pmitd"][string(BOUNDARY_NUMBER)]["distribution_boundary"] == "source"
    end

    @testset "parse_files (.m, .dss, .json)" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3.json")

        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        @test haskey(pmitd_data, "multiinfrastructure")
        @test pmitd_data["multiinfrastructure"] == true
        @test haskey(pmitd_data["it"], "pmitd")
        @test haskey(pmitd_data["it"], _PM.pm_it_name)
        @test haskey(pmitd_data["it"], _PMD.pmd_it_name)
    end


    @testset "parse_link_file (invalid extension)" begin
        path = joinpath(dirname(dist_path), "case3_balanced.raw")
        @test_throws ErrorException parse_link_file(path)
    end

    @testset "parse_power_transmission_file (invalid extension)" begin
        path = joinpath(dirname(dist_path), "case_wrong_extension.txt")
        @test_throws ErrorException parse_power_transmission_file(path)
    end

    @testset "parse_power_distribution_file (invalid extension)" begin
        path = joinpath(dirname(dist_path), "case3_balanced.raw")
        @test_throws ErrorException parse_power_distribution_file(path)
    end
end
