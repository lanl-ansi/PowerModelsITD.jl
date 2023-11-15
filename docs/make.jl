using Documenter
using PowerModelsITD


import Pluto
import Gumbo

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


# Insert HTML rendered from Pluto.jl into tutorial stubs as iframes
if !_FAST
    ss = Pluto.ServerSession()
    client = Pluto.ClientSession(Symbol("client", rand(UInt16)), nothing)
    ss.connected_clients[client.id] = client
    for file in readdir("examples", join=true)
        if endswith(file, ".jl")
            nb = Pluto.load_notebook_nobackup(file)
            client.connected_notebook = nb
            Pluto.update_run!(ss, nb, nb.cells)
            html = Pluto.generate_html(nb)

            base_name = basename(file)
            base_name_splitted = split(base_name, '.')[1]
            fileout = "docs/build/tutorials/$(base_name_splitted).html"

            open(fileout, "w") do io
                write(io, html)
            end

            doc = open("docs/build/tutorials/$(base_name_splitted).html", "r") do io
                Gumbo.parsehtml(read(io, String))
            end

            # add style for full height iframe
            style = Gumbo.HTMLElement(:style)
            style.children = Gumbo.HTMLNode[Gumbo.HTMLText("iframe { height: 100vh; width: 100%; }")]
            push!(doc.root[1], style)

            # create iframe containing Pluto.jl rendered HTML
            iframe = Gumbo.HTMLElement(:iframe)
            iframe.attributes = Dict{AbstractString,AbstractString}(
                "src" => "$(basename(file)).html",
            )

            # edit existing html to replace :article with :iframe
            doc.root[2][1][2][2] = iframe
            # doc.root[2][1][1] = iframe

            # Overwrite HTML
            open("docs/build/tutorials/$(base_name_splitted).html", "w") do io
                Gumbo.prettyprint(io, doc)
            end
        end
    end
end


deploydocs(
    repo = "github.com/lanl-ansi/PowerModelsITD.jl.git",
    push_preview = false,
    devbranch = "main",
)
