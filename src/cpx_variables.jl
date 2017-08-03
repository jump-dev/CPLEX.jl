function cpx_newcols!(model::Model, n::Int)
    if n > 0
        for i in 1:n
            push!(model.mipstarts, NaN)
        end
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


function cpx_chgctype!(model::Model, vidx::Vector{Int}, vtype::Vector{Cchar})
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

#=
    Ref https://github.com/JuliaOpt/CPLEX.jl/pull/114 and
    https://github.com/JuliaOpt/CPLEX.jl/issues/117

    Basically, mipstarts can only be added to a model if the problem type is
    integer. However the user might want to set the mip start before the call
    to integer. Therefore we need to record them in the Model object and run
    again before calling mipopt

=#
function cpx_addmipstarts!(model::Model, cols::Vector{Int}, vals::Vector{Float64}, effortlevel::Cint=CPX_MIPSTART_AUTO)
    @assert length(cols) == length(vals)
    for (i, v) in zip(cols, vals)
        model.mipstarts[i] = v
    end
    if PROB_TYPE_MAP[cpx_getprobtype(model)] in INTEGER_PROBLEM_TYPES
        # otherwise problem is not yet integer and we can ignore
        @cpx_ccall_error(model.env, addmipstarts, Cint,
            (Ptr{Void}, Ptr{Void}, Cint, Cint, Ptr{Cint}, Ptr{Cint},
            Ptr{Cdouble}, Ptr{Cint}, Ptr{Ptr{Cchar}}),
            model.env.ptr, model.lp, Cint(1), Cint(length(cols)), Cint[0],
            Cint.(cols-1), Cdouble.(vals), Cint[effortlevel], C_NULL
        )
    end
end
