#=
    Helper functions to store constraint mappings
=#
cmap(m::CplexSolverInstance) = m.constraint_mapping

function Base.getindex(m::CplexSolverInstance, c::CR{F,S}) where F where S
    dict = constrdict(m, c)
    return dict[c]
end
constrdict(m::CplexSolverInstance, ::LCR{LE})  = cmap(m).less_than
constrdict(m::CplexSolverInstance, ::LCR{GE})  = cmap(m).greater_than
constrdict(m::CplexSolverInstance, ::LCR{EQ})  = cmap(m).equal_to
constrdict(m::CplexSolverInstance, ::SVCR{LE}) = cmap(m).upper_bound
constrdict(m::CplexSolverInstance, ::SVCR{GE}) = cmap(m).lower_bound
constrdict(m::CplexSolverInstance, ::SVCR{EQ}) = cmap(m).fixed_bound
constrdict(m::CplexSolverInstance, ::SVCR{IV}) = cmap(m).interval_bound
constrdict(m::CplexSolverInstance, ::SVCR{MOI.ZeroOne}) = cmap(m).binary
constrdict(m::CplexSolverInstance, ::SVCR{MOI.Integer}) = cmap(m).integer
constrdict(m::CplexSolverInstance, ::VVCR{MOI.SOS1}) = cmap(m).sos1
constrdict(m::CplexSolverInstance, ::VVCR{MOI.SOS2}) = cmap(m).sos2

#=
    Set variable bounds
=#

function setvariablebound!(m::CplexSolverInstance, col::Int, bound::Float64, sense::Cchar)
    cpx_chgbds!(m.inner, [col], [bound], [sense])
end

function setvariablebound!(m::CplexSolverInstance, v::MOI.SingleVariable, set::LE)
    setvariablebound!(m, getcol(m, v), set.upper, Cchar('U'))
end
function setvariablebound!(m::CplexSolverInstance, v::MOI.SingleVariable, set::GE)
    setvariablebound!(m, getcol(m, v), set.lower, Cchar('L'))
end
function setvariablebound!(m::CplexSolverInstance, v::MOI.SingleVariable, set::EQ)
    setvariablebound!(m, getcol(m, v), set.value, Cchar('U'))
    setvariablebound!(m, getcol(m, v), set.value, Cchar('L'))
end
function setvariablebound!(m::CplexSolverInstance, v::MOI.SingleVariable, set::IV)
    setvariablebound!(m, getcol(m, v), set.upper, Cchar('U'))
    setvariablebound!(m, getcol(m, v), set.lower, Cchar('L'))
end

function MOI.addconstraint!(m::CplexSolverInstance, v::MOI.SingleVariable, set::S) where S <: Union{LE, GE, EQ, IV}
    setvariablebound!(m, v, set)
    m.last_constraint_reference += 1
    ref = MOI.ConstraintReference{SinVar, S}(m.last_constraint_reference)
    dict = constrdict(m, ref)
    dict[ref] = v.variable
    ref
end

#=
    Get constraint set of variable bound
=#

getbound(m::CplexSolverInstance, c::SVCR{LE}) = cpx_getub(m.inner, getcol(m, m[c]))
getbound(m::CplexSolverInstance, c::SVCR{GE}) = cpx_getlb(m.inner, getcol(m, m[c]))
getbound(m::CplexSolverInstance, c::SVCR{EQ}) = cpx_getlb(m.inner, getcol(m, m[c]))

function MOI.getattribute(m::CplexSolverInstance, ::MOI.ConstraintSet, c::SVCR{S}) where S <: Union{LE, GE, EQ}
    S(getbound(m, c))
end

function MOI.getattribute(m::CplexSolverInstance, ::MOI.ConstraintSet, c::SVCR{IV})
    col = getcol(m, m[c])
    lb = cpx_getlb(m.inner, col)
    ub = cpx_getub(m.inner, col)
    return Interval{Float64}(lb, ub)
end

MOI.cangetattribute(m::CplexSolverInstance, ::MOI.ConstraintSet, c::SVCR{S}) where S <: Union{LE, GE, EQ, IV} = true

