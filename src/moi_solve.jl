function MOI.optimize!(m::CplexSolverInstance)
    optimize!(m.inner)
    # TODO check status to allow this
    cpx_getx!(m.inner, m.primal_solution)
end

function MOI.getattribute(m::CplexSolverInstance, ::MOI.TerminationStatus)
    code = cpx_get_status_code(m.inner)
    return getterminationstatus(code)
end
MOI.cangetattribute(m::CplexSolverInstance, ::MOI.TerminationStatus) = true

# TODO
function MOI.getattribute(m::CplexSolverInstance, ::MOI.PrimalStatus)
    MOI.FeasiblePoint
end
MOI.cangetattribute(m::CplexSolverInstance, ::MOI.PrimalStatus) = true

# Objective Value

function MOI.getattribute(m::CplexSolverInstance, attr::MOI.ObjectiveValue)
    if attr.resultindex == 1
        cpx_getobjval(m.inner)
    else
        error("Unable to access multiple objective values")
    end
end
function MOI.cangetattribute(m::CplexSolverInstance, attr::MOI.ObjectiveValue)
    if attr.resultindex == 1
        return true
    else
        return false
    end
end

# Variable Primal

function MOI.getattribute(m::CplexSolverInstance, ::MOI.VariablePrimal, v::MOI.VariableReference)
    col = m.variable_mapping[v]
    return m.primal_solution[col]
end
MOI.cangetattribute(m::CplexSolverInstance, ::MOI.VariablePrimal, v::MOI.VariableReference) = true
function MOI.getattribute(m::CplexSolverInstance, ::MOI.VariablePrimal, v::Vector{MOI.VariableReference})
    MOI.getattribute.(m, MOI.VariablePrimal(), v)
end
MOI.cangetattribute(m::CplexSolverInstance, ::MOI.VariablePrimal, v::Vector{MOI.VariableReference}) = true
