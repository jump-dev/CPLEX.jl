function add_rangeconstrs!(prob::CPXproblem, cbegins::IVec, inds::IVec, coeffs::FVec, lb::FVec, ub::FVec)
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

function add_rangeconstrs!(prob::CPXproblem, cbeg::Vector, inds::Vector, coeffs::Vector, lb::Vector, ub::Vector)
    add_rangeconstrs!(prob, ivec(cbeg), ivec(inds), fvec(coeffs), fvec(lb), fvec(ub))
end

function add_rangeconstrs_t!(prob::CPXproblem, At::SparseMatrixCSC{Float64}, lb::Vector, ub::Vector)
    add_rangeconstrs!(prob, At.colptr-1, At.rowval-1, At.nzval, lb, ub)
end

function add_rangeconstrs_t!(prob::CPXproblem, At::Matrix{Float64}, lb::Vector, ub::Vector)
    add_rangeconstrs_t!(prob, sparse(At), lb, ub)
end

function add_rangeconstrs!(prob::CPXproblem, A::CoeffMat, lb::Vector, ub::Vector)
    m, n = size(A)
    (m == length(lb) == length(ub) && n == prob.nvars) || error("Incompatible constraint argument dimensions.")
    add_rangeconstrs_t!(prob, transpose(A), lb, ub)
end
