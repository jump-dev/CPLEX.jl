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
            error("CPLEX: Error adding new variables")
        end
        prob.nvars = prob.nvars + nvars
    end
end

add_var!(prob::CPXproblem, obj::Vector, lb::Vector, ub::Vector) = add_vars!(prob, obj, lb, ub)

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
    nvars = num_var(prob)
    lb = Array(Float64, nvars)
    status = @cpx_ccall(getlb, Cint, (
                        Ptr{Void},
                        Ptr{Void},
                        Ptr{Float64},
                        Cint,
                        Cint
                        ),
                        prob.env.ptr, prob.lp, lb, 0, nvars-1)
    if status != 0
        error("CPLEX: error getting variable lower bounds")
    end
    return lb
end

function set_varLB!(prob::CPXproblem, l::FVec)
    nvars = num_var(prob)
    status = @cpx_ccall(getlb, Cint, (
                        Ptr{Void},
                        Ptr{Void},
                        Cint,
                        Ptr{Cint},
                        Ptr{Cchar},
                        Ptr{Float64}
                        ),
                        prob.env.ptr, prob.lp, nvars, Cint[0:nvars-1], fill(convert(Cchar, 'L'), nvars), l)
    if status != 0
        error("CPLEX: error setting variable lower bounds")
    end
end

function get_varUB(prob::CPXproblem)
    nvars = num_var(prob)
    ub = Array(Float64, nvars)
    status = @cpx_ccall(getub, Cint, (
                        Ptr{Void},
                        Ptr{Void},
                        Ptr{Float64},
                        Cint,
                        Cint
                        ),
                        prob.env.ptr, prob.lp, ub, 0, nvars-1)
    if status != 0
        error("CPLEX: error getting variable upper bounds")
    end
    return ub
end

function set_varUB!(prob::CPXproblem, u::FVec)
    nvars = num_var(prob)
    status = @cpx_ccall(getlb, Cint, (
                        Ptr{Void},
                        Ptr{Void},
                        Cint,
                        Ptr{Cint},
                        Ptr{Cchar},
                        Ptr{Float64}
                        ),
                        prob.env.ptr, prob.lp, nvars, Cint[0:prob.nvars-1], fill(convert(Cchar, 'U'), nvars), u)
    if status != 0
        error("CPLEX: error setting variable lower bounds")
    end
end


function set_vartype!(prob::CPXproblem, vtype::Vector{Char})
    nvars = num_var(prob)
    status = @cpx_ccall(chgctype, Cint, (
                        Ptr{Void},
                        Ptr{Void},
                        Cint,
                        Ptr{Cint},
                        Ptr{Cchar}
                        ),
                        prob.env.ptr, prob.lp, nvars, Cint[0:nvars-1], Cchar[vtype...])
    if status != 0
        error("CPLEX: error setting variable types")
    end
    # this should change...need to indicate whether to use MIP or LP solver
    prob.nint = 1
    # prob.nint += sum([vtype[i]=='I' for i=1:prob.nvars])
    write_problem(prob, "out.lp")
end

function get_vartype(prob::CPXproblem)
    nvars = num_var(prob)
    vartypes = Array(Cchar, nvars)
    status = @cpx_ccall(getctype, Cint, (
                        Ptr{Void},
                        Ptr{Void},
                        Ptr{Cchar},
                        Cint,
                        Cint
                        ),
                        prob.env.ptr, prob.lp, vartypes, 0, nvars-1)
    if status != 0
        error("CPLEX: error grabbing variable types")
    end
    return(vartypes)
end

function num_var(prob::CPXproblem)
    nvar = @cpx_ccall(getnumcols, Cint, (
                      Ptr{Void},
                      Ptr{Void}
                      ),
                      prob.env.ptr, prob.lp)
    return(nvar)
end
