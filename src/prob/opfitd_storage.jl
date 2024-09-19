# Definitions for solving the integrated T&D opf problem with storage opf dispatch

"""
	function solve_opfitd_storage(
        pm_file,
        pmd_file,
        pmitd_file,
        pmitd_type,
        optimizer;
        solution_processors::Vector{<:Function}=Function[],
        pmitd_ref_extensions::Vector{<:Function}=Vector{Function}([]),
        eng2math_passthrough::Dict{String,Vector{String}}=Dict{String,Vector{String}}(),
        make_si::Bool=true,
        auto_rename::Bool=false,
        solution_model::String="eng",
        export_models::Bool=false,
        kwargs...
	)

Solve Integrated T&D Optimal Power Flow with Storage OPF Dispatch.
"""
function solve_opfitd_storage(pm_file, pmd_file, pmitd_file, pmitd_type, optimizer; solution_processors::Vector{<:Function}=Function[], pmitd_ref_extensions::Vector{<:Function}=Vector{Function}([]), eng2math_passthrough::Dict{String,Vector{String}}=Dict{String,Vector{String}}(), make_si::Bool=true, auto_rename::Bool=false, solution_model::String="eng", export_models::Bool=false, kwargs...)

    if isempty(eng2math_passthrough)
        eng2math_passthrough = Dict("storage"=>["cost"])    # by default, pass the eng2math passthrough
    else
        eng2math_pass_strg = "storage"=>["cost"]
        push!(eng2math_passthrough, eng2math_pass_strg)
    end

    return solve_model(pm_file, pmd_file, pmitd_file, pmitd_type, optimizer, build_opfitd_storage; solution_processors=solution_processors, pmitd_ref_extensions=pmitd_ref_extensions, eng2math_passthrough=eng2math_passthrough, make_si=make_si, auto_rename=auto_rename, solution_model=solution_model, export_models=export_models, kwargs...)
end


"""
	function solve_opfitd_storage(
        pmitd_data::Dict{String,<:Any},
        pmitd_type,
        optimizer;
        solution_processors::Vector{<:Function}=Function[],
        pmitd_ref_extensions::Vector{<:Function}=Vector{Function}([]),
        eng2math_passthrough::Dict{String,Vector{String}}=Dict{String,Vector{String}}(),
        make_si::Bool=true,
        solution_model::String="eng",
        export_models::Bool=false,
        kwargs...
	)

Solve Integrated T&D Optimal Power Flow with Storage OPF Dispatch.
"""
function solve_opfitd_storage(pmitd_data::Dict{String,<:Any}, pmitd_type, optimizer; solution_processors::Vector{<:Function}=Function[], pmitd_ref_extensions::Vector{<:Function}=Vector{Function}([]), eng2math_passthrough::Dict{String,Vector{String}}=Dict{String,Vector{String}}(), make_si::Bool=true, solution_model::String="eng", export_models::Bool=false, kwargs...)

    if isempty(eng2math_passthrough)
        eng2math_passthrough = Dict("storage"=>["cost"])    # by default, pass the eng2math passthrough
    else
        eng2math_pass_strg = "storage"=>["cost"]
        push!(eng2math_passthrough, eng2math_pass_strg)
    end

    return solve_model(pmitd_data, pmitd_type, optimizer, build_opfitd_storage; solution_processors=solution_processors, pmitd_ref_extensions=pmitd_ref_extensions, eng2math_passthrough=eng2math_passthrough, make_si=make_si, solution_model=solution_model, export_models=export_models, kwargs...)
end


"""
	function solve_mn_opfitd_storage(
        pm_file,
        pmd_file,
        pmitd_file,
        pmitd_type,
        optimizer;
        solution_processors::Vector{<:Function}=Function[],
        pmitd_ref_extensions::Vector{<:Function}=Vector{Function}([]),
        eng2math_passthrough::Dict{String,Vector{String}}=Dict{String,Vector{String}}(),
        make_si::Bool=true,
        auto_rename::Bool=false,
        solution_model::String="eng",
        export_models::Bool=false,
        kwargs...
	)

Solve Multinetwork Integrated T&D Optimal Power Flow with Storage OPF Dispatch.
"""
function solve_mn_opfitd_storage(pm_file, pmd_file, pmitd_file, pmitd_type, optimizer; solution_processors::Vector{<:Function}=Function[], pmitd_ref_extensions::Vector{<:Function}=Vector{Function}([]), eng2math_passthrough::Dict{String,Vector{String}}=Dict{String,Vector{String}}(), make_si::Bool=true, auto_rename::Bool=false, solution_model::String="eng", export_models::Bool=false, kwargs...)

    if isempty(eng2math_passthrough)
        eng2math_passthrough = Dict("storage"=>["cost"])    # by default, pass the eng2math passthrough
    else
        eng2math_pass_strg = "storage"=>["cost"]
        push!(eng2math_passthrough, eng2math_pass_strg)
    end

    return solve_model(pm_file, pmd_file, pmitd_file, pmitd_type, optimizer, build_mn_opfitd_storage; multinetwork=true, solution_processors=solution_processors, pmitd_ref_extensions=pmitd_ref_extensions, eng2math_passthrough=eng2math_passthrough, make_si=make_si, auto_rename=auto_rename, solution_model=solution_model, export_models=export_models, kwargs...)
end


"""
	function solve_mn_opfitd_storage(
        pmitd_data::Dict{String,<:Any}
        pmitd_type,
        optimizer;
        solution_processors::Vector{<:Function}=Function[],
        pmitd_ref_extensions::Vector{<:Function}=Vector{Function}([]),
        eng2math_passthrough::Dict{String,Vector{String}}=Dict{String,Vector{String}}(),
        make_si::Bool=true,
        solution_model::String="eng",
        export_models::Bool=false,
        kwargs...
	)

Solve Multinetwork Integrated T&D Optimal Power Flow with Storage OPF Dispatch.
"""
function solve_mn_opfitd_storage(pmitd_data::Dict{String,<:Any}, pmitd_type, optimizer; solution_processors::Vector{<:Function}=Function[], pmitd_ref_extensions::Vector{<:Function}=Vector{Function}([]), eng2math_passthrough::Dict{String,Vector{String}}=Dict{String,Vector{String}}(), make_si::Bool=true, solution_model::String="eng", export_models::Bool=false, kwargs...)

    if isempty(eng2math_passthrough)
        eng2math_passthrough = Dict("storage"=>["cost"])    # by default, pass the eng2math passthrough
    else
        eng2math_pass_strg = "storage"=>["cost"]
        push!(eng2math_passthrough, eng2math_pass_strg)
    end

    return solve_model(pmitd_data, pmitd_type, optimizer, build_mn_opfitd_storage; multinetwork=true, solution_processors=solution_processors, pmitd_ref_extensions=pmitd_ref_extensions, eng2math_passthrough=eng2math_passthrough, make_si=make_si, solution_model=solution_model, export_models=export_models, kwargs...)
