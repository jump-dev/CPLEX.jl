# Julia wrapper for header: cplex.h
# Automatically generated using Clang.jl


function CPXaddcols(env, lp, ccnt, nzcnt, obj, cmatbeg, cmatind, cmatval, lb, ub, colname)
    ccall((:CPXaddcols, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint, Cint, Ptr{Cdouble}, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Ptr{Cchar}}), env, lp, ccnt, nzcnt, obj, cmatbeg, cmatind, cmatval, lb, ub, colname)
end

function CPXaddfuncdest(env, channel, handle, msgfunction)
    ccall((:CPXaddfuncdest, libcplex), Cint, (CPXCENVptr, CPXCHANNELptr, Ptr{Cvoid}, Ptr{Cvoid}), env, channel, handle, msgfunction)
end

function CPXaddpwl(env, lp, vary, varx, preslope, postslope, nbreaks, breakx, breaky, pwlname)
    ccall((:CPXaddpwl, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint, Cint, Cdouble, Cdouble, Cint, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cchar}), env, lp, vary, varx, preslope, postslope, nbreaks, breakx, breaky, pwlname)
end

function CPXaddrows(env, lp, ccnt, rcnt, nzcnt, rhs, sense, rmatbeg, rmatind, rmatval, colname, rowname)
    ccall((:CPXaddrows, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint, Cint, Cint, Ptr{Cdouble}, Ptr{Cchar}, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}, Ptr{Ptr{Cchar}}, Ptr{Ptr{Cchar}}), env, lp, ccnt, rcnt, nzcnt, rhs, sense, rmatbeg, rmatind, rmatval, colname, rowname)
end

function CPXbasicpresolve(env, lp, redlb, redub, rstat)
    ccall((:CPXbasicpresolve, libcplex), Cint, (CPXCENVptr, CPXLPptr, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cint}), env, lp, redlb, redub, rstat)
end

function CPXbinvacol(env, lp, j, x)
    ccall((:CPXbinvacol, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Cint, Ptr{Cdouble}), env, lp, j, x)
end

function CPXbinvarow(env, lp, i, z)
    ccall((:CPXbinvarow, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Cint, Ptr{Cdouble}), env, lp, i, z)
end

function CPXbinvcol(env, lp, j, x)
    ccall((:CPXbinvcol, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Cint, Ptr{Cdouble}), env, lp, j, x)
end

function CPXbinvrow(env, lp, i, y)
    ccall((:CPXbinvrow, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Cint, Ptr{Cdouble}), env, lp, i, y)
end

function CPXboundsa(env, lp, _begin, _end, lblower, lbupper, ublower, ubupper)
    ccall((:CPXboundsa, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Cint, Cint, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}), env, lp, _begin, _end, lblower, lbupper, ublower, ubupper)
end

function CPXbtran(env, lp, y)
    ccall((:CPXbtran, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cdouble}), env, lp, y)
end

function CPXcallbackabort(context)
    ccall((:CPXcallbackabort, libcplex), Cvoid, (CPXCALLBACKCONTEXTptr,), context)
end

function CPXcallbackaddusercuts(context, rcnt, nzcnt, rhs, sense, rmatbeg, rmatind, rmatval, purgeable, _local)
    ccall((:CPXcallbackaddusercuts, libcplex), Cint, (CPXCALLBACKCONTEXTptr, Cint, Cint, Ptr{Cdouble}, Ptr{Cchar}, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}, Ptr{Cint}, Ptr{Cint}), context, rcnt, nzcnt, rhs, sense, rmatbeg, rmatind, rmatval, purgeable, _local)
end

function CPXcallbackcandidateispoint(context, ispoint_p)
    ccall((:CPXcallbackcandidateispoint, libcplex), Cint, (CPXCALLBACKCONTEXTptr, Ptr{Cint}), context, ispoint_p)
end

function CPXcallbackcandidateisray(context, isray_p)
    ccall((:CPXcallbackcandidateisray, libcplex), Cint, (CPXCALLBACKCONTEXTptr, Ptr{Cint}), context, isray_p)
end

function CPXcallbackexitcutloop(context)
    ccall((:CPXcallbackexitcutloop, libcplex), Cint, (CPXCALLBACKCONTEXTptr,), context)
end

function CPXcallbackgetcandidatepoint(context, x, _begin, _end, obj_p)
    ccall((:CPXcallbackgetcandidatepoint, libcplex), Cint, (CPXCALLBACKCONTEXTptr, Ptr{Cdouble}, Cint, Cint, Ptr{Cdouble}), context, x, _begin, _end, obj_p)
end

function CPXcallbackgetcandidateray(context, x, _begin, _end)
    ccall((:CPXcallbackgetcandidateray, libcplex), Cint, (CPXCALLBACKCONTEXTptr, Ptr{Cdouble}, Cint, Cint), context, x, _begin, _end)
end

function CPXcallbackgetfunc(env, lp, contextmask_p, callback_p, cbhandle_p)
    ccall((:CPXcallbackgetfunc, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{CPXLONG}, Ptr{Ptr{CPXCALLBACKFUNC}}, Ptr{Ptr{Cvoid}}), env, lp, contextmask_p, callback_p, cbhandle_p)
end

function CPXcallbackgetincumbent(context, x, _begin, _end, obj_p)
    ccall((:CPXcallbackgetincumbent, libcplex), Cint, (CPXCALLBACKCONTEXTptr, Ptr{Cdouble}, Cint, Cint, Ptr{Cdouble}), context, x, _begin, _end, obj_p)
end

function CPXcallbackgetinfodbl(context, what, data_p)
    ccall((:CPXcallbackgetinfodbl, libcplex), Cint, (CPXCALLBACKCONTEXTptr, CPXCALLBACKINFO, Ptr{Cdouble}), context, what, data_p)
end

function CPXcallbackgetinfoint(context, what, data_p)
    ccall((:CPXcallbackgetinfoint, libcplex), Cint, (CPXCALLBACKCONTEXTptr, CPXCALLBACKINFO, Ptr{CPXINT}), context, what, data_p)
end

function CPXcallbackgetinfolong(context, what, data_p)
    ccall((:CPXcallbackgetinfolong, libcplex), Cint, (CPXCALLBACKCONTEXTptr, CPXCALLBACKINFO, Ptr{CPXLONG}), context, what, data_p)
end

function CPXcallbackgetrelaxationpoint(context, x, _begin, _end, obj_p)
    ccall((:CPXcallbackgetrelaxationpoint, libcplex), Cint, (CPXCALLBACKCONTEXTptr, Ptr{Cdouble}, Cint, Cint, Ptr{Cdouble}), context, x, _begin, _end, obj_p)
end

function CPXcallbackgetrelaxationstatus(context, nodelpstat_p, flags)
    ccall((:CPXcallbackgetrelaxationstatus, libcplex), Cint, (CPXCALLBACKCONTEXTptr, Ptr{Cint}, CPXLONG), context, nodelpstat_p, flags)
end

function CPXcallbackmakebranch(context, varcnt, varind, varlu, varbd, rcnt, nzcnt, rhs, sense, rmatbeg, rmatind, rmatval, nodeest, seqnum_p)
    ccall((:CPXcallbackmakebranch, libcplex), Cint, (CPXCALLBACKCONTEXTptr, Cint, Ptr{Cint}, Ptr{Cchar}, Ptr{Cdouble}, Cint, Cint, Ptr{Cdouble}, Ptr{Cchar}, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}, Cdouble, Ptr{Cint}), context, varcnt, varind, varlu, varbd, rcnt, nzcnt, rhs, sense, rmatbeg, rmatind, rmatval, nodeest, seqnum_p)
end

function CPXcallbackpostheursoln(context, cnt, ind, val, obj, strat)
    ccall((:CPXcallbackpostheursoln, libcplex), Cint, (CPXCALLBACKCONTEXTptr, Cint, Ptr{Cint}, Ptr{Cdouble}, Cdouble, CPXCALLBACKSOLUTIONSTRATEGY), context, cnt, ind, val, obj, strat)
end

function CPXcallbackprunenode(context)
    ccall((:CPXcallbackprunenode, libcplex), Cint, (CPXCALLBACKCONTEXTptr,), context)
end

function CPXcallbackrejectcandidate(context, rcnt, nzcnt, rhs, sense, rmatbeg, rmatind, rmatval)
    ccall((:CPXcallbackrejectcandidate, libcplex), Cint, (CPXCALLBACKCONTEXTptr, Cint, Cint, Ptr{Cdouble}, Ptr{Cchar}, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}), context, rcnt, nzcnt, rhs, sense, rmatbeg, rmatind, rmatval)
end

function CPXcallbackrejectcandidatelocal(context, rcnt, nzcnt, rhs, sense, rmatbeg, rmatind, rmatval)
    ccall((:CPXcallbackrejectcandidatelocal, libcplex), Cint, (CPXCALLBACKCONTEXTptr, Cint, Cint, Ptr{Cdouble}, Ptr{Cchar}, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}), context, rcnt, nzcnt, rhs, sense, rmatbeg, rmatind, rmatval)
end

function CPXcallbacksetfunc(env, lp, contextmask, callback, userhandle)
    ccall((:CPXcallbacksetfunc, libcplex), Cint, (CPXENVptr, CPXLPptr, CPXLONG, CPXCALLBACKFUNC, Ptr{Cvoid}), env, lp, contextmask, callback, userhandle)
end

function CPXcheckdfeas(env, lp, infeas_p)
    ccall((:CPXcheckdfeas, libcplex), Cint, (CPXCENVptr, CPXLPptr, Ptr{Cint}), env, lp, infeas_p)
end

function CPXcheckpfeas(env, lp, infeas_p)
    ccall((:CPXcheckpfeas, libcplex), Cint, (CPXCENVptr, CPXLPptr, Ptr{Cint}), env, lp, infeas_p)
end

function CPXchecksoln(env, lp, lpstatus_p)
    ccall((:CPXchecksoln, libcplex), Cint, (CPXCENVptr, CPXLPptr, Ptr{Cint}), env, lp, lpstatus_p)
end

function CPXchgbds(env, lp, cnt, indices, lu, bd)
    ccall((:CPXchgbds, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint, Ptr{Cint}, Ptr{Cchar}, Ptr{Cdouble}), env, lp, cnt, indices, lu, bd)
end

function CPXchgcoef(env, lp, i, j, newvalue)
    ccall((:CPXchgcoef, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint, Cint, Cdouble), env, lp, i, j, newvalue)
end

function CPXchgcoeflist(env, lp, numcoefs, rowlist, collist, vallist)
    ccall((:CPXchgcoeflist, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}), env, lp, numcoefs, rowlist, collist, vallist)
end

function CPXchgcolname(env, lp, cnt, indices, newname)
    ccall((:CPXchgcolname, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint, Ptr{Cint}, Ptr{Ptr{Cchar}}), env, lp, cnt, indices, newname)
end

function CPXchgname(env, lp, key, ij, newname_str)
    ccall((:CPXchgname, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint, Cint, Ptr{Cchar}), env, lp, key, ij, newname_str)
end

function CPXchgobj(env, lp, cnt, indices, values)
    ccall((:CPXchgobj, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint, Ptr{Cint}, Ptr{Cdouble}), env, lp, cnt, indices, values)
end

function CPXchgobjoffset(env, lp, offset)
    ccall((:CPXchgobjoffset, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cdouble), env, lp, offset)
end

function CPXchgobjsen(env, lp, maxormin)
    ccall((:CPXchgobjsen, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint), env, lp, maxormin)
end

function CPXchgprobname(env, lp, probname)
    ccall((:CPXchgprobname, libcplex), Cint, (CPXCENVptr, CPXLPptr, Ptr{Cchar}), env, lp, probname)
end

function CPXchgprobtype(env, lp, type)
    ccall((:CPXchgprobtype, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint), env, lp, type)
end

function CPXchgprobtypesolnpool(env, lp, type, soln)
    ccall((:CPXchgprobtypesolnpool, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint, Cint), env, lp, type, soln)
end

function CPXchgrhs(env, lp, cnt, indices, values)
    ccall((:CPXchgrhs, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint, Ptr{Cint}, Ptr{Cdouble}), env, lp, cnt, indices, values)
end

function CPXchgrngval(env, lp, cnt, indices, values)
    ccall((:CPXchgrngval, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint, Ptr{Cint}, Ptr{Cdouble}), env, lp, cnt, indices, values)
end

function CPXchgrowname(env, lp, cnt, indices, newname)
    ccall((:CPXchgrowname, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint, Ptr{Cint}, Ptr{Ptr{Cchar}}), env, lp, cnt, indices, newname)
end

function CPXchgsense(env, lp, cnt, indices, sense)
    ccall((:CPXchgsense, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint, Ptr{Cint}, Ptr{Cchar}), env, lp, cnt, indices, sense)
end

function CPXcleanup(env, lp, eps)
    ccall((:CPXcleanup, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cdouble), env, lp, eps)
end

function CPXcloneprob(env, lp, status_p)
    ccall((:CPXcloneprob, libcplex), CPXLPptr, (CPXCENVptr, CPXCLPptr, Ptr{Cint}), env, lp, status_p)
end

function CPXcloseCPLEX(env_p)
    ccall((:CPXcloseCPLEX, libcplex), Cint, (Ptr{CPXENVptr},), env_p)
end

function CPXclpwrite(env, lp, filename_str)
    ccall((:CPXclpwrite, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cchar}), env, lp, filename_str)
end

function CPXcompletelp(env, lp)
    ccall((:CPXcompletelp, libcplex), Cint, (CPXCENVptr, CPXLPptr), env, lp)
end

function CPXcopybase(env, lp, cstat, rstat)
    ccall((:CPXcopybase, libcplex), Cint, (CPXCENVptr, CPXLPptr, Ptr{Cint}, Ptr{Cint}), env, lp, cstat, rstat)
end

function CPXcopybasednorms(env, lp, cstat, rstat, dnorm)
    ccall((:CPXcopybasednorms, libcplex), Cint, (CPXCENVptr, CPXLPptr, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}), env, lp, cstat, rstat, dnorm)
end

function CPXcopydnorms(env, lp, norm, head, len)
    ccall((:CPXcopydnorms, libcplex), Cint, (CPXCENVptr, CPXLPptr, Ptr{Cdouble}, Ptr{Cint}, Cint), env, lp, norm, head, len)
end

function CPXcopylp(env, lp, numcols, numrows, objsense, objective, rhs, sense, matbeg, matcnt, matind, matval, lb, ub, rngval)
    ccall((:CPXcopylp, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint, Cint, Cint, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cchar}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}), env, lp, numcols, numrows, objsense, objective, rhs, sense, matbeg, matcnt, matind, matval, lb, ub, rngval)
end

function CPXcopylpwnames(env, lp, numcols, numrows, objsense, objective, rhs, sense, matbeg, matcnt, matind, matval, lb, ub, rngval, colname, rowname)
    ccall((:CPXcopylpwnames, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint, Cint, Cint, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cchar}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Ptr{Cchar}}, Ptr{Ptr{Cchar}}), env, lp, numcols, numrows, objsense, objective, rhs, sense, matbeg, matcnt, matind, matval, lb, ub, rngval, colname, rowname)
end

function CPXcopynettolp(env, lp, net)
    ccall((:CPXcopynettolp, libcplex), Cint, (CPXCENVptr, CPXLPptr, CPXCNETptr), env, lp, net)
end

function CPXcopyobjname(env, lp, objname_str)
    ccall((:CPXcopyobjname, libcplex), Cint, (CPXCENVptr, CPXLPptr, Ptr{Cchar}), env, lp, objname_str)
end

function CPXcopypnorms(env, lp, cnorm, rnorm, len)
    ccall((:CPXcopypnorms, libcplex), Cint, (CPXCENVptr, CPXLPptr, Ptr{Cdouble}, Ptr{Cdouble}, Cint), env, lp, cnorm, rnorm, len)
end

function CPXcopyprotected(env, lp, cnt, indices)
    ccall((:CPXcopyprotected, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint, Ptr{Cint}), env, lp, cnt, indices)
end

