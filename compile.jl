#!/usr/bin/env julia
# julia --project=. -e "using Pkg, PackageCompiler; Pkg.instantiate(); create_app("groupay","compiled")"
using Pkg
Pkg.activate(".")
Pkg.instantiate()
using PackageCompiler
# create_app("PayGroups.jl", "compiled")
create_app("Groupay", "compiled")
