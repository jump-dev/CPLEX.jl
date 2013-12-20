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

using CPLEXLink

env = CPLEXLink.Env()

model = CPLEXLink.Model(env, "mip_01")
CPLEXLink.set_sense!(model, :Max)

CPLEXLink.add_var!(model, 1., 0., 5.)  # x
CPLEXLink.add_var!(model, 2., 0, 10)   # y
CPLEXLink.add_var!(model, 5., 0, 1)    # z
CPLEXLink.set_vartype!(model, ['C', 'I', 'B'])

CPLEXLink.add_constr!(model, ones(3), '<', 10.)
CPLEXLink.add_constr!(model, [1., 2., 1.], '<', 15.)

optimize!(model)

println("sol = $(CPLEXLink.get_solution(model))")
println("objv = $(CPLEXLink.get_objval(model))")
