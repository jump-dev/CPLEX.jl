function cpx_lpopt!(model::Model)
  @assert is_valid(model.env)
  stat = @cpx_ccall_intercept(model, lpopt, Cint, (Ptr{Void}, Ptr{Void}), model.env.ptr, model.lp)
  if stat != 0
    throw(CplexError(model.env, stat))
  end
end
function cpx_mipopt!(model::Model)
    #=
        See the comment above cpx_addmipstarts!
    =#
    cols = [i for i in 1:length(model.mipstarts) if !isnan(model.mipstarts[i])]
    vals = [model.mipstarts[i] for i in 1:length(model.mipstarts) if !isnan(model.mipstarts[i])]
    if length(cols) > 0
        cpx_addmipstarts!(model, cols, vals, model.mipstart_effort)
    end

    @assert is_valid(model.env)
    stat = @cpx_ccall_intercept(model, mipopt, Cint, (Ptr{Void}, Ptr{Void}), model.env.ptr, model.lp)
    if stat != 0
        throw(CplexError(model.env, stat))
    end
end
function cpx_qpopt!(model::Model)
  @assert is_valid(model.env)
  stat = @cpx_ccall_intercept(model, qpopt, Cint, (Ptr{Void}, Ptr{Void}), model.env.ptr, model.lp)
  if stat != 0
    throw(CplexError(model.env, stat))
  end
end

cpx_getstat(model::Model) = @cpx_ccall(getstat, Cint, (Ptr{Void}, Ptr{Void}), model.env.ptr, model.lp)

function cpx_solninfo(model::Model)
    solnmethod = Vector{Cint}(1)
    solntype = Vector{Cint}(1)
    primalfeas = Vector{Cint}(1)
    dualfeas = Vector{Cint}(1)
    @cpx_ccall_error(model.env, solninfo, Cint, (
                      Ptr{Void},
                      Ptr{Void},
                      Ptr{Cint},
                      Ptr{Cint},
                      Ptr{Cint},
                      Ptr{Cint}
                      ),
                      model.env.ptr, model.lp, solnmethod, solntype, primalfeas, dualfeas)
    solnmethod[1], solntype[1], primalfeas[1], dualfeas[1]
end

function cpx_getobjval(model::Model)
  objval = Vector{Cdouble}(1)
  @cpx_ccall_error(model.env, getobjval, Cint, (
                    Ptr{Void},
                    Ptr{Void},
                    Ptr{Cdouble}
                    ),
                    model.env.ptr, model.lp, objval)
  return objval[1]
end

"""
    Variable Primal Solution
"""
function cpx_getx(model::Model)
    nvars = cpx_getnumcols(model)
    x = Vector{Cdouble}(nvars)
    cpx_getx!(model, x)
    x
end
function cpx_getx!(model::Model, x::Vector{Cdouble})
  @cpx_ccall_error(model.env, getx, Cint, (
                    Ptr{Void},
                    Ptr{Void},
                    Ptr{Cdouble},
                    Cint,
                    Cint
                    ),
                    model.env.ptr, model.lp, x, 0, length(x)-1)
  return x
end

"""
    Variable Dual Solution
"""
function cpx_getdj(model::Model)
    nvars = cpx_getnumcols(model)
    x = Vector{Cdouble}(nvars)
    cpx_getdj!(model, x)
    x
end
function cpx_getdj!(model::Model, x::Vector{Cdouble})
  @cpx_ccall_error(model.env, getdj, Cint, (
                    Ptr{Void},
                    Ptr{Void},
                    Ptr{Cdouble},
                    Cint,
                    Cint
                    ),
                    model.env.ptr, model.lp, x, 0, length(x)-1)
  return x
end

"""
    Constraint Dual Solution
"""
function cpx_getpi(model::Model)
    nvars = cpx_getnumrows(model)
    x = Vector{Cdouble}(nvars)
    cpx_getpi!(model, x)
    x
end
function cpx_getpi!(model::Model, x::Vector{Cdouble})
  @cpx_ccall_error(model.env, getpi, Cint, (
                    Ptr{Void},
                    Ptr{Void},
                    Ptr{Cdouble},
                    Cint,
                    Cint
                    ),
                    model.env.ptr, model.lp, x, 0, length(x)-1)
  return x
end

"""
    Constraint Primal Solution
"""
function cpx_getax(model::Model)
    n = cpx_getnumrows(model)
    x = Vector{Cdouble}(n)
    cpx_getax!(model, x)
    x
end
function cpx_getax!(model::Model, x::Vector{Cdouble})
  @cpx_ccall_error(model.env, getax, Cint, (
                    Ptr{Void},
                    Ptr{Void},
                    Ptr{Cdouble},
                    Cint,
                    Cint
                    ),
                    model.env.ptr, model.lp, x, 0, length(x)-1)
  return x
end

"""
    Infeasibility: Dual Farkas
"""
function cpx_dualfarkas(model::Model)
    ncons = cpx_numrows(model)
    ray = Vector{Cdouble}(ncons)
    cpx_dualfarkas!(model, ray)
    return ray
end
function cpx_dualfarkas!(model::Model, ray::Vector{Cdouble})
  proof_p = Vector{Cdouble}(1)
  stat = @cpx_ccall(dualfarkas, Cint, (
                    Ptr{Void},
                    Ptr{Void},
                    Ptr{Cdouble},
                    Ptr{Cdouble}
                    ),
                    model.env.ptr, model.lp, ray, proof_p)
  if stat != 0
    warn("CPLEX is unable to grab infeasible ray; consider resolving with presolve turned off")
    throw(CplexError(model.env, stat))
  end
end

"""
    Unbounded Ray
"""
function cpx_getray(model::Model)
    n = cpx_numcols(model)
    ray = Vector{Cdouble}(n)
    cpx_getray!(model, ray)
    return ray
end
function cpx_getray!(model::Model, ray::Vector{Cdouble})
    stat = @cpx_ccall(getray, Cint, (
                      Ptr{Void},
                      Ptr{Void},
                      Ptr{Cdouble}
                      ),
                      model.env.ptr, model.lp, ray)
    if stat != 0
        warn("CPLEX is unable to grab unbounded ray; consider resolving with presolve turned off")
        throw(CplexError(model.env, stat))
    end
end

function cpx_getbaritcnt(model::Model)
    @cpx_ccall(getbaritcnt, Cint, (Ptr{Void}, Ptr{Void}), model.env.ptr, model.lp)
end
function cpx_getitcnt(model::Model)
    @cpx_ccall(getitcnt, Cint, (Ptr{Void}, Ptr{Void}), model.env.ptr, model.lp)
end
function cpx_getnodecnt(model::Model)
    @cpx_ccall(getnodecnt, Cint, (Ptr{Void}, Ptr{Void}), model.env.ptr, model.lp)
end
function cpx_getbestobjval(model::Model)
    ret = Vector{Cdouble}(1)
    @cpx_ccall_error(model.env, getbestobjval, Cint, (Ptr{Void}, Ptr{Void}, Ptr{Cdouble}), model.env.ptr, model.lp, ret)
    return ret[1]
end
function cpx_getmiprelgap(model::Model)
    ret = Vector{Cdouble}(1)
    @cpx_ccall_error(model.env, getmiprelgap, Cint, (Ptr{Void}, Ptr{Void}, Ptr{Cdouble}), model.env.ptr, model.lp, ret)
    return ret[1]
end
