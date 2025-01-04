@kwdef mutable struct HMA2Strategy <: AbstractStrategy
    # read-only market state
    rf::ReversedFrame

    # mutable internal state
    is_late_entry::Bool = false
    entry_price::Float64 = 0.0

    # immutable (by gentleman's agreement) strategy configuration
    early_entry_percent = 3.0
    late_entry_percent = 8.5
    late_entry_close_percent = 6.0
end

function should_open_long(strategy::HMA2Strategy)
    rf = strategy.rf
    # Don't trade until numeric values for hma440 exist.
    if ismissing(rf.hma440[1])
        return false
    end
    
    # trade 3: try an alternate entry criteria so that it doesn't get classified as late
    if (crossed_up(rf.hma220, rf.hma440)
        && rf.c[1] > rf.hma440[1]
        && positive_slope_currently(rf.hma330)
        && percent_diff(rf.hma440[1], rf.c[1]) < strategy.early_entry_percent)
        @info :early_entry ts=rf.ts[1]
        return true
    end
    
    if (crossed_up(rf.hma330, rf.hma440))
        # trade 4 & 5: late entry criteria
        if percent_diff(rf.hma440[1], rf.c[1]) > strategy.late_entry_percent
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

function should_close_long(strategy::HMA2Strategy)
    rf = strategy.rf
    if strategy.is_late_entry
        return percent_diff(strategy.entry_price, rf.c[1]) > strategy.late_entry_close_percent
    end
    crossed_down(strategy.rf.hma330, strategy.rf.hma440)
end

function load_strategy(::Type{HMA2Strategy};
                       symbol="BTCUSD",
                       tf=Hour(4),
                       early_entry_percent=3.0,
                       late_entry_percent=8.6,
                       late_entry_close_percent=6.0)
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
    chart_subject = ChartSubject(;charts=all_charts)
    strategy = HMA2Strategy(;rf=ReversedFrame(hma_chart.df),
                            early_entry_percent,
                            late_entry_percent,
                            late_entry_close_percent)
    strategy_subject = StrategySubject(;strategy)
    return (chart_subject, strategy_subject)
end
