function c_api_addrows(model::Model, cbegins::IVec, inds::IVec, coeffs::FVec,
                   rel::CVec, rhs::FVec)

    nnz   = length(inds)
    ncons = length(rhs)
    (nnz == length(coeffs)) || error("Incompatible constraint arg dimensions.")

    if ncons > 0
        stat = @cpx_ccall(addrows, Cint, (
                          Ptr{Cvoid},        # environment
                          Ptr{Cvoid},        # problem
                          Cint,             # num new cols
                          Cint,             # num new rows
                          Cint,             # num non-zeros
                          Ptr{Cdouble},     # rhs
                          Ptr{Cchar},       # sense
                          Ptr{Cint},        # matrix start
                          Ptr{Cint},        # matrix index
                          Ptr{Cdouble},     # matrix values
                          Ptr{Ptr{Cchar}},  # col names
                          Ptr{Ptr{Cchar}}   # row names
                          ),
                          model.env.ptr, model.lp, 0, ncons, nnz, rhs, rel,
                          cbegins .- Cint(1), inds .- Cint(1), coeffs,
                          C_NULL, C_NULL)

        if stat != 0
           throw(CplexError(model.env, stat))
        end
    end
end

# same as add_rows but does conversion of sense chars
function add_constrs!(model::Model, cbegins::IVec, inds::IVec, coeffs::FVec,
                      rel::CVec, rhs::FVec)

    for k in 1:length(rel)
        if rel[k] == UInt8('>')
            rel[k] = convert(Cchar, 'G')
        elseif rel[k] == UInt8('<')
            rel[k] = convert(Cchar, 'L')
        elseif rel[k] == UInt8('=')
            rel[k] = convert(Cchar, 'E')
        end
    end

    c_api_addrows(model, cbegins, inds, coeffs, rel, rhs)
end

add_constr!(model::Model, coef::Vector, sense::Char, rhs) = add_constrs!(model, [1], collect(1:length(coef)), coef, [sense], [rhs])

function add_constrs!(model::Model, cbeg::Vector, inds::Vector, coeffs::Vector, rel::Vector, rhs::Vector)
    add_constrs!(model, ivec(cbeg), ivec(inds), fvec(coeffs), cvecx(rel, length(cbeg)), fvec(rhs))
end

function add_constrs_t!(model::Model, At::SparseMatrixCSC{Float64}, rel::GCharOrVec, b::Vector)
    n, m = size(At)
    (m == length(b) && n == num_var(model)) || error("Incompatible argument dimensions.")
    add_constrs!(model, At.colptr[1:At.n], At.rowval, At.nzval, rel, b)
end

function add_constrs_t!(model::Model, At::AbstractArray{Float64, 2}, rel::GCharOrVec, b::Vector)
    n, m = size(At)
    (m == length(b) && n == num_var(model)) || error("Incompatible argument dimensions.")
    add_constrs_t!(model, sparse(At), rel, b)
end

function add_constrs!(model::Model, A::CoeffMat, rel::GCharOrVec, b::Vector{Float64})
    m, n = size(A)
    (m == length(b) && n == num_var(model)) || error("Incompatible argument dimensions.")
    add_constrs_t!(model, transpose(A), rel, b)
end

add_constrs!(model::Model, cbeg::Vector, inds::Vector, coeffs::Vector, rel::Char, rhs::Vector) = add_constrs!(model, cbeg, inds, coeffs, cvecx(rel, length(cbeg)), rhs)

