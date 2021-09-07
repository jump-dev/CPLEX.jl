mutable struct _ConflictRefinerData
    confstat::Cint
    rowind::Vector{Cint}
    rowbdstat::Vector{Cint}
    confnumrows::Cint
    colind::Vector{Cint}
    colbdstat::Vector{Cint}
    confnumcols::Cint
end

function MOI.compute_conflict!(model::Optimizer)
    # This function always calls refineconflict first, which starts the conflict
    # refiner. In other words, any call to this function is expensive.
    confnumrows_p = Ref{Cint}(0)
    confnumcols_p = Ref{Cint}(0)
    ret = CPXrefineconflict(model.env, model.lp, confnumrows_p, confnumcols_p)
    _check_ret(model, ret)
    # Then, retrieve it.
    confstat_p = Ref{Cint}()
    rowind = Vector{Cint}(undef, confnumrows_p[])
    rowbdstat = Vector{Cint}(undef, confnumrows_p[])
    confnumrows_p = Ref{Cint}()
    colind = Vector{Cint}(undef, confnumcols_p[])
    colbdstat = Vector{Cint}(undef, confnumcols_p[])
    confnumcols_p = Ref{Cint}()
    ret = CPXgetconflict(
        model.env,
        model.lp,
        confstat_p,
        rowind,
        rowbdstat,
        confnumrows_p,
        colind,
        colbdstat,
        confnumcols_p,
    )
    if ret == CPXERR_NO_CONFLICT
        model.conflict = _ConflictRefinerData(
            CPX_STAT_CONFLICT_FEASIBLE,
            Cint[],
            Cint[],
            0,
            Cint[],
            Cint[],
            0,
        )
    else
        _check_ret(model, ret)
        model.conflict = _ConflictRefinerData(
            confstat_p[],
            rowind,
            rowbdstat,
            confnumrows_p[],
            colind,
            colbdstat,
            confnumcols_p[],
        )
    end
    return
end

function _ensure_conflict_computed(model::Optimizer)
    if model.conflict === nothing
        error(
            "Cannot access conflict status. Call " *
            "`MOI.compute_conflict!(model)` first. In case the model is " *
            "modified, the computed conflict will not be purged.",
        )
    end
end

"""
    ConflictStatus()

Return the raw status from CPLEX indicating the status of the last computed
conflict.

It returns an integer value defined in
the [CPLEX documentation](https://www.ibm.com/support/knowledgecenter/SSSA5P_12.10.0/ilog.odms.cplex.help/refcallablelibrary/macros/homepagesolutionstatus.html)
(with a name like `CPX_STAT_CONFLICT_*`) or `nothing` if the function
`MOI.compute_conflict!` has not yet been called.
"""
struct ConflictStatus <: MOI.AbstractModelAttribute end

MOI.supports(::Optimizer, ::ConflictStatus) = true

function MOI.get(model::Optimizer, ::ConflictStatus)
    return model.conflict === nothing ? nothing : model.conflict.confstat
end

MOI.supports(::Optimizer, ::MOI.ConflictStatus) = true

function MOI.get(model::Optimizer, ::MOI.ConflictStatus)
    status = MOI.get(model, ConflictStatus())
    if status === nothing
        return MOI.COMPUTE_CONFLICT_NOT_CALLED
    elseif status == CPX_STAT_CONFLICT_MINIMAL
        return MOI.CONFLICT_FOUND
    elseif status == CPX_STAT_CONFLICT_FEASIBLE
        return MOI.NO_CONFLICT_EXISTS
    else
        return MOI.NO_CONFLICT_FOUND
    end
end

function _get_conflict_status(
    model::Optimizer,
    index::MOI.ConstraintIndex{MOI.SingleVariable,<:Any},
)
    _ensure_conflict_computed(model)
    cindex = findfirst(
        x -> x == Cint(_info(model, index).column - 1),
        model.conflict.colind,
    )
    return cindex === nothing ? nothing : model.conflict.colbdstat[cindex]
end

