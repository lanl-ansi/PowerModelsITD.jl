"General PowerModelITD"
mutable struct PowerModelITD{T1, T2} <: AbstractPowerModelITD{T1, T2} @pmitd_fields end

# "Unions/groups of formulations available in PM and PMD"
NonlinearPowerModels = Union{_PM.ACPPowerModel, _PM.ACRPowerModel}
NonlinearPowerModelsDistribution = Union{_PMD.ACPUPowerModel, _PMD.ACRUPowerModel}
LinearPowerModels = Union{_PM.DCPPowerModel, _PM.NFAPowerModel}
LinearPowerModelsDistribution = Union{_PMD.DCPUPowerModel, _PMD.NFAUPowerModel}
FOTPowerModelsDistribution = Union{_PMD.FOTRUPowerModel, _PMD.FOTPUPowerModel}
IVRPowerModels = Union{_PM.IVRPowerModel}
IVRPowerModelsDistribution = Union{_PMD.IVRUPowerModel}
BFPowerModels = Union{_PM.SOCBFPowerModel, _PM.BFAPowerModel, _PM.SOCBFConicPowerModel}
BFPowerModelsDistribution = Union{ _PMD.SOCNLPUBFPowerModel, _PMD.FBSUBFPowerModel, _PMD.LPUBFDiagModel, _PMD.SOCConicUBFPowerModel}
WRPowerModels = Union{_PM.SOCWRConicPowerModel, _PM.SDPWRMPowerModel}


"Abstract Non-Linear ITD formulation"
mutable struct AbstractNLPowerModelITD{T1, T2} <: AbstractPowerModelITD{T1, T2} @pmitd_fields end

"Non-Linear to Non-Linear ITD formulation"
const NLPowerModelITD = AbstractNLPowerModelITD{<:NonlinearPowerModels, <:NonlinearPowerModelsDistribution}

"Abstract Linear ITD formulation"
mutable struct AbstractLPowerModelITD{T1, T2} <: AbstractPowerModelITD{T1, T2} @pmitd_fields end

"Linear to Linear ITD formulation"
const LPowerModelITD = AbstractLPowerModelITD{<:LinearPowerModels, <:LinearPowerModelsDistribution}

"Abstract Current-Voltage (IVR) ITD formulation"
mutable struct AbstractIVRPowerModelITD{T1, T2} <: AbstractPowerModelITD{T1, T2} @pmitd_fields end

"IVR to IVR ITD formulation"
const IVRPowerModelITD = AbstractIVRPowerModelITD{<:IVRPowerModels, <:IVRPowerModelsDistribution}

"Abstract Branch-flow ITD formulation"
mutable struct AbstractBFPowerModelITD{T1, T2} <: AbstractPowerModelITD{T1, T2} @pmitd_fields end

"Branch-flow to Branch-flow ITD formulation"
const BFPowerModelITD = AbstractBFPowerModelITD{<:BFPowerModels, <:BFPowerModelsDistribution}


# --- Hybrid formulations ---

# NL-FOT formulations
"Non-Linear to First-Order Taylor (FOT) ITD formulation"
const NLFOTPowerModelITD = AbstractNLPowerModelITD{<:NonlinearPowerModels, <:FOTPowerModelsDistribution}

# L/NL-BF (BF-L/NL) formulations
"Abstract Linear/Non-Linear to Branch-flow ITD formulation"
mutable struct AbstractLNLBFPowerModelITD{T1, T2} <: AbstractPowerModelITD{T1, T2} @pmitd_fields end

"Non-Linear to Branch-flow ITD formulation"
const NLBFPowerModelITD = AbstractLNLBFPowerModelITD{<:NonlinearPowerModels, <:BFPowerModelsDistribution}

"Linear to Branch-flow ITD formulation"
const LBFPowerModelITD = AbstractLNLBFPowerModelITD{<:LinearPowerModels, <:BFPowerModelsDistribution}

"WR to Branch-flow ITD formulation"
const WRBFPowerModelITD = AbstractLNLBFPowerModelITD{<:WRPowerModels, <:BFPowerModelsDistribution}