function add_rangeconstrs!(model::Model, cbegins::IVec, inds::IVec, coeffs::FVec, lb::FVec, ub::FVec)
    nnz   = length(inds)
    ncons = length(lb)
    (ncons  == length(ub) && nnz == length(coeffs)) || error("Incompatible constraint argument dimensions.")

    sense = fill!(Vector{Cchar}(undef, ncons), 'R')

    for i in 1:ncons
        if lb[i] == -Inf
            lb[i] = -ub[i]
            ub[i] = Inf
            coeffs[cbegins[i]+1:cbegins[i+1]] = -coeffs[cbegins[i]+1:cbegins[i+1]]
        end
    end

    if ncons > 0
        stat = @cpx_ccall(addrows, Cint, (
                          Ptr{Cvoid},        # environment
                          Ptr{Cvoid},        # problem
                          Cint,             # num new cols
                          Cint,             # num new rows
                          Cint,             # num non-zeros
                          Ptr{Cdouble},     # rhs
                          Ptr{Cchar},       # sense
                          Ptr{Cint},        # matrix start
                          Ptr{Cint},        # matrix index
                          Ptr{Cdouble},     # matrix values
                          Ptr{Cvoid},        # col names
                          Ptr{Cvoid}         # row names
                          ),
                          model.env.ptr, model.lp, 0, ncons, nnz, lb, sense, cbegins[1:end-1], inds, coeffs, C_NULL, C_NULL)
        if stat != 0
            throw(CplexError(model.env, stat))
        end
        for i = 1:ncons
            stat = @cpx_ccall(chgrngval, Cint, (
                      Ptr{Cvoid},
                      Ptr{Cvoid},
                      Cint,
                      Ptr{Cint},
                      Ptr{Cdouble}
                      ),
                      model.env.ptr, model.lp, 1, Cint[i-1], [ub[i]-lb[i]])
            if stat != 0
                throw(CplexError(model.env, stat))
            end
        end
    end
end

function add_rangeconstrs!(model::Model, cbeg::Vector, inds::Vector, coeffs::Vector, lb::Vector, ub::Vector)
    add_rangeconstrs!(model, ivec(cbeg), ivec(inds), fvec(coeffs), fvec(lb), fvec(ub))
end

function add_rangeconstrs_t!(model::Model, At::SparseMatrixCSC{Float64}, lb::Vector, ub::Vector)
    add_rangeconstrs!(model, At.colptr-1, At.rowval-1, At.nzval, lb, ub)
end

function add_rangeconstrs_t!(model::Model, At::Matrix{Float64}, lb::Vector, ub::Vector)
    add_rangeconstrs_t!(model, sparse(At), lb, ub)
end

function add_rangeconstrs!(model::Model, A::CoeffMat, lb::Vector, ub::Vector)
    m, n = size(A)
    (m == length(lb) == length(ub) && n == num_var(model)) || error("Incompatible constraint argument dimensions.")
    add_rangeconstrs_t!(model, transpose(A), lb, ub)
end

function c_api_getnumrows(model::Model)
    ncons = @cpx_ccall(getnumrows, Cint, (
                       Ptr{Cvoid},
                       Ptr{Cvoid}
                       ),
                       model.env.ptr, model.lp)
    return ncons
end
# Needed by MathProgBase Interface
num_constr(model::Model) = c_api_getnumrows(model)

function get_constr_senses(model::Model)
    ncons = num_constr(model)
    senses = Vector{Cchar}(undef, ncons)
    stat = @cpx_ccall(getsense, Cint, (
                      Ptr{Cvoid},
                      Ptr{Cvoid},
                      Ptr{Cchar},
                      Cint,
                      Cint
                      ),
                      model.env.ptr, model.lp, senses, 0, ncons-1)
    if stat != 0
        throw(CplexError(model.env, stat))
    end
    return senses
end

function c_api_chgsense(model::Model, indices::IVec, senses::CVec)
    ncons = length(IVec)
    stat = @cpx_ccall(chgsense, Cint, (
                      Ptr{Cvoid},
                      Ptr{Cvoid},
                      Cint,
                      Ptr{Cint},
                      Ptr{Cchar}
                      ),
                      model.env.ptr, model.lp, ncons,
                      indices .- Cint(1), senses)
    if stat != 0
        throw(CplexError(model.env, stat))
    end
end

function set_constr_senses!(model::Model, senses::Vector)
    ncons = num_constr(model)
    stat = @cpx_ccall(chgsense, Cint, (
                      Ptr{Cvoid},
                      Ptr{Cvoid},
                      Cint,
                      Ptr{Cint},
                      Ptr{Cchar}
                      ),
                      model.env.ptr, model.lp, ncons, Cint[0:ncons-1;],
                      convert(Vector{Cchar},senses))
    if stat != 0
        throw(CplexError(model.env, stat))
    end
end