function CPXcopystart(env, lp, cstat, rstat, cprim, rprim, cdual, rdual)
    ccall((:CPXcopystart, libcplex), Cint, (CPXCENVptr, CPXLPptr, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}), env, lp, cstat, rstat, cprim, rprim, cdual, rdual)
end

function CPXcreateprob(env, status_p, probname_str)
    ccall((:CPXcreateprob, libcplex), CPXLPptr, (CPXCENVptr, Ptr{Cint}, Ptr{Cchar}), env, status_p, probname_str)
end

function CPXcrushform(env, lp, len, ind, val, plen_p, poffset_p, pind, pval)
    ccall((:CPXcrushform, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Cint, Ptr{Cint}, Ptr{Cdouble}, Ptr{Cint}, Ptr{Cdouble}, Ptr{Cint}, Ptr{Cdouble}), env, lp, len, ind, val, plen_p, poffset_p, pind, pval)
end

function CPXcrushpi(env, lp, pi, prepi)
    ccall((:CPXcrushpi, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cdouble}, Ptr{Cdouble}), env, lp, pi, prepi)
end

function CPXcrushx(env, lp, x, prex)
    ccall((:CPXcrushx, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cdouble}, Ptr{Cdouble}), env, lp, x, prex)
end

function CPXdelcols(env, lp, _begin, _end)
    ccall((:CPXdelcols, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint, Cint), env, lp, _begin, _end)
end

function CPXdeldblannotation(env, lp, idx)
    ccall((:CPXdeldblannotation, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint), env, lp, idx)
end

function CPXdeldblannotations(env, lp, _begin, _end)
    ccall((:CPXdeldblannotations, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint, Cint), env, lp, _begin, _end)
end

function CPXdelfuncdest(env, channel, handle, msgfunction)
    ccall((:CPXdelfuncdest, libcplex), Cint, (CPXCENVptr, CPXCHANNELptr, Ptr{Cvoid}, Ptr{Cvoid}), env, channel, handle, msgfunction)
end

function CPXdellongannotation(env, lp, idx)
    ccall((:CPXdellongannotation, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint), env, lp, idx)
end

function CPXdellongannotations(env, lp, _begin, _end)
    ccall((:CPXdellongannotations, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint, Cint), env, lp, _begin, _end)
end

function CPXdelnames(env, lp)
    ccall((:CPXdelnames, libcplex), Cint, (CPXCENVptr, CPXLPptr), env, lp)
end

function CPXdelpwl(env, lp, _begin, _end)
    ccall((:CPXdelpwl, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint, Cint), env, lp, _begin, _end)
end

function CPXdelrows(env, lp, _begin, _end)
    ccall((:CPXdelrows, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint, Cint), env, lp, _begin, _end)
end

function CPXdelsetcols(env, lp, delstat)
    ccall((:CPXdelsetcols, libcplex), Cint, (CPXCENVptr, CPXLPptr, Ptr{Cint}), env, lp, delstat)
end

function CPXdelsetpwl(env, lp, delstat)
    ccall((:CPXdelsetpwl, libcplex), Cint, (CPXCENVptr, CPXLPptr, Ptr{Cint}), env, lp, delstat)
end

function CPXdelsetrows(env, lp, delstat)
    ccall((:CPXdelsetrows, libcplex), Cint, (CPXCENVptr, CPXLPptr, Ptr{Cint}), env, lp, delstat)
end

function CPXdeserializercreate(deser_p, size, buffer)
    ccall((:CPXdeserializercreate, libcplex), Cint, (Ptr{CPXDESERIALIZERptr}, CPXLONG, Ptr{Cvoid}), deser_p, size, buffer)
end

function CPXdeserializerdestroy(deser)
    ccall((:CPXdeserializerdestroy, libcplex), Cvoid, (CPXDESERIALIZERptr,), deser)
end

function CPXdeserializerleft(deser)
    ccall((:CPXdeserializerleft, libcplex), CPXLONG, (CPXCDESERIALIZERptr,), deser)
end

function CPXdisconnectchannel(env, channel)
    ccall((:CPXdisconnectchannel, libcplex), Cint, (CPXCENVptr, CPXCHANNELptr), env, channel)
end

function CPXdjfrompi(env, lp, pi, dj)
    ccall((:CPXdjfrompi, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cdouble}, Ptr{Cdouble}), env, lp, pi, dj)
end

function CPXdperwrite(env, lp, filename_str, epsilon)
    ccall((:CPXdperwrite, libcplex), Cint, (CPXCENVptr, CPXLPptr, Ptr{Cchar}, Cdouble), env, lp, filename_str, epsilon)
end

function CPXdratio(env, lp, indices, cnt, downratio, upratio, downenter, upenter, downstatus, upstatus)
    ccall((:CPXdratio, libcplex), Cint, (CPXCENVptr, CPXLPptr, Ptr{Cint}, Cint, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}), env, lp, indices, cnt, downratio, upratio, downenter, upenter, downstatus, upstatus)
end

function CPXdualfarkas(env, lp, y, proof_p)
    ccall((:CPXdualfarkas, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cdouble}, Ptr{Cdouble}), env, lp, y, proof_p)
end

function CPXdualopt(env, lp)
    ccall((:CPXdualopt, libcplex), Cint, (CPXCENVptr, CPXLPptr), env, lp)
end

function CPXdualwrite(env, lp, filename_str, objshift_p)
    ccall((:CPXdualwrite, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cchar}, Ptr{Cdouble}), env, lp, filename_str, objshift_p)
end

function CPXembwrite(env, lp, filename_str)
    ccall((:CPXembwrite, libcplex), Cint, (CPXCENVptr, CPXLPptr, Ptr{Cchar}), env, lp, filename_str)
end

function CPXfeasopt(env, lp, rhs, rng, lb, ub)
    ccall((:CPXfeasopt, libcplex), Cint, (CPXCENVptr, CPXLPptr, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}), env, lp, rhs, rng, lb, ub)
end

function CPXfeasoptext(env, lp, grpcnt, concnt, grppref, grpbeg, grpind, grptype)
    ccall((:CPXfeasoptext, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint, Cint, Ptr{Cdouble}, Ptr{Cint}, Ptr{Cint}, Ptr{Cchar}), env, lp, grpcnt, concnt, grppref, grpbeg, grpind, grptype)
end

function CPXfinalize()
    ccall((:CPXfinalize, libcplex), Cvoid, ())
end

function CPXflushchannel(env, channel)
    ccall((:CPXflushchannel, libcplex), Cint, (CPXCENVptr, CPXCHANNELptr), env, channel)
end

function CPXflushstdchannels(env)
    ccall((:CPXflushstdchannels, libcplex), Cint, (CPXCENVptr,), env)
end

function CPXfreepresolve(env, lp)
    ccall((:CPXfreepresolve, libcplex), Cint, (CPXCENVptr, CPXLPptr), env, lp)
end

function CPXfreeprob(env, lp_p)
    ccall((:CPXfreeprob, libcplex), Cint, (CPXCENVptr, Ptr{CPXLPptr}), env, lp_p)
end

function CPXftran(env, lp, x)
    ccall((:CPXftran, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cdouble}), env, lp, x)
end

function CPXgetax(env, lp, x, _begin, _end)
    ccall((:CPXgetax, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cdouble}, Cint, Cint), env, lp, x, _begin, _end)
end

function CPXgetbaritcnt(env, lp)
    ccall((:CPXgetbaritcnt, libcplex), Cint, (CPXCENVptr, CPXCLPptr), env, lp)
end

function CPXgetbase(env, lp, cstat, rstat)
    ccall((:CPXgetbase, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cint}, Ptr{Cint}), env, lp, cstat, rstat)
end

function CPXgetbasednorms(env, lp, cstat, rstat, dnorm)
    ccall((:CPXgetbasednorms, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}), env, lp, cstat, rstat, dnorm)
end

function CPXgetbhead(env, lp, head, x)
    ccall((:CPXgetbhead, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cint}, Ptr{Cdouble}), env, lp, head, x)
end

function CPXgetcallbackinfo(env, cbdata, wherefrom, whichinfo, result_p)
    ccall((:CPXgetcallbackinfo, libcplex), Cint, (CPXCENVptr, Ptr{Cvoid}, Cint, Cint, Ptr{Cvoid}), env, cbdata, wherefrom, whichinfo, result_p)
end

function CPXgetchannels(env, cpxresults_p, cpxwarning_p, cpxerror_p, cpxlog_p)
    ccall((:CPXgetchannels, libcplex), Cint, (CPXCENVptr, Ptr{CPXCHANNELptr}, Ptr{CPXCHANNELptr}, Ptr{CPXCHANNELptr}, Ptr{CPXCHANNELptr}), env, cpxresults_p, cpxwarning_p, cpxerror_p, cpxlog_p)
end

function CPXgetchgparam(env, cnt_p, paramnum, pspace, surplus_p)
    ccall((:CPXgetchgparam, libcplex), Cint, (CPXCENVptr, Ptr{Cint}, Ptr{Cint}, Cint, Ptr{Cint}), env, cnt_p, paramnum, pspace, surplus_p)
end

function CPXgetcoef(env, lp, i, j, coef_p)
    ccall((:CPXgetcoef, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Cint, Cint, Ptr{Cdouble}), env, lp, i, j, coef_p)
end

function CPXgetcolindex(env, lp, lname_str, index_p)
    ccall((:CPXgetcolindex, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cchar}, Ptr{Cint}), env, lp, lname_str, index_p)
end

function CPXgetcolinfeas(env, lp, x, infeasout, _begin, _end)
    ccall((:CPXgetcolinfeas, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cdouble}, Ptr{Cdouble}, Cint, Cint), env, lp, x, infeasout, _begin, _end)
end

function CPXgetcolname(env, lp, name, namestore, storespace, surplus_p, _begin, _end)
    ccall((:CPXgetcolname, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Ptr{Cchar}}, Ptr{Cchar}, Cint, Ptr{Cint}, Cint, Cint), env, lp, name, namestore, storespace, surplus_p, _begin, _end)
end

function CPXgetcols(env, lp, nzcnt_p, cmatbeg, cmatind, cmatval, cmatspace, surplus_p, _begin, _end)
    ccall((:CPXgetcols, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}, Cint, Ptr{Cint}, Cint, Cint), env, lp, nzcnt_p, cmatbeg, cmatind, cmatval, cmatspace, surplus_p, _begin, _end)
end

function CPXgetconflict(env, lp, confstat_p, rowind, rowbdstat, confnumrows_p, colind, colbdstat, confnumcols_p)
    ccall((:CPXgetconflict, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}), env, lp, confstat_p, rowind, rowbdstat, confnumrows_p, colind, colbdstat, confnumcols_p)
end

function CPXgetconflictext(env, lp, grpstat, beg, _end)
    ccall((:CPXgetconflictext, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cint}, Cint, Cint), env, lp, grpstat, beg, _end)
end

function CPXgetconflictgroups(env, lp, concnt_p, grppref, grpbeg, grpind, grptype, grpspace, surplus_p, _begin, _end)
    ccall((:CPXgetconflictgroups, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cint}, Ptr{Cdouble}, Ptr{Cint}, Ptr{Cint}, Ptr{Cchar}, Cint, Ptr{Cint}, Cint, Cint), env, lp, concnt_p, grppref, grpbeg, grpind, grptype, grpspace, surplus_p, _begin, _end)
end

function CPXgetconflictnumgroups(env, lp)
    ccall((:CPXgetconflictnumgroups, libcplex), Cint, (CPXCENVptr, CPXCLPptr), env, lp)
end

function CPXgetconflictnumpasses(env, lp)
    ccall((:CPXgetconflictnumpasses, libcplex), Cint, (CPXCENVptr, CPXCLPptr), env, lp)
end

function CPXgetcrossdexchcnt(env, lp)
    ccall((:CPXgetcrossdexchcnt, libcplex), Cint, (CPXCENVptr, CPXCLPptr), env, lp)
end

function CPXgetcrossdpushcnt(env, lp)
    ccall((:CPXgetcrossdpushcnt, libcplex), Cint, (CPXCENVptr, CPXCLPptr), env, lp)
end

function CPXgetcrosspexchcnt(env, lp)
    ccall((:CPXgetcrosspexchcnt, libcplex), Cint, (CPXCENVptr, CPXCLPptr), env, lp)
end

function CPXgetcrossppushcnt(env, lp)
    ccall((:CPXgetcrossppushcnt, libcplex), Cint, (CPXCENVptr, CPXCLPptr), env, lp)
end

function CPXgetdblannotationdefval(env, lp, idx, defval_p)
    ccall((:CPXgetdblannotationdefval, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Cint, Ptr{Cdouble}), env, lp, idx, defval_p)
end

function CPXgetdblannotationindex(env, lp, annotationname_str, index_p)
    ccall((:CPXgetdblannotationindex, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cchar}, Ptr{Cint}), env, lp, annotationname_str, index_p)
end

function CPXgetdblannotationname(env, lp, idx, buf_str, bufspace, surplus_p)
    ccall((:CPXgetdblannotationname, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Cint, Ptr{Cchar}, Cint, Ptr{Cint}), env, lp, idx, buf_str, bufspace, surplus_p)
end

function CPXgetdblannotations(env, lp, idx, objtype, annotation, _begin, _end)
    ccall((:CPXgetdblannotations, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Cint, Cint, Ptr{Cdouble}, Cint, Cint), env, lp, idx, objtype, annotation, _begin, _end)
end

function CPXgetdblparam(env, whichparam, value_p)
    ccall((:CPXgetdblparam, libcplex), Cint, (CPXCENVptr, Cint, Ptr{Cdouble}), env, whichparam, value_p)
end

function CPXgetdblquality(env, lp, quality_p, what)
    ccall((:CPXgetdblquality, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cdouble}, Cint), env, lp, quality_p, what)
end

function CPXgetdettime(env, dettimestamp_p)
    ccall((:CPXgetdettime, libcplex), Cint, (CPXCENVptr, Ptr{Cdouble}), env, dettimestamp_p)
end

function CPXgetdj(env, lp, dj, _begin, _end)
    ccall((:CPXgetdj, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cdouble}, Cint, Cint), env, lp, dj, _begin, _end)
end

function CPXgetdnorms(env, lp, norm, head, len_p)
    ccall((:CPXgetdnorms, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cdouble}, Ptr{Cint}, Ptr{Cint}), env, lp, norm, head, len_p)
end

function CPXgetdsbcnt(env, lp)
    ccall((:CPXgetdsbcnt, libcplex), Cint, (CPXCENVptr, CPXCLPptr), env, lp)
end

function CPXgeterrorstring(env, errcode, buffer_str)
    ccall((:CPXgeterrorstring, libcplex), CPXCCHARptr, (CPXCENVptr, Cint, Ptr{Cchar}), env, errcode, buffer_str)
end

function CPXgetgrad(env, lp, j, head, y)
    ccall((:CPXgetgrad, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Cint, Ptr{Cint}, Ptr{Cdouble}), env, lp, j, head, y)
end

function CPXgetijdiv(env, lp, idiv_p, jdiv_p)
    ccall((:CPXgetijdiv, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cint}, Ptr{Cint}), env, lp, idiv_p, jdiv_p)
end

function CPXgetijrow(env, lp, i, j, row_p)
    ccall((:CPXgetijrow, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Cint, Cint, Ptr{Cint}), env, lp, i, j, row_p)
end

function CPXgetintparam(env, whichparam, value_p)
    ccall((:CPXgetintparam, libcplex), Cint, (CPXCENVptr, Cint, Ptr{CPXINT}), env, whichparam, value_p)
end

function CPXgetintquality(env, lp, quality_p, what)
    ccall((:CPXgetintquality, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cint}, Cint), env, lp, quality_p, what)
end

function CPXgetitcnt(env, lp)
    ccall((:CPXgetitcnt, libcplex), Cint, (CPXCENVptr, CPXCLPptr), env, lp)
end

function CPXgetlb(env, lp, lb, _begin, _end)
    ccall((:CPXgetlb, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cdouble}, Cint, Cint), env, lp, lb, _begin, _end)
end

