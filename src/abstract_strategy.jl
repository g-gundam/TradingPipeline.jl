using TechnicalIndicatorCharts
using ReversedSeries

# All strategies must be a sbutype of AbstractStrategy
abstract type AbstractStrategy end

# A strategy is only responsible for answering these four questions.
should_open_long(subject::AbstractStrategy) = false
should_close_long(subject::AbstractStrategy) = false
should_open_short(subject::AbstractStrategy) = false
should_close_short(subject::AbstractStrategy) = false

