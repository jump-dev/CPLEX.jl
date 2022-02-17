using CPLEX
using Test

@testset "MathOptInterface Tests" begin
    for file in readdir("MathOptInterface")
        include(joinpath("MathOptInterface", file))
    end
end
