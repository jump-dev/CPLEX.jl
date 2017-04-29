# QP example
#
#    minimize 2 x^2 + y^2 + xy + x + y
#
#       s.t.  x, y >= 0
#             x + y = 1
#
#    solution: (0.25, 0.75), objv = 1.875
#

using CPLEX

@testset "QP 01" begin
    env = CPLEX.Env()

    model = CPLEX.Model(env, "qp_02")

    CPLEX.add_vars!(model, [1., 1.], 0., Inf)

    CPLEX.add_qpterms!(model, [1, 1, 2], [1, 2, 2], [2., 1., 1.])
    CPLEX.add_constr!(model, [1., 1.], '=', 1.)

    CPLEX.optimize!(model)

    println("sol = $(CPLEX.get_solution(model))")
    println("obj = $(CPLEX.get_objval(model))")
end