function MOI.get(
    model::Optimizer,
    ::MOI.ConstraintConflictStatus,
    index::MOI.ConstraintIndex{MOI.SingleVariable,<:MOI.LessThan},
)
    status = _get_conflict_status(model, index)
    if status in (CPX_CONFLICT_MEMBER, CPX_CONFLICT_UB)
        return MOI.IN_CONFLICT
    elseif status in (CPX_CONFLICT_POSSIBLE_MEMBER, CPX_CONFLICT_POSSIBLE_UB)
        return MOI.MAYBE_IN_CONFLICT
    else
        return MOI.NOT_IN_CONFLICT
    end
end

function MOI.get(
    model::Optimizer,
    ::MOI.ConstraintConflictStatus,
    index::MOI.ConstraintIndex{MOI.SingleVariable,<:MOI.GreaterThan},
)
    status = _get_conflict_status(model, index)
    if status in (CPX_CONFLICT_MEMBER, CPX_CONFLICT_LB)
        return MOI.IN_CONFLICT
    elseif status in (CPX_CONFLICT_POSSIBLE_MEMBER, CPX_CONFLICT_POSSIBLE_LB)
        return MOI.MAYBE_IN_CONFLICT
    else
        return MOI.NOT_IN_CONFLICT
    end
end

function MOI.get(
    model::Optimizer,
    ::MOI.ConstraintConflictStatus,
    index::MOI.ConstraintIndex{
        MOI.SingleVariable,
        <:Union{MOI.EqualTo,MOI.Interval},
    },
)
    status = _get_conflict_status(model, index)
    if status in (CPX_CONFLICT_MEMBER, CPX_CONFLICT_LB, CPX_CONFLICT_UB)
        return MOI.IN_CONFLICT
    elseif status in (
        CPX_CONFLICT_POSSIBLE_MEMBER,
        CPX_CONFLICT_POSSIBLE_LB,
        CPX_CONFLICT_POSSIBLE_UB,
    )
        return MOI.MAYBE_IN_CONFLICT
    else
        return MOI.NOT_IN_CONFLICT
    end
end

function MOI.get(
    model::Optimizer,
    ::MOI.ConstraintConflictStatus,
    index::MOI.ConstraintIndex{
        <:MOI.ScalarAffineFunction,
        <:Union{MOI.LessThan,MOI.GreaterThan,MOI.EqualTo},
    },
)
    _ensure_conflict_computed(model)
    rindex = findfirst(
        x -> x == Cint(_info(model, index).row - 1),
        model.conflict.rowind,
    )
    if rindex === nothing
        return MOI.NOT_IN_CONFLICT
    elseif model.conflict.rowbdstat[rindex] == CPX_CONFLICT_MEMBER
        return MOI.IN_CONFLICT
    else
        return MOI.MAYBE_IN_CONFLICT
    end
end

function MOI.get(
    model::Optimizer,
    ::MOI.ConstraintConflictStatus,
    index::MOI.ConstraintIndex{
        MOI.SingleVariable,
        <:Union{MOI.Integer,MOI.ZeroOne},
    },
)
    _ensure_conflict_computed(model)

    # CPLEX doesn't give that information (only linear constraints and bounds, 
    # i.e. about the linear relaxation), even though it will report a conflict.
    # Report that lack of information to the user.
    if MOI.is_valid(model, index)
        return MOI.MAYBE_IN_CONFLICT
    else
        throw(MOI.InvalidIndex(index))
    end
end

function MOI.supports(
    ::Optimizer,
    ::MOI.ConstraintConflictStatus,
    ::Type{MOI.ConstraintIndex{<:MOI.SingleVariable,<:_SCALAR_SETS}},
)
    return true
end

function MOI.supports(
    ::Optimizer,
    ::MOI.ConstraintConflictStatus,
    ::Type{
        MOI.ConstraintIndex{
            <:MOI.ScalarAffineFunction,
            <:Union{MOI.LessThan,MOI.GreaterThan,MOI.EqualTo},
        },
    },
)
    return true
end
