using Rocket
using CryptoMarketData
using CryptoMarketData: AbstractExchange, AbstractCandle, Bitstamp, PancakeSwap
using TechnicalIndicatorCharts
using HTTP
using HTTP: WebSocket, WebSockets
using Visor
using DataFrames
using Dates

# This file will be all about creating candle observables.
# - The original kind was a Rocket.iterable backed by a DataFrame.
# - I need to make a WebSocket backed candle observable too.
# - I also want a hybrid of the two where it:
#   + starts with a DataFrame
#   + uses HTTP to fetch the most recent minutes (in case it doesn't have them from the df)
#   + swithces to WebSockets
# - I just realized the switch has to be lazy!

# First, let's take a DataFrame and make it into an Observable.
"""$(TYPEDSIGNATURES)

Take a DataFrame and return an observable that emits candles.
"""
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

"""$(TYPEDSIGNATURES)

Start a websocket session and create an observable that emits candles from the websocket.
"""
function ws_candles_observable(exchange::AbstractExchange, market::AbstractString; from::Date=today())
    # load a dataframe of candles from
    # - local storage to the extent that we can
    # - HTTP API for any missing gaps between now and the last locally saved candle
    # continuously load future candles from a websocket
    # - maintain collected candles in memory.
    session = start(exchange, market)
    (ch, t, o) = stream(session, from)
    observable = Rocket.iterable(ch)

    # standardize on TechnicalIndicatorCharts.Candle
    # INFO: This is my first time using Rocket.jl's map operator.
    converted_observable = observable |> map(TechnicalIndicatorCharts.Candle, (c) -> convert(TechnicalIndicatorCharts.Candle, c))

    return (converted_observable, session, ch, t, o)
end

"""$(TYPEDSIGNATURES)

Convert an AbstractCandle into a TechnicalIndicatorCharts.Candle.
TradingPipeline.jl standardizes on TechnicalIndicatorCharts.Candle as a common denominator.
"""
function Base.convert(::Type{TechnicalIndicatorCharts.Candle}, c::CryptoMarketData.AbstractCandle)
    Candle(
        candle_datetime(c),
        c.o,
        c.h,
        c.l,
        c.c,
        c.v
    )
end
