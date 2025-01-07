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