function CPXgetlogfilename(env, buf_str, bufspace, surplus_p)
    ccall((:CPXgetlogfilename, libcplex), Cint, (CPXCENVptr, Ptr{Cchar}, Cint, Ptr{Cint}), env, buf_str, bufspace, surplus_p)
end

function CPXgetlongannotationdefval(env, lp, idx, defval_p)
    ccall((:CPXgetlongannotationdefval, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Cint, Ptr{CPXLONG}), env, lp, idx, defval_p)
end

function CPXgetlongannotationindex(env, lp, annotationname_str, index_p)
    ccall((:CPXgetlongannotationindex, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cchar}, Ptr{Cint}), env, lp, annotationname_str, index_p)
end

function CPXgetlongannotationname(env, lp, idx, buf_str, bufspace, surplus_p)
    ccall((:CPXgetlongannotationname, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Cint, Ptr{Cchar}, Cint, Ptr{Cint}), env, lp, idx, buf_str, bufspace, surplus_p)
end

function CPXgetlongannotations(env, lp, idx, objtype, annotation, _begin, _end)
    ccall((:CPXgetlongannotations, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Cint, Cint, Ptr{CPXLONG}, Cint, Cint), env, lp, idx, objtype, annotation, _begin, _end)
end

function CPXgetlongparam(env, whichparam, value_p)
    ccall((:CPXgetlongparam, libcplex), Cint, (CPXCENVptr, Cint, Ptr{CPXLONG}), env, whichparam, value_p)
end

function CPXgetlpcallbackfunc(env, callback_p, cbhandle_p)
    ccall((:CPXgetlpcallbackfunc, libcplex), Cint, (CPXCENVptr, Ptr{Ptr{Cvoid}}, Ptr{Ptr{Cvoid}}), env, callback_p, cbhandle_p)
end

function CPXgetmethod(env, lp)
    ccall((:CPXgetmethod, libcplex), Cint, (CPXCENVptr, CPXCLPptr), env, lp)
end

function CPXgetnetcallbackfunc(env, callback_p, cbhandle_p)
    ccall((:CPXgetnetcallbackfunc, libcplex), Cint, (CPXCENVptr, Ptr{Ptr{Cvoid}}, Ptr{Ptr{Cvoid}}), env, callback_p, cbhandle_p)
end

function CPXgetnumcols(env, lp)
    ccall((:CPXgetnumcols, libcplex), Cint, (CPXCENVptr, CPXCLPptr), env, lp)
end

function CPXgetnumcores(env, numcores_p)
    ccall((:CPXgetnumcores, libcplex), Cint, (CPXCENVptr, Ptr{Cint}), env, numcores_p)
end

function CPXgetnumdblannotations(env, lp)
    ccall((:CPXgetnumdblannotations, libcplex), Cint, (CPXCENVptr, CPXCLPptr), env, lp)
end

function CPXgetnumlongannotations(env, lp)
    ccall((:CPXgetnumlongannotations, libcplex), Cint, (CPXCENVptr, CPXCLPptr), env, lp)
end

function CPXgetnumnz(env, lp)
    ccall((:CPXgetnumnz, libcplex), Cint, (CPXCENVptr, CPXCLPptr), env, lp)
end

function CPXgetnumobjs(env, lp)
    ccall((:CPXgetnumobjs, libcplex), Cint, (CPXCENVptr, CPXCLPptr), env, lp)
end

function CPXgetnumpwl(env, lp)
    ccall((:CPXgetnumpwl, libcplex), Cint, (CPXCENVptr, CPXCLPptr), env, lp)
end

function CPXgetnumrows(env, lp)
    ccall((:CPXgetnumrows, libcplex), Cint, (CPXCENVptr, CPXCLPptr), env, lp)
end

function CPXgetobj(env, lp, obj, _begin, _end)
    ccall((:CPXgetobj, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cdouble}, Cint, Cint), env, lp, obj, _begin, _end)
end

function CPXgetobjname(env, lp, buf_str, bufspace, surplus_p)
    ccall((:CPXgetobjname, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cchar}, Cint, Ptr{Cint}), env, lp, buf_str, bufspace, surplus_p)
end

function CPXgetobjoffset(env, lp, objoffset_p)
    ccall((:CPXgetobjoffset, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cdouble}), env, lp, objoffset_p)
end

function CPXgetobjsen(env, lp)
    ccall((:CPXgetobjsen, libcplex), Cint, (CPXCENVptr, CPXCLPptr), env, lp)
end

function CPXgetobjval(env, lp, objval_p)
    ccall((:CPXgetobjval, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cdouble}), env, lp, objval_p)
end

function CPXgetparamhiername(env, whichparam, name_str)
    ccall((:CPXgetparamhiername, libcplex), Cint, (CPXCENVptr, Cint, Ptr{Cchar}), env, whichparam, name_str)
end

function CPXgetparamname(env, whichparam, name_str)
    ccall((:CPXgetparamname, libcplex), Cint, (CPXCENVptr, Cint, Ptr{Cchar}), env, whichparam, name_str)
end

function CPXgetparamnum(env, name_str, whichparam_p)
    ccall((:CPXgetparamnum, libcplex), Cint, (CPXCENVptr, Ptr{Cchar}, Ptr{Cint}), env, name_str, whichparam_p)
end

function CPXgetparamtype(env, whichparam, paramtype)
    ccall((:CPXgetparamtype, libcplex), Cint, (CPXCENVptr, Cint, Ptr{Cint}), env, whichparam, paramtype)
end

function CPXgetphase1cnt(env, lp)
    ccall((:CPXgetphase1cnt, libcplex), Cint, (CPXCENVptr, CPXCLPptr), env, lp)
end

function CPXgetpi(env, lp, pi, _begin, _end)
    ccall((:CPXgetpi, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cdouble}, Cint, Cint), env, lp, pi, _begin, _end)
end

function CPXgetpnorms(env, lp, cnorm, rnorm, len_p)
    ccall((:CPXgetpnorms, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cint}), env, lp, cnorm, rnorm, len_p)
end

function CPXgetprestat(env, lp, prestat_p, pcstat, prstat, ocstat, orstat)
    ccall((:CPXgetprestat, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}), env, lp, prestat_p, pcstat, prstat, ocstat, orstat)
end

function CPXgetprobname(env, lp, buf_str, bufspace, surplus_p)
    ccall((:CPXgetprobname, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cchar}, Cint, Ptr{Cint}), env, lp, buf_str, bufspace, surplus_p)
end

function CPXgetprobtype(env, lp)
    ccall((:CPXgetprobtype, libcplex), Cint, (CPXCENVptr, CPXCLPptr), env, lp)
end

function CPXgetprotected(env, lp, cnt_p, indices, pspace, surplus_p)
    ccall((:CPXgetprotected, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cint}, Ptr{Cint}, Cint, Ptr{Cint}), env, lp, cnt_p, indices, pspace, surplus_p)
end

function CPXgetpsbcnt(env, lp)
    ccall((:CPXgetpsbcnt, libcplex), Cint, (CPXCENVptr, CPXCLPptr), env, lp)
end

function CPXgetpwl(env, lp, pwlindex, vary_p, varx_p, preslope_p, postslope_p, nbreaks_p, breakx, breaky, breakspace, surplus_p)
    ccall((:CPXgetpwl, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Cint, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cint}, Ptr{Cdouble}, Ptr{Cdouble}, Cint, Ptr{Cint}), env, lp, pwlindex, vary_p, varx_p, preslope_p, postslope_p, nbreaks_p, breakx, breaky, breakspace, surplus_p)
end

function CPXgetpwlindex(env, lp, lname_str, index_p)
    ccall((:CPXgetpwlindex, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cchar}, Ptr{Cint}), env, lp, lname_str, index_p)
end

function CPXgetpwlname(env, lp, buf_str, bufspace, surplus_p, which)
    ccall((:CPXgetpwlname, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cchar}, Cint, Ptr{Cint}, Cint), env, lp, buf_str, bufspace, surplus_p, which)
end

function CPXgetray(env, lp, z)
    ccall((:CPXgetray, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cdouble}), env, lp, z)
end

function CPXgetredlp(env, lp, redlp_p)
    ccall((:CPXgetredlp, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{CPXCLPptr}), env, lp, redlp_p)
end

function CPXgetrhs(env, lp, rhs, _begin, _end)
    ccall((:CPXgetrhs, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cdouble}, Cint, Cint), env, lp, rhs, _begin, _end)
end

function CPXgetrngval(env, lp, rngval, _begin, _end)
    ccall((:CPXgetrngval, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cdouble}, Cint, Cint), env, lp, rngval, _begin, _end)
end

function CPXgetrowindex(env, lp, lname_str, index_p)
    ccall((:CPXgetrowindex, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cchar}, Ptr{Cint}), env, lp, lname_str, index_p)
end

function CPXgetrowinfeas(env, lp, x, infeasout, _begin, _end)
    ccall((:CPXgetrowinfeas, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cdouble}, Ptr{Cdouble}, Cint, Cint), env, lp, x, infeasout, _begin, _end)
end

function CPXgetrowname(env, lp, name, namestore, storespace, surplus_p, _begin, _end)
    ccall((:CPXgetrowname, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Ptr{Cchar}}, Ptr{Cchar}, Cint, Ptr{Cint}, Cint, Cint), env, lp, name, namestore, storespace, surplus_p, _begin, _end)
end

function CPXgetrows(env, lp, nzcnt_p, rmatbeg, rmatind, rmatval, rmatspace, surplus_p, _begin, _end)
    ccall((:CPXgetrows, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}, Cint, Ptr{Cint}, Cint, Cint), env, lp, nzcnt_p, rmatbeg, rmatind, rmatval, rmatspace, surplus_p, _begin, _end)
end

function CPXgetsense(env, lp, sense, _begin, _end)
    ccall((:CPXgetsense, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cchar}, Cint, Cint), env, lp, sense, _begin, _end)
end

function CPXgetsiftitcnt(env, lp)
    ccall((:CPXgetsiftitcnt, libcplex), Cint, (CPXCENVptr, CPXCLPptr), env, lp)
end

function CPXgetsiftphase1cnt(env, lp)
    ccall((:CPXgetsiftphase1cnt, libcplex), Cint, (CPXCENVptr, CPXCLPptr), env, lp)
end

function CPXgetslack(env, lp, slack, _begin, _end)
    ccall((:CPXgetslack, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cdouble}, Cint, Cint), env, lp, slack, _begin, _end)
end

function CPXgetsolnpooldblquality(env, lp, soln, quality_p, what)
    ccall((:CPXgetsolnpooldblquality, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Cint, Ptr{Cdouble}, Cint), env, lp, soln, quality_p, what)
end

function CPXgetsolnpoolintquality(env, lp, soln, quality_p, what)
    ccall((:CPXgetsolnpoolintquality, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Cint, Ptr{Cint}, Cint), env, lp, soln, quality_p, what)
end

function CPXgetstat(env, lp)
    ccall((:CPXgetstat, libcplex), Cint, (CPXCENVptr, CPXCLPptr), env, lp)
end

function CPXgetstatstring(env, statind, buffer_str)
    ccall((:CPXgetstatstring, libcplex), CPXCHARptr, (CPXCENVptr, Cint, Ptr{Cchar}), env, statind, buffer_str)
end

function CPXgetstrparam(env, whichparam, value_str)
    ccall((:CPXgetstrparam, libcplex), Cint, (CPXCENVptr, Cint, Ptr{Cchar}), env, whichparam, value_str)
end

function CPXgettime(env, timestamp_p)
    ccall((:CPXgettime, libcplex), Cint, (CPXCENVptr, Ptr{Cdouble}), env, timestamp_p)
end

function CPXgettuningcallbackfunc(env, callback_p, cbhandle_p)
    ccall((:CPXgettuningcallbackfunc, libcplex), Cint, (CPXCENVptr, Ptr{Ptr{Cvoid}}, Ptr{Ptr{Cvoid}}), env, callback_p, cbhandle_p)
end

function CPXgetub(env, lp, ub, _begin, _end)
    ccall((:CPXgetub, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cdouble}, Cint, Cint), env, lp, ub, _begin, _end)
end

function CPXgetweight(env, lp, rcnt, rmatbeg, rmatind, rmatval, weight, dpriind)
    ccall((:CPXgetweight, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Cint, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}, Ptr{Cdouble}, Cint), env, lp, rcnt, rmatbeg, rmatind, rmatval, weight, dpriind)
end

function CPXgetx(env, lp, x, _begin, _end)
    ccall((:CPXgetx, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cdouble}, Cint, Cint), env, lp, x, _begin, _end)
end

function CPXhybnetopt(env, lp, method)
    ccall((:CPXhybnetopt, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint), env, lp, method)
end

function CPXinfodblparam(env, whichparam, defvalue_p, minvalue_p, maxvalue_p)
    ccall((:CPXinfodblparam, libcplex), Cint, (CPXCENVptr, Cint, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}), env, whichparam, defvalue_p, minvalue_p, maxvalue_p)
end

function CPXinfointparam(env, whichparam, defvalue_p, minvalue_p, maxvalue_p)
    ccall((:CPXinfointparam, libcplex), Cint, (CPXCENVptr, Cint, Ptr{CPXINT}, Ptr{CPXINT}, Ptr{CPXINT}), env, whichparam, defvalue_p, minvalue_p, maxvalue_p)
end

function CPXinfolongparam(env, whichparam, defvalue_p, minvalue_p, maxvalue_p)
    ccall((:CPXinfolongparam, libcplex), Cint, (CPXCENVptr, Cint, Ptr{CPXLONG}, Ptr{CPXLONG}, Ptr{CPXLONG}), env, whichparam, defvalue_p, minvalue_p, maxvalue_p)
end

function CPXinfostrparam(env, whichparam, defvalue_str)
    ccall((:CPXinfostrparam, libcplex), Cint, (CPXCENVptr, Cint, Ptr{Cchar}), env, whichparam, defvalue_str)
end

function CPXinitialize()
    ccall((:CPXinitialize, libcplex), Cvoid, ())
end

function CPXkilldnorms(lp)
    ccall((:CPXkilldnorms, libcplex), Cint, (CPXLPptr,), lp)
end

function CPXkillpnorms(lp)
    ccall((:CPXkillpnorms, libcplex), Cint, (CPXLPptr,), lp)
end

function CPXlpopt(env, lp)
    ccall((:CPXlpopt, libcplex), Cint, (CPXCENVptr, CPXLPptr), env, lp)
end

function CPXmbasewrite(env, lp, filename_str)
    ccall((:CPXmbasewrite, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cchar}), env, lp, filename_str)
end

function CPXmdleave(env, lp, indices, cnt, downratio, upratio)
    ccall((:CPXmdleave, libcplex), Cint, (CPXCENVptr, CPXLPptr, Ptr{Cint}, Cint, Ptr{Cdouble}, Ptr{Cdouble}), env, lp, indices, cnt, downratio, upratio)
end

function CPXmodelasstcallbackgetfunc(env, lp, callback_p, cbhandle_p)
    ccall((:CPXmodelasstcallbackgetfunc, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Ptr{CPXMODELASSTCALLBACKFUNC}}, Ptr{Ptr{Cvoid}}), env, lp, callback_p, cbhandle_p)
end

function CPXmodelasstcallbacksetfunc(env, lp, callback, userhandle)
    ccall((:CPXmodelasstcallbacksetfunc, libcplex), Cint, (CPXENVptr, CPXLPptr, CPXMODELASSTCALLBACKFUNC, Ptr{Cvoid}), env, lp, callback, userhandle)
end

function CPXmsgstr(channel, msg_str)
    ccall((:CPXmsgstr, libcplex), Cint, (CPXCHANNELptr, Ptr{Cchar}), channel, msg_str)
end

function CPXmultiobjchgattribs(env, lp, objind, offset, weight, priority, abstol, reltol, name)
    ccall((:CPXmultiobjchgattribs, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint, Cdouble, Cdouble, Cint, Cdouble, Cdouble, Ptr{Cchar}), env, lp, objind, offset, weight, priority, abstol, reltol, name)
end

