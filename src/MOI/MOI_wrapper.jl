import MathOptInterface

const MOI = MathOptInterface
const CleverDicts = MOI.Utilities.CleverDicts

@enum(
    _BoundType,
    _NONE,
    _LESS_THAN,
    _GREATER_THAN,
    _LESS_AND_GREATER_THAN,
    _INTERVAL,
    _EQUAL_TO,
)

@enum(
    _ObjectiveType,
    _SINGLE_VARIABLE,
    _SCALAR_AFFINE,
    _SCALAR_QUADRATIC,
    _UNSET_OBJECTIVE,
)

@enum(
    CallbackState,
    _CB_NONE,
    _CB_GENERIC,
    _CB_LAZY,
    _CB_USER_CUT,
    _CB_HEURISTIC,
)

const _SCALAR_SETS = Union{
    MOI.GreaterThan{Float64},
    MOI.LessThan{Float64},
    MOI.EqualTo{Float64},
    MOI.Interval{Float64},
}

mutable struct _VariableInfo
    index::MOI.VariableIndex
    column::Int
    bound::_BoundType
    type::Char
    start::Union{Float64,Nothing}
    name::String
    # Storage for the lower bound if the variable is the `t` variable in a
    # second order cone.
    lower_bound_if_soc::Float64
    num_soc_constraints::Int
    function _VariableInfo(index::MOI.VariableIndex, column::Int)
        return new(index, column, _NONE, CPX_CONTINUOUS, nothing, "", NaN, 0)
    end
end

mutable struct _ConstraintInfo
    row::Int
    set::MOI.AbstractSet
    # Storage for constraint names. Where possible, these are also stored in the
    # CPLEX model.
    name::String
    _ConstraintInfo(row::Int, set::MOI.AbstractSet) = new(row, set, "")
end

mutable struct Env
    ptr::Ptr{Cvoid}
    # These fields keep track of how many models the `Env` is used for to help
    # with finalizing. If you finalize an Env first, then the model, CPLEX will
    # throw an error.
    finalize_called::Bool
    attached_models::Int

    function Env()
        status_p = Ref{Cint}()
        ptr = CPXopenCPLEX(status_p)
        if status_p[] != 0
            error(
                "CPLEX Error $(status_p[]): Unable to create CPLEX environment.",
            )
        end
        env = new(ptr, false, 0)
        finalizer(env) do e
            e.finalize_called = true
            if e.attached_models == 0
                # Only finalize the model if there are no models using it.
                CPXcloseCPLEX(Ref(e.ptr))
                e.ptr = C_NULL
            end
        end
        return env
    end
end
Base.cconvert(::Type{Ptr{Cvoid}}, x::Env) = x
Base.unsafe_convert(::Type{Ptr{Cvoid}}, env::Env) = env.ptr::Ptr{Cvoid}

function _get_error_string(env::Union{Env,CPXENVptr}, ret::Cint)
    buffer = Array{Cchar}(undef, CPXMESSAGEBUFSIZE)
    p = pointer(buffer)
    return GC.@preserve buffer begin
        errstr = CPXgeterrorstring(env, ret, p)
        if errstr == C_NULL
            "CPLEX Error $(ret): Unknown error code."
        else
            unsafe_string(p)
        end
    end
end

function _check_ret(env::Union{Env,CPXENVptr}, ret::Cint)
    if ret == 0
        return
    end
    return error(_get_error_string(env, ret))
end

# If you add a new error code that, when returned by CPLEX inside `optimize!`,
# should be treated as a TerminationStatus by MOI, to the global `Dict`
# below, then the rest of the code should pick up on this seamlessly.
const _ERROR_TO_STATUS = Dict{Cint,MOI.TerminationStatusCode}([
    # CPLEX Code => TerminationStatus
    CPXERR_NO_MEMORY => MOI.MEMORY_LIMIT,
])

# Same as _check_ret, but deals with the `model.ret_optimize` machinery.
function _check_ret_optimize(model)
    if !haskey(_ERROR_TO_STATUS, model.ret_optimize)
        _check_ret(model, model.ret_optimize)
    end
    return
end

"""
    Optimizer(env::Union{Nothing, Env} = nothing)

Create a new Optimizer object.

You can share CPLEX `Env`s between models by passing an instance of `Env` as the
first argument.

Set optimizer attributes using `MOI.RawOptimizerAttribute` or
`JuMP.set_optimizer_atttribute`.

## Example

```julia
using JuMP, CPLEX
const env = CPLEX.Env()
model = JuMP.Model(() -> CPLEX.Optimizer(env)
set_optimizer_attribute(model, "CPXPARAM_ScreenOutput", 0)
```

## `CPLEX.PassNames`

By default, variable and constraint names are stored in the MOI wrapper, but are
_not_ passed to the inner CPLEX model object because doing so can lead to a
large performance degradation. The downside of not passing names is that various
log messages from CPLEX will report names like constraint "R1" and variable "C2"
instead of their actual names. You can change this behavior using
`CPLEX.PassNames` to force CPLEX.jl to pass variable and constraint names to the
inner CPLEX model object:

```julia
using JuMP, CPLEX
model = JuMP.Model(CPLEX.Optimizer)
set_optimizer_attribute(model, CPLEX.PassNames(), true)
```
"""
mutable struct Optimizer <: MOI.AbstractOptimizer
    # The low-level CPLEX model.
    lp::CPXLPptr
    env::Env

    # A flag to keep track of MOI.Silent, which over-rides the OutputFlag
    # parameter.
    silent::Bool

    variable_primal::Union{Nothing,Vector{Float64}}

    # Helpers to remember what objective is currently stored in the model.
    objective_type::_ObjectiveType
    objective_sense::Union{Nothing,MOI.OptimizationSense}

    # A mapping from the MOI.VariableIndex to the CPLEX column. _VariableInfo
    # also stores some additional fields like what bounds have been added, the
    # variable type, and the names of VariableIndex-in-Set constraints.
    variable_info::CleverDicts.CleverDict{MOI.VariableIndex,_VariableInfo}

    # An index that is incremented for each new constraint (regardless of type).
    # We can check if a constraint is valid by checking if it is in the correct
    # xxx_constraint_info. We should _not_ reset this to zero, since then new
    # constraints cannot be distinguished from previously created ones.
    last_constraint_index::Int
    # ScalarAffineFunction{Float64}-in-Set storage.
    affine_constraint_info::Dict{Int,_ConstraintInfo}
    # ScalarQuadraticFunction{Float64}-in-Set storage.
    quadratic_constraint_info::Dict{Int,_ConstraintInfo}
    # VectorOfVariables-in-Set storage.
    sos_constraint_info::Dict{Int,_ConstraintInfo}
    # VectorAffineFunction-in-Set storage.
    # the function info is also stored in the dict
    indicator_constraint_info::Dict{
        Int,
        Tuple{_ConstraintInfo,MOI.VectorAffineFunction{Float64}},
    }
    # Note: we do not have a VariableIndex_constraint_info dictionary. Instead,
    # data associated with these constraints are stored in the _VariableInfo
    # objects.

    # Mappings from variable and constraint names to their indices. These are
    # lazily built on-demand, so most of the time, they are `nothing`.
    name_to_variable::Union{
        Nothing,
        Dict{String,Union{Nothing,MOI.VariableIndex}},
    }
    name_to_constraint_index::Union{
        Nothing,
        Dict{String,Union{Nothing,MOI.ConstraintIndex}},
    }

    # CPLEX has more than one configurable memory limit, but these do not seem
    # to cover all situations, for example, there are no memory limits for
    # solving LPs with the many possible algorithms (simplex, barrier, etc...).
    # In such situations, CPLEX does detect when it needs more memory than it
    # is available, but returns an error code instead of setting the
    # termination status (like it does for the configurable memory and time
    # limits).  For convenience, and homogeinity with other solvers, we save
    # the code obtained inside `_optimize!` in `ret_optimize`, and do not throw
    # an exception case it should be interpreted as a termination status.
    # Then, when/if the termination status is queried, we may override the
    # result taking into account the `ret_optimize` field.
    ret_optimize::Cint

    has_primal_certificate::Bool
    has_dual_certificate::Bool
    certificate::Vector{Float64}

    solve_time::Float64

    conflict::Any # ::Union{Nothing, ConflictRefinerData}

    # Callback fields.
    callback_variable_primal::Vector{Float64}
    has_generic_callback::Bool
    callback_state::CallbackState
    lazy_callback::Union{Nothing,Function}
    user_cut_callback::Union{Nothing,Function}
    heuristic_callback::Union{Nothing,Function}
    generic_callback::Any

    # For more information on why `pass_names` is necessary, read:
    # https://github.com/jump-dev/CPLEX.jl/issues/392
    # The underlying problem is that we observed that add_variable, then set
    # VariableName then add_variable (i.e., what CPLEX in direct-mode does) is
    # faster than adding variable in batch then setting names in batch (i.e.,
    # what default_copy_to does). If implementing MOI.copy_to, you should take
    # this into consideration.
    pass_names::Bool

    function Optimizer(env::Union{Nothing,Env} = nothing)
        model = new()
        model.lp = C_NULL
        model.env = env === nothing ? Env() : env
        MOI.set(model, MOI.RawOptimizerAttribute("CPXPARAM_ScreenOutput"), 1)
        model.silent = false
        model.variable_primal = nothing

        model.variable_info =
            CleverDicts.CleverDict{MOI.VariableIndex,_VariableInfo}()
        model.affine_constraint_info = Dict{Int,_ConstraintInfo}()
        model.quadratic_constraint_info = Dict{Int,_ConstraintInfo}()
        model.sos_constraint_info = Dict{Int,_ConstraintInfo}()
        model.indicator_constraint_info =
            Dict{Int,Tuple{_ConstraintInfo,MOI.VectorAffineFunction{Float64}}}()
        model.callback_variable_primal = Float64[]
        model.certificate = Float64[]
        model.pass_names = false
        MOI.empty!(model)
        finalizer(model) do m
            ret = CPXfreeprob(m.env, Ref(m.lp))
            _check_ret(m, ret)
            m.env.attached_models -= 1
            if env === nothing
                # We created this env. Finalize it now
                finalize(m.env)
            elseif m.env.finalize_called && m.env.attached_models == 0
                # We delayed finalizing `m.env` earlier because there were still
                # models attached. Finalize it now.
                CPXcloseCPLEX(Ref(m.env.ptr))
                m.env.ptr = C_NULL
            end
        end
        return model
    end
end

_check_ret(model::Optimizer, ret::Cint) = _check_ret(model.env, ret)

Base.show(io::IO, model::Optimizer) = show(io, model.lp)

function MOI.empty!(model::Optimizer)
    if model.lp != C_NULL
        ret = CPXfreeprob(model.env, Ref(model.lp))
        _check_ret(model.env, ret)
        model.env.attached_models -= 1
    end
    # Try open a new problem
    stat = Ref{Cint}()
    tmp = CPXcreateprob(model.env, stat, "")
    if tmp == C_NULL
        _check_ret(model.env, stat[])
    end
    model.env.attached_models += 1
    model.lp = tmp
    if model.silent
        MOI.set(model, MOI.RawOptimizerAttribute("CPXPARAM_ScreenOutput"), 0)
    end
    model.objective_type = _UNSET_OBJECTIVE
    model.objective_sense = nothing
    empty!(model.variable_info)
    empty!(model.affine_constraint_info)
    empty!(model.quadratic_constraint_info)
    empty!(model.sos_constraint_info)
    model.name_to_variable = nothing
    model.name_to_constraint_index = nothing
    model.ret_optimize = Cint(0)
    empty!(model.callback_variable_primal)
    empty!(model.certificate)
    model.has_primal_certificate = false
    model.has_dual_certificate = false
    model.solve_time = NaN
    model.conflict = nothing
    model.callback_state = _CB_NONE
    model.has_generic_callback = false
    model.lazy_callback = nothing
    model.user_cut_callback = nothing
    model.heuristic_callback = nothing
    model.generic_callback = nothing
    model.variable_primal = nothing
    return
end

function MOI.is_empty(model::Optimizer)
    model.objective_type != _UNSET_OBJECTIVE && return false
    model.objective_sense !== nothing && return false
    !isempty(model.variable_info) && return false
    length(model.affine_constraint_info) != 0 && return false
    length(model.quadratic_constraint_info) != 0 && return false
    length(model.sos_constraint_info) != 0 && return false
    model.name_to_variable !== nothing && return false
    model.name_to_constraint_index !== nothing && return false
    model.ret_optimize !== Cint(0) && return false
    length(model.callback_variable_primal) != 0 && return false
    model.callback_state != _CB_NONE && return false
    model.has_generic_callback && return false
    model.lazy_callback !== nothing && return false
    model.user_cut_callback !== nothing && return false
    model.heuristic_callback !== nothing && return false
    return true
end

"""
    PassNames() <: MOI.AbstractOptimizerAttribute

An optimizer attribute to control whether CPLEX.jl should pass names to the
inner CPLEX model object. See the docstring of `CPLEX.Optimizer` for more
information.
"""
struct PassNames <: MOI.AbstractOptimizerAttribute end

function MOI.set(model::Optimizer, ::PassNames, value::Bool)
    model.pass_names = value
    return
end

MOI.get(::Optimizer, ::MOI.SolverName) = "CPLEX"

MOI.get(::Optimizer, ::MOI.SolverVersion) = string(_CPLEX_VERSION)

function MOI.supports(
    ::Optimizer,
    ::MOI.ObjectiveFunction{F},
) where {
    F<:Union{
        MOI.VariableIndex,
        MOI.ScalarAffineFunction{Float64},
        MOI.ScalarQuadraticFunction{Float64},
    },
}
    return true
end

function MOI.supports_constraint(
    ::Optimizer,
    ::Type{MOI.VariableIndex},
    ::Type{F},
) where {
    F<:Union{
        MOI.EqualTo{Float64},
        MOI.LessThan{Float64},
        MOI.GreaterThan{Float64},
        MOI.Interval{Float64},
        MOI.ZeroOne,
        MOI.Integer,
        MOI.Semicontinuous{Float64},
        MOI.Semiinteger{Float64},
    },
}
    return true
end

function MOI.supports_constraint(
    ::Optimizer,
    ::Type{MOI.VectorOfVariables},
    ::Type{F},
) where {F<:Union{MOI.SOS1{Float64},MOI.SOS2{Float64},MOI.SecondOrderCone}}
    return true
end

# We choose _not_ to support ScalarAffineFunction-in-Interval and
# ScalarQuadraticFunction-in-Interval because CPLEX introduces some slack
# variables that makes it hard to keep track of the column indices.

function MOI.supports_constraint(
    ::Optimizer,
    ::Type{MOI.ScalarAffineFunction{Float64}},
    ::Type{F},
) where {
    F<:Union{
        MOI.EqualTo{Float64},
        MOI.LessThan{Float64},
        MOI.GreaterThan{Float64},
    },
}
    return true
end

function MOI.supports_constraint(
    ::Optimizer,
    ::Type{MOI.ScalarQuadraticFunction{Float64}},
    ::Type{F},
) where {F<:Union{MOI.LessThan{Float64},MOI.GreaterThan{Float64}}}
    # Note: CPLEX does not support quadratic equality constraints.
    return true
end

MOI.supports(::Optimizer, ::MOI.VariableName, ::Type{MOI.VariableIndex}) = true
function MOI.supports(
    ::Optimizer,
    ::MOI.ConstraintName,
    ::Type{<:MOI.ConstraintIndex},
)
    return true
end

MOI.supports(::Optimizer, ::MOI.Name) = true
MOI.supports(::Optimizer, ::MOI.Silent) = true
MOI.supports(::Optimizer, ::MOI.NumberOfThreads) = true
MOI.supports(::Optimizer, ::MOI.TimeLimitSec) = true
MOI.supports(::Optimizer, ::MOI.ObjectiveSense) = true
MOI.supports(::Optimizer, ::MOI.RawOptimizerAttribute) = true

function MOI.set(model::Optimizer, param::MOI.RawOptimizerAttribute, value)
    numP, typeP = Ref{Cint}(), Ref{Cint}()
    ret = CPXgetparamnum(model.env, param.name, numP)
    _check_ret(model.env, ret)
    ret = CPXgetparamtype(model.env, numP[], typeP)
    _check_ret(model.env, ret)
    ret = if typeP[] == CPX_PARAMTYPE_NONE
        Cint(0)
    elseif typeP[] == CPX_PARAMTYPE_INT
        CPXsetintparam(model.env, numP[], value)
    elseif typeP[] == CPX_PARAMTYPE_DOUBLE
        CPXsetdblparam(model.env, numP[], value)
    elseif typeP[] == CPX_PARAMTYPE_STRING
        CPXsetstrparam(model.env, numP[], value)
    else
        @assert typeP[] == CPX_PARAMTYPE_LONG
        CPXsetlongparam(model.env, numP[], value)
    end
    _check_ret(model.env, ret)
    return
