# a simple LP example
#
#   maximize x 
#
#   s.t. x >= 2
#        x <= 1
#        x >= 0
#
#   conflict: the two constraints

@testset "IIS" begin
    env = CPLEX.Env()

    model = CPLEX.Model(env, "iis")
    CPLEX.set_sense!(model, :Max)

    # add variables
    CPLEX.add_var!(model, 1.0, 0., Inf)  # x

    # add constraints
    CPLEX.add_constr!(model, [1.], '>', 2.)
    CPLEX.add_constr!(model, [1.], '<', 1.)

    # compute conflict
    c = CPLEX.c_api_getconflict(model)

    @test c !== nothing
    @test c.stat == CPLEX.CPX_STAT_CONFLICT_MINIMAL
    @test c.nrows == 2
    @test c.rowind[1] == 0
    @test c.rowind[2] == 1
    @test c.ncols == 0

    # gc()  # test finalizers
end
