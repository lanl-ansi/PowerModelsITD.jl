using Documenter
using PowerModelsITD


makedocs(
    modules = [PowerModelsITD],
    format = Documenter.HTML(
        analytics = "",
        mathengine = Documenter.MathJax(),
        prettyurls=false,
        collapselevel=1,
    ),
    strict=false,
    sitename = "PowerModelsITD",
    authors = "Juan Ospina, David M Fobes, and contributors",
    pages = [
        "Introduction" => "index.md",
        "installation.md",
        "Manual" => [
            "Getting Started" => "manual/quickguide.md",
        ],
        "Tutorials" => [
            "Beginners Guide" => "tutorials/Beginners Guide.md",
        ],
        "API Reference" => [
            "Base" => "reference/base.md",
            "Data Models" => "reference/data_models.md",
            "Formulations" => "reference/formulations.md",
            "Problems" => "reference/problems.md",
            "Variables" => "reference/variables.md",
            "Constraints" => "reference/constraints.md",
            "Objectives" => "reference/objectives.md",
            "Constants" => "reference/constants.md",
        ],
        "Developer Docs" => [
            "Contributing" => "developer/contributing.md",
            "Style Guide" => "developer/style.md",
            "Roadmap" => "developer/roadmap.md",
        ],
    ]
)
