export CplexSolver

type CplexMathProgModel <: AbstractMathProgModel
  inner::Model
  lazycb
  cutcb
  heuristiccb
  branchcb
end

function CplexMathProgModel(;options...)
  env = Env()
  set_param!(env, "CPX_PARAM_MIPCBREDLP", 0) # access variables in original problem, not presolved
  set_param!(env, "CPX_PARAM_PRELINEAR", 0) # MAY NOT BE NECESSARY, only performs linear presolving so can recover original variables
  set_param!(env, "CPX_PARAM_SCRIND", 1) # output logs to stdout by default
  for (name,value) in options
    set_param!(env, string(name), value)
  end

  m = CplexMathProgModel(Model(env, "Cplex.jl"), nothing, nothing, nothing, nothing)
  return m
end

immutable CplexSolver <: AbstractMathProgSolver
  options
end
CplexSolver(;kwargs...) = CplexSolver(kwargs)
model(s::CplexSolver) = CplexMathProgModel(;s.options...)

loadproblem!(m::CplexMathProgModel, filename::String) = read_model(m.inner, filename)

function loadproblem!(m::CplexMathProgModel, A, collb, colub, obj, rowlb, rowub, sense)
  add_vars!(m.inner, float(obj), float(collb), float(colub))

  neginf = typemin(eltype(rowlb))
  posinf = typemax(eltype(rowub))

  rangeconstrs = any((rowlb .!= rowub) & (rowlb .> neginf) & (rowub .< posinf))
  if rangeconstrs
    warn("Julia Cplex interface doesn't properly support range (two-sided) constraints.")
    add_rangeconstrs!(m.inner, float(A), float(rowlb), float(rowub))
  else
    b = Array(Float64,length(rowlb))
    senses = Array(Cchar,length(rowlb))
    for i in 1:length(rowlb)
      if rowlb[i] == rowub[i]
        senses[i] = 'E'
        b[i] = rowlb[i]
      elseif rowlb[i] > neginf
        senses[i] = 'G'
        b[i] = rowlb[i]
      else
        @assert rowub[i] < posinf
        senses[i] = 'L'
        b[i] = rowub[i]
      end
    end
    add_constrs!(m.inner, float(A), senses, b)
  end

  set_sense!(m.inner, sense)
end

writeproblem(m::CplexMathProgModel, filename::String) = write_model(m.inner, filename)

getvarLB(m::CplexMathProgModel) = get_varLB(m.inner)
setvarLB!(m::CplexMathProgModel, l) = set_varLB!(m.inner, l)
getvarUB(m::CplexMathProgModel) = get_varUB(m.inner)
setvarUB!(m::CplexMathProgModel, u) = set_varUB!(m.inner, u)

# CPXchgcoef
getconstrLB(m::CplexMathProgModel) = get_constrLB(m.inner)
setconstrLB!(m::CplexMathProgModel, lb) = set_constrLB!(m.inner, lb)
getconstrUB(m::CplexMathProgModel) = get_constrUB(m.inner)
setconstrUB!(m::CplexMathProgModel, ub) = set_constrUB!(m.inner, ub)

getobj(m::CplexMathProgModel) = get_obj(m.inner)
setobj!(m::CplexMathProgModel, c) = set_obj!(m.inner, c)

addvar!(m::CplexMathProgModel, constridx, constrcoef, l, u, coeff) = add_var!(m.inner, constridx, constrcoef, l, u, coeff)

function addconstr!(m::CplexMathProgModel, varidx, coef, lb, ub) 
  neginf = typemin(eltype(lb))
  posinf = typemax(eltype(ub))

  rangeconstrs = any((lb .!= ub) & (lb .> neginf) & (ub .< posinf))
  if rangeconstrs
    warn("Julia Cplex interface doesn't properly support range (two-sided) constraints.")
    add_rangeconstrs!(m.inner, [0], varidx, float(coef), float(lb), float(ub))
  else
    if lb == ub
      rel = 'E'
      rhs = lb
    elseif lb > neginf
      rel = 'G'
      rhs = lb
    else
      @assert ub < posinf
      rel = 'L'
      rhs = ub
    end
    add_constrs!(m.inner, ivec([1]), ivec(varidx), fvec(coef), Cchar[rel...], fvec([rhs...]))
  end
