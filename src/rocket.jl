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
