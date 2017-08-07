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
    mipstart_effortlevel::Cint
    logfile::String
    options
end
function CplexSolver(;mipstart_effortlevel::Cint = CPX_MIPSTART_AUTO, logfile::String="", options...)
    CplexSolver(mipstart_effortlevel, logfile, options)
end

MOI.getattribute(s::CplexSolver, ::MOI.SupportsDuals) = true
MOI.getattribute(s::CplexSolver, ::MOI.SupportsAddConstraintAfterSolve) = true
MOI.getattribute(s::CplexSolver, ::MOI.SupportsAddVariableAfterSolve) = true
MOI.getattribute(s::CplexSolver, ::MOI.SupportsDeleteConstraint) = true
MOI.getattribute(s::CplexSolver, ::MOI.SupportsDeleteVariable) = true

# functions
const Linear = MOI.ScalarAffineFunction{Float64}
const Quad   = MOI.ScalarQuadraticFunction{Float64}
const SinVar = MOI.SingleVariable
const VecVar = MOI.VectorOfVariables
const VecLin = MOI.VectorAffineFunction{Float64}
# sets
const LE     = MOI.LessThan{Float64}
const GE     = MOI.GreaterThan{Float64}
const EQ     = MOI.EqualTo{Float64}
const IV     = MOI.Interval{Float64}
# constraint references
const CR{F,S} = MOI.ConstraintReference{F,S}
const LCR{S} = CR{Linear,S}
const VLCR{S} = CR{VecLin,S}
const QCR{S} = CR{Quad,S}
const SVCR{S}  = CR{SinVar, S}
const VVCR{S}  = CR{VecVar, S}
# variable reference
const VarRef = MOI.VariableReference

const SUPPORTED_OBJECTIVES = [
    Linear,
    Quad
]

const SUPPORTED_CONSTRAINTS = [
    (Linear, EQ),
    (Linear, LE),
    (Linear, GE),
    (Quad, EQ),
    (Quad, LE),
    (Quad, GE),
    (SinVar, EQ),
    (SinVar, LE),
    (SinVar, GE),
    (SinVar, IV),
    (SinVar, MOI.ZeroOne),
    (SinVar, MOI.Integer),
    (VecVar, MOI.SOS1),
    (VecVar, MOI.SOS2),
    (VecVar, MOI.Nonnegatives),
    (VecVar, MOI.Nonpositives),
    (VecVar, MOI.Zeros),
    (VecLin, MOI.Nonnegatives),
    (VecLin, MOI.Nonpositives),
    (VecLin, MOI.Zeros)
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

    # vectors of rows in constraint matrix
    nonnegatives::Dict{VLCR{MOI.Nonnegatives}, Vector{Int}}
    nonpositives::Dict{VLCR{MOI.Nonpositives}, Vector{Int}}
    zeros::Dict{VLCR{MOI.Zeros}, Vector{Int}}

    # rows in quadratic constraint matrix
    q_less_than::Dict{QCR{LE}, Int}
    q_greater_than::Dict{QCR{GE}, Int}
    q_equal_to::Dict{QCR{EQ}, Int}

    # references to variable
    upper_bound::Dict{SVCR{LE}, VarRef}
    lower_bound::Dict{SVCR{GE}, VarRef}
    fixed_bound::Dict{SVCR{EQ}, VarRef}
    interval_bound::Dict{SVCR{MOI.Interval{Float64}}, VarRef}

    # vectors of rows in constraint matrix
    vv_nonnegatives::Dict{VVCR{MOI.Nonnegatives}, Vector{VarRef}}
    vv_nonpositives::Dict{VVCR{MOI.Nonpositives}, Vector{VarRef}}
    vv_zeros::Dict{VVCR{MOI.Zeros}, Vector{VarRef}}

    integer::Dict{SVCR{MOI.Integer}, VarRef}
    #=
     for some reason CPLEX doesn't respect bounds on a binary variable, so we
     should store the previous bounds so that if we delete the binary constraint
     we can revert to the old bounds
    =#
    binary::Dict{SVCR{MOI.ZeroOne}, Tuple{VarRef, Float64, Float64}}
    sos1::Dict{VVCR{MOI.SOS1}, Int}
    sos2::Dict{VVCR{MOI.SOS2}, Int}
end
ConstraintMapping() = ConstraintMapping(
    Dict{LCR{LE}, Int}(),
    Dict{LCR{GE}, Int}(),
    Dict{LCR{EQ}, Int}(),
    Dict{VLCR{MOI.Nonnegatives}, Vector{Int}}(),
    Dict{VLCR{MOI.Nonpositives}, Vector{Int}}(),
    Dict{VLCR{MOI.Zeros}, Vector{Int}}(),
    Dict{QCR{LE}, Int}(),
    Dict{QCR{GE}, Int}(),
    Dict{QCR{EQ}, Int}(),
    Dict{SVCR{LE}, VarRef}(),
    Dict{SVCR{GE}, VarRef}(),
    Dict{SVCR{EQ}, VarRef}(),
    Dict{SVCR{IV}, VarRef}(),
    Dict{VVCR{MOI.Nonnegatives}, Vector{VarRef}}(),
    Dict{VVCR{MOI.Nonpositives}, Vector{VarRef}}(),
    Dict{VVCR{MOI.Zeros}, Vector{VarRef}}(),
    Dict{SVCR{MOI.Integer}, VarRef}(),
    Dict{SVCR{MOI.ZeroOne}, Tuple{VarRef, Float64, Float64}}(),
    Dict{VVCR{MOI.SOS1}, Int}(),
    Dict{VVCR{MOI.SOS2}, Int}()
)

mutable struct CplexSolverInstance <: MOI.AbstractSolverInstance
    inner::Model

    obj_is_quad::Bool

    last_variable_reference::UInt64
    variable_mapping::Dict{MOI.VariableReference, Int}
    variable_references::Vector{MOI.VariableReference}

    variable_primal_solution::Vector{Float64}
    variable_dual_solution::Vector{Float64}

    last_constraint_reference::UInt64
    constraint_mapping::ConstraintMapping

    constraint_primal_solution::Vector{Float64}
    constraint_dual_solution::Vector{Float64}

    qconstraint_primal_solution::Vector{Float64}
    qconstraint_dual_solution::Vector{Float64}

    objective_constant::Float64

    termination_status::MOI.TerminationStatusCode
    primal_status::MOI.ResultStatusCode
    dual_status::MOI.ResultStatusCode
    primal_result_count::Int
    dual_result_count::Int

    solvetime::Float64
end

function MOI.SolverInstance(s::CplexSolver)
    env = Env()
    cpx_setparam!(env, CPX_PARAM_SCRIND, 1) # output logs to stdout by default
    for (name,value) in s.options
        cpx_setparam!(env, string(name), value)
    end
    csi = CplexSolverInstance(
        Model(env),
        false,
        0,
        Dict{MOI.VariableReference, Int}(),
        MOI.VariableReference[],
        Float64[],
        Float64[],
        0,
        ConstraintMapping(),
        Float64[],
        Float64[],
        Float64[],
        Float64[],
        0.0,
        MOI.OtherError, # not solved
        MOI.UnknownResultStatus,
        MOI.UnknownResultStatus,
        0,
        0,
        0.0
    )
    csi.inner.mipstart_effort = s.mipstart_effortlevel
    if s.logfile != ""
        cpx_setlogfile!(env, s.logfile)
    end
    return csi
end

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

include(joinpath("cpx_defines", "status_codes.jl"))

include("moi_variables.jl")
include("moi_constraints.jl")
include("moi_objective.jl")
include("moi_solve.jl")
