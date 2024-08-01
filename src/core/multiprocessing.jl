"""
    function optimize_subproblem_multiprocessing((
        data::Dict{String, Any},
        type,
        build_method,
        status_signal::Distributed.RemoteChannel,
        mp_string_rc::Distributed.RemoteChannel,
        sp_string_rc::Distributed.RemoteChannel,
        i::Int,
        number_of_subprobs::Int;
        export_models::Bool
    )

Instantiates and solves subproblems in parallel (multiprocessing). Writes the results to a .txt file.
"""
function optimize_subproblem_multiprocessing(
    data::Dict{String, Any},
    type,
    build_method,
    status_signal::Distributed.RemoteChannel,
    mp_string_rc::Distributed.RemoteChannel,
    sp_string_rc::Distributed.RemoteChannel,
    i::Int,
    number_of_subprobs::Int;
    export_models::Bool=false
)

    # Instantiate the PMD model
    subproblem_instantiated = _IM.instantiate_model(data,
                                    type,
                                    build_method,
                                    ref_add_core_decomposition_distribution!,
                                    _PMD._pmd_global_keys,
                                    _PMD.pmd_it_sym
    )

    # Set the optimizer to the instantiated subproblem JuMP model
    JuMP.set_optimizer(subproblem_instantiated.model, _SDO.Optimizer; add_bridges = true)

    # Assign the type of the problem
    subproblem_instantiated.model.moi_backend.optimizer.model.type = "Subproblem"

    # Obtain ckt boundary data
    boundary_number = first(keys(data[pmitd_it_name]))

    # Get vector of boundary linking vars
    subprob_linking_vars_vector = generate_boundary_linking_vars_distribution(subproblem_instantiated,
                                                                            boundary_number;
                                                                            export_models=export_models
    )

    # Assign the list of linking vars
    subproblem_instantiated.model.moi_backend.optimizer.model.list_linking_vars = [subprob_linking_vars_vector]

     # Export mof.json models
     if (export_models == true)
        JuMP.write_to_file(subproblem_instantiated.model, "subproblem_$(i)_$(data["ckt_name"])_$(boundary_number)_model_exported.mof.json")
    end

    # Setup and initilize the subproblem
    JuMP.optimize!(subproblem_instantiated.model) # Setup the Subproblem model

    # Solve the subproblem
    _SDO.solve_subproblem!(subproblem_instantiated.model,
                        status_signal,
                        mp_string_rc,
                        sp_string_rc,
                        i,
                        number_of_subprobs
    )

    # Build, transform, and write result to file
    result = build_pmd_decomposition_solution(subproblem_instantiated)

    # TODO: Find a way to transform distribution systems solution from MATH to ENG and PU to SI before output.

    result_json = JSON.json(result)
    open("subproblem_$(i)-ckt_$(data["ckt_name"])-boundary_$(boundary_number).json", "w") do file
        write(file, result_json)
    end

    # Close RemoteChannels
    close(status_signal)
    close(mp_string_rc)
    close(sp_string_rc)

    # # Clear references to help the garbage collector
    # subproblem_instantiated = nothing
    # subprob_linking_vars_vector = nothing
    # result = nothing
    # result_json = nothing
    # data = nothing

    # Clean everything before leaving process
    GC.gc()

end
