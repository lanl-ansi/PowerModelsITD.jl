"Root of the PowerModelsITD formulation hierarchy."
abstract type AbstractPowerModelITD{T1 <: _PM.AbstractPowerModel, T2 <: _PMD.AbstractUnbalancedPowerModel} <: _IM.AbstractInfrastructureModel end

"A macro for adding the base PowerModelsITD fields to a type definition."
_IM.@def pmitd_fields begin PowerModelsITD.@im_fields end


# Helper functions for multinetwork AbstractPowerModelITD objects.
nw_ids(pmitd::AbstractPowerModelITD) = _IM.nw_ids(pmitd, pmitd_it_sym)
nws(pmitd::AbstractPowerModelITD) = _IM.nws(pmitd, pmitd_it_sym)

# Helper functions for AbstractPowerModelITD component indices.
ids(pmitd::AbstractPowerModelITD, nw::Int, key::Symbol) = _IM.ids(pmitd, pmitd_it_sym, nw, key)
ids(pmitd::AbstractPowerModelITD, key::Symbol; nw::Int=nw_id_default) = _IM.ids(pmitd, pmitd_it_sym, key; nw = nw)

# Helper functions for AbstractPowerModelITD `ref` access.
ref(pmitd::AbstractPowerModelITD, nw::Int=nw_id_default) = _IM.ref(pmitd, pmitd_it_sym, nw)
ref(pmitd::AbstractPowerModelITD, nw::Int, key::Symbol) = _IM.ref(pmitd, pmitd_it_sym, nw, key)
ref(pmitd::AbstractPowerModelITD, nw::Int, key::Symbol, idx::Any) = _IM.ref(pmitd, pmitd_it_sym, nw, key, idx)
ref(pmitd::AbstractPowerModelITD, nw::Int, key::Symbol, idx::Any, param::String) = _IM.ref(pmitd, pmitd_it_sym, nw, key, idx, param)
ref(pmitd::AbstractPowerModelITD, key::Symbol; nw::Int=nw_id_default) = _IM.ref(pmitd, pmitd_it_sym, key; nw = nw)
ref(pmitd::AbstractPowerModelITD, key::Symbol, idx::Any; nw::Int=nw_id_default) = _IM.ref(pmitd, pmitd_it_sym, key, idx; nw = nw)
ref(pmitd::AbstractPowerModelITD, key::Symbol, idx::Any, param::String; nw::Int=nw_id_default) = _IM.ref(pmitd, pmitd_it_sym, key, idx, param; nw = nw)


# Helper functions for AbstractPowerModelITD `var` access.
var(pmitd::AbstractPowerModelITD, nw::Int = nw_id_default) = _IM.var(pmitd, pmitd_it_sym, nw)
var(pmitd::AbstractPowerModelITD, nw::Int, key::Symbol) = _IM.var(pmitd, pmitd_it_sym, nw, key)
var(pmitd::AbstractPowerModelITD, nw::Int, key::Symbol, idx::Any) = _IM.var(pmitd, pmitd_it_sym, nw, key, idx)
var(pmitd::AbstractPowerModelITD, key::Symbol; nw::Int=nw_id_default) = _IM.var(pmitd, pmitd_it_sym, key; nw = nw)
var(pmitd::AbstractPowerModelITD, key::Symbol, idx::Any; nw::Int=nw_id_default) = _IM.var(pmitd, pmitd_it_sym, key, idx; nw = nw)


# Helper functions for AbstractPowerModelITD `con` access.
con(pmitd::AbstractPowerModelITD, nw::Int=nw_id_default) = _IM.con(pmitd, pmitd_it_sym; nw = nw)
con(pmitd::AbstractPowerModelITD, nw::Int, key::Symbol) = _IM.con(pmitd, pmitd_it_sym, nw, key)
con(pmitd::AbstractPowerModelITD, nw::Int, key::Symbol, idx::Any) = _IM.con(pmitd, pmitd_it_sym, nw, key, idx)
con(pmitd::AbstractPowerModelITD, key::Symbol; nw::Int=nw_id_default) = _IM.con(pmitd, pmitd_it_sym, key; nw = nw)
con(pmitd::AbstractPowerModelITD, key::Symbol, idx::Any; nw::Int=nw_id_default) = _IM.con(pmitd, pmitd_it_sym, key, idx; nw = nw)