#=
    Get constraint function of variable bound
=#

function MOI.getattribute(m::CplexSolverInstance, ::MOI.ConstraintFunction, c::SVCR{<: Union{LE, GE, EQ, IV}})
    return MOI.SingleVariable(m[c])
end
MOI.cangetattribute(m::CplexSolverInstance, ::MOI.ConstraintFunction, c::SVCR{<: Union{LE, GE, EQ, IV}}) = true

#=
    Change variable bounds of same set
=#

function MOI.modifyconstraint!(m::CplexSolverInstance, c::SVCR{S}, newset::S) where S<: Union{LE, GE, EQ, IV}
    setvariablebound!(m, MOI.SingleVariable(m[c]), newset)
end

#=
    Delete a variable bound
=#

function MOI.delete!(m::CplexSolverInstance, c::SVCR{S}) where S <: Union{LE, GE, EQ, IV}
    dict = constrdict(m, c)
    vref = dict[c]
    setvariablebound!(m, MOI.SingleVariable(vref), MOI.Interval{Float64}(-Inf, Inf))
    delete!(dict, c)
end

#=
    Add linear constraints
=#

function MOI.addconstraint!(m::CplexSolverInstance, func::Linear, set::T) where T <: Union{LE, GE, EQ}
    addlinearconstraint!(m, func, set)
    m.last_constraint_reference += 1
    ref = MOI.ConstraintReference{Linear, T}(m.last_constraint_reference)
    dict = constrdict(m, ref)
    dict[ref] = cpx_getnumrows(m.inner)
    push!(m.constraint_primal_solution, NaN)
    push!(m.constraint_dual_solution, NaN)
    return ref
end

function addlinearconstraint!(m::CplexSolverInstance, func::Linear, set::LE)
    addlinearconstraint!(m, func, Cchar('L'), set.upper)
end
function addlinearconstraint!(m::CplexSolverInstance, func::Linear, set::GE)
    addlinearconstraint!(m, func, Cchar('G'), set.lower)
end
function addlinearconstraint!(m::CplexSolverInstance, func::Linear, set::EQ)
    addlinearconstraint!(m, func, Cchar('E'), set.value)
end

function addlinearconstraint!(m::CplexSolverInstance, func::Linear, sense::Cchar, rhs)
    if abs(func.constant) > eps(Float64)
        warn("Constant in scalar function moved into set.")
    end
    cpx_addrows!(m.inner, getcol.(m, func.variables), func.coefficients, sense, rhs - func.constant)
end

#=
    Constraint set of Linear function
=#

function MOI.getattribute(m::CplexSolverInstance, ::MOI.ConstraintSet, c::LCR{S}) where S <: Union{LE, GE, EQ}
    rhs = cpx_getrhs(m.inner, m[c])
    S(rhs)
end
MOI.cangetattribute(m::CplexSolverInstance, ::MOI.ConstraintSet, ::LCR{<: Union{LE, GE, EQ}}) = true

#=
    Constraint function of Linear function
=#

function MOI.getattribute(m::CplexSolverInstance, ::MOI.ConstraintFunction, c::LCR{<: Union{LE, GE, EQ}})
    # TODO more efficiently
    colidx, coefs = cpx_getrows(m.inner, m[c])
    MOI.ScalarAffineFunction(m.variable_references[colidx+1] , coefs, 0.0)
end
MOI.cangetattribute(m::CplexSolverInstance, ::MOI.ConstraintFunction, c::LCR{<: Union{LE, GE, EQ}}) = true

#=
    Get number of constraints
=#

function MOI.getattribute(m::CplexSolverInstance, ::MOI.NumberOfConstraints{F, S}) where F where S
    length(constrdict(m, MOI.ConstraintReference{F,S}(UInt(0))))
end
MOI.cangetattribute(m::CplexSolverInstance, ::MOI.NumberOfConstraints{F, S}) where F where S = true

#=
    Scalar Coefficient Change of Linear Constraint
=#

function MOI.modifyconstraint!(m::CplexSolverInstance, c::LCR{<: Union{LE, GE, EQ}}, chg::MOI.ScalarCoefficientChange{Float64})
    col = m.variable_mapping[chg.variable]
    cpx_chgcoef!(m.inner, m[c], col, chg.new_coefficient)
