export CplexSolver

type CplexMathProgModel <: AbstractLinearQuadraticModel
    inner::Model
    lazycb
    cutcb
    heuristiccb
    branchcb
    incumbentcb
    infocb
    solvetime::Float64
    mipstart_effortlevel::Cint
end

function CplexMathProgModel(;mipstart_effortlevel::Cint = CPX_MIPSTART_AUTO, options...)
    env = Env()
    # set_param!(env, "CPX_PARAM_MIPCBREDLP", 0) # access variables in original problem, not presolved
    # set_param!(env, "CPX_PARAM_PRELINEAR", 0) # MAY NOT BE NECESSARY, only performs linear presolving so can recover original variables
    set_param!(env, "CPX_PARAM_SCRIND", 1) # output logs to stdout by default
    for (name,value) in options
        set_param!(env, string(name), value)
    end

    m = CplexMathProgModel(Model(env), nothing, nothing, nothing, nothing, nothing, nothing, NaN, mipstart_effortlevel)
    return m
end

type CplexSolver <: AbstractMathProgSolver
    options
end
CplexSolver(;kwargs...) = CplexSolver(kwargs)
LinearQuadraticModel(s::CplexSolver) = CplexMathProgModel(;s.options...)

ConicModel(s::CplexSolver) = LPQPtoConicBridge(LinearQuadraticModel(s))
supportedcones(::CplexSolver) = [:Free,:Zero,:NonNeg,:NonPos,:SOC]

function setparameters!(s::CplexSolver; mpboptions...)
    opts = collect(Any,s.options)
    for (optname, optval) in mpboptions
        if optname == :TimeLimit
            push!(opts, (:CPX_PARAM_TILIM, optval))
        elseif optname == :Silent
            if optval == true
                push!(opts, (:CPX_PARAM_SCRIND, 0))
            end
        else
            error("Unrecognized parameter $optname")
        end
    end
    s.options = opts
    return
end

function setparameters!(s::CplexMathProgModel; mpboptions...)
    for (optname, optval) in mpboptions
        if optname == :TimeLimit
            setparam!(m.inner, "CPX_PARAM_TILIM", optval)
        elseif optname == :Silent
            if optval == true
                setparam!(m.inner,"CPX_PARAM_SCRIND",0)
            end
        else
            error("Unrecognized parameter $optname")
        end
    end
end

function loadproblem!(m::CplexMathProgModel, filename::String)
   read_model(m.inner, filename)
   prob_type = get_prob_type(m.inner)
   if prob_type in [:MILP,:MIQP, :MIQCP]
      m.inner.has_int = true
   end
   if prob_type in [:QP, :MIQP, :QCP, :MIQCP]
      m.inner.has_qc = true
   end
end

function loadproblem!(m::CplexMathProgModel, A, collb, colub, obj, rowlb, rowub, sense)
  # throw away old model but keep env
  m.inner = Model(m.inner.env)
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

addvar!(m::CplexMathProgModel, l, u, coeff) = add_var!(m.inner, [], [], l, u, coeff)
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
    add_constrs!(m.inner, ivec([1]), ivec(varidx), fvec(coef), convert(Vector{Cchar},[rel]), fvec(vec(collect(rhs))))
  end
end

getconstrmatrix(m::CplexMathProgModel) = get_constr_matrix(m.inner)

setsense!(m::CplexMathProgModel, sense) = set_sense!(m.inner, sense)

getsense(m::CplexMathProgModel) = get_sense(m.inner)

numvar(m::CplexMathProgModel) = num_var(m.inner)
numconstr(m::CplexMathProgModel) = num_constr(m.inner) + num_qconstr(m.inner)
numlinconstr(m::CplexMathProgModel) = num_constr(m.inner)
numquadconstr(m::CplexMathProgModel) = num_qconstr(m.inner)

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
    if m.branchcb != nothing
        setmathprogbranchcallback!(m)
    end
    if m.incumbentcb != nothing
        setmathprogincumbentcallback!(m)
    end
    if m.infocb != nothing
        setmathproginfocallback!(m)
    end
    start = time()
    optimize!(m.inner)
    m.solvetime = time() - start
end

