using Base.Test
using MathProgBase
using CPLEX

@testset "C API" begin
    include("constants.jl")
    include("low_level_api.jl")
    @testset "LP" begin
        include("lp_01.jl")
        include("lp_02.jl")
        include("lp_03.jl")
    end
    include("mip_01.jl")
    @testset "QP" begin
        include("qp_01.jl")
        include("qp_02.jl")
    end
    include("qcqp_01.jl")
    include("env.jl")
    include("sos.jl")
    include("problemtype.jl")
    include("miqcp.jl")
end

@testset "MathProgBase" begin
    include("mathprog.jl")
end

@testset "MathOptInterface" begin
    include("MOI_Wrapper.jl")
end
