function add_rangeconstrs!(prob::CPXproblem, cbegins::IVec, inds::IVec, coeffs::FVec, lb::FVec, ub::FVec)
    nvars = length(cbegins)
    nnz   = length(inds)
    ncons = length(lb)
    (nvars == length(lb) == length(ub) && nnz == length(coeffs)) || error("Incompatible argument dimensions.")

    sense = fill!(Array(Char, ncons), 'R')

    if nvars > 0 && nnz > 0
        status = @cpx_ccall(addrows, Cint, (
                            Ptr{Void},        # environment
                            Ptr{Void},        # problem
                            Cint,             # num constraints
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
                            prob.env.ptr, prob.lp, ccnt, ncons, nnz, ub, sense, cbegins, inds, coeffs, C_NULL, C_NULL)
        if status != 0   
            error("CPLEX: Error adding constraints.")
        end
        status = @cpx_ccall(chgrngval, Cint, (
                            Ptr{Void},
                            Ptr{Void},
                            Cint,
                            Ptr{Cint},
                            Ptr{Float64}
                            ),
                            prob.env.ptr, prob.lp, ncons, convert(Vector, 1:ncons), lb)
    end
end

function add_rangeconstrs!(prob::CPXproblem, cbeg::Vector, inds::Vector, coeffs::Vector, lb::Vector, ub::Vector)
    add_rangeconstrs!(prob, ivec(cbeg), ivec(inds), fvec(coeffs), fvec(lb), fvec(ub))
end

function add_rangeconstrs_t!(prob::CPXproblem, At::SparseMatrixCSC{Float64}, lb::Vector, ub::Vector)
    add_rangeconstrs!(prob, At.colptr[1:At.n], At.rowval, At.nzval, lb, ub)
end

function add_rangeconstrs_t!(prob::CPXproblem, At::Matrix{Float64}, lb::Vector, ub::Vector)
    add_rangeconstrs_t!(prob, sparse(At), lb, ub)
end

function add_rangeconstrs!(prob::CPXproblem, A::CoeffMat, lb::Vector, ub::Vector)
    m, n = size(A)
    (m == length(lb) == length(ub) && n == prob.nvars) || error("Incompatible argument dimensions.")
    add_rangeconstrs_t!(prob, transpose(A), lb, ub)
end
