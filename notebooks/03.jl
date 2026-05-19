### A Pluto.jl notebook ###
# v0.20.25

using Markdown
using InteractiveUtils

# ╔═╡ f3095108-14d2-492b-bff5-cd87395603a8
begin
    import Pkg
    Pkg.activate("tpp"; shared=true) # (T)rading(P)ipeline (P)luto => @tpp
    using Revise
    using PlutoUI
    using Rocket
    using Dates
    using DataFrames
    using Chain
    using UnPack
    using LightweightCharts
    using OnlineTechnicalIndicators
end

# ╔═╡ b072bd4a-5d16-49ad-9ade-f80732580948
begin
    # Due to using the @tpp environment,
    # I don't have to Pkg.add the local directories.
    # The @tpp environment already did that.
    import TradingPipeline as TP
    using TradingPipeline
    using CryptoMarketData
    using TechnicalIndicatorCharts
    using ReversedSeries
    import ExchangeOperations as XO
end

# ╔═╡ 0e4ebea7-5b6a-4e78-bd9b-011bf5d094a6
md"""
# 03 - Template for using latest unregistered libraries

- 03.jl is meant to be a template for strategy backtesting in Pluto notebooks.
- It assumes a certain directory structure in order to load the latest versions of my libraries and be able to use Revise.jl in a notebook context.
- It also assumes that candles have been downloaded into `datadir` using CryptoMarketData.jl's `save!` function.
"""

# ╔═╡ 38bd1675-650f-4276-becb-216f3da6b630
md"""
# Data
"""

# ╔═╡ b2b6745d-4dd4-4a82-af6f-c1d0d791fc00
datadir = "../data"

# ╔═╡ 5ef635f6-52b7-4660-beea-bfcd67d67131
pancakeswap = PancakeSwap()

# ╔═╡ ed9771c3-9937-4122-9d43-c41ea94db033
btcusd1m = load(pancakeswap, "BTCUSD"; datadir, span=Date("2026-03-19"):Date("2026-05-18"));

# ╔═╡ db7ee608-5c9c-40db-9ba8-40159219b95b
candle_observable = TP.df_candles_observable(btcusd1m)

# ╔═╡ ef19c935-3270-46e3-97a0-8e874bb56643
md"""
# Simulator Sessions
"""

# ╔═╡ e1b9d946-f59a-4db4-b20f-9f4d0626f45c
md"""
## HMA2Strategy - Taking Profit Sooner on Late Entries
"""

# ╔═╡ e85c116e-acfb-468c-b087-499111d33be1
@kwdef mutable struct HMA2Strategy <: TP.AbstractStrategy
    chart::Chart
    rf::ReversedFrame
    is_late_entry::Bool = false
    entry_price::Float64 = 0.0
end

# ╔═╡ fc6fd612-ab52-4298-b8f6-b4f1abb2525b
function percent_diff(a, b)
    ((b - a) / a) * 100
end

# ╔═╡ 45e75970-4627-4258-a1cd-a3cd028206b6
function TP.should_open_long(strategy::HMA2Strategy)
    rf = strategy.rf

    # trade 3: try an alternate entry criteria so that it doesn't get classified as late
    if (crossed_up(rf.hma220, rf.hma440)
        && rf.c[1] > rf.hma440[1]
        && positive_slope_currently(rf.hma330)
        && percent_diff(rf.hma440[1], rf.c[1]) < 3)
        return true
    end

    is_crossed = crossed_up(rf.hma330, rf.hma440)
    if (is_crossed)
        # trade 4 & 5: late entry criteria
        if percent_diff(rf.hma440[1], rf.c[1]) > 8.5
            strategy.is_late_entry = true
            strategy.entry_price = rf.c[1]
            @info :late_entry ts=rf.ts[1]
        else
            strategy.is_late_entry = false
        end

        # trade 6: avoid negative slope
        if ismissing(rf.hma330[1])
            return false
        end
        if rf.hma330[1] !== missing && rf.hma330[1] > rf.c[1] && negative_slope_currently(rf.hma330)
            @info :negative_slope ts=rf.ts[1]
            return false
        end

        # if we got this far, go long.
        return true
    else
        return false
    end
end

# ╔═╡ 0856646f-565f-45bd-a17e-9eac33c82c73
function TP.should_close_long(strategy::HMA2Strategy)
    rf = strategy.rf
    if strategy.is_late_entry
        return percent_diff(strategy.entry_price, rf.c[1]) > 6.0
    else
        crossed_down(strategy.rf.hma330, strategy.rf.hma440)
    end
end

