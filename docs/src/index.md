===

```@meta
CurrentModule = PowerModelsITD
```

## What is PowerModelsITD?

[PowerModelsITD.jl](https://github.com/lanl-ansi/PowerModelsITD.jl) is a Julia/JuMP-based package for modeling integrated transmission-distribution power networks.

## Resources for Getting Started

Read the [Installation Guide](@ref Installation-Guide).

Read the [Quickstart Guide](@ref Quick-Start-Guide).

Read the introductory tutorial [Introduction to PowerModelsITD](@ref Introduction-to-PowerModelsITD).

## How the documentation is structured

The following is a high-level overview of how our documentation is structured. There are three primary sections:

- The **Manual** contains detailed documentation for certain aspects of PowerModelsITD, such as the [Data Models](@ref DataModelAPI), the [Network Formulations](@ref FormulationAPI), or the [Optimization Problem Specifications](@ref ProblemAPI).

- **Tutorials** contains working examples of how to use PowerModelsITD. Start here if you are new to PowerModelsITD.

- The **API Reference** contains a complete list of the functions you can use in PowerModelsITD. Look here if you want to know how to use a particular function.

## Citing PowerModelsITD

If you find PowerModelsITD useful for your work, we kindly request that you cite the following [publication]:

```bibtex
@article{powermodelsitdresearchpaper,
title = "Modeling and Rapid Prototyping of Integrated Transmission-Distribution OPF Formulations with PowerModelsITD.jl",
journal = "In Submission Process",
volume = "",
pages = "",
year = "2022",
issn = "",
doi = "",
url = "https://lanl-ansi.github.io/PowerModelsITD.jl/stable/index.html",
author = "Juan Ospina and David M. Fobes and Russell Bent and Andreas W\"achter",
keywords = "Nonlinear optimization, Convex optimization, AC optimal power flow, Julia language, Open-source",
abstract = "Conventional electric power systems are composed of different unidirectional power flow stages of generation transmission, and distribution, managed independently by transmission system and distribution system operators. However, as distribution systems increase in complexity due to the integration of distributed energy resources, coordination between transmission and distribution networks will be imperative for the optimal operation of the power grid. However, coupling models and formulations between transmission and distribution is non-trivial, in particular due to common practice of modeling transmission systems as single-phase, and distribution systems as multi-conductor phase-unbalanced. To enable the rapid prototyping of power flow formulations, in particular in the modeling of the boundary conditions between these two seemingly incompatible data models, we introduce PowerModelsITD.jl, a free, open-source toolkit written in Julia for integrated transmission-distribution (ITD) optimization that leverages mature optimization libraries from the InfrastructureModels.jl-ecosystem. The primary objective of the proposed framework is to provide baseline implementations of steady-state ITD optimization problems, while providing a common platform for the evaluation of emerging formulations and optimization problems. In this work, we introduce the nonlinear formulations currently supported in PowerModelsITD.jl, which include AC-polar, AC-rectangular, current-voltage, and a linear network transportation model. Results are validated using combinations of IEEE transmission and distribution networks."
}
```

## Acknowledgments

This code has been developed with the support of the Grant: "Optimized Resilience for Distribution and Transmission Systems" funded by the U.S. Department of Energy (DOE) Office of Electricity (OE) Advanced Grid Modeling (AGM) Research Program under program manager Ali Ghassemian. The research work conducted at Los Alamos National Laboratory is done under the auspices of the National Nuclear Security Administration of the U.S. Department of Energy under Contract No. 89233218CNA000001. The primary developers are Juan Ospina (@juanjospina) and David Fobes (@pseudocubic).

## License

This code is provided under a BSD license as part of the Multi-Infrastructure Control and Optimization Toolkit (MICOT) project, LA-CC-13-108.
