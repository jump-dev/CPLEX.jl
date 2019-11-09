mutable struct Model
    env::Env # Cplex environment
    lp::Ptr{Cvoid} # Cplex problem (lp)
    has_int::Bool # problem has integer variables?
    has_qc::Bool # problem has quadratic constraints?
    has_sos::Bool # problem has Special Ordered Sets?
    callback::Any
    terminator::Vector{Cint}
end
function Model(env::Env, lp::Ptr{Cvoid})
    notify_new_model(env)
    model = Model(env, lp, false, false, false, nothing, Cint[0])
    function model_finalizer(model)
        if model.lp != C_NULL
            free_problem(model)
        else
            # User must have called `free_problem` directly.
        end
        notify_freed_model(env)
    end
    finalizer(model_finalizer, model)
    set_terminate(model)
    return model
end

function Model(env::Env, name::String="CPLEX.jl")
    @assert is_valid(env)
    stat = Vector{Cint}(undef, 1)
    tmp = @cpx_ccall(createprob, Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cint}, Ptr{Cchar}), env.ptr, stat, name)
    if tmp == C_NULL
        throw(CplexError(env, stat))
    end
    return Model(env, tmp)
end

function read_model(model::Model, filename::String)
    stat = @cpx_ccall(readcopyprob, Cint, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cchar}, Ptr{Cchar}), model.env.ptr, model.lp, filename, C_NULL)
    if stat != 0
        throw(CplexError(model.env, stat))
    end
    prob_type = get_prob_type(model)
    if prob_type in [:MILP,:MIQP, :MIQCP]
        model.has_int = true
    end
    if prob_type in [:QP, :MIQP, :QCP, :MIQCP]
        model.has_qc = true
    end
end

function write_model(model::Model, filename::String)
    if endswith(filename,".mps")
        filetype = "MPS"
    elseif endswith(filename,".lp")
        filetype = "LP"
    else
        error("Unrecognized file extension: $filename (Only .mps and .lp are supported)")
    end
    stat = @cpx_ccall(writeprob, Cint, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cchar}, Ptr{Cchar}), model.env.ptr, model.lp, filename, filetype)
    if stat != 0
        throw(CplexError(model.env, stat))
    end
end

## TODO: deep copy model, reset model

function c_api_getobjsen(model::Model)
    sense_int = @cpx_ccall(getobjsen, Cint, (
                           Ptr{Cvoid},
                           Ptr{Cvoid},
                           ),
                           model.env.ptr, model.lp)

    return sense_int
end
function get_sense(model::Model)
    sense_int = c_api_getobjsen(model)
    if sense_int == 1
        return :Min
    elseif sense_int == -1
        return :Max
    else
        error("CPLEX: problem object or environment does not exist")
    end
end

function set_sense!(model::Model, sense)
    if sense == :Min
        @cpx_ccall(chgobjsen, Nothing, (Ptr{Cvoid}, Ptr{Cvoid}, Cint), model.env.ptr, model.lp, 1)
    elseif sense == :Max
        @cpx_ccall(chgobjsen, Nothing, (Ptr{Cvoid}, Ptr{Cvoid}, Cint), model.env.ptr, model.lp, -1)
    else
        error("Unrecognized objective sense $sense")
    end
end

function c_api_chgobjsen(model::Model, sense_int::Cint)
    @cpx_ccall(chgobjsen, Nothing, (Ptr{Cvoid}, Ptr{Cvoid}, Cint),
               model.env.ptr, model.lp, sense_int)
end

function c_api_getobj(model::Model, sized_obj::FVec,
                      col_start::Cint, col_end::Cint)

    nvars = num_var(model)
    stat = @cpx_ccall(getobj, Cint, (
                      Ptr{Cvoid},
                      Ptr{Cvoid},
                      Ptr{Cdouble},
                      Cint,
                      Cint
                      ),
                      model.env.ptr, model.lp, sized_obj,
                      col_start - Cint(1), col_end - Cint(1))
    if stat != 0
        throw(CplexError(model.env, stat))
    end
end

