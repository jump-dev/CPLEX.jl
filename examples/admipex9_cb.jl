#callbacks for cap problem
using CPLEX, Revise#, Gallium
import Base: convert, unsafe_convert, show, copy
using Compat
import Gallium
#revise julia
# JuliaPath="/Users/chengguo/.julia/v0.6/CPLEX/src/"
# include("/Users/chengguo/.julia/v0.6/CPLEX/deps/deps.jl")

# include(string(JuliaPath,"cpx_common.jl"))
# include(string(JuliaPath,"cpx_env.jl"))
# include(string(JuliaPath,"cpx_model.jl"))
# include(string(JuliaPath,"full_defines_1280.jl"))
# include(string(JuliaPath,"cpx_params_1280.jl"))
# include(string(JuliaPath,"cpx_callbacks.jl"))
# include(string(JuliaPath,"cpx_newcbs.jl"))
# Libdl.dlopen("libstdc++",Libdl.RTLD_GLOBAL)
##################
#example of cplex callable library, admipex9.c
env=CPLEX.Env()
#build the model and read the problem from the .mps file
path=joinpath(dirname(@__FILE__),"sentoy.mps")
model=CPLEX.Model(env,path)
CPLEX.read_model(model,path)
model.has_int = true#need to change cpx_solve.jl L4
CPLEX.set_param!(env,"CPXPARAM_MIP_Tolerances_MIPGap", 1e-6)
#set up generic callback
ncols=CPLEX.num_var(model)
obj=CPLEX.get_obj(model)
# where=Clong(0)
where=Clong(0)
where |=CPLEX.CPX_CALLBACKCONTEXT_RELAXATION

gcbdata=CPLEX.GenCallbackData(ncols,obj)
# GenCallbackData(gcbdata,ncols,obj)
# gcbdata.ncol=ncols
# gcbdata.obj=obj

CPLEX.setcallbackfunc(env,model,where,pointer_from_objref(gcbdata))

CPLEX.set_param!(env,"CPXPARAM_MIP_Strategy_HeuristicFreq", -1)

# @enter CPLEX.optimize!(model)
CPLEX.optimize!(model)

println("The solving status: ", CPLEX.get_status(model))
println("The optimal objective value is: ", CPLEX.get_objval(model))
