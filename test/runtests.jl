"""
    is_general_registry()

Detect if we are being called from AutoMerge CI on the Julia General registry.

The Julia General registry attempts to install and test packages. Since it does't have a
CPLEX license, this build will fail, preventing auto-merge. Therefore, we need to detect
when we are being called and silently bail.

Complicating matters is the very particular way in which we get called, because we don't get
a typical installation. In particular, a very restricted set of environment variables is
passed. See here for details:
https://github.com/JuliaRegistries/RegistryCI.jl/blob/0d19525c7120176e5e0f11637dcca7b229b5f0c9/src/AutoMerge/guidelines.jl#L178-L196

This check is fragile, and subject to breakage. But it seems highly unlikely that a user
will have a set-up identical to this.
"""
function is_general_registry()
    return all([
        sort(collect(keys(ENV))) == ["JULIA_DEPOT_PATH", "PATH", "PYTHON", "R_HOME"],
        get(ENV, "PYTHON", "false") == "",
        get(ENV, "R_HOME", "false") == "*",
    ])
end

if is_general_registry()
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