end

function MOI.get(model::Optimizer, param::MOI.RawOptimizerAttribute)
    numP, typeP = Ref{Cint}(), Ref{Cint}()
    ret = CPXgetparamnum(model.env, param.name, numP)
    _check_ret(model.env, ret)
    ret = CPXgetparamtype(model.env, numP[], typeP)
    _check_ret(model.env, ret)
    if typeP[] == CPX_PARAMTYPE_NONE
        Cint(0)
    elseif typeP[] == CPX_PARAMTYPE_INT
        valueP = Ref{Cint}()
        ret = CPXgetintparam(model.env, numP[], valueP)
        _check_ret(model.env, ret)
        return Int(valueP[])
    elseif typeP[] == CPX_PARAMTYPE_DOUBLE
        valueP = Ref{Cdouble}()
        ret = CPXgetdblparam(model.env, numP[], valueP)
        _check_ret(model.env, ret)
        return valueP[]
    elseif typeP[] == CPX_PARAMTYPE_STRING
        buffer = Array{Cchar}(undef, CPXMESSAGEBUFSIZE)
        valueP = pointer(buffer)
        GC.@preserve buffer begin
            ret = CPXgetstrparam(model.env, numP[], valueP)
            _check_ret(model, ret)
            return unsafe_string(valueP)
        end
    else
        @assert typeP[] == CPX_PARAMTYPE_LONG
        valueP = Ref{CPXLONG}()
        ret = CPXgetlongparam(model.env, numP[], valueP)
        _check_ret(model.env, ret)
        return valueP[]
    end
    _check_ret(model.env, ret)
    return
end

function MOI.set(model::Optimizer, ::MOI.TimeLimitSec, limit::Real)
    MOI.set(model, MOI.RawOptimizerAttribute("CPXPARAM_TimeLimit"), limit)
    return
end

function MOI.get(model::Optimizer, ::MOI.TimeLimitSec)
    return MOI.get(model, MOI.RawOptimizerAttribute("CPXPARAM_TimeLimit"))
end

MOI.supports_incremental_interface(::Optimizer) = true

# !!! info
#     If modifying this function, read the comment in the defintion of Optimizer
#     about the need for `pass_names`.
function MOI.copy_to(dest::Optimizer, src::MOI.ModelLike)
    return MOI.Utilities.default_copy_to(dest, src)
end

function MOI.get(model::Optimizer, ::MOI.ListOfVariableAttributesSet)
    ret = MOI.AbstractVariableAttribute[]
    found_name, found_start = false, false
    for info in values(model.variable_info)
        if !found_name && !isempty(info.name)
            push!(ret, MOI.VariableName())
            found_name = true
        end
        if !found_start && info.start !== nothing
            push!(ret, MOI.VariablePrimalStart())
            found_start = true
        end
        if found_start && found_name
            return ret
        end
    end
    return ret
end

function MOI.get(model::Optimizer, ::MOI.ListOfModelAttributesSet)
    attributes = MOI.AbstractModelAttribute[]
    if model.objective_sense !== nothing
        push!(attributes, MOI.ObjectiveSense())
    end
    if model.objective_type != _UNSET_OBJECTIVE
        F = MOI.get(model, MOI.ObjectiveFunctionType())
        push!(attributes, MOI.ObjectiveFunction{F}())
    end
    if MOI.get(model, MOI.Name()) != ""
        push!(attributes, MOI.Name())
    end
    return attributes
end

function MOI.get(::Optimizer, ::MOI.ListOfConstraintAttributesSet)
    return MOI.AbstractConstraintAttribute[MOI.ConstraintName()]
end

function MOI.get(
    ::Optimizer,
    ::MOI.ListOfConstraintAttributesSet{MOI.VariableIndex},
)
    return MOI.AbstractConstraintAttribute[]
end

function _indices_and_coefficients(
    indices::AbstractVector{Cint},
    coefficients::AbstractVector{Float64},
    model::Optimizer,
    f::MOI.ScalarAffineFunction{Float64},
)
    for (i, term) in enumerate(f.terms)
        indices[i] = Cint(column(model, term.variable) - 1)
        coefficients[i] = term.coefficient
    end
    return indices, coefficients
end

function _indices_and_coefficients(
    model::Optimizer,
    f::MOI.ScalarAffineFunction{Float64},
)
    f_canon = MOI.Utilities.canonical(f)
    nnz = length(f_canon.terms)
    indices = Vector{Cint}(undef, nnz)
    coefficients = Vector{Float64}(undef, nnz)
    _indices_and_coefficients(indices, coefficients, model, f_canon)
    return indices, coefficients
end

function _indices_and_coefficients(
    I::AbstractVector{Cint},
    J::AbstractVector{Cint},
    V::AbstractVector{Float64},
    indices::AbstractVector{Cint},
    coefficients::AbstractVector{Float64},
    model::Optimizer,
    f::MOI.ScalarQuadraticFunction,
)
    for (i, term) in enumerate(f.quadratic_terms)
        I[i] = Cint(column(model, term.variable_1) - 1)
        J[i] = Cint(column(model, term.variable_2) - 1)
        V[i] = term.coefficient
        # CPLEX returns a list of terms. MOI requires 0.5 x' Q x. So, to get
        # from
        #   CPLEX -> MOI => multiply diagonals by 2.0
        #   MOI -> CPLEX => multiply diagonals by 0.5
        # Example: 2x^2 + x*y + y^2
        #   |x y| * |a b| * |x| = |ax+by bx+cy| * |x| = 0.5ax^2 + bxy + 0.5cy^2
        #           |b c|   |y|                   |y|
        #   CPLEX needs: (I, J, V) = ([0, 0, 1], [0, 1, 1], [2, 1, 1])
        #   MOI needs:
        #     [SQT(4.0, x, x), SQT(1.0, x, y), SQT(2.0, y, y)]
        if I[i] == J[i]
            V[i] *= 0.5
        end
    end
    for (i, term) in enumerate(f.affine_terms)
        indices[i] = Cint(column(model, term.variable) - 1)
        coefficients[i] = term.coefficient
    end
    return
end

function _indices_and_coefficients(
    model::Optimizer,
    f::MOI.ScalarQuadraticFunction,
)
    f_canon = MOI.Utilities.canonical(f)
    nnz_quadratic = length(f_canon.quadratic_terms)
    nnz_affine = length(f_canon.affine_terms)
    I = Vector{Cint}(undef, nnz_quadratic)
    J = Vector{Cint}(undef, nnz_quadratic)
    V = Vector{Float64}(undef, nnz_quadratic)
    indices = Vector{Cint}(undef, nnz_affine)
    coefficients = Vector{Float64}(undef, nnz_affine)
    _indices_and_coefficients(I, J, V, indices, coefficients, model, f_canon)
    return indices, coefficients, I, J, V
end

_sense_and_rhs(s::MOI.LessThan{Float64}) = (Cchar('L'), s.upper)
_sense_and_rhs(s::MOI.GreaterThan{Float64}) = (Cchar('G'), s.lower)
_sense_and_rhs(s::MOI.EqualTo{Float64}) = (Cchar('E'), s.value)

###
### Variables
###

# Short-cuts to return the _VariableInfo associated with an index.
function _info(model::Optimizer, key::MOI.VariableIndex)
    if haskey(model.variable_info, key)
        return model.variable_info[key]
    end
    return throw(MOI.InvalidIndex(key))
end

"""
    column(model::Optimizer, x::MOI.VariableIndex)

Return the 1-indexed column associated with `x`.

The C API requires 0-indexed columns.
"""
function column(model::Optimizer, x::MOI.VariableIndex)
    return _info(model, x).column
end

function column(model::Optimizer, x::Vector{MOI.VariableIndex})
    return [_info(model, xi).column for xi in x]
end

function MOI.add_variable(model::Optimizer)
    # Initialize `_VariableInfo` with a dummy `VariableIndex` and a column,
    # because we need `add_item` to tell us what the `VariableIndex` is.
    index = CleverDicts.add_item(
        model.variable_info,
        _VariableInfo(MOI.VariableIndex(0), 0),
    )
    info = _info(model, index)
    info.index = index
    info.column = length(model.variable_info)
    ret = CPXnewcols(
        model.env,
        model.lp,
        1,
        C_NULL,
        [-Inf],
        C_NULL,
        C_NULL,
        C_NULL,
    )
    _check_ret(model, ret)
    return index
end

function MOI.add_variables(model::Optimizer, N::Int)
    ret = CPXnewcols(
        model.env,
        model.lp,
        N,
        C_NULL,
        fill(-Inf, N),
        C_NULL,
        C_NULL,
        C_NULL,
    )
    _check_ret(model, ret)
    indices = Vector{MOI.VariableIndex}(undef, N)
    num_variables = length(model.variable_info)
    for i in 1:N
        # Initialize `_VariableInfo` with a dummy `VariableIndex` and a column,
        # because we need `add_item` to tell us what the `VariableIndex` is.
        index = CleverDicts.add_item(
            model.variable_info,
            _VariableInfo(MOI.VariableIndex(0), 0),
        )
        info = _info(model, index)
        info.index = index
        info.column = num_variables + i
        indices[i] = index
    end
    return indices
end

function MOI.is_valid(model::Optimizer, v::MOI.VariableIndex)
    return haskey(model.variable_info, v)
end

# Helper function used inside MOI.delete (vector version). Takes a list of
# numbers (MOI.VariableIndex) sorted by increasing values, return two lists
# representing the same set of numbers but in the form of intervals.
# Ex.: _intervalize([1, 3, 4, 5, 8, 10, 11]) -> ([1, 3, 8, 10], [1, 5, 8, 11])
function _intervalize(xs)
    starts, ends = empty(xs), empty(xs)
    for x in xs
        if isempty(starts) || x != last(ends) + 1
            push!(starts, x)
            push!(ends, x)
        else
            ends[end] = x
        end
    end

    return starts, ends
end

function MOI.delete(model::Optimizer, indices::Vector{<:MOI.VariableIndex})
    info = [_info(model, var_idx) for var_idx in indices]
    soc_idx = findfirst(e -> e.num_soc_constraints > 0, info)
    soc_idx !== nothing && throw(MOI.DeleteNotAllowed(indices[soc_idx]))
    sorted_del_cols = sort!(collect(i.column for i in info))
    starts, ends = _intervalize(sorted_del_cols)
    for ri in reverse(1:length(starts))
        ret = CPXdelcols(
            model.env,
            model.lp,
            Cint(starts[ri] - 1),
            Cint(ends[ri] - 1),
        )
        _check_ret(model, ret)
    end
    for var_idx in indices
        delete!(model.variable_info, var_idx)
    end
    # When the deleted variables are not contiguous, the main advantage of this
    # method is that the loop below is O(n*log(m)) instead of the O(m*n) of the
    # repeated application of single variable delete (n is the total number of
    # variables in the model, m is the number of deleted variables).
    for other_info in values(model.variable_info)
        # The trick here is: `searchsortedlast` returns, in O(log n), the
        # last index with a row smaller than `other_info.row`, over
        # `sorted_del_cols` this is the same as the number of rows deleted
        # before it, and how much its value need to be shifted.
        other_info.column -=
            searchsortedlast(sorted_del_cols, other_info.column)
    end
    model.name_to_variable = nothing
    # We throw away name_to_constraint_index so we will rebuild VariableIndex
    # constraint names without v.
    model.name_to_constraint_index = nothing
    return
end

function MOI.delete(model::Optimizer, v::MOI.VariableIndex)
    info = _info(model, v)
    if info.num_soc_constraints > 0
        throw(MOI.DeleteNotAllowed(v))
    end
    ret = CPXdelcols(
        model.env,
        model.lp,
        Cint(info.column - 1),
        Cint(info.column - 1),
    )
    _check_ret(model, ret)
    delete!(model.variable_info, v)
    for other_info in values(model.variable_info)
        if other_info.column > info.column
            other_info.column -= 1
        end
    end
    model.name_to_variable = nothing
    # We throw away name_to_constraint_index so we will rebuild VariableIndex
    # constraint names without v.
    model.name_to_constraint_index = nothing
    return
end

function MOI.get(model::Optimizer, ::Type{MOI.VariableIndex}, name::String)
    if model.name_to_variable === nothing
        _rebuild_name_to_variable(model)
    end
    if haskey(model.name_to_variable, name)
        variable = model.name_to_variable[name]
        if variable === nothing
            error("Duplicate variable name detected: $(name)")
        end
        return variable
    end
    return nothing
end

function _rebuild_name_to_variable(model::Optimizer)
    model.name_to_variable = Dict{String,Union{Nothing,MOI.VariableIndex}}()
    for (index, info) in model.variable_info
        if info.name == ""
            continue
        end
        if haskey(model.name_to_variable, info.name)
            model.name_to_variable[info.name] = nothing
        else
            model.name_to_variable[info.name] = index
        end
    end
    return
end

function MOI.get(model::Optimizer, ::MOI.VariableName, v::MOI.VariableIndex)
    return _info(model, v).name
end

function MOI.set(
    model::Optimizer,
    ::MOI.VariableName,
    v::MOI.VariableIndex,
    name::String,
)
    info = _info(model, v)
    if model.pass_names && info.name != name && isascii(name)
        ret = CPXchgname(
            model.env,
            model.lp,
            Cchar('c'),
            Cint(info.column - 1),
            name,
        )
        _check_ret(model, ret)
    end
    info.name = name
    model.name_to_variable = nothing
    return
end

###
### Objectives
###

function _zero_objective(model::Optimizer)
    num_vars = length(model.variable_info)
    n = fill(Cint(0), num_vars)
    ret = CPXcopyquad(model.env, model.lp, n, n, Cint[], Cdouble[])
    _check_ret(model, ret)
    ind = convert(Vector{Cint}, 0:(num_vars-1))
    obj = zeros(Float64, num_vars)
    ret = CPXchgobj(model.env, model.lp, length(ind), ind, obj)
    _check_ret(model, ret)
    ret = CPXchgobjoffset(model.env, model.lp, 0.0)
    _check_ret(model, ret)
    return
end

function MOI.set(
    model::Optimizer,
    ::MOI.ObjectiveSense,
    sense::MOI.OptimizationSense,
)
    ret = if sense == MOI.MIN_SENSE
        CPXchgobjsen(model.env, model.lp, CPX_MIN)
    elseif sense == MOI.MAX_SENSE
        CPXchgobjsen(model.env, model.lp, CPX_MAX)
    else
        @assert sense == MOI.FEASIBILITY_SENSE
        _zero_objective(model)
        CPXchgobjsen(model.env, model.lp, CPX_MIN)
    end
    _check_ret(model, ret)
    model.objective_sense = sense
    return
end

function MOI.get(model::Optimizer, ::MOI.ObjectiveSense)
    return something(model.objective_sense, MOI.FEASIBILITY_SENSE)
end

function MOI.set(
    model::Optimizer,
    ::MOI.ObjectiveFunction{F},
    f::F,
) where {F<:MOI.VariableIndex}
    MOI.set(
        model,
        MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(),
        convert(MOI.ScalarAffineFunction{Float64}, f),
    )
    model.objective_type = _SINGLE_VARIABLE
    return
end

function MOI.get(model::Optimizer, ::MOI.ObjectiveFunction{MOI.VariableIndex})
    obj = MOI.get(
        model,
        MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(),
    )
    return convert(MOI.VariableIndex, obj)
end

function MOI.set(
    model::Optimizer,
    ::MOI.ObjectiveFunction{F},
    f::F,
) where {F<:MOI.ScalarAffineFunction{Float64}}
    num_vars = length(model.variable_info)
    if model.objective_type == _SCALAR_QUADRATIC
        # We need to zero out the existing quadratic objective.
        ret = CPXcopyquad(
            model.env,
            model.lp,
            fill(Cint(0), num_vars),
            fill(Cint(0), num_vars),
            Ref{Cint}(),
            Ref{Cdouble}(),
        )
        _check_ret(model, ret)
    end
    obj = zeros(Float64, num_vars)
    for term in f.terms
        col = column(model, term.variable)
        obj[col] += term.coefficient
    end
    ind = convert(Vector{Cint}, 0:(num_vars-1))
    ret = CPXchgobj(model.env, model.lp, num_vars, ind, obj)
    _check_ret(model, ret)
    ret = CPXchgobjoffset(model.env, model.lp, f.constant)
    _check_ret(model, ret)
    model.objective_type = _SCALAR_AFFINE
    return
end

