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
        eng2math_passthrough::Dict{String,Vector{String}}=Dict{String,Vector{String}}(),
        auto_rename::Bool=false,
        kwargs...
    )

Instantiates and returns PowerModelsITD modeling object from power transmission,
power distribution, and boundary linking input files `pm_file`, `pmd_files` vector, and `pmitd_file`,
respectively. Here, `pmitd_type` is the integrated power transmission-distribution modeling type and
`build_method` is the build method for the problem specification being considered.
`multinetwork` is the boolean that defines if the modeling object should be define as multinetwork.
`pmitd_ref_extensions` are the arrays of power transmission and distribution modeling extensions.
`eng2math_passthrough` are the passthrough vectors to be considered by the PMD MATH models.
"""
function instantiate_model(
    pm_file::String, pmd_files::Vector{String}, pmitd_file::String, pmitd_type::Type,
    build_method::Function; multinetwork::Bool=false, pmitd_ref_extensions::Vector{<:Function}=Function[],
    eng2math_passthrough::Dict{String,Vector{String}}=Dict{String,Vector{String}}(), auto_rename::Bool=false, kwargs...)

    # Read power t&d and linkage data from files.
    pmitd_data = parse_files(pm_file, pmd_files, pmitd_file; multinetwork=multinetwork, auto_rename=auto_rename)

    # Instantiate the PowerModelsITD object.
    return instantiate_model(
        pmitd_data, pmitd_type, build_method;
        multinetwork=multinetwork,
        pmitd_ref_extensions=pmitd_ref_extensions,
        eng2math_passthrough=eng2math_passthrough,
        kwargs...)
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
        eng2math_passthrough::Dict{String,Vector{String}}=Dict{String,Vector{String}}(),
        auto_rename::Bool=false,
        kwargs...
    )

Instantiates and returns PowerModelsITD modeling object from power transmission,
power distribution, and boundary linking input files `pm_file`, `pmd_file` (one file provided), and `pmitd_file`,
respectively. Here, `pmitd_type` is the integrated power transmission-distribution modeling type and
`build_method` is the build method for the problem specification being considered.
`multinetwork` is the boolean that defines if the modeling object should be define as multinetwork.
`pmitd_ref_extensions` are the arrays of power transmission and distribution modeling extensions.
`eng2math_passthrough` are the passthrough vectors to be considered by the PMD MATH models.
"""
function instantiate_model(
    pm_file::String, pmd_file::String, pmitd_file::String, pmitd_type::Type,
    build_method::Function; multinetwork::Bool=false, pmitd_ref_extensions::Vector{<:Function}=Function[],
    eng2math_passthrough::Dict{String,Vector{String}}=Dict{String,Vector{String}}(), auto_rename::Bool=false, kwargs...)

    pmd_files = [pmd_file] # convert to vector

    # Read power t&d and linkage data from files.
    pmitd_data = parse_files(pm_file, pmd_files, pmitd_file; multinetwork=multinetwork, auto_rename=auto_rename)

    # Instantiate the PowerModelsITD object.
    return instantiate_model(
        pmitd_data, pmitd_type, build_method;
        multinetwork=multinetwork,
        pmitd_ref_extensions=pmitd_ref_extensions,
        eng2math_passthrough=eng2math_passthrough,
        kwargs...
    )
end


"""
    function instantiate_model(
        pmitd_data::Dict{String,<:Any},
        pmitd_type::Type,
        build_method::Function;
        multinetwork::Bool=false,
        pmitd_ref_extensions::Vector{<:Function}=Function[],
        eng2math_passthrough::Dict{String,Vector{String}}=Dict{String,Vector{String}}(),
        kwargs...
    )

Instantiates and returns PowerModelsITD modeling object from parsed power transmission
and distribution (PMITD) input data `pmitd_data`. Here, `pmitd_type` is the integrated power
transmission and distribution modeling type and `build_method` is the build method for the problem
specification being considered.
`multinetwork` is the boolean that defines if the modeling object should be define as multinetwork.
`pmitd_ref_extensions` is an array of power transmission and distribution modeling extensions.
`eng2math_passthrough` are the passthrough vectors to be considered by the PMD MATH models.
"""
function instantiate_model(
    pmitd_data::Dict{String,<:Any}, pmitd_type::Type, build_method::Function;
    multinetwork::Bool=false, pmitd_ref_extensions::Vector{<:Function}=Function[],
    eng2math_passthrough::Dict{String,Vector{String}}=Dict{String,Vector{String}}(), kwargs...)

    # Extract PMD model/data
    pmd_data = pmitd_data["it"][_PMD.pmd_it_name]

    # transform PMD data (only) from ENG to MATH Model
    if (!_PMD.ismath(pmd_data))
        pmitd_data["it"][_PMD.pmd_it_name] = _PMD.transform_data_model(pmd_data;
                                                                    multinetwork=multinetwork,
                                                                    eng2math_passthrough=eng2math_passthrough)
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
        export_models::Bool=false,
        kwargs...
    )