# Helper functions for AbstractPowerModelITD `sol` access.
sol(pmitd::AbstractPowerModelITD, nw::Int=nw_id_default) = _IM.sol(pmitd, pmitd_it_sym; nw = nw)
sol(pmitd::AbstractPowerModelITD, nw::Int, key::Symbol) = _IM.sol(pmitd, pmitd_it_sym, nw, key)
sol(pmitd::AbstractPowerModelITD, nw::Int, key::Symbol, idx::Any) = _IM.sol(pmitd, pmitd_it_sym, nw, key, idx)
sol(pmitd::AbstractPowerModelITD, key::Symbol; nw::Int=nw_id_default) = _IM.sol(pmitd, pmitd_it_sym, key; nw = nw)
sol(pmitd::AbstractPowerModelITD, key::Symbol, idx::Any; nw::Int=nw_id_default) = _IM.sol(pmitd, pmitd_it_sym, key, idx; nw = nw)


@doc "helper function to access the `ids` of multinetworks from AbstractPowerModelITD structs, returns ints" nw_ids
@doc "helper function to access multinetwork data from AbstractPowerModelITD structs, returns (id,data) pairs" nws
@doc "helper function to access the `ids` of AbstractPowerModelITD structs' `ref`, returns ints" ids
@doc "helper function to access the AbstractPowerModelITD structs' `ref`, returns (id,data) pairs" ref
@doc "helper function to access the AbstractPowerModelITD structs' `var`, returns JuMP VariableRef" var
@doc "helper function to access the AbstractPowerModelITD structs' `con`, returns JuMP Constraint" con
@doc "helper function to access the AbstractPowerModelITD structs' `sol`, returns Dict" sol


"""
    function instantiate_model(
        pm_file::String,
        pmd_files::Vector,
        pmitd_file::String,
        pmitd_type::Type,
        build_method::Function;
        multinetwork::Bool=false,
        pmitd_ref_extensions::Vector{<:Function}=Function[],
        auto_rename::Bool=false,
        kwargs...
    )

Instantiates and returns PowerModelsITD modeling object from power transmission,
power distribution, and boundary linking input files `pm_file`, `pmd_files` vector, and `pmitd_file`,
respectively. Here, `pmitd_type` is the integrated power transmission-distribution modeling type and
`build_method` is the build method for the problem specification being considered.
`multinetwork` is the boolean that defines if the modeling object should be define as multinetwork.
`pmitd_ref_extensions` are the arrays of power transmission and distribution modeling extensions.
"""
function instantiate_model(
    pm_file::String, pmd_files::Vector{String}, pmitd_file::String, pmitd_type::Type,
    build_method::Function; multinetwork::Bool=false, pmitd_ref_extensions::Vector{<:Function}=Function[], auto_rename::Bool=false, kwargs...)

    # Read power t&d and linkage data from files.
    pmitd_data = parse_files(pm_file, pmd_files, pmitd_file; multinetwork=multinetwork, auto_rename=auto_rename)

    # Instantiate the PowerModelsITD object.
    return instantiate_model(
        pmitd_data, pmitd_type, build_method;
        multinetwork=multinetwork,
        pmitd_ref_extensions=pmitd_ref_extensions, kwargs...)
end


