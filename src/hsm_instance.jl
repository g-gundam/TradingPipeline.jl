# XXX: strategy_subject must be in scope at this point.
# XXX: I hate this, but I don't see another way.
hsm                 = MarketOrderStrategyStateMachine(nothing, nothing)
neutral             = Neutral(hsm, nothing)
want_to_long        = WantToLong(hsm, nothing)
in_long             = InLong(hsm, nothing)
want_to_close_long  = WantToCloseLong(hsm, nothing)
want_to_short       = WantToShort(hsm, nothing)
in_short            = InShort(hsm, nothing)
want_to_close_short = WantToCloseShort(hsm, nothing)

# initialize
function HSM.on_initialize!(state::MarketOrderStrategyStateMachine)
    HSM.transition_to_state!(hsm, neutral)
end

# define transitions
function HSM.on_event!(state::Neutral, event::OpenLongSignal)
    HSM.transition_to_state!(hsm, want_to_long)
    return true
end

function HSM.on_event!(state::WantToLong, event::Fill)
    HSM.transition_to_state!(hsm, in_long)
    return true
end

function HSM.on_event!(state::InLong, event::CloseLongSignal)
    HSM.transition_to_state!(hsm, want_to_close_long)
    return true
end

function HSM.on_event!(state::InLong, event::StopFill)
    HSM.transition_to_state!(hsm, neutral)
    return true
end

function HSM.on_event!(state::WantToCloseLong, event::Fill)
    HSM.transition_to_state!(hsm, neutral)
    return true
end

function HSM.on_event!(state::Neutral, event::OpenShortSignal)
    HSM.transition_to_state!(hsm, want_to_short)
    return true
end

function HSM.on_event!(state::WantToShort, event::Fill)
    HSM.transition_to_state!(hsm, in_short)
    return true
end

function HSM.on_event!(state::InShort, event::CloseShortSignal)
    HSM.transition_to_state!(hsm, want_to_close_short)
    return true
end

function HSM.on_event!(state::InShort, event::StopFill)
    HSM.transition_to_state!(hsm, neutral)
    return true
end

function HSM.on_event!(state::WantToCloseShort, event::Fill)
    HSM.transition_to_state!(hsm, neutral)
    return true
end

function set_subject!(subject::Rocket.AbstractSubject)
    hsm.subject                 = subject
    neutral.subject             = subject
    want_to_long.subject        = subject
    in_long.subject             = subject
    want_to_close_long.subject  = subject
    want_to_short.subject       = subject
    in_short.subject            = subject
    want_to_close_short.subject = subject
end

# How to start the machine
#   HSM.transition_to_state!(hsm, hsm)
# This will call on_initialize! and the machine will be put into neutral and
# be ready to use.

# How to send events to the machine
#   HSM.handle_event!(hsm, OpenLongSignal())
#   HSM.handle_event!(hsm, Fill())
#   HSM.handle_event!(hsm, CloseLongSignal())
#   HSM.handle_event!(hsm, Fill())

# [2025-02-15 Sat 18:42]
# Since these state machines are singletons, maybe the rocket subjects they work
# with should also be singletons.
# Furthermore, make those subjects sufficiently mutable to that behaviors can
# be swapped out.
# In the case of strategy_subject, instead of instantiating a new subject,
# reuse the global singleton strategy_subject.
# Ugh.  Still not ideal, but it might be less ugly than what I'm doing now
# with repeated includes.

# [2024-12-07 Sat 23:49]
# Split hsm.jl into hsm_types.jl and hsm_instance.jl because rocket.jl needed
# to see the types to implement its features.

# [2024-12-03 Tue 10:56]
# I discovered that the macro approach won't work, because HSM.on_event! dispatches
# on type which will be the same no matter what the instance is.  This library
# needs a redesign to accomodate more than one instance of the same state machine
# in the same process.

# [2024-11-30 Sat 14:49]
# What if I need another instance of a state machine?
# - I could use macros to generete more on_event! methods.
# - I'd also need new instances of the same states.
# - If I choose to have a Strategy struct, I'd need a new instance of that too.
#
# Everything from '# instantiate all the states' on down needs to be in the macro.

