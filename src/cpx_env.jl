function  cpx_finalizer(env)
    if env.num_models == 0
        cpx_closeCPLEX(env)
    else
        env.finalize_called = true
    end
end

mutable struct Env
    ptr::Ptr{Void}
    num_models::Int
    finalize_called::Bool

    function Env()
      stat = Vector{Cint}(1)
      tmp = @cpx_ccall(openCPLEX, Ptr{Void}, (Ptr{Cint},), stat)
      if tmp == C_NULL
          error("CPLEX: Error creating environment")
      end
      env = new(tmp, 0, false)
      finalizer(env, cpx_finalizer)
      env
    end
end

convert(ty::Type{Ptr{Void}}, env::Env) = env.ptr::Ptr{Void}
unsafe_convert(ty::Type{Ptr{Void}}, env::Env) = convert(ty, env)

function is_valid(env::Env)
    env.ptr != C_NULL
end

function notify_new_model(env::Env)
    env.num_models += 1
end

function notify_freed_model(env::Env)
    @assert env.num_models > 0
    env.num_models -= 1
    if env.num_models <= 0 && env.finalize_called
        cpx_closeCPLEX(env)
    end
end

function cpx_closeCPLEX(env::Env)
    tmp = Ptr{Void}[env.ptr]
    stat = @cpx_ccall(closeCPLEX, Cint, (Ptr{Void},), tmp)
    env.ptr = C_NULL
    if stat != 0
        throw(CplexError(env, stat))
    end
end

function cpx_setlogfile!(env::Env, filename::String)
  @assert isascii(filename)
  fp = @cpx_ccall(fopen, Ptr{Void}, (Ptr{Cchar}, Ptr{Cchar}), filename, "w")
  if fp == C_NULL
    error("CPLEX: Error setting logfile")
  end
  @cpx_ccall_error(env, setlogfile, Cint, (Ptr{Void}, Ptr{Void}), env, fp)
end

function cpx_geterrorstring(env::Env, code::Number)
    @assert env.ptr != C_NULL
    buf = Vector{Cchar}(4096) # minimum size for Cplex to accept
    errstr = @cpx_ccall(geterrorstring, Ptr{Cchar}, (Ptr{Void}, Cint, Ptr{Cchar}), env.ptr, convert(Cint, code), buf)
    if errstr != C_NULL
      return unsafe_string(pointer(buf))
    else
      error("CPLEX: error getting error message(!)")
    end
end

function cpx_version(env::Env = Env())
    charptr = @cpx_ccall(version, Ptr{Cchar}, (Ptr{Void},), env.ptr)
    if charptr != C_NULL
        return unsafe_string(charptr)
    else
        return error("CPLEX: error getting version")
    end
end

type CplexError <: Exception
  code::Int
  msg::String

  function CplexError(env::Env, code::Integer)
    new(convert(Cint, code), cpx_geterrorstring(env, code))
  end
end