function c_api_getrhs(model::Model, rhs::Vector{Cdouble},
        row_start::Cint, row_end::Cint)

    stat = @cpx_ccall(getrhs, Cint, (
                      Ptr{Cvoid},
                      Ptr{Cvoid},
                      Ptr{Cdouble},
                      Cint,
                      Cint
                      ),
                      model.env.ptr, model.lp, rhs,
                      row_start - Cint(1), row_end - Cint(1))
    if stat != 0
        throw(CplexError(model.env, stat))
    end
end

function get_rhs(model::Model)
    ncons = num_constr(model)
    rhs = Vector{Cdouble}(undef, ncons)
    stat = @cpx_ccall(getrhs, Cint, (
                      Ptr{Cvoid},
                      Ptr{Cvoid},
                      Ptr{Cdouble},
                      Cint,
                      Cint
                      ),
                      model.env.ptr, model.lp, rhs, 0, ncons-1)
    if stat != 0
        throw(CplexError(model.env, stat))
    end
    return rhs
end

function c_api_chgrhs(model::Model, indices::IVec, rhs::FVec)
    ncons = length(indices)
    @assert ncons == length(rhs)
    stat = @cpx_ccall(chgrhs, Cint, (
                      Ptr{Cvoid},
                      Ptr{Cvoid},
                      Cint,
                      Ptr{Cint},
                      Ptr{Cdouble}
                      ),
                      model.env.ptr, model.lp, ncons, indices .- Cint(1), rhs)
    if stat != 0
        throw(CplexError(model.env, stat))
    end
end

function set_rhs!(model::Model, rhs::Vector)
    ncons = num_constr(model)
    @assert ncons == length(rhs)
    stat = @cpx_ccall(chgrhs, Cint, (
                      Ptr{Cvoid},
                      Ptr{Cvoid},
                      Cint,
                      Ptr{Cint},
                      Ptr{Cdouble}
                      ),
                      model.env.ptr, model.lp, ncons, Cint[0:ncons-1;], float(rhs))
    if stat != 0
        throw(CplexError(model.env, stat))
    end
end

function get_constrLB(model::Model)
    senses = get_constr_senses(model)
    ret    = get_rhs(model)
    for i = 1:num_constr(model)
        if senses[i] == UInt8('G') || senses[i] == UInt8('E')
            # Do nothing
        else
            # LEQ constraint so LB is -Inf
            ret[i] = -Inf
        end
    end
    return ret
end

function get_constrUB(model::Model)
    senses = get_constr_senses(model)
    ret    = get_rhs(model)
    for i = 1:num_constr(model)
        if senses[i] == UInt8('L') || senses[i] == UInt8('E')
            # Do nothing
        else
            # GEQ constraint so UB is Inf
            ret[i] = +Inf
        end
    end
    return ret
end

function set_constrLB!(model::Model, lb)
    senses = get_constr_senses(model)
    rhs    = get_rhs(model)
    sense_changed = false
    for i = 1:num_constr(model)
        if senses[i] == UInt8('G') || senses[i] == UInt8('E')
            # Do nothing
        elseif senses[i] == UInt8('L')
            if lb[i] != -Inf
                # LEQ constraint with non-NegInf LB implies a range
                if isapprox(lb[i], rhs[i])
                    # seems to be an equality
                    senses[i] = 'E'
                    sense_changed = true
                else
                    error("Tried to set LB != -Inf on a LEQ constraint (index $i)")
                end
            else
                lb[i] = rhs[i]
            end
        end
    end
    if sense_changed
        set_constr_senses!(model, senses)
    end
    set_rhs!(model, lb)
end

function set_constrUB!(model::Model, ub)
    senses = get_constr_senses(model)
    rhs    = get_rhs(model)
    sense_changed = false
    for i = 1:num_constr(model)
        if senses[i] == UInt8('L') || senses[i] == UInt8('E')
            # Do nothing
        elseif senses[i] == UInt8('G')
            if ub[i] != Inf
                # GEQ constraint with non-PosInf UB implies a range
                if isapprox(ub[i], rhs[i])
                    # seems to be an equality
                    senses[i] = 'E'
                    sense_changed = true
                else
                    error("Tried to set UB != +Inf on a GEQ constraint (index $i)")
                end
            else
              ub[i] = rhs[i]
            end
        end
    end
    if sense_changed
        set_constr_senses!(model, senses)
    end
    set_rhs!(model, ub)
end

