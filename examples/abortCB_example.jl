# This example aborts the solving process once an integer-feasible solution is found or encountered an unbounded relaxation
# Solve:
    # minimize x
    # s.t. x is integral: 0 <= x <= 1

using CPLEX

env = CPLEX.Env()
# This is pretty important for thread safety (probably)
# Maybe remove in the future!
CPLEX.set_param!(env, "CPX_PARAM_THREADS", 1)
model = CPLEX.Model(env, "callback_test")
CPLEX.add_vars!(model, [1.0], [0.0], [1.0])
CPLEX.c_api_chgctype(model, Int32[1], Cchar['I'])
 # Hack for these tests.
model.has_int = true
function my_callback(cb_context::CPLEX.CallbackContext, context_id::Clong)
    println("Aborting!")
    CPLEX.cbabort(cb_context)
end
context_id = CPLEX.CPX_CALLBACKCONTEXT_CANDIDATE
CPLEX.cbsetfunc(model, context_id, my_callback)
CPLEX.optimize!(model)

println("The solving status: ", CPLEX.get_status(model))
println(CPLEX.get_status(model) == :CPXMIP_ABORT_INFEAS)
