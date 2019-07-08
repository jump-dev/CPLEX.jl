using LinQuadOptInterface

const LQOI = LinQuadOptInterface
const MOI  = LQOI.MathOptInterface

const SUPPORTED_OBJECTIVES = [
    LQOI.Linear
    LQOI.SinVar
    LQOI.Quad
]

const SUPPORTED_CONSTRAINTS = [
    (LQOI.Linear, LQOI.EQ),
    (LQOI.Linear, LQOI.LE),
    (LQOI.Linear, LQOI.GE),
    (LQOI.SinVar, LQOI.EQ),
    (LQOI.SinVar, LQOI.LE),
    (LQOI.SinVar, LQOI.GE),
    (LQOI.SinVar, LQOI.IV),
    (LQOI.SinVar, MOI.ZeroOne),
    (LQOI.SinVar, MOI.Integer),
    (LQOI.VecVar, MOI.Nonnegatives),
    (LQOI.VecVar, MOI.Nonpositives),
    (LQOI.VecVar, MOI.Zeros),
    (LQOI.VecVar, MOI.SOS1{Float64}),
    (LQOI.VecVar, MOI.SOS2{Float64}),
    (LQOI.VecLin, MOI.Nonnegatives),
    (LQOI.VecLin, MOI.Nonpositives),
    (LQOI.VecLin, MOI.Zeros),
    (LQOI.Quad, LQOI.EQ),
    (LQOI.Quad, LQOI.LE),
    (LQOI.Quad, LQOI.GE)
]

mutable struct Optimizer <: LQOI.LinQuadOptimizer
    LQOI.@LinQuadOptimizerBase
    env::Union{Nothing, Env}
    params::Dict{String, Any}
    conflict::Union{Nothing, ConflictRefinerData}

    """
        Optimizer(env = nothing; kwargs...)

    Create a new Optimizer object.

    You can share CPLEX `Env`s between models by passing an instance of `Env` as
    the first argument. By default, a new environment is created for every
    model.
    """
    function Optimizer(env::Union{Nothing, Env} = nothing; kwargs...)
        model = new()
        model.env = env
        model.params = Dict{String, Any}()
        for (name, value) in kwargs
            model.params[string(name)] = value
        end

        # For consistency with MPB, output logs to stdout by default.
        if !haskey(model.params, "CPX_PARAM_SCRIND") && !haskey(model.params, "CPXPARAM_ScreenOutput")
            model.params["CPX_PARAM_SCRIND"] = 1
        end

        MOI.empty!(model)
        return model
    end
end

# The existing env is `Nothing`, so create a new one.
LQOI.LinearQuadraticModel(::Type{Optimizer}, ::Nothing) = Model(Env())
# The existing env is `Env`, so pass it through.
LQOI.LinearQuadraticModel(::Type{Optimizer}, env::Env) = Model(env)

function MOI.empty!(model::Optimizer)
    MOI.empty!(model, model.env)
    for (name, value) in model.params
        set_param!(model.inner.env, name, value)
    end
    model.conflict = nothing
    return
end

MOI.get(::Optimizer, ::MOI.SolverName) = "CPLEX"

LQOI.supported_constraints(::Optimizer) = SUPPORTED_CONSTRAINTS
LQOI.supported_objectives(::Optimizer)  = SUPPORTED_OBJECTIVES

LQOI.backend_type(model::Optimizer, ::MOI.EqualTo{Float64})     = Cchar('E')
LQOI.backend_type(model::Optimizer, ::MOI.LessThan{Float64})    = Cchar('L')
LQOI.backend_type(model::Optimizer, ::MOI.GreaterThan{Float64}) = Cchar('G')

LQOI.backend_type(model::Optimizer, ::MOI.Zeros)                = Cchar('E')
LQOI.backend_type(model::Optimizer, ::MOI.Nonpositives)         = Cchar('L')
LQOI.backend_type(model::Optimizer, ::MOI.Nonnegatives)         = Cchar('G')

