# a simple LP example
#
#   maximize x + y
#
#   s.t. 50 x + 24 y <= 2400
#        30 x + 33 y <= 2100
#        x >= 45, y >= 5
#
#   solution: x = 45, y = 6.25, objv = 51.25

using CPLEXLink

env = CPLEXLink.Env()

# method = getparam(env, "Method")
# println("method = $method")

model = CPLEXLink.Model(env, "lp_01")
CPLEXLink.set_sense!(model, :Max)

# add variables
CPLEXLink.add_var!(model, 1.0, 45., Inf)  # x
CPLEXLink.add_var!(model, 1.0,  5., Inf)  # y

# add constraints
CPLEXLink.add_constr!(model, [50., 24.], '<', 2400.)
CPLEXLink.add_constr!(model, [30., 33.], '<', 2100.)

println(model)

# perform optimization
CPLEXLink.optimize!(model)

sol = CPLEXLink.get_solution(model)
println("soln = $(sol)")

objv = CPLEXLink.get_objval(model)
println("objv = $(objv)")

gc()  # test finalizers
