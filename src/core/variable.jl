# Boundary power and current variables

"Boundary power flow variables - DC cases (P-only)"
function variable_boundary_power(pm::AbstractLPowerModelITD; nw::Int=nw_id_default, report::Bool=true)
    variable_boundary_power_real_from(pm; nw, report)
    variable_boundary_power_real_to(pm; nw, report)
end


"Boundary power flow variables - AC cases (P and Q)"
function variable_boundary_power(pm::AbstractPowerModelITD; nw::Int=nw_id_default, report::Bool=true)
    variable_boundary_power_real_from(pm; nw, report)
    variable_boundary_power_imaginary_from(pm; nw, report)
    variable_boundary_power_real_to(pm; nw, report)
    variable_boundary_power_imaginary_to(pm; nw, report)
end


"Boundary current flow variables - IVR cases (Current Real and Current Imaginary)"
function variable_boundary_current(pm::AbstractIVRPowerModelITD; nw::Int=nw_id_default, report::Bool=true)
    variable_boundary_current_real_from(pm; nw, report)
    variable_boundary_current_imaginary_from(pm; nw, report)
    variable_boundary_current_real_to(pm; nw, report)
    variable_boundary_current_imaginary_to(pm; nw, report)
end


"Variable: `pbound_fr[l,i,j]` for `(l,i,j)` in `arcs bus_arcs_conns_boundary_from`"
function variable_boundary_power_real_from(pm::AbstractPowerModelITD; nw::Int=nw_id_default, report::Bool=true)

    connections = Dict((l,i,j) => connections for (bus,entry) in ref(pm, nw, :bus_arcs_conns_boundary_from) for ((l,i,j), connections) in entry)

    # creating the variables
    pbound_from = Dict{Any,Any}((l,i,j) => JuMP.@variable(pm.model,
            [c in connections[(l,i,j)]], base_name="$(nw)_pbound_fr_$((l,i,j))",
            start = _PMD.comp_start_value(ref(pm, nw, :boundary, l), "pbound_fr_start", c, 0.0)
        ) for (l,i,j) in ref(pm, nw, :arcs_boundary_from)
    )

    # this explicit type erasure is necessary
    var(pm, nw)[:pbound_fr] = pbound_from

    report && _IM.sol_component_value(pm, pmitd_it_sym, nw, :boundary, :pbound_fr, ref(pm, nw, :arcs_boundary_from), pbound_from)

end


"Variable: `pbound_to[l,i,j]` for `(l,i,j)` in `bus_arcs_conns_boundary_to`"
function variable_boundary_power_real_to(pm::AbstractPowerModelITD; nw::Int=nw_id_default, report::Bool=true)

    connections = Dict((l,i,j) => connections for (bus,entry) in ref(pm, nw, :bus_arcs_conns_boundary_to) for ((l,i,j), connections) in entry)

    # creating the variables
    pbound_to = Dict{Any,Any}((l,j,i) => JuMP.@variable(pm.model,
            [c in connections[(l,j,i)]], base_name="$(nw)_pbound_to_$((l,j,i))",
            start = _PMD.comp_start_value(ref(pm, nw, :boundary, l), "pbound_to_start", c, 0.0)
        ) for (l,j,i) in ref(pm, nw, :arcs_boundary_to)
    )

    # this explicit type erasure is necessary
    var(pm, nw)[:pbound_to] = pbound_to

    report && _IM.sol_component_value(pm, pmitd_it_sym, nw, :boundary, :pbound_to, ref(pm, nw, :arcs_boundary_to), pbound_to)

end


"Variable: `qbound_fr[l,i,j]` for `(l,i,j)` in `bus_arcs_conns_boundary_from`"
function variable_boundary_power_imaginary_from(pm::AbstractPowerModelITD; nw::Int=nw_id_default, report::Bool=true)

    connections = Dict((l,i,j) => connections for (bus,entry) in ref(pm, nw, :bus_arcs_conns_boundary_from) for ((l,i,j), connections) in entry)

    # creating the variables
    qbound_from = Dict{Any,Any}((l,i,j) => JuMP.@variable(pm.model,
            [c in connections[(l,i,j)]], base_name="$(nw)_qbound_fr_$((l,i,j))",
            start = _PMD.comp_start_value(ref(pm, nw, :boundary, l), "qbound_fr_start", c, 0.0)
        ) for (l,i,j) in ref(pm, nw, :arcs_boundary_from)
    )

    # this explicit type erasure is necessary
    var(pm, nw)[:qbound_fr] = qbound_from

    report && _IM.sol_component_value(pm, pmitd_it_sym, nw, :boundary, :qbound_fr, ref(pm, nw, :arcs_boundary_from), qbound_from)

end


