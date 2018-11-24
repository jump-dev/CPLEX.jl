@enum CbSolStrat CPXCALLBACKSOLUTION_CHECKFEAS CPXCALLBACKSOLUTION_PROPAGATE

@enum CbInfo CPXCALLBACKINFO_THREADID CPXCALLBACKINFO_NODECOUNT CPXCALLBACKINFO_ITCOUNT CPXCALLBACKINFO_BEST_SOL CPXCALLBACKINFO_BEST_BND CPXCALLBACKINFO_THREADS CPXCALLBACKINFO_FEASIBLE CPXCALLBACKINFO_TIME CPXCALLBACKINFO_DETTIME

mutable struct CallbackContext
    model::Model
    context::Ptr{Cvoid}
end

function callback_wrapper(context::Ptr{Cvoid},
                          context_id::Clong,
                          user_handle::Ptr{Cvoid})
    (model, callback_func) = unsafe_pointer_to_objref(user_handle)::Tuple{Model, Function}
    # Run the `callback_func`.
    callback_func(CallbackContext(model, context), context_id)
    # Exit normally.
    return Cint(0)
end
 """
    cpx_callbacksetfunc(model::Model, context_mask::Clong, callback_func::Function)
 Set the general callback function of model to `callback_func`.
 `callback_func` is a function that takes two arguments. The first is a
`CallbackContext` instance, and the second is a `Clong` indicating where the
callback is being called from.
 ## Examples
     function my_callback(cb_context::CPLEX.CallbackContext, context_id::Clong)
        CPLEX.cpx_callbackabort(cb_context)
    end
    CPLEX.cpx_callbacksetfunc(model, Clong(0), my_callback)
"""
function cpx_callbacksetfunc(model::Model, context_mask::Clong, callback_func::Function)
    c_callback = @cfunction(
        callback_wrapper, Cint, (Ptr{Cvoid}, Clong, Ptr{Cvoid})
    )
    user_handle = (model, callback_func)::Tuple{Model, Function}
    ret = @cpx_ccall(callbacksetfunc,
        Cint,
        (Ptr{Cvoid}, Ptr{Cvoid}, Clong, Ptr{Cvoid}, Any),
        model.env, model.lp, context_mask, c_callback, user_handle
    )
    if ret != 0
        throw(CplexError(model.env, ret))
    end
    # We need to keep a reference to the callback function so that it isn't
    # garbage collected.
    model.callback = user_handle
    return ret
end
 # int CPXXcallbackabort( CPXCALLBACKCONTEXptr context )
function cpx_callbackabort(callback_data::CallbackContext)

    return_status = @cpx_ccall(callbackabort,
    Cint,
    (Ptr{Cvoid},),
    callback_data.context)

    if return_status != 0
        throw(CplexError(callback_data.env, return_status))
    end
    return return_status
end

#added Nov 24th 2018

function cbgetrelaxedpoint(env::Env, callback_data::CallbackContext, x::Vector{Cdouble}, start::Cint, final::Cint, obj_::Base.RefValue{Cdouble})

    return_status = @cpx_ccall(callbackgetrelaxationpoint,Cint,(
    Ptr{Cvoid},
    Ptr{Cdouble},
    Cint,
    Cint,
    Ptr{Cdouble}
    ),
    callback_data.context, x, start, final, obj_)
    # println("cbgetrelaxedpoint status $return_status")#@
    if return_status != 0
        throw(CplexError(env, return_status))
    end

    return return_status
end

function cbpostheursoln(env::Env,callback_data::CallbackContext,cnt::Cint,ind::Vector{Cint},val::Vector{Cdouble}, obj::Cdouble, strat::CbSolStrat)
    return_status = @cpx_ccall(callbackpostheursoln,Cint,(
    Ptr{Cvoid},
    Cint,
    # ConstPtr{Cint},
    # ConstPtr{Cdouble},
    Ptr{Cint},
    Ptr{Cdouble},
    # Ptr{Cvoid},
    # Ptr{Cvoid},
    Cdouble,
    Cint
    ),
    callback_data.context,cnt,ind,val,obj,strat)

    # println("context is $callback_data.context")#@
    # println("cbpostheursoln status $return_status")
    # println("cbpostheursoln status $stat")#@

    if return_status != 0
        throw(CplexError(env, return_status))
    end
    return return_status
end

function cbaddusercuts(callback_data::CallbackContext, rcnt::Cint, nzcnt::Cint, rhs::Cdouble, sense::Cstring, rmatbeg::Cint, rmatind::Cint, rmatval::Cdouble, purgeable::Cint, lcl::Cint)

    return_status = @cpx_ccall(callbackaddusercuts,
    Cint,
    (Ptr{Cvoid}, Cint, Cint, Ptr{Cdouble}, Ptr{Cstring}, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}, Ptr{Cint}, Ptr{Cint}),
    callback_data.context, rcnt, nzcnt, rhs, sense, rmatbeg, rmatind, rmatval, purgeable, lcl)

    if return_status != 0
        throw(CplexError(callback_data.env, return_status))
    end

    return Cint(0)
