# I'm using this to learn how to use HSM.jl
# https://github.com/AndrewWasHere/HSM.jl
# https://andrewwashere.github.io/HSM.jl/dev/
# https://andrewwashere.github.io/2022/05/21/state-machines.html

# I think I'm going to need this for strategy implementation.
# turnstile

import HierarchicalStateMachines as HSM
using Rocket

macro strategy_state(name)
    return :(
        struct $name <: HSM.AbstractHsmState
            state_info::HSM.HsmStateInfo
            subject::Rocket.AbstractSubject

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