"""
    function instantiate_model(
        pm_file::String,
        pmd_file::String,
        pmitd_file::String,
        pmitd_type::Type,
        build_method::Function;
        multinetwork::Bool=false,
        pmitd_ref_extensions::Vector{<:Function}=Function[],
        auto_rename::Bool=false,
        kwargs...
    )

Instantiates and returns PowerModelsITD modeling object from power transmission,
power distribution, and boundary linking input files `pm_file`, `pmd_file` (one file provided), and `pmitd_file`,
respectively. Here, `pmitd_type` is the integrated power transmission-distribution modeling type and
`build_method` is the build method for the problem specification being considered.
`multinetwork` is the boolean that defines if the modeling object should be define as multinetwork.
`pmitd_ref_extensions` are the arrays of power transmission and distribution modeling extensions.
"""
function instantiate_model(
    pm_file::String, pmd_file::String, pmitd_file::String, pmitd_type::Type,
    build_method::Function; multinetwork::Bool=false, pmitd_ref_extensions::Vector{<:Function}=Function[], auto_rename::Bool=false, kwargs...)

    pmd_files = [pmd_file] # convert to vector

    # Read power t&d and linkage data from files.
    pmitd_data = parse_files(pm_file, pmd_files, pmitd_file; multinetwork=multinetwork, auto_rename=auto_rename)

    # Instantiate the PowerModelsITD object.
    return instantiate_model(
        pmitd_data, pmitd_type, build_method;
        multinetwork=multinetwork,
        pmitd_ref_extensions=pmitd_ref_extensions, kwargs...
    )
end


"""
    function instantiate_model(
        pmitd_data::Dict{String,<:Any},
        pmitd_type::Type,
        build_method::Function;
        multinetwork::Bool=false,
        pmitd_ref_extensions::Vector{<:Function}=Function[],
        kwargs...
    )

Instantiates and returns PowerModelsITD modeling object from parsed power transmission
and distribution (PMITD) input data `pmitd_data`. Here, `pmitd_type` is the integrated power
transmission and distribution modeling type and `build_method` is the build method for the problem
specification being considered.
`multinetwork` is the boolean that defines if the modeling object should be define as multinetwork.
`pmitd_ref_extensions` is an array of power transmission and distribution modeling extensions.
"""
function instantiate_model(
    pmitd_data::Dict{String,<:Any}, pmitd_type::Type, build_method::Function;
    multinetwork::Bool=false, pmitd_ref_extensions::Vector{<:Function}=Function[], kwargs...)

    # Extract PMD model/data
    pmd_data = pmitd_data["it"][_PMD.pmd_it_name]

    # transform PMD data (only) from ENG to MATH Model
    if (!_PMD.ismath(pmd_data))
        pmitd_data["it"][_PMD.pmd_it_name] = _PMD.transform_data_model(pmd_data; multinetwork=multinetwork)
    end

    # Correct the network data and assign the respective boundary number values.
    correct_network_data!(pmitd_data; multinetwork=multinetwork)

    pmitd = _IM.instantiate_model(
        pmitd_data, pmitd_type, build_method, ref_add_core!, _pmitd_global_keys;
        ref_extensions=pmitd_ref_extensions, kwargs...
    )

    return pmitd
end


"""
    function instantiate_model_decomposition(
        pm_file::String,
        pmd_files::Vector,
        pmitd_file::String,
        pmitd_type::Type,
        build_method::Function;
        multinetwork::Bool=false,
        pmitd_ref_extensions::Vector{<:Function}=Function[],
        auto_rename::Bool=false,
        kwargs...
    )

Instantiates and returns a decomposition-based PowerModelsITD modeling object from power transmission,
power distribution, and boundary linking input files `pm_file`, `pmd_files` vector, and `pmitd_file`,
respectively. Here, `pmitd_type` is the integrated power transmission-distribution modeling type and
`build_method` is the build method for the problem specification being considered.
`multinetwork` is the boolean that defines if the modeling object should be define as multinetwork.
`pmitd_ref_extensions` are the arrays of power transmission and distribution modeling extensions.
"""
function instantiate_model_decomposition(
    pm_file::String, pmd_files::Vector{String}, pmitd_file::String, pmitd_type::Type, optimizer,
    build_method::Function; multinetwork::Bool=false, pmitd_ref_extensions::Vector{<:Function}=Function[], auto_rename::Bool=false, kwargs...)

    # Read power t&d and linkage data from files.
    pmitd_data = parse_files(pm_file, pmd_files, pmitd_file; multinetwork=multinetwork, auto_rename=auto_rename)

    # Instantiate the PowerModelsITD object.
    return instantiate_model_decomposition(
        pmitd_data, pmitd_type, optimizer, build_method;
        multinetwork=multinetwork,
        pmitd_ref_extensions=pmitd_ref_extensions, kwargs...)
