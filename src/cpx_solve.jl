function optimize!(model::Model)
  @assert is_valid(model.env)
  stat = (if model.has_int
    if VERSION < v"0.7.0-DEV.3382"
        @cpx_ccall_intercept(model, mipopt, Cint, (Ptr{Cvoid}, Ptr{Cvoid}), model.env.ptr, model.lp)
    else
        @cpx_ccall(mipopt, Cint, (Ptr{Cvoid}, Ptr{Cvoid}), model.env.ptr, model.lp)
    end
  elseif model.has_qc
    if VERSION < v"0.7.0-DEV.3382"
        @cpx_ccall_intercept(model, qpopt, Cint, (Ptr{Cvoid}, Ptr{Cvoid}), model.env.ptr, model.lp)
    else
        @cpx_ccall(qpopt, Cint, (Ptr{Cvoid}, Ptr{Cvoid}), model.env.ptr, model.lp)
    end
  else
    if VERSION < v"0.7.0-DEV.3382"
        @cpx_ccall_intercept(model, lpopt, Cint, (Ptr{Cvoid}, Ptr{Cvoid}), model.env.ptr, model.lp)
    else
        @cpx_ccall(lpopt, Cint, (Ptr{Cvoid}, Ptr{Cvoid}), model.env.ptr, model.lp)
    end
  end)
  if stat != 0
    throw(CplexError(model.env, stat))
  end
end

set_branching_priority(model::Model, priority) =
    set_branching_priority(model, Cint[1:num_var(model)], priority)

set_branching_priority(model::Model, indices, priority) =
    set_branching_priority(model, indices, priority, C_NULL)

set_branching_priority(model, indices, priority, direction) =
    set_branching_priority(model, convert(Vector{Cint},indices), convert(Vector{Cint},priority), direction)

function set_branching_priority(model::Model, indices::Vector{Cint}, priority::Vector{Cint}, direction)
    @assert (cnt = length(indices)) == length(priority)
    isa(direction,Vector) && @assert cnt == length(direction)
    stat = @cpx_ccall(copyorder, Cint, (
                      Ptr{Cvoid},
                      Ptr{Cvoid},
                      Cint,
                      Ptr{Cint},
                      Ptr{Cint},
                      Ptr{Cint}),
                      model.env.ptr, model.lp, cnt, indices .- Cint(1), priority, direction)
    stat == 0 || throw(CplexError(model.env, stat))
    return nothing
end


function newlongannotation(model::Model, name::String, defval::Clong)
    stat = @cpx_ccall(newlongannotation, Cint, (
                      Ptr{Cvoid},
                      Ptr{Cvoid},
                      Ptr{Cchar},
                      Clong),
                      model.env.ptr, model.lp, name, defval)
    stat == 0 || throw(CplexError(model.env, stat))

    return nothing
end

function setlongannotations(model::Model, idx::Cint, objtype::Cint, cnt::Cint, indexArr::Array{Cint},
                valArr::Array{Clong})
    stat = @cpx_ccall(setlongannotations, Cint, (
                Ptr{Cvoid},
                Ptr{Cvoid},
                Cint,
                Cint,
                Cint,
                Ptr{Cvoid},
                Ptr{Cvoid}),
                model.env.ptr, model.lp, idx, objtype, cnt, indexArr, valArr)
    stat == 0 || throw(CplexError(model.env, stat))
    return nothing
end

export setlongannotations, newlongannotation

function c_api_getobjval(model::Model)
  objval = Vector{Cdouble}(undef, 1)
  stat = @cpx_ccall(getobjval, Cint, (
                    Ptr{Cvoid},
                    Ptr{Cvoid},
                    Ptr{Cdouble}
                    ),
                    model.env.ptr, model.lp, objval)
  if stat != 0
    throw(CplexError(model.env, stat))
  end
  return objval[1]
end
get_objval(model::Model) = c_api_getobjval(model)

function c_api_solninfo(model::Model)
  solnmethod_p = Ref{Cint}()
  solntype_p = Ref{Cint}()
  pfeasind_p = Ref{Cint}()
  dfeasind_p = Ref{Cint}()
  stat = @cpx_ccall(solninfo, Cint, (
                    Ptr{Cvoid},
                    Ptr{Cvoid},
                    Ptr{Cint},
                    Ptr{Cint},
                    Ptr{Cint},
                    Ptr{Cint}
                    ),
                    model.env.ptr, model.lp, solnmethod_p, solntype_p,
                    pfeasind_p, dfeasind_p)
  if stat != 0
    throw(CplexError(model.env, stat))
  end
  return (solnmethod_p[], solntype_p[], pfeasind_p[], dfeasind_p[])
end