function CPXmultiobjgetdblinfo(env, lp, subprob, info_p, what)
    ccall((:CPXmultiobjgetdblinfo, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Cint, Ptr{Cdouble}, Cint), env, lp, subprob, info_p, what)
end

function CPXmultiobjgetindex(env, lp, name, index_p)
    ccall((:CPXmultiobjgetindex, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cchar}, Ptr{Cint}), env, lp, name, index_p)
end

function CPXmultiobjgetintinfo(env, lp, subprob, info_p, what)
    ccall((:CPXmultiobjgetintinfo, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Cint, Ptr{Cint}, Cint), env, lp, subprob, info_p, what)
end

function CPXmultiobjgetlonginfo(env, lp, subprob, info_p, what)
    ccall((:CPXmultiobjgetlonginfo, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Cint, Ptr{CPXLONG}, Cint), env, lp, subprob, info_p, what)
end

function CPXmultiobjgetname(env, lp, objind, buf_str, bufspace, surplus_p)
    ccall((:CPXmultiobjgetname, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Cint, Ptr{Cchar}, Cint, Ptr{Cint}), env, lp, objind, buf_str, bufspace, surplus_p)
end

function CPXmultiobjgetnumsolves(env, lp)
    ccall((:CPXmultiobjgetnumsolves, libcplex), Cint, (CPXCENVptr, CPXCLPptr), env, lp)
end

function CPXmultiobjgetobj(env, lp, n, coeffs, _begin, _end, offset_p, weight_p, priority_p, abstol_p, reltol_p)
    ccall((:CPXmultiobjgetobj, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Cint, Ptr{Cdouble}, Cint, Cint, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cint}, Ptr{Cdouble}, Ptr{Cdouble}), env, lp, n, coeffs, _begin, _end, offset_p, weight_p, priority_p, abstol_p, reltol_p)
end

function CPXmultiobjgetobjval(env, lp, n, objval_p)
    ccall((:CPXmultiobjgetobjval, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Cint, Ptr{Cdouble}), env, lp, n, objval_p)
end

function CPXmultiobjgetobjvalbypriority(env, lp, priority, objval_p)
    ccall((:CPXmultiobjgetobjvalbypriority, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Cint, Ptr{Cdouble}), env, lp, priority, objval_p)
end

function CPXmultiobjopt(env, lp, paramsets)
    ccall((:CPXmultiobjopt, libcplex), Cint, (CPXCENVptr, CPXLPptr, Ptr{CPXCPARAMSETptr}), env, lp, paramsets)
end

function CPXmultiobjsetobj(env, lp, n, objnz, objind, objval, offset, weight, priority, abstol, reltol, objname)
    ccall((:CPXmultiobjsetobj, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint, Cint, Ptr{Cint}, Ptr{Cdouble}, Cdouble, Cdouble, Cint, Cdouble, Cdouble, Ptr{Cchar}), env, lp, n, objnz, objind, objval, offset, weight, priority, abstol, reltol, objname)
end

function CPXNETextract(env, net, lp, colmap, rowmap)
    ccall((:CPXNETextract, libcplex), Cint, (CPXCENVptr, CPXNETptr, CPXCLPptr, Ptr{Cint}, Ptr{Cint}), env, net, lp, colmap, rowmap)
end

function CPXnewcols(env, lp, ccnt, obj, lb, ub, xctype, colname)
    ccall((:CPXnewcols, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cchar}, Ptr{Ptr{Cchar}}), env, lp, ccnt, obj, lb, ub, xctype, colname)
end

function CPXnewdblannotation(env, lp, annotationname_str, defval)
    ccall((:CPXnewdblannotation, libcplex), Cint, (CPXCENVptr, CPXLPptr, Ptr{Cchar}, Cdouble), env, lp, annotationname_str, defval)
end

function CPXnewlongannotation(env, lp, annotationname_str, defval)
    ccall((:CPXnewlongannotation, libcplex), Cint, (CPXCENVptr, CPXLPptr, Ptr{Cchar}, CPXLONG), env, lp, annotationname_str, defval)
end

function CPXnewrows(env, lp, rcnt, rhs, sense, rngval, rowname)
    ccall((:CPXnewrows, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint, Ptr{Cdouble}, Ptr{Cchar}, Ptr{Cdouble}, Ptr{Ptr{Cchar}}), env, lp, rcnt, rhs, sense, rngval, rowname)
end

function CPXobjsa(env, lp, _begin, _end, lower, upper)
    ccall((:CPXobjsa, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Cint, Cint, Ptr{Cdouble}, Ptr{Cdouble}), env, lp, _begin, _end, lower, upper)
end

function CPXopenCPLEX(status_p)
    ccall((:CPXopenCPLEX, libcplex), CPXENVptr, (Ptr{Cint},), status_p)
end

function CPXparamsetadddbl(env, ps, whichparam, newvalue)
    ccall((:CPXparamsetadddbl, libcplex), Cint, (CPXCENVptr, CPXPARAMSETptr, Cint, Cdouble), env, ps, whichparam, newvalue)
end

function CPXparamsetaddint(env, ps, whichparam, newvalue)
    ccall((:CPXparamsetaddint, libcplex), Cint, (CPXCENVptr, CPXPARAMSETptr, Cint, CPXINT), env, ps, whichparam, newvalue)
end

function CPXparamsetaddlong(env, ps, whichparam, newvalue)
    ccall((:CPXparamsetaddlong, libcplex), Cint, (CPXCENVptr, CPXPARAMSETptr, Cint, CPXLONG), env, ps, whichparam, newvalue)
end

function CPXparamsetaddstr(env, ps, whichparam, svalue)
    ccall((:CPXparamsetaddstr, libcplex), Cint, (CPXCENVptr, CPXPARAMSETptr, Cint, Ptr{Cchar}), env, ps, whichparam, svalue)
end

function CPXparamsetapply(env, ps)
    ccall((:CPXparamsetapply, libcplex), Cint, (CPXENVptr, CPXCPARAMSETptr), env, ps)
end

function CPXparamsetcopy(targetenv, targetps, sourceps)
    ccall((:CPXparamsetcopy, libcplex), Cint, (CPXCENVptr, CPXPARAMSETptr, CPXCPARAMSETptr), targetenv, targetps, sourceps)
end

function CPXparamsetcreate(env, status_p)
    ccall((:CPXparamsetcreate, libcplex), CPXPARAMSETptr, (CPXCENVptr, Ptr{Cint}), env, status_p)
end

function CPXparamsetdel(env, ps, whichparam)
    ccall((:CPXparamsetdel, libcplex), Cint, (CPXCENVptr, CPXPARAMSETptr, Cint), env, ps, whichparam)
end

function CPXparamsetfree(env, ps_p)
    ccall((:CPXparamsetfree, libcplex), Cint, (CPXCENVptr, Ptr{CPXPARAMSETptr}), env, ps_p)
end

function CPXparamsetgetdbl(env, ps, whichparam, dval_p)
    ccall((:CPXparamsetgetdbl, libcplex), Cint, (CPXCENVptr, CPXCPARAMSETptr, Cint, Ptr{Cdouble}), env, ps, whichparam, dval_p)
end

function CPXparamsetgetids(env, ps, cnt_p, whichparams, pspace, surplus_p)
    ccall((:CPXparamsetgetids, libcplex), Cint, (CPXCENVptr, CPXCPARAMSETptr, Ptr{Cint}, Ptr{Cint}, Cint, Ptr{Cint}), env, ps, cnt_p, whichparams, pspace, surplus_p)
end

function CPXparamsetgetint(env, ps, whichparam, ival_p)
    ccall((:CPXparamsetgetint, libcplex), Cint, (CPXCENVptr, CPXCPARAMSETptr, Cint, Ptr{CPXINT}), env, ps, whichparam, ival_p)
end

function CPXparamsetgetlong(env, ps, whichparam, ival_p)
    ccall((:CPXparamsetgetlong, libcplex), Cint, (CPXCENVptr, CPXCPARAMSETptr, Cint, Ptr{CPXLONG}), env, ps, whichparam, ival_p)
end

function CPXparamsetgetstr(env, ps, whichparam, sval)
    ccall((:CPXparamsetgetstr, libcplex), Cint, (CPXCENVptr, CPXCPARAMSETptr, Cint, Ptr{Cchar}), env, ps, whichparam, sval)
end

function CPXparamsetreadcopy(env, ps, filename_str)
    ccall((:CPXparamsetreadcopy, libcplex), Cint, (CPXENVptr, CPXPARAMSETptr, Ptr{Cchar}), env, ps, filename_str)
end

function CPXparamsetwrite(env, ps, filename_str)
    ccall((:CPXparamsetwrite, libcplex), Cint, (CPXCENVptr, CPXCPARAMSETptr, Ptr{Cchar}), env, ps, filename_str)
end

function CPXpivot(env, lp, jenter, jleave, leavestat)
    ccall((:CPXpivot, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint, Cint, Cint), env, lp, jenter, jleave, leavestat)
end

function CPXpivotin(env, lp, rlist, rlen)
    ccall((:CPXpivotin, libcplex), Cint, (CPXCENVptr, CPXLPptr, Ptr{Cint}, Cint), env, lp, rlist, rlen)
end

function CPXpivotout(env, lp, clist, clen)
    ccall((:CPXpivotout, libcplex), Cint, (CPXCENVptr, CPXLPptr, Ptr{Cint}, Cint), env, lp, clist, clen)
end

function CPXpperwrite(env, lp, filename_str, epsilon)
    ccall((:CPXpperwrite, libcplex), Cint, (CPXCENVptr, CPXLPptr, Ptr{Cchar}, Cdouble), env, lp, filename_str, epsilon)
end

function CPXpratio(env, lp, indices, cnt, downratio, upratio, downleave, upleave, downleavestatus, upleavestatus, downstatus, upstatus)
    ccall((:CPXpratio, libcplex), Cint, (CPXCENVptr, CPXLPptr, Ptr{Cint}, Cint, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}), env, lp, indices, cnt, downratio, upratio, downleave, upleave, downleavestatus, upleavestatus, downstatus, upstatus)
end

function CPXpreaddrows(env, lp, rcnt, nzcnt, rhs, sense, rmatbeg, rmatind, rmatval, rowname)
    ccall((:CPXpreaddrows, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint, Cint, Ptr{Cdouble}, Ptr{Cchar}, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}, Ptr{Ptr{Cchar}}), env, lp, rcnt, nzcnt, rhs, sense, rmatbeg, rmatind, rmatval, rowname)
end

function CPXprechgobj(env, lp, cnt, indices, values)
    ccall((:CPXprechgobj, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint, Ptr{Cint}, Ptr{Cdouble}), env, lp, cnt, indices, values)
end

function CPXpreslvwrite(env, lp, filename_str, objoff_p)
    ccall((:CPXpreslvwrite, libcplex), Cint, (CPXCENVptr, CPXLPptr, Ptr{Cchar}, Ptr{Cdouble}), env, lp, filename_str, objoff_p)
end

function CPXpresolve(env, lp, method)
    ccall((:CPXpresolve, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint), env, lp, method)
end

function CPXprimopt(env, lp)
    ccall((:CPXprimopt, libcplex), Cint, (CPXCENVptr, CPXLPptr), env, lp)
end

function CPXqpdjfrompi(env, lp, pi, x, dj)
    ccall((:CPXqpdjfrompi, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}), env, lp, pi, x, dj)
end

function CPXqpuncrushpi(env, lp, pi, prepi, x)
    ccall((:CPXqpuncrushpi, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}), env, lp, pi, prepi, x)
end

function CPXreadcopyannotations(env, lp, filename)
    ccall((:CPXreadcopyannotations, libcplex), Cint, (CPXCENVptr, CPXLPptr, Ptr{Cchar}), env, lp, filename)
end

function CPXreadcopybase(env, lp, filename_str)
    ccall((:CPXreadcopybase, libcplex), Cint, (CPXCENVptr, CPXLPptr, Ptr{Cchar}), env, lp, filename_str)
end

function CPXreadcopyparam(env, filename_str)
    ccall((:CPXreadcopyparam, libcplex), Cint, (CPXENVptr, Ptr{Cchar}), env, filename_str)
end

function CPXreadcopyprob(env, lp, filename_str, filetype)
    ccall((:CPXreadcopyprob, libcplex), Cint, (CPXCENVptr, CPXLPptr, Ptr{Cchar}, Ptr{Cchar}), env, lp, filename_str, filetype)
end

function CPXreadcopysol(env, lp, filename_str)
    ccall((:CPXreadcopysol, libcplex), Cint, (CPXCENVptr, CPXLPptr, Ptr{Cchar}), env, lp, filename_str)
end

function CPXreadcopystartinfo(env, lp, filename_str)
    ccall((:CPXreadcopystartinfo, libcplex), Cint, (CPXCENVptr, CPXLPptr, Ptr{Cchar}), env, lp, filename_str)
end

function CPXrefineconflict(env, lp, confnumrows_p, confnumcols_p)
    ccall((:CPXrefineconflict, libcplex), Cint, (CPXCENVptr, CPXLPptr, Ptr{Cint}, Ptr{Cint}), env, lp, confnumrows_p, confnumcols_p)
end

function CPXrefineconflictext(env, lp, grpcnt, concnt, grppref, grpbeg, grpind, grptype)
    ccall((:CPXrefineconflictext, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint, Cint, Ptr{Cdouble}, Ptr{Cint}, Ptr{Cint}, Ptr{Cchar}), env, lp, grpcnt, concnt, grppref, grpbeg, grpind, grptype)
end

function CPXrhssa(env, lp, _begin, _end, lower, upper)
    ccall((:CPXrhssa, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Cint, Cint, Ptr{Cdouble}, Ptr{Cdouble}), env, lp, _begin, _end, lower, upper)
end

function CPXrobustopt(env, lp, lblp, ublp, objchg, maxchg)
    ccall((:CPXrobustopt, libcplex), Cint, (CPXCENVptr, CPXLPptr, CPXLPptr, CPXLPptr, Cdouble, Ptr{Cdouble}), env, lp, lblp, ublp, objchg, maxchg)
end

function CPXserializercreate(ser_p)
    ccall((:CPXserializercreate, libcplex), Cint, (Ptr{CPXSERIALIZERptr},), ser_p)
end

function CPXserializerdestroy(ser)
    ccall((:CPXserializerdestroy, libcplex), Cvoid, (CPXSERIALIZERptr,), ser)
end

function CPXserializerlength(ser)
    ccall((:CPXserializerlength, libcplex), CPXLONG, (CPXCSERIALIZERptr,), ser)
end

function CPXserializerpayload(ser)
    ccall((:CPXserializerpayload, libcplex), Ptr{Cvoid}, (CPXCSERIALIZERptr,), ser)
end

function CPXsetdblannotations(env, lp, idx, objtype, cnt, indices, values)
    ccall((:CPXsetdblannotations, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint, Cint, Cint, Ptr{Cint}, Ptr{Cdouble}), env, lp, idx, objtype, cnt, indices, values)
end

function CPXsetdblparam(env, whichparam, newvalue)
    ccall((:CPXsetdblparam, libcplex), Cint, (CPXENVptr, Cint, Cdouble), env, whichparam, newvalue)
end

function CPXsetdefaults(env)
    ccall((:CPXsetdefaults, libcplex), Cint, (CPXENVptr,), env)
end

function CPXsetintparam(env, whichparam, newvalue)
    ccall((:CPXsetintparam, libcplex), Cint, (CPXENVptr, Cint, CPXINT), env, whichparam, newvalue)
end

function CPXsetlogfilename(env, filename, mode)
    ccall((:CPXsetlogfilename, libcplex), Cint, (CPXCENVptr, Ptr{Cchar}, Ptr{Cchar}), env, filename, mode)
end

function CPXsetlongannotations(env, lp, idx, objtype, cnt, indices, values)
    ccall((:CPXsetlongannotations, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint, Cint, Cint, Ptr{Cint}, Ptr{CPXLONG}), env, lp, idx, objtype, cnt, indices, values)
end

function CPXsetlongparam(env, whichparam, newvalue)
    ccall((:CPXsetlongparam, libcplex), Cint, (CPXENVptr, Cint, CPXLONG), env, whichparam, newvalue)
