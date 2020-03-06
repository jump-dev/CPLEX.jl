
function MOI.supports_constraint(
    ::Optimizer,
    ::Type{MOI.VectorAffineFunction{Float64}},
    ::Type{<:MOI.IndicatorSet{A, S}}
) where {
    A, S <: Union{MOI.LessThan{Float64}, MOI.GreaterThan{Float64}, MOI.EqualTo{Float64}}
}
    return true
end

function MOI.is_valid(
    model::Optimizer,
    c::MOI.ConstraintIndex{MOI.VectorAffineFunction{Float64}, S}
) where {
    S <: MOI.IndicatorSet
}
    info_tuple = get(model.indicator_constraint_info, c.value, nothing)
    if info_tuple === nothing
        return false
    end
    return typeof(info_tuple[1].set) == S
end

function MOI.get(
    model::Optimizer,
    ::MOI.ConstraintSet,
    c::MOI.ConstraintIndex{<:MOI.VectorAffineFunction, <:MOI.IndicatorSet}
)
    MOI.throw_if_not_valid(model, c)
    info = model.indicator_constraint_info[c.value][1]
    return info.set
end

function MOI.get(
    model::Optimizer,
    ::MOI.ConstraintFunction,
    c::MOI.ConstraintIndex{<:MOI.VectorAffineFunction, <:MOI.IndicatorSet}
)
    MOI.throw_if_not_valid(model, c)
    func = model.indicator_constraint_info[c.value][2]
    return func
end

function MOI.add_constraint(
    model::Optimizer,
    func::MOI.VectorAffineFunction{Float64},
    s::MOI.IndicatorSet{A, S}
) where {
    A, S <: Union{MOI.GreaterThan{Float64}, MOI.LessThan{Float64}, MOI.EqualTo{Float64}}
}
    first_index_terms  = [v.scalar_term for v in func.terms if v.output_index == 1]
    scalar_index_terms = [v.scalar_term for v in func.terms if v.output_index != 1]
    if length(first_index_terms) != 1
        throw(ArgumentError("There should be exactly one term in output_index 1, found $(length(first_index_terms))"))
    end
    # getting the indicator variable
    sense_code = _get_indicator_sense(s.set)
    active_bool = A == MOI.ACTIVATE_ON_ONE ? Cint(0) : Cint(1)
    var_inner = _info(model, first_index_terms[1].variable_index).column

    # keeping track of the constraints
    model.last_constraint_index += 1
    info = ConstraintInfo(length(model.indicator_constraint_info) + 1, s)
    model.indicator_constraint_info[model.last_constraint_index] = (info, func)

    linear_idx = Vector{Cint}(undef, length(scalar_index_terms))
    linear_coefficients = Vector{Cdouble}(undef, length(scalar_index_terms))
    for (i, term) in enumerate(scalar_index_terms)
        linear_idx[i] = _info(model, term.variable_index).column
        linear_coefficients[i] = term.coefficient
    end
    # switching constant on other side
    # a^T x + b <= c <==> a^T x <= c - b
    fcons = MOI.constant(func)
    rhs = Cdouble(MOI.constant(s.set) - fcons[2])
    add_indicator_constraint(model.inner, linear_idx, linear_coefficients, sense_code, rhs, var_inner, active_bool)
    return MOI.ConstraintIndex{typeof(func), typeof(s)}(model.last_constraint_index)
end

_get_indicator_sense(::MOI.GreaterThan) = Cint('G')
_get_indicator_sense(::MOI.LessThan) = Cint('L')
_get_indicator_sense(::MOI.EqualTo) = Cint('E')

function MOI.get(
    model::Optimizer,
    ::MOI.ListOfConstraintIndices{<:MOI.VectorAffineFunction, S},
) where {
    S <: MOI.IndicatorSet
}
    indices = MOI.ConstraintIndex{MOI.VectorAffineFunction{Float64}, S}[
        MOI.ConstraintIndex{MOI.VectorAffineFunction{Float64}, S}(key)
        for (key, info_func) in model.indicator_constraint_info
        if typeof(info_func[1].set) === S
    ]
    return sort!(indices, by = x -> x.value)
end

function MOI.get(
    model::Optimizer,
    ::MOI.NumberOfConstraints{MOI.VectorAffineFunction{Float64}, S}
) where {
    S <: MOI.IndicatorSet
}
    nindices = 0
    for (key, info_func) in model.indicator_constraint_info
        info = info_func[1]
        if typeof(info.set) === S
            nindices += 1
        end
    end
    return nindices
end

function MOI.get(
    model::Optimizer,
    ::MOI.ConstraintName,
    c::MOI.ConstraintIndex{<:MOI.VectorAffineFunction, <:MOI.IndicatorSet}
)
    MOI.throw_if_not_valid(model, c)
    info = model.indicator_constraint_info[c.value][1]
    return info.name
end

function MOI.set(
    model::Optimizer,
    ::MOI.ConstraintName,
    c::MOI.ConstraintIndex{<:MOI.VectorAffineFunction, S},
    name::String,
) where {
    S <: MOI.IndicatorSet
}
    MOI.throw_if_not_valid(model, c)
    info = model.indicator_constraint_info[c.value][1]
    info.name = name
    return
end
