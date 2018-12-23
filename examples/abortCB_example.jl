#Julia 1.0; CPLEX newest branch.
#Not particularly important to be compatible with Julia 0.6
using Revise
using CPLEX
# import Gallium

env = CPLEX.Env()
# This is pretty important for thread safety (probably).
CPLEX.set_param!(env, "CPX_PARAM_THREADS", 1)#Maybe remove in the future!
model = CPLEX.Model(env, "callback_test")
CPLEX.add_vars!(model, [1.0], [0.0], [1.0])
CPLEX.c_api_chgctype(model, Int32[1], Cchar['I'])
 # Hack for these tests.
model.has_int = true
function my_callback(cb_context::CPLEX.CallbackContext, context_id::Clong)
    println("Aborting!")
    CPLEX.cpx_callbackabort(cb_context)
end
context_id = Clong(0) | CPLEX.CPX_CALLBACKCONTEXT_CANDIDATE
CPLEX.cpx_callbacksetfunc(model, context_id, my_callback)
CPLEX.optimize!(model)

println("The solving status: ", CPLEX.get_status(model))
