function add_constrs!(prob::Model, cbegins::IVec, inds::IVec, coeffs::FVec, rel::CVec, rhs::FVec)
    nnz   = length(inds)
    ncons = length(rhs)
    (nnz == length(coeffs)) || error("Incompatible constraint argument dimensions.")

    if ncons > 0 && nnz > 0
        status = @cpx_ccall(addrows, Cint, (
                            Ptr{Void},        # environment
                            Ptr{Void},        # problem
                            Cint,             # num new cols
                            Cint,             # num new rows
                            Cint,             # num non-zeros
                            Ptr{Float64},     # rhs
                            Ptr{Uint8},       # sense
                            Ptr{Cint},        # matrix start
                            Ptr{Cint},        # matrix index
                            Ptr{Float64},     # matrix values
                            Ptr{Ptr{Uint8}},  # col names
                            Ptr{Ptr{Uint8}}   # row names
                            ), 
                            prob.env.ptr, prob.lp, 0, ncons, nnz, rhs, rel, cbegins-1, inds-1, coeffs, C_NULL, C_NULL)

        if status != 0   
            error("CPLEX: Error adding constraints.")
        end
    end
end

function add_constrs!(model::Model, cbeg::Vector, inds::Vector, coeffs::Vector, rel::Vector, rhs::Vector)
    add_constrs!(model, ivec(cbeg), ivec(inds), fvec(coeffs), cvecx(rel, length(cbeg)), fvec(rhs))
end

function add_constrs_t!(model::Model, At::SparseMatrixCSC{Float64}, rel::GCharOrVec, b::Vector)
    n, m = size(At)
    (m == length(b) && n == num_var(model)) || error("Incompatible argument dimensions.")
    add_constrs!(model, At.colptr[1:At.n], At.rowval, At.nzval, rel, b)
end

function add_constrs_t!(model::Model, At::Matrix{Float64}, rel::GCharOrVec, b::Vector)
    n, m = size(At)
    (m == length(b) && n == num_var(model)) || error("Incompatible argument dimensions.")
    add_constrs_t!(model, sparse(At), rel, b)
end

function add_constrs!(model::Model, A::CoeffMat, rel::GCharOrVec, b::Vector{Float64})
    m, n = size(A)
    (m == length(b) && n == num_var(model)) || error("Incompatible argument dimensions.")
    add_constrs_t!(model, transpose(A), rel, b)
end

function add_rangeconstrs!(prob::Model, cbegins::IVec, inds::IVec, coeffs::FVec, lb::FVec, ub::FVec)
    nnz   = length(inds)
    ncons = length(lb)
    (ncons  == length(ub) && nnz == length(coeffs)) || error("Incompatible constraint argument dimensions.")

    sense = fill!(Array(Cchar, ncons), 'R')

    for i in 1:ncons
        if lb[i] == -Inf
            lb[i] = -ub[i]
            ub[i] = Inf
            coeffs[cbegins[i]+1:cbegins[i+1]] = -coeffs[cbegins[i]+1:cbegins[i+1]]
        end
    end

    if ncons > 0 && nnz > 0
        status = @cpx_ccall(addrows, Cint, (
                            Ptr{Void},        # environment
                            Ptr{Void},        # problem
                            Cint,             # num new cols
                            Cint,             # num new rows
                            Cint,             # num non-zeros
                            Ptr{Float64},     # rhs
                            Ptr{Uint8},       # sense
                            Ptr{Cint},        # matrix start
                            Ptr{Cint},        # matrix index
                            Ptr{Float64},     # matrix values
                            Ptr{Ptr{Uint8}},  # col names
                            Ptr{Ptr{Uint8}}   # row names
                            ), 
                            prob.env.ptr, prob.lp, 0, ncons, nnz, lb, sense, cbegins[1:end-1], inds, coeffs, C_NULL, C_NULL)
                            # prob.env.ptr, prob.lp, 0, ncons, nnz, lb, sense, cbegins-1, inds-1, coeffs, C_NULL, C_NULL)
        if status != 0   
            error("CPLEX: Error adding constraints.")
        end
        for i = 1:ncons
            status = @cpx_ccall(chgrngval, Cint, (
                        Ptr{Void},
                        Ptr{Void},
                        Cint,
                        Ptr{Cint},
                        Ptr{Float64}
                        ),
                        prob.env.ptr, prob.lp, 1, [i-1], [ub[i]-lb[i]])
            if status != 0
                error("CPLEX: Error changing range values.")
            end
        end
    end
end

function add_rangeconstrs!(prob::Model, cbeg::Vector, inds::Vector, coeffs::Vector, lb::Vector, ub::Vector)
    add_rangeconstrs!(prob, ivec(cbeg), ivec(inds), fvec(coeffs), fvec(lb), fvec(ub))
end

function add_rangeconstrs_t!(prob::Model, At::SparseMatrixCSC{Float64}, lb::Vector, ub::Vector)
    add_rangeconstrs!(prob, At.colptr-1, At.rowval-1, At.nzval, lb, ub)