function get_nnz(model::Model)
  ret = @cpx_ccall(getnumnz, Cint, (Ptr{Cvoid}, Ptr{Cvoid}), model.env.ptr, model.lp)
  ret == 0 && throw(error("Could not query number of nonzeros in model"))
  return ret
end

function c_api_getrows(model::Model, mbegin::Cint, mend::Cint)
    nzcnt_p = Vector{Cint}(undef, 1)
    m = mend - mbegin + 1
    nnz = get_nnz(model)
    rmatbeg = Vector{Cint}(undef, m+1)
    rmatind = Vector{Cint}(undef, nnz)
    rmatval = Vector{Cdouble}(undef, nnz)
    surplus_p = Vector{Cint}(undef, 1)
    stat = @cpx_ccall(getrows, Cint, (
                    Ptr{Cvoid},
                    Ptr{Cvoid},
                    Ptr{Cint},
                    Ptr{Cint},
                    Ptr{Cint},
                    Ptr{Cdouble},
                    Cint,
                    Ptr{Cint},
                    Cint,
                    Cint
                    ),
                    model.env.ptr, model.lp, nzcnt_p,
                    rmatbeg, rmatind, rmatval,
                    nnz, surplus_p, mbegin-Cint(1), mend-Cint(1))
    if stat != 0 || surplus_p[1] < 0
        throw(CplexError(model.env, stat))
    end
    rmatbeg[end] = nnz # add the last entry that Julia wants
    return (nzcnt_p[1], rmatbeg, rmatind .+ Cint(1), rmatval)
end

function get_constr_matrix(model::Model)
  nzcnt_p = Vector{Cint}(undef, 1)
  m = num_constr(model)
  n = num_var(model)
  nnz = get_nnz(model)
  cmatbeg = Vector{Cint}(undef, n+1)
  cmatind = Vector{Cint}(undef, nnz)
  cmatval = Vector{Cdouble}(undef, nnz)
  surplus_p = Vector{Cint}(undef, 1)
  stat = @cpx_ccall(getcols, Cint, (
                    Ptr{Cvoid},
                    Ptr{Cvoid},
                    Ptr{Cint},
                    Ptr{Cint},
                    Ptr{Cint},
                    Ptr{Cdouble},
                    Cint,
                    Ptr{Cint},
                    Cint,
                    Cint
                    ),
                    model.env.ptr, model.lp, nzcnt_p, cmatbeg, cmatind, cmatval, nnz, surplus_p, 0, n-1)
  if stat != 0 || surplus_p[1] < 0
    throw(CplexError(model.env, stat))
  end
  cmatbeg[end] = nnz # add the last entry that Julia wants
  return SparseMatrixCSC(m, n, convert(Vector{Int64}, cmatbeg.+1), convert(Vector{Int64}, cmatind.+1), cmatval)
end

get_num_sos(model::Model) = @cpx_ccall(getnumsos, Cint, (Ptr{Cvoid}, Ptr{Cvoid}), model.env.ptr, model.lp)

# int CPXaddsos( CPXCENVptr env, CPXLPptr lp, int numsos, int numsosnz, char const * sostype, int const * sosbeg, int const * sosind, double const * soswt, char ** sosname )
function add_sos!(model::Model, sostype::Symbol, idx::Vector{Int}, weight::Vector{Cdouble})
    ((nelem = length(idx)) == length(weight)) || error("Index and weight vectors of unequal length")
    (sostype == :SOS1) ? (typ = CPX_TYPE_SOS1) : ((sostype == :SOS2) ? (typ = CPX_TYPE_SOS2) : error("Invalid SOS constraint type"))
    stat = @cpx_ccall(addsos, Cint, (
                      Ptr{Cvoid},
                      Ptr{Cvoid},
                      Cint,
                      Cint,
                      Ptr{Cchar},
                      Ptr{Cint},
                      Ptr{Cint},
                      Ptr{Cdouble},
                      Ptr{Ptr{Cchar}}
                      ),
                      model.env.ptr, model.lp, convert(Cint, 1), convert(Cint, nelem), [convert(Cchar, typ)], Cint[0], convert(Vector{Cint}, idx.-1), weight, C_NULL)
    if stat != 0
        throw(CplexError(model.env, stat))
    end
    model.has_int = true
    model.has_sos = true
    return nothing