end

function CPXsetlpcallbackfunc(env, callback, cbhandle)
    ccall((:CPXsetlpcallbackfunc, libcplex), Cint, (CPXENVptr, Ptr{Cvoid}, Ptr{Cvoid}), env, callback, cbhandle)
end

function CPXsetnetcallbackfunc(env, callback, cbhandle)
    ccall((:CPXsetnetcallbackfunc, libcplex), Cint, (CPXENVptr, Ptr{Cvoid}, Ptr{Cvoid}), env, callback, cbhandle)
end

function CPXsetnumobjs(env, lp, n)
    ccall((:CPXsetnumobjs, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Cint), env, lp, n)
end

function CPXsetphase2(env, lp)
    ccall((:CPXsetphase2, libcplex), Cint, (CPXCENVptr, CPXLPptr), env, lp)
end

function CPXsetprofcallbackfunc(env, callback, cbhandle)
    ccall((:CPXsetprofcallbackfunc, libcplex), Cint, (CPXENVptr, Ptr{Cvoid}, Ptr{Cvoid}), env, callback, cbhandle)
end

function CPXsetstrparam(env, whichparam, newvalue_str)
    ccall((:CPXsetstrparam, libcplex), Cint, (CPXENVptr, Cint, Ptr{Cchar}), env, whichparam, newvalue_str)
end

function CPXsetterminate(env, terminate_p)
    ccall((:CPXsetterminate, libcplex), Cint, (CPXENVptr, Ptr{Cint}), env, terminate_p)
end

function CPXsettuningcallbackfunc(env, callback, cbhandle)
    ccall((:CPXsettuningcallbackfunc, libcplex), Cint, (CPXENVptr, Ptr{Cvoid}, Ptr{Cvoid}), env, callback, cbhandle)
end

function CPXsiftopt(env, lp)
    ccall((:CPXsiftopt, libcplex), Cint, (CPXCENVptr, CPXLPptr), env, lp)
end

function CPXslackfromx(env, lp, x, slack)
    ccall((:CPXslackfromx, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cdouble}, Ptr{Cdouble}), env, lp, x, slack)
end

function CPXsolninfo(env, lp, solnmethod_p, solntype_p, pfeasind_p, dfeasind_p)
    ccall((:CPXsolninfo, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}), env, lp, solnmethod_p, solntype_p, pfeasind_p, dfeasind_p)
end

function CPXsolution(env, lp, lpstat_p, objval_p, x, pi, slack, dj)
    ccall((:CPXsolution, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cint}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}), env, lp, lpstat_p, objval_p, x, pi, slack, dj)
end

function CPXsolwrite(env, lp, filename_str)
    ccall((:CPXsolwrite, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cchar}), env, lp, filename_str)
end

function CPXsolwritesolnpool(env, lp, soln, filename_str)
    ccall((:CPXsolwritesolnpool, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Cint, Ptr{Cchar}), env, lp, soln, filename_str)
end

function CPXsolwritesolnpoolall(env, lp, filename_str)
    ccall((:CPXsolwritesolnpoolall, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cchar}), env, lp, filename_str)
end

function CPXstrongbranch(env, lp, indices, cnt, downobj, upobj, itlim)
    ccall((:CPXstrongbranch, libcplex), Cint, (CPXCENVptr, CPXLPptr, Ptr{Cint}, Cint, Ptr{Cdouble}, Ptr{Cdouble}, Cint), env, lp, indices, cnt, downobj, upobj, itlim)
end

function CPXtightenbds(env, lp, cnt, indices, lu, bd)
    ccall((:CPXtightenbds, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint, Ptr{Cint}, Ptr{Cchar}, Ptr{Cdouble}), env, lp, cnt, indices, lu, bd)
end

function CPXtuneparam(env, lp, intcnt, intnum, intval, dblcnt, dblnum, dblval, strcnt, strnum, strval, tunestat_p)
    ccall((:CPXtuneparam, libcplex), Cint, (CPXENVptr, CPXLPptr, Cint, Ptr{Cint}, Ptr{Cint}, Cint, Ptr{Cint}, Ptr{Cdouble}, Cint, Ptr{Cint}, Ptr{Ptr{Cchar}}, Ptr{Cint}), env, lp, intcnt, intnum, intval, dblcnt, dblnum, dblval, strcnt, strnum, strval, tunestat_p)
end

function CPXtuneparamprobset(env, filecnt, filename, filetype, intcnt, intnum, intval, dblcnt, dblnum, dblval, strcnt, strnum, strval, tunestat_p)
    ccall((:CPXtuneparamprobset, libcplex), Cint, (CPXENVptr, Cint, Ptr{Ptr{Cchar}}, Ptr{Ptr{Cchar}}, Cint, Ptr{Cint}, Ptr{Cint}, Cint, Ptr{Cint}, Ptr{Cdouble}, Cint, Ptr{Cint}, Ptr{Ptr{Cchar}}, Ptr{Cint}), env, filecnt, filename, filetype, intcnt, intnum, intval, dblcnt, dblnum, dblval, strcnt, strnum, strval, tunestat_p)
end

function CPXuncrushform(env, lp, plen, pind, pval, len_p, offset_p, ind, val)
    ccall((:CPXuncrushform, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Cint, Ptr{Cint}, Ptr{Cdouble}, Ptr{Cint}, Ptr{Cdouble}, Ptr{Cint}, Ptr{Cdouble}), env, lp, plen, pind, pval, len_p, offset_p, ind, val)
end

function CPXuncrushpi(env, lp, pi, prepi)
    ccall((:CPXuncrushpi, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cdouble}, Ptr{Cdouble}), env, lp, pi, prepi)
end

function CPXuncrushx(env, lp, x, prex)
    ccall((:CPXuncrushx, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cdouble}, Ptr{Cdouble}), env, lp, x, prex)
end

function CPXunscaleprob(env, lp)
    ccall((:CPXunscaleprob, libcplex), Cint, (CPXCENVptr, CPXLPptr), env, lp)
end

function CPXversion(env)
    ccall((:CPXversion, libcplex), CPXCCHARptr, (CPXCENVptr,), env)
end

function CPXversionnumber(env, version_p)
    ccall((:CPXversionnumber, libcplex), Cint, (CPXCENVptr, Ptr{Cint}), env, version_p)
end

function CPXwriteannotations(env, lp, filename)
    ccall((:CPXwriteannotations, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cchar}), env, lp, filename)
end

function CPXwritebendersannotation(env, lp, filename)
    ccall((:CPXwritebendersannotation, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cchar}), env, lp, filename)
end

function CPXwriteparam(env, filename_str)
    ccall((:CPXwriteparam, libcplex), Cint, (CPXCENVptr, Ptr{Cchar}), env, filename_str)
end

function CPXwriteprob(env, lp, filename_str, filetype)
    ccall((:CPXwriteprob, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cchar}, Ptr{Cchar}), env, lp, filename_str, filetype)
end

function CPXbaropt(env, lp)
    ccall((:CPXbaropt, libcplex), Cint, (CPXCENVptr, CPXLPptr), env, lp)
end

function CPXhybbaropt(env, lp, method)
    ccall((:CPXhybbaropt, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint), env, lp, method)
end

function CPXaddindconstraints(env, lp, indcnt, type, indvar, complemented, nzcnt, rhs, sense, linbeg, linind, linval, indname)
    ccall((:CPXaddindconstraints, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Cint, Ptr{Cdouble}, Ptr{Cchar}, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}, Ptr{Ptr{Cchar}}), env, lp, indcnt, type, indvar, complemented, nzcnt, rhs, sense, linbeg, linind, linval, indname)
end

function CPXaddlazyconstraints(env, lp, rcnt, nzcnt, rhs, sense, rmatbeg, rmatind, rmatval, rowname)
    ccall((:CPXaddlazyconstraints, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint, Cint, Ptr{Cdouble}, Ptr{Cchar}, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}, Ptr{Ptr{Cchar}}), env, lp, rcnt, nzcnt, rhs, sense, rmatbeg, rmatind, rmatval, rowname)
end

function CPXaddmipstarts(env, lp, mcnt, nzcnt, beg, varindices, values, effortlevel, mipstartname)
    ccall((:CPXaddmipstarts, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint, Cint, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}, Ptr{Cint}, Ptr{Ptr{Cchar}}), env, lp, mcnt, nzcnt, beg, varindices, values, effortlevel, mipstartname)
end

function CPXaddsolnpooldivfilter(env, lp, lower_bound, upper_bound, nzcnt, ind, weight, refval, lname_str)
    ccall((:CPXaddsolnpooldivfilter, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cdouble, Cdouble, Cint, Ptr{Cint}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cchar}), env, lp, lower_bound, upper_bound, nzcnt, ind, weight, refval, lname_str)
end

function CPXaddsolnpoolrngfilter(env, lp, lb, ub, nzcnt, ind, val, lname_str)
    ccall((:CPXaddsolnpoolrngfilter, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cdouble, Cdouble, Cint, Ptr{Cint}, Ptr{Cdouble}, Ptr{Cchar}), env, lp, lb, ub, nzcnt, ind, val, lname_str)
end

function CPXaddsos(env, lp, numsos, numsosnz, sostype, sosbeg, sosind, soswt, sosname)
    ccall((:CPXaddsos, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint, Cint, Ptr{Cchar}, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}, Ptr{Ptr{Cchar}}), env, lp, numsos, numsosnz, sostype, sosbeg, sosind, soswt, sosname)
end

function CPXaddusercuts(env, lp, rcnt, nzcnt, rhs, sense, rmatbeg, rmatind, rmatval, rowname)
    ccall((:CPXaddusercuts, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint, Cint, Ptr{Cdouble}, Ptr{Cchar}, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}, Ptr{Ptr{Cchar}}), env, lp, rcnt, nzcnt, rhs, sense, rmatbeg, rmatind, rmatval, rowname)
end

function CPXbendersopt(env, lp)
    ccall((:CPXbendersopt, libcplex), Cint, (CPXCENVptr, CPXLPptr), env, lp)
end

function CPXbranchcallbackbranchasCPLEX(env, cbdata, wherefrom, num, userhandle, seqnum_p)
    ccall((:CPXbranchcallbackbranchasCPLEX, libcplex), Cint, (CPXCENVptr, Ptr{Cvoid}, Cint, Cint, Ptr{Cvoid}, Ptr{Cint}), env, cbdata, wherefrom, num, userhandle, seqnum_p)
end

function CPXbranchcallbackbranchbds(env, cbdata, wherefrom, cnt, indices, lu, bd, nodeest, userhandle, seqnum_p)
    ccall((:CPXbranchcallbackbranchbds, libcplex), Cint, (CPXCENVptr, Ptr{Cvoid}, Cint, Cint, Ptr{Cint}, Ptr{Cchar}, Ptr{Cdouble}, Cdouble, Ptr{Cvoid}, Ptr{Cint}), env, cbdata, wherefrom, cnt, indices, lu, bd, nodeest, userhandle, seqnum_p)
end

function CPXbranchcallbackbranchconstraints(env, cbdata, wherefrom, rcnt, nzcnt, rhs, sense, rmatbeg, rmatind, rmatval, nodeest, userhandle, seqnum_p)
    ccall((:CPXbranchcallbackbranchconstraints, libcplex), Cint, (CPXCENVptr, Ptr{Cvoid}, Cint, Cint, Cint, Ptr{Cdouble}, Ptr{Cchar}, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}, Cdouble, Ptr{Cvoid}, Ptr{Cint}), env, cbdata, wherefrom, rcnt, nzcnt, rhs, sense, rmatbeg, rmatind, rmatval, nodeest, userhandle, seqnum_p)
end

function CPXbranchcallbackbranchgeneral(env, cbdata, wherefrom, varcnt, varind, varlu, varbd, rcnt, nzcnt, rhs, sense, rmatbeg, rmatind, rmatval, nodeest, userhandle, seqnum_p)
    ccall((:CPXbranchcallbackbranchgeneral, libcplex), Cint, (CPXCENVptr, Ptr{Cvoid}, Cint, Cint, Ptr{Cint}, Ptr{Cchar}, Ptr{Cdouble}, Cint, Cint, Ptr{Cdouble}, Ptr{Cchar}, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}, Cdouble, Ptr{Cvoid}, Ptr{Cint}), env, cbdata, wherefrom, varcnt, varind, varlu, varbd, rcnt, nzcnt, rhs, sense, rmatbeg, rmatind, rmatval, nodeest, userhandle, seqnum_p)
end

function CPXcallbackgetgloballb(context, lb, _begin, _end)
    ccall((:CPXcallbackgetgloballb, libcplex), Cint, (CPXCALLBACKCONTEXTptr, Ptr{Cdouble}, Cint, Cint), context, lb, _begin, _end)
end

function CPXcallbackgetglobalub(context, ub, _begin, _end)
    ccall((:CPXcallbackgetglobalub, libcplex), Cint, (CPXCALLBACKCONTEXTptr, Ptr{Cdouble}, Cint, Cint), context, ub, _begin, _end)
end

function CPXcallbackgetlocallb(context, lb, _begin, _end)
    ccall((:CPXcallbackgetlocallb, libcplex), Cint, (CPXCALLBACKCONTEXTptr, Ptr{Cdouble}, Cint, Cint), context, lb, _begin, _end)
end

function CPXcallbackgetlocalub(context, ub, _begin, _end)
    ccall((:CPXcallbackgetlocalub, libcplex), Cint, (CPXCALLBACKCONTEXTptr, Ptr{Cdouble}, Cint, Cint), context, ub, _begin, _end)
end

function CPXcallbacksetnodeuserhandle(env, cbdata, wherefrom, nodeindex, userhandle, olduserhandle_p)
    ccall((:CPXcallbacksetnodeuserhandle, libcplex), Cint, (CPXCENVptr, Ptr{Cvoid}, Cint, Cint, Ptr{Cvoid}, Ptr{Ptr{Cvoid}}), env, cbdata, wherefrom, nodeindex, userhandle, olduserhandle_p)
end

function CPXcallbacksetuserhandle(env, cbdata, wherefrom, userhandle, olduserhandle_p)
    ccall((:CPXcallbacksetuserhandle, libcplex), Cint, (CPXCENVptr, Ptr{Cvoid}, Cint, Ptr{Cvoid}, Ptr{Ptr{Cvoid}}), env, cbdata, wherefrom, userhandle, olduserhandle_p)
end

function CPXchgctype(env, lp, cnt, indices, xctype)
    ccall((:CPXchgctype, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint, Ptr{Cint}, Ptr{Cchar}), env, lp, cnt, indices, xctype)
end

function CPXchgmipstarts(env, lp, mcnt, mipstartindices, nzcnt, beg, varindices, values, effortlevel)
    ccall((:CPXchgmipstarts, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint, Ptr{Cint}, Cint, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}, Ptr{Cint}), env, lp, mcnt, mipstartindices, nzcnt, beg, varindices, values, effortlevel)
end

function CPXcopyctype(env, lp, xctype)
    ccall((:CPXcopyctype, libcplex), Cint, (CPXCENVptr, CPXLPptr, Ptr{Cchar}), env, lp, xctype)
end

function CPXcopyorder(env, lp, cnt, indices, priority, direction)
    ccall((:CPXcopyorder, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}), env, lp, cnt, indices, priority, direction)
end

function CPXcopysos(env, lp, numsos, numsosnz, sostype, sosbeg, sosind, soswt, sosname)
    ccall((:CPXcopysos, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint, Cint, Ptr{Cchar}, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}, Ptr{Ptr{Cchar}}), env, lp, numsos, numsosnz, sostype, sosbeg, sosind, soswt, sosname)
end

function CPXcutcallbackadd(env, cbdata, wherefrom, nzcnt, rhs, sense, cutind, cutval, purgeable)
    ccall((:CPXcutcallbackadd, libcplex), Cint, (CPXCENVptr, Ptr{Cvoid}, Cint, Cint, Cdouble, Cint, Ptr{Cint}, Ptr{Cdouble}, Cint), env, cbdata, wherefrom, nzcnt, rhs, sense, cutind, cutval, purgeable)
