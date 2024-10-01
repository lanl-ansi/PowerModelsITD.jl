# Definitions for solving the integrated T&D decomposition pf problem

"""
	function solve_pfitd_decomposition(
        pm_file,
        pmd_file,
        pmitd_file,
        pmitd_type,
        optimizer;
        solution_processors::Vector{<:Function}=Function[],
        pmitd_ref_extensions::Vector{<:Function}=Vector{Function}([]),
        make_si::Bool=true,
        auto_rename::Bool=false,
        solution_model::String="eng",
        distribution_basekva::Float64=0.0,
        export_models::Bool=false,
        kwargs...
	)

Solve Integrated T&D Decomposition-based Power Flow.
"""
function solve_pfitd_decomposition(pm_file, pmd_file, pmitd_file, pmitd_type, optimizer; solution_processors::Vector{<:Function}=Function[], pmitd_ref_extensions::Vector{<:Function}=Vector{Function}([]), make_si::Bool=true, auto_rename::Bool=false, solution_model::String="eng", distribution_basekva::Float64=0.0, export_models::Bool=false, kwargs...)
    return solve_model(pm_file, pmd_file, pmitd_file, pmitd_type, optimizer, build_pfitd_decomposition; solution_processors=solution_processors, pmitd_ref_extensions=pmitd_ref_extensions, make_si=make_si, auto_rename=auto_rename, solution_model=solution_model, distribution_basekva=distribution_basekva, export_models=export_models, kwargs...)
end

"""
	function solve_mn_pfitd_decomposition(
        pm_file,
        pmd_file,
        pmitd_file,
        pmitd_type,
        optimizer;
        solution_processors::Vector{<:Function}=Function[],
        pmitd_ref_extensions::Vector{<:Function}=Vector{Function}([]),
        make_si::Bool=true,
        auto_rename::Bool=false,
        solution_model::String="eng",
        export_models::Bool=false,
        kwargs...
	)

Solve Multinetwork Integrated T&D Decomposition-based Power Flow.
"""
function solve_mn_pfitd_decomposition(pm_file, pmd_file, pmitd_file, pmitd_type, optimizer; solution_processors::Vector{<:Function}=Function[], pmitd_ref_extensions::Vector{<:Function}=Vector{Function}([]), make_si::Bool=true, auto_rename::Bool=false, solution_model::String="eng", export_models::Bool=false, kwargs...)
    return solve_model(pm_file, pmd_file, pmitd_file, pmitd_type, optimizer, build_mn_pfitd_decomposition; multinetwork=true, solution_processors=solution_processors, pmitd_ref_extensions=pmitd_ref_extensions, make_si=make_si, auto_rename=auto_rename, solution_model=solution_model, export_models=export_models, kwargs...)
end

"""
	function build_pfitd_decomposition(
		pm_model::_PM.AbstractPowerModel
	)
Constructor for Transmission Integrated T&D Decomposition-based Power Flow.
"""
function build_pfitd_decomposition(pm_model::_PM.AbstractPowerModel)

    # PM(Transmission) Variables
    _PM.variable_bus_voltage(pm_model, bounded = false)
    _PM.variable_gen_power(pm_model, bounded = false)
    _PM.variable_dcline_power(pm_model, bounded = false)

    for i in _PM.ids(pm_model, :branch)
        _PM.expression_branch_power_ohms_yt_from(pm_model, i)
        _PM.expression_branch_power_ohms_yt_to(pm_model, i)
    end

    # Decomposition-related vars
    variable_boundary_power(pm_model)

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

    # -------------------------------------------------
    # --- PMITD(T&D) KCL Constraints ----------
    boundary_buses_transmission = Vector{Int}() # vector to store the boundary buses transmission
    for j in _PM.ids(pm_model, :boundary)
        boundary_pmitd = _PM.ref(pm_model, nw_id_default, :boundary, j)
        bus_pm = boundary_pmitd["f_bus"]
        push!(boundary_buses_transmission, bus_pm)
    end
    # Convert to Julia Set - Note: membership checks are faster in sets (vs. vectors) in Julia
    boundary_buses_transmission_set = Set(boundary_buses_transmission)

    # # ---- Transmission Power Balance ---
    for (i, bus) in _PM.ref(pm_model, :bus)
        if i in boundary_buses_transmission_set
            constraint_transmission_power_balance_boundary(pm_model, i)
        else
            _PM.constraint_power_balance(pm_model, i)
        end

        # PV Bus Constraints
        if length(_PM.ref(pm_model, :bus_gens, i)) > 0 && !(i in _PM.ids(pm_model, :ref_buses))
            # this assumes inactive generators are filtered out of bus_gens
            @assert bus["bus_type"] == 2

            _PM.constraint_voltage_magnitude_setpoint(pm_model, i)
            for j in _PM.ref(pm_model, :bus_gens, i)
                _PM.constraint_gen_setpoint_active(pm_model, j)
            end
        end

    end

    # Boundary constraints
    for i in _PM.ids(pm_model, :boundary)
        constraint_transmission_boundary_power_shared_vars_scaled(pm_model, i)
    end

