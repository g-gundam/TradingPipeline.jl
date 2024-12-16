using DataFrames
import ExchangeOperations as XO

function make_result(open::XO.SimulatorMarketBuyFill, close::XO.SimulatorMarketSellFill)
    r = @pnl open.price close.price close.amount
    return (action      = :long,
            open_ts     = open.ts,
            open_price  = open.price,
            close_ts    = close.ts,
            close_price = close.price,
            amount      = close.amount,
            pnl         = r.profit_loss)
end

function make_result(open::XO.SimulatorMarketSellFill, close::XO.SimulatorMarketBuyFill)
    r = @pnls open.price close.price close.amount
    return (action      = :short,
            open_ts     = open.ts,
            open_price  = open.price,
            close_ts    = close.ts,
            close_price = close.price,
            amount      = close.amount,
            pnl         = r.profit_loss)
end

"""report(session::XO.SimulatorSession) -> Vector{Result}

Return a list of trades that happened during the simulator session.
"""
function report(session::XO.SimulatorSession)
    neutral = true
    open = missing
    close = missing
    trades = []
    for fill in session.order_log
        if neutral
            open = fill
            neutral = false
        else
            close = fill
            push!(trades, make_result(open, close))
            neutral = true
        end
    end
    if !neutral
        # INFO: This is a marker for a position that was left open at the end of the simulation.
        dt = DateTime(2222)
        close = if typeof(open) == XO.SimulatorMarketBuyFill
            XO.SimulatorMarketSellFill(;ts=dt, price=session.state.price, amount=open.amount)
        else
            XO.SimulatorMarketBuyFill(;ts=dt, price=session.state.price, amount=open.amount)
        end
        push!(trades, make_result(open, close))
    end
    return DataFrame(trades)
end