function get_obj(model::Model)
    nvars = num_var(model)
    obj = Vector{Cdouble}(undef, nvars)
    stat = @cpx_ccall(getobj, Cint, (
                      Ptr{Cvoid},
                      Ptr{Cvoid},
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

const type_map = Dict(
     0 => :LP,
     1 => :MILP,
     3 => :FIXEDMILP, # actually fixed milp
     5 => :QP,
     7 => :MIQP,
     8 => :FIXEDMIQP,
    10 => :QCP,
    11 => :MIQCP
)

const rev_prob_type_map = Dict(
    :LP    => 0,
    :MILP  => 1,
    :FIXEDMILP  => 3,
    :QP    => 5,
    :MIQP  => 7,
    :FIXEDMIQP  => 8,
    :QCP   => 10,
    :MIQCP => 11
)

function get_prob_type(model::Model)
  ret = @cpx_ccall(getprobtype, Cint, (
                   Ptr{Cvoid},
                   Ptr{Cvoid}),
                   model.env.ptr, model.lp)
  ret == -1 && error("No problem of environment")
  return type_map[Int(ret)]
end

function set_prob_type!(model::Model, tyint::Int)
    stat = @cpx_ccall(chgprobtype, Cint, (
                     Ptr{Cvoid},
                     Ptr{Cvoid},
                     Cint),
                     model.env.ptr, model.lp, tyint)
     if stat != 0
         throw(CplexError(model.env, stat))
     end
end
set_prob_type!(model::Model, ty::Symbol) = set_prob_type!(model, rev_prob_type_map[ty])


function set_obj!(model::Model, c::Vector)
    nvars = num_var(model)
    stat = @cpx_ccall(chgobj, Cint, (
                        Ptr{Cvoid},
                        Ptr{Cvoid},
                        Cint,
                        Ptr{Cint},
                        Ptr{Cdouble}
                        ),
                        model.env.ptr, model.lp, nvars, Cint[0:nvars-1;], float(c))
    if stat != 0
        throw(CplexError(model.env, stat))
    end
end

function c_api_chgobj(model::Model, indices::IVec, values::FVec)
    nvars = length(indices)
    stat = @cpx_ccall(chgobj, Cint, (
                        Ptr{Cvoid},
                        Ptr{Cvoid},
                        Cint,
                        Ptr{Cint},
                        Ptr{Cdouble}
                        ),
                        model.env.ptr, model.lp, nvars,
                        indices .- Cint(1), values)
    if stat != 0
        throw(CplexError(model.env, stat))
    end
end

function c_api_chgobjoffset(model::Model, offset::Float64)
    stat = @cpx_ccall(
        chgobjoffset,
        Cint,
        (Ptr{Cvoid}, Ptr{Cvoid}, Cdouble),
        model.env.ptr, model.lp, offset
    )
    if stat != 0
        throw(CplexError(model.env, stat))
    end
    return
end

function c_api_getobjoffset(model::Model)
    objoffset_p = Ref{Float64}()
    stat = @cpx_ccall(
        getobjoffset,
        Cint,
        (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cdouble}),
        model.env.ptr, model.lp, objoffset_p
    )
    if stat != 0
        throw(CplexError(model.env, stat))
    end
    return objoffset_p[]
end

set_warm_start!(model::Model, x::Vector{Float64}, effortlevel::Integer = CPX_MIPSTART_AUTO) = set_warm_start!(model, Cint[1:length(x);], x, effortlevel)

function set_warm_start!(model::Model, indx::IVec, val::FVec, effortlevel::Integer)
    stat = @cpx_ccall(addmipstarts, Cint, (
                      Ptr{Cvoid},
                      Ptr{Cvoid},
                      Cint,
                      Cint,
                      Ptr{Cint},
                      Ptr{Cint},
                      Ptr{Cdouble},
                      Ptr{Cint},
                      Ptr{Ptr{Cchar}}
                      ),
                      model.env.ptr, model.lp, 1, length(indx), Cint[0], indx .- Cint(1), val, Cint[effortlevel], C_NULL)
    if stat != 0
        throw(CplexError(model.env, stat))
    end
end

function free_problem(model::Model)
    stat = @cpx_ccall(freeprob, Cint, (Ptr{Cvoid}, Ptr{Cvoid}), model.env.ptr, model.lp)
    model.lp = C_NULL
    if stat != 0
        throw(CplexError(model.env, stat))
    end
end

function set_terminate(model::Model)
    stat = @cpx_ccall(setterminate, Cint, (Ptr{Cvoid},Ptr{Cint}), model.env.ptr, model.terminator)
    if stat != 0
        throw(CplexError(env, stat))
    end
end

terminate(model::Model) = (model.terminator[1] = 1)

mutable struct ConflictRefinerData
    stat::Int
    nrows::Int # number of rows participating in the conflict
    rowind::Vector{Cint} # index of the rows that participate
    rowstat::Vector{Cint} # state of the rows that participate
    ncols::Int # number of columns participating in the conflict
    colind::Vector{Cint} # index of the columns that participate
    colstat::Vector{Cint} # state of the columns that participates
end

function c_api_getconflict(model::Model)
    # This function always calls refineconflict first, which starts the conflict refiner.
    # In other words, any call to this function is expensive.

    # First, compute the conflict.
    confnumrows_p = Ref{Cint}()
    confnumcols_p = Ref{Cint}()
    stat = @cpx_ccall(
        refineconflict,
        Cint,
        (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cint}, Ptr{Cint}),
        model.env.ptr, model.lp, confnumrows_p, confnumcols_p)
    if stat != 0
        throw(CplexError(model.env, stat))
    end

    # Then, retrieve it.
    confstat_p = Ref{Cint}()
    rowind = Vector{Cint}(undef, confnumrows_p[])
    rowbdstat = Vector{Cint}(undef, confnumrows_p[])
    confnumrows_p = Ref{Cint}()
    colind = Vector{Cint}(undef, confnumcols_p[])
    colbdstat = Vector{Cint}(undef, confnumcols_p[])
    confnumcols_p  = Ref{Cint}()
    stat = @cpx_ccall(
        getconflict,
        Cint,
        (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}),
        model.env.ptr, model.lp, confstat_p, rowind, rowbdstat, confnumrows_p, colind, colbdstat, confnumcols_p)
    if stat != 0
        throw(CplexError(model.env, stat))
    end

    return ConflictRefinerData(confstat_p[], confnumrows_p[], rowind, rowbdstat, confnumcols_p[], colind, colbdstat)
end

function c_api_chgname(model::Model, key::Cchar, ij::Cint, name::String)
    stat = @cpx_ccall(
        chgname,
        Cint,
        (Ptr{Cvoid}, Ptr{Cvoid}, Cint, Cint, Ptr{Cchar}),
        model.env.ptr, model.lp, key, ij, name
    )
    if stat != 0
        throw(CplexError(model.env, stat))
    end
    return
end