function c_api_getx(model::Model, x::FVec)
  nvars = num_var(model)
  stat = @cpx_ccall(getx, Cint, (
                    Ptr{Cvoid},
                    Ptr{Cvoid},
                    Ptr{Cdouble},
                    Cint,
                    Cint
                    ),
                    model.env.ptr, model.lp, x, 0, nvars-Cint(1))
  if stat != 0
    throw(CplexError(model.env, stat))
  end
end

function get_solution(model::Model)
  nvars = num_var(model)
  x = Vector{Cdouble}(undef, nvars)
  c_api_getx(model, x)
  return x
end

function c_api_getdj(model::Model, p::FVec)
    nvars = num_var(model)
    stat = @cpx_ccall(getdj, Cint, (
                      Ptr{Cvoid},
                      Ptr{Cvoid},
                      Ptr{Cdouble},
                      Cint,
                      Cint
                      ),
                      model.env.ptr, model.lp, p, 0, nvars-1)
    if stat != 0
       throw(CplexError(model.env, stat))
    end
end

function get_reduced_costs(model::Model)
    nvars = num_var(model)
    p = Vector{Cdouble}(undef, nvars)
    c_api_getdj(model, p)
    return p
end

function c_api_getpi(model::Model, p::FVec)
    ncons = num_constr(model)
    stat = @cpx_ccall(getpi, Cint, (
                      Ptr{Cvoid},
                      Ptr{Cvoid},
                      Ptr{Cdouble},
                      Cint,
                      Cint
                      ),
                      model.env.ptr, model.lp, p, 0, ncons-1)
    if stat != 0
       throw(CplexError(model.env, stat))
    end
end

function c_api_getqconstrslack(model::Model, dest::Vector{Float64})
    ncons = num_qconstr(model)
    stat = @cpx_ccall(getqconstrslack, Cint, (
                      Ptr{Cvoid},
                      Ptr{Cvoid},
                      Ptr{Cdouble},
                      Cint,
                      Cint
                      ),
                      model.env.ptr, model.lp, dest, 0, ncons-1)
    if stat != 0
       throw(CplexError(model.env, stat))
    end
end

function get_constr_duals(model::Model)
    ncons = num_constr(model)
    p = Vector{Cdouble}(undef, ncons)
    c_api_getpi(model, p)
    return p
end

function c_api_getax(model::Model, Ax::FVec)
    ncons = num_constr(model)
    stat = @cpx_ccall(getax, Cint, (
                      Ptr{Cvoid},
                      Ptr{Cvoid},
                      Ptr{Cdouble},
                      Cint,
                      Cint
                      ),
                      model.env.ptr, model.lp, Ax, 0, ncons-1)
    if stat != 0
      throw(CplexError(model.env, stat))
    end
end

function c_api_getxqxax(model::Model, dest::Vector{Float64})
    ncons = num_qconstr(model)
    stat = @cpx_ccall(getxqxax, Cint, (
                      Ptr{Cvoid},
                      Ptr{Cvoid},
                      Ptr{Cdouble},
                      Cint,
                      Cint
                      ),
                      model.env.ptr, model.lp, dest, 0, ncons-1)
    if stat != 0
      throw(CplexError(model.env, stat))
    end
end

function get_constr_solution(model::Model)
    ncons = num_constr(model)
    Ax = Vector{Cdouble}(undef, ncons)
    c_api_getax(model, Ax)
    return Ax
end

function get_infeasibility_ray(model::Model)
  ncons = num_constr(model)
  y = Vector{Cdouble}(undef, ncons)
  proof_p = Vector{Cdouble}(undef, 1)
  stat = @cpx_ccall(dualfarkas, Cint, (
                    Ptr{Cvoid},
                    Ptr{Cvoid},
                    Ptr{Cdouble},
                    Ptr{Cdouble}
                    ),
                    model.env.ptr, model.lp, y, proof_p)
  if stat != 0
    error("CPLEX is unable to grab infeasible ray; consider resolving with presolve turned off")
    throw(CplexError(model.env, stat))
  end
  return y
end

function get_unbounded_ray(model::Model)
  solve_stat = get_status(model)
  if solve_stat == :CPX_STAT_UNBOUNDED
    n = num_var(model)
    z = Vector{Cdouble}(undef, n)
    stat = @cpx_ccall(getray, Cint, (
                      Ptr{Cvoid},
                      Ptr{Cvoid},
                      Ptr{Cdouble}
                      ),
                      model.env.ptr, model.lp, z)
    if stat != 0
      throw(CplexError(model.env, stat))
    end
    return z
  else
    error("CPLEX is unable to grab unbounded ray; consider resolving with presolve turned off")
  end
end

const varmap = Dict(
    0 => :NonbasicAtLower,
    1 => :Basic,
    2 => :NonbasicAtUpper,
    3 => :Free
)

