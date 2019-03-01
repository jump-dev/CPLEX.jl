# an example of mip start on mixed integer programming
#
#   minimize x + 2 y
#
#   s.t.  x + y => 10
#         x + 3 y => 15
#
#         x is integer: 0 <= x <= 15
#         y is continuous: 0 <= y <= 15

@testset "MIP 02" begin
    env = CPLEX.Env()
    model = CPLEX.Model(env, "mip_02")
    CPLEX.set_sense!(model, :Max)
    CPLEX.set_param!(env, "CPX_PARAM_MIPDISPLAY", 1)
    CPLEX.set_param!(env, "CPX_PARAM_MIPINTERVAL", 1)
    CPLEX.set_param!(env, "CPX_PARAM_INTSOLLIM", 1) # Only solve the submip
    CPLEX.add_var!(model, 1.0, 0.0, 15.0)   # x
    CPLEX.add_var!(model, 2.0, 0.0, 15.0)   # y
    CPLEX.set_vartype!(model, ['I', 'C'])
    @test model.has_int == true
    CPLEX.add_constr!(model, ones(2), '>', 10.0)
    CPLEX.add_constr!(model, [1.0, 3.0], '>', 15.0)
    CPLEX.c_api_addmipstarts(model, [0.0], 2)
    CPLEX.optimize!(model)
    sol = CPLEX.get_solution(model)
    @test sol ≈ [0.0, 10.0]
    @test CPLEX.get_objval(model) ≈ 20
    
    CPLEX.c_api_addmipstarts(model, [0.0], 2)
    CPLEX.c_api_chgmipstarts(model, [15.0], 2)
    CPLEX.optimize!(model)
    sol = CPLEX.get_solution(model)
    @test sol ≈ [15.0, 0.0]
    @test CPLEX.get_objval(model) ≈ 15
end