end


"""
    function instantiate_model_decomposition(
        pm_file::String,
        pmd_file::String,
        pmitd_file::String,
        pmitd_type::Type,
        build_method::Function;
        multinetwork::Bool=false,
        pmitd_ref_extensions::Vector{<:Function}=Function[],
        auto_rename::Bool=false,
        kwargs...
    )

Instantiates and returns a decomposition-based PowerModelsITD modeling object from power transmission,
power distribution, and boundary linking input files `pm_file`, `pmd_file` (one file provided), and `pmitd_file`,
respectively. Here, `pmitd_type` is the integrated power transmission-distribution modeling type and
`build_method` is the build method for the problem specification being considered.
`multinetwork` is the boolean that defines if the modeling object should be define as multinetwork.
`pmitd_ref_extensions` are the arrays of power transmission and distribution modeling extensions.
"""
function instantiate_model_decomposition(
    pm_file::String, pmd_file::String, pmitd_file::String, pmitd_type::Type, optimizer,
    build_method::Function; multinetwork::Bool=false, pmitd_ref_extensions::Vector{<:Function}=Function[], auto_rename::Bool=false, kwargs...)

    pmd_files = [pmd_file] # convert to vector

    # Read power t&d and linkage data from files.
    pmitd_data = parse_files(pm_file, pmd_files, pmitd_file; multinetwork=multinetwork, auto_rename=auto_rename)

    # Instantiate the PowerModelsITD object.
    return instantiate_model_decomposition(
        pmitd_data, pmitd_type, optimizer, build_method;
        multinetwork=multinetwork,
        pmitd_ref_extensions=pmitd_ref_extensions, kwargs...
    )
end


