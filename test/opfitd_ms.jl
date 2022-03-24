@info "running integrated transmission-distribution optimal power flow (opfitd) tests for multi-systems (ms)"

@testset "test/opfitd_ms.jl - (multi-systems)" begin

    @testset "solve_model opfitd (with network inputs): Multi-System Unbalanced case5-case3x2 Without Dist. Generator ACR-ACR" begin
        pm_file = joinpath(dirname(trans_path), "case5_with2loads.m")
        pmd_file1 = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen.dss")
        pmd_file2 = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen.dss")
        pmd_files = [pmd_file1, pmd_file2]
        pmitd_file = joinpath(dirname(bound_path), "case5_case3x2.json")
        pmitd_type = NLPowerModelITD{ACRPowerModel, ACRUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_files, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 18277.938357; atol = 1e-4)
    end

    @testset "solve_model opfitd (with network inputs): Multi-System Unbalanced case5-case3x2 Without Dist. Generator ACP-ACP" begin
        pm_file = joinpath(dirname(trans_path), "case5_with2loads.m")
        pmd_file1 = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen.dss")
        pmd_file2 = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen.dss")
        pmd_files = [pmd_file1, pmd_file2]
        pmitd_file = joinpath(dirname(bound_path), "case5_case3x2.json")
        pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_files, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 18277.93835; atol = 1e-4)
    end

    @testset "solve_model opfitd (with network inputs): Multi-System Unbalanced case5-case3x2 Without Dist. Generator NFA-NFA" begin
        pm_file = joinpath(dirname(trans_path), "case5_with2loads.m")
        pmd_file1 = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen.dss")
        pmd_file2 = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen.dss")
        pmd_files = [pmd_file1, pmd_file2]
        pmitd_file = joinpath(dirname(bound_path), "case5_case3x2.json")
        pmitd_type = LPowerModelITD{NFAPowerModel, NFAUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_files, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 15109.99982; atol = 1e-4)
    end

    @testset "solve_model opfitd (with network inputs): Multi-System Unbalanced case5-case3x2 Without Dist. Generator IVR-IVR" begin
        pm_file = joinpath(dirname(trans_path), "case5_with2loads.m")
        pmd_file1 = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen.dss")
        pmd_file2 = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen.dss")
        pmd_files = [pmd_file1, pmd_file2]
        pmitd_file = joinpath(dirname(bound_path), "case5_case3x2.json")
        pmitd_type = IVRPowerModelITD{IVRPowerModel, IVRUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_files, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 18277.9384; atol = 1e-4)
    end

    @testset "solve_model opfitd (with network inputs): Multi-System Unbalanced case5-case3x2 Without Dist. Generator SOCBF-SOCNLPUB" begin
        pm_file = joinpath(dirname(trans_path), "case5_with2loads.m")
        pmd_file1 = joinpath(dirname(dist_path), "case3_unbalanced_notransformer.dss")
        pmd_file2 = joinpath(dirname(dist_path), "case3_unbalanced_notransformer.dss")
        pmd_files = [pmd_file1, pmd_file2]
        pmitd_file = joinpath(dirname(bound_path), "case5_case3x2.json")
        pmitd_type = BFPowerModelITD{SOCBFPowerModel, SOCNLPUBFPowerModel}
        pmitd_data = parse_files(pm_file, pmd_files, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 15200.83762; atol = 1e-4)
    end

    @testset "solve_model opfitd (with network inputs): Multi-System Balanced case5-case3x2 Without Dist. Generator ACP-ACP: Per Unit Test Result" begin
        pm_file = joinpath(dirname(trans_path), "case5_with2loads.m")
        pmd_file1 = joinpath(dirname(dist_path), "case3_balanced_withoutgen.dss")
        pmd_file2 = joinpath(dirname(dist_path), "case3_balanced_withoutgen.dss")
        pmd_files = [pmd_file1, pmd_file2]
        pmitd_file = joinpath(dirname(bound_path), "case5_case3x2.json")
        pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_files, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd; make_si=false)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 18223.63488; atol = 1e-4)
        @test all(isapprox.(result["solution"]["it"]["pm"]["bus"]["1"]["vm"], 0.91781; atol=1e-3))
        @test all(isapprox.(result["solution"]["it"]["pm"]["gen"]["1"]["pg"], 0.4; atol=1e-3))
        @test all(isapprox.(result["solution"]["it"]["pmd"]["bus"]["primary"]["vm"][1], 0.93348146; atol=1e-3))
        @test all(isapprox.(result["solution"]["it"]["pmd"]["bus"]["primary"]["va"][2], -121.04281; atol=1e-3))
    end

    @testset "solve_model opfitd (with network inputs): Multi-System Balanced case5-case3x2 Without Dist. Generator ACP-ACP: SI units Test Result" begin
        pm_file = joinpath(dirname(trans_path), "case5_with2loads.m")
        pmd_file1 = joinpath(dirname(dist_path), "case3_balanced_withoutgen.dss")
        pmd_file2 = joinpath(dirname(dist_path), "case3_balanced_withoutgen.dss")
        pmd_files = [pmd_file1, pmd_file2]
        pmitd_file = joinpath(dirname(bound_path), "case5_case3x2.json")
        pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_files, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd; make_si=true)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 18223.63488; atol = 1e-4)
        @test all(isapprox.(result["solution"]["it"]["pm"]["bus"]["1"]["vm"], 0.91781; atol=1e-3))
        @test all(isapprox.(result["solution"]["it"]["pm"]["gen"]["1"]["pg"], 40.0; atol=1e-3))
        @test all(isapprox.(result["solution"]["it"]["pmd"]["bus"]["primary"]["vm"][1], 7.437451; atol=1e-3))
        @test all(isapprox.(result["solution"]["it"]["pmd"]["bus"]["primary"]["va"][2], -121.0428; atol=1e-3))
    end


    @testset "solve_model opfitd (with network inputs): Multi-System Balanced case5-case3x2 With PV ACP-ACP" begin
        pm_file = joinpath(dirname(trans_path), "case5_with2loads.m")
        pmd_file1 = joinpath(dirname(dist_path), "case3_balanced_withPV.dss")
        pmd_file2 = joinpath(dirname(dist_path), "case3_balanced_withPV.dss")
        pmd_files = [pmd_file1, pmd_file2]
        pmitd_file = joinpath(dirname(bound_path), "case5_case3x2.json")
        pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_files, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_model opfitd (with network inputs): Multi-System Balanced case5-case3x2 With Battery ACP-ACP" begin
        pm_file = joinpath(dirname(trans_path), "case5_with2loads.m")
        pmd_file1 = joinpath(dirname(dist_path), "case3_balanced_withBattery.dss")
        pmd_file2 = joinpath(dirname(dist_path), "case3_balanced_withBattery.dss")
        pmd_files = [pmd_file1, pmd_file2]
        pmitd_file = joinpath(dirname(bound_path), "case5_case3x2.json")
        pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_files, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_model opfitd (with network inputs): Multi-System Balanced case5-case3x2 With Switch ACP-ACP" begin
        pm_file = joinpath(dirname(trans_path), "case5_with2loads.m")
        pmd_file1 = joinpath(dirname(dist_path), "case3_balanced_withSwitch.dss")
        pmd_file2 = joinpath(dirname(dist_path), "case3_balanced_withSwitch.dss")
        pmd_files = [pmd_file1, pmd_file2]
        pmitd_file = joinpath(dirname(bound_path), "case5_case3x2.json")
        pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_files, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_model opfitd (with network inputs): Multi-System Balanced case5-case3x2 With Capacitor ACP-ACP" begin
        pm_file = joinpath(dirname(trans_path), "case5_with2loads.m")
        pmd_file1 = joinpath(dirname(dist_path), "case3_balanced_withCapacitor.dss")
        pmd_file2 = joinpath(dirname(dist_path), "case3_balanced_withCapacitor.dss")
        pmd_files = [pmd_file1, pmd_file2]
        pmitd_file = joinpath(dirname(bound_path), "case5_case3x2.json")
        pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_files, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
    end
end
