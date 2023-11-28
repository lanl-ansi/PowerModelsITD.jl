using Documenter
using PowerModelsITD

const _FAST = findfirst(isequal("--fast"), ARGS) !== nothing

makedocs(
    modules = [PowerModelsITD],
    format = Documenter.HTML(
        analytics = "",
        mathengine = Documenter.MathJax(),
        prettyurls=false,
        collapselevel=1,
    ),
    sitename = "PowerModelsITD.jl",
    authors = "Juan Ospina, David M Fobes, and contributors",
    pages = [
        "Introduction" => "index.md",
        "installation.md",
        "Manual" => [
            "Getting Started" => "manual/quickguide.md",
            "File Formats" => "manual/fileformat.md",
            "Formulations" => "manual/formulations.md",
            "Storage" => "manual/storage.md",
        ],
        "Tutorials" => [
            "Beginners Guide" => "tutorials/BeginnersGuide.md",
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

deploydocs(
    repo = "github.com/lanl-ansi/PowerModelsITD.jl.git",
    push_preview = false,
    devbranch = "main",
)
