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
        "128", "1280", "129", "1290"
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

"""
    is_general_registry()

Detect if we are being called from AutoMerge CI on the Julia General registry.

The Julia General registry attempts to install and test packages. Since it does't have a
CPLEX license, this build will fail, preventing auto-merge. Therefore, we need to detect
when we are being called and silently bail.

Complicating matters is the very particular way in which we get called, because we don't get
a typical installation. In particular, a very restricted set of environment variables is
passed. See here for details:
https://github.com/JuliaRegistries/RegistryCI.jl/blob/0d19525c7120176e5e0f11637dcca7b229b5f0c9/src/AutoMerge/guidelines.jl#L178-L196

This check is fragile, and subject to breakage. But it seems highly unlikely that a user
will have a set-up identical to this.
"""
function is_general_registry()
    return all([
        haskey(ENV, "PATH"),
        haskey(ENV, "JULIA_DEPOT_PATH"),
        get(ENV, "PYTHON", "false") == "",
        get(ENV, "R_HOME", "false") == "*",
    ])
end

if get(ENV, "TRAVIS", "false") == "true"
    try_travis_installation()
elseif is_general_registry()
    # TODO(odow): remove this once we distribute the community edition.
else
    try_local_installation()
end
