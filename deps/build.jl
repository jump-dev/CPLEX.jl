using Libdl

const depsfile = joinpath(dirname(@__FILE__), "deps.jl")
if isfile(depsfile)
    rm(depsfile)
end

function write_depsfile(path)
    open(depsfile, "w") do f
        println(f, "const libcplex = \"$(escape_string(path))\"")
    end
end

function library_name(v)
    cpx_prefix = Sys.iswindows() ? "" : "lib"
    return "$(cpx_prefix)cplex$(v).$(Libdl.dlext)"
end

function try_local_installation()
    # Find the path to the CPLEX executable.
    cplex_path = try
        @static if Sys.isapple() || Sys.isunix()
            dirname(strip(read(`which cplex`, String)))
        elseif Sys.iswindows()
            dirname(strip(read(`where cplex`, String)))
        end
    catch
        nothing
    end

    # Iterate through a series of places where CPLEX could be found: either in
    # the path (directly the callable library or # the CPLEX executable) or from
    # an environment variable.
    cpxvers = [
        "128", "1280", "129", "1290", "12100"
    ]
    base_env = "CPLEX_STUDIO_BINARIES"

    libnames = String["cplex"]
    for v in reverse(cpxvers)
        name = library_name(v)
        push!(libnames, name)
        if cplex_path !== nothing
            push!(libnames, joinpath(cplex_path, name))
        end
        for env in [base_env, base_env * v]
            if !haskey(ENV, env)
                continue
            end
            for d in split(ENV[env], ';')
                push!(libnames, joinpath(d, name))
            end
        end
    end

    # Perform the actual search in the potential places.
    for l in libnames
        d = Libdl.dlopen_e(l)
        d == C_NULL && continue
        write_depsfile(Libdl.dlpath(d))
        @info("Using CPLEX found in location `$(l)`")
        return
    end
    error(
        "Unable to locate CPLEX installation. Note this must be downloaded " *
        "separately. See the CPLEX.jl README for further instructions."
    )
end

function try_travis_installation()
    url = ENV["SECRET_CPLEX_URL"]
    local_filename = joinpath(@__DIR__, "libcplex.so")
    download(url, local_filename)
    write_depsfile(local_filename)
end

if get(ENV, "TRAVIS", "false") == "true"
    try_travis_installation()
else
    try_local_installation()
end