end


"""
	function build_opfitd_storage(
		pmitd::AbstractPowerModelITD
	)
Constructor for Integrated T&D Optimal Power Flow with Storage OPF Dispatch.
"""
function build_opfitd_storage(pmitd::AbstractPowerModelITD)

    # Get Models
    pm_model = _get_powermodel_from_powermodelitd(pmitd)
    pmd_model = _get_powermodeldistribution_from_powermodelitd(pmitd)

    # PM(Transmission) Variables
    _PM.variable_bus_voltage(pm_model)
    _PM.variable_gen_power(pm_model)
    _PM.variable_branch_power(pm_model)
    _PM.variable_dcline_power(pm_model)
    _PM.variable_storage_power(pm_model)

    # PMD(Distribution) Variables
    _PMD.variable_mc_bus_voltage(pmd_model)
    _PMD.variable_mc_branch_power(pmd_model)
    _PMD.variable_mc_transformer_power(pmd_model)
    _PMD.variable_mc_switch_power(pmd_model)
    _PMD.variable_mc_generator_power(pmd_model)
    _PMD.variable_mc_load_power(pmd_model)
    _PMD.variable_mc_storage_power(pmd_model)

    # PMITD (Boundary) Variables
    variable_boundary_power(pmitd)

    # --- PM(Transmission) Constraints ---
    _PM.constraint_model_voltage(pm_model)

    # reference buses (this only needs to happen for pm(transmission))
    for i in _PM.ids(pm_model, :ref_buses)
        _PM.constraint_theta_ref(pm_model, i)
    end

    for i in _PM.ids(pm_model, :storage)
        _PM.constraint_storage_state(pm_model, i)
        _PM.constraint_storage_complementarity_nl(pm_model, i)
        _PM.constraint_storage_losses(pm_model, i)
        _PM.constraint_storage_thermal_limit(pm_model, i)
    end

    # PM branches
    for i in _PM.ids(pm_model, :branch)
        _PM.constraint_ohms_yt_from(pm_model, i)
        _PM.constraint_ohms_yt_to(pm_model, i)

        _PM.constraint_voltage_angle_difference(pm_model, i)

        _PM.constraint_thermal_limit_from(pm_model, i)
        _PM.constraint_thermal_limit_to(pm_model, i)
    end

    # PM DC lines
    for i in _PM.ids(pm_model, :dcline)
        _PM.constraint_dcline_power_losses(pm_model, i)
    end

    # -------------------------------------------------
    # --- PMD(Distribution) Constraints ---
    _PMD.constraint_mc_model_voltage(pmd_model)

    # generators should be constrained before KCL, or Pd/Qd undefined
    for id in _PMD.ids(pmd_model, :gen)
        _PMD.constraint_mc_generator_power(pmd_model, id)
    end

    # loads should be constrained before KCL, or Pd/Qd undefined
    for id in _PMD.ids(pmd_model, :load)
        _PMD.constraint_mc_load_power(pmd_model, id)
    end

    for i in _PMD.ids(pmd_model, :storage)
        _PMD.constraint_storage_state(pmd_model, i)
        _PMD.constraint_storage_complementarity_nl(pmd_model, i)
        _PMD.constraint_mc_storage_losses(pmd_model, i)
        _PMD.constraint_mc_storage_thermal_limit(pmd_model, i)
    end

    for i in _PMD.ids(pmd_model, :branch)
        _PMD.constraint_mc_ohms_yt_from(pmd_model, i)
        _PMD.constraint_mc_ohms_yt_to(pmd_model, i)

        _PMD.constraint_mc_voltage_angle_difference(pmd_model, i)

        _PMD.constraint_mc_thermal_limit_from(pmd_model, i)
        _PMD.constraint_mc_thermal_limit_to(pmd_model, i)
        _PMD.constraint_mc_ampacity_from(pmd_model, i)
        _PMD.constraint_mc_ampacity_to(pmd_model, i)
    end

    for i in _PMD.ids(pmd_model, :switch)
        _PMD.constraint_mc_switch_state(pmd_model, i)
        _PMD.constraint_mc_switch_thermal_limit(pmd_model, i)
        _PMD.constraint_mc_switch_ampacity(pmd_model, i)
    end

    for i in _PMD.ids(pmd_model, :transformer)
        _PMD.constraint_mc_transformer_power(pmd_model, i)
    end

    # -------------------------------------------------
    # --- PMITD(T&D) INDEPENDENT Constraints ----------

    for i in ids(pmitd, :boundary)
        constraint_boundary_power(pmitd, i)
        constraint_boundary_voltage_magnitude(pmitd, i)
        constraint_boundary_voltage_angle(pmitd, i)
    end

    # -------------------------------------------------
    # --- PMITD(T&D) KCL Constraints ----------
    # Note: Both of these need to consider flow on boundaries if bus is connected to boundary
    boundary_buses_transmission = Vector{Int}() # vector to store the boundary buses transmission
    boundary_buses_distribution = Vector{Int}() # vector to store the boundary buses distribution
    for j in ids(pmitd, :boundary)
        boundary_pmitd = ref(pmitd, nw_id_default, :boundary, j)
        bus_pm = boundary_pmitd["f_bus"]
        bus_pmd = boundary_pmitd["t_bus"]
        push!(boundary_buses_transmission, bus_pm)
        push!(boundary_buses_distribution, bus_pmd)
    end
    # Convert to Julia Set - Note: membership checks are faster in sets (vs. vectors) in Julia
    boundary_buses_transmission_set = Set(boundary_buses_transmission)
    boundary_buses_distribution_set = Set(boundary_buses_distribution)

    # # ---- Transmission Power Balance ---
    for i in _PM.ids(pm_model, :bus)
        if i in boundary_buses_transmission_set
            constraint_transmission_power_balance_boundary(pmitd, i)
        else
            _PM.constraint_power_balance(pm_model, i)
        end
    end

    # ---- Distribution Power Balance ---
    for i in _PMD.ids(pmd_model, :bus)
        if i in boundary_buses_distribution_set
            constraint_distribution_power_balance_boundary(pmitd, i)
        else
            _PMD.constraint_mc_power_balance(pmd_model, i)
        end
    end

    # -------------------------------------------------
    # --- PMITD(T&D) Cost Functions -------------------
    objective_itd_min_fuel_cost_storage(pmitd)

