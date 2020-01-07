using Test
import Pkg
using MathProgBase
using CPLEX

@testset "$folder" for folder in ["C_API", "MathProgBase", "MathOptInterface"]
    @testset "$(file)" for file in readdir(folder)
        include(joinpath(folder, file))
    end
end
