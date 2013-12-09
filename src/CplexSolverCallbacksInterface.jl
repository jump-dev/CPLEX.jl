type CplexCallbackData <: MathProgCallbackData
  cbdata::CallbackData
  state::Symbol
  where::Cint
  # model::CplexMathProgModel # not needed?
end

# set to nothing to clear callback
setlazycallback!(m::CplexMathProgModel,f) = (m.lazycb = f)
setcutcallback!(m::CplexMathProgModel,f) = (m.cutcb = f)
setheuristiccallback!(m::CplexMathProgModel,f) = (m.heuristiccb = f)

function cbgetmipsolution(d::CplexCallbackData)
    @assert d.state == :MIPSol
    return cbget_mipsol_sol(d.cbdata, d.where)
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

cbaddsolution!(d::CplexCallbackData, x) = cbsolution(d.stat, x)

const sensemap = [:(==) => 'E', :(<=) => 'L', :(>=) => 'G']
function cbaddcut!(d::CplexCallbackData,varidx,varcoef,sense,rhs)
    @assert d.state == :MIPNode
    cbcut(d.cbdata, convert(Vector{Cint}, varidx), float(varcoef), sensemap[sense], float(rhs))
end

function cbaddlazy!(d::CplexCallbackData,varidx,varcoef,sense,rhs)
    @assert d.state == :MIPNode || d.state == :MIPSol
    cblazy(d.cbdata, convert(Vector{Cint}, varidx), float(varcoef), sensemap[sense], float(rhs))
end

# breaking abstraction, define our low-level callback to eliminate
# a level of indirection
function mastercallback(lp::Ptr{Void}, cbdata::Ptr{Void}, where::Cint, userdata::Ptr{Void})
    model = unsafe_pointer_to_objref(userdata)::CplexMathProgModel
    cpxrawcb = CallbackData(cbdata, model.inner)
    if where == CPX_CALLBACK_MIP_CUT_FEAS || where == CPX_CALLBACK_MIP_CUT_UNBD
        state = :MIPSol
        cpxcb = CplexCallbackData(cpxrawcb, state, where)
        if model.lazycb != nothing
            stat = model.lazycb(cpxcb)
            if stat == :Exit
                return convert(Cint, 1006)
            end
        end
    elseif where == CPX_CALLBACK_MIP_NODE
        state = :MIPNode
        cpxcb = CplexCallbackData(cpxrawcb, state, where)
        if model.cutcb != nothing
            stat = model.cutcb(cpxcb)
            if stat == :Exit
                return convert(Cint, 1006)
            end
        end
        if model.heuristiccb != nothing
            stat = model.heuristiccb(cpxcb)
            if stat == :Exit
                return convert(Cint, 1006)
            end
        end
    end
    return convert(Cint, 0)
end

# User callback function should be of the form:
# callback(cbdata::MathProgCallbackData)
# return :Exit to indicate an error

function setmathproglazycallback!(model::CplexMathProgModel)
    cpxcallback = cfunction(mastercallback, Cint, (Ptr{Void}, Ptr{Void}, Cint, Ptr{Void}))
    stat = @cpx_ccall(setlazyconstraintcallbackfunc, Cint, (
                      Ptr{Void}, 
                      Ptr{Void},
                      Any,
                      ), 
                      model.inner.env, cpxcallback, model)
    if stat != 0
        throw(CplexError(model.env, ret))
    end
    nothing
end

function setmathprogcutcallback!(model::CplexMathProgModel)
    cpxcallback = cfunction(mastercallback, Cint, (Ptr{Void}, Ptr{Void}, Cint, Ptr{Void}))
    stat = @cpx_ccall(setusercutcallbackfunc, Cint, (
                      Ptr{Void}, 
                      Ptr{Void},
                      Any,
                      ), 
                      model.inner.env, cpxcallback, model)
    if stat != 0
        throw(CplexError(model.env, ret))
    end
    nothing
end

function setmathprogheuristiccallback!(model::CplexMathProgModel)
    cpxcallback = cfunction(mastercallback, Cint, (Ptr{Void}, Ptr{Void}, Cint, Ptr{Void}))
    stat = @cpx_ccall(setheuristiccallbackfunc, Cint, (
                      Ptr{Void}, 
                      Ptr{Void},
                      Any,
                      ), 
                      model.inner.env, cpxcallback, model)
    if stat != 0
        throw(CplexError(model.env, ret))
    end
    nothing
end
