using TradingPipeline
using Documenter
using DocumenterVitepress

makedocs(;
    format = DocumenterVitepress.MarkdownVitepress(
        repo = "github.com/g-gundam/TradingPipeline.jl",
        devbranch = "main", # or master, trunk, ...
        devurl = "dev",
    ),
    pages = [
        Home => "index.md",
        PNL  => "pnl.md",
    ]
)

DocumenterVitepress.deploydocs(;
    repo = "github.com/g-gundam/TradingPipeline.jl",
    target = joinpath(@__DIR__, "build"),
    branch = "gh-pages",
    devbranch = "main", # or master, trunk, ...
    push_preview = true,
)
