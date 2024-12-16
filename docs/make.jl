using TradingPipeline
using Documenter

DocMeta.setdocmeta!(TradingPipeline, :DocTestSetup, :(using TradingPipeline); recursive=true)

makedocs(;
    modules=[TradingPipeline],
    authors="gg <gg@nowhere> and contributors",
    sitename="TradingPipeline.jl",
    format=Documenter.HTML(;
        canonical="https://g-gundam.github.io/TradingPipeline.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/g-gundam/TradingPipeline.jl",
    devbranch="main",
)
