mutable struct CallbackContext
    model::Optimizer
    ptr::Ptr{Cvoid}
end
Base.cconvert(::Type{Ptr{Cvoid}}, x::CallbackContext) = x
Base.unsafe_convert(::Type{Ptr{Cvoid}}, x::CallbackContext) = x.ptr::Ptr{Cvoid}

mutable struct _CallbackUserData
    model::Optimizer
    callback::Function
end
Base.cconvert(::Type{Ptr{Cvoid}}, x::_CallbackUserData) = x
function Base.unsafe_convert(::Type{Ptr{Cvoid}}, x::_CallbackUserData)
    return pointer_from_objref(x)::Ptr{Cvoid}
end

function _cplex_callback_wrapper(
    p_context::Ptr{Cvoid},
    context_id::Clong,
    p_user_data::Ptr{Cvoid},
)
    user_data = unsafe_pointer_to_objref(p_user_data)::_CallbackUserData
    try
        user_data.callback(
            CallbackContext(user_data.model, p_context), context_id
        )
    catch ex
        CPXcallbackabort(p_context)
        if !(ex isa InterruptException)
            rethrow(ex)
        end
    end
    return Cint(0)
end

"""
    column(cb_data::CallbackContext, x::MOI.VariableIndex)

Return the 1-indexed column associated with `x` in a callback.

The C API requires 0-indexed columns.
"""
function column(cb_data::CallbackContext, x::MOI.VariableIndex)
    return _info(cb_data.model, x).column
end

"""
    CallbackFunction(
        context_mask::UInt16 =
            CPX_CALLBACKCONTEXT_THREAD_UP |
            CPX_CALLBACKCONTEXT_THREAD_DOWN |
            CPX_CALLBACKCONTEXT_LOCAL_PROGRESS |
            CPX_CALLBACKCONTEXT_GLOBAL_PROGRESS |
            CPX_CALLBACKCONTEXT_CANDIDATE |
            CPX_CALLBACKCONTEXT_RELAXATION |
            CPX_CALLBACKCONTEXT_BRANCHING
        )
    )

Set a generic CPLEX callback function. Use `context_mask` to control where the
callback is called from.

Callback must be a function with signature:

    callback(cb_data::CallbackContext, context_id::Clong)

Before accessing `MOI.CallbackVariablePrimal`, you must call
`CPLEX.load_callback_variable_primal(cb_data, context_id)`.
"""
struct CallbackFunction <: MOI.AbstractCallback
    context_mask::UInt16

    function CallbackFunction(
        context_mask::UInt16 =
            CPX_CALLBACKCONTEXT_THREAD_UP |
            CPX_CALLBACKCONTEXT_THREAD_DOWN |
            CPX_CALLBACKCONTEXT_LOCAL_PROGRESS |
            CPX_CALLBACKCONTEXT_GLOBAL_PROGRESS |
            CPX_CALLBACKCONTEXT_CANDIDATE |
            CPX_CALLBACKCONTEXT_RELAXATION |
            CPX_CALLBACKCONTEXT_BRANCHING
    )
        return new(context_mask)
    end
end

function MOI.set(model::Optimizer, cb::CallbackFunction, f::Function)
    if MOI.get(model, MOI.NumberOfThreads()) != 1
        @warn(
            "When using callbacks, make sure to set `NumberOfThreads` to `1` " *
            "using `MOI.set(model, MOI.NumberOfThreads(), 1)`. Bad things can" *
            " happen if you don't! Only ignore this message if you know what " *
            "you are doing."
        )
    end
    cpx_callback = @cfunction(
        _cplex_callback_wrapper, Cint, (Ptr{Cvoid}, Clong, Ptr{Cvoid})
    )
    user_data = _CallbackUserData(
        model,
        (context, context_id) -> begin
            model.callback_state = _CB_GENERIC
            f(context::CallbackContext, context_id::Clong)
            model.callback_state = _CB_NONE
        end
    )
    ret = CPXcallbacksetfunc(
        model.env,
        model.lp,
        cb.context_mask,
        cpx_callback,
        user_data,
    )
    _check_ret(model, ret)
    model.generic_callback = user_data
    model.has_generic_callback = true
    return
