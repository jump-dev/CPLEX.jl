function hasquadratic(m::CplexSolverInstance)
    m.obj_is_quad || (length(cmap(m).q_less_than) + length(cmap(m).q_greater_than) + length(cmap(m).q_equal_to) > 0)
end

function getterminationstatus(status::Cint)
    if haskey(TERMINATION_STATUS_MAP, status)
        return TERMINATION_STATUS_MAP[status]
    else
        error("Status $(status) has not been mapped to a MOI termination status.")
    end
end

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

    t = time()
    if hasinteger(m)
        cpx_mipopt!(m.inner)
    elseif hasquadratic(m)
        cpx_qpopt!(m.inner)
    else
        cpx_lpopt!(m.inner)
    end
    m.solvetime = time() - t

    # termination_status
    code = cpx_getstat(m.inner)
    m.termination_status = getterminationstatus(code)

    # get some more information about solution
    mthd, soltype, prifeas, dualfeas = cpx_solninfo(m.inner)
    #
    @assert soltype in [CPX_BASIC_SOLN, CPX_NONBASIC_SOLN, CPX_PRIMAL_SOLN, CPX_NO_SOLN]
    if soltype == CPX_BASIC_SOLN || soltype == CPX_NONBASIC_SOLN || soltype == CPX_PRIMAL_SOLN
        # primal solution exists
        cpx_getx!(m.inner, m.variable_primal_solution)
        cpx_getax!(m.inner, m.constraint_primal_solution)
        m.primal_result_count = 1
        # CPLEX can return infeasible points
        if prifeas > 0
            m.primal_status = MOI.FeasiblePoint
        else
            m.primal_status = MOI.InfeasiblePoint
        end
    end
    if soltype == CPX_BASIC_SOLN || soltype == CPX_NONBASIC_SOLN
        # dual solution exists
        cpx_getdj!(m.inner, m.variable_dual_solution)
        cpx_getpi!(m.inner, m.constraint_dual_solution)
        m.dual_result_count = 1
        # dual solution may not be feasible
        if dualfeas > 0
            m.dual_status = MOI.FeasiblePoint
        else
            m.dual_status = MOI.InfeasiblePoint
        end
    end

    if code == CPX_STAT_INFEASIBLE
        solvefordualfarkas!(m)
    elseif code == CPX_STAT_UNBOUNDED
        solveforunboundedray!(m)
    end

    #=
        CPLEX has the dual convention that the sign of the dual depends on the
        optimization sense. This isn't the same as the MOI convention so we need
        to correct that.
    =#
    if MOI.getattribute(m, MOI.ObjectiveSense()) == MOI.MaxSense
        m.constraint_dual_solution *= -1
        m.variable_dual_solution *= -1
    end
end

function solvefordualfarkas!(m::CplexSolverInstance)
    cpx_dualopt!(m.inner)
    @assert cpx_getstat(m.inner) == CPX_STAT_INFEASIBLE
    mthd, soltype, prifeas, dualfeas = cpx_solninfo(m.inner)
    if dualfeas > 0
        # ensure we have a dual feasible solution
        cpx_dualfarkas!(m.inner, m.constraint_dual_solution)
        m.dual_status = MOI.InfeasibilityCertificate
        m.termination_status = MOI.Success
        m.dual_result_count = 1
    end
end

function solveforunboundedray!(m::CplexSolverInstance)
    @assert cpx_getstat(m.inner) == CPX_STAT_UNBOUNDED
    cpx_getray!(m.inner, m.variable_primal_solution)
    m.primal_status = MOI.InfeasibilityCertificate
    m.termination_status = MOI.Success
    m.primal_result_count = 1
end

#=
    Result Count
=#
function MOI.getattribute(m::CplexSolverInstance, ::MOI.ResultCount)
    max(m.primal_result_count, m.dual_result_count)
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

function MOI.getattribute(m::CplexSolverInstance, ::MOI.ConstraintPrimal, c::LCR{<: Union{LE, GE, EQ, IV}})
    row = m[c]
    return m.constraint_primal_solution[row]