"""
    function instantiate_model_decomposition(
        pmitd_data::Dict{String,<:Any},
        pmitd_type::Type,
        optimizer,
        build_method::Function;
        multinetwork::Bool=false,
        pmitd_ref_extensions::Vector{<:Function}=Function[],
        kwargs...
    )

Instantiates and returns a decomposition-based PowerModelsITD modeling object vector from parsed power
transmission and distribution (PMITD) input data `pmitd_data`. Here, `pmitd_type` is the integrated
power transmission and distribution modeling type and `build_method` is the build method for the problem
specification being considered. `multinetwork` is the boolean that defines if the modeling object
should be define as multinetwork. `pmitd_ref_extensions` is an array of power transmission and
distribution modeling extensions.
"""
function instantiate_model_decomposition(
    pmitd_data::Dict{String,<:Any}, pmitd_type::Type, optimizer, build_method::Function;
    multinetwork::Bool=false, pmitd_ref_extensions::Vector{<:Function}=Function[], kwargs...)

    # Separate pmd ckts in a single dictionary to multiple dict entries
    pmd_separated = _separate_pmd_circuits(pmitd_data["it"][_PMD.pmd_it_name]; multinetwork=multinetwork)
    pmitd_data["it"][_PMD.pmd_it_name] = pmd_separated

    # Correct the network data and assign the respective boundary number values.
    correct_network_data_decomposition!(pmitd_data; multinetwork=multinetwork)

    # Initialize DecompositionStruct
    decomposed_models = DecompositionStruct() # intialize empty struct

    # ----- IpoptDecomposition Optimizer ------

    # PM models
    pmitd_data["it"][_PM.pm_it_name][pmitd_it_name] = pmitd_data["it"]["pmitd"]         # add pmitd(boundary) info. to pm ref

    # Instantiate the PM model
    pm_inst_model = _IM.instantiate_model(pmitd_data["it"][_PM.pm_it_name],
                                    pmitd_type.parameters[1],
                                    build_method,
                                    ref_add_core_decomposition_transmission!,
                                    _PM._pm_global_keys,
                                    _PM.pm_it_sym; kwargs...)

    decomposed_models.pm = pm_inst_model
    optimizer.master = pm_inst_model.model                                      # Add pm model to master
    JuMP.set_optimizer(optimizer.master, _IDEC.Optimizer; add_bridges = true)   # Set optimizer

    # PMD models & Boundary linking vars
    pmd_inst_models = []
    pmd_inst_JuMP_models = []
    boundary_vars_vect = []
    for (ckt_name, ckt_data) in pmitd_data["it"][_PMD.pmd_it_name]

        # Obtain ckt boundary data
        boundary_info = pmitd_data["it"][pmitd_it_name]
        boundary_number = findfirst(x -> ckt_name == x["ckt_name"], boundary_info)
        boundary_for_ckt = Dict(boundary_number => boundary_info[boundary_number])
        ckt_data[pmitd_it_name] = boundary_for_ckt                                  # add pmitd(boundary) info. to pmd ref

        # Instantiate the PMD model
        pmd_inst_model = _IM.instantiate_model(ckt_data,
                                        pmitd_type.parameters[2],
                                        build_method,
                                        ref_add_core_decomposition_distribution!,
                                        _PMD._pmd_global_keys,
                                        _PMD.pmd_it_sym; kwargs...)

        push!(pmd_inst_models, pmd_inst_model)                                              # Add pmd IM model to vector
        JuMP.set_optimizer(pmd_inst_model.model , _IDEC.Optimizer; add_bridges = true)      # Set the IDEC optimizer to the JuMP model
        push!(pmd_inst_JuMP_models, pmd_inst_model.model )                                  # push the subproblem JuMP model into the vector of subproblems

        # Boundary linking vars.
        linking_vars_vect = generate_boundary_linking_vars(pm_inst_model, pmd_inst_model, boundary_number)  # generates the respective (ACP, ACR, etc.) boundary linking vars vector.
        push!(boundary_vars_vect, linking_vars_vect)                                                        # Add linking vars vector to vector containing all vectors of linking vars.

    end

    # Add subproblems
    decomposed_models.pmd = pmd_inst_models          # Add all IM models to DecompositionStruct
    optimizer.subproblems = pmd_inst_JuMP_models     # Add all pmd JuMP models (i.e., vector) as subproblems to Optimizer

    # Boundary Linking vars
    optimizer.list_linking_vars = boundary_vars_vect

    # Add Optimizer to DecompositionStruct
    decomposed_models.optimizer = optimizer

    return decomposed_models

end


