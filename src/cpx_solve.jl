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

function cpx_getx(model::Model, x::Vector{Cdouble})
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
