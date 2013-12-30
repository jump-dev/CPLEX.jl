type CallbackData
    cbdata::Ptr{Void}
    model::Model
end

export CallbackData

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

cbget_mipsol_sol(cbdata::CallbackData, where::Integer) = cbget_mipsol_sol(cbdata, where, Array(Cdouble, num_var(cbdata.model)))

function cbget_mipsol_sol(cbdata::CallbackData, where::Integer, sol::Array{Cdouble})
    nvar = num_var(cbdata.model)
    # sol = Array(Cdouble, nvar)
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
