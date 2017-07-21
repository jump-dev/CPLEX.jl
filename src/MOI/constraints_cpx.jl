function cpx_add_constraint!(m, cols::Vector{Int}, coefficients::Vector{Float64}, sense::Cchar, rhs::Float64)
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
        model.env.ptr, model.lp, 0, Cint(1), nnz, rhs, sense, Cint(0), Cint.(cols-1), coeffs, C_NULL, C_NULL)
end
