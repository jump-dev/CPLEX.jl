type Model
    env::Env # Cplex environment
    lp::Ptr{Void} # Cplex problem (lp)
    terminator::Vector{Cint}
end

function Model(env::Env, lp::Ptr{Void})
    notify_new_model(env)
    model = Model(env, lp, Cint[0])
    finalizer(model, m -> begin
                              free_problem(m)
                              notify_freed_model(env)
                          end)
    set_terminate(model)
    model
end

function Model(env::Env, name::String="CPLEX.jl")
    @assert is_valid(env)
    stat = Vector{Cint}(1)
    tmp = @cpx_ccall(createprob, Ptr{Void}, (Ptr{Void}, Ptr{Cint}, Ptr{Cchar}), env.ptr, stat, name)
    if tmp == C_NULL
        throw(CplexError(env, stat))
    end
    return Model(env, tmp)
end

const PROB_TYPE_MAP = Dict(
     0 => :LP,
     1 => :MILP,
     3 => :FIXEDMILP, # actually fixed milp
     5 => :QP,
     7 => :MIQP,
     8 => :FIXEDMIQP,
    10 => :QCP,
    11 => :MIQCP
)
const REV_PROB_TYPE_MAP = Dict(
    :LP         => 0,
    :MILP       => 1,
    :FIXEDMILP  => 3,
    :QP         => 5,
    :MIQP       => 7,
    :FIXEDMIQP  => 8,
    :QCP        => 10,
    :MIQCP      => 11
)

const PROB_TYPE_TOGGLE = Dict(
:LP         => :MILP,
:MILP       => :LP,
# :FIXEDMILP  => ,
:QP         => :MIQP,
:MIQP       => :QP,
# :FIXEDMIQP  => ,
:QCP        => :MIQCP,
:MIQCP      => :QCP
)
const INTEGER_PROBLEM_TYPES = [:MILP, :MIQP, :MIQCP]
const CONTINUOUS_PROBLEM_TYPES = [:LP, :QP, :QCP]


function cpx_getprobtype(model::Model)
    @cpx_ccall(getprobtype, Cint, (Ptr{Void}, Ptr{Void}), model.env.ptr, model.lp)
end

function cpx_chgprobtype!(model::Model, tyint::Int)
    @cpx_ccall_error(model.env, chgprobtype, Cint, (Ptr{Void}, Ptr{Void}, Cint),
                     model.env.ptr, model.lp, tyint)
end
cpx_setprobtype!(model::Model, ty::Symbol) = cpx_chgprobtype!(model, rev_prob_type_map[ty])

function _make_problem_type_integer(model::Model)
    prob_type_code = cpx_getprobtype(model)
    prob_type_sym = PROB_TYPE_MAP[prob_type_code]
    if !(prob_type_sym in INTEGER_PROBLEM_TYPES)
        new_type_code = PROB_TYPE_TOGGLE[prob_type_sym]
        cpx_chgprobtype!(model, REV_PROB_TYPE_MAP[new_type_code])
    end
end
function _make_problem_type_continuous(model::Model)
    prob_type_code = cpx_getprobtype(model)
    prob_type_sym = PROB_TYPE_MAP[prob_type_code]
    if !(prob_type_sym in CONTINUOUS_PROBLEM_TYPES)
        new_type_code = PROB_TYPE_TOGGLE[prob_type_sym]
        cpx_chgprobtype!(model, REV_PROB_TYPE_MAP[new_type_code])
    end
end

#
#
# function read_model(model::Model, filename::String)
#     stat = @cpx_ccall(readcopyprob, Cint, (Ptr{Void}, Ptr{Void}, Ptr{Cchar}, Ptr{Cchar}), model.env.ptr, model.lp, filename, C_NULL)
#     if stat != 0
#         throw(CplexError(model.env, stat))
#     end
# end
#
# function write_model(model::Model, filename::String)
#     if endswith(filename,".mps")
#         filetype = "MPS"
#     elseif endswith(filename,".lp")
#         filetype = "LP"
#     else
#         error("Unrecognized file extension: $filename (Only .mps and .lp are supported)")
#     end
#     stat = @cpx_ccall(writeprob, Cint, (Ptr{Void}, Ptr{Void}, Ptr{Cchar}, Ptr{Cchar}), model.env.ptr, model.lp, filename, filetype)
#     if stat != 0
#         throw(CplexError(model.env, stat))
#     end
# end
#
# ## TODO: deep copy model, reset model
#
# set_warm_start!(model::Model, x::Vector{Float64}, effortlevel::Integer = CPX_MIPSTART_AUTO) = set_warm_start!(model, Cint[1:length(x);], x, effortlevel)
#
# function set_warm_start!(model::Model, indx::IVec, val::FVec, effortlevel::Integer)
#     stat = @cpx_ccall(addmipstarts, Cint, (
#                       Ptr{Void},
#                       Ptr{Void},
#                       Cint,
#                       Cint,
#                       Ptr{Cint},
#                       Ptr{Cint},
#                       Ptr{Cdouble},
#                       Ptr{Cint},
#                       Ptr{Ptr{Cchar}}
#                       ),
#                       model.env.ptr, model.lp, 1, length(indx), Cint[0], indx -Cint(1), val, Cint[effortlevel], C_NULL)
#     if stat != 0
#         throw(CplexError(model.env, stat))
#     end
# end
#
function free_problem(model::Model)
    tmp = Ptr{Void}[model.lp]
    @cpx_ccall_error(model.env, freeprob, Cint, (Ptr{Void}, Ptr{Void}), model.env.ptr, tmp)
end

function set_terminate(model::Model)
    @cpx_ccall_error(model.env, setterminate, Cint, (Ptr{Void},Ptr{Cint}), model.env.ptr, model.terminator)
end

terminate(model::Model) = (model.terminator[1] = 1)
