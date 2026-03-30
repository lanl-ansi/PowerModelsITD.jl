function objective_min_shed_load_block_mod(pmitd::AbstractPowerModelITD)

    pm_t = PowerModelsITD._get_powermodel_from_powermodelitd(pmitd)

     # Extract the distribution model
     pm = PowerModelsITD._get_powermodeldistribution_from_powermodelitd(pmitd) 
    nw_id_list = sort(collect(_ONM.nw_ids(pm)))

    for (i, n) in enumerate(nw_id_list)
        nw_ref = _ONM.ref(pm, n)

        _ONM.var(pm, n)[:delta_sw_state] = JuMP.@variable(
            pm.model,
            [i in _ONM.ids(pm, n, :switch_dispatchable)],
            base_name="$(n)_$(i)_delta_sw_state",
            start = 0
        )

        for (s,switch) in nw_ref[:switch_dispatchable]
            z_switch = _ONM.var(pm, n, :switch_state, s)
            if i == 1
                JuMP.@constraint(pm.model, _ONM.var(pm, n, :delta_sw_state, s) >=  (JuMP.start_value(z_switch) - z_switch))
                JuMP.@constraint(pm.model, _ONM.var(pm, n, :delta_sw_state, s) >= -(JuMP.start_value(z_switch) - z_switch))
            else  # multinetwork
                z_switch_prev = _ONM.var(pm, nw_id_list[i-1], :switch_state, s)
                JuMP.@constraint(pm.model, _ONM.var(pm, n, :delta_sw_state, s) >=  (z_switch_prev - z_switch))
                JuMP.@constraint(pm.model, _ONM.var(pm, n, :delta_sw_state, s) >= -(z_switch_prev - z_switch))
            end
        end
    end

    total_energy_ub = sum(Float64[strg["energy_rating"] for (n,nw_ref) in _ONM.nws(pm) for (i,strg) in nw_ref[:storage]])
    total_pmax = sum(Float64[all(.!isfinite.(gen["pmax"])) ? 0.0 : sum(gen["pmax"][isfinite.(gen["pmax"])]) for (n,nw_ref) in _ONM.nws(pm) for (i, gen) in nw_ref[:gen]])

    total_energy_ub = total_energy_ub <= 1.0 ? 1.0 : total_energy_ub
    total_pmax = total_pmax <= 1.0 ? 1.0 : total_pmax

    n_dispatchable_switches = Dict(n => length(_ONM.ids(pm, n, :switch_dispatchable)) for n in _ONM.nw_ids(pm))
    for (n,nswitch) in n_dispatchable_switches
        if nswitch < 1
            n_dispatchable_switches[n] = 1
        end
    end

    obj_opts = Dict(n=>_ONM.ref(pm, n, :options, "objective") for n in _ONM.nw_ids(pm))

    no_weights = first(obj_opts).second["disable-load-block-weight-cost"]

    load_weights = Dict(
        n => Dict(
            l => no_weights ? 1.0 : _ONM.ref(pm, n, :block_weights, b) / length(_ONM.ref(pm, n, :block_loads, b)) for b in _ONM.ids(pm, n, :blocks) for l in _ONM.ref(pm, n, :block_loads, b)
        ) for n in _ONM.nw_ids(pm)
    )

    if no_weights
        block_weights = Dict(n => Dict(i => 1.0 for i in _ONM.ids(pm, n, :blocks)) for n in _ONM.nw_ids(pm))
    else
        block_weights = Dict(n => _ONM.ref(pm, n, :block_weights) for n in _ONM.nw_ids(pm))
    end

    _PM.expression_pg_cost(pm_t)
    _PM.expression_p_dc_cost(pm_t)

    #println("block weights: ", block_weights)
    #println("load weights: ", load_weights)
    JuMP.@objective(pmitd.model, Min,
        sum(
            sum(block_weights[n][i] * Int(!obj_opts[n]["disable-load-block-shed-cost"]) * (1-_ONM.var(pm, n, :z_block, i)) for (i,block) in nw_ref[:blocks])
            + sum(load_weights[n][i] * Int(!obj_opts[n]["disable-load-block-shed-cost"]) * (1-_ONM.var(pm, n, :z_demand, i)) for (i,load) in nw_ref[:dispatchable_loads])
            + sum( Int(obj_opts[n]["enable-switch-state-open-cost"]) * _ONM.ref(pm, n, :switch_scores, l)*(1-_ONM.var(pm, n, :switch_state, l)) for l in _ONM.ids(pm, n, :switch_dispatchable) )
            #+ sum( Int(!obj_opts[n]["disable-switch-state-change-cost"]) * sum(_ONM.var(pm, n, :delta_sw_state, l)) for l in _ONM.ids(pm, n, :switch_dispatchable)) / n_dispatchable_switches[n]
            +sum( Int(!obj_opts[n]["disable-storage-discharge-cost"]) * (strg["energy_rating"] - _ONM.var(pm, n, :se, i)) for (i,strg) in nw_ref[:storage]) / total_energy_ub
            + sum( Int(!obj_opts[n]["disable-generation-dispatch-cost"]) * sum(get(gen,  "cost", [0.0, 0.0])[2] * _ONM.var(pm, n, :pg, i)[c] + get(gen,  "cost", [0.0, 0.0])[1] for c in  gen["connections"]) for (i,gen) in nw_ref[:gen]) / total_energy_ub
        for (n, nw_ref) in _ONM.nws(pm))
        +
        0.01*sum(
            sum( _PM.var(pm_t, n,   :pg_cost, i) for (i,gen) in nw_ref[:gen]) +
            sum( _PM.var(pm_t, n, :p_dc_cost, i) for (i,dcline) in nw_ref[:dcline])
        for (n, nw_ref) in _PM.nws(pm_t))
    )
end