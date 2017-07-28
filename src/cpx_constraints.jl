function cpx_add_constraint!(model::Model, cols::Vector{Int}, coefficients::Vector{Float64}, sense::Cchar, rhs::Float64)
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

function get_rhs(model::Model)
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
