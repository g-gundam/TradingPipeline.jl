### A Pluto.jl notebook ###
# v0.20.3

using Markdown
using InteractiveUtils

# ╔═╡ c7a73aca-78f4-402d-8199-48e83affac95
begin
	push!(LOAD_PATH, "../Project.toml")
	using TradingPipeline
	import TradingPipeline as TP
end

# ╔═╡ f3095108-14d2-492b-bff5-cd87395603a8
begin
	using Revise
	using PlutoUI
	using Rocket
	using Dates
	using DataFrames
	using Chain
	using UnPack
	using LightweightCharts
	using OnlineTechnicalIndicators

	using CryptoMarketData
	using TechnicalIndicatorCharts
	using ReversedSeries
	using ExchangeOperations
end

# ╔═╡ 14ee20f3-2742-41d7-b816-0bb2f143e226
md"""
# 01 HMA 4h Improvements
- I'm going to take the naive, long-only HMA cross strategy, and try to soften or eliminate some of its weak spots.
"""

# ╔═╡ 38bd1675-650f-4276-becb-216f3da6b630
md"""
# Data
"""

# ╔═╡ b2b6745d-4dd4-4a82-af6f-c1d0d791fc00
datadir = "../data"

# ╔═╡ ef255b70-795f-4052-9220-3e85f4b7061d
md"""
Those who really want to run this notebook themselves will need to download some data using [CryptoMarketData.jl](https://github.com/g-gundam/CryptoMarketData.jl) and put it in "$(datadir)" relative to the location of this notebook.  If you live outside of the US, you can probably skip the [proxy](https://g-gundam.github.io/CryptoMarketData.jl/dev/examples/#Proxies) part.

```julia-repl
julia> using CryptoMarketData

julia> http_options = Dict(:proxy => "http://user:password@proxyserver:3128")
Dict{Symbol, String} with 1 entry:
  :proxy => "http://user:password@proxyserver:3128"

julia> pancakeswap = PancakeSwap(http_options)
PancakeSwap("https://perp.pancakeswap.finance", Dict(:proxy => "http://user:password@proxyserver:3128"))

julia> save!(pancakeswap, "BTCUSD")
┌ Info: 2024-12-24
└   length(cs) = 1440
┌ Info: 2024-12-25
└   length(cs) = 1440
┌ Info: 2024-12-26
└   length(cs) = 1440
┌ Info: 2024-12-27
└   length(cs) = 1440
┌ Info: 2024-12-28
└   length(cs) = 1097
```
"""

# ╔═╡ 5ef635f6-52b7-4660-beea-bfcd67d67131
pancakeswap = PancakeSwap()

# ╔═╡ ed9771c3-9937-4122-9d43-c41ea94db033
btcusd1m = load(pancakeswap, "BTCUSD"; datadir, span=Date("2023-07-01"):Date("2024-11-29"));

# ╔═╡ db7ee608-5c9c-40db-9ba8-40159219b95b
candle_observable = TP.df_candles_observable(btcusd1m)

# ╔═╡ ef19c935-3270-46e3-97a0-8e874bb56643
md"""
# Simulator Sessions
"""

# ╔═╡ f93d3f19-3893-4c61-b383-04e1394e79ea
md"""
## TP.HMAStrategy - Base Line
"""

# ╔═╡ d5273d6f-6585-4e70-9b0b-533e4b0c2ed5
r = TP.simulate(candle_observable, TP.HMAStrategy; tf=Hour(4));

# ╔═╡ 52d6a457-041f-47e8-b9d4-660bb202155d
visualize((r.chart_subject.charts[:trend], r.simulator_session); min_height=800)

# ╔═╡ 5852651b-e16e-4f74-895c-9d85c5d122bf
rdf = TP.report(r.simulator_session)

# ╔═╡ 357359d5-bb87-4f82-ad3c-0195ecc53d17
rdf[4, :entry_ts]

# ╔═╡ ee1cfab6-5b47-4997-862f-eeab49230308
# wins
sum(filter(n -> n >= 0, rdf.pnl))

# ╔═╡ 2cb4800f-4924-4760-9d13-e96cecd9968f
# losses
sum(filter(n -> n < 0, rdf.pnl))

# ╔═╡ 8bf26867-59b1-47c6-a7af-ff63f06dd9c5
# total
sum(rdf.pnl)

# ╔═╡ 824d9b52-c6c6-4d7c-8775-a51f56eeda28
md"""
### Trade 2:  Should this be avoided?
- It was a small loss.
- There's nothing obviously terrible about the entry conditions.
- Maybe this is a loss we take.

### Trade 3:  Unintended consequences of late entry code
- This was a big win that turned into a small win due to the late entry criteria for trades 4 & 5.
- To solve this, I added an alternate entry using an hma220/hma440 cross and a few other criteria for safer entry.

### Trade 4 & 5:  Similar losses due to late entry
- I feel like these could have been turned into wins.
- They're both what I would call late entries where the 330/440 HMA cross happened way below the entry point.
- HMA440 was very far from the close price at entry time.
- They were also profitable for a while until they weren't.
"""

# ╔═╡ 69ef481d-a8c8-442b-a30a-501fb41c8516
md"""
>Investigating the distance from HMA440 to close price as criteria for late entry
"""

# ╔═╡ 5a5bc95b-5a79-4e41-8697-a263b2d88ddf
t4 = around(rdf[4, :entry_ts], r.chart_subject[:trend].df)

# ╔═╡ a618687b-a909-4057-8604-1cad820a867b
t5 = TP.around(rdf[5, :entry_ts], r.chart_subject[:trend].df)

# ╔═╡ 95a8b4d1-428c-43b5-afef-d2084b19fb82
md"""
>Trying to get an idea of potential gain
"""

# ╔═╡ 85fbdd77-deed-4470-bbf4-917fd941f595
t4high = around(DateTime("2024-05-21"), r.chart_subject[:trend].df)

# ╔═╡ e1318a87-e181-442d-b4d0-49531be21ee3
# This is the percentage increase of price from entry to a nearby peak.
# Late entry needs an early exit.
((t4high.h[2] - rdf[4, :entry_price]) / rdf[4, :entry_price]) * 100

# ╔═╡ eeb6ec32-5ad3-4235-bbd8-0c6f47de0c08
md"""
### Trade 6:  I think this can be avoided
- If price is under the 330 and 440 HMAs when the 330 crosses over the 440, don't open a long.
- Also, maybe look at the slope of the 330 and 440 HMAs.
  + Negative slopes are bad for long enry.
"""

