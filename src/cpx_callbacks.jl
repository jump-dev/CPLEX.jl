type CallbackData
    cbdata::Ptr{Void}
    model::Model
end

function cplex_callback_wrapper(ptr_model::Ptr{Void}, cbdata::Ptr{Void}, where::Cint, userdata::Ptr{Void})

    callback,model = unsafe_pointer_to_objref(userdata)::(Function,Model)
    callback(CallbackData(cbdata,model), where)
    return convert(Cint,0)
end

# User callback function should be of the form:
# callback(cbdata::CallbackData, where::Cint)

function set_callback_func!(model::Model, callback::Function)
    
    cpxcallback = cfunction(cplex_callback_wrapper, Cint, (Ptr{Void}, Ptr{Void}, Cint, Ptr{Void}))
    # Not correct, Cplex does not have a monolithic callback setting function
    stat = @cpx_ccall(setcallbackfunc, Cint, (Ptr{Void}, Ptr{Void}, Any), model.ptr_model, cpxcallback, (callback,model))
    if stat != 0
        throw(CplexError(model.env, stat))
    end
    # we need to keep a reference to the callback function
    # so that it isn't garbage collected
    model.callback = callback
    nothing
end

# these are to be used if calling directly from Cplex.jl w/o MathProgBase
export CallbackData, set_callback_func!

function setcallbackcut(cbdata::CallbackData, where::Cint, ind::Vector{Cint}, val::Vector{Cdouble}, sense::Char, rhs::Cdouble)
    len = length(ind)
    @assert length(val) == len
    sns = convert(Cint, sense)
    ## the last argument, purgeable, describes Cplex's treatment of the cut, i.e. whether it has liberty to drop it later in the tree.
    ## should really have default and then allow user override
    stat = @cpx_ccall(cutcallbackadd, Cint, (
                      Ptr{Void},
                      Ptr{Void},
                      Cint,
                      Cint,
                      Cdouble,
                      Cint,
                      Ptr{Cint},
                      Ptr{Cdouble},
                      Cint
                      ),
                      cbdata.model.env, cbdata.cbdata, where, len, rhs, sns, ind-1, val, 0) # CPX_USECUT_FORCE = 0
    if stat != 0
        throw(CplexError(cbdata.model.env.ptr, stat))
    end
end

cbcut(cbdata::CallbackData, where::Integer, ind::Vector{Cint}, val::Vector{Cdouble}, sense::Char, rhs::Cdouble) = setcallbackcut(cbdata, where, ind, val, sense, rhs)

cblazy(cbdata::CallbackData, where::Integer, ind::Vector{Cint}, val::Vector{Cdouble}, sense::Char, rhs::Cdouble) = setcallbackcut(cbdata, where, ind, val, sense, rhs)

export cbcut, cblazy

# function cbsolution(cbdata::CallbackData, sol::Vector{Cdouble})
#     nvar = num_vars(cbdata.model)
#     @assert length(sol) >= nvar
# ## note: this is not right. getcallbacknodex returns the subproblem LP soln
#     stat = @cpx_ccall(getcallbacknodex, Cint, (
#                       Ptr{Void},
#                       Ptr{Void},
#                       Cint,
#                       Ptr{Cdouble},
#                       Cint,
#                       Cint
#                       ),
#                       cdbdata.model.env, cbdata.cbdata, wherefrom, sol, 0, nvar)
#     if stat != 0
#         throw(CplexError(cbdata.model.env, ret))
#     end
# end

# cbsolution(cbdata::CallbackData) = cbsolution(cbdata, Array(Cdouble, num_vars(cbdata.model)))

# function cbget{T}(::Type{T},cbdata::CallbackData, where::Cint, what::Integer)
    
#     out = Array(T,1)
#     stat = @cpx_ccall(getcallbackinfo, Cint, (
#                       Ptr{Void}, 
#                       Ptr{Void},
#                       Cint, 
#                       Cint, 
#                       Ptr{T}
#                       ),
#                       cbdata.model.env.ptr, cbdata.cbdata, where, what, out)
#     if stat != 0
#         throw(CplexError(cbdata.model.env, stat))
#     end
#     return out[1]
# end

# function cbdet_mipsol_objbst(d.cbdata, d.where) 

# end

# function cbget_mipnode_objbst(d.cbdata, d.where)

# end

# TODO: think we want solution vector for this function, not obj. val
function cbget_mipnode_rel(cbdata::CallbackData, where::Integer)
  sol = Array(Cdouble, 1)
  stat = @cpx_ccall(getcallbacknodeobjval, Cint, (
                    Ptr{Void},
                    Ptr{Void},
                    Cint,
                    Ptr{Cdouble}
                    ),
                    cbdata.model.env.ptr, cbdata.cbdata, where, sol)
  if stat != 0
    throw(CplexError(cbdata.model.env, stat))
  end
  return sol[1]
end

function cbget_mipsol_sol(cbdata::CallbackData, where::Integer)
    nvar = num_var(cbdata.model)
    sol = Array(Cdouble, nvar)
    # stat = @cpx_ccall(getcallbackincumbent, Cint, (
    #                   Ptr{Void},
    #                   Ptr{Void},
    #                   Cint,
    #                   Ptr{Cdouble},
    #                   Cint,
    #                   Cint
    #                   ),
    #                   cbdata.model.env, cbdata.cbdata, where, sol, 0, nvar-1)
    stat = @cpx_ccall(getcallbacknodex, Cint, (
                      Ptr{Void},
                      Ptr{Void},
                      Cint,
                      Ptr{Cdouble},
                      Cint,
                      Cint
                      ),
                      cbdata.model.env, cbdata.cbdata, where, sol, 0, nvar-1)
    if stat != 0
      # throw(CplexError(cbdata.model.env, stat))
      error(CplexError(cbdata.model.env, stat).msg)
    end
    return sol
end

# cbget_nodcnt(cbdata::CallbackData, where::Integer)
#   stat = @cpx_ccall(getcallbacknodeinfo, Cint, (
#                     Ptr{Void},
#                     Ptr{Void},
#                     Cint,
#                     Cint,
#                     Cint,
#                     Ptr{Void}
#                     ),
#                     cbdata.model.env, cbdata.cbdata, where, nodeindex, whichinfo, result_p)
#   if stat != 0
#     throw(CplexError(cbdata.model.env, ret))
#   end
#   return result_p[1]
# end
