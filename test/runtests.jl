using Base.Test
# using MathProgBase
using CPLEX
using MathOptInterface
const MOI = MathOptInterface

# @testset "Basic CPLEX Only tests" begin
#     s = CplexSolver(logfile="abc.txt")
#     m = MOI.SolverInstance(s)
# end

include(joinpath(Pkg.dir("MathOptInterface"), "test", "contlinear.jl"))

@testset "LP Related Tests" begin
    # run all MOI cont linear tests
    contlineartest(CplexSolver(CPX_PARAM_SCRIND=0), 1e-8)
end

include(joinpath(Pkg.dir("MathOptInterface"), "test", "intlinear.jl"))

@testset "MIP Related Tests" begin
    # run all MOI int linear tests
    intlineartest(CplexSolver(CPX_PARAM_SCRIND=0), 1e-8)
end

include(joinpath(Pkg.dir("MathOptInterface"), "test", "contquadratic.jl"))

@testset "QP Related Tests" begin
    # run all MOI cont quadratic tests
    contquadratictests(CplexSolver(CPX_PARAM_SCRIND=0), 1e-4)
end

# include("constants.jl")
# include("low_level_api.jl")
# @testset "LP" begin
#     include("lp_01.jl")
#     include("lp_02.jl")
#     include("lp_03.jl")
# end
# include("mip_01.jl")
# @testset "QP" begin
#     include("qp_01.jl")
#     include("qp_02.jl")
# end
# include("qcqp_01.jl")
# include("env.jl")
# include("sos.jl")
# include("problemtype.jl")
# include("miqcp.jl")
# @testset "MathProgBase" begin
#     include("mathprog.jl")
# end