function MOI.get(
    model::Optimizer,
    ::MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}},
)
    if model.objective_type == _SCALAR_QUADRATIC
        error(
            "Unable to get objective function. Currently: $(model.objective_type).",
        )
    end
    dest = zeros(length(model.variable_info))
    ret = CPXgetobj(model.env, model.lp, dest, Cint(0), Cint(length(dest) - 1))
    _check_ret(model, ret)
    terms = MOI.ScalarAffineTerm{Float64}[]
    for (index, info) in model.variable_info
        coefficient = dest[info.column]
        if !iszero(coefficient)
            push!(terms, MOI.ScalarAffineTerm(coefficient, index))
        end
    end
    constant = Ref{Cdouble}()
    ret = CPXgetobjoffset(model.env, model.lp, constant)
    _check_ret(model, ret)
    return MOI.ScalarAffineFunction(terms, constant[])
end

function MOI.set(
    model::Optimizer,
    ::MOI.ObjectiveFunction{F},
    f::F,
) where {F<:MOI.ScalarQuadraticFunction{Float64}}
    a, b, I, J, V = _indices_and_coefficients(model, f)
    n = length(model.variable_info)
    obj = zeros(n)
    for (i, c) in zip(a, b)
        obj[i+1] += c
    end
    ind = convert(Vector{Cint}, 0:(n-1))
    ret = CPXchgobj(model.env, model.lp, n, ind, obj)
    _check_ret(model, ret)
    ret = CPXchgobjoffset(model.env, model.lp, f.constant)
    _check_ret(model, ret)
    Q = SparseArrays.sparse(I .+ 1, J .+ 1, V, n, n)
    Q = Q .+ Q'
    ret = CPXcopyquad(
        model.env,
        model.lp,
        convert(Vector{Cint}, Q.colptr .- 1),
        Cint[Q.colptr[k+1] - Q.colptr[k] for k in 1:n],
        convert(Vector{Cint}, Q.rowval .- 1),
        Q.nzval,
    )
    _check_ret(model, ret)
    model.objective_type = _SCALAR_QUADRATIC
    return
end

function MOI.get(
    model::Optimizer,
    ::MOI.ObjectiveFunction{MOI.ScalarQuadraticFunction{Float64}},
)
    dest = zeros(length(model.variable_info))
    ret = CPXgetobj(model.env, model.lp, dest, Cint(0), Cint(length(dest) - 1))
    _check_ret(model, ret)
    terms = MOI.ScalarAffineTerm{Float64}[]
    for (index, info) in model.variable_info
        coefficient = dest[info.column]
        iszero(coefficient) && continue
        push!(terms, MOI.ScalarAffineTerm(coefficient, index))
    end
    constant = Ref{Cdouble}()
    ret = CPXgetobjoffset(model.env, model.lp, constant)
    _check_ret(model, ret)
    q_terms = MOI.ScalarQuadraticTerm{Float64}[]
    surplus_p = Ref{Cint}()
    ret = CPXgetquad(
        model.env,
        model.lp,
        C_NULL,
        C_NULL,
        C_NULL,
        C_NULL,
        0,
        surplus_p,
        0,
        length(dest) - 1,
    )
    qmatbeg = Vector{Cint}(undef, length(dest))
    qmatind = Vector{Cint}(undef, -surplus_p[])
    qmatval = Vector{Cdouble}(undef, -surplus_p[])
    nzcnt_p = Ref{Cint}()
    ret = CPXgetquad(
        model.env,
        model.lp,
        nzcnt_p,
        qmatbeg,
        qmatind,
        qmatval,
        -surplus_p[],
        surplus_p,
        0,
        length(dest) - 1,
    )
    row = 0
    for (i, (col, val)) in enumerate(zip(qmatind, qmatval))
        if row < length(qmatbeg) && i == (qmatbeg[row+1] + 1)
            row += 1
        end
        push!(
            q_terms,
            MOI.ScalarQuadraticTerm(
                row == col + 1 ? val : 0.5 * val,
                model.variable_info[CleverDicts.LinearIndex(row)].index,
                model.variable_info[CleverDicts.LinearIndex(col + 1)].index,
            ),
        )
    end
    return MOI.Utilities.canonical(
        MOI.ScalarQuadraticFunction(q_terms, terms, constant[]),
    )
end

function MOI.modify(
    model::Optimizer,
    ::MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}},
    chg::MOI.ScalarConstantChange{Float64},
)
    ret = CPXchgobjoffset(model.env, model.lp, chg.new_constant)
    _check_ret(model, ret)
    return
end

##
##  VariableIndex-in-Set constraints.
##

function _info(
    model::Optimizer,
    c::MOI.ConstraintIndex{MOI.VariableIndex,<:Any},
)
    var_index = MOI.VariableIndex(c.value)
    if haskey(model.variable_info, var_index)
        return _info(model, var_index)
    end
    return throw(MOI.InvalidIndex(c))
end

"""
    column(model::Optimizer, c::MOI.ConstraintIndex{MOI.VariableIndex, <:Any})

Return the 1-indexed column associated with `c`.

The C API requires 0-indexed columns.
"""
function column(
    model::Optimizer,
    c::MOI.ConstraintIndex{MOI.VariableIndex,<:Any},
)
    return _info(model, c).column
end

function MOI.is_valid(
    model::Optimizer,
    c::MOI.ConstraintIndex{MOI.VariableIndex,MOI.LessThan{Float64}},
)
    if haskey(model.variable_info, MOI.VariableIndex(c.value))
        info = _info(model, c)
        return info.bound == _LESS_THAN || info.bound == _LESS_AND_GREATER_THAN
    end
    return false
end

function MOI.is_valid(
    model::Optimizer,
    c::MOI.ConstraintIndex{MOI.VariableIndex,MOI.GreaterThan{Float64}},
)
    if haskey(model.variable_info, MOI.VariableIndex(c.value))
        info = _info(model, c)
        return info.bound == _GREATER_THAN ||
               info.bound == _LESS_AND_GREATER_THAN
    end
    return false
end

function MOI.is_valid(
    model::Optimizer,
    c::MOI.ConstraintIndex{MOI.VariableIndex,MOI.Interval{Float64}},
)
    return haskey(model.variable_info, MOI.VariableIndex(c.value)) &&
           _info(model, c).bound == _INTERVAL
end

function MOI.is_valid(
    model::Optimizer,
    c::MOI.ConstraintIndex{MOI.VariableIndex,MOI.EqualTo{Float64}},
)
    return haskey(model.variable_info, MOI.VariableIndex(c.value)) &&
           _info(model, c).bound == _EQUAL_TO
end

function MOI.is_valid(
    model::Optimizer,
    c::MOI.ConstraintIndex{MOI.VariableIndex,MOI.ZeroOne},
)
    return haskey(model.variable_info, MOI.VariableIndex(c.value)) &&
           _info(model, c).type == CPX_BINARY
end

function MOI.is_valid(
    model::Optimizer,
    c::MOI.ConstraintIndex{MOI.VariableIndex,MOI.Integer},
)
    return haskey(model.variable_info, MOI.VariableIndex(c.value)) &&
           _info(model, c).type == CPX_INTEGER
end

function MOI.is_valid(
    model::Optimizer,
    c::MOI.ConstraintIndex{MOI.VariableIndex,MOI.Semicontinuous{Float64}},
)
    return haskey(model.variable_info, MOI.VariableIndex(c.value)) &&
           _info(model, c).type == CPX_SEMICONT
end

function MOI.is_valid(
    model::Optimizer,
    c::MOI.ConstraintIndex{MOI.VariableIndex,MOI.Semiinteger{Float64}},
)
    return haskey(model.variable_info, MOI.VariableIndex(c.value)) &&
           _info(model, c).type == CPX_SEMIINT
end

function MOI.get(
    model::Optimizer,
    ::MOI.ConstraintFunction,
    c::MOI.ConstraintIndex{MOI.VariableIndex,<:Any},
)
    MOI.throw_if_not_valid(model, c)
    return MOI.VariableIndex(c.value)
end

function MOI.set(
    model::Optimizer,
    ::MOI.ConstraintFunction,
    c::MOI.ConstraintIndex{MOI.VariableIndex,<:Any},
    ::MOI.VariableIndex,
)
    return throw(MOI.SettingVariableIndexNotAllowed())
end

_bounds(s::MOI.GreaterThan{Float64}) = (s.lower, nothing)
_bounds(s::MOI.LessThan{Float64}) = (nothing, s.upper)
_bounds(s::MOI.EqualTo{Float64}) = (s.value, s.value)
_bounds(s::MOI.Interval{Float64}) = (s.lower, s.upper)

function _throw_if_existing_lower(
    bound::_BoundType,
    var_type::Char,
    new_set::Type{<:MOI.AbstractSet},
    variable::MOI.VariableIndex,
)
    existing_set = if bound == _LESS_AND_GREATER_THAN || bound == _GREATER_THAN
        MOI.GreaterThan{Float64}
    elseif bound == _INTERVAL
        MOI.Interval{Float64}
    elseif bound == _EQUAL_TO
        MOI.EqualTo{Float64}
    elseif var_type == CPX_SEMIINT
        MOI.Semiinteger{Float64}
    elseif var_type == CPX_SEMICONT
        MOI.Semicontinuous{Float64}
    else
        nothing  # Also covers `_NONE` and `_LESS_THAN`.
    end
    if existing_set !== nothing
        throw(MOI.LowerBoundAlreadySet{existing_set,new_set}(variable))
    end
end

function _throw_if_existing_upper(
    bound::_BoundType,
    var_type::Char,
    new_set::Type{<:MOI.AbstractSet},
    variable::MOI.VariableIndex,
)
    existing_set = if bound == _LESS_AND_GREATER_THAN || bound == _LESS_THAN
        MOI.LessThan{Float64}
    elseif bound == _INTERVAL
        MOI.Interval{Float64}
    elseif bound == _EQUAL_TO
        MOI.EqualTo{Float64}
    elseif var_type == CPX_SEMIINT
        MOI.Semiinteger{Float64}
    elseif var_type == CPX_SEMICONT
        MOI.Semicontinuous{Float64}
    else
        nothing  # Also covers `_NONE` and `_GREATER_THAN`.
    end
    if existing_set !== nothing
        throw(MOI.UpperBoundAlreadySet{existing_set,new_set}(variable))
    end
end

function MOI.add_constraint(
    model::Optimizer,
    f::MOI.VariableIndex,
    s::S,
) where {S<:_SCALAR_SETS}
    info = _info(model, f)
    if S <: MOI.LessThan{Float64}
        _throw_if_existing_upper(info.bound, info.type, S, f)
        info.bound =
            info.bound == _GREATER_THAN ? _LESS_AND_GREATER_THAN : _LESS_THAN
    elseif S <: MOI.GreaterThan{Float64}
        _throw_if_existing_lower(info.bound, info.type, S, f)
        info.bound =
            info.bound == _LESS_THAN ? _LESS_AND_GREATER_THAN : _GREATER_THAN
    elseif S <: MOI.EqualTo{Float64}
        _throw_if_existing_lower(info.bound, info.type, S, f)
        _throw_if_existing_upper(info.bound, info.type, S, f)
        info.bound = _EQUAL_TO
    else
        @assert S <: MOI.Interval{Float64}
        _throw_if_existing_lower(info.bound, info.type, S, f)
        _throw_if_existing_upper(info.bound, info.type, S, f)
        info.bound = _INTERVAL
    end
    index = MOI.ConstraintIndex{MOI.VariableIndex,typeof(s)}(f.value)
    MOI.set(model, MOI.ConstraintSet(), index, s)
    return index
end

function MOI.add_constraints(
    model::Optimizer,
    f::Vector{MOI.VariableIndex},
    s::Vector{S},
) where {S<:_SCALAR_SETS}
    for fi in f
        info = _info(model, fi)
        if S <: MOI.LessThan{Float64}
            _throw_if_existing_upper(info.bound, info.type, S, fi)
            info.bound =
                info.bound == _GREATER_THAN ? _LESS_AND_GREATER_THAN :
                _LESS_THAN
        elseif S <: MOI.GreaterThan{Float64}
            _throw_if_existing_lower(info.bound, info.type, S, fi)
            info.bound =
                info.bound == _LESS_THAN ? _LESS_AND_GREATER_THAN :
                _GREATER_THAN
        elseif S <: MOI.EqualTo{Float64}
            _throw_if_existing_lower(info.bound, info.type, S, fi)
            _throw_if_existing_upper(info.bound, info.type, S, fi)
            info.bound = _EQUAL_TO
        else
            @assert S <: MOI.Interval{Float64}
            _throw_if_existing_lower(info.bound, info.type, S, fi)
            _throw_if_existing_upper(info.bound, info.type, S, fi)
            info.bound = _INTERVAL
        end
    end
    indices =
        [MOI.ConstraintIndex{MOI.VariableIndex,eltype(s)}(fi.value) for fi in f]
    _set_bounds(model, indices, s)
    return indices
end

function _set_bounds(
    model::Optimizer,
    indices::Vector{MOI.ConstraintIndex{MOI.VariableIndex,S}},
    sets::Vector{S},
) where {S}
    columns, senses, values = Cint[], Cchar[], Float64[]
    for (c, s) in zip(indices, sets)
        lower, upper = _bounds(s)
        info = _info(model, c)
        if lower !== nothing
            push!(columns, Cint(info.column - 1))
            push!(senses, Cchar('L'))
            push!(values, lower)
        end
        if upper !== nothing
            push!(columns, Cint(info.column - 1))
            push!(senses, Cchar('U'))
            push!(values, upper)
        end
    end
    ret =
        CPXchgbds(model.env, model.lp, length(columns), columns, senses, values)
    _check_ret(model, ret)
    return
end

function MOI.delete(
    model::Optimizer,
    c::MOI.ConstraintIndex{MOI.VariableIndex,MOI.LessThan{Float64}},
)
    MOI.throw_if_not_valid(model, c)
    info = _info(model, c)
    _set_variable_upper_bound(model, info, Inf)
    if info.bound == _LESS_AND_GREATER_THAN
        info.bound = _GREATER_THAN
    else
        info.bound = _NONE
    end
    model.name_to_constraint_index = nothing
    return
end

"""
    _set_variable_lower_bound(model, info, value)

This function is used to indirectly set the lower bound of a variable.

We need to do it this way to account for potential lower bounds of 0.0 added by
VectorOfVariables-in-SecondOrderCone constraints.

See also `_get_variable_lower_bound`.
"""
function _set_variable_lower_bound(model, info, value)
    if info.num_soc_constraints == 0
        # No SOC constraints, set directly.
        @assert isnan(info.lower_bound_if_soc)
        ret = CPXchgbds(
            model.env,
            model.lp,
            1,
            Ref{Cint}(info.column - 1),
            Ref{Cchar}('L'),
            Ref(value),
        )
        _check_ret(model, ret)
    elseif value >= 0.0
        # Regardless of whether there are SOC constraints, this is a valid bound
        # for the SOC constraint and should over-ride any previous bounds.
        info.lower_bound_if_soc = NaN
        ret = CPXchgbds(
            model.env,
            model.lp,
            1,
            Ref{Cint}(info.column - 1),
            Ref{Cchar}('L'),
            Ref(value),
        )
        _check_ret(model, ret)
    elseif isnan(info.lower_bound_if_soc)
        # Previously, we had a non-negative lower bound (i.e., it was set in the
        # case above). Now we're setting this with a negative one, but there are
        # still some SOC constraints, so we cache `value` and set the variable
        # lower bound to `0.0`.
        @assert value < 0.0
        ret = CPXchgbds(
            model.env,
            model.lp,
            1,
            Ref{Cint}(info.column - 1),
            Ref{Cchar}('L'),
            Ref(0.0),
        )
        _check_ret(model, ret)
        info.lower_bound_if_soc = value
    else
        # Previously, we had a negative lower bound. We're setting this with
        # another negative one, but there are still some SOC constraints.
        @assert info.lower_bound_if_soc < 0.0
        info.lower_bound_if_soc = value
    end
end

"""
    _get_variable_lower_bound(model, info)

Get the current variable lower bound, ignoring a potential bound of `0.0` set
by a second order cone constraint.

See also `_set_variable_lower_bound`.
"""
function _get_variable_lower_bound(model, info)
    if !isnan(info.lower_bound_if_soc)
        # There is a value stored. That means that we must have set a value that
        # was < 0.
        @assert info.lower_bound_if_soc < 0.0
        return info.lower_bound_if_soc
    end
    lb = Ref{Cdouble}()
    ret = CPXgetlb(
        model.env,
        model.lp,
        lb,
        Cint(info.column - 1),
        Cint(info.column - 1),
    )
    _check_ret(model, ret)
    return lb[] == -CPX_INFBOUND ? -Inf : lb[]
end

