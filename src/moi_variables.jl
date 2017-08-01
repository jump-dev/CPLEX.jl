
"""
    Get a vector of column indices given a vector of variable references
"""
function getcol(m::CplexSolverInstance, ref::MOI.VariableReference)
    m.variable_mapping[ref]
end
getcol(m::CplexSolverInstance, v::MOI.SingleVariable) = getcol(m, v.variable)
getcols(m::CplexSolverInstance, ref::Vector{MOI.VariableReference}) = getcol.(m, ref)

function MOI.getattribute(m::CplexSolverInstance, ::MOI.NumberOfVariables)
    return cpx_getnumcols(m.inner)
end

function getvariables(m::CplexSolverInstance)
    m.variable_references
end
#=
    Add a variable to the CplexSolverInstance

Returns a MathOptInterface VariableReference. So we need to increment the
variable reference counter in the m.variablemapping, and store the column number
in the dictionary
=#
function MOI.addvariable!(m::CplexSolverInstance)
    cpx_newcols!(m.inner, 1)
    # assumes we add columns linearly
    m.last_variable_reference += 1
    ref = MOI.VariableReference(m.last_variable_reference)
    m.variable_mapping[ref] = MOI.getattribute(m, MOI.NumberOfVariables())
    push!(m.variable_references, ref)
    push!(m.variable_primal_solution, NaN)
    push!(m.variable_dual_solution, NaN)
    return ref
end

function MOI.addvariables!(m::CplexSolverInstance, n::Int)
    previous_vars = MOI.getattribute(m, MOI.NumberOfVariables())
    cpx_newcols!(m.inner, n)
    variable_references = MOI.VariableReference[]
    sizehint!(variable_references, n)
    for i in 1:n
        # assumes we add columns linearly
        m.last_variable_reference += 1
        ref = MOI.VariableReference(m.last_variable_reference)
        push!(variable_references, ref)
        m.variable_mapping[ref] = previous_vars + i
        push!(m.variable_references, ref)
        push!(m.variable_primal_solution, NaN)
        push!(m.variable_dual_solution, NaN)
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

function _shift_variablecols!(dict::Dict, deleted_col::Int, ref::MOI.VariableReference)
    for (key, val) in dict
        if val > deleted_col
            dict[key] -= 1
        end
    end
    delete!(dict, ref)
end

function MOI.delete!(m::CplexSolverInstance, ref::MOI.VariableReference)
    col = m.variable_mapping[ref]
    cpx_delcols!(m.inner, col, col)
    deleteat!(m.variable_references, col)
    deleteat!(m.variable_primal_solution, col)
    deleteat!(m.variable_dual_solution, col)
    _shift_variablecols!(m.variable_mapping, col, ref)
    # deleting from a dict without the key does nothing
    delete!(m.constraint_mapping.variable_upper_bound, ref)
    delete!(m.constraint_mapping.variable_lower_bound, ref)
    delete!(m.constraint_mapping.fixed_variables, ref)
    delete!(m.constraint_mapping.interval_variables, ref)

end