function LQOI.change_variable_bounds!(model::Optimizer,
        columns::Vector{Int}, values::Vector{Float64}, senses::Vector{Cchar})
    c_api_chgbds(model.inner, ivec(columns), senses, values)
    return
end

function LQOI.get_variable_lowerbound(model::Optimizer, column::Int)
    return c_api_getlb(model.inner, Cint(column), Cint(column))[1]
end

function LQOI.get_variable_upperbound(model::Optimizer, column::Int)
    return c_api_getub(model.inner, Cint(column), Cint(column))[1]
end

function LQOI.get_number_linear_constraints(model::Optimizer)
    return c_api_getnumrows(model.inner)
end

function LQOI.add_linear_constraints!(model::Optimizer,
        A::LQOI.CSRMatrix{Float64}, sense::Vector{Cchar}, rhs::Vector{Float64})
    c_api_addrows(model.inner, ivec(A.row_pointers), ivec(A.columns),
        A.coefficients, sense, rhs)
    return
end

function LQOI.get_rhs(model::Optimizer, row::Int)
    rhs = Vector{Cdouble}(undef, 1)
    c_api_getrhs(model.inner, rhs, Cint(row), Cint(row))
    return rhs[1]
end

function LQOI.get_linear_constraint(model::Optimizer, row::Int)
    (nzcnt, rmatbeg, rmatind, rmatval) =
            c_api_getrows(model.inner, Cint(row), Cint(row))
    return rmatind[1:nzcnt], rmatval[1:nzcnt]
end

function LQOI.change_matrix_coefficient!(
        model::Optimizer, row::Int, col::Int, coef::Float64)
    c_api_chgcoef(model.inner, Cint(row), Cint(col), coef)
    return
end

function LQOI.change_objective_coefficient!(
        model::Optimizer, col::Int, coef::Float64)
    c_api_chgobj(model.inner, [Cint(col)], [coef])
    return
end

function LQOI.change_rhs_coefficient!(
        model::Optimizer, row::Int, coef::Float64)
    c_api_chgrhs(model.inner, [Cint(row)], [coef])
    return
end

function LQOI.delete_linear_constraints!(
        model::Optimizer, first_row::Int, last_row::Int)
    c_api_delrows(model.inner, Cint(first_row), Cint(last_row))
    return
end

function LQOI.change_variable_types!(
        model::Optimizer, columns::Vector{Int}, vtypes::Vector{Cchar})
    c_api_chgctype(model.inner, ivec(columns), vtypes)
    return
end

function LQOI.change_linear_constraint_sense!(
        model::Optimizer, rows::Vector{Int}, senses::Vector{Cchar})
    c_api_chgsense(model.inner, ivec(rows), senses)
    return
end

function LQOI.set_linear_objective!(
        model::Optimizer, columns::Vector{Int}, coefficients::Vector{Float64})
    n = num_var(model.inner)
    all_coefs = zeros(Float64, n)
    for (col, coef) in zip(columns, coefficients)
        all_coefs[col] += coef
    end
    c_api_chgobj(model.inner, Cint[1:n;], all_coefs)
    return
end

function LQOI.change_objective_sense!(model::Optimizer, symbol)
    if symbol == :min
        c_api_chgobjsen(model.inner, Cint(1))
    else
        @assert symbol == :max
        c_api_chgobjsen(model.inner, Cint(-1))
    end
    return
end

function LQOI.get_linear_objective!(model::Optimizer, dest)
    c_api_getobj(model.inner, dest, Cint(1), c_api_getnumcols(model.inner))
    return
end

function LQOI.get_objectivesense(model::Optimizer)
    s = c_api_getobjsen(model.inner)
    if s == 1
        return MOI.MIN_SENSE
    else
        @assert s == -1
        return MOI.MAX_SENSE
    end
end

function LQOI.get_number_variables(model::Optimizer)
    return c_api_getnumcols(model.inner)
end

function LQOI.add_variables!(model::Optimizer, N::Int)
    add_vars!(model.inner, zeros(Float64, N), fill(-Inf, N), fill(Inf, N))
    return
end

