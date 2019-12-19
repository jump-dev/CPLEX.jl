import Pkg

if haskey(Pkg.installed(), "RegistryCI")
    # Skip installation is we detect that the package RegistryCI is installed. This is
    # almost certainly the Julia General registry running the AutoMerge. Users should have
    # no reason to install CPLEX and RegistryCI locally in the same project.
    # TODO(odow): remove this once we distribute the community edition.
    exit(0)
end

using Test
import Pkg
using MathProgBase
using CPLEX

@testset "$folder" for folder in ["C_API", "MathProgBase", "MathOptInterface"]
    @testset "$(file)" for file in readdir(folder)
        include(joinpath(folder, file))
    end
end
