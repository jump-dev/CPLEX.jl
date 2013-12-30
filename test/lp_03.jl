# Test get/set objective coefficients in LP

using MathProgBase
using CPLEXLink
using Base.Test

env = CPLEXLink.Env()

# original model
#
#   maximize  2x + 2y
#
# s.t. 0.2 <= x, y <= 1
#         

model = CPLEXLink.cplex_model(env;
  name="lp_03",
  sense=:Max,
  f=[2.0, 2.0], 
  lb=[0.2, 0.2],
  ub=[1.0, 1.0])

lb_ = CPLEXLink.get_varLB(model)
ub_ = CPLEXLink.get_varUB(model)
c_ = CPLEXLink.get_obj(model)

@test lb_ == [0.2, 0.2]
@test ub_ == [1.0, 1.0]
@test c_ == [2.0, 2.0]

CPLEXLink.optimize!(model)

println()
println("soln = $(CPLEXLink.get_solution(model))")
println("objv = $(CPLEXLink.get_objval(model))")


# change objective (warm start)
#
# maximize x - y
#
# s.t. 0.2 <= x, y <= 1
#

CPLEXLink.set_obj!(model, [1, -1])

c_ = CPLEXLink.get_obj(model)
@test c_ == [1.0, -1.0]

CPLEXLink.optimize!(model)

println()
println("soln = $(CPLEXLink.get_solution(model))")
println("objv = $(CPLEXLink.get_objval(model))")
