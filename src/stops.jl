using HierarchicalStateMachines
import HierarchicalStateMachines as HSM
using Rocket



# TODO: Drop in the Plan struct + friends I've been experimenting with.



macro stop_state(name)
    return :(
        mutable struct $name <: HSM.AbstractHsmState
            state_info::HSM.HsmStateInfo
            subject::Union{Nothing,Rocket.AbstractSubject} # XXX: I wonder if I really need this.

	    $name(parent, subject) = new(HSM.HsmStateInfo(parent), subject)
	end
    )
end

# states
@stop_state StopLossStateMachine
@stop_state Neutral
@stop_state WantInitialStop
@stop_state StopSet
@stop_state WantMove
@stop_state WantCancelAfterClose

# events
struct Fill           <: HSM.AbstractHsmEvent end
struct PositionOpened <: HSM.AbstractHsmEvent end
struct MoveCondition  <: HSM.AbstractHsmEvent end
struct StoppedOut     <: HSM.AbstractHsmEvent end
struct PositionClosed <: HSM.AbstractHsmEvent end

# global variables
# state instances
hsm                     = StopLossStateMachine(nothing, nothing)
neutral                 = Neutral(hsm, nothing)
want_initial_stop       = WantInitialStop(hsm, nothing)
stop_set                = StopSet(hsm, nothing)
want_move               = WantMove(hsm, nothing)
want_cancel_after_close = WantCancelAfterClose(hsm, nothing)

"""    set_subject!(subject::Rocket.AbstractSubject)

Mutate the subject of all TP.Stops state instances.
This is my workaround for state machines being singletons.
"""
function set_subject!(subject::Rocket.AbstractSubject)
    hsm.subject                     = subject
    neutral.subject                 = subject
    want_initial_stop.subject       = subject
    stop_set.subject                = subject
    want_move.subject               = subject
    want_cancel_after_close.subject = subject
end

# transitions
function HSM.on_initialize!(state::StopLossStateMachine)
    @warn "initialize"
    HSM.transition_to_state!(hsm, neutral)
end

function HSM.on_event!(state::Neutral, event::PositionOpened)
    HSM.transition_to_state!(hsm, want_initial_stop)
    return true
end

function HSM.on_event!(state::WantInitialStop, event::Fill)
    HSM.transition_to_state!(hsm, stop_set)
    return true
end

function HSM.on_event!(state::StopSet, event::MoveCondition)
    HSM.transition_to_state!(hsm, want_move)
    return true
end

function HSM.on_event!(state::WantMove, event::Fill)
    HSM.transition_to_state!(hsm, stop_set)
    return true
end

function HSM.on_event!(state::StopSet, event::StoppedOut)
    HSM.transition_to_state!(hsm, neutral)
    return true
end

function HSM.on_event!(state::StopSet, event::PositionClosed)
    HSM.transition_to_state!(hsm, want_cancel_after_close)
    return true
end

function HSM.on_event!(state::WantCancelAfterClose, event::Fill)
    HSM.transition_to_state!(hsm, neutral)
    return true
end
