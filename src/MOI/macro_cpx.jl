# makes calling C functions a bit easier
macro cpx_ccall(env, func, args...)
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
end
