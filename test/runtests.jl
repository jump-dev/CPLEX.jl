using Base.Test
# using MathProgBase
using CPLEX

@testset "Legacy Tests" begin
    @testset "Low level" begin
        include(joinpath("old", "constants.jl"))
        include(joinpath("old", "low_level_api.jl"))
        include(joinpath("old", "env.jl"))
        include(joinpath("old", "problemtype.jl"))
    end
    @testset "LP" begin
        include(joinpath("old", "lp_01.jl"))
        include(joinpath("old", "lp_02.jl"))
        include(joinpath("old", "lp_03.jl"))
    end
    @testset "MIP" begin
        include(joinpath("old", "mip_01.jl"))
        include(joinpath("old", "sos.jl"))
    end
    @testset "QP" begin
        include(joinpath("old", "qp_01.jl"))
        include(joinpath("old", "qp_02.jl"))
        include(joinpath("old", "qcqp_01.jl"))
        include(joinpath("old", "miqcp.jl"))
    end
    @testset "MathProgBase" begin
        include(joinpath("old", "mathprog.jl"))
    end
end
