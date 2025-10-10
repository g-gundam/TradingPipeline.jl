module TradingPipeline

## Dependencies

# from the wider ecosystem
using Chain
using DataFrames
using Dates
using DocStringExtensions
using EnumX
using Printf
using UnPack
using Rocket

# work of people I've interacted with
import HierarchicalStateMachines as HSM
using OnlineTechnicalIndicators

# my own work
using CryptoMarketData
using TechnicalIndicatorCharts
using ReversedSeries
import ExchangeOperations as XO

## module TradingPipeline.PNL

# - I wanted to hide its types away and only use this functionality through @pnl and @pnls.
module PNL
include("pnl.jl")
end
using .PNL: @pnl, @pnls, Contracts
export @pnl, @pnls, Contracts

## module TradingPipeline.Stops

# TODO: Fix this this is weird.  i should do it more like perl where the
# module keyword is already in the included file.
module Stops
include("stops.jl") # This is like the stop version of hsm*.jl.
end

## module TradingPipeline.MOS

module MOS 
# Market Order Strategy
# - MarketOrderStrategyStateMachine and related symbols are isolated here in an attempt to avoid clutter.
include("hsm_types.jl")
include("hsm_instance.jl")
end

## module TradingPipeline (continued)

include("util.jl")
include("report.jl")
include("explore.jl")
export report

include("abstract_strategy.jl")
include("strategies/goldencross.jl")
include("strategies/hma.jl")
include("strategies/hma2.jl")

include("abstract_stops.jl")
include("stops/default.jl") # Set an initial stop and let it sit until it's hit or the position closes.

export load_strategy
include("candles.jl")
include("rocket.jl")
include("pipeline.jl")
export simulate
export backtest

end



## REPL work

#=

using Statistics
using CryptoMarketData
using TechnicalIndicatorCharts
using ReversedSeries
import ExchangeOperations as XO

using UnPack
using LightweightCharts

pancakeswap = PancakeSwap()
btcusd1m = load(pancakeswap, "BTCUSD"; span=Date("2023-07-01"):Date("2024-11-29"))

import TradingPipeline as TP
import HierarchicalStateMachines as HSM
using TradingPipeline
using TradingPipeline: simulate, GoldenCrossStrategy, HMAStrategy, HMA2Strategy, df_candles_observable
using TradingPipeline: load_strategy, report
candle_observable = df_candles_observable(btcusd1m)

# old way
#@unpack hsm, simulator_session, chart_subject = simulate(candle_observable, HMA2Strategy);

# new way
strategy_config = HMA2Strategy => Dict()
@unpack hsm, simulator_session, chart_subject = backtest(candle_observable, strategy_config);

rdf = report(simulator_session)

sum(rdf.pnl)
mean(rdf.pnl)
mean(rdf.percent)

chart = chart_subject.charts[:trend]
v = visualize((chart, simulator_session); min_height=800)
lwc_show(v)

=#
