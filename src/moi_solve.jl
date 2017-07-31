function MOI.optimize!(m::CplexSolverInstance)
    fill!(m.variable_primal_solution, NaN)
    fill!(m.variable_dual_solution, NaN)
    fill!(m.constraint_primal_solution, NaN)
    fill!(m.constraint_dual_solution, NaN)

    optimize!(m.inner)

    # TODO check status to allow this
    cpx_getx!(m.inner, m.variable_primal_solution)
    cpx_getdj!(m.inner, m.variable_dual_solution)

    cpx_getax!(m.inner, m.constraint_primal_solution)
    cpx_getpi!(m.inner, m.constraint_dual_solution)

    #=
        CPLEX has the dual convention that the sign of the dual depends on the
        optimization sense. This isn't the same as the MOI convention so we need
        to correct that.
    =#
    if MOI.getattribute(m, MOI.Sense()) == MOI.MaxSense
        m.constraint_dual_solution *= -1
        m.variable_dual_solution *= -1
    end

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
function MOI.getattribute(m::CplexSolverInstance, ::MOI.DualStatus)
    MOI.FeasiblePoint
end
MOI.cangetattribute(m::CplexSolverInstance, ::MOI.DualStatus) = true
# Objective Value

function MOI.getattribute(m::CplexSolverInstance, attr::MOI.ObjectiveValue)
    if attr.resultindex == 1
        cpx_getobjval(m.inner) + m.objective_constant
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
    return m.variable_primal_solution[col]
end
MOI.cangetattribute(m::CplexSolverInstance, ::MOI.VariablePrimal, v::MOI.VariableReference) = true
function MOI.getattribute(m::CplexSolverInstance, ::MOI.VariablePrimal, v::Vector{MOI.VariableReference})
    MOI.getattribute.(m, MOI.VariablePrimal(), v)
end
MOI.cangetattribute(m::CplexSolverInstance, ::MOI.VariablePrimal, v::Vector{MOI.VariableReference}) = true

# Variable Dual

function MOI.getattribute(m::CplexSolverInstance,::MOI.ConstraintDual, c::MOI.ConstraintReference{MOI.SingleVariable, S}) where S
    vref = constraint_storage_value(m, c)
    col = m.variable_mapping[vref]
    return m.variable_dual_solution[col]
end
MOI.cangetattribute(m::CplexSolverInstance, ::MOI.ConstraintDual, c::MOI.ConstraintReference{MOI.SingleVariable, S}) where S = true

# Constraint Primal

function MOI.getattribute(m::CplexSolverInstance, ::MOI.ConstraintPrimal, c::MOI.ConstraintReference{F, S}) where F where S
    row = constraint_storage_value(m, c)
    return m.constraint_primal_solution[row]
end
function MOI.cangetattribute(m::CplexSolverInstance, ::MOI.ConstraintPrimal,c::MOI.ConstraintReference{F, S}) where F where S
    true
end

#    Constraint Dual

function MOI.getattribute(m::CplexSolverInstance, ::MOI.ConstraintDual, c::MOI.ConstraintReference{Linear, LE})
    dual = _getconstraintdual(m, c)
    @assert dual <= 0.0
    return dual
end
function MOI.getattribute(m::CplexSolverInstance, ::MOI.ConstraintDual, c::MOI.ConstraintReference{Linear, GE})
    dual = _getconstraintdual(m, c)
    @assert dual >= 0.0
    return dual
end
function MOI.getattribute(m::CplexSolverInstance, ::MOI.ConstraintDual, c::MOI.ConstraintReference{F, S}) where F where S
    _getconstraintdual(m, c)
end

function _getconstraintdual(m::CplexSolverInstance, c::MOI.ConstraintReference{F, S}) where F where S
    row = constraint_storage_value(m, c)
    return m.constraint_dual_solution[row]
end
function MOI.cangetattribute(m::CplexSolverInstance, ::MOI.ConstraintDual,c::MOI.ConstraintReference{F, S}) where F where S
    true
end
