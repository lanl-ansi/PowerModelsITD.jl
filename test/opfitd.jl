@info "running integrated transmission-distribution optimal power flow (opfitd) tests"

@testset "test/opfitd.jl" begin

    @testset "solve_model (with network inputs): Balanced case5-case3 ACR-ACR with piecewise linear terms" begin
        pm_file = joinpath(dirname(trans_path), "case5_pwlc_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3.json")
        pmitd_type = NLPowerModelITD{ACRPowerModel, ACRUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        # transform pmd to math, to change gens cost models
        pmitd_data["it"]["pmd"] = _PMD.transform_data_model(pmitd_data["it"]["pmd"])
        # Modify (internally) the gen cost model for PMD generator (for piecewise linear terms)
        pmitd_data["it"]["pmd"]["gen"]["1"]["ncost"] = 4
        pmitd_data["it"]["pmd"]["gen"]["1"]["model"] = 1
        pmitd_data["it"]["pmd"]["gen"]["1"]["cost"] = [0.02, 112.0, 0.033, 141.0, 0.044, 174.0, 0.055, 207.0]
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
    end


    @testset "solve_model (with network inputs): Balanced case5-case3 ACR-ACR with polynomial nl terms" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3.json")
        pmitd_type = NLPowerModelITD{ACRPowerModel, ACRUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        # transform pmd to math, to change gens cost models
        pmitd_data["it"]["pmd"] = _PMD.transform_data_model(pmitd_data["it"]["pmd"])
        # Modify (internally) all gens (both T&D) costs so that polynomial nl terms are used.
        pmitd_data["it"]["pmd"]["gen"]["1"]["cost"] = [20.0, 35.0,  110.0, 1.0] # modify dist. system gen.
        pmitd_data["it"]["pmd"]["gen"]["1"]["ncost"] = 4
        pmitd_data["it"]["pm"]["gen"]["4"]["cost"] = [200.0, 350.0,  4100.0, 1.0] # modify trans. system gen.
        pmitd_data["it"]["pm"]["gen"]["4"]["ncost"] = 4
        pmitd_data["it"]["pm"]["gen"]["1"]["cost"] = [100.0, 300.0,  1400.0, 1.0] # modify trans. system gen.
        pmitd_data["it"]["pm"]["gen"]["1"]["ncost"] = 4
        pmitd_data["it"]["pm"]["gen"]["5"]["cost"] = [80.0, 200.0,  1000.0, 1.0] # modify trans. system gen.
        pmitd_data["it"]["pm"]["gen"]["5"]["ncost"] = 4
        pmitd_data["it"]["pm"]["gen"]["2"]["cost"] = [110.0, 350.0,  1500.0, 1.0] # modify trans. system gen.
        pmitd_data["it"]["pm"]["gen"]["2"]["ncost"] = 4
        pmitd_data["it"]["pm"]["gen"]["3"]["cost"] = [120.0, 500.0,  3000.0, 1.0] # modify trans. system gen.
        pmitd_data["it"]["pm"]["gen"]["3"]["ncost"] = 4
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
    end


    @testset "solve_model (with network inputs): Balanced case5-case3 Without Dist. Generator ACR-ACR" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced_withoutgen.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3.json")
        pmitd_type = NLPowerModelITD{ACRPowerModel, ACRUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd; make_si=true)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 17978.85605; atol = 1e-4)
    end

    @testset "solve_model (with network inputs): Balanced case5-case3 Without Dist. Generator ACR-ACR - RAW PSSE File" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.raw")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced_withoutgen.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3.json")
        pmitd_type = NLPowerModelITD{ACRPowerModel, ACRUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 1088.88138315; atol = 1e-4)
    end

    @testset "solve_model (with network inputs): Unbalanced case5-case3 ACR-ACR" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_unbalanced.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3.json")
        pmitd_type = NLPowerModelITD{ACRPowerModel, ACRUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 17953.7465; atol = 1e-4)
    end

    @testset "solve_model (with network inputs): Unbalanced case5-case3 Without Dist. Generator ACR-ACR" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3.json")
        pmitd_type = NLPowerModelITD{ACRPowerModel, ACRUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 18005.97151; atol = 1e-4)
    end


    @testset "solve_model (with network inputs): Balanced case5-case13 ACR-ACR Without Dist. Generator ACR-ACR" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload_ieee13.m")
        pmd_file = joinpath(dirname(dist_path), "caseIEEE13_balanced_withoutgen.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case13.json")
        pmitd_type = NLPowerModelITD{ACRPowerModel, ACRUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 17925.1066; atol = 1e-3)
    end

    @testset "solve_model (with network inputs): Balanced case5-case3 ACP-ACP" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3.json")
        pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 17926.7247; atol = 1e-4)
    end

    @testset "solve_model (with network inputs): Balanced case5-case3 Without Dist. Generator ACP-ACP" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced_withoutgen.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3.json")
        pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 17978.85605; atol = 1e-4)
    end

    @testset "solve_model (with network inputs): Balanced case5-case3 Without Dist. Generator ACP-ACP - RAW PSSE File" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.raw")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced_withoutgen.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3.json")
        pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 1088.88138315; atol = 1e-4)
    end

    @testset "solve_model (with network inputs): Unbalanced case5-case3 ACP-ACP" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_unbalanced.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3.json")
        pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 17953.7465; atol = 1e-4)
    end

    @testset "solve_model (with network inputs): Unbalanced case5-case3 Without Dist. Generator ACP-ACP" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3.json")
        pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 18005.97151; atol = 1e-4)
    end

    @testset "solve_model (with network inputs): Balanced case5-case13 Without Dist. Generator ACP-ACP" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload_ieee13.m")
        pmd_file = joinpath(dirname(dist_path), "caseIEEE13_balanced_withoutgen.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case13.json")
        pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 17925.1066; atol = 1e-3)
    end

    @testset "solve_model (with network inputs): Balanced case5-case3 NFA-NFA" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3.json")
        pmitd_type = LPowerModelITD{NFAPowerModel, NFAUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 14721.99974; atol = 1e-4)
    end

    @testset "solve_model (with network inputs): Balanced case5-case3 Without Dist. Generator NFA-NFA" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced_withoutgen.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3.json")
        pmitd_type = LPowerModelITD{NFAPowerModel, NFAUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 14779.99974; atol = 1e-4)
    end

    @testset "solve_model (with network inputs): Unbalanced case5-case3 NFA-NFA" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_unbalanced.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3.json")
        pmitd_type = LPowerModelITD{NFAPowerModel, NFAUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 14751.99974; atol = 1e-4)
    end

    @testset "solve_model (with network inputs): Unbalanced case5-case3 Without Dist. Generator NFA-NFA" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3.json")
        pmitd_type = LPowerModelITD{NFAPowerModel, NFAUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 14809.99974; atol = 1e-4)
    end

    @testset "solve_model (with network inputs): Balanced case5-case13 Without Dist. Generator NFA-NFA" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload_ieee13.m")
        pmd_file = joinpath(dirname(dist_path), "caseIEEE13_balanced_withoutgen.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case13.json")
        pmitd_type = LPowerModelITD{NFAPowerModel, NFAUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 14613.52974; atol = 1e-4)
    end

    @testset "solve_model (with network inputs): Unbalanced case5-case13 Without Dist. Generator NFA-NFA" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload_ieee13.m")
        pmd_file = joinpath(dirname(dist_path), "caseIEEE13_unbalanced_withoutgen.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case13.json")
        pmitd_type = LPowerModelITD{NFAPowerModel, NFAUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 14613.97983; atol = 1e-4)
    end

    @testset "solve_model (with network inputs): Balanced case5-case3 Without Dist. Generator IVR-IVR" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced_withoutgen.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3.json")
        pmitd_type = IVRPowerModelITD{IVRPowerModel, IVRUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 17978.8561; atol = 1e-4)
    end

    @testset "solve_model (with network inputs): Unbalanced case5-case3 Without Dist. Generator IVR-IVR" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_unbalanced_withoutgen.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3.json")
        pmitd_type = IVRPowerModelITD{IVRPowerModel, IVRUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 18005.97151; atol = 1e-4)
    end


    @testset "solve_model (with network inputs): Balanced case5-case3 IVR-IVR with polynomial nl terms" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3.json")
        pmitd_type = IVRPowerModelITD{IVRPowerModel, IVRUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        # transform pmd to math, to change gens cost models
        pmitd_data["it"]["pmd"] = _PMD.transform_data_model(pmitd_data["it"]["pmd"])
        # Modify (internally) all gens (both T&D) costs so that polynomial nl terms are used.
        pmitd_data["it"]["pmd"]["gen"]["1"]["cost"] = [20.0, 35.0,  110.0, 1.0] # modify dist. system gen.
        pmitd_data["it"]["pmd"]["gen"]["1"]["ncost"] = 4
        pmitd_data["it"]["pm"]["gen"]["4"]["cost"] = [200.0, 350.0,  4100.0, 1.0] # modify trans. system gen.
        pmitd_data["it"]["pm"]["gen"]["4"]["ncost"] = 4
        pmitd_data["it"]["pm"]["gen"]["1"]["cost"] = [100.0, 300.0,  1400.0, 1.0] # modify trans. system gen.
        pmitd_data["it"]["pm"]["gen"]["1"]["ncost"] = 4
        pmitd_data["it"]["pm"]["gen"]["5"]["cost"] = [80.0, 200.0,  1000.0, 1.0] # modify trans. system gen.
        pmitd_data["it"]["pm"]["gen"]["5"]["ncost"] = 4
        pmitd_data["it"]["pm"]["gen"]["2"]["cost"] = [110.0, 350.0,  1500.0, 1.0] # modify trans. system gen.
        pmitd_data["it"]["pm"]["gen"]["2"]["ncost"] = 4
        pmitd_data["it"]["pm"]["gen"]["3"]["cost"] = [120.0, 500.0,  3000.0, 1.0] # modify trans. system gen.
        pmitd_data["it"]["pm"]["gen"]["3"]["ncost"] = 4
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

     @testset "solve_model (with network inputs): Balanced case5-case3 IVR-IVR with piecewise linear terms" begin
        pm_file = joinpath(dirname(trans_path), "case5_pwlc_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3.json")
        pmitd_type = IVRPowerModelITD{IVRPowerModel, IVRUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        # transform pmd to math, to change gens cost models
        pmitd_data["it"]["pmd"] = _PMD.transform_data_model(pmitd_data["it"]["pmd"])
        # Modify (internally) the gen cost model for PMD generator (for piecewise linear terms)
        pmitd_data["it"]["pmd"]["gen"]["1"]["ncost"] = 4
        pmitd_data["it"]["pmd"]["gen"]["1"]["model"] = 1
        pmitd_data["it"]["pmd"]["gen"]["1"]["cost"] = [0.02, 112.0, 0.033, 141.0, 0.044, 174.0, 0.055, 207.0]
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
    end

    @testset "solve_model (with network inputs): Balanced case5-case3 With Dist. Generator SOCBF-SOCNLPUBF" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced_notransformer.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3.json")
        pmitd_type = BFPowerModelITD{SOCBFPowerModel, SOCNLPUBFPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 14927.8428; atol = 1e-4)
    end

    @testset "solve_model (with network inputs): Balanced case5-case3 Without Dist. Generator SOCBF-SOCNLPUBF" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced_notransformer_withoutgen.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3.json")
        pmitd_type = BFPowerModelITD{SOCBFPowerModel, SOCNLPUBFPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 14986.03389; atol = 1e-4)
    end

    @testset "solve_model (with network inputs): Unbalanced case5-case3 With Dist. Generator SOCBF-SOCNLPUBF" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_unbalanced_notransformer.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3.json")
        pmitd_type = BFPowerModelITD{SOCBFPowerModel, SOCNLPUBFPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 14957.9736; atol = 1e-4)
    end

    @testset "solve_model (with network inputs): Unbalanced case5-case3 Without Dist. Generator SOCBF-SOCNLPUBF" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_unbalanced_notransformer_withoutgen.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3.json")
        pmitd_type = BFPowerModelITD{SOCBFPowerModel, SOCNLPUBFPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 15016.19713; atol = 1e-4)
    end

    @testset "solve_model (with network inputs): Balanced case5-case3 ACP-ACP: Per Unit Test Result" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3.json")
        pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd; make_si=false)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 17926.7247; atol = 1e-4)
        @test all(isapprox.(result["solution"]["it"]["pm"]["bus"]["1"]["vm"], 0.91781; atol=1e-3))
        @test all(isapprox.(result["solution"]["it"]["pm"]["gen"]["1"]["pg"], 0.4; atol=1e-3))
        @test all(isapprox.(result["solution"]["it"]["pmd"]["bus"]["primary"]["vm"][1], 0.9368; atol=1e-3))
        @test all(isapprox.(result["solution"]["it"]["pmd"]["bus"]["primary"]["va"][2], -120.7730; atol=1e-3))
        @test all(isapprox.(result["solution"]["it"]["pmd"]["generator"]["gen1"]["pg"][1], 0.006666; atol=1e-3))

    end

    @testset "solve_model (with network inputs): Balanced case5-case3 ACP-ACP: SI units Test Result" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3.json")
        pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd; make_si=true)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 17926.7247; atol = 1e-4)
        @test all(isapprox.(result["solution"]["it"]["pm"]["bus"]["1"]["vm"], 0.91781; atol=1e-3))
        @test all(isapprox.(result["solution"]["it"]["pm"]["gen"]["1"]["pg"], 40.0; atol=1e-3))
        @test all(isapprox.(result["solution"]["it"]["pmd"]["bus"]["primary"]["vm"][1], 7.4641984; atol=1e-3))
        @test all(isapprox.(result["solution"]["it"]["pmd"]["bus"]["primary"]["va"][2], -120.7730; atol=1e-3))
        @test all(isapprox.(result["solution"]["it"]["pmd"]["generator"]["gen1"]["pg"][1], 666.667; atol=1e-3))

    end

    @testset "solve_model (with network inputs): Balanced case5-case3 Without Dist. Generator SOCBFConic-SOCConicUBF" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced_notransformer_withoutgen.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3.json")
        pmitd_type = BFPowerModelITD{SOCBFConicPowerModel, SOCConicUBFPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
        result = solve_model(pmitd_data, pmitd_type, scs_solver, build_opfitd)
        @test result["termination_status"] == OPTIMAL
    end
end
