


# TradingPipeline {#TradingPipeline}
- Hello, how are you?
  
- DocumenterVitepress.jl generates very good-looking output.
  
- I forgot how to do so much though.
  

Documentation for [TradingPipeline](https://github.com/g-gundam/TradingPipeline.jl).
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
<summary><a id='TradingPipeline.simulate_sanity_check_failure_error' href='#TradingPipeline.simulate_sanity_check_failure_error'><span class="jlbinding">TradingPipeline.simulate_sanity_check_failure_error</span></a> <Badge type="info" class="jlObjectType jlConstant" text="Constant" /></summary>



`simulate_sanity_check_failure_error` is a tuple filled with a lot of nothing values so that code that&#39;s @unpack&#39;ing return values from `simulate()` don&#39;t crash.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/g-gundam/TradingPipeline.jl/blob/55f3b0d9101e749bc99704449879caadb80ca9e7/src/pipeline.jl#L19-L21" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='TradingPipeline.AbstractExchangeResponse' href='#TradingPipeline.AbstractExchangeResponse'><span class="jlbinding">TradingPipeline.AbstractExchangeResponse</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



An **AbstractExchangeResponse** represents a message that was received from an ExchangeFillSubject. The most common is **ExchangeFill** which lets the StrategySubject know that after putting out an intent to open or close a position, the exchange has filled the order and the requested position change has occurred.

**Example**

```julia
julia> subtypes(TradingPipeline.AbstractExchangeResponse)
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/g-gundam/TradingPipeline.jl/blob/55f3b0d9101e749bc99704449879caadb80ca9e7/src/rocket.jl#L47-L58" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='TradingPipeline.AbstractManualCommand' href='#TradingPipeline.AbstractManualCommand'><span class="jlbinding">TradingPipeline.AbstractManualCommand</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



An **AbstractManualCommand** represents a manual intervention from a human to the StrategySubject.

**Example**

```julia
julia> subtypes(TradingPipeline.AbstractExchangeResponse)
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/g-gundam/TradingPipeline.jl/blob/55f3b0d9101e749bc99704449879caadb80ca9e7/src/rocket.jl#L66-L74" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='TechnicalIndicatorCharts.visualize-Tuple{Tuple{TechnicalIndicatorCharts.Chart, ExchangeOperations.AbstractSession}}' href='#TechnicalIndicatorCharts.visualize-Tuple{Tuple{TechnicalIndicatorCharts.Chart, ExchangeOperations.AbstractSession}}'><span class="jlbinding">TechnicalIndicatorCharts.visualize</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
visualize(
    t::Tuple{TechnicalIndicatorCharts.Chart, ExchangeOperations.AbstractSession};
    kwargs...
) -> LightweightCharts.LWCLayout

```


Let&#39;s see if I can visualize trades on top of a chart.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/g-gundam/TradingPipeline.jl/blob/55f3b0d9101e749bc99704449879caadb80ca9e7/src/report.jl#L65" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='TradingPipeline.around-Tuple{Dates.DateTime, DataFrames.AbstractDataFrame}' href='#TradingPipeline.around-Tuple{Dates.DateTime, DataFrames.AbstractDataFrame}'><span class="jlbinding">TradingPipeline.around</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
around(
    ts::Dates.DateTime,
    df::DataFrames.AbstractDataFrame;
    before,
    after,
    ts_field
) -> Any

```


Return a few rows before and after the given timestamp `ts` in the DataFrame `df`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/g-gundam/TradingPipeline.jl/blob/55f3b0d9101e749bc99704449879caadb80ca9e7/src/explore.jl#L9" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='TradingPipeline.decide-Tuple{TradingPipeline.AbstractStrategy, TradingPipeline.MOS.Neutral}' href='#TradingPipeline.decide-Tuple{TradingPipeline.AbstractStrategy, TradingPipeline.MOS.Neutral}'><span class="jlbinding">TradingPipeline.decide</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
decide(strategy::AbstractStrategy, state::HSM.AbstractHsmState)
-> Union{Nothing, TradeDecision.T}
```


The decide method takes the current strategy and the current state according to the state machine, and looks at the market data available to it to make a decision.  Often, it decides to return `nothing`, but if conditions as defined by the strategy are met, it could return an `HSM.AbstractHsmEvent` which will cause the state machine to move to the next appropriate state.

There are decide methods for every state in the state machine.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/g-gundam/TradingPipeline.jl/blob/55f3b0d9101e749bc99704449879caadb80ca9e7/src/rocket.jl#L151-L163" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='TradingPipeline.load_strategy-Tuple{Type{TradingPipeline.GoldenCrossStrategy}}' href='#TradingPipeline.load_strategy-Tuple{Type{TradingPipeline.GoldenCrossStrategy}}'><span class="jlbinding">TradingPipeline.load_strategy</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



Initialize a long-only simple golden cross strategy.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/g-gundam/TradingPipeline.jl/blob/55f3b0d9101e749bc99704449879caadb80ca9e7/src/strategies/goldencross.jl#L26-L28" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='TradingPipeline.load_strategy-Tuple{Type{TradingPipeline.HMAStrategy}}' href='#TradingPipeline.load_strategy-Tuple{Type{TradingPipeline.HMAStrategy}}'><span class="jlbinding">TradingPipeline.load_strategy</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



Initialize a long-only hma strategy.
- Looking for 330/440 crosses
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/g-gundam/TradingPipeline.jl/blob/55f3b0d9101e749bc99704449879caadb80ca9e7/src/strategies/hma.jl#L20-L24" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='TradingPipeline.percent_diff-Tuple{Any, Any}' href='#TradingPipeline.percent_diff-Tuple{Any, Any}'><span class="jlbinding">TradingPipeline.percent_diff</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
percent_diff(a, b) -> Any

```


Return the percent difference between `a` and `b`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/g-gundam/TradingPipeline.jl/blob/55f3b0d9101e749bc99704449879caadb80ca9e7/src/util.jl#L3-L7" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='TradingPipeline.report-Tuple{ExchangeOperations.SimulatorSession}' href='#TradingPipeline.report-Tuple{ExchangeOperations.SimulatorSession}'><span class="jlbinding">TradingPipeline.report</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



report(session::XO.SimulatorSession) -&gt; DataFrame

Return a list of trades that happened during the simulator session.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/g-gundam/TradingPipeline.jl/blob/55f3b0d9101e749bc99704449879caadb80ca9e7/src/report.jl#L33-L37" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='TradingPipeline.simulate-Tuple{Any, Type{<:TradingPipeline.AbstractStrategy}}' href='#TradingPipeline.simulate-Tuple{Any, Type{<:TradingPipeline.AbstractStrategy}}'><span class="jlbinding">TradingPipeline.simulate</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
simulate(
    candle_observable,
    strategy_type::Type{<:TradingPipeline.AbstractStrategy};
    kwargs...
) -> Any

```


Run a strategy on the simulator using the given `candle_observable`.

**Return Values**

A named tuple with the following keys will be returned: `simulator_session`, `hsm`, `simultator_exchange_driver_subject`, `fill_observable`, `chart_subject`, `strategy_subject`, `simulator_session_actor`.

**Example**

```julia
julia> candle_observable = df_candles_observable(btcusd1m)
IterableObservable(Candle, Vector{Candle}, Rocket.AsapScheduler)

julia> @unpack simulator_session, chart_subject = simulate(candle_observable, HMAStrategy);
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/g-gundam/TradingPipeline.jl/blob/55f3b0d9101e749bc99704449879caadb80ca9e7/src/pipeline.jl#L40" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='TradingPipeline.Stops.set_subject!-Tuple{Rocket.AbstractSubject}' href='#TradingPipeline.Stops.set_subject!-Tuple{Rocket.AbstractSubject}'><span class="jlbinding">TradingPipeline.Stops.set_subject!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
set_subject!(subject::Rocket.AbstractSubject)
```


Mutate the subject of all TP.Stops state instances. This is my workaround for state machines being singletons.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/g-gundam/TradingPipeline.jl/blob/55f3b0d9101e749bc99704449879caadb80ca9e7/src/stops.jl#L45-L50" target="_blank" rel="noreferrer">source</a></Badge>

</details>

