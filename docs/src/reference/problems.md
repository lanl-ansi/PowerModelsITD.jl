# [Problems](@id ProblemAPI)

## Solve Problems

```@autodocs
Modules = [PowerModelsITD]
Private = false
Order = [:function]
Filter = t -> startswith(string(t), "solve")
```

## Builders

```@autodocs
Modules = [PowerModelsITD]
Private = false
Order = [:function]
Filter = t -> startswith(string(t), "build")
```

## Model Instantiation

```@docs
instantiate_model
```