function status(m::CplexMathProgModel)
    ret = get_status(m.inner)
    return (if ret in [:CPX_STAT_OPTIMAL, :CPXMIP_OPTIMAL, :CPXMIP_OPTIMAL_TOL]
        :Optimal
    elseif ret in [:CPX_STAT_UNBOUNDED, :CPXMIP_UNBOUNDED]
        :Unbounded
    elseif ret in [:CPX_STAT_INFEASIBLE, :CPXMIP_INFEASIBLE]
        :Infeasible
    elseif ret in [:CPX_STAT_INForUNBD, :CPXMIP_INForUNBD]
        Base.warn_once("CPLEX reported infeasible or unbounded. Set CPX_PARAM_REDUCE=1 to check
                        infeasibility or CPX_PARAM_REDUCE=2 to check unboundedness.")
        :InfeasibleOrUnbounded
    elseif contains(string(ret), "TIME_LIM") || contains(string(ret), "MIP_ABORT")
        :UserLimit
    else
        ret
    end)
end

getobjval(m::CplexMathProgModel)   = get_objval(m.inner)
getobjbound(m::CplexMathProgModel) = get_best_bound(m.inner)
getsolution(m::CplexMathProgModel) = get_solution(m.inner)
getconstrsolution(m::CplexMathProgModel) = get_constr_solution(m.inner)
getreducedcosts(m::CplexMathProgModel) = get_reduced_costs(m.inner)
getconstrduals(m::CplexMathProgModel) = get_constr_duals(m.inner)
getrawsolver(m::CplexMathProgModel) = m.inner
getnodecount(m::CplexMathProgModel) = get_node_count(m.inner)

const var_type_map = Dict(
    'C' => :Cont,
    'B' => :Bin,
    'I' => :Int,
    'S' => :SemiCont,
    'N' => :SemiInt
)

const rev_var_type_map = Dict(
    :Cont     => 'C',
    :Bin      => 'B',
    :Int      => 'I',
    :SemiCont => 'S',
    :SemiInt  => 'N'
)

function setvartype!(m::CplexMathProgModel, v::Vector{Symbol})
    target_int = all(x->isequal(x,:Cont), v)
    prob_type = get_prob_type(m.inner)
    if target_int
        if m.inner.has_sos # if it has sos we need to keep has_int==true and the MI(prob_type) version.
            set_vartype!(m.inner, map(x->rev_var_type_map[x], v))    
        else
            m.inner.has_int = false
            if !(prob_type in [:LP,:QP,:QCP])
                toggleproblemtype!(m)
            end
        end
    else
        if prob_type in [:LP,:QP,:QCP]
            toggleproblemtype!(m)
        end
        set_vartype!(m.inner, map(x->rev_var_type_map[x], v))
    end
    return nothing
end

const prob_type_toggle_map = Dict(
    :LP    => :MILP,
    :MILP  => :LP,
    :QP    => :MIQP,
    :MIQP  => :QP,
    :QCP   => :MIQCP,
    :MIQCP => :QCP
)

function toggleproblemtype!(m::CplexMathProgModel)
    prob_type = get_prob_type(m.inner)
    set_prob_type!(m.inner, prob_type_toggle_map[prob_type])
end

function getvartype(m::CplexMathProgModel)
    if m.inner.has_int
        return map(x->var_type_map[x], get_vartype(m.inner))
    else
        return fill(:Cont, num_var(m.inner))
    end
end

function getsolvetime(m::CplexMathProgModel)
    return m.solvetime
end

getinfeasibilityray(m::CplexMathProgModel) = get_infeasibility_ray(m.inner)
getunboundedray(m::CplexMathProgModel) = get_unbounded_ray(m.inner)

getbasis(m::CplexMathProgModel) = get_basis(m.inner)

function setwarmstart!(m::CplexMathProgModel, v)
    # This means that warm starts are ignored if you haven't called setvartype! first
    if m.inner.has_int
        set_warm_start!(m.inner, v, m.mipstart_effortlevel)
    end
end

addsos1!(m::CplexMathProgModel, idx, weight) = add_sos!(m.inner, :SOS1, idx, weight)
addsos2!(m::CplexMathProgModel, idx, weight) = add_sos!(m.inner, :SOS2, idx, weight)

######
# QCQP
######
addquadconstr!(m::CplexMathProgModel, linearidx, linearval, quadrowidx, quadcolidx, quadval, sense, rhs) =
    add_qconstr!(m.inner,linearidx,linearval,quadrowidx,quadcolidx,quadval,sense,rhs)
setquadobj!(m::CplexMathProgModel,rowidx,colidx,quadval) = add_qpterms!(m.inner,rowidx,colidx,quadval)

######
# Data
######
function getdettime(m::CplexMathProgModel)
    tim = Array(Cdouble,1)
    stat = @cpx_ccall(getdettime, Cint, (Ptr{Void},Ptr{Cdouble}), m.inner.env.ptr, tim)
    if stat != 0
        error(CplexError(m.inner.env, stat).msg)
    end
    return tim[1]
end

getobjgap(m::CplexMathProgModel) = get_rel_gap(m.inner)

###########
# Callbacks
###########
export cbaddboundbranchup!,
       cbaddboundbranchdown!,
       setmathprogbranchcallback!,
       cbgetnodelb,
       cbgetnodeub,
       cbgetnodeobjval,
       cbgetnodesleft,
       cbgetmipiterations,
       cbgetfeasibility,
       cbgetgap,
       cbgetstarttime,
       cbgetdetstarttime,
       cbgettimestamp,
       cbgetdettimestamp,
       cbgetintfeas

abstract CplexCallbackData <: MathProgCallbackData

# set to nothing to clear callback
setlazycallback!(m::CplexMathProgModel,f) = (m.lazycb = f)
setcutcallback!(m::CplexMathProgModel,f) = (m.cutcb = f)
setheuristiccallback!(m::CplexMathProgModel,f) = (m.heuristiccb = f)
setbranchcallback!(m::CplexMathProgModel,f) = (m.branchcb = f)
setincumbentcallback!(m::CplexMathProgModel,f) = (m.incumbentcb = f)
setinfocallback!(m::CplexMathProgModel,f) = (m.infocb = f)

function cbgetmipsolution(d::CplexCallbackData)
    @assert d.state == :MIPSol || d.state == :MIPIncumbent
    n = num_var(d.cbdata.model)
    sol = Array(Cdouble, n)
    stat = @cpx_ccall(getcallbacknodex, Cint, (Ptr{Void},Ptr{Void},Cint,Ptr{Cdouble},Cint,Cint),
                      d.cbdata.model.env.ptr, d.cbdata.cbdata, d.where, sol, 0, n-1)
    if stat != 0
        error(CplexError(d.cbdata.model.env, stat).msg)
    end
    return sol
end

function cbgetmipsolution(d::CplexCallbackData, sol::Vector{Cdouble})
    @assert d.state == :MIPSol
    stat = @cpx_ccall(getcallbacknodex, Cint, (Ptr{Void},Ptr{Void},Cint,Ptr{Cdouble},Cint,Cint),
                      d.cbdata.model.env.ptr, d.cbdata.cbdata, d.where, sol, 0, length(sol)-1)
    if stat != 0
        error(CplexError(d.cbdata.model.env, stat).msg)
    end
    return nothing
end

function cbgetlpsolution(d::CplexCallbackData)
    @assert d.state == :MIPNode || d.state == :MIPBranch
    n = num_var(d.cbdata.model)
    sol = Array(Cdouble, n)
    stat = @cpx_ccall(getcallbacknodex, Cint, (Ptr{Void},Ptr{Void},Cint,Ptr{Cdouble},Cint,Cint),
                      d.cbdata.model.env.ptr, d.cbdata.cbdata, d.where, sol, 0, n-1)
    if stat != 0
        error(CplexError(d.cbdata.model.env, stat).msg)
    end
    return sol
end

function cbgetlpsolution(d::CplexCallbackData, sol::Vector{Cdouble})
    @assert d.state == :MIPNode || d.state == :MIPIncumbent || d.state == :MIPBranch
    stat = @cpx_ccall(getcallbacknodex, Cint, (Ptr{Void},Ptr{Void},Cint,Ptr{Cdouble},Cint,Cint),
                      d.cbdata.model.env.ptr, d.cbdata.cbdata, d.where, sol, 0, length(sol)-1)
    if stat != 0
        error(CplexError(d.cbdata.model.env, stat).msg)
    end
    return nothing
end

for (func,param,typ) in ((:cbgetexplorednodes,CPX_CALLBACK_INFO_NODE_COUNT_LONG,:Int64),
                         (:cbgetnodesleft,CPX_CALLBACK_INFO_NODES_LEFT_LONG,:Int64),
                         (:cbgetmipiterations,CPX_CALLBACK_INFO_MIP_ITERATIONS_LONG,:Int64),
                         (:cbgetbestbound,CPX_CALLBACK_INFO_BEST_REMAINING,:Cdouble),
                         (:cbgetobj,CPX_CALLBACK_INFO_BEST_INTEGER,:Cdouble),
                         (:cbgetgap,CPX_CALLBACK_INFO_MIP_REL_GAP,:Cdouble),
                         (:cbgetfeasibility,CPX_CALLBACK_INFO_MIP_FEAS,:Cint),
                         (:cbgetstarttime,CPX_CALLBACK_INFO_STARTTIME,:Cdouble),
                         (:cbgetdetstarttime,CPX_CALLBACK_INFO_STARTDETTIME,:Cdouble),
                         (:cbgettimestamp,CPX_CALLBACK_INFO_ENDTIME,:Cdouble),
                         (:cbgetdettimestamp,CPX_CALLBACK_INFO_ENDDETTIME,:Cdouble))
    @eval begin
        function $(func)(d::CplexCallbackData)
            val = Array($(typ),1)
            ret = @cpx_ccall(getcallbackinfo, Cint, (Ptr{Void},Ptr{Void},Cint,Cint,Ptr{Void}),
                              d.cbdata.model.env.ptr, d.cbdata.cbdata, d.where, $(convert(Cint,param)), val)
            if ret != 0
                error(CplexError(d.cbdata.model.env, stat).msg)
            end
            return val[1]
        end
    end
end

# returns :MIPNode :MIPSol :Intermediate
cbgetstate(d::CplexCallbackData) = d.state

#const sensemap = Dict('=' => 'E', '<' => 'L', '>' => 'G')
function cbaddcut!(d::CplexCallbackData,varidx,varcoef,sense,rhs)
    @assert d.state == :MIPNode
    cbcut(d.cbdata, d.where, convert(Vector{Cint}, varidx), float(varcoef), sensemap[sense], float(rhs))
    unsafe_store!(d.userinteraction_p, convert(Cint,CPX_CALLBACK_ABORT_CUT_LOOP), 1)
end

function cbaddcutlocal!(d::CplexCallbackData,varidx,varcoef,sense,rhs)
    @assert d.state == :MIPNode
    cbcutlocal(d.cbdata, d.where, convert(Vector{Cint}, varidx), float(varcoef), sensemap[sense], float(rhs))
    unsafe_store!(d.userinteraction_p, convert(Cint,CPX_CALLBACK_ABORT_CUT_LOOP), 1)
end


function cbaddlazy!(d::CplexCallbackData,varidx,varcoef,sense,rhs)
    @assert d.state == :MIPNode || d.state == :MIPSol
    cblazy(d.cbdata, d.where, convert(Vector{Cint}, varidx), float(varcoef), sensemap[sense], float(rhs))
end

function cbaddlazylocal!(d::CplexCallbackData,varidx,varcoef,sense,rhs)
    @assert d.state == :MIPNode || d.state == :MIPSol
    cblazylocal(d.cbdata, d.where, convert(Vector{Cint}, varidx), float(varcoef), sensemap[sense], float(rhs))
end


function cbaddsolution!(d::CplexCallbackData)
    val = unsafe_wrap(Array, d.userinteraction_p, 1)
    if val[1] == CPX_CALLBACK_SET
        error("CPLEX only allows one heuristic solution for each call to the callback")
    end
    unsafe_store!(d.userinteraction_p, convert(Cint,CPX_CALLBACK_SET), 1)
end

function cbsetsolutionvalue!(d::CplexCallbackData,varidx,value)
    @assert 1 <= varidx <= num_var(d.cbdata.model)
    d.heur_x[varidx] = value
end

function cbaddboundbranchup!(d::CplexCallbackData,idx,bd,nodeest)
    seqnum = cbbranch(d.cbdata, d.where,convert(Cint,idx-1),convert(Cchar,'L'),bd,nodeest)
    unsafe_store!(d.userinteraction_p, convert(Cint,CPX_CALLBACK_SET), 1)
    seqnum
end

function cbaddboundbranchdown!(d::CplexCallbackData,idx,bd,nodeest)
    seqnum = cbbranch(d.cbdata, d.where,convert(Cint,idx-1),convert(Cchar,'U'),bd,nodeest)
    unsafe_store!(d.userinteraction_p, convert(Cint,CPX_CALLBACK_SET), 1)
    seqnum
end

function cbaddconstrbranch!(d::CplexCallbackData, indices, coeffs, rhs, sense, nodeest)
    seqnum = cbbranchconstr(d.cbdata,
                   d.where,
                   Cint[idx-1 for idx in indices],
                   Cdouble[c for c in coeffs],
                   convert(Cdouble, rhs),
                   convert(Cchar, sense),
                   nodeest)
    unsafe_store!(d.userinteraction_p, convert(Cint,CPX_CALLBACK_SET), 1)
    seqnum
end

function cbprocessincumbent!(d::CplexCallbackData,accept::Bool)
    if accept
        unsafe_store!(d.isfeas_p, convert(Cint, 1), 1)
    else
        unsafe_store!(d.isfeas_p, convert(Cint, 0), 1)
    end
    nothing
end

type CplexLazyCallbackData <: CplexCallbackData
    cbdata::CallbackData
    state::Symbol
    where::Cint
    userinteraction_p::Ptr{Cint}
end

type CplexCutCallbackData <: CplexCallbackData
    cbdata::CallbackData
    state::Symbol
    where::Cint
    userinteraction_p::Ptr{Cint}
end

terminate(model::CplexMathProgModel) = terminate(model.inner)

# breaking abstraction, define our low-level callback to eliminate
# a level of indirection
function mastercallback(env::Ptr{Void}, cbdata::Ptr{Void}, wherefrom::Cint, userdata::Ptr{Void}, userinteraction_p::Ptr{Cint})
    model = unsafe_pointer_to_objref(userdata)::CplexMathProgModel
    cpxrawcb = CallbackData(cbdata, model.inner)
    if wherefrom == CPX_CALLBACK_MIP_CUT_FEAS || wherefrom == CPX_CALLBACK_MIP_CUT_UNBD
        state = :MIPSol
    # elseif wherefrom == CPX_CALLBACK_MIP_CUT_LOOP || wherefrom == CPX_CALLBACK_MIP_CUT_LAST
    elseif wherefrom == CPX_CALLBACK_MIP_CUT_LAST
        state = :MIPNode
    else
        state = :Intermediate
    end

    if model.infocb != nothing
        cpxcb = CplexInfoCallbackData(cpxrawcb, state, wherefrom)
        stat = model.infocb(cpxcb)
        if stat == :Exit
            terminate(model.inner)
        end
    end
    if model.lazycb != nothing && state == :MIPSol
        cpxcb = CplexLazyCallbackData(cpxrawcb, state, wherefrom, userinteraction_p)
        stat = model.lazycb(cpxcb)
        if stat == :Exit
            terminate(model.inner)
        end
    end
    if model.cutcb != nothing && state == :MIPNode
        cpxcb = CplexCutCallbackData(cpxrawcb, state, wherefrom, userinteraction_p)
        stat = model.cutcb(cpxcb)
        if stat == :Exit
            terminate(model.inner)
        end
    end
    return convert(Cint, 0)
end

type CplexHeuristicCallbackData <: CplexCallbackData
    cbdata::CallbackData
    state::Symbol
    where::Cint
    sol::Vector{Float64}
    heur_x::Vector{Float64}
    isfeas_p::Ptr{Cint}
    userinteraction_p::Ptr{Cint}
end

function masterheuristiccallback(env::Ptr{Void},
                                 cbdata::Ptr{Void},
                                 wherefrom::Cint,
                                 userdata::Ptr{Void},
                                 objval_p::Ptr{Cdouble},
                                 xx::Ptr{Cdouble},
                                 isfeas_p::Ptr{Cint},
                                 userinteraction_p::Ptr{Cint})
    model = unsafe_pointer_to_objref(userdata)::CplexMathProgModel
    cpxrawcb = CallbackData(cbdata, model.inner)
    if wherefrom == CPX_CALLBACK_MIP_HEURISTIC
        state = :MIPNode
    else
        state = :Intermediate
    end

    if model.infocb != nothing
        cpxcb = CplexInfoCallbackData(cpxrawcb, state, wherefrom)
        stat = model.infocb(cpxcb)
        if stat == :Exit
            terminate(model.inner)
        end
    end
    if model.heuristiccb != nothing && state == :MIPNode
        sol = unsafe_wrap(Array, xx, numvar(model))
        cpxcb = CplexHeuristicCallbackData(cpxrawcb, state, wherefrom, sol, fill(NaN, numvar(model)), isfeas_p, userinteraction_p)
        stat = model.heuristiccb(cpxcb)
        if stat == :Exit
            terminate(model.inner)
        end
        if any(x->!isnan(x), cpxcb.heur_x) # we filled in some solution values
            unsafe_store!(objval_p, dot(get_obj(model.inner), cpxcb.heur_x), 1)
            for i in 1:numvar(model)
                unsafe_store!(xx, cpxcb.heur_x[i], i)
            end
            if any(x->isnan(x), cpxcb.heur_x) # we have a partial solution
                unsafe_store!(isfeas_p, convert(Cint,CPX_ON),  1)
            else
                unsafe_store!(isfeas_p, convert(Cint,CPX_OFF), 1)
            end
        end
    end
    return convert(Cint, 0)
end

function setmathproglazycallback!(model::CplexMathProgModel)
    set_param!(model.inner.env, "CPX_PARAM_MIPCBREDLP", 0)
    set_param!(model.inner.env, "CPX_PARAM_PRELINEAR", 0)
    set_param!(model.inner.env, "CPX_PARAM_REDUCE", CPX_PREREDUCE_PRIMALONLY)
    cpxcallback = cfunction(mastercallback, Cint, (Ptr{Void}, Ptr{Void}, Cint, Ptr{Void}, Ptr{Cint}))
    stat = @cpx_ccall(setlazyconstraintcallbackfunc, Cint, (
                      Ptr{Void},
                      Ptr{Void},
                      Any,
                      ),
                      model.inner.env.ptr, cpxcallback, model)
    if stat != 0
        throw(CplexError(model.env, stat))
    end
    nothing
end

function setmathprogcutcallback!(model::CplexMathProgModel)
    set_param!(model.inner.env, "CPX_PARAM_MIPCBREDLP", 0)
    set_param!(model.inner.env, "CPX_PARAM_PRELINEAR", 0)
    cpxcallback = cfunction(mastercallback, Cint, (Ptr{Void}, Ptr{Void}, Cint, Ptr{Void}, Ptr{Cint}))
    stat = @cpx_ccall(setusercutcallbackfunc, Cint, (
                      Ptr{Void},
                      Ptr{Void},
                      Any,
                      ),
                      model.inner.env.ptr, cpxcallback, model)
    if stat != 0
        throw(CplexError(model.env, stat))
    end
    nothing
end

function setmathprogheuristiccallback!(model::CplexMathProgModel)
    set_param!(model.inner.env, "CPX_PARAM_MIPCBREDLP", 0)
    set_param!(model.inner.env, "CPX_PARAM_PRELINEAR", 0)
    cpxcallback = cfunction(masterheuristiccallback, Cint, (Ptr{Void}, Ptr{Void}, Cint, Ptr{Void}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cint}, Ptr{Cint}))
    stat = @cpx_ccall(setheuristiccallbackfunc, Cint, (
                      Ptr{Void},
                      Ptr{Void},
                      Any,
                      ),
                      model.inner.env.ptr, cpxcallback, model)
    if stat != 0
        throw(CplexError(model.env, stat))
    end
    nothing
