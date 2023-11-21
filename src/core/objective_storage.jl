"""
    function objective_itd_min_fuel_cost_storage(
        pmitd::AbstractPowerModelITD
    )

Standard fuel cost minimization objective with storage.
"""
function objective_itd_min_fuel_cost_storage(pmitd::AbstractPowerModelITD)

    # Extract the transmission model
    pm_model = _get_powermodel_from_powermodelitd(pmitd)

    # Extract the distribution model
    pmd_model = _get_powermodeldistribution_from_powermodelitd(pmitd)

    # PM cost models
    pm_cost_model = _PM.check_cost_models(pm_model)

    # PMD cost models
    pmd_cost_model = _PMD.check_gen_cost_models(pmd_model)

    if pm_cost_model == 1 # && pmd_cost_model == 1 # pmd_cost_model may not be needed (see cases when no gen is in dist. system.)
        @error "cost models of type 1 are currently not supported for problems with storage devices."
    elseif pm_cost_model == 2 # && pmd_cost_model == 2 # pmd_cost_model may not be needed (see cases when no gen is in dist. system.)
        return objective_itd_min_fuel_cost_polynomial_storage(pmitd, pm_model, pmd_model)
    else
        @error "Only cost models of types 1 and 2 are supported at this time, given cost model type of $(pm_cost_model) and $(pmd_cost_model)"
    end

end


"""
    function objective_itd_min_fuel_cost_polynomial_storage(
        pmitd::AbstractPowerModelITD,
        pm::_PM.AbstractPowerModel,
        pmd::_PMD.AbstractUnbalancedPowerModel
    )

Fuel cost minimization objective for polynomial terms with storage.
"""
function objective_itd_min_fuel_cost_polynomial_storage(pmitd::AbstractPowerModelITD, pm::_PM.AbstractPowerModel, pmd::_PMD.AbstractUnbalancedPowerModel)

    # Extract the specific dictionary
    pm_data = pmitd.data["it"]["pm"]
    pmd_data = pmitd.data["it"]["pmd"]

    # PM
    pm_order = _PM.calc_max_cost_index(pm_data)-1
    # PMD
    pmd_order = _PMD.calc_max_cost_index(pmd_data)-1

    if pm_order <= 2 && pmd_order <= 2
        return _objective_itd_min_fuel_cost_polynomial_linquad_storage(pmitd, pm, pmd)
    else
        return _objective_itd_min_fuel_cost_polynomial_nl_storage(pmitd, pm, pmd)
    end

end