end
MOI.supports(::Optimizer, ::CallbackFunction) = true

"""
    load_callback_variable_primal(cb_data, context_id)

Load the solution during a callback so that it can be accessed using
`MOI.CallbackVariablePrimal`.
"""
function load_callback_variable_primal(
    cb_data::CallbackContext, context_id::Clong
)
    model = cb_data.model::Optimizer
    N = length(model.variable_info)
    resize!(model.callback_variable_primal, N)
    if context_id == CPX_CALLBACKCONTEXT_CANDIDATE
        ret = CPXcallbackgetcandidatepoint(
            cb_data,
            model.callback_variable_primal,
            Cint(0),
            Cint(N - 1),
            C_NULL,
        )
    elseif context_id == CPX_CALLBACKCONTEXT_RELAXATION
        ret = CPXcallbackgetrelaxationpoint(
            cb_data,
            model.callback_variable_primal,
            Cint(0),
            Cint(N - 1),
            C_NULL,
        )
    else
        error(
            "`load_callback_variable_primal` can only be called at " *
            "CPX_CALLBACKCONTEXT_CANDIDATE or CPX_CALLBACKCONTEXT_RELAXATION."
        )
    end
    return
end

# ==============================================================================
#    MOI callbacks
# ==============================================================================

function _default_moi_callback(model::Optimizer)
    if MOI.get(model, MOI.NumberOfThreads()) != 1
        # The current callback system isn't thread-safe. As a work-around, set
        # the number of threads to 1, regardless of what the user intended.
        # We only do this for the MOI callbacks, since we assume the user knows
        # what they are doing if they use a solver-dependent callback.
        MOI.set(model, MOI.NumberOfThreads(), 1)
    end
    return (cb_data, cb_context) -> begin
        if cb_context == CPX_CALLBACKCONTEXT_CANDIDATE
            ispoint_p = Ref{Cint}()
            ret = CPXcallbackcandidateispoint(cb_data, ispoint_p)
            _check_ret(cb_data.model, ret)
            if ispoint_p[] == 0
                return  # No candidate point available
            end
            load_callback_variable_primal(cb_data, cb_context)
            if model.lazy_callback !== nothing
                model.callback_state = _CB_LAZY
                model.lazy_callback(cb_data)
            end
        elseif cb_context == CPX_CALLBACKCONTEXT_RELAXATION
            load_callback_variable_primal(cb_data, cb_context)
            if model.user_cut_callback !== nothing
                model.callback_state = _CB_USER_CUT
                model.user_cut_callback(cb_data)
            end
            if model.heuristic_callback !== nothing
                model.callback_state = _CB_HEURISTIC
                model.heuristic_callback(cb_data)
            end
        end
        model.callback_state = _CB_NONE
    end
end

function MOI.get(
    model::Optimizer,
    ::MOI.CallbackVariablePrimal{CallbackContext},
    x::MOI.VariableIndex
)
    return model.callback_variable_primal[_info(model, x).column]
end

# ==============================================================================
#    MOI.LazyConstraint
# ==============================================================================

function MOI.set(model::Optimizer, ::MOI.LazyConstraintCallback, cb::Function)
    model.lazy_callback = cb
    return
end
MOI.supports(::Optimizer, ::MOI.LazyConstraintCallback) = true