end

immutable BranchingChoice
    indices::Vector{Cint}
    bounds::Vector{Cdouble}
    lu::Vector{Cchar}
end
export BranchingChoice

type CplexBranchCallbackData <: CplexCallbackData
    cbdata::CallbackData
    state::Symbol
    where::Cint
    userinteraction_p::Ptr{Cint}
    nodes::Vector{BranchingChoice}
end

function masterbranchcallback(env::Ptr{Void},
                              cbdata::Ptr{Void},
                              wherefrom::Cint,
                              userdata::Ptr{Void},
                              typ::Cint,
                              sos::Cint,
                              nodecnt::Cint,
                              bdcnt::Cint,
                              nodebeg::Ptr{Cint},
                              indices::Ptr{Cint},
                              lu::Ptr{Cchar},
                              bd::Ptr{Cdouble},
                              nodeest::Ptr{Cdouble},
                              userinteraction_p::Ptr{Cint})
    model = unsafe_pointer_to_objref(userdata)::CplexMathProgModel
    cpxrawcb = CallbackData(cbdata, model.inner)
    if wherefrom == CPX_CALLBACK_MIP_BRANCH
        @assert 0 <= nodecnt <= 2
        state = :MIPBranch
    else
        state = :Intermediate
    end

    if model.infocb != nothing
        cpxcb = CplexInfoCallbackData(cpxrawcb, state, wherefrom)
        stat = model.infocb(cpxcb)
        if stat == :Exit
            terminate(model.inner)
        end
    end
    if model.branchcb != nothing && state == :MIPBranch
        numbranchingvars = unsafe_wrap(Array, nodebeg, convert(Cint,nodecnt))::Vector{Cint} + 1
        idxs = unsafe_wrap(Array, indices, sum(numbranchingvars))::Vector{Cint}
        vals = unsafe_wrap(Array, bd, sum(numbranchingvars))::Vector{Cdouble}
        dirs = unsafe_wrap(Array, lu, sum(numbranchingvars))::Vector{Cchar}
        nodes = Array(BranchingChoice, nodecnt)
        if nodecnt >= 1
            subidx = 1 : (numbranchingvars[1])
            nodes[1] = BranchingChoice(idxs[subidx], vals[subidx], dirs[subidx])
        end
        if nodecnt == 2
            subidx = (numbranchingvars[1]+1) : (numbranchingvars[2])
            nodes[2] = BranchingChoice(idxs[subidx], vals[subidx], dirs[subidx])
        end
        cpxcb = CplexBranchCallbackData(cpxrawcb, state, wherefrom, userinteraction_p, nodes)
        stat = model.branchcb(cpxcb)
        if stat == :Exit
            terminate(model.inner)
        end
    end
    return convert(Cint, 0)
