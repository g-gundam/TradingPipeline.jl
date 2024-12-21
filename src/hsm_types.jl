using HierarchicalStateMachines
import HierarchicalStateMachines as HSM
using Rocket
using UnPack

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

const TP = TradingPipeline



# XXX: [2024-12-18 Wed 22:56] Everything from here down can be ignored.
#      Instead of wrestling with the macro system, I ended up using include.

"""    @hsm strategy_subject

Given a StrategySubject instance, define the states and transitions for a
MarketOrderStrategyStateMachine, and return the singleton instance of that state machine.
"""
macro hsm(strategy_subject::Any)
    # XXX: This macro doesn't quite work as intended.
    # Strangely, it's OK if I use it from the REPL.
    # However, if used within the simulate function, the hsm it returns doesn't work as intended.
    # I have no idea why.
    return quote
        local strategy_subject = $(esc(strategy_subject))
        local TP = TradingPipeline

        hsm                 = TP.MarketOrderStrategyStateMachine(nothing, strategy_subject)
        neutral             = TP.Neutral(hsm, strategy_subject)
        want_to_long        = TP.WantToLong(hsm, strategy_subject)
        in_long             = TP.InLong(hsm, strategy_subject)
        want_to_close_long  = TP.WantToCloseLong(hsm, strategy_subject)
        want_to_short       = TP.WantToShort(hsm, strategy_subject)
        in_short            = TP.InShort(hsm, strategy_subject)
        want_to_close_short = TP.WantToCloseShort(hsm, strategy_subject)

        strategy_subject.hsm = hsm

        eval(quote
            function HierarchicalStateMachines.on_initialize!(state::TP.MarketOrderStrategyStateMachine)
                HierarchicalStateMachines.transition_to_state!($hsm, $neutral)
            end
        end)

        # define transitions
        eval(quote
            "OpenLongSignal"
            function HSM.on_event!(state::TP.Neutral, event::TP.OpenLongSignal)
                HSM.transition_to_state!($hsm, $want_to_long)
                return true
            end
        end)

        eval(quote
            function HSM.on_event!(state::TP.WantToLong, event::TP.Fill)
                HSM.transition_to_state!($hsm, $in_long)
                return true
            end
        end)

        eval(quote
            function HSM.on_event!(state::TP.InLong, event::TP.CloseLongSignal)
                HSM.transition_to_state!($hsm, $want_to_close_long)
                return true
            end
        end)

        eval(quote
            function HSM.on_event!(state::TP.InLong, event::TP.StopFill)
                HSM.transition_to_state!($hsm, $neutral)
                return true
            end
        end)

        eval(quote
            function HSM.on_event!(state::TP.WantToCloseLong, event::TP.Fill)
                HSM.transition_to_state!($hsm, $neutral)
                return true
            end
        end)

        eval(quote
            function HSM.on_event!(state::TP.Neutral, event::TP.OpenShortSignal)
                HSM.transition_to_state!($hsm, $want_to_short)
                return true
            end
        end)

        eval(quote
            function HSM.on_event!(state::TP.WantToShort, event::TP.Fill)
                HSM.transition_to_state!($hsm, $in_short)
                return true
            end
        end)

        eval(quote
            function HSM.on_event!(state::TP.InShort, event::TP.CloseShortSignal)
                HSM.transition_to_state!($hsm, $want_to_close_short)
                return true
            end
        end)

        eval(quote
            function HSM.on_event!(state::TP.InShort, event::TP.StopFill)
                HSM.transition_to_state!($hsm, $neutral)
                return true
            end
        end)

        eval(quote
            function HSM.on_event!(state::TP.WantToCloseShort, event::TP.Fill)
                HSM.transition_to_state!($hsm, $neutral)
                return true
            end
        end)

        @info "yeah"
        (;hsm, neutral, want_to_long, in_long, want_to_close_long, want_to_short, in_short, want_to_close_short)
    end
end

export @hsm
