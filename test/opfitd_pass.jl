@info "running ITD eng2math_passthrough tests"

@testset "test/opfitd_pass.jl" begin

    @testset "Check that eng2math_passthrough value is being added to the instantiated model: " begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced_withBattery.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_bal_battery.json")
        pmitd_type = NLPowerModelITD{ACRPowerModel, ACRUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)

        # add cost to storages in PMD
        for (st_name, st_data) in pmitd_data["it"]["pmd"]["storage"]
            st_data["cost"] = 0.25
        end

        # instantiate model with eng2math_passthrough
        eng2math_passthrough = Dict("storage"=>["cost"])
        pmitd_inst_model = instantiate_model(pmitd_data, pmitd_type, build_opfitd; eng2math_passthrough=eng2math_passthrough)

        # get storage reference
        storage_ref = _IM.ref(pmitd_inst_model, _PMD.pmd_it_sym, nw=nw_id_default, :storage)

        # test that the "cost" value in storage exists.
        @test storage_ref[1]["cost"] == 0.25
    end

    @testset "Check that eng2math_passthrough value is being added to the instantiated model (Multinetwork): " begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced_withBattery_mn.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_bal_battery_mn.json")
        pmitd_type = NLPowerModelITD{ACRPowerModel, ACRUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file; multinetwork=true)

        # add cost to storages in PMD
        for (nw_id, nw_data) in pmitd_data["it"]["pmd"]["nw"]
            for (st_name, st_data) in nw_data["storage"]
                st_data["cost"] = 0.25
            end
        end

        # instantiate model with eng2math_passthrough
        eng2math_passthrough = Dict("storage"=>["cost"])
        pmitd_inst_model = instantiate_model(pmitd_data, pmitd_type, build_mn_opfitd; multinetwork=true, eng2math_passthrough=eng2math_passthrough)

        # get storage reference from nw=4
        storage_ref_nw4 = _IM.ref(pmitd_inst_model, _PMD.pmd_it_sym, nw=4, :storage)

        # test that the "cost" value in storage nw=4 exists.
        @test storage_ref_nw4[1]["cost"] == 0.25
    end

    @testset "solve_model (build_opfitd_storage): Balanced case5-case3 With Battery Generator ACP-ACPU " begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced_withBattery.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_bal_battery.json")
        pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)

        # add cost to storages in PMD
        for (st_name, st_data) in pmitd_data["it"]["pmd"]["storage"]
            st_data["cost"] = 0.25
        end

        # instantiate model with eng2math_passthrough
        eng2math_passthrough = Dict("storage"=>["cost"])
        pmitd_inst_model = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd_storage; eng2math_passthrough=eng2math_passthrough)

    end

    @testset "solve_model (build_mn_opfitd_storage): Multinetwork Balanced case5-case3 With Battery Generator ACP-ACPU " begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced_withBattery_mn.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_bal_battery_mn.json")
        pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file; multinetwork=true)

        # add cost to storages in PMD
        for (nw_id, nw_data) in pmitd_data["it"]["pmd"]["nw"]
            for (st_name, st_data) in nw_data["storage"]
                st_data["cost"] = 0.25
            end
        end

        # instantiate model with eng2math_passthrough
        eng2math_passthrough = Dict("storage"=>["cost"])
        pmitd_inst_model = solve_model(pmitd_data, pmitd_type, ipopt, build_mn_opfitd_storage; multinetwork=true, eng2math_passthrough=eng2math_passthrough)

    end

end
