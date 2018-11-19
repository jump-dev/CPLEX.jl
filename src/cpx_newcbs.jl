mutable struct CallbackContext
    model::Model
    context::Ptr{Void}
end

function callback_wrapper(context::Ptr{Void},
                          context_id::Clong,
                          user_handle::Ptr{Void})
    (model, user_callback) = unsafe_pointer_to_objref(user_handle)::Tuple{Model, Function}
    # Run the `user_callback`.
    user_callback(CallbackContext(model, context), context_id)
    # Exit normally.
    return Cint(0)
end
 """
    cpx_callbacksetfunc(model::Model, context_mask::Clong, user_callback::Function)
 Set the general callback function of model to `user_callback`.
 `user_callback` is a function that takes two arguments. The first is a
`CallbackContext` instance, and the second is a `Clong` indicating where the
callback is being called from.
 ## Examples
     function my_callback(cb_context::CPLEX.CallbackContext, context_id::Clong)
        CPLEX.cpx_callbackabort(cb_context)
    end
    CPLEX.cpx_callbacksetfunc(model, Clong(0), my_callback)
"""
function cpx_callbacksetfunc(model::Model, context_mask::Clong, user_callback::Function)
    c_callback = cfunction(
        callback_wrapper, Cint, (Ptr{Void}, Clong, Ptr{Void})
    )
    user_handle = (model, user_callback)::Tuple{Model, Function}
    ret = @cpx_ccall(callbacksetfunc,
        Cint,
        (Ptr{Void}, Ptr{Void}, Clong, Ptr{Void}, Any),
        model.env, model.lp, context_mask, c_callback, user_handle
    )
    if ret != 0
        throw(CplexError(model.env, ret))
    end
    # We need to keep a reference to the callback function so that it isn't
    # garbage collected.
    model.callback = user_handle
    return
end
 # int CPXXcallbackabort( CPXCALLBACKCONTEXptr context )
function cpx_callbackabort(callback_data::CallbackContext)

    return_status = @cpx_ccall(callbackabort,
    Cint,
    (Ptr{Void},),
    callback_data.context)

    if return_status != 0
        throw(CplexError(callback_data.env, return_status))
    end
    return
end
