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
constrdict(m::CplexSolverInstance, ::LCR{IV})  = cmap(m).interval

constrdict(m::CplexSolverInstance, ::VLCR{MOI.Nonnegatives})  = cmap(m).nonnegatives
constrdict(m::CplexSolverInstance, ::VLCR{MOI.Nonpositives}) = cmap(m).nonpositives
constrdict(m::CplexSolverInstance, ::VLCR{MOI.Zeros})         = cmap(m).zeros

constrdict(m::CplexSolverInstance, ::QCR{LE})  = cmap(m).q_less_than
constrdict(m::CplexSolverInstance, ::QCR{GE})  = cmap(m).q_greater_than
constrdict(m::CplexSolverInstance, ::QCR{EQ})  = cmap(m).q_equal_to

constrdict(m::CplexSolverInstance, ::SVCR{LE}) = cmap(m).upper_bound
constrdict(m::CplexSolverInstance, ::SVCR{GE}) = cmap(m).lower_bound
constrdict(m::CplexSolverInstance, ::SVCR{EQ}) = cmap(m).fixed_bound
constrdict(m::CplexSolverInstance, ::SVCR{IV}) = cmap(m).interval_bound

constrdict(m::CplexSolverInstance, ::VVCR{MOI.Nonnegatives}) = cmap(m).vv_nonnegatives
constrdict(m::CplexSolverInstance, ::VVCR{MOI.Nonpositives}) = cmap(m).vv_nonpositives
constrdict(m::CplexSolverInstance, ::VVCR{MOI.Zeros}) = cmap(m).vv_zeros

constrdict(m::CplexSolverInstance, ::SVCR{MOI.ZeroOne}) = cmap(m).binary
constrdict(m::CplexSolverInstance, ::SVCR{MOI.Integer}) = cmap(m).integer

constrdict(m::CplexSolverInstance, ::VVCR{MOI.SOS1}) = cmap(m).sos1
constrdict(m::CplexSolverInstance, ::VVCR{MOI.SOS2}) = cmap(m).sos2


_getsense(::MOI.Zeros)        = Cchar('E')
_getsense(::MOI.Nonpositives) = Cchar('L')
_getsense(::MOI.Nonnegatives) = Cchar('G')
_getboundsense(::MOI.Nonpositives) = Cchar('U')
_getboundsense(::MOI.Nonnegatives) = Cchar('L')


#=
    Get number of constraints
=#

function MOI.getattribute(m::CplexSolverInstance, ::MOI.NumberOfConstraints{F, S}) where F where S
    length(constrdict(m, MOI.ConstraintReference{F,S}(UInt(0))))
end
function MOI.cangetattribute(m::CplexSolverInstance, ::MOI.NumberOfConstraints{F, S}) where F where S
    return (F,S) in SUPPORTED_CONSTRAINTS
end

#=
    Get list of constraint references
=#

function MOI.getattribute(m::CplexSolverInstance, ::MOI.ListOfConstraintReferences{F, S}) where F where S
    collect(keys(constrdict(m, MOI.ConstraintReference{F,S}(UInt(0)))))
end
function MOI.cangetattribute(m::CplexSolverInstance, ::MOI.ListOfConstraintReferences{F, S}) where F where S
    return (F,S) in SUPPORTED_CONSTRAINTS
end

#=
    Get list of constraint types in model
=#

function MOI.getattribute(m::CplexSolverInstance, ::MOI.ListOfConstraints)
    ret = []
    for (F,S) in SUPPORTED_CONSTRAINTS
        if MOI.getattribute(m, MOI.NumberOfConstraints{F,S}()) > 0
            push!(ret, (F,S))
        end
    end
    ret
end
MOI.cangetattribute(m::CplexSolverInstance, ::MOI.ListOfConstraints) = true

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
    Vector valued bounds