function _set_variable_upper_bound(model, info, value)
    ret = CPXchgbds(
        model.env,
        model.lp,
        1,
        Ref{Cint}(info.column - 1),
        Ref{Cchar}('U'),
        Ref(value),
    )
    _check_ret(model, ret)
    return
end

function _get_variable_upper_bound(model, info)
    ub = Ref{Cdouble}()
    ret = CPXgetub(
        model.env,
        model.lp,
        ub,
        Cint(info.column - 1),
        Cint(info.column - 1),
    )
    _check_ret(model, ret)
    return ub[] == CPX_INFBOUND ? Inf : ub[]
end

function MOI.delete(
    model::Optimizer,
    c::MOI.ConstraintIndex{MOI.VariableIndex,MOI.GreaterThan{Float64}},
)
    MOI.throw_if_not_valid(model, c)
    info = _info(model, c)
    _set_variable_lower_bound(model, info, -Inf)
    if info.bound == _LESS_AND_GREATER_THAN
        info.bound = _LESS_THAN
    else
        info.bound = _NONE
    end
    model.name_to_constraint_index = nothing
    return
end

function MOI.delete(
    model::Optimizer,
    c::MOI.ConstraintIndex{MOI.VariableIndex,MOI.Interval{Float64}},
)
    MOI.throw_if_not_valid(model, c)
    info = _info(model, c)
    _set_variable_lower_bound(model, info, -Inf)
    _set_variable_upper_bound(model, info, Inf)
    info.bound = _NONE
    model.name_to_constraint_index = nothing
    return
end

function MOI.delete(
    model::Optimizer,
    c::MOI.ConstraintIndex{MOI.VariableIndex,MOI.EqualTo{Float64}},
)
    MOI.throw_if_not_valid(model, c)
    info = _info(model, c)
    _set_variable_lower_bound(model, info, -Inf)
    _set_variable_upper_bound(model, info, Inf)
    info.bound = _NONE
    model.name_to_constraint_index = nothing
    return
end

function MOI.get(
    model::Optimizer,
    ::MOI.ConstraintSet,
    c::MOI.ConstraintIndex{MOI.VariableIndex,MOI.GreaterThan{Float64}},
)
    MOI.throw_if_not_valid(model, c)
    lower = _get_variable_lower_bound(model, _info(model, c))
    return MOI.GreaterThan(lower)
end

function MOI.get(
    model::Optimizer,
    ::MOI.ConstraintSet,
    c::MOI.ConstraintIndex{MOI.VariableIndex,MOI.LessThan{Float64}},
)
    MOI.throw_if_not_valid(model, c)
    upper = _get_variable_upper_bound(model, _info(model, c))
    return MOI.LessThan(upper)
end

function MOI.get(
    model::Optimizer,
    ::MOI.ConstraintSet,
    c::MOI.ConstraintIndex{MOI.VariableIndex,MOI.EqualTo{Float64}},
)
    MOI.throw_if_not_valid(model, c)
    lower = _get_variable_lower_bound(model, _info(model, c))
    return MOI.EqualTo(lower)
end

function MOI.get(
    model::Optimizer,
    ::MOI.ConstraintSet,
    c::MOI.ConstraintIndex{MOI.VariableIndex,MOI.Interval{Float64}},
)
    MOI.throw_if_not_valid(model, c)
    info = _info(model, c)
    lower = _get_variable_lower_bound(model, info)
    upper = _get_variable_upper_bound(model, info)
    return MOI.Interval(lower, upper)
end

function MOI.set(
    model::Optimizer,
    ::MOI.ConstraintSet,
    c::MOI.ConstraintIndex{MOI.VariableIndex,S},
    s::S,
) where {S<:_SCALAR_SETS}
    MOI.throw_if_not_valid(model, c)
    lower, upper = _bounds(s)
    info = _info(model, c)
    if lower !== nothing
        _set_variable_lower_bound(model, info, lower)
    end
    if upper !== nothing
        _set_variable_upper_bound(model, info, upper)
    end
    return
end

function MOI.add_constraint(
    model::Optimizer,
    f::MOI.VariableIndex,
    ::MOI.ZeroOne,
)
    info = _info(model, f)
    col = Cint(info.column - 1)
    p_col = Ref(col)
    ret = CPXchgctype(model.env, model.lp, 1, p_col, Ref{Cchar}(CPX_BINARY))
    # Round bounds to avoid the CPLEX warning:
    #   Warning:  Non-integral bounds for integer variables rounded.
    # See issue https://github.com/jump-dev/CPLEX.jl/issues/311
    ret = if info.bound == _NONE
        CPXchgbds(
            model.env,
            model.lp,
            2,
            Cint[col, col],
            Cchar['L', 'U'],
            [0.0, 1.0],
        )
    elseif info.bound == _GREATER_THAN
        CPXchgbds(model.env, model.lp, 1, p_col, Ref{Cchar}('U'), Ref(1.0))
    elseif info.bound == _LESS_THAN
        CPXchgbds(model.env, model.lp, 1, p_col, Ref{Cchar}('L'), Ref(0.0))
    else
        Cint(0)
    end
    _check_ret(model, ret)
    info.type = CPX_BINARY
    return MOI.ConstraintIndex{MOI.VariableIndex,MOI.ZeroOne}(f.value)
end

function MOI.delete(
    model::Optimizer,
    c::MOI.ConstraintIndex{MOI.VariableIndex,MOI.ZeroOne},
)
    MOI.throw_if_not_valid(model, c)
    info = _info(model, c)
    col = Cint(info.column - 1)
    ret = CPXchgctype(
        model.env,
        model.lp,
        1,
        Ref(col),
        Ref{Cchar}(CPX_CONTINUOUS),
    )
    _check_ret(model, ret)
    # When deleting the ZeroOne bound, reset any bounds that were added. If no
    # _NONE, we added '[0, 1]'. If _GREATER_THAN, we added '1]', if _LESS_THAN,
    # we added '[0'. If it is anything else, both bounds were set by the user,
    # so we don't need to worry.
    ret = if info.bound == _NONE
        CPXchgbds(
            model.env,
            model.lp,
            2,
            [col, col],
            Cchar['L', 'U'],
            [-CPX_INFBOUND, CPX_INFBOUND],
        )
    elseif info.bound == _GREATER_THAN
        CPXchgbds(
            model.env,
            model.lp,
            1,
            Ref(col),
            Ref{Cchar}('U'),
            Ref(CPX_INFBOUND),
        )
    elseif info.bound == _LESS_THAN
        CPXchgbds(
            model.env,
            model.lp,
            1,
            Ref(col),
            Ref{Cchar}('L'),
            Ref(-CPX_INFBOUND),
        )
    else
        Cint(0)
    end
    _check_ret(model, ret)
    info.type = CPX_CONTINUOUS
    model.name_to_constraint_index = nothing
    return
end

function MOI.get(
    model::Optimizer,
    ::MOI.ConstraintSet,
    c::MOI.ConstraintIndex{MOI.VariableIndex,MOI.ZeroOne},
)
    MOI.throw_if_not_valid(model, c)
    return MOI.ZeroOne()
end

function MOI.add_constraint(
    model::Optimizer,
    f::MOI.VariableIndex,
    ::MOI.Integer,
)
    info = _info(model, f)
    ret = CPXchgctype(
        model.env,
        model.lp,
        1,
        Ref{Cint}(info.column - 1),
        Ref{Cchar}(CPX_INTEGER),
    )
    _check_ret(model, ret)
    info.type = CPX_INTEGER
    return MOI.ConstraintIndex{MOI.VariableIndex,MOI.Integer}(f.value)
end

function MOI.delete(
    model::Optimizer,
    c::MOI.ConstraintIndex{MOI.VariableIndex,MOI.Integer},
)
    MOI.throw_if_not_valid(model, c)
    info = _info(model, c)
    ret = CPXchgctype(
        model.env,
        model.lp,
        1,
        Ref{Cint}(info.column - 1),
        Ref{Cchar}(CPX_CONTINUOUS),
    )
    _check_ret(model, ret)
    info.type = CPX_CONTINUOUS
    model.name_to_constraint_index = nothing
    return
end

function MOI.get(
    model::Optimizer,
    ::MOI.ConstraintSet,
    c::MOI.ConstraintIndex{MOI.VariableIndex,MOI.Integer},
)
    MOI.throw_if_not_valid(model, c)
    return MOI.Integer()
end

function MOI.add_constraint(
    model::Optimizer,
    f::MOI.VariableIndex,
    s::MOI.Semicontinuous{Float64},
)
    info = _info(model, f)
    _throw_if_existing_lower(info.bound, info.type, typeof(s), f)
    _throw_if_existing_upper(info.bound, info.type, typeof(s), f)
    ret = CPXchgctype(
        model.env,
        model.lp,
        1,
        Ref{Cint}(info.column - 1),
        Ref{Cchar}(CPX_SEMICONT),
    )
    _check_ret(model, ret)
    _set_variable_lower_bound(model, info, s.lower)
    _set_variable_upper_bound(model, info, s.upper)
    info.type = CPX_SEMICONT
    return MOI.ConstraintIndex{MOI.VariableIndex,MOI.Semicontinuous{Float64}}(
        f.value,
    )
end

function MOI.delete(
    model::Optimizer,
    c::MOI.ConstraintIndex{MOI.VariableIndex,MOI.Semicontinuous{Float64}},
)
    MOI.throw_if_not_valid(model, c)
    info = _info(model, c)
    ret = CPXchgctype(
        model.env,
        model.lp,
        1,
        Ref{Cint}(info.column - 1),
        Ref{Cchar}(CPX_CONTINUOUS),
    )
    _check_ret(model, ret)
    _set_variable_lower_bound(model, info, -Inf)
    _set_variable_upper_bound(model, info, Inf)
    info.type = CPX_CONTINUOUS
    model.name_to_constraint_index = nothing
    return
end

function MOI.get(
    model::Optimizer,
    ::MOI.ConstraintSet,
    c::MOI.ConstraintIndex{MOI.VariableIndex,MOI.Semicontinuous{Float64}},
)
    MOI.throw_if_not_valid(model, c)
    info = _info(model, c)
    lower = _get_variable_lower_bound(model, info)
    upper = _get_variable_upper_bound(model, info)
    return MOI.Semicontinuous(lower, upper)
end

function MOI.add_constraint(
    model::Optimizer,
    f::MOI.VariableIndex,
    s::MOI.Semiinteger{Float64},
)
    info = _info(model, f)
    _throw_if_existing_lower(info.bound, info.type, typeof(s), f)
    _throw_if_existing_upper(info.bound, info.type, typeof(s), f)
    ret = CPXchgctype(
        model.env,
        model.lp,
        1,
        Ref{Cint}(info.column - 1),
        Ref{Cchar}(CPX_SEMIINT),
    )
    _check_ret(model, ret)
    _set_variable_lower_bound(model, info, s.lower)
    _set_variable_upper_bound(model, info, s.upper)
    info.type = CPX_SEMIINT
    return MOI.ConstraintIndex{MOI.VariableIndex,MOI.Semiinteger{Float64}}(
        f.value,
    )
end

function MOI.delete(
    model::Optimizer,
    c::MOI.ConstraintIndex{MOI.VariableIndex,MOI.Semiinteger{Float64}},
)
    MOI.throw_if_not_valid(model, c)
    info = _info(model, c)
    ret = CPXchgctype(
        model.env,
        model.lp,
        1,
        Ref{Cint}(info.column - 1),
        Ref{Cchar}(CPX_CONTINUOUS),
    )
    _check_ret(model, ret)
    _set_variable_lower_bound(model, info, -Inf)
    _set_variable_upper_bound(model, info, Inf)
    info.type = CPX_CONTINUOUS
    model.name_to_constraint_index = nothing
    return
end

function MOI.get(
    model::Optimizer,
    ::MOI.ConstraintSet,
    c::MOI.ConstraintIndex{MOI.VariableIndex,MOI.Semiinteger{Float64}},
)
    MOI.throw_if_not_valid(model, c)
    info = _info(model, c)
    lower = _get_variable_lower_bound(model, info)
    upper = _get_variable_upper_bound(model, info)
    return MOI.Semiinteger(lower, upper)
end

###
### ScalarAffineFunction-in-Set
###

function _info(
    model::Optimizer,
    key::MOI.ConstraintIndex{MOI.ScalarAffineFunction{Float64},<:Any},
)
    if haskey(model.affine_constraint_info, key.value)
        return model.affine_constraint_info[key.value]
    end
    return throw(MOI.InvalidIndex(key))
end

function MOI.is_valid(
    model::Optimizer,
    c::MOI.ConstraintIndex{MOI.ScalarAffineFunction{Float64},S},
) where {S}
    info = get(model.affine_constraint_info, c.value, nothing)
    if info === nothing
        return false
    else
        return typeof(info.set) == S
    end
end

function MOI.add_constraint(
    model::Optimizer,
    f::MOI.ScalarAffineFunction{Float64},
    s::Union{
        MOI.GreaterThan{Float64},
        MOI.LessThan{Float64},
        MOI.EqualTo{Float64},
    },
)
    if !iszero(f.constant)
        throw(
            MOI.ScalarFunctionConstantNotZero{Float64,typeof(f),typeof(s)}(
                f.constant,
            ),
        )
    end
    model.last_constraint_index += 1
    model.affine_constraint_info[model.last_constraint_index] =
        _ConstraintInfo(length(model.affine_constraint_info) + 1, s)
    indices, coefficients = _indices_and_coefficients(model, f)
    sense, rhs = _sense_and_rhs(s)
    ret = CPXaddrows(
        model.env,
        model.lp,
        0,
        1,
        length(indices),
        Ref(rhs),
        Ref{Cchar}(sense),
        Cint[0, length(indices)],
        indices,
        coefficients,
        C_NULL,
        C_NULL,
    )
    _check_ret(model, ret)
    return MOI.ConstraintIndex{typeof(f),typeof(s)}(model.last_constraint_index)
end

function MOI.add_constraints(
    model::Optimizer,
    f::Vector{MOI.ScalarAffineFunction{Float64}},
    s::Vector{
        <:Union{
            MOI.GreaterThan{Float64},
            MOI.LessThan{Float64},
            MOI.EqualTo{Float64},
        },
    },
)
    if length(f) != length(s)
        error("Number of functions does not equal number of sets.")
    end
    canonicalized_functions = MOI.Utilities.canonical.(f)
    # First pass: compute number of non-zeros to allocate space.
    nnz = 0
    for fi in canonicalized_functions
        if !iszero(fi.constant)
            throw(
                MOI.ScalarFunctionConstantNotZero{Float64,eltype(f),eltype(s)}(
                    fi.constant,
                ),
            )
        end
        nnz += length(fi.terms)
    end
    # Initialize storage
    indices = Vector{MOI.ConstraintIndex{eltype(f),eltype(s)}}(undef, length(f))
    row_starts = Vector{Cint}(undef, length(f) + 1)
    row_starts[1] = 0
    columns = Vector{Cint}(undef, nnz)
    coefficients = Vector{Float64}(undef, nnz)
    senses = Vector{Cchar}(undef, length(f))
    rhss = Vector{Float64}(undef, length(f))
    # Second pass: loop through, passing views to _indices_and_coefficients.
    for (i, (fi, si)) in enumerate(zip(canonicalized_functions, s))
        senses[i], rhss[i] = _sense_and_rhs(si)
        row_starts[i+1] = row_starts[i] + length(fi.terms)
        _indices_and_coefficients(
            view(columns, (1+row_starts[i]):row_starts[i+1]),
            view(coefficients, (1+row_starts[i]):row_starts[i+1]),
            model,
            fi,
        )
        model.last_constraint_index += 1
        indices[i] = MOI.ConstraintIndex{eltype(f),eltype(s)}(
            model.last_constraint_index,
        )
        model.affine_constraint_info[model.last_constraint_index] =
            _ConstraintInfo(length(model.affine_constraint_info) + 1, si)
    end
    pop!(row_starts)
    ret = CPXaddrows(
        model.env,
        model.lp,
        0,
        length(f),
        length(coefficients),
        rhss,
        senses,
        row_starts,
        columns,
        coefficients,
        C_NULL,
        C_NULL,
    )
    _check_ret(model, ret)
    return indices
end

function MOI.delete(
    model::Optimizer,
    c::MOI.ConstraintIndex{MOI.ScalarAffineFunction{Float64},<:Any},
)
    row = _info(model, c).row
    ret = CPXdelrows(model.env, model.lp, Cint(row - 1), Cint(row - 1))
    _check_ret(model, ret)
    for (key, info) in model.affine_constraint_info
        if info.row > row
            info.row -= 1
        end
    end
    delete!(model.affine_constraint_info, c.value)
    model.name_to_constraint_index = nothing
    return
end

