# Definitions for solving the integrated T&D pf problem

"""
	function solve_pfitd(
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

Solve Integrated T&D Power Flow
"""
function solve_pfitd(pm_file, pmd_file, pmitd_file, pmitd_type, optimizer; solution_processors::Vector{<:Function}=Function[], pmitd_ref_extensions::Vector{<:Function}=Vector{Function}([]), eng2math_passthrough::Dict{String,Vector{String}}=Dict{String,Vector{String}}(), make_si::Bool=true, auto_rename::Bool=false, solution_model::String="eng", export_models::Bool=false, kwargs...)
    return solve_model(pm_file, pmd_file, pmitd_file, pmitd_type, optimizer, build_pfitd; solution_processors=solution_processors, pmitd_ref_extensions=pmitd_ref_extensions, eng2math_passthrough=eng2math_passthrough, make_si=make_si, auto_rename=auto_rename, solution_model=solution_model, export_models=export_models, kwargs...)
end


"""
	function solve_pfitd(
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

Solve Integrated T&D Power Flow
"""
function solve_pfitd(pmitd_data::Dict{String,<:Any}, pmitd_type, optimizer; solution_processors::Vector{<:Function}=Function[], pmitd_ref_extensions::Vector{<:Function}=Vector{Function}([]), eng2math_passthrough::Dict{String,Vector{String}}=Dict{String,Vector{String}}(), make_si::Bool=true, solution_model::String="eng", export_models::Bool=false, kwargs...)
    return solve_model(pmitd_data, pmitd_type, optimizer, build_pfitd; solution_processors=solution_processors, pmitd_ref_extensions=pmitd_ref_extensions, eng2math_passthrough=eng2math_passthrough, make_si=make_si, solution_model=solution_model, export_models=export_models, kwargs...)
end


"""
	function solve_mn_pfitd(
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
        kwargs...
	)

Solve Multinetwork Integrated T&D Power Flow.
"""
function solve_mn_pfitd(pm_file, pmd_file, pmitd_file, pmitd_type, optimizer; solution_processors::Vector{<:Function}=Function[], pmitd_ref_extensions::Vector{<:Function}=Vector{Function}([]), eng2math_passthrough::Dict{String,Vector{String}}=Dict{String,Vector{String}}(), make_si::Bool=true, auto_rename::Bool=false, solution_model::String="eng", kwargs...)
    return solve_model(pm_file, pmd_file, pmitd_file, pmitd_type, optimizer, build_mn_pfitd; multinetwork=true, solution_processors=solution_processors, pmitd_ref_extensions=pmitd_ref_extensions, eng2math_passthrough=eng2math_passthrough, make_si=make_si, auto_rename=auto_rename, solution_model=solution_model, kwargs...)
end


"""
	function solve_mn_pfitd(
        pmitd_data::Dict{String,<:Any}
        pmitd_type,
        optimizer;
        solution_processors::Vector{<:Function}=Function[],
        pmitd_ref_extensions::Vector{<:Function}=Vector{Function}([]),
        eng2math_passthrough::Dict{String,Vector{String}}=Dict{String,Vector{String}}(),
        make_si::Bool=true,
        solution_model::String="eng",
        kwargs...
	)

Solve Multinetwork Integrated T&D Power Flow.
"""
function solve_mn_pfitd(pmitd_data::Dict{String,<:Any}, pmitd_type, optimizer; solution_processors::Vector{<:Function}=Function[], pmitd_ref_extensions::Vector{<:Function}=Vector{Function}([]), eng2math_passthrough::Dict{String,Vector{String}}=Dict{String,Vector{String}}(), make_si::Bool=true, solution_model::String="eng", kwargs...)
    return solve_model(pmitd_data, pmitd_type, optimizer, build_mn_pfitd; multinetwork=true, solution_processors=solution_processors, pmitd_ref_extensions=pmitd_ref_extensions, eng2math_passthrough=eng2math_passthrough, make_si=make_si, solution_model=solution_model, kwargs...)
end




