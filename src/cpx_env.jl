type Env
    ptr::Ptr{Void}

    function Env()
      stat = Array(Cint, 1)
      tmp = @cpx_ccall(openCPLEX, Ptr{Void}, (Ptr{Cint},), stat)
      if tmp == C_NULL
          error("CPLEX: Error creating environment")
      end
      env = new(tmp)
      env
    end
end

convert(ty::Type{Ptr{Void}}, env::Env) = env.ptr::Ptr{Void}

function is_valid(env::Env)
    env.ptr != C_NULL
end

function get_error_msg(env::Env, code::Number)
    @assert env.ptr != C_NULL
    buf = Array(Cchar, 4096) # minimum size for Cplex to accept
    errstr = @cpx_ccall(geterrorstring, Ptr{Cchar}, (Ptr{Void}, Cint, Ptr{Cchar}), env.ptr_env, convert(Cint, code), buf)
    if errstr != C_NULL
      return bytestring(pointer(buf))
    else
      error("CPLEX: error getting error message(!)")
    end
end

type CplexError
  code::Int
  msg::ASCIIString

  function CplexError(env::Env, code::Integer)
    new(convert(Int, Code), get_error_msg(env, code))
  end
end
