"""
    Get a vector of column indices given a vector of variable references
"""
function getcol(m::CplexSolverInstance, ref::VariableReference)
    m.variable_mapping[ref.value]
end
getcols(m, ref::Vector{VariableReference}) = getcol.(m, ref)

function MOI.getattribute(m::CplexSolverInstance, ::MOI.NumberOfVariables)
    return cpx_number_variables(m.inner)
end

#=
    Add a variable to the CplexSolverInstance

Returns a MathOptInterface VariableReference. So we need to increment the
variable reference counter in the m.variablemapping, and store the column number
in the dictionary
=#
function MOI.addvariable!(m::CplexSolverInstance)
    cpx_add_variables!(m.inner, 1)
    # assumes we add columns linearly
    m.last_variable_reference += 1
    ref = MOI.VariableReference(m.last_variable_reference)
    m.variable_mapping[ref] = getattribute(m, MOI.NumberOfVariables())
    return ref
end

function MOI.addvariables!(m::CplexSolverInstance, n::Int)
    previous_vars = getattribute(m, MOI.NumberOfVariables())
    cpx_add_variables!(m.inner, n)
    variable_references = MOI.VariableReference[]
    sizehint!(varref, n)
    for i in 1:n
        # assumes we add columns linearly
        m.last_variable_reference += 1
        ref = MOI.VariableReference(m.last_variable_reference)
        push!(variable_references, ref)
        m.variable_mapping[ref] = previous_vars + i
    end
    return variable_references
end

"""
    We assume a VariableReference is valid if it exists in the mapping, and returns
    a column between 1 and the number of variables in the model.
"""
function MOI.isvalid(m::CplexSolverInstance, ref::VariableReference)
    if haskey(m.variable_mapping.refmap, ref.value)
        column = m.variable_mapping.refmap[ref.value]
        if column > 0 && column <= getattribute(m, MOI.NumberOfVariables())
            return true
        end
    end
    return false
end

"""
    Set bounds on variable
"""
function MOI.addconstraint!(m::CplexSolverInstance, v::SingleVariable, set)
    setvariablebound!(m, v, set)
    m.last_constraint_reference += 1
    ref = ConstraintReference{SingleVariable, typeof(set)}(m.last_constraint_reference)
    m.constraint_mapping[ref] = v.variable
    ref
end
function setvariablebound!(m::CplexSolverInstance, col::Int, bound::Float64, sense::Cchar)
    cpx_set_variable_bounds!(m.inner, [col], [bound], [sense])
end
function setvariablebound!(m::CplexSolverInstance, v::SingleVariable, set::LessThan{Float64})
    setvariablebound!(m, getcol(m, v), set.upper, Cchar('U'))
end
function setvariablebound!(m::CplexSolverInstance, v::SingleVariable, set::GreaterThan{Float64})
    setvariablebounds!(m, getcol(m, v), set.lower, Cchar('L'))
end
function setvariablebound!(m::CplexSolverInstance, v::SingleVariable, set::EqualsTo{Float64})
    setvariablebound!(m, getcol(m, v), set.value, Cchar('U'))
    setvariablebound!(m, getcol(m, v), set.value, Cchar('L'))
end
function setvariablebound!(m::CplexSolverInstance, v::SingleVariable, set::Interval{Float64})
    setvariablebound!(m, getcol(m, v), set.upper, Cchar('U'))
    setvariablebound!(m, getcols(m, v), set.lower, Cchar('L'))
end

function MOI.getattribute(m::CplexSolverInstance, ::ConstraintSet, c::ConstraintReference{SingleVariable,LessThan{Float64}})
    vref = m.constraint_mapping[c]::VariableReference
    ub = cpx_get_variable_upperbound(m.inner, getcol(m, vref))
    return LessThan{Float64}(ub)
end
function MOI.getattribute(m::CplexSolverInstance, ::ConstraintSet, c::ConstraintReference{SingleVariable,GreaterThan{Float64}})
    vref = m.constraint_mapping[c]::VariableReference
    lb = cpx_get_variable_lowerbound(m.inner, getcol(m, vref))
    return GreaterThan{Float64}(lb)
end
function MOI.getattribute(m::CplexSolverInstance, ::ConstraintSet, c::ConstraintReference{SingleVariable,EqualsTo{Float64}})
    vref = m.constraint_mapping[c]::VariableReference
    lb = cpx_get_variable_lowerbound(m.inner, getcol(m, vref))
    return EqualsTo{Float64}(lb)
end
function MOI.getattribute(m::CplexSolverInstance, ::ConstraintSet, c::ConstraintReference{SingleVariable,Interval{Float64}})
    vref = m.constraint_mapping[c]::VariableReference
    lb = cpx_get_variable_lowerbound(m.inner, getcol(m, vref))
    ub = cpx_get_variable_upperbound(m.inner, getcol(m, vref))
    return Interval{Float64}(lb, ub)
end

function MOI.getattribute(m::CplexSolverInstance, ::ConstraintFunction, c::ConstraintReference{SingleVariable,T}) where T <: Union{LessThan{Float64}, GreaterThan{Float64}, EqualsTo{Float64}, Interval{Float64}}
    vref = m.constraint_mapping[c]::VariableReference
    return SingleVariable(vref)
end
