using Dates
using OnlineTechnicalIndicators

# golden cross strategy
mutable struct GoldenCrossStrategy <: AbstractStrategy
    # This one just needs one chart, but a strategy could require multiple charts in different timeframes.
    # I'm assuming sma50 vs sma200, but I can parametrize the fields if I wanted.
    chart::Chart
    rf::ReversedFrame

    function GoldenCrossStrategy(chart)
        new(chart, ReversedFrame(chart.df))
    end
end

function should_open_long(strategy::GoldenCrossStrategy)
    # if we're neutral and
    crossed_up(strategy.rf.sma50, strategy.rf.sma200)
end

function should_close_long(strategy::GoldenCrossStrategy)
    # if we're long and
    crossed_down(strategy.rf.sma50, strategy.rf.sma200)
end

"""
Initialize a long-only simple golden cross strategy.
"""
function load_strategy(::Type{GoldenCrossStrategy}; symbol="BTCUSD", tf=Hour(4))
    golden_cross_chart = Chart(
        symbol, tf,
        indicators = [
            SMA{Float64}(;period=50),
            SMA{Float64}(;period=200),
            BB{Float64}(;period=20)
        ],
        visuals = [
            Dict(
                :label_name => "SMA 50",
                :line_color => "#6D9F71",
                :line_width => 2
            ),
            Dict(
                :label_name => "SMA 200",
                :line_color => "#E01A4F",
                :line_width => 5
            ),
            Dict(
                :upper => Dict(),
                :central => Dict(),
                :lower => Dict()
            )
        ]
    )
    all_charts = Dict(:trend => golden_cross_chart)
    chart_subject = ChartSubject(charts=all_charts)
    gcstrat = GoldenCrossStrategy(golden_cross_chart)
    strategy_subject = StrategySubject(strategy=gcstrat)
    return (chart_subject, strategy_subject)
end