end


"""
	function build_opfitd_storage(
		pmitd::AbstractIVRPowerModelITD
	)
Constructor for Integrated T&D Optimal Power Flow in current-voltage (IV) variable space with Storage OPF Dispatch.
"""
function build_opfitd_storage(pmitd::AbstractIVRPowerModelITD)

    @error "IVR-IVRU formulation not yet supported for storage problems."
    throw(error())

end


"""
	function build_opfitd_storage(
		pmitd::AbstractBFPowerModelITD
	)
Constructor for Integrated T&D Optimal Power Flow for BF Models with Storage OPF Dispatch.
"""
function build_opfitd_storage(pmitd::AbstractBFPowerModelITD)

    # Get Models
    pm_model = _get_powermodel_from_powermodelitd(pmitd)
    pmd_model = _get_powermodeldistribution_from_powermodelitd(pmitd)

    # PM(Transmission) Variables
    _PM.variable_bus_voltage(pm_model)
    _PM.variable_gen_power(pm_model)
    _PM.variable_branch_power(pm_model)
    _PM.variable_branch_current(pm_model)
    _PM.variable_dcline_power(pm_model)
    _PM.variable_storage_power(pm_model)


    # PMD(Distribution) Variables
    _PMD.variable_mc_bus_voltage(pmd_model)
    _PMD.variable_mc_branch_current(pmd_model)
    _PMD.variable_mc_branch_power(pmd_model)
    _PMD.variable_mc_transformer_power(pmd_model)
    _PMD.variable_mc_switch_power(pmd_model)
    _PMD.variable_mc_generator_power(pmd_model)
    _PMD.variable_mc_load_power(pmd_model)
    _PMD.variable_mc_storage_power(pmd_model)

    # PMITD (Boundary) Variables
    variable_boundary_power(pmitd)

    # --- PM(Transmission) Constraints ---
    _PM.constraint_model_current(pm_model)

    # reference buses (this only needs to happen for pm(transmission))
    for i in _PM.ids(pm_model, :ref_buses)
        _PM.constraint_theta_ref(pm_model, i)
    end

    for i in _PM.ids(pm_model, :storage)
        _PM.constraint_storage_state(pm_model, i)
        _PM.constraint_storage_complementarity_nl(pm_model, i)
        _PM.constraint_storage_losses(pm_model, i)
        _PM.constraint_storage_thermal_limit(pm_model, i)
    end

    # PM branches
    for i in _PM.ids(pm_model, :branch)
        _PM.constraint_power_losses(pm_model, i)
        _PM.constraint_voltage_magnitude_difference(pm_model, i)

        _PM.constraint_voltage_angle_difference(pm_model, i)

        _PM.constraint_thermal_limit_from(pm_model, i)
        _PM.constraint_thermal_limit_to(pm_model, i)
    end

    # PM DC lines
    for i in _PM.ids(pm_model, :dcline)
        _PM.constraint_dcline_power_losses(pm_model, i)
    end

    # -------------------------------------------------
    # --- PMD(Distribution) Constraints ---
    _PMD.constraint_mc_model_current(pmd_model)

    # generators should be constrained before KCL, or Pd/Qd undefined
    for id in _PMD.ids(pmd_model, :gen)
        _PMD.constraint_mc_generator_power(pmd_model, id)
    end

    # loads should be constrained before KCL, or Pd/Qd undefined
    for id in _PMD.ids(pmd_model, :load)
        _PMD.constraint_mc_load_power(pmd_model, id)
    end

    for i in _PMD.ids(pmd_model, :storage)
        _PMD.constraint_storage_state(pmd_model, i)
        _PMD.constraint_storage_complementarity_nl(pmd_model, i)
        _PMD.constraint_mc_storage_losses(pmd_model, i)
        _PMD.constraint_mc_storage_thermal_limit(pmd_model, i)
    end

    for i in _PMD.ids(pmd_model, :branch)
        _PMD.constraint_mc_power_losses(pmd_model, i)
        _PMD.constraint_mc_model_voltage_magnitude_difference(pmd_model, i)

        _PMD.constraint_mc_voltage_angle_difference(pmd_model, i)

        _PMD.constraint_mc_thermal_limit_from(pmd_model, i)
        _PMD.constraint_mc_thermal_limit_to(pmd_model, i)
        _PMD.constraint_mc_ampacity_from(pmd_model, i)
        _PMD.constraint_mc_ampacity_to(pmd_model, i)
    end

    for i in _PMD.ids(pmd_model, :switch)
        _PMD.constraint_mc_switch_state(pmd_model, i)
        _PMD.constraint_mc_switch_thermal_limit(pmd_model, i)
        _PMD.constraint_mc_switch_ampacity(pmd_model, i)
    end


    for i in _PMD.ids(pmd_model, :transformer)
        _PMD.constraint_mc_transformer_power(pmd_model, i)
    end


    # -------------------------------------------------
    # --- PMITD(T&D) INDEPENDENT Constraints ----------

    for i in ids(pmitd, :boundary)
        constraint_boundary_power(pmitd, i)
        constraint_boundary_voltage_magnitude(pmitd, i)
        constraint_boundary_voltage_angle(pmitd, i)
    end

    # -------------------------------------------------
    # --- PMITD(T&D) KCL Constraints ----------
    # Note: Both of these need to consider flow on boundaries if bus is connected to boundary
    boundary_buses_transmission = Vector{Int}() # vector to store the boundary buses transmission
    boundary_buses_distribution = Vector{Int}() # vector to store the boundary buses distribution
    for j in ids(pmitd, :boundary)
        boundary_pmitd = ref(pmitd, nw_id_default, :boundary, j)
        bus_pm = boundary_pmitd["f_bus"]
        bus_pmd = boundary_pmitd["t_bus"]
        push!(boundary_buses_transmission, bus_pm)
        push!(boundary_buses_distribution, bus_pmd)
    end
    # Convert to Julia Set - Note: membership checks are faster in sets (vs. vectors) in Julia
    boundary_buses_transmission_set = Set(boundary_buses_transmission)
    boundary_buses_distribution_set = Set(boundary_buses_distribution)

    # # ---- Transmission Power Balance ---
    for i in _PM.ids(pm_model, :bus)
        if i in boundary_buses_transmission_set
            constraint_transmission_power_balance_boundary(pmitd, i)
        else
            _PM.constraint_power_balance(pm_model, i)
        end
    end

    # ---- Distribution Power Balance ---
    for i in _PMD.ids(pmd_model, :bus)
        if i in boundary_buses_distribution_set
            constraint_distribution_power_balance_boundary(pmitd, i)
        else
            _PMD.constraint_mc_power_balance(pmd_model, i)
        end
    end

    # -------------------------------------------------
    # --- PMITD(T&D) Cost Functions -------------------
    objective_itd_min_fuel_cost_storage(pmitd)