=#
function setvariablebounds!(m::CplexSolverInstance, func::VecVar, set::S)  where S <: Union{MOI.Nonnegatives, MOI.Nonpositives}
    n = MOI.dimension(set)
    cpx_chgbds!(m.inner, getcol.(m, func.variables), fill(0.0, n), fill(_getboundsense(set), n))
end
function setvariablebounds!(m::CplexSolverInstance, func::VecVar, set::MOI.Zeros)
    n = MOI.dimension(set)
    cpx_chgbds!(m.inner, getcol.(m, func.variables), fill(0.0, n), fill(Cchar('L'), n))
    cpx_chgbds!(m.inner, getcol.(m, func.variables), fill(0.0, n), fill(Cchar('U'), n))
end

function MOI.addconstraint!(m::CplexSolverInstance, func::VecVar, set::S) where S <: Union{MOI.Nonnegatives, MOI.Nonpositives, MOI.Zeros}
    @assert length(func.variables) == MOI.dimension(set)
    setvariablebounds!(m, func, set)
    m.last_constraint_reference += 1
    ref = MOI.ConstraintReference{VecVar, S}(m.last_constraint_reference)
    dict = constrdict(m, ref)
    dict[ref] = func.variables
    return ref
end

#=
    Add linear constraints
=#

function MOI.addconstraint!(m::CplexSolverInstance, func::Linear, set::T) where T <: Union{LE, GE, EQ, IV}
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

function addlinearconstraint!(m::CplexSolverInstance, func::Linear, set::IV)
    addlinearconstraint!(m, func, Cchar('R'), set.lower)
    cpx_chgrngval!(m.inner, [cpx_getnumrows(m.inner)], [set.upper - set.lower])
end

function addlinearconstraint!(m::CplexSolverInstance, func::Linear, sense::Cchar, rhs)
    if abs(func.constant) > eps(Float64)
        warn("Constant in scalar function moved into set.")
    end
    cpx_addrows!(m.inner, [1], getcol.(m, func.variables), func.coefficients, [sense], [rhs - func.constant])
end

#=
    Add linear constraints (plural)
=#

function MOI.addconstraints!(m::CplexSolverInstance, func::Vector{Linear}, set::Vector{S}) where S <: Union{LE, GE, EQ, IV}
    @assert length(func) == length(set)
    numrows = cpx_getnumrows(m.inner)
    addlinearconstraints!(m, func, set)
    crefs = Vector{MOI.ConstraintReference{Linear, S}}(length(func))
    for i in 1:length(func)
        m.last_constraint_reference += 1
        ref = MOI.ConstraintReference{Linear, S}(m.last_constraint_reference)
        dict = constrdict(m, ref)
        dict[ref] = numrows + i
        push!(m.constraint_primal_solution, NaN)
        push!(m.constraint_dual_solution, NaN)
        crefs[i] = ref
    end
    return crefs
end

function addlinearconstraints!(m::CplexSolverInstance, func::Vector{Linear}, set::Vector{LE})
    addlinearconstraints!(m, func, fill(Cchar('L'), length(func)), [s.upper for s in set])
end
function addlinearconstraints!(m::CplexSolverInstance, func::Vector{Linear}, set::Vector{GE})
    addlinearconstraints!(m, func, fill(Cchar('G'), length(func)), [s.lower for s in set])
end
function addlinearconstraints!(m::CplexSolverInstance, func::Vector{Linear}, set::Vector{EQ})
    addlinearconstraints!(m, func, fill(Cchar('E'), length(func)), [s.value for s in set])
end

function addlinearconstraints!(m::CplexSolverInstance, func::Vector{Linear}, set::Vector{IV})
    numrows = cpx_getnumrows(m.inner)
    addlinearconstraints!(m, func, fill(Cchar('R'), length(func)), [s.lower for s in set])
    numrows2 = cpx_getnumrows(m.inner)
    cpx_chgrngval!(m.inner, collect(numrows+1:numrows2), [s.upper - s.lower for s in set])
end

