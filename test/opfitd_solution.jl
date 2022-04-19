@info "running integrated transmission-distribution optimal power flow (opfitd) tests with solution processors"

@testset "test/solution.jl" begin

    @testset "solve_model (with network inputs): Unbalanced case5-case3 ACR-ACR" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_unbalanced.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_unbal.json")
        pmitd_type = NLPowerModelITD{ACRPowerModel, ACRUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd; make_si=false, solution_processors=[sol_data_model!])
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 17953.7465; atol = 1e-4)
        @test all(isapprox.(result["solution"]["it"]["pm"]["bus"]["1"]["vm"], 0.91781; atol=1e-3))
        @test all(isapprox.(result["solution"]["it"]["pmd"]["bus"]["3bus_unbal.primary"]["vm"][1], 0.9352; atol=1e-3))
    end


    @testset "solve_model (with network inputs): Balanced case5-case3 Without Dist. Generator IVR-IVR" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced_withoutgen.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_bal_nogen.json")
        pmitd_type = IVRPowerModelITD{IVRPowerModel, IVRUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd; make_si=false, solution_processors=[sol_data_model!])
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 17978.8561; atol = 1e-4)
        @test all(isapprox.(result["solution"]["it"]["pm"]["bus"]["1"]["vm"], 0.91781; atol=1e-3))
        @test all(isapprox.(result["solution"]["it"]["pmd"]["bus"]["3bus_bal_nogen.primary"]["vm"][1], 0.9359; atol=1e-3))
    end

    @testset "solve_model (with network inputs): Balanced case5-case3 With Dist. Generator SOCBF-SOCNLPUBF" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced_notransformer.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_bal_notrans.json")
        pmitd_type = BFPowerModelITD{SOCBFPowerModel, SOCNLPUBFPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd; make_si=false, solution_processors=[sol_data_model!])
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 14927.8428; atol = 1e-4)
    end

    @testset "solve_model (with network inputs): Balanced case5-case3 Without Dist. Generator SOCBFConic-SOCConicUBF" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced_notransformer_withoutgen.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_bal_notrans_nogen.json")
        pmitd_type = BFPowerModelITD{SOCBFConicPowerModel, SOCConicUBFPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, scs_solver, build_opfitd; make_si=false, solution_processors=[sol_data_model!])
        @test result["termination_status"] == OPTIMAL
    end

    @testset "solve_mn_opfitd_oltc: Balanced case5-case3 ACR-FOTR - OLTC Problem" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced_oltc_mn.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_bal_oltc_mn.json")
        pmitd_type = NLFOTPowerModelITD{ACRPowerModel, FOTRUPowerModel}
        result = solve_mn_opfitd_oltc(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt; make_si=false, solution_processors=[sol_data_model!])
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 71022.0195; atol = 1e-4)
        @test all(isapprox.(result["solution"]["it"]["pm"]["nw"]["2"]["bus"]["1"]["vm"], 0.9179; atol=1e-3))
        @test all(isapprox.(result["solution"]["it"]["pmd"]["nw"]["2"]["bus"]["3bus_bal_oltc_mn.primary"]["vm"][1], 1.0181; atol=1e-3))
    end

    @testset "solve_mn_opfitd_oltc: Balanced case5-case3 ACR-FBS - OLTC Problem" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced_oltc_mn.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_bal_oltc_mn.json")
        pmitd_type = NLBFPowerModelITD{ACRPowerModel, FBSUBFPowerModel}
        result = solve_mn_opfitd_oltc(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt; make_si=false, solution_processors=[sol_data_model!])
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 71022.0068; atol = 1e-4)
        @test all(isapprox.(result["solution"]["it"]["pm"]["nw"]["2"]["bus"]["1"]["vm"], 0.9179; atol=1e-3))
        @test all(isapprox.(result["solution"]["it"]["pmd"]["nw"]["2"]["bus"]["3bus_bal_oltc_mn.primary"]["vm"][1], 1.0004; atol=1e-3))
    end

    @testset "solve_model opfitd (with network inputs): Multi-System Unbalanced case5-case3x2 Without Dist. Generator ACR-ACR" begin
        pm_file = joinpath(dirname(trans_path), "case5_with2loads.m")
        pmd_file1 = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen.dss")
        pmd_file2 = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen.dss")
        pmd_files = [pmd_file1, pmd_file2]
        pmitd_file = joinpath(dirname(bound_path), "case5_case3x2.json")
        pmitd_type = NLPowerModelITD{ACRPowerModel, ACRUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_files, pmitd_file; auto_rename=true)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd; make_si=false, solution_processors=[sol_data_model!])
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 18277.938357; atol = 1e-4)
        @test all(isapprox.(result["solution"]["it"]["pm"]["bus"]["1"]["vm"],  0.9176; atol=1e-3))
        @test all(isapprox.(result["solution"]["it"]["pmd"]["bus"]["3bus_unbal_nogen_2.primary"]["vm"][1], 0.9303; atol=1e-3))
    end
end