"""
    function _objective_itd_min_fuel_cost_polynomial_linquad_storage(
        pmitd::AbstractPowerModelITD,
        pm::_PM.AbstractPowerModel,
        pmd::_PMD.AbstractUnbalancedPowerModel
    )

Fuel cost minimization objective for polynomial terms linear-quadratic with storage.
"""
function _objective_itd_min_fuel_cost_polynomial_linquad_storage(pmitd::AbstractPowerModelITD, pm::_PM.AbstractPowerModel, pmd::_PMD.AbstractUnbalancedPowerModel)

    # PM
    pm_gen_cost = Dict()

    for (n, nw_ref) in _PM.nws(pm)
        for (i,gen) in nw_ref[:gen]
            pg = sum( _PM.var(pm, n, :pg, i)[c] for c in _PM.conductor_ids(pm, n) )

            if length(gen["cost"]) == 1
                pm_gen_cost[(n,i)] = gen["cost"][1]
            elseif length(gen["cost"]) == 2
                pm_gen_cost[(n,i)] = gen["cost"][1]*pg + gen["cost"][2]
            elseif length(gen["cost"]) == 3
                pm_gen_cost[(n,i)] = gen["cost"][1]*pg^2 + gen["cost"][2]*pg + gen["cost"][3]
            else
                pm_gen_cost[(n,i)] = 0.0
            end
        end
    end

    # PM Storage
    pm_strg_cost = Dict()

    for (n, nw_ref) in _PM.nws(pm)
        for (i, strg) in nw_ref[:storage]
            dsch = _PM.var(pm, n, :sd, i)                   # get discharge power value
            pm_strg_cost[(n,i)] = strg["cost"][1]*dsch     # compute discharge cost (no cost conversion is needed, cost must be in $/pu)
        end
    end

    # PMD
    pmd_gen_cost = Dict()

    for (n, nw_ref) in _PMD.nws(pmd)
        for (i,gen) in nw_ref[:gen]
            pg = sum( _PMD.var(pmd, n, :pg, i)[c] for c in gen["connections"] )

            if length(gen["cost"]) == 1
                pmd_gen_cost[(n,i)] = gen["cost"][1]
            elseif length(gen["cost"]) == 2
                pmd_gen_cost[(n,i)] = gen["cost"][1]*pg + gen["cost"][2]
            elseif length(gen["cost"]) == 3
                pmd_gen_cost[(n,i)] = gen["cost"][1]*pg^2 + gen["cost"][2]*pg + gen["cost"][3]
            else
                pmd_gen_cost[(n,i)] = 0.0
            end
        end
    end


    # PMD Storage
    pmd_strg_cost = Dict()

    for (n, nw_ref) in _PMD.nws(pmd)
        for (i, strg) in nw_ref[:storage]
            dsch = _PMD.var(pmd, n, :sd, i)                                                     # get discharge power value
            strg_cost_dollar_per_pu = strg["cost"][1]#*nw_ref[:settings]["sbase_default"]        # convert from $/kWh -> $/pu
            strg_cost_dollar_per_pu = round(strg_cost_dollar_per_pu, digits=4)
            pmd_strg_cost[(n,i)] = strg_cost_dollar_per_pu*dsch                                 # compute discharge cost
        end
    end


    # ITD (Combined objective)
    return JuMP.@objective(pmitd.model, Min,
        sum(
            sum( pm_gen_cost[(n,i)] for (i,gen) in nw_ref[:gen] )
        for (n, nw_ref) in _PM.nws(pm))
        + sum(
            sum( pm_strg_cost[(n,i)] for (i,strg) in nw_ref[:storage] )
        for (n, nw_ref) in _PM.nws(pm))
        + sum(
            sum( pmd_gen_cost[(n,i)] for (i,gen) in nw_ref[:gen] )
        for (n, nw_ref) in _PMD.nws(pmd))
        + sum(
            sum( pmd_strg_cost[(n,i)] for (i,strg) in nw_ref[:storage] )
        for (n, nw_ref) in _PMD.nws(pmd))
    )

end


"""
    function _objective_itd_min_fuel_cost_polynomial_linquad_storage(
        pmitd::AbstractIVRPowerModelITD,
        pm::_PM.AbstractIVRModel,
        pmd::_PMD.AbstractUnbalancedIVRModel
    )

Fuel cost minimization objective for polynomial terms linear-quadratic (IVR formulation) with storage.
"""
function _objective_itd_min_fuel_cost_polynomial_linquad_storage(pmitd::AbstractIVRPowerModelITD, pm::_PM.AbstractIVRModel, pmd::_PMD.AbstractUnbalancedIVRModel)

    # PM
    pm_gen_cost = Dict()

    for (n, nw_ref) in _PM.nws(pm)
        for (i,gen) in nw_ref[:gen]
            bus = gen["gen_bus"]

            #to avoid function calls inside of @NLconstraint:
            pg = _PM.var(pm, n, :pg, i)
            if length(gen["cost"]) == 1
                pm_gen_cost[(n,i)] = gen["cost"][1]
            elseif length(gen["cost"]) == 2
                pm_gen_cost[(n,i)] = JuMP.@NLexpression(pm.model, gen["cost"][1]*pg + gen["cost"][2])
            elseif length(gen["cost"]) == 3
                pm_gen_cost[(n,i)] = JuMP.@NLexpression(pm.model, gen["cost"][1]*pg^2 + gen["cost"][2]*pg + gen["cost"][3])
            else
                pm_gen_cost[(n,i)] = 0.0
            end
        end
    end

    # PM Storage
    pm_strg_cost = Dict()

    for (n, nw_ref) in _PM.nws(pm)
        for (i, strg) in nw_ref[:storage]
            dsch = _PM.var(pm, n, :sd, i)                   # get discharge power value
            pm_strg_cost[(n,i)] = strg["cost"][1]*dsch     # compute discharge cost (no cost conversion is needed, cost must be in $/pu)
        end
    end

    # PMD
    pmd_gen_cost = Dict()

    for (n, nw_ref) in _PMD.nws(pmd)
        for (i,gen) in nw_ref[:gen]
            bus = gen["gen_bus"]

            #to avoid function calls inside of @NLconstraint:
            pg = _PMD.var(pmd, n, :pg, i)
            if length(gen["cost"]) == 1
                pmd_gen_cost[(n,i)] = gen["cost"][1]
            elseif length(gen["cost"]) == 2
                pmd_gen_cost[(n,i)] = JuMP.@NLexpression(pmd.model, gen["cost"][1]*sum(pg[c] for c in gen["connections"]) + gen["cost"][2])
            elseif length(gen["cost"]) == 3
                pmd_gen_cost[(n,i)] = JuMP.@NLexpression(pmd.model, gen["cost"][1]*sum(pg[c] for c in gen["connections"])^2 + gen["cost"][2]*sum(pg[c] for c in gen["connections"]) + gen["cost"][3])
            else
                pmd_gen_cost[(n,i)] = 0.0
            end
        end
    end

    # PMD Storage
    pmd_strg_cost = Dict()

    for (n, nw_ref) in _PMD.nws(pmd)
        for (i, strg) in nw_ref[:storage]
            dsch = _PMD.var(pmd, n, :sd, i)                                                     # get discharge power value
            strg_cost_dollar_per_pu = strg["cost"][1]#*nw_ref[:settings]["sbase_default"]        # convert from $/kWh -> $/pu
            strg_cost_dollar_per_pu = round(strg_cost_dollar_per_pu, digits=4)
            pmd_strg_cost[(n,i)] = strg_cost_dollar_per_pu*dsch                                 # compute discharge cost
        end
    end


    # ITD (Combined objective)
    return JuMP.@NLobjective(pmitd.model, Min,
        sum(
            sum( pm_gen_cost[(n,i)] for (i,gen) in nw_ref[:gen] )
        for (n, nw_ref) in _PM.nws(pm))
        + sum(
            sum( pm_strg_cost[(n,i)] for (i,strg) in nw_ref[:storage] )
        for (n, nw_ref) in _PM.nws(pm))
        + sum(
            sum( pmd_gen_cost[(n,i)] for (i,gen) in nw_ref[:gen] )
        for (n, nw_ref) in _PMD.nws(pmd))
        + sum(
            sum( pmd_strg_cost[(n,i)] for (i,strg) in nw_ref[:storage] )
        for (n, nw_ref) in _PMD.nws(pmd))
    )

