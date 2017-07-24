include("constraints_cpx.jl")

constraint_storage(m::CplexSolverInstance, func::MOI.AbstractScalarFunction, set::MOI.AbstractSet) = constraint_storage(m, typeof(func), typeof(set))
constraint_storage(m::CplexSolverInstance, ::Type{Linear}, ::Type{LE}) = m.constraint_mapping.less_than
constraint_storage(m::CplexSolverInstance, ::Type{Linear}, ::Type{GE}) = m.constraint_mapping.greater_than
constraint_storage(m::CplexSolverInstance, ::Type{Linear}, ::Type{EQ}) = m.constraint_mapping.equal_to

constraint_storage(m::CplexSolverInstance, ::Type{MOI.SingleVariable}, ::Type{LE}) = m.constraint_mapping.variable_upper_bound
constraint_storage(m::CplexSolverInstance, ::Type{MOI.SingleVariable}, ::Type{GE}) = m.constraint_mapping.variable_lower_bound
constraint_storage(m::CplexSolverInstance, ::Type{MOI.SingleVariable}, ::Type{EQ}) = m.constraint_mapping.fixed_variables
constraint_storage(m::CplexSolverInstance, ::Type{MOI.SingleVariable}, ::Type{MOI.Interval{Float64}}) = m.constraint_mapping.interval_variables

"""
    Set bounds on variable
"""
function MOI.addconstraint!(m::CplexSolverInstance, v::MOI.SingleVariable, set)
    setvariablebound!(m, v, set)
    m.last_constraint_reference += 1
    ref = MOI.ConstraintReference{MOI.SingleVariable, typeof(set)}(m.last_constraint_reference)
    dict = constraint_storage(m, v, set)
    dict[ref] = v.variable
    ref
end
function setvariablebound!(m::CplexSolverInstance, col::Int, bound::Float64, sense::Cchar)
    cpx_set_variable_bounds!(m.inner, [col], [bound], [sense])
end
function setvariablebound!(m::CplexSolverInstance, v::MOI.SingleVariable, set::LE)
    setvariablebound!(m, getcol(m, v), set.upper, Cchar('U'))
end
function setvariablebound!(m::CplexSolverInstance, v::MOI.SingleVariable, set::GE)
    setvariablebound!(m, getcol(m, v), set.lower, Cchar('L'))
end
function setvariablebound!(m::CplexSolverInstance, v::MOI.SingleVariable, set::EQ)
    setvariablebound!(m, getcol(m, v), set.value, Cchar('U'))
    setvariablebound!(m, getcol(m, v), set.value, Cchar('L'))
end
function setvariablebound!(m::CplexSolverInstance, v::MOI.SingleVariable, set::MOI.Interval{Float64})
    setvariablebound!(m, getcol(m, v), set.upper, Cchar('U'))
    setvariablebound!(m, getcols(m, v), set.lower, Cchar('L'))
end

function MOI.getattribute(m::CplexSolverInstance, ::MOI.ConstraintSet, c::MOI.ConstraintReference{MOI.SingleVariable,MOI.LessThan{Float64}})
    vref = m.constraint_mapping[c]::MOI.VariableReference
    ub = cpx_get_variable_upperbound(m.inner, getcol(m, vref))
    return MOI.LessThan{Float64}(ub)
end
function MOI.getattribute(m::CplexSolverInstance, ::MOI.ConstraintSet, c::MOI.ConstraintReference{MOI.SingleVariable,MOI.GreaterThan{Float64}})
    vref = m.constraint_mapping[c]::MOI.VariableReference
    lb = cpx_get_variable_lowerbound(m.inner, getcol(m, vref))
    return MOI.GreaterThan{Float64}(lb)
end
function MOI.getattribute(m::CplexSolverInstance, ::MOI.ConstraintSet, c::MOI.ConstraintReference{MOI.SingleVariable,MOI.EqualTo{Float64}})
    vref = m.constraint_mapping[c]::MOI.VariableReference
    lb = cpx_get_variable_lowerbound(m.inner, getcol(m, vref))
    return MOI.EqualTo{Float64}(lb)
end
function MOI.getattribute(m::CplexSolverInstance, ::MOI.ConstraintSet, c::MOI.ConstraintReference{MOI.SingleVariable,MOI.Interval{Float64}})
    vref = m.constraint_mapping[c]::MOI.VariableReference
    lb = cpx_get_variable_lowerbound(m.inner, getcol(m, vref))
    ub = cpx_get_variable_upperbound(m.inner, getcol(m, vref))
    return MOI.Interval{Float64}(lb, ub)
end

function MOI.getattribute(m::CplexSolverInstance, ::MOI.ConstraintFunction, c::MOI.ConstraintReference{MOI.SingleVariable,T}) where T
    vref = m.constraint_mapping[c]::MOI.VariableReference
    return MOI.SingleVariable(vref)
end

function MOI.addconstraint!(m::CplexSolverInstance, func::Linear, set::T) where T
    addlinearconstraint!(m, func, set)
    m.last_constraint_reference += 1
    ref = MOI.ConstraintReference{Linear, T}(m.last_constraint_reference)
    dict = constraint_storage(m, func, set)
    dict[ref] = num_constr(m.inner)
    return ref
end

function addlinearconstraint!(m::CplexSolverInstance, func::Linear, set::MOI.LessThan{Float64})
    addlinearconstraint!(m, func, Cchar('L'), set.upper)
end
function addlinearconstraint!(m::CplexSolverInstance, func::Linear, set::MOI.GreaterThan{Float64})
    addlinearconstraint!(m, func, Cchar('G'), set.lower)
end
function addlinearconstraint!(m::CplexSolverInstance, func::Linear, set::MOI.EqualTo{Float64})
    addlinearconstraint!(m, func, Cchar('E'), set.value)
end

function addlinearconstraint!(m::CplexSolverInstance, func::Linear, sense::Cchar, rhs)
    if abs(func.constant) > eps(Float64)
        warn("Constant in scalar function moved into set.")
    end
    cpx_add_constraint!(m.inner, getcols(m, func.variables), func.coefficients, sense, rhs - func.constant)
end

function MOI.getattribute(m::CplexSolverInstance, ::MOI.NumberOfConstraints{F, S}) where F where S
    length(constraint_storage(m, F, S))
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
