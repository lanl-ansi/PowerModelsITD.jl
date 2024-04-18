# Boundary power variables for decomposition problem formulation

"Boundary power flow variables - DC/NFA cases (P-only)"
function variable_boundary_power(pm::_PM.AbstractActivePowerModel; nw::Int=nw_id_default, report::Bool=true)
    variable_boundary_power_real_load(pm; nw, report)
    variable_boundary_power_real_load_scaled(pm; nw, report)
end


"Boundary power flow variables in Transmission - AC cases (P and Q)"
function variable_boundary_power(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, report::Bool=true)
    variable_boundary_power_real_load(pm; nw, report)
    variable_boundary_power_real_load_scaled(pm; nw, report)
    variable_boundary_power_imaginary_load(pm; nw, report)
    variable_boundary_power_imaginary_load_scaled(pm; nw, report)
end


"Variable: `pbound_load[l,i,j]` for `(l,i,j)` in `arcs bus_arcs_conns_boundary_from`"
function variable_boundary_power_real_load(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, report::Bool=true)

    connections = Dict((l,i,j) => connections for (bus,entry) in _PM.ref(pm, nw, :bus_arcs_conns_boundary_from) for ((l,i,j), connections) in entry)

    # creating the variables
    pbound_load = Dict{Any,Any}((l,i,j) => JuMP.@variable(pm.model,
            [c in connections[(l,i,j)]], base_name="$(nw)_pbound_load_$((l,i,j))",
            start = _PM.comp_start_value(_PM.ref(pm, nw, :boundary, l), "pbound_load_start", c)
        ) for (l,i,j) in _PM.ref(pm, nw, :arcs_boundary_from)
    )

    # this explicit type erasure is necessary
    _PM.var(pm, nw)[:pbound_load] = pbound_load

    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :boundary, :pbound_load, _PM.ref(pm, nw, :arcs_boundary_from), pbound_load)

end


"Variable: `pbound_load_scaled[l,i,j]` for `(l,i,j)` in `arcs bus_arcs_conns_boundary_from`"
function variable_boundary_power_real_load_scaled(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, report::Bool=true)

    connections = Dict((l,i,j) => connections for (bus,entry) in _PM.ref(pm, nw, :bus_arcs_conns_boundary_from) for ((l,i,j), connections) in entry)

    # creating the variables
    pbound_load_scaled = Dict{Any,Any}((l,i,j) => JuMP.@variable(pm.model,
            [c in connections[(l,i,j)]], base_name="$(nw)_pbound_load_scaled_$((l,i,j))",
            start = _PM.comp_start_value(_PM.ref(pm, nw, :boundary, l), "pbound_load_scaled_start", c)
        ) for (l,i,j) in _PM.ref(pm, nw, :arcs_boundary_from)
    )

    # this explicit type erasure is necessary
    _PM.var(pm, nw)[:pbound_load_scaled] = pbound_load_scaled

    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :boundary, :pbound_load_scaled, _PM.ref(pm, nw, :arcs_boundary_from), pbound_load_scaled)

end


"Variable: `qbound_load[l,i,j]` for `(l,i,j)` in `arcs bus_arcs_conns_boundary_from`"
function variable_boundary_power_imaginary_load(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, report::Bool=true)

    connections = Dict((l,i,j) => connections for (bus,entry) in _PM.ref(pm, nw, :bus_arcs_conns_boundary_from) for ((l,i,j), connections) in entry)

    # creating the variables
    qbound_load = Dict{Any,Any}((l,i,j) => JuMP.@variable(pm.model,
            [c in connections[(l,i,j)]], base_name="$(nw)_qbound_load_$((l,i,j))",
            start = _PM.comp_start_value(_PM.ref(pm, nw, :boundary, l), "qbound_load_start", c)
        ) for (l,i,j) in _PM.ref(pm, nw, :arcs_boundary_from)
    )

    # this explicit type erasure is necessary
    _PM.var(pm, nw)[:qbound_load] = qbound_load

    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :boundary, :qbound_load, _PM.ref(pm, nw, :arcs_boundary_from), qbound_load)

end


