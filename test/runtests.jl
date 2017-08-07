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

include(joinpath(Pkg.dir("MathOptInterface"), "test", "contconic.jl"))

@testset "Conic Related Tests" begin
    # run some MOI cont conic tests
    lin1test(CplexSolver(CPX_PARAM_SCRIND=0), 1e-4)
    lin2test(CplexSolver(CPX_PARAM_SCRIND=0), 1e-4)

    # requires conic duals
    lin1atest(CplexSolver(CPX_PARAM_SCRIND=0), 1e-4)
    lin2atest(CplexSolver(CPX_PARAM_SCRIND=0), 1e-4)

    #requires infeasibility certificates
    # lin3test(CplexSolver(CPX_PARAM_SCRIND=0), 1e-4)
    # lin4test(CplexSolver(CPX_PARAM_SCRIND=0), 1e-4)
end
