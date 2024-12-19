module TradingPipeline

# from the wider ecosystem
using Chain
using DataFrames
using Dates
using DocStringExtensions
using EnumX
using Printf
using UnPack

# work of people I've interacted with
import HierarchicalStateMachines as HSM
using OnlineTechnicalIndicators

# my own work
using CryptoMarketData
using TechnicalIndicatorCharts
using ReversedSeries
import ExchangeOperations as XO

include("pnl.jl")
include("report.jl")
include("hsm_types.jl")
include("abstract_strategy.jl")
include("strategies/goldencross.jl")
include("strategies/hma.jl")
include("rocket.jl")
include("pipeline.jl")

end