"""
    function solve_model(
        pm_file::String,
        pmd_file::String,
        pmitd_file::String,
        pmitd_type::Type,
        optimizer,
        build_method::Function;
        multinetwork::Bool=false,
        solution_processors::Vector{<:Function}=Function[],
        pmitd_ref_extensions::Vector{<:Function}=Function[],
        make_si::Bool=true,
        auto_rename::Bool=false,
        solution_model::String="eng",
        kwargs...
    )


Parses, instantiates, and solves the integrated Transmission (PowerModels) & Distribution (PowerModelsDistribution)
modeling objects from power transmission, power distribution, and boundry linking input files `pm_file`, `pmd_file`,
and `pmitd_file`, respectively. Here, `pmitd_type` is the integrated power transmission-distribution modeling type,
`optimizer` is the optimzer used to solve the problem, `build_method` is the build method for the problem
specification being considered, `multinetwork` is the boolean that defines if the modeling object should be define
as multinetwork, `solution_processors` is the vector of the model solution processors, `pmitd_ref_extensions` is
the array of modeling extensions, and `make_si` is the boolean that determines if the results are returned in SI or per-unit.
The variable `auto_rename` indicates if the user wants PMITD to automatically rename distribution systems with repeated ckt names.
`solution_model` is a string that determines in which model, ENG or MATH, the solutions are presented.
Returns a dictionary of results.
"""
function solve_model(
    pm_file::String, pmd_file::String, pmitd_file::String, pmitd_type::Type,
    optimizer,
    build_method::Function;
    multinetwork::Bool=false,
    solution_processors::Vector{<:Function}=Function[],
    pmitd_ref_extensions::Vector{<:Function}=Function[],
    make_si::Bool=true,
    auto_rename::Bool=false,
    solution_model::String="eng",
    kwargs...)

    pmd_files = [pmd_file] # convert to vector

    # Read power t&d and linkage data from files.
    pmitd_data = parse_files(pm_file, pmd_files, pmitd_file; multinetwork=multinetwork, auto_rename=auto_rename)

    # Instantiate and solve the PowerModelsITD modeling object.
    return solve_model(
        pmitd_data, pmitd_type, optimizer, build_method;
        multinetwork=multinetwork,
        solution_processors=solution_processors,
        pmitd_ref_extensions=pmitd_ref_extensions,
        make_si=make_si,
        solution_model=solution_model,
        kwargs...
    )
end



"""
    function solve_model(
        pm_file::String,
        pmd_files::Vector,
        pmitd_file::String,
        pmitd_type::Type,
        optimizer,
        build_method::Function;
        multinetwork::Bool=false,
        solution_processors::Vector{<:Function}=Function[],
        pmitd_ref_extensions::Vector{<:Function}=Function[],
        make_si::Bool=true,
        auto_rename::Bool=false,
        solution_model::String="eng",
        kwargs...
    )

Parses, instantiates, and solves the integrated Transmission (PowerModels) & Distribution (PowerModelsDistribution)
modeling objects from power transmission, multiple power distribution systems, and boundary linking input files
`pm_file`, `pmd_files` vector of files, and `pmitd_file`, respectively. Here, `pmitd_type` is the integrated power
transmission-distribution modeling type, `optimizer` is the optimzer used to solve the problem, `build_method` is
the build method for the problem specification being considered, `multinetwork` is the boolean that defines if the
modeling object should be define as multinetwork,`solution_processors` is the vector of the model solution processors,
`pmitd_ref_extensions` is the array of modeling extensions, and `make_si` is the boolean that determines
if the results are returned in SI or per-unit.
The variable `auto_rename` indicates if the user wants PMITD to automatically rename distribution systems with repeated ckt names.
`solution_model` is a string that determines in which model, ENG or MATH, the solutions are presented.
Returns a dictionary of results.
"""
function solve_model(
    pm_file::String, pmd_files::Vector, pmitd_file::String, pmitd_type::Type,
    optimizer,
    build_method::Function;
    multinetwork::Bool=false,
    solution_processors::Vector{<:Function}=Function[],
    pmitd_ref_extensions::Vector{<:Function}=Function[],
    make_si::Bool=true,
    auto_rename::Bool=false,
    solution_model::String="eng",
    kwargs...)

    # Read power t&d and linkage data from files.
    pmitd_data = parse_files(pm_file, pmd_files, pmitd_file, multinetwork=multinetwork, auto_rename=auto_rename)

    # Instantiate and solve the PowerModelsITD modeling object.
    return solve_model(
        pmitd_data, pmitd_type, optimizer, build_method;
        multinetwork=multinetwork,
        solution_processors=solution_processors,
        pmitd_ref_extensions=pmitd_ref_extensions,
        make_si=make_si,
        solution_model=solution_model,
        kwargs...
    )
end