"""
	function build_pfitd(
		pmitd::AbstractPowerModelITD
	)
Constructor for Integrated T&D Power Flow.
"""
function build_pfitd(pmitd::AbstractPowerModelITD)

    # Get Models
    pm_model = _get_powermodel_from_powermodelitd(pmitd)
    pmd_model = _get_powermodeldistribution_from_powermodelitd(pmitd)

    # PM(Transmission) Variables
    _PM.variable_bus_voltage(pm_model, bounded = false)
    _PM.variable_gen_power(pm_model, bounded = false)
    _PM.variable_dcline_power(pm_model, bounded = false)
    _PM.variable_storage_power(pm_model, bounded = false)

    for i in _PM.ids(pm_model, :branch)
        _PM.expression_branch_power_ohms_yt_from(pm_model, i)
        _PM.expression_branch_power_ohms_yt_to(pm_model, i)
    end

    # PMD(Distribution) Variables
    _PMD.variable_mc_bus_voltage(pmd_model; bounded=false)
    _PMD.variable_mc_branch_power(pmd_model; bounded=false)
    _PMD.variable_mc_transformer_power(pmd_model; bounded=false)
    _PMD.variable_mc_switch_power(pmd_model; bounded=false)
    _PMD.variable_mc_generator_power(pmd_model; bounded=false)
    _PMD.variable_mc_load_power(pmd_model; bounded=false)
    _PMD.variable_mc_storage_power(pmd_model; bounded=false)

    # PMITD (Boundary) Variables
    variable_boundary_power(pmitd)

    # --- PM(Transmission) Constraints ---
    _PM.constraint_model_voltage(pm_model)

    # reference buses (this only needs to happen for pm(transmission))
    for (i,bus) in _PM.ref(pm_model, :ref_buses)
        @assert bus["bus_type"] == 3
        _PM.constraint_theta_ref(pm_model, i)
        _PM.constraint_voltage_magnitude_setpoint(pm_model, i)

        # if multiple generators, fix power generation degeneracies
        if length(_PM.ref(pm_model, :bus_gens, i)) > 1
            for j in collect(_PM.ref(pm_model, :bus_gens, i))[2:end]
                _PM.constraint_gen_setpoint_active(pm_model, j)
                _PM.constraint_gen_setpoint_reactive(pm_model, j)
            end
        end

    end

    # DC lines
    for (i,dcline) in _PM.ref(pm_model, :dcline)
        _PM.constraint_dcline_setpoint_active(pm_model, i)
        f_bus = _PM.ref(pm_model, :bus)[dcline["f_bus"]]
        if f_bus["bus_type"] == 1
            _PM.constraint_voltage_magnitude_setpoint(pm_model, f_bus["index"])
        end

        t_bus = _PM.ref(pm_model, :bus)[dcline["t_bus"]]
        if t_bus["bus_type"] == 1
            _PM.constraint_voltage_magnitude_setpoint(pm_model, t_bus["index"])
        end
    end

    # Storage
    for i in _PM.ids(pm_model, :storage)
        _PM.constraint_storage_state(pm_model, i)
        _PM.constraint_storage_complementarity_nl(pm_model, i)
        _PM.constraint_storage_losses(pm_model, i)
        _PM.constraint_storage_thermal_limit(pm_model, i)
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
    end

    for i in _PMD.ids(pmd_model, :switch)
        _PMD.constraint_mc_switch_state(pmd_model, i)
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
    for (i, bus) in _PM.ref(pm_model, :bus)

        if i in boundary_buses_transmission_set
            constraint_transmission_power_balance_boundary(pmitd, i)
        else
            _PM.constraint_power_balance(pm_model, i)
        end

        # PV Bus Constraints
        if length(_PM.ref(pm_model, :bus_gens, i)) > 0 && !(i in _PM.ids(pm_model,:ref_buses))
            # this assumes inactive generators are filtered out of bus_gens
            @assert bus["bus_type"] == 2
            _PM.constraint_voltage_magnitude_setpoint(pm_model, i)
            for j in _PM.ref(pm_model, :bus_gens, i)
                _PM.constraint_gen_setpoint_active(pm_model, j)
            end
        end
    end

    # ---- Distribution Power Balance ---
    for (i, bus) in _PMD.ref(pmd_model, :bus)

        if i in boundary_buses_distribution_set
            constraint_distribution_power_balance_boundary(pmitd, i)
        else
            _PMD.constraint_mc_power_balance(pmd_model, i)
        end

        # PV Bus Constraints
        if (length(_PMD.ref(pmd_model, :bus_gens, i)) > 0 || length(_PMD.ref(pmd_model, :bus_storages, i)) > 0) && !(i in _PMD.ids(pmd_model, :ref_buses))
            # this assumes inactive generators are filtered out of bus_gens
            @assert bus["bus_type"] == 2
            _PMD.constraint_mc_voltage_magnitude_only(pmd_model, i)
            for j in _PMD.ref(pmd_model, :bus_gens, i)
                _PMD.constraint_mc_gen_power_setpoint_real(pmd_model, j)
            end
            for j in _PMD.ref(pmd_model, :bus_storages, i)
                _PMD.constraint_mc_storage_power_setpoint_real(pmd_model, j)
            end
        end
    end

end


"""
	function build_pfitd(
		pmitd::AbstractIVRPowerModelITD
	)
Constructor for Integrated T&D Power Flow in current-voltage (IV) variable space.
"""
function build_pfitd(pmitd::AbstractIVRPowerModelITD)

    # Get Models
    pm_model = _get_powermodel_from_powermodelitd(pmitd)
    pmd_model = _get_powermodeldistribution_from_powermodelitd(pmitd)

    # PM(Transmission) Variables
    _PM.variable_bus_voltage(pm_model, bounded = false)
    _PM.variable_branch_current(pm_model, bounded = false)
    _PM.variable_gen_current(pm_model, bounded = false)
    _PM.variable_dcline_current(pm_model, bounded = false)

    # PMD(Distribution) Variables
    _PMD.variable_mc_bus_voltage(pmd_model, bounded = false)
    _PMD.variable_mc_branch_current(pmd_model, bounded = false)
    _PMD.variable_mc_switch_current(pmd_model, bounded = false)
    _PMD.variable_mc_transformer_current(pmd_model, bounded = false)
    _PMD.variable_mc_generator_current(pmd_model, bounded = false)
    _PMD.variable_mc_load_current(pmd_model, bounded = false)

    # PMITD (Boundary) Current Variables
    variable_boundary_current(pmitd)

    # --- PM(Transmission) Constraints ---
    # reference buses (this only needs to happen for pm(transmission))
    for (i,bus) in _PM.ref(pm_model, :ref_buses)
        @assert bus["bus_type"] == 3
        _PM.constraint_theta_ref(pm_model, i)
        _PM.constraint_voltage_magnitude_setpoint(pm_model, i)
    end

    for i in _PM.ids(pm_model, :branch)
        _PM.constraint_current_from(pm_model, i)
        _PM.constraint_current_to(pm_model, i)
        _PM.constraint_voltage_drop(pm_model, i)
    end

    for (i,dcline) in _PM.ref(pm_model, :dcline)
        constraint_dcline_setpoint_active(pm_model, i)
        f_bus =  _PM.ref(pm_model, :bus)[dcline["f_bus"]]
        if f_bus["bus_type"] == 1
            _PM.constraint_voltage_magnitude_setpoint(pm_model, f_bus["index"])
        end
        t_bus =  _PM.ref(pm_model, :bus)[dcline["t_bus"]]
        if t_bus["bus_type"] == 1
            _PM.constraint_voltage_magnitude_setpoint(pm_model, t_bus["index"])
        end
    end


    # --- PMD(Distribution) Constraints ---
    # gens should be constrained before KCL, or Pd/Qd undefined
    for id in _PMD.ids(pmd_model, :gen)
        _PMD.constraint_mc_generator_power(pmd_model, id)
    end

    # loads should be constrained before KCL, or Pd/Qd undefined
    for id in _PMD.ids(pmd_model, :load)
        _PMD.constraint_mc_load_power(pmd_model, id)
    end


    for i in _PMD.ids(pmd_model, :branch)
        _PMD.constraint_mc_current_from(pmd_model, i)
        _PMD.constraint_mc_current_to(pmd_model, i)
        _PMD.constraint_mc_bus_voltage_drop(pmd_model, i)
    end

    for i in _PMD.ids(pmd_model, :switch)
        _PMD.constraint_mc_switch_state(pmd_model, i)
    end

    for i in _PMD.ids(pmd_model, :transformer)
        _PMD.constraint_mc_transformer_power(pmd_model, i)
    end


    # -------------------------------------------------
    # --- PMITD(T&D) INDEPENDENT Constraints ----------

    for i in ids(pmitd, :boundary)
        constraint_boundary_current(pmitd, i)
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
    for (i, bus) in _PM.ref(pm_model, :bus)

        if i in boundary_buses_transmission_set
            constraint_transmission_current_balance_boundary(pmitd, i)
        else
            _PM.constraint_current_balance(pm_model, i)
        end

        # PV Bus Constraints
        if length(_PM.ref(pm_model, :bus_gens, i)) > 0 && !(i in _PM.ids(pm_model,:ref_buses))
            # this assumes inactive generators are filtered out of bus_gens
            @assert bus["bus_type"] == 2
            _PM.constraint_voltage_magnitude_setpoint(pm_model, i)
            for j in _PM.ref(pm_model, :bus_gens, i)
                _PM.constraint_gen_setpoint_active(pm_model, j)
            end
        end
    end

    # ---- Distribution Power Balance ---
    for (i, bus) in _PMD.ref(pmd_model, :bus)

        if i in boundary_buses_distribution_set
            constraint_distribution_current_balance_boundary(pmitd, i)
        else
            _PMD.constraint_mc_current_balance(pmd_model, i)
        end

        # PV Bus Constraints
        if length(_PMD.ref(pmd_model, :bus_gens, i)) > 0 && !(i in _PMD.ids(pmd_model,:ref_buses))
            # this assumes inactive generators are filtered out of bus_gens
            @assert bus["bus_type"] == 2
            _PMD.constraint_mc_voltage_magnitude_only(pmd_model, i)
            for j in _PMD.ref(pmd_model, :bus_gens, i)
                _PMD.constraint_mc_gen_power_setpoint_real(pmd_model, j)
            end
        end
    end

