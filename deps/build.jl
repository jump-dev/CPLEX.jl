using Libdl

const _DEPS_FILE = joinpath(dirname(@__FILE__), "deps.jl")
if isfile(_DEPS_FILE)
    rm(_DEPS_FILE)
end

function write_depsfile(path)
    open(_DEPS_FILE, "w") do f
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
        "1210", "12100"
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
        if d == C_NULL
            continue
        end
        write_depsfile(Libdl.dlpath(d))
        @info("Using CPLEX found in location `$(l)`")
        return
    end
    error("""
    Unable to install CPLEX.jl.

    The versions of CPLEX supported by CPLEX.jl are:

    * 12.10

    You must download and install one of these versions separately.

    You should set the `CPLEX_STUDIO_BINARIES` environment variable to point to
    the install location then try again. For example (updating the path to the
    correct location if needed):

    ```
    # On Windows, this might be
    ENV["CPLEX_STUDIO_BINARIES"] = "C:\\\\Program Files\\\\CPLEX_Studio1210\\\\cplex\\\\bin\\\\x86-64_win\\\\"
    import Pkg
    Pkg.add("CPLEX")
    Pkg.build("CPLEX")

    # On OSX, this might be
    ENV["CPLEX_STUDIO_BINARIES"] = "/Applications/CPLEX_Studio1210/cplex/bin/x86-64_osx/"
    import Pkg
    Pkg.add("CPLEX")
    Pkg.build("CPLEX")

    # On Unix, this might be
    ENV["CPLEX_STUDIO_BINARIES"] = "/opt/CPLEX_Studio1210/cplex/bin/x86-64_linux/"
    import Pkg
    Pkg.add("CPLEX")
    Pkg.build("CPLEX")
    ```

    See the CPLEX.jl README at https://github.com/jump-dev/CPLEX.jl for further
    instructions.
    """)
end

function try_travis_installation()
    url = ENV["SECRET_CPLEX_URL_12100"]
    local_filename = joinpath(@__DIR__, "libcplex.so")
    download(url, local_filename)
    write_depsfile(local_filename)
end

if get(ENV, "TRAVIS", "false") == "true"
    try_travis_installation()
else
    try_local_installation()
end
