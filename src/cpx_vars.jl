function add_vars!(prob::CPXproblem, obj::Vector, lb::Vector, ub::Vector)

    ccnt = length(obj)
    if (length(obj) != length(lb)) || (length(obj) != length(ub))
        error("Inconsistent dimensions when adding variables.")
    end

    (ccnt == length(lb) == length(ub)) || error("Incompatible argument dimensions.")

    # for i in 1:prob.nvars
    #     if lb[i] == -Inf
    #         lb[i] = CPX_INFBOUND
    #     end
    #     if ub[i] == Inf
    #         ub[i] = CPX_INFBOUND
    #     end
    # end

    vartype = fill!(Array(Char, prob.nvars), 'C')

    if nvars > 0
        status = @cpx_ccall(newcols, Cint, (
                            Ptr{Void}, 
                            Ptr{Void}, 
                            Cint, 
                            Ptr{Float64}, 
                            Ptr{Float64}, 
                            Ptr{Float64}, 
                            Ptr{Uint8}, 
                            Ptr{Ptr{Uint8}}
                            ),
                            prob.env.ptr, prob.lp, ccnt, float(obj), float(lb), float(ub), vartype, C_NULL)
        if status != 0
            error("CPLEX: Error adding new variables.")
        end
    end
end