function LQOI.delete_variables!(model::Optimizer, first_col::Int, last_col::Int)
    c_api_delcols(model.inner, Cint(first_col), Cint(last_col))
    return
end

function LQOI.solve_mip_problem!(model::Optimizer)
    LQOI.make_problem_type_integer(model)
    optimize!(model.inner)
    return
end

function LQOI.solve_linear_problem!(model::Optimizer)
    LQOI.make_problem_type_continuous(model)
    optimize!(model.inner)
    return
end

function LQOI.get_termination_status(model::Optimizer)
    stat = c_api_getstat(model.inner)

    if stat == 1 # CPX_STAT_OPTIMAL
        return MOI.OPTIMAL
    elseif stat == 3 # CPX_STAT_INFEASIBLE
        return MOI.INFEASIBLE
    elseif stat == 4 # CPX_STAT_INForUNBD
        return MOI.INFEASIBLE_OR_UNBOUNDED
    elseif stat == 2 # CPX_STAT_UNBOUNDED
        return MOI.DUAL_INFEASIBLE
    elseif stat in (12, 21, 22, 36) # CPX_STAT_*ABORT*_OBJ_LIM
        return MOI.OBJECTIVE_LIMIT
    elseif stat in (10, 34) # CPX_STAT_*ABORT_IT_LIM
        return MOI.ITERATION_LIMIT
    elseif stat == 53 # CPX_STAT_CONFLICT_ABORT_NODE_LIM
        return MOI.NODE_LIMIT
    elseif stat in (11, 25, 33, 39) # CPX_STAT_*ABORT*TIME_LIM
        return MOI.TIME_LIMIT
    elseif stat == 5 # CPX_STAT_OPTIMAL_INFEAS
        return MOI.NUMERICAL_ERROR
    # MIP STATUS
    elseif stat in (101, 102) # CPXMIP_OPTIMAL, CPXMIP_OPTIMAL_TOL
        return MOI.OPTIMAL
    elseif stat == 103 # CPXMIP_INFEASIBLE
        return MOI.INFEASIBLE
    elseif stat == 119 # CPXMIP_INForUNBD
        return MOI.INFEASIBLE_OR_UNBOUNDED
    elseif stat == 118 # CPXMIP_UNBOUNDED
        return MOI.DUAL_INFEASIBLE
    elseif stat in (105, 106) # CPXMIP_NODE_LIM*
        return MOI.NODE_LIMIT
    elseif stat in (107, 108, 131, 132) # CPXMIP_*TIME_LIM*
        return MOI.TIME_LIMIT
    else
        return MOI.OTHER_ERROR
    end
end

function LQOI.get_primal_status(model::Optimizer)
    soln_method, soln_type, primal_stat, dual_stat = c_api_solninfo(model.inner)
    if primal_stat == 1
        return MOI.FEASIBLE_POINT
    else
        return MOI.NO_SOLUTION
    end
end

function LQOI.get_dual_status(model::Optimizer)
    if model.inner.has_int
        return MOI.NO_SOLUTION
    end
    soln_method, soln_type, primal_stat, dual_stat = c_api_solninfo(model.inner)
    if dual_stat == 1
        return MOI.FEASIBLE_POINT
    else
        return MOI.NO_SOLUTION
    end
end

function LQOI.get_variable_primal_solution!(model::Optimizer, dest)
    c_api_getx(model.inner, dest)
    return
end

function LQOI.get_linear_primal_solution!(model::Optimizer, dest)
    c_api_getax(model.inner, dest)
    return
end

function LQOI.get_variable_dual_solution!(model::Optimizer, dest)
    c_api_getdj(model.inner, dest)
    return
end

function LQOI.get_linear_dual_solution!(model::Optimizer, dest)
    c_api_getpi(model.inner, dest)
    return
end

function LQOI.get_objective_value(model::Optimizer)
    return c_api_getobjval(model.inner)
end

function LQOI.get_objective_bound(model::Optimizer)
    return get_best_bound(model.inner)
end

function LQOI.get_farkas_dual!(model::Optimizer, dest)
    copy!(dest, get_infeasibility_ray(model.inner))
    return
