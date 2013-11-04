function add_vars!(prob::CPXproblem, obj::Vector, lb::Vector, ub::Vector)

    nvars = length(obj)

    (nvars == length(lb) == length(ub)) || error("Inconsistent dimensions when adding variables.")

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

function get_varLB(prob::CPXproblem)
    lb = Array(Float64, prob.nvars)
    @cpx_ccall_check(getlb, Cint, (
                     Ptr{Void},
                     Ptr{Void},
                     Ptr{Float64},
                     Cint,
                     Cint
                     ),
                     prob.env.ptr, prob.lp, lb, 0, prob.nvars-1)
    return lb
end

set_varLB!(prob::CPXproblem, l) = error("Need to find appropriate CPLEX function")

function get_varUB(prob::CPXproblem)
    ub = Array(Float64, prob.nvars)
    @cpx_ccall_check(getlb, Cint, (
                     Ptr{Void},
                     Ptr{Void},
                     Ptr{Float64},
                     Cint,
                     Cint
                     ),
                     prob.env.ptr, prob.lp, ub, 0, prob.nvars-1)
    return ub
end

set_varUB!(prob::CPXproblem, u) = error("Need to find appropriate CPLEX function")

