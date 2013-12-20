# QP example
#
#    minimize 2 x^2 + y^2 + xy + x + y
#
#       s.t.  x, y >= 0
#             x + y = 1
#
#    solution: (0.25, 0.75), objv = 1.875
#

using CPLEXLink 

env = CPLEXLink.Env()

model = CPLEXLink.Model(env, "qp_02")

CPLEXLink.add_vars!(model, [1., 1.], 0., Inf)

CPLEXLink.add_qpterms!(model, [1, 1, 2], [1, 2, 2], [2., 1., 1.])
CPLEXLink.add_constr!(model, [1., 1.], '=', 1.)

CPLEXLink.optimize!(model)

println("sol = $(CPLEXLink.get_solution(model))")
println("obj = $(CPLEXLink.get_objval(model))")