end

function LQOI.get_unbounded_ray!(model::Optimizer, dest)
    copy!(dest, get_unbounded_ray(model.inner))
    return
end

function LQOI.add_sos_constraint!(model::Optimizer, columns::Vector{Int},
        weights::Vector{Float64}, sos_type::Symbol)
    add_sos!(model.inner, sos_type, columns, weights)
    return
end

function LQOI.get_sos_constraint(model::Optimizer, index::Int)
    (cols, weights, sos_type) = c_api_getsos(model.inner, index - 1)
    if sos_type == Cchar('1')
        return (cols .+ 1, weights, :SOS1)
    else
        @assert sos_type == Cchar('2')
        return (cols .+ 1, weights, :SOS2)
    end
    return
end

function LQOI.delete_sos!(model::Optimizer, begin_index::Int, end_index::Int)
    c_api_delsos(model.inner, begin_index - 1, end_index - 1)
    return
end


function scalediagonal!(V, I, J, scale)
    #  LQOI assumes 0.5 x' Q x, but CPLEX requires the list of terms, e.g.,
    #  2x^2 + xy + y^2, so we multiply the diagonal of V by 0.5. We don't
    #  multiply the off-diagonal terms since we assume they are symmetric and we
    #  only need to give one.
    #
    #  We also need to make sure that after adding the constraint we un-scale
    #  the vector because we can't modify user-data.
    for i in 1:length(I)
        if I[i] == J[i]
            V[i] *= scale
        end
    end
    return
end


function LQOI.set_quadratic_objective!(model::Optimizer, I::Vector{Int}, J::Vector{Int}, V::Vector{Float64})
    @assert length(I) == length(J) == length(V)
    CPLEX.add_qpterms!(model.inner, I, J, V)
    return
end

function LQOI.solve_quadratic_problem!(model::Optimizer)
    model.inner.has_qc = true
    LQOI.solve_linear_problem!(model)
end

function LQOI.get_quadratic_primal_solution!(model::Optimizer, dest)
    c_api_getxqxax(model.inner, dest)
    return
end

function LQOI.get_quadratic_dual_solution!(model::Optimizer, dest)
    c_api_getqconstrslack(model.inner, dest)
    return
end

function LQOI.add_quadratic_constraint!(model::Optimizer,
        affine_columns::Vector{Int}, affine_coefficients::Vector{Float64},
        rhs::Float64, sense::Cchar,
        I::Vector{Int}, J::Vector{Int}, V::Vector{Float64})
    @assert length(I) == length(J) == length(V)
    scalediagonal!(V, I, J, 0.5)
    add_qconstr!(model.inner, Cint.(affine_columns), affine_coefficients,
                 Cint.(I), Cint.(J), V, sense, rhs)
    scalediagonal!(V, I, J, 2.0)
    return
end

function LQOI.get_quadratic_constraint(model::Optimizer, row::Int)
    affine_cols, affine_coefficients, I, J, V, _, _ = c_api_getqconstr(model.inner, row)
    for i in 1:length(I)
        if I[i] != J[i]
            V[i] *= 0.5  # Account for the 0.5 term in 0.5 x' Q x.
        end
    end
    # Convert 0-based indices into 1-based indices for the variables.
    return Int.(affine_cols .+ 1), affine_coefficients, sparse(I .+ 1, J .+ 1, V)
end

function LQOI.get_quadratic_rhs(model::Optimizer, row::Int)
    _, _, _, _, _, _, rhs = c_api_getqconstr(model.inner, row)
    return rhs
end

function LQOI.get_number_quadratic_constraints(model::Optimizer)
    return CPLEX.num_qconstr(model.inner)
end

