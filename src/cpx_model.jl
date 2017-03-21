type Model
    env::Env # Cplex environment
    lp::Ptr{Void} # Cplex problem (lp)
    has_int::Bool # problem has integer variables?
    has_qc::Bool # problem has quadratic constraints?
    has_sos::Bool # problem has Special Ordered Sets?
    callback::Any
    terminator::Vector{Cint}
end

function Model(env::Env, lp::Ptr{Void})
    notify_new_model(env)
    model = Model(env, lp, false, false, false, nothing, Cint[0])
    finalizer(model, m -> begin
                              free_problem(m)
                              notify_freed_model(env)
                          end)
    set_terminate(model)
    model
end

function Model(env::Env, name::String="CPLEX.jl")
    @assert is_valid(env)
    stat = Array(Cint, 1)
    tmp = @cpx_ccall(createprob, Ptr{Void}, (Ptr{Void}, Ptr{Cint}, Ptr{Cchar}), env.ptr, stat, name)
    if tmp == C_NULL
        throw(CplexError(env, stat))
    end
    return Model(env, tmp)
end

function read_model(model::Model, filename::String)
    stat = @cpx_ccall(readcopyprob, Cint, (Ptr{Void}, Ptr{Void}, Ptr{Cchar}, Ptr{Cchar}), model.env.ptr, model.lp, filename, C_NULL)
    if stat != 0
        throw(CplexError(model.env, stat))
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
                   Ptr{Void},
                   Ptr{Void}),
                   model.env.ptr, model.lp)
  ret == -1 && error("No problem of environment")
  return type_map[Int(ret)]
end

function set_prob_type!(model::Model, tyint::Int)
    stat = @cpx_ccall(chgprobtype, Cint, (
                     Ptr{Void},
                     Ptr{Void},
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
                        Ptr{Void},
                        Ptr{Void},
                        Cint,
                        Ptr{Cint},
                        Ptr{Cdouble}
                        ),
                        model.env.ptr, model.lp, nvars, Cint[0:nvars-1;], float(c))
    if stat != 0
        throw(CplexError(model.env, stat))
    end
end

set_warm_start!(model::Model, x::Vector{Float64}, effortlevel::Integer = CPX_MIPSTART_AUTO) = set_warm_start!(model, Cint[1:length(x);], x, effortlevel)

function set_warm_start!(model::Model, indx::IVec, val::FVec, effortlevel::Integer)
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
                      model.env.ptr, model.lp, 1, length(indx), Cint[0], indx -Cint(1), val, Cint[effortlevel], C_NULL)
    if stat != 0
        throw(CplexError(model.env, stat))
    end
end

function set_warm_starts!(model::Model, x::Vector{Vector{Float64}}, efforts::Vector{Cint})
	beg, inds, vals = Cint[], Cint[], Cdouble[]
	count::Int64 = 1
	for i in 1:length(x)
		push!(beg, count)
		for j in 1:length(x[i])
			push!(inds, j)
			push!(vals, x[i][j])
			count += 1
		end
	end
	set_warm_starts!(model, convert(Cint, length(x)), beg, inds, vals, efforts)
end

set_warm_start!{T<:Signed}(model::Model, x::Vector{Float64}, effort::T) = set_warm_starts!(model, convert(Cint, 1), Cint[1], Cint[1:length(x);], x, [convert(Cint, effort)])

function set_warm_starts!(model::Model, num_warm_starts::Cint, beg::Vector{Cint}, inds::Vector{Cint}, vals::Vector{Cdouble}, efforts::Vector{Cint})
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
                      model.env.ptr, model.lp, num_warm_starts, length(inds), beg - 1, inds - 1, vals, efforts, fill(C_NULL, num_warm_starts))
    if stat != 0
        throw(CplexError(model.env, stat))
    end
end

del_warm_start!{T<:Signed}(model::Model, ind::T) = del_warm_starts!(model, convert(Cint, ind), convert(Cint, ind))

del_warm_starts!{T<:Signed}(model::Model, start_ind::T, end_ind::T) = del_warm_starts!(model, convert(Cint, start_ind), convert(Cint, end_ind))

function del_warm_starts!(model::Model, start_ind::Cint, end_ind::Cint)
    stat = @cpx_ccall(delmipstarts, Cint, (
                      Ptr{Void},
                      Ptr{Void},
                      Cint,
                      Cint
                      ),
                      model.env.ptr, model.lp, start_ind-1, end_ind-1)
    if stat != 0
        throw(CplexError(model.env, stat))
    end
end

function free_problem(model::Model)
    tmp = Ptr{Void}[model.lp]
    stat = @cpx_ccall(freeprob, Cint, (Ptr{Void}, Ptr{Void}), model.env.ptr, tmp)
    if stat != 0
        throw(CplexError(model.env, stat))
    end
end

function set_terminate(model::Model)
    stat = @cpx_ccall(setterminate, Cint, (Ptr{Void},Ptr{Cint}), model.env.ptr, model.terminator)
    if stat != 0
        throw(CplexError(env, stat))
    end
end

terminate(model::Model) = (model.terminator[1] = 1)
