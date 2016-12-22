function add_vars!(model::Model, obj::Vector, l_in::Bounds, u_in::Bounds)
    nvars = length(obj)
    obj = fvec(obj)
    l = fvecx(copy(l_in), nvars)
    u = fvecx(copy(u_in), nvars)
    for i = 1:nvars
        if l[i] == -Inf
            l[i] = -CPX_INFBOUND
        end
        if u[i] == Inf
            u[i] = CPX_INFBOUND
        end
    end
    if nvars > 0
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
                          model.env.ptr, model.lp, nvars, float(obj), float(l), float(u), C_NULL, C_NULL)
        if stat != 0
            throw(CplexError(model.env, stat))
        end
    end
end

add_var!(model::Model, obj::Vector, l::Vector, u::Vector) = add_vars!(model, obj, l, u)

function add_var!(model::Model, constridx::IVec, constrcoef::FVec, l::FVec, u::FVec, objcoef::FVec)
    nvars = length(objcoef)
    (nvars == length(l) == length(u)) || error("Inconsistent dimensions when adding variables.")
    for i = 1:nvars
        if l[i] == -Inf
            l[i] = -CPX_INFBOUND
        end
        if u[i] == Inf
            u[i] = CPX_INFBOUND
        end
    end
    if nvars > 0
        stat = @cpx_ccall(addcols, Cint, (
                          Ptr{Void},
                          Ptr{Void},
                          Cint,
                          Cint,
                          Ptr{Cdouble},
                          Ptr{Cint},
                          Ptr{Cint},
                          Ptr{Cdouble},
                          Ptr{Cdouble},
                          Ptr{Cdouble},
                          Ptr{Ptr{Cchar}}
                          ),
                          model.env.ptr, model.lp, nvars, length(constridx), objcoef, Cint[0], constridx-Cint(1), constrcoef, l, u, C_NULL)
        if stat != 0
            throw(CplexError(model.env, stat))
        end
    end
end

add_var!(model::Model, obj, l, u) = add_vars!(model, Cdouble[obj], Cdouble[l], Cdouble[u])

function add_var!(model::Model, constridx, constrcoef, l, u, objcoef)
    return add_var!(model,
                    convert(Vector{Cint},   vec(collect(constridx))),
                    convert(Vector{Cdouble},vec(collect(constrcoef))),
                    convert(Vector{Cdouble},vec(collect(l))),
                    convert(Vector{Cdouble},vec(collect(u))),
                    convert(Vector{Cdouble},vec(collect(objcoef))))
end

function add_var!(model::Model, constridx::Vector, constrcoef::Vector, l::Vector, u::Vector, objcoef::Vector)
    return add_var!(model, ivec(constridx), fvec(constrcoef), fvec(l), fvec(u), fvec(objcoef))
end

function get_varLB(model::Model)
    nvars = num_var(model)
    lb = Array(Cdouble, nvars)
    stat = @cpx_ccall(getlb, Cint, (
                      Ptr{Void},
                      Ptr{Void},
                      Ptr{Cdouble},
                      Cint,
                      Cint
                      ),
                      model.env.ptr, model.lp, lb, 0, nvars-1)
    if stat != 0
        throw(CplexError(model.env, stat))
    end
    return lb
end

function set_varLB!(model::Model, l::FVec)
    nvars = num_var(model)
    for i = 1:nvars
        if l[i] == -Inf
            l[i] = -CPX_INFBOUND
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
                      model.env.ptr, model.lp, nvars, Cint[0:nvars-1;], fill(convert(Cchar, 'L'), nvars), l)
    if stat != 0
        throw(CplexError(model.env, stat))
    end
end

function get_varUB(model::Model)
    nvars = num_var(model)
    ub = Array(Cdouble, nvars)
    stat = @cpx_ccall(getub, Cint, (
                      Ptr{Void},
                      Ptr{Void},
                      Ptr{Cdouble},
                      Cint,
                      Cint
                      ),
                      model.env.ptr, model.lp, ub, 0, nvars-1)
    if stat != 0
        throw(CplexError(model.env, stat))
    end
    return ub
end

function set_varUB!(model::Model, u::FVec)
    nvars = num_var(model)
        for i = 1:nvars
        if u[i] == Inf
            u[i] = CPX_INFBOUND
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
                      model.env.ptr, model.lp, nvars, Cint[0:nvars-1;], fill(convert(Cchar, 'U'), nvars), u)
    if stat != 0
        throw(CplexError(model.env, stat))
    end
end


function set_vartype!(model::Model, vtype::Vector{Char})
    nvars = num_var(model)
    stat = @cpx_ccall(chgctype, Cint, (
                      Ptr{Void},
                      Ptr{Void},
                      Cint,
                      Ptr{Cint},
                      Ptr{Cchar}
                      ),
                      model.env.ptr, model.lp, length(vtype), Cint[0:length(vtype)-1;], convert(Vector{Cchar},vtype))
    if stat != 0
        throw(CplexError(model.env, stat))
    end
    if !isempty(find(!(vtype.=='C')))
        model.has_int = true
    end
end

function get_vartype(model::Model)
    nvars = num_var(model)
    vartypes = Array(Cchar, nvars)
    stat = @cpx_ccall(getctype, Cint, (
                      Ptr{Void},
                      Ptr{Void},
                      Ptr{Cchar},
                      Cint,
                      Cint
                      ),
                      model.env.ptr, model.lp, vartypes, 0, nvars-1)
    if stat != 0
        throw(CplexError(model.env, stat))
    end
    return convert(Vector{Char},vartypes)
end

function num_var(model::Model)
    nvar = @cpx_ccall(getnumcols, Cint, (
                      Ptr{Void},
                      Ptr{Void}
                      ),
                      model.env.ptr, model.lp)
    return(nvar)
end

function set_varname!(model::Model, idx::Integer, name::String)
    s = bytestring(name)
    @assert isascii(name)

    stat = @cpx_ccall(chgcolname, Cint, (
                      Ptr{Void},
                      Ptr{Void},
                      Cint,
                      Ptr{Cint},
                      Ptr{Ptr{UInt8}}
                      ),
                      model.env.ptr, model.lp, 1, Cint[idx-1], [pointer(s)])
    if stat != 0
        throw(CplexError(model.env, stat))
    end
end
