@enum CbSolStrat CPXCALLBACKSOLUTION_CHECKFEAS CPXCALLBACKSOLUTION_PROPAGATE

type GenCallbackData
    # cbdata::Ptr{Void}
    ncol::Cint
    obj::Any
end

function cbgetrelaxedpoint(env::Env,context_::Ptr{Void},x::Vector{Cdouble},start::Cint,final::Cint,obj_::Ptr{Void})
    stat=@cpx_ccall(callbackgetrelaxationpoint,Cint,(
    Ptr{Void},
    Ptr{Cdouble},
    Cint,
    Cint,
    Ptr{Cdouble}
    ),
    context_,x,start,final,obj_)
    # if stat!=0
    #     throw(CplexError(env,stat))
    # end
    return stat
end

function cbpostheursoln(env::Env,context_::Ptr{Void},cnt::Cint,ind::Vector{Cint},val::Vector{Cdouble},obj::Cdouble,strat::CbSolStrat)
    stat=@cpx_ccall(callbackpostheursoln,Cint,(
    Ptr{Void},
    Cint,
    Ptr{Cint},
    Ptr{Cdouble},
    Cdouble,
    Cint,
    ),
    context_,cnt,ind,val,obj,strat)
    # if stat!=0
    #     throw(CplexError(model.env,stat))
    # end
    return stat
end

function rounddownheur(env::Env,context_::Ptr{Void},userdata_::Ptr{Void})
    userdata=unsafe_pointer_to_objref(userdata_)
    cols=userdata.ncol
    obj=userdata.obj

    x=Vector{Float64}(cols)
    ind=Vector{Cint}(cols)
    objrel=0.0

    status=cbgetrelaxedpoint(env,context_,x,Cint(0),Cint(cols-1),pointer_from_objref(objrel))
    # println(objrel)#@
    if status!=0
        error("Could not get solution $status")
    end

    for j in 1:cols
        ind[j]=j

        if x[j]>0.5
            frac=x[j]-floor(x[j])
            frac=min(1-frac,frac)
            if frac>1.0e-6
                objrel-=x[j]*obj[j]
                x[j]=0
            end
        end
    end

    status=cbpostheursoln(env,context_,cols,ind,x,objrel,CPXCALLBACKSOLUTION_CHECKFEAS)
    if status!=0
        error("Could not post solution $status")
    end

    return status
end

function cplex_callback_wrapper(env::Env,context_::Ptr{Void},where::Clong,userdata_::Ptr{Void})
    status=0

    if (where==CPX_CALLBACKCONTEXT_RELAXATION)
        status=rounddownheur(env,context_,userdata_)
    else
        println("ERROR: Callback called in an unexpected context.")
        return convert(Cint,1)
    end
    return status
end

type Cplex_Callback
    
end

function setcallbackfunc(env::Env,model::Model,where::Clong,userdata_::Ptr{Void})
    cplex_callback_c=cfunction(cplex_callback_wrapper, Cint,(Env,Ptr{Void},Clong,Ptr{Void}))

    # println(cplex_callback_c)#@

    stat=@cpx_ccall(callbacksetfunc, Cint,(
    Ptr{Void},
    Ptr{Void},
    Clong,
    Ptr{Void},
    Ptr{Void}
    ),
    env.ptr,model.lp,where,cplex_callback_c,userdata_)
    if stat != 0
        throw(CplexError(env, stat))
    end
    return stat
end