end


"""
	function build_pfitd_decomposition(
		pmd_model::_PMD.AbstractUnbalancedPowerModel
	)
Constructor for Distribution Integrated T&D Decomposition-based Power Flow.
"""
function build_pfitd_decomposition(pmd_model::_PMD.AbstractUnbalancedPowerModel)

    # PMD(Distribution) Variables
    _PMD.variable_mc_bus_voltage(pmd_model; bounded = false)
    _PMD.variable_mc_branch_power(pmd_model; bounded = false)
    _PMD.variable_mc_transformer_power(pmd_model; bounded = false)
    _PMD.variable_mc_switch_power(pmd_model; bounded = false)
    _PMD.variable_mc_generator_power(pmd_model)
    _PMD.variable_mc_load_power(pmd_model; bounded = false)
    _PMD.variable_mc_storage_power(pmd_model; bounded = false)

    # Decomposition-related vars
    variable_boundary_power(pmd_model)

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

    # Power balance for PMD buses.
    for (i, bus) in _PMD.ref(pmd_model, :bus)
        _PMD.constraint_mc_power_balance(pmd_model, i)

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

    # Boundary constraints
    for i in _PMD.ids(pmd_model, :boundary)
        constraint_boundary_power(pmd_model, i)
        constraint_boundary_voltage_magnitude(pmd_model, i)
        constraint_boundary_voltage_angle(pmd_model, i)
    end

end



"""
	function build_pfitd_decomposition(
		pm_model::_PM.AbstractWModels
	)
Constructor for Transmission Integrated T&D Decomposition-based Power Flow.
"""
function build_pfitd_decomposition(pm_model::_PM.AbstractWModels)

    # PM(Transmission) Variables
    _PM.variable_bus_voltage(pm_model, bounded = false)
    _PM.variable_gen_power(pm_model, bounded = false)
    _PM.variable_branch_power(pm_model, bounded = false)
    _PM.variable_branch_current(pm_model, bounded = false)
    _PM.variable_dcline_power(pm_model, bounded = false)

    # Decomposition-related vars
    variable_boundary_power(pm_model)

    # --- PM(Transmission) Constraints ---
    _PM.constraint_model_current(pm_model)

    # reference buses (this only needs to happen for pm(transmission))
    for (i,bus) in _PM.ref(pm_model, :ref_buses)
        @assert bus["bus_type"] == 3
        _PM.constraint_theta_ref(pm_model, i)
        _PM.constraint_voltage_magnitude_setpoint(pm_model, i)
    end

    # Branches
    for i in _PM.ids(pm_model, :branch)
        _PM.constraint_power_losses(pm_model, i)
        _PM.constraint_voltage_magnitude_difference(pm_model, i)
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

    # -------------------------------------------------
    # --- PMITD(T&D) KCL Constraints ----------
    boundary_buses_transmission = Vector{Int}() # vector to store the boundary buses transmission
    for j in _PM.ids(pm_model, :boundary)
        boundary_pmitd = _PM.ref(pm_model, nw_id_default, :boundary, j)
        bus_pm = boundary_pmitd["f_bus"]
        push!(boundary_buses_transmission, bus_pm)
    end
    # Convert to Julia Set - Note: membership checks are faster in sets (vs. vectors) in Julia
    boundary_buses_transmission_set = Set(boundary_buses_transmission)

    # # ---- Transmission Power Balance ---
    for (i, bus) in _PM.ref(pm_model, :bus)
        if i in boundary_buses_transmission_set
            constraint_transmission_power_balance_boundary(pm_model, i)
        else
            _PM.constraint_power_balance(pm_model, i)
        end

        # PV Bus Constraints
        if length(_PM.ref(pm_model, :bus_gens, i)) > 0 && !(i in _PM.ids(pm_model, :ref_buses))
            # this assumes inactive generators are filtered out of bus_gens
            @assert bus["bus_type"] == 2

            _PM.constraint_voltage_magnitude_setpoint(pm_model, i)
            for j in _PM.ref(pm_model, :bus_gens, i)
                _PM.constraint_gen_setpoint_active(pm_model, j)
            end
        end

    end

    # Boundary constraints
    for i in _PM.ids(pm_model, :boundary)
        constraint_transmission_boundary_power_shared_vars_scaled(pm_model, i)
    end

