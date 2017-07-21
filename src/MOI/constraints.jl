function addlinearconstraint!(m::CplexSolverInstance, func::ScalarAffineFunction{Float64}, sense, rhs)
    add_constrs!(m.inner, [Cint(1)], ivec(getcols(m, func.variables)), fvec(func.coefficients), [Cchar(sense)], [Cdouble(rhs - func.constant)])

    m.constraint_mapping.last += 1
    m.constraint_mapping.refmap[m.constraint_mapping.last] = num_constr(m.inner)
    return MOI.Constraintference(m.constraint_mapping.last)
end

MOI.addconstraint!(m::CplexSolverInstance, func::ScalarAffineFunction{Float64}, set::LessThan{Float64}) = addlinearconstraint!(m, func, 'L', set.upper)
MOI.addconstraint!(m::CplexSolverInstance, func::ScalarAffineFunction{Float64}, set::GreaterThan{Float64}) = addlinearconstraint!(m, func, 'G', set.lower)
MOI.addconstraint!(m::CplexSolverInstance, func::ScalarAffineFunction{Float64}, set::EqualsTo{Float64}) = addlinearconstraint!(m, func, 'E', set.value)