"""
    function solve_model(
        pmitd_data::Dict{String,<:Any},
        pmitd_type::Type, optimizer,
        build_method::Function;
        multinetwork::Bool=false,
        solution_processors::Vector{<:Function}=Function[],
        pmitd_ref_extensions::Vector{<:Function}=Function[],
        make_si::Bool=true,
        solution_model::String="eng",
        kwargs...
    )

Instantiates and solves the integrated Transmission (PowerModels) & Distribution (PowerModelsDistribution)
modeling object from power integrated transmission-distribution input data, `pmitd_data`. Here, `pmitd_type`
is the integrated power transmission-distribution modeling type, `build_method` is the build method for the
problem specification being considered, `multinetwork` is the boolean that defines if the modeling object
should be define as multinetwork`, solution_processors` is the vector of the model solution processors,
`pmitd_ref_extensions` is the array of modeling extensions, and `make_si` is the boolean that determines
if the results are returned in SI or per-unit. `solution_model` is a string that determines in which model,
ENG or MATH, the solutions are presented.
Returns a dictionary of results.
"""
function solve_model(
    pmitd_data::Dict{String,<:Any},
    pmitd_type::Type, optimizer,
    build_method::Function;
    multinetwork::Bool=false,
    solution_processors::Vector{<:Function}=Function[],
    pmitd_ref_extensions::Vector{<:Function}=Function[],
    make_si::Bool=true,
    solution_model::String="eng",
    kwargs...)

    # extract build_method name (string)
    build_method_name = string(build_method)

    # Solve the model and build the result, timing both processes.
    start_time = time() # Start the timer.

    # Solve standard ITD problem
    if (typeof(optimizer) == JuMP.MOI.OptimizerWithAttributes)

        # Instantiate the PowerModelsITD object.
        pmitd = instantiate_model(
            pmitd_data, pmitd_type, build_method;
            multinetwork=multinetwork,
            pmitd_ref_extensions=pmitd_ref_extensions, kwargs...)

        # Solve ITD Model
        result = _IM.optimize_model!(
            pmitd, optimizer=optimizer, solution_processors=solution_processors)

        # Inform about the time for solving the problem (*change to @debug)
        @info "pmitd model solution time (instantiate + optimization): $(time() - start_time)"

        # Transform solution (both T&D) - SI or per unit - MATH or ENG.
        if (make_si == false)
            _transform_solution_to_pu!(result, pmitd_data; make_si, multinetwork=multinetwork, solution_model=solution_model)
        else
            _transform_solution_to_si!(result, pmitd_data; make_si, multinetwork=multinetwork, solution_model=solution_model)
        end

    # Solve decomposition ITD problem
    elseif (typeof(optimizer) == _IDEC.MetaOptimizer)

        # Instantiate the Decomposition PowerModelsITD object.
        pmitd = instantiate_model_decomposition(
            pmitd_data, pmitd_type, optimizer, build_method;
            multinetwork=multinetwork,
            pmitd_ref_extensions=pmitd_ref_extensions, kwargs...)

        # Calls the _IDEC optimize!(..) function
        _, solve_time, solve_bytes_alloc, sec_in_gc = @timed _IDEC.optimize!(pmitd.optimizer)   #TODO: works but core dumped when solving any problem (NL, L).

        # Build and organize the result dictionary
        # TODO: merge the pm and pmd(s) results into a single Dict result similarly to PMITD
        result = Dict{String, Any}("it" => Dict{String, Any}("pm" => Dict{String, Any}(), "pmd" => Dict{String, Any}()))
        result["it"]["pm"] = _IM.build_result(pmitd.pm, solve_time)

        pmd_count = 1
        for pmd in pmitd.pmd
            result["it"]["pmd"]["ckt_$(pmd_count)"] = _IM.build_result(pmitd.pmd[pmd_count], solve_time)
            pmd_count += 1
        end

        # Inform about the time for solving the problem (*change to @debug)
        @info "pmitd decomposition model solution time (instantiate + optimization): $(time() - start_time)"

        # TODO: Transform solution (both T&D) - SI or per unit - MATH or ENG.

    else
        @error "The problem specification (build_method) or optimizer defined is not supported! Please use a supported optimizer or build_method."
        throw(error())
    end

    return result
end
