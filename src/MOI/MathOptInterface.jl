using MathOptInterface

const MOI = MathOptInterface

export CplexSolver

struct CplexSolver <: MOI.AbstractSolver
    mipstart_effortlevel::Cint
    options
end
function CplexSolver(;mipstart_effortlevel::Cint = CPX_MIPSTART_AUTO, options...)
    CplexSolver(mipstart_effortlevel, options)
end


const Linear = MOI.ScalarAffineFunction{Float64}
const LE = MOI.LessThan{Float64}
const GE = MOI.GreaterThan{Float64}
const EQ = MOI.EqualTo{Float64}
const LinConstrRef{T} = MOI.ConstraintReference{Linear, T}
const SVConstrRef{T} = MOI.ConstraintReference{MOI.SingleVariable, T}

const SUPPORTED_OBJECTIVES = [
    Linear
    # ScalarQuadraticFunction{Float64}
]

const SUPPORTED_CONSTRAINTS = [
    (Linear, EQ),
    (Linear, LE),
    (Linear, GE),
    (MOI.SingleVariable, EQ),
    (MOI.SingleVariable, LE),
    (MOI.SingleVariable, GE),
    (MOI.SingleVariable, MOI.Interval{Float64})
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

struct ConstraintMapping
    # rows in constraint matrix
    less_than::Dict{LinConstrRef{LE}, Int}
    greater_than::Dict{LinConstrRef{GE}, Int}
    equal_to::Dict{LinConstrRef{EQ}, Int}

    # references to variable
    variable_upper_bound::Dict{SVConstrRef{LE}, MOI.VariableReference}
    variable_lower_bound::Dict{SVConstrRef{GE}, MOI.VariableReference}
    fixed_variables::Dict{SVConstrRef{EQ}, MOI.VariableReference}
    interval_variables::Dict{SVConstrRef{MOI.Interval{Float64}}, MOI.VariableReference}
end
ConstraintMapping() = ConstraintMapping(
    Dict{LinConstrRef{LE}, Int}(),
    Dict{LinConstrRef{GE}, Int}(),
    Dict{LinConstrRef{EQ}, Int}(),
    Dict{SVConstrRef{LE}, MOI.VariableReference}(),
    Dict{SVConstrRef{GE}, MOI.VariableReference}(),
    Dict{SVConstrRef{EQ}, MOI.VariableReference}(),
    Dict{SVConstrRef{MOI.Interval{Float64}}, MOI.VariableReference}()
)

mutable struct CplexSolverInstance <: MOI.AbstractSolverInstance
    inner::Model
    last_variable_reference::UInt64
    variable_mapping::Dict{MOI.VariableReference, Int}

    last_constraint_reference::UInt64
    constraint_mapping::ConstraintMapping
end

function MOI.SolverInstance(s::CplexSolver)
    env = Env()
    set_param!(env, "CPX_PARAM_SCRIND", 1) # output logs to stdout by default
    for (name,value) in s.options
        set_param!(env, string(name), value)
    end
    CplexSolverInstance(
        Model(env),
        0,
        Dict{MOI.VariableReference, Int}(),
        0,
        ConstraintMapping()
    )
end

include("macros_cpx.jl")
include("variables.jl")
include("constraints.jl")
include("objective.jl")
include("solve.jl")
