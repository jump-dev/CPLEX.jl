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

    import Base: convert, unsafe_convert, show, copy

    using MathOptInterface

    const MOI = MathOptInterface

    include("cpx_common.jl")
    include("cpx_env.jl")

    v = cpx_version()
    if startswith(v,"12.6")
        include(joinpath("cpx_defines", "cpx_defines_1261.jl"))
        include(joinpath("cpx_defines", "cpx_params_1261.jl"))
    elseif startswith(v,"12.7.1")
        include(joinpath("cpx_defines", "cpx_defines_1271.jl"))
        include(joinpath("cpx_defines", "cpx_params_1271.jl"))
    elseif startswith(v,"12.7")
        include(joinpath("cpx_defines", "cpx_defines_1270.jl"))
        include(joinpath("cpx_defines", "cpx_params_1270.jl"))
    else
        error("Unsupported CPLEX version $v. Only 12.6 and 12.7 are currently supported.")
    end

    include("cpx_model.jl")
    include("cpx_params.jl")
    include("cpx_variables.jl")
    include("cpx_constraints.jl")
    include("cpx_objective.jl")
    include("cpx_solve.jl")

    include("MOIWrapper.jl")

    #=
        Include the old MPB layer with associated functions
    =#
    importall MathProgBase.SolverInterface
    using Compat
    include(joinpath("old", "cpx_common.jl"))
    include(joinpath("old", "cpx_env.jl"))
    v = version()
    if startswith(v,"12.6")
        include(joinpath("old", "full_defines_126.jl"))
        include(joinpath("old", "cpx_params_126.jl"))
    elseif startswith(v,"12.7.1")
        include(joinpath("old", "full_defines_1271.jl"))
        include(joinpath("old", "cpx_params_1271.jl"))
    elseif startswith(v,"12.7")
        include(joinpath("old", "full_defines_127.jl"))
        include(joinpath("old", "cpx_params_127.jl"))
    else
        error("Unsupported CPLEX version $v. Only 12.6 and 12.7 are currently supported.")
    end
    include(joinpath("old", "cpx_model.jl"))
    include(joinpath("old", "cpx_params.jl"))
    include(joinpath("old", "cpx_vars.jl"))
    include(joinpath("old", "cpx_constrs.jl"))
    include(joinpath("old", "cpx_quad.jl"))
    include(joinpath("old", "cpx_solve.jl"))
    include(joinpath("old", "cpx_callbacks.jl"))
    include(joinpath("old", "cpx_highlevel.jl"))
    include(joinpath("old", "CplexSolverInterface.jl"))
    # These are undocumented JuMP extensions for CPLEX which
    # will need to be hosted in a separate package for Julia 0.6 and later.
    if isdir(Pkg.dir("JuMP")) && VERSION < v"0.6-"
        try
            eval(current_module(), Expr(:import,:JuMP))
            include(joinpath("old", "JuMPfunctions.jl"))
        end
    end
end