Instantiates and returns a decomposition-based PowerModelsITD modeling object from power transmission,
power distribution, and boundary linking input files `pm_file`, `pmd_files` vector, and `pmitd_file`,
respectively. Here, `pmitd_type` is the integrated power transmission-distribution modeling type and
`build_method` is the build method for the problem specification being considered.
`multinetwork` is the boolean that defines if the modeling object should be define as multinetwork.
`pmitd_ref_extensions` are the arrays of power transmission and distribution modeling extensions.
The parameter `export_models` is a boolean that determines if the JuMP models are exported to the pwd as `.mof.json` files.
"""
function instantiate_model_decomposition(
    pm_file::String, pmd_files::Vector{String}, pmitd_file::String, pmitd_type::Type, optimizer,
    build_method::Function; multinetwork::Bool=false, pmitd_ref_extensions::Vector{<:Function}=Function[],
    auto_rename::Bool=false, export_models::Bool=false, kwargs...)

    # Read power t&d and linkage data from files.
    pmitd_data = parse_files(pm_file, pmd_files, pmitd_file; multinetwork=multinetwork, auto_rename=auto_rename)

    # Instantiate the PowerModelsITD object.
    return instantiate_model_decomposition(
        pmitd_data, pmitd_type, optimizer, build_method;
        multinetwork=multinetwork,
        pmitd_ref_extensions=pmitd_ref_extensions,
        export_models=export_models, kwargs...)
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
        export_models::Bool=false,
        kwargs...
    )

Instantiates and returns a decomposition-based PowerModelsITD modeling object from power transmission,
power distribution, and boundary linking input files `pm_file`, `pmd_file` (one file provided), and `pmitd_file`,
respectively. Here, `pmitd_type` is the integrated power transmission-distribution modeling type and
`build_method` is the build method for the problem specification being considered.
`multinetwork` is the boolean that defines if the modeling object should be define as multinetwork.
`pmitd_ref_extensions` are the arrays of power transmission and distribution modeling extensions.
The parameter `export_models` is a boolean that determines if the JuMP models are exported to the pwd as `.mof.json` files.
"""
function instantiate_model_decomposition(
    pm_file::String, pmd_file::String, pmitd_file::String, pmitd_type::Type, optimizer,
    build_method::Function; multinetwork::Bool=false, pmitd_ref_extensions::Vector{<:Function}=Function[],
    auto_rename::Bool=false, export_models::Bool=false, kwargs...)

    pmd_files = [pmd_file] # convert to vector

    # Read power t&d and linkage data from files.
    pmitd_data = parse_files(pm_file, pmd_files, pmitd_file; multinetwork=multinetwork, auto_rename=auto_rename)

    # Instantiate the PowerModelsITD object.
    return instantiate_model_decomposition(
        pmitd_data, pmitd_type, optimizer, build_method;
        multinetwork=multinetwork,
        pmitd_ref_extensions=pmitd_ref_extensions,
        export_models=export_models, kwargs...
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
        export_models::Bool=false,
        kwargs...
    )

