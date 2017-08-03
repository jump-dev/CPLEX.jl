__precompile__()

module CPLEX

    if is_apple()
        Libdl.dlopen("libstdc++",Libdl.RTLD_GLOBAL)
    end

    if isfile(joinpath(dirname(@__FILE__),"..","deps","deps.jl"))
        include("../deps/deps.jl")
    else
        error("CPLEX not properly installed. Please run Pkg.build(\"CPLEX\")")
    end

    ### imports
    import Base: convert, unsafe_convert, show, copy

    using Compat

    include("cpx_common.jl")
    include("cpx_env.jl")

    v = version()
    if startswith(v,"12.6")
        include(joinpath("cpx_defines", "cpx_defines_1261.jl"))
        include(joinpath("cpx_defines", "cpx_params_1261.jl"))
    elseif startswith(v,"12.7.1")
        include(joinpath("cpx_defines", "cpx_defines_1261.jl"))
        include(joinpath("cpx_defines", "cpx_params_1261.jl"))
    elseif startswith(v,"12.7")
        include(joinpath("cpx_defines", "cpx_defines_1261.jl"))
        include(joinpath("cpx_defines", "cpx_params_1261.jl"))
    else
        error("Unsupported CPLEX version $v. Only 12.6 and 12.7 are currently supported.")
    end


    include("cpx_model.jl")
    include("cpx_params.jl")
    # include("cpx_vars.jl")
    # include("cpx_constrs.jl")
    # include("cpx_quad.jl")
    # include("cpx_solve.jl")
    # include("cpx_callbacks.jl")
    # include("cpx_highlevel.jl")


    include("cpx_variables.jl")
    include("cpx_constraints.jl")
    include("cpx_objective.jl")
    include("cpx_solve.jl")

    # include("CplexSolverInterface.jl")
    include("MathOptInterface.jl")
    # These are undocumented JuMP extensions for CPLEX which
    # will need to be hosted in a separate package for Julia 0.6 and later.
    if isdir(Pkg.dir("JuMP")) && VERSION < v"0.6-"
        try
            eval(current_module(), Expr(:import,:JuMP))
            include("JuMPfunctions.jl")
        end
    end
end