end


# -- Combined (Hybrid) Formulations
"""
	function build_opfitd_storage(
		pmitd::AbstractLNLBFPowerModelITD
	)
Constructor for Integrated T&D Optimal Power Flow for L/NL to BF with Storage OPF Dispatch.
"""
function build_opfitd_storage(pmitd::AbstractLNLBFPowerModelITD)

    # Get Models
    pm_model = _get_powermodel_from_powermodelitd(pmitd)
    pmd_model = _get_powermodeldistribution_from_powermodelitd(pmitd)

    # PM(Transmission) Variables
    _PM.variable_bus_voltage(pm_model)
    _PM.variable_gen_power(pm_model)
    _PM.variable_branch_power(pm_model)
    _PM.variable_dcline_power(pm_model)
    _PM.variable_storage_power(pm_model)


    # PMD(Distribution) Variables
    _PMD.variable_mc_bus_voltage(pmd_model)
    _PMD.variable_mc_branch_current(pmd_model)
    _PMD.variable_mc_branch_power(pmd_model)
    _PMD.variable_mc_transformer_power(pmd_model)
    _PMD.variable_mc_switch_power(pmd_model)
    _PMD.variable_mc_generator_power(pmd_model)
    _PMD.variable_mc_load_power(pmd_model)
    _PMD.variable_mc_storage_power(pmd_model)

    # PMITD (Boundary) Variables
    variable_boundary_power(pmitd)

    # --- PM(Transmission) Constraints ---
    _PM.constraint_model_voltage(pm_model)

    # reference buses (this only needs to happen for pm(transmission))
    for i in _PM.ids(pm_model, :ref_buses)
        _PM.constraint_theta_ref(pm_model, i)
    end

    for i in _PM.ids(pm_model, :storage)
        _PM.constraint_storage_state(pm_model, i)
        _PM.constraint_storage_complementarity_nl(pm_model, i)
        _PM.constraint_storage_losses(pm_model, i)
        _PM.constraint_storage_thermal_limit(pm_model, i)
    end

    # PM branches
    for i in _PM.ids(pm_model, :branch)
        _PM.constraint_ohms_yt_from(pm_model, i)
        _PM.constraint_ohms_yt_to(pm_model, i)

        _PM.constraint_voltage_angle_difference(pm_model, i)

        _PM.constraint_thermal_limit_from(pm_model, i)
        _PM.constraint_thermal_limit_to(pm_model, i)
    end

    # PM DC lines
    for i in _PM.ids(pm_model, :dcline)
        _PM.constraint_dcline_power_losses(pm_model, i)
    end

    # -------------------------------------------------
    # --- PMD(Distribution) Constraints ---
    _PMD.constraint_mc_model_current(pmd_model)

    # generators should be constrained before KCL, or Pd/Qd undefined
    for id in _PMD.ids(pmd_model, :gen)
        _PMD.constraint_mc_generator_power(pmd_model, id)
    end

    # loads should be constrained before KCL, or Pd/Qd undefined
    for id in _PMD.ids(pmd_model, :load)
        _PMD.constraint_mc_load_power(pmd_model, id)
    end

    for i in _PMD.ids(pmd_model, :storage)
        _PMD.constraint_storage_state(pmd_model, i)
        _PMD.constraint_storage_complementarity_nl(pmd_model, i)
        _PMD.constraint_mc_storage_losses(pmd_model, i)
        _PMD.constraint_mc_storage_thermal_limit(pmd_model, i)
    end

    for i in _PMD.ids(pmd_model, :branch)
        _PMD.constraint_mc_power_losses(pmd_model, i)
        _PMD.constraint_mc_model_voltage_magnitude_difference(pmd_model, i)

        _PMD.constraint_mc_voltage_angle_difference(pmd_model, i)

        _PMD.constraint_mc_thermal_limit_from(pmd_model, i)
        _PMD.constraint_mc_thermal_limit_to(pmd_model, i)
        _PMD.constraint_mc_ampacity_from(pmd_model, i)
        _PMD.constraint_mc_ampacity_to(pmd_model, i)
    end

    for i in _PMD.ids(pmd_model, :switch)
        _PMD.constraint_mc_switch_state(pmd_model, i)
        _PMD.constraint_mc_switch_thermal_limit(pmd_model, i)
        _PMD.constraint_mc_switch_ampacity(pmd_model, i)
    end

    for i in _PMD.ids(pmd_model, :transformer)
        _PMD.constraint_mc_transformer_power(pmd_model, i)
    end

    # -------------------------------------------------
    # --- PMITD(T&D) INDEPENDENT Constraints ----------

    for i in ids(pmitd, :boundary)
        constraint_boundary_power(pmitd, i)
        constraint_boundary_voltage_magnitude(pmitd, i)
        constraint_boundary_voltage_angle(pmitd, i)
    end

    # -------------------------------------------------
    # --- PMITD(T&D) KCL Constraints ----------
    # Note: Both of these need to consider flow on boundaries if bus is connected to boundary
    boundary_buses_transmission = Vector{Int}() # vector to store the boundary buses transmission
    boundary_buses_distribution = Vector{Int}() # vector to store the boundary buses distribution
    for j in ids(pmitd, :boundary)
        boundary_pmitd = ref(pmitd, nw_id_default, :boundary, j)
        bus_pm = boundary_pmitd["f_bus"]
        bus_pmd = boundary_pmitd["t_bus"]
        push!(boundary_buses_transmission, bus_pm)
        push!(boundary_buses_distribution, bus_pmd)
    end
    # Convert to Julia Set - Note: membership checks are faster in sets (vs. vectors) in Julia
    boundary_buses_transmission_set = Set(boundary_buses_transmission)
    boundary_buses_distribution_set = Set(boundary_buses_distribution)

    # # ---- Transmission Power Balance ---
    for i in _PM.ids(pm_model, :bus)
        if i in boundary_buses_transmission_set
            constraint_transmission_power_balance_boundary(pmitd, i)
        else
            _PM.constraint_power_balance(pm_model, i)
        end
    end

    # ---- Distribution Power Balance ---
    for i in _PMD.ids(pmd_model, :bus)
        if i in boundary_buses_distribution_set
            constraint_distribution_power_balance_boundary(pmitd, i)
        else
            _PMD.constraint_mc_power_balance(pmd_model, i)
        end
    end

    # -------------------------------------------------
    # --- PMITD(T&D) Cost Functions -------------------
    objective_itd_min_fuel_cost_storage(pmitd)