const conmap = Dict(
    0 => :NonbasicAtLower,
    1 => :Basic,
    2 => :NonbasicAtUpper
)

function get_basis(model::Model)
    cval = Vector{Cint}(undef, num_var(model))
    rval = Vector{Cint}(undef, num_constr(model))
    stat = @cpx_ccall(getbase, Cint, (Ptr{Cvoid},Ptr{Cvoid},Ptr{Cint},Ptr{Cint}),
                      model.env.ptr, model.lp, cval, rval)
    stat != 0 && throw(CplexError(model.env, stat))

    csense = get_constr_senses(model)
    cbasis = Vector{Symbol}(undef, num_var(model))
    rbasis = Vector{Symbol}(undef, num_constr(model))
    for it in 1:num_var(model)
        cbasis[it] = varmap[cval[it]]
    end
    for it in 1:num_constr(model)
        rbasis[it] = conmap[rval[it]]
        if (rbasis[it] == :NonbasicAtLower) && (csense[it] == convert(Cchar,'L'))
            rbasis[it] = :NonbasicAtUpper
        end
    end
    return cbasis, rbasis
end

get_node_count(model::Model) = @cpx_ccall(getnodecnt, Cint, (Ptr{Cvoid},Ptr{Cvoid}), model.env.ptr, model.lp)

function get_rel_gap(model::Model)
  ret = Vector{Cdouble}(undef, 1)
  stat = @cpx_ccall(getmiprelgap, Cint, (Ptr{Cvoid},Ptr{Cvoid},Ptr{Cdouble}), model.env.ptr, model.lp, ret)
  if stat != 0
    throw(CplexError(model.env, stat))
  end
  ret[1]
end


function get_num_cuts(model::Model,cuttype)
    cutcount = Vector{Cint}(undef, 1)

    stat = @cpx_ccall(getnumcuts, Cint, (Ptr{Cvoid},Ptr{Cvoid},Cint,Ptr{Cvoid}), model.env.ptr , model.lp, cuttype, cutcount)
    if stat != 0
        error(CplexError(model.inner.env, stat).msg)
    end
    return cutcount[1]
end

const status_symbols = Dict(
    1   => :CPX_STAT_OPTIMAL,
    2   => :CPX_STAT_UNBOUNDED,
    3   => :CPX_STAT_INFEASIBLE,
    4   => :CPX_STAT_INForUNBD,
    5   => :CPX_STAT_OPTIMAL_INFEAS,
    6   => :CPX_STAT_NUM_BEST,
    7   => :CPX_STAT_FEASIBLE_RELAXED,
    8   => :CPX_STAT_OPTIMAL_RELAXED,
    10  => :CPX_STAT_ABORT_IT_LIM,
    11  => :CPX_STAT_ABORT_TIME_LIM,
    12  => :CPX_STAT_ABORT_OBJ_LIM,
    13  => :CPX_STAT_ABORT_USER,
    20  => :CPX_STAT_OPTIMAL_FACE_UNBOUNDED,
    21  => :CPX_STAT_ABORT_PRIM_OBJ_LIM,
    22  => :CPX_STAT_ABORT_DUAL_OBJ_LIM,
    101 => :CPXMIP_OPTIMAL,
    102 => :CPXMIP_OPTIMAL_TOL,
    103 => :CPXMIP_INFEASIBLE,
    104 => :CPXMIP_SOL_LIM,
    105 => :CPXMIP_NODE_LIM_FEAS,
    106 => :CPXMIP_NODE_LIM_INFEAS,
    107 => :CPXMIP_TIME_LIM_FEAS,
    108 => :CPXMIP_TIME_LIM_INFEAS,
    109 => :CPXMIP_FAIL_FEAS,
    110 => :CPXMIP_FAIL_INFEAS,
    111 => :CPXMIP_MEM_LIM_FEAS,
    112 => :CPXMIP_MEM_LIM_INFEAS,
    113 => :CPXMIP_ABORT_FEAS,
    114 => :CPXMIP_ABORT_INFEAS,
    115 => :CPXMIP_OPTIMAL_INFEAS,
    116 => :CPXMIP_FAIL_FEAS_NO_TREE,
    117 => :CPXMIP_FAIL_INFEAS_NO_TREE,
    118 => :CPXMIP_UNBOUNDED,
    119 => :CPXMIP_INForUNBD,
    120 => :CPXMIP_FEASIBLE_RELAXED,
    121 => :CPXMIP_OPTIMAL_RELAXED
)

get_status(model::Model) = status_symbols[Int(get_status_code(model))]::Symbol

function c_api_getstat(model::Model)
    return @cpx_ccall(getstat, Cint, (Ptr{Cvoid}, Ptr{Cvoid}),
                      model.env.ptr, model.lp)
end
get_status_code(model::Model) = c_api_getstat(model)