function MOI.get(
    model::Optimizer,
    ::MOI.ConstraintSet,
    c::MOI.ConstraintIndex{MOI.ScalarAffineFunction{Float64},S},
) where {S}
    rhs = Ref{Cdouble}()
    row = _info(model, c).row
    ret = CPXgetrhs(model.env, model.lp, rhs, Cint(row - 1), Cint(row - 1))
    return S(rhs[])
end

function MOI.set(
    model::Optimizer,
    ::MOI.ConstraintSet,
    c::MOI.ConstraintIndex{MOI.ScalarAffineFunction{Float64},S},
    s::S,
) where {S}
    ret = CPXchgrhs(
        model.env,
        model.lp,
        1,
        Ref{Cint}(_info(model, c).row - 1),
        Ref(MOI.constant(s)),
    )
    _check_ret(model, ret)
    return
end

function MOI.get(
    model::Optimizer,
    ::MOI.ConstraintFunction,
    c::MOI.ConstraintIndex{MOI.ScalarAffineFunction{Float64},S},
) where {S}
    row = Cint(_info(model, c).row - 1)
    surplus_p = Ref{Cint}()
    CPXgetrows(
        model.env,
        model.lp,
        C_NULL,
        C_NULL,
        C_NULL,
        C_NULL,
        0,
        surplus_p,
        row,
        row,
    )
    rmatbeg = Vector{Cint}(undef, 2)
    rmatind = Vector{Cint}(undef, -surplus_p[])
    rmatval = Vector{Cdouble}(undef, -surplus_p[])
    nzcnt_p = Ref{Cint}()
    ret = CPXgetrows(
        model.env,
        model.lp,
        nzcnt_p,
        rmatbeg,
        rmatind,
        rmatval,
        -surplus_p[],
        surplus_p,
        row,
        row,
    )
    _check_ret(model, ret)
    terms = MOI.ScalarAffineTerm{Float64}[]
    for i in 1:nzcnt_p[]
        push!(
            terms,
            MOI.ScalarAffineTerm(
                rmatval[i],
                model.variable_info[CleverDicts.LinearIndex(
                    rmatind[i] + 1,
                )].index,
            ),
        )
    end
    return MOI.ScalarAffineFunction(terms, 0.0)
end

function MOI.get(
    model::Optimizer,
    ::MOI.ConstraintName,
    c::MOI.ConstraintIndex{MOI.ScalarAffineFunction{Float64},<:Any},
)
    return _info(model, c).name
end

function MOI.set(
    model::Optimizer,
    ::MOI.ConstraintName,
    c::MOI.ConstraintIndex{MOI.ScalarAffineFunction{Float64},<:Any},
    name::String,
)
    info = _info(model, c)
    if model.pass_names && info.name != name && isascii(name)
        ret = CPXchgname(
            model.env,
            model.lp,
            Cchar('r'),
            Cint(info.row - 1),
            name,
        )
        _check_ret(model, ret)
    end
    info.name = name
    model.name_to_constraint_index = nothing
    return
end

function MOI.get(model::Optimizer, ::Type{MOI.ConstraintIndex}, name::String)
    if model.name_to_constraint_index === nothing
        _rebuild_name_to_constraint_index(model)
    end
    if haskey(model.name_to_constraint_index, name)
        constr = model.name_to_constraint_index[name]
        if constr === nothing
            error("Duplicate constraint name detected: $(name)")
        end
        return constr
    end
    return nothing
end

function MOI.get(
    model::Optimizer,
    C::Type{MOI.ConstraintIndex{F,S}},
    name::String,
) where {F,S}
    index = MOI.get(model, MOI.ConstraintIndex, name)
    if typeof(index) == C
        return index::MOI.ConstraintIndex{F,S}
    end
    return nothing
end

function _rebuild_name_to_constraint_index(model::Optimizer)
    model.name_to_constraint_index =
        Dict{String,Union{Nothing,MOI.ConstraintIndex}}()
    _rebuild_name_to_constraint_index_util(
        model,
        model.affine_constraint_info,
        MOI.ScalarAffineFunction{Float64},
    )
    _rebuild_name_to_constraint_index_util(
        model,
        model.quadratic_constraint_info,
        MOI.ScalarQuadraticFunction{Float64},
    )
    _rebuild_name_to_constraint_index_util(
        model,
        model.sos_constraint_info,
        MOI.VectorOfVariables,
    )
    return
end

function _rebuild_name_to_constraint_index_util(model::Optimizer, dict, F)
    for (index, info) in dict
        if info.name == ""
            continue
        elseif haskey(model.name_to_constraint_index, info.name)
            model.name_to_constraint_index[info.name] = nothing
        else
            model.name_to_constraint_index[info.name] =
                MOI.ConstraintIndex{F,typeof(info.set)}(index)
        end
    end
    return
end

###
### ScalarQuadraticFunction-in-SCALAR_SET
###

function _info(
    model::Optimizer,
    c::MOI.ConstraintIndex{MOI.ScalarQuadraticFunction{Float64},S},
) where {S}
    if haskey(model.quadratic_constraint_info, c.value)
        return model.quadratic_constraint_info[c.value]
    end
    return throw(MOI.InvalidIndex(c))
end

function MOI.add_constraint(
    model::Optimizer,
    f::MOI.ScalarQuadraticFunction{Float64},
    s::_SCALAR_SETS,
)
    if !iszero(f.constant)
        throw(
            MOI.ScalarFunctionConstantNotZero{Float64,typeof(f),typeof(s)}(
                f.constant,
            ),
        )
    end
    indices, coefficients, I, J, V = _indices_and_coefficients(model, f)
    sense, rhs = _sense_and_rhs(s)
    ret = CPXaddqconstr(
        model.env,
        model.lp,
        length(indices),
        length(V),
        rhs,
        sense,
        indices,
        coefficients,
        I,
        J,
        V,
        C_NULL,
    )
    _check_ret(model, ret)
    model.last_constraint_index += 1
    model.quadratic_constraint_info[model.last_constraint_index] =
        _ConstraintInfo(length(model.quadratic_constraint_info) + 1, s)
    return MOI.ConstraintIndex{MOI.ScalarQuadraticFunction{Float64},typeof(s)}(
        model.last_constraint_index,
    )
end

function MOI.is_valid(
    model::Optimizer,
    c::MOI.ConstraintIndex{MOI.ScalarQuadraticFunction{Float64},S},
) where {S}
    info = get(model.quadratic_constraint_info, c.value, nothing)
    return info !== nothing && typeof(info.set) == S
end

function MOI.delete(
    model::Optimizer,
    c::MOI.ConstraintIndex{MOI.ScalarQuadraticFunction{Float64},S},
) where {S}
    info = _info(model, c)
    ret = CPXdelqconstrs(
        model.env,
        model.lp,
        Cint(info.row - 1),
        Cint(info.row - 1),
    )
    _check_ret(model, ret)
    for (key, info_2) in model.quadratic_constraint_info
        if info_2.row > info.row
            info_2.row -= 1
        end
    end
    delete!(model.quadratic_constraint_info, c.value)
    model.name_to_constraint_index = nothing
    return
end

function MOI.get(
    model::Optimizer,
    ::MOI.ConstraintSet,
    c::MOI.ConstraintIndex{MOI.ScalarQuadraticFunction{Float64},S},
) where {S}
    rhs_p = Ref{Cdouble}()
    ret = CPXgetqconstr(
        model.env,
        model.lp,
        C_NULL,
        C_NULL,
        rhs_p,
        C_NULL,
        C_NULL,
        C_NULL,
        0,
        C_NULL,
        C_NULL,
        C_NULL,
        C_NULL,
        0,
        C_NULL,
        Cint(_info(model, c).row - 1),
    )
    return S(rhs_p[])
end

function _CPXgetqconstr(model::Optimizer, c::MOI.ConstraintIndex)
    row = Cint(_info(model, c).row - 1)
    linsurplus_p, quadsurplus_p = Ref{Cint}(), Ref{Cint}()
    CPXgetqconstr(
        model.env,
        model.lp,
        C_NULL,
        C_NULL,
        C_NULL,
        C_NULL,
        C_NULL,
        C_NULL,
        0,
        linsurplus_p,
        C_NULL,
        C_NULL,
        C_NULL,
        0,
        quadsurplus_p,
        row,
    )
    linind = Vector{Cint}(undef, -linsurplus_p[])
    linval = Vector{Cdouble}(undef, -linsurplus_p[])
    quadrow = Vector{Cint}(undef, -quadsurplus_p[])
    quadcol = Vector{Cint}(undef, -quadsurplus_p[])
    quadval = Vector{Cdouble}(undef, -quadsurplus_p[])
    ret = CPXgetqconstr(
        model.env,
        model.lp,
        Ref{Cint}(),
        Ref{Cint}(),
        Ref{Cdouble}(),
        Ref{Cchar}(),
        linind,
        linval,
        -linsurplus_p[],
        linsurplus_p,
        quadrow,
        quadcol,
        quadval,
        -quadsurplus_p[],
        quadsurplus_p,
        row,
    )
    _check_ret(model, ret)
    return linind, linval, quadrow, quadcol, quadval
end

function MOI.get(
    model::Optimizer,
    ::MOI.ConstraintFunction,
    c::MOI.ConstraintIndex{MOI.ScalarQuadraticFunction{Float64},S},
) where {S}
    a, b, I, J, V = _CPXgetqconstr(model, c)
    affine_terms = MOI.ScalarAffineTerm{Float64}[]
    for (col, coef) in zip(a, b)
        push!(
            affine_terms,
            MOI.ScalarAffineTerm(
                coef,
                model.variable_info[CleverDicts.LinearIndex(col + 1)].index,
            ),
        )
    end
    quadratic_terms = MOI.ScalarQuadraticTerm{Float64}[]
    for (i, j, coef) in zip(I, J, V)
        new_coef = i == j ? 2coef : coef
        push!(
            quadratic_terms,
            MOI.ScalarQuadraticTerm(
                new_coef,
                model.variable_info[CleverDicts.LinearIndex(i + 1)].index,
                model.variable_info[CleverDicts.LinearIndex(j + 1)].index,
            ),
        )
    end
    return MOI.ScalarQuadraticFunction(quadratic_terms, affine_terms, 0.0)
end

function MOI.get(
    model::Optimizer,
    ::MOI.ConstraintName,
    c::MOI.ConstraintIndex{MOI.ScalarQuadraticFunction{Float64},S},
) where {S}
    return _info(model, c).name
end

function MOI.set(
    model::Optimizer,
    ::MOI.ConstraintName,
    c::MOI.ConstraintIndex{MOI.ScalarQuadraticFunction{Float64},S},
    name::String,
) where {S}
    info = _info(model, c)
    info.name = name
    model.name_to_constraint_index = nothing
    return
end

###
### VectorOfVariables-in-SOS{I|II}
###

const _SOS = Union{MOI.SOS1{Float64},MOI.SOS2{Float64}}

function _info(
    model::Optimizer,
    key::MOI.ConstraintIndex{MOI.VectorOfVariables,<:_SOS},
)
    if haskey(model.sos_constraint_info, key.value)
        return model.sos_constraint_info[key.value]
    end
    return throw(MOI.InvalidIndex(key))
end

_sos_type(::MOI.SOS1) = CPX_TYPE_SOS1
_sos_type(::MOI.SOS2) = CPX_TYPE_SOS2

function MOI.is_valid(
    model::Optimizer,
    c::MOI.ConstraintIndex{MOI.VectorOfVariables,S},
) where {S}
    info = get(model.sos_constraint_info, c.value, nothing)
    if info === nothing || typeof(info.set) != S
        return false
    end
    f = MOI.get(model, MOI.ConstraintFunction(), c)
    return all(MOI.is_valid.(model, f.variables))
end

function MOI.add_constraint(model::Optimizer, f::MOI.VectorOfVariables, s::_SOS)
    columns = Cint[column(model, v) - 1 for v in f.variables]
    ret = CPXaddsos(
        model.env,
        model.lp,
        1,
        length(columns),
        Ref{Cchar}(_sos_type(s)),
        Ref{Cint}(0),
        columns,
        s.weights,
        C_NULL,
    )
    _check_ret(model, ret)
    model.last_constraint_index += 1
    index = MOI.ConstraintIndex{MOI.VectorOfVariables,typeof(s)}(
        model.last_constraint_index,
    )
    model.sos_constraint_info[index.value] =
        _ConstraintInfo(length(model.sos_constraint_info) + 1, s)
    return index
end

function MOI.delete(
    model::Optimizer,
    c::MOI.ConstraintIndex{MOI.VectorOfVariables,<:_SOS},
)
    row = Cint(_info(model, c).row - 1)
    ret = CPXdelsos(model.env, model.lp, row, row)
    _check_ret(model, ret)
    for (key, info) in model.sos_constraint_info
        if info.row > row
            info.row -= 1
        end
    end
    delete!(model.sos_constraint_info, c.value)
    model.name_to_constraint_index = nothing
    return
end

function MOI.get(
    model::Optimizer,
    ::MOI.ConstraintName,
    c::MOI.ConstraintIndex{MOI.VectorOfVariables,<:Any},
)
    return _info(model, c).name
end

function MOI.set(
    model::Optimizer,
    ::MOI.ConstraintName,
    c::MOI.ConstraintIndex{MOI.VectorOfVariables,<:Any},
    name::String,
)
    info = _info(model, c)
    info.name = name
    model.name_to_constraint_index = nothing
    return
end

function MOI.get(
    model::Optimizer,
    ::MOI.ConstraintSet,
    c::MOI.ConstraintIndex{MOI.VectorOfVariables,S},
) where {S<:_SOS}
    surplus_p = Ref{Cint}()
    row = Cint(_info(model, c).row - 1)
    CPXgetsos(
        model.env,
        model.lp,
        C_NULL,
        C_NULL,
        C_NULL,
        C_NULL,
        C_NULL,
        0,
        surplus_p,
        row,
        row,
    )
    sosind = Vector{Cint}(undef, -surplus_p[])
    soswt = Vector{Cdouble}(undef, -surplus_p[])
    ret = CPXgetsos(
        model.env,
        model.lp,
        Ref{Cint}(),
        Ref{Cchar}(),
        Ref{Cint}(),
        sosind,
        soswt,
        -surplus_p[],
        surplus_p,
        row,
        row,
    )
    _check_ret(model, ret)
    return S(soswt)
end

function MOI.get(
    model::Optimizer,
    ::MOI.ConstraintFunction,
    c::MOI.ConstraintIndex{MOI.VectorOfVariables,S},
) where {S<:_SOS}
    surplus_p = Ref{Cint}()
    row = Cint(_info(model, c).row - 1)
    CPXgetsos(
        model.env,
        model.lp,
        C_NULL,
        C_NULL,
        C_NULL,
        C_NULL,
        C_NULL,
        0,
        surplus_p,
        row,
        row,
    )
    sosind = Vector{Cint}(undef, -surplus_p[])
    soswt = Vector{Cdouble}(undef, -surplus_p[])
    ret = CPXgetsos(
        model.env,
        model.lp,
        Ref{Cint}(),
        Ref{Cchar}(),
        Ref{Cint}(),
        sosind,
        soswt,
        -surplus_p[],
        surplus_p,
        row,
        row,
    )
    _check_ret(model, ret)
    return MOI.VectorOfVariables([
        model.variable_info[CleverDicts.LinearIndex(i + 1)].index for
        i in sosind
    ])
end

###
### Optimize methods.
###

function _check_moi_callback_validity(model::Optimizer)
    has_moi_callback =
        model.lazy_callback !== nothing ||
        model.user_cut_callback !== nothing ||
        model.heuristic_callback !== nothing
    if has_moi_callback && model.has_generic_callback
        error(
            "Cannot use CPLEX.CallbackFunction as well as MOI.AbstractCallbackFunction",
        )
    end
    return has_moi_callback
end

function _make_problem_type_continuous(model::Optimizer)
    prob_type = CPXgetprobtype(model.env, model.lp)
    # There are prob_types other than the ones listed here, but the
    # CPLEX.Optimizer should never encounter them.
    if prob_type == CPXPROB_MILP
        ret = CPXchgprobtype(model.env, model.lp, CPXPROB_LP)
        _check_ret(model, ret)
    elseif prob_type == CPXPROB_MIQP
        ret = CPXchgprobtype(model.env, model.lp, CPXPROB_QP)
        _check_ret(model, ret)
    elseif prob_type == CPXPROB_MIQCP
        ret = CPXchgprobtype(model.env, model.lp, CPXPROB_QCP)
        _check_ret(model, ret)
    end
    return
end

function _has_discrete_variables(model::Optimizer)
    if length(model.sos_constraint_info) > 0
        return true
    end
    return any(v -> v.type != CPX_CONTINUOUS, values(model.variable_info))
end

