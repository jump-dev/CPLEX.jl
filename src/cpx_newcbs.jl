@enum CbSolStrat CPXCALLBACKSOLUTION_CHECKFEAS CPXCALLBACKSOLUTION_PROPAGATE
#this function calls a callback function with its own parameters.
#Need to figure out how to pass the function callback as a parameter, then pass cplex context pointer to callback()
type GenCallbackData
    cbdata::Ptr{Void}
    ncol::Cint
    obj::Any
end

function cplex_callback_wrapper(context_::Ptr{Void},where::Clong,userdata_::Ptr{void})
    if (where==CPX_CALLBACKCONTEXT_RELAXATION)
        status=rounddownheur(context,userdata)
    else
        println("ERROR: Callback called in an unexpected context.")
        return convert(Cint,1)
    end
    return convert(Cint,0)
end

function setcallbackfunc(model::Model,where::Clong,callback::Cint,userdata_::Ptr{Void})
    cplex_callback_c=cfunction(cplex_callback_function, Cint,(Ptr{Void},Clong,Ptr{Void}))
    stat=@cpx_ccall(callbacksetfunc, Cint,(
    Ptr{Void},
    Ptr{Void},
    Clong,
    Cint,
    Ptr{Void}
    ),
    model.env.ptr,model.lp,where,cplex_callback_c,userdata_)
    if stat != 0
        throw(CplexError(model.env.ptr, stat))
    end
end

function cbgetrelaxedpoint(context_::Ptr{Void},x::Vector{Cdouble},start::Cint,final::Cint,obj_::Ptr{Void})
    stat=@cpx_ccall(callbackgetrelaxationpoint,Cint,(
    Ptr{Void},
    Ptr{Cdouble},
    Ptr{Cint},
    Ptr{Cint},
    Ptr{Void}
    ),
    context,x,start,final,obj_)
    if stat!=0
        throw(CplexError(model.env.ptr,stat))
    end
    return stat
end

function cbpostheursoln(context_::Ptr{Void},cnt::Cint,ind_::Ptr{Cint},val_::Ptr{Cdouble},obj_::Ptr{Cdouble},strat::CbSolStrat)
    stat=@cpx_ccall(callbackpostheursoln,Cint,(
    Ptr{Void},
    Cint,
    Ptr{Cint},
    Ptr{Cdouble},
    Ptr{Cdouble},
    Cint,
    ),
    context_,cnt,ind_,val_,obj_,strat)
    if stat!=0
        throw(CplexError(model.env.ptr,stat))
    end
    return stat
end

function rounddownheur(context_::Ptr{Void},userdata_::Ptr{Void})
    userdata=unsafe_pointer_to_objref(userdata_)
    cols=userdata.ncols
    obj=userdata.obj

    x=Vector(cols)
    ind=Vector(cols)
    objrel=Cdouble

    status=cbgetrelaxedpoint(context_,x,0,cols-1,objrel)
    println(objrel)#@
    if status
        error("Could not get solution $status")
    end

    for j in 1:cols
        ind[j]=j

        if x[j]
            frac=x[j]-floor(x[j])
            frac=min(1-frac,frac)
            if frac>1.0e-6
                objrel-=x[j]*obj[j]
                x[j]=0
            end
        end
    end

    status=cbpostheursoln(context_,cols,ind,x,objrel,CPXCALLBACKSOLUTION_CHECKFEAS)
    if status
        error("Could not post solution $status")
    end

    return status
end
