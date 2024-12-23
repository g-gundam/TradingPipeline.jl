using TechnicalIndicatorCharts
using ReversedSeries

# All strategies must be a sbutype of AbstractStrategy
abstract type AbstractStrategy end

# A strategy is only responsible for answering these four questions.
should_open_long(strategy::AbstractStrategy) = false
should_close_long(strategy::AbstractStrategy) = false
should_open_short(strategy::AbstractStrategy) = false
should_close_short(strategy::AbstractStrategy) = false