"Variable: `qbound_to[l,i,j]` for `(l,i,j)` in `bus_arcs_conns_boundary_to`"
function variable_boundary_power_imaginary_to(pm::AbstractPowerModelITD; nw::Int=nw_id_default, report::Bool=true)

    connections = Dict((l,i,j) => connections for (bus,entry) in ref(pm, nw, :bus_arcs_conns_boundary_to) for ((l,i,j), connections) in entry)

    # creating the variables
    qbound_to = Dict{Any,Any}((l,j,i) => JuMP.@variable(pm.model,
            [c in connections[(l,j,i)]], base_name="$(nw)_qbound_to_$((l,j,i))",
            start = _PMD.comp_start_value(ref(pm, nw, :boundary, l), "qbound_to_start", c, 0.0)
        ) for (l,j,i) in ref(pm, nw, :arcs_boundary_to)
    )

    # this explicit type erasure is necessary
    var(pm, nw)[:qbound_to] = qbound_to

    report && _IM.sol_component_value(pm, pmitd_it_sym, nw, :boundary, :qbound_to, ref(pm, nw, :arcs_boundary_to), qbound_to)

end


"Variable: `crbound_fr[l,i,j]` for `(l,i,j)` in `arcs bus_arcs_conns_boundary_from`"
function variable_boundary_current_real_from(pm::AbstractIVRPowerModelITD; nw::Int=nw_id_default, report::Bool=true)

    connections = Dict((l,i,j) => connections for (bus,entry) in ref(pm, nw, :bus_arcs_conns_boundary_from) for ((l,i,j), connections) in entry)

    # creating the variables
    crbound_from = Dict{Any,Any}((l,i,j) => JuMP.@variable(pm.model,
            [c in connections[(l,i,j)]], base_name="$(nw)_crbound_fr_$((l,i,j))",
            start = _PMD.comp_start_value(ref(pm, nw, :boundary, l), "crbound_fr_start", c, 0.0)
        ) for (l,i,j) in ref(pm, nw, :arcs_boundary_from)
    )

    # this explicit type erasure is necessary
    var(pm, nw)[:crbound_fr] = crbound_from

    report && _IM.sol_component_value(pm, pmitd_it_sym, nw, :boundary, :crbound_fr, ref(pm, nw, :arcs_boundary_from), crbound_from)

end


"Variable: `crbound_to[l,i,j]` for `(l,i,j)` in `bus_arcs_conns_boundary_to`"
function variable_boundary_current_real_to(pm::AbstractIVRPowerModelITD; nw::Int=nw_id_default, report::Bool=true)

    connections = Dict((l,i,j) => connections for (bus,entry) in ref(pm, nw, :bus_arcs_conns_boundary_to) for ((l,i,j), connections) in entry)

    # creating the variables
    crbound_to = Dict{Any,Any}((l,j,i) => JuMP.@variable(pm.model,
            [c in connections[(l,j,i)]], base_name="$(nw)_crbound_to_$((l,j,i))",
            start = _PMD.comp_start_value(ref(pm, nw, :boundary, l), "crbound_to_start", c, 0.0)
        ) for (l,j,i) in ref(pm, nw, :arcs_boundary_to)
    )

    # this explicit type erasure is necessary
    var(pm, nw)[:crbound_to] = crbound_to

    report && _IM.sol_component_value(pm, pmitd_it_sym, nw, :boundary, :crbound_to, ref(pm, nw, :arcs_boundary_to), crbound_to)

end


"Variable: `cibound_fr[l,i,j]` for `(l,i,j)` in `bus_arcs_conns_boundary_from`"
function variable_boundary_current_imaginary_from(pm::AbstractIVRPowerModelITD; nw::Int=nw_id_default, report::Bool=true)

    connections = Dict((l,i,j) => connections for (bus,entry) in ref(pm, nw, :bus_arcs_conns_boundary_from) for ((l,i,j), connections) in entry)

    # creating the variables
    cibound_from = Dict{Any,Any}((l,i,j) => JuMP.@variable(pm.model,
            [c in connections[(l,i,j)]], base_name="$(nw)_cibound_fr_$((l,i,j))",
            start = _PMD.comp_start_value(ref(pm, nw, :boundary, l), "cibound_fr_start", c, 0.0)
        ) for (l,i,j) in ref(pm, nw, :arcs_boundary_from)
    )

    # this explicit type erasure is necessary
    var(pm, nw)[:cibound_fr] = cibound_from

    report && _IM.sol_component_value(pm, pmitd_it_sym, nw, :boundary, :cibound_fr, ref(pm, nw, :arcs_boundary_from), cibound_from)

end


"Variable: `cibound_to[l,i,j]` for `(l,i,j)` in `bus_arcs_conns_boundary_to`"
function variable_boundary_current_imaginary_to(pm::AbstractIVRPowerModelITD; nw::Int=nw_id_default, report::Bool=true)

    connections = Dict((l,i,j) => connections for (bus,entry) in ref(pm, nw, :bus_arcs_conns_boundary_to) for ((l,i,j), connections) in entry)

    # creating the variables
    cibound_to = Dict{Any,Any}((l,j,i) => JuMP.@variable(pm.model,
            [c in connections[(l,j,i)]], base_name="$(nw)_cibound_to_$((l,j,i))",
            start = _PMD.comp_start_value(ref(pm, nw, :boundary, l), "cibound_to_start", c, 0.0)
        ) for (l,j,i) in ref(pm, nw, :arcs_boundary_to)
    )

    # this explicit type erasure is necessary
    var(pm, nw)[:cibound_to] = cibound_to

    report && _IM.sol_component_value(pm, pmitd_it_sym, nw, :boundary, :cibound_to, ref(pm, nw, :arcs_boundary_to), cibound_to)
end
