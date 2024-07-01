"""
    function constraint_transmission_current_balance(
        pm::_PM.AbstractIVRModel,
        n::Int,
        i::Int,
        bus_arcs,
        bus_arcs_dc,
        bus_gens,
        bus_pd,
        bus_qd,
        bus_gs,
        bus_bs,
        bus_arcs_boundary_from
    )

IVR transmission constraint current balance for decomposition model.
"""
function constraint_transmission_current_balance(pm::_PM.AbstractIVRModel, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_gens, bus_pd, bus_qd, bus_gs, bus_bs, bus_arcs_boundary_from)
    vr = _PM.var(pm, n, :vr, i)
    vi = _PM.var(pm, n, :vi, i)

    cr =  _PM.get(_PM.var(pm, n),   :cr, Dict()); _PM._check_var_keys(cr, bus_arcs, "real current", "branch")
    ci =  _PM.get(_PM.var(pm, n),   :ci, Dict()); _PM._check_var_keys(ci, bus_arcs, "imaginary current", "branch")
    crdc = _PM.get(_PM.var(pm, n),  :crdc, Dict()); _PM._check_var_keys(crdc, bus_arcs_dc, "real current", "dcline")
    cidc = _PM.get(_PM.var(pm, n),  :cidc, Dict()); _PM._check_var_keys(cidc, bus_arcs_dc, "imaginary current", "dcline")
    crg = _PM.get(_PM.var(pm, n), :crg, Dict()); _PM._check_var_keys(crg, bus_gens, "real current", "generator")
    cig = _PM.get(_PM.var(pm, n), :cig, Dict()); _PM._check_var_keys(cig, bus_gens, "imaginary current", "generator")

    # Boundary
    pbound_load    = get(_PM.var(pm, n),    :pbound_load, Dict()); _PM._check_var_keys(pbound_load, bus_arcs_boundary_from, "active power", "boundary")
    qbound_load    = get(_PM.var(pm, n),    :qbound_load, Dict()); _PM._check_var_keys(qbound_load, bus_arcs_boundary_from, "reactive power", "boundary")

    JuMP.@NLconstraint(pm.model, sum(cr[a] for a in bus_arcs)
                                + sum(crdc[d] for d in bus_arcs_dc)
                                + (sum(pbound_load[a_pbound_load][1] for a_pbound_load in bus_arcs_boundary_from)*vr + sum(qbound_load[a_qbound_load][1] for a_qbound_load in bus_arcs_boundary_from)*vi)/(vr^2 + vi^2)
                                ==
                                sum(crg[g] for g in bus_gens)
                                - (sum(pd for pd in values(bus_pd))*vr + sum(qd for qd in values(bus_qd))*vi)/(vr^2 + vi^2)
                                - sum(gs for gs in values(bus_gs))*vr + sum(bs for bs in values(bus_bs))*vi
                                )
    JuMP.@NLconstraint(pm.model, sum(ci[a] for a in bus_arcs)
                                + sum(cidc[d] for d in bus_arcs_dc)
                                + (sum(pbound_load[a_pbound_load][1] for a_pbound_load in bus_arcs_boundary_from)*vi - sum(qbound_load[a_qbound_load][1] for a_qbound_load in bus_arcs_boundary_from)*vr)/(vr^2 + vi^2)
                                ==
                                sum(cig[g] for g in bus_gens)
                                - (sum(pd for pd in values(bus_pd))*vi - sum(qd for qd in values(bus_qd))*vr)/(vr^2 + vi^2)
                                - sum(gs for gs in values(bus_gs))*vi - sum(bs for bs in values(bus_bs))*vr
                                )
end



