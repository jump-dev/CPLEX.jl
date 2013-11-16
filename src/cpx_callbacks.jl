type CallbackData
    cbdata::Ptr{Void}
    model::Model
end

function cplex_callback_wrapper(ptr_model::Ptr{Void}, cbdata::Ptr{Void}, where::Cint, userdata::Ptr{Void})

    callback,model = unsafe_pointer_to_objref(userdata)::(Function,Model)
    callback(CallbackData(cbdata,model), where)
    return convert(Cint,0)
end

# User callback function should be of the form:
# callback(cbdata::CallbackData, where::Cint)

function set_callback_func!(model::Model, callback::Function)
    
    cpxcallback = cfunction(cplex_callback_wrapper, Cint, (Ptr{Void}, Ptr{Void}, Cint, Ptr{Void}))
    stat = @cpx_ccall(setcallbackfunc, Cint, (Ptr{Void}, Ptr{Void}, Any), model.ptr_model, cpxcallback, (callback,model))
    if stat != 0
        throw(CplexError(model.env, stat))
    end
    # we need to keep a reference to the callback function
    # so that it isn't garbage collected
    model.callback = callback
    nothing
end

export CallbackData, set_callback_func!

function setcallbackcut(cbdata::CallbackData, ind::Vector{Cint}, val::Vector{Cdouble}, sense::Char, rhs::Cdouble)
    len = length(ind)
    @assert length(val) == len
    if sense == '<'
        sns = Cint['L']
    elseif sense == '>'
        sns = Cint['G']
    elseif sense == '='
        sns = Cint['E']
    else
        error("Invalid cut sense")
    end
    ## the last argument, purgeable, describes Cplex's treatment of the cut, i.e. whether it has liberty to drop it later in the tree.
    ## should really have default and then allow user override
    stat = @cpx_ccall(cutcallbackadd, Cint, (
                      Ptr{Void},
                      Ptr{Void},
                      Cint,
                      Cint,
                      Cdouble,
                      Cint,
                      Cint,
                      Ptr{Cdouble},
                      Cint
                      ),
                      cbdata.model.env, cbdata.cbdata, wherefrom, len, rhs, sns, ind, val, CPX_USECUT_PURGE)
    if stat != 0
        throw(CplexError(cbdata.model.env.ptr, stat))
    end
end

cbcut(cbdata::CallbackData, ind::Vector{Cint}, val::Vector{Float64}, sense::Char, rhs::Float64) = setcallbackcut(cbdata, ind, convert(Vector{Cdouble}, val), sense, convert(Vector{Cdouble}, rhs))

cblazy(cbdata::CallbackData, ind::Vector{Cint}, val::Vector{Float64}, sense::Char, rhs::Float64) = setcallbackcut(cbdata, ind, convert(Vector{Cdouble}, val), sense, convert(Vector{Cdouble}, rhs))

export cbcut, cblazy

function cbsolution(cbdata::CallbackData, sol::Vector{Cdouble})
    nvar = num_vars(cbdata.model)
    @assert length(sol) >= nvar
## note: this is not right. getcallbacknodex returns the subproblem LP soln
    stat = @cpx_ccall(getcallbacknodex, Cint, (
                      Ptr{Void},
                      Ptr{Void},
                      Cint,
                      Ptr{Cdouble},
                      Cint,
                      Cint
                      ),
                      cdbdata.model.env, cbdata.cbdata, wherefrom, sol, 0, nvar)
    if stat != 0
        throw(CplexError(cbdata.model.env, ret))
    end
end

cbsolution(cbdata::CallbackData) = cbsolution(cbdata, Array(Cdouble, num_vars(cbdata.model)))

function cbget{T}(::Type{T},cbdata::CallbackData, where::Cint, what::Integer)
    
    out = Array(T,1)
    stat = @cpx_ccall(getcallbackinfo, Cint, (
                      Ptr{Void}, 
                      Ptr{Void},
                      Cint, 
                      Cint, 
                      Ptr{T}
                      ),
                      cbdata.model.env.ptr, cbdata.cbdata, where, what, out)
    if stat != 0
        throw(CplexError(cbdata.model.env, stat))
    end
    return out[1]
end


# Callback constants
# grep GRB_CB gurobi_c.h | awk '{ print "const " substr($2,5) " = " $3; }'
const CB_POLLING = 0
const CB_PRESOLVE = 1
const CB_SIMPLEX = 2
const CB_MIP = 3
const CB_MIPSOL = 4
const CB_MIPNODE = 5
const CB_MESSAGE = 6
const CB_BARRIER = 7

export CB_POLLING, CB_PRESOLVE, CB_SIMPLEX, CB_MIP,
       CB_MIPSOL, CB_MIPNODE, CB_MESSAGE, CB_BARRIER

# grep GRB_CB gurobi_c.h | awk '{ print "(\"" tolower(substr($2,8)) "\"," $3 ")"; }'
const cbconstants = [
("pre_coldel",1000,Cint),
("pre_rowdel",1001,Cint),
("pre_senchg",1002,Cint),
("pre_bndchg",1003,Cint),
("pre_coechg",1004,Cint),
("spx_itrcnt",2000,Float64),
("spx_objval",2001,Float64),
("spx_priminf",2002,Float64),
("spx_dualinf",2003,Float64),
("spx_ispert",2004,Float64),
("mip_objbst",3000,Float64),
("mip_objbnd",3001,Float64),
("mip_nodcnt",3002,Float64),
("mip_solcnt",3003,Cint),
("mip_cutcnt",3004,Cint),
("mip_nodlft",3005,Float64),
("mip_itrcnt",3006,Float64),
###("mipsol_sol",4001),
("mipsol_obj",4002,Float64),
("mipsol_objbst",4003,Float64),
("mipsol_objbnd",4004,Float64),
("mipsol_nodcnt",4005,Float64),
("mipsol_solcnt",4006,Cint),
("mipnode_status",5001,Cint),
###("mipnode_rel",5002),
("mipnode_objbst",5003,Float64),
("mipnode_objbnd",5004,Float64),
("mipnode_nodcnt",5005,Float64),
("mipnode_solcnt",5006,Cint),
##("mipnode_brvar",5007), -- undocumented
##("msg_string",6001), -- not yet implemented: 
### documentation is unclear on output type
("runtime",6002, Float64),
("barrier_itrcnt",7001,Cint),
("barrier_primobj",7002,Float64),
("barrier_dualobj",7003,Float64),
("barrier_priminf",7004,Float64),
("barrier_dualinf",7005,Float64),
("barrier_compl",7006,Float64)]

for (cname,what,T) in cbconstants
    fname = symbol("cbget_$cname")
    @eval ($fname)(cbdata::CallbackData, where::Cint) = cbget($T, cbdata, where, $what)
    eval(Expr(:export,fname))
end

for (fname, what) in ((:cbget_mipsol_sol, 4001), (:cbget_mipnode_rel, 5002))
    @eval function ($fname)(cbdata::CallbackData, where::Cint, out::Vector{Float64})
        nvar = num_vars(cbdata.model)
        @assert length(out) >= nvar
        ret = @cpx_ccall(cbget, Cint, (Ptr{Void}, Cint, Cint, Ptr{Float64}),
                         cbdata.cbdata, where, $what, out)
        if ret != 0
            throw(CplexError(cbdata.model.env, ret))
        end
    end
    @eval function ($fname)(cbdata::CallbackData, where::Cint)
        nvar = num_vars(cbdata.model)
        out = Array(Float64,nvar)
        ($fname)(cbdata, where, out)
        return out
    end
    eval(Expr(:export,fname))
end


