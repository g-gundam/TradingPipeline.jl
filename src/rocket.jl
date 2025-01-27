using EnumX
using Rocket
using UUIDs



@kwdef mutable struct ChartSubject <: Rocket.AbstractSubject{Candle}
    charts::Dict{Symbol,Chart}
    subscribers::Vector = []
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



"""
An **AbstractExchangeResponse** represents a message that was received from an ExchangeFillSubject.
The most common is **ExchangeFill** which lets the StrategySubject know that after putting out an
intent to open or close a position, the exchange has filled the order and the requested position
change has occurred.

# Example

```julia-repl
julia> subtypes(TradingPipeline.AbstractExchangeResponse)
```
"""
abstract type AbstractExchangeResponse end
struct ExchangeFill <: AbstractExchangeResponse end

"""
An **AbstractManualCommand** represents a manual intervention from a human to the StrategySubject.

# Example

```julia-repl
julia> subtypes(TradingPipeline.AbstractExchangeResponse)
```
"""
abstract type AbstractManualCommand end # I haven't used these yet.
struct ManualPause <: AbstractManualCommand end
struct ManualResume <: AbstractManualCommand end

# """
# TradeDecision was created with @enumx to define the 4 messages that can be emitted by a StrategySubject.

# - Long
# - CloseLong
# - Short
# - CloseShort

# These requests are typically sent by a StrategySubject to an ExchangeDriver that will interpret them and
# perform concrete operations through an exchange API to open or close a position.
# """
@enumx TradeDecision begin
    Long
    CloseLong
    Short
    CloseShort
    CreateStop
    MoveStop
    CancelStop
end

# """
# StrategySubjectMode was created with @enumx to define 3 modes of operation for the StrategySubject

# - Normal
# - LongOnly
# - ShortOnly

# This makes it so that a new strategy doesn't have to be implemented if I wanted to test an existing
# strategy in a long-only or short-only way.
# """
@enumx StrategySubjectMode begin
    Normal
    LongOnly
    ShortOnly
end

@kwdef mutable struct StrategySubject <: Rocket.AbstractSubject{Any}
    # This strategy only needs one chart.
    strategy::AbstractStrategy
    hsm::Union{Missing,HSM.AbstractHsmState} = missing
    mode::StrategySubjectMode.T = StrategySubjectMode.Normal
    session::Union{Missing,Any} = missing
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
    decide(strategy::AbstractStrategy, state::HSM.AbstractHsmState)
    -> Union{Nothing, TradeDecision.T}

The decide method takes the current strategy and the current state
according to the state machine, and looks at the market data available
to it to make a decision.  Often, it decides to return `nothing`, but
if conditions as defined by the strategy are met, it could return an
`HSM.AbstractHsmEvent` which will cause the state machine to move to
the next appropriate state.

There are decide methods for every state in the state machine.
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
    session = state.subject.session
    if !ismissing(session)
        ts = session.state.ts
        price = session.state.price
        total = session.state.total
        @info "Neutral" ts price total
    else
        @info "Neutral"
    end
end

function HSM.on_entry!(state::WantToLong)
    @info "WantToLong"
    for sub in state.subject.subscribers
        next!(sub, TradeDecision.Long)
    end
end

function HSM.on_entry!(state::InLong)
    session = state.subject.session
    if !ismissing(session)
        ts = session.state.ts
        price = session.state.price
        @info "InLong" ts price
    else
        @info "InLong"
    end
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



@kwdef mutable struct StopSubject <: Rocket.AbstractSubject{Any}
    policy::AbstractStop
    in_trade::Bool = false
    auto_setup::Bool = true
    auto_cancel::Bool = true
    subscribers::Vector = []
end

function Rocket.on_subscribe!(stop::StopSubject, actor)
    push!(subject.subscribers, actor)
    return voidTeardown
end

## Inputs

# raw candle from candle_subject
function Rocket.on_next!(stop::StopSubject, c::Candle)
    if !stop.in_trade
        return
    end
    # should_move_stop(stop.policy)
    # next!(sub, TradeDecision.MoveStop, new_stop) # this is a new signature
end

# complete candle from chart_subject
function Rocket.on_next!(stop::StopSubject, t::Tuple{Symbol, Candle})
    if !stop.in_trade
        return
    end
end