end


"""
    function _objective_itd_min_fuel_cost_polynomial_nl_storage(
        pmitd::AbstractIVRPowerModelITD,
        pm::_PM.AbstractIVRModel,
        pmd::_PMD.AbstractUnbalancedIVRModel
    )

Fuel cost minimization objective for polynomial terms non-linear (IVR formulation) with storage.
"""
function _objective_itd_min_fuel_cost_polynomial_nl_storage(pmitd::AbstractIVRPowerModelITD, pm::_PM.AbstractIVRModel, pmd::_PMD.AbstractUnbalancedIVRModel)

    # PM
    pm_gen_cost = Dict()
    for (n, nw_ref) in _PM.nws(pm)
        for (i,gen) in nw_ref[:gen]
            bus = gen["gen_bus"]

            #to avoid function calls inside of @NLconstraint:
            pg = _PM.var(pm, n, :pg, i)
            cost_rev = reverse(gen["cost"])
            if length(cost_rev) == 1
                pm_gen_cost[(n,i)] = JuMP.@NLexpression(pmitd.model, cost_rev[1])
            elseif length(cost_rev) == 2
                pm_gen_cost[(n,i)] = JuMP.@NLexpression(pmitd.model, cost_rev[1] + cost_rev[2]*pg)
            elseif length(cost_rev) == 3
                pm_gen_cost[(n,i)] = JuMP.@NLexpression(pmitd.model, cost_rev[1] + cost_rev[2]*pg + cost_rev[3]*pg^2)
            elseif length(cost_rev) >= 4
                cost_rev_nl = cost_rev[4:end]
                pm_gen_cost[(n,i)] = JuMP.@NLexpression(pmitd.model, cost_rev[1] + cost_rev[2]*pg + cost_rev[3]*pg^2 + sum( v*pg^(d+3) for (d,v) in enumerate(cost_rev_nl)) )
            else
                pm_gen_cost[(n,i)] = JuMP.@NLexpression(pmitd.model, 0.0)
            end
        end
    end

    # PM Storage
    pm_strg_cost = Dict()

    for (n, nw_ref) in _PM.nws(pm)
        for (i, strg) in nw_ref[:storage]
            dsch = _PM.var(pm, n, :sd, i)                   # get discharge power value
            pm_strg_cost[(n,i)] = strg["cost"][1]*dsch     # compute discharge cost (no cost conversion is needed, cost must be in $/pu)
        end
    end


    # PMD
    pmd_gen_cost = Dict()
    for (n, nw_ref) in _PMD.nws(pmd)
        for (i,gen) in nw_ref[:gen]

            pg = _PMD.var(pmd, n, :pg, i)
            cost_rev = reverse(gen["cost"])

            if length(cost_rev) == 1
                pmd_gen_cost[(n,i)] = JuMP.@NLexpression(pmitd.model, cost_rev[1])
            elseif length(cost_rev) == 2
                pmd_gen_cost[(n,i)] = JuMP.@NLexpression(pmitd.model, cost_rev[1] + cost_rev[2]*sum(pg[c] for c in gen["connections"]))
            elseif length(cost_rev) == 3
                pmd_gen_cost[(n,i)] = JuMP.@NLexpression(pmitd.model, cost_rev[1] + cost_rev[2]*sum(pg[c] for c in gen["connections"]) + cost_rev[3]*sum(pg[c] for c in gen["connections"])^2)
            elseif length(cost_rev) >= 4
                cost_rev_nl = cost_rev[4:end]
                pmd_gen_cost[(n,i)] = JuMP.@NLexpression(pmitd.model, cost_rev[1] + cost_rev[2]*sum(pg[c] for c in gen["connections"]) + cost_rev[3]*sum(pg[c] for c in gen["connections"])^2 + sum( v*sum(pg[c] for c in gen["connections"])^(d+3) for (d,v) in enumerate(cost_rev_nl)) )
            else
                pmd_gen_cost[(n,i)] = JuMP.@NLexpression(pmitd.model, 0.0)
            end
        end
    end

    # PMD Storage
    pmd_strg_cost = Dict()

    for (n, nw_ref) in _PMD.nws(pmd)
        for (i, strg) in nw_ref[:storage]
            dsch = _PMD.var(pmd, n, :sd, i)                                                     # get discharge power value
            strg_cost_dollar_per_pu = strg["cost"][1]#*nw_ref[:settings]["sbase_default"]        # convert from $/kWh -> $/pu
            strg_cost_dollar_per_pu = round(strg_cost_dollar_per_pu, digits=4)
            pmd_strg_cost[(n,i)] = strg_cost_dollar_per_pu*dsch                                 # compute discharge cost
        end
    end


    # ITD (Combined objective)
    return JuMP.@NLobjective(pmitd.model, Min,
        sum(
            sum( pm_gen_cost[(n,i)] for (i,gen) in nw_ref[:gen] )
        for (n, nw_ref) in _PM.nws(pm))
        + sum(
            sum( pm_strg_cost[(n,i)] for (i,strg) in nw_ref[:storage] )
        for (n, nw_ref) in _PM.nws(pm))
        + sum(
            sum( pmd_gen_cost[(n,i)] for (i,gen) in nw_ref[:gen] )
        for (n, nw_ref) in _PMD.nws(pmd))
        + sum(
            sum( pmd_strg_cost[(n,i)] for (i,strg) in nw_ref[:storage] )
        for (n, nw_ref) in _PMD.nws(pmd))
    )

