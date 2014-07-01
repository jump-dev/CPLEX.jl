type Model
    env::Env # Cplex environment
    lp::Ptr{Void} # Cplex problem (lp)
    has_int::Bool # problem has integer variables?
    has_qc::Bool # problem has quadratic constraints?
    callback::Any

    function Model(env::Env, lp::Ptr{Void})
        model = new(env, lp, false, false, nothing)
        finalizer(model, free_problem)
        model
    end
end

function Model(env::Env, name::ASCIIString)
    @assert is_valid(env) 
    stat = Array(Cint, 1)
    tmp = @cpx_ccall(createprob, Ptr{Void}, (Ptr{Void}, Ptr{Cint}, Ptr{Cchar}), env.ptr, stat, name)
    if tmp == C_NULL
        throw(CplexError(model.env, stat))
    end
    return Model(env, tmp)
end

function read_model(model::Model, filename::ASCIIString)
    stat = @cpx_ccall(readcopyprob, Cint, (Ptr{Void}, Ptr{Void}, Ptr{Cchar}, Ptr{Cchar}), model.env.ptr, model.lp, filename, C_NULL)
    if stat != 0
        throw(CplexError(model.env, stat))
    end
end

function write_model(model::Model, filename::ASCIIString)
    if endswith(filename,".mps")
        filetype = "MPS"
    elseif endswith(filename,".lp")
        filetype = "LP"
    else
        error("Unrecognized file extension: $filename (Only .mps and .lp are supported)")
    end
    stat = @cpx_ccall(writeprob, Cint, (Ptr{Void}, Ptr{Void}, Ptr{Cchar}, Ptr{Cchar}), model.env.ptr, model.lp, filename, filetype)
    if stat != 0
        throw(CplexError(model.env, stat))
    end
end

## TODO: deep copy model, reset model

function get_sense(model::Model)
    sense_int = @cpx_ccall(getobjsen, Cint, (
                           Ptr{Void},
                           Ptr{Void},
                           ),
                           model.env.ptr, model.lp)
    if sense_int == 1
        sense = :Min
    elseif sense_int == -1
        sense = :Max
    else
        error("CPLEX: problem object or environment does not exist")
    end
    return sense
end      

function set_sense!(model::Model, sense)
    if sense == :Min
        @cpx_ccall(chgobjsen, Void, (Ptr{Void}, Ptr{Void}, Cint), model.env.ptr, model.lp, 1)
    elseif sense == :Max
        @cpx_ccall(chgobjsen, Void, (Ptr{Void}, Ptr{Void}, Cint), model.env.ptr, model.lp, -1)
    else
        error("Unrecognized objective sense $sense")
    end
end

function get_obj(model::Model)
    nvars = num_var(model)
    obj = Array(Cdouble, nvars)
    stat = @cpx_ccall(getobj, Cint, (
                      Ptr{Void},
                      Ptr{Void},
                      Ptr{Cdouble},
                      Cint,
                      Cint
                      ),
                      model.env.ptr, model.lp, obj, 0, nvars-1)
    if stat != 0
        throw(CplexError(model.env, stat))
    end
    return obj
end

const type_map = Dict{Cint,Symbol}([  0,    1,    3,  5,    7,    8,  10,    11],
                                   [:LP,:MILP,:MILP,:QP,:MIQP,:MIQP,:QCP,:MIQCP])

function get_prob_type(model::Model)
  ret = @cpx_ccall(getprobtype, Cint, (
                   Ptr{Void},
                   Ptr{Void}),
                   model.env.ptr, model.lp)
  ret == -1 && error("No problem of environment")
  return type_map[ret]
end

function set_obj!(model::Model, c::Vector)
    nvars = num_var(model)
    stat = @cpx_ccall(chgobj, Cint, (
                        Ptr{Void},
                        Ptr{Void},
                        Cint,
                        Ptr{Cint},
                        Ptr{Cdouble}
                        ),
                        model.env.ptr, model.lp, nvars, Cint[0:nvars-1], float(c))                    
    if stat != 0
        throw(CplexError(model.env, stat))
    end
end

set_warm_start!(model::Model, x::Vector{Float64}) = set_warm_start!(model, Cint[1:length(x)], x)

function set_warm_start!(model::Model, indx::IVec, val::FVec)
    stat = @cpx_ccall(addmipstarts, Cint, (
                      Ptr{Void},
                      Ptr{Void},
                      Cint,
                      Cint,
                      Ptr{Cint},
                      Ptr{Cint},
                      Ptr{Cdouble},
                      Ptr{Cint},
                      Ptr{Ptr{Cchar}}
                      ),
                      model.env.ptr, model.lp, 1, length(indx), Cint[0], indx.-1, val, Cint[0], C_NULL)
    if stat != 0
        throw(CplexError(model.env, stat))
    end
end

function free_problem(model::Model)
    stat = @cpx_ccall(freeprob, Cint, (Ptr{Void}, Ptr{Void}), model.env.ptr, model.lp)
    if stat != 0
        throw(CplexError(model.env, stat))
    end
end

function close_CPLEX(env::Env)
    stat = @cpx_ccall(closeCPLEX, Cint, (Ptr{Void},), env.ptr)
    if stat != 0
        throw(CplexError(model.env, stat))
    end
end
