# a simple LP example
#
#   maximize x + y
#
#   s.t. 50 x + 24 y <= 2400
#        30 x + 33 y <= 2100
#        x >= 45, y >= 5
#
#   solution: x = 45, y = 6.25, objv = 51.25

using CPLEX, Base.Test

@testset "LP 01" begin

    env = CPLEX.Env()

    # method = getparam(env, "Method")
    # println("method = $method")

    model = CPLEX.Model(env, "lp_01")
    CPLEX.set_sense!(model, :Max)

    # add variables
    CPLEX.add_var!(model, 1.0, 45., Inf)  # x
    CPLEX.add_var!(model, 1.0,  5., Inf)  # y

    # add constraints
    CPLEX.add_constr!(model, [50., 24.], '<', 2400.)
    CPLEX.add_constr!(model, [30., 33.], '<', 2100.)

    println(model)

    # perform optimization
    CPLEX.optimize!(model)

    sol = CPLEX.get_solution(model)
    println("soln = $(sol)")

    objv = CPLEX.get_objval(model)
    println("objv = $(objv)")

    gc()  # test finalizers
end
