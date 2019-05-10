# Quadratic terms & constraints
#

function add_qpterms!(model::Model, qr::IVec, qc::IVec, qv::FVec)
    n = num_var(model)
    ((m = length(qr)) == length(qc) == length(qv)) || error("Inconsistent argument dimensions.")
    nqv = copy(qv)
    Q = sparse(qr, qc, nqv, n, n)
    if istriu(Q) || istril(Q) || issymmetric(Q)
        if VERSION >= v"0.7.0-DEV.3382"
            diag_matrix = spdiagm(0 => diag(Q))
        else
            diag_matrix = spdiagm(diag(Q))
        end
        Q = Q + Q' - diag_matrix # reconstruct full matrix like CPLEX wants
    else
        error("Matrix Q must be either symmetric or triangular")
    end
    qmatcnt = Vector{Cint}(undef, n)
    for k = 1:n
      qmatcnt[k] = Q.colptr[k+1] - Q.colptr[k]
    end
    stat = @cpx_ccall(copyquad, Cint, (
                      Ptr{Cvoid},
                      Ptr{Cvoid},
                      Ptr{Cint},
                      Ptr{Cint},
                      Ptr{Cint},
                      Ptr{Cdouble}
                      ),
                      model.env.ptr, model.lp, convert(Array{Cint,1}, Q.colptr[1:end-1].-1), convert(Array{Cint,1},qmatcnt), convert(Array{Cint,1}, Q.rowval.-1), Q.nzval)
    if stat != 0
        throw(CplexError(model.env, stat))
        end
    model.has_qc = true
    nothing
end

function add_qpterms!(model::Model, qr::Vector, qc::Vector, qv::Vector)
    add_qpterms!(model, ivec(qr), ivec(qc), fvec(qv))
end


function add_qpterms!(model, H::SparseMatrixCSC{Float64}) # H must be symmetric
    n = num_var(model)
    (H.m == n && H.n == n) || error("H must be an n-by-n symmetric matrix.")

    nnz_h = nnz(H)
    qr = Vector{Cint}(undef, nnz_h)
    qc = Vector{Cint}(undef, nnz_h)
    qv = Vector{Float64}(undef, nnz_h)
    k = 0

    colptr::Vector{Int} = H.colptr
    nzval::Vector{Float64} = H.nzval

    for i = 1 : n
        qi::Cint = convert(Cint, i)
        for j = colptr[i]:(colptr[i+1]-1)
            qj = convert(Cint, H.rowval[j])

            if qi <= qj
                k += 1
                qr[k] = qi
                qc[k] = qj
                qv[k] = nzval[j]
            end
        end
    end

    add_qpterms!(model, qr[1:k], qc[1:k], qv[1:k])
end

function add_qpterms!(model, H::Matrix{Float64}) # H must be symmetric
    n = num_var(model)
    size(H) == (n, n) || error("H must be an n-by-n symmetric matrix.")

    nmax = div(n * (n + 1), 2)
    qr = Vector{Cint}(undef, nmax)
    qc = Vector{Cint}(undef, nmax)
    qv = Vector{Float64}(undef, nmax)
    k::Int = 0

    for i = 1 : n
        qi = convert(Cint, i)
        for j = i : n
            v = H[j, i]
            if v != 0.
                k += 1
                qr[k] = qi
                qc[k] = convert(Cint, j)
                qv[k] = v
            end
        end
    end

    add_qpterms!(model, qr[1:k], qc[1:k], qv[1:k])
end

function add_diag_qpterms!(model, H::Vector)  # H stores only the diagonal element
    n = num_var(model)
    n == length(H) || error("Incompatible dimensions.")
    q = [convert(Cint,1):convert(Cint,n)]
    add_qpterms!(model, q, q, fvec(h))
end

function add_diag_qpterms!(model, hv::Real)  # all diagonal elements are H
    n = num_var(model)
    q = [convert(Cint,1):convert(Cint,n)]
    add_qpterms!(model, q, q, fill(float64(hv), n))
end


# add_qconstr!

function add_qconstr!(model::Model, lind::IVec, lval::FVec, qr::IVec, qc::IVec, qv::FVec, rel::Cchar, rhs::Float64)
    qnnz = length(qr)
    qnnz == length(qc) == length(qv) || error("Inconsistent argument dimensions.")

    lnnz = length(lind)
    lnnz == length(lval) || error("Inconsistent argument dimensions.")

    if qnnz > 0 || lnnz > 0
        stat = @cpx_ccall(addqconstr, Cint, (
                          Ptr{Cvoid},   # env
                          Ptr{Cvoid},   # model
                          Cint,         # lnnz
                          Cint,         # qnnz
                          Float64,      # rhs
                          Cchar,        # sense
                          Ptr{Cint},    # lind
                          Ptr{Float64}, # lval
                          Ptr{Cint},    # qrow
                          Ptr{Cint},    # qcol
                          Ptr{Float64}, # qval
                          Ptr{UInt8}    # name
                          ),
                          model.env.ptr, model.lp, lnnz, qnnz, rhs, rel, 
                          lind .- Cint(1), lval, qr .- Cint(1), qc .- Cint(1), 
                          qv, C_NULL)
        if stat != 0
            throw(CplexError(model.env, stat))
        end
        model.has_qc = true
    end
    nothing
