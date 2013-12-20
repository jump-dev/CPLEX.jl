# QCP example 
#    maximize x + y
#
#    s.t.  x, y >= 0
#          x^2 + y^2 <= 1
#
#    solution: (0.71, 0.71) objv = 1.414

using CPLEXLink

env = CPLEXLink.Env()

model = CPLEXLink.Model(env, "qcqp_01")
CPLEXLink.set_sense!(model, :Max)

CPLEXLink.add_vars!(model, [1., 1.], 0., Inf)

 # add_qpterms!(model, linearindices, linearcoeffs, qrowinds, qcolinds, qcoeffs, sense, rhs)
CPLEXLink.add_qconstr!(model, [], [], [1, 2], [1, 2], [1, 1.], '<', 1.0)

CPLEXLink.optimize!(model)

println("sol = $(CPLEXLink.get_solution(model))")
println("obj = $(CPLEXLink.get_objval(model))")

