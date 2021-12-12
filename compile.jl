#!/usr/bin/env julia
using Pkg
Pkg.activate(".")
Pkg.instantiate()
using PackageCompiler
run(`rm -rf compiled`)
create_app("Groupay", "compiled")
