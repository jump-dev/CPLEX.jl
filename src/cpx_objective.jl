function cpx_chgobj!(model::Model, cols::Vector{Int}, coefs::Vector{Float64})
    @assert length(cols) == length(coefs)
    @cpx_ccall_error(model.env, chgobj, Cint, (
        Ptr{Void},
        Ptr{Void},
        Cint,
        Ptr{Cint},
        Ptr{Cdouble}
        ),
        model.env.ptr, model.lp, Cint(length(cols)), Cint.(cols - 1), coefs)
end

function cpx_chgobjsen!(model::Model, sense::Symbol)
    if sense == :Min
        @cpx_ccall_error(model.env, chgobjsen, Cint, (Ptr{Void}, Ptr{Void}, Cint), model.env.ptr, model.lp, CPX_MIN)
    elseif sense == :Max
        @cpx_ccall_error(model.env, chgobjsen, Cint, (Ptr{Void}, Ptr{Void}, Cint), model.env.ptr, model.lp, CPX_MAX)
    else
        error("Unrecognized objective sense $sense")
    end
end

function cpx_getobjsen(model::Model)
    sense_int = @cpx_ccall(getobjsen, Cint, (Ptr{Void}, Ptr{Void},), model.env.ptr, model.lp)
    if sense_int == CPX_MIN
        return MOI.MinSense
    elseif sense_int == CPX_MAX
        return MOI.MaxSense
    else
        error("CPLEX: problem object or environment does not exist")
    end
end

function cpx_getobj(model::Model)
    nvars = cpx_getnumcols(model)
    obj = Vector{Cdouble}(nvars)
    @cpx_ccall_error(model.env, getobj, Cint, (
                      Ptr{Void},
                      Ptr{Void},
                      Ptr{Cdouble},
                      Cint,
                      Cint
                      ),
                      model.env.ptr, model.lp, obj, 0, nvars-1)
    return obj
end

#=
    Quadratic Related Functions
=#

function cpx_copyquad!(model::Model, rowidx::Vector{Int}, colidx::Vector{Int}, val::Vector{Cdouble})
    @assert length(rowidx) == length(colidx) == length(val)
    n = cpx_getnumcols(model)
    Q = sparse(rowidx, colidx, val, n, n)
    if istriu(Q) || istril(Q) || issymmetric(Q)
        Q = Q + Q' - spdiagm(diag(Q)) # reconstruct full matrix like CPLEX wants
    else
        error("Matrix Q must be either symmetric or triangular")
    end

    nnz_in_row = Cint[Q.colptr[row+1] - Q.colptr[row] for row in 1:n]

    @cpx_ccall_error(model.env, copyquad, Cint,
        (Ptr{Void}, Ptr{Void}, Ptr{Int}, Ptr{Int}, Ptr{Int}, Ptr{Cdouble}),
        model.env.ptr, model.lp, Cint.(Q.colptr[1:end-1]-1), nnz_in_row, Cint.(Q.rowval-1), Cdouble.(Q.nzval)
    )
end