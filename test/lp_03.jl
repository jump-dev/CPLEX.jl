using CPLEX, Base.Test

@testset "LP 03" begin
    # Test get/set objective coefficients in LP

    env = CPLEX.Env()

    # original model
    #
    #   maximize  2x + 2y
    #
    # s.t. 0.2 <= x, y <= 1
    #

    model = CPLEX.cplex_model(env;
      name="lp_03",
      sense=:Max,
      f=[2.0, 2.0],
      lb=[0.2, 0.2],
      ub=[1.0, 1.0])

    lb_ = CPLEX.get_varLB(model)
    ub_ = CPLEX.get_varUB(model)
    c_ = CPLEX.get_obj(model)

    @test lb_ == [0.2, 0.2]
    @test ub_ == [1.0, 1.0]
    @test c_ == [2.0, 2.0]

    CPLEX.optimize!(model)

    sol = CPLEX.get_solution(model)
    @test sol[1] ≈ 1
    @test sol[2] ≈ 1
    @test CPLEX.get_objval(model) ≈ 4


    # change objective (warm start)
    #
    # maximize x - y
    #
    # s.t. 0.2 <= x, y <= 1
    #

    CPLEX.set_obj!(model, [1, -1])

    c_ = CPLEX.get_obj(model)
    @test c_ == [1.0, -1.0]

    CPLEX.optimize!(model)

    sol = CPLEX.get_solution(model)
    @test sol[1] ≈ 1
    @test sol[2] ≈ 0.2
    @test CPLEX.get_objval(model) ≈ 0.8
end
