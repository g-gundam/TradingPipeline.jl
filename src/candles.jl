using Rocket
using CryptoMarketData
using HTTP
using HTTP: WebSocket, WebSockets

# This file will be all about creating candle observables.
# - The original kind was a Rocket.iterable backed by a DataFrame.
# - I need to make a WebSocket backed candle observable too.
# - I also want a hybrid of the two where it:
#   + starts with a DataFrame
#   + uses HTTP to fetch the most recent minutes (in case it doesn't have them from the df)
#   + swithces to WebSockets
# - I just realized the switch has to be lazy!

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

function ws_candles_observable(bitstamp::CryptoMarketData.Bitstamp)
end

function ws_candles_observable(pancakeswap::CryptoMarketData.PancakeSwap)
end
