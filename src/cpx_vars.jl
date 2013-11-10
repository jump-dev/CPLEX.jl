function add_var!(prob::CPXproblem, obj::Vector, lb::Vector, ub::Vector)
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
            error("CPLEX: Error adding new variables")
        end
        prob.nvars = prob.nvars + nvars
    end
end

function add_var!(prob::CPXproblem, constridx::IVec, constrcoef::FVec, l::FVec, u::FVec, objcoef::FVec)
    nvars = length(obj)
    (nvars == length(lb) == length(ub)) || error("Inconsistent dimensions when adding variables.")
    if nvars > 0
        status = @cpx_ccall(addcols, Cint, (
                            Ptr{Void},
                            Ptr{Void},
                            Cint,
                            Cint,
                            Ptr{Float64},
                            Ptr{Cint},
                            Ptr{Cint},
                            Ptr{Float64},
                            Ptr{Float64},
                            Ptr{Float64},
                            Ptr{Ptr{Cchar}}
                            ),
                            prob.env.ptr, prob.lp, nvars, length(constridx), objcoef, [0], constridx-1, constrcoef, l, u, C_NULL)
        if status != 0
            error("CPLEX: error adding columns to model")
        end
    end
end

add_var!(prob::CPXproblem, constridx::Vector, constrcoef::Vector, l::Vector, u::Vector, objcoef::Vector) = add_var!(prob, int(constridx), float(constrcoef), float(l), float(u), float(objcoef))

function get_varLB(prob::CPXproblem)
    lb = Array(Float64, prob.nvars)
    status = @cpx_ccall(getlb, Cint, (
                        Ptr{Void},
                        Ptr{Void},
                        Ptr{Float64},
                        Cint,
                        Cint
                        ),
                        prob.env.ptr, prob.lp, lb, 0, prob.nvars-1)
    if status != 0
        error("CPLEX: error getting variable lower bounds")
    end
    return lb
end

function set_varLB!(prob::CPXproblem, l::FVec)
    status = @cpx_ccall(getlb, Cint, (
                        Ptr{Void},
                        Ptr{Void},
                        Cint,
                        Ptr{Cint},
                        Ptr{Cchar},
                        Ptr{Float64}
                        ),
                        prob.env.ptr, prob.lp, prob.nvars, Cint[0:prob.nvars-1], fill(convert(Cchar, 'L'), prob.nvars), l)
    if status != 0
        error("CPLEX: error setting variable lower bounds")
    end
end

function get_varUB(prob::CPXproblem)
    ub = Array(Float64, prob.nvars)
    status = @cpx_ccall(getub, Cint, (
                        Ptr{Void},
                        Ptr{Void},
                        Ptr{Float64},
                        Cint,
                        Cint
                        ),
                        prob.env.ptr, prob.lp, ub, 0, prob.nvars-1)
    if status != 0
        error("CPLEX: error getting variable upper bounds")
    end
    return ub
end

function set_varUB!(prob::CPXproblem, u::FVec)
    status = @cpx_ccall(getlb, Cint, (
                        Ptr{Void},
                        Ptr{Void},
                        Cint,
                        Ptr{Cint},
                        Ptr{Cchar},
                        Ptr{Float64}
                        ),
                        prob.env.ptr, prob.lp, prob.nvars, Cint[0:prob.nvars-1], fill(convert(Cchar, 'U'), prob.nvars), u)
    if status != 0
        error("CPLEX: error setting variable lower bounds")
    end
end


function set_vartype!(prob::CPXproblem, vtype::Vector{Char})
    status = @cpx_ccall(chgctype, Cint, (
                        Ptr{Void},
                        Ptr{Void},
                        Cint,
                        Ptr{Cint},
                        Ptr{Cchar}
                        ),
                        prob.env.ptr, prob.lp, prob.nvars, Cint[0:prob.nvars-1], Cchar[vtype...])
    if status != 0
        error("CPLEX: error setting variable types")
    end
    # this should change...need to indicate whether to use MIP or LP solver
    prob.nint = 1
    # prob.nint += sum([vtype[i]=='I' for i=1:prob.nvars])
    write_problem(prob, "out.lp")
end

function get_vartype(prob::CPXproblem)
    vartypes = Array(Cchar, prob.nvars)
    status = @cpx_ccall(getctype, Cint, (
                        Ptr{Void},
                        Ptr{Void},
                        Ptr{Cchar},
                        Cint,
                        Cint
                        ),
                        prob.env.ptr, prob.lp, vartypes, 0, prob.nvars-1)
    if status != 0
        error("CPLEX: error grabbing variable types")
    end
    return(vartypes)
end
