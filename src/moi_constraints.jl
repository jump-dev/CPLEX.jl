
constraint_storage(m::CplexSolverInstance, func::MOI.AbstractScalarFunction, set::MOI.AbstractSet) = constraint_storage(m, typeof(func), typeof(set))
constraint_storage(m::CplexSolverInstance, ::Type{Linear}, ::Type{LE}) = m.constraint_mapping.less_than
constraint_storage(m::CplexSolverInstance, ::Type{Linear}, ::Type{GE}) = m.constraint_mapping.greater_than
constraint_storage(m::CplexSolverInstance, ::Type{Linear}, ::Type{EQ}) = m.constraint_mapping.equal_to

constraint_storage(m::CplexSolverInstance, ::Type{MOI.SingleVariable}, ::Type{LE}) = m.constraint_mapping.variable_upper_bound
constraint_storage(m::CplexSolverInstance, ::Type{MOI.SingleVariable}, ::Type{GE}) = m.constraint_mapping.variable_lower_bound
constraint_storage(m::CplexSolverInstance, ::Type{MOI.SingleVariable}, ::Type{EQ}) = m.constraint_mapping.fixed_variables
constraint_storage(m::CplexSolverInstance, ::Type{MOI.SingleVariable}, ::Type{MOI.Interval{Float64}}) = m.constraint_mapping.interval_variables
constraint_storage(m::CplexSolverInstance, c::MOI.ConstraintReference{F, S}) where F where S = constraint_storage(m, F, S)
function constraint_storage_value(m::CplexSolverInstance, c::MOI.ConstraintReference{F, S}) where F where S
    dict = constraint_storage(m, c)
    return dict[c]
end
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
    setvariablebound!(m, getcol(m, v), set.lower, Cchar('L'))
end

function MOI.getattribute(m::CplexSolverInstance, ::MOI.ConstraintSet, c::MOI.ConstraintReference{MOI.SingleVariable,T}) where T <: Union{LE, GE, EQ}
    varref = constraint_storage_value(m, c)
    val = get_bound_value(m, varref, T)
    return T(val)
end

function get_bound_value(m::CplexSolverInstance, v::MOI.VariableReference, ::Type{LE})
    cpx_get_variable_upperbound(m.inner, getcol(m, v))
end
function get_bound_value(m::CplexSolverInstance, v::MOI.VariableReference, ::Type{GE})
    cpx_get_variable_lowerbound(m.inner, getcol(m, v))
end
function get_bound_value(m::CplexSolverInstance, v::MOI.VariableReference, ::Type{EQ})
    cpx_get_variable_lowerbound(m.inner, getcol(m, v))
end
function MOI.getattribute(m::CplexSolverInstance, ::MOI.ConstraintSet, c::MOI.ConstraintReference{MOI.SingleVariable,MOI.Interval{Float64}})
    varref = constraint_storage_value(m, c)
    lb = cpx_get_variable_lowerbound(m.inner, getcol(m, varref))
    ub = cpx_get_variable_upperbound(m.inner, getcol(m, varref))
    return Interval{Float64}(lb, ub)
end

MOI.cangetattribute(m::CplexSolverInstance, ::MOI.ConstraintSet, c::MOI.ConstraintReference{MOI.SingleVariable,T}) where T <: Union{LE, GE, EQ, MOI.Interval{Float64}} = true

function MOI.getattribute(m::CplexSolverInstance, ::MOI.ConstraintFunction, c::MOI.ConstraintReference{MOI.SingleVariable,T}) where T
    vref = constraint_storage_value(m, c)
    return MOI.SingleVariable(vref)
end
MOI.cangetattribute(m::CplexSolverInstance, ::MOI.ConstraintFunction, c::MOI.ConstraintReference{MOI.SingleVariable,T}) where T <: Union{LE, GE, EQ, MOI.Interval{Float64}} = true


"""
    Add linear constraints
"""
function MOI.addconstraint!(m::CplexSolverInstance, func::Linear, set::T) where T
    addlinearconstraint!(m, func, set)
    m.last_constraint_reference += 1
    ref = MOI.ConstraintReference{Linear, T}(m.last_constraint_reference)
    dict = constraint_storage(m, func, set)
    dict[ref] = cpx_number_constraints(m.inner)
    push!(m.constraint_primal_solution, NaN)
    push!(m.constraint_dual_solution, NaN)
    return ref
