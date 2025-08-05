using TradingPipeline
using Documenter
using DocumenterVitepress
using LiveServer

include("shared.jl")

makedocs(; md_local...)

## This is all I need to run for local documentation development.
#include("makedev.jl")
#ls_pid = Threads.@spawn servedocs(foldername=pwd())

## Somehow, this isn't needed.
#DocumenterVitepress.dev_docs("build", md_output_path = "")

## Kill the spawned thread like this.
#schedule(ls_id, InterruptException(); error=true) # stop servedocs thread