#
function Rocket.on_next!(stop::StopSubject, state::HSM.AbstractHsmState)
    @info :stop state
    if state == Neutral
        stop.in_trade = false
        if !stop.auto_cancel
            for sub in stop.subscribers
                next!(sub, TradeDecision.CancelStop)
            end
        end
    end
    if state == InLong || state == InShort
        stop.in_trade = true
        if !stop.auto_setup
            for sub in stop.subscribers
                next!(sub, TradeDecision.CreateStop)
            end
        end
    end
end



# This is for keeping the price updated in the simulator_session.
# It also got a side job of shutting down a scheduled task after simulation completion.

@kwdef mutable struct SimulatorSessionActor <: NextActor{Candle}
    session::XO.AbstractSession
    t_fill::Union{Missing,Task}
end

function Rocket.on_complete!(actor::SimulatorSessionActor)
    @info :complete message=typeof(actor)
    if !ismissing(actor.t_fill)
        @info :cleanup message="t_fill"
        setTimeout(1000) do
            schedule(actor.t_fill, InterruptException(); error=true)
        end
    end
end

function Rocket.on_next!(actor::SimulatorSessionActor, c::Candle)
    session = actor.session
    XO.update!(session, c.ts, c.o)
    XO.update!(session, c.ts, c.h)
    XO.update!(session, c.ts, c.l)
    XO.update!(session, c.ts, c.c)
end



# This used to be called ExchangeDriverSubject, but I wanted to be more specific,
# because there are going to be many different exchange drivers.  Some exchanges
# may have more than one driver depending on how one wants to open/close positions.

abstract type AbstractExchangeDriverSubject{T} <: AbstractSubject{T} end

@kwdef struct SimulatorExchangeDriverSubject <: AbstractExchangeDriverSubject{Any}
    session::XO.AbstractSession
    stop_id::Union{Missing,UUID} = missing
    subscribers::Vector = []
end

function Rocket.on_subscribe!(subject::SimulatorExchangeDriverSubject, actor)
    push!(subject.subscribers, actor)
    return voidTeardown
end

function Rocket.on_complete!(subject::SimulatorExchangeDriverSubject)
    @info :complete subject
end

# Position sizing decisions should be made here, but how?

function Rocket.on_next!(subject::SimulatorExchangeDriverSubject, decision::TradeDecision.T)
    session = subject.session
    if decision == TradeDecision.Long
        XO.send!(session, XO.SimulatorMarketBuy(1.0))
    elseif decision == TradeDecision.CloseLong
        XO.send!(session, XO.SimulatorMarketSell(1.0))
    elseif decision == TradeDecision.Short
        XO.send!(session, XO.SimulatorMarketSell(1.0))
    elseif decision == TradeDecision.CloseShort
        XO.send!(session, XO.SimulatorMarketBuy(1.0))
    elseif decision == TradeDecision.CancelStop
        id = subject.stop_id
        if !ismissing(id)
            XO.send!(session, XO.SimulatorStopMarketCancel(id))
        end
    else
        @warn :simulator_exchange_driver message="Unhandled TradeDecision" decision
    end
end

function Rocket.on_next!(subject::SimulatorExchangeDriverSubject, decision::TradeDecision.T, price::Float64)
    session = subject.session
    if decision == TradeDecision.MoveStop
        # get the stop order
        id = subject.stop_id
        if !ismissing(id)
            XO.send!(session, XO.SimulatorStopMarketUpdate(id, price))
        end
    end
end



# This receives async messages from the exchange (XO.AbstractResposne)
# and translates it into something more generic for StrategySubject to consume.
# These may have to be exchange-specific.
# This one works for the simulator.

struct ExchangeFillSubject <: AbstractSubject{Any}
    subscribers::Vector
end

function Rocket.on_subscribe!(subject::ExchangeFillSubject, actor)
    push!(subject.subscribers, actor)
    return voidTeardown
end

function Rocket.on_complete!(subject::ExchangeFillSubject)
    @info :complete subject
end

function Rocket.on_next!(subject::ExchangeFillSubject, response::XO.AbstractResponse)
    for sub in subject.subscribers
        next!(sub, ExchangeFill())
        # XXX: There needs to be more information in ExchangeFill instances.
        # - timestamp (with exchange time)
        # - price (that the fill happeend at)
        # - amount (that was filled)
    end
end
