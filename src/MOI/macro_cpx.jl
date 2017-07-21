# makes calling C functions a bit easier
"""
    @cpx_ccall_error(env, func, args...)

Throws CplexError if return code is not 0
"""
macro cpx_ccall_error(env, func, args...)
    f = "CPX$(func)"
    args = map(esc,args)
    code = quote end
    if is_unix()
        push!(code.args, :(stat = ccall(($f,libcplex), $(args...))))
    elseif is_windows()
        if VERSION < v"0.6.0-dev.1512" # probably julia PR #15850
            push!(code.args, :(stat = ccall(($f,libcplex), stdcall, $(args...))))
        else
            push!(code.args, :(stat = ccall(($f,libcplex), $(esc(:stdcall)), $(args...))))
        end
    else
        error("Unknown platform.")
    end
    push!(code.args, quote
        if stat != 0
           throw(CplexError($env, stat))
        end
    end)
    return code
end


"""
    @cpx_ccall(func, args...)
"""
macro cpx_ccall(func, args...)
    f = "CPX$(func)"
    args = map(esc,args)
    if is_unix()
        return quote stat = ccall(($f,libcplex), $(args...))) end
    elseif is_windows()
        if VERSION < v"0.6.0-dev.1512" # probably julia PR #15850
            return quote stat = ccall(($f,libcplex), stdcall, $(args...))) end
        else
            return quote stat = ccall(($f,libcplex), $(esc(:stdcall)), $(args...))) end
        end
    else
        error("Unknown platform.")
    end
end