function _optimize!(model)
    prob_type = CPXgetprobtype(model.env, model.lp)
    # There are prob_types other than the ones listed here, but the
    # CPLEX.Optimizer should never encounter them.
    ret = if prob_type in (CPXPROB_MILP, CPXPROB_MIQP, CPXPROB_MIQCP)
        CPXmipopt(model.env, model.lp)
    elseif prob_type in (CPXPROB_QP, CPXPROB_QCP)
        CPXqpopt(model.env, model.lp)
    else
        @assert prob_type == CPXPROB_LP
        CPXlpopt(model.env, model.lp)
    end
    model.ret_optimize = ret
    _check_ret_optimize(model)
    return
end

function MOI.optimize!(model::Optimizer)
    if _check_moi_callback_validity(model)
        context_mask = UInt16(0)
        if model.lazy_callback !== nothing
            context_mask |= CPX_CALLBACKCONTEXT_CANDIDATE
        end
        if model.user_cut_callback !== nothing ||
           model.heuristic_callback !== nothing
            context_mask |= CPX_CALLBACKCONTEXT_RELAXATION
        end
        MOI.set(
            model,
            CallbackFunction(context_mask),
            _default_moi_callback(model),
        )
        model.has_generic_callback = false
    end
    if _has_discrete_variables(model)
        varindices = Cint[]
        values = Float64[]
        for (key, info) in model.variable_info
            if info.start !== nothing
                push!(varindices, Cint(info.column - 1))
                push!(values, info.start)
            end
        end
        if length(varindices) > 0
            ret = CPXaddmipstarts(
                model.env,
                model.lp,
                1,
                length(varindices),
                Ref{Cint}(0),
                varindices,
                values,
                Ref{Cint}(CPX_MIPSTART_AUTO),
                C_NULL,
            )
            _check_ret(model, ret)
        end
    else
        # CPLEX is annoying. If you add a discrete constraint, then delete it,
        # CPLEX _DOES NOT_ change the prob type back to the continuous version.
        # That means we dispatch to mipopt instead of lpopt/qpopt and we fail to
        # compute the expected dual information. Force the change here if
        # needed.
        _make_problem_type_continuous(model)
    end
    start_time = time()

    # Catch [CTRL+C], even when Julia is run from a script not in interactive
    # mode. If `true`, then a script would call `atexit` without throwing the
    # `InterruptException`. `false` is the default in interactive mode.
    #
    # TODO(odow): Julia 1.5 exposes `Base.exit_on_sigint(::Bool)`.
    ccall(:jl_exit_on_sigint, Cvoid, (Cint,), false)
    _optimize!(model)
    if !isinteractive()
        ccall(:jl_exit_on_sigint, Cvoid, (Cint,), true)
    end

    model.solve_time = time() - start_time
    model.has_primal_certificate = false
    model.has_dual_certificate = false
    if MOI.get(model, MOI.PrimalStatus()) == MOI.INFEASIBILITY_CERTIFICATE
        resize!(model.certificate, length(model.variable_info))
        ret = CPXgetray(model.env, model.lp, model.certificate)
        _check_ret(model, ret)
        model.has_primal_certificate = true
    elseif MOI.get(model, MOI.DualStatus()) == MOI.INFEASIBILITY_CERTIFICATE
        resize!(model.certificate, length(model.affine_constraint_info))
        ret = CPXdualfarkas(model.env, model.lp, model.certificate, C_NULL)
        _check_ret(model, ret)
        model.has_dual_certificate = true
    end
    model.variable_primal = nothing
    return
end

function _throw_if_optimize_in_progress(model, attr)
    if model.callback_state != _CB_NONE
        throw(MOI.OptimizeInProgress(attr))
    end
end

function MOI.get(model::Optimizer, attr::MOI.RawStatusString)
    _throw_if_optimize_in_progress(model, attr)
    if haskey(_ERROR_TO_STATUS, model.ret_optimize)
        return _get_error_string(model.env, model.ret_optimize)
    end
    stat = CPXgetstat(model.env, model.lp)
    buffer_str = Vector{Cchar}(undef, CPXMESSAGEBUFSIZE)
    p = CPXgetstatstring(model.env, stat, buffer_str)
    return unsafe_string(p)
end

# These status symbols are taken from libcpx_common at CPLEX 12.10.
const _TERMINATION_STATUSES = Dict(
    CPX_STAT_ABORT_DETTIME_LIM => MOI.TIME_LIMIT,
    CPX_STAT_ABORT_DUAL_OBJ_LIM => MOI.OBJECTIVE_LIMIT,
    CPX_STAT_ABORT_IT_LIM => MOI.ITERATION_LIMIT,
    CPX_STAT_ABORT_OBJ_LIM => MOI.OBJECTIVE_LIMIT,
    CPX_STAT_ABORT_PRIM_OBJ_LIM => MOI.OBJECTIVE_LIMIT,
    CPX_STAT_ABORT_TIME_LIM => MOI.TIME_LIMIT,
    CPX_STAT_ABORT_USER => MOI.INTERRUPTED,
    CPX_STAT_BENDERS_NUM_BEST => MOI.NUMERICAL_ERROR,
    CPX_STAT_CONFLICT_ABORT_CONTRADICTION => MOI.LOCALLY_INFEASIBLE,
    CPX_STAT_CONFLICT_ABORT_DETTIME_LIM => MOI.TIME_LIMIT,
    CPX_STAT_CONFLICT_ABORT_IT_LIM => MOI.ITERATION_LIMIT,
    CPX_STAT_CONFLICT_ABORT_MEM_LIM => MOI.MEMORY_LIMIT,
    CPX_STAT_CONFLICT_ABORT_NODE_LIM => MOI.NODE_LIMIT,
    CPX_STAT_CONFLICT_ABORT_OBJ_LIM => MOI.OBJECTIVE_LIMIT,
    CPX_STAT_CONFLICT_ABORT_TIME_LIM => MOI.TIME_LIMIT,
    CPX_STAT_CONFLICT_ABORT_USER => MOI.INTERRUPTED,
    CPX_STAT_CONFLICT_FEASIBLE => MOI.LOCALLY_SOLVED,
    CPX_STAT_CONFLICT_MINIMAL => MOI.INFEASIBLE,
    CPX_STAT_FEASIBLE => MOI.LOCALLY_SOLVED,
    CPX_STAT_FEASIBLE_RELAXED_INF => MOI.LOCALLY_SOLVED,
    CPX_STAT_FEASIBLE_RELAXED_QUAD => MOI.LOCALLY_SOLVED,
    CPX_STAT_FEASIBLE_RELAXED_SUM => MOI.LOCALLY_SOLVED,
    CPX_STAT_FIRSTORDER => MOI.LOCALLY_SOLVED,
    CPX_STAT_INFEASIBLE => MOI.INFEASIBLE,
    CPX_STAT_INForUNBD => MOI.INFEASIBLE_OR_UNBOUNDED,
    CPX_STAT_MULTIOBJ_INFEASIBLE => MOI.INFEASIBLE,
    CPX_STAT_MULTIOBJ_INForUNBD => MOI.INFEASIBLE_OR_UNBOUNDED,
    CPX_STAT_MULTIOBJ_NON_OPTIMAL => MOI.LOCALLY_SOLVED,
    CPX_STAT_MULTIOBJ_OPTIMAL => MOI.OPTIMAL,
    CPX_STAT_MULTIOBJ_STOPPED => MOI.INTERRUPTED,
    CPX_STAT_MULTIOBJ_UNBOUNDED => MOI.DUAL_INFEASIBLE,
    CPX_STAT_NUM_BEST => MOI.NUMERICAL_ERROR,
    CPX_STAT_OPTIMAL => MOI.OPTIMAL,
    CPX_STAT_OPTIMAL_FACE_UNBOUNDED => MOI.DUAL_INFEASIBLE,
    CPX_STAT_OPTIMAL_INFEAS => MOI.ALMOST_INFEASIBLE,
    CPX_STAT_OPTIMAL_RELAXED_INF => MOI.LOCALLY_SOLVED,
    CPX_STAT_OPTIMAL_RELAXED_QUAD => MOI.LOCALLY_SOLVED,
    CPX_STAT_OPTIMAL_RELAXED_SUM => MOI.LOCALLY_SOLVED,
    CPX_STAT_UNBOUNDED => MOI.DUAL_INFEASIBLE,
    CPXMIP_ABORT_FEAS => MOI.INTERRUPTED,
    CPXMIP_ABORT_INFEAS => MOI.INTERRUPTED,
    CPXMIP_ABORT_RELAXATION_UNBOUNDED => MOI.INFEASIBLE_OR_UNBOUNDED,
    CPXMIP_ABORT_RELAXED => MOI.LOCALLY_SOLVED,
    CPXMIP_DETTIME_LIM_FEAS => MOI.TIME_LIMIT,
    CPXMIP_DETTIME_LIM_INFEAS => MOI.TIME_LIMIT,
    CPXMIP_FAIL_FEAS => MOI.LOCALLY_SOLVED,
    CPXMIP_FAIL_FEAS_NO_TREE => MOI.LOCALLY_SOLVED,
    CPXMIP_FAIL_INFEAS => MOI.OTHER_ERROR,
    CPXMIP_FAIL_INFEAS_NO_TREE => MOI.MEMORY_LIMIT,
    CPXMIP_FEASIBLE => MOI.LOCALLY_SOLVED,
    CPXMIP_FEASIBLE_RELAXED_INF => MOI.LOCALLY_SOLVED,
    CPXMIP_FEASIBLE_RELAXED_QUAD => MOI.LOCALLY_SOLVED,
    CPXMIP_FEASIBLE_RELAXED_SUM => MOI.LOCALLY_SOLVED,
    CPXMIP_INFEASIBLE => MOI.INFEASIBLE,
    CPXMIP_INForUNBD => MOI.INFEASIBLE_OR_UNBOUNDED,
    CPXMIP_MEM_LIM_FEAS => MOI.MEMORY_LIMIT,
    CPXMIP_MEM_LIM_INFEAS => MOI.MEMORY_LIMIT,
    CPXMIP_NODE_LIM_FEAS => MOI.NODE_LIMIT,
    CPXMIP_NODE_LIM_INFEAS => MOI.NODE_LIMIT,
    CPXMIP_OPTIMAL => MOI.OPTIMAL,
    CPXMIP_OPTIMAL_INFEAS => MOI.INFEASIBLE,
    CPXMIP_OPTIMAL_POPULATED => MOI.OPTIMAL,
    CPXMIP_OPTIMAL_POPULATED_TOL => MOI.OPTIMAL,
    CPXMIP_OPTIMAL_RELAXED_INF => MOI.LOCALLY_SOLVED,
    CPXMIP_OPTIMAL_RELAXED_QUAD => MOI.LOCALLY_SOLVED,
    CPXMIP_OPTIMAL_RELAXED_SUM => MOI.LOCALLY_SOLVED,
    CPXMIP_OPTIMAL_TOL => MOI.OPTIMAL,
    CPXMIP_POPULATESOL_LIM => MOI.SOLUTION_LIMIT,
    CPXMIP_SOL_LIM => MOI.SOLUTION_LIMIT,
    CPXMIP_TIME_LIM_FEAS => MOI.TIME_LIMIT,
    CPXMIP_TIME_LIM_INFEAS => MOI.TIME_LIMIT,
    CPXMIP_UNBOUNDED => MOI.DUAL_INFEASIBLE,
)

function MOI.get(model::Optimizer, attr::MOI.TerminationStatus)
    _throw_if_optimize_in_progress(model, attr)
    if haskey(_ERROR_TO_STATUS, model.ret_optimize)
        return _ERROR_TO_STATUS[model.ret_optimize]
    end
    stat = CPXgetstat(model.env, model.lp)
    if stat == 0
        return MOI.OPTIMIZE_NOT_CALLED
    end
    term_stat = get(_TERMINATION_STATUSES, stat, nothing)
    if term_stat === nothing
        @warn("""
        Termination status $(stat) is not wrapped by CPLEX.jl. CPLEX explains
        this status as follows:

        $(MOI.get(model, MOI.RawStatusString()))

        Please open an issue at https://github.com/jump-dev/CPLEX.jl/issues and
        provide the complete text of this error message.
        """)
        return MOI.OTHER_ERROR
    end
    return term_stat
end

function MOI.get(model::Optimizer, attr::MOI.PrimalStatus)
    _throw_if_optimize_in_progress(model, attr)
    if attr.result_index != 1
        return MOI.NO_SOLUTION
    end
    solnmethod_p, solntype_p, pfeas_p = Ref{Cint}(), Ref{Cint}(), Ref{Cint}()
    ret = CPXsolninfo(model.env, model.lp, C_NULL, solntype_p, pfeas_p, C_NULL)
    _check_ret(model, ret)
    stat = CPXgetstat(model.env, model.lp)
    if stat == CPX_STAT_UNBOUNDED
        return MOI.INFEASIBILITY_CERTIFICATE
    end
    if pfeas_p[] > 0 && solntype_p[] != CPX_NO_SOLN
        return MOI.FEASIBLE_POINT
    end
    return MOI.NO_SOLUTION
end

function MOI.get(model::Optimizer, attr::MOI.DualStatus)
    _throw_if_optimize_in_progress(model, attr)
    if attr.result_index != 1
        return MOI.NO_SOLUTION
    end
    solnmethod_p, solntype_p, dfeas_p = Ref{Cint}(), Ref{Cint}(), Ref{Cint}()
    ret = CPXsolninfo(
        model.env,
        model.lp,
        solnmethod_p,
        solntype_p,
        C_NULL,
        dfeas_p,
    )
    _check_ret(model, ret)
    stat = CPXgetstat(model.env, model.lp)
    if stat == CPX_STAT_INFEASIBLE && solnmethod_p[] == CPX_ALG_DUAL
        # Dual farkas only available when model is infeasible and CPXdualopt
        # used as the solution method.
        return MOI.INFEASIBILITY_CERTIFICATE
    end
    if dfeas_p[] == 0
        return MOI.NO_SOLUTION
    elseif solntype_p[] == CPX_PRIMAL_SOLN || solntype_p[] == CPX_NO_SOLN
        return MOI.NO_SOLUTION
    else
        return MOI.FEASIBLE_POINT
    end
end

_update_cache(::Optimizer, data::Vector{Float64}) = data

function _update_cache(model::Optimizer, ::Nothing)
    n = length(model.variable_info)
    x = zeros(n)
    ret = CPXgetx(model.env, model.lp, x, 0, n - 1)
    _check_ret(model, ret)
    return x
end

function MOI.get(
    model::Optimizer,
    attr::MOI.VariablePrimal,
    x::Union{MOI.VariableIndex,Vector{MOI.VariableIndex}},
)
    _throw_if_optimize_in_progress(model, attr)
    MOI.check_result_index_bounds(model, attr)
    if model.has_primal_certificate
        return model.certificate[column(model, x)]
    end
    model.variable_primal = _update_cache(model, model.variable_primal)
    return model.variable_primal[column(model, x)]
end

function MOI.get(
    model::Optimizer,
    attr::MOI.ConstraintPrimal,
    c::MOI.ConstraintIndex{MOI.VariableIndex,<:Any},
)
    _throw_if_optimize_in_progress(model, attr)
    MOI.check_result_index_bounds(model, attr)
    return MOI.get(model, MOI.VariablePrimal(), MOI.VariableIndex(c.value))
end

function MOI.get(
    model::Optimizer,
    attr::MOI.ConstraintPrimal,
    c::MOI.ConstraintIndex{MOI.ScalarAffineFunction{Float64},<:Any},
)
    _throw_if_optimize_in_progress(model, attr)
    MOI.check_result_index_bounds(model, attr)
    row = Cint(_info(model, c).row - 1)
    ax = Ref{Cdouble}()
    ret = CPXgetax(model.env, model.lp, ax, row, row)
    _check_ret(model, ret)
    return ax[]
end

function MOI.get(
    model::Optimizer,
    attr::MOI.ConstraintPrimal,
    c::MOI.ConstraintIndex{MOI.ScalarQuadraticFunction{Float64},<:Any},
)
    _throw_if_optimize_in_progress(model, attr)
    MOI.check_result_index_bounds(model, attr)
    row = Cint(_info(model, c).row - 1)
    xqxax = Ref{Cdouble}()
    ret = CPXgetxqxax(model.env, model.lp, xqxax, row, row)
    _check_ret(model, ret)
    return xqxax[]
end

function _dual_multiplier(model::Optimizer)
    return MOI.get(model, MOI.ObjectiveSense()) == MOI.MIN_SENSE ? 1.0 : -1.0
end