end

# int CPXgetsos( CPXCENVptr env, CPXCLPptr lp, int * numsosnz_p, char * sostype,
# int * sosbeg, int * sosind, double * soswt, int sosspace, int * surplus_p, int
# begin, int end )
function c_api_getsos(model::Model, index::Int)
    numsosnz_p = Ref{Cint}()
    surplus_p = Ref{Cint}()
    sos_type = Ref{Cchar}()
    sos_beg = Ref{Cint}()
    stat = @cpx_ccall(getsos, Cint, (
        Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cint}, Ptr{Cchar}, Ptr{Cint}, Ptr{Cint},
        Ptr{Cdouble}, Cint, Ptr{Cint}, Cint, Cint),
        model.env.ptr, model.lp, numsosnz_p, sos_type, sos_beg, C_NULL, C_NULL,
        0, surplus_p, index, index)

    num_terms = -surplus_p[]
    columns = fill(Cint(0), num_terms)
    weights = fill(Cdouble(0.0), num_terms)
    stat = @cpx_ccall(getsos, Cint, (
        Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cint}, Ptr{Cchar}, Ptr{Cint}, Ptr{Cint},
        Ptr{Cdouble}, Cint, Ptr{Cint}, Cint, Cint),
        model.env.ptr, model.lp, numsosnz_p, sos_type, sos_beg, columns, weights,
        num_terms, surplus_p, index, index)
    if stat != 0
        throw(CplexError(model.env, stat))
    end
    return (columns, weights, sos_type[])
end

# int CPXdelsos( CPXCENVptr env, CPXLPptr lp, int begin, int end )
function c_api_delsos(model::Model, begin_index::Int, end_index::Int)
    stat = @cpx_ccall(delsos, Cint, (Ptr{Cvoid}, Ptr{Cvoid}, Cint, Cint),
        model.env.ptr, model.lp, begin_index, end_index)
    if stat != 0
        throw(CplexError(model.env, stat))
    end
    return
end

add_indicator_constraint(model::Model, idx, coeff, sense, rhs, indicator) =
    add_indicator_constraint(model::Model, idx, coeff, sense, rhs, indicator, 0)
add_indicator_constraint(model::Model, idx, coeff, sense, rhs, indicator, comp) =
    add_indicator_constraint(model, convert(Vector{Cint},idx), convert(Vector{Cdouble},coeff),
                             convert(Cint,sense), convert(Cdouble,rhs), convert(Cint,indicator), convert(Cint,comp))
function add_indicator_constraint(model::Model, idx::Vector{Cint}, coeff::Vector{Cdouble}, sense::Cint, rhs::Cdouble, indicator::Cint, comp::Cint)
    (nzcnt = length(idx)) == length(coeff) || error("Incompatible lengths in constraint specification")
    stat = @cpx_ccall(addindconstr, Cint, (
                      Ptr{Cvoid},
                      Ptr{Cvoid},
                      Cint,
                      Cint,
                      Cint,
                      Cdouble,
                      Cint,
                      Ptr{Cint},
                      Ptr{Cdouble},
                      Ptr{Cchar}),
                      model.env.ptr, model.lp, indicator .- Cint(1), comp,
                      nzcnt, rhs, sense, idx .- Cint(1), coeff, C_NULL)
    if stat != 0
        throw(CplexError(model.env, stat))
    end
    return nothing
end

function c_api_chgcoef(model::Model, row::Cint, col::Cint, coef::Cdouble)
    stat = @cpx_ccall(chgcoef, Cint, (
                      Ptr{Cvoid},        # environment
                      Ptr{Cvoid},        # problem
                      Cint,             # row
                      Cint,             # col
                      Cdouble,          # coef
                      ),
                      model.env.ptr, model.lp,
                      row - Cint(1), col - Cint(1), coef)

    if stat != 0
       throw(CplexError(model.env, stat))
    end
end

function c_api_delrows(model::Model, first::Cint, last::Cint)
    stat = @cpx_ccall(delrows, Cint, (
                      Ptr{Cvoid},
                      Ptr{Cvoid},
                      Cint,
                      Cint,
                      ),
                      model.env.ptr, model.lp, first-1, last-1)

    if stat != 0
       throw(CplexError(model.env, stat))
    end
end
