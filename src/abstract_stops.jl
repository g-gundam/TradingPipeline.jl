# This represents a stop loss policy.
# You can think of it as another kind of strategy for stop loss behavior.
# However, I anticipate there being less variation here than in trading strategies.
abstract type AbstractStops end

# a stop policy needs to be able to answer the following
initial_price(stops::AbstractStops; kwargs...) = missing
should_move_stop(stops::AbstractStops) = false
new_price(stops::AbstractStops) = missing

# TODO: There's probably a little bit more, but I'll figure that out when I implement my first stop policy.
# Maybe I need something for initial price.
# The simplest stop policy is to do nothing at all.
# - Just let it sit until it's hit or the position is closed.
