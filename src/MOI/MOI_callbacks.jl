"""
    CallbackFunction()

Set a generic CPLEX callback function.

Note: before accessing `MOI.CallbackVariablePrimal`, you must call either
`callbackgetcandidatepoint(model::Optimizer, cb_data, cb_where)` or
`callbackgetrelaxationpoint(model::Optimizer, cb_data, cb_where)`.
"""
struct CallbackFunction <: MOI.AbstractCallback end

function MOI.set(model::Optimizer, ::CallbackFunction, f::Function)
    if MOI.get(model, MOI.NumberOfThreads()) != 1
        @warn(
            "When using callbacks, make sure to set `NumberOfThreads` to `1` " *
            "using `MOI.set(model, MOI.NumberOfThreads(), 1)`. Bad things can" *
            " happen if you don't! Only ignore this message if you know what " *
            "you are doing."
        )
    end
    model.has_generic_callback = true
    context_mask =
        CPX_CALLBACKCONTEXT_THREAD_UP |
        CPX_CALLBACKCONTEXT_THREAD_DOWN |
        CPX_CALLBACKCONTEXT_LOCAL_PROGRESS |
        CPX_CALLBACKCONTEXT_GLOBAL_PROGRESS |
        CPX_CALLBACKCONTEXT_CANDIDATE |
        CPX_CALLBACKCONTEXT_RELAXATION
    CPLEX.cbsetfunc(model.inner, context_mask, (cb_data, cb_where) -> begin
        model.callback_state = CB_GENERIC
        f(cb_data, cb_where)
        model.callback_state = CB_NONE
    end)
    return
end
MOI.supports(::Optimizer, ::CallbackFunction) = true

"""
    callbackgetcandidatepoint(model::Optimizer, cb_data, cb_where)

Load the solution at a CPX_CALLBACKCONTEXT_CANDIDATE node so that it can be
accessed using `MOI.CallbackVariablePrimal`.
"""
function callbackgetcandidatepoint(model::Optimizer, cb_data, cb_where)
    N = length(model.variable_info)
    resize!(model.callback_variable_primal, N)
    CPLEX.cbgetcandidatepoint(
        cb_data, model.callback_variable_primal, Cint(0), Cint(N - 1), Ref{Float64}()
    )
    return
end

"""
    callbackgetrelaxationpoint(model::Optimizer, cb_data, cb_where)

Load the solution at a CB_MIPNODE node so that it can be accessed using
`MOI.CallbackVariablePrimal`.
"""
function callbackgetrelaxationpoint(model::Optimizer, cb_data, cb_where)
    N = length(model.variable_info)
    resize!(model.callback_variable_primal, N)
    CPLEX.cbgetrelaxationpoint(
        cb_data, model.callback_variable_primal, Cint(0), Cint(N - 1), Ref{Float64}()
    )
    return
end

# ==============================================================================
#    MOI callbacks
# ==============================================================================

function default_moi_callback(model::Optimizer)
    if MOI.get(model, MOI.NumberOfThreads()) != 1
        # The current callback system isn't thread-safe. As a work-around, set
        # the number of threads to 1, regardless of what the user intended.
        # We only do this for the MOI callbacks, since we assume the user knows
        # what they are doing if they use a solver-dependent callback.
        MOI.set(model, MOI.NumberOfThreads(), 1)
    end
    return (cb_data, cb_where) -> begin
    if cb_where == CPX_CALLBACKCONTEXT_CANDIDATE
        if cbcandidateispoint(cb_data) == 0
            return  # No candidate point available
        end
        callbackgetcandidatepoint(model, cb_data, cb_where)
        if model.lazy_callback !== nothing
            model.callback_state = CB_LAZY
            model.lazy_callback(cb_data)
        end
    elseif cb_where == CPX_CALLBACKCONTEXT_RELAXATION
        callbackgetrelaxationpoint(model, cb_data, cb_where)        
            if model.user_cut_callback !== nothing
                model.callback_state = CB_USER_CUT
                model.user_cut_callback(cb_data)
            end
            if model.heuristic_callback !== nothing
                model.callback_state = CB_HEURISTIC
                model.heuristic_callback(cb_data)
            end
        end
        model.callback_state = CB_NONE
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
    if model.callback_state == CB_USER_CUT
        throw(MOI.InvalidCallbackUsage(MOI.UserCutCallback(), cb))
    elseif model.callback_state == CB_HEURISTIC
        throw(MOI.InvalidCallbackUsage(MOI.HeuristicCallback(), cb))
    elseif !iszero(f.constant)
        throw(MOI.ScalarFunctionConstantNotZero{Float64, typeof(f), typeof(s)}(f.constant))
    end
    indices, coefficients = _indices_and_coefficients(model, f)
    sense, rhs = _sense_and_rhs(s)
    CPLEX.cbrejectcandidate(
        cb.callback_data,
        Cint(1),
        Cint(length(coefficients)),
        Float64[rhs],
        Cchar[sense],
        Cint[0],
        indices .- Cint(1),
        coefficients
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
    s::Union{MOI.LessThan{Float64}, MOI.GreaterThan{Float64}, MOI.EqualTo{Float64}}
)
    if model.callback_state == CB_LAZY
        throw(MOI.InvalidCallbackUsage(MOI.LazyConstraintCallback(), cb))
    elseif model.callback_state == CB_HEURISTIC
        throw(MOI.InvalidCallbackUsage(MOI.HeuristicCallback(), cb))
    elseif !iszero(f.constant)
        throw(MOI.ScalarFunctionConstantNotZero{Float64, typeof(f), typeof(s)}(f.constant))
    end
    indices, coefficients = _indices_and_coefficients(model, f)
    sense, rhs = _sense_and_rhs(s)
    CPLEX.cbaddusercuts(
        cb.callback_data,
        Cint(1),
        Cint(length(coefficients)),
        [rhs],
        [sense],
        Cint[0],
        indices .- Cint(1),
        coefficients,
        [CPX_USECUT_FILTER],
        Cint[0]
    )
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
    values::MOI.Vector{Float64}
)
    if model.callback_state == CB_LAZY
        throw(MOI.InvalidCallbackUsage(MOI.LazyConstraintCallback(), cb))
    elseif model.callback_state == CB_USER_CUT
        throw(MOI.InvalidCallbackUsage(MOI.UserCutCallback(), cb))
    end
    ind = Cint[_info(model, var).column - 1 for var in variables]
    CPLEX.cbpostheursoln(
        cb.callback_data, Cint(1), ind, values, NaN, CPXCALLBACKSOLUTION_SOLVE
    )
    return MOI.HEURISTIC_SOLUTION_UNKNOWN
end
MOI.supports(::Optimizer, ::MOI.HeuristicSolution{CallbackContext}) = true
