@info "running integrated transmission-distribution optimal power flow (opfitd) with passthroughs tests"

@testset "test/opfitd_pass.jl" begin

    @testset "solve_model (with network inputs): Balanced case5-case3 Without Dist. Generator ACR-ACR" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced_withBattery.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_bal_battery.json")
        pmitd_type = NLPowerModelITD{ACRPowerModel, ACRUPowerModel}
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)

        # pmitd_inst_model = instantiate_model(pmitd_data, pmitd_type, build_opfitd)
        eng2math_passthrough = Dict("storage"=>["cost", "0.25"])
        pmitd_inst_model = instantiate_model(pmitd_data, pmitd_type, build_opfitd; eng2math_passthrough=eng2math_passthrough)
        # @info "$(pmitd_inst_model)"

        storage_ref = _IM.ref(pmitd_inst_model, _PMD.pmd_it_sym, nw=nw_id_default, :storage)
        @info "$(storage_ref)"

        # result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd; make_si=true)
        # @test result["termination_status"] == LOCALLY_SOLVED


        #### PMD tests
        pmd_parsed = _PMD.parse_file(pmd_file)
        eng2math_passthrough = Dict("storage"=>["cost", "0.25"])
        pmd_transformed = _PMD.transform_data_model(pmd_parsed; eng2math_passthrough=eng2math_passthrough)
        @info "$(pmd_transformed["storage"]["cost"])"
        # @info "$(pmd_transformed)" # passthrough not working! (ASK DAVID IF THIS IS A BUG).
    end

end
