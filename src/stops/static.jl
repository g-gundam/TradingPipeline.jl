# Set a stop once and never move it.
# Cancel the stop order when the position is closed normally.

# Many exchanges allow setting a stop when the position is first created.
# In those cases, this doesn't have to emit any instructions to the driver.

@kwdef struct StaticStop <: AbstractStop
    percent::Float64
end
