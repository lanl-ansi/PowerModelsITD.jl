using PowerModelsITD
using Test

@testset "Matlab File Parsing" begin
    pm_file = joinpath(dirname(trans_path), "case5_withload.m")
    pmd_files = joinpath(dirname(dist_path), "case3_balanced_withoutgen.m")
    boundary_file = joinpath(dirname(bound_path), "case5_case3_bal_nogen.json") 

    data = PowerModelsITD.parse_files(pm_file, pmd_files, boundary_file)

    @test haskey(data["it"], "pm")
end