end

getconstrmatrix(m::CplexMathProgModel) = get_constr_matrix(m.inner)

updatemodel!(m::CplexMathProgModel) = Base.warn_once("Model update not necessary for Cplex.")

setsense!(m::CplexMathProgModel, sense) = set_sense!(m.inner, sense)

getsense(m::CplexMathProgModel) = get_sense(m.inner)

numvar(m::CplexMathProgModel) = num_var(m.inner)
numconstr(m::CplexMathProgModel) = num_constr(m.inner)

# optimize!(m::CplexMathProgModel) = optimize!(m.inner)

function optimize!(m::CplexMathProgModel)
    # set callbacks if present
    if m.lazycb != nothing
      setmathproglazycallback!(m)
    end
    if m.cutcb != nothing
      setmathprogcutcallback!(m)
    end
    if m.heuristiccb != nothing
      setmathprogheuristiccallback!(m)
    end
    optimize!(m.inner)
end

function status(m::CplexMathProgModel)
  ret = get_status(m.inner)
  if ret in [:CPX_STAT_OPTIMAL, :CPXMIP_OPTIMAL, :CPXMIP_OPTIMAL_TOL]
    stat = :Optimal
  elseif ret in [:CPX_STAT_UNBOUNDED, :CPXMIP_UNBOUNDED]
    stat = :Unbounded
  elseif ret in [:CPX_STAT_INFEASIBLE, :CPXMIP_INFEASIBLE]
    stat = :Infeasible
  elseif ret in [:CPX_STAT_INForUNBD, :CPXMIP_INForUNBD]
    # this is an ugly hack that should be fixed at some point
    stat = :Unbounded
  else
    stat = ret
  end
  return stat
end

getobjval(m::CplexMathProgModel)   = get_objval(m.inner)
getobjbound(m::CplexMathProgModel) = get_best_bound(m.inner)
getsolution(m::CplexMathProgModel) = get_solution(m.inner)
getconstrsolution(m::CplexMathProgModel) = get_constr_solution(m.inner)
getreducedcosts(m::CplexMathProgModel) = get_reduced_costs(m.inner)
getconstrduals(m::CplexMathProgModel) = get_constr_duals(m.inner)
getrawsolver(m::CplexMathProgModel) = m.inner

setvartype!(m::CplexMathProgModel, v::Vector{Char}) = set_vartype!(m.inner, v)
getvartype(m::CplexMathProgModel) = get_vartype(m.inner)

getinfeasibilityray(m::CplexMathProgModel) = get_infeasibility_ray(m.inner)
getunboundedray(m::CplexMathProgModel) = get_unbounded_ray(m.inner)

setwarmstart!(m::CplexMathProgModel, v) = set_warm_start!(m.inner, v) 

addsos1!(m::CplexMathProgModel, idx, weight) = add_sos!(m.inner, :SOS1, idx, weight)
addsos2!(m::CplexMathProgModel, idx, weight) = add_sos!(m.inner, :SOS2, idx, weight)

######
# QCQP
######
addquadconstr!(m::CplexMathProgModel, linearidx, linearval, quadrowidx, quadcolidx, quadval, sense, rhs) = add_qconstr!(m.inner,linearidx,linearval,quadrowidx,quadcolidx,quadval,sense,rhs)
setquadobj!(m::CplexMathProgModel,rowidx,colidx,quadval) = add_qpterms!(m.inner,rowidx,colidx,quadval)

###########
# Callbacks
###########
type CplexCallbackData <: MathProgCallbackData
    cbdata::CallbackData
    state::Symbol
    where::Cint
    sol::Ptr{Float64}
    userinteraction_p::Ptr{Cint}
end

# set to nothing to clear callback
setlazycallback!(m::CplexMathProgModel,f) = (m.lazycb = f)
setcutcallback!(m::CplexMathProgModel,f) = (m.cutcb = f)
setheuristiccallback!(m::CplexMathProgModel,f) = (m.heuristiccb = f)

function cbgetmipsolution(d::CplexCallbackData)
    @assert d.state == :MIPSol
    return cbget_mipsol_sol(d.cbdata, d.where)