# ╔═╡ e1b9d946-f59a-4db4-b20f-9f4d0626f45c
md"""
## HMA2Strategy - Taking Profit Sooner on Late Entries
"""

# ╔═╡ e85c116e-acfb-468c-b087-499111d33be1
@kwdef mutable struct HMA2Strategy <: TP.AbstractStrategy
	chart::Chart
	rf::ReversedFrame
	is_late_entry::Bool = false
	entry_price::Float64 = 0.0
end

# ╔═╡ fc6fd612-ab52-4298-b8f6-b4f1abb2525b
function percent_diff(a, b)
    ((b - a) / a) * 100
end

# ╔═╡ c852424f-0cc3-48e5-988b-5190f4d93001
percent_diff(t5[2, :hma440], t5[2, :c])

# ╔═╡ c149ff61-3df1-4ab1-b03f-563f456c88fc
percent_diff(t4[2, :hma440], t4[2, :c])

# ╔═╡ 45e75970-4627-4258-a1cd-a3cd028206b6
function TP.should_open_long(strategy::HMA2Strategy)
    rf = strategy.rf
	# Don't trade until numeric values for hma440 exist.
	if ismissing(rf.hma440[1])
		return false
	end
	
	# trade 3: try an alternate entry criteria so that it doesn't get classified as late
	if (crossed_up(rf.hma220, rf.hma440)
		&& rf.c[1] > rf.hma440[1]
		&& positive_slope_currently(rf.hma330)
	 	&& percent_diff(rf.hma440[1], rf.c[1]) < 3)
		@info :early_entry ts=rf.ts[1]
		return true
	end
	
	if (crossed_up(rf.hma330, rf.hma440))
		# trade 4 & 5: late entry criteria
		if percent_diff(rf.hma440[1], rf.c[1]) > 8.5
			strategy.is_late_entry = true
			strategy.entry_price = rf.c[1]
			@info :late_entry ts=rf.ts[1]
		else
			strategy.is_late_entry = false
		end

		# trade 6: avoid negative slope
		if rf.hma330[1] !== missing && rf.hma330[1] > rf.c[1] && negative_slope_currently(rf.hma330)
			@info :negative_slope ts=rf.ts[1]
			return false
		end

		# if we got this far, go long.
		return true
	else
		return false
	end
end

# ╔═╡ 0856646f-565f-45bd-a17e-9eac33c82c73
function TP.should_close_long(strategy::HMA2Strategy)
    rf = strategy.rf
    if strategy.is_late_entry
        return percent_diff(strategy.entry_price, rf.c[1]) > 6.0
	end
    crossed_down(strategy.rf.hma330, strategy.rf.hma440)
end

# ╔═╡ 001b7749-0a24-4461-9729-203a0e454c6b
function TP.load_strategy(::Type{HMA2Strategy}; symbol="BTCUSD", tf=Hour(4))
    hma_chart = Chart(
        symbol, tf,
        indicators = [
            HMA{Float64}(;period=55),
            HMA{Float64}(;period=110),
            HMA{Float64}(;period=220),
            HMA{Float64}(;period=330),
            HMA{Float64}(;period=440)
        ],
        visuals = [
            Dict(
                :label_name => "HMA 55",
                :line_color => "#e57373",
                :line_width => 2
            ),
            Dict(
                :label_name => "HMA 110",
                :line_color => "#f39337",
                :line_width => 1
            ),
            Dict(
                :label_name => "HMA 220",
                :line_color => "#ff6d00",
                :line_width => 2
            ),
            Dict(
                :label_name => "HMA 330",
                :line_color => "#26c6da",
                :line_width => 2
            ),
            Dict(
                :label_name => "HMA 440",
                :line_color => "#64b5f6",
                :line_width => 3
            )
        ]
    )
    all_charts = Dict(:trend => hma_chart)
    chart_subject = TP.ChartSubject(charts=all_charts)
    strategy = HMA2Strategy(chart=hma_chart, rf=ReversedFrame(hma_chart.df))
    strategy_subject = TP.StrategySubject(;strategy)
    return (chart_subject, strategy_subject)
end

# ╔═╡ 46c4e15a-89e7-4127-a48d-3caa7ea7a025
r2 = TP.simulate(candle_observable, HMA2Strategy);

# ╔═╡ 7914d77b-d1e4-4862-a802-445f22230bac
visualize((r2.chart_subject[:trend], r2.simulator_session); min_height=800)

# ╔═╡ ba956630-8be2-408a-928a-bbe3b34dc5a3
rdf2 = TP.report(r2.simulator_session)

# ╔═╡ 09e9d23c-1bb0-4fc2-956d-918e8cb583e0
# wins
sum(filter(n -> n >= 0, rdf2.pnl))

# ╔═╡ 70f1b5da-d433-4931-a10c-8fb77913bda0
# losses
sum(filter(n -> n < 0, rdf2.pnl))

# ╔═╡ 385d4772-0255-4fe8-a43c-01fe2cd1f644
# total
sum(rdf2.pnl)

# ╔═╡ 05fe72c2-d0a2-4d67-81df-17908c29c3c4
md"""
### Trade 3 Improved: Earlier entry
- An earlier entry at a lower price yielded an extra $4433.
"""

# ╔═╡ 871f3aaa-f334-4e26-9d89-2139fe8d5330
rdf[3, :]

# ╔═╡ 8a39b6d5-2d25-40ab-b228-eaab4f563b96
rdf2[3, :]

# ╔═╡ 79bdc784-e3cf-4772-b11a-94bcc42e913d
md"""
### Trade 4 Improved: Small loss to decent win
- Using the late-entry/early-exit criteria, a small loss was turned into a decent win.
"""

# ╔═╡ e0ec2d0f-709f-44ff-bfc9-117421ee91c1
rdf[4, :]

# ╔═╡ d18a6c22-c47f-47ff-af60-fd068e1aaa19
rdf2[4, :]

# ╔═╡ 4aa92651-1e2b-4c78-b330-5471cefd4e43
md"""
### Trade 5 Improved: Big loss to decent win
- The late-entry/early-exit criteria saved the trade.
"""

# ╔═╡ 7a7b3125-589e-44c0-aba2-47ac87809a3b
rdf[5, :]

# ╔═╡ ee115084-6f76-4b8e-abcd-680c927c6cb3
rdf2[5, :]