end


# ----------------------------------------------------------------------------------------
# --- Multinetwork OPFITD Problem Specifications
# ----------------------------------------------------------------------------------------

"""
	function build_mn_opfitd_storage(
		pmitd::AbstractPowerModelITD
	)
Constructor for Multinetwork Integrated T&D Optimal Power Flow with Storage OPF Dispatch.
"""
function build_mn_opfitd_storage(pmitd::AbstractPowerModelITD)

    # Get Models
    pm_model = _get_powermodel_from_powermodelitd(pmitd)
    pmd_model = _get_powermodeldistribution_from_powermodelitd(pmitd)

    for (n, network) in nws(pmitd)
        # PM(Transmission) Variables
        _PM.variable_bus_voltage(pm_model, nw=n)
        _PM.variable_gen_power(pm_model, nw=n)
        _PM.variable_branch_power(pm_model, nw=n)
        _PM.variable_dcline_power(pm_model, nw=n)
        _PM.variable_storage_power(pm_model, nw=n)

        # PMD(Distribution) Variables
        _PMD.variable_mc_bus_voltage(pmd_model; nw=n)
        _PMD.variable_mc_branch_power(pmd_model; nw=n)
        _PMD.variable_mc_transformer_power(pmd_model; nw=n)
        _PMD.variable_mc_switch_power(pmd_model; nw=n)
        _PMD.variable_mc_generator_power(pmd_model; nw=n)
        _PMD.variable_mc_load_power(pmd_model; nw=n)
        _PMD.variable_mc_storage_power(pmd_model; nw=n)

        # PMITD (Boundary) Variables
        variable_boundary_power(pmitd; nw=n)

        # --- PM(Transmission) Constraints ---
        _PM.constraint_model_voltage(pm_model, nw=n)

        # reference buses (this only needs to happen for pm(transmission))
        for i in _PM.ids(pm_model, :ref_buses, nw=n)
            _PM.constraint_theta_ref(pm_model, i, nw=n)
        end

        for i in _PM.ids(pm_model, :storage, nw=n)
            _PM.constraint_storage_complementarity_nl(pm_model, i, nw=n)
            _PM.constraint_storage_losses(pm_model, i, nw=n)
            _PM.constraint_storage_thermal_limit(pm_model, i, nw=n)
        end

        # PM branches
        for i in _PM.ids(pm_model, :branch, nw=n)
            _PM.constraint_ohms_yt_from(pm_model, i, nw=n)
            _PM.constraint_ohms_yt_to(pm_model, i, nw=n)

            _PM.constraint_voltage_angle_difference(pm_model, i, nw=n)

            _PM.constraint_thermal_limit_from(pm_model, i, nw=n)
            _PM.constraint_thermal_limit_to(pm_model, i, nw=n)
        end

        # PM DC lines
        for i in _PM.ids(pm_model, :dcline, nw=n)
            _PM.constraint_dcline_power_losses(pm_model, i, nw=n)
        end

        # -------------------------------------------------
        # --- PMD(Distribution) Constraints ---
        _PMD.constraint_mc_model_voltage(pmd_model; nw=n)

        # generators should be constrained before KCL, or Pd/Qd undefined
        for i in _PMD.ids(pmd_model, n, :gen)
            _PMD.constraint_mc_generator_power(pmd_model, i; nw=n)
        end

        # loads should be constrained before KCL, or Pd/Qd undefined
        for i in _PMD.ids(pmd_model, n, :load)
            _PMD.constraint_mc_load_power(pmd_model, i; nw=n)
        end

        for i in _PMD.ids(pmd_model, n, :storage)
            _PMD.constraint_storage_complementarity_nl(pmd_model, i; nw=n)
            _PMD.constraint_mc_storage_losses(pmd_model, i; nw=n)
            _PMD.constraint_mc_storage_thermal_limit(pmd_model, i; nw=n)
        end

        for i in _PMD.ids(pmd_model, n, :branch)
            _PMD.constraint_mc_ohms_yt_from(pmd_model, i; nw=n)
            _PMD.constraint_mc_ohms_yt_to(pmd_model, i; nw=n)

            _PMD.constraint_mc_voltage_angle_difference(pmd_model, i; nw=n)

            _PMD.constraint_mc_thermal_limit_from(pmd_model, i; nw=n)
            _PMD.constraint_mc_thermal_limit_to(pmd_model, i; nw=n)
            _PMD.constraint_mc_ampacity_from(pmd_model, i; nw=n)
            _PMD.constraint_mc_ampacity_to(pmd_model, i; nw=n)
        end

        for i in _PMD.ids(pmd_model, n, :switch)
            _PMD.constraint_mc_switch_state(pmd_model, i; nw=n)
            _PMD.constraint_mc_switch_thermal_limit(pmd_model, i; nw=n)
            _PMD.constraint_mc_switch_ampacity(pmd_model, i; nw=n)
        end

        for i in _PMD.ids(pmd_model, n, :transformer)
            _PMD.constraint_mc_transformer_power(pmd_model, i; nw=n)
        end

        # -------------------------------------------------
        # --- PMITD(T&D) INDEPENDENT Constraints ----------

        for i in ids(pmitd, :boundary; nw=n)
            constraint_boundary_power(pmitd, i; nw=n)
            constraint_boundary_voltage_magnitude(pmitd, i; nw=n)
            constraint_boundary_voltage_angle(pmitd, i; nw=n)
        end

        # -------------------------------------------------
        # --- PMITD(T&D) KCL Constraints ----------
        # Note: Both of these need to consider flow on boundaries if bus is connected to boundary
        boundary_buses_transmission = Vector{Int}() # vector to store the boundary buses transmission
        boundary_buses_distribution = Vector{Int}() # vector to store the boundary buses distribution
        for j in ids(pmitd, :boundary; nw=n)
            boundary_pmitd = ref(pmitd, n, :boundary, j)
            bus_pm = boundary_pmitd["f_bus"]
            bus_pmd = boundary_pmitd["t_bus"]
            push!(boundary_buses_transmission, bus_pm)
            push!(boundary_buses_distribution, bus_pmd)
        end
        # Convert to Julia Set - Note: membership checks are faster in sets (vs. vectors) in Julia
        boundary_buses_transmission_set = Set(boundary_buses_transmission)
        boundary_buses_distribution_set = Set(boundary_buses_distribution)

        # # ---- Transmission Power Balance ---
        for i in _PM.ids(pm_model, :bus, nw=n)
            if i in boundary_buses_transmission_set
                constraint_transmission_power_balance_boundary(pmitd, i; nw_pmitd=n)
            else
                _PM.constraint_power_balance(pm_model, i, nw=n)
            end
        end

        # ---- Distribution Power Balance ---
        for i in _PMD.ids(pmd_model, n, :bus)
            if i in boundary_buses_distribution_set
                constraint_distribution_power_balance_boundary(pmitd, i; nw_pmitd=n)
            else
                _PMD.constraint_mc_power_balance(pmd_model, i; nw=n)
            end
        end

    end

    # --- PM energy storage state constraint ---
    network_ids_pm = sort(collect(_PM.nw_ids(pm_model)))

    n_1_pm = network_ids_pm[1]
    for i in _PM.ids(pm_model, :storage, nw=n_1_pm)
        _PM.constraint_storage_state(pm_model, i, nw=n_1_pm)
    end

    for n_2_pm in network_ids_pm[2:end]
        for i in _PM.ids(pm_model, :storage, nw=n_2_pm)
            _PM.constraint_storage_state(pm_model, i, n_1_pm, n_2_pm)
        end
        n_1_pm = n_2_pm
    end

    # --- PMD energy storage state constraint ---
    network_ids_pmd = sort(collect(_PMD.nw_ids(pmd_model)))

    n_1_pmd = network_ids_pmd[1]

    for i in _PMD.ids(pmd_model, :storage; nw=n_1_pmd)
        _PMD.constraint_storage_state(pmd_model, i; nw=n_1_pmd)
    end

    for n_2_pmd in network_ids_pmd[2:end]
        for i in _PMD.ids(pmd_model, :storage; nw=n_2_pmd)
            _PMD.constraint_storage_state(pmd_model, i, n_1_pmd, n_2_pmd)
        end

        n_1_pmd = n_2_pmd
    end

    # -------------------------------------------------
    # --- PMITD(T&D) Cost Functions -------------------
    objective_itd_min_fuel_cost_storage(pmitd)

