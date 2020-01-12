using Test
import Pkg
using MathProgBase
using CPLEX

@testset "$folder" for folder in ["C_API", "MathProgBase", "MathOptInterface"]
        @testset "$(file)" for file in readdir(folder)
            if file != "MOI_callbacks.jl"
                include(joinpath(folder, file))
            end
        end
    end
end
