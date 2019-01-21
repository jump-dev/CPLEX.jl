mutable struct GenCallbackData
    ncol::Int
    obj::Any
end

@testset "GenCB_02" begin
    env = CPLEX.Env()
    path = joinpath(dirname(@__FILE__), "../examples/sentoy.mps")
    model = CPLEX.Model(env, path)
    CPLEX.read_model(model, path)
    model.has_int = true
    CPLEX.set_param!(env, "CPXPARAM_MIP_Tolerances_MIPGap", 1e-6)
    ncols = CPLEX.num_var(model)
    obj = CPLEX.get_obj(model)
    context_id = CPLEX.CPX_CALLBACKCONTEXT_RELAXATION



    gcbdata = GenCallbackData(ncols, obj)

    function rounddownheur(model::CPLEX.Model, cb_context::CPLEX.CallbackContext)
        userdata = gcbdata
        cols = userdata.ncol
        obj = userdata.obj

        x = Vector{Float64}(undef, cols)
        ind = Vector{Int}(undef, cols)
        objrel = 0.0

        status = CPLEX.cbgetrelaxationpoint(cb_context, x, 1, cols, objrel)

        for j in 1:cols
            ind[j] = j

            if x[j]>1.0e-6
                frac = x[j]-floor(x[j])
                frac = min(1-frac, frac)
                if frac>1.0e-6
                    objrel -= x[j]*obj[j]
                    x[j] = 0.0
                end
            end
        end

        status = CPLEX.cbpostheursoln(cb_context, cols, ind, x, objrel, CPLEX.CPXCALLBACKSOLUTION_CHECKFEAS)

        return status
    end

    function my_callback_rounddownheur(cb_context::CPLEX.CallbackContext, context_id::Clong)
        if (context_id == CPLEX.CPX_CALLBACKCONTEXT_RELAXATION)
            status = rounddownheur(model, cb_context)
        end
        return status
    end

    CPLEX.cbsetfunc(model, context_id, my_callback_rounddownheur)

    CPLEX.set_param!(model.env, "CPXPARAM_MIP_Strategy_HeuristicFreq", -1)
    CPLEX.set_param!(env, "CPX_PARAM_THREADS", 1)

    CPLEX.optimize!(model)

    @test CPLEX.get_status(model) == :CPXMIP_OPTIMAL
    @test CPLEX.get_objval(model) ≈ -7772.0
end
