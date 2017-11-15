const PARAM_TYPES = Dict{Int, DataType}(
    0 => Void,
    1 => Cint,
    2 => Cdouble,
    3 => Cchar,
    4 => Clonglong
)
function cpx_getparamtype(env::Env, indx::Cint)
    ptype = Vector{Cint}(1)
    @cpx_ccall_error(env, getparamtype, Cint, (Ptr{Void}, Cint, Ptr{Cint}),
        env.ptr, indx, ptype)
    if haskey(PARAM_TYPES, ptype[1])
        return PARAM_TYPES[ptype[1]]
    else
        error("Parameter type not recognized")
    end
end
cpx_getparamtype(env::Env, name::String) = cpx_getparamtype(env, CPX_PARAMS[name])

function cpx_getparam(::Type{Cint}, env::Env, pindx::Cint)
    ret = Vector{Cint}(1)
    @cpx_ccall_error(env, getintparam, Cint, (Ptr{Void}, Cint, Ptr{Cint}), env.ptr, pindx, ret)
    return ret[1]
end
function cpx_getparam(::Type{Cdouble}, env::Env, pindx::Cint)
    ret = Vector{Cdouble}(1)
    @cpx_ccall_error(env, getdblparam, Cint, (Ptr{Void}, Cint, Ptr{Cint}), env.ptr, pindx, ret)
    return ret[1]
end
function cpx_getparam(::Type{Clonglong}, env::Env, pindx::Cint)
    ret = Vector{Clonglong}(1)
    @cpx_ccall_error(env, getlongparam, Cint, (Ptr{Void}, Cint, Ptr{Clonglong}), env.ptr, pindx, ret)
    return ret[1]
end
function cpx_getparam(::Type{Cchar}, env::Env, pindx::Cint)
    ret = Vector{Cchar}(CPX_STR_PARAM_MAX)
    @cpx_ccall_error(env, getstrparam, Cint, (Ptr{Void}, Cint, Ptr{Cchar}), env.ptr, pindx, ret)
    return bytestring(pointer(ret))
end
cpx_getparam(T, env::Env, pindx::Cint) = warn("Trying to get a parameter of unknown type; doing nothing.")

cpx_getparam(env::Env, pindx::Cint) = cpx_getparam(cpx_getparamtype(env, pindx), env, pindx)

cpx_getparam(env::Env, pname::String) = cpx_getparam(env, CPX_PARAMS[pname])


function cpx_setparam!(::Type{Cint}, env::Env, pindx::Cint, val)
    @cpx_ccall_error(env, setintparam, Cint, (Ptr{Void}, Cint, Cint), env.ptr, pindx, convert(Cint, val))
end
function cpx_setparam!(::Type{Cdouble}, env::Env, pindx::Cint, val)
    @cpx_ccall_error(env, getdblparam, Cint, (Ptr{Void}, Cint, Cdouble), env.ptr, pindx, float(val))
end
function cpx_setparam!(::Type{Clonglong}, env::Env, pindx::Cint, val)
    @cpx_ccall_error(env, getlongparam, Cint, (Ptr{Void}, Cint, Clonglong), env.ptr, pindx, convert(Clonglong, val))
end
function cpx_setparam!(::Type{Cchar}, env::Env, pindx::Int, val)
    @cpx_ccall_error(env, getstrparam, Cint, (Ptr{Void}, Cint, Cstring), env.ptr, pindx, String(val))
end
cpx_setparam!(T, env::Env, pindx::Cint, val) = warn("Trying to set a parameter of unknown type; doing nothing.")

cpx_setparam!(env::Env, pindx::Cint, val) = cpx_setparam!(cpx_getparamtype(env, pindx), env, pindx, val)

cpx_setparam!(env::Env, pname::String, val) = cpx_setparam!(env, CPX_PARAMS[pname], val)




# tune_param(model::Model) = tune_param(model, Dict(), Dict(), Dict())
#
# function tune_param(model::Model, intfixed::Dict, dblfixed::Dict, strfixed::Dict)
#   intkeys = Cint[k for k in keys(intfixed)]
#   dblkeys = Cint[k for k in keys(dblfixed)]
#   strkeys = Cint[k for k in keys(strfixed)]
#   tune_stat = Vector{Cint}(1)
#   stat = @cpx_ccall(tuneparam, Cint, (Ptr{Void},
#                          Ptr{Void},
#                          Cint,
#                          Ptr{Cint},
#                          Ptr{Cint},
#                          Cint,
#                          Ptr{Cint},
#                          Ptr{Cdouble},
#                          Cint,
#                          Ptr{Cint},
#                          Ptr{Ptr{Cchar}},
#                          Ptr{Cint}),
#                         model.env,
#                         model.lp,
#                         convert(Cint, length(intkeys)),
#                         intkeys,
#                         Cint[intfixed[int(k)] for k in intkeys],
#                         convert(Cint, length(dblkeys)),
#                         dblkeys,
#                         Cdouble[dblfixed[int(k)] for k in dblkeys],
#                         convert(Cint, length(strkeys)),
#                         strkeys,
#                         [strkeys[int(k)] for k in strkeys],
#                         tune_stat)
#   if stat != 0
#     throw(CplexError(model.env, stat))
#   end
#   for param in keys(paramName2Indx)
#     print(param * ": ")
#     val = get_param(model.env, param)
#     println(val)
#   end
#   return tune_stat[1]
# end
