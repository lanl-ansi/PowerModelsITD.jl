@info "running integrated transmission-distribution optimal power flow (opfitd) tests with bounds and transformations"

@testset "test/transformations_opfitd.jl" begin

    @testset "solve_model (with network inputs): Balanced case5-case3 Without Dist. Generator ACR-ACR - Applying voltage bounds" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced_withoutgen.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3.json")
        pmitd_type = NLPowerModelITD{ACRPowerModel, ACRUPowerModel}

        # parse files
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)

        # apply transformations
        apply_voltage_bounds!(pmitd_data; vm_lb=0.99, vm_ub=1.01)
	    apply_voltage_angle_difference_bounds!(pmitd_data, 1)

        # run opfitd
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
    end


    @testset "solve_model (with network inputs): Balanced case5-case3 Without Dist. Generator ACR-ACR - Remove all bounds" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced_withoutgen.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3.json")
        pmitd_type = NLPowerModelITD{ACRPowerModel, ACRUPowerModel}

        # parse files
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)

        # apply transformations
        remove_all_bounds!(pmitd_data)

        # run opfitd
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
    end


    @testset "solve_model (with network inputs): Balanced case5-case3 Without Dist. Generator ACR-ACR - Apply Kron reduction and phase projections" begin
        pm_file = joinpath(dirname(trans_path), "case5_withload.m")
        pmd_file = joinpath(dirname(dist_path), "case3_balanced_withoutgen.dss")
        pmitd_file = joinpath(dirname(bound_path), "case5_case3.json")
        pmitd_type = NLPowerModelITD{ACRPowerModel, ACRUPowerModel}

        # parse files
        pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)

        # apply transformations
        apply_kron_reduction!(pmitd_data)
        apply_phase_projection!(pmitd_data)
        apply_phase_projection_delta!(pmitd_data)

        # run opftid
        result = solve_model(pmitd_data, pmitd_type, ipopt, build_opfitd)
        @test result["termination_status"] == LOCALLY_SOLVED
    end
end
