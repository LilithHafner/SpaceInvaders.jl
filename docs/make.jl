using SpaceInvaders
using Documenter

DocMeta.setdocmeta!(SpaceInvaders, :DocTestSetup, :(using SpaceInvaders); recursive=true)

makedocs(;
    modules=[SpaceInvaders],
    authors="Lilith Orion Hafner <lilithhafner@gmail.com> and contributors",
    repo="https://github.com/LilithHafner/SpaceInvaders.jl/blob/{commit}{path}#{line}",
    sitename="SpaceInvaders.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://LilithHafner.github.io/SpaceInvaders.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/LilithHafner/SpaceInvaders.jl",
    devbranch="main",
)
