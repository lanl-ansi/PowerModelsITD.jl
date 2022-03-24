# This file contains useful transformation functions for the engineering data model for the combined pmd(s) files

"""
    function apply_voltage_bounds!(
        pmitd_data::Dict{String,<:Any};
        vm_lb::Union{Real,Missing}=0.9,
        vm_ub::Union{Real,Missing}=1.1
    )

Applies the corresponding transformation of voltage bounds to all buses based on per-unit upper (`vm_ub`) and lower (`vm_lb`) bounds,
scaled by the bus' voltage, to the `pmd` dictionary.
"""
function apply_voltage_bounds!(pmitd_data::Dict{String,<:Any}; vm_lb::Union{Real,Missing}=0.9, vm_ub::Union{Real,Missing}=1.1)
    # Call PMD function
    _PMD.apply_voltage_bounds!(pmitd_data["it"]["pmd"]; vm_lb, vm_ub)
end


"""
    function apply_voltage_angle_difference_bounds!(
        pmitd_data::Dict{String,<:Any},
        vad::Real=5.0
    )

Applies the corresponding transformation of voltage angle difference bound given by `vad::Real`
in degrees (_i.e._, the allowed drift of angle from one end of a line to another) to all lines,
to the `pmd` dictionary.
"""
function apply_voltage_angle_difference_bounds!(pmitd_data::Dict{String,<:Any}, vad::Real=5.0)
    # Call PMD function
    _PMD.apply_voltage_angle_difference_bounds!(pmitd_data["it"]["pmd"], vad)
end


"""
    function make_lossless!(
        pmitd_data::Dict{String,<:Any}
    )

Applies the corresponding transformation that removes parameters from objects with loss models to make them lossless.
This includes switches voltage sources and transformers, which all have loss model parameters that can be omitted.
"""
function make_lossless!(pmitd_data::Dict{String,<:Any})
    # Call PMD function
    _PMD.make_lossless!(pmitd_data["it"]["pmd"])
end


"""
    function remove_all_bounds!(
        pmitd_data::Dict{String,<:Any};
        exclude::Vector{<:String}=String["energy_ub"]
    )

Applies the corresponding transformation that removes all fields ending in '_ub' or '_lb' that aren't required by the math model.
Properties can be excluded from this removal with `exclude::Vector{String}`.
By default, `"energy_ub"` is excluded from this removal, since it is a required property on storage (in pmd).
"""
function remove_all_bounds!(pmitd_data::Dict{String,<:Any}, exclude::Vector{<:String}=String["energy_ub"])
    # Call PMD function
    _PMD.remove_all_bounds!(pmitd_data["it"]["pmd"])
end


"""
    function apply_kron_reduction!(
        pmitd_data::Dict{String,<:Any}
    )

Applies the corresponding transformation that applies a Kron Reduction to the network, reducing out the `kr_neutral`,
leaving only the `kr_phases`.
"""
function apply_kron_reduction!(pmitd_data::Dict{String,<:Any})
    # Call PMD function
    _PMD.apply_kron_reduction!(pmitd_data["it"]["pmd"])
end


"""
    function apply_phase_projection!(
        pmitd_data::Dict{String,<:Any}
    )

Applies the corresponding transformation to apply phase projection: pad matrices and vectors to max number of conductors
"""
function apply_phase_projection!(pmitd_data::Dict{String,<:Any})
    # Call PMD function
    _PMD.apply_phase_projection!(pmitd_data["it"]["pmd"])
end


"""
    function apply_phase_projection_delta!(
        pmitd_data::Dict{String,<:Any}
    )

Applies the corresponding transformation to apply phase projection delta for components where unprojected states are not yet supported
(delta configurations). See [`apply_phase_projection!`]
"""
function apply_phase_projection_delta!(pmitd_data::Dict{String,<:Any})
    # Call PMD function
    _PMD.apply_phase_projection_delta!(pmitd_data["it"]["pmd"])
end
