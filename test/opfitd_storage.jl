@info "running ITD storage tests"

@testset "test/opfitd_pass.jl" begin


    # @testset "Check that eng2math_passthrough value is being added to the instantiated model: " begin
    #     # pm_file = joinpath(dirname(trans_path), "case5_withload_strg.m")
    #     pm_file = joinpath(dirname(trans_path), "case5_withload.m")
    #     pmd_file = joinpath(dirname(dist_path), "case3_balanced_withBattery.dss")
    #     pmitd_file = joinpath(dirname(bound_path), "case5_case3_bal_battery.json")
    #     pmitd_type = NLPowerModelITD{ACRPowerModel, ACRUPowerModel}

    #     # One way of doing
    #     # pmitd_result_strg = solve_opfitd_storage(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt)

    #     # Other way of doing it
    #     pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)
    #     pmitd_result_strg = solve_opfitd_storage(pmitd_data, pmitd_type, ipopt)

    # end


    @testset "solve_model (build_mn_opfitd_storage): Multinetwork Balanced case5-case3 With Battery ACP-ACPU " begin
        # pm_file = joinpath(dirname(trans_path), "case5_withload_strg.m")
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced_withBattery_mn.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_bal_battery_mn.json")
        pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}

        # One way
        # pmitd_result_strg = solve_mn_opfitd_storage(pm_file, pmd_file, pmitd_file, pmitd_type, ipopt)

        # Other way
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file; multinetwork=true)
        pmitd_result_strg = solve_mn_opfitd_storage(pmitd_data, pmitd_type, ipopt)


    end


    #---------------------------------------------------------------------------------------------------------------


    # @testset "Check that eng2math_passthrough value is being added to the instantiated model: " begin
    #     pm_file = joinpath(dirname(trans_path), "case5_withload.m")
    #     pmd_file = joinpath(dirname(dist_path), "case3_balanced_withBattery.dss")
    #     pmitd_file = joinpath(dirname(bound_path), "case5_case3_bal_battery.json")
    #     pmitd_type = NLPowerModelITD{ACRPowerModel, ACRUPowerModel}
    #     pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)

    #     # add cost to storages in PMD
    #     for (st_name, st_data) in pmitd_data["it"]["pmd"]["storage"]
    #         st_data["cost"] = 0.25
    #     end

    #     # instantiate model with eng2math_passthrough
    #     eng2math_passthrough = Dict("storage"=>["cost"])
    #     pmitd_inst_model = instantiate_model(pmitd_data, pmitd_type, build_opfitd; eng2math_passthrough=eng2math_passthrough)

    #     # get storage reference
    #     storage_ref = _IM.ref(pmitd_inst_model, _PMD.pmd_it_sym, nw=nw_id_default, :storage)

    #     # test that the "cost" value in storage exists.
    #     @test storage_ref[1]["cost"] == 0.25
    # end

    # @testset "Check that eng2math_passthrough value is being added to the instantiated model (Multinetwork): " begin
    #     pm_file = joinpath(dirname(trans_path), "case5_withload.m")
    #     pmd_file = joinpath(dirname(dist_path), "case3_balanced_withBattery_mn.dss")
    #     pmitd_file = joinpath(dirname(bound_path), "case5_case3_bal_battery_mn.json")
    #     pmitd_type = NLPowerModelITD{ACRPowerModel, ACRUPowerModel}
    #     pmitd_data = parse_files(pm_file, pmd_file, pmitd_file; multinetwork=true)

    #     # add cost to storages in PMD
    #     for (nw_id, nw_data) in pmitd_data["it"]["pmd"]["nw"]
    #         for (st_name, st_data) in nw_data["storage"]
    #             st_data["cost"] = 0.25
    #         end
    #     end

    #     # instantiate model with eng2math_passthrough
    #     eng2math_passthrough = Dict("storage"=>["cost"])
    #     pmitd_inst_model = instantiate_model(pmitd_data, pmitd_type, build_mn_opfitd; multinetwork=true, eng2math_passthrough=eng2math_passthrough)

    #     # get storage reference from nw=4
    #     storage_ref_nw4 = _IM.ref(pmitd_inst_model, _PMD.pmd_it_sym, nw=4, :storage)

    #     # test that the "cost" value in storage nw=4 exists.
    #     @test storage_ref_nw4[1]["cost"] == 0.25
    # end

    # @testset "solve_model (build_opfitd_storage): Balanced case5-case3 With Battery ACP-ACPU " begin
    #     pm_file = joinpath(dirname(trans_path), "case5_withload.m")
    #     pmd_file = joinpath(dirname(dist_path), "case3_balanced_withBattery.dss")
    #     pmitd_file = joinpath(dirname(bound_path), "case5_case3_bal_battery.json")
    #     pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
    #     pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)

    #     # cost to assign to energy storage
    #     # Units $/pu, to convert from your wanted $/MWh just multiply by MVABase (e.g., 2.5 $/MWh x 100 MWh/1pu = 250 $/pu)
    #     strg_cost = 250

    #     # add cost to storages in PMD
    #     for (st_name, st_data) in pmitd_data["it"]["pmd"]["storage"]
    #         st_data["cost"] = strg_cost
    #     end

    #     # eng2math_passthrough
    #     eng2math_passthrough = Dict("storage"=>["cost"])

    #     # with storage cost problem
    #     pmitd_result_strg = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd_storage; eng2math_passthrough=eng2math_passthrough)
    #     @test isapprox(pmitd_result_strg["objective"], 17977.48172498742+(pmitd_result_strg["solution"]["it"]["pmd"]["storage"]["3bus_bal_battery.s1"]["sd"]*strg_cost)/100000; atol = 1e-3)

    # end

    # @testset "solve_model (build_mn_opfitd_storage): Multinetwork Balanced case5-case3 With Battery ACP-ACPU " begin
    #     pm_file = joinpath(dirname(trans_path), "case5_withload.m")
    #     pmd_file = joinpath(dirname(dist_path), "case3_balanced_withBattery_mn.dss")
    #     pmitd_file = joinpath(dirname(bound_path), "case5_case3_bal_battery_mn.json")
    #     pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
    #     pmitd_data = parse_files(pm_file, pmd_file, pmitd_file; multinetwork=true)

    #     # cost to assign to energy storage
    #     # Units $/pu, to convert from your wanted $/MWh just multiply by MVABase (e.g., 2.5 $/MWh x 100 MWh/1pu = 250 $/pu)
    #     strg_cost = 250

    #     # add cost to storages in PMD
    #     for (nw_id, nw_data) in pmitd_data["it"]["pmd"]["nw"]
    #         for (st_name, st_data) in nw_data["storage"]
    #             st_data["cost"] = strg_cost
    #         end
    #     end

    #     # instantiate model with eng2math_passthrough
    #     eng2math_passthrough = Dict("storage"=>["cost"])

    #     # with storage cost problem
    #     pmitd_result_strg = solve_model(pmitd_data, pmitd_type, ipopt, build_mn_opfitd_storage; multinetwork=true, eng2math_passthrough=eng2math_passthrough)
    #     @test isapprox(pmitd_result_strg["objective"], 71226.99645541582+0.12500248519; atol = 1e-3)

    # end

end
