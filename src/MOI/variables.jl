include("variables_cpx.jl")

"""
    Get a vector of column indices given a vector of variable references
"""
function getcol(m::CplexSolverInstance, ref::MOI.VariableReference)
    m.variable_mapping[ref]
end
getcol(m::CplexSolverInstance, v::MOI.SingleVariable) = getcol(m, v.variable)
getcols(m::CplexSolverInstance, ref::Vector{MOI.VariableReference}) = getcol.(m, ref)

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
    previous_vars = MOI.getattribute(m, MOI.NumberOfVariables())
    cpx_add_variables!(m.inner, n)
    variable_references = MOI.VariableReference[]
    sizehint!(variable_references, n)
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
function MOI.isvalid(m::CplexSolverInstance, ref::MOI.VariableReference)
    if haskey(m.variable_mapping.refmap, ref.value)
        column = m.variable_mapping.refmap[ref.value]
        if column > 0 && column <= MOI.getattribute(m, MOI.NumberOfVariables())
            return true
        end
    end
    return false
end