"""
    function constraint_boundary_voltage_magnitude(
        pmd::_PMD.IVRUPowerModel,
        i::Int,
        f_idx::Tuple{Int,Int,Int},
        f_connections::Vector{Int},
        t_connections::Vector{Int};
        nw::Int = nw_id_default
    )

IVRU boundary bus voltage magnitude constraints.
"""
function constraint_boundary_voltage_magnitude(pmd::_PMD.IVRUPowerModel, ::Int, t_bus::Int, ::Vector{Int}, ::Vector{Int}; nw::Int=nw_id_default)

    vr_source = _PMD.var(pmd, nw, :vr, t_bus)
    vi_source = _PMD.var(pmd, nw, :vi, t_bus)

    # Add constraint(s): r->real, i->imaginary
    JuMP.@constraint(pmd.model, vr_source[1]^2+vi_source[1]^2 == vr_source[2]^2+vi_source[2]^2)
    JuMP.@constraint(pmd.model, vr_source[1]^2+vi_source[1]^2 == vr_source[3]^2+vi_source[3]^2)

end


"""
    function constraint_boundary_voltage_angle(
        pmd::_PMD.IVRUPowerModel,
        i::Int,
        f_idx::Tuple{Int,Int,Int},
        f_connections::Vector{Int},
        t_connections::Vector{Int};
        nw::Int = nw_id_default
    )

IVRU boundary bus voltage angle constraints.
"""
function constraint_boundary_voltage_angle(pmd::_PMD.IVRUPowerModel, ::Int, t_bus::Int, ::Vector{Int}, ::Vector{Int}; nw::Int=nw_id_default)

    vr_source = _PMD.var(pmd, nw, :vr, t_bus)
    vi_source = _PMD.var(pmd, nw, :vi, t_bus)

    # Add constraints related to 120 degrees offset for the distribution b and c phases
    shift_120degs_rad = deg2rad(120)

    # TODO: These are non-linear constraints due to transformation to degrees of phase a angle (another way - non-linear may be possible)
    JuMP.@NLconstraint(pmd.model, vi_source[2] == tan(atan(vi_source[1]/vr_source[1]) - shift_120degs_rad)*vr_source[2])
    JuMP.@NLconstraint(pmd.model, vi_source[3] == tan(atan(vi_source[1]/vr_source[1]) + shift_120degs_rad)*vr_source[3])

end


"""
    function constraint_transmission_boundary_power_shared_vars_scaled(
        pm::_PM.AbstractIVRModel,
        i::Int;
        nw::Int = nw_id_default
    )

IVRU power shared variables scaling constraints.
"""
function constraint_transmission_boundary_power_shared_vars_scaled(pm::_PM.AbstractIVRModel, i::Int; nw::Int=nw_id_default)

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
        pm::_PM.AbstractIVRModel,
        pmd::_PMD.IVRUPowerModel,
        boundary_number::String;
        nw::Int = nw_id_default,
        export_models::Bool=false
    )

Generates the IVR-IVRU boundary linking vars vector to be used by the IDEC Optimizer.
The parameter `export_models` is a boolean that determines if the JuMP models' shared variable indices are exported to the pwd as `.nl` files.
"""
function generate_boundary_linking_vars(pm::_PM.AbstractIVRModel, pmd::_PMD.IVRUPowerModel, boundary_number::String; nw::Int=nw_id_default, export_models::Bool=false)

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

    # Distribution: vr, vi (subproblem)
    vr = _PMD.var(pmd, nw, :vr, t_bus)
    vi = _PMD.var(pmd, nw, :vi, t_bus)

    # Transmission: Vr, Vi (master)
    Vr = _PM.var(pm, nw, :vr, f_bus)
    Vi = _PM.var(pm, nw, :vi, f_bus)

    # Transmission: Pload & Qload (master)
    P_load = _PM.var(pm, nw, :pbound_load_scaled, f_idx)
    Q_load = _PM.var(pm, nw, :qbound_load_scaled, f_idx)

    boundary_linking_vars = [[P_load[1], Q_load[1], Vr, Vi], [p_aux[1], q_aux[1], vr[1], vi[1]]]

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