end

function CPXcutcallbackaddlocal(env, cbdata, wherefrom, nzcnt, rhs, sense, cutind, cutval)
    ccall((:CPXcutcallbackaddlocal, libcplex), Cint, (CPXCENVptr, Ptr{Cvoid}, Cint, Cint, Cdouble, Cint, Ptr{Cint}, Ptr{Cdouble}), env, cbdata, wherefrom, nzcnt, rhs, sense, cutind, cutval)
end

function CPXdelindconstrs(env, lp, _begin, _end)
    ccall((:CPXdelindconstrs, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint, Cint), env, lp, _begin, _end)
end

function CPXdelmipstarts(env, lp, _begin, _end)
    ccall((:CPXdelmipstarts, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint, Cint), env, lp, _begin, _end)
end

function CPXdelsetmipstarts(env, lp, delstat)
    ccall((:CPXdelsetmipstarts, libcplex), Cint, (CPXCENVptr, CPXLPptr, Ptr{Cint}), env, lp, delstat)
end

function CPXdelsetsolnpoolfilters(env, lp, delstat)
    ccall((:CPXdelsetsolnpoolfilters, libcplex), Cint, (CPXCENVptr, CPXLPptr, Ptr{Cint}), env, lp, delstat)
end

function CPXdelsetsolnpoolsolns(env, lp, delstat)
    ccall((:CPXdelsetsolnpoolsolns, libcplex), Cint, (CPXCENVptr, CPXLPptr, Ptr{Cint}), env, lp, delstat)
end

function CPXdelsetsos(env, lp, delset)
    ccall((:CPXdelsetsos, libcplex), Cint, (CPXCENVptr, CPXLPptr, Ptr{Cint}), env, lp, delset)
end

function CPXdelsolnpoolfilters(env, lp, _begin, _end)
    ccall((:CPXdelsolnpoolfilters, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint, Cint), env, lp, _begin, _end)
end

function CPXdelsolnpoolsolns(env, lp, _begin, _end)
    ccall((:CPXdelsolnpoolsolns, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint, Cint), env, lp, _begin, _end)
end

function CPXdelsos(env, lp, _begin, _end)
    ccall((:CPXdelsos, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint, Cint), env, lp, _begin, _end)
end

function CPXfltwrite(env, lp, filename_str)
    ccall((:CPXfltwrite, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cchar}), env, lp, filename_str)
end

function CPXfreelazyconstraints(env, lp)
    ccall((:CPXfreelazyconstraints, libcplex), Cint, (CPXCENVptr, CPXLPptr), env, lp)
end

function CPXfreeusercuts(env, lp)
    ccall((:CPXfreeusercuts, libcplex), Cint, (CPXCENVptr, CPXLPptr), env, lp)
end

function CPXgetbestobjval(env, lp, objval_p)
    ccall((:CPXgetbestobjval, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cdouble}), env, lp, objval_p)
end

function CPXgetbranchcallbackfunc(env, branchcallback_p, cbhandle_p)
    ccall((:CPXgetbranchcallbackfunc, libcplex), Cint, (CPXCENVptr, Ptr{Ptr{Cvoid}}, Ptr{Ptr{Cvoid}}), env, branchcallback_p, cbhandle_p)
end

function CPXgetbranchnosolncallbackfunc(env, branchnosolncallback_p, cbhandle_p)
    ccall((:CPXgetbranchnosolncallbackfunc, libcplex), Cint, (CPXCENVptr, Ptr{Ptr{Cvoid}}, Ptr{Ptr{Cvoid}}), env, branchnosolncallback_p, cbhandle_p)
end

function CPXgetcallbackbranchconstraints(env, cbdata, wherefrom, which, cuts_p, nzcnt_p, rhs, sense, rmatbeg, rmatind, rmatval, rmatsz, surplus_p)
    ccall((:CPXgetcallbackbranchconstraints, libcplex), Cint, (CPXCENVptr, Ptr{Cvoid}, Cint, Cint, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}, Ptr{Cchar}, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}, Cint, Ptr{Cint}), env, cbdata, wherefrom, which, cuts_p, nzcnt_p, rhs, sense, rmatbeg, rmatind, rmatval, rmatsz, surplus_p)
end

function CPXgetcallbackctype(env, cbdata, wherefrom, xctype, _begin, _end)
    ccall((:CPXgetcallbackctype, libcplex), Cint, (CPXCENVptr, Ptr{Cvoid}, Cint, Ptr{Cchar}, Cint, Cint), env, cbdata, wherefrom, xctype, _begin, _end)
end

function CPXgetcallbackgloballb(env, cbdata, wherefrom, lb, _begin, _end)
    ccall((:CPXgetcallbackgloballb, libcplex), Cint, (CPXCENVptr, Ptr{Cvoid}, Cint, Ptr{Cdouble}, Cint, Cint), env, cbdata, wherefrom, lb, _begin, _end)
end

function CPXgetcallbackglobalub(env, cbdata, wherefrom, ub, _begin, _end)
    ccall((:CPXgetcallbackglobalub, libcplex), Cint, (CPXCENVptr, Ptr{Cvoid}, Cint, Ptr{Cdouble}, Cint, Cint), env, cbdata, wherefrom, ub, _begin, _end)
end

function CPXgetcallbackincumbent(env, cbdata, wherefrom, x, _begin, _end)
    ccall((:CPXgetcallbackincumbent, libcplex), Cint, (CPXCENVptr, Ptr{Cvoid}, Cint, Ptr{Cdouble}, Cint, Cint), env, cbdata, wherefrom, x, _begin, _end)
end

function CPXgetcallbackindicatorinfo(env, cbdata, wherefrom, iindex, whichinfo, result_p)
    ccall((:CPXgetcallbackindicatorinfo, libcplex), Cint, (CPXCENVptr, Ptr{Cvoid}, Cint, Cint, Cint, Ptr{Cvoid}), env, cbdata, wherefrom, iindex, whichinfo, result_p)
end

function CPXgetcallbacklp(env, cbdata, wherefrom, lp_p)
    ccall((:CPXgetcallbacklp, libcplex), Cint, (CPXCENVptr, Ptr{Cvoid}, Cint, Ptr{CPXCLPptr}), env, cbdata, wherefrom, lp_p)
end

function CPXgetcallbacknodeinfo(env, cbdata, wherefrom, nodeindex, whichinfo, result_p)
    ccall((:CPXgetcallbacknodeinfo, libcplex), Cint, (CPXCENVptr, Ptr{Cvoid}, Cint, Cint, Cint, Ptr{Cvoid}), env, cbdata, wherefrom, nodeindex, whichinfo, result_p)
end

function CPXgetcallbacknodeintfeas(env, cbdata, wherefrom, feas, _begin, _end)
    ccall((:CPXgetcallbacknodeintfeas, libcplex), Cint, (CPXCENVptr, Ptr{Cvoid}, Cint, Ptr{Cint}, Cint, Cint), env, cbdata, wherefrom, feas, _begin, _end)
end

function CPXgetcallbacknodelb(env, cbdata, wherefrom, lb, _begin, _end)
    ccall((:CPXgetcallbacknodelb, libcplex), Cint, (CPXCENVptr, Ptr{Cvoid}, Cint, Ptr{Cdouble}, Cint, Cint), env, cbdata, wherefrom, lb, _begin, _end)
end

function CPXgetcallbacknodelp(env, cbdata, wherefrom, nodelp_p)
    ccall((:CPXgetcallbacknodelp, libcplex), Cint, (CPXCENVptr, Ptr{Cvoid}, Cint, Ptr{CPXLPptr}), env, cbdata, wherefrom, nodelp_p)
end

function CPXgetcallbacknodeobjval(env, cbdata, wherefrom, objval_p)
    ccall((:CPXgetcallbacknodeobjval, libcplex), Cint, (CPXCENVptr, Ptr{Cvoid}, Cint, Ptr{Cdouble}), env, cbdata, wherefrom, objval_p)
end

function CPXgetcallbacknodestat(env, cbdata, wherefrom, nodestat_p)
    ccall((:CPXgetcallbacknodestat, libcplex), Cint, (CPXCENVptr, Ptr{Cvoid}, Cint, Ptr{Cint}), env, cbdata, wherefrom, nodestat_p)
end

function CPXgetcallbacknodeub(env, cbdata, wherefrom, ub, _begin, _end)
    ccall((:CPXgetcallbacknodeub, libcplex), Cint, (CPXCENVptr, Ptr{Cvoid}, Cint, Ptr{Cdouble}, Cint, Cint), env, cbdata, wherefrom, ub, _begin, _end)
end

function CPXgetcallbacknodex(env, cbdata, wherefrom, x, _begin, _end)
    ccall((:CPXgetcallbacknodex, libcplex), Cint, (CPXCENVptr, Ptr{Cvoid}, Cint, Ptr{Cdouble}, Cint, Cint), env, cbdata, wherefrom, x, _begin, _end)
end

function CPXgetcallbackorder(env, cbdata, wherefrom, priority, direction, _begin, _end)
    ccall((:CPXgetcallbackorder, libcplex), Cint, (CPXCENVptr, Ptr{Cvoid}, Cint, Ptr{Cint}, Ptr{Cint}, Cint, Cint), env, cbdata, wherefrom, priority, direction, _begin, _end)
end

function CPXgetcallbackpseudocosts(env, cbdata, wherefrom, uppc, downpc, _begin, _end)
    ccall((:CPXgetcallbackpseudocosts, libcplex), Cint, (CPXCENVptr, Ptr{Cvoid}, Cint, Ptr{Cdouble}, Ptr{Cdouble}, Cint, Cint), env, cbdata, wherefrom, uppc, downpc, _begin, _end)
end

function CPXgetcallbackseqinfo(env, cbdata, wherefrom, seqid, whichinfo, result_p)
    ccall((:CPXgetcallbackseqinfo, libcplex), Cint, (CPXCENVptr, Ptr{Cvoid}, Cint, Cint, Cint, Ptr{Cvoid}), env, cbdata, wherefrom, seqid, whichinfo, result_p)
end

function CPXgetcallbacksosinfo(env, cbdata, wherefrom, sosindex, member, whichinfo, result_p)
    ccall((:CPXgetcallbacksosinfo, libcplex), Cint, (CPXCENVptr, Ptr{Cvoid}, Cint, Cint, Cint, Cint, Ptr{Cvoid}), env, cbdata, wherefrom, sosindex, member, whichinfo, result_p)
end

function CPXgetctype(env, lp, xctype, _begin, _end)
    ccall((:CPXgetctype, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cchar}, Cint, Cint), env, lp, xctype, _begin, _end)
end

function CPXgetcutoff(env, lp, cutoff_p)
    ccall((:CPXgetcutoff, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cdouble}), env, lp, cutoff_p)
end

function CPXgetdeletenodecallbackfunc(env, deletecallback_p, cbhandle_p)
    ccall((:CPXgetdeletenodecallbackfunc, libcplex), Cint, (CPXCENVptr, Ptr{Ptr{Cvoid}}, Ptr{Ptr{Cvoid}}), env, deletecallback_p, cbhandle_p)
end

function CPXgetheuristiccallbackfunc(env, heuristiccallback_p, cbhandle_p)
    ccall((:CPXgetheuristiccallbackfunc, libcplex), Cint, (CPXCENVptr, Ptr{Ptr{Cvoid}}, Ptr{Ptr{Cvoid}}), env, heuristiccallback_p, cbhandle_p)
end

function CPXgetincumbentcallbackfunc(env, incumbentcallback_p, cbhandle_p)
    ccall((:CPXgetincumbentcallbackfunc, libcplex), Cint, (CPXCENVptr, Ptr{Ptr{Cvoid}}, Ptr{Ptr{Cvoid}}), env, incumbentcallback_p, cbhandle_p)
end

function CPXgetindconstr(env, lp, indvar_p, complemented_p, nzcnt_p, rhs_p, sense_p, linind, linval, space, surplus_p, which)
    ccall((:CPXgetindconstr, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}, Ptr{Cchar}, Ptr{Cint}, Ptr{Cdouble}, Cint, Ptr{Cint}, Cint), env, lp, indvar_p, complemented_p, nzcnt_p, rhs_p, sense_p, linind, linval, space, surplus_p, which)
end

function CPXgetindconstraints(env, lp, type, indvar, complemented, nzcnt_p, rhs, sense, linbeg, linind, linval, linspace, surplus_p, _begin, _end)
    ccall((:CPXgetindconstraints, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}, Ptr{Cchar}, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}, Cint, Ptr{Cint}, Cint, Cint), env, lp, type, indvar, complemented, nzcnt_p, rhs, sense, linbeg, linind, linval, linspace, surplus_p, _begin, _end)
end

function CPXgetindconstrindex(env, lp, lname_str, index_p)
    ccall((:CPXgetindconstrindex, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cchar}, Ptr{Cint}), env, lp, lname_str, index_p)
end

function CPXgetindconstrinfeas(env, lp, x, infeasout, _begin, _end)
    ccall((:CPXgetindconstrinfeas, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cdouble}, Ptr{Cdouble}, Cint, Cint), env, lp, x, infeasout, _begin, _end)
end

function CPXgetindconstrname(env, lp, buf_str, bufspace, surplus_p, which)
    ccall((:CPXgetindconstrname, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cchar}, Cint, Ptr{Cint}, Cint), env, lp, buf_str, bufspace, surplus_p, which)
end

function CPXgetindconstrslack(env, lp, indslack, _begin, _end)
    ccall((:CPXgetindconstrslack, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cdouble}, Cint, Cint), env, lp, indslack, _begin, _end)
end

function CPXgetinfocallbackfunc(env, callback_p, cbhandle_p)
    ccall((:CPXgetinfocallbackfunc, libcplex), Cint, (CPXCENVptr, Ptr{Ptr{Cvoid}}, Ptr{Ptr{Cvoid}}), env, callback_p, cbhandle_p)
end

function CPXgetlazyconstraintcallbackfunc(env, cutcallback_p, cbhandle_p)
    ccall((:CPXgetlazyconstraintcallbackfunc, libcplex), Cint, (CPXCENVptr, Ptr{Ptr{Cvoid}}, Ptr{Ptr{Cvoid}}), env, cutcallback_p, cbhandle_p)
end

function CPXgetmipcallbackfunc(env, callback_p, cbhandle_p)
    ccall((:CPXgetmipcallbackfunc, libcplex), Cint, (CPXCENVptr, Ptr{Ptr{Cvoid}}, Ptr{Ptr{Cvoid}}), env, callback_p, cbhandle_p)
end

function CPXgetmipitcnt(env, lp)
    ccall((:CPXgetmipitcnt, libcplex), Cint, (CPXCENVptr, CPXCLPptr), env, lp)
end

function CPXgetmiprelgap(env, lp, gap_p)
    ccall((:CPXgetmiprelgap, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cdouble}), env, lp, gap_p)
end

function CPXgetmipstartindex(env, lp, lname_str, index_p)
    ccall((:CPXgetmipstartindex, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cchar}, Ptr{Cint}), env, lp, lname_str, index_p)
end

function CPXgetmipstartname(env, lp, name, store, storesz, surplus_p, _begin, _end)
    ccall((:CPXgetmipstartname, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Ptr{Cchar}}, Ptr{Cchar}, Cint, Ptr{Cint}, Cint, Cint), env, lp, name, store, storesz, surplus_p, _begin, _end)
end

function CPXgetmipstarts(env, lp, nzcnt_p, beg, varindices, values, effortlevel, startspace, surplus_p, _begin, _end)
    ccall((:CPXgetmipstarts, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}, Ptr{Cint}, Cint, Ptr{Cint}, Cint, Cint), env, lp, nzcnt_p, beg, varindices, values, effortlevel, startspace, surplus_p, _begin, _end)
end

function CPXgetnodecallbackfunc(env, nodecallback_p, cbhandle_p)
    ccall((:CPXgetnodecallbackfunc, libcplex), Cint, (CPXCENVptr, Ptr{Ptr{Cvoid}}, Ptr{Ptr{Cvoid}}), env, nodecallback_p, cbhandle_p)
