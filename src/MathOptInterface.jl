#=
    TODO

    integer
    quadratic
    sos
    parameters
    unbounded/infeasibility rays
=#
using MathOptInterface

const MOI = MathOptInterface

export CplexSolver

struct CplexSolver <: MOI.AbstractSolver
    options
end
function CplexSolver(;mipstart_effortlevel::Cint = CPX_MIPSTART_AUTO, options...)
    CplexSolver(options)
end

MOI.getattribute(s::CplexSolver, ::MOI.SupportsDuals) = true
MOI.getattribute(s::CplexSolver, ::MOI.SupportsAddConstraintAfterSolve) = true
MOI.getattribute(s::CplexSolver, ::MOI.SupportsAddVariableAfterSolve) = true
MOI.getattribute(s::CplexSolver, ::MOI.SupportsDeleteConstraint) = true
MOI.getattribute(s::CplexSolver, ::MOI.SupportsDeleteVariable) = true

# functions
const Linear = MOI.ScalarAffineFunction{Float64}
const SinVar = MOI.SingleVariable
# sets
const LE     = MOI.LessThan{Float64}
const GE     = MOI.GreaterThan{Float64}
const EQ     = MOI.EqualTo{Float64}
const IV     = MOI.Interval{Float64}
# constraint references
const CR{F,S} = MOI.ConstraintReference{F,S}
const LCR{S} = CR{Linear,S}
const SVCR{S}  = CR{SinVar, S}
# variable reference
const VarRef = MOI.VariableReference

const SUPPORTED_OBJECTIVES = [
    Linear
    # ScalarQuadraticFunction{Float64}
]

const SUPPORTED_CONSTRAINTS = [
    (Linear, EQ),
    (Linear, LE),
    (Linear, GE),
    (SinVar, EQ),
    (SinVar, LE),
    (SinVar, GE),
    (SinVar, IV),
    (SinVar, MOI.ZeroOne),
    (SinVar, MOI.Integer)
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
    less_than::Dict{LCR{LE}, Int}
    greater_than::Dict{LCR{GE}, Int}
    equal_to::Dict{LCR{EQ}, Int}

    # references to variable
    upper_bound::Dict{SVCR{LE}, VarRef}
    lower_bound::Dict{SVCR{GE}, VarRef}
    fixed_bound::Dict{SVCR{EQ}, VarRef}
    interval_bound::Dict{SVCR{MOI.Interval{Float64}}, VarRef}

    integer::Dict{SVCR{MOI.Integer}, VarRef}
    #=
     for some reason CPLEX doesn't respect bounds on a binary variable, so we
     should store the previous bounds so that if we delete the binary constraint
     we can revert to the old bounds
    =#
    binary::Dict{SVCR{MOI.ZeroOne}, Tuple{VarRef, Float64, Float64}}
end
ConstraintMapping() = ConstraintMapping(
    Dict{LCR{LE}, Int}(),
    Dict{LCR{GE}, Int}(),
    Dict{LCR{EQ}, Int}(),
    Dict{SVCR{LE}, VarRef}(),
    Dict{SVCR{GE}, VarRef}(),
    Dict{SVCR{EQ}, VarRef}(),
    Dict{SVCR{IV}, VarRef}(),
    Dict{SVCR{MOI.Integer}, VarRef}(),
    Dict{SVCR{MOI.ZeroOne}, Tuple{VarRef, Float64, Float64}}()
)

mutable struct CplexSolverInstance <: MOI.AbstractSolverInstance
    inner::Model

    last_variable_reference::UInt64
    variable_mapping::Dict{MOI.VariableReference, Int}
    variable_references::Vector{MOI.VariableReference}

    variable_primal_solution::Vector{Float64}
    variable_dual_solution::Vector{Float64}

    last_constraint_reference::UInt64
    constraint_mapping::ConstraintMapping

    constraint_primal_solution::Vector{Float64}
    constraint_dual_solution::Vector{Float64}

    objective_constant::Float64

    termination_status::MOI.TerminationStatusCode
    primal_status::MOI.ResultStatusCode
    dual_status::MOI.ResultStatusCode
    primal_result_count::Int
    dual_result_count::Int
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
        MOI.VariableReference[],
        Float64[],
        Float64[],
        0,
        ConstraintMapping(),
        Float64[],
        Float64[],
        0.0,
        MOI.OtherError, # not solved
        MOI.UnknownResultStatus,
        MOI.UnknownResultStatus,
        0,
        0
    )
end
include(joinpath("cpx_status", "status_codes.jl"))

# a useful helper function
function deleteref!(dict::Dict, i::Int, ref)
    for (key, val) in dict
        if val > i
            dict[key] -= 1
        end
    end
    delete!(dict, ref)
end

function problemtype(m::CplexSolverInstance)
    code = cpx_getprobtype(m.inner)
    PROB_TYPE_MAP[code]
end
include("moi_variables.jl")
include("moi_constraints.jl")
include("moi_objective.jl")
include("moi_solve.jl")
