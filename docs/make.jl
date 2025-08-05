using TradingPipeline
using Documenter
using DocumenterVitepress

include("shared.jl")

makedocs(; md_default...)

DocumenterVitepress.deploydocs(
    ;
    repo         = "github.com/g-gundam/TradingPipeline.jl",
    target       = joinpath(@__DIR__, "build"),
    branch       = "gh-pages",
    devbranch    = "main",
    push_preview = true,
)
