# QCP example
#    maximize x + y
#
#    s.t.  x, y >= 0
#          x^2 + y^2 <= 1
#
#    solution: (0.71, 0.71) objv = 1.414

using CPLEX, Base.Test

@testset "QCQP 01" begin
    env = CPLEX.Env()

    model = CPLEX.Model(env, "qcqp_01")
    CPLEX.set_sense!(model, :Max)

    CPLEX.add_vars!(model, [1., 1.], 0., Inf)

     # add_qpterms!(model, linearindices, linearcoeffs, qrowinds, qcolinds, qcoeffs, sense, rhs)
    CPLEX.add_qconstr!(model, [], [], [1, 2], [1, 2], [1, 1.], '<', 1.0)

    CPLEX.optimize!(model)

    sol = CPLEX.get_solution(model)
    @test isapprox(sol[1], sqrt(2)/2, rtol=1e-4)
    @test isapprox(sol[2], sqrt(2)/2, rtol=1e-4)
    @test isapprox(CPLEX.get_objval(model), sqrt(2), rtol=1e-8)
end
