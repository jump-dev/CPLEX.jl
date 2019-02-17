@enum(CbSolStrat, CPXCALLBACKSOLUTION_CHECKFEAS, CPXCALLBACKSOLUTION_PROPAGATE)

@enum(CbInfo,
    CPXCALLBACKINFO_THREADID, CPXCALLBACKINFO_NODECOUNT,
    CPXCALLBACKINFO_ITCOUNT, CPXCALLBACKINFO_BEST_SOL, CPXCALLBACKINFO_BEST_BND,
    CPXCALLBACKINFO_THREADS, CPXCALLBACKINFO_FEASIBLE, CPXCALLBACKINFO_TIME,
    CPXCALLBACKINFO_DETTIME)

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

function return_status_or_throw(model, status)
    if status != 0
        throw(CplexError(model.env, status))
    else
        return status
    end
end

 """
    cpx_callbacksetfunc(model::Model, context_mask::Clong, callback_func::Function)

Set the general callback function of model to `callback_func`.

`callback_func` is a function that takes two arguments. The first is a
`CallbackContext` instance, and the second is a `Clong` indicating where the
callback is being called from.

### Examples

     function my_callback(cb_context::CPLEX.CallbackContext, context_id::Clong)
        CPLEX.cpx_callbackabort(cb_context)
    end
    CPLEX.cpx_callbacksetfunc(model, Clong(0), my_callback)
"""
function cbsetfunc(model::Model, context_mask::Clong, callback_func::Function)
    c_callback = @cfunction(callback_wrapper, Cint, (Ptr{Cvoid}, Clong, Ptr{Cvoid}))
    user_handle = (model, callback_func)::Tuple{Model, Function}
    return_status = @cpx_ccall(callbacksetfunc,
                    Cint,
                    (Ptr{Cvoid}, Ptr{Cvoid}, Clong, Ptr{Cvoid}, Any),
                    model.env, model.lp, context_mask, c_callback, user_handle)
    # We need to keep a reference to the callback function so that it isn't
    # garbage collected.
    model.callback = user_handle
    return return_status_or_throw(model, return_status)
end

function cbabort(callback_data::CallbackContext)
    return_status = @cpx_ccall(
        callbackabort, Cint, (Ptr{Cvoid},), callback_data.context)
    return return_status_or_throw(callback_data.model, return_status)
end

function cbgetrelaxationpoint(
        callback_data::CallbackContext, x::Vector{Float64}, begin_index::Int,
        end_index::Int, obj::Ref{Float64})
    return_status = @cpx_ccall(callbackgetrelaxationpoint,
        Cint,
        (Ptr{Cvoid}, Ptr{Cdouble}, Cint, Cint, Ptr{Cdouble}),
        callback_data.context, x, begin_index - 1, end_index - 1, obj)
    return return_status_or_throw(callback_data.model, return_status)
end

function cbpostheursoln(
        callback_data::CallbackContext, num_entries::Int, columns::Vector{Int},
        values::Vector{Cdouble}, objective_value::Cdouble, strat::CbSolStrat)
    return_status = @cpx_ccall(callbackpostheursoln,
        Cint,
        (Ptr{Cvoid}, Cint, Ptr{Cint}, Ptr{Cdouble}, Cdouble, Cint),
        callback_data.context, num_entries, columns .- 1, values,
            objective_value, strat)
    return return_status_or_throw(callback_data.model, return_status)
end

function cbaddusercuts(
        callback_data::CallbackContext, reject_count::Int, nonzero_count::Int,
        rhs::Cdouble, sense::Char, sparse_index_begin::Vector{Int},
        sparse_index::Vector{Int}, sparse_index_coeff::Vector{Cdouble},
        purgeable::Int, lcl::Int)
    return_status = @cpx_ccall(callbackaddusercuts,
        Cint,
        (Ptr{Cvoid}, Cint, Cint, Ref{Cdouble}, Ptr{UInt8}, Ptr{Cint}, Ptr{Cint},
            Ptr{Cdouble}, Ptr{Cint}, Ptr{Cint}),
        callback_data.context, reject_count, nonzero_count, rhs, string(sense),
            sparse_index_begin .- 1, sparse_index .- 1, sparse_index_coeff,
            purgeable, lcl)
    return return_status_or_throw(callback_data.model, return_status)
end

# Check if the callback for the context CPX_CALLBACKCONTEXT_CANDIDATE is invoked by a feasible integer point
function cbcandidateispoint(callback_data::CallbackContext, is_point::Int)
    return_status = @cpx_ccall(callbackcandidateispoint,
        Cint, (Ptr{Cvoid}, Ptr{Cint}), callback_data.context, is_point)
    return return_status_or_throw(callback_data.model, return_status)
end

# Check if the callback for the context CPX_CALLBACKCONTEXT_CANDIDATE is invoked by an unbounded relaxation
function cbcandidateisray(callback_data::CallbackContext, is_ray::Int)
    return_status = @cpx_ccall(callbackcandidateisray,
        Cint, (Ptr{Cvoid}, Ptr{Cint}), callback_data.context, is_ray)
    return return_status_or_throw(callback_data.model, return_status)
end

function cbgetcandidatepoint(
        callback_data::CallbackContext, x::Vector{Float64}, begin_index::Int,
        end_index::Int, obj::Ref{Float64})
    return_status = @cpx_ccall(callbackgetcandidatepoint,
        Cint,
        (Ptr{Cvoid}, Ptr{Cdouble}, Cint, Cint, Ref{Cdouble}),
        callback_data.context, x, begin_index - 1, end_index - 1, obj)
    return return_status_or_throw(callback_data.model, return_status)
