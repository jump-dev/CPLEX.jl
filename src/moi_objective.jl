#=
    Set the objective
=#

function MOI.setobjective!(m::CplexSolverInstance, sense::MOI.OptimizationSense, objf::Linear)
    if m.obj_is_quad
        # previous objective was quadratic...
        m.obj_is_quad = false
        # zero quadratic part
        cpx_copyquad!(m.inner, Int[], Int[], Float64[])
    end
    cpx_chgobj!(m.inner, getcol.(m, objf.variables), objf.coefficients)
    _setsense!(m, sense)
    m.objective_constant = objf.constant
    nothing
end

#=
    Set the objective sense
=#

function _setsense!(m::CplexSolverInstance, sense::MOI.OptimizationSense)
    if sense == MOI.MinSense
        cpx_chgobjsen!(m.inner, :Min)
    elseif sense == MOI.MaxSense
        cpx_chgobjsen!(m.inner, :Max)
    elseif sense == MOI.FeasibilitySense
        warn("FeasibilitySense not supported. Using MinSense")
        cpx_chgobjsen!(m.inner, :Min)
    else
        error("Sense $(sense) unknown.")
    end
end

#=
    Get the objective sense
=#

MOI.getattribute(m::CplexSolverInstance,::MOI.ObjectiveSense) = cpx_getobjsen(m.inner)
MOI.cangetattribute(m::CplexSolverInstance, ::MOI.ObjectiveSense) = true

#=
    Get the objective function
=#

function MOI.getattribute(m::CplexSolverInstance, ::MOI.ObjectiveFunction)
    variable_coefficients = cpx_getobj(m.inner)
    MOI.ScalarAffineFunction(m.variable_references, variable_coefficients, m.objective_constant)
end
# can't get quadratic objective functions
MOI.cangetattribute(m::CplexSolverInstance, ::MOI.ObjectiveFunction) = !m.obj_is_quad

#=
    Modify objective function
=#

function MOI.modifyobjective!(m::CplexSolverInstance, chg::MOI.ScalarCoefficientChange{Float64})
    col = m.variable_mapping[chg.variable]
    # 0 row is the objective
    cpx_chgcoef!(m.inner, 0, col, chg.new_coefficient)
end
MOI.canmodifyobjective(m::CplexSolverInstance, chg::MOI.ScalarCoefficientChange{Float64}) = true

#=
    Set quadratic objective
=#

function MOI.setobjective!(m::CplexSolverInstance, sense::MOI.OptimizationSense, objf::Quad)
    m.obj_is_quad = true
    cpx_chgobj!(m.inner,
        getcol.(m, objf.affine_variables),
        objf.affine_coefficients
    )
    cpx_copyquad!(m.inner,
        getcol.(m, objf.quadratic_rowvariables),
        getcol.(m, objf.quadratic_colvariables),
        objf.quadratic_coefficients
    )
    _setsense!(m, sense)
    m.objective_constant = objf.constant
    nothing
end
