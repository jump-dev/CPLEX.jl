function cpx_addrows!(model::Model, cols::Vector{Int}, coefficients::Vector{Float64}, sense::Cchar, rhs::Float64)
    @assert length(cols) == length(coefficients)
    nnz = Cint(length(cols))
    @cpx_ccall(addrows, Cint, (
        Ptr{Void},        # environment
        Ptr{Void},        # problem
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
        model.env.ptr, model.lp, 0, Cint(1), nnz, [rhs], [sense], [Cint(0)], Cint.(cols-1), coefficients, C_NULL, C_NULL)
end

function cpx_number_constraints(model::Model)
    ncons = @cpx_ccall(getnumrows, Cint, (
                       Ptr{Void},
                       Ptr{Void}
                       ),
                       model.env.ptr, model.lp)
    return ncons
end

function cpx_get_rhs(model::Model)
    ncons = cpx_number_constraints(model)
    rhs = Vector{Cdouble}(ncons)
    @cpx_ccall_error(model.env, getrhs, Cint, (
                      Ptr{Void},
                      Ptr{Void},
                      Ptr{Cdouble},
                      Cint,
                      Cint
                      ),
                      model.env.ptr, model.lp, rhs, 0, ncons-1)
    return rhs
end

function cpx_get_rhs(model::Model, row::Int)
    rhs = Vector{Cdouble}(1)
    @cpx_ccall_error(model.env, getrhs, Cint, (
                      Ptr{Void},
                      Ptr{Void},
                      Ptr{Cdouble},
                      Cint,
                      Cint
                      ),
                      model.env.ptr, model.lp, rhs, Cint(row-1), Cint(row-1))
    return rhs[1]
end

function cpx_chgcoef(model::Model, row::Int, col::Int, val::Cdouble)
    @cpx_ccall_error(model.env, chgcoef, Cint, (
                      Ptr{Void},
                      Ptr{Void},
                      Cint,
                      Cint,
                      Cdouble
                      ),
                      model.env.ptr, model.lp, Cint(row-1), Cint(col-1), val)
end

function cpx_delrows(model::Model, rowsbegin::Int, rowsend::Int)
    @cpx_ccall_error(model.env, delrows, Cint, (
                      Ptr{Void},
                      Ptr{Void},
                      Cint,
                      Cint
                      ),
                      model.env.ptr, model.lp, Cint(rowsbegin-1), Cint(rowsend-1))
end

function cpx_getrows(model::Model, row::Int)
    # query space needed
    nnz_returned = Vector{Cint}(1)
    space_needed = Vector{Cint}(1)
    @cpx_ccall(getrows, Cint, (
                      Ptr{Void},
                      Ptr{Void},
                      Ptr{Cint},
                      Ptr{Cint},
                      Ptr{Cint},
                      Ptr{Cdouble},
                      Cint,
                      Ptr{Cint},
                      Cint,
                      Cint
                      ),
                      model.env.ptr, model.lp, nnz_returned, [Cint(0)], C_NULL, C_NULL, Cint(0), space_needed, Cint(row-1), Cint(row-1))
    nnz = -space_needed[1]

    # now fill with non-zeros
    coef = Vector{Cdouble}(nnz)
    colidx = Vector{Cint}(nnz)
    @cpx_ccall_error(model.env, getrows, Cint, (
                      Ptr{Void},
                      Ptr{Void},
                      Ptr{Cint},
                      Ptr{Cint},
                      Ptr{Cint},
                      Ptr{Cdouble},
                      Cint,
                      Ptr{Cint},
                      Cint,
                      Cint
                      ),
                      model.env.ptr, model.lp, nnz_returned, [Cint(0)], colidx, coef, Cint(nnz), space_needed, Cint(row-1), Cint(row-1))
    return colidx, coef
end