function addlinearconstraints!(m::CplexSolverInstance, func::Vector{Linear}, sense::Vector{Cchar}, rhs::Vector{Float64})
    # loop through once to get number of non-zeros and to move rhs across
    nnz = 0
    for (i, f) in enumerate(func)
        if abs(f.constant) > eps(Float64)
            warn("Constant in scalar function moved into set.")
            rhs[i] -= f.constant
        end
        nnz += length(f.coefficients)
    end

    rowbegins = Vector{Int}(length(func))   # index of start of each row
    column_indices = Vector{Int}(nnz)       # flattened columns for each function
    nnz_vals = Vector{Float64}(nnz)         # corresponding non-zeros
    cnt = 1
    for (fi, f) in enumerate(func)
        rowbegins[fi] = cnt
        for (var, coef) in zip(f.variables, f.coefficients)
            column_indices[cnt] = getcol(m, var)
            nnz_vals[cnt] = coef
            cnt += 1
        end
    end
    cpx_addrows!(m.inner, rowbegins, column_indices, nnz_vals, sense, rhs)
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

function MOI.getattribute(m::CplexSolverInstance, ::MOI.ConstraintFunction, c::LCR{<: Union{LE, GE, EQ, IV}})
    # TODO more efficiently
    colidx, coefs = cpx_getrows(m.inner, m[c])
    MOI.ScalarAffineFunction(m.variable_references[colidx+1] , coefs, 0.0)
end
MOI.cangetattribute(m::CplexSolverInstance, ::MOI.ConstraintFunction, c::LCR{<: Union{LE, GE, EQ, IV}}) = true

#=
    Scalar Coefficient Change of Linear Constraint
=#

function MOI.modifyconstraint!(m::CplexSolverInstance, c::LCR{<: Union{LE, GE, EQ, IV}}, chg::MOI.ScalarCoefficientChange{Float64})
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

function MOI.modifyconstraint!(m::CplexSolverInstance, c::LCR{IV}, set::IV)
    # the column 0 (or -1 in 0-index) is the rhs.
    # a range constraint has the RHS value of the lower limit of the range, and
    # a rngval equal to upper-lower.
    row = m[c]
    cpx_chgcoef!(m.inner, row, 0, set.lower)
    cpx_chgrngval!(m.inner, [row], [set.upper - set.lower])
end

#=
    Delete a linear constraint
=#

function deleteref!(m::CplexSolverInstance, row::Int, ref::LCR{<: Union{LE, GE, EQ, IV}})
    deleteref!(cmap(m).less_than, row, ref)
    deleteref!(cmap(m).greater_than, row, ref)
    deleteref!(cmap(m).equal_to, row, ref)
    deleteref!(cmap(m).interval, row, ref)
end
function MOI.delete!(m::CplexSolverInstance, c::LCR{<: Union{LE, GE, EQ, IV}})
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
    cpx_chgctype!(m.inner, [getcol(m, v)], [CPX_BINARY])
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
    cpx_chgctype!(m.inner, [getcol(m, v)], [CPX_CONTINUOUS])
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
    cpx_chgctype!(m.inner, [getcol(m, v)], [CPX_INTEGER])
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
    cpx_chgctype!(m.inner, [getcol(m, v)], [CPX_CONTINUOUS])
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


#=
    Quadratic constraint
=#

function MOI.addconstraint!(m::CplexSolverInstance, func::Quad, set::S) where S <: Union{LE, GE, EQ}
    addquadraticconstraint!(m, func, set)
    m.last_constraint_reference += 1
    ref = MOI.ConstraintReference{Quad, S}(m.last_constraint_reference)
    dict = constrdict(m, ref)
    dict[ref] = cpx_getnumqconstrs(m.inner)
    push!(m.qconstraint_primal_solution, NaN)
    push!(m.qconstraint_dual_solution, NaN)
    return ref
end

function addquadraticconstraint!(m::CplexSolverInstance, func::Quad, set::LE)
    addquadraticconstraint!(m, func, Cchar('L'), set.upper)
