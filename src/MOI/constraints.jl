function MOI.addconstraint!(m::CplexSolverInstance, func::ScalarAffineFunction{Float64}, set::T) where T <: Union{LessThan{Float64}, GreaterThan{Float64}, EqualsTo{Float64}}
    addlinearconstraint!(m, func, set)
    m.last_constraint_reference += 1
    ref = MOI.ConstraintReference{ScalarAffineFunction{Float64}, T}(m.last_constraint_reference)
    m.constraint_mapping[ref] = num_constr(m.inner)
    return ref
end

addlinearconstraint!(m::CplexSolverInstance, func::ScalarAffineFunction{Float64}, set::LessThan{Float64}) = addlinearconstraint!(m, func, 'L', set.upper)
addlinearconstraint!(m::CplexSolverInstance, func::ScalarAffineFunction{Float64}, set::GreaterThan{Float64}) = addlinearconstraint!(m, func, 'G', set.lower)
addlinearconstraint!(m::CplexSolverInstance, func::ScalarAffineFunction{Float64}, set::EqualsTo{Float64}) = addlinearconstraint!(m, func, 'E', set.value)
function addlinearconstraint!(m::CplexSolverInstance, func::ScalarAffineFunction{Float64}, sense::Cchar, rhs)
    if abs(func.constant) > eps(Float64)
        warn("Constant in scalar function moved into set.")
    end
    cpx_add_constraint!(m.inner, getcols(m, func.variables), func.coefficients, sense, rhs - func.constant)
end

# function MOI.getattribute(m::CplexSolverInstance, ::ConstraintSet, c::ConstraintReference{ScalarAffineFunction{Float64},LessThan{Float64}})
#     row = m.constraint_mapping[c]::Int
#     ub = cpx_get_variable_upperbound(m.inner, getcol(m, vref))
#     return LessThan{Float64}(ub)
# end
# function MOI.getattribute(m::CplexSolverInstance, ::ConstraintSet, c::ConstraintReference{SingleVariable,GreaterThan{Float64}})
#     row = m.constraint_mapping[c]::Int
#     lb = cpx_get_variable_lowerbound(m.inner, getcol(m, vref))
#     return GreaterThan{Float64}(lb)
# end
# function MOI.getattribute(m::CplexSolverInstance, ::ConstraintSet, c::ConstraintReference{SingleVariable,EqualsTo{Float64}})
#     row = m.constraint_mapping[c]::Int
#     lb = cpx_get_variable_lowerbound(m.inner, getcol(m, vref))
#     return EqualsTo{Float64}(lb)
# end
# function MOI.getattribute(m::CplexSolverInstance, ::ConstraintSet, c::ConstraintReference{SingleVariable,Interval{Float64}})
#     row = m.constraint_mapping[c]::Int
#     lb = cpx_get_variable_lowerbound(m.inner, getcol(m, vref))
#     ub = cpx_get_variable_upperbound(m.inner, getcol(m, vref))
#     return Interval{Float64}(lb, ub)
# end
#
# function MOI.getattribute(m::CplexSolverInstance, ::ConstraintFunction, c::ConstraintReference{ScalarAffineFunction{Float64},T}) where T <: Union{LessThan{Float64}, GreaterThan{Float64}, EqualsTo{Float64}}
#     row = m.constraint_mapping[c]::Int
#
# end
