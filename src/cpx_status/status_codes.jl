#=
    Codes taken from
 https://www.ibm.com/support/knowledgecenter/tr/SSSA5P_12.6.0/ilog.odms.cplex.help/refcallablelibrary/macros/Solution_status_codes.html

    and manually mapped to MathOptInterface status codes.
=#

function getstatussymbol(code::Cint)
    if haskey(STATUS_CODE, code)
        return STATUS_CODE[code]
    else
        error("Status code $(code) not been mapped to CPLEX.jl status")
    end
end
function getterminationstatus(status::Symbol)
    if haskey(TERMINATION_STATUS_MAP, status)
        return TERMINATION_STATUS_MAP[status]
    else
        error("Status $(status) has not been mapped to a MOI termination status.")
    end
end
getterminationstatus(code::Cint) = getterminationstatus(getstatussymbol(code))

const STATUS_CODE = Dict{Cint, Symbol}(
25  => :CPX_STAT_ABORT_DETTIME_LIM,
22  => :CPX_STAT_ABORT_DUAL_OBJ_LIM,
10  => :CPX_STAT_ABORT_IT_LIM,
12  => :CPX_STAT_ABORT_OBJ_LIM,
21  => :CPX_STAT_ABORT_PRIM_OBJ_LIM,
11  => :CPX_STAT_ABORT_TIME_LIM,
13  => :CPX_STAT_ABORT_USER,
# CPX_STAT_CONFLICT_ABORT_CONTRADICTION,
# CPX_STAT_CONFLICT_ABORT_DETTIME_LIM,
# CPX_STAT_CONFLICT_ABORT_IT_LIM,
# CPX_STAT_CONFLICT_ABORT_MEM_LIM,
# CPX_STAT_CONFLICT_ABORT_NODE_LIM,
# CPX_STAT_CONFLICT_ABORT_OBJ_LIM,
# CPX_STAT_CONFLICT_ABORT_TIME_LIM,
# CPX_STAT_CONFLICT_ABORT_USER,
# CPX_STAT_CONFLICT_FEASIBLE,
# CPX_STAT_CONFLICT_MINIMAL,
# CPX_STAT_FEASIBLE,
# CPX_STAT_FEASIBLE_RELAXED_INF,
# CPX_STAT_FEASIBLE_RELAXED_QUAD,
# CPX_STAT_FEASIBLE_RELAXED_SUM,
# CPX_STAT_FIRSTORDER,
3   => :CPX_STAT_INFEASIBLE,
4   => :CPX_STAT_INForUNBD,
6   => :CPX_STAT_NUM_BEST,
1   => :CPX_STAT_OPTIMAL,
20  => :CPX_STAT_OPTIMAL_FACE_UNBOUNDED,
5   => :CPX_STAT_OPTIMAL_INFEAS,
# CPX_STAT_OPTIMAL_RELAXED_INF,
# CPX_STAT_OPTIMAL_RELAXED_QUAD,
# CPX_STAT_OPTIMAL_RELAXED_SUM,
2   => :CPX_STAT_UNBOUNDED
)
const TERMINATION_STATUS_MAP = Dict(
:CPX_STAT_ABORT_DETTIME_LIM            => MOI.TimeLimit,
:CPX_STAT_ABORT_DUAL_OBJ_LIM           => MOI.ObjectiveLimit,
:CPX_STAT_ABORT_IT_LIM                 => MOI.IterationLimit,
:CPX_STAT_ABORT_OBJ_LIM                => MOI.ObjectiveLimit,
:CPX_STAT_ABORT_PRIM_OBJ_LIM           => MOI.ObjectiveLimit,
:CPX_STAT_ABORT_TIME_LIM               => MOI.TimeLimit,
:CPX_STAT_ABORT_USER                   => MOI.Interrupted,
# :CPX_STAT_CONFLICT_ABORT_CONTRADICTION => MOI.
# :CPX_STAT_CONFLICT_ABORT_DETTIME_LIM   => MOI.
# :CPX_STAT_CONFLICT_ABORT_IT_LIM        => MOI.
# :CPX_STAT_CONFLICT_ABORT_MEM_LIM       => MOI.
# :CPX_STAT_CONFLICT_ABORT_NODE_LIM      => MOI.
# :CPX_STAT_CONFLICT_ABORT_OBJ_LIM       => MOI.
# :CPX_STAT_CONFLICT_ABORT_TIME_LIM      => MOI.
# :CPX_STAT_CONFLICT_ABORT_USER          => MOI.
# :CPX_STAT_CONFLICT_FEASIBLE            => MOI.
# :CPX_STAT_CONFLICT_MINIMAL             => MOI.
# :CPX_STAT_FEASIBLE                     => MOI.
# :CPX_STAT_FEASIBLE_RELAXED_INF         => MOI.
# :CPX_STAT_FEASIBLE_RELAXED_QUAD        => MOI.
# :CPX_STAT_FEASIBLE_RELAXED_SUM         => MOI.
# :CPX_STAT_FIRSTORDER                   => MOI.
:CPX_STAT_INFEASIBLE                   => MOI.InfeasibleNoResult, # improve
:CPX_STAT_INForUNBD                    => MOI.InfeasibleOrUnbounded,
:CPX_STAT_NUM_BEST                     => MOI.NumericalError,
:CPX_STAT_OPTIMAL                      => MOI.Success,
:CPX_STAT_OPTIMAL_FACE_UNBOUNDED       => MOI.UnboundedNoResult, # improve
:CPX_STAT_OPTIMAL_INFEAS               => MOI.NumericalError,
# :CPX_STAT_OPTIMAL_RELAXED_INF          => MOI.
# :CPX_STAT_OPTIMAL_RELAXED_QUAD         => MOI.
# :CPX_STAT_OPTIMAL_RELAXED_SUM          => MOI.
:CPX_STAT_UNBOUNDED                    => MOI.UnboundedNoResult # improve
)