end

const sensemap = Dict('=' => 'E', '<' => 'L', '>' => 'G')
function add_qconstr!(model::Model, lind::Vector, lval::Vector, qr::Vector, qc::Vector, qv::Vector{Float64}, rel::GChars, rhs::Real)
    add_qconstr!(model, ivec(lind), fvec(lval), ivec(qr), ivec(qc), fvec(qv), cchar(sensemap[rel]), float(rhs))
end

function num_qconstr(model::Model)
    return @cpx_ccall(getnumqconstrs, Cint, (Ptr{Cvoid}, Ptr{Cvoid}),
                      model.env.ptr, model.lp)
end

function c_api_getqconstr(model::Model, row::Int)
    # In the first call, we ask CPLEX how many non-zero elements there are in
    # the affine (-linsurplus_p ) and quadratic (-quadsurplus_p) components.
    rhs_p = Ref{Cdouble}()
    sense_p = Ref{Cchar}()
    linsurplus_p = Ref{Cint}()
    quadsurplus_p = Ref{Cint}()
    stat = @cpx_ccall(
        getqconstr, 
        Cint, (
            Ptr{Cvoid}, Ptr{Cvoid}, 
            Ptr{Cint}, Ptr{Cint}, Ptr{Float64}, Ptr{Cchar},
            Ptr{Cint}, Ptr{Float64}, Cint, Ptr{Cint},
            Ptr{Cint}, Ptr{Cint}, Ptr{Float64}, Cint, Ptr{Cint},
            Cint),
        model.env.ptr, model.lp, 
        C_NULL, C_NULL, rhs_p, sense_p, 
        C_NULL, C_NULL, 0, linsurplus_p,
        C_NULL, C_NULL, C_NULL, 0, quadsurplus_p,
        Cint(row-1))
    # In the second call, we initialize arrays to contain the number of non-zero
    # elements computed in the first part and then actually query the
    # coefficients.
    linspace = -linsurplus_p[]
    quadspace = -quadsurplus_p[]
    linind = fill(Cint(0), linspace)
    linval = fill(Cdouble(0.0), linspace)
    quadrow = fill(Cint(0), quadspace)
    quadcol = fill(Cint(0), quadspace)
    quadval = fill(Cdouble(0.0), quadspace)
    linnzcnt_p = Ref{Cint}()
    quadnzcnt_p = Ref{Cint}()
    stat = @cpx_ccall(
        getqconstr, 
        Cint, (
            Ptr{Cvoid}, Ptr{Cvoid}, 
            Ptr{Cint}, Ptr{Cint}, Ptr{Float64}, Ptr{Cchar},
            Ptr{Cint}, Ptr{Float64}, Cint, Ptr{Cint},
            Ptr{Cint}, Ptr{Cint}, Ptr{Float64}, Cint, Ptr{Cint},
            Cint),
        model.env.ptr, model.lp, 
        linnzcnt_p, quadnzcnt_p, rhs_p, sense_p, 
        linind, linval, linspace, linsurplus_p,
        quadrow, quadcol, quadval, quadspace, quadsurplus_p,
        Cint(row-1))
    if stat != 0
        throw(CplexError(model.env, stat))
    end
    if quadsurplus_p[] < 0 || linsurplus_p[] < 0
        error("Unable to query quadratic constraint, there were more " * 
              "non-zero elements than expected.")
    end
    return linind, linval, quadrow, quadcol, quadval, sense_p[], rhs_p[]
end

function c_api_getquad(model::Model)
    num_variables = num_var(model)
    # In the first call, we ask CPLEX how many non-zero elements there are.
    surplus_p = Ref{Cint}()
    stat = @cpx_ccall(
        getquad,
        Cint, (
             Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cint},
             Ptr{Cint}, Ptr{Cint}, Ptr{Float64},
             Cint, Ptr{Cint}, Cint, Cint),
             model.env.ptr, model.lp, C_NULL,
             C_NULL, C_NULL, C_NULL,
             0, surplus_p, 0, num_variables - 1)
    # In the second call, we initialize arrays to contain the number of
    # non-zero elements computed in the first part and then actually query the
    # coefficients.
    nzcnt_p = Ref{Cint}()
    qmatbeg = fill(Cint(0), num_variables)
    qmatind = fill(Cint(0), -surplus_p[])
    qmatval = fill(0.0, -surplus_p[])
    stat = @cpx_ccall(
        getquad,
        Cint, (
            Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cint},
            Ptr{Cint}, Ptr{Cint}, Ptr{Float64},
            Cint, Ptr{Cint}, Cint, Cint),
        model.env.ptr, model.lp, nzcnt_p,
        qmatbeg, qmatind, qmatval,
        -surplus_p[], surplus_p, 0, num_variables - 1)
    if stat != 0
        throw(CplexError(model.env, stat))
    end
    if surplus_p[] < 0 || nzcnt_p[] != length(qmatind)
        error("Unable to query quadratic constraint, there were more " *
              "non-zero elements than expected.")
    end
    return qmatbeg, qmatind, qmatval
end