end


"""
	function build_pfitd(
		pmitd::AbstractBFPowerModelITD
	)
Constructor for Integrated T&D Power Flow for Branch Flow (BF) Formulations.
"""
function build_pfitd(pmitd::AbstractBFPowerModelITD)

    # Get Models
    pm_model = _get_powermodel_from_powermodelitd(pmitd)
    pmd_model = _get_powermodeldistribution_from_powermodelitd(pmitd)

    # PM(Transmission) Variables
    _PM.variable_bus_voltage(pm_model, bounded = false)
    _PM.variable_gen_power(pm_model, bounded = false)
    _PM.variable_branch_power(pm_model, bounded = false)
    _PM.variable_branch_current(pm_model, bounded = false)
    _PM.variable_dcline_power(pm_model, bounded = false)
    _PM.variable_storage_power(pm_model, bounded = false)

    # PMD(Distribution) Variables
    _PMD.variable_mc_bus_voltage(pmd_model; bounded=false)
    _PMD.variable_mc_branch_current(pmd_model)
    _PMD.variable_mc_branch_power(pmd_model)
    _PMD.variable_mc_transformer_power(pmd_model; bounded=false)
    _PMD.variable_mc_switch_power(pmd_model)
    _PMD.variable_mc_generator_power(pmd_model; bounded=false)
    _PMD.variable_mc_load_power(pmd_model)
    _PMD.variable_mc_storage_power(pmd_model; bounded=false)

    # PMITD (Boundary) Variables
    variable_boundary_power(pmitd)

    # --- PM(Transmission) Constraints ---
    _PM.constraint_model_current(pm_model)

    # reference buses (this only needs to happen for pm(transmission))
    for (i,bus) in _PM.ref(pm_model, :ref_buses)
        @assert bus["bus_type"] == 3
        _PM.constraint_theta_ref(pm_model, i)
        _PM.constraint_voltage_magnitude_setpoint(pm_model, i)
    end

    # DC lines
    for (i,dcline) in _PM.ref(pm_model, :dcline)
        _PM.constraint_dcline_setpoint_active(pm_model, i)
        f_bus = _PM.ref(pm_model, :bus)[dcline["f_bus"]]
        if f_bus["bus_type"] == 1
            _PM.constraint_voltage_magnitude_setpoint(pm_model, f_bus["index"])
        end

        t_bus = _PM.ref(pm_model, :bus)[dcline["t_bus"]]
        if t_bus["bus_type"] == 1
            _PM.constraint_voltage_magnitude_setpoint(pm_model, t_bus["index"])
        end
    end

    # Branches
    for i in _PM.ids(pm_model, :branch)
        _PM.constraint_power_losses(pm_model, i)
        _PM.constraint_voltage_magnitude_difference(pm_model, i)
    end

    # Storage
    for i in _PM.ids(pm_model, :storage)
        _PM.constraint_storage_state(pm_model, i)
        _PM.constraint_storage_complementarity_nl(pm_model, i)
        _PM.constraint_storage_losses(pm_model, i)
        _PM.constraint_storage_thermal_limit(pm_model, i)
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
    end

    for i in _PMD.ids(pmd_model, :switch)
        _PMD.constraint_mc_switch_state(pmd_model, i)
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
    for (i, bus) in _PM.ref(pm_model, :bus)

        if i in boundary_buses_transmission_set
            constraint_transmission_power_balance_boundary(pmitd, i)
        else
            _PM.constraint_power_balance(pm_model, i)
        end

        # PV Bus Constraints
        if length(_PM.ref(pm_model, :bus_gens, i)) > 0 && !(i in _PM.ids(pm_model,:ref_buses))
            # this assumes inactive generators are filtered out of bus_gens
            @assert bus["bus_type"] == 2
            _PM.constraint_voltage_magnitude_setpoint(pm_model, i)
            for j in _PM.ref(pm_model, :bus_gens, i)
                _PM.constraint_gen_setpoint_active(pm_model, j)
            end
        end
    end

    # ---- Distribution Power Balance ---
    for (i, bus) in _PMD.ref(pmd_model, :bus)

        if i in boundary_buses_distribution_set
            constraint_distribution_power_balance_boundary(pmitd, i)
        else
            _PMD.constraint_mc_power_balance(pmd_model, i)
        end

        # PV Bus Constraints
        if (length(_PMD.ref(pmd_model, :bus_gens, i)) > 0 || length(_PMD.ref(pmd_model, :bus_storages, i)) > 0) && !(i in _PMD.ids(pmd_model, :ref_buses))
            # this assumes inactive generators are filtered out of bus_gens
            @assert bus["bus_type"] == 2
            _PMD.constraint_mc_voltage_magnitude_only(pmd_model, i)
            for j in _PMD.ref(pmd_model, :bus_gens, i)
                _PMD.constraint_mc_gen_power_setpoint_real(pmd_model, j)
            end
            for j in _PMD.ref(pmd_model, :bus_storages, i)
                _PMD.constraint_mc_storage_power_setpoint_real(pmd_model, j)
            end
        end
    end

