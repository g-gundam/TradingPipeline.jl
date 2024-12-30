# TradingPipeline

[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://g-gundam.github.io/TradingPipeline.jl/dev/)
[![Build Status](https://github.com/g-gundam/TradingPipeline.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/g-gundam/TradingPipeline.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/g-gundam/TradingPipeline.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/g-gundam/TradingPipeline.jl)

## What's going on?

- A lot of this is Rocket.jl-related code that takes some of my other libraries and connects them together in a graph of async tasks.
  + Thanks to **[Lucky.jl](https://github.com/oliviermilla/Lucky.jl)** for introducing me to [Rocket.jl](https://github.com/ReactiveBayes/Rocket.jl) in the first place.
  + I liked how backtesting and live trading could be accomplished with very similar code.
  + I also saw how I could structure the feedback loop of events from the exchange back into the strategy.
    - I was stuck on this for a long time.
- Everything here is very tentative.
- I've been feeling things out in the REPL, and I've finally gotten to the point where I may need to shift to Pluto notebooks.
- I needed a way to load portions of my code into a notebook, and this package was created to facilitate that.

## What's going to be in here?

- ...a lot

## Read More About It

- https://g-gundam.github.io/
