# Here you'll find functions meant to be interactively
# during data exploration
# either in Pluto.jl or the REPL.

using Dates
using DataFrames
using DocStringExtensions

"""$(TYPEDSIGNATURES)

Return a few rows before and after the given timestamp `ts`
in the DataFrame `df`.
"""
function around(ts::DateTime, df::AbstractDataFrame; before=1, after=1, ts_field=:ts)
    i = 1
    for row in eachrow(df)
        if row[ts_field] == ts
            break
        elseif row[ts_field] > ts
            break
        else
            i += 1
        end
    end
    return df[i-before:i+after, :]
end

export around
