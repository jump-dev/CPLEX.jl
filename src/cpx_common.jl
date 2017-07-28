# makes calling C functions a bit easier
"""
    @cpx_ccall(func, args...)
"""
macro cpx_ccall(func, args...)
    f = "CPX$(func)"
    args = map(esc,args)
    if is_unix()
        return quote stat = ccall(($f,libcplex), $(args...)) end
    elseif is_windows()
        if VERSION < v"0.6.0-dev.1512" # probably julia PR #15850
            return quote stat = ccall(($f,libcplex), stdcall, $(args...)) end
        else
            return quote stat = ccall(($f,libcplex), $(esc(:stdcall)), $(args...)) end
        end
    else
        error("Unknown platform.")
    end
end

"""
    @cpx_ccall_error(env, func, args...)

Throws CplexError if return code is not 0
"""
macro cpx_ccall_error(env, func, args...)
    args = map(esc,args)
    quote
        stat = $(Expr(:macrocall, Symbol("@cpx_ccall"), esc(func), args...))
        if stat != 0
           throw(CplexError($(esc(env)), stat))
        end
    end
end

macro cpx_ccall_intercept(model, func, args...)
    args = map(esc,args)
    quote
        ccall(:jl_exit_on_sigint, Void, (Cint,), convert(Cint,0))
        ret = try
            $(Expr(:macrocall, Symbol("@cpx_ccall"), esc(func), args...))
        catch ex
            println("Caught exception")
            if !isinteractive()
                ccall(:jl_exit_on_sigint, Void, (Cint,), convert(Cint,1))
            end
            if isa(ex, InterruptException)
                model.terminator[1] = 1
            end
            rethrow(ex)
        end
        if !isinteractive()
            ccall(:jl_exit_on_sigint, Void, (Cint,), convert(Cint,1))
        end
        ret
    end
end