end

function cbgetmipsolution(d::CplexCallbackData, output)
    @assert d.state == :MIPSol
    return cbget_mipsol_sol(d.cbdata, d.where, output)
end

function cbgetlpsolution(d::CplexCallbackData)
    @assert d.state == :MIPNode
    return cbget_mipnode_rel(d.cbdata, d.where)
end

function cbgetobj(d::CplexCallbackData)
    if d.state == :MIPNode
        return cbget_mipnode_objbst(d.cbdata, d.where)
    elseif d.state == :MIPSol
        return cbdet_mipsol_objbst(d.cbdata, d.where)
    else
        error("Unrecognized callback state $(d.state)")
    end
end

function cbgetbestbound(d::CplexCallbackData)
    if d.state == :MIPNode
        return cbget_mipnode_objbnd(d.cbdata, d.where)
    elseif d.state == :MIPSol
        return cbdet_mipsol_objbnd(d.cbdata, d.where)
    else
        error("Unrecognized callback state $(d.state)")
    end
end

cbgetexplorednodes(d::CplexCallbackData) = cbget_nodcnt(d.cbdata, d.where)
        
# returns :MIPNode :MIPSol :Other
cbgetstate(d::CplexCallbackData) = d.state

const sensemap = ['=' => 'E', '<' => 'L', '>' => 'G']
function cbaddcut!(d::CplexCallbackData,varidx,varcoef,sense,rhs)
    @assert d.state == :MIPNode
    cbcut(d.cbdata, convert(Vector{Cint}, varidx), float(varcoef), sensemap[sense], float(rhs))
    unsafe_store!(d.userinteraction_p, convert(Cint,CPX_CALLBACK_SET), 1)
end

function cbaddlazy!(d::CplexCallbackData,varidx,varcoef,sense,rhs)
    @assert d.state == :MIPNode || d.state == :MIPSol
    cblazy(d.cbdata, d.where, convert(Vector{Cint}, varidx), float(varcoef), sensemap[sense], float(rhs))
end

cbaddsolution!(d::CplexCallbackData) = (unsafe_store!(d.userinteraction_p, convert(Cint,CPX_CALLBACK_SET), 1))

function cbsetsolutionvalue!(d::CplexCallbackData,varidx,value) 
    @assert 1 <= varidx <= num_var(d.cbdata.model)
    unsafe_store!(d.sol, value, varidx)
end
    

# breaking abstraction, define our low-level callback to eliminate
# a level of indirection
function mastercallback(env::Ptr{Void}, cbdata::Ptr{Void}, wherefrom::Cint, userdata::Ptr{Void}, userinteraction_p::Ptr{Cint})
    model = unsafe_pointer_to_objref(userdata)::CplexMathProgModel
    cpxrawcb = CallbackData(cbdata, model.inner)
    if wherefrom == CPX_CALLBACK_MIP_CUT_FEAS || wherefrom == CPX_CALLBACK_MIP_CUT_UNBD
        state = :MIPSol
        cpxcb = CplexCallbackData(cpxrawcb, state, wherefrom, [0.], userinteraction_p)
        if model.lazycb != nothing
            stat = model.lazycb(cpxcb)
            if stat == :Exit
                return convert(Cint, 1006)
            end
        end
    elseif wherefrom == CPX_CALLBACK_MIP_NODE
        state = :MIPNode
        cpxcb = CplexCallbackData(cpxrawcb, state, wherefrom, [0.], userinteraction_p)
        if model.cutcb != nothing
            stat = model.cutcb(cpxcb)
            if stat == :Exit
                return convert(Cint, 1006)
            end
        end
    end
    return convert(Cint, 0)
end

