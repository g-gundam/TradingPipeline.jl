```@meta
CurrentModule = TradingPipeline
```

# TradingPipeline

- Hello, how are you?
- DocumenterVitepress.jl generates very good-looking output.
- I forgot how to do so much though.

## Live Reloading Saga

- Live-reloading doesn't work as documented.
  + It's almost there, but not quite.
  + It can't serve the js and css assets.
  + However, it does live reload the HTML parts.
  
### Something that *does* work.

```julia-repl
julia> ls_pid = Threads.@spawn LiveServer.serve(dir = "./build/1")
```

This is handy, because I can manually rebuild like I did before, and
the HTTP server will still work even though the previous `/build/` directory
was blown away.  LiveServer is smart about finding the new one and continuing
to work.

Documentation for [TradingPipeline](https://github.com/g-gundam/TradingPipeline.jl).

```@index
```

```@autodocs
Modules = [TradingPipeline, TradingPipeline.Stops]
```
