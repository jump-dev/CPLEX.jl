module Cplex

    @osx_only dlopen("libstdc++",RTLD_GLOBAL)

    using BinDeps
    @BinDeps.load_dependencies

    ### imports
    import Base.convert, Base.show, Base.copy

    # Standard LP interface
    require(joinpath(Pkg.dir("MathProgBase"),"src","MathProgSolverInterface.jl"))
    importall MathProgSolverInterface

    # exported functions
    export make_env, 
           make_problem, 
           read_file!,
           set_param!,
           add_var!, 
           add_vars!, 
           add_rangeconstrs!, 
           add_rangeconstrs_t!, 
           add_constr!,
           set_sense!,
           set_obj!,
           optimize!, 
           get_solution, 
           write_problem, 
           free_problem, 
           close_CPLEX
    include("full_defines.jl") 
    include("cpx_common.jl")
    include("cpx_env.jl")
    include("cpx_model.jl")
    include("cpx_params.jl")
    include("cpx_vars.jl")
    include("cpx_constrs.jl")
    include("cpx_solve.jl")
    include("cpx_callbacks.jl")

    include("CplexSolverInterface.jl")
    include("CplexSolverCallbacksInterface.jl")
end