# ╔═╡ 55ec5c0f-95a5-4729-85a5-003058eab3b4
md"""
### Trade 6 Eliminated: Big loss to no loss
- A bad loss was easily avoided and turned into no loss.
"""

# ╔═╡ 4bef174a-558d-4ec0-9de0-9be1e3d42e53
rdf[6, :]

# ╔═╡ 208afea4-2dcf-4e1d-826c-81591cea9617
# This turned 7k in losses
sum(rdf.pnl[4:6])

# ╔═╡ 1d2c6d88-6dc9-4302-8ffc-90776c719cb0
# ...into 8k in wins.
sum(rdf2.pnl[4:5])

# ╔═╡ 396f5bec-0ec8-473f-b9bf-abe65a2b7d73
md"""
## HMABullFighterStrategy
- Who is brave (or stupid) enough to stand in front of a raging bull and open short positions?
- My exchange simulator is supposed to know how to short, but I haven't really tried it yet.
- This is going to be a short-only strategy that's meant to be run during bullish conditions.
- It's going to be very selective in its entries, and it's designed to take profit quickly and get back to safety.

*to be continued*
"""

# ╔═╡ c9217c78-a249-4f03-8a5e-fca4272a0559
@kwdef mutable struct HMABullFighterStrategy <: TP.AbstractStrategy
	rf::ReversedFrame
	srf::ReversedFrame
	entry_price::Float64 = 0.0
end

# ╔═╡ 9031f92e-4ca7-4302-adbe-d8bde9c96125
function TP.should_open_short(strategy::HMABullFighterStrategy)
	rf = strategy.rf
	srf = strategy.srf
	if ismissing(rf.hma440[1])
		return false
	end
	if (crossed_down_currently(rf.hma330, rf.hma440)
		#&& crossed_down_currently(srf.stochrsi_k, srf.stochrsi_d)
		&& rf.c[1] > rf.hma330[1]
		&& rf.c[1] < rf.hma440[1]
		&& negative_slope_currently(rf.hma330)
		&& negative_slope_currently(rf.hma440))
	
		strategy.entry_price = rf.c[1]
		return true
	end
	return false
end

# ╔═╡ 1b089aa4-8915-4f89-9de9-d50774a0f122
function TP.should_close_short(strategy::HMABullFighterStrategy)
	rf = strategy.rf
	if percent_diff(strategy.entry_price, rf.c[1]) <= -9.0
		return true
	end
	return crossed_up(rf.hma330, rf.hma440) # if this happens, absolutely get out
end

# ╔═╡ cce8abd8-24cc-4e32-97ed-d82f13733972
function TP.load_strategy(::Type{HMABullFighterStrategy}; symbol="BTCUSD", tf=Hour(4), stf=Hour(12))
    hma_chart = Chart(
        symbol, tf,
        indicators = [
            HMA{Float64}(;period=330),
            HMA{Float64}(;period=440)
        ],
        visuals = [
            Dict(
                :label_name => "HMA 330",
                :line_color => "#26c6da",
                :line_width => 2
            ),
            Dict(
                :label_name => "HMA 440",
                :line_color => "#64b5f6",
                :line_width => 3
            )
        ]
    )
	srsi_chart = Chart(
		symbol, stf,
		indicators = [ StochRSI{Float64}(;k_smoothing_period=5, d_smoothing_period=5)],
		visuals = [nothing]
	)
    all_charts = Dict(:trend => hma_chart, :srsi => srsi_chart)
    chart_subject = TP.ChartSubject(charts=all_charts)
    strategy = HMABullFighterStrategy(rf=ReversedFrame(hma_chart.df), srf=ReversedFrame(srsi_chart.df))
    strategy_subject = TP.StrategySubject(;strategy)
    return (chart_subject, strategy_subject)
end

# ╔═╡ 6e5dc20e-a640-491a-960f-53a8f440d776
r3 = TP.simulate(candle_observable, HMABullFighterStrategy);

# ╔═╡ 4f53788e-6b8a-457f-86a7-1ef2565503a5
visualize((r3.chart_subject.charts[:trend], r3.simulator_session); min_height=800)

# ╔═╡ bcc5e3ab-7f02-461f-af15-e152145b2a98
visualize((r3.chart_subject.charts[:srsi], r3.simulator_session); min_height=800)

# ╔═╡ 60abfce9-cb2a-4810-b7f6-27469833ad8a
r3.chart_subject.charts[:srsi].df

# ╔═╡ 9b5db1ac-f0d5-42d0-b344-6c72c19422b3
rdf3 = TP.report(r3.simulator_session)

# ╔═╡ 3942d492-d58a-4e0e-b4a0-7edaea463a22
sum(rdf3.pnl)

# ╔═╡ 7123d5f5-77ff-4231-97e7-be0064a82cf7
md"""
# Libraries
"""

# ╔═╡ dbfea1b0-d616-416a-a7d3-e1d59121071d
TableOfContents(;depth=3)

# ╔═╡ 533cd39c-bde7-11ef-127b-c917240c6f66
md"""
## Local Libraries
"""

# ╔═╡ db3b46c0-4f25-4a8e-ada2-00fad0e796d8
md"""
# CSS
"""

# ╔═╡ ab4805a4-1482-4531-90d2-b8ef0741c026
# https://discourse.julialang.org/t/cell-width-in-pluto-notebook/49761/11
html"""
<style>
  @media screen {
    main {
      margin: 0 auto;
      max-width: 2000px;
        padding-left: max(283px, 10%);
        padding-right: max(383px, 10%);
        # 383px to accomodate TableOfContents(aside=true)
    }
    .plutoui-toc.aside {
      width: min(80vw, 320px)
    }
  }
</style>
"""

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Chain = "8be319e6-bccf-4806-a6f7-6fae938471bc"
CryptoMarketData = "57973c84-8724-49d2-9af5-7f2266b21095"
DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
Dates = "ade2ca70-3891-5945-98fb-dc099432e06a"
ExchangeOperations = "48bbcad9-ae6a-4618-9eec-9c3ca8e1b15b"
LightweightCharts = "d6998af1-87ca-4e7f-83d4-864c79a249fa"
OnlineTechnicalIndicators = "dc2d07fb-478f-4566-8417-81bb3e5a7af1"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
ReversedSeries = "87ffe17a-2ae0-4c33-b274-0f3657b00e05"
Revise = "295af30f-e4ad-537b-8983-00126c2a3abe"
Rocket = "df971d30-c9d6-4b37-b8ff-e965b2cb3a40"
TechnicalIndicatorCharts = "ffc6123f-ba44-4b2f-a8ce-46f3306b22af"
UnPack = "3a884ed6-31ef-47d7-9d2a-63182c4928ed"