end


# -- Combined (Hybrid) Formulations
"""
	function build_pfitd(
		pmitd::AbstractLNLBFPowerModelITD
	)
Constructor for Integrated T&D Power Flow for L/NL to BF.
"""
function build_pfitd(pmitd::AbstractLNLBFPowerModelITD)

    # Get Models
    pm_model = _get_powermodel_from_powermodelitd(pmitd)
    pmd_model = _get_powermodeldistribution_from_powermodelitd(pmitd)

    # PM(Transmission) Variables
    _PM.variable_bus_voltage(pm_model, bounded = false)
    _PM.variable_gen_power(pm_model, bounded = false)
    _PM.variable_dcline_power(pm_model, bounded = false)
    _PM.variable_storage_power(pm_model, bounded = false)

    for i in _PM.ids(pm_model, :branch)
        _PM.expression_branch_power_ohms_yt_from(pm_model, i)
        _PM.expression_branch_power_ohms_yt_to(pm_model, i)
    end

    # PMD(Distribution) Variables
    _PMD.variable_mc_bus_voltage(pmd_model; bounded=false)
    _PMD.variable_mc_branch_current(pmd_model)
    _PMD.variable_mc_branch_power(pmd_model)
    _PMD.variable_mc_transformer_power(pmd_model; bounded=false)
    _PMD.variable_mc_switch_power(pmd_model)
    _PMD.variable_mc_generator_power(pmd_model; bounded=false)
    _PMD.variable_mc_load_power(pmd_model)
    _PMD.variable_mc_storage_power(pmd_model; bounded=false)


    # PMITD (Boundary) Variables
    variable_boundary_power(pmitd)

    # --- PM(Transmission) Constraints ---
    _PM.constraint_model_voltage(pm_model)

    # reference buses (this only needs to happen for pm(transmission))
    for (i,bus) in _PM.ref(pm_model, :ref_buses)
        @assert bus["bus_type"] == 3
        _PM.constraint_theta_ref(pm_model, i)
        _PM.constraint_voltage_magnitude_setpoint(pm_model, i)

        # if multiple generators, fix power generation degeneracies
        if length(_PM.ref(pm_model, :bus_gens, i)) > 1
            for j in collect(_PM.ref(pm_model, :bus_gens, i))[2:end]
                _PM.constraint_gen_setpoint_active(pm_model, j)
                _PM.constraint_gen_setpoint_reactive(pm_model, j)
            end
        end
    end

    # DC lines
    for (i,dcline) in _PM.ref(pm_model, :dcline)
        _PM.constraint_dcline_setpoint_active(pm_model, i)
        f_bus = _PM.ref(pm_model, :bus)[dcline["f_bus"]]
        if f_bus["bus_type"] == 1
            _PM.constraint_voltage_magnitude_setpoint(pm_model, f_bus["index"])
        end

        t_bus = _PM.ref(pm_model, :bus)[dcline["t_bus"]]
        if t_bus["bus_type"] == 1
            _PM.constraint_voltage_magnitude_setpoint(pm_model, t_bus["index"])
        end
    end

    # Storage
    for i in _PM.ids(pm_model, :storage)
        _PM.constraint_storage_state(pm_model, i)
        _PM.constraint_storage_complementarity_nl(pm_model, i)
        _PM.constraint_storage_losses(pm_model, i)
        _PM.constraint_storage_thermal_limit(pm_model, i)
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
    end

    for i in _PMD.ids(pmd_model, :switch)
        _PMD.constraint_mc_switch_state(pmd_model, i)
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
    for (i, bus) in _PM.ref(pm_model, :bus)

        if i in boundary_buses_transmission_set
            constraint_transmission_power_balance_boundary(pmitd, i)
        else
            _PM.constraint_power_balance(pm_model, i)
        end

        # PV Bus Constraints
        if length(_PM.ref(pm_model, :bus_gens, i)) > 0 && !(i in _PM.ids(pm_model,:ref_buses))
            # this assumes inactive generators are filtered out of bus_gens
            @assert bus["bus_type"] == 2
            _PM.constraint_voltage_magnitude_setpoint(pm_model, i)
            for j in _PM.ref(pm_model, :bus_gens, i)
                _PM.constraint_gen_setpoint_active(pm_model, j)
            end
        end
    end

    # ---- Distribution Power Balance ---
    for (i, bus) in _PMD.ref(pmd_model, :bus)

        if i in boundary_buses_distribution_set
            constraint_distribution_power_balance_boundary(pmitd, i)
        else
            _PMD.constraint_mc_power_balance(pmd_model, i)
        end

        # PV Bus Constraints
        if (length(_PMD.ref(pmd_model, :bus_gens, i)) > 0 || length(_PMD.ref(pmd_model, :bus_storages, i)) > 0) && !(i in _PMD.ids(pmd_model, :ref_buses))
            # this assumes inactive generators are filtered out of bus_gens
            @assert bus["bus_type"] == 2
            _PMD.constraint_mc_voltage_magnitude_only(pmd_model, i)
            for j in _PMD.ref(pmd_model, :bus_gens, i)
                _PMD.constraint_mc_gen_power_setpoint_real(pmd_model, j)
            end
            for j in _PMD.ref(pmd_model, :bus_storages, i)
                _PMD.constraint_mc_storage_power_setpoint_real(pmd_model, j)
            end
        end
    end

