function cpx_newcols!(model::Model, n::Int)
    if n > 0
        @cpx_ccall_error(model.env, newcols, Cint, (
          Ptr{Void},
          Ptr{Void},
          Cint,
          Ptr{Cdouble},
          Ptr{Cdouble},
          Ptr{Cdouble},
          Ptr{Cchar},
          Ptr{Ptr{Cchar}}
          ),
          model.env.ptr, model.lp, n, zeros(n), fill(-CPX_INFBOUND, n), fill(CPX_INFBOUND, n), C_NULL, C_NULL)
    end
end

function cpx_getnumcols(model::Model)
    @cpx_ccall(getnumcols, Cint, (Ptr{Void}, Ptr{Void}), model.env.ptr, model.lp)
end

function cpx_chgbds!(model::Model, cols::Vector{Int}, values::Vector{Float64}, sense::Vector{Cchar})
    @assert length(cols) == length(values) == length(sense)
    bounds = copy(values)
    for (i, v) in enumerate(values)
        if v > CPX_INFBOUND
            # TODO: potentially throw a warning here
            bounds[i] = CPX_INFBOUND
        elseif v < -CPX_INFBOUND
            bounds[i] = -CPX_INFBOUND
        end
    end
    @cpx_ccall_error(model.env, chgbds, Cint, (
        Ptr{Void},
        Ptr{Void},
        Cint,
        Ptr{Cint},
        Ptr{Cchar},
        Ptr{Cdouble}
        ),
        model.env.ptr, model.lp, Cint(length(cols)), Cint.(cols-1), sense, bounds)
end

function cpx_getub(model::Model, col::Int)
    ub = Vector{Cdouble}(1)
    @cpx_ccall_error(model.env, getub, Cint, (
        Ptr{Void},
        Ptr{Void},
        Ptr{Cdouble},
        Cint,
        Cint
        ),
        model.env.ptr, model.lp, ub, col-1, col-1)
    return ub[1]
end
function cpx_getlb(model::Model, col::Int)
    lb = Vector{Cdouble}(1)
    @cpx_ccall_error(model.env, getlb, Cint, (
        Ptr{Void},
        Ptr{Void},
        Ptr{Cdouble},
        Cint,
        Cint
        ),
        model.env.ptr, model.lp, lb, col-1, col-1)
    return lb[1]
end

function cpx_delcols!(model::Model, colbegin::Int, colend::Int)
    @cpx_ccall_error(model.env, delcols, Cint, (
        Ptr{Void},
        Ptr{Void},
        Cint,
        Cint
        ),
        model.env.ptr, model.lp, Cint(colbegin-1), Cint(colend-1))
end


function cpx_chgctype!(model::Model, vidx::Vector{Int}, vtype::Vector{Char})
    @cpx_ccall_error(model.env, chgctype, Cint, (
                      Ptr{Void},
                      Ptr{Void},
                      Cint,
                      Ptr{Cint},
                      Ptr{Cchar}
                      ),
                      model.env.ptr, model.lp, length(vtype), Cint.(vidx), Cchar.(vtype))
end

function cpx_getctype(model::Model)
    nvars = cpx_numcols(model)
    vartypes = Vector{Cchar}(nvars)
    @cpx_ccall_error(model.env, getctype, Cint, (
                      Ptr{Void},
                      Ptr{Void},
                      Ptr{Cchar},
                      Cint,
                      Cint
                      ),
                      model.env.ptr, model.lp, vartypes, 0, nvars-1)
    return Char.(vartypes)
end
