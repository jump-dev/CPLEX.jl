function optimize!(model::Model)
  @assert is_valid(model.env)
  stat = @cpx_ccall_intercept(model, lpopt, Cint, (Ptr{Void}, Ptr{Void}), model.env.ptr, model.lp)
  if stat != 0
    throw(CplexError(model.env, stat))
  end
end

cpx_get_status_code(model::Model) = @cpx_ccall(getstat, Cint, (Ptr{Void}, Ptr{Void}), model.env.ptr, model.lp)

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
    nvars = cpx_number_variables(model)
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
    nvars = cpx_number_variables(model)
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
    nvars = cpx_number_constraints(model)
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
    n = cpx_number_constraints(model)
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
