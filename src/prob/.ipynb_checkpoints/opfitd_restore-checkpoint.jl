# leftover from ONM
#=
function solve_mn_opfitd_restore(data::Dict{String,<:Any}, model_type::Type, solver; kwargs...)::Dict{String,Any}
    _ONM.solve_onm_model(data, model_type, solver, build_mn_opfitd_restore; multinetwork=true, kwargs...)
end
=#

# will need to revisit the import of solve_onm_model, maybe integrated into ITD/io/common.jl?


function solve_mn_opfitd_restore(pm_file, pmd_file, pmitd_file, pmitd_type, optimizer; solution_processors::Vector{<:Function}=Function[], pmitd_ref_extensions::Vector{<:Function}=Vector{Function}([]), eng2math_passthrough::Dict{String,Vector{String}}=Dict{String,Vector{String}}(), make_si::Bool=true, auto_rename::Bool=false, solution_model::String="eng", kwargs...)
    return solve_model(pm_file, pmd_file, pmitd_file, pmitd_type, optimizer, build_mn_opfitd_restore; multinetwork=true, solution_processors=[solution_processors; _ONM.default_solution_processors], pmitd_ref_extensions=[pmitd_ref_extensions; _ONM._default_ref_extensions], eng2math_passthrough=eng2math_passthrough, make_si=make_si, auto_rename=auto_rename, solution_model=solution_model, kwargs...)
end


function sol_data_model_itdonm!(pm::AbstractBFPowerModelITD, solution::Dict{String,<:Any})
    solution_d = solution["it"]["pmd"]
    _PMD.apply_pmd!(_PMD._sol_data_model_w!, solution_d)
end

function solution_statuses_itdonm!(pm::AbstractBFPowerModelITD, sol::Dict{String,Any})
    solution_d = sol["it"]["pmd"]
    _PMD.apply_pmd!(_ONM._solution_statuses!, solution_d; apply_to_subnetworks=true)
end

function constraint_boundary_voltage_magnitude_ONM(pmitd::AbstractPowerModelITD, i::Int; nw::Int=nw_id_default)

     # Extract the transmission model
     pm_model = PowerModelsITD._get_powermodel_from_powermodelitd(pmitd)

     # Extract the distribution model
     pmd_model = PowerModelsITD._get_powermodeldistribution_from_powermodelitd(pmitd)

    boundary = PowerModelsITD.ref(pmitd, nw, :boundary, i)
    f_bus = boundary["f_bus"] # convention: from bus Transmission always!
    t_bus = boundary["t_bus"] # convention: to bus Distribution always!
    f_idx = (i, f_bus, t_bus)
   

    constraint_boundary_voltage_magnitude_ONM(pm_model, pmd_model, i, f_idx, boundary["f_connections"], boundary["t_connections"]; nw=nw)

end


function constraint_boundary_voltage_magnitude_ONM(pm::_PM.AbstractBFModel, pmd::_PMD.LPUBFDiagPowerModel, i::Int, f_idx::Tuple{Int,Int,Int}, f_connections::Vector{Int}, t_connections::Vector{Int}; nw::Int=nw_id_default)
    i, f_bus, t_bus = f_idx
    w_fr = _PM.var(pm, nw, :w, f_bus)
    w_to = _PMD.var(pmd, nw, :w, t_bus)
    z_block = _ONM.var(pmd, nw, :z_block, _ONM.ref(pmd, nw, :bus_block_map, t_bus))

    JuMP.@constraint(pmd.model, z_block * (w_fr - w_to[1]) == 0.0)
    JuMP.@constraint(pmd.model, z_block * (w_fr - w_to[2]) == 0.0)
    JuMP.@constraint(pmd.model, z_block * (w_fr - w_to[3]) == 0.0)


end

