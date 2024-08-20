![PowerModelsITD Logo](assets/logo.svg)
===

```@meta
CurrentModule = PowerModelsITD
```

## What is PowerModelsITD.jl?

[PowerModelsITD.jl](https://github.com/lanl-ansi/PowerModelsITD.jl) is a Julia/JuMP-based package for modeling and optimizing integrated transmission-distribution (ITD) power networks.

## Resources for Getting Started

Read the [Installation Guide](@ref Installation-Guide).

Read the [Quickstart Guide](@ref Quick-Start-Guide).

Read the [File Formats Guide](@ref File-Formats-Guide).

Read the introductory tutorial [Introduction to PowerModelsITD.jl](@ref Introduction-to-PowerModelsITD).

## How the documentation is structured

The following is a high-level overview of how our documentation is structured. There are three primary sections:

- The **Manual** contains detailed documentation for certain aspects of PowerModelsITD.jl, such as the [Data Models](@ref DataModelAPI), the [Network Formulations](@ref FormulationAPI), or the [Optimization Problem Specifications](@ref ProblemAPI).

- **Tutorials** contains working examples of how to use PowerModelsITD.jl. Start here if you are new to PowerModelsITD.jl.

- The **API Reference** contains a complete list of the functions you can use in PowerModelsITD.jl. Look here if you want to know how to use a particular function.

## Citing PowerModelsITD.jl

If you find `PowerModelsITD` useful for your work, we kindly request that you cite the following [publication](https://doi.org/10.1109/TPWRS.2023.3234725):

```bibtex
@article{ospina2024modeling,
  author={Ospina, Juan and Fobes, David M. and Bent, Russell and Wächter, Andreas},
  journal={IEEE Transactions on Power Systems},
  title={Modeling and Rapid Prototyping of Integrated Transmission-Distribution OPF Formulations With PowerModelsITD.jl},
  year={2024},
  volume={39},
  number={1},
  pages={172-185},
  keywords={Optimization;Reactive power;Voltage;Upper bound;Distribution networks;Steady-state;Transportation;AC optimal power flow;Julia language;nonlinear optimization;open-source},
  doi={10.1109/TPWRS.2023.3234725}}
```

## Acknowledgments

This code has been developed with the support of the Grant: "Optimized Resilience for Distribution and Transmission Systems" funded by the U.S. Department of Energy (DOE) Office of Electricity (OE) Advanced Grid Modeling (AGM) Research Program under program manager Ali Ghassemian. The research work conducted at Los Alamos National Laboratory is done under the auspices of the National Nuclear Security Administration of the U.S. Department of Energy under Contract No. 89233218CNA000001. The primary developers are Juan Ospina (@juanjospina) and David Fobes (@pseudocubic).

## License

This code is provided under a BSD license as part of the Multi-Infrastructure Control and Optimization Toolkit (MICOT) project, LA-CC-13-108.
