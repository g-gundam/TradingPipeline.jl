using TradingPipeline
using Documenter
using DocumenterVitepress

DocMeta.setdocmeta!(TradingPipeline, :DocTestSetup, :(using TradingPipeline); recursive=true)

makedocs(;
    modules=[TradingPipeline],
    authors="gg <gg@nowhere> and contributors",
    sitename="TradingPipeline.jl",
    # format=Documenter.HTML(;
    #     canonical="https://g-gundam.github.io/TradingPipeline.jl",
    #     edit_link="main",
    #     assets=String[],
    # ),
    format=MarkdownVitepress(;
        repo="https://github.com/g-gundam/TradingPipeline.jl"
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/g-gundam/TradingPipeline.jl",
    devbranch="main",
)
