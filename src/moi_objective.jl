#=
    Set the objective
=#

function MOI.setobjective!(m::CplexSolverInstance, sense::MOI.OptimizationSense, objf::Linear)
    cpx_chgobj!(m.inner, getcol.(m, objf.variables), objf.coefficients)
    setsense!(m, sense)
    m.objective_constant = objf.constant
    nothing
end

#=
    Set the objective sense
=#

function setsense!(m::CplexSolverInstance, sense::MOI.OptimizationSense)
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

MOI.getattribute(m::CplexSolverInstance,::MOI.Sense) = cpx_getobjsen(m.inner)
MOI.cangetattribute(m::CplexSolverInstance, ::MOI.Sense) = true

#=
    Get the objective function
=#

function MOI.getattribute(m::CplexSolverInstance, ::MOI.ObjectiveFunction)
    variable_coefficients = cpx_getobj(m.inner)
    MOI.ScalarAffineFunction(m.variable_references, variable_coefficients, m.objective_constant)
end
MOI.cangetattribute(m::CplexSolverInstance, ::MOI.ObjectiveFunction) = true

#=
    Modify objective function
=#

function MOI.modifyobjective!(m::CplexSolverInstance, chg::MOI.ScalarCoefficientChange{Float64})
    col = m.variable_mapping[chg.variable]
    # 0 row is the objective
    cpx_chgcoef!(m.inner, 0, col, chg.new_coefficient)
end