end

function cbgetcandidateray(
        callback_data::CallbackContext, x::Vector{Cdouble}, begin_index::Int,
        end_index::Int)
    return_status = @cpx_ccall(callbackgetcandidateray,
        Cint,
        (Ptr{Cvoid}, Ptr{Cdouble}, Cint, Cint),
        callback_data.context, x, begin_index - 1, end_index - 1)
    return return_status_or_throw(callback_data.model, return_status)
end

# This function may have bug, should be tested.
# function cbgetfunc(model::Model, context_id::Clong, callback_func::Function)
#     c_callback = @cfunction(callback_wrapper, Cint, (Ptr{Cvoid}, Clong, Ptr{Cvoid}))
#     user_handle = (model, callback_func)::Tuple{Model, Function}
#     return_status = @cpx_ccall(callbackgetfunc,
#                     Cint,
#                     (Ptr{Cvoid}, Ptr{Cvoid}, Ref{Clong}, Ptr{Cvoid}, Any),
#                     model.env, model.lp, context_mask, c_callback, user_handle)
#     if return_status != 0
#         throw(CplexError(model.env, return_status))
#     end
#     model.callback = user_handle
#     return return_status
# end

function cbgetincumbent(
        callback_data::CallbackContext, x::Vector{Cdouble}, begin_index::Int,
        end_index::Int, obj::Ref{Float64})
    return_status = @cpx_ccall(callbackgetincumbent,
        Cint,
        (Ptr{Cvoid}, Ptr{Cdouble}, Cint, Cint, Ref{Cdouble}),
        callback_data.context, x, begin_index - 1, end_index - 1, obj)
    return return_status_or_throw(callback_data.model, return_status)
end

function cbgetinfodbl(
        callback_data::CallbackContext, cbinfo::CbInfo, data_p::Cdouble)
    return_status = @cpx_ccall(callbackgetinfodbl,
        Cint,
        (Ptr{Cvoid}, Cint, Ref{Cdouble}),
        callback_data.context, cbinfo, data_p)
    return return_status_or_throw(callback_data.model, return_status)
end

function cbgetinfoint(
        callback_data::CallbackContext, cbinfo::CbInfo, data_p::Int)
    return_status = @cpx_ccall(callbackgetinfoint,
        Cint,
        (Ptr{Cvoid}, Cint, Ref{Cint}),
        callback_data.context, cbinfo, data_p)
    return return_status_or_throw(callback_data.model, return_status)
end

function cbgetinfolong(
        callback_data::CallbackContext, cbinfo::CbInfo, data_p::Clong)
    return_status = @cpx_ccall(callbackgetinfolong,
        Cint,
        (Ptr{Cvoid}, Cint, Ref{Clong}),
        callback_data.context, cbinfo, data_p)
    return return_status_or_throw(callback_data.model, return_status)
end

function cbrejectcandidate(
        callback_data::CallbackContext, reject_count::Int, nonzero_count::Int,
        rhs::Cdouble, sense::Char, sparse_index_begin::Vector{Int},
        sparse_index::Vector{Int}, sparse_index_coeff::Vector{Cdouble})
    return_status = @cpx_ccall(callbackrejectcandidate,
        Cint,
        (Ptr{Cvoid}, Cint, Cint, Ref{Cdouble}, Ptr{UInt8}, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}),
        callback_data.context, reject_count, nonzero_count, rhs, string(sense),
            sparse_index_begin .- 1, sparse_index .- 1, sparse_index_coeff)
    return return_status_or_throw(callback_data.model, return_status)
end

function cbgetlocallb(
        callback_data::CallbackContext, lb::Vector{Cdouble}, begin_index::Int,
        end_index::Int)
    return_status = @cpx_ccall(callbackgetlocallb,
        Cint,
        (Ptr{Cvoid}, Ptr{Cdouble}, Cint, Cint),
        callback_data.context, lb, begin_index - 1, end_index - 1)
    return return_status_or_throw(callback_data.model, return_status)
end

function cbgetlocalub(
        callback_data::CallbackContext, ub::Vector{Cdouble}, begin_index::Int,
        end_index::Int)
    return_status = @cpx_ccall(callbackgetlocalub,
        Cint,
        (Ptr{Cvoid}, Ptr{Cdouble}, Cint, Cint),
        callback_data.context, ub, begin_index - 1, end_index - 1)
    return return_status_or_throw(callback_data.model, return_status)
end

function cbgetgloballb(
        callback_data::CallbackContext, lb::Vector{Cdouble}, begin_index::Int,
        end_index::Int)
    return_status = @cpx_ccall(callbackgetgloballb,
        Cint,
        (Ptr{Cvoid}, Ptr{Cdouble}, Cint, Cint),
        callback_data.context, lb, begin_index - 1, end_index - 1)
    return return_status_or_throw(callback_data.model, return_status)
end

function cbgetglobalub(
        callback_data::CallbackContext, ub::Vector{Cdouble}, begin_index::Int,
        end_index::Int)
    return_status = @cpx_ccall(callbackgetglobalub,
        Cint,
        (Ptr{Cvoid}, Ptr{Cdouble}, Cint, Cint),
        callback_data.context, ub, begin_index - 1, end_index - 1)
    return return_status_or_throw(callback_data.model, return_status)
end
