using PowerModelsITD
using Test

##  Initialize shortened package names for convenience.
const _IM = PowerModelsITD._IM
const _PM = PowerModelsITD._PM
const _PMD = PowerModelsITD._PMD


# Setup optimizers
import Ipopt
import SCS

# Paths to test files
trans_path = joinpath(dirname(pathof(PowerModelsITD)), "../test/data/transmission/")
dist_path = joinpath(dirname(pathof(PowerModelsITD)), "../test/data/distribution/")
bound_path = joinpath(dirname(pathof(PowerModelsITD)), "../test/data/json/")

ipopt = optimizer_with_attributes(Ipopt.Optimizer, "acceptable_tol"=>1.0e-8, "print_level"=>0, "sb"=>"yes")
scs_solver = optimizer_with_attributes(SCS.Optimizer, "verbose"=>0)

# Silence warnings from PM and PMD in test cases
PowerModelsITD.silence!()

@testset "PowerModelsITD.jl" begin
    include("io.jl")
    include("base.jl")
    include("data.jl")
    include("autorename.jl")
    include("opfitd.jl")
    include("opfitd_duals.jl")
    include("pfitd.jl")
    include("opfitd_ms.jl")
    include("pfitd_ms.jl")
    include("transformations_opfitd.jl")
    include("largescale_opfitd.jl")
    include("opfitd_hybrids.jl")
    include("pfitd_hybrids.jl")
    include("opfitd_oltc.jl")
    include("opfitd_mn.jl")
    include("opfitd_oltc_mn.jl")
    include("opfitd_dmld.jl")
    include("opfitd_solution.jl")
    include("opfitd_pass.jl")
end