end


# ----------------------------------------------------------------------------------------
# --- Multinetwork PFITD Problem Specifications
# ----------------------------------------------------------------------------------------

"""
	function build_mn_pfitd(
		pmitd::AbstractPowerModelITD
	)
Constructor for Multinetwork Integrated T&D Power Flow.
"""
function build_mn_pfitd(pmitd::AbstractPowerModelITD)

    # Get Models
    pm_model = _get_powermodel_from_powermodelitd(pmitd)
    pmd_model = _get_powermodeldistribution_from_powermodelitd(pmitd)

    for (n, network) in nws(pmitd)
        # PM(Transmission) Variables
        _PM.variable_bus_voltage(pm_model, bounded = false, nw=n)
        _PM.variable_gen_power(pm_model, bounded = false, nw=n)
        _PM.variable_dcline_power(pm_model, bounded = false, nw=n)
        _PM.variable_storage_power(pm_model, bounded = false, nw=n)

        for i in _PM.ids(pm_model, :branch, nw=n)
            _PM.expression_branch_power_ohms_yt_from(pm_model, i; nw=n)
            _PM.expression_branch_power_ohms_yt_to(pm_model, i; nw=n)
        end

        # PMD(Distribution) Variables
        _PMD.variable_mc_bus_voltage(pmd_model; nw=n, bounded=false)
        _PMD.variable_mc_branch_power(pmd_model; nw=n, bounded=false)
        _PMD.variable_mc_transformer_power(pmd_model; nw=n, bounded=false)
        _PMD.variable_mc_switch_power(pmd_model; nw=n, bounded=false)
        _PMD.variable_mc_generator_power(pmd_model; nw=n, bounded=false)
        _PMD.variable_mc_load_power(pmd_model; nw=n, bounded=false)
        _PMD.variable_mc_storage_power(pmd_model; nw=n, bounded=false)

        # PMITD (Boundary) Variables
        variable_boundary_power(pmitd; nw=n)

        # --- PM(Transmission) Constraints ---
        _PM.constraint_model_voltage(pm_model, nw=n)

        # reference buses (this only needs to happen for pm(transmission))
        for (i,bus) in _PM.ref(pm_model, :ref_buses, nw=n)
            @assert bus["bus_type"] == 3
            _PM.constraint_theta_ref(pm_model, i, nw=n)
            _PM.constraint_voltage_magnitude_setpoint(pm_model, i, nw=n)

            # if multiple generators, fix power generation degeneracies
            if length(_PM.ref(pm_model, :bus_gens, i, nw=n)) > 1
                for j in collect(_PM.ref(pm_model, :bus_gens, i, nw=n))[2:end]
                    _PM.constraint_gen_setpoint_active(pm_model, j, nw=n)
                    _PM.constraint_gen_setpoint_reactive(pm_model, j, nw=n)
                end
            end

        end

        # Storage
        for i in _PM.ids(pm_model, :storage, nw=n)
            _PM.constraint_storage_complementarity_nl(pm_model, i, nw=n)
            _PM.constraint_storage_losses(pm_model, i, nw=n)
            _PM.constraint_storage_thermal_limit(pm_model, i, nw=n)
        end

        # DC lines
        for (i,dcline) in _PM.ref(pm_model, :dcline, nw=n)
            _PM.constraint_dcline_setpoint_active(pm_model, i, nw=n)
            f_bus = _PM.ref(pm_model, :bus, nw=n)[dcline["f_bus"]]
            if f_bus["bus_type"] == 1
                _PM.constraint_voltage_magnitude_setpoint(pm_model, f_bus["index"], nw=n)
            end

            t_bus = _PM.ref(pm_model, :bus, nw=n)[dcline["t_bus"]]
            if t_bus["bus_type"] == 1
                _PM.constraint_voltage_magnitude_setpoint(pm_model, t_bus["index"], nw=n)
            end
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
        end

        for i in _PMD.ids(pmd_model, n, :switch)
            _PMD.constraint_mc_switch_state(pmd_model, i; nw=n)
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
        for (i, bus) in _PM.ref(pm_model, :bus, nw=n)
            if i in boundary_buses_transmission_set
                constraint_transmission_power_balance_boundary(pmitd, i; nw_pmitd=n)
            else
                _PM.constraint_power_balance(pm_model, i, nw=n)
            end

            # PV Bus Constraints
            if length(_PM.ref(pm_model, :bus_gens, i, nw=n)) > 0 && !(i in _PM.ids(pm_model,:ref_buses, nw=n))
                # this assumes inactive generators are filtered out of bus_gens
                @assert bus["bus_type"] == 2
                _PM.constraint_voltage_magnitude_setpoint(pm_model, i, nw=n)
                for j in _PM.ref(pm_model, :bus_gens, i, nw=n)
                    _PM.constraint_gen_setpoint_active(pm_model, j, nw=n)
                end
            end

        end

        # ---- Distribution Power Balance ---
        for (i, bus) in _PMD.ref(pmd_model, :bus, nw=n)
            if i in boundary_buses_distribution_set
                constraint_distribution_power_balance_boundary(pmitd, i; nw_pmitd=n)
            else
                _PMD.constraint_mc_power_balance(pmd_model, i; nw=n)
            end

            # PV Bus Constraints
            if (length(_PMD.ref(pmd_model, :bus_gens, i, nw=n)) > 0 || length(_PMD.ref(pmd_model, :bus_storages, i, nw=n)) > 0) && !(i in _PMD.ids(pmd_model, :ref_buses, nw=n))
                # this assumes inactive generators are filtered out of bus_gens
                @assert bus["bus_type"] == 2
                _PMD.constraint_mc_voltage_magnitude_only(pmd_model, i; nw=n)
                for j in _PMD.ref(pmd_model, :bus_gens, i, nw=n)
                    _PMD.constraint_mc_gen_power_setpoint_real(pmd_model, j; nw=n)
                end
                for j in _PMD.ref(pmd_model, :bus_storages, i, nw=n)
                    _PMD.constraint_mc_storage_power_setpoint_real(pmd_model, j; nw=n)
                end
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

