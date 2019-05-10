# Quadratic programming in MATLAB-like style
#
#   minimize x^2 + xy + y^2 + yz + z^2
#
#   s.t.    x + 2 y + 3 z >= 4
#           x +   y       >= 1
#

@testset "QP 02" begin
    env = CPLEX.Env()

    model = CPLEX.cplex_model(env;
        name = "qp_02",
        f = [0., 0., 0.],
        H = [2. 1. 0.; 1. 2. 1.; 0. 1. 2.],
        A = -[1. 2. 3.; 1. 1. 0.],
        b = -[4., 1.])

    CPLEX.optimize!(model)

    sol = CPLEX.get_solution(model)
    @test isapprox(sol[1], 0.571429, rtol=1e-4)
    @test isapprox(sol[2], 0.428571, rtol=1e-4)
    @test isapprox(sol[3], 0.857143, rtol=1e-4)
    @test isapprox(CPLEX.get_objval(model), 1.857142864, rtol=1e-8)
end
