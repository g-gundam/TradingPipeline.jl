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

# `strategy_subject` is global so that the `include` of hsm_instance.jl works.
strategy_subject::Union{Rocket.AbstractSubject, Nothing} = nothing

# XXX: `stop_subject` is also global for similar reasons -- HSMs are singletons so I have to do it this weird way. 
stop_subject::Union{Rocket.AbstractSubject, Nothing} = StopSubject(;policy=nothing, in_trade=false, auto_setup=false, auto_cancel=false)

"`simulate_sanity_check_failure_error` is a tuple filled with a lot of nothing values so that
code that's @unpack'ing return values from `simulate()` don't crash."
simulate_sanity_check_failure_error = (
    hsm = nothing,
    simulator_session = nothing,
    simulator_exchange_driver_subject = nothing,
    fill_observable = nothing,
    chart_subject = nothing,
    strategy_subject = nothing,
    simulator_session_actor = nothing,
)

# What's the signature that I want?
# simulate(candles, strategytype=>config; positionsizefn, stoppolicy)
function simulate(candle_observable, strategy_type::Type{<: AbstractStrategy}, strategy_options::AbstractDict;
                  stops::Any=nothing,
                  position_size::Any=nothing)
    (cs, ss) = load_strategy(strategy_type; strategy_options...)
    simulate_main(candle_observable, cs, ss)
end

"""$(TYPEDSIGNATURES)
Run a strategy on the simulator using the given `candle_observable`.

## Return Values

A named tuple with the following keys will be returned:
`simulator_session`, `hsm`, `simultator_exchange_driver_subject`,
`fill_observable`, `chart_subject`, `strategy_subject`, `simulator_session_actor`.

# Example

```julia-repl
julia> candle_observable = df_candles_observable(btcusd1m)
IterableObservable(Candle, Vector{Candle}, Rocket.AsapScheduler)

julia> @unpack simulator_session, chart_subject = simulate(candle_observable, HMAStrategy);
```
"""
function simulate(candle_observable, strategy_type::Type{<: AbstractStrategy}; kwargs...)
    (cs, ss) = load_strategy(strategy_type; kwargs...)
    simulate_main(candle_observable, cs, ss)
end

# function simulate(candle_observable, chart_subject,
#                   Pair{AbstractStrategySubject,Dict},
#                   Pair{AbstractExchangeDriverSubject,Dict})
# end

function simulate_main(candle_observable, chart_subject, ss)
    candle_subject = Subject(Candle)
    global strategy_subject = ss # XXX: FUUUUUUUU
    src = dirname(@__FILE__)
    # INFO: It worked, but I hate having to do this.
    # INFO: If HSM gets a v2, I hope I can remove this.
    hsm = include("$(src)/hsm_instance.jl") # XXX: I wish I didn't have to do this.
    strategy_subject.hsm = hsm
    HSM.transition_to_state!(hsm, hsm)
    sanity_check = typeof(HSM.active_state(hsm))
    if sanity_check != TradingPipeline.Neutral
        @error "wtf" sanity_check should_be=TradingPipeline.Neutral solution="Try running it again.  Subsequent runs seem OK."
        return simulate_sanity_check_failure_error
    end

    # Connect strategy_subject => simulator_exchange_driver_subject
    simulator_session = XO.SimulatorSession()
    simulator_exchange_driver_subject = SimulatorExchangeDriverSubject(session=simulator_session)
    subscribe!(strategy_subject, simulator_exchange_driver_subject)

    # connect the simulator to candle_subject
    simulator_session_actor = SimulatorSessionActor(simulator_session, missing)
    subscribe!(candle_subject, simulator_session_actor)

    # Create an observable for simulator_session.responses
    fill_observable = iterable(simulator_session.responses)

    # Connect fill_observable to something that sends fills back to the strategy_subject
    exchange_fill_subject = ExchangeFillSubject([])
    t_fill = @task subscribe!(fill_observable, exchange_fill_subject)
    schedule(t_fill)
    simulator_session_actor.t_fill = t_fill
    subscribe!(exchange_fill_subject, strategy_subject)

    # Connect chart_subject to strategy_subject
    subscribe!(chart_subject, strategy_subject)

    # Connect chart_subject to candle_subject.
    subscribe!(candle_subject, chart_subject)

    # This will put everything in motion.
    subscribe!(candle_observable, candle_subject)

    # Return a named tuple
    (;
     simulator_session,
     hsm,
     simulator_exchange_driver_subject,
     fill_observable,
     chart_subject,
     strategy_subject,
     simulator_session_actor)
end

# What do I need?
# - [candle_observable] the raw candle data to test on
# - [??] a strategy and its configuration
# - [??] a stop policy and its configuration
function backtest(candle_observable, strategy, stops)
    # Maybe strategy and stops can be a tuple of (Strategy, Configuration) and (StopPolicy, Configuration).
    # Given those configs, I can construct all the auxiliary data structures that support them.
end
