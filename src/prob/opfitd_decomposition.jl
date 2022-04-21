# Definitions for solving the integrated T&D decomposition opf problem

"""
	function solve_opfitd_decomposition(
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

Solve Integrated T&D Decomposition-based Optimal Power Flow.
"""
function solve_opfitd_decomposition(pm_file, pmd_file, pmitd_file, pmitd_type, optimizer; solution_processors::Vector{<:Function}=Function[], pmitd_ref_extensions::Vector{<:Function}=Vector{Function}([]), make_si::Bool=true, auto_rename::Bool=false, solution_model::String="eng", kwargs...)
    return solve_model(pm_file, pmd_file, pmitd_file, pmitd_type, optimizer, build_opfitd_decomposition; solution_processors=solution_processors, pmitd_ref_extensions=pmitd_ref_extensions, make_si=make_si, auto_rename=auto_rename, solution_model=solution_model, kwargs...)
end

"""
	function solve_mn_opfitd_decomposition(
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

Solve Multinetwork Integrated T&D Decomposition-based Optimal Power Flow.
"""
function solve_mn_opfitd_decomposition(pm_file, pmd_file, pmitd_file, pmitd_type, optimizer; solution_processors::Vector{<:Function}=Function[], pmitd_ref_extensions::Vector{<:Function}=Vector{Function}([]), make_si::Bool=true, auto_rename::Bool=false, solution_model::String="eng", kwargs...)
    return solve_model(pm_file, pmd_file, pmitd_file, pmitd_type, optimizer, build_mn_opfitd_decomposition; multinetwork=true, solution_processors=solution_processors, pmitd_ref_extensions=pmitd_ref_extensions, make_si=make_si, auto_rename=auto_rename, solution_model=solution_model, kwargs...)
end

"""
	function build_opfitd_decomposition(
		pm_model::_PM.AbstractPowerModel
	)
Constructor for Transmission Integrated T&D Decomposition-based Optimal Power Flow.
"""
function build_opfitd_decomposition(pm_model::_PM.AbstractPowerModel)

    # PM(Transmission) Variables
    _PM.variable_bus_voltage(pm_model)
    _PM.variable_gen_power(pm_model)
    _PM.variable_branch_power(pm_model)
    _PM.variable_dcline_power(pm_model)

    # --- PM(Transmission) Constraints ---
    _PM.constraint_model_voltage(pm_model)

    # reference buses (this only needs to happen for pm(transmission))
    for i in _PM.ids(pm_model, :ref_buses)
        _PM.constraint_theta_ref(pm_model, i)
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

    # TODO: Add boundary and normal node power balance
    # TODO: Add decomposition Constraints
    # TODO: Add decomposition cost function

end


"""
	function build_opfitd_decomposition(
		pmd_model::_PMD.AbstractUnbalancedPowerModel
	)
Constructor for Distribution Integrated T&D Decomposition-based Optimal Power Flow.
"""
function build_opfitd_decomposition(pmd_model::_PMD.AbstractUnbalancedPowerModel)


    # PMD(Distribution) Variables
    _PMD.variable_mc_bus_voltage(pmd_model)
    _PMD.variable_mc_branch_power(pmd_model)
    _PMD.variable_mc_transformer_power(pmd_model)
    _PMD.variable_mc_switch_power(pmd_model)
    _PMD.variable_mc_generator_power(pmd_model)
    _PMD.variable_mc_load_power(pmd_model)
    _PMD.variable_mc_storage_power(pmd_model)

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


    # TODO: Add boundary and normal node power balance
    # TODO: Add decomposition Constraints
    # TODO: Add decomposition cost function

end


# ----------------------------------------------------------------------------------------
# --- Multinetwork OPFITD Problem Specifications
# ----------------------------------------------------------------------------------------

"""
	function build_mn_opfitd_decomposition(
		pm_model::_PM.AbstractPowerModel
	)
Constructor for Transmission Multinetwork Integrated T&D Decomposition-based Optimal Power Flow.
"""
function build_mn_opfitd_decomposition(pm_model::_PM.AbstractPowerModel)

    for (n, network) in _PM.nws(pm_model)

        # PM(Transmission) Variables
        _PM.variable_bus_voltage(pm_model, nw=n)
        _PM.variable_gen_power(pm_model, nw=n)
        _PM.variable_branch_power(pm_model, nw=n)
        _PM.variable_dcline_power(pm_model, nw=n)
        _PM.variable_storage_power_mi(pm_model, nw=n)

        # --- PM(Transmission) Constraints ---
        _PM.constraint_model_voltage(pm_model, nw=n)

        # reference buses (this only needs to happen for pm(transmission))
        for i in _PM.ids(pm_model, :ref_buses, nw=n)
            _PM.constraint_theta_ref(pm_model, i, nw=n)
        end

        for i in _PM.ids(pm_model, :storage, nw=n)
            _PM.constraint_storage_complementarity_mi(pm_model, i, nw=n)
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

    # TODO: Add boundary and normal node power balance
    # TODO: Add decomposition Constraints
    # TODO: Add decomposition cost function

end


"""
	function build_mn_opfitd_decomposition(
		pmd_model::_PMD.AbstractUnbalancedPowerModel
	)
Constructor for Distribution Multinetwork Integrated T&D Decomposition-based Optimal Power Flow.
"""
function build_mn_opfitd_decomposition(pmd_model::_PMD.AbstractUnbalancedPowerModel)

    for (n, network) in _PMD.nws(pmd_model)

        # PMD(Distribution) Variables
        _PMD.variable_mc_bus_voltage(pmd_model; nw=n)
        _PMD.variable_mc_branch_power(pmd_model; nw=n)
        _PMD.variable_mc_transformer_power(pmd_model; nw=n)
        _PMD.variable_mc_switch_power(pmd_model; nw=n)
        _PMD.variable_mc_generator_power(pmd_model; nw=n)
        _PMD.variable_mc_load_power(pmd_model; nw=n)
        _PMD.variable_mc_storage_power(pmd_model; nw=n)

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

    # TODO: Add boundary and normal node power balance
    # TODO: Add decomposition Constraints
    # TODO: Add decomposition cost function

end