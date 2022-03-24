@info "running data.jl function tests"

@testset "src/core/data.jl" begin
    pm_file = joinpath(dirname(trans_path), "case5_withload.m")
    pmd_file = joinpath(dirname(dist_path), "case3_balanced.dss")

    @testset "assign_boundary_buses! (with non-existing transmission bus name)" begin
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_wrongname_transmission.json")
        pmitd_data = parse_link_file(pmitd_file)                              # Parse linking file
        _IM.update_data!(pmitd_data, parse_power_transmission_file(pm_file))  # Update data with transmission data
        pmd_data = parse_power_distribution_file(pmd_file)                    # Parse distribution file
        pmd_data = _PMD.transform_data_model(pmd_data)                        # Transform data to MATH model
        pmd_data = Dict("multiinfrastructure" => true, "it" => Dict(_PMD.pmd_it_name => pmd_data)) # make it dict. compatible
        _IM.update_data!(pmitd_data, pmd_data)                                # Update data with distribution data
        @test_throws ErrorException assign_boundary_buses!(pmitd_data)        # Throw error for wrong name
    end

    @testset "assign_boundary_buses! (with non-existing distribution bus name)" begin
        pmitd_file = joinpath(dirname(bound_path), "case5_case3_wrongname_distribution.json")
        pmitd_data = parse_link_file(pmitd_file)                              # Parse linking file
        _IM.update_data!(pmitd_data, parse_power_transmission_file(pm_file))  # Update data with transmission data
        pmd_data = parse_power_distribution_file(pmd_file)                    # Parse distribution file
        pmd_data = _PMD.transform_data_model(pmd_data)                        # Transform data to MATH model
        pmd_data = Dict("multiinfrastructure" => true, "it" => Dict(_PMD.pmd_it_name => pmd_data)) # make it dict. compatible
        _IM.update_data!(pmitd_data, pmd_data)                                # Update data with distribution data
        @test_throws ErrorException assign_boundary_buses!(pmitd_data)        # Throw error for wrong name
        @test_throws ErrorException assign_boundary_buses!(pmitd_data)         # Throw error for wrong name
    end
end
