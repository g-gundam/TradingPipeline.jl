```@meta
CurrentModule = TradingPipeline
```

# TradingPipeline

- Hello, how are you?
- DocumenterVitepress.jl generates very good-looking output.


## Live Reloading SAGA

- Live-reloading doesn't work as documented.
  + It's almost there, but not quite.
  + It can't serve the js and css assets.
  + However, it does live reload the HTML parts.
  
## Holy fucking shit.

- It is so hacky, but I made it work.
  + servedocs() starts a LiveSerever
  + then I run another LiveServer, but the two servers share state, and the config I give the second one overrides the first LiveServer.
  + Finally, I added a userscript to hack the websocket listener to make it wait a few seconds before reloading the page.
- [2025-08-04 Mon 19:13] UPDATE: I made it less hacky after reading the source of LiveServer.servedocs and passing in a custom buildfoldername of "build/1" to match the new way of doing things.
  + `'(testing 1 2 3)`
  
```julia
include("makedev.jl")
# This runs a LiveSerever.
sd_pid = Threads.@spawn servedocs(foldername=pwd())
# This runs another LiveServer, but it also overrides the `dir` for the first one.
# The LiveServer is effectively a singleton.
ls_pid = Threads.@spawn LiveServer.serve(dir = "./build/1")
```

And then the UserScript to top it all off.

```javascript
// ==UserScript==
// @name        New script localhost
// @namespace   Violentmonkey Scripts
// @match       http://localhost:8000/*
// @grant       unsafeWindow
// @version     1.0
// @author      -
// @description 8/4/2025, 6:26:18 PM
// ==/UserScript==

unsafeWindow.ws_liveserver_M3sp9.onmessage = function(msg) {
  if (msg.data === "update") {
    console.log("update received");
    ws_liveserver_M3sp9.close();
    setTimeout(() => { console.log("after wait"); location.reload() }, 3000);
  };
};
console.log("websocket delay hack added.")
```


Documentation for [TradingPipeline](https://github.com/g-gundam/TradingPipeline.jl).

```@index
```

```@autodocs
Modules = [TradingPipeline, TradingPipeline.Stops]
```
