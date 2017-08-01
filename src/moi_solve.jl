#=
    Optimize the model
=#

function MOI.optimize!(m::CplexSolverInstance)
    # reset storage
    fill!(m.variable_primal_solution, NaN)
    fill!(m.variable_dual_solution, NaN)
    fill!(m.constraint_primal_solution, NaN)
    fill!(m.constraint_dual_solution, NaN)
    m.primal_status = MOI.UnknownResultStatus
    m.dual_status   = MOI.UnknownResultStatus
    m.primal_result_count = 0
    m.dual_result_count = 0

    # reset storage
    if hasinteger(m)
        cpx_mipopt!(m.inner)
    else
        cpx_lpopt!(m.inner)
    end

    # termination_status
    code = cpx_getstat(m.inner)
    status_symbol = getstatussymbol(code)
    m.termination_status = getterminationstatus(status_symbol)

    # get some more information about solution
    mthd, soltype, prifeas, dualfeas = cpx_solninfo(m.inner)
    #
    @assert soltype in [CPX_BASIC_SOLN, CPX_NONBASIC_SOLN, CPX_PRIMAL_SOLN, CPX_NO_SOLN]
    if soltype == CPX_BASIC_SOLN || soltype == CPX_NONBASIC_SOLN || soltype == CPX_PRIMAL_SOLN
        # primal solution exists
        cpx_getx!(m.inner, m.variable_primal_solution)
        cpx_getax!(m.inner, m.constraint_primal_solution)
        m.primal_status = MOI.FeasiblePoint
        m.primal_result_count = 1
    end
    if soltype == CPX_BASIC_SOLN || soltype == CPX_NONBASIC_SOLN
        # dual solution exists
        cpx_getdj!(m.inner, m.variable_dual_solution)
        cpx_getpi!(m.inner, m.constraint_dual_solution)
        m.dual_status = MOI.FeasiblePoint
        m.dual_result_count = 1
    end

    # TODO: handle the case where we can find a proof of infeasibility etc.
    # if m.termination_status == MOI.InfeasibleNoResult
    #     cpx_dualfarkas!(m.inner, m.constraint_primal_solution)
    #     m.termination_status = MOI.Success
    #     m.primal_status = MOI.InfeasibilityCertificate
    # elseif m.termination_status == MOI.UnboundedNoResult
    #     cpx_getray!(m.inner, m.variable_primal_solution)
    #     m.termination_status = MOI.Success
    #     m.termination_status = MOI.ReductionCertificate
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

#=
    Result Count
    TODO: improve
=#
function MOI.getattribute(m::CplexSolverInstance, ::MOI.ResultCount)
    m.primal_result_count
end
MOI.cangetattribute(m::CplexSolverInstance, ::MOI.ResultCount) = true

#=
    Termination status
=#

function MOI.getattribute(m::CplexSolverInstance, ::MOI.TerminationStatus)
    m.termination_status
end
MOI.cangetattribute(m::CplexSolverInstance, ::MOI.TerminationStatus) = true

#=
    Primal status
=#

function MOI.getattribute(m::CplexSolverInstance, p::MOI.PrimalStatus)
    m.primal_status
end
function MOI.cangetattribute(m::CplexSolverInstance, p::MOI.PrimalStatus)
    m.primal_result_count >= p.N
end

#=
    Dual status
=#

function MOI.getattribute(m::CplexSolverInstance, d::MOI.DualStatus)
    m.dual_status
end
function MOI.cangetattribute(m::CplexSolverInstance, d::MOI.DualStatus)
    m.dual_result_count >= d.N
end

#=
    Objective Value
=#


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

#=
    Variable Primal solution
=#


function MOI.getattribute(m::CplexSolverInstance, ::MOI.VariablePrimal, v::MOI.VariableReference)
    col = m.variable_mapping[v]
    return m.variable_primal_solution[col]
end
MOI.cangetattribute(m::CplexSolverInstance, ::MOI.VariablePrimal, v::MOI.VariableReference) = true

function MOI.getattribute(m::CplexSolverInstance, ::MOI.VariablePrimal, v::Vector{MOI.VariableReference})
    MOI.getattribute.(m, MOI.VariablePrimal(), v)
end
MOI.cangetattribute(m::CplexSolverInstance, ::MOI.VariablePrimal, v::Vector{MOI.VariableReference}) = true

#=
    Variable Dual solution
=#


function MOI.getattribute(m::CplexSolverInstance,::MOI.ConstraintDual, c::SVCR{<: Union{LE, GE, EQ, IV}})
    vref = m[c]
    col = m.variable_mapping[vref]
    return m.variable_dual_solution[col]
end
MOI.cangetattribute(m::CplexSolverInstance, ::MOI.ConstraintDual, c::SVCR{<: Union{LE, GE, EQ, IV}}) = true

#=
    Constraint Primal solution
=#

function MOI.getattribute(m::CplexSolverInstance, ::MOI.ConstraintPrimal, c::LCR{<: Union{LE, GE, EQ}})
    row = m[c]
    return m.constraint_primal_solution[row]
end
MOI.cangetattribute(m::CplexSolverInstance, ::MOI.ConstraintPrimal,c::LCR{<: Union{LE, GE, EQ}}) = true

#=
    Constraint Dual solution
=#

function MOI.getattribute(m::CplexSolverInstance, ::MOI.ConstraintDual, c::LCR{LE})
    dual = _getconstraintdual(m, c)
    @assert dual <= 0.0
    return dual
end
function MOI.getattribute(m::CplexSolverInstance, ::MOI.ConstraintDual, c::LCR{GE})
    dual = _getconstraintdual(m, c)
    @assert dual >= 0.0
    return dual
end
function MOI.getattribute(m::CplexSolverInstance, ::MOI.ConstraintDual, c::LCR{<: Union{LE, GE, EQ}})
    _getconstraintdual(m, c)
end

function _getconstraintdual(m::CplexSolverInstance, c::LCR{<: Union{LE, GE, EQ}})
    row = m[c]
    return m.constraint_dual_solution[row]
end
MOI.cangetattribute(m::CplexSolverInstance, ::MOI.ConstraintDual,c::LCR{<: Union{LE, GE, EQ}}) = true
