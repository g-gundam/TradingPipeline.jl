using TradingPipeline
using Documenter
using DocumenterVitepress
using LiveServer

include("shared.jl")

@info "[makedocs]"
makedocs(; md_local...)
@info "[servedocs]"
sd_pid = Threads.@spawn servedocs(foldername=pwd(), buildfoldername="build/1")
# ls_pid = nothing
# @async begin
#     sleep(8)
#     global ls_pid = Threads.@spawn LiveServer.serve(dir = "./build/1")
#     @info "[LiveServer] reconfigured"
# end

## This is all I need to run for local documentation development.
# if false
#     include("makedev.jl")
#     sd_pid = Threads.@spawn servedocs(foldername=pwd())
#     ls_pid = Threads.@spawn LiveServer.serve(dir = "./build/1")
# end

## Somehow, this isn't needed.
#DocumenterVitepress.dev_docs("build", md_output_path = "")

## Kill the spawned thread like this.
#schedule(ls_id, InterruptException(); error=true) # stop servedocs thread

