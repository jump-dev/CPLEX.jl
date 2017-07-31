using Base.Test
# using MathProgBase
using CPLEX
using MathOptInterface
const MOI = MathOptInterface
# include(joinpath(Pkg.dir("MathOptInterface"), "test", "function_utilities.jl"))
include(joinpath(Pkg.dir("MathOptInterface"), "test", "contlinear.jl"))

linear1test(CplexSolver(), 1e-5)

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