end

function setmathprogbranchcallback!(model::CplexMathProgModel)
    set_param!(model.inner.env, "CPX_PARAM_MIPCBREDLP", 0)
    set_param!(model.inner.env, "CPX_PARAM_PRELINEAR", 0)
    set_param!(model.inner.env, "CPX_PARAM_REDUCE", CPX_PREREDUCE_PRIMALONLY)
    cpxcallback = cfunction(masterbranchcallback, Cint, (Ptr{Void},
                                                         Ptr{Void},
                                                         Cint,
                                                         Ptr{Void},
                                                         Cint,
                                                         Cint,
                                                         Cint,
                                                         Cint,
                                                         Ptr{Cint},
                                                         Ptr{Cint},
                                                         Ptr{Cchar},
                                                         Ptr{Cdouble},
                                                         Ptr{Cdouble},
                                                         Ptr{Cint}))
    stat = @cpx_ccall(setbranchcallbackfunc, Cint, (
                      Ptr{Void},
                      Ptr{Void},
                      Any,
                      ),
                      model.inner.env.ptr, cpxcallback, model)
    if stat != 0
        throw(CplexError(model.env, stat))
    end
    nothing
end

type CplexIncumbentCallbackData <: CplexCallbackData
    cbdata::CallbackData
    state::Symbol
    where::Cint
    sol::Vector{Float64}
    isfeas_p::Ptr{Cint}
    userinteraction_p::Ptr{Cint}
    nodes::Vector{BranchingChoice}
