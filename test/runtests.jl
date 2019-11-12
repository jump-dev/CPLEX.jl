if get(ENV, "TRAVIS", "false") == "true" && get(ENV, "SECRET_CPLEX_URL", nothing) === nothing
    # If we're running on TRAVIS, but there isn't the secret URL,  then it means
    # that we're being tested from an account other than JuliaOpt. To enable
    # auto-merge on the General registry, silently exit tests indicating that
    # we passed.
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
