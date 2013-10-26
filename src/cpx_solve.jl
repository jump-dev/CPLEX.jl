function solve_lp!(prob::CPXproblem)
    ret = @cpx_ccall(lpopt, Cint, (Ptr{Void}, Ptr{Void}), prob.env.ptr, prob.lp)
    if ret != 0
        error("CPLEX: Error solving LP")
    end
end

function get_solution(prob::CPXproblem)
    obj = [0.0]
    x   = Array(Float64, prob.nvars)
    status = Array(Cint, 1)
    ret = @cpx_ccall(solution,
                     Cint,
                     (Ptr{Void}, Ptr{Void}, Ptr{Cint}, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}),
                     prob.env.ptr,
                     prob.lp,
                     status,
                     obj,
                     x,
                     C_NULL,
                     C_NULL,
                     C_NULL)
    if ret != 0
       error("CPLEX: Error getting solution")
   end
   return(obj[1], x)
end