end

function cbcandidateispoint(callback_data::CallbackContext, ispoint::Cint)

    return_status = @cpx_ccall(callbackcandidateispoint,
    Cint,
    (Ptr{Cvoid}, Ptr{Cint}),
    callback_data.context, ispoint)

    if return_status != 0
        throw(CplexError(callback_data.env, return_status))
    end

    return Cint(0)
end

function cbcandidateisray(callback_data::CallbackContext, isray::Cint)

    return_status = @cpx_ccall(callbackcandidateisray,
    Cint,
    (Ptr{Cvoid}, Ptr{Cint}),
    callback_data.context, isray)

    if return_status != 0
        throw(CplexError(callback_data.env, return_status))
    end

    return Cint(0)
end

function cbgetcandidatepoint(callback_data::CallbackContext, x::Vector{Cdouble}, bgn::Cint, ed::Cint, obj::Cdouble)

    return_status = @cpx_ccall(callbackgetcandidatepoint,
    Cint,
    (Ptr{Cvoid}, Ptr{Cdouble}, Cint, Cint, Ptr{Cdouble}),
    callback_data.context, x, bgn, ed, obj})

    if return_status != 0
        throw(CplexError(callback_data.env, return_status))
    end

    return Cint(0)
end

function cbgetcandidateray(callback_data::CallbackContext, x::Vector{Cdouble}, bgn::Cint, ed::Cint)

    return_status = @cpx_ccall(callbackgetcandidateray,
    Cint,
    (Ptr{Cvoid}, Ptr{Cdouble}, Cint, Cint),
    callback_data.context, x, bgn, ed})

    if return_status != 0
        throw(CplexError(callback_data.env, return_status))
    end

    return Cint(0)
end
#not sure if this one is right. Will check if ** is translated correctly
function cbgetfunc(model::Model, context_id::Clong, callback_func::Function)

    c_callback = @cfunction(
        callback_wrapper, Cint, (Ptr{Cvoid}, Clong, Ptr{Cvoid})
    )
    user_handle = (model, callback_func)::Tuple{Model, Function}
    ret = @cpx_ccall(callbackgetfunc,
        Cint,
        (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Clong}, Any, Any),
        model.env, model.lp, context_mask, c_callback, user_handle
    )
    if ret != 0
        throw(CplexError(model.env, ret))
    end

    model.callback = user_handle
    return ret
end

function cbgetincumbent(callback_data::CallbackContext, x::Vector{Cdouble}, bgn::Cint, ed::Cint, obj::Cdouble)

    return_status = @cpx_ccall(CPXcallbackgetincumbent,
    Cint,
    (Ptr{Cvoid}, Ptr{Cdouble}, Cint, Cint, Ptr{Cdouble}),
    callback_data.context, x, bgn, ed, obj})

    if return_status != 0
        throw(CplexError(callback_data.env, return_status))
    end

    return Cint(0)
end

function cbgetinfodbl(callback_data::CallbackContext, what::CbInfo, dta::Cdouble)

    return_status = @cpx_ccall(CPXcallbackgetinfodbl,
    Cint,
    (Ptr{Cvoid}, Cint, Ptr{Cdouble}),
    callback_data.context, what, dta})

    if return_status != 0
        throw(CplexError(callback_data.env, return_status))
    end

    return Cint(0)
end

function cbgetinfoint(callback_data::CallbackContext, what::CbInfo, dta::Cint)

    return_status = @cpx_ccall(CPXcallbackgetinfoint,
    Cint,
    (Ptr{Cvoid}, Cint, Ptr{Cint}),
    callback_data.context, what, dta})

    if return_status != 0
        throw(CplexError(callback_data.env, return_status))
    end

    return Cint(0)
end

function cbgetinfolong(callback_data::CallbackContext, what::CbInfo, dta::Clong)

    return_status = @cpx_ccall(CPXcallbackgetinfolong,
    Cint,
    (Ptr{Cvoid}, Cint, Ptr{Clong}),
    callback_data.context, what, dta})

    if return_status != 0
        throw(CplexError(callback_data.env, return_status))
    end

    return Cint(0)
end

function cbrejectcandidate(callback_data::CallbackContext, rcnt::Cint, nzcnt::Cint, rhs::Cdouble, sense::Cstring, rmatbeg::Cint, rmatind::Cint, rmatval::Cdouble)

    return_status = @cpx_ccall(CPXcallbackrejectcandidate,
    Cint,
    (Ptr{Cvoid}, Cint, Cint, Ptr{Cdouble}, Ptr{Cstring}, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}),
    callback_data.context, rcnt, nzcnt, rhs, sense, rmatbeg, rmatind, rmatval)

    if return_status != 0
        throw(CplexError(callback_data.env, return_status))
    end

    return Cint(0)
end