end


"""
	function build_mn_opfitd_storage(
		pmitd::AbstractIVRPowerModelITD
	)
Constructor for Multinetwork Integrated T&D Optimal Power Flow in current-voltage (IV) variable space with Storage OPF Dispatch.
"""
function build_mn_opfitd_storage(pmitd::AbstractIVRPowerModelITD)

    @error "IVR-IVRU formulation not yet supported for multinetwork storage problems."
    throw(error())

end


"""
	function build_mn_opfitd_storage(
		pmitd::AbstractBFPowerModelITD
	)
Constructor for Multinetwork Integrated T&D Optimal Power Flow for BF Models with Storage OPF Dispatch.
"""
function build_mn_opfitd_storage(pmitd::AbstractBFPowerModelITD)

    # Get Models
    pm_model = _get_powermodel_from_powermodelitd(pmitd)
    pmd_model = _get_powermodeldistribution_from_powermodelitd(pmitd)

    for (n, network) in nws(pmitd)
        # PM(Transmission) Variables
        _PM.variable_bus_voltage(pm_model, nw=n)
        _PM.variable_gen_power(pm_model, nw=n)
        _PM.variable_branch_power(pm_model, nw=n)
        _PM.variable_branch_current(pm_model, nw=n)
        _PM.variable_dcline_power(pm_model, nw=n)
        _PM.variable_storage_power(pm_model, nw=n)

        # PMD(Distribution) Variables
        _PMD.variable_mc_bus_voltage(pmd_model; nw=n)
        _PMD.variable_mc_branch_current(pmd_model; nw=n)
        _PMD.variable_mc_branch_power(pmd_model; nw=n)
        _PMD.variable_mc_switch_power(pmd_model; nw=n)
        _PMD.variable_mc_transformer_power(pmd_model; nw=n)
        _PMD.variable_mc_generator_power(pmd_model; nw=n)
        _PMD.variable_mc_load_power(pmd_model; nw=n)
        _PMD.variable_mc_storage_power(pmd_model; nw=n)

        # PMITD (Boundary) Current Variables
        variable_boundary_power(pmitd; nw=n)

        # --- PM(Transmission) Constraints ---
        _PM.constraint_model_current(pm_model; nw=n)

        # reference buses (this only needs to happen for pm(transmission))
        for i in _PM.ids(pm_model, :ref_buses, nw=n)
            _PM.constraint_theta_ref(pm_model, i, nw=n)
        end

        for i in _PM.ids(pm_model, :storage, nw=n)
            _PM.constraint_storage_complementarity_nl(pm_model, i, nw=n)
            _PM.constraint_storage_losses(pm_model, i, nw=n)
            _PM.constraint_storage_thermal_limit(pm_model, i, nw=n)
        end

        # PM branches
        for i in _PM.ids(pm_model, :branch, nw=n)
            _PM.constraint_power_losses(pm_model, i, nw=n)
            _PM.constraint_voltage_magnitude_difference(pm_model, i, nw=n)

            _PM.constraint_voltage_angle_difference(pm_model, i, nw=n)

            _PM.constraint_thermal_limit_from(pm_model, i, nw=n)
            _PM.constraint_thermal_limit_to(pm_model, i, nw=n)
        end

        # PM DC lines
        for i in _PM.ids(pm_model, :dcline, nw=n)
            _PM.constraint_dcline_power_losses(pm_model, i, nw=n)
        end

        # -------------------------------------------------
        # --- PMD(Distribution) Constraints ---
        _PMD.constraint_mc_model_current(pmd_model; nw=n)

        # generators should be constrained before KCL, or Pd/Qd undefined
        for i in _PMD.ids(pmd_model, n, :gen)
            _PMD.constraint_mc_generator_power(pmd_model, i; nw=n)
        end

        # loads should be constrained before KCL, or Pd/Qd undefined
        for i in _PMD.ids(pmd_model, n, :load)
            _PMD.constraint_mc_load_power(pmd_model, i; nw=n)
        end

        for i in _PMD.ids(pmd_model, n, :storage)
            _PMD.constraint_storage_complementarity_nl(pmd_model, i; nw=n)
            _PMD.constraint_mc_storage_losses(pmd_model, i; nw=n)
            _PMD.constraint_mc_storage_thermal_limit(pmd_model, i; nw=n)
        end

        for i in _PMD.ids(pmd_model, n, :branch)
            _PMD.constraint_mc_power_losses(pmd_model, i; nw=n)
            _PMD.constraint_mc_model_voltage_magnitude_difference(pmd_model, i; nw=n)

            _PMD.constraint_mc_voltage_angle_difference(pmd_model, i; nw=n)

            _PMD.constraint_mc_thermal_limit_from(pmd_model, i; nw=n)
            _PMD.constraint_mc_thermal_limit_to(pmd_model, i; nw=n)
            _PMD.constraint_mc_ampacity_from(pmd_model, i; nw=n)
            _PMD.constraint_mc_ampacity_to(pmd_model, i; nw=n)
        end

        for i in _PMD.ids(pmd_model, n, :switch)
            _PMD.constraint_mc_switch_state(pmd_model, i; nw=n)
            _PMD.constraint_mc_switch_thermal_limit(pmd_model, i; nw=n)
            _PMD.constraint_mc_switch_ampacity(pmd_model, i; nw=n)
        end

        for i in _PMD.ids(pmd_model, n, :transformer)
            _PMD.constraint_mc_transformer_power(pmd_model, i; nw=n)
        end

        # -------------------------------------------------
        # --- PMITD(T&D) INDEPENDENT Constraints ----------

        for i in ids(pmitd, :boundary; nw=n)
            constraint_boundary_power(pmitd, i; nw=n)
            constraint_boundary_voltage_magnitude(pmitd, i; nw=n)
            constraint_boundary_voltage_angle(pmitd, i; nw=n)
        end

        # -------------------------------------------------
        # --- PMITD(T&D) KCL Constraints ----------
        # Note: Both of these need to consider flow on boundaries if bus is connected to boundary
        boundary_buses_transmission = Vector{Int}() # vector to store the boundary buses transmission
        boundary_buses_distribution = Vector{Int}() # vector to store the boundary buses distribution
        for j in ids(pmitd, :boundary; nw=n)
            boundary_pmitd = ref(pmitd, n, :boundary, j)
            bus_pm = boundary_pmitd["f_bus"]
            bus_pmd = boundary_pmitd["t_bus"]
            push!(boundary_buses_transmission, bus_pm)
            push!(boundary_buses_distribution, bus_pmd)
        end
        # Convert to Julia Set - Note: membership checks are faster in sets (vs. vectors) in Julia
        boundary_buses_transmission_set = Set(boundary_buses_transmission)
        boundary_buses_distribution_set = Set(boundary_buses_distribution)

        # # ---- Transmission Power Balance ---
        for i in _PM.ids(pm_model, :bus, nw=n)
            if i in boundary_buses_transmission_set
                constraint_transmission_power_balance_boundary(pmitd, i; nw_pmitd=n)
            else
                _PM.constraint_power_balance(pm_model, i, nw=n)
            end
        end

        # ---- Distribution Power Balance ---
        for i in _PMD.ids(pmd_model, n, :bus)
            if i in boundary_buses_distribution_set
                constraint_distribution_power_balance_boundary(pmitd, i; nw_pmitd=n)
            else
                _PMD.constraint_mc_power_balance(pmd_model, i; nw=n)
            end
        end

    end

    # --- PM energy storage state constraint ---
    network_ids_pm = sort(collect(_PM.nw_ids(pm_model)))

    n_1_pm = network_ids_pm[1]
    for i in _PM.ids(pm_model, :storage, nw=n_1_pm)
        _PM.constraint_storage_state(pm_model, i, nw=n_1_pm)
    end

    for n_2_pm in network_ids_pm[2:end]
        for i in _PM.ids(pm_model, :storage, nw=n_2_pm)
            _PM.constraint_storage_state(pm_model, i, n_1_pm, n_2_pm)
        end
        n_1_pm = n_2_pm
    end

    # --- PMD energy storage state constraint ---
    network_ids_pmd = sort(collect(_PMD.nw_ids(pmd_model)))

    n_1_pmd = network_ids_pmd[1]

    for i in _PMD.ids(pmd_model, :storage; nw=n_1_pmd)
        _PMD.constraint_storage_state(pmd_model, i; nw=n_1_pmd)
    end

    for n_2_pmd in network_ids_pmd[2:end]
        for i in _PMD.ids(pmd_model, :storage; nw=n_2_pmd)
            _PMD.constraint_storage_state(pmd_model, i, n_1_pmd, n_2_pmd)
        end

        n_1_pmd = n_2_pmd
    end

    # -------------------------------------------------
    # --- PMITD(T&D) Cost Functions -------------------
    objective_itd_min_fuel_cost_storage(pmitd)

