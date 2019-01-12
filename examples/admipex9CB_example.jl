#callbacks for a capacity problem
# optimal result: -7772

using CPLEX, Revise
# import Gallium

##################
# Rewrite from an example of the CPLEX Callable library, admipex9.c
env=CPLEX.Env()
#build the model and read the problem from the .mps file
path=joinpath(dirname(@__FILE__),"sentoy.mps")
model=CPLEX.Model(env,path)
CPLEX.read_model(model,path)
model.has_int = true #need to change cpx_solve.jl L4
CPLEX.set_param!(env,"CPXPARAM_MIP_Tolerances_MIPGap", 1e-6)
#set up generic callback
ncols=CPLEX.num_var(model)
obj=CPLEX.get_obj(model)
context_id = Clong(0) | CPLEX.CPX_CALLBACKCONTEXT_RELAXATION

mutable struct GenCallbackData
    ncol::Int
    obj::Any
end

gcbdata=GenCallbackData(ncols,obj)

function rounddownheur(model::CPLEX.Model, cb_context::CPLEX.CallbackContext)
    userdata=gcbdata
    # userdata = unsafe_pointer_to_objref(gcbdata)
    cols=userdata.ncol
    obj=userdata.obj

    x=Vector{Float64}(undef, cols)
    ind=Vector{Int}(undef, cols)
    # objrel = Ref{Cdouble}(0.0)
    objrel = 0.0

    status=CPLEX.cbgetrelaxationpoint(cb_context, x, 1, cols, objrel)

    # x=[-0.0, 1.0, -0.0, -0.0, 1.0, -0.0, -0.0, 1.0, 0.799815, -0.0, -0.0, -0.0, 1.0, 1.0, -0.0, 1.0, -0.0, 1.0, 1.0, -0.0, 1.0, -0.0, -0.0, -0.0, 1.0, -0.0, 0.691323, 0.450987, -0.0, 1.0, -0.0, -0.0, -0.0, -0.0, -0.0, 0.930968, 1.0, -0.0, 0.731431, -0.0, -0.0, -0.0, 0.544755, -0.0, 0.45098, 1.0, 1.0, -0.0, -0.0, -0.0, -0.0, -0.0, 1.0, -0.0, -0.0, 1.0, 0.293466, -0.0, 1.0, -0.0]
    #
    # objrel=-7839.278018021
    # println("x is $x")#@
    # println(objrel)#@

    # objrel_value = objrel[]

    if status!=0
        error("Could not get solution $status")
    end
    # println("before pointer of x is: ",pointer_from_objref(x))#@
    for j in 1:cols
        ind[j]=j

        if x[j]>1.0e-6
            frac=x[j]-floor(x[j])
            frac=min(1-frac,frac)
            if frac>1.0e-6
                objrel -= x[j]*obj[j]
                x[j] = 0.0
                # println(objrel_value)#@
            end
        end
    end

    # println("later pointer of x is: ", pointer_from_objref(x))#@
    # println("pointer of ind is: ", pointer_from_objref(ind))#@
    # println("x is $x")#@
    # println("objrel is: $objrel_value")#@

    # @enter cbpostheursoln(env,context_,cols,ind,x,objrel,CPXCALLBACKSOLUTION_CHECKFEAS)

    #objrel_value
    status=CPLEX.cbpostheursoln(cb_context, cols, ind, x, objrel, CPLEX.CPXCALLBACKSOLUTION_CHECKFEAS)

    # clear!(:x)
    # clear!(:ind)

    # println("later pointer of x is: ", pointer_from_objref(x))#@
    # println("pointer of ind is: ", pointer_from_objref(ind))#@
    # println("objrel is: $objrel")

    #anti-garbage collection
    # objrel_value2 = objrel_value

    if status!=0
        error("Could not post solution $status")
    end

    return status
end

function my_callback_rounddownheur(cb_context::CPLEX.CallbackContext, context_id::Clong)

    if (context_id == CPLEX.CPX_CALLBACKCONTEXT_RELAXATION)
        status=rounddownheur(model, cb_context)
    else
        println("ERROR: Callback called in an unexpected context.")
        return convert(Cint,1)
    end
    return status
end

CPLEX.cpx_callbacksetfunc(model, context_id, my_callback_rounddownheur)

CPLEX.set_param!(model.env, "CPXPARAM_MIP_Strategy_HeuristicFreq", -1)
CPLEX.set_param!(env, "CPX_PARAM_THREADS", 1)# single thread for now

# @enter CPLEX.optimize!(model)
CPLEX.optimize!(model)

println("The solving status: ", CPLEX.get_status(model))
println("The optimal objective value is: ", CPLEX.get_objval(model))