end

function addlinearconstraint!(m::CplexSolverInstance, func::Linear, set::LE)
    addlinearconstraint!(m, func, Cchar('L'), set.upper)
end
function addlinearconstraint!(m::CplexSolverInstance, func::Linear, set::GE)
    addlinearconstraint!(m, func, Cchar('G'), set.lower)
end
function addlinearconstraint!(m::CplexSolverInstance, func::Linear, set::EQ)
    addlinearconstraint!(m, func, Cchar('E'), set.value)
end

function addlinearconstraint!(m::CplexSolverInstance, func::Linear, sense::Cchar, rhs)
    if abs(func.constant) > eps(Float64)
        warn("Constant in scalar function moved into set.")
    end
    cpx_addrows!(m.inner, getcols(m, func.variables), func.coefficients, sense, rhs - func.constant)
end

function MOI.getattribute(m::CplexSolverInstance, ::MOI.NumberOfConstraints{F, S}) where F where S
    length(constraint_storage(m, F, S))
end
MOI.cangetattribute(m::CplexSolverInstance, ::MOI.NumberOfConstraints{F, S}) where F where S = true

function MOI.getattribute(m::CplexSolverInstance, ::MOI.ConstraintSet, c::MOI.ConstraintReference{Linear,T}) where T <: Union{LE, GE, EQ}
    row = constraint_storage_value(m, c)::Int
    rhs = cpx_get_rhs(m.inner, row)
    T(rhs)
end
MOI.cangetattribute(m::CplexSolverInstance, ::MOI.ConstraintSet, ::MOI.ConstraintReference{Linear,T}) where T <: Union{LE, GE, EQ} = true

function MOI.getattribute(m::CplexSolverInstance, ::MOI.ConstraintFunction, c::MOI.ConstraintReference{Linear, S}) where S
    row = constraint_storage_value(m, c)
    # TODO more efficiently
    colidx, coefs = cpx_getrows(m.inner, row)
    MOI.ScalarAffineFunction(m.variable_references[colidx+1] , coefs, 0.0)
end

function MOI.cangetattribute(m::CplexSolverInstance, ::MOI.ConstraintFunction, c::MOI.ConstraintReference{F, S}) where F where S
    true
end
"""
    modifyconstraint
"""
function MOI.modifyconstraint!(m::CplexSolverInstance, c::MOI.ConstraintReference{Linear, S}, chg::MOI.ScalarCoefficientChange{Float64}) where S
    col = m.variable_mapping[chg.variable]
    row = constraint_storage_value(m, c)
    cpx_chgcoef(m.inner, row, col, chg.new_coefficient)
end

function MOI.modifyconstraint!(m::CplexSolverInstance, c::MOI.ConstraintReference{MOI.SingleVariable, S}, newset::S) where S
    vref = constraint_storage_value(m, c)
    setvariablebound!(m, MOI.SingleVariable(vref), newset)
end

function _shift_constraintrows!(dict::Dict, deleted_row::Int)
    for (key, val) in dict
        if val > deleted_row
            dict[key] -= 1
        end
    end
end
function _shift_constraintrows!(m::CplexSolverInstance, deleted_row::Int)
    _shift_constraintrows!(m.constraint_mapping.less_than, deleted_row)
    _shift_constraintrows!(m.constraint_mapping.greater_than, deleted_row)
    _shift_constraintrows!(m.constraint_mapping.equal_to, deleted_row)
end
function MOI.delete!(m::CplexSolverInstance, c::MOI.ConstraintReference{Linear, S}) where S
    dict = constraint_storage(m, c)
    row = dict[c]
    cpx_delrows(m.inner, row, row)
    _shift_constraintrows!(m, row)
    deleteat!(m.constraint_primal_solution, row)
    deleteat!(m.constraint_dual_solution, row)
    delete!(dict, c)
end

function MOI.delete!(m::CplexSolverInstance, c::MOI.ConstraintReference{MOI.SingleVariable, S}) where S
    dict = constraint_storage(m, c)
    vref = dict[c]
    setvariablebound!(m, MOI.SingleVariable(vref), MOI.Interval{Float64}(-Inf, Inf))
    delete!(dict, c)
end
