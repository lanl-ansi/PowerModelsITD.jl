# ACP Constraints & Boundary Linking Vars.

"""
    function constraint_transmission_power_balance(
        pm::_PM.AbstractACPModel,
        n::Int,
        i::Int,
        bus_arcs,
        bus_arcs_dc,
        bus_arcs_sw,
        bus_gens,
        bus_storage,
        bus_pd,
        bus_qd,
        bus_gs,
        bus_bs,
        bus_arcs_boundary_from
    )

ACP transmission constraint power balance for decomposition model.
"""
function constraint_transmission_power_balance(pm::_PM.AbstractACPModel, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_qd, bus_gs, bus_bs, bus_arcs_boundary_from)

    vm = _PM.var(pm, n, :vm, i)

    p    = _PM.get(_PM.var(pm, n),    :p, Dict()); _PM._check_var_keys(p, bus_arcs, "active power", "branch")
    q    = _PM.get(_PM.var(pm, n),    :q, Dict()); _PM._check_var_keys(q, bus_arcs, "reactive power", "branch")
    pg   = _PM.get(_PM.var(pm, n),   :pg, Dict()); _PM._check_var_keys(pg, bus_gens, "active power", "generator")
    qg   = _PM.get(_PM.var(pm, n),   :qg, Dict()); _PM._check_var_keys(qg, bus_gens, "reactive power", "generator")
    ps   = _PM.get(_PM.var(pm, n),   :ps, Dict()); _PM._check_var_keys(ps, bus_storage, "active power", "storage")
    qs   = _PM.get(_PM.var(pm, n),   :qs, Dict()); _PM._check_var_keys(qs, bus_storage, "reactive power", "storage")
    psw  = _PM.get(_PM.var(pm, n),  :psw, Dict()); _PM._check_var_keys(psw, bus_arcs_sw, "active power", "switch")
    qsw  = _PM.get(_PM.var(pm, n),  :qsw, Dict()); _PM._check_var_keys(qsw, bus_arcs_sw, "reactive power", "switch")
    p_dc = _PM.get(_PM.var(pm, n), :p_dc, Dict()); _PM._check_var_keys(p_dc, bus_arcs_dc, "active power", "dcline")
    q_dc = _PM.get(_PM.var(pm, n), :q_dc, Dict()); _PM._check_var_keys(q_dc, bus_arcs_dc, "reactive power", "dcline")

    # Boundary
    pbound_load    = get(_PM.var(pm, n),    :pbound_load, Dict()); _PM._check_var_keys(pbound_load, bus_arcs_boundary_from, "active power", "boundary")
    qbound_load    = get(_PM.var(pm, n),    :qbound_load, Dict()); _PM._check_var_keys(qbound_load, bus_arcs_boundary_from, "reactive power", "boundary")

    # the check "typeof(p[arc]) <: JuMP.NonlinearExpression" is required for the
    # case when p/q are nonlinear expressions instead of decision variables
    # once NLExpressions are first order in JuMP it should be possible to
    # remove this.
    nl_form = length(bus_arcs) > 0 && (typeof(p[iterate(bus_arcs)[1]]) <: JuMP.NonlinearExpression)

    if !nl_form
        cstr_p = JuMP.@constraint(pm.model,
            sum(p[a] for a in bus_arcs)
            + sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
            + sum(psw[a_sw] for a_sw in bus_arcs_sw)
            + sum(pbound_load[a_pbound_load][1] for a_pbound_load in bus_arcs_boundary_from)
            ==
            sum(pg[g] for g in bus_gens)
            - sum(ps[s] for s in bus_storage)
            - sum(pd for (i,pd) in bus_pd)
            - sum(gs for (i,gs) in bus_gs)*vm^2
        )
    else
        cstr_p = JuMP.@NLconstraint(pm.model,
            sum(p[a] for a in bus_arcs)
            + sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
            + sum(psw[a_sw] for a_sw in bus_arcs_sw)
            + sum(pbound_load[a_pbound_load][1] for a_pbound_load in bus_arcs_boundary_from)
            ==
            sum(pg[g] for g in bus_gens)
            - sum(ps[s] for s in bus_storage)
            - sum(pd for (i,pd) in bus_pd)
            - sum(gs for (i,gs) in bus_gs)*vm^2
        )
    end

    if !nl_form
        cstr_q = JuMP.@constraint(pm.model,
            sum(q[a] for a in bus_arcs)
            + sum(q_dc[a_dc] for a_dc in bus_arcs_dc)
            + sum(qsw[a_sw] for a_sw in bus_arcs_sw)
            + sum(qbound_load[a_qbound_load][1] for a_qbound_load in bus_arcs_boundary_from)
            ==
            sum(qg[g] for g in bus_gens)
            - sum(qs[s] for s in bus_storage)
            - sum(qd for (i,qd) in bus_qd)
            + sum(bs for (i,bs) in bus_bs)*vm^2
        )
    else
        cstr_q = JuMP.@NLconstraint(pm.model,
            sum(q[a] for a in bus_arcs)
            + sum(q_dc[a_dc] for a_dc in bus_arcs_dc)
            + sum(qsw[a_sw] for a_sw in bus_arcs_sw)
            + sum(qbound_load[a_qbound_load][1] for a_qbound_load in bus_arcs_boundary_from)
            ==
            sum(qg[g] for g in bus_gens)
            - sum(qs[s] for s in bus_storage)
            - sum(qd for (i,qd) in bus_qd)
            + sum(bs for (i,bs) in bus_bs)*vm^2
        )
    end

    if _IM.report_duals(pm)
        _PM.sol(pm, n, :bus, i)[:lam_kcl_r] = cstr_p
        _PM.sol(pm, n, :bus, i)[:lam_kcl_i] = cstr_q
    end

