include("objective_cpx.jl")

function MOI.setobjective!(m::CplexSolverInstance, sense::OptimizationSense, objf::ScalarAffineFunction{Float64})
    cpx_set_objective!(m, getcols.(objf.variables), objf.coefficients)
    setsense!(m, sense)
end

setsense!(m::CplexSolverInstance, ::MinSense) = cpx_set_sense!(m.inner, :Min)
setsense!(m::CplexSolverInstance, ::MaxSense) = cpx_set_sense!(m.inner, :Max)
function setsense!(m::CplexSolverInstance, ::FeasibilitySense)
    warn("FeasibilitySense not supported. Using MinSense")
    cpx_set_sense!(m.inner, :Min)
end

function MOI.getattribute(m::CplexSolverInstance,::Sense)
    cpx_get_sense(m.inner)
end
