const MOI = MathOptInterface

export CplexSolver

struct CplexSolver <: MOI.AbstractSolver
    mipstart_effortlevel::Cint
    options
end
function CplexSolver(;mipstart_effortlevel::Cint = CPX_MIPSTART_AUTO, options...)
    CplexSolver(mipstart_effortlevel, options)
end

const SUPPORTED_OBJECTIVES = [
    # ScalarAffineFunction{Float64},
    # ScalarQuadraticFunction{Float64}
]
const SUPPORTED_CONSTRAINTS = [
    (ScalarAffineFunction{Float64}, EqualsTo{Float64}),
    (ScalarAffineFunction{Float64}, LessThan{Float64}),
    (ScalarAffineFunction{Float64}, GreaterThan{Float64}),
    (SingleVariable, EqualsTo{Float64}),
    (SingleVariable, LessThan{Float64}),
    (SingleVariable, GreaterThan{Float64}),
    (SingleVariable, Interval{Float64})
]

function MOI.supportsproblem(s::CplexSolver, objective_type, constraint_types)
    if !(objective_type in SUPPORTED_OBJECTIVES)
        return false
    end
    for c in constraint_types
        if !(c in SUPPORTED_CONSTRAINTS)
            return false
        end
    end
    return true
end

mutable struct CplexSolverInstance <: MOI.AbstractSolverInstance
    inner::Model
    last_variable_reference::UInt64
    variable_mapping::Dict{VariableReference, Int}

    last_constraint_reference::UInt64
    constraint_mapping::Dict{ConstraintRef, Any}

    # callbacks not yet dealt with
    # solvetime::Float64
    # mipstart_effortlevel::Cint
    # heuristic_buffer::Vector{Float64}
end

function MOI.SolverInstance(s::CplexSolver)
    env = Env()
    set_param!(env, "CPX_PARAM_SCRIND", 1) # output logs to stdout by default
    for (name,value) in s.options
        set_param!(env, string(name), value)
    end
    CplexSolverInstance(Model(env), 0, Dict{VariableReference, Int}(), 0, Dict{ConstraintRef, Any}())
end

function MOI.optimize!(m::CplexSolverInstance)
    # start = time()
    optimize!(m.inner)
    # m.solvetime = time() - start
end

function MOI.free!(m::CplexSolverInstance)
end