end

function CPXgetnodecnt(env, lp)
    ccall((:CPXgetnodecnt, libcplex), Cint, (CPXCENVptr, CPXCLPptr), env, lp)
end

function CPXgetnodeint(env, lp)
    ccall((:CPXgetnodeint, libcplex), Cint, (CPXCENVptr, CPXCLPptr), env, lp)
end

function CPXgetnodeleftcnt(env, lp)
    ccall((:CPXgetnodeleftcnt, libcplex), Cint, (CPXCENVptr, CPXCLPptr), env, lp)
end

function CPXgetnumbin(env, lp)
    ccall((:CPXgetnumbin, libcplex), Cint, (CPXCENVptr, CPXCLPptr), env, lp)
end

function CPXgetnumcuts(env, lp, cuttype, num_p)
    ccall((:CPXgetnumcuts, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Cint, Ptr{Cint}), env, lp, cuttype, num_p)
end

function CPXgetnumindconstrs(env, lp)
    ccall((:CPXgetnumindconstrs, libcplex), Cint, (CPXCENVptr, CPXCLPptr), env, lp)
end

function CPXgetnumint(env, lp)
    ccall((:CPXgetnumint, libcplex), Cint, (CPXCENVptr, CPXCLPptr), env, lp)
end

function CPXgetnumlazyconstraints(env, lp)
    ccall((:CPXgetnumlazyconstraints, libcplex), Cint, (CPXCENVptr, CPXCLPptr), env, lp)
end

function CPXgetnummipstarts(env, lp)
    ccall((:CPXgetnummipstarts, libcplex), Cint, (CPXCENVptr, CPXCLPptr), env, lp)
end

function CPXgetnumsemicont(env, lp)
    ccall((:CPXgetnumsemicont, libcplex), Cint, (CPXCENVptr, CPXCLPptr), env, lp)
end

function CPXgetnumsemiint(env, lp)
    ccall((:CPXgetnumsemiint, libcplex), Cint, (CPXCENVptr, CPXCLPptr), env, lp)
end

function CPXgetnumsos(env, lp)
    ccall((:CPXgetnumsos, libcplex), Cint, (CPXCENVptr, CPXCLPptr), env, lp)
end

function CPXgetnumusercuts(env, lp)
    ccall((:CPXgetnumusercuts, libcplex), Cint, (CPXCENVptr, CPXCLPptr), env, lp)
end

function CPXgetorder(env, lp, cnt_p, indices, priority, direction, ordspace, surplus_p)
    ccall((:CPXgetorder, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Cint, Ptr{Cint}), env, lp, cnt_p, indices, priority, direction, ordspace, surplus_p)
end

function CPXgetsolnpooldivfilter(env, lp, lower_cutoff_p, upper_cutoff_p, nzcnt_p, ind, val, refval, space, surplus_p, which)
    ccall((:CPXgetsolnpooldivfilter, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}, Ptr{Cdouble}, Cint, Ptr{Cint}, Cint), env, lp, lower_cutoff_p, upper_cutoff_p, nzcnt_p, ind, val, refval, space, surplus_p, which)
end

function CPXgetsolnpoolfilterindex(env, lp, lname_str, index_p)
    ccall((:CPXgetsolnpoolfilterindex, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cchar}, Ptr{Cint}), env, lp, lname_str, index_p)
end

function CPXgetsolnpoolfiltername(env, lp, buf_str, bufspace, surplus_p, which)
    ccall((:CPXgetsolnpoolfiltername, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cchar}, Cint, Ptr{Cint}, Cint), env, lp, buf_str, bufspace, surplus_p, which)
end

function CPXgetsolnpoolfiltertype(env, lp, ftype_p, which)
    ccall((:CPXgetsolnpoolfiltertype, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cint}, Cint), env, lp, ftype_p, which)
end

function CPXgetsolnpoolmeanobjval(env, lp, meanobjval_p)
    ccall((:CPXgetsolnpoolmeanobjval, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cdouble}), env, lp, meanobjval_p)
end

function CPXgetsolnpoolnumfilters(env, lp)
    ccall((:CPXgetsolnpoolnumfilters, libcplex), Cint, (CPXCENVptr, CPXCLPptr), env, lp)
end

function CPXgetsolnpoolnumreplaced(env, lp)
    ccall((:CPXgetsolnpoolnumreplaced, libcplex), Cint, (CPXCENVptr, CPXCLPptr), env, lp)
end

function CPXgetsolnpoolnumsolns(env, lp)
    ccall((:CPXgetsolnpoolnumsolns, libcplex), Cint, (CPXCENVptr, CPXCLPptr), env, lp)
end

function CPXgetsolnpoolobjval(env, lp, soln, objval_p)
    ccall((:CPXgetsolnpoolobjval, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Cint, Ptr{Cdouble}), env, lp, soln, objval_p)
end

function CPXgetsolnpoolqconstrslack(env, lp, soln, qcslack, _begin, _end)
    ccall((:CPXgetsolnpoolqconstrslack, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Cint, Ptr{Cdouble}, Cint, Cint), env, lp, soln, qcslack, _begin, _end)
end

function CPXgetsolnpoolrngfilter(env, lp, lb_p, ub_p, nzcnt_p, ind, val, space, surplus_p, which)
    ccall((:CPXgetsolnpoolrngfilter, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}, Cint, Ptr{Cint}, Cint), env, lp, lb_p, ub_p, nzcnt_p, ind, val, space, surplus_p, which)
end

function CPXgetsolnpoolslack(env, lp, soln, slack, _begin, _end)
    ccall((:CPXgetsolnpoolslack, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Cint, Ptr{Cdouble}, Cint, Cint), env, lp, soln, slack, _begin, _end)
end

function CPXgetsolnpoolsolnindex(env, lp, lname_str, index_p)
    ccall((:CPXgetsolnpoolsolnindex, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cchar}, Ptr{Cint}), env, lp, lname_str, index_p)
end

function CPXgetsolnpoolsolnname(env, lp, store, storesz, surplus_p, which)
    ccall((:CPXgetsolnpoolsolnname, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cchar}, Cint, Ptr{Cint}, Cint), env, lp, store, storesz, surplus_p, which)
end

function CPXgetsolnpoolx(env, lp, soln, x, _begin, _end)
    ccall((:CPXgetsolnpoolx, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Cint, Ptr{Cdouble}, Cint, Cint), env, lp, soln, x, _begin, _end)
end

function CPXgetsolvecallbackfunc(env, solvecallback_p, cbhandle_p)
    ccall((:CPXgetsolvecallbackfunc, libcplex), Cint, (CPXCENVptr, Ptr{Ptr{Cvoid}}, Ptr{Ptr{Cvoid}}), env, solvecallback_p, cbhandle_p)
end

function CPXgetsos(env, lp, numsosnz_p, sostype, sosbeg, sosind, soswt, sosspace, surplus_p, _begin, _end)
    ccall((:CPXgetsos, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cint}, Ptr{Cchar}, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}, Cint, Ptr{Cint}, Cint, Cint), env, lp, numsosnz_p, sostype, sosbeg, sosind, soswt, sosspace, surplus_p, _begin, _end)
end

function CPXgetsosindex(env, lp, lname_str, index_p)
    ccall((:CPXgetsosindex, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cchar}, Ptr{Cint}), env, lp, lname_str, index_p)
end

function CPXgetsosinfeas(env, lp, x, infeasout, _begin, _end)
    ccall((:CPXgetsosinfeas, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cdouble}, Ptr{Cdouble}, Cint, Cint), env, lp, x, infeasout, _begin, _end)
end

function CPXgetsosname(env, lp, name, namestore, storespace, surplus_p, _begin, _end)
    ccall((:CPXgetsosname, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Ptr{Cchar}}, Ptr{Cchar}, Cint, Ptr{Cint}, Cint, Cint), env, lp, name, namestore, storespace, surplus_p, _begin, _end)
end

function CPXgetsubmethod(env, lp)
    ccall((:CPXgetsubmethod, libcplex), Cint, (CPXCENVptr, CPXCLPptr), env, lp)
end

function CPXgetsubstat(env, lp)
    ccall((:CPXgetsubstat, libcplex), Cint, (CPXCENVptr, CPXCLPptr), env, lp)
end

function CPXgetusercutcallbackfunc(env, cutcallback_p, cbhandle_p)
    ccall((:CPXgetusercutcallbackfunc, libcplex), Cint, (CPXCENVptr, Ptr{Ptr{Cvoid}}, Ptr{Ptr{Cvoid}}), env, cutcallback_p, cbhandle_p)
end

function CPXindconstrslackfromx(env, lp, x, indslack)
    ccall((:CPXindconstrslackfromx, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cdouble}, Ptr{Cdouble}), env, lp, x, indslack)
end

function CPXmipopt(env, lp)
    ccall((:CPXmipopt, libcplex), Cint, (CPXCENVptr, CPXLPptr), env, lp)
end

function CPXordread(env, filename_str, numcols, colname, cnt_p, indices, priority, direction)
    ccall((:CPXordread, libcplex), Cint, (CPXCENVptr, Ptr{Cchar}, Cint, Ptr{Ptr{Cchar}}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}), env, filename_str, numcols, colname, cnt_p, indices, priority, direction)
end

function CPXordwrite(env, lp, filename_str)
    ccall((:CPXordwrite, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cchar}), env, lp, filename_str)
end

function CPXpopulate(env, lp)
    ccall((:CPXpopulate, libcplex), Cint, (CPXCENVptr, CPXLPptr), env, lp)
end

function CPXreadcopymipstarts(env, lp, filename_str)
    ccall((:CPXreadcopymipstarts, libcplex), Cint, (CPXCENVptr, CPXLPptr, Ptr{Cchar}), env, lp, filename_str)
end

function CPXreadcopyorder(env, lp, filename_str)
    ccall((:CPXreadcopyorder, libcplex), Cint, (CPXCENVptr, CPXLPptr, Ptr{Cchar}), env, lp, filename_str)
end

function CPXreadcopysolnpoolfilters(env, lp, filename_str)
    ccall((:CPXreadcopysolnpoolfilters, libcplex), Cint, (CPXCENVptr, CPXLPptr, Ptr{Cchar}), env, lp, filename_str)
end

function CPXrefinemipstartconflict(env, lp, mipstartindex, confnumrows_p, confnumcols_p)
    ccall((:CPXrefinemipstartconflict, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint, Ptr{Cint}, Ptr{Cint}), env, lp, mipstartindex, confnumrows_p, confnumcols_p)
end

function CPXrefinemipstartconflictext(env, lp, mipstartindex, grpcnt, concnt, grppref, grpbeg, grpind, grptype)
    ccall((:CPXrefinemipstartconflictext, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint, Cint, Cint, Ptr{Cdouble}, Ptr{Cint}, Ptr{Cint}, Ptr{Cchar}), env, lp, mipstartindex, grpcnt, concnt, grppref, grpbeg, grpind, grptype)
end

function CPXsetbranchcallbackfunc(env, branchcallback, cbhandle)
    ccall((:CPXsetbranchcallbackfunc, libcplex), Cint, (CPXENVptr, Ptr{Cvoid}, Ptr{Cvoid}), env, branchcallback, cbhandle)
end

function CPXsetbranchnosolncallbackfunc(env, branchnosolncallback, cbhandle)
    ccall((:CPXsetbranchnosolncallbackfunc, libcplex), Cint, (CPXENVptr, Ptr{Cvoid}, Ptr{Cvoid}), env, branchnosolncallback, cbhandle)
end

function CPXsetdeletenodecallbackfunc(env, deletecallback, cbhandle)
    ccall((:CPXsetdeletenodecallbackfunc, libcplex), Cint, (CPXENVptr, Ptr{Cvoid}, Ptr{Cvoid}), env, deletecallback, cbhandle)
end

function CPXsetheuristiccallbackfunc(env, heuristiccallback, cbhandle)
    ccall((:CPXsetheuristiccallbackfunc, libcplex), Cint, (CPXENVptr, Ptr{Cvoid}, Ptr{Cvoid}), env, heuristiccallback, cbhandle)
end

function CPXsetincumbentcallbackfunc(env, incumbentcallback, cbhandle)
    ccall((:CPXsetincumbentcallbackfunc, libcplex), Cint, (CPXENVptr, Ptr{Cvoid}, Ptr{Cvoid}), env, incumbentcallback, cbhandle)
end

function CPXsetinfocallbackfunc(env, callback, cbhandle)
    ccall((:CPXsetinfocallbackfunc, libcplex), Cint, (CPXENVptr, Ptr{Cvoid}, Ptr{Cvoid}), env, callback, cbhandle)
end

function CPXsetlazyconstraintcallbackfunc(env, lazyconcallback, cbhandle)
    ccall((:CPXsetlazyconstraintcallbackfunc, libcplex), Cint, (CPXENVptr, Ptr{Cvoid}, Ptr{Cvoid}), env, lazyconcallback, cbhandle)
end

function CPXsetmipcallbackfunc(env, callback, cbhandle)
    ccall((:CPXsetmipcallbackfunc, libcplex), Cint, (CPXENVptr, Ptr{Cvoid}, Ptr{Cvoid}), env, callback, cbhandle)
end

function CPXsetnodecallbackfunc(env, nodecallback, cbhandle)
    ccall((:CPXsetnodecallbackfunc, libcplex), Cint, (CPXENVptr, Ptr{Cvoid}, Ptr{Cvoid}), env, nodecallback, cbhandle)
end

function CPXsetsolvecallbackfunc(env, solvecallback, cbhandle)
    ccall((:CPXsetsolvecallbackfunc, libcplex), Cint, (CPXENVptr, Ptr{Cvoid}, Ptr{Cvoid}), env, solvecallback, cbhandle)
end

function CPXsetusercutcallbackfunc(env, cutcallback, cbhandle)
    ccall((:CPXsetusercutcallbackfunc, libcplex), Cint, (CPXENVptr, Ptr{Cvoid}, Ptr{Cvoid}), env, cutcallback, cbhandle)
end

function CPXwritemipstarts(env, lp, filename_str, _begin, _end)
    ccall((:CPXwritemipstarts, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cchar}, Cint, Cint), env, lp, filename_str, _begin, _end)
end

function CPXaddindconstr(env, lp, indvar, complemented, nzcnt, rhs, sense, linind, linval, indname_str)
    ccall((:CPXaddindconstr, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint, Cint, Cint, Cdouble, Cint, Ptr{Cint}, Ptr{Cdouble}, Ptr{Cchar}), env, lp, indvar, complemented, nzcnt, rhs, sense, linind, linval, indname_str)
end

function CPXNETaddarcs(env, net, narcs, fromnode, tonode, low, up, obj, anames)
    ccall((:CPXNETaddarcs, libcplex), Cint, (CPXCENVptr, CPXNETptr, Cint, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Ptr{Cchar}}), env, net, narcs, fromnode, tonode, low, up, obj, anames)
end

function CPXNETaddnodes(env, net, nnodes, supply, name)
    ccall((:CPXNETaddnodes, libcplex), Cint, (CPXCENVptr, CPXNETptr, Cint, Ptr{Cdouble}, Ptr{Ptr{Cchar}}), env, net, nnodes, supply, name)
end

function CPXNETbasewrite(env, net, filename_str)
    ccall((:CPXNETbasewrite, libcplex), Cint, (CPXCENVptr, CPXCNETptr, Ptr{Cchar}), env, net, filename_str)
end

function CPXNETchgarcname(env, net, cnt, indices, newname)
    ccall((:CPXNETchgarcname, libcplex), Cint, (CPXCENVptr, CPXNETptr, Cint, Ptr{Cint}, Ptr{Ptr{Cchar}}), env, net, cnt, indices, newname)
end

function CPXNETchgarcnodes(env, net, cnt, indices, fromnode, tonode)
    ccall((:CPXNETchgarcnodes, libcplex), Cint, (CPXCENVptr, CPXNETptr, Cint, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}), env, net, cnt, indices, fromnode, tonode)
end