function masterheuristiccallback(env::Ptr{Void}, 
                                 cbdata::Ptr{Void}, 
                                 wherefrom::Cint, 
                                 userdata::Ptr{Void}, 
                                 objval_p::Ptr{Cdouble}, 
                                 xx::Ptr{Cdouble}, 
                                 checkfeas_p::Ptr{Cint},
                                 userinteraction_p::Ptr{Cint})
    model = unsafe_pointer_to_objref(userdata)::CplexMathProgModel
    cpxrawcb = CallbackData(cbdata, model.inner)
    if wherefrom == CPX_CALLBACK_MIP_HEURISTIC
        state = :MIPNode
        cpxcb = CplexCallbackData(cpxrawcb, state, wherefrom, xx, userinteraction_p)
        if model.heuristiccb != nothing
            stat = model.heuristiccb(cpxcb)
            if stat == :Exit
                return convert(Cint, 1006)
            end
        end
    end
    unsafe_store!(checkfeas_p, convert(Cint,CPX_OFF), 1)
    return convert(Cint, 0)
end

# User callback function should be of the form:
# callback(cbdata::MathProgCallbackData)
# return :Exit to indicate an error

function setmathproglazycallback!(model::CplexMathProgModel)
    cpxcallback = cfunction(mastercallback, Cint, (Ptr{Void}, Ptr{Void}, Cint, Ptr{Void}, Ptr{Cint}))
    stat = @cpx_ccall(setlazyconstraintcallbackfunc, Cint, (
                      Ptr{Void}, 
                      Ptr{Void},
                      Any,
                      ), 
                      model.inner.env, cpxcallback, model)
    if stat != 0
        throw(CplexError(model.env, stat))
    end
    nothing
end

function setmathprogcutcallback!(model::CplexMathProgModel)
    cpxcallback = cfunction(mastercallback, Cint, (Ptr{Void}, Ptr{Void}, Cint, Ptr{Void}, Ptr{Cint}))
    stat = @cpx_ccall(setusercutcallbackfunc, Cint, (
                      Ptr{Void}, 
                      Ptr{Void},
                      Any,
                      ), 
                      model.inner.env, cpxcallback, model)
    if stat != 0
        throw(CplexError(model.env, stat))
    end
    nothing
end

function setmathprogheuristiccallback!(model::CplexMathProgModel)
    cpxcallback = cfunction(masterheuristiccallback, Cint, (Ptr{Void}, Ptr{Void}, Cint, Ptr{Void}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cint}, Ptr{Cint}))
    stat = @cpx_ccall(setheuristiccallbackfunc, Cint, (
                      Ptr{Void}, 
                      Ptr{Void},
                      Any,
                      ), 
                      model.inner.env, cpxcallback, model)
    if stat != 0
        throw(CplexError(model.env, stat))
    end
    nothing
end

# function masterbranchcallback(env::Ptr{Void},
#                               userdata::Ptr{Void},
#                               wherefrom::Cint,
#                               cbhandle::Ptr{Void},
#                               typ::Cint,
#                               sos::Cint,
#                               nodecnt::Cint,
#                               bdcnt::Cint,
#                               nodebeg::Ptr{Cint},
#                               indices::Ptr{Cint},
#                               lu::Ptr{Cchar},
#                               bd::Ptr{Cdouble},
#                               nodeest::Ptr{Cdouble},
#                               useraction_p::Ptr{Cint});
#     model = unsafe_pointer_to_objref(userdata)::CplexMathProgModel
#     cpxrawcb = CallbackData(cbdata, model.inner)
#     if wherefrom == CPX_CALLBACK_MIP_BRANCH
#         state = :MIPBranch
#         cpxcb = CplexCallbackData(cpxrawcb, state, wherefrom, [0.])
#         if model.branchcb != nothing
#             stat = model.branchcb(cpxcb)
#             if stat == :Exit
#                 return convert(Cint, 1006)
#             end
#         end
#     end
#     return convert(Cint, 0)
# end

# funtion setbranchcallbackmodel(model::CplexMathProgModel)
#     cpxcallback = cfunction(masterbranchcallback, Cint, (Ptr{Void}, Ptr{Void}, Cint, Ptr{Void}, Cint, Cint, Cint, Cint, Ptr{Cint}, Ptr{Cint}, Ptr{Cchar}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cint}))
#     stat = @cpx_ccall(sethbranchcallbackfunc, Cint, (
#                       Ptr{Void}, 
#                       Ptr{Void},
#                       Any,
#                       ), 
#                       model.env, cpxcallback, model)
#     if stat != 0
#         throw(CplexError(model.env, stat))
#     end
#     nothing
# end
