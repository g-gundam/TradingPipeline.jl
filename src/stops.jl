module Stops

using HierarchicalStateMachines
import HierarchicalStateMachines as HSM
using Rocket

macro stop_state(name)
    return :(
        mutable struct $name <: HSM.AbstractHsmState
            state_info::HSM.HsmStateInfo
            subject::Rocket.AbstractSubject

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
struct Fill <: HSM.AbstractHsmEvent end
struct PositionOpened <: HSM.AbstractHsmEvent end
struct MoveCondition <: HSM.AbstractHsmEvent end
struct StoppedOut <: HSM.AbstractHsmEvent end
struct PositionClosed <: HSM.AbstractHsmEvent end

end
