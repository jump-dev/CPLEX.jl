
function MOI.setobjective!(m::CplexSolverInstance, sense::MOI.OptimizationSense, objf::Linear)
    cpx_set_objective!(m.inner, getcols(m, objf.variables), objf.coefficients)
    setsense!(m, sense)
    m.objective_constant = objf.constant
    nothing
end

function setsense!(m::CplexSolverInstance, sense::MOI.OptimizationSense)
    if sense == MOI.MinSense
        cpx_set_sense!(m.inner, :Min)
    elseif sense == MOI.MaxSense
        cpx_set_sense!(m.inner, :Max)
    elseif sense == MOI.FeasibilitySense
        warn("FeasibilitySense not supported. Using MinSense")
        cpx_set_sense!(m.inner, :Min)
    else
        error("Sense $(sense) unknown.")
    end
end

function MOI.getattribute(m::CplexSolverInstance,::MOI.Sense)
    cpx_get_sense(m.inner)
end

MOI.cangetattribute(m::CplexSolverInstance, ::MOI.ObjectiveFunction) = true
function MOI.getattribute(m::CplexSolverInstance, ::MOI.ObjectiveFunction)
    variable_coefficients = cpx_get_obj(m.inner)
    MOI.ScalarAffineFunction(getvariables(m), variable_coefficients, m.objective_constant)
end