end


"""
	function build_mn_opfitd_storage(
		pmitd::AbstractLNLBFPowerModelITD
	)
Constructor for Multinetwork Integrated T&D Optimal Power Flow for L/NL to BF with Storage OPF Dispatch.
"""
function build_mn_opfitd_storage(pmitd::AbstractLNLBFPowerModelITD)

    # Get Models
    pm_model = _get_powermodel_from_powermodelitd(pmitd)
    pmd_model = _get_powermodeldistribution_from_powermodelitd(pmitd)

    for (n, network) in nws(pmitd)
        # PM(Transmission) Variables
        _PM.variable_bus_voltage(pm_model, nw=n)
        _PM.variable_gen_power(pm_model, nw=n)
        _PM.variable_branch_power(pm_model, nw=n)
        _PM.variable_dcline_power(pm_model, nw=n)
        _PM.variable_storage_power(pm_model, nw=n)

        # PMD(Distribution) Variables
        _PMD.variable_mc_bus_voltage(pmd_model; nw=n)
        _PMD.variable_mc_branch_current(pmd_model; nw=n)
        _PMD.variable_mc_branch_power(pmd_model; nw=n)
        _PMD.variable_mc_transformer_power(pmd_model; nw=n)
        _PMD.variable_mc_switch_power(pmd_model; nw=n)
        _PMD.variable_mc_generator_power(pmd_model; nw=n)
        _PMD.variable_mc_load_power(pmd_model; nw=n)
        _PMD.variable_mc_storage_power(pmd_model; nw=n)

        # PMITD (Boundary) Variables
        variable_boundary_power(pmitd; nw=n)

        # --- PM(Transmission) Constraints ---
        _PM.constraint_model_voltage(pm_model, nw=n)

        # reference buses (this only needs to happen for pm(transmission))
        for i in _PM.ids(pm_model, :ref_buses, nw=n)
            _PM.constraint_theta_ref(pm_model, i, nw=n)
        end

        for i in _PM.ids(pm_model, :storage, nw=n)
            _PM.constraint_storage_complementarity_nl(pm_model, i, nw=n)
            _PM.constraint_storage_losses(pm_model, i, nw=n)
            _PM.constraint_storage_thermal_limit(pm_model, i, nw=n)
        end

        # PM branches
        for i in _PM.ids(pm_model, :branch, nw=n)
            _PM.constraint_ohms_yt_from(pm_model, i, nw=n)
            _PM.constraint_ohms_yt_to(pm_model, i, nw=n)

            _PM.constraint_voltage_angle_difference(pm_model, i, nw=n)

            _PM.constraint_thermal_limit_from(pm_model, i, nw=n)
            _PM.constraint_thermal_limit_to(pm_model, i, nw=n)
        end

        # PM DC lines
        for i in _PM.ids(pm_model, :dcline, nw=n)
            _PM.constraint_dcline_power_losses(pm_model, i, nw=n)
        end

        # -------------------------------------------------
        # --- PMD(Distribution) Constraints ---
        _PMD.constraint_mc_model_current(pmd_model; nw=n)

        # generators should be constrained before KCL, or Pd/Qd undefined
        for i in _PMD.ids(pmd_model, n, :gen)
            _PMD.constraint_mc_generator_power(pmd_model, i; nw=n)
        end

        # loads should be constrained before KCL, or Pd/Qd undefined
        for i in _PMD.ids(pmd_model, n, :load)
            _PMD.constraint_mc_load_power(pmd_model, i; nw=n)
        end

        for i in _PMD.ids(pmd_model, n, :storage)
            _PMD.constraint_storage_complementarity_nl(pmd_model, i; nw=n)
            _PMD.constraint_mc_storage_losses(pmd_model, i; nw=n)
            _PMD.constraint_mc_storage_thermal_limit(pmd_model, i; nw=n)
        end

        for i in _PMD.ids(pmd_model, n, :branch)
            _PMD.constraint_mc_power_losses(pmd_model, i; nw=n)
            _PMD.constraint_mc_model_voltage_magnitude_difference(pmd_model, i; nw=n)

            _PMD.constraint_mc_voltage_angle_difference(pmd_model, i; nw=n)

            _PMD.constraint_mc_thermal_limit_from(pmd_model, i; nw=n)
            _PMD.constraint_mc_thermal_limit_to(pmd_model, i; nw=n)
            _PMD.constraint_mc_ampacity_from(pmd_model, i; nw=n)
            _PMD.constraint_mc_ampacity_to(pmd_model, i; nw=n)
        end

        for i in _PMD.ids(pmd_model, n, :switch)
            _PMD.constraint_mc_switch_state(pmd_model, i; nw=n)
            _PMD.constraint_mc_switch_thermal_limit(pmd_model, i; nw=n)
            _PMD.constraint_mc_switch_ampacity(pmd_model, i; nw=n)
        end

        for i in _PMD.ids(pmd_model, n, :transformer)
            _PMD.constraint_mc_transformer_power(pmd_model, i; nw=n)
        end

        # -------------------------------------------------
        # --- PMITD(T&D) INDEPENDENT Constraints ----------

        for i in ids(pmitd, :boundary; nw=n)
            constraint_boundary_power(pmitd, i; nw=n)
            constraint_boundary_voltage_magnitude(pmitd, i; nw=n)
            constraint_boundary_voltage_angle(pmitd, i; nw=n)
        end

        # -------------------------------------------------
        # --- PMITD(T&D) KCL Constraints ----------
        # Note: Both of these need to consider flow on boundaries if bus is connected to boundary
        boundary_buses_transmission = Vector{Int}() # vector to store the boundary buses transmission
        boundary_buses_distribution = Vector{Int}() # vector to store the boundary buses distribution
        for j in ids(pmitd, :boundary; nw=n)
            boundary_pmitd = ref(pmitd, n, :boundary, j)
            bus_pm = boundary_pmitd["f_bus"]
            bus_pmd = boundary_pmitd["t_bus"]
            push!(boundary_buses_transmission, bus_pm)
            push!(boundary_buses_distribution, bus_pmd)
        end
        # Convert to Julia Set - Note: membership checks are faster in sets (vs. vectors) in Julia
        boundary_buses_transmission_set = Set(boundary_buses_transmission)
        boundary_buses_distribution_set = Set(boundary_buses_distribution)

        # # ---- Transmission Power Balance ---
        for i in _PM.ids(pm_model, :bus, nw=n)
            if i in boundary_buses_transmission_set
                constraint_transmission_power_balance_boundary(pmitd, i; nw_pmitd=n)
            else
                _PM.constraint_power_balance(pm_model, i, nw=n)
            end
        end

        # ---- Distribution Power Balance ---
        for i in _PMD.ids(pmd_model, n, :bus)
            if i in boundary_buses_distribution_set
                constraint_distribution_power_balance_boundary(pmitd, i; nw_pmitd=n)
            else
                _PMD.constraint_mc_power_balance(pmd_model, i; nw=n)
            end
        end

    end

    # --- PM energy storage state constraint ---
    network_ids_pm = sort(collect(_PM.nw_ids(pm_model)))

    n_1_pm = network_ids_pm[1]
    for i in _PM.ids(pm_model, :storage, nw=n_1_pm)
        _PM.constraint_storage_state(pm_model, i, nw=n_1_pm)
    end

    for n_2_pm in network_ids_pm[2:end]
        for i in _PM.ids(pm_model, :storage, nw=n_2_pm)
            _PM.constraint_storage_state(pm_model, i, n_1_pm, n_2_pm)
        end
        n_1_pm = n_2_pm
    end

    # --- PMD energy storage state constraint ---
    network_ids_pmd = sort(collect(_PMD.nw_ids(pmd_model)))

    n_1_pmd = network_ids_pmd[1]

    for i in _PMD.ids(pmd_model, :storage; nw=n_1_pmd)
        _PMD.constraint_storage_state(pmd_model, i; nw=n_1_pmd)
    end

    for n_2_pmd in network_ids_pmd[2:end]
        for i in _PMD.ids(pmd_model, :storage; nw=n_2_pmd)
            _PMD.constraint_storage_state(pmd_model, i, n_1_pmd, n_2_pmd)
        end

        n_1_pmd = n_2_pmd
    end

    # -------------------------------------------------
    # --- PMITD(T&D) Cost Functions -------------------
    objective_itd_min_fuel_cost_storage(pmitd)
end
