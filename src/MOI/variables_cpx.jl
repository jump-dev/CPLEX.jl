function cpx_add_variables!(model::Model, n::Int)
    if n > 0
        stat = @cpx_ccall(newcols, Cint, (
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
        if stat != 0
            throw(CplexError(model.env, stat))
        end
    end
end

function cpx_number_variables(model::Model)
    @cpx_ccall(getnumcols, Cint, (Ptr{Void}, Ptr{Void}), model.env.ptr, model.lp)
end

function cpx_set_variable_bounds!(model::Model, cols::Vector{Int}, values::Vector{Float64}, sense::Vector{Cchar})
    @assert length(cols) == length(values) == length(sense)
    n = length(cols)
    bounds = copy(values)
    for (i, v) in enumerate(upperbounds)
        if v > CPX_INFBOUND
            # TODO: potentially throw a warning here
            bounds[i] = CPX_INFBOUND
        elseif v < -CPX_INFBOUND
            bounds[i] = -CPX_INFBOUND
        end
    end
    stat = @cpx_ccall(chgbds, Cint, (
                      Ptr{Void},
                      Ptr{Void},
                      Cint,
                      Ptr{Cint},
                      Ptr{Cchar},
                      Ptr{Cdouble}
                      ),
                      model.env.ptr, model.lp, nvars, Cint.(cols-1), sense, bounds)
    if stat != 0
        throw(CplexError(model.env, stat))
    end
end

function cpx_get_variable_upperbound(model::Model, col::Int)
    ub = Vector{Cdouble}(1)
    stat = @cpx_ccall(getub, Cint, (
                      Ptr{Void},
                      Ptr{Void},
                      Ptr{Cdouble},
                      Cint,
                      Cint
                      ),
                      model.env.ptr, model.lp, ub, col-1, col-1)
    if stat != 0
        throw(CplexError(model.env, stat))
    end
    return ub[1]
end
function cpx_get_variable_lowerbound(model::Model, col::Int)
    lb = Vector{Cdouble}(1)
    stat = @cpx_ccall(getlb, Cint, (
                      Ptr{Void},
                      Ptr{Void},
                      Ptr{Cdouble},
                      Cint,
                      Cint
                      ),
                      model.env.ptr, model.lp, lb, col-1, col-1)
    if stat != 0
        throw(CplexError(model.env, stat))
    end
    return lb[1]
end