"Variable: `qbound_load_scaled[l,i,j]` for `(l,i,j)` in `arcs bus_arcs_conns_boundary_from`"
function variable_boundary_power_imaginary_load_scaled(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, report::Bool=true)

    connections = Dict((l,i,j) => connections for (bus,entry) in _PM.ref(pm, nw, :bus_arcs_conns_boundary_from) for ((l,i,j), connections) in entry)

    # creating the variables
    qbound_load_scaled = Dict{Any,Any}((l,i,j) => JuMP.@variable(pm.model,
            [c in connections[(l,i,j)]], base_name="$(nw)_qbound_load_scaled_$((l,i,j))",
            start = _PM.comp_start_value(_PM.ref(pm, nw, :boundary, l), "qbound_load_scaled_start", c)
        ) for (l,i,j) in _PM.ref(pm, nw, :arcs_boundary_from)
    )

    # this explicit type erasure is necessary
    _PM.var(pm, nw)[:qbound_load_scaled] = qbound_load_scaled

    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :boundary, :qbound_load_scaled, _PM.ref(pm, nw, :arcs_boundary_from), qbound_load_scaled)

end


"Boundary power flow variables in Distribution - Linear Active cases (P-only)"
function variable_boundary_power(pmd::_PMD.AbstractUnbalancedActivePowerModel; nw::Int=nw_id_default, report::Bool=true)
    variable_boundary_power_real_aux(pmd; nw, report)
end


"Boundary power flow variables in Distribution - AC cases (P and Q)"
function variable_boundary_power(pmd::_PMD.AbstractUnbalancedPowerModel; nw::Int=nw_id_default, report::Bool=true)
    variable_boundary_power_real_aux(pmd; nw, report)
    variable_boundary_power_imaginary_aux(pmd; nw, report)
end


"Variable: `pbound_aux[l,i,j]` for `(l,i,j)` in `arcs bus_arcs_conns_boundary_from`"
function variable_boundary_power_real_aux(pmd::_PMD.AbstractUnbalancedPowerModel; nw::Int=nw_id_default, report::Bool=true)

    connections = Dict((l,i,j) => connections for (bus,entry) in _PMD.ref(pmd, nw, :bus_arcs_conns_boundary_from) for ((l,i,j), connections) in entry)

    # creating the variables
    pbound_aux = Dict{Any,Any}((l,i,j) => JuMP.@variable(pmd.model,
            [c in connections[(l,i,j)]], base_name="$(nw)_pbound_aux_$((l,i,j))",
            start = _PMD.comp_start_value(_PMD.ref(pmd, nw, :boundary, l), "pbound_aux_start", c, 0.0)
        ) for (l,i,j) in _PMD.ref(pmd, nw, :arcs_boundary_from)
    )

    # this explicit type erasure is necessary
    _PMD.var(pmd, nw)[:pbound_aux] = pbound_aux

    report && _IM.sol_component_value(pmd, _PMD.pmd_it_sym, nw, :boundary, :pbound_aux, _PMD.ref(pmd, nw, :arcs_boundary_from), pbound_aux)

end


"Variable: `qbound_aux[l,i,j]` for `(l,i,j)` in `bus_arcs_conns_boundary_from`"
function variable_boundary_power_imaginary_aux(pmd::_PMD.AbstractUnbalancedPowerModel; nw::Int=nw_id_default, report::Bool=true)

    connections = Dict((l,i,j) => connections for (bus,entry) in _PMD.ref(pmd, nw, :bus_arcs_conns_boundary_from) for ((l,i,j), connections) in entry)

    # creating the variables
    qbound_aux = Dict{Any,Any}((l,i,j) => JuMP.@variable(pmd.model,
            [c in connections[(l,i,j)]], base_name="$(nw)_qbound_aux_$((l,i,j))",
            start = _PMD.comp_start_value(_PMD.ref(pmd, nw, :boundary, l), "qbound_aux_start", c, 0.0)
        ) for (l,i,j) in _PMD.ref(pmd, nw, :arcs_boundary_from)
    )

    # this explicit type erasure is necessary
    _PMD.var(pmd, nw)[:qbound_aux] = qbound_aux

    report && _IM.sol_component_value(pmd, _PMD.pmd_it_sym, nw, :boundary, :qbound_aux, _PMD.ref(pmd, nw, :arcs_boundary_from), qbound_aux)

end

## TODO: ACR (i.e., all rectangular models)
# function variable_boundary_power_real_aux(pmd::_PMD.AbstractUnbalancedACRModel; nw::Int=nw_id_default, report::Bool=true)
    ## The ACR model needs a P_real_aux, P_imag_aux, Q_real_aux, Q_imag_aux
# end