end

function masterincumbentcallback(env::Ptr{Void},
                                 cbdata::Ptr{Void},
                                 wherefrom::Cint,
                                 userdata::Ptr{Void},
                                 objval::Cdouble,
                                 xx::Ptr{Cdouble},
                                 isfeas_p::Ptr{Cint},
                                 useraction_p::Ptr{Cint})
    model = unsafe_pointer_to_objref(userdata)::CplexMathProgModel
    cpxrawcb = CallbackData(cbdata, model.inner)
    if wherefrom == CPX_CALLBACK_MIP_INCUMBENT_NODESOLN ||
       wherefrom == CPX_CALLBACK_MIP_INCUMBENT_HEURSOLN ||
       wherefrom == CPX_CALLBACK_MIP_INCUMBENT_USERSOLN
        state = :MIPIncumbent
    else
        state = :Intermediate
    end

    if model.infocb != nothing
        cpxcb = CplexInfoCallbackData(cpxrawcb, state, wherefrom)
        stat = model.infocb(cpxcb)
        if stat == :Exit
            terminate(model.inner)
        end
    end
    if model.incumbentcb != nothing && state == :MIPIncumbent
        sol = unsafe_wrap(Array, xx, numvar(model))
        cpxcb = CplexIncumbentCallbackData(cpxrawcb, state, wherefrom, sol, isfeas_p, useraction_p, BranchingChoice[])
        stat = model.incumbentcb(cpxcb)
        if stat == :Exit
            terminate(model.inner)
        end
    end
    return convert(Cint, 0)
