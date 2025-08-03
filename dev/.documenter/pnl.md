
# TradingPipeline.PNL {#TradingPipeline.PNL}

This is a utility module for doing PNL calculations.
- [`TradingPipeline.simulate_sanity_check_failure_error`](#TradingPipeline.simulate_sanity_check_failure_error)
- [`TradingPipeline.AbstractExchangeResponse`](#TradingPipeline.AbstractExchangeResponse)
- [`TradingPipeline.AbstractManualCommand`](#TradingPipeline.AbstractManualCommand)
- [`TechnicalIndicatorCharts.visualize`](#TechnicalIndicatorCharts.visualize-Tuple{Tuple{TechnicalIndicatorCharts.Chart,%20ExchangeOperations.AbstractSession}})
- [`TradingPipeline.PNL.pnl`](#TradingPipeline.PNL.pnl-Tuple{TradingPipeline.PNL.Short})
- [`TradingPipeline.PNL.pnl`](#TradingPipeline.PNL.pnl-Tuple{TradingPipeline.PNL.Long})
- [`TradingPipeline.PNL.qty`](#TradingPipeline.PNL.qty-Tuple{Contracts,%20Number})
- [`TradingPipeline.PNL.qty`](#TradingPipeline.PNL.qty-Tuple{Number,%20Number})
- [`TradingPipeline.Stops.set_subject!`](#TradingPipeline.Stops.set_subject!-Tuple{Rocket.AbstractSubject})
- [`TradingPipeline.around`](#TradingPipeline.around-Tuple{Dates.DateTime,%20DataFrames.AbstractDataFrame})
- [`TradingPipeline.decide`](#TradingPipeline.decide-Tuple{TradingPipeline.AbstractStrategy,%20TradingPipeline.MOS.Neutral})
- [`TradingPipeline.load_strategy`](#TradingPipeline.load_strategy-Tuple{Type{TradingPipeline.GoldenCrossStrategy}})
- [`TradingPipeline.load_strategy`](#TradingPipeline.load_strategy-Tuple{Type{TradingPipeline.HMAStrategy}})
- [`TradingPipeline.percent_diff`](#TradingPipeline.percent_diff-Tuple{Any,%20Any})
- [`TradingPipeline.report`](#TradingPipeline.report-Tuple{ExchangeOperations.SimulatorSession})
- [`TradingPipeline.simulate`](#TradingPipeline.simulate-Tuple{Any,%20Type{<:TradingPipeline.AbstractStrategy}})
- [`TradingPipeline.PNL.@pnl`](#TradingPipeline.PNL.@pnl-NTuple{4,%20Any})
- [`TradingPipeline.PNL.@pnls`](#TradingPipeline.PNL.@pnls-NTuple{4,%20Any})

<details class='jldocstring custom-block' open>
<summary><a id='TradingPipeline.PNL.pnl-Tuple{TradingPipeline.PNL.Long}' href='#TradingPipeline.PNL.pnl-Tuple{TradingPipeline.PNL.Long}'><span class="jlbinding">TradingPipeline.PNL.pnl</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
pnl(
    long::TradingPipeline.PNL.Long
) -> TradingPipeline.PNL.Result

```


Calculate profit/loss of a long position.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/g-gundam/TradingPipeline.jl/blob/2f33d4547167fb17b1d47b67654973f638d81fa7/src/pnl.jl#L56" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='TradingPipeline.PNL.pnl-Tuple{TradingPipeline.PNL.Short}' href='#TradingPipeline.PNL.pnl-Tuple{TradingPipeline.PNL.Short}'><span class="jlbinding">TradingPipeline.PNL.pnl</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
pnl(
    short::TradingPipeline.PNL.Short
) -> TradingPipeline.PNL.Result

```


Calculate profit/loss of a short position.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/g-gundam/TradingPipeline.jl/blob/2f33d4547167fb17b1d47b67654973f638d81fa7/src/pnl.jl#L72" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='TradingPipeline.PNL.qty-Tuple{Contracts, Number}' href='#TradingPipeline.PNL.qty-Tuple{Contracts, Number}'><span class="jlbinding">TradingPipeline.PNL.qty</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
qty(c::Contracts, price::Number)
```


Convert contracts into the equivalent quantity of the asset being traded.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/g-gundam/TradingPipeline.jl/blob/2f33d4547167fb17b1d47b67654973f638d81fa7/src/pnl.jl#L48-L52" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='TradingPipeline.PNL.qty-Tuple{Number, Number}' href='#TradingPipeline.PNL.qty-Tuple{Number, Number}'><span class="jlbinding">TradingPipeline.PNL.qty</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
qty(n::Number, price::Number)
```


This just returns n since the quantity `n`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/g-gundam/TradingPipeline.jl/blob/2f33d4547167fb17b1d47b67654973f638d81fa7/src/pnl.jl#L40-L44" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='TradingPipeline.PNL.@pnl-NTuple{4, Any}' href='#TradingPipeline.PNL.@pnl-NTuple{4, Any}'><span class="jlbinding">TradingPipeline.PNL.@pnl</span></a> <Badge type="info" class="jlObjectType jlMacro" text="Macro" /></summary>



```julia
@pnl entry exit quantity leverage
```


Calculate the profit/loss of a long positon.  The `quantity` and `leverage` are optional.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/g-gundam/TradingPipeline.jl/blob/2f33d4547167fb17b1d47b67654973f638d81fa7/src/pnl.jl#L105-L109" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='TradingPipeline.PNL.@pnls-NTuple{4, Any}' href='#TradingPipeline.PNL.@pnls-NTuple{4, Any}'><span class="jlbinding">TradingPipeline.PNL.@pnls</span></a> <Badge type="info" class="jlObjectType jlMacro" text="Macro" /></summary>



```julia
@pnls entry exit quantity leverage
```


Calculate the profit/loss of a short positon.  The `quantity` and `leverage` are optional.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/g-gundam/TradingPipeline.jl/blob/2f33d4547167fb17b1d47b67654973f638d81fa7/src/pnl.jl#L136-L140" target="_blank" rel="noreferrer">source</a></Badge>

</details>

