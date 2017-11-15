# const CPX_INFBOUND = 1e20
# const CPX_STR_PARAM_MAX = 512

function get_param_type(env::Env, indx::Int)
  ptype = Vector{Cint}(1)
  stat = @cpx_ccall(getparamtype, Cint, (
                    Ptr{Void},
                    Cint,
                    Ptr{Cint}
                    ),
                    env.ptr, convert(Cint,indx), ptype)
  if stat != 0
    throw(CplexError(env, stat))
  end
  if ptype[1] == 0
    ret = :None
  elseif ptype[1] == 1
    ret = :Int
  elseif ptype[1] == 2
    ret = :Double
  elseif ptype[1] == 3
    ret = :String
  elseif ptype[1] == 4
    ret = :Long
  else
    error("Parameter type not recognized")
  end

  return ret
end

get_param_type(env::Env, name::String) = get_param_type(env, paramName2Indx[name])

function set_param!(env::Env, _pindx::Int, val, ptype::Symbol)
  pindx = convert(Cint, _pindx)
  if ptype == :Int
    stat = @cpx_ccall(setintparam, Cint, (Ptr{Void}, Cint, Cint), env.ptr, pindx, convert(Cint,val))
  elseif ptype == :Double
    stat = @cpx_ccall(setdblparam, Cint, (Ptr{Void}, Cint, Cdouble), env.ptr, pindx, float(val))
  elseif ptype == :String
    stat = @cpx_ccall(setstrparam, Cint, (Ptr{Void}, Cint, Cstring), env.ptr, pindx, String(val))
  elseif ptype == :Long
    stat = @cpx_ccall(setlongparam, Cint, (Ptr{Void}, Cint, Clonglong), env.ptr, pindx, convert(Clonglong, val))
  elseif ptype == :None
    warn("Trying to set a parameter of type None; doing nothing")
  else
    error("Unrecognized parameter type")
  end
  if stat != 0
    throw(CplexError(env, stat))
  end
end

set_param!(env::Env, pindx::Int, val) = set_param!(env, pindx, val, get_param_type(env, pindx))

set_param!(env::Env, pname::String, val) = set_param!(env, paramName2Indx[pname], val)

# set_params!(env::Env, args...)
#   for (name, v) in args
#     set_param!(prob, string(name), v)
#   end
# end

function get_param(env::Env, pindx::Int, ptype::Symbol)
  if ptype == :Int
    val_int = Vector{Cint}(1)
    stat = @cpx_ccall(getintparam, Cint, (Ptr{Void}, Cint, Ptr{Cint}), env.ptr, convert(Cint,pindx), val_int)
    if stat != 0
      throw(CplexError(env, stat))
    end
    return val_int[1]
  elseif ptype == :Double
    val_double = Vector{Cdouble}(1)
    stat = @cpx_ccall(getdblparam, Cint, (Ptr{Void}, Cint, Ptr{Cdouble}), env.ptr, convert(Cint,pindx), val_double)
    if stat != 0
      throw(CplexError(env, stat))
    end
    return val_double[1]
  elseif ptype == :String
    buf = Vector{Cchar}(CPX_STR_PARAM_MAX) # max str param length is 512 in Cplex 12.51
    stat = @cpx_ccall(getstrparam, Cint, (Ptr{Void}, Cint, Ptr{Cchar}), env.ptr, convert(Cint,pindx), buf)
    if stat != 0
      throw(CplexError(env, stat))
    end
    return bytestring(pointer(buf))
  elseif ptype == :Long
    val_long = Vector{Clonglong}(1)
    stat = @cpx_ccall(getlongparam, Cint, (Ptr{Void}, Cint, Ptr{Clonglong}), env.ptr, convert(Cint,pindx), val_long)
    if stat != 0
      throw(CplexError(env, stat))
    end
    return val_long[1]
  elseif ptype == :None
    warn("Trying to set a parameter of type None; doing nothing")
  else
    error("Unrecognized parameter type")
  end
  nothing
end

get_param(env::Env, pindx::Int) = get_param(env, pindx, get_param_type(env, pindx))

get_param(env::Env, pname::String) = get_param(env, paramName2Indx[pname])

tune_param(model::Model) = tune_param(model, Dict(), Dict(), Dict())

function tune_param(model::Model, intfixed::Dict, dblfixed::Dict, strfixed::Dict)
  intkeys = Cint[k for k in keys(intfixed)]
  dblkeys = Cint[k for k in keys(dblfixed)]
  strkeys = Cint[k for k in keys(strfixed)]
  tune_stat = Vector{Cint}(1)
  stat = @cpx_ccall(tuneparam, Cint, (Ptr{Void},
                         Ptr{Void},
                         Cint,
                         Ptr{Cint},
                         Ptr{Cint},
                         Cint,
                         Ptr{Cint},
                         Ptr{Cdouble},
                         Cint,
                         Ptr{Cint},
                         Ptr{Ptr{Cchar}},
                         Ptr{Cint}),
                        model.env,
                        model.lp,
                        convert(Cint, length(intkeys)),
                        intkeys,
                        Cint[intfixed[int(k)] for k in intkeys],
                        convert(Cint, length(dblkeys)),
                        dblkeys,
                        Cdouble[dblfixed[int(k)] for k in dblkeys],
                        convert(Cint, length(strkeys)),
                        strkeys,
                        [strkeys[int(k)] for k in strkeys],
                        tune_stat)
  if stat != 0
    throw(CplexError(model.env, stat))
  end
  for param in keys(paramName2Indx)
    print(param * ": ")
    val = get_param(model.env, param)
    println(val)
  end
  return tune_stat[1]
end
