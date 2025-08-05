using TradingPipeline
using Documenter
using DocumenterVitepress
using LiveServer

include("shared.jl")

makedocs(; md_local...)

#LiveServer.serve(dir = "docs/build/1")