[compat]
Chain = "~0.6.0"
CryptoMarketData = "~1.0.5"
DataFrames = "~1.7.0"
ExchangeOperations = "~0.0.1"
LightweightCharts = "~2.3.0"
OnlineTechnicalIndicators = "~0.1.0"
PlutoUI = "~0.7.60"
ReversedSeries = "~1.1.1"
Revise = "~3.6.4"
Rocket = "~1.8.1"
TechnicalIndicatorCharts = "~0.6.1"
UnPack = "~1.0.2"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.11.2"
manifest_format = "2.0"
project_hash = "e9d031611757033ef19297aead99e69df4335457"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "6e1d2a35f2f90a4bc7c2ed98079b2ba09c35b83a"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.3.2"

[[deps.AbstractTrees]]
git-tree-sha1 = "2d9c9a55f9c93e8887ad391fbae72f8ef55e1177"
uuid = "1520ce14-60c1-5f80-bbc7-55ef81b5835c"
version = "0.4.5"

[[deps.AliasTables]]
deps = ["PtrArrays", "Random"]
git-tree-sha1 = "9876e1e164b144ca45e9e3198d0b689cadfed9ff"
uuid = "66dad0bd-aa9a-41b7-9441-69ab47430ed8"
version = "1.1.3"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.2"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"
version = "1.11.0"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"
version = "1.11.0"

[[deps.BitFlags]]
git-tree-sha1 = "0691e34b3bb8be9307330f88d1a3c3f25466c24d"
uuid = "d1d4a3ce-64b1-5f1a-9ba4-7e7e69966f35"
version = "0.1.9"

[[deps.CSV]]
deps = ["CodecZlib", "Dates", "FilePathsBase", "InlineStrings", "Mmap", "Parsers", "PooledArrays", "PrecompileTools", "SentinelArrays", "Tables", "Unicode", "WeakRefStrings", "WorkerUtilities"]
git-tree-sha1 = "deddd8725e5e1cc49ee205a1964256043720a6c3"
uuid = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
version = "0.10.15"

[[deps.Chain]]
git-tree-sha1 = "9ae9be75ad8ad9d26395bf625dea9beac6d519f1"
uuid = "8be319e6-bccf-4806-a6f7-6fae938471bc"
version = "0.6.0"

[[deps.CodeTracking]]
deps = ["InteractiveUtils", "UUIDs"]
git-tree-sha1 = "7eee164f122511d3e4e1ebadb7956939ea7e1c77"
uuid = "da1fd8a2-8d9e-5ec2-8556-3022fb5608a2"
version = "1.3.6"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "bce6804e5e6044c6daab27bb533d1295e4a2e759"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.6"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "b10d0b65641d57b8b4d5e234446582de5047050d"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.5"

[[deps.Compat]]
deps = ["TOML", "UUIDs"]
git-tree-sha1 = "8ae8d32e09f0dcf42a36b90d4e17f5dd2e4c4215"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.16.0"
weakdeps = ["Dates", "LinearAlgebra"]

    [deps.Compat.extensions]
    CompatLinearAlgebraExt = "LinearAlgebra"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.1.1+0"

[[deps.ConcurrentUtilities]]
deps = ["Serialization", "Sockets"]
git-tree-sha1 = "f36e5e8fdffcb5646ea5da81495a5a7566005127"
uuid = "f0e56b4a-5159-44fe-b623-3e5288b988bb"
version = "2.4.3"

[[deps.Crayons]]
git-tree-sha1 = "249fe38abf76d48563e2f4556bebd215aa317e15"
uuid = "a8cc5b0e-0ffa-5ad4-8c14-923d3ee1735f"
version = "4.1.1"

[[deps.CryptoMarketData]]
deps = ["CSV", "DataFrames", "DataFramesMeta", "DataStructures", "Dates", "DocStringExtensions", "HTTP", "JSON3", "NanoDates", "Nullables", "Printf", "TidyTest", "TimeZones", "URIs"]
git-tree-sha1 = "2e87dba03062ce16bd9db62f180fe0a60f77e732"
uuid = "57973c84-8724-49d2-9af5-7f2266b21095"
version = "1.0.5"

[[deps.DataAPI]]
git-tree-sha1 = "abe83f3a2f1b857aac70ef8b269080af17764bbe"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.16.0"

[[deps.DataFrames]]
deps = ["Compat", "DataAPI", "DataStructures", "Future", "InlineStrings", "InvertedIndices", "IteratorInterfaceExtensions", "LinearAlgebra", "Markdown", "Missings", "PooledArrays", "PrecompileTools", "PrettyTables", "Printf", "Random", "Reexport", "SentinelArrays", "SortingAlgorithms", "Statistics", "TableTraits", "Tables", "Unicode"]
git-tree-sha1 = "fb61b4812c49343d7ef0b533ba982c46021938a6"
uuid = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
version = "1.7.0"

[[deps.DataFramesMeta]]
deps = ["Chain", "DataFrames", "MacroTools", "OrderedCollections", "Reexport", "TableMetadataTools"]
git-tree-sha1 = "21a4335f249f8b5f311d00d5e62938b50ccace4e"
uuid = "1313f7d8-7da2-5740-9ea0-a2ca25f37964"
version = "0.15.4"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "1d0a14036acb104d9e89698bd408f63ab58cdc82"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.20"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"
version = "1.11.0"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"
version = "1.11.0"

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "2fb1e02f2b635d0845df5d7c167fec4dd739b00d"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.3"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.EnumX]]
git-tree-sha1 = "bdb1942cd4c45e3c678fd11569d5cccd80976237"
uuid = "4e289a0a-7415-4d19-859d-a7e5c4648b56"
version = "1.0.4"

[[deps.ExceptionUnwrapping]]
deps = ["Test"]
git-tree-sha1 = "d36f682e590a83d63d1c7dbd287573764682d12a"
uuid = "460bff9d-24e4-43bc-9d9f-a8973cb893f4"
version = "0.1.11"

[[deps.ExchangeOperations]]
deps = ["Dates", "DocStringExtensions", "EnumX", "HTTP", "NanoDates", "Random", "TidyTest", "UUIDs", "Web3"]
git-tree-sha1 = "538c5ba61d62ebbf71d2d9cf1e8cb63c7d50f266"
uuid = "48bbcad9-ae6a-4618-9eec-9c3ca8e1b15b"
version = "0.0.1"