end



"""
	function build_pfitd_decomposition(
		pmd_model::_PMD.AbstractUBFModels
	)
Constructor for Distribution Integrated T&D Decomposition-based Power Flow.
"""
function build_pfitd_decomposition(pmd_model::_PMD.AbstractUBFModels)

    # PMD(Distribution) Variables
    _PMD.variable_mc_bus_voltage(pmd_model; bounded=false)
    _PMD.variable_mc_branch_current(pmd_model)
    _PMD.variable_mc_branch_power(pmd_model)
    _PMD.variable_mc_transformer_power(pmd_model; bounded=false)
    _PMD.variable_mc_switch_power(pmd_model)
    _PMD.variable_mc_generator_power(pmd_model)
    _PMD.variable_mc_load_power(pmd_model)
    _PMD.variable_mc_storage_power(pmd_model; bounded=false)

    # Decomposition-related vars
    variable_boundary_power(pmd_model)

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

    # Power balance for PMD buses.
    for (i, bus) in _PMD.ref(pmd_model, :bus)
        _PMD.constraint_mc_power_balance(pmd_model, i)

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
    end

    for i in _PMD.ids(pmd_model, :switch)
        _PMD.constraint_mc_switch_state(pmd_model, i)
    end

    for i in _PMD.ids(pmd_model, :transformer)
        _PMD.constraint_mc_transformer_power(pmd_model, i)
    end

    # Boundary constraints
    for i in _PMD.ids(pmd_model, :boundary)
        constraint_boundary_power(pmd_model, i)
        constraint_boundary_voltage_magnitude(pmd_model, i)
        constraint_boundary_voltage_angle(pmd_model, i)
    end

end



"""
	function build_pfitd_decomposition(
		pm_model::_PM.AbstractIVRModel
	)
Constructor for Transmission Integrated T&D Decomposition-based Power Flow.
"""
function build_pfitd_decomposition(pm_model::_PM.AbstractIVRModel)

    # PM(Transmission) Variables
    _PM.variable_bus_voltage(pm_model, bounded = false)
    _PM.variable_branch_current(pm_model, bounded = false)
    _PM.variable_gen_current(pm_model, bounded = false)
    _PM.variable_dcline_current(pm_model, bounded = false)

    # Decomposition-related vars
    variable_boundary_power(pm_model)

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

    # -------------------------------------------------
    # --- PMITD(T&D) KCL Constraints ----------
    boundary_buses_transmission = Vector{Int}() # vector to store the boundary buses transmission
    for j in _PM.ids(pm_model, :boundary)
        boundary_pmitd = _PM.ref(pm_model, nw_id_default, :boundary, j)
        bus_pm = boundary_pmitd["f_bus"]
        push!(boundary_buses_transmission, bus_pm)
    end
    # Convert to Julia Set - Note: membership checks are faster in sets (vs. vectors) in Julia
    boundary_buses_transmission_set = Set(boundary_buses_transmission)

    # # ---- Transmission Power Balance ---
    for (i, bus) in _PM.ref(pm_model, :bus)
        if i in boundary_buses_transmission_set
            constraint_transmission_current_balance_boundary(pm_model, i)
        else
            _PM.constraint_current_balance(pm_model, i)
        end

        # PV Bus Constraints
        if length(_PM.ref(pm_model, :bus_gens, i)) > 0 && !(i in _PM.ids(pm_model, :ref_buses))
            # this assumes inactive generators are filtered out of bus_gens
            @assert bus["bus_type"] == 2

            _PM.constraint_voltage_magnitude_setpoint(pm_model, i)
            for j in _PM.ref(pm_model, :bus_gens, i)
                _PM.constraint_gen_setpoint_active(pm_model, j)
            end
        end

    end

    # Boundary constraints
    for i in _PM.ids(pm_model, :boundary)
        constraint_transmission_boundary_power_shared_vars_scaled(pm_model, i)
    end

