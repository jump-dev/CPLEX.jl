# Import functions that act on JuMP Models

typealias JuMPModel JuMP.Model

function setBranchCallback(m::JuMPModel, f::Function) 
    branchcallback(d::MathProgCallbackData) = f(d)
    setbranchcallback!(m.internalModel, branchcallback)
    println("setting branch callback")
end
export setBranchCallback

function addBranch(cbdata::MathProgCallbackData, aff::JuMP.LinearConstraint)
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
export addBranch
