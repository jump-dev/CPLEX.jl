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


const STATUS_CODE = Dict(
    1   => :CPX_STAT_OPTIMAL,
    2   => :CPX_STAT_UNBOUNDED,
    3   => :CPX_STAT_INFEASIBLE,
    4   => :CPX_STAT_INForUNBD,
    5   => :CPX_STAT_OPTIMAL_INFEAS,
    6   => :CPX_STAT_NUM_BEST,
    10  => :CPX_STAT_ABORT_IT_LIM,
    11  => :CPX_STAT_ABORT_TIME_LIM,
    12  => :CPX_STAT_ABORT_OBJ_LIM,
    13  => :CPX_STAT_ABORT_USER,
    20  => :CPX_STAT_OPTIMAL_FACE_UNBOUNDED,
    21  => :CPX_STAT_ABORT_PRIM_OBJ_LIM,
    22  => :CPX_STAT_ABORT_DUAL_OBJ_LIM,
    101 => :CPXMIP_OPTIMAL,
    102 => :CPXMIP_OPTIMAL_TOL,
    103 => :CPXMIP_INFEASIBLE,
    104 => :CPXMIP_SOL_LIM,
    105 => :CPXMIP_NODE_LIM_FEAS,
    106 => :CPXMIP_NODE_LIM_INFEAS,
    107 => :CPXMIP_TIME_LIM_FEAS,
    108 => :CPXMIP_TIME_LIM_INFEAS,
    109 => :CPXMIP_FAIL_FEAS,
    110 => :CPXMIP_FAIL_INFEAS,
    111 => :CPXMIP_MEM_LIM_FEAS,
    112 => :CPXMIP_MEM_LIM_INFEAS,
    113 => :CPXMIP_ABORT_FEAS,
    114 => :CPXMIP_ABORT_INFEAS,
    115 => :CPXMIP_OPTIMAL_INFEAS,
    116 => :CPXMIP_FAIL_FEAS_NO_TREE,
    117 => :CPXMIP_FAIL_INFEAS_NO_TREE,
    118 => :CPXMIP_UNBOUNDED,
    119 => :CPXMIP_INForUNBD
)

const TERMINATION_STATUS_MAP = Dict(
    :CPX_STAT_OPTIMAL                => MOI.Success,
    :CPX_STAT_UNBOUNDED              => MOI.UnboundedNoResult,
    :CPX_STAT_INFEASIBLE             => MOI.InfeasibleNoResult,
    :CPX_STAT_INForUNBD              => MOI.InfeasibleOrUnbounded,
    :CPX_STAT_OPTIMAL_INFEAS         => MOI.Success,
    :CPX_STAT_NUM_BEST               => MOI.NumericalError,
    :CPX_STAT_ABORT_IT_LIM           => MOI.IterationLimit,
    :CPX_STAT_ABORT_TIME_LIM         => MOI.TimeLimit,
    :CPX_STAT_ABORT_OBJ_LIM          => MOI.ObjectiveLimit,
    :CPX_STAT_ABORT_USER             => MOI.Interrupted,
    :CPX_STAT_OPTIMAL_FACE_UNBOUNDED => MOI.UnboundedNoResult,
    :CPX_STAT_ABORT_PRIM_OBJ_LIM     => MOI.ObjectiveLimit,
    :CPX_STAT_ABORT_DUAL_OBJ_LIM     => MOI.ObjectiveLimit,
    :CPXMIP_OPTIMAL                  => MOI.Success,
    :CPXMIP_OPTIMAL_TOL              => MOI.Success,
    :CPXMIP_INFEASIBLE               => MOI.InfeasibleNoResult,
    :CPXMIP_SOL_LIM                  => MOI.SolutionLimit,
    :CPXMIP_NODE_LIM_FEAS            => MOI.NodeLimit,
    :CPXMIP_NODE_LIM_INFEAS          => MOI.NodeLimit,
    :CPXMIP_TIME_LIM_FEAS            => MOI.TimeLimit,
    :CPXMIP_TIME_LIM_INFEAS          => MOI.TimeLimit,
    :CPXMIP_FAIL_FEAS                => MOI.OtherError,
    :CPXMIP_FAIL_INFEAS              => MOI.OtherError,
    :CPXMIP_MEM_LIM_FEAS             => MOI.MemoryLimit,
    :CPXMIP_MEM_LIM_INFEAS           => MOI.MemoryLimit,
    :CPXMIP_ABORT_FEAS               => MOI.Interrupted,
    :CPXMIP_ABORT_INFEAS             => MOI.Interrupted,
    :CPXMIP_OPTIMAL_INFEAS           => MOI.Success,
    :CPXMIP_FAIL_FEAS_NO_TREE        => MOI.MemoryLimit,
    :CPXMIP_FAIL_INFEAS_NO_TREE      => MOI.MemoryLimit,
    :CPXMIP_UNBOUNDED                => MOI.UnboundedNoResult,
    :CPXMIP_INForUNBD                => MOI.InfeasibleOrUnbounded
)
