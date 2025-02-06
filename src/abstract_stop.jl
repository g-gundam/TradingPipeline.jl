abstract type AbstractStop end

# initial_stop
# should_move_stop


# XXX: REDESIGN
# I don't need to use polymorphism here.
# Functions may be enough to express variances in behavior.

struct Stop
    initial::Any,
    break_even::Any,
    move_when::Function
end