[[deps.ExprTools]]
git-tree-sha1 = "27415f162e6028e81c72b82ef756bf321213b6ec"
uuid = "e2ba6199-217a-4e67-a87a-7c52f15ade04"
version = "0.1.10"

[[deps.EzXML]]
deps = ["Printf", "XML2_jll"]
git-tree-sha1 = "380053d61bb9064d6aa4a9777413b40429c79901"
uuid = "8f5d6c58-4d21-5cfd-889c-e3ad7ee6a615"
version = "1.2.0"

[[deps.FilePathsBase]]
deps = ["Compat", "Dates"]
git-tree-sha1 = "7878ff7172a8e6beedd1dea14bd27c3c6340d361"
uuid = "48062228-2e41-5def-b9a4-89aafe57970f"
version = "0.9.22"
weakdeps = ["Mmap", "Test"]

    [deps.FilePathsBase.extensions]
    FilePathsBaseMmapExt = "Mmap"
    FilePathsBaseTestExt = "Test"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"
version = "1.11.0"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "05882d6995ae5c12bb5f36dd2ed3f61c98cbb172"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.5"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"
version = "1.11.0"

[[deps.HTTP]]
deps = ["Base64", "CodecZlib", "ConcurrentUtilities", "Dates", "ExceptionUnwrapping", "Logging", "LoggingExtras", "MbedTLS", "NetworkOptions", "OpenSSL", "PrecompileTools", "Random", "SimpleBufferStream", "Sockets", "URIs", "UUIDs"]
git-tree-sha1 = "c67b33b085f6e2faf8bf79a61962e7339a81129c"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "1.10.15"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "179267cfa5e712760cd43dcae385d7ea90cc25a4"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.5"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "7134810b1afce04bbc1045ca1985fbe81ce17653"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.5"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "b6d6bfdd7ce25b0f9b2f6b3dd56b2673a66c8770"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.5"

[[deps.InlineStrings]]
git-tree-sha1 = "45521d31238e87ee9f9732561bfee12d4eebd52d"
uuid = "842dd82b-1e85-43dc-bf29-5d0ee9dffc48"
version = "1.4.2"

    [deps.InlineStrings.extensions]
    ArrowTypesExt = "ArrowTypes"
    ParsersExt = "Parsers"

    [deps.InlineStrings.weakdeps]
    ArrowTypes = "31f734f8-188a-4ce0-8406-c8a06bd891cd"
    Parsers = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"
version = "1.11.0"

[[deps.InvertedIndices]]
git-tree-sha1 = "6da3c4316095de0f5ee2ebd875df8721e7e0bdbe"
uuid = "41ab1584-1d38-5bbf-9106-f11c6c58b48f"
version = "1.3.1"

[[deps.IrrationalConstants]]
git-tree-sha1 = "630b497eafcc20001bba38a4651b327dcfc491d2"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.2.2"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLLWrappers]]
deps = ["Artifacts", "Preferences"]
git-tree-sha1 = "a007feb38b422fbdab534406aeca1b86823cb4d6"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.7.0"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "31e996f0a15c7b280ba9f76636b3ff9e2ae58c9a"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.4"

[[deps.JSON3]]
deps = ["Dates", "Mmap", "Parsers", "PrecompileTools", "StructTypes", "UUIDs"]
git-tree-sha1 = "1d322381ef7b087548321d3f878cb4c9bd8f8f9b"
uuid = "0f8b85d8-7281-11e9-16c2-39a750bddbf1"
version = "1.14.1"

    [deps.JSON3.extensions]
    JSON3ArrowExt = ["ArrowTypes"]

    [deps.JSON3.weakdeps]
    ArrowTypes = "31f734f8-188a-4ce0-8406-c8a06bd891cd"

[[deps.JuliaInterpreter]]
deps = ["CodeTracking", "InteractiveUtils", "Random", "UUIDs"]
git-tree-sha1 = "10da5154188682e5c0726823c2b5125957ec3778"
uuid = "aa1ae85d-cabe-5617-a682-6adf51b2e16a"
version = "0.9.38"

[[deps.LaTeXStrings]]
git-tree-sha1 = "dda21b8cbd6a6c40d9d02a73230f9d70fed6918c"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.4.0"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.4"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "8.6.0+0"