const PRIMAL_STATUS_MAP = Dict(
:CPX_STAT_ABORT_DETTIME_LIM            => MOI.UnknownResultStatus,
:CPX_STAT_ABORT_DUAL_OBJ_LIM           => MOI.UnknownResultStatus,
:CPX_STAT_ABORT_IT_LIM                 => MOI.UnknownResultStatus,
:CPX_STAT_ABORT_OBJ_LIM                => MOI.UnknownResultStatus,
:CPX_STAT_ABORT_PRIM_OBJ_LIM           => MOI.UnknownResultStatus,
:CPX_STAT_ABORT_TIME_LIM               => MOI.UnknownResultStatus,
:CPX_STAT_ABORT_USER                   => MOI.UnknownResultStatus,
# :CPX_STAT_CONFLICT_ABORT_CONTRADICTION => MOI.UnknownResultStatus,
# :CPX_STAT_CONFLICT_ABORT_DETTIME_LIM   => MOI.UnknownResultStatus,
# :CPX_STAT_CONFLICT_ABORT_IT_LIM        => MOI.UnknownResultStatus,
# :CPX_STAT_CONFLICT_ABORT_MEM_LIM       => MOI.UnknownResultStatus,
# :CPX_STAT_CONFLICT_ABORT_NODE_LIM      => MOI.UnknownResultStatus,
# :CPX_STAT_CONFLICT_ABORT_OBJ_LIM       => MOI.UnknownResultStatus,
# :CPX_STAT_CONFLICT_ABORT_TIME_LIM      => MOI.UnknownResultStatus,
# :CPX_STAT_CONFLICT_ABORT_USER          => MOI.UnknownResultStatus,
# :CPX_STAT_CONFLICT_FEASIBLE            => MOI.UnknownResultStatus,
# :CPX_STAT_CONFLICT_MINIMAL             => MOI.UnknownResultStatus,
# :CPX_STAT_FEASIBLE                     => MOI.UnknownResultStatus,
# :CPX_STAT_FEASIBLE_RELAXED_INF         => MOI.UnknownResultStatus,
# :CPX_STAT_FEASIBLE_RELAXED_QUAD        => MOI.UnknownResultStatus,
# :CPX_STAT_FEASIBLE_RELAXED_SUM         => MOI.UnknownResultStatus,
# :CPX_STAT_FIRSTORDER                   => MOI.UnknownResultStatus,
:CPX_STAT_INFEASIBLE                   => MOI.UnknownResultStatus, # improve
:CPX_STAT_INForUNBD                    => MOI.UnknownResultStatus,
:CPX_STAT_NUM_BEST                     => MOI.UnknownResultStatus,
:CPX_STAT_OPTIMAL                      => MOI.UnknownResultStatus,
:CPX_STAT_OPTIMAL_FACE_UNBOUNDED       => MOI.UnknownResultStatus, # improve
:CPX_STAT_OPTIMAL_INFEAS               => MOI.UnknownResultStatus,
# :CPX_STAT_OPTIMAL_RELAXED_INF          => MOI.UnknownResultStatus,
# :CPX_STAT_OPTIMAL_RELAXED_QUAD         => MOI.UnknownResultStatus,
# :CPX_STAT_OPTIMAL_RELAXED_SUM          => MOI.UnknownResultStatus,
:CPX_STAT_UNBOUNDED                    => MOI.UnknownResultStatus # improve
)