end


function constraint_distribution_power_balance(pmd::_PMD.AbstractUnbalancedACPModel, n::Int, i::Int, terminals::Vector{Int}, grounded::Vector{Bool}, bus_arcs::Vector{Tuple{Tuple{Int,Int,Int},Vector{Int}}}, bus_arcs_sw::Vector{Tuple{Tuple{Int,Int,Int},Vector{Int}}}, bus_arcs_trans::Vector{Tuple{Tuple{Int,Int,Int},Vector{Int}}}, bus_gens::Vector{Tuple{Int,Vector{Int}}}, bus_storage::Vector{Tuple{Int,Vector{Int}}}, bus_loads::Vector{Tuple{Int,Vector{Int}}}, bus_shunts::Vector{Tuple{Int,Vector{Int}}}, bus_arcs_boundary_to)

    vm = _PMD.var(pmd, n, :vm, i)
    va = _PMD.var(pmd, n, :va, i)

    p    = _PMD.get(_PMD.var(pmd, n),      :p, Dict()); _PMD._check_var_keys(  p, bus_arcs, "active power", "branch")
    q    = _PMD.get(_PMD.var(pmd, n),      :q, Dict()); _PMD._check_var_keys(  q, bus_arcs, "reactive power", "branch")
    pg   = _PMD.get(_PMD.var(pmd, n), :pg_bus, Dict()); _PMD._check_var_keys( pg, bus_gens, "active power", "generator")
    qg   = _PMD.get(_PMD.var(pmd, n), :qg_bus, Dict()); _PMD._check_var_keys( qg, bus_gens, "reactive power", "generator")
    ps   = _PMD.get(_PMD.var(pmd, n),     :ps, Dict()); _PMD._check_var_keys( ps, bus_storage, "active power", "storage")
    qs   = _PMD.get(_PMD.var(pmd, n),     :qs, Dict()); _PMD._check_var_keys( qs, bus_storage, "reactive power", "storage")
    psw  = _PMD.get(_PMD.var(pmd, n),    :psw, Dict()); _PMD._check_var_keys(psw, bus_arcs_sw, "active power", "switch")
    qsw  = _PMD.get(_PMD.var(pmd, n),    :qsw, Dict()); _PMD._check_var_keys(qsw, bus_arcs_sw, "reactive power", "switch")
    pt   = _PMD.get(_PMD.var(pmd, n),     :pt, Dict()); _PMD._check_var_keys( pt, bus_arcs_trans, "active power", "transformer")
    qt   = _PMD.get(_PMD.var(pmd, n),     :qt, Dict()); _PMD._check_var_keys( qt, bus_arcs_trans, "reactive power", "transformer")
    pd   = _PMD.get(_PMD.var(pmd, n), :pd_bus, Dict()); _PMD._check_var_keys( pd, bus_loads, "active power", "load")
    qd   = _PMD.get(_PMD.var(pmd, n), :qd_bus, Dict()); _PMD._check_var_keys( pd, bus_loads, "reactive power", "load")

    # Boundary
    pbound_aux_phases    = get(_PMD.var(pmd, n),    :pbound_aux_phases, Dict()); _PMD._check_var_keys(pbound_aux_phases, bus_arcs_boundary_to, "active power", "boundary")
    qbound_aux_phases    = get(_PMD.var(pmd, n),    :qbound_aux_phases, Dict()); _PMD._check_var_keys(qbound_aux_phases, bus_arcs_boundary_to, "reactive power", "boundary")

    Gs, Bs = _PMD._build_bus_shunt_matrices(pmd, n, terminals, bus_shunts)

    cstr_p = []
    cstr_q = []

    ungrounded_terminals = [(idx,t) for (idx,t) in enumerate(terminals) if !grounded[idx]]

    for (idx,t) in ungrounded_terminals
        if any(Bs[idx,jdx] != 0 for (jdx, u) in ungrounded_terminals if idx != jdx) || any(Gs[idx,jdx] != 0 for (jdx, u) in ungrounded_terminals if idx != jdx)
            cp = JuMP.@NLconstraint(pmd.model,
                  sum(  p[a][t] for (a, conns) in bus_arcs if t in conns)
                + sum(psw[a][t] for (a, conns) in bus_arcs_sw if t in conns)
                + sum( pt[a][t] for (a, conns) in bus_arcs_trans if t in conns)
                - sum( pg[g][t] for (g, conns) in bus_gens if t in conns)
                + sum( ps[s][t] for (s, conns) in bus_storage if t in conns)
                + sum( pd[l][t] for (l, conns) in bus_loads if t in conns)
                - sum( pbound_aux_phases[a_pbound_aux][t] for a_pbound_aux in bus_arcs_boundary_to)
                + ( # shunt
                    +Gs[idx,idx] * vm[t]^2
                    +sum( Gs[idx,jdx] * vm[t]*vm[u] * cos(va[t]-va[u])
                         +Bs[idx,jdx] * vm[t]*vm[u] * sin(va[t]-va[u])
                        for (jdx,u) in ungrounded_terminals if idx != jdx)
                )
                ==
                0.0
            )
            push!(cstr_p, cp)

            cq = JuMP.@NLconstraint(pmd.model,
                  sum(  q[a][t] for (a, conns) in bus_arcs if t in conns)
                + sum(qsw[a][t] for (a, conns) in bus_arcs_sw if t in conns)
                + sum( qt[a][t] for (a, conns) in bus_arcs_trans if t in conns)
                - sum( qg[g][t] for (g, conns) in bus_gens if t in conns)
                + sum( qs[s][t] for (s, conns) in bus_storage if t in conns)
                + sum( qd[l][t] for (l, conns) in bus_loads if t in conns)
                - sum( qbound_aux_phases[a_qbound_aux][t] for a_qbound_aux in bus_arcs_boundary_to)
                + ( # shunt
                    -Bs[idx,idx] * vm[t]^2
                    -sum( Bs[idx,jdx] * vm[t]*vm[u] * cos(va[t]-va[u])
                         -Gs[idx,jdx] * vm[t]*vm[u] * sin(va[t]-va[u])
                         for (jdx,u) in ungrounded_terminals if idx != jdx)
                )
                ==
                0.0
            )
            push!(cstr_q, cq)
        else
            cp = @smart_constraint(pmd.model, [p, pg, ps, psw, pt, pd, pbound_aux_phases, vm],
                  sum(  p[a][t] for (a, conns) in bus_arcs if t in conns)
                + sum(psw[a][t] for (a, conns) in bus_arcs_sw if t in conns)
                + sum( pt[a][t] for (a, conns) in bus_arcs_trans if t in conns)
                - sum( pg[g][t] for (g, conns) in bus_gens if t in conns)
                + sum( ps[s][t] for (s, conns) in bus_storage if t in conns)
                + sum( pd[l][t] for (l, conns) in bus_loads if t in conns)
                - sum( pbound_aux_phases[a_pbound_aux][t] for a_pbound_aux in bus_arcs_boundary_to)
                + Gs[idx,idx] * vm[t]^2
                ==
                0.0
            )
            push!(cstr_p, cp)

            cq = @smart_constraint(pmd.model, [q, qg, qs, qsw, qt, qd, qbound_aux_phases, vm],
                  sum(  q[a][t] for (a, conns) in bus_arcs if t in conns)
                + sum(qsw[a][t] for (a, conns) in bus_arcs_sw if t in conns)
                + sum( qt[a][t] for (a, conns) in bus_arcs_trans if t in conns)
                - sum( qg[g][t] for (g, conns) in bus_gens if t in conns)
                + sum( qs[s][t] for (s, conns) in bus_storage if t in conns)
                + sum( qd[l][t] for (l, conns) in bus_loads if t in conns)
                - sum( qbound_aux_phases[a_qbound_aux][t] for a_qbound_aux in bus_arcs_boundary_to)
                - Bs[idx,idx] * vm[t]^2
                ==
                0.0
            )
            push!(cstr_q, cq)
        end
    end

    _PMD.con(pmd, n, :lam_kcl_r)[i] = cstr_p
    _PMD.con(pmd, n, :lam_kcl_i)[i] = cstr_q

    if _IM.report_duals(pmd)
        sol(pmd, n, :bus, i)[:lam_kcl_r] = cstr_p
        sol(pmd, n, :bus, i)[:lam_kcl_i] = cstr_q
    end