function CPXNETchgbds(env, net, cnt, indices, lu, bd)
    ccall((:CPXNETchgbds, libcplex), Cint, (CPXCENVptr, CPXNETptr, Cint, Ptr{Cint}, Ptr{Cchar}, Ptr{Cdouble}), env, net, cnt, indices, lu, bd)
end

function CPXNETchgname(env, net, key, vindex, name_str)
    ccall((:CPXNETchgname, libcplex), Cint, (CPXCENVptr, CPXNETptr, Cint, Cint, Ptr{Cchar}), env, net, key, vindex, name_str)
end

function CPXNETchgnodename(env, net, cnt, indices, newname)
    ccall((:CPXNETchgnodename, libcplex), Cint, (CPXCENVptr, CPXNETptr, Cint, Ptr{Cint}, Ptr{Ptr{Cchar}}), env, net, cnt, indices, newname)
end

function CPXNETchgobj(env, net, cnt, indices, obj)
    ccall((:CPXNETchgobj, libcplex), Cint, (CPXCENVptr, CPXNETptr, Cint, Ptr{Cint}, Ptr{Cdouble}), env, net, cnt, indices, obj)
end

function CPXNETchgobjsen(env, net, maxormin)
    ccall((:CPXNETchgobjsen, libcplex), Cint, (CPXCENVptr, CPXNETptr, Cint), env, net, maxormin)
end

function CPXNETchgsupply(env, net, cnt, indices, supply)
    ccall((:CPXNETchgsupply, libcplex), Cint, (CPXCENVptr, CPXNETptr, Cint, Ptr{Cint}, Ptr{Cdouble}), env, net, cnt, indices, supply)
end

function CPXNETcopybase(env, net, astat, nstat)
    ccall((:CPXNETcopybase, libcplex), Cint, (CPXCENVptr, CPXNETptr, Ptr{Cint}, Ptr{Cint}), env, net, astat, nstat)
end

function CPXNETcopynet(env, net, objsen, nnodes, supply, nnames, narcs, fromnode, tonode, low, up, obj, anames)
    ccall((:CPXNETcopynet, libcplex), Cint, (CPXCENVptr, CPXNETptr, Cint, Cint, Ptr{Cdouble}, Ptr{Ptr{Cchar}}, Cint, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Ptr{Cchar}}), env, net, objsen, nnodes, supply, nnames, narcs, fromnode, tonode, low, up, obj, anames)
end

function CPXNETcreateprob(env, status_p, name_str)
    ccall((:CPXNETcreateprob, libcplex), CPXNETptr, (CPXENVptr, Ptr{Cint}, Ptr{Cchar}), env, status_p, name_str)
end

function CPXNETdelarcs(env, net, _begin, _end)
    ccall((:CPXNETdelarcs, libcplex), Cint, (CPXCENVptr, CPXNETptr, Cint, Cint), env, net, _begin, _end)
end

function CPXNETdelnodes(env, net, _begin, _end)
    ccall((:CPXNETdelnodes, libcplex), Cint, (CPXCENVptr, CPXNETptr, Cint, Cint), env, net, _begin, _end)
end

function CPXNETdelset(env, net, whichnodes, whicharcs)
    ccall((:CPXNETdelset, libcplex), Cint, (CPXCENVptr, CPXNETptr, Ptr{Cint}, Ptr{Cint}), env, net, whichnodes, whicharcs)
end

function CPXNETfreeprob(env, net_p)
    ccall((:CPXNETfreeprob, libcplex), Cint, (CPXENVptr, Ptr{CPXNETptr}), env, net_p)
end

function CPXNETgetarcindex(env, net, lname_str, index_p)
    ccall((:CPXNETgetarcindex, libcplex), Cint, (CPXCENVptr, CPXCNETptr, Ptr{Cchar}, Ptr{Cint}), env, net, lname_str, index_p)
end

function CPXNETgetarcname(env, net, nnames, namestore, namespc, surplus_p, _begin, _end)
    ccall((:CPXNETgetarcname, libcplex), Cint, (CPXCENVptr, CPXCNETptr, Ptr{Ptr{Cchar}}, Ptr{Cchar}, Cint, Ptr{Cint}, Cint, Cint), env, net, nnames, namestore, namespc, surplus_p, _begin, _end)
end

function CPXNETgetarcnodes(env, net, fromnode, tonode, _begin, _end)
    ccall((:CPXNETgetarcnodes, libcplex), Cint, (CPXCENVptr, CPXCNETptr, Ptr{Cint}, Ptr{Cint}, Cint, Cint), env, net, fromnode, tonode, _begin, _end)
end

function CPXNETgetbase(env, net, astat, nstat)
    ccall((:CPXNETgetbase, libcplex), Cint, (CPXCENVptr, CPXCNETptr, Ptr{Cint}, Ptr{Cint}), env, net, astat, nstat)
end

function CPXNETgetdj(env, net, dj, _begin, _end)
    ccall((:CPXNETgetdj, libcplex), Cint, (CPXCENVptr, CPXCNETptr, Ptr{Cdouble}, Cint, Cint), env, net, dj, _begin, _end)
end

function CPXNETgetitcnt(env, net)
    ccall((:CPXNETgetitcnt, libcplex), Cint, (CPXCENVptr, CPXCNETptr), env, net)
end

function CPXNETgetlb(env, net, low, _begin, _end)
    ccall((:CPXNETgetlb, libcplex), Cint, (CPXCENVptr, CPXCNETptr, Ptr{Cdouble}, Cint, Cint), env, net, low, _begin, _end)
end

function CPXNETgetnodearcs(env, net, arccnt_p, arcbeg, arc, arcspace, surplus_p, _begin, _end)
    ccall((:CPXNETgetnodearcs, libcplex), Cint, (CPXCENVptr, CPXCNETptr, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Cint, Ptr{Cint}, Cint, Cint), env, net, arccnt_p, arcbeg, arc, arcspace, surplus_p, _begin, _end)
end

function CPXNETgetnodeindex(env, net, lname_str, index_p)
    ccall((:CPXNETgetnodeindex, libcplex), Cint, (CPXCENVptr, CPXCNETptr, Ptr{Cchar}, Ptr{Cint}), env, net, lname_str, index_p)
end

function CPXNETgetnodename(env, net, nnames, namestore, namespc, surplus_p, _begin, _end)
    ccall((:CPXNETgetnodename, libcplex), Cint, (CPXCENVptr, CPXCNETptr, Ptr{Ptr{Cchar}}, Ptr{Cchar}, Cint, Ptr{Cint}, Cint, Cint), env, net, nnames, namestore, namespc, surplus_p, _begin, _end)
end

function CPXNETgetnumarcs(env, net)
    ccall((:CPXNETgetnumarcs, libcplex), Cint, (CPXCENVptr, CPXCNETptr), env, net)
end

function CPXNETgetnumnodes(env, net)
    ccall((:CPXNETgetnumnodes, libcplex), Cint, (CPXCENVptr, CPXCNETptr), env, net)
end

function CPXNETgetobj(env, net, obj, _begin, _end)
    ccall((:CPXNETgetobj, libcplex), Cint, (CPXCENVptr, CPXCNETptr, Ptr{Cdouble}, Cint, Cint), env, net, obj, _begin, _end)
end

function CPXNETgetobjsen(env, net)
    ccall((:CPXNETgetobjsen, libcplex), Cint, (CPXCENVptr, CPXCNETptr), env, net)
end

function CPXNETgetobjval(env, net, objval_p)
    ccall((:CPXNETgetobjval, libcplex), Cint, (CPXCENVptr, CPXCNETptr, Ptr{Cdouble}), env, net, objval_p)
end

function CPXNETgetphase1cnt(env, net)
    ccall((:CPXNETgetphase1cnt, libcplex), Cint, (CPXCENVptr, CPXCNETptr), env, net)
end

function CPXNETgetpi(env, net, pi, _begin, _end)
    ccall((:CPXNETgetpi, libcplex), Cint, (CPXCENVptr, CPXCNETptr, Ptr{Cdouble}, Cint, Cint), env, net, pi, _begin, _end)
end

function CPXNETgetprobname(env, net, buf_str, bufspace, surplus_p)
    ccall((:CPXNETgetprobname, libcplex), Cint, (CPXCENVptr, CPXCNETptr, Ptr{Cchar}, Cint, Ptr{Cint}), env, net, buf_str, bufspace, surplus_p)
end

function CPXNETgetslack(env, net, slack, _begin, _end)
    ccall((:CPXNETgetslack, libcplex), Cint, (CPXCENVptr, CPXCNETptr, Ptr{Cdouble}, Cint, Cint), env, net, slack, _begin, _end)
end

function CPXNETgetstat(env, net)
    ccall((:CPXNETgetstat, libcplex), Cint, (CPXCENVptr, CPXCNETptr), env, net)
end

function CPXNETgetsupply(env, net, supply, _begin, _end)
    ccall((:CPXNETgetsupply, libcplex), Cint, (CPXCENVptr, CPXCNETptr, Ptr{Cdouble}, Cint, Cint), env, net, supply, _begin, _end)
end

function CPXNETgetub(env, net, up, _begin, _end)
    ccall((:CPXNETgetub, libcplex), Cint, (CPXCENVptr, CPXCNETptr, Ptr{Cdouble}, Cint, Cint), env, net, up, _begin, _end)
end

function CPXNETgetx(env, net, x, _begin, _end)
    ccall((:CPXNETgetx, libcplex), Cint, (CPXCENVptr, CPXCNETptr, Ptr{Cdouble}, Cint, Cint), env, net, x, _begin, _end)
end

function CPXNETprimopt(env, net)
    ccall((:CPXNETprimopt, libcplex), Cint, (CPXCENVptr, CPXNETptr), env, net)
end

function CPXNETreadcopybase(env, net, filename_str)
    ccall((:CPXNETreadcopybase, libcplex), Cint, (CPXCENVptr, CPXNETptr, Ptr{Cchar}), env, net, filename_str)
end

function CPXNETreadcopyprob(env, net, filename_str)
    ccall((:CPXNETreadcopyprob, libcplex), Cint, (CPXCENVptr, CPXNETptr, Ptr{Cchar}), env, net, filename_str)
end

function CPXNETsolninfo(env, net, pfeasind_p, dfeasind_p)
    ccall((:CPXNETsolninfo, libcplex), Cint, (CPXCENVptr, CPXCNETptr, Ptr{Cint}, Ptr{Cint}), env, net, pfeasind_p, dfeasind_p)
end

function CPXNETsolution(env, net, netstat_p, objval_p, x, pi, slack, dj)
    ccall((:CPXNETsolution, libcplex), Cint, (CPXCENVptr, CPXCNETptr, Ptr{Cint}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}), env, net, netstat_p, objval_p, x, pi, slack, dj)
end

function CPXNETwriteprob(env, net, filename_str, format_str)
    ccall((:CPXNETwriteprob, libcplex), Cint, (CPXCENVptr, CPXCNETptr, Ptr{Cchar}, Ptr{Cchar}), env, net, filename_str, format_str)
end

function CPXchgqpcoef(env, lp, i, j, newvalue)
    ccall((:CPXchgqpcoef, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint, Cint, Cdouble), env, lp, i, j, newvalue)
end

function CPXcopyqpsep(env, lp, qsepvec)
    ccall((:CPXcopyqpsep, libcplex), Cint, (CPXCENVptr, CPXLPptr, Ptr{Cdouble}), env, lp, qsepvec)
end

function CPXcopyquad(env, lp, qmatbeg, qmatcnt, qmatind, qmatval)
    ccall((:CPXcopyquad, libcplex), Cint, (CPXCENVptr, CPXLPptr, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}), env, lp, qmatbeg, qmatcnt, qmatind, qmatval)
end

function CPXgetnumqpnz(env, lp)
    ccall((:CPXgetnumqpnz, libcplex), Cint, (CPXCENVptr, CPXCLPptr), env, lp)
end

function CPXgetnumquad(env, lp)
    ccall((:CPXgetnumquad, libcplex), Cint, (CPXCENVptr, CPXCLPptr), env, lp)
end

function CPXgetqpcoef(env, lp, rownum, colnum, coef_p)
    ccall((:CPXgetqpcoef, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Cint, Cint, Ptr{Cdouble}), env, lp, rownum, colnum, coef_p)
end

function CPXgetquad(env, lp, nzcnt_p, qmatbeg, qmatind, qmatval, qmatspace, surplus_p, _begin, _end)
    ccall((:CPXgetquad, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}, Cint, Ptr{Cint}, Cint, Cint), env, lp, nzcnt_p, qmatbeg, qmatind, qmatval, qmatspace, surplus_p, _begin, _end)
end

function CPXqpindefcertificate(env, lp, x)
    ccall((:CPXqpindefcertificate, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cdouble}), env, lp, x)
end

function CPXqpopt(env, lp)
    ccall((:CPXqpopt, libcplex), Cint, (CPXCENVptr, CPXLPptr), env, lp)
end

function CPXaddqconstr(env, lp, linnzcnt, quadnzcnt, rhs, sense, linind, linval, quadrow, quadcol, quadval, lname_str)
    ccall((:CPXaddqconstr, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint, Cint, Cdouble, Cint, Ptr{Cint}, Ptr{Cdouble}, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}, Ptr{Cchar}), env, lp, linnzcnt, quadnzcnt, rhs, sense, linind, linval, quadrow, quadcol, quadval, lname_str)
end

function CPXdelqconstrs(env, lp, _begin, _end)
    ccall((:CPXdelqconstrs, libcplex), Cint, (CPXCENVptr, CPXLPptr, Cint, Cint), env, lp, _begin, _end)
end

function CPXgetnumqconstrs(env, lp)
    ccall((:CPXgetnumqconstrs, libcplex), Cint, (CPXCENVptr, CPXCLPptr), env, lp)
end

function CPXgetqconstr(env, lp, linnzcnt_p, quadnzcnt_p, rhs_p, sense_p, linind, linval, linspace, linsurplus_p, quadrow, quadcol, quadval, quadspace, quadsurplus_p, which)
    ccall((:CPXgetqconstr, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}, Ptr{Cchar}, Ptr{Cint}, Ptr{Cdouble}, Cint, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}, Cint, Ptr{Cint}, Cint), env, lp, linnzcnt_p, quadnzcnt_p, rhs_p, sense_p, linind, linval, linspace, linsurplus_p, quadrow, quadcol, quadval, quadspace, quadsurplus_p, which)
end

function CPXgetqconstrdslack(env, lp, qind, nz_p, ind, val, space, surplus_p)
    ccall((:CPXgetqconstrdslack, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Cint, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}, Cint, Ptr{Cint}), env, lp, qind, nz_p, ind, val, space, surplus_p)
end

function CPXgetqconstrindex(env, lp, lname_str, index_p)
    ccall((:CPXgetqconstrindex, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cchar}, Ptr{Cint}), env, lp, lname_str, index_p)
end

function CPXgetqconstrinfeas(env, lp, x, infeasout, _begin, _end)
    ccall((:CPXgetqconstrinfeas, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cdouble}, Ptr{Cdouble}, Cint, Cint), env, lp, x, infeasout, _begin, _end)
end

function CPXgetqconstrname(env, lp, buf_str, bufspace, surplus_p, which)
    ccall((:CPXgetqconstrname, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cchar}, Cint, Ptr{Cint}, Cint), env, lp, buf_str, bufspace, surplus_p, which)
end

function CPXgetqconstrslack(env, lp, qcslack, _begin, _end)
    ccall((:CPXgetqconstrslack, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cdouble}, Cint, Cint), env, lp, qcslack, _begin, _end)
end

function CPXgetxqxax(env, lp, xqxax, _begin, _end)
    ccall((:CPXgetxqxax, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cdouble}, Cint, Cint), env, lp, xqxax, _begin, _end)
end

function CPXqconstrslackfromx(env, lp, x, qcslack)
    ccall((:CPXqconstrslackfromx, libcplex), Cint, (CPXCENVptr, CPXCLPptr, Ptr{Cdouble}, Ptr{Cdouble}), env, lp, x, qcslack)
end
# Julia wrapper for header: cpxconst.h
# Automatically generated using Clang.jl

