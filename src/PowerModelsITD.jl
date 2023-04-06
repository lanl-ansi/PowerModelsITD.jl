module PowerModelsITD

    import InfrastructureModels as _IM
    import PowerModels as _PM
    import PowerModelsDistribution as _PMD

    import IpoptDecomposition as _IDEC

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

    # const vectors with strings build function names availables.
    "STANDARD_PROBLEMS constant vector that contains the different types of ITD problems supported."
    const STANDARD_PROBLEMS = ["build_opfitd", "build_mn_opfitd", "build_pfitd", "build_mn_opfitd_oltc", "build_opfitd_oltc", "build_dmld_opfitd", "build_mn_dmld_opfitd_simple"]

    "DECOMPOSITION_PROBLEMS constant vector that contains the different types of ITD decomposition problems supported."
    const DECOMPOSITION_PROBLEMS = ["build_opfitd_decomposition", "build_mn_opfitd_decomposition"]

    # Files to include in module
    include("io/common.jl")
    include("core/base.jl")
    include("core/data.jl")
    include("core/types.jl")
    include("core/ref.jl")
    include("core/ref_decomposition.jl")
    include("core/helpers.jl")
    include("core/variable.jl")
<<<<<<< HEAD
    include("core/objective_helpers.jl")
=======
    include("core/variable_decomposition.jl")
>>>>>>> ADD: new ref_add_core_decomposition funcs for both Transmission and Distribution systems.
    include("core/objective.jl")
    include("core/objective_dmld.jl")
    include("core/objective_dmld_simple.jl")
    include("core/objective_storage.jl")
    include("core/solution.jl")
    include("core/constraint_storage_linear.jl")

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
    include("form_decomposition/acp.jl")
    include("form_decomposition/linear.jl")
    include("form_decomposition/lindist3flow.jl")
    include("form_decomposition/wmodels.jl")

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