function LQOI.get_quadratic_terms_objective(model::Optimizer)
    qmatbeg, qmatind, qmatval = c_api_getquad(model.inner)
    qmatind .+= 1
    qmatcol = fill(length(qmatbeg), length(qmatind))
    # qmatbeg[i] stores the initial element (0-indexed) in qmatind and qmatval
    # for the i'th variable. In the next loop, we exclude the last variable
    # because it is implicitly set via the call to `fill`.
    for i in 1:length(qmatbeg) - 1
        start_index = qmatbeg[i] + 1  # +1 converts to 1-based.
        stop_index = qmatbeg[i + 1]
        for j in start_index:stop_index
            qmatcol[j] = i
        end
    end
    for i in 1:length(qmatval)
        if qmatind[i] != qmatcol[i]
            qmatval[i] *= 0.5  # Account for the 0.5 term in 0.5 x' Q x.
        end
    end
    # qmatind is ::Vector{Cint}, so we convert back to ::Vector{Int}.
    return sparse(Int.(qmatind), qmatcol, qmatval)
end

const INTEGER_TYPES = Set{Symbol}([:MILP, :MIQP, :MIQCP])
const CONTINUOUS_TYPES = Set{Symbol}([:LP, :QP, :QCP])

function LQOI.make_problem_type_integer(optimizer::Optimizer)
    optimizer.inner.has_int = true
    prob_type = get_prob_type(optimizer.inner)
    prob_type in INTEGER_TYPES && return
    # prob_type_toggle_map is defined in file CplexSolverInterface.jl
    set_prob_type!(optimizer.inner, prob_type_toggle_map[prob_type])
    return
end

function LQOI.make_problem_type_continuous(optimizer::Optimizer)
    optimizer.inner.has_int = false
    prob_type = get_prob_type(optimizer.inner)
    prob_type in CONTINUOUS_TYPES && return
    # prob_type_toggle_map is defined in file CplexSolverInterface.jl
    set_prob_type!(optimizer.inner, prob_type_toggle_map[prob_type])
    return
end

"""
    compute_conflict(model::Optimizer)

Compute a minimal subset of the constraints and variables that keep the model
infeasible.

See also `CPLEX.ConflictStatus` and `CPLEX.ConstraintConflictStatus`.

Note that if `model` is modified after a call to `compute_conflict`, the
conflict is not purged, and any calls to the above attributes will return values
for the original conflict without a warning.
"""
function compute_conflict(model::Optimizer)
    # In case there is no conflict, c_api_getconflict throws an error, while the conflict
    # data structure can handle more gracefully this case (via a status check).
    try
        model.conflict = c_api_getconflict(model.inner)
    catch exc
        if isa(exc, CplexError) && exc.code == CPXERR_NO_CONFLICT
            model.conflict = ConflictRefinerData(CPX_STAT_CONFLICT_FEASIBLE, 0, Cint[], Cint[], 0, Cint[], Cint[])
        else
            rethrow(exc)
        end
    end
    return

    # TODO: decide what to do about the POSSIBLE statuses for the constraints (CPX_CONFLICT_POSSIBLE_MEMBER,
    # CPX_CONFLICT_POSSIBLE_UB, CPX_CONFLICT_POSSIBLE_LB).
end

function _ensure_conflict_computed(model::Optimizer)
    if model.conflict === nothing
        error("Cannot access conflict status. Call `CPLEX.compute_conflict(model)` first. " *
              "In case the model is modified, the computed conflict will not be purged.")
    end
end

"""
    ConflictStatus()

Return an `MOI.TerminationStatusCode` indicating the status of the last computed conflict.

If a minimal conflict is found, it will return `MOI.OPTIMAL`. If the problem is feasible, it will
return `MOI.INFEASIBLE`. If `compute_conflict` has not been called yet, it will return
`MOI.OPTIMIZE_NOT_CALLED`.
"""
struct ConflictStatus <: MOI.AbstractModelAttribute  end
MOI.is_set_by_optimize(::ConflictStatus) = true