end



"""
    function constraint_boundary_voltage_magnitude(
        pmd::_PMD.ACPUPowerModel,
        i::Int,
        f_idx::Tuple{Int,Int,Int},
        f_connections::Vector{Int},
        t_connections::Vector{Int};
        nw::Int = nw_id_default
    )

ACPU boundary bus voltage magnitude constraints.
"""
function constraint_boundary_voltage_magnitude(pmd::_PMD.ACPUPowerModel, ::Int, t_bus::Int, ::Vector{Int}, ::Vector{Int}; nw::Int=nw_id_default)

    vm_source = _PMD.var(pmd, nw, :vm, t_bus)

    # Add constraint(s): m->magnitude
    JuMP.@constraint(pmd.model, vm_source[1] == vm_source[2])
    JuMP.@constraint(pmd.model, vm_source[1] == vm_source[3])

end


"""
    function constraint_boundary_voltage_angle(
        pmd::_PMD.ACPUPowerModel,
        i::Int,
        f_idx::Tuple{Int,Int,Int},
        f_connections::Vector{Int},
        t_connections::Vector{Int};
        nw::Int = nw_id_default
    )

ACPU boundary bus voltage angle constraints.
"""
function constraint_boundary_voltage_angle(pmd::_PMD.ACPUPowerModel, ::Int, t_bus::Int, ::Vector{Int}, ::Vector{Int}; nw::Int=nw_id_default)

    ## --- NOTE: These constraints seem to make ACP-ACPU decomposition formulation harder to solve
    ## if the  _PMD.constraint_mc_theta_ref(pmd_model, i) is kept ---

    # --- Either this constraint ---
    # _PMD.constraint_mc_theta_ref(pmd, t_bus)

    # --- Or these constraints ---.

    va_source = _PMD.var(pmd, nw, :va, t_bus)
    # Add constraint(s): angles
    JuMP.@constraint(pmd.model, va_source[1] == 0.0)
    # Add constraints related to 120 degrees offset for the distribution b and c phases
    shift_120degs_rad = deg2rad(120)
    # Offset constraints for other phases (-+120 degrees)
    JuMP.@constraint(pmd.model, va_source[2] == (va_source[1] - shift_120degs_rad))
    JuMP.@constraint(pmd.model, va_source[3] == (va_source[1] + shift_120degs_rad))

