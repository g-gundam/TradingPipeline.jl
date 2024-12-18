module TradingPipeline
using DocStringExtensions
using Dates

include("pnl.jl")
include("report.jl")
include("hsm_types.jl")
include("abstract_strategy.jl")
include("strategies/goldencross.jl")
include("strategies/hma.jl")
include("rocket.jl")
include("pipeline.jl")

end
