# an example on mixed integer programming
#
#   maximize x + 2 y + 5 z
#
#   s.t.  x + y + z <= 10
#         x + 2 y + z <= 15
#
#         x is continuous: 0 <= x <= 5
#         y is integer: 0 <= y <= 10
#         z is binary
#

using CPLEX
using JuMP

m = Model(solver=CplexSolver())
@variable(m, 5 >= x >= 0)
@variable(m, 10 >= y >= 0, Int)
@variable(m, z, Bin)
@objective(m, Max, x + 2*y + 5*z)
@constraint(m, x + y + z <= 10)
@constraint(m, x + 2*y + z <= 15)
status = solve(m)
println("walltime = $(MathProgBase.getsolvetime(internalmodel(m)))")
