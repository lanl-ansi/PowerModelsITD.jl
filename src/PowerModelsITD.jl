module PowerModelsITD

    import InfrastructureModels as _IM
    import PowerModels as _PM
    import PowerModelsDistribution as _PMD

    import StsDOpt as _SDO
    import Distributed

    import JuMP
    import JSON

    # Borrow dependencies from other packages
    import InfrastructureModels: optimize_model!, @im_fields, nw_id_default

    # Import necessary (additional) packages/functions
    import LinearAlgebra

    "Suppresses information and warning messages output by PowerModels and PowerModelsDistribution"
    function silence!()
        @warn "Suppressing information and warning messages output by PowerModels and PowerModelsDistribution for the rest of this session."
        _PM.silence()
        _PMD.silence!()
    end

    # Name and symbol
    const pmitd_it_name = "pmitd"
    const pmitd_it_sym = Symbol(pmitd_it_name)

    const _pmitd_global_keys = union(_PM._pm_global_keys, _PMD._pmd_global_keys)

    # const starting number for boundary branches (to avoid confusion with normal branches - TODO: this may change in the future!)
    "BOUNDARY_NUMBER constant that determines the starting counter for the boundaries defined."
    const BOUNDARY_NUMBER = 100001

    ### compat for PM v0.20
    # enables support for v[1]
    Base.getindex(v::JuMP.VariableRef, i::Int) = v

    # Files to include in module
    include("io/common.jl")
    include("core/base.jl")
    include("core/data.jl")
    include("core/types.jl")
    include("core/ref.jl")
    include("core/ref_decomposition.jl")
    include("core/helpers.jl")
    include("core/variable.jl")
    include("core/objective_helpers.jl")
    include("core/variable_decomposition.jl")
    include("core/objective.jl")
    include("core/objective_dmld.jl")
    include("core/objective_dmld_simple.jl")
    include("core/objective_storage.jl")
    include("core/solution.jl")
    include("core/constraint_storage_linear.jl")
    include("core/solution_decomposition.jl")

    include("data_model/transformations.jl")

    include("form/boundary.jl")
    include("form/acr.jl")
    include("form/acp.jl")
    include("form/linear.jl")
    include("form/ivr.jl")
    include("form/wmodels.jl")
    include("form/fbs.jl")
    include("form/fotr.jl")
    include("form/fotp.jl")
    include("form/lindist3flow.jl")

    include("form_decomposition/boundary.jl")
    include("form_decomposition/acr.jl")
    include("form_decomposition/acp.jl")
    include("form_decomposition/ivr.jl")
    include("form_decomposition/linear.jl")
    include("form_decomposition/wmodels.jl")
    include("form_decomposition/fbs.jl")
    include("form_decomposition/fotr.jl")
    include("form_decomposition/fotp.jl")
    include("form_decomposition/lindist3flow.jl")

    include("prob/pfitd.jl")
    include("prob/opfitd.jl")
    include("prob/opfitd_oltc.jl")
    include("prob/opfitd_dmld.jl")
    include("prob/opfitd_storage.jl")
    include("prob/opfitd_storage_linear.jl")
    include("prob/opfitd_decomposition.jl")

    # This must come last to support automated export.
    include("core/export.jl")
end
