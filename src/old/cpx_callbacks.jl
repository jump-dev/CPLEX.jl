function get_best_bound(m::Model)
    objval_p = Vector{Cdouble}(1)
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

function setcallbackcut(cbdata::CallbackData, wherefrom::Cint, ind::Vector{Cint}, val::Vector{Cdouble}, sense::Char, rhs::Cdouble, purgeable::Cint)
    len = length(ind)
    @assert length(val) == len
    sns = convert(Cint, sense)
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
                      cbdata.model.env.ptr, cbdata.cbdata, wherefrom, len, rhs, sns, ind-Cint(1), val, purgeable)
    if stat != 0
        throw(CplexError(cbdata.model.env.ptr, stat))
    end
end

function setcallbackcutlocal(cbdata::CallbackData, wherefrom::Cint, ind::Vector{Cint}, val::Vector{Cdouble}, sense::Char, rhs::Cdouble, purgeable::Cint)
    len = length(ind)
    @assert length(val) == len
    sns = convert(Cint, sense)
    stat = @cpx_ccall(cutcallbackaddlocal, Cint, (
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
                      cbdata.model.env.ptr, cbdata.cbdata, wherefrom, len, rhs, sns, ind-Cint(1), val, purgeable)
    if stat != 0
        throw(CplexError(cbdata.model.env.ptr, stat))
    end
end



cbcut(cbdata::CallbackData, wherefrom::Cint, ind::Vector{Cint}, val::Vector{Cdouble}, sense::Char, rhs::Cdouble) =
        setcallbackcut(cbdata, wherefrom, ind, val, sense, rhs, convert(Cint,CPX_USECUT_PURGE))

cbcutlocal(cbdata::CallbackData, wherefrom::Cint, ind::Vector{Cint}, val::Vector{Cdouble}, sense::Char, rhs::Cdouble) =
        setcallbackcutlocal(cbdata, wherefrom, ind, val, sense, rhs, convert(Cint,CPX_USECUT_PURGE))

cblazy(cbdata::CallbackData, wherefrom::Cint, ind::Vector{Cint}, val::Vector{Cdouble}, sense::Char, rhs::Cdouble) =
        setcallbackcut(cbdata, wherefrom, ind, val, sense, rhs, convert(Cint,CPX_USECUT_FORCE))

cblazylocal(cbdata::CallbackData, wherefrom::Cint, ind::Vector{Cint}, val::Vector{Cdouble}, sense::Char, rhs::Cdouble) =
        setcallbackcutlocal(cbdata, wherefrom, ind, val, sense, rhs, convert(Cint,CPX_USECUT_FORCE))

function cbbranch(cbdata::CallbackData, wherefrom::Cint, idx::Cint, LU::Cchar, bd::Cdouble, nodeest::Cdouble)
    seqnum = Vector{Cint}(1)
    stat = @cpx_ccall(branchcallbackbranchbds, Cint, (Ptr{Void},Ptr{Void},Cint,Cint,Ptr{Cint},Ptr{Cchar},Ptr{Cdouble},Cdouble,Ptr{Void},Ptr{Cint}),
                      cbdata.model.env.ptr,cbdata.cbdata,wherefrom,convert(Cint,1),[idx],[LU],[bd],nodeest,C_NULL,seqnum)
    if stat != 0
        throw(CplexError(cbdata.model.env.ptr, stat))
    end
    return seqnum[1]
end

function cbbranchconstr(cbdata::CallbackData, wherefrom::Cint, indices::Vector{Cint}, coeffs::Vector{Cdouble}, rhs::Cdouble, sense::Cchar, nodeest::Cdouble)
    seqnum = Vector{Cint}(1)
    stat = @cpx_ccall(branchcallbackbranchconstraints, Cint,
                      (Ptr{Void},
                       Ptr{Void},
                       Cint,
                       Cint,
                       Cint,
                       Ptr{Cdouble},
                       Ptr{Cchar},
                       Ptr{Cint},
                       Ptr{Cint},
                       Ptr{Cdouble},
                       Cdouble,
                       Ptr{Void},
                       Ptr{Cint}),
                      cbdata.model.env.ptr,
                      cbdata.cbdata,
                      wherefrom,
                      convert(Cint,1),
                      convert(Cint,length(indices)),
                      [rhs],
                      [sense],
                      Cint[0],
                      indices,
                      coeffs,
                      nodeest,
                      C_NULL,
                      seqnum)
    if stat != 0
        throw(CplexError(cbdata.model.env.ptr, stat))
    end
    return seqnum[1]
end
