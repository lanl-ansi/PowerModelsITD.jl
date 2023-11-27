# Quick Guide on Storage (with Costs) Problem Specification

In this guide, we will discuss the differences between the two problem specifications currently available in `PowermodelsITD` that consider `storage devices` when performing OPF.

## TL;DR

- `solve_opfitd(...)`: considers the operation (charge and discharge) of storage devices at both transmission and distribution system(s), but, no cost is added to the objective cost function. In other words, cycling/using the storage devices is a `free` operation.

- `solve_opfitd_storage(...)`: considers the operation (charge and discharge) of storage devices at both transmission and distribution system(s), and cost term(s) are added to the objective cost function. In other words, cycling/using the storage devices is `not free` and the specific cost of using the storage device is added to the cost function as $sd \times cost$, where `sd` is the amount of power discharged and `cost` is a scalar value in units \$/kWh or \$/pu.

## Default Costs and Units

By default, the costs of the storage devices are calculated based on the references shown below. However, users are *encouraged* to assign their own costs after parsing files.

- Transmission cost must be in \$/pu units.
(e.g., transformation from \$/MWh -> \$/pu: 200 \$/MWh x 100 MVA base/1 pu = 20,000 \$/pu)
- Distribution cost must be in \$/kWh units.
- Default costs of storage devices (in \$/kWh) are computed based on Eq. (23) from this [publication](https://ieeexplore.ieee.org/document/8805394).
- The total cost of the storage system, $C_{total}^{ES}$, is estimated based on NREL data obtained from this [resource](https://atb.nrel.gov/electricity/2021/residential_battery_storage).

```math
\begin{align}
%
cost =  c_{\epsilon, \varepsilon} = \dfrac{C_{total}^{ES}}{Cyc\cdot {E_{_{ES}}^{max}}\cdot DoD\cdot \eta_{r}},
%
\end{align}
```

## Running Integrated Transmission-Distribution Optimal Power Flow with Storage Costs

The snippet below shows how to run a steady-state Integrated Transmission-Distribution (ITD) AC Optimal Power Flow with storage costs.
All of these files can be found in `test` folder of the repository.

```julia
using PowerModelsITD
using Ipopt

pm_file = "case5_withload.m"
pmd_file = "case3_balanced_withBattery.dss"
pmitd_file = "case5_case3_bal_battery.json"
pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
pmitd_data = parse_files(pm_file, pmd_file, pmitd_file)

# cost to assign to energy storage
# Units $/kWh
strg_cost = 0.025

# add cost to storages in PMD
for (st_name, st_data) in pmitd_data["it"]["pmd"]["storage"]
    st_data["cost"] = strg_cost
end

# solve optimization with storage cost problem
pmitd_result_strg = solve_opfitd_storage(pmitd_data, pmitd_type, Ipopt.Optimizer)

```

## Running Integrated Transmission-Distribution Optimal Power Flow with Storage Costs Multinetwork

Running a multinetwork (i.e., multi-timestep) is also very simple. Only slight changes are required (assuming multinetwork data exists in the distribution files) as seen in the snippet shown below.

```julia
using PowerModelsITD
using Ipopt

pm_file = "case5_withload.m"
pmd_file = "case3_balanced_withBattery_mn_diff.dss"
pmitd_file = "case5_case3_bal_battery_mn.json"
pmitd_type = NLPowerModelITD{ACPPowerModel, ACPUPowerModel}
pmitd_data = parse_files(pm_file, pmd_file, pmitd_file; multinetwork=true)

# cost to assign to energy storage
# Units $/kWh
strg_cost = 0.0025

# add cost to storages in PMD
for (nw_id, nw_data) in pmitd_data["it"]["pmd"]["nw"]
    for (st_name, st_data) in nw_data["storage"]
        st_data["cost"] = strg_cost
    end
end

pmitd_result_strg = solve_mn_opfitd_storage(pmitd_data, pmitd_type, Ipopt.Optimizer)

```

## How are the Storage Devices Modeled?

The storage mathematical model (for both transmission and distribution system(s)) are based on the model shown [here](https://lanl-ansi.github.io/PowerModels.jl/stable/storage/).
Given the storage data model and two sequential time points $s$ and $t$, the storage component's mathematical model is given by,

```math
\begin{align}
%
\mbox{data: } & \nonumber \\
& e^u \mbox{ - energy rating} \nonumber \\
& sc^u \mbox{ - charge rating} \nonumber \\
& sd^u \mbox{ - discharge rating} \nonumber \\
& \eta^c \mbox{ - charge efficiency} \nonumber \\
& \eta^d \mbox{ - discharge efficiency} \nonumber \\
& te \mbox{ - time elapsed} \nonumber \\
& S^l \mbox{ - power losses} \nonumber \\
& Z \mbox{ - injection impedance} \nonumber \\
& q^l, q^u  \mbox{ - reactive power injection limits} \nonumber \\
& s^u \mbox{ - thermal injection limit} \nonumber \\
& i^u \mbox{ - current injection limit} \nonumber \\
%
\mbox{variables: } & \nonumber \\
& e_i \in (0, e^u) \mbox{ - storage energy at time $i$} \label{var_strg_energy} \\
& sc_i \in (0, sc^u) \mbox{ - charge amount at time $i$} \label{var_strg_charge} \\
& sd_i \in (0, sd^u) \mbox{ - discharge amount at time $i$} \label{var_strg_discharge} \\
& sqc_i \mbox{ - reactive power slack at time $i$} \label{var_strg_qslack} \\
& S_i \mbox{ - complex bus power injection at time $i$} \label{var_strg_power} \\
& I_i \mbox{ - complex bus current injection at time $i$} \label{var_strg_current} \\
%
\mbox{subject to: } & \nonumber \\
& e_t - e_s = te \left(\eta^c sc_t - \frac{sd_t}{\eta^d} \right) \label{eq_strg_energy} \\
& sc_t \cdot sd_t = 0 \label{eq_strg_compl} \\
& S_t + (sd_t - sc_t) = j \cdot sqc_t + S^l + Z |I_t|^2 \label{eq_strg_loss} \\
& q^l \leq \Im(S_t) \leq q^u \label{eq_strg_q_limit} \\
& |S_t| \leq s^u \label{eq_strg_thermal_limit} \\
& |I_t| \leq i^u \label{eq_strg_current_limit}
\end{align}
```

## What is the Cost (Objective) Function?

The cost (objective) function of the `solve_opfitd_storage(...)` and `solve_mn_opfitd_storage(...)` is based on the mathematical model:

```math
\begin{align}
\begin{split}
   \text{min} &\bigg(\sum_{k \in G^{^\mathcal{T}}} c_{2k}(P_{g,k}^{\mathcal{T}})^2 + c_{1k}(P_{g,k}^{\mathcal{T}}) + c_{0k} \bigg) +\\
    &\bigg(\sum_{\epsilon \in E^{^\mathcal{T}}} c_{\epsilon}(sd_{\epsilon}^{\mathcal{T}})\bigg) +\\
    &\bigg(\sum_{m \in G^{^\mathcal{D}}} c_{2m}(\sum_{\varphi \in \Phi} P_{g,m}^{\mathcal{D},\varphi})^2 + c_{1m}(\sum_{\varphi \in \Phi} P_{g,m}^{\mathcal{D},\varphi}) + c_{0m} \bigg) +\\
    &\bigg(\sum_{\varepsilon \in E^{^\mathcal{D}}} c_{\varepsilon}(sd_{\varepsilon}^{\mathcal{D}})\bigg)
\end{split}
\end{align}
```

As observed, the costs of discharging the storage devices for both Transmission and Distribution system(s) are added the cost function of the OPFITD. This means that storage devices will only discharge power to the grid when the cost of `charging` + `discharging` energy is less than the cost of *not* using (cycling) the storage device.

This cost function only cosiders cost as a factor for determining when to use the storage devices, however, it is important to note that users are encouraged to create their own cost functions that consider other factors (e.g., voltage deviations) that will make the storage devices operate more often, as needed.
