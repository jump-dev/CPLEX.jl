function cpx_addrows!(model::Model, rowidxbegins::Vector{Int}, cols::Vector{Int}, coefficients::Vector{Float64}, sense::Vector{Cchar}, rhs::Vector{Float64})
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
        model.env.ptr, model.lp, 0, Cint(length(rowidxbegins)), nnz, Cdouble.(rhs), sense, Cint.(rowidxbegins-1), Cint.(cols-1), coefficients, C_NULL, C_NULL)
end

#=
    A ranged constraint has the form
     lb <= f(x) <= ub
     this is implemented by adding a row f(x) 'R' lb, and changing the rngval
     to ub-lb
=#
function cpx_chgrngval!(model::Model, rows::Vector{<:Integer}, vals::Vector{<:Real})
    @cpx_ccall_error(model.env, chgrngval, Cint, (
          Ptr{Void}, Ptr{Void}, Cint, Ptr{Cint}, Ptr{Cdouble}),
          model.env.ptr, model.lp, Cint(length(rows)), Cint.(rows-1), Cdouble.(vals))
end

function cpx_getnumrows(model::Model)
    ncons = @cpx_ccall(getnumrows, Cint, (
                       Ptr{Void},
                       Ptr{Void}
                       ),
                       model.env.ptr, model.lp)
    return ncons
end

function cpx_getrhs(model::Model)
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

function cpx_getrhs(model::Model, row::Int)
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

function cpx_chgcoef!(model::Model, row::Int, col::Int, val::Cdouble)
    @cpx_ccall_error(model.env, chgcoef, Cint, (
                      Ptr{Void},
                      Ptr{Void},
                      Cint,
                      Cint,
                      Cdouble
                      ),
                      model.env.ptr, model.lp, Cint(row-1), Cint(col-1), val)
end

function cpx_delrows!(model::Model, rowsbegin::Int, rowsend::Int)
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

function cpx_addsos!(model::Model, columns::Vector{Int}, weights::Vector{Cdouble}, sostype::Cchar)
    @assert length(columns) == length(weights)
    @assert sostype == CPX_TYPE_SOS1 || sostype == CPX_TYPE_SOS2
    @cpx_ccall_error(model.env, addsos, Cint, (
            Ptr{Void},    # env
            Ptr{Void},    # lp
            Cint,         # numsos
            Cint,         # nnz
            Ptr{Cchar},   # sostype
            Ptr{Cint},    # sos begin
            Ptr{Cint},    # sos indices
            Ptr{Cdouble}, # weights
            Ptr{Ptr{Cchar}} # names
        ),
        model.env.ptr,
        model.lp,
        Cint(1),
        Cint(length(weights)),
        [sostype],
        [Cint(0)],
        Cint.(columns-1),
        Cdouble.(weights),
        C_NULL
    )
end

function cpx_delsos!(model::Model, ibegin::Int, iend::Int)
    @cpx_ccall_error(model.env, delsos, Cint,
        (Ptr{Void}, Ptr{Void}, Cint, Cint),
        model.env.ptr, model.lp, Cint(ibegin-1), Cint(iend-1)
    )
end

function cpx_getnumsos(model::Model)
    @cpx_ccall(getnumsos, Cint,
        (Ptr{Void}, Ptr{Void}),
        model.env.ptr, model.lp)
end

function cpx_getsos(model::Model, idx::Int)
    nnz_returned = Vector{Cint}(1)
    nnz_needed = Vector{Cint}(1)
    types = Vector{Cchar}(1)

    # call once to get space
    @cpx_ccall(getsos, Cint, (
            Ptr{Void},    # env
            Ptr{Void},    # lp
            Ptr{Cint},         # nnz
            Ptr{Cchar},   # sostype
            Ptr{Cint},    # sos begin
            Ptr{Cint},    # sos indices
            Ptr{Cdouble}, # weights
            Cint,       # length of idices vector
            Ptr{Cint},  # length needed
            Cint,   # begin
            Cint    # end
        ),
        model.env.ptr, model.lp, nnz_returned, types, Cint[0], C_NULL, C_NULL,
        Cint(0), nnz_needed, Cint(idx-1), Cint(idx-1)
    )

    # now fill'
    indices = Vector{Cint}(-nnz_needed[1])
    weights = Vector{Cdouble}(-nnz_needed[1])
    @cpx_ccall(getsos, Cint, (
            Ptr{Void},    # env
            Ptr{Void},    # lp
            Ptr{Cint},         # nnz
            Ptr{Cchar},   # sostype
            Ptr{Cint},    # sos begin
            Ptr{Cint},    # sos indices
            Ptr{Cdouble}, # weights
            Cint,       # length of idices vector
            Ptr{Cint},  # length needed
            Cint,   # begin
            Cint    # end
        ),
        model.env.ptr, model.lp, nnz_returned, types, Cint[0], indices, weights,
        Cint(length(indices)), nnz_needed, Cint(idx-1), Cint(idx-1)
    )
    return indices+1, weights, types[1]
end

#=
    Quadratic Constraints
=#

function cpx_addqconstr!(model::Model, lincol::Vector{Int}, linval::Vector{Float64}, rhs::Float64, sense::Cchar, quadrow::Vector{Int}, quadcol::Vector{Int}, quadval::Vector{Float64})
    @assert length(lincol) == length(linval)
    @assert length(quadrow) == length(quadcol) == length(quadval)
    @cpx_ccall(addqconstr, Cint, (
        Ptr{Void},    # env
        Ptr{Void},    # model
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
        model.env.ptr, # env
        model.lp, # model
        Cint(length(lincol)), # lnnz
        Cint(length(quadrow)), # qnnz
        Cdouble(rhs), # rhs
        sense, # sense
        Cint.(lincol-1), # lind
        Cdouble.(linval), # lval
        Cint.(quadrow-1), # qrow
        Cint.(quadcol-1), # qcol
        Cdouble.(quadval), # qval
        C_NULL # name
    )
end

function cpx_getnumqconstrs(model::Model)
    @cpx_ccall(getnumqconstrs, Cint,
        (Ptr{Void}, Ptr{Void}), model.env.ptr, model.lp
    )
end

#=
    sense modification
=#
function cpx_chgsense!(model::Model, rows::Vector{Int}, newsenses::Vector{Cchar})
    @assert length(rows) == length(newsenses)
    @cpx_ccall_error(model.env, chgsense, Cint,
        (Ptr{Void}, Ptr{Void}, Cint, Ptr{Cint}, Ptr{Cchar}),
        model.env.ptr, model.lp, Cint(length(rows)), Cint.(rows-1), newsenses
    )
end