end


"""
    function constraint_transmission_boundary_power_shared_vars_scaled(
        pm::_PM.AbstractACPModel,
        i::Int;
        nw::Int = nw_id_default
    )

ACPU power shared variables scaling constraints.
"""
function constraint_transmission_boundary_power_shared_vars_scaled(pm::_PM.AbstractACPModel, i::Int; nw::Int=nw_id_default)

    boundary = _PM.ref(pm, nw, :boundary, i)
    f_bus = boundary["f_bus"] # convention: from bus Transmission always!
    t_bus = boundary["t_bus"] # convention: to bus Distribution always!

    # Pbound_load vars
    f_idx = (i, f_bus, t_bus)
    pbound_load = _PM.var(pm, nw, :pbound_load, f_idx)
    qbound_load = _PM.var(pm, nw, :qbound_load, f_idx)

    pbound_load_scaled = _PM.var(pm, nw, :pbound_load_scaled, f_idx)
    qbound_load_scaled = _PM.var(pm, nw, :qbound_load_scaled, f_idx)

    # Get the base power conversion factor for T&D boundary connection
    base_conv_factor = boundary["base_conv_factor"]

    # Add scaling constraint
    JuMP.@constraint(pm.model, pbound_load_scaled[1] == pbound_load[1]*(base_conv_factor))
    JuMP.@constraint(pm.model, qbound_load_scaled[1] == qbound_load[1]*(base_conv_factor))