end
function addquadraticconstraint!(m::CplexSolverInstance, func::Quad, set::GE)
    addquadraticconstraint!(m, func, Cchar('G'), set.lower)
end
function addquadraticconstraint!(m::CplexSolverInstance, func::Quad, set::EQ)
    addquadraticconstraint!(m, func, Cchar('E'), set.value)
end
function addquadraticconstraint!(m::CplexSolverInstance, f::Quad, sense::Cchar, rhs::Float64)
    if abs(f.constant) > 0
        warn("Constant in quadratic function. Moving into set")
    end
    ri, ci, vi = reduceduplicates(
        getcol.(m, f.quadratic_rowvariables),
        getcol.(m, f.quadratic_colvariables),
        f.quadratic_coefficients
    )
    cpx_addqconstr!(m.inner,
        getcol.(m, f.affine_variables),
        f.affine_coefficients,
        rhs - f.constant,
        sense,
        ri, ci, vi
    )
end

function reduceduplicates(rowi::Vector{T}, coli::Vector{T}, vals::Vector{S}) where T where S
    @assert length(rowi) == length(coli) == length(vals)
    d = Dict{Tuple{T, T},S}()
    for (r,c,v) in zip(rowi, coli, vals)
        if haskey(d, (r,c))
            d[(r,c)] += v
        else
            d[(r,c)] = v
        end
    end
    ri = Vector{T}(length(d))
    ci = Vector{T}(length(d))
    vi = Vector{S}(length(d))
    for (i, (key, val)) in enumerate(d)
        ri[i] = key[1]
        ci[i] = key[2]
        vi[i] = val
    end
    ri, ci, vi
end

#=
    Vector valued constraints
=#


function MOI.addconstraint!(m::CplexSolverInstance, func::VecLin, set::S) where S <: Union{MOI.Nonnegatives, MOI.Nonpositives, MOI.Zeros}
    @assert MOI.dimension(set) == length(func.constant)

    nrows = cpx_getnumrows(m.inner)
    addlinearconstraint!(m, func, _getsense(set))
    nrows2 = cpx_getnumrows(m.inner)

    m.last_constraint_reference += 1
    ref = MOI.ConstraintReference{VecLin, S}(m.last_constraint_reference)

    dict = constrdict(m, ref)
    dict[ref] = collect(nrows+1:nrows2)
    for i in 1:MOI.dimension(set)
        push!(m.constraint_primal_solution, NaN)
        push!(m.constraint_dual_solution, NaN)
    end
    ref
end

function addlinearconstraint!(m::CplexSolverInstance, func::VecLin, sense::Cchar)
    @assert length(func.outputindex) == length(func.variables) == length(func.coefficients)
    # get list of unique rows
    rows = unique(func.outputindex)
    @assert length(rows) == length(func.constant)
    # sort into row order
    pidx = sortperm(func.outputindex)
    cols = getcol.(m, func.variables)[pidx]
    vals = func.coefficients[pidx]
    # loop through to gte starting position of each row
    rowbegins = Vector{Int}(length(rows))
    rowbegins[1] = 1
    cnt = 1
    for i in 2:length(pidx)
        if func.outputindex[pidx[i]] != func.outputindex[pidx[i-1]]
            cnt += 1
            rowbegins[cnt] = i
        end
    end
    cpx_addrows!(m.inner, rowbegins, cols, vals, fill(sense, length(rows)), -func.constant)
end

function MOI.modifyconstraint!(m::CplexSolverInstance, ref::VLCR{<: Union{MOI.Nonnegatives, MOI.Nonpositives, MOI.Zeros}}, chg::MOI.VectorConstantChange{Float64})
    @assert length(chg.new_constant) == length(m[ref])
    for (r, v) in zip(m[ref], chg.new_constant)
        cpx_chgcoef!(m.inner, r, 0, -v)
    end
end