end

function add_rangeconstrs_t!(prob::Model, At::Matrix{Float64}, lb::Vector, ub::Vector)
    add_rangeconstrs_t!(prob, sparse(At), lb, ub)
end

function add_rangeconstrs!(prob::Model, A::CoeffMat, lb::Vector, ub::Vector)
    m, n = size(A)
    (m == length(lb) == length(ub) && n == num_var(prob)) || error("Incompatible constraint argument dimensions.")
    add_rangeconstrs_t!(prob, transpose(A), lb, ub)
end

function num_constr(prob::Model)
    ncons = @cpx_ccall(getnumrows, Cint, (
                       Ptr{Void},
                       Ptr{Void}
                       ),
                       prob.env.ptr, prob.lp)
    return ncons
end

function get_constr_senses(prob::Model)
    ncons = num_constr(prob)
    senses = Array(Cchar, ncons)
    status = @cpx_ccall(getsense, Cint, (
                        Ptr{Void},
                        Ptr{Void},
                        Ptr{Cchar},
                        Cint,
                        Cint
                        ),
                        prob.env.ptr, prob.lp, senses, 0, ncons-1)
    if status != 0
        error("CPLEX: error grabbing constraint senses")
    end
    return senses 
end

function set_constr_senses!(prob::Model, senses::Vector)
    ncons = num_constr(prob)
    status = @cpx_ccall(chgsense, Cint, (
                        Ptr{Void},
                        Ptr{Void},
                        Cint, 
                        Ptr{Cint},
                        Ptr{Cchar}
                        ),
                        prob.env.ptr, prob.lp, ncons, Cint[0:ncons-1], Cchar[senses...])
    if status != 0
        error("CPLEX: error changing constraint senses")
    end
end

function get_rhs(prob::Model)
    ncons = num_constr(prob)
    rhs = Array(Float64, ncons)
    status = @cpx_ccall(getrhs, Cint, (
                        Ptr{Void},
                        Ptr{Void},
                        Ptr{Float64},
                        Cint,
                        Cint
                        ),
                        prob.env.ptr, prob.lp, rhs, 0, ncons-1)
    if status != 0
        error("CPLEX: error grabbing RHS")
    end
    return rhs
end

function set_rhs!(prob::Model, rhs::Vector)
    ncons = num_constr(prob)
    status = @cpx_ccall(chgrhs, Cint, (
                        Ptr{Void},
                        Ptr{Void},
                        Cint,
                        Ptr{Cint},
                        Ptr{Float64}
                        ),
                        prob.env.ptr, prob.lp, ncons, Cint[0:ncons-1], float(rhs))
    if status != 0
        error("CPLEX: error setting RHS")
    end
end

function get_constrLB(prob::Model)
    senses = get_constr_senses(prob)
    ret    = get_rhs(prob)
    for i = 1:num_constr(prob)
        if senses[i] == 'G' || senses[i] == 'E'
            # Do nothing
        else
            # LEQ constraint so LB is -Inf
            ret[i] = -Inf
        end
    end
    return ret
end

function get_constrUB(prob::Model)
    senses = get_constr_senses(prob)
    ret    = get_rhs(prob)
    for i = 1:num_constr(prob)
        if senses[i] == 'L' || senses[i] == 'E'
            # Do nothing
        else
            # GEQ constraint so UB is Inf
            ret[i] = +Inf
        end
    end
    return ret
end

function set_constrLB!(prob::Model, lb)
    senses = get_constr_senses(prob)
    rhs    = get_rhs(prob)
    sense_changed = false
    for i = 1:num_constr(prob)
        if senses[i] == 'G' || senses[i] == 'E'
            # Do nothing
        elseif senses[i] == 'L' && lb[i] != -Inf
            # LEQ constraint with non-NegInf LB implies a range
            if isapprox(lb[i], rhs[i])
                # seems to be an equality
                senses[i] = 'E'
                sense_changed = true
            else
                error("Tried to set LB != -Inf on a LEQ constraint (index $i)")
            end
        end
    end
    if sense_changed
        set_constr_senses!(prob, senses)
    end
    set_rhs!(prob, lb)
end

function set_constrUB!(prob::Model, lb)
    senses = get_constr_senses(prob)
    rhs    = get_rhs(prob)
    sense_changed = false
    for i = 1:num_constr(prob)
        if senses[i] == 'L' || senses[i] == 'E'
            # Do nothing
        elseif senses[i] == 'L' && lb[i] != -Inf
            # GEQ constraint with non-PosInf UB implies a range
            if isapprox(ub[i], rhs[i])
                # seems to be an equality
                senses[i] = 'E'
                sense_changed = true
            else
                error("Tried to set LB != +Inf on a GEQ constraint (index $i)")
            end
        end
    end
    if sense_changed
        set_constr_senses!(prob, senses)
    end
    set_rhs!(prob, lb)
end