end


# TODO: multinetwork compatibility by using nw info.
"""
    function generate_boundary_linking_vars(
        pm::_PM.ACPPowerModel,
        pmd::_PMD.ACPUPowerModel,
        boundary_number::String;
        nw::Int = nw_id_default,
        export_models::Bool=false
    )

Generates the ACP-ACPU boundary linking vars vector to be used by the IDEC Optimizer.
The parameter `export_models` is a boolean that determines if the JuMP models' shared variable indices are exported to the pwd as `.nl` files.
"""
function generate_boundary_linking_vars(pm::_PM.ACPPowerModel, pmd::_PMD.ACPUPowerModel, boundary_number::String; nw::Int=nw_id_default, export_models::Bool=false)

    # Parse to Int
    boundary_number = parse(Int64, boundary_number)

    # Get boundary info.
    boundary = _PMD.ref(pmd, nw, :boundary, boundary_number)

    f_bus = boundary["f_bus"] # convention: from bus Transmission always!
    t_bus = boundary["t_bus"] # convention: to bus Distribution always!

    # Distribution: Aux vars (subproblem)
    f_idx = (boundary_number, f_bus, t_bus)
    p_aux = _PMD.var(pmd, nw, :pbound_aux, f_idx)
    q_aux = _PMD.var(pmd, nw, :qbound_aux, f_idx)

    # Distribution: vm (subproblem)
    vm = _PMD.var(pmd, nw, :vm, t_bus)

    # Transmission: Vm (master)
    Vm = _PM.var(pm, nw, :vm, f_bus)

    # Transmission: Pload & Qload (master)
    P_load = _PM.var(pm, nw, :pbound_load_scaled, f_idx)
    Q_load = _PM.var(pm, nw, :qbound_load_scaled, f_idx)

    boundary_linking_vars = [[P_load[1], Q_load[1], Vm], [p_aux[1], q_aux[1], vm[1]]]

    # # Distribution: va (subproblem)
    # va = _PMD.var(pmd, nw, :va, t_bus)
    # # Transmission: Va (master)
    # Va = _PM.var(pm, nw, :va, f_bus)
    # boundary_linking_vars = [[P_load[1], Q_load[1], Vm, Va], [p_aux[1], q_aux[1], vm[1], va[1]]]

    if (export_models == true)
        # Open file where shared vars indices are going to be written
        file = open("shared_vars.txt", "a")
        # Loop through the vector of shared variables
        for sh_vect in boundary_linking_vars
            for sh_var in sh_vect
                str_to_write = "Shared Variable ($(sh_var)) Index: $(sh_var.index)\n"
                # Write the string to the file
                write(file, str_to_write)
            end
        end
        # Close the file
        close(file)
    end

    return boundary_linking_vars

end
