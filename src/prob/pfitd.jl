# Definitions for solving the integrated T&D opf problem

"""
	function solve_pfitd(
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
        kwargs...
	)

Solve Integrated T&D Power Flow
"""
function solve_pfitd(pm_file, pmd_file, pmitd_file, pmitd_type, optimizer; solution_processors::Vector{<:Function}=Function[], pmitd_ref_extensions::Vector{<:Function}=Vector{Function}([]), make_si::Bool=true, auto_rename::Bool=false, solution_model::String="eng", kwargs...)
    return solve_model(pm_file, pmd_file, pmitd_file, pmitd_type, optimizer, build_pfitd; solution_processors=solution_processors, pmitd_ref_extensions=pmitd_ref_extensions, make_si=make_si, auto_rename=auto_rename, solution_model=solution_model, kwargs...)
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
        _PMD.constraint_mc_switch_thermal_limit(pmd_model, i)
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

    # Note: Both of these need to consider flow on boundaries if bus is connected to boundary
    # # # ---- Transmission Power Balance ---
    boundary_buses = Vector{Int}() # empty vector that stores the boundary buses, so they are not repeated by the other constraint
    for (i,bus) in _PM.ref(pm_model, :bus)
        for j in ids(pmitd, :boundary)
            constraint_transmission_power_balance_boundary(pmitd, i, j, boundary_buses)
        end

        if !(i in boundary_buses)
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

    # # ---- Distribution Power Balance ---
    boundary_buses = Vector{Int}() # empty vector that stores the boundary buses, so they are not repeated by the other constraint
    for (i,bus) in _PMD.ref(pmd_model, :bus)
        for j in ids(pmitd, :boundary)
            constraint_distribution_power_balance_boundary(pmitd, i, j, boundary_buses)
        end

        if !(i in boundary_buses)
            _PMD.constraint_mc_power_balance(pmd_model, i)
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
        _PMD.constraint_mc_switch_current_limit(pmd_model, i)
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

    # # # ---- Transmission Power Balance ---
    boundary_buses = Vector{Int}() # empty vector that stores the boundary buses, so they are not repeated by the other constraint
    for (i,bus) in _PM.ref(pm_model, :bus)
        for j in ids(pmitd, :boundary)
            constraint_transmission_current_balance_boundary(pmitd, i, j, boundary_buses)
        end

        if !(i in boundary_buses)
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

    # # ---- Distribution Power Balance ---
    boundary_buses = Vector{Int}() # empty vector that stores the boundary buses, so they are not repeated by the other constraint
    for (i,bus) in _PMD.ref(pmd_model, :bus)
        for j in ids(pmitd, :boundary)
            constraint_distribution_current_balance_boundary(pmitd, i, j, boundary_buses)
        end

        if !(i in boundary_buses)
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
    end

    for i in _PMD.ids(pmd_model, :switch)
        _PMD.constraint_mc_switch_state(pmd_model, i)
        _PMD.constraint_mc_switch_thermal_limit(pmd_model, i)
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

    # Note: Both of these need to consider flow on boundaries if bus is connected to boundary
    # # # ---- Transmission Power Balance ---
    boundary_buses = Vector{Int}() # empty vector that stores the boundary buses, so they are not repeated by the other constraint
    for (i,bus) in _PM.ref(pm_model, :bus)
        for j in ids(pmitd, :boundary)
            constraint_transmission_power_balance_boundary(pmitd, i, j, boundary_buses)
        end

        if !(i in boundary_buses)
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

    # # ---- Distribution Power Balance ---
    boundary_buses = Vector{Int}() # empty vector that stores the boundary buses, so they are not repeated by the other constraint
    for (i,bus) in _PMD.ref(pmd_model, :bus)
        for j in ids(pmitd, :boundary)
            constraint_distribution_power_balance_boundary(pmitd, i, j, boundary_buses)
        end

        if !(i in boundary_buses)
            _PMD.constraint_mc_power_balance(pmd_model, i)
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
    end

    for i in _PM.ids(pm_model, :branch)
        _PM.expression_branch_power_ohms_yt_from(pm_model, i)
        _PM.expression_branch_power_ohms_yt_to(pm_model, i)
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
    end

    for i in _PMD.ids(pmd_model, :switch)
        _PMD.constraint_mc_switch_state(pmd_model, i)
        _PMD.constraint_mc_switch_thermal_limit(pmd_model, i)
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

    # Note: Both of these need to consider flow on boundaries if bus is connected to boundary
    # # # ---- Transmission Power Balance ---
    boundary_buses = Vector{Int}() # empty vector that stores the boundary buses, so they are not repeated by the other constraint
    for (i,bus) in _PM.ref(pm_model, :bus)
        for j in ids(pmitd, :boundary)
            constraint_transmission_power_balance_boundary(pmitd, i, j, boundary_buses)
        end

        if !(i in boundary_buses)
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

    # # ---- Distribution Power Balance ---
    boundary_buses = Vector{Int}() # empty vector that stores the boundary buses, so they are not repeated by the other constraint
    for (i,bus) in _PMD.ref(pmd_model, :bus)
        for j in ids(pmitd, :boundary)
            constraint_distribution_power_balance_boundary(pmitd, i, j, boundary_buses)
        end

        if !(i in boundary_buses)
            _PMD.constraint_mc_power_balance(pmd_model, i)
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
