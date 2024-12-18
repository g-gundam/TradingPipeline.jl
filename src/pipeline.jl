# XXX: Now what?
# I need a function that takes a
# - candle observable,
# - a strategy,
# - and optional kwargs for the strategy
#
# It's job is to run a simulation to completion.
# It should return the simulator_session.
# Maybe the chart_subject and strategy_subject, too.
#
# test

"Is this allowed?"
function simulate(candle_observable, strategy_type::Type{<: AbstractStrategy}; kwargs...)
    candle_subject = Subject(Candle)
    (chart_subject, strategy_subject) = load_strategy(strategy_type)
    @info :t typeof(strategy_subject)
    hsm = @hsm strategy_subject # XXX: This macro is not working.  Go back to include?
    HSM.transition_to_state!(hsm, hsm)
    state = HSM.active_state(strategy_subject.hsm)
    @info :state typeof(state) typeof(hsm.state_info.active_substate)

    # Connect strategy_subject => simulator_exchange_driver_subject
    simulator_session = XO.SimulatorSession()
    simulator_exchange_driver_subject = SimulatorExchangeDriverSubject(simulator_session, [])
    subscribe!(strategy_subject, simulator_exchange_driver_subject)

    # Create an observable for simulator_session.responses
    fill_observable = iterable(simulator_session.responses)

    # Connect fill_observable to something that sends fills back to the strategy_subject
    exchange_fill_subject = ExchangeFillSubject([])
    t_fill = @task subscribe!(fill_observable, exchange_fill_subject)
    schedule(t_fill)
    subscribe!(exchange_fill_subject, strategy_subject)

    # Connect chart_subject to strategy_subject
    subscribe!(chart_subject, strategy_subject)

    # Connect chart_subject to candle_subject.
    subscribe!(candle_subject, chart_subject)

    # connect the simulator to candle_subject
    simulator_session_actor = SimulatorSessionActor(simulator_session, t_fill)
    subscribe!(candle_subject, simulator_session_actor)

    # This will put everything in motion.
    subscribe!(candle_observable, candle_subject)

    return simulator_session # maybe more later
end
