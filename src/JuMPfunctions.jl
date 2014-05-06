# Import functions that act on JuMP Models

typealias JuMPModel JuMP.Model

export setBranchCallback,
       addBranch,
       setIncumbentCallback,
       getIncumbent,
       acceptIncumbent,
       rejectIncumbent

type CPLEXcb
    branchcb
    incumbentcb
end

function initcb(m::JuMPModel)
    if !haskey(m.ext, :cb)
        m.ext[:cb] = CPLEXcb(nothing,nothing)
    end
end

# function setBranchCallback(m::JuMPModel, f::Function) 
#     branchcallback(d::MathProgCallbackData) = f(d)
#     setbranchcallback!(m.internalModel, branchcallback)
#     println("setting branch callback")
# end

function setBranchCallback(m::JuMPModel, f::Function)
    initcb(m)
    m.ext[:cb].branchcb = f
end

function addBranch(cbdata::MathProgCallbackData, aff::JuMP.LinearConstraint)
    addBranch(cbdata, aff, cbgetnodeobjval(cbdata))
end

function addBranch(cbdata::MathProgCallbackData, aff::JuMP.LinearConstraint, nodeest)
    if length(aff.terms.vars) == 1 # branch on variable
        @assert (isinf(aff.lb) + isinf(aff.ub) == 1)
        up = isinf(aff.ub) ? true : false
        idx = aff.terms.vars[1].col
        bnd = (up ? aff.lb : aff.ub) / aff.terms.coeffs[1]
        nodeest = 0.0
        if up
            cbaddboundbranchup!(cbdata, idx, bnd, nodeest)
        else
            cbaddboundbranchdown!(cbdata, idx, bnd, nodeest)
        end
    else
        # TODO: add cbaddconstrbranch!
    end
end

# function setIncumbentCallback(m::JuMPModel, f::Function)
#     incumbentcallback(d::MathProgCallbackData) = f(d)
#     setincumbentcallback!(m.internalModel, incumbentcallback)
#     println("setting incumbent callback")
# end

function setBranchCallback(m::JuMPModel, f::Function)
    initcb(m)
    m.ext[:cb].incumbentcb = f
end

getIncumbent(cbdata::MathProgCallbackData) = 
    unsafe_pointer_to_objref(cbdata.sol)::Array{Float64}

acceptIncumbent(cbdata::MathProgCallbackData) = 
    cbprocessincumbent!(cbdata, true)

rejectIncumbent(cbdata::MathProgCallbackData) = 
    cbprocessincumbent!(cbdata, false)
