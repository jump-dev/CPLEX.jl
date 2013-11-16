type CplexCallbackData <: MathProgCallbackData
  cbdata::CallbackData
  state::Symbol
  where::Cint
  model::CplexMathProgModel # not needed?
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

function cbgetexplorednodes(d::CplexCallbackData)
    if d.state == :MIPNode
        return cbget_mipnode_nodcnt(d.cbdata, d.where)
    elseif d.state == :MIPSol
        return cbdet_mipsol_nodcnt(d.cbdata, d.where)
    else
        error("Unrecognized callback state $(d.state)")
    end
end
        
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
   
