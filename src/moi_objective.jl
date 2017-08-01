
function MOI.setobjective!(m::CplexSolverInstance, sense::MOI.OptimizationSense, objf::Linear)
    cpx_chgobj!(m.inner, getcols(m, objf.variables), objf.coefficients)
    setsense!(m, sense)
    m.objective_constant = objf.constant
    nothing
end

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

function MOI.getattribute(m::CplexSolverInstance,::MOI.Sense)
    cpx_getobjsen(m.inner)
end

MOI.cangetattribute(m::CplexSolverInstance, ::MOI.ObjectiveFunction) = true
function MOI.getattribute(m::CplexSolverInstance, ::MOI.ObjectiveFunction)
    variable_coefficients = cpx_getobj(m.inner)
    MOI.ScalarAffineFunction(getvariables(m), variable_coefficients, m.objective_constant)
end

function MOI.modifyobjective!(m::CplexSolverInstance, chg::MOI.ScalarCoefficientChange{Float64})
    col = m.variable_mapping[chg.variable]
    cpx_chgcoef!(m.inner, 0, col, chg.new_coefficient)
end
