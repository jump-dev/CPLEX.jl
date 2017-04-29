# QP example
#
#    minimize 2 x^2 + y^2 + xy + x + y
#
#       s.t.  x, y >= 0
#             x + y = 1
#
#    solution: (0.25, 0.75), objv = 1.875
#

using CPLEX, Base.Test

@testset "QP 01" begin
    env = CPLEX.Env()
    CPLEX.set_param!(env, "CPX_PARAM_SCRIND", 0)

    model = CPLEX.Model(env, "qp_02")

    CPLEX.add_vars!(model, [1., 1.], 0., Inf)

    CPLEX.add_qpterms!(model, [1, 1, 2], [1, 2, 2], [2., 1., 1.])
    CPLEX.add_constr!(model, [1., 1.], '=', 1.)

    CPLEX.optimize!(model)

    sol = CPLEX.get_solution(model)
    @test abs(sol[1]) < 1e-4
    @test isapprox(sol[2], 1, rtol=1e-4)
    @test isapprox(CPLEX.get_objval(model), 1.5, rtol=1e-8)
end
