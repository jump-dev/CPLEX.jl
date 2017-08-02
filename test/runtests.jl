using Base.Test
# using MathProgBase
using CPLEX
using MathOptInterface
const MOI = MathOptInterface

include(joinpath(Pkg.dir("MathOptInterface"), "test", "contlinear.jl"))

@testset "LP Related Tests" begin
    linear1test(CplexSolver(CPX_PARAM_SCRIND=0), 1e-8)
    linear2test(CplexSolver(CPX_PARAM_SCRIND=0), 1e-8)
    linear3test(CplexSolver(CPX_PARAM_SCRIND=0), 1e-8)
    linear4test(CplexSolver(CPX_PARAM_SCRIND=0), 1e-8)
    linear5test(CplexSolver(CPX_PARAM_SCRIND=0), 1e-8)
    linear6test(CplexSolver(CPX_PARAM_SCRIND=0), 1e-8)
    # # linear7test(CplexSolver(), 1e-8)
    linear8test(CplexSolver(CPX_PARAM_SCRIND=0), 1e-8)
    linear9test(CplexSolver(CPX_PARAM_SCRIND=0), 1e-8)
end

include(joinpath(Pkg.dir("MathOptInterface"), "test", "intlinear.jl"))

@testset "MIP Related Tests" begin
    knapsacktest(CplexSolver(CPX_PARAM_SCRIND=0), 1e-8)
    int1test(CplexSolver(CPX_PARAM_SCRIND=0), 1e-8)
    int2test(CplexSolver(CPX_PARAM_SCRIND=0), 1e-8)
end

include(joinpath(Pkg.dir("MathOptInterface"), "test", "contquadratic.jl"))

@testset "QP Related Tests" begin
    qpp0test(CplexSolver(CPX_PARAM_SCRIND=0), 1e-8)
    qpp1test(CplexSolver(CPX_PARAM_SCRIND=0), 1e-8)
    QP01test(CplexSolver(CPX_PARAM_SCRIND=0), 1e-8)
    # # qpp2test(CplexSolver(), 1e-8)
    qpd0test(CplexSolver(CPX_PARAM_SCRIND=0), 1e-8)
    qpd1test(CplexSolver(CPX_PARAM_SCRIND=0), 1e-8)
    socptest(CplexSolver(CPX_PARAM_SCRIND=0), 1e-8)
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