end

#=
    Change RHS of linear constraint without modifying sense
=#

_newrhs(set::LE) = set.upper
_newrhs(set::GE) = set.lower
_newrhs(set::EQ) = set.value
function MOI.modifyconstraint!(m::CplexSolverInstance, c::LCR{S}, newset::S) where S
    # the column 0 (or -1 in 0-index) is the rhs.
    cpx_chgcoef!(m.inner, m[c], 0, _newrhs(newset))
end

#=
    Delete a linear constraint
=#

function deleteref!(m::CplexSolverInstance, row::Int, ref::LCR{<: Union{LE, GE, EQ}})
    deleteref!(cmap(m).less_than, row, ref)
    deleteref!(cmap(m).greater_than, row, ref)
    deleteref!(cmap(m).equal_to, row, ref)
end
function MOI.delete!(m::CplexSolverInstance, c::LCR{<: Union{LE, GE, EQ}})
    dict = constrdict(m, c)
    row = dict[c]
    cpx_delrows!(m.inner, row, row)
    deleteat!(m.constraint_primal_solution, row)
    deleteat!(m.constraint_dual_solution, row)
    deleteref!(m, row, c)
end

#=
    MIP related constraints
=#
"""
    hasinteger(m::CplexSolverInstance)::Bool

A helper function to determine if the solver instance `m` has any integer
components (i.e. binary, integer, special ordered sets, etc).
"""
function hasinteger(m::CplexSolverInstance)
    length(cmap(m).integer) + length(cmap(m).binary) + length(cmap(m).sos1) + length(cmap(m).sos2) > 0
end

#=
    Binary constraints

 for some reason CPLEX doesn't respect bounds on a binary variable, so we
 should store the previous bounds so that if we delete the binary constraint
 we can revert to the old bounds
=#
function MOI.addconstraint!(m::CplexSolverInstance, v::SinVar, ::MOI.ZeroOne)
    cpx_chgctype!(m.inner, [getcol(m, v)], ['B'])
    ub = cpx_getub(m.inner, getcol(m, v))
    lb = cpx_getlb(m.inner, getcol(m, v))
    m.last_constraint_reference += 1
    ref = MOI.ConstraintReference{SinVar, MOI.ZeroOne}(m.last_constraint_reference)
    dict = constrdict(m, ref)
    dict[ref] = (v.variable, lb, ub)
    setvariablebound!(m, getcol(m, v), 1.0, Cchar('U'))
    setvariablebound!(m, getcol(m, v), 0.0, Cchar('L'))
    _make_problem_type_integer(m.inner)
    ref
end
function MOI.delete!(m::CplexSolverInstance, c::SVCR{MOI.ZeroOne})
    dict = constrdict(m, c)
    (v, lb, ub) = dict[c]
    cpx_chgctype!(m.inner, [getcol(m, v)], ['C'])
    setvariablebound!(m, getcol(m, v), ub, Cchar('U'))
    setvariablebound!(m, getcol(m, v), lb, Cchar('L'))
    delete!(dict, c)
    if !hasinteger(m)
        _make_problem_type_continuous(m.inner)
    end
end

MOI.getattribute(m::CplexSolverInstance, ::MOI.ConstraintSet, c::SVCR{MOI.ZeroOne}) =MOI.ZeroOne()
MOI.cangetattribute(m::CplexSolverInstance, ::MOI.ConstraintSet, c::SVCR{MOI.ZeroOne}) = true

MOI.getattribute(m::CplexSolverInstance, ::MOI.ConstraintFunction, c::SVCR{MOI.ZeroOne}) = m[c]
MOI.cangetattribute(m::CplexSolverInstance, ::MOI.ConstraintFunction, c::SVCR{MOI.ZeroOne}) = true


#=
    Integer constraints
=#