function constraint_boundary_voltage_magnitude_ONM_McCormick(pmitd::AbstractPowerModelITD, i::Int; nw::Int=nw_id_default)

     # Extract the transmission model
     pm_model = PowerModelsITD._get_powermodel_from_powermodelitd(pmitd)

     # Extract the distribution model
     pmd_model = PowerModelsITD._get_powermodeldistribution_from_powermodelitd(pmitd)

    boundary = PowerModelsITD.ref(pmitd, nw, :boundary, i)
    f_bus = boundary["f_bus"] # convention: from bus Transmission always!
    t_bus = boundary["t_bus"] # convention: to bus Distribution always!
    f_idx = (i, f_bus, t_bus)
   

    constraint_boundary_voltage_magnitude_ONM_McCormick(pm_model, pmd_model, i, f_idx, boundary["f_connections"], boundary["t_connections"]; nw=nw)

end

function constraint_boundary_voltage_magnitude_ONM_McCormick(pm::_PM.AbstractBFModel, pmd::_PMD.LPUBFDiagPowerModel, i::Int, f_idx::Tuple{Int,Int,Int}, f_connections::Vector{Int}, t_connections::Vector{Int}; nw::Int=nw_id_default)
    i, f_bus, t_bus = f_idx
    w_fr = _PM.var(pm, nw, :w, f_bus)
    w_to = _PMD.var(pmd, nw, :w, t_bus)
    z_block = _ONM.var(pmd, nw, :z_block, _ONM.ref(pmd, nw, :bus_block_map, t_bus))
    # distribution bounds
    d1u = min(_PMD.ref(pmd, nw, :bus)[t_bus]["vmax"][1]^2, 1.1^2)
    d2u = min(_PMD.ref(pmd, nw, :bus)[t_bus]["vmax"][2]^2, 1.1^2)
    d3u = min(_PMD.ref(pmd, nw, :bus)[t_bus]["vmax"][3]^2, 1.1^2)
    d1l = max(_PMD.ref(pmd, nw, :bus)[t_bus]["vmin"][1]^2, 0.9^2)
    d2l = max(_PMD.ref(pmd, nw, :bus)[t_bus]["vmin"][2]^2, 0.9^2)
    d3l = max(_PMD.ref(pmd, nw, :bus)[t_bus]["vmin"][3]^2, 0.9^2)
    tu = min(_PM.ref(pm, nw, :bus)[f_bus]["vmax"]^2, 1E6)
    tl = max(_PM.ref(pm, nw, :bus)[f_bus]["vmin"]^2, -1E6)
    println("bounds = ", [d1u, d2u, d3u, d1l, d2l, d3l, tu, tl])

    u1 = tu - d1l; u2 = tu - d2l; u3 = tu - d3l;
    l1 = tl -d1u; l2 = tl -d2u; l3 = tl -d3u;

    #u1 = 1.1^2; u2 = 1.1^2; u3 = 1.1^2;
    #l1 = -1.1^2; l2 = -1.1^2; l3 = -1.1^2
   
    g_binding_1 = JuMP.@variable(pmd.model, base_name = "g_"*string(nw)*"_"*string(i)*"_1")
    g_binding_2 = JuMP.@variable(pmd.model, base_name = "g_"*string(nw)*"_"*string(i)*"_2")
    g_binding_3 = JuMP.@variable(pmd.model, base_name = "g_"*string(nw)*"_"*string(i)*"_3")
    h_binding_1 = JuMP.@variable(pmd.model, base_name = "h_"*string(nw)*"_"*string(i)*"_1")
    JuMP.@constraint(pmd.model, h_binding_1 - (w_fr - w_to[1]) <= 1E-222)
    JuMP.@constraint(pmd.model, h_binding_1 - (w_fr - w_to[1]) >= -1E-222)
    h_binding_2 = JuMP.@variable(pmd.model, base_name = "h_"*string(nw)*"_"*string(i)*"_2")
    JuMP.@constraint(pmd.model, h_binding_2 - (w_fr - w_to[2]) <= 1E-222)
    JuMP.@constraint(pmd.model, h_binding_2 - (w_fr - w_to[2]) >= -1E-222)
    h_binding_3 = JuMP.@variable(pmd.model, base_name = "h_"*string(nw)*"_"*string(i)*"_3")
    JuMP.@constraint(pmd.model, h_binding_3 - (w_fr - w_to[3]) <= 1E-222)
    JuMP.@constraint(pmd.model, h_binding_3 - (w_fr - w_to[3]) >= -1E-222)

    #JuMP.@constraint(pmd.model, w_to[1] == w_to[2])
    #JuMP.@constraint(pmd.model, w_to[2] == w_to[3])
    #JuMP.@constraint(pmd.model, w_to[1] == w_to[3])


    JuMP.@constraint(pmd.model, g_binding_1 == 0)
    JuMP.@constraint(pmd.model, g_binding_2 == 0)
    JuMP.@constraint(pmd.model, g_binding_3 == 0)




    # upper bound 1: $w \geq x^L y + xy^L - x^L y^L$
    JuMP.@constraint(pmd.model, g_binding_1 >= z_block*l1)
    JuMP.@constraint(pmd.model, g_binding_2 >= z_block*l2)
    JuMP.@constraint(pmd.model, g_binding_3 >= z_block*l3)

    # upper bound 2: $w \geq x^U y + xy^U - x^U y^U$
    JuMP.@constraint(pmd.model, g_binding_1 >=  h_binding_1 + z_block*u1 - u1)
    JuMP.@constraint(pmd.model, g_binding_2 >=  h_binding_2 + z_block*u2 - u2)
    JuMP.@constraint(pmd.model, g_binding_3 >=  h_binding_3 + z_block*u3 - u3)

    # lower bound 1: $w \leq x^U y + xy^L - x^U y^L$
    JuMP.@constraint(pmd.model, g_binding_1 <= h_binding_1 + z_block*l1 - l1)
    JuMP.@constraint(pmd.model, g_binding_2 <= h_binding_2 + z_block*l2 - l2)
    JuMP.@constraint(pmd.model, g_binding_3 <= h_binding_3 + z_block*l3 - l3)

    # lower bound 2: $w \leq xy^U + x^Ly - x^L y^U$
    JuMP.@constraint(pmd.model, g_binding_1 <= z_block*u1)
    JuMP.@constraint(pmd.model, g_binding_2 <= z_block*u2)
    JuMP.@constraint(pmd.model, g_binding_3 <= z_block*u3)
