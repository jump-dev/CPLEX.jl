function MOI.optimize!(m::CplexSolverInstance)
    fill!(m.variable_primal_solution, NaN)
    fill!(m.variable_dual_solution, NaN)
    fill!(m.constraint_primal_solution, NaN)
    fill!(m.constraint_dual_solution, NaN)
    m.primal_status = MOI.UnknownResultStatus
    m.dual_status   = MOI.UnknownResultStatus

    optimize!(m.inner)

    code = cpx_getstat(m.inner)
    status_symbol = getstatussymbol(code)

    m.termination_status = getterminationstatus(status_symbol)

    mthd, soltype, prifeas, dualfeas = cpx_solninfo(m.inner)
    if !(soltype in [CPX_BASIC_SOLN, CPX_NONBASIC_SOLN, CPX_PRIMAL_SOLN, CPX_NO_SOLN])
        error("Unable to understand solution type code $soltype")
    end
    if soltype == CPX_BASIC_SOLN || soltype == CPX_NONBASIC_SOLN || soltype == CPX_PRIMAL_SOLN
        # primal solution
        cpx_getx!(m.inner, m.variable_primal_solution)
        cpx_getax!(m.inner, m.constraint_primal_solution)
        m.primal_status = MOI.FeasiblePoint
    end
    if soltype == CPX_BASIC_SOLN || soltype == CPX_NONBASIC_SOLN
        # dual solution
        cpx_getdj!(m.inner, m.variable_dual_solution)
        cpx_getpi!(m.inner, m.constraint_dual_solution)
        m.dual_status = MOI.FeasiblePoint
    end

    # if m.termination_status == MOI.InfeasibleNoResult
    #     cpx_dualfarkas!(m.inner, m.constraint_primal_solution)
    #     # m.termination_status = MOI.Success
    # #     m.primal_status = MOI.InfeasibilityCertificate
    # #
    # elseif m.termination_status == MOI.UnboundedNoResult
    #     cpx_getray!(m.inner, m.variable_primal_solution)
    # #     m.termination_status = MOI.ReductionCertificate
    # end

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
    m.termination_status
end
MOI.cangetattribute(m::CplexSolverInstance, ::MOI.TerminationStatus) = true

# TODO
function MOI.getattribute(m::CplexSolverInstance, ::MOI.PrimalStatus)
    m.primal_status
end
MOI.cangetattribute(m::CplexSolverInstance, ::MOI.PrimalStatus) = true
function MOI.getattribute(m::CplexSolverInstance, ::MOI.DualStatus)
    m.dual_status
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
