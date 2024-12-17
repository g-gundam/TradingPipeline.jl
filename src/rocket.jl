using EnumX
using Rocket

# First, let's take a DataFrame and make it into an Observable.
function df_candles_observable(df::DataFrame)
    Rocket.iterable(map(row -> Candle(
        row.ts,
        row.o,
        row.h,
        row.l,
        row.c,
        row.v
    ), eachrow(df)))
end



mutable struct ChartSubject <: Rocket.AbstractSubject{Candle}
    charts::Dict{Symbol,Chart}
    subscribers::Vector
end

function Rocket.on_subscribe!(subject::ChartSubject, actor)
    push!(subject.subscribers, actor)
    return voidTeardown
end

function Rocket.on_next!(subject::ChartSubject, c::Candle)
    for (k, v) in subject.charts
        complete_candle = TechnicalIndicatorCharts.update!(v, c)
        if !isnothing(complete_candle)
            # send a value of type Tuple{Symbol, Candle)} to subscribers
            #next!(subject, (k, complete_candle))
            for s in subject.subscribers
                next!(s, (k, complete_candle))
                #next!(s, complete_candle)
                #next!(s, complete_candle.o)
            end
            yield() # INFO: This allows ExchangeFillSubject to have a chance to work.
            # Otherwise, the loop goes too fast.
        end
    end
end

function Rocket.on_complete!(subject::ChartSubject)
    @info :complete message=typeof(subject)
end

function Base.getindex(subject::ChartSubject, k::Symbol)
    return subject.charts[k]
end



abstract type AbstractExchangeResponse end
struct ExchangeFill <: AbstractExchangeResponse end

abstract type AbstractManualCommand end # I haven't used these yet.
struct ManualPause <: AbstractManualCommand end
struct ManualResume <: AbstractManualCommand end

# These are the only messages a StrategySubject sends to its subscribers.
@enumx TradeDecision begin
    Long
    CloseLong
    Short
    CloseShort
end

@kwdef mutable struct StrategySubject <: Rocket.AbstractSubject{Any}
    # This strategy only needs one chart.
    strategy::AbstractStrategy
    hsm::Union{Missing,HSM.AbstractHsmState} = missing
    subscribers::Vector = []
end

function Rocket.on_subscribe!(subject::StrategySubject, actor)
    push!(subject.subscribers, actor)
    return voidTeardown
end

# candle completion event from chart
function Rocket.on_next!(subject::StrategySubject, t::Tuple{Symbol, Candle})
    # figure out current state
    # take the appropriate action for the current state
    # emit trading decisions if conditions are met
    current_state = HSM.active_state(subject.hsm)
    transition = decide(subject.strategy, current_state)
    if transition !== nothing
        HSM.handle_event!(subject.hsm, transition)
    end
end

# fill (or error) from exchange
function Rocket.on_next!(subject::StrategySubject, xr::AbstractExchangeResponse)
    current_state = HSM.active_state(subject.hsm)
    transition = decide(subject.strategy, current_state, xr) # Take more parameters to help decide the next move.
    if transition !== nothing
        HSM.handle_event!(subject.hsm, transition)
    end
end

"""
From neutral, decide whether to go long or short.
"""
function decide(strategy::AbstractStrategy, state::Neutral)
    long = should_open_long(strategy)
    short = should_open_short(strategy)

    # if both are true for some reason, do nothing
    if long && short
        # TODO: Add market timestamp.
        @warn :decide strategy=typeof(strategy) message="Both long and short conditions are true."
        return nothing
    end
    # otherwise, ask the exchange drivers to get in position.
    if long
        return OpenLongSignal()
    end
    if short
        return OpenShortSignal()
    end
end

function decide(strategy::AbstractStrategy, state::InLong)
    if should_close_long(strategy)
        return CloseLongSignal()
    end
end

function decide(strategy::AbstractStrategy, state::InShort)
    if should_close_short(strategy)
        return CloseShortSignal()
    end
end

# With enough method dispatch magic, the amount of code I need to write becomes very small.
# I'm just translating a fill notification into a fill state transition.

decide(strategy::AbstractStrategy, state::WantToLong) = nothing
decide(strategy::AbstractStrategy, state::WantToLong, xr::ExchangeFill) = Fill()
decide(strategy::AbstractStrategy, state::WantToCloseLong) = nothing
decide(strategy::AbstractStrategy, state::WantToCloseLong, xr::ExchangeFill) = Fill()
decide(strategy::AbstractStrategy, state::WantToShort) = nothing
decide(strategy::AbstractStrategy, state::WantToShort, xr::ExchangeFill) = Fill()
decide(strategy::AbstractStrategy, state::WantToCloseShort) = nothing
decide(strategy::AbstractStrategy, state::WantToCloseShort, xr::ExchangeFill) = Fill()

# Most trade decisions are sent to subscribers during on_entry! into the Want* states.

function HSM.on_entry!(state::Neutral)
    @info "Neutral"
end

function HSM.on_entry!(state::WantToLong)
    @info "WantToLong"
    for sub in state.subject.subscribers
        next!(sub, TradeDecision.Long)
    end
end

function HSM.on_entry!(state::InLong)
    @info "InLong"
end

function HSM.on_entry!(state::WantToCloseLong)
    @info "WantToCloseLong"
    for sub in state.subject.subscribers
        next!(sub, TradeDecision.CloseLong)
    end
end

function HSM.on_entry!(state::WantToShort)
    @info "WantToShort"
    for sub in state.subject.subscribers
        next!(sub, TradeDecision.Short)
    end
end

function HSM.on_entry!(state::InShort)
    @info "InShort"
end

function HSM.on_entry!(state::WantToCloseShort)
    @info "WantToCloseShort"
    for sub in state.subject.subscribers
        next!(sub, TradeDecision.CloseShort)
    end
end



# This is for keeping the price updated in the simulator_session.
# It also got a side job of shutting down a scheduled task after simulation completion.

@kwdef struct SimulatorSessionActor <: NextActor{Candle}
    session::XO.AbstractSession
    t_fill::Union{Missing,Task}
end

function Rocket.on_complete!(actor::SimulatorSessionActor)
    @info :complete msg=typeof(actor)
    if !ismissing(actor.t_fill)
        @info :cleanup msg="t_fill"
        schedule(actor.t_fill, InterruptException(); error=true)
    end
end

function Rocket.on_next!(actor::SimulatorSessionActor, c::Candle)
    session = actor.session
    XO.update!(session, c.ts, c.o)
    XO.update!(session, c.ts, c.h)
    XO.update!(session, c.ts, c.l)
    XO.update!(session, c.ts, c.c)
end
