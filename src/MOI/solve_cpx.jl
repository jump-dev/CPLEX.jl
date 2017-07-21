function optimize!(model::Model)
  @assert is_valid(model.env)
  stat = (if model.has_int
    @cpx_ccall_intercept(model, mipopt, Cint, (Ptr{Void}, Ptr{Void}), model.env.ptr, model.lp)
  elseif model.has_qc
    @cpx_ccall_intercept(model, qpopt, Cint, (Ptr{Void}, Ptr{Void}), model.env.ptr, model.lp)
  else
    @cpx_ccall_intercept(model, lpopt, Cint, (Ptr{Void}, Ptr{Void}), model.env.ptr, model.lp)
    end)
  if stat != 0
    throw(CplexError(model.env, stat))
  end
end
