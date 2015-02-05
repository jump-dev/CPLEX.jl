# Import functions that act on JuMP Models

export setBranchCallback,
       addBranch,
       setIncumbentCallback,
       acceptIncumbent,
       rejectIncumbent

type CPLEXcb
    branchcallback
    incumbentcallback
end

function initcb(m::JuMP.Model)
    if !haskey(m.ext, :cb)
        m.ext[:cb] = CPLEXcb(nothing,nothing)
    end
end

function solvehook(m::JuMP.Model; kwargs...)
    JuMP.buildInternalModel(m)
    if isa(m.ext[:cb].branchcallback, Function)
        function branchcallback(d::CplexCallbackData)
            state = cbgetstate(d)
            if state == :MIPSol
                cbgetmipsolution(d,m.colVal)
            else
                cbgetlpsolution(d,m.colVal)
            end
            m.ext[:cb].branchcallback(d)
        end
        setbranchcallback!(m.internalModel, branchcallback)
    end
    if isa(m.ext[:cb].incumbentcallback, Function)
        function incumbentcallback(d::CplexCallbackData)
            state = cbgetstate(d)
            @assert state == :MIPIncumbent
            m.colVal = copy(d.sol)
            m.ext[:cb].incumbentcallback(d)
        end
        setincumbentcallback!(m.internalModel, incumbentcallback)
    end
    JuMP.solve(m; ignore_solve_hook=true, kwargs...)
end

function setBranchCallback(m::JuMP.Model, f::Function)
    initcb(m)
    m.ext[:cb].branchcallback = f
    JuMP.setSolveHook(m, solvehook)
    nothing
end

function addBranch(cbdata::MathProgCallbackData, aff::JuMP.LinearConstraint)
    addBranch(cbdata, aff, cbgetnodeobjval(cbdata))
end

function addBranch(cbdata::MathProgCallbackData, aff::JuMP.LinearConstraint, nodeest)
    if length(aff.terms.vars) == 1 # branch on variable
        @assert (isinf(aff.lb) + isinf(aff.ub) == 1)
        up = isinf(aff.ub)
        idx = aff.terms.vars[1].col
        bnd = (up ? aff.lb : aff.ub) / aff.terms.coeffs[1]
        #nodeest = 0.0
        if up
            cbaddboundbranchup!(  cbdata, idx, bnd, nodeest)
        else
            cbaddboundbranchdown!(cbdata, idx, bnd, nodeest)
        end
    else
        indices = [x.col for x in aff.terms.vars]
        coeffs  = [v for v in aff.terms.coeffs]
        lb, ub = aff.lb, aff.ub
        isinf(lb) || isinf(ub) || lb == ub || error("Cannot branch on ranged constraint $aff")
        if isinf(lb)
            sense = 'L'
            rhs = ub
        elseif isinf(ub)
            sense = 'G'
            rhs = lb
        else
            sense = 'E'
            rhs = lb
        end
        cbaddconstrbranch!(cbdata, indices, coeffs, rhs, sense, nodeest)
    end
end

function setIncumbentCallback(m::JuMP.Model, f::Function)
    initcb(m)
    m.ext[:cb].incumbentcallback = f
    JuMP.setSolveHook(m, solvehook)
    nothing
end

acceptIncumbent(cbdata::MathProgCallbackData) =
    cbprocessincumbent!(cbdata, true)

rejectIncumbent(cbdata::MathProgCallbackData) =
    cbprocessincumbent!(cbdata, false)
