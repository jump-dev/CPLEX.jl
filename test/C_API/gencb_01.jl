# A test for abort in the generic callback.
# Solve:
    # minimize x
    # s.t. x is integral: 0 <= x <= 1

@testset "GenCB_01" begin
    env = CPLEX.Env()
    CPLEX.set_param!(env, "CPX_PARAM_THREADS", 1)
    model = CPLEX.Model(env, "callback_test")
    CPLEX.add_vars!(model, [1.0], [0.0], [1.0])
    CPLEX.c_api_chgctype(model, Int32[1], Cchar['I'])
    function my_callback(cb_context::CPLEX.CallbackContext, context_id::Clong)
        CPLEX.cbabort(cb_context)
    end
    CPLEX.cbsetfunc(model, CPLEX.CPX_CALLBACKCONTEXT_CANDIDATE, my_callback)
    CPLEX.optimize!(model)
    @test CPLEX.get_status(model) == :CPXMIP_ABORT_INFEAS
end