end


"""
    function _objective_itd_min_fuel_cost_polynomial_nl_storage(
        pmitd::AbstractPowerModelITD,
        pm::_PM.AbstractPowerModel,
        pmd::_PMD.AbstractUnbalancedPowerModel
    )

Fuel cost minimization objective for polynomial terms non-linear with storage.
"""
function _objective_itd_min_fuel_cost_polynomial_nl_storage(pmitd::AbstractPowerModelITD, pm::_PM.AbstractPowerModel, pmd::_PMD.AbstractUnbalancedPowerModel)

    # PM
    pm_gen_cost = Dict()
    for (n, nw_ref) in _PM.nws(pm)
        for (i,gen) in nw_ref[:gen]
            pg = sum( _PM.var(pm, n, :pg, i)[c] for c in _PM.conductor_ids(pm, n))

            cost_rev = reverse(gen["cost"])
            if length(cost_rev) == 1
                pm_gen_cost[(n,i)] = JuMP.@NLexpression(pmitd.model, cost_rev[1])
            elseif length(cost_rev) == 2
                pm_gen_cost[(n,i)] = JuMP.@NLexpression(pmitd.model, cost_rev[1] + cost_rev[2]*pg)
            elseif length(cost_rev) == 3
                pm_gen_cost[(n,i)] = JuMP.@NLexpression(pmitd.model, cost_rev[1] + cost_rev[2]*pg + cost_rev[3]*pg^2)
            elseif length(cost_rev) >= 4
                cost_rev_nl = cost_rev[4:end]
                pm_gen_cost[(n,i)] = JuMP.@NLexpression(pmitd.model, cost_rev[1] + cost_rev[2]*pg + cost_rev[3]*pg^2 + sum( v*pg^(d+3) for (d,v) in enumerate(cost_rev_nl)) )
            else
                pm_gen_cost[(n,i)] = JuMP.@NLexpression(pmitd.model, 0.0)
            end
        end
    end

    # PM Storage
    pm_strg_cost = Dict()

    for (n, nw_ref) in _PM.nws(pm)
        for (i, strg) in nw_ref[:storage]
            dsch = _PM.var(pm, n, :sd, i)                   # get discharge power value
            pm_strg_cost[(n,i)] = strg["cost"][1]*dsch     # compute discharge cost (no cost conversion is needed, cost must be in $/pu)
        end
    end


    # PMD
    pmd_gen_cost = Dict()
    for (n, nw_ref) in _PMD.nws(pmd)
        for (i,gen) in nw_ref[:gen]
            pg = sum( _PMD.var(pmd, n, :pg, i)[c] for c in gen["connections"] )

            cost_rev = reverse(gen["cost"])

            # This is needed to get around error: "unexpected affine expression in nl objective", See JuMP Documentation: 'AffExpr and QuadExpr cannot be used'
            pg_aux = JuMP.@variable(pmitd.model, base_name="$(n)_pg_aux_dist_$(i)")
            JuMP.@constraint(pmitd.model, pg_aux == pg)

            if length(cost_rev) == 1
                pmd_gen_cost[(n,i)] = JuMP.@NLexpression(pmitd.model, cost_rev[1])
            elseif length(cost_rev) == 2
                pmd_gen_cost[(n,i)] = JuMP.@NLexpression(pmitd.model, cost_rev[1] + cost_rev[2]*pg_aux)
            elseif length(cost_rev) == 3
                pmd_gen_cost[(n,i)] = JuMP.@NLexpression(pmitd.model, cost_rev[1] + cost_rev[2]*pg_aux + cost_rev[3]*pg_aux^2)
            elseif length(cost_rev) >= 4
                cost_rev_nl = cost_rev[4:end]
                pmd_gen_cost[(n,i)] = JuMP.@NLexpression(pmitd.model, cost_rev[1] + cost_rev[2]*pg_aux + cost_rev[3]*pg_aux^2 + sum( v*pg_aux^(d+3) for (d,v) in enumerate(cost_rev_nl)) )
            else
                pmd_gen_cost[(n,i)] = JuMP.@NLexpression(pmitd.model, 0.0)
            end
        end
    end

    # PMD Storage
    pmd_strg_cost = Dict()

    for (n, nw_ref) in _PMD.nws(pmd)
        for (i, strg) in nw_ref[:storage]
            dsch = _PMD.var(pmd, n, :sd, i)                                                     # get discharge power value
            strg_cost_dollar_per_pu = strg["cost"][1]#*nw_ref[:settings]["sbase_default"]        # convert from $/kWh -> $/pu
            strg_cost_dollar_per_pu = round(strg_cost_dollar_per_pu, digits=4)
            pmd_strg_cost[(n,i)] = strg_cost_dollar_per_pu*dsch                                 # compute discharge cost
        end
    end

    # ITD (Combined objective)
    return JuMP.@NLobjective(pmitd.model, Min,
        sum(
            sum( pm_gen_cost[(n,i)] for (i,gen) in nw_ref[:gen] )
        for (n, nw_ref) in _PM.nws(pm))
        + sum(
            sum( pm_strg_cost[(n,i)] for (i,strg) in nw_ref[:storage] )
        for (n, nw_ref) in _PM.nws(pm))
        + sum(
            sum( pmd_gen_cost[(n,i)] for (i,gen) in nw_ref[:gen] )
        for (n, nw_ref) in _PMD.nws(pmd))
        + sum(
            sum( pmd_strg_cost[(n,i)] for (i,strg) in nw_ref[:storage] )
        for (n, nw_ref) in _PMD.nws(pmd))
    )

end
