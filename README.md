# PowerModelsITD.jl

[![CI](https://github.com/lanl-ansi/PowerModelsITD.jl/workflows/CI/badge.svg)](https://github.com/lanl-ansi/PowerModelsITD.jl/actions?query=workflow%3ACI) [![Documentation](https://github.com/lanl-ansi/PowerModelsITD.jl/workflows/Documentation/badge.svg)](https://lanl-ansi.github.io/PowerModelsITD.jl/stable/)

PowerModelsITD.jl is an extention package of PowerModels.jl and PowerModelsDistribution.jl for Steady-State Integrated Power Transmission-Distribution Network Optimization. It is designed to enable computational evaluation of emerging power network formulations and algorithms in a common platform. The code is engineered to decouple problem specifications (e.g. Power Flow, Optimal Power Flow, ...) from the power network formulations (e.g. AC, linear-approximation, SOC-relaxation, ...) on both transmission and distribution system. Thus, enabling the definition of a wide variety of power network formulations and their comparison on common problem specifications.

## Core Problem Specifications

- Integrated T&D Power Flow (pfitd)
- Integrated T&D Optimal Power Flow (opfitd)
- Integrated T&D Optimal Power Flow with on-load tap-changer (opfitd_oltc)
- Integrated T&D Optimal power flow at transmission and minimum load delta at distribution system (opfitd_dmld)

## Core Network Formulations

- Nonlinear
  - ACP-ACP
  - ACR-ACR
  - IVR-IVR
- Relaxations
  - SOCBFM-SOCBFM (W-space)
- Linear Approximations
  - NFA-NFA
  - DCP-DCP
- Hybrid
  - ACR-FOTR (First-Order Taylor Rectangular)
  - ACP-FOTP (First-Order Taylor Polar)
  - ACR-FBS (Forward-Backward Sweep)
  - SOCBFM-LinDist3Flow
  - BFA-LinDist3Flow

## Network Data Formats

- **Transmission**: Matpower ".m" and PTI ".raw" files (PSS(R)E v33 specification)
- **Distribution**: OpenDSS ".dss" files
- **Boundary**: JSON ".json" files

## Documentation

Please see our documentation (i.e., `./docs`) for information about how to install and use PowerModelsITD.

## Examples

Examples of how to use PowerModelsITD can be found in the main documentation and in Pluto Notebooks inside the `/examples` directory.

## Development

Community-driven development and enhancement of PowerModelsITD is welcomed and encouraged.
Please feel free to fork this repository and share your contributions to the main branch with a pull request.
When submitting a PR, please keep in mind the code quality requirements and scope of PowerModelsITD before preparing a contribution.
See [CONTRIBUTING.md] for code contribution guidelines.

## Acknowledgments

This code has been developed with the support of the Grant: "Optimized Resilience for Distribution and Transmission Systems" funded by the U.S. Department of Energy (DOE) Office of Electricity (OE) Advanced Grid Modeling (AGM) Research Program under program manager Ali Ghassemian. The research work conducted at Los Alamos National Laboratory is done under the auspices of the National Nuclear Security Administration of the U.S. Department of Energy under Contract No. 89233218CNA000001. The primary developers are Juan Ospina (@juanjospina) and David Fobes (@pseudocubic).

## License

This code is provided under a BSD license as part of the Multi-Infrastructure Control and Optimization Toolkit (MICOT) project, LA-CC-13-108.