end

function setmathprogincumbentcallback!(model::CplexMathProgModel)
    set_param!(model.inner.env, "CPX_PARAM_MIPCBREDLP", 0)
    set_param!(model.inner.env, "CPX_PARAM_PRELINEAR", 0)
    set_param!(model.inner.env, "CPX_PARAM_REDUCE", CPX_PREREDUCE_PRIMALONLY)
    cpxcallback = cfunction(masterincumbentcallback, Cint, (Ptr{Void},
                                                            Ptr{Void},
                                                            Cint,
                                                            Ptr{Void},
                                                            Cdouble,
                                                            Ptr{Cdouble},
                                                            Ptr{Cint},
                                                            Ptr{Cint}))
    stat = @cpx_ccall(setincumbentcallbackfunc, Cint, (
                      Ptr{Void},
                      Ptr{Void},
                      Any,
                      ),
                      model.inner.env.ptr, cpxcallback, model)
    if stat != 0
        throw(CplexError(model.env, stat))
    end
    nothing
end

type CplexInfoCallbackData <: CplexCallbackData
    cbdata::CallbackData
    state::Symbol
    where::Cint
end

function masterinfocallback(env::Ptr{Void},
                            cbdata::Ptr{Void},
                            wherefrom::Cint,
                            userdata::Ptr{Void})
    model = unsafe_pointer_to_objref(userdata)::CplexMathProgModel
    if model.infocb != nothing
        state = :Intermediate
        cpxrawcb = CallbackData(cbdata, model.inner)
        cpxcb = CplexInfoCallbackData(cpxrawcb, state, wherefrom)
        stat = model.infocb(cpxcb)
        if stat == :Exit
            terminate(model.inner)
        end
    end
    return convert(Cint, 0)