# ╔═╡ 001b7749-0a24-4461-9729-203a0e454c6b
function TP.load_strategy(::Type{HMA2Strategy}; symbol="BTCUSD", tf=Minute(30))
    # Hello
    hma_chart = Chart(
        symbol, tf,
        indicators = [
            HMA{Float64}(;period=55),
            HMA{Float64}(;period=110),
            HMA{Float64}(;period=220),
            HMA{Float64}(;period=330),
            HMA{Float64}(;period=440)
        ],
        visuals = [
            Dict(
                :label_name => "HMA 55",
                :line_color => "#e57373",
                :line_width => 2
            ),
            Dict(
                :label_name => "HMA 110",
                :line_color => "#f39337",
                :line_width => 1
            ),
            Dict(
                :label_name => "HMA 220",
                :line_color => "#ff6d00",
                :line_width => 2
            ),
            Dict(
                :label_name => "HMA 330",
                :line_color => "#26c6da",
                :line_width => 2
            ),
            Dict(
                :label_name => "HMA 440",
                :line_color => "#64b5f6",
                :line_width => 3
            )
        ]
    )
    all_charts = Dict(:trend => hma_chart)
    chart_subject = TP.ChartSubject(charts=all_charts)
    strategy = HMA2Strategy(chart=hma_chart, rf=ReversedFrame(hma_chart.df))
    strategy_subject = TP.StrategySubject(;strategy)
    return (chart_subject, strategy_subject)
end

# ╔═╡ 1775aba7-3cb5-4e82-8642-78daff6954c6
strategy_config = HMA2Strategy => Dict(
	:symbol => "BTCUSD",
	:tf => Minute(15)
)

# ╔═╡ 46c4e15a-89e7-4127-a48d-3caa7ea7a025
r = TP.backtest(candle_observable, strategy_config);

# ╔═╡ 7914d77b-d1e4-4862-a802-445f22230bac
visualize((r.chart_subject[:trend], r.simulator_session); min_height=800)

# ╔═╡ ba956630-8be2-408a-928a-bbe3b34dc5a3
rdf = TP.report(r.simulator_session)

# ╔═╡ 09e9d23c-1bb0-4fc2-956d-918e8cb583e0
# wins
sum(filter(n -> n >= 0, rdf.pnl))

# ╔═╡ 70f1b5da-d433-4931-a10c-8fb77913bda0
# losses
sum(filter(n -> n < 0, rdf.pnl))

# ╔═╡ 385d4772-0255-4fe8-a43c-01fe2cd1f644
# total
sum(rdf.pnl)

# ╔═╡ 7123d5f5-77ff-4231-97e7-be0064a82cf7
md"""
# Libraries
"""

# ╔═╡ dbfea1b0-d616-416a-a7d3-e1d59121071d
TableOfContents(;depth=3)

# ╔═╡ 533cd39c-bde7-11ef-127b-c917240c6f66
md"""
## Local Libraries
"""

# ╔═╡ db3b46c0-4f25-4a8e-ada2-00fad0e796d8
md"""
# CSS
"""

# ╔═╡ ab4805a4-1482-4531-90d2-b8ef0741c026
# https://discourse.julialang.org/t/cell-width-in-pluto-notebook/49761/11
html"""
<style>
  @media screen {
    main {
      margin: 0 auto;
      max-width: 2000px;
        padding-left: max(283px, 10%);
        padding-right: max(383px, 10%);
        # 383px to accomodate TableOfContents(aside=true)
    }
    .plutoui-toc.aside {
      width: min(80vw, 360px)
    }
  }
</style>
"""

# ╔═╡ Cell order:
# ╟─0e4ebea7-5b6a-4e78-bd9b-011bf5d094a6
# ╟─38bd1675-650f-4276-becb-216f3da6b630
# ╠═b2b6745d-4dd4-4a82-af6f-c1d0d791fc00
# ╠═5ef635f6-52b7-4660-beea-bfcd67d67131
# ╠═ed9771c3-9937-4122-9d43-c41ea94db033
# ╠═db7ee608-5c9c-40db-9ba8-40159219b95b
# ╟─ef19c935-3270-46e3-97a0-8e874bb56643
# ╟─e1b9d946-f59a-4db4-b20f-9f4d0626f45c
# ╠═e85c116e-acfb-468c-b087-499111d33be1
# ╠═fc6fd612-ab52-4298-b8f6-b4f1abb2525b
# ╠═45e75970-4627-4258-a1cd-a3cd028206b6
# ╠═0856646f-565f-45bd-a17e-9eac33c82c73
# ╠═001b7749-0a24-4461-9729-203a0e454c6b
# ╠═1775aba7-3cb5-4e82-8642-78daff6954c6
# ╠═46c4e15a-89e7-4127-a48d-3caa7ea7a025
# ╠═7914d77b-d1e4-4862-a802-445f22230bac
# ╠═ba956630-8be2-408a-928a-bbe3b34dc5a3
# ╠═09e9d23c-1bb0-4fc2-956d-918e8cb583e0
# ╠═70f1b5da-d433-4931-a10c-8fb77913bda0
# ╠═385d4772-0255-4fe8-a43c-01fe2cd1f644
# ╟─7123d5f5-77ff-4231-97e7-be0064a82cf7
# ╠═f3095108-14d2-492b-bff5-cd87395603a8
# ╠═dbfea1b0-d616-416a-a7d3-e1d59121071d
# ╟─533cd39c-bde7-11ef-127b-c917240c6f66
# ╠═b072bd4a-5d16-49ad-9ade-f80732580948
# ╟─db3b46c0-4f25-4a8e-ada2-00fad0e796d8
# ╠═ab4805a4-1482-4531-90d2-b8ef0741c026
