## Default Config for GitHub Actions

vite_default = (
    repo      = "github.com/g-gundam/TradingPipeline.jl",
    devbranch = "main", # or master, trunk, ...
    devurl    = "dev",
)

md_default = (
    sitename = "TradingPipeline.jl",
    format   = DocumenterVitepress.MarkdownVitepress(; vite_default...),
    pages    = [
        "Home"      => "index.md",
        "Utilities" => "util.md",
    ]
)

## Preview Documentation Development Instantly
# https://luxdl.github.io/DocumenterVitepress.jl/stable/manual/get_started#Preview-Documentation-Development-Instantly

vite_local = (
    ; vite_default...,
    md_output_path  = ".",
    build_vitepress = false,
)

md_local = merge(
    md_default,
    (format = DocumenterVitepress.MarkdownVitepress(; vite_local...),),
    (clean = false,)
);