end

function setmathproginfocallback!(model::CplexMathProgModel)
    cpxcallback = cfunction(masterinfocallback, Cint, (Ptr{Void}, Ptr{Void}, Cint, Ptr{Void}))
    stat = @cpx_ccall(setinfocallbackfunc, Cint, (
                      Ptr{Void},
                      Ptr{Void},
                      Any,
                      ),
                      model.inner.env.ptr, cpxcallback, model)
    if stat != 0
        throw(CplexError(model.env, stat))
    end
    nothing
end

function cbgetnodelb(d::CplexCallbackData)
    n = num_var(d.cbdata.model)
    lb = Array(Cdouble,n)
    stat = @cpx_ccall(getcallbacknodelb, Cint, (Ptr{Void},Ptr{Void},Cint,Ptr{Cdouble},Cint,Cint),
                      d.cbdata.model.env.ptr, d.cbdata.cbdata, d.where, lb, 0, n-1)
    if stat != 0
        throw(CplexError(model.env, stat))
    end
    return lb
end

function cbgetnodeub(d::CplexCallbackData)
    n = num_var(d.cbdata.model)
    ub = Array(Cdouble,n)
    stat = @cpx_ccall(getcallbacknodeub, Cint, (Ptr{Void},Ptr{Void},Cint,Ptr{Cdouble},Cint,Cint),
                      d.cbdata.model.env.ptr, d.cbdata.cbdata, d.where, ub, 0, n-1)
    if stat != 0
        throw(CplexError(model.env, stat))
    end
    return ub
end

function cbgetnodeobjval(d::CplexCallbackData)
    val = Array(Cdouble,1)
    stat = @cpx_ccall(getcallbacknodeobjval, Cint, (Ptr{Void},Ptr{Void},Cint,Ptr{Cdouble}),
                      d.cbdata.model.env.ptr, d.cbdata.cbdata, d.where, val)
    if stat != 0
        throw(CplexError(model.env, stat))
    end
    return val[1]
end

function cbgetintfeas(d::CplexCallbackData)
    n = num_var(d.cbdata.model)
    feas = Array(Cint,n)
    stat = @cpx_ccall(getcallbacknodeintfeas, Cint, (Ptr{Void},Ptr{Void},Cint,Ptr{Cint},Cint,Cint),
                      d.cbdata.model.env.ptr, d.cbdata.cbdata, d.where, feas, 0, n-1)
    if stat != 0
        throw(CplexError(model.env, stat))
    end
    return convert(Vector{Int64},feas)
end