function MOI.submit(
    model::Optimizer,
    cb::MOI.LazyConstraint{CallbackContext},
    f::MOI.ScalarAffineFunction{Float64},
    s::Union{MOI.LessThan{Float64}, MOI.GreaterThan{Float64}, MOI.EqualTo{Float64}}
)
    if model.callback_state == _CB_USER_CUT
        throw(MOI.InvalidCallbackUsage(MOI.UserCutCallback(), cb))
    elseif model.callback_state == _CB_HEURISTIC
        throw(MOI.InvalidCallbackUsage(MOI.HeuristicCallback(), cb))
    elseif !iszero(f.constant)
        throw(MOI.ScalarFunctionConstantNotZero{Float64, typeof(f), typeof(s)}(f.constant))
    end
    indices, coefficients = _indices_and_coefficients(model, f)
    sense, rhs = _sense_and_rhs(s)
    ret = CPXcallbackrejectcandidate(
        cb.callback_data,
        Cint(1),
        Cint(length(coefficients)),
        Ref(rhs),
        Ref{Cchar}(sense),
        Ref{Cint}(0),
        indices,
        coefficients,
    )
    return
end
MOI.supports(::Optimizer, ::MOI.LazyConstraint{CallbackContext}) = true

# ==============================================================================
#    MOI.UserCutCallback
# ==============================================================================

function MOI.set(model::Optimizer, ::MOI.UserCutCallback, cb::Function)
    model.user_cut_callback = cb
    return
end
MOI.supports(::Optimizer, ::MOI.UserCutCallback) = true

function MOI.submit(
    model::Optimizer,
    cb::MOI.UserCut{CallbackContext},
    f::MOI.ScalarAffineFunction{Float64},
    s::Union{
        MOI.LessThan{Float64}, MOI.GreaterThan{Float64}, MOI.EqualTo{Float64}
    },
)
    if model.callback_state == _CB_LAZY
        throw(MOI.InvalidCallbackUsage(MOI.LazyConstraintCallback(), cb))
    elseif model.callback_state == _CB_HEURISTIC
        throw(MOI.InvalidCallbackUsage(MOI.HeuristicCallback(), cb))
    elseif !iszero(f.constant)
        throw(MOI.ScalarFunctionConstantNotZero{Float64, typeof(f), typeof(s)}(f.constant))
    end
    rmatind, rmatval = _indices_and_coefficients(model, f)
    sense, rhs = _sense_and_rhs(s)
    ret = CPXcallbackaddusercuts(
        cb.callback_data,
        Cint(1),
        Cint(length(rmatval)),
        Ref(rhs),
        Ref(sense),
        Ref{Cint}(0),
        rmatind,
        rmatval,
        Ref{Cint}(CPX_USECUT_FILTER),
        Ref{Cint}(0),
    )
    _check_ret(model, ret)
    return
end
MOI.supports(::Optimizer, ::MOI.UserCut{CallbackContext}) = true

# ==============================================================================
#    MOI.HeuristicCallback
# ==============================================================================

function MOI.set(model::Optimizer, ::MOI.HeuristicCallback, cb::Function)
    model.heuristic_callback = cb
    return
end
MOI.supports(::Optimizer, ::MOI.HeuristicCallback) = true

function MOI.submit(
    model::Optimizer,
    cb::MOI.HeuristicSolution{CallbackContext},
    variables::Vector{MOI.VariableIndex},
    values::MOI.Vector{Float64},
)
    if model.callback_state == _CB_LAZY
        throw(MOI.InvalidCallbackUsage(MOI.LazyConstraintCallback(), cb))
    elseif model.callback_state == _CB_USER_CUT
        throw(MOI.InvalidCallbackUsage(MOI.UserCutCallback(), cb))
    end
    ret = CPXcallbackpostheursoln(
        cb.callback_data,
        Cint(1),
        Cint[_info(model, var).column - 1 for var in variables],
        values,
        NaN,
        CPXCALLBACKSOLUTION_SOLVE,
    )
    _check_ret(model, ret)
    return MOI.HEURISTIC_SOLUTION_UNKNOWN
end
MOI.supports(::Optimizer, ::MOI.HeuristicSolution{CallbackContext}) = true