Instantiates and returns a decomposition-based PowerModelsITD modeling object vector from parsed power
transmission and distribution (PMITD) input data `pmitd_data`. Here, `pmitd_type` is the integrated
power transmission and distribution modeling type and `build_method` is the build method for the problem
specification being considered. `multinetwork` is the boolean that defines if the modeling object
should be define as multinetwork. `pmitd_ref_extensions` is an array of power transmission and
distribution modeling extensions.
The parameter `export_models` is a boolean that determines if the JuMP models are exported to the pwd as `.mof.json` files.
ParallelOptimizer Version.
"""
function instantiate_model_decomposition(
    pmitd_data::Dict{String,<:Any},
    pmitd_type::Type,
    optimizer::_SDO.ParallelOptimizer,
    build_method::Function;
    multinetwork::Bool=false,
    pmitd_ref_extensions::Vector{<:Function}=Function[],
    export_models::Bool=false, kwargs...
)

    # Separate distro. ckts from a single dictionary to multiple dictionary entries
    distro_systems_separated = _separate_pmd_circuits(pmitd_data["it"][_PMD.pmd_it_name]; multinetwork=multinetwork)
    pmitd_data["it"][_PMD.pmd_it_name] = distro_systems_separated

    # Correct the network data and assign the respective boundary number values.
    correct_network_data_decomposition!(pmitd_data; multinetwork=multinetwork)

    # Add pmitd(boundary) info. to pm ref
    pmitd_data["it"][_PM.pm_it_name][pmitd_it_name] = pmitd_data["it"][pmitd_it_name]

    # Instantiate the PM model
    master_instantiated = _IM.instantiate_model(pmitd_data["it"][_PM.pm_it_name],
                                    pmitd_type.parameters[1],
                                    build_method,
                                    ref_add_core_decomposition_transmission!,
                                    _PM._pm_global_keys,
                                    _PM.pm_it_sym; kwargs...
    )

    # Export mof.json models
    if export_models
        JuMP.write_to_file(master_instantiated.model, "master_model_exported.mof.json")
    end

    # Add master model to optimizer and set optimizer
    optimizer.master = master_instantiated.model
    JuMP.set_optimizer(optimizer.master, _SDO.Optimizer; add_bridges = true)

    # Get the number of subproblems
    number_of_subproblems = length(pmitd_data["it"][_PMD.pmd_it_name])

    # Convert distro. dictionary to arrays for threaded version
    ckts_names_vector = collect(keys(pmitd_data["it"][_PMD.pmd_it_name]))
    ckts_data_vector = collect(values(pmitd_data["it"][_PMD.pmd_it_name]))

    # Workers vector
    workers_vector = Distributed.workers()

    # Number of workers defined
    number_of_workers = length(workers_vector)

    # Check that workers_vector >= number_of_subprobs
    if (number_of_workers < number_of_subproblems)
        # Removes workers no longer needed.
        Distributed.rmprocs(workers_vector)
        # Display error.
        error("Number of workers = $(number_of_workers), Number of subproblems = $(number_of_subproblems).
            Workers (processes) must be equal or more than the number of subproblems defined; please allocate more processes."
        )
    end

    # RemoteChannel to communicate MP and SP strings (It needs to be a )
    mp_string_vector_rcs = Vector{Distributed.RemoteChannel}(undef, number_of_subproblems)
    sp_string_vector_rcs = Vector{Distributed.RemoteChannel}(undef, number_of_subproblems)

    # RemoteChannel to communicate subproblems that should finalize the Subproblems
    status_signal_vector_rcs = Vector{Distributed.RemoteChannel}(undef, number_of_subproblems)

    # Set-up the master boundary linking vars
    master_boundary_vars_vector = Vector{Vector{Vector{JuMP.VariableRef}}}(undef, number_of_subproblems)

    # Threaded loop for instantiating subproblems
    # Threads.@threads for i in 1:1:number_of_subproblems # faster but causes +RAM usage
    for i in 1:1:number_of_subproblems
        ckt_name = ckts_names_vector[i]
        ckt_data = ckts_data_vector[i]

        # Obtain ckt boundary data
        boundary_info = pmitd_data["it"][pmitd_it_name]
        boundary_number = findfirst(x -> ckt_name == x["ckt_name"], boundary_info)
        boundary_for_ckt = Dict(boundary_number => boundary_info[boundary_number])

        # Add ckt_name to ckt_data for instantiation
        ckt_data["ckt_name"] = ckt_name
        ckt_data[pmitd_it_name] = boundary_for_ckt

        # Initialize MP and SP in RemoteChannel
        mp_string_vector_rcs[i] = Distributed.RemoteChannel(()->Channel{String}(1))
        sp_string_vector_rcs[i] = Distributed.RemoteChannel(()->Channel{String}(1))

        # Initialize MP and SP in RemoteChannel
        status_signal_vector_rcs[i] = Distributed.RemoteChannel(()->Channel{String}(1))

        # Spawn subprocess for subproblem
        Distributed.remote_do(optimize_subproblem_multiprocessing,
                                workers_vector[i],
                                ckt_data,
                                pmitd_type.parameters[2],
                                build_method,
                                status_signal_vector_rcs[i],
                                mp_string_vector_rcs[i],
                                sp_string_vector_rcs[i],
                                i,
                                number_of_subproblems;
                                export_models=export_models
        )

        # Generate master linking vars
        master_linking_vars_vector = generate_boundary_linking_vars_transmission(master_instantiated,
                                                                                boundary_number;
                                                                                export_models=export_models
        )

        # Add linking vars vector to vector containing all vectors of linking vars.
        master_boundary_vars_vector[i] = master_linking_vars_vector

    end

    # Add vector of subproblems JuMP models (empty JuMP vector) and boundary linking vars
    optimizer.subproblems = Vector{JuMP.Model}(undef, number_of_subproblems)
    optimizer.list_linking_vars = master_boundary_vars_vector

    # Add RemoteChannels to the optimizer
    optimizer.status_signal_channel = status_signal_vector_rcs
    optimizer.mp_string_vector_channel = mp_string_vector_rcs
    optimizer.sp_string_vector_channel = sp_string_vector_rcs

    # return optimizer, master model
    return optimizer, master_instantiated

end


"""
    function instantiate_model_decomposition(
        pmitd_data::Dict{String,<:Any},
        pmitd_type::Type,
        optimizer,
        build_method::Function;
        multinetwork::Bool=false,
        pmitd_ref_extensions::Vector{<:Function}=Function[],
        export_models::Bool=false,
        kwargs...
    )