"""
    _farkas_variable_dual(model::Optimizer, col::Cint)

Return a Farkas dual associated with the variable bounds of `col`.

Compute the Farkas dual as:

    ā * x = λ' * A * x <= λ' * b = -β + sum(āᵢ * Uᵢ | āᵢ < 0) + sum(āᵢ * Lᵢ | āᵢ > 0)

The Farkas dual of the variable is ā, and it applies to the upper bound if ā < 0,
and it applies to the lower bound if ā > 0.
"""
function _farkas_variable_dual(model::Optimizer, col::Cint)
    nzcnt_p, surplus_p = Ref{Cint}(), Ref{Cint}()
    cmatbeg = Vector{Cint}(undef, 2)
    ret = CPXgetcols(
        model.env,
        model.lp,
        nzcnt_p,
        cmatbeg,
        C_NULL,
        C_NULL,
        Cint(0),
        surplus_p,
        col,
        col,
    )
    cmatind = Vector{Cint}(undef, -surplus_p[])
    cmatval = Vector{Cdouble}(undef, -surplus_p[])
    ret = CPXgetcols(
        model.env,
        model.lp,
        nzcnt_p,
        cmatbeg,
        cmatind,
        cmatval,
        -surplus_p[],
        surplus_p,
        col,
        col,
    )
    _check_ret(model, ret)
    return sum(v * model.certificate[i+1] for (i, v) in zip(cmatind, cmatval))
end

function MOI.get(
    model::Optimizer,
    attr::MOI.ConstraintDual,
    c::MOI.ConstraintIndex{MOI.VariableIndex,MOI.LessThan{Float64}},
)
    _throw_if_optimize_in_progress(model, attr)
    MOI.check_result_index_bounds(model, attr)
    col = Cint(column(model, c) - 1)
    if model.has_dual_certificate
        dual = -_farkas_variable_dual(model, col)
        return min(0.0, dual)
    end
    p = Ref{Cdouble}()
    ret = CPXgetdj(model.env, model.lp, p, col, col)
    _check_ret(model, ret)
    sense = MOI.get(model, MOI.ObjectiveSense())
    # The following is a heuristic for determining whether the reduced cost
    # applies to the lower or upper bound. It can be wrong by at most
    # `FeasibilityTol`.
    if sense == MOI.MIN_SENSE && p[] < 0
        # If minimizing, the reduced cost must be negative (ignoring
        # tolerances).
        return p[]
    elseif sense == MOI.MAX_SENSE && p[] > 0
        # If minimizing, the reduced cost must be positive (ignoring
        # tolerances). However, because of the MOI dual convention, we return a
        # negative value.
        return -p[]
    else
        # The reduced cost, if non-zero, must related to the lower bound.
        return 0.0
    end
end

function MOI.get(
    model::Optimizer,
    attr::MOI.ConstraintDual,
    c::MOI.ConstraintIndex{MOI.VariableIndex,MOI.GreaterThan{Float64}},
)
    _throw_if_optimize_in_progress(model, attr)
    MOI.check_result_index_bounds(model, attr)
    col = Cint(column(model, c) - 1)
    if model.has_dual_certificate
        dual = -_farkas_variable_dual(model, col)
        return max(0.0, dual)
    end
    p = Ref{Cdouble}()
    ret = CPXgetdj(model.env, model.lp, p, col, col)
    _check_ret(model, ret)
    sense = MOI.get(model, MOI.ObjectiveSense())
    # The following is a heuristic for determining whether the reduced cost
    # applies to the lower or upper bound. It can be wrong by at most
    # `FeasibilityTol`.
    if sense == MOI.MIN_SENSE && p[] > 0
        # If minimizing, the reduced cost must be negative (ignoring
        # tolerances).
        return p[]
    elseif sense == MOI.MAX_SENSE && p[] < 0
        # If minimizing, the reduced cost must be positive (ignoring
        # tolerances). However, because of the MOI dual convention, we return a
        # negative value.
        return -p[]
    else
        # The reduced cost, if non-zero, must related to the lower bound.
        return 0.0
    end
end

function MOI.get(
    model::Optimizer,
    attr::MOI.ConstraintDual,
    c::MOI.ConstraintIndex{
        MOI.VariableIndex,
        <:Union{MOI.Interval{Float64},MOI.EqualTo{Float64}},
    },
)
    _throw_if_optimize_in_progress(model, attr)
    MOI.check_result_index_bounds(model, attr)
    col = Cint(column(model, c) - 1)
    if model.has_dual_certificate
        return -_farkas_variable_dual(model, col)
    end
    p = Ref{Cdouble}()
    ret = CPXgetdj(model.env, model.lp, p, col, col)
    _check_ret(model, ret)
    return _dual_multiplier(model) * p[]
end

function MOI.get(
    model::Optimizer,
    attr::MOI.ConstraintDual,
    c::MOI.ConstraintIndex{MOI.ScalarAffineFunction{Float64},<:Any},
)
    _throw_if_optimize_in_progress(model, attr)
    MOI.check_result_index_bounds(model, attr)
    row = Cint(_info(model, c).row - 1)
    if model.has_dual_certificate
        return model.certificate[row+1]
    end
    p = Ref{Cdouble}()
    ret = CPXgetpi(model.env, model.lp, p, row, row)
    _check_ret(model, ret)
    return _dual_multiplier(model) * p[]
end

function MOI.get(
    model::Optimizer,
    attr::MOI.ConstraintDual,
    c::MOI.ConstraintIndex{MOI.ScalarQuadraticFunction{Float64},<:Any},
)
    # For more information on QCP duals, see
    # https://www.ibm.com/support/knowledgecenter/SSSA5P_12.10.0/ilog.odms.cplex.help/CPLEX/UsrMan/topics/cont_optim/qcp/17_QCP_duals.html
    _throw_if_optimize_in_progress(model, attr)
    MOI.check_result_index_bounds(model, attr)
    if model.has_dual_certificate
        error("Infeasibility certificate not available for $(c)")
    end
    # The derivative of a quadratic f(x) = x^TQx + a^Tx + b <= 0 is
    # ∇f(x) = Q^Tx + Qx + a
    # The dual is undefined if x is at the point of the cone. This can only be
    # checked to numeric tolerances. We use `cone_top_tol`.
    cone_top, cone_top_tol = true, 1e-6
    x = zeros(length(model.variable_info))
    ret = CPXgetx(model.env, model.lp, x, 0, length(x) - 1)
    _check_ret(model, ret)
    ∇f = zeros(length(x))
    a_i, a_v, qrow, qcol, qval = _CPXgetqconstr(model, c)
    for (i, j, v) in zip(qrow, qcol, qval)
        ∇f[i+1] += v * x[j+1]
        ∇f[j+1] += v * x[i+1]
        if abs(x[i+1]) > cone_top_tol || abs(x[j+1]) > cone_top_tol
            cone_top = false
        end
    end
    for (i, v) in zip(a_i, a_v)
        ∇f[i+1] += v
        if abs(x[i+1]) > cone_top_tol
            cone_top = false
        end
    end
    # TODO(odow): if at top of cone (x = 0) dual multiplier is ill-formed.
    if cone_top
        return NaN
    end
    qind = Cint(_info(model, c).row - 1)
    nz_p, surplus_p = Ref{Cint}(), Ref{Cint}()
    CPXgetqconstrdslack(
        model.env,
        model.lp,
        qind,
        nz_p,
        C_NULL,
        C_NULL,
        0,
        surplus_p,
    )
    ind = Vector{Cint}(undef, -surplus_p[])
    val = Vector{Cdouble}(undef, -surplus_p[])
    ret = CPXgetqconstrdslack(
        model.env,
        model.lp,
        qind,
        nz_p,
        ind,
        val,
        -surplus_p[],
        surplus_p,
    )
    _check_ret(model, ret)
    ∇f_max, ∇f_i = findmax(abs.(∇f))
    if ∇f_max > cone_top_tol
        for (i, v) in zip(ind, val)
            if i + 1 == ∇f_i
                return _dual_multiplier(model) * v / ∇f[∇f_i]
            end
        end
    end
    return 0.0
end

function MOI.get(model::Optimizer, attr::MOI.ObjectiveValue)
    _throw_if_optimize_in_progress(model, attr)
    MOI.check_result_index_bounds(model, attr)
    p = Ref{Cdouble}()
    ret = CPXgetobjval(model.env, model.lp, p)
    _check_ret(model, ret)
    return p[]
end

function MOI.get(model::Optimizer, attr::MOI.ObjectiveBound)
    _throw_if_optimize_in_progress(model, attr)
    p = Ref{Cdouble}()
    ret = CPXgetbestobjval(model.env, model.lp, p)
    if ret == CPXERR_NOT_MIP
        ret = CPXgetobjval(model.env, model.lp, p)
    end
    _check_ret(model, ret)
    return p[]
end

function MOI.get(model::Optimizer, attr::MOI.SolveTimeSec)
    _throw_if_optimize_in_progress(model, attr)
    return model.solve_time
end

function MOI.get(model::Optimizer, attr::MOI.SimplexIterations)
    _throw_if_optimize_in_progress(model, attr)
    return convert(Int64, CPXgetitcnt(model.env, model.lp))
end

function MOI.get(model::Optimizer, attr::MOI.BarrierIterations)
    _throw_if_optimize_in_progress(model, attr)
    return convert(Int64, CPXgetbaritcnt(model.env, model.lp))
end

function MOI.get(model::Optimizer, attr::MOI.NodeCount)
    _throw_if_optimize_in_progress(model, attr)
    return convert(Int64, CPXgetnodecnt(model.env, model.lp))
end

function MOI.get(model::Optimizer, attr::MOI.RelativeGap)
    _throw_if_optimize_in_progress(model, attr)
    p = Ref{Cdouble}()
    ret = CPXgetmiprelgap(model.env, model.lp, p)
    _check_ret(model, ret)
    return p[]
end

function MOI.get(model::Optimizer, attr::MOI.DualObjectiveValue)
    _throw_if_optimize_in_progress(model, attr)
    MOI.check_result_index_bounds(model, attr)
    p = Ref{Cdouble}()
    ret = CPXgetbestobjval(model.env, model.lp, p)
    if ret == CPXERR_NOT_MIP
        ret = CPXgetobjval(model.env, model.lp, p)
    end
    _check_ret(model, ret)
    return p[]
end

function MOI.get(model::Optimizer, attr::MOI.ResultCount)
    _throw_if_optimize_in_progress(model, attr)
    if model.has_dual_certificate
        return 1
    elseif model.has_primal_certificate
        return 1
    else
        pfeasind_p = Ref{Cint}()
        ret =
            CPXsolninfo(model.env, model.lp, C_NULL, C_NULL, pfeasind_p, C_NULL)
        _check_ret(model, ret)
        return pfeasind_p[] == 1 ? 1 : 0
    end
end

function MOI.get(model::Optimizer, ::MOI.Silent)
    return model.silent
end

function MOI.set(model::Optimizer, ::MOI.Silent, flag::Bool)
    model.silent = flag
    MOI.set(model, MOI.RawOptimizerAttribute("CPX_PARAM_SCRIND"), flag ? 0 : 1)
    return
end

function MOI.get(model::Optimizer, ::MOI.NumberOfThreads)
    return Int(MOI.get(model, MOI.RawOptimizerAttribute("CPX_PARAM_THREADS")))
end

function MOI.set(model::Optimizer, ::MOI.NumberOfThreads, x::Int)
    return MOI.set(model, MOI.RawOptimizerAttribute("CPX_PARAM_THREADS"), x)
end

function MOI.get(model::Optimizer, ::MOI.Name)
    surplus_p = Ref{Cint}()
    CPXgetprobname(model.env, model.lp, C_NULL, 0, surplus_p)
    buf_str = Vector{Cchar}(undef, -surplus_p[])
    buf_str_p = pointer(buf_str)
    GC.@preserve buf_str begin
        ret = CPXgetprobname(
            model.env,
            model.lp,
            buf_str_p,
            -surplus_p[],
            surplus_p,
        )
        _check_ret(model, ret)
        return unsafe_string(buf_str_p)
    end
end

function MOI.set(model::Optimizer, ::MOI.Name, name::String)
    ret = CPXchgprobname(model.env, model.lp, name)
    _check_ret(model, ret)
    return
end

MOI.get(model::Optimizer, ::MOI.NumberOfVariables) = length(model.variable_info)
function MOI.get(model::Optimizer, ::MOI.ListOfVariableIndices)
    return sort!(collect(keys(model.variable_info)), by = x -> x.value)
end

MOI.get(model::Optimizer, ::MOI.RawSolver) = model.lp

function MOI.set(
    model::Optimizer,
    ::MOI.VariablePrimalStart,
    x::MOI.VariableIndex,
    value::Union{Nothing,Float64},
)
    info = _info(model, x)
    info.start = value
    return
end

function MOI.get(
    model::Optimizer,
    ::MOI.VariablePrimalStart,
    x::MOI.VariableIndex,
)
    return _info(model, x).start
end

function MOI.supports(
    ::Optimizer,
    ::MOI.VariablePrimalStart,
    ::Type{MOI.VariableIndex},
)
    return true
end

function MOI.get(model::Optimizer, ::MOI.NumberOfConstraints{F,S}) where {F,S}
    # TODO: this could be more efficient.
    return length(MOI.get(model, MOI.ListOfConstraintIndices{F,S}()))
end

_bound_enums(::Type{<:MOI.LessThan}) = (_LESS_THAN, _LESS_AND_GREATER_THAN)
function _bound_enums(::Type{<:MOI.GreaterThan})
    return (_GREATER_THAN, _LESS_AND_GREATER_THAN)
end
_bound_enums(::Type{<:MOI.Interval}) = (_INTERVAL,)
_bound_enums(::Type{<:MOI.EqualTo}) = (_EQUAL_TO,)
_bound_enums(::Any) = (nothing,)

_type_enums(::Type{MOI.ZeroOne}) = (CPX_BINARY,)
_type_enums(::Type{MOI.Integer}) = (CPX_INTEGER,)
_type_enums(::Type{<:MOI.Semicontinuous}) = (CPX_SEMICONT,)
_type_enums(::Type{<:MOI.Semiinteger}) = (CPX_SEMIINT,)
_type_enums(::Any) = (nothing,)

function MOI.get(
    model::Optimizer,
    ::MOI.ListOfConstraintIndices{MOI.VariableIndex,S},
) where {S}
    indices = MOI.ConstraintIndex{MOI.VariableIndex,S}[]
    for (key, info) in model.variable_info
        if info.bound in _bound_enums(S) || info.type in _type_enums(S)
            push!(indices, MOI.ConstraintIndex{MOI.VariableIndex,S}(key.value))
        end
    end
    return sort!(indices, by = x -> x.value)
end

function MOI.get(
    model::Optimizer,
    ::MOI.ListOfConstraintIndices{MOI.ScalarAffineFunction{Float64},S},
) where {S}
    indices = MOI.ConstraintIndex{MOI.ScalarAffineFunction{Float64},S}[]
    for (key, info) in model.affine_constraint_info
        if typeof(info.set) == S
            push!(
                indices,
                MOI.ConstraintIndex{MOI.ScalarAffineFunction{Float64},S}(key),
            )
        end
    end
    return sort!(indices, by = x -> x.value)
end

function MOI.get(
    model::Optimizer,
    ::MOI.ListOfConstraintIndices{MOI.ScalarQuadraticFunction{Float64},S},
) where {S}
    indices = MOI.ConstraintIndex{MOI.ScalarQuadraticFunction{Float64},S}[]
    for (key, info) in model.quadratic_constraint_info
        if typeof(info.set) == S
            push!(
                indices,
                MOI.ConstraintIndex{MOI.ScalarQuadraticFunction{Float64},S}(
                    key,
                ),
            )
        end
    end
    return sort!(indices, by = x -> x.value)
end

function MOI.get(
    model::Optimizer,
    ::MOI.ListOfConstraintIndices{MOI.VectorOfVariables,S},
) where {S<:Union{<:MOI.SOS1,<:MOI.SOS2}}
    indices = MOI.ConstraintIndex{MOI.VectorOfVariables,S}[]
    for (key, info) in model.sos_constraint_info
        if typeof(info.set) == S
            push!(indices, MOI.ConstraintIndex{MOI.VectorOfVariables,S}(key))
        end
    end
    return sort!(indices, by = x -> x.value)
end

function MOI.get(
    model::Optimizer,
    ::MOI.ListOfConstraintIndices{MOI.VectorOfVariables,MOI.SecondOrderCone},
)
    indices = MOI.ConstraintIndex{MOI.VectorOfVariables,MOI.SecondOrderCone}[
        MOI.ConstraintIndex{MOI.VectorOfVariables,MOI.SecondOrderCone}(key)
        for (key, info) in model.quadratic_constraint_info if
        typeof(info.set) == MOI.SecondOrderCone
    ]
    return sort!(indices, by = x -> x.value)
end

