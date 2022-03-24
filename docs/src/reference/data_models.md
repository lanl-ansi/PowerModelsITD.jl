# [Data Models and Parsers](@id DataModelAPI)

## Parsers

```@docs
parse_files
parse_json
parse_link_file
parse_power_transmission_file
parse_power_distribution_file
```

## Data Transformations

```@autodocs
Modules = [PowerModelsITD]
Private = false
Order = [:function]
Pages = ["transformations.jl"]
```

## Data Checking and Units Correction

```@docs
correct_network_data!
assign_boundary_buses!
resolve_units!
replicate
sol_data_model!
```