end


"""
	function build_mn_pfitd(
		pmitd::AbstractIVRPowerModelITD
	)
Constructor for Multinetwork Integrated T&D Power Flow in current-voltage (IV) variable space.
"""
function build_mn_pfitd(pmitd::AbstractIVRPowerModelITD)

    # Get Models
    pm_model = _get_powermodel_from_powermodelitd(pmitd)
    pmd_model = _get_powermodeldistribution_from_powermodelitd(pmitd)

    for (n, network) in nws(pmitd)
        # PM(Transmission) Variables
        _PM.variable_bus_voltage(pm_model, bounded = false, nw=n)
        _PM.variable_branch_current(pm_model, bounded = false, nw=n)
        _PM.variable_gen_current(pm_model, bounded = false, nw=n)
        _PM.variable_dcline_current(pm_model, bounded = false, nw=n)

        # PMD(Distribution) Variables
        _PMD.variable_mc_bus_voltage(pmd_model, bounded = false; nw=n)
        _PMD.variable_mc_branch_current(pmd_model, bounded = false; nw=n)
        _PMD.variable_mc_switch_current(pmd_model, bounded = false; nw=n)
        _PMD.variable_mc_transformer_current(pmd_model, bounded = false; nw=n)
        _PMD.variable_mc_generator_current(pmd_model, bounded = false; nw=n)
        _PMD.variable_mc_load_current(pmd_model, bounded = false; nw=n)

        # PMITD (Boundary) Current Variables
        variable_boundary_current(pmitd; nw=n)

        # reference buses (this only needs to happen for pm(transmission))
        for (i,bus) in _PM.ref(pm_model, :ref_buses, nw=n)
            @assert bus["bus_type"] == 3
            _PM.constraint_theta_ref(pm_model, i, nw=n)
            _PM.constraint_voltage_magnitude_setpoint(pm_model, i, nw=n)
        end

        # PM branches
        for i in _PM.ids(pm_model, :branch, nw=n)
            _PM.constraint_current_from(pm_model, i, nw=n)
            _PM.constraint_current_to(pm_model, i, nw=n)
            _PM.constraint_voltage_drop(pm_model, i, nw=n)
        end

        # DC lines
        for (i,dcline) in _PM.ref(pm_model, :dcline, nw=n)
            _PM.constraint_dcline_setpoint_active(pm_model, i, nw=n)
            f_bus = _PM.ref(pm_model, :bus, nw=n)[dcline["f_bus"]]
            if f_bus["bus_type"] == 1
                _PM.constraint_voltage_magnitude_setpoint(pm_model, f_bus["index"], nw=n)
            end

            t_bus = _PM.ref(pm_model, :bus, nw=n)[dcline["t_bus"]]
            if t_bus["bus_type"] == 1
                _PM.constraint_voltage_magnitude_setpoint(pm_model, t_bus["index"], nw=n)
            end
        end

        # -------------------------------------------------
        # --- PMD(Distribution) Constraints ---

        # generators should be constrained before KCL, or Pd/Qd undefined
        for i in _PMD.ids(pmd_model, n, :gen)
            _PMD.constraint_mc_generator_power(pmd_model, i; nw=n)
        end

        # loads should be constrained before KCL, or Pd/Qd undefined
        for i in _PMD.ids(pmd_model, n, :load)
            _PMD.constraint_mc_load_power(pmd_model, i; nw=n)
        end

        for i in _PMD.ids(pmd_model, n, :branch)
            _PMD.constraint_mc_current_from(pmd_model, i; nw=n)
            _PMD.constraint_mc_current_to(pmd_model, i; nw=n)
            _PMD.constraint_mc_bus_voltage_drop(pmd_model, i; nw=n)
        end

        for i in _PMD.ids(pmd_model, n, :switch)
            _PMD.constraint_mc_switch_state(pmd_model, i; nw=n)
        end

        for i in _PMD.ids(pmd_model, n, :transformer)
            _PMD.constraint_mc_transformer_power(pmd_model, i; nw=n)
        end

        # -------------------------------------------------
        # --- PMITD(T&D) INDEPENDENT Constraints ----------

        for i in ids(pmitd, :boundary; nw=n)
            constraint_boundary_current(pmitd, i; nw=n)
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
        for (i, bus) in _PM.ref(pm_model, :bus, nw=n)
            if i in boundary_buses_transmission_set
                constraint_transmission_current_balance_boundary(pmitd, i; nw_pmitd=n)
            else
                _PM.constraint_current_balance(pm_model, i, nw=n)
            end

            # PV Bus Constraints
            if length(_PM.ref(pm_model, :bus_gens, i, nw=n)) > 0 && !(i in _PM.ids(pm_model,:ref_buses, nw=n))
                # this assumes inactive generators are filtered out of bus_gens
                @assert bus["bus_type"] == 2
                _PM.constraint_voltage_magnitude_setpoint(pm_model, i, nw=n)
                for j in _PM.ref(pm_model, :bus_gens, i, nw=n)
                    _PM.constraint_gen_setpoint_active(pm_model, j, nw=n)
                end
            end

        end

        # ---- Distribution Power Balance ---
        for (i, bus) in _PMD.ref(pmd_model, :bus, nw=n)
            if i in boundary_buses_distribution_set
                constraint_distribution_current_balance_boundary(pmitd, i; nw_pmitd=n)
            else
                _PMD.constraint_mc_current_balance(pmd_model, i; nw=n)
            end

            # PV Bus Constraints
            if length(_PMD.ref(pmd_model, :bus_gens, i, nw=n)) > 0 && !(i in _PMD.ids(pmd_model, :ref_buses, nw=n))
                # this assumes inactive generators are filtered out of bus_gens
                @assert bus["bus_type"] == 2
                _PMD.constraint_mc_voltage_magnitude_only(pmd_model, i; nw=n)
                for j in _PMD.ref(pmd_model, :bus_gens, i, nw=n)
                    _PMD.constraint_mc_gen_power_setpoint_real(pmd_model, j; nw=n)
                end
            end

        end

    end