Instantiates and returns a decomposition-based PowerModelsITD modeling object vector from parsed power
transmission and distribution (PMITD) input data `pmitd_data`. Here, `pmitd_type` is the integrated
power transmission and distribution modeling type and `build_method` is the build method for the problem
specification being considered. `multinetwork` is the boolean that defines if the modeling object
should be define as multinetwork. `pmitd_ref_extensions` is an array of power transmission and
distribution modeling extensions.
The parameter `export_models` is a boolean that determines if the JuMP models are exported to the pwd as `.mof.json` files.
MultiThreadOptimizer Version.
"""
function instantiate_model_decomposition(
    pmitd_data::Dict{String,<:Any},
    pmitd_type::Type,
    optimizer::_SDO.MultiThreadOptimizer,
    build_method::Function;
    multinetwork::Bool=false,
    pmitd_ref_extensions::Vector{<:Function}=Function[],
    export_models::Bool=false, kwargs...
)

    # Separate distro. ckts from a single dictionary to multiple dictionary entries
    distro_systems_separated = _separate_pmd_circuits(pmitd_data["it"][_PMD.pmd_it_name]; multinetwork=multinetwork)
    pmitd_data["it"][_PMD.pmd_it_name] = distro_systems_separated

    # Correct the network data and assign the respective boundary number values.
    correct_network_data_decomposition!(pmitd_data; multinetwork=multinetwork)

    # Add pmitd(boundary) info. to pm ref
    pmitd_data["it"][_PM.pm_it_name][pmitd_it_name] = pmitd_data["it"][pmitd_it_name]

    # Instantiate the PM model
    master_instantiated = _IM.instantiate_model(pmitd_data["it"][_PM.pm_it_name],
                                    pmitd_type.parameters[1],
                                    build_method,
                                    ref_add_core_decomposition_transmission!,
                                    _PM._pm_global_keys,
                                    _PM.pm_it_sym; kwargs...
    )

    # Export master model if required
    if export_models
        JuMP.write_to_file(master_instantiated.model, "master_model_exported.mof.json")
    end

    # Add master model to optimizer and set optimizer
    optimizer.master = master_instantiated.model
    JuMP.set_optimizer(optimizer.master, _SDO.Optimizer; add_bridges = true)

    # Get the number of subproblems
    number_of_subproblems = length(pmitd_data["it"][_PMD.pmd_it_name])

    # Convert distro. dictionary to arrays for threaded version
    ckts_names_vector = collect(keys(pmitd_data["it"][_PMD.pmd_it_name]))
    ckts_data_vector = collect(values(pmitd_data["it"][_PMD.pmd_it_name]))

    # Pre-allocate space for subproblems and boundary variables
    subproblems_instantiated_models = Vector{pmitd_type.parameters[2]}(undef, number_of_subproblems)
    subproblems_JuMP_models = Vector{JuMP.Model}(undef, number_of_subproblems)
    boundary_vars_vector = Vector{Vector{Vector{JuMP.VariableRef}}}(undef, number_of_subproblems)

    # Threaded loop for instantiating subproblems
    # Threads.@threads for i in 1:1:number_of_subproblems # faster but causes +RAM usage
    for i in 1:number_of_subproblems
        ckt_name = ckts_names_vector[i]
        ckt_data = ckts_data_vector[i]

        # Obtain ckt boundary data
        boundary_info = pmitd_data["it"][pmitd_it_name]
        boundary_number = findfirst(x -> ckt_name == x["ckt_name"], boundary_info)
        boundary_for_ckt = Dict(boundary_number => boundary_info[boundary_number])

        # Add ckt_name to ckt_data for instantiation
        ckt_data["ckt_name"] = ckt_name
        ckt_data[pmitd_it_name] = boundary_for_ckt

        # --- Presolve Admittance PF ---
        try
            presolve_pf = _PMD.compute_mc_pf(ckts_data_vector[i]; max_iter=20)
            # Initialize the voltage and angles based on PF presolve
            for (bus_num, bus_data) in presolve_pf["solution"]["bus"]
                ckts_data_vector[i]["bus"][bus_num]["vm_start"] = bus_data["vm"]
                ckts_data_vector[i]["bus"][bus_num]["va_start"] = bus_data["va"]
            end

            # Initialize the generators based on PF presolve
            for (gen_num, gen_data) in presolve_pf["solution"]["gen"]
                gen_bus = ckts_data_vector[i]["gen"][gen_num]["gen_bus"]
                vr = ckts_data_vector[i]["bus"]["$(gen_bus)"]["vr_start"]
                vi = ckts_data_vector[i]["bus"]["$(gen_bus)"]["vi_start"]
                crg = presolve_pf["solution"]["gen"][gen_num]["crg"]
                cig = presolve_pf["solution"]["gen"][gen_num]["cig"]
                length_of_pg = length(ckts_data_vector[i]["gen"][gen_num]["pg"])
                pg_start = Vector{Float64}(undef, length_of_pg)
                qg_start = Vector{Float64}(undef, length_of_pg)
                for phase in 1:1:length_of_pg
                    pg = vr[phase]*crg[phase] + vi[phase]*cig[phase]
                    qg = vi[phase]*crg[phase] - vr[phase]*cig[phase]
                    pg_start[phase] = pg
                    qg_start[phase] = qg
                end
                ckts_data_vector[i]["gen"][gen_num]["pg_start"] = -pg_start
                ckts_data_vector[i]["gen"][gen_num]["qg_start"] = -qg_start
            end

            # Initialize the branches based on PF presolve
            for (branch_num, branch_data) in presolve_pf["solution"]["branch"]
                branch_fbus = ckts_data_vector[i]["branch"][branch_num]["f_bus"]
                branch_tbus = ckts_data_vector[i]["branch"][branch_num]["t_bus"]

                vr_fbus = ckts_data_vector[i]["bus"]["$(branch_fbus)"]["vr_start"]
                vi_fbus = ckts_data_vector[i]["bus"]["$(branch_fbus)"]["vi_start"]

                vr_tbus = ckts_data_vector[i]["bus"]["$(branch_tbus)"]["vr_start"]
                vi_tbus = ckts_data_vector[i]["bus"]["$(branch_tbus)"]["vi_start"]

                cr = presolve_pf["solution"]["branch"][branch_num]["cr"]
                ci = presolve_pf["solution"]["branch"][branch_num]["ci"]

                length_of_conns_f = length(ckts_data_vector[i]["branch"][branch_num]["f_connections"])
                length_of_conns_t = length(ckts_data_vector[i]["branch"][branch_num]["t_connections"])

                pf_start = Vector{Float64}(undef, length_of_conns_f)
                qf_start = Vector{Float64}(undef, length_of_conns_f)

                pt_start = Vector{Float64}(undef, length_of_conns_t)
                qt_start = Vector{Float64}(undef, length_of_conns_t)

                for phase in 1:1:length_of_conns_f
                    pf = vr_fbus[phase]*cr[phase] + vi_fbus[phase]*ci[phase]
                    qf = vi_fbus[phase]*cr[phase] - vr_fbus[phase]*ci[phase]
                    pf_start[phase] = pf
                    qf_start[phase] = qf
                end

                for phase in 1:1:length_of_conns_t
                    pt = vr_tbus[phase]*cr[phase] + vi_tbus[phase]*ci[phase]
                    qt = vi_tbus[phase]*cr[phase] - vr_tbus[phase]*ci[phase]
                    pt_start[phase] = pt
                    qt_start[phase] = qt
                end

                ckts_data_vector[i]["branch"][branch_num]["pf_start"] = pf_start
                ckts_data_vector[i]["branch"][branch_num]["qf_start"] = qf_start

                ckts_data_vector[i]["branch"][branch_num]["pt_start"] = pt_start
                ckts_data_vector[i]["branch"][branch_num]["qt_start"] = qt_start
            end
        catch
            @warn "Couldn't solve the PF for $(ckts_names_vector[i])"
             # Initialize the generators using zeros when PF fails
            for (gen_num, _) in ckts_data_vector[i]["gen"]
                length_of_pg = length(ckts_data_vector[i]["gen"][gen_num]["pg"])
                ckts_data_vector[i]["gen"][gen_num]["pg_start"] = zeros(length_of_pg)
                ckts_data_vector[i]["gen"][gen_num]["qg_start"] = zeros(length_of_pg)
            end
        end
        # -------------------------------------------------------------

        # Instantiate the PMD model
        subproblem_instantiated = _IM.instantiate_model(ckt_data,
                                        pmitd_type.parameters[2],
                                        build_method,
                                        ref_add_core_decomposition_distribution!,
                                        _PMD._pmd_global_keys,
                                        _PMD.pmd_it_sym; kwargs...
        )

        # Add instantiated subproblem to vector
        subproblems_instantiated_models[i] = subproblem_instantiated

        # Export subproblem model if required
        if export_models
            JuMP.write_to_file(subproblem_instantiated.model, "subproblem_$(i)_$(ckt_name)_$(boundary_number)_model_exported.mof.json")
        end

        # Set the optimizer to the instantiated subproblem JuMP model
        JuMP.set_optimizer(subproblem_instantiated.model, _SDO.Optimizer; add_bridges = true)

        # Add the subproblem JuMP model to the vector
        subproblems_JuMP_models[i] = subproblem_instantiated.model

        # Generate the boundary linking vars
        linking_vars_vector = generate_boundary_linking_vars(master_instantiated,
                                                              subproblem_instantiated,
                                                              boundary_number;
                                                              export_models=export_models
        )

        # Add linking vars vector to the boundary vars vector
        boundary_vars_vector[i] = linking_vars_vector
    end

    # Add vectors of subproblems JuMP models and boundary linking vars to Optimizer
    optimizer.subproblems = subproblems_JuMP_models
    optimizer.list_linking_vars = boundary_vars_vector

    # Return optimizer, master model, and subproblem models
    return optimizer, master_instantiated, subproblems_instantiated_models

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
        eng2math_passthrough::Dict{String,Vector{String}}=Dict{String,Vector{String}}(),
        make_si::Bool=true,
        auto_rename::Bool=false,
        solution_model::String="eng",
        distribution_basekva::Float64=0.0,
        export_models::Bool=false,
        kwargs...
    )


Parses, instantiates, and solves the integrated Transmission (PowerModels) & Distribution (PowerModelsDistribution)
modeling objects from power transmission, power distribution, and boundry linking input files `pm_file`, `pmd_file`,
and `pmitd_file`, respectively. Here, `pmitd_type` is the integrated power transmission-distribution modeling type,
`optimizer` is the optimzer used to solve the problem, `build_method` is the build method for the problem
specification being considered, `multinetwork` is the boolean that defines if the modeling object should be define
as multinetwork, `solution_processors` is the vector of the model solution processors, `pmitd_ref_extensions` is
the array of modeling extensions, and `make_si` is the boolean that determines if the results are returned in SI or per-unit.
`eng2math_passthrough` are the passthrough vectors to be considered by the PMD MATH models.
The variable `auto_rename` indicates if the user wants PMITD to automatically rename distribution systems with repeated ckt names.
`solution_model` is a string that determines in which model, ENG or MATH, the solutions are presented.
The parameter `distribution_basekva` is used to explicitly define the power base of the distribution system(s).
The parameter `export_models` is a boolean that determines if the JuMP models are exported to the pwd as `.mof.json` files.
Returns a dictionary of results.
"""
function solve_model(
    pm_file::String, pmd_file::String, pmitd_file::String, pmitd_type::Type,
    optimizer,
    build_method::Function;
    multinetwork::Bool=false,
    solution_processors::Vector{<:Function}=Function[],
    pmitd_ref_extensions::Vector{<:Function}=Function[],
    eng2math_passthrough::Dict{String,Vector{String}}=Dict{String,Vector{String}}(),
    make_si::Bool=true,
    auto_rename::Bool=false,
    solution_model::String="eng",
    distribution_basekva::Float64=0.0,
    export_models::Bool=false,
    kwargs...)

    pmd_files = [pmd_file] # convert to vector

    # Read power t&d and linkage data from files.
    pmitd_data = parse_files(pm_file, pmd_files, pmitd_file; multinetwork=multinetwork, auto_rename=auto_rename, distribution_basekva=distribution_basekva)

    # Instantiate and solve the PowerModelsITD modeling object.
    return solve_model(
        pmitd_data, pmitd_type, optimizer, build_method;
        multinetwork=multinetwork,
        solution_processors=solution_processors,
        pmitd_ref_extensions=pmitd_ref_extensions,
        eng2math_passthrough=eng2math_passthrough,
        make_si=make_si,
        solution_model=solution_model,
        export_models=export_models,
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
        eng2math_passthrough::Dict{String,Vector{String}}=Dict{String,Vector{String}}(),
        make_si::Bool=true,
        auto_rename::Bool=false,
        solution_model::String="eng",
        distribution_basekva::Float64=0.0,
        export_models::Bool=false,
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
`eng2math_passthrough` are the passthrough vectors to be considered by the PMD MATH models.
The variable `auto_rename` indicates if the user wants PMITD to automatically rename distribution systems with repeated ckt names.
`solution_model` is a string that determines in which model, ENG or MATH, the solutions are presented.
The parameter `distribution_basekva` is used to explicitly define the power base of the distribution system(s).
The parameter `export_models` is a boolean that determines if the JuMP models are exported to the pwd as `.mof.json` files.
Returns a dictionary of results.
"""
function solve_model(
    pm_file::String, pmd_files::Vector, pmitd_file::String, pmitd_type::Type,
    optimizer,
    build_method::Function;
    multinetwork::Bool=false,
    solution_processors::Vector{<:Function}=Function[],
    pmitd_ref_extensions::Vector{<:Function}=Function[],
    eng2math_passthrough::Dict{String,Vector{String}}=Dict{String,Vector{String}}(),
    make_si::Bool=true,
    auto_rename::Bool=false,
    solution_model::String="eng",
    distribution_basekva::Float64=0.0,
    export_models::Bool=false,
    kwargs...)

    # Read power t&d and linkage data from files.
    pmitd_data = parse_files(pm_file, pmd_files, pmitd_file, multinetwork=multinetwork, auto_rename=auto_rename, distribution_basekva=distribution_basekva)

    # Instantiate and solve the PowerModelsITD modeling object.
    return solve_model(
        pmitd_data, pmitd_type, optimizer, build_method;
        multinetwork=multinetwork,
        solution_processors=solution_processors,
        pmitd_ref_extensions=pmitd_ref_extensions,
        eng2math_passthrough=eng2math_passthrough,
        make_si=make_si,
        solution_model=solution_model,
        export_models=export_models,
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
        eng2math_passthrough::Dict{String,Vector{String}}=Dict{String,Vector{String}}(),
        make_si::Bool=true,
        solution_model::String="eng",
        export_models::Bool=false,
        kwargs...
    )

Instantiates and solves the integrated Transmission (PowerModels) & Distribution (PowerModelsDistribution)
modeling object from power integrated transmission-distribution input data, `pmitd_data`. Here, `pmitd_type`
is the integrated power transmission-distribution modeling type, `build_method` is the build method for the
problem specification being considered, `multinetwork` is the boolean that defines if the modeling object
should be define as multinetwork`, solution_processors` is the vector of the model solution processors,
`pmitd_ref_extensions` is the array of modeling extensions, and `make_si` is the boolean that determines
if the results are returned in SI or per-unit. `eng2math_passthrough` are the passthrough vectors to be
considered by the PMD MATH models. `solution_model` is a string that determines in which model,
ENG or MATH, the solutions are presented.
The parameter `export_models` is a boolean that determines if the JuMP models are exported to the pwd as `.mof.json` files.
Returns a dictionary of results.
"""
function solve_model(
    pmitd_data::Dict{String,<:Any},
    pmitd_type::Type, optimizer,
    build_method::Function;
    multinetwork::Bool=false,
    solution_processors::Vector{<:Function}=Function[],
    pmitd_ref_extensions::Vector{<:Function}=Function[],
    eng2math_passthrough::Dict{String,Vector{String}}=Dict{String,Vector{String}}(),
    make_si::Bool=true,
    solution_model::String="eng",
    export_models::Bool=false,
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
            pmitd_ref_extensions=pmitd_ref_extensions,
            eng2math_passthrough=eng2math_passthrough,
            kwargs...)

        # Export nl models
        if (export_models == true)
            # Export model to nl file
            JuMP.write_to_file(pmitd.model, "integrated_$(build_method_name)_model_exported.mof.json")
            # Open file where shared vars indices are going to be written
            file = open("integrated_vars_indices.txt", "a")
            # Loop through all variables and write them to a file
            av = JuMP.all_variables(pmitd.model);
            for v in av
                str_to_write = "Variable: $(v), Index: $(_SDO.column(v.index))\n"
                write(file, str_to_write)
            end
            # Close the file
            close(file)
        end

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
    elseif (typeof(optimizer) == _SDO.ParallelOptimizer)

        # Instantiate the Decomposition PowerModelsITD object.
        pmitd_optimizer, transmission_instantiated = instantiate_model_decomposition(
            pmitd_data,
            pmitd_type,
            optimizer,
            build_method;
            multinetwork=multinetwork,
            pmitd_ref_extensions=pmitd_ref_extensions,
            export_models=export_models,
            kwargs...
        )

        # Calls the _SDO optimize!(..) function and solves decomposition problem
        _, solve_time, solve_bytes_alloc, sec_in_gc = @timed _SDO.optimize!(pmitd_optimizer)

        # Build the master decomposition solution
        result = build_pm_decomposition_solution(transmission_instantiated, solve_time)

        # Inform about the time for solving the problem (*change to @debug)
        @info "pmitd decomposition model solution time (instantiate + optimization): $(time() - start_time)"

        # Transform solution (both T&D) - SI or per unit - MATH or ENG.
        if (make_si == false)
            _transform_decomposition_solution_to_pu!(result, pmitd_data; make_si, multinetwork=multinetwork, solution_model=solution_model)
        else
            _transform_decomposition_solution_to_si!(result, pmitd_data; make_si, multinetwork=multinetwork, solution_model=solution_model)
        end

        # Force call Garbage collector to reduce RAM usage
        GC.gc()

        # # Remove Processes
        # Distributed.rmprocs(Distributed.workers())

    elseif (typeof(optimizer) == _SDO.MultiThreadOptimizer)

        # Instantiate the Decomposition PowerModelsITD object.
        pmitd_optimizer, transmission_instantiated, subproblems_instantiated = instantiate_model_decomposition(
            pmitd_data,
            pmitd_type,
            optimizer,
            build_method;
            multinetwork=multinetwork,
            pmitd_ref_extensions=pmitd_ref_extensions,
            export_models=export_models,
            kwargs...
        )

        # Calls the _SDO optimize!(..) function and solves decomposition problem
        _, solve_time, solve_bytes_alloc, sec_in_gc = @timed _SDO.optimize!(pmitd_optimizer)

        # Build the decomposition result/solution
        result = build_pm_decomposition_solution(transmission_instantiated, solve_time)
        result["solution"]["it"][_PMD.pmd_it_name] = Dict()
        for d in subproblems_instantiated
            ckt_name = d.data["ckt_name"]
            build_soln = build_pmd_decomposition_solution(d, solve_time)
            result["solution"]["it"][_PMD.pmd_it_name][ckt_name] = build_soln["solution"]["it"]["pmd"]["solution"]

            # Add boundary info. to PMITD dict.
            for (b_name, b_data) in result["solution"]["it"][_PMD.pmd_it_name][ckt_name]["boundary"]
                result["solution"]["it"][pmitd_it_name]["boundary"][b_name]["pbound_aux"] = b_data["pbound_aux"]
                if haskey(b_data, "qbound_aux")
                    result["solution"]["it"][pmitd_it_name]["boundary"][b_name]["qbound_aux"] = b_data["qbound_aux"]
                end
            end

        end

        # Inform about the time for solving the problem (*change to @debug)
        @info "pmitd decomposition model solution time (instantiate + optimization): $(time() - start_time)"

        # Transform solution (both T&D) - SI or per unit - MATH or ENG.
        if (make_si == false)
            _transform_decomposition_solution_to_pu!(result, pmitd_data; make_si, multinetwork=multinetwork, solution_model=solution_model)
        else
            _transform_decomposition_solution_to_si!(result, pmitd_data; make_si, multinetwork=multinetwork, solution_model=solution_model)
        end

        # Force call Garbage collector to reduce RAM usage
        GC.gc()

    else
        @error "The problem specification (build_method) or optimizer defined is not supported! Please use a supported optimizer or build_method."
        throw(error())
    end

    # Inform about the time for solving the problem (*change to @debug)
    @info "pmitd decomposition model solution time (instantiate + optimization): $(time() - start_time)"

    return result
end
