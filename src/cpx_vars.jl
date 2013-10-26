function add_vars!(prob::CPXproblem, obj::Vector, lb::Vector, ub::Vector)

    nvars = length(obj)

    (nvars == length(lb) == length(ub)) || error("Inconsistent dimensions when adding variables.")

    # for i in 1:prob.nvars
    #     if lb[i] == -Inf
    #         lb[i] = CPX_INFBOUND
    #     end
    #     if ub[i] == Inf
    #         ub[i] = CPX_INFBOUND
    #     end
    # end

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
                            prob.env.ptr, prob.lp, nvars, float(obj), float(lb), float(ub), C_NULL, C_NULL)
        if status != 0
            error("CPLEX: Error adding new variables.")
        end
        prob.nvars = prob.nvars + nvars
    end
end
