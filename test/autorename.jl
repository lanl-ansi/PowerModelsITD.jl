@info "running autorename tests that must throw errors."

@testset "test/autorename.jl" begin

    @testset "test: auto_rename=false and no explicit distribution ckt name is given in JSON file. " begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced_withoutgen.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3x2.json")
        pmd_files = [pmd_file, pmd_file]
        pmitd_type = NLPowerModelITD{ACRPowerModel, ACRUPowerModel}
        @test_throws ErrorException pmitd_data = parse_files(pm_file, pmd_files, pmitd_file)
    end

    @testset "test: auto_rename=false and same distribution ckt name is given in JSON file. " begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced_withoutgen.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3x2_samename.json")
        pmd_files = [pmd_file, pmd_file]
        pmitd_type = NLPowerModelITD{ACRPowerModel, ACRUPowerModel}
        @test_throws ErrorException pmitd_data = parse_files(pm_file, pmd_files, pmitd_file)
    end

    @testset "test: auto_rename=false and two distribution ckt names are the same in the given JSON file. " begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file1 = joinpath(dirname(dist_path), "case3_balanced_withoutgen.dss")
        pmd_file2 = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen.dss")
        pmd_file3 = joinpath(dirname(dist_path), "case3_balanced_withoutgen.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3x3_samename.json")
        pmd_files = [pmd_file1, pmd_file2, pmd_file3]
        pmitd_type = NLPowerModelITD{ACRPowerModel, ACRUPowerModel}
        @test_throws ErrorException pmitd_data = parse_files(pm_file, pmd_files, pmitd_file)
    end

    @testset "test: auto_rename=true and a wrong format (longer) for the distribution ckt name is given in the JSON file. " begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file1 = joinpath(dirname(dist_path), "case3_balanced_withoutgen.dss")
        pmd_file2 = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3x2_wrongformat_long.json")
        pmitd_type = NLPowerModelITD{ACRPowerModel, ACRUPowerModel}
        pmd_files = [pmd_file1, pmd_file2]
        @test_throws ErrorException pmitd_data = parse_files(pm_file, pmd_files, pmitd_file; auto_rename=true)
    end

    @testset "test: auto_rename=true and a wrong format (shorter) for the distribution ckt name is given in the JSON file. " begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file1 = joinpath(dirname(dist_path), "case3_balanced_withoutgen.dss")
        pmd_file2 = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3x2_wrongformat_short.json")
        pmitd_type = NLPowerModelITD{ACRPowerModel, ACRUPowerModel}
        pmd_files = [pmd_file1, pmd_file2]
        @test_throws ErrorException pmitd_data = parse_files(pm_file, pmd_files, pmitd_file; auto_rename=true)
    end

end
