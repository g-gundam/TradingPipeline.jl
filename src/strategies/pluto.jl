# Pluto Strategy A, B, and C.
# These are temporary strategies for use in Pluto notebooks.
# The structs are defined outside of Pluto, because I can't define them in Pluto
# and also have them dispatch in non-Pluto code.

@kwdef mutable struct PSA <: AbstractStrategy
    chart::Union{Missing,Chart} = missing
    chart2::Union{Missing,Chart} = missing
    chart3::Union{Missing,Chart} = missing
    rf::Union{Missing,ReversedFrame} = missing
    rf2::Union{Missing,ReversedFrame} = missing
    rf3::Union{Missing,ReversedFrame} = missing
    data::Dict = Dict{Symbol,Any}()
end

@kwdef mutable struct PSB <: AbstractStrategy
    chart::Union{Missing,Chart} = missing
    chart2::Union{Missing,Chart} = missing
    chart3::Union{Missing,Chart} = missing
    rf::Union{Missing,ReversedFrame} = missing
    rf2::Union{Missing,ReversedFrame} = missing
    rf3::Union{Missing,ReversedFrame} = missing
    data::Dict = Dict{Symbol,Any}()
end

@kwdef mutable struct PSC <: AbstractStrategy
    chart::Union{Missing,Chart} = missing
    chart2::Union{Missing,Chart} = missing
    chart3::Union{Missing,Chart} = missing
    rf::Union{Missing,ReversedFrame} = missing
    rf2::Union{Missing,ReversedFrame} = missing
    rf3::Union{Missing,ReversedFrame} = missing
    data::Dict = Dict{Symbol,Any}()
end
