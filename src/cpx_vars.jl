function add_vars!(prob::Model, obj::Vector, l::Vector, u::Vector)
    nvars = length(obj)
    (nvars == length(l) == length(u)) || error("Inconsistent dimensions when adding variables.")
    for i = 1:nvars
        if l[i] == -Inf
            l[i] = -CPX_INFBOUND
        end
        if u[i] == Inf
            u[i] = CPX_INFBOUND
        end
    end
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
                            prob.env.ptr, prob.lp, nvars, float(obj), float(l), float(u), C_NULL, C_NULL)
        if status != 0
            error("CPLEX: Error adding new variables")
        end
    end
end

add_var!(prob::Model, obj::Vector, l::Vector, u::Vector) = add_vars!(prob, obj, l, u)

function add_var!(prob::Model, constridx::IVec, constrcoef::FVec, l::FVec, u::FVec, objcoef::FVec)
    nvars = length(objcoef)
    (nvars == length(l) == length(u)) || error("Inconsistent dimensions when adding variables.")
    for i = 1:nvars
        if l[i] == -Inf
            l[i] = -CPX_INFBOUND
        end
        if u[i] == Inf
            u[i] = CPX_INFBOUND
        end
    end
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
                            prob.env.ptr, prob.lp, nvars, length(constridx), objcoef, Cint[0], constridx-1, constrcoef, l, u, C_NULL)
        if status != 0
            error("CPLEX: error adding columns to model")
        end
    end
end

function add_var!(prob::Model, constridx, constrcoef, l, u, objcoef)
    return add_var!(prob, convert(IVec, [constridx...]), convert(FVec, [constrcoef...]), convert(FVec, [l...]), convert(FVec, [u...]), convert(FVec, [objcoef...]))
end

function get_varLB(prob::Model)
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

function set_varLB!(prob::Model, l::FVec)
    nvars = num_var(prob)
    for i = 1:nvars
        if l[i] == -Inf
            l[i] = -CPX_INFBOUND
        end
    end
    status = @cpx_ccall(chgbds, Cint, (
                        Ptr{Void},
                        Ptr{Void},
                        Cint,
                        Ptr{Cint},
                        Ptr{Cchar},
                        Ptr{Float64}
                        ),
                        prob.env.ptr, prob.lp, nvars, Cint[0:nvars-1], fill(convert(Cchar, 'L'), nvars), l)
    if status != 0
        println(status)
        error("CPLEX: error setting variable lower bounds")
    end
end

function get_varUB(prob::Model)
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

function set_varUB!(prob::Model, u::FVec)
    nvars = num_var(prob)
        for i = 1:nvars
        if u[i] == Inf
            u[i] = CPX_INFBOUND
        end
    end
    status = @cpx_ccall(chgbds, Cint, (
                        Ptr{Void},
                        Ptr{Void},
                        Cint,
                        Ptr{Cint},
                        Ptr{Cchar},
                        Ptr{Float64}
                        ),
                        prob.env.ptr, prob.lp, nvars, Cint[0:nvars-1], fill(convert(Cchar, 'U'), nvars), u)
    if status != 0
        error("CPLEX: error setting variable lower bounds")
    end
end


function set_vartype!(prob::Model, vtype::Vector{Char})
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
    prob.has_int = true
    # prob.nint += sum([vtype[i]=='I' for i=1:prob.nvars])
end

function get_vartype(prob::Model)
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

function num_var(prob::Model)
    nvar = @cpx_ccall(getnumcols, Cint, (
                      Ptr{Void},
                      Ptr{Void}
                      ),
                      prob.env.ptr, prob.lp)
    return(nvar)
end