end



"""
	function build_pfitd_decomposition(
		pmd_model::_PMD.AbstractUnbalancedIVRModel
	)
Constructor for Distribution Integrated T&D Decomposition-based Power Flow.
"""
function build_pfitd_decomposition(pmd_model::_PMD.AbstractUnbalancedIVRModel)

    # PMD(Distribution) Variables
    _PMD.variable_mc_bus_voltage(pmd_model, bounded = false)
    _PMD.variable_mc_branch_current(pmd_model, bounded = false)
    _PMD.variable_mc_switch_current(pmd_model, bounded = false)
    _PMD.variable_mc_transformer_current(pmd_model, bounded = false)
    _PMD.variable_mc_generator_current(pmd_model)
    _PMD.variable_mc_load_current(pmd_model, bounded = false)

    # Decomposition-related vars
    variable_boundary_power(pmd_model)

    # --- PMD(Distribution) Constraints ---
    # gens should be constrained before KCL, or Pd/Qd undefined
    for id in _PMD.ids(pmd_model, :gen)
        _PMD.constraint_mc_generator_power(pmd_model, id)
    end

    # loads should be constrained before KCL, or Pd/Qd undefined
    for id in _PMD.ids(pmd_model, :load)
        _PMD.constraint_mc_load_power(pmd_model, id)
    end

    for (i, bus) in _PMD.ref(pmd_model, :bus)
        _PMD.constraint_mc_current_balance(pmd_model, i)

        # PV Bus Constraints
        if length(_PMD.ref(pmd_model, :bus_gens, i)) > 0 && !(i in _PMD.ids(pmd_model, :ref_buses))
            # this assumes inactive generators are filtered out of bus_gens
            @assert bus["bus_type"] == 2
            _PMD.constraint_mc_voltage_magnitude_only(pmd_model, i)
            for j in _PMD.ref(pmd_model, :bus_gens, i)
                _PMD.constraint_mc_gen_power_setpoint_real(pmd_model, j)
            end
        end

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

    # Boundary constraints
    for i in _PMD.ids(pmd_model, :boundary)
        constraint_boundary_power(pmd_model, i)
        constraint_boundary_voltage_magnitude(pmd_model, i)
        constraint_boundary_voltage_angle(pmd_model, i)
    end

end


# TODO: Multinetwork specs.
# ----------------------------------------------------------------------------------------
# --- Multinetwork OPFITD Problem Specifications
# ----------------------------------------------------------------------------------------

# """
# 	function build_mn_pfitd_decomposition(
# 		pm_model::_PM.AbstractPowerModel
# 	)
# Constructor for Transmission Multinetwork Integrated T&D Decomposition-based Power Flow.
# """
# function build_mn_pfitd_decomposition(pm_model::_PM.AbstractPowerModel)
# end


# """
# 	function build_mn_pfitd_decomposition(
# 		pmd_model::_PMD.AbstractUnbalancedPowerModel
# 	)
# Constructor for Distribution Multinetwork Integrated T&D Decomposition-based Power Flow.
# """
# function build_mn_pfitd_decomposition(pmd_model::_PMD.AbstractUnbalancedPowerModel)
# end