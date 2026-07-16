@kwdef mutable struct NullStrategy <: AbstractStrategy
    charts::Vector{Chart}
end

function load_strategy(::Type{NullStrategy}; symbol="BTCUSD", tf=Day(1))
    default_chart = Chart(symbol, tf, indicators=[], visuals=[])
    all_charts = Dict(:default => default_chart)
    chart_subject = ChartSubject(charts=all_charts)
    null_strat = NullStrategy(charts=all_charts)
    strategy_subject = StrategySubject(strategy=null_strat)
    return (chart_subject, strategy_subject)
end
