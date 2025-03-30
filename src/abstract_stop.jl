# All stop policies are a subtype of AbstractStop
abstract type AbstractStop end

# What methods should be implemented by stop policies?
should_move_stop(policy::AbstractStop) = false
# TODO: I need something for initial price
# initial_stop(policy::AbstractStop) = 