function MOI.get(model::Optimizer, ::ConflictStatus)
    if model.conflict === nothing
        return MOI.OPTIMIZE_NOT_CALLED
    elseif model.conflict.stat == CPX_STAT_CONFLICT_MINIMAL
        return MOI.OPTIMAL
    elseif model.conflict.stat == CPX_STAT_CONFLICT_FEASIBLE
        return MOI.INFEASIBLE
    elseif model.conflict.stat == CPX_STAT_CONFLICT_ABORT_CONTRADICTION
        return MOI.OTHER_LIMIT
    elseif model.conflict.stat == CPX_STAT_CONFLICT_ABORT_DETTIME_LIM
        return MOI.TIME_LIMIT
    elseif model.conflict.stat == CPX_STAT_CONFLICT_ABORT_IT_LIM
        return MOI.ITERATION_LIMIT
    elseif model.conflict.stat == CPX_STAT_CONFLICT_ABORT_MEM_LIM
        return MOI.MEMORY_LIMIT
    elseif model.conflict.stat == CPX_STAT_CONFLICT_ABORT_NODE_LIM
        return MOI.NODE_LIMIT
    elseif model.conflict.stat == CPX_STAT_CONFLICT_ABORT_OBJ_LIM
        return MOI.OBJECTIVE_LIMIT
    elseif model.conflict.stat == CPX_STAT_CONFLICT_ABORT_TIME_LIM
        return MOI.TIME_LIMIT
    elseif model.conflict.stat == CPX_STAT_CONFLICT_ABORT_USER
        return MOI.OTHER_LIMIT
    else
        return MOI.OTHER_LIMIT
    end
end

function MOI.supports(::Optimizer, ::ConflictStatus)
    return true
end

"""
    ConstraintConflictStatus()

A Boolean constraint attribute indicating whether the constraint participates in the last computed conflict.
"""
struct ConstraintConflictStatus <: MOI.AbstractConstraintAttribute end
MOI.is_set_by_optimize(::ConstraintConflictStatus) = true

function _sinvar_get_conflict_status(model::Optimizer, index::MOI.ConstraintIndex)
    _ensure_conflict_computed(model)
    var_in_conflict = findfirst(isequal(LQOI.get_column(model, model[index]) - 1), model.conflict.colind)

    if var_in_conflict === nothing
        return nothing
    else
        return model.conflict.colstat[var_in_conflict]
    end
end

function MOI.get(model::Optimizer, ::ConstraintConflictStatus, index::MOI.ConstraintIndex{<:MOI.SingleVariable, <:LQOI.LE})
    status = _sinvar_get_conflict_status(model, index)
    return status !== nothing && (status == CPLEX.CPX_CONFLICT_MEMBER || status == CPLEX.CPX_CONFLICT_UB)
end

function MOI.get(model::Optimizer, ::ConstraintConflictStatus, index::MOI.ConstraintIndex{<:MOI.SingleVariable, <:LQOI.GE})
    status = _sinvar_get_conflict_status(model, index)
    return status !== nothing && (status == CPLEX.CPX_CONFLICT_MEMBER || status == CPLEX.CPX_CONFLICT_LB)
end

function MOI.get(model::Optimizer, ::ConstraintConflictStatus, index::MOI.ConstraintIndex{<:MOI.SingleVariable, <:Union{LQOI.EQ, LQOI.IV}})
    status = _sinvar_get_conflict_status(model, index)
    return status !== nothing && (status == CPLEX.CPX_CONFLICT_MEMBER || status == CPLEX.CPX_CONFLICT_LB || status == CPLEX.CPX_CONFLICT_UB)
end

function MOI.get(model::Optimizer, ::ConstraintConflictStatus, index::MOI.ConstraintIndex{<:MOI.ScalarAffineFunction, <:Union{LQOI.LE, LQOI.GE, LQOI.EQ}})
    _ensure_conflict_computed(model)
    return (model[index] - 1) in model.conflict.rowind
end

function MOI.supports(::Optimizer, ::ConstraintConflictStatus, ::Type{MOI.ConstraintIndex{<:MOI.SingleVariable, <:LQOI.LinSets}})
    return true
end

function MOI.supports(::Optimizer, ::ConstraintConflictStatus, ::Type{MOI.ConstraintIndex{<:MOI.ScalarAffineFunction, <:Union{LQOI.LE, LQOI.GE, LQOI.EQ}}})
    return true
end
