type Env
    ptr::Ptr{Void}

    function Env()
      stat = Array(Cint, 1)
      tmp = @cpx_ccall(openCPLEX, Ptr{Void}, (Ptr{Cint},), stat)
      if tmp == C_NULL
          error("CPLEX: Error creating environment")
      end
      new(tmp)
    end
end

convert(ty::Type{Ptr{Void}}, env::Env) = env.ptr::Ptr{Void}
unsafe_convert(ty::Type{Ptr{Void}}, env::Env) = convert(ty, env)

function is_valid(env::Env)
    env.ptr != C_NULL
end

function set_logfile(env::Env, filename::String)
  @assert isascii(filename)
  fp = @cpx_ccall(fopen, Ptr{Void}, (Ptr{Cchar}, Ptr{Cchar}), filename, "w")
  if fp == C_NULL
    error("CPLEX: Error setting logfile")
  end
  stat = @cpx_ccall(setlogfile, Cint, (Ptr{Void}, Ptr{Void}), env, fp)
  if stat != 0
    throw(CplexError(env, stat))
  end
end

function get_error_msg(env::Env, code::Number)
    @assert env.ptr != C_NULL
    buf = Array(Cchar, 4096) # minimum size for Cplex to accept
    errstr = @cpx_ccall(geterrorstring, Ptr{Cchar}, (Ptr{Void}, Cint, Ptr{Cchar}), env.ptr, convert(Cint, code), buf)
    if errstr != C_NULL
      return unsafe_string(pointer(buf))
    else
      error("CPLEX: error getting error message(!)")
    end
end

type CplexError <: Exception
  code::Int
  msg::String

  function CplexError(env::Env, code::Integer)
    new(convert(Cint, code), get_error_msg(env, code))
  end
end
