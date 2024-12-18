mutable struct HMAStrategy <: AbstractStrategy
    chart::Chart
    rf::ReversedFrame

    function HMAStrategy(chart)
        new(chart, ReversedFrame(chart.df))
    end
end

function should_open_long(strategy::HMAStrategy)
    # if we're neutral and
    crossed_up(strategy.rf.hma330, strategy.rf.hma440)
end

function should_close_long(strategy::HMAStrategy)
    # if we're long and
    crossed_down(strategy.rf.hma330, strategy.rf.hma440)
end

"""
Initialize a long-only hma strategy.

- Looking for 330/440 crosses
"""
function load_strategy(::Type{HMAStrategy}; symbol="BTCUSD", tf=Hour(4))
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
    chart_subject = ChartSubject(all_charts, [])
    strategy = HMAStrategy(hma_chart)
    strategy_subject = StrategySubject(;strategy)
    return (chart_subject, strategy_subject)
end