function MOI.addconstraint!(m::CplexSolverInstance, v::SinVar, ::MOI.Integer)
    cpx_chgctype!(m.inner, [getcol(m, v)], ['I'])
    m.last_constraint_reference += 1
    ref = MOI.ConstraintReference{SinVar, MOI.Integer}(m.last_constraint_reference)
    dict = constrdict(m, ref)
    dict[ref] = v.variable
    _make_problem_type_integer(m.inner)
    ref
end

function MOI.delete!(m::CplexSolverInstance, c::SVCR{MOI.Integer})
    dict = constrdict(m, c)
    v = dict[c]
    cpx_chgctype!(m.inner, [getcol(m, v)], ['C'])
    delete!(dict, c)
    if !hasinteger(m)
        _make_problem_type_continuous(m.inner)
    end
end

MOI.getattribute(m::CplexSolverInstance, ::MOI.ConstraintSet, c::SVCR{MOI.Integer}) =MOI.Integer()
MOI.cangetattribute(m::CplexSolverInstance, ::MOI.ConstraintSet, c::SVCR{MOI.Integer}) = true

MOI.getattribute(m::CplexSolverInstance, ::MOI.ConstraintFunction, c::SVCR{MOI.Integer}) = m[c]
MOI.cangetattribute(m::CplexSolverInstance, ::MOI.ConstraintFunction, c::SVCR{MOI.Integer}) = true


#=
    SOS constraints
=#

function MOI.addconstraint!(m::CplexSolverInstance, v::VecVar, sos::MOI.SOS1)
    _make_problem_type_integer(m.inner)
    cpx_addsos!(m.inner, getcol.(m, v.variables), sos.weights, CPX_TYPE_SOS1)
    m.last_constraint_reference += 1
    ref = MOI.ConstraintReference{VecVar, MOI.SOS1}(m.last_constraint_reference)
    dict = constrdict(m, ref)
    dict[ref] = length(cmap(m).sos1) + length(cmap(m).sos2) + 1
    ref
end

function MOI.addconstraint!(m::CplexSolverInstance, v::VecVar, sos::MOI.SOS2)
    _make_problem_type_integer(m.inner)
    cpx_addsos!(m.inner, getcol.(m, v.variables), sos.weights, CPX_TYPE_SOS2)
    m.last_constraint_reference += 1
    ref = MOI.ConstraintReference{VecVar, MOI.SOS2}(m.last_constraint_reference)
    dict = constrdict(m, ref)
    dict[ref] = length(cmap(m).sos1) + length(cmap(m).sos2) + 1
    ref
end

function MOI.delete!(m::CplexSolverInstance, c::VVCR{<:Union{MOI.SOS1, MOI.SOS2}})
    dict = constrdict(m, c)
    idx = dict[c]
    cpx_delsos!(m.inner, idx, idx)
    deleteref!(cmap(m).sos1, idx, c)
    deleteref!(cmap(m).sos2, idx, c)
    if !hasinteger(m)
        _make_problem_type_continuous(m.inner)
    end
end

function MOI.getattribute(m::CplexSolverInstance, ::MOI.ConstraintSet, c::VVCR{MOI.SOS1})
    indices, weights, types = cpx_getsos(m.inner, m[c])
    @assert types == CPX_TYPE_SOS1
    return MOI.SOS1(weights)
end

function MOI.getattribute(m::CplexSolverInstance, ::MOI.ConstraintSet, c::VVCR{MOI.SOS2})
    indices, weights, types = cpx_getsos(m.inner, m[c])
    @assert types == CPX_TYPE_SOS2
    return MOI.SOS2(weights)
end

MOI.cangetattribute(m::CplexSolverInstance, ::MOI.ConstraintSet, c::VVCR{<:Union{MOI.SOS1, MOI.SOS2}}) = true

function MOI.getattribute(m::CplexSolverInstance, ::MOI.ConstraintFunction, c::VVCR{<:Union{MOI.SOS1, MOI.SOS2}})
    indices, weights, types = cpx_getsos(m.inner, m[c])
    return MOI.VectorOfVariables(m.variable_references[indices])
end

MOI.cangetattribute(m::CplexSolverInstance, ::MOI.ConstraintFunction, c::VVCR{<:Union{MOI.SOS1, MOI.SOS2}}) = true