end


"""
	function build_mn_pfitd(
		pmitd::AbstractBFPowerModelITD
	)
Constructor for Multinetwork Integrated T&D Power Flow for BF Models.
"""
function build_mn_pfitd(pmitd::AbstractBFPowerModelITD)

    # Get Models
    pm_model = _get_powermodel_from_powermodelitd(pmitd)
    pmd_model = _get_powermodeldistribution_from_powermodelitd(pmitd)

    for (n, network) in nws(pmitd)
        # PM(Transmission) Variables
        _PM.variable_bus_voltage(pm_model, bounded = false, nw=n)
        _PM.variable_gen_power(pm_model, bounded = false, nw=n)
        _PM.variable_dcline_power(pm_model, bounded = false, nw=n)
        _PM.variable_branch_power(pm_model, bounded = false, nw=n)
        _PM.variable_branch_current(pm_model, bounded = false, nw=n)
        _PM.variable_storage_power(pm_model, bounded = false, nw=n)

        # PMD(Distribution) Variables
        _PMD.variable_mc_bus_voltage(pmd_model; nw=n, bounded=false)
        _PMD.variable_mc_branch_current(pmd_model; nw=n)
        _PMD.variable_mc_branch_power(pmd_model; nw=n)
        _PMD.variable_mc_transformer_power(pmd_model; nw=n, bounded=false)
        _PMD.variable_mc_switch_power(pmd_model; nw=n)
        _PMD.variable_mc_generator_power(pmd_model; nw=n, bounded=false)
        _PMD.variable_mc_load_power(pmd_model; nw=n)
        _PMD.variable_mc_storage_power(pmd_model; nw=n, bounded=false)

        # PMITD (Boundary) Variables
        variable_boundary_power(pmitd; nw=n)

        # --- PM(Transmission) Constraints ---
        _PM.constraint_model_current(pm_model, nw=n)

        # reference buses (this only needs to happen for pm(transmission))
        for (i,bus) in _PM.ref(pm_model, :ref_buses, nw=n)
            @assert bus["bus_type"] == 3
            _PM.constraint_theta_ref(pm_model, i, nw=n)
            _PM.constraint_voltage_magnitude_setpoint(pm_model, i, nw=n)

            # if multiple generators, fix power generation degeneracies
            if length(_PM.ref(pm_model, :bus_gens, i, nw=n)) > 1
                for j in collect(_PM.ref(pm_model, :bus_gens, i, nw=n))[2:end]
                    _PM.constraint_gen_setpoint_active(pm_model, j, nw=n)
                    _PM.constraint_gen_setpoint_reactive(pm_model, j, nw=n)
                end
            end
        end

        # Storage
        for i in _PM.ids(pm_model, :storage, nw=n)
            _PM.constraint_storage_complementarity_nl(pm_model, i, nw=n)
            _PM.constraint_storage_losses(pm_model, i, nw=n)
            _PM.constraint_storage_thermal_limit(pm_model, i, nw=n)
        end

        # DC lines
        for (i,dcline) in _PM.ref(pm_model, :dcline, nw=n)
            _PM.constraint_dcline_setpoint_active(pm_model, i, nw=n)
            f_bus = _PM.ref(pm_model, :bus, nw=n)[dcline["f_bus"]]
            if f_bus["bus_type"] == 1
                _PM.constraint_voltage_magnitude_setpoint(pm_model, f_bus["index"], nw=n)
            end

            t_bus = _PM.ref(pm_model, :bus, nw=n)[dcline["t_bus"]]
            if t_bus["bus_type"] == 1
                _PM.constraint_voltage_magnitude_setpoint(pm_model, t_bus["index"], nw=n)
            end
        end

        # Branches
        for i in _PM.ids(pm_model, :branch, nw=n)
            _PM.constraint_power_losses(pm_model, i, nw=n)
            _PM.constraint_voltage_magnitude_difference(pm_model, i, nw=n)
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
        end

        for i in _PMD.ids(pmd_model, n, :switch)
            _PMD.constraint_mc_switch_state(pmd_model, i; nw=n)
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
        for (i, bus) in _PM.ref(pm_model, :bus, nw=n)
            if i in boundary_buses_transmission_set
                constraint_transmission_power_balance_boundary(pmitd, i; nw_pmitd=n)
            else
                _PM.constraint_power_balance(pm_model, i, nw=n)
            end

            # PV Bus Constraints
            if length(_PM.ref(pm_model, :bus_gens, i, nw=n)) > 0 && !(i in _PM.ids(pm_model,:ref_buses, nw=n))
                # this assumes inactive generators are filtered out of bus_gens
                @assert bus["bus_type"] == 2
                _PM.constraint_voltage_magnitude_setpoint(pm_model, i, nw=n)
                for j in _PM.ref(pm_model, :bus_gens, i, nw=n)
                    _PM.constraint_gen_setpoint_active(pm_model, j, nw=n)
                end
            end

        end

        # ---- Distribution Power Balance ---
        for (i, bus) in _PMD.ref(pmd_model, :bus, nw=n)
            if i in boundary_buses_distribution_set
                constraint_distribution_power_balance_boundary(pmitd, i; nw_pmitd=n)
            else
                _PMD.constraint_mc_power_balance(pmd_model, i; nw=n)
            end

            # PV Bus Constraints
            if (length(_PMD.ref(pmd_model, :bus_gens, i, nw=n)) > 0 || length(_PMD.ref(pmd_model, :bus_storages, i, nw=n)) > 0) && !(i in _PMD.ids(pmd_model, :ref_buses, nw=n))
                # this assumes inactive generators are filtered out of bus_gens
                @assert bus["bus_type"] == 2
                _PMD.constraint_mc_voltage_magnitude_only(pmd_model, i; nw=n)
                for j in _PMD.ref(pmd_model, :bus_gens, i, nw=n)
                    _PMD.constraint_mc_gen_power_setpoint_real(pmd_model, j; nw=n)
                end
                for j in _PMD.ref(pmd_model, :bus_storages, i, nw=n)
                    _PMD.constraint_mc_storage_power_setpoint_real(pmd_model, j; nw=n)
                end
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

