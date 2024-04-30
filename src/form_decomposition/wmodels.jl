# W-Models (i.e., SOCBF) Constraints

"""
    function constraint_transmission_power_balance(
        pm::_PM.AbstractWModels,
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

W Models (e.g., SOCBF) transmission constraint power balance.
"""
function constraint_transmission_power_balance(pm::_PM.AbstractWModels, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_qd, bus_gs, bus_bs, bus_arcs_boundary_from)
    w    = _PM.var(pm, n, :w, i)
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

    cstr_p = JuMP.@constraint(pm.model,
        sum(p[a] for a in bus_arcs)
        + sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
        + sum(psw[a_sw] for a_sw in bus_arcs_sw)
        + sum(pbound_load[a_pbound_load][1] for a_pbound_load in bus_arcs_boundary_from)
        ==
        sum(pg[g] for g in bus_gens)
        - sum(ps[s] for s in bus_storage)
        - sum(pd for pd in values(bus_pd))
        - sum(gs for gs in values(bus_gs))*w
    )
    cstr_q = JuMP.@constraint(pm.model,
        sum(q[a] for a in bus_arcs)
        + sum(q_dc[a_dc] for a_dc in bus_arcs_dc)
        + sum(qsw[a_sw] for a_sw in bus_arcs_sw)
        + sum(qbound_load[a_qbound_load][1] for a_qbound_load in bus_arcs_boundary_from)
        ==
        sum(qg[g] for g in bus_gens)
        - sum(qs[s] for s in bus_storage)
        - sum(qd for qd in values(bus_qd))
        + sum(bs for bs in values(bus_bs))*w
    )

    if _IM.report_duals(pm)
        _PM.sol(pm, n, :bus, i)[:lam_kcl_r] = cstr_p
        _PM.sol(pm, n, :bus, i)[:lam_kcl_i] = cstr_q
    end
end


"""
    function constraint_boundary_voltage_magnitude(
        pmd::_PMD.SOCNLPUBFPowerModel,
        i::Int,
        f_idx::Tuple{Int,Int,Int},
        f_connections::Vector{Int},
        t_connections::Vector{Int};
        nw::Int=nw_id_default
    )

SOCNLPUBFPowerModel boundary bus voltage magnitude constraints.
"""
function constraint_boundary_voltage_magnitude(pmd::_PMD.SOCNLPUBFPowerModel, i::Int, t_bus::Int, f_connections::Vector{Int}, t_connections::Vector{Int}; nw::Int=nw_id_default)

    w_source = _PMD.var(pmd, nw, :w, t_bus)

    # Add constraint(s): m->magnitude
    JuMP.@constraint(pmd.model, w_source[1] == w_source[2])
    JuMP.@constraint(pmd.model, w_source[1] == w_source[3])

end



"""
    function constraint_boundary_voltage_angle(
        pmd::_PMD.SOCNLPUBFPowerModel,
        i::Int,
        f_idx::Tuple{Int,Int,Int},
        f_connections::Vector{Int},
        t_connections::Vector{Int};
        nw::Int = nw_id_default
    )

SOCNLPUBFPowerModel boundary bus voltage angle constraints.
"""
function constraint_boundary_voltage_angle(pmd::_PMD.SOCNLPUBFPowerModel, ::Int, t_bus::Int, ::Vector{Int}, ::Vector{Int}; nw::Int=nw_id_default)

    Wr_to = _PMD.var(pmd, nw, :Wr, t_bus)
    Wi_to = _PMD.var(pmd, nw, :Wi, t_bus)

    shift_120degs_rad = deg2rad(120)

    # These constraints assume angles at the T&D boundary are 0, -120, 120.
    JuMP.@constraint(pmd.model, Wi_to[1,2] == (Wr_to[1,2]*tan(shift_120degs_rad)))
    JuMP.@constraint(pmd.model, Wi_to[1,3] == (Wr_to[1,3]*tan(-shift_120degs_rad)))
    JuMP.@constraint(pmd.model, Wi_to[2,3] == (Wr_to[2,3]*tan(shift_120degs_rad)))

end



"""
    function constraint_transmission_boundary_power_shared_vars_scaled(
        pm::_PM.AbstractSOCBFModel,
        i::Int;
        nw::Int = nw_id_default
    )

SOCBF power shared variables scaling constraints.
"""
function constraint_transmission_boundary_power_shared_vars_scaled(pm::_PM.AbstractSOCBFModel, i::Int; nw::Int=nw_id_default)

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
        pm::_PM.AbstractSOCBFModel,
        pmd::_PMD.SOCNLPUBFPowerModel,
        boundary_number::String;
        nw::Int = nw_id_default

    )

Generates the SOCBF-SOCNLPUBF boundary linking vars vector to be used by the IDEC Optimizer.
The parameter `export_models` is a boolean that determines if the JuMP models' shared variable indices are exported to the pwd as `.nl` files.
"""
function generate_boundary_linking_vars(pm::_PM.AbstractSOCBFModel, pmd::_PMD.SOCNLPUBFPowerModel, boundary_number::String; nw::Int=nw_id_default, export_models::Bool=false)

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

    # Distribution: w (subproblem)
    w = _PMD.var(pmd, nw, :w, t_bus)

    # Transmission: W (master)
    W = _PM.var(pm, nw, :w, f_bus)

    # Transmission: Pload & Qload (master)
    P_load = _PM.var(pm, nw, :pbound_load_scaled, f_idx)
    Q_load = _PM.var(pm, nw, :qbound_load_scaled, f_idx)

    boundary_linking_vars = [[P_load[1], Q_load[1], W], [p_aux[1], q_aux[1], w[1]]]

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
