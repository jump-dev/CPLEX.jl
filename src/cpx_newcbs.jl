@enum CbSolStrat CPXCALLBACKSOLUTION_CHECKFEAS CPXCALLBACKSOLUTION_PROPAGATE
#this function calls a callback function with its own parameters.
#Need to figure out how to pass the function callback as a parameter, then pass cplex context pointer to callback()
function setcallbackfunc(model::Model,where::Clong,callback::Cint,userhandle::Ptr{Void})
    cb_stat=callback(model,where,)
    stat=@cpx_ccall(callbacksetfunc, Cint,(
    Ptr{Void},
    Ptr{Void},
    Clong,
    Cint,
    Ptr{Void}
    ),
    model.env.ptr,model.lp,where,cb_stat,userhandle)
    if stat != 0
        throw(CplexError(model.env.ptr, stat))
    end
end

function cbgetrelaxedpoint(model::Model,context::Ptr{Void},x::Vector{Cdouble},start::Cint,final::Cint,obj_p::Cdouble)
    stat=@cpx_ccall(callbackgetrelaxationpoint,Cint,(
    Ptr{Void},
    Ptr{Cdouble},
    Ptr{Cint},
    Ptr{Cint},
    Ptr{Cdouble}
    ),
    context,x,start,final,obj_p)
    if stat!=0
        throw(CplexError(model.env.ptr,stat))
    end
end

function cbpostheursoln(model::Model,context::Ptr{Void},cnt::Cint,ind::Cint,val::Cdouble,obj::Cdouble,strat::CbSolStrat)
    stat=@cpx_ccall(callbackpostheursoln,Cint,(
    Ptr{Void},
    Cint,
    Ptr{Cint},
    Ptr{Cdouble},
    Ptr{Cdouble},
    Cint,
    ),
    context,cnt,ind,val,obj,strat)
    if stat!=0
        throw(CplexError(model.env.ptr,stat))
    end
end
