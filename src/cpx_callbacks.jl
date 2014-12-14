function get_best_bound(m::Model)
    objval_p = Array(Cdouble, 1)
    stat = @cpx_ccall(getbestobjval, Cint, (Ptr{Void}, Ptr{Void}, Ptr{Cdouble}), m.env.ptr, m.lp, objval_p)
    if stat != 0
        throw(CplexError(m.env.ptr, stat))
    end
    return objval_p[1]
end

type CallbackData
    cbdata::Ptr{Void}
    model::Model
end

export CallbackData

function setcallbackcut(cbdata::CallbackData, where::Cint, ind::Vector{Cint}, val::Vector{Cdouble}, sense::Char, rhs::Cdouble)
    len = length(ind)
    @assert length(val) == len
    sns = convert(Cint, sense)
    ## the last argument, purgeable, describes Cplex's treatment of the cut, i.e. whether it has liberty to drop it later in the tree.
    ## should really have default and then allow user override
    stat = @cpx_ccall(cutcallbackadd, Cint, (
                      Ptr{Void},
                      Ptr{Void},
                      Cint,
                      Cint,
                      Cdouble,
                      Cint,
                      Ptr{Cint},
                      Ptr{Cdouble},
                      Cint
                      ),
                      cbdata.model.env.ptr, cbdata.cbdata, where, len, rhs, sns, ind.-1, val, 0) # CPX_USECUT_FORCE = 0
    if stat != 0
        throw(CplexError(cbdata.model.env.ptr, stat))
    end
end

for f in (:cbcut, :cblazy)
    @eval ($f)(cbdata::CallbackData, where::Cint, ind::Vector{Cint}, val::Vector{Cdouble}, sense::Char, rhs::Cdouble) = 
        setcallbackcut(cbdata, where, ind, val, sense, rhs)
end

function cbbranch(cbdata::CallbackData, where::Cint, idx::Cint, LU::Cchar, bd::Cdouble, nodeest::Cdouble)
    seqnum = Array(Cint,1)
    stat = @cpx_ccall(branchcallbackbranchbds, Cint, (Ptr{Void},Ptr{Void},Cint,Cint,Ptr{Cint},Ptr{Cchar},Ptr{Cdouble},Cdouble,Ptr{Void},Ptr{Cint}),
                      cbdata.model.env.ptr,cbdata.cbdata,where,convert(Cint,1),[idx],[LU],[bd],nodeest,C_NULL,seqnum)
    if stat != 0
        throw(CplexError(cbdata.model.env.ptr, stat))
    end
    return seqnum[1]
end
