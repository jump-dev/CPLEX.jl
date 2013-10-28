module Cplex

    # using BinDeps
    # @BinDeps.load_dependencies

    ### imports
    import Base.convert, Base.show, Base.copy

    # Standard LP interface
    require(joinpath(Pkg.dir("MathProgBase"),"src","MathProgSolverInterface.jl"))
    importall MathProgSolverInterface

    # exported functions
    export make_env, 
           make_problem, 
           read_file!, 
           add_vars!, 
           add_rangeconstrs!, 
           add_rangeconstrs_t!, 
           set_sense!, 
           solve_lp!, 
           get_solution, 
           write_problem, 
           free_problem, 
           close_CPLEX

    include("cpx_common.jl")
    include("cpx_model.jl")
    include("cpx_vars.jl")
    include("cpx_constrs.jl")
    include("cpx_solve.jl")

    include("CplexSolverInterface.jl")

end
