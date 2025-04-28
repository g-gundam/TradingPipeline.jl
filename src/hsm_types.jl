using HierarchicalStateMachines
import HierarchicalStateMachines as HSM
using Rocket
using UnPack

macro strategy_state(name)
    return :(
        mutable struct $name <: HSM.AbstractHsmState
            state_info::HSM.HsmStateInfo
            subject::Union{Nothing, Rocket.AbstractSubject}

	    $name(parent, subject) = new(HSM.HsmStateInfo(parent), subject)
	end
    )
end

@strategy_state MarketOrderStrategyStateMachine
@strategy_state Neutral
@strategy_state WantToLong
@strategy_state InLong
@strategy_state WantToCloseLong
@strategy_state WantToShort
@strategy_state InShort
@strategy_state WantToCloseShort

# I think the events will also have an amount
struct Fill <: HSM.AbstractHsmEvent end
struct StopFill <: HSM.AbstractHsmEvent end
struct OpenLongSignal <: HSM.AbstractHsmEvent end
struct CloseLongSignal <: HSM.AbstractHsmEvent end
struct OpenShortSignal <: HSM.AbstractHsmEvent end
struct CloseShortSignal <: HSM.AbstractHsmEvent end
