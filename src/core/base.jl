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
        eng2math_passthrough=eng2math_passthrough,
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
        eng2math_passthrough::Dict{String,Vector{String}}=Dict{String,Vector{String}}(),
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
`eng2math_passthrough` are the passthrough vectors to be considered by the PMD MATH models.
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
    eng2math_passthrough::Dict{String,Vector{String}}=Dict{String,Vector{String}}(),
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
        eng2math_passthrough=eng2math_passthrough,
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
        eng2math_passthrough::Dict{String,Vector{String}}=Dict{String,Vector{String}}(),
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
if the results are returned in SI or per-unit. `eng2math_passthrough` are the passthrough vectors to be
considered by the PMD MATH models. `solution_model` is a string that determines in which model,
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
    eng2math_passthrough::Dict{String,Vector{String}}=Dict{String,Vector{String}}(),
    make_si::Bool=true,
    solution_model::String="eng",
    kwargs...)

    # Solve the model and build the result, timing both processes.
    start_time = time() # Start the timer.

    # Instantiate the PowerModelsITD object.
    pmitd = instantiate_model(
        pmitd_data, pmitd_type, build_method;
        multinetwork=multinetwork,
        pmitd_ref_extensions=pmitd_ref_extensions,
        eng2math_passthrough=eng2math_passthrough,
        kwargs...)

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

    return result
end
