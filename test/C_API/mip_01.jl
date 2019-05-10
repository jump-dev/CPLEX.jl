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

@testset "MIP 01" begin
    env = CPLEX.Env()
    model = CPLEX.Model(env, "mip_01")
    CPLEX.set_sense!(model, :Max)
    CPLEX.set_param!(env, "CPX_PARAM_MIPDISPLAY", 1)
    CPLEX.set_param!(env, "CPX_PARAM_MIPINTERVAL", 1)
    CPLEX.add_var!(model, 1.0, 0.0, 5.0)  # x
    CPLEX.add_var!(model, 2.0, 0.0, 10.0)   # y
    CPLEX.add_var!(model, 5.0, 0.0, 1.0)    # z
    CPLEX.set_vartype!(model, ['C', 'I', 'B'])
    @test model.has_int == true
    CPLEX.add_constr!(model, ones(3), '<', 10.0)
    CPLEX.add_constr!(model, [1.0, 2.0, 1.0], '<', 15.0)
    CPLEX.optimize!(model)
    sol = CPLEX.get_solution(model)
    @test sol ≈ [4.0, 5.0, 1.0]
    @test CPLEX.get_objval(model) ≈ 19
end