end
MOI.cangetattribute(m::CplexSolverInstance, ::MOI.ConstraintPrimal,c::LCR{<: Union{LE, GE, EQ, IV}}) = true


# vector valued constraint duals
MOI.getattribute(m::CplexSolverInstance, ::MOI.ConstraintPrimal, c::VLCR{<: Union{MOI.Zeros, MOI.Nonnegatives, MOI.Nonpositives}}) = m.constraint_primal_solution[m[c]]
MOI.cangetattribute(m::CplexSolverInstance, ::MOI.ConstraintPrimal,c::VLCR{<: Union{MOI.Zeros, MOI.Nonnegatives, MOI.Nonpositives}}) = true

#=
    Constraint Dual solution
=#

_checkdualsense(::LCR{LE}, dual) = dual <= 0.0
_checkdualsense(::LCR{GE}, dual) = dual >= 0.0
_checkdualsense(::LCR{IV}, dual) = true
_checkdualsense(::LCR{EQ}, dual) = true

function MOI.getattribute(m::CplexSolverInstance, ::MOI.ConstraintDual, c::LCR{<: Union{LE, GE, EQ, IV}})
    row = m[c]
    dual = m.constraint_dual_solution[row]
    @assert _checkdualsense(c, dual)
    return dual
end
MOI.cangetattribute(m::CplexSolverInstance, ::MOI.ConstraintDual,c::LCR{<: Union{LE, GE, EQ, IV}}) = true

# vector valued constraint duals
MOI.getattribute(m::CplexSolverInstance, ::MOI.ConstraintDual, c::VLCR{<: Union{MOI.Zeros, MOI.Nonnegatives, MOI.Nonpositives}}) = m.constraint_dual_solution[m[c]]
MOI.cangetattribute(m::CplexSolverInstance, ::MOI.ConstraintDual,c::VLCR{<: Union{MOI.Zeros, MOI.Nonnegatives, MOI.Nonpositives}}) = true

#=
    Solution Attributes
=#

# struct ObjectiveBound <: AbstractSolverInstanceAttribute end
MOI.getattribute(m::CplexSolverInstance, ::MOI.ObjectiveBound) = cpx_getbestobjval(m.inner)
MOI.cangetattribute(m::CplexSolverInstance, ::MOI.ObjectiveBound) = true

# struct RelativeGap <: AbstractSolverInstanceAttribute  end
MOI.getattribute(m::CplexSolverInstance, ::MOI.RelativeGap) = cpx_getmiprelgap(m.inner)
MOI.cangetattribute(m::CplexSolverInstance, ::MOI.RelativeGap) = true

# struct SolveTime <: AbstractSolverInstanceAttribute end
MOI.getattribute(m::CplexSolverInstance, ::MOI.SolveTime) = m.solvetime
MOI.cangetattribute(m::CplexSolverInstance, ::MOI.SolveTime) = true

# struct SimplexIterations <: AbstractSolverInstanceAttribute end
MOI.getattribute(m::CplexSolverInstance, ::MOI.SimplexIterations) = cpx_getitcnt(m.inner)
MOI.cangetattribute(m::CplexSolverInstance, ::MOI.SimplexIterations) = true

# struct BarrierIterations <: AbstractSolverInstanceAttribute end
MOI.getattribute(m::CplexSolverInstance, ::MOI.BarrierIterations) = cpx_getbaritcnt(m.inner)
MOI.cangetattribute(m::CplexSolverInstance, ::MOI.BarrierIterations) = true

# struct NodeCount <: AbstractSolverInstanceAttribute end
MOI.getattribute(m::CplexSolverInstance, ::MOI.NodeCount) = cpx_getnodecnt(m.inner)
MOI.cangetattribute(m::CplexSolverInstance, ::MOI.NodeCount) = true

# struct RawSolver <: AbstractSolverInstanceAttribute end
MOI.getattribute(m::CplexSolverInstance, ::MOI.RawSolver) = m.inner
MOI.cangetattribute(m::CplexSolverInstance, ::MOI.RawSolver) = true
