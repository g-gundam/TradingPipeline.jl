# A place for miscellaneous useful funcitons.

"""    $(TYPEDSIGNATURES)

Return the percent difference between `a` and `b`.
"""
function percent_diff(a, b)
    ((b - a) / a) * 100
end
