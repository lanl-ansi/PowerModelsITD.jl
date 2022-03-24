# Base

```@docs
ref
var
ids
con
sol
nws
nw_ids
```

## Helper functions

```@docs
@smart_constraint
silence!
```

## Ref Creation Functions

```@autodocs
Modules = [PowerModelsITD]
Private = false
Order = [:function]
Filter = t -> startswith(string(t), "ref_")
```