function MOI.get(model::Optimizer, ::MOI.ListOfConstraintTypesPresent)
    constraints = Set{Tuple{DataType,DataType}}()
    for info in values(model.variable_info)
        if info.bound == _NONE
        elseif info.bound == _LESS_THAN
            push!(constraints, (MOI.VariableIndex, MOI.LessThan{Float64}))
        elseif info.bound == _GREATER_THAN
            push!(constraints, (MOI.VariableIndex, MOI.GreaterThan{Float64}))
        elseif info.bound == _LESS_AND_GREATER_THAN
            push!(constraints, (MOI.VariableIndex, MOI.LessThan{Float64}))
            push!(constraints, (MOI.VariableIndex, MOI.GreaterThan{Float64}))
        elseif info.bound == _EQUAL_TO
            push!(constraints, (MOI.VariableIndex, MOI.EqualTo{Float64}))
        elseif info.bound == _INTERVAL
            push!(constraints, (MOI.VariableIndex, MOI.Interval{Float64}))
        end
        if info.type == CPX_CONTINUOUS
        elseif info.type == CPX_BINARY
            push!(constraints, (MOI.VariableIndex, MOI.ZeroOne))
        elseif info.type == CPX_INTEGER
            push!(constraints, (MOI.VariableIndex, MOI.Integer))
        elseif info.type == CPX_SEMICONT
            push!(constraints, (MOI.VariableIndex, MOI.Semicontinuous{Float64}))
        elseif info.type == CPX_SEMIINT
            push!(constraints, (MOI.VariableIndex, MOI.Semiinteger{Float64}))
        end
    end
    for info in values(model.affine_constraint_info)
        push!(
            constraints,
            (MOI.ScalarAffineFunction{Float64}, typeof(info.set)),
        )
    end
    for info in values(model.quadratic_constraint_info)
        if typeof(info.set) == MOI.SecondOrderCone
            push!(constraints, (MOI.VectorOfVariables, MOI.SecondOrderCone))
        else
            push!(
                constraints,
                (MOI.ScalarQuadraticFunction{Float64}, typeof(info.set)),
            )
        end
    end
    for info in values(model.sos_constraint_info)
        push!(constraints, (MOI.VectorOfVariables, typeof(info.set)))
    end
    return collect(constraints)
end

function MOI.get(model::Optimizer, ::MOI.ObjectiveFunctionType)
    if model.objective_type == _SINGLE_VARIABLE
        return MOI.VariableIndex
    elseif model.objective_type == _SCALAR_AFFINE
        return MOI.ScalarAffineFunction{Float64}
    else
        @assert model.objective_type == _SCALAR_QUADRATIC
        return MOI.ScalarQuadraticFunction{Float64}
    end
end

function MOI.modify(
    model::Optimizer,
    c::MOI.ConstraintIndex{MOI.ScalarAffineFunction{Float64},<:Any},
    chg::MOI.ScalarCoefficientChange{Float64},
)
    ret = CPXchgcoef(
        model.env,
        model.lp,
        Cint(_info(model, c).row - 1),
        Cint(column(model, chg.variable) - 1),
        chg.new_coefficient,
    )
    _check_ret(model, ret)
    return
end

function MOI.modify(
    model::Optimizer,
    ::MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}},
    chg::MOI.ScalarCoefficientChange{Float64},
)
    col = Cint(column(model, chg.variable) - 1)
    ret = CPXchgobj(model.env, model.lp, 1, Ref(col), Ref(chg.new_coefficient))
    _check_ret(model, ret)
    if model.objective_type == _UNSET_OBJECTIVE ||
       model.objective_type == _SINGLE_VARIABLE
        model.objective_type = _SCALAR_AFFINE
    end
    return
end

"""
    _replace_with_matching_sparsity!(
        model::Optimizer,
        previous::MOI.ScalarAffineFunction,
        replacement::MOI.ScalarAffineFunction, row::Int
    )

Internal function, not intended for external use.

Change the linear constraint function at index `row` in `model` from
`previous` to `replacement`. This function assumes that `previous` and
`replacement` have exactly the same sparsity pattern w.r.t. which variables
they include and that both constraint functions are in canonical form (as
returned by `MOIU.canonical()`. Neither assumption is checked within the body
of this function.
"""
function _replace_with_matching_sparsity!(
    model::Optimizer,
    previous::MOI.ScalarAffineFunction,
    replacement::MOI.ScalarAffineFunction,
    row::Int,
)
    for term in replacement.terms
        col = Cint(column(model, term.variable) - 1)
        ret = CPXchgcoef(
            model.env,
            model.lp,
            Cint(row - 1),
            col,
            MOI.coefficient(term),
        )
        _check_ret(model, ret)
    end
    return
end

"""
    _replace_with_different_sparsity!(
        model::Optimizer,
        previous::MOI.ScalarAffineFunction,
        replacement::MOI.ScalarAffineFunction, row::Int
    )

Internal function, not intended for external use.

    Change the linear constraint function at index `row` in `model` from
`previous` to `replacement`. This function assumes that `previous` and
`replacement` may have different sparsity patterns.

This function (and `_replace_with_matching_sparsity!` above) are necessary
because in order to fully replace a linear constraint, we have to zero out the
current matrix coefficients and then set the new matrix coefficients. When the
sparsity patterns match, the zeroing-out step can be skipped.
"""
function _replace_with_different_sparsity!(
    model::Optimizer,
    previous::MOI.ScalarAffineFunction,
    replacement::MOI.ScalarAffineFunction,
    row::Int,
)
    # First, zero out the old constraint function terms.
    for term in previous.terms
        col = Cint(column(model, term.variable) - 1)
        ret = CPXchgcoef(model.env, model.lp, Cint(row - 1), col, 0.0)
        _check_ret(model, ret)
    end

    # Next, set the new constraint function terms.
    for term in previous.terms
        col = Cint(column(model, term.variable) - 1)
        ret = CPXchgcoef(
            model.env,
            model.lp,
            Cint(row - 1),
            col,
            MOI.coefficient(term),
        )
        _check_ret(model, ret)
    end
    return
end

"""
    _matching_sparsity_pattern(
        f1::MOI.ScalarAffineFunction{Float64},
        f2::MOI.ScalarAffineFunction{Float64}
    )

Internal function, not intended for external use.

Determines whether functions `f1` and `f2` have the same sparsity pattern
w.r.t. their constraint columns. Assumes both functions are already in
canonical form.
"""
function _matching_sparsity_pattern(
    f1::MOI.ScalarAffineFunction{Float64},
    f2::MOI.ScalarAffineFunction{Float64},
)
    if axes(f1.terms) != axes(f2.terms)
        return false
    end
    for (f1_term, f2_term) in zip(f1.terms, f2.terms)
        if MOI.term_indices(f1_term) != MOI.term_indices(f2_term)
            return false
        end
    end
    return true
end

function MOI.set(
    model::Optimizer,
    ::MOI.ConstraintFunction,
    c::MOI.ConstraintIndex{MOI.ScalarAffineFunction{Float64},<:_SCALAR_SETS},
    f::MOI.ScalarAffineFunction{Float64},
)
    previous = MOI.get(model, MOI.ConstraintFunction(), c)
    MOI.Utilities.canonicalize!(previous)
    replacement = MOI.Utilities.canonical(f)
    # If the previous and replacement constraint functions have exactly
    # the same sparsity pattern, then we can take a faster path by just
    # passing the replacement terms to the model. But if their sparsity
    # patterns differ, then we need to first zero out the previous terms
    # and then set the replacement terms.
    row = _info(model, c).row
    if _matching_sparsity_pattern(previous, replacement)
        _replace_with_matching_sparsity!(model, previous, replacement, row)
    else
        _replace_with_different_sparsity!(model, previous, replacement, row)
    end
    rhs = Ref{Cdouble}()
    ret = CPXgetrhs(model.env, model.lp, rhs, Cint(row - 1), Cint(row - 1))
    _check_ret(model, ret)
    rhs[] -= replacement.constant - previous.constant
    ret = CPXchgrhs(model.env, model.lp, 1, Ref{Cint}(row - 1), rhs)
    _check_ret(model, ret)
    return
end

function MOI.get(
    model::Optimizer,
    ::MOI.ConstraintBasisStatus,
    c::MOI.ConstraintIndex{MOI.ScalarAffineFunction{Float64},S},
) where {S<:_SCALAR_SETS}
    rstat = Vector{Cint}(undef, length(model.affine_constraint_info))
    ret = CPXgetbase(model.env, model.lp, C_NULL, rstat)
    _check_ret(model, ret)
    cbasis = rstat[_info(model, c).row]
    if cbasis == CPX_BASIC
        return MOI.BASIC
    else
        # CPLEX uses CPX_AT_LOWER regardless of whether it is <= or >=.
        @assert cbasis == CPX_AT_LOWER
        return MOI.NONBASIC
    end
end

function MOI.get(
    model::Optimizer,
    ::MOI.VariableBasisStatus,
    x::MOI.VariableIndex,
)
    cstat = Vector{Cint}(undef, length(model.variable_info))
    ret = CPXgetbase(model.env, model.lp, cstat, C_NULL)
    _check_ret(model, ret)
    vbasis = cstat[_info(model, x).column]
    if vbasis == CPX_BASIC
        return MOI.BASIC
    elseif vbasis == CPX_FREE_SUPER
        return MOI.SUPER_BASIC
    elseif vbasis == CPX_AT_LOWER
        return MOI.NONBASIC_AT_LOWER
    else
        @assert vbasis == CPX_AT_UPPER
        return MOI.NONBASIC_AT_UPPER
    end
end

###
### VectorOfVariables-in-SecondOrderCone
###

function _info(
    model::Optimizer,
    c::MOI.ConstraintIndex{MOI.VectorOfVariables,MOI.SecondOrderCone},
)
    if haskey(model.quadratic_constraint_info, c.value)
        return model.quadratic_constraint_info[c.value]
    end
    return throw(MOI.InvalidIndex(c))
end

function MOI.add_constraint(
    model::Optimizer,
    f::MOI.VectorOfVariables,
    s::MOI.SecondOrderCone,
)
    if length(f.variables) != s.dimension
        error("Dimension of $(s) does not match number of terms in $(f)")
    end

    # SOC is the cone: t ≥ ||x||₂ ≥ 0. In quadratic form, this is
    # t² - Σᵢ xᵢ² ≥ 0 and t ≥ 0.

    # First, check the lower bound on t.

    t_info = _info(model, f.variables[1])
    lb = _get_variable_lower_bound(model, t_info)
    if isnan(t_info.lower_bound_if_soc) && lb < 0.0
        t_info.lower_bound_if_soc = lb
        ret = CPXchgbds(
            model.env,
            model.lp,
            1,
            Ref{Cint}(t_info.column - 1),
            Ref{Cchar}('L'),
            Ref(0.0),
        )
        _check_ret(model, ret)
    end
    t_info.num_soc_constraints += 1

    # Now add the quadratic constraint.

    I = Cint[column(model, v) - 1 for v in f.variables]
    V = fill(-1.0, length(f.variables))
    V[1] = 1.0
    ret = CPXaddqconstr(
        model.env,
        model.lp,
        0,
        length(V),
        0.0,
        Cchar('G'),
        C_NULL,
        C_NULL,
        I,
        I,
        V,
        C_NULL,
    )
    _check_ret(model, ret)
    model.last_constraint_index += 1
    model.quadratic_constraint_info[model.last_constraint_index] =
        _ConstraintInfo(length(model.quadratic_constraint_info) + 1, s)
    return MOI.ConstraintIndex{MOI.VectorOfVariables,MOI.SecondOrderCone}(
        model.last_constraint_index,
    )
end

function MOI.is_valid(
    model::Optimizer,
    c::MOI.ConstraintIndex{MOI.VectorOfVariables,MOI.SecondOrderCone},
)
    info = get(model.quadratic_constraint_info, c.value, nothing)
    return info !== nothing && typeof(info.set) == MOI.SecondOrderCone
end

function MOI.delete(
    model::Optimizer,
    c::MOI.ConstraintIndex{MOI.VectorOfVariables,MOI.SecondOrderCone},
)
    f = MOI.get(model, MOI.ConstraintFunction(), c)
    info = _info(model, c)
    ret = CPXdelqconstrs(
        model.env,
        model.lp,
        Cint(info.row - 1),
        Cint(info.row - 1),
    )
    _check_ret(model, ret)
    for (key, info_2) in model.quadratic_constraint_info
        if info_2.row > info.row
            info_2.row -= 1
        end
    end
    model.name_to_constraint_index = nothing
    delete!(model.quadratic_constraint_info, c.value)
    # Reset the lower bound on the `t` variable.
    t_info = _info(model, f.variables[1])
    t_info.num_soc_constraints -= 1
    if t_info.num_soc_constraints > 0
        # Don't do anything. There are still SOC associated with this variable.
        return
    elseif isnan(t_info.lower_bound_if_soc)
        # Don't do anything. It must have a >0 lower bound anyway.
        return
    end
    # There was a previous bound that we over-wrote, and it must have been
    # < 0 otherwise we wouldn't have needed to overwrite it.
    @assert t_info.lower_bound_if_soc < 0.0
    tmp_lower_bound = t_info.lower_bound_if_soc
    t_info.lower_bound_if_soc = NaN
    _set_variable_lower_bound(model, t_info, tmp_lower_bound)
    return
end

function MOI.get(
    model::Optimizer,
    ::MOI.ConstraintSet,
    c::MOI.ConstraintIndex{MOI.VectorOfVariables,MOI.SecondOrderCone},
)
    return _info(model, c).set
end

function MOI.get(
    model::Optimizer,
    ::MOI.ConstraintFunction,
    c::MOI.ConstraintIndex{MOI.VectorOfVariables,MOI.SecondOrderCone},
)
    a, b, I, J, V = _CPXgetqconstr(model, c)
    @assert length(a) == length(b) == 0  # Check for no linear terms.
    t = nothing
    x = MOI.VariableIndex[]
    for (i, j, coef) in zip(I, J, V)
        v = model.variable_info[CleverDicts.LinearIndex(i + 1)].index
        @assert i == j  # Check for no off-diagonals.
        if coef == 1.0
            @assert t === nothing  # There should only be one `t`.
            t = v
        else
            @assert coef == -1.0  # The coefficients _must_ be -1 for `x` terms.
            push!(x, v)
        end
    end
    @assert t !== nothing  # Check that we found a `t` variable.
    return MOI.VectorOfVariables([t; x])
end

function MOI.get(
    model::Optimizer,
    ::MOI.ConstraintPrimal,
    c::MOI.ConstraintIndex{MOI.VectorOfVariables,MOI.SecondOrderCone},
)
    f = MOI.get(model, MOI.ConstraintFunction(), c)
    return MOI.get(model, MOI.VariablePrimal(), f.variables)
end

function MOI.get(
    model::Optimizer,
    ::MOI.ConstraintName,
    c::MOI.ConstraintIndex{MOI.VectorOfVariables,MOI.SecondOrderCone},
)
    return _info(model, c).name
end

function MOI.set(
    model::Optimizer,
    ::MOI.ConstraintName,
    c::MOI.ConstraintIndex{MOI.VectorOfVariables,MOI.SecondOrderCone},
    name::String,
)
    info = _info(model, c)
    if !isempty(info.name) && model.name_to_constraint_index !== nothing
        delete!(model.name_to_constraint_index, info.name)
    end
    info.name = name
    if model.name_to_constraint_index === nothing || isempty(name)
        return
    end
    if haskey(model.name_to_constraint_index, name)
        model.name_to_constraint_index = nothing
    else
        model.name_to_constraint_index[c] = name
    end
    return
end

function MOI.get(
    model::Optimizer,
    ::MOI.ConstraintDual,
    c::MOI.ConstraintIndex{MOI.VectorOfVariables,MOI.SecondOrderCone},
)
    f = MOI.get(model, MOI.ConstraintFunction(), c)
    qind = Cint(_info(model, c).row - 1)
    surplus_p = Ref{Cint}()
    CPXgetqconstrdslack(
        model.env,
        model.lp,
        qind,
        C_NULL,
        C_NULL,
        C_NULL,
        0,
        surplus_p,
    )
    ind = Vector{Cint}(undef, -surplus_p[])
    val = Vector{Cdouble}(undef, -surplus_p[])
    ret = CPXgetqconstrdslack(
        model.env,
        model.lp,
        qind,
        C_NULL,
        ind,
        val,
        -surplus_p[],
        surplus_p,
    )
    _check_ret(model, ret)
    slack = zeros(length(model.variable_info))
    for (i, v) in zip(ind, val)
        slack[i+1] += v
    end
    z = _dual_multiplier(model)
    return [z * slack[_info(model, v).column] for v in f.variables]
end