end


"""
	function build_mn_pfitd(
		pmitd::AbstractLNLBFPowerModelITD
	)
Constructor for Multinetwork Integrated T&D Power Flow for L/NL to BF.
"""
function build_mn_pfitd(pmitd::AbstractLNLBFPowerModelITD)

        # Get Models
    pm_model = _get_powermodel_from_powermodelitd(pmitd)
    pmd_model = _get_powermodeldistribution_from_powermodelitd(pmitd)

    for (n, network) in nws(pmitd)
        # PM(Transmission) Variables
        _PM.variable_bus_voltage(pm_model, bounded = false, nw=n)
        _PM.variable_gen_power(pm_model, bounded = false, nw=n)
        _PM.variable_dcline_power(pm_model, bounded = false, nw=n)
        _PM.variable_storage_power(pm_model, bounded = false, nw=n)

        for i in _PM.ids(pm_model, :branch, nw=n)
            _PM.expression_branch_power_ohms_yt_from(pm_model, i; nw=n)
            _PM.expression_branch_power_ohms_yt_to(pm_model, i; nw=n)
        end

        # PMD(Distribution) Variables
        _PMD.variable_mc_bus_voltage(pmd_model; nw=n, bounded=false)
        _PMD.variable_mc_branch_current(pmd_model; nw=n)
        _PMD.variable_mc_branch_power(pmd_model; nw=n)
        _PMD.variable_mc_transformer_power(pmd_model; nw=n, bounded=false)
        _PMD.variable_mc_switch_power(pmd_model; nw=n)
        _PMD.variable_mc_generator_power(pmd_model; nw=n, bounded=false)
        _PMD.variable_mc_load_power(pmd_model; nw=n)
        _PMD.variable_mc_storage_power(pmd_model; nw=n, bounded=false)

        # PMITD (Boundary) Variables
        variable_boundary_power(pmitd; nw=n)

        # --- PM(Transmission) Constraints ---
        _PM.constraint_model_voltage(pm_model, nw=n)

        # reference buses (this only needs to happen for pm(transmission))
        for (i,bus) in _PM.ref(pm_model, :ref_buses, nw=n)
            @assert bus["bus_type"] == 3
            _PM.constraint_theta_ref(pm_model, i, nw=n)
            _PM.constraint_voltage_magnitude_setpoint(pm_model, i, nw=n)

            # if multiple generators, fix power generation degeneracies
            if length(_PM.ref(pm_model, :bus_gens, i, nw=n)) > 1
                for j in collect(_PM.ref(pm_model, :bus_gens, i, nw=n))[2:end]
                    _PM.constraint_gen_setpoint_active(pm_model, j, nw=n)
                    _PM.constraint_gen_setpoint_reactive(pm_model, j, nw=n)
                end
            end
        end

        # Storage
        for i in _PM.ids(pm_model, :storage, nw=n)
            _PM.constraint_storage_complementarity_nl(pm_model, i, nw=n)
            _PM.constraint_storage_losses(pm_model, i, nw=n)
            _PM.constraint_storage_thermal_limit(pm_model, i, nw=n)
        end

        # DC lines
        for (i,dcline) in _PM.ref(pm_model, :dcline, nw=n)
            _PM.constraint_dcline_setpoint_active(pm_model, i, nw=n)
            f_bus = _PM.ref(pm_model, :bus, nw=n)[dcline["f_bus"]]
            if f_bus["bus_type"] == 1
                _PM.constraint_voltage_magnitude_setpoint(pm_model, f_bus["index"], nw=n)
            end

            t_bus = _PM.ref(pm_model, :bus, nw=n)[dcline["t_bus"]]
            if t_bus["bus_type"] == 1
                _PM.constraint_voltage_magnitude_setpoint(pm_model, t_bus["index"], nw=n)
            end
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
        end

        for i in _PMD.ids(pmd_model, n, :switch)
            _PMD.constraint_mc_switch_state(pmd_model, i; nw=n)
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
        for (i, bus) in _PM.ref(pm_model, :bus, nw=n)
            if i in boundary_buses_transmission_set
                constraint_transmission_power_balance_boundary(pmitd, i; nw_pmitd=n)
            else
                _PM.constraint_power_balance(pm_model, i, nw=n)
            end

            # PV Bus Constraints
            if length(_PM.ref(pm_model, :bus_gens, i, nw=n)) > 0 && !(i in _PM.ids(pm_model,:ref_buses, nw=n))
                # this assumes inactive generators are filtered out of bus_gens
                @assert bus["bus_type"] == 2
                _PM.constraint_voltage_magnitude_setpoint(pm_model, i, nw=n)
                for j in _PM.ref(pm_model, :bus_gens, i, nw=n)
                    _PM.constraint_gen_setpoint_active(pm_model, j, nw=n)
                end
            end

        end

        # ---- Distribution Power Balance ---
        for (i, bus) in _PMD.ref(pmd_model, :bus, nw=n)
            if i in boundary_buses_distribution_set
                constraint_distribution_power_balance_boundary(pmitd, i; nw_pmitd=n)
            else
                _PMD.constraint_mc_power_balance(pmd_model, i; nw=n)
            end

            # PV Bus Constraints
            if (length(_PMD.ref(pmd_model, :bus_gens, i, nw=n)) > 0 || length(_PMD.ref(pmd_model, :bus_storages, i, nw=n)) > 0) && !(i in _PMD.ids(pmd_model, :ref_buses, nw=n))
                # this assumes inactive generators are filtered out of bus_gens
                @assert bus["bus_type"] == 2
                _PMD.constraint_mc_voltage_magnitude_only(pmd_model, i; nw=n)
                for j in _PMD.ref(pmd_model, :bus_gens, i, nw=n)
                    _PMD.constraint_mc_gen_power_setpoint_real(pmd_model, j; nw=n)
                end
                for j in _PMD.ref(pmd_model, :bus_storages, i, nw=n)
                    _PMD.constraint_mc_storage_power_setpoint_real(pmd_model, j; nw=n)
                end
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

end