end



#takes dict instead of files
function solve_mn_opfitd_restore(pmitd_data::Dict{String,<:Any}, pmitd_type, optimizer; solution_processors::Vector{<:Function}=Function[], pmitd_ref_extensions::Vector{<:Function}=Vector{Function}([]), eng2math_passthrough::Dict{String,Vector{String}}=Dict{String,Vector{String}}(), make_si::Bool=true, solution_model::String="eng", kwargs...)
    return solve_model(pmitd_data, pmitd_type, optimizer, build_mn_opfitd_restore; multinetwork=true, solution_processors=vcat(solution_processors, [sol_data_model_itdonm!; solution_statuses_itdonm!]...), pmitd_ref_extensions=vcat(pmitd_ref_extensions, _ONM._default_ref_extensions...), eng2math_passthrough=_ONM.recursive_merge_including_vectors(_ONM._eng2math_passthrough_default, eng2math_passthrough), make_si=false, solution_model=solution_model, kwargs...)
end


function build_mn_opfitd_restore(pmitd::AbstractBFPowerModelITD)   
    # Get Models
    pm_model = PowerModelsITD._get_powermodel_from_powermodelitd(pmitd)
    pmd_model = PowerModelsITD._get_powermodeldistribution_from_powermodelitd(pmitd)
    obj_opts = Dict(n=>_ONM.ref(pmd_model, n, :options, "objective") for n in _ONM.nw_ids(pmd_model))


    #for n in _ONM.nw_ids(pmd_model)
    for (n, network) in nws(pmitd)

        # Transmission variables
        # PM(Transmission) Variables
        _PM.variable_bus_voltage(pm_model, nw=n)
        _PM.variable_gen_power(pm_model, nw=n)
        _PM.variable_branch_power(pm_model, nw=n)
        _PM.variable_branch_current(pm_model, nw=n)
        _PM.variable_dcline_power(pm_model, nw=n)
        _PM.variable_storage_power(pm_model, nw=n)

        var_opts = _PMD.ref(pmd_model, n, :options, "variables")
        con_opts = _PMD.ref(pmd_model, n, :options, "constraints")
        obj_opts[n]["disable-generation-dispatch-cost"] = false

        _ONM.variable_block_indicator(pmd_model; nw=n, relax=var_opts["relax-integer-variables"])
        !con_opts["disable-grid-forming-inverter-constraint"] && _ONM.variable_inverter_indicator(pmd_model; nw=n, relax=var_opts["relax-integer-variables"])

        _PMD.variable_mc_bus_voltage_on_off(pmd_model; nw=n, bounded=!var_opts["unbound-voltage"])

        _PMD.variable_mc_branch_current(pmd_model; nw=n, bounded=!var_opts["unbound-line-current"])
        _PMD.variable_mc_branch_power(pmd_model; nw=n, bounded=!var_opts["unbound-line-power"])

        _PMD.variable_mc_switch_power(pmd_model; nw=n, bounded=!var_opts["unbound-switch-power"])
        _ONM.variable_switch_state(pmd_model; nw=n, relax=var_opts["relax-integer-variables"])

        _PMD.variable_mc_transformer_power(pmd_model; nw=n, bounded=!var_opts["unbound-transformer-power"])
        _PMD.variable_mc_oltc_transformer_tap(pmd_model; nw=n)

        _PMD.variable_mc_generator_power_on_off(pmd_model; nw=n, bounded=!var_opts["unbound-generation-power"])


        _ONM.variable_mc_storage_power_mi_on_off(pmd_model; nw=n, bounded=!var_opts["unbound-storage-power"], relax=var_opts["relax-integer-variables"])

        _PMD.variable_mc_load_power(pmd_model, nw=n)

        _PMD.variable_mc_capcontrol(pmd_model; nw=n, relax=var_opts["relax-integer-variables"])

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

        # --- PMD(Distribution) Constraints --- #
        
         _PMD.constraint_mc_model_current(pmd_model; nw=n)
         _PMD.constraint_mc_model_voltage(pmd_model; nw=n)

        #!con_opts["disable-grid-forming-inverter-constraint"] && _ONM.constraint_grid_forming_inverter_per_cc_block(pmd_model; nw=n, relax=var_opts["relax-integer-variables"])

       if con_opts["disable-grid-forming-inverter-constraint"]
            for i in _ONM.ids(pmd_model, n, :ref_buses)
                _PMD.constraint_mc_theta_ref(pmd_model, i; nw=n)
            end
        else
            for i in _ONM.ids(pmd_model, n, :bus)
                _ONM.constraint_mc_inverter_theta_ref(pmd_model, i; nw=n)
            end
        end
        

        _ONM.constraint_mc_bus_voltage_block_on_off(pmd_model; nw=n)

        for i in _ONM.ids(pmd_model, n, :gen)
            !var_opts["unbound-generation-power"] && _ONM.constraint_mc_generator_power_block_on_off(pmd_model, i; nw=n)
        end

        for i in _ONM.ids(pmd_model, n, :load)
            _ONM.constraint_mc_load_power_block_on_off(pmd_model, i; nw=n)
        end

        for i in _ONM.ids(pmd_model, n, :storage)
            _PMD.constraint_storage_state(pmd_model, i; nw=n)
            _ONM.constraint_storage_complementarity_mi_block_on_off(pmd_model, i; nw=n)
            _ONM.constraint_mc_storage_block_on_off(pmd_model, i; nw=n)
            _ONM.constraint_mc_storage_losses_block_on_off(pmd_model, i; nw=n)
            !con_opts["disable-thermal-limit-constraints"] && !var_opts["unbound-storage-power"] && _PMD.constraint_mc_storage_thermal_limit(pmd_model, i; nw=n)
            !con_opts["disable-storage-unbalance-constraint"] && _ONM.constraint_mc_storage_phase_unbalance_grid_following(pmd_model, i; nw=n)
        end

        for i in _ONM.ids(pmd_model, n, :branch)
            _PMD.constraint_mc_power_losses(pmd_model, i; nw=n)
            _PMD.constraint_mc_model_voltage_magnitude_difference(pmd_model, i; nw=n)
            _PMD.constraint_mc_voltage_angle_difference(pmd_model, i; nw=n)

            !con_opts["disable-thermal-limit-constraints"] && _PMD.constraint_mc_thermal_limit_from(pmd_model, i; nw=n)
            !con_opts["disable-thermal-limit-constraints"] && _PMD.constraint_mc_thermal_limit_to(pmd_model, i; nw=n)
            !con_opts["disable-current-limit-constraints"] && _PMD.constraint_mc_ampacity_from(pmd_model, i; nw=n)
            !con_opts["disable-current-limit-constraints"] && _PMD.constraint_mc_ampacity_to(pmd_model, i; nw=n)
        end

        !con_opts["disable-switch-close-action-limit"] && _ONM.constraint_switch_close_action_limit(pmd_model; nw=n)
        con_opts["disable-microgrid-networking"] && _ONM.constraint_disable_networking(pmd_model; nw=n, relax=var_opts["relax-integer-variables"])
        !con_opts["disable-radiality-constraint"] && _ONM.constraint_radial_topology(pmd_model; relax=var_opts["relax-integer-variables"], nw=n)
        !con_opts["disable-block-isolation-constraint"] && _ONM.constraint_isolate_block(pmd_model; nw=n)
        
        for i in _ONM.ids(pmd_model, n, :switch)
            _ONM.constraint_mc_switch_state_open_close(pmd_model, i; nw=n)

            !con_opts["disable-thermal-limit-constraints"] && _PMD.constraint_mc_switch_thermal_limit(pmd_model, i; nw=n)
            !con_opts["disable-current-limit-constraints"] && _PMD.constraint_mc_switch_ampacity(pmd_model, i; nw=n)
        end
        

        for i in _ONM.ids(pmd_model, n, :transformer)
            _ONM.constraint_mc_transformer_power_block_on_off(pmd_model, i; fix_taps=false, nw=n)
        end
        
    

        # -------------------------------------------------
        # --- PMITD(T&D) INDEPENDENT Constraints ----------
        
        #n_boundary = length(ids(pmitd, :boundary; nw=n))
        #JuMP.@variable(pmitd.model, g[1:n_nws, 1:n_boundary, 1:3])
        for i in ids(pmitd, :boundary; nw=n)
            constraint_boundary_power(pmitd, i; nw=n)
            constraint_boundary_voltage_magnitude_ONM_McCormick(pmitd, i; nw=n)
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
                _ONM.constraint_mc_power_balance_shed_block(pmd_model, i; nw=n)
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

    network_ids_pmd = sort(collect(_ONM.nw_ids(pmd_model)))

    n_1_pmd = network_ids_pmd[1]

    for i in _ONM.ids(pmd_model, :storage; nw=n_1_pmd)
        _PMD.constraint_storage_state(pmd_model, i; nw=n_1_pmd)
    end

    for n_2_pmd in network_ids_pmd[2:end]
        for i in _ONM.ids(pmd_model, :storage; nw=n_2_pmd)
             _PMD.constraint_storage_state(pmd_model, i, n_1_pmd, n_2_pmd)
        end

        n_1_pmd = n_2_pmd
    end
    
    objective_min_shed_load_block_mod(pmd_model)
end