[[deps.LibGit2]]
deps = ["Base64", "LibGit2_jll", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"
version = "1.11.0"

[[deps.LibGit2_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll"]
uuid = "e37daf67-58a4-590a-8e99-b0245dd2ffc5"
version = "1.7.2+0"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.11.0+1"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"
version = "1.11.0"

[[deps.Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "61dfdba58e585066d8bce214c5a51eaa0539f269"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.17.0+1"

[[deps.LightweightCharts]]
deps = ["Dates", "NanoDates", "Serde"]
git-tree-sha1 = "c9ee490f9c6bc5769082521979ced6e6db2f1e5b"
uuid = "d6998af1-87ca-4e7f-83d4-864c79a249fa"
version = "2.3.0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
version = "1.11.0"

[[deps.LogExpFunctions]]
deps = ["DocStringExtensions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "13ca9e2586b89836fd20cccf56e57e2b9ae7f38f"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.29"

    [deps.LogExpFunctions.extensions]
    LogExpFunctionsChainRulesCoreExt = "ChainRulesCore"
    LogExpFunctionsChangesOfVariablesExt = "ChangesOfVariables"
    LogExpFunctionsInverseFunctionsExt = "InverseFunctions"

    [deps.LogExpFunctions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    ChangesOfVariables = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"
version = "1.11.0"

[[deps.LoggingExtras]]
deps = ["Dates", "Logging"]
git-tree-sha1 = "f02b56007b064fbfddb4c9cd60161b6dd0f40df3"
uuid = "e6f89c97-d47a-5376-807f-9c37f3926c36"
version = "1.1.0"

[[deps.LoweredCodeUtils]]
deps = ["JuliaInterpreter"]
git-tree-sha1 = "688d6d9e098109051ae33d126fcfc88c4ce4a021"
uuid = "6f1432cf-f94c-5a45-995e-cdbf5db27b0b"
version = "3.1.0"

[[deps.MIMEs]]
git-tree-sha1 = "65f28ad4b594aebe22157d6fac869786a255b7eb"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "0.1.4"

[[deps.MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "2fa9ee3e63fd3a4f7a9a4f4744a52f4856de82df"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.13"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"
version = "1.11.0"

[[deps.MbedTLS]]
deps = ["Dates", "MbedTLS_jll", "MozillaCACerts_jll", "NetworkOptions", "Random", "Sockets"]
git-tree-sha1 = "c067a280ddc25f196b5e7df3877c6b226d390aaf"
uuid = "739be429-bea8-5141-9913-cc70e7f3736d"
version = "1.1.9"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.6+0"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "ec4f7fbeab05d7747bdf98eb74d130a2a2ed298d"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.2.0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"
version = "1.11.0"

[[deps.Mocking]]
deps = ["Compat", "ExprTools"]
git-tree-sha1 = "2c140d60d7cb82badf06d8783800d0bcd1a7daa2"
uuid = "78c3b35d-d492-501b-9361-3d52fe80e533"
version = "0.8.1"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2023.12.12"

[[deps.NanoDates]]
deps = ["Dates", "Parsers"]
git-tree-sha1 = "850a0557ae5934f6e67ac0dc5ca13d0328422d1f"
uuid = "46f1a544-deae-4307-8689-c12aa3c955c6"
version = "1.0.3"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.Nullables]]
git-tree-sha1 = "8f87854cc8f3685a60689d8edecaa29d2251979b"
uuid = "4d1e1d77-625e-5b40-9113-a560ec7a8ecd"
version = "1.0.0"

[[deps.OnlineStatsBase]]
deps = ["AbstractTrees", "Dates", "LinearAlgebra", "OrderedCollections", "Statistics", "StatsBase"]
git-tree-sha1 = "a5a5a68d079ce531b0220e99789e0c1c8c5ed215"
uuid = "925886fa-5bf2-5e8e-b522-a9147a512338"
version = "1.7.1"

[[deps.OnlineTechnicalIndicators]]
deps = ["Dates", "OnlineStatsBase", "Tables"]
git-tree-sha1 = "bff61d307678117081d09d291c2e356bdfd980a7"
uuid = "dc2d07fb-478f-4566-8417-81bb3e5a7af1"
version = "0.1.0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.27+1"

[[deps.OpenSSL]]
deps = ["BitFlags", "Dates", "MozillaCACerts_jll", "OpenSSL_jll", "Sockets"]
git-tree-sha1 = "38cb508d080d21dc1128f7fb04f20387ed4c0af4"
uuid = "4d8831e6-92b7-49fb-bdf8-b643e874388c"
version = "1.4.3"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "f58782a883ecbf9fb48dcd363f9ccd65f36c23a8"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "3.0.15+2"

[[deps.OrderedCollections]]
git-tree-sha1 = "12f1439c4f986bb868acda6ea33ebc78e19b95ad"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.7.0"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "8489905bcdbcfac64d1daa51ca07c0d8f0283821"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.8.1"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "Random", "SHA", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.11.0"
weakdeps = ["REPL"]

    [deps.Pkg.extensions]
    REPLExt = "REPL"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "eba4810d5e6a01f612b948c9fa94f905b49087b0"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.60"

[[deps.PooledArrays]]
deps = ["DataAPI", "Future"]
git-tree-sha1 = "36d8b4b899628fb92c2749eb488d884a926614d3"
uuid = "2dfb63ee-cc39-5dd5-95bd-886bf059d720"
version = "1.4.3"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "5aa36f7049a63a1528fe8f7c3f2113413ffd4e1f"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.2.1"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "9306f6085165d270f7e3db02af26a400d580f5c6"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.4.3"

[[deps.PrettyTables]]
deps = ["Crayons", "LaTeXStrings", "Markdown", "PrecompileTools", "Printf", "Reexport", "StringManipulation", "Tables"]
git-tree-sha1 = "1101cd475833706e4d0e7b122218257178f48f34"
uuid = "08abe8d2-0d0c-5749-adfa-8a2ac140af0d"
version = "2.4.0"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"
version = "1.11.0"

[[deps.ProgressMeter]]
deps = ["Distributed", "Printf"]
git-tree-sha1 = "8f6bc219586aef8baf0ff9a5fe16ee9c70cb65e4"
uuid = "92933f4c-e287-5a05-a399-4b506db050ca"
version = "1.10.2"

[[deps.PtrArrays]]
git-tree-sha1 = "77a42d78b6a92df47ab37e177b2deac405e1c88f"
uuid = "43287f4e-b6f4-7ad1-bb20-aadabca52c3d"
version = "1.2.1"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "StyledStrings", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"
version = "1.11.0"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
version = "1.11.0"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "838a3a4188e2ded87a4f9f184b4b0d78a1e91cb7"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.0"

[[deps.ReversedSeries]]
deps = ["Chain", "DataFrames", "DataStructures", "Dates", "DocStringExtensions", "TidyTest"]
git-tree-sha1 = "6fd19670d521479db2b3f76b4a066b72c4582146"
uuid = "87ffe17a-2ae0-4c33-b274-0f3657b00e05"
version = "1.1.1"

[[deps.Revise]]
deps = ["CodeTracking", "Distributed", "FileWatching", "JuliaInterpreter", "LibGit2", "LoweredCodeUtils", "OrderedCollections", "REPL", "Requires", "UUIDs", "Unicode"]
git-tree-sha1 = "470f48c9c4ea2170fd4d0f8eb5118327aada22f5"
uuid = "295af30f-e4ad-537b-8983-00126c2a3abe"
version = "3.6.4"

[[deps.Rocket]]
deps = ["DataStructures", "Sockets", "Unrolled"]
git-tree-sha1 = "c405231d77d3ff6c9eb6dc2da48147e761888ac1"
uuid = "df971d30-c9d6-4b37-b8ff-e965b2cb3a40"
version = "1.8.1"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Scratch]]
deps = ["Dates"]
git-tree-sha1 = "3bac05bc7e74a75fd9cba4295cde4045d9fe2386"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.2.1"

[[deps.SentinelArrays]]
deps = ["Dates", "Random"]
git-tree-sha1 = "712fb0231ee6f9120e005ccd56297abbc053e7e0"
uuid = "91c51154-3ec4-41a3-a24f-3f23e20d615c"
version = "1.4.8"

[[deps.Serde]]
deps = ["CSV", "Dates", "EzXML", "JSON", "TOML", "UUIDs", "YAML"]
git-tree-sha1 = "61746bae631f17bfde03ae69445df5ec0a4e1aef"
uuid = "db9b398d-9517-45f8-9a95-92af99003e0e"
version = "3.4.1"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"
version = "1.11.0"

[[deps.SimpleBufferStream]]
git-tree-sha1 = "f305871d2f381d21527c770d4788c06c097c9bc1"
uuid = "777ac1f9-54b0-4bf8-805c-2214025038e7"
version = "1.2.0"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"
version = "1.11.0"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "66e0a8e672a0bdfca2c3f5937efb8538b9ddc085"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.2.1"

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
version = "1.11.0"

[[deps.Statistics]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "ae3bb1eb3bba077cd276bc5cfc337cc65c3075c0"
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.11.1"
weakdeps = ["SparseArrays"]

    [deps.Statistics.extensions]
    SparseArraysExt = ["SparseArrays"]

[[deps.StatsAPI]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1ff449ad350c9c4cbc756624d6f8a8c3ef56d3ed"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.7.0"

[[deps.StatsBase]]
deps = ["AliasTables", "DataAPI", "DataStructures", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "29321314c920c26684834965ec2ce0dacc9cf8e5"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.34.4"

[[deps.StringEncodings]]
deps = ["Libiconv_jll"]
git-tree-sha1 = "b765e46ba27ecf6b44faf70df40c57aa3a547dcb"
uuid = "69024149-9ee7-55f6-a4c4-859efe599b68"
version = "0.3.7"

[[deps.StringManipulation]]
deps = ["PrecompileTools"]
git-tree-sha1 = "a6b1675a536c5ad1a60e5a5153e1fee12eb146e3"
uuid = "892a3eda-7b42-436c-8928-eab12a02cf0e"
version = "0.4.0"

[[deps.StructTypes]]
deps = ["Dates", "UUIDs"]
git-tree-sha1 = "159331b30e94d7b11379037feeb9b690950cace8"
uuid = "856f2bd8-1eba-4b0a-8007-ebc267875bd4"
version = "1.11.0"

[[deps.StyledStrings]]
uuid = "f489334b-da3d-4c2e-b8f0-e476e12c162b"
version = "1.11.0"

[[deps.SuiteSparse_jll]]
deps = ["Artifacts", "Libdl", "libblastrampoline_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"
version = "7.7.0+0"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.TZJData]]
deps = ["Artifacts"]
git-tree-sha1 = "006a327222dda856e2304959e566ff0104ac8594"
uuid = "dc5dba14-91b3-4cab-a142-028a31da12f7"
version = "1.3.1+2024b"

[[deps.TableMetadataTools]]
deps = ["DataAPI", "Dates", "TOML", "Tables", "Unitful"]
git-tree-sha1 = "c0405d3f8189bb9a9755e429c6ea2138fca7e31f"
uuid = "9ce81f87-eacc-4366-bf80-b621a3098ee2"
version = "0.1.0"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "OrderedCollections", "TableTraits"]
git-tree-sha1 = "598cd7c1f68d1e205689b1c2fe65a9f85846f297"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.12.0"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.TechnicalIndicatorCharts]]
deps = ["Chain", "DataFrames", "DataFramesMeta", "DataStructures", "Dates", "DocStringExtensions", "LightweightCharts", "NanoDates", "OnlineTechnicalIndicators", "TidyTest"]
git-tree-sha1 = "10378437c3eb164256f573773441e81e23ddd138"
uuid = "ffc6123f-ba44-4b2f-a8ce-46f3306b22af"
version = "0.6.1"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"
version = "1.11.0"

[[deps.TidyTest]]
deps = ["ProgressMeter", "Reexport", "Test"]
git-tree-sha1 = "e87dd4db778a4cf1adf3f60d5df0084acbde6234"
uuid = "ef104744-fcb3-4e7e-8bb2-6e95860d81ed"
version = "0.1.1"

[[deps.TimeZones]]
deps = ["Artifacts", "Dates", "Downloads", "InlineStrings", "Mocking", "Printf", "Scratch", "TZJData", "Unicode", "p7zip_jll"]
git-tree-sha1 = "fcbcffdc11524d08523e92ae52214b29d90b50bb"
uuid = "f269a46b-ccf7-5d73-abea-4c690281aa53"
version = "1.20.0"

    [deps.TimeZones.extensions]
    TimeZonesRecipesBaseExt = "RecipesBase"

    [deps.TimeZones.weakdeps]
    RecipesBase = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"

[[deps.TranscodingStreams]]
git-tree-sha1 = "0c45878dcfdcfa8480052b6ab162cdd138781742"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.11.3"

[[deps.Tricks]]
git-tree-sha1 = "7822b97e99a1672bfb1b49b668a6d46d58d8cbcb"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.9"

[[deps.URIs]]
git-tree-sha1 = "67db6cc7b3821e19ebe75791a9dd19c9b1188f2b"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.5.1"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"
version = "1.11.0"

[[deps.UnPack]]
git-tree-sha1 = "387c1f73762231e86e0c9c5443ce3b4a0a9a0c2b"
uuid = "3a884ed6-31ef-47d7-9d2a-63182c4928ed"
version = "1.0.2"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"
version = "1.11.0"

[[deps.Unitful]]
deps = ["Dates", "LinearAlgebra", "Random"]
git-tree-sha1 = "01915bfcd62be15329c9a07235447a89d588327c"
uuid = "1986cc42-f94f-5a68-af5c-568840ba703d"
version = "1.21.1"

    [deps.Unitful.extensions]
    ConstructionBaseUnitfulExt = "ConstructionBase"
    InverseFunctionsUnitfulExt = "InverseFunctions"

    [deps.Unitful.weakdeps]
    ConstructionBase = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"

[[deps.Unrolled]]
deps = ["MacroTools"]
git-tree-sha1 = "6cc9d682755680e0f0be87c56392b7651efc2c7b"
uuid = "9602ed7d-8fef-5bc8-8597-8f21381861e8"
version = "0.1.5"

[[deps.WeakRefStrings]]
deps = ["DataAPI", "InlineStrings", "Parsers"]
git-tree-sha1 = "b1be2855ed9ed8eac54e5caff2afcdb442d52c23"
uuid = "ea10d353-3f73-51f8-a26c-33c1cb351aa5"
version = "1.4.2"

[[deps.Web3]]
deps = ["HTTP", "JSON"]
git-tree-sha1 = "dd49b6fe70e7f70ecfefd2c47216c205f89f1c47"
uuid = "0881af41-a624-557c-96ff-9a730c8d7287"
version = "0.2.5"

[[deps.WorkerUtilities]]
git-tree-sha1 = "cd1659ba0d57b71a464a29e64dbc67cfe83d54e7"
uuid = "76eceee3-57b5-4d4a-8e66-0e911cebbf60"
version = "1.6.1"

[[deps.XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Zlib_jll"]
git-tree-sha1 = "a2fccc6559132927d4c5dc183e3e01048c6dcbd6"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.13.5+0"

[[deps.YAML]]
deps = ["Base64", "Dates", "Printf", "StringEncodings"]
git-tree-sha1 = "dea63ff72079443240fbd013ba006bcbc8a9ac00"
uuid = "ddb6d928-2868-570f-bddf-ab3f9cf99eb6"
version = "0.4.12"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.13+1"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.11.0+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.59.0+0"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+2"
"""

# ╔═╡ Cell order:
# ╟─14ee20f3-2742-41d7-b816-0bb2f143e226
# ╟─38bd1675-650f-4276-becb-216f3da6b630
# ╟─ef255b70-795f-4052-9220-3e85f4b7061d
# ╠═b2b6745d-4dd4-4a82-af6f-c1d0d791fc00
# ╠═5ef635f6-52b7-4660-beea-bfcd67d67131
# ╠═ed9771c3-9937-4122-9d43-c41ea94db033
# ╠═db7ee608-5c9c-40db-9ba8-40159219b95b
# ╟─ef19c935-3270-46e3-97a0-8e874bb56643
# ╟─f93d3f19-3893-4c61-b383-04e1394e79ea
# ╠═d5273d6f-6585-4e70-9b0b-533e4b0c2ed5
# ╠═52d6a457-041f-47e8-b9d4-660bb202155d
# ╠═5852651b-e16e-4f74-895c-9d85c5d122bf
# ╠═357359d5-bb87-4f82-ad3c-0195ecc53d17
# ╠═ee1cfab6-5b47-4997-862f-eeab49230308
# ╠═2cb4800f-4924-4760-9d13-e96cecd9968f
# ╠═8bf26867-59b1-47c6-a7af-ff63f06dd9c5
# ╟─824d9b52-c6c6-4d7c-8775-a51f56eeda28
# ╟─69ef481d-a8c8-442b-a30a-501fb41c8516
# ╠═5a5bc95b-5a79-4e41-8697-a263b2d88ddf
# ╠═a618687b-a909-4057-8604-1cad820a867b
# ╠═c852424f-0cc3-48e5-988b-5190f4d93001
# ╠═c149ff61-3df1-4ab1-b03f-563f456c88fc
# ╟─95a8b4d1-428c-43b5-afef-d2084b19fb82
# ╠═85fbdd77-deed-4470-bbf4-917fd941f595
# ╠═e1318a87-e181-442d-b4d0-49531be21ee3
# ╟─eeb6ec32-5ad3-4235-bbd8-0c6f47de0c08
# ╟─e1b9d946-f59a-4db4-b20f-9f4d0626f45c
# ╠═e85c116e-acfb-468c-b087-499111d33be1
# ╠═fc6fd612-ab52-4298-b8f6-b4f1abb2525b
# ╠═45e75970-4627-4258-a1cd-a3cd028206b6
# ╠═0856646f-565f-45bd-a17e-9eac33c82c73
# ╠═001b7749-0a24-4461-9729-203a0e454c6b
# ╠═46c4e15a-89e7-4127-a48d-3caa7ea7a025
# ╠═7914d77b-d1e4-4862-a802-445f22230bac
# ╠═ba956630-8be2-408a-928a-bbe3b34dc5a3
# ╠═09e9d23c-1bb0-4fc2-956d-918e8cb583e0
# ╠═70f1b5da-d433-4931-a10c-8fb77913bda0
# ╠═385d4772-0255-4fe8-a43c-01fe2cd1f644
# ╟─05fe72c2-d0a2-4d67-81df-17908c29c3c4
# ╠═871f3aaa-f334-4e26-9d89-2139fe8d5330
# ╠═8a39b6d5-2d25-40ab-b228-eaab4f563b96
# ╟─79bdc784-e3cf-4772-b11a-94bcc42e913d
# ╠═e0ec2d0f-709f-44ff-bfc9-117421ee91c1
# ╠═d18a6c22-c47f-47ff-af60-fd068e1aaa19
# ╟─4aa92651-1e2b-4c78-b330-5471cefd4e43
# ╠═7a7b3125-589e-44c0-aba2-47ac87809a3b
# ╠═ee115084-6f76-4b8e-abcd-680c927c6cb3
# ╟─55ec5c0f-95a5-4729-85a5-003058eab3b4
# ╠═4bef174a-558d-4ec0-9de0-9be1e3d42e53
# ╠═208afea4-2dcf-4e1d-826c-81591cea9617
# ╠═1d2c6d88-6dc9-4302-8ffc-90776c719cb0
# ╟─396f5bec-0ec8-473f-b9bf-abe65a2b7d73
# ╠═c9217c78-a249-4f03-8a5e-fca4272a0559
# ╠═9031f92e-4ca7-4302-adbe-d8bde9c96125
# ╠═1b089aa4-8915-4f89-9de9-d50774a0f122
# ╠═cce8abd8-24cc-4e32-97ed-d82f13733972
# ╠═6e5dc20e-a640-491a-960f-53a8f440d776
# ╠═4f53788e-6b8a-457f-86a7-1ef2565503a5
# ╠═bcc5e3ab-7f02-461f-af15-e152145b2a98
# ╠═60abfce9-cb2a-4810-b7f6-27469833ad8a
# ╠═9b5db1ac-f0d5-42d0-b344-6c72c19422b3
# ╠═3942d492-d58a-4e0e-b4a0-7edaea463a22
# ╟─7123d5f5-77ff-4231-97e7-be0064a82cf7
# ╠═f3095108-14d2-492b-bff5-cd87395603a8
# ╠═dbfea1b0-d616-416a-a7d3-e1d59121071d
# ╟─533cd39c-bde7-11ef-127b-c917240c6f66
# ╠═c7a73aca-78f4-402d-8199-48e83affac95
# ╟─db3b46c0-4f25-4a8e-ada2-00fad0e796d8
# ╠═ab4805a4-1482-4531-90d2-b8ef0741c026
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
