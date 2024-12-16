using Printf
using DocStringExtensions

abstract type HypotheticalTrade end

struct Contracts
    n::Number
end

@kwdef struct Long <: HypotheticalTrade
    entry::Number
    exit::Number
    quantity::Union{Number,Contracts} = 1.0
    leverage::Number = 10
end

@kwdef struct Short <: HypotheticalTrade
    entry::Number
    exit::Number
    quantity::Union{Number,Contracts} = 1.0
    leverage::Number = 10
end

@kwdef struct Result
    quantity::Number
    initial_margin::Number
    profit_loss::Number
    profit_loss_percent::Number
    roi::Number
end

function Base.show(io::IO, ::MIME"text/plain", r::Result)
    @printf "%14s %14.2f\n" "quantity" r.quantity
    @printf "%14s %14.2f\n" "initial margin" r.initial_margin
    @printf "%14s %14.2f\n" "profit/loss" r.profit_loss
    @printf "%14s %14.2f\n" "change %" r.profit_loss_percent
    @printf "%14s %14.2f" "roi %" r.roi
end

"""    qty(n::Number, price::Number)

This just returns n since the quantity `n`.
"""
function qty(n::Number, price::Number)
    n
end

"""    qty(c::Contracts, price::Number)

Convert contracts into the equivalent quantity of the asset being traded.
"""
function qty(c::Contracts, price::Number)
    c.n / price
end

"""$(TYPEDSIGNATURES)

Calculate profit/loss of a long position.
"""
function pnl(long::Long)
    entry               = long.entry
    exit                = long.exit
    quantity            = qty(long.quantity, entry)
    leverage            = long.leverage
    initial_margin      = entry * quantity / leverage
    profit_loss         = (exit * quantity) - (entry * quantity)
    profit_loss_percent = ((exit - entry) / entry) * 100
    roi                 = profit_loss_percent * leverage
    Result(;quantity, initial_margin, profit_loss, profit_loss_percent, roi)
end

"""$(TYPEDSIGNATURES)

Calculate profit/loss of a short position.
"""
function pnl(short::Short)
    entry               = short.entry
    exit                = short.exit
    quantity            = qty(short.quantity, entry)
    leverage            = short.leverage
    initial_margin      = entry * quantity / leverage
    profit_loss         = (entry * quantity) - (exit * quantity)
    profit_loss_percent = ((exit - entry) / entry) * -100
    roi                 = profit_loss_percent * leverage
    Result(;quantity, initial_margin, profit_loss, profit_loss_percent, roi)
end

macro pnl(entry, exit)
    return quote
        local entry = $(esc(entry))
        local exit  = $(esc(exit))
        pnl(Long(;entry, exit))
    end
end

macro pnl(entry, exit, quantity)
    return quote
        local entry    = $(esc(entry))
        local exit     = $(esc(exit))
        local quantity = $(esc(quantity))
        pnl(Long(;entry, exit, quantity))
    end
end

"""    @pnl entry exit quantity leverage

Calculate the profit/loss of a long positon.  The `quantity` and `leverage` are optional.
"""
macro pnl(entry, exit, quantity, leverage)
    return quote
        local entry    = $(esc(entry))
        local exit     = $(esc(exit))
        local quantity = $(esc(quantity))
        local leverage = $(esc(leverage))
        pnl(Long(;entry, exit, quantity, leverage))
    end
end

macro pnls(entry, exit)
    return quote
        local entry    = $(esc(entry))
        local exit     = $(esc(exit))
        pnl(Short(;entry, exit))
    end
end

macro pnls(entry, exit, quantity)
    return quote
        local entry    = $(esc(entry))
        local exit     = $(esc(exit))
        local quantity = $(esc(quantity))
        pnl(Short(;entry, exit, quantity))
    end
end

"""    @pnls entry exit quantity leverage

Calculate the profit/loss of a short positon.  The `quantity` and `leverage` are optional.
"""
macro pnls(entry, exit, quantity, leverage)
    return quote
        local entry    = $(esc(entry))
        local exit     = $(esc(exit))
        local quantity = $(esc(quantity))
        local leverage = $(esc(leverage))
        pnl(Short(;entry, exit, quantity, leverage))
    end
end

export @pnl
export @pnls

export pnl
export qty

export HypotheticalTrade
export Long
export Short
export Contracts
