module CPLEXLink

    @osx_only dlopen("libstdc++",RTLD_GLOBAL)

    using BinDeps
    @BinDeps.load_dependencies

    ### imports
    import Base.convert, Base.show, Base.copy

    # Standard LP interface
    require(joinpath(Pkg.dir("MathProgBase"),"src","MathProgSolverInterface.jl"))
    importall MathProgSolverInterface

    # exported functions
    export is_valid,
           get_error_msg,
           read_model,
           write_model,
           get_sense,
           set_sense!,
           get_obj,
           set_obj!,
           set_warm_start,
           free_problem,
           close_CPLEX,
           get_param_type,
           set_param!,
           get_param,
           add_vars!,
           add_var!,
           get_varLB,
           set_varLB!,
           get_varUB,
           set_varUB!,
           set_vartype!,
           get_vartype,
           num_var,
           add_constrs!,
           add_constrs_t!,
           add_rangeconstrs!,
           add_rangeconstrs_t!,
           num_constr,
           get_constr_senses,
           set_constr_senses!,
           get_rhs,
           set_rhs!,
           get_constrLB,
           get_constrUB,
           set_constrLB!,
           set_constrUB!,
           add_qpterms!,
           add_diag_qpterms!,
           add_qconstr!,
           optimize!,
           get_objval,
           get_solution,
           get_reduced_costs,
           get_constr_duals,
           get_constr_solution,
           get_infeasibility_ray,
           get_unbounded_ray,
           get_status,
           get_status_code,
           setcallbackcut,
           cbcut,
           cblazy,
           cbget_mipnode_rel,
           cbget_mipsol_sol,
           cplex_model

    include("full_defines.jl") 
    include("cpx_common.jl")
    include("cpx_env.jl")
    include("cpx_model.jl")
    include("cpx_params.jl")
    include("cpx_vars.jl")
    include("cpx_constrs.jl")
    include("cpx_quad.jl")
    include("cpx_solve.jl")
    include("cpx_callbacks.jl")
    include("cpx_highlevel.jl")

    include("CplexSolverInterface.jl")
end