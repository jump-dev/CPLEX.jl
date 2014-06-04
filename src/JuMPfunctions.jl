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

# function setBranchCallback(m::JuMP.Model, f::Function) 
#     branchcallback(d::MathProgCallbackData) = f(d)
#     setbranchcallback!(m.internalModel, branchcallback)
#     println("setting branch callback")
# end

function setBranchCallback(m::JuMP.Model, f::Function)
    initcb(m)
    m.ext[:cb].branchcallback = f

    function registercb(m::JuMP.Model)
        if isa(m.ext[:cb].branchcallback, Function)
            function branchcallback(d::MathProgCallbackData)
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
            function incumbentcallback(d::MathProgCallbackData)
                state = cbgetstate(d)
                @assert state == :MIPIncumbent
                m.colVal = pointer_to_array(d.sol,m.numCols)
                m.ext[:cb].incumbentcallback(d)
            end
            setincumbentcallback!(m.internalModel, incumbentcallback)
        end
    end
    m.presolve = registercb
    nothing
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

# function setIncumbentCallback(m::JuMP.Model, f::Function)
#     incumbentcallback(d::MathProgCallbackData) = f(d)
#     setincumbentcallback!(m.internalModel, incumbentcallback)
#     println("setting incumbent callback")
# end

function setIncumbentCallback(m::JuMP.Model, f::Function)
    initcb(m)
    m.ext[:cb].incumbentcallback = f

    function registercb(m::JuMP.Model)
        if isa(m.ext[:cb].branchcallback, Function)
            function branchcallback(d::MathProgCallbackData)
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
            function incumbentcallback(d::MathProgCallbackData)
                state = cbgetstate(d)
                @assert state == :MIPIncumbent
                m.colVal = pointer_to_array(d.sol,m.numCols) # This will only work for CPLEX!
                m.ext[:cb].incumbentcallback(d)
            end
            setincumbentcallback!(m.internalModel, incumbentcallback)
        end
    end
    m.presolve = registercb
    nothing
end

acceptIncumbent(cbdata::MathProgCallbackData) = 
    cbprocessincumbent!(cbdata, true)

rejectIncumbent(cbdata::MathProgCallbackData) = 
    cbprocessincumbent!(cbdata, false)
