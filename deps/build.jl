# Copyright (c) 2013: Joey Huchette and contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

using Libdl

const _DEPS_FILE = joinpath(dirname(@__FILE__), "deps.jl")
if isfile(_DEPS_FILE)
    rm(_DEPS_FILE)
end

const _CPX_VERS = [ # From oldest to most recent.
    "1210", "12100",
    "201", "2010", "20100",
    "221", "2210", "22100",
    "2211",
]
const _BASE_ENV = "CPLEX_STUDIO_BINARIES"

function write_depsfile(path)
    open(_DEPS_FILE, "w") do f
        println(f, "const libcplex = \"$(escape_string(path))\"")
    end
end

function library_name(v)
    cpx_prefix = Sys.iswindows() ? "" : "lib"
    return "$(cpx_prefix)cplex$(v).$(Libdl.dlext)"
end

function default_installation_path(cplex_studio_path::AbstractString)
    if Sys.iswindows()
        return escape_string("C:\\Program Files\\IBM\\ILOG\\$cplex_studio_path\\cplex\\bin\\x64_win64\\")
    elseif Sys.isapple()
        return "/Applications/$cplex_studio_path/cplex/bin/x86-64_osx/"
    else
        return "/opt/$cplex_studio_path/cplex/bin/x86-64_linux/"
    end
end

function get_error_message_if_not_found()
    return """
    Unable to install CPLEX.jl.

    The versions of CPLEX supported by CPLEX.jl are:

    * 12.10
    * 20.1
    * 22.1 22.1.1

    You must download and install one of these versions separately.

    You should set the `CPLEX_STUDIO_BINARIES` environment variable to point to
    the install location then try again. For example (updating the path to the
    correct location):
    
    ```
    ENV["CPLEX_STUDIO_BINARIES"] = "$(default_installation_path("CPLEX_Studio221"))"
    import Pkg
    Pkg.add("CPLEX")
    Pkg.build("CPLEX")
    ```

    See the CPLEX.jl README at https://github.com/jump-dev/CPLEX.jl for further
    instructions.
    """
end

function check_cplex_in_libnames(libnames)
    for l in libnames
        d = Libdl.dlopen_e(l)
        if d == C_NULL
            continue
        end
        return l
    end
    return nothing
end

function check_cplex_in_environment_variables()
    # Find CPLEX in the CPLEX environment variables. 
    libnames = String[]
    
    for v in reverse(_CPX_VERS)
        name = library_name(v)

        # Library name is not always using the same suffix as in _CPX_VERS.
        # E.g., on Windows, mix between 201 and 2010 for 20.1:
        # C:\Program Files\IBM\ILOG\CPLEX_Studio201\opl\bin\x64_win64\cplex2010.dll
        for env in [_BASE_ENV, _BASE_ENV * v, [_BASE_ENV * v2 for v2 in reverse(_CPX_VERS) if v2 != v]...]
            if !haskey(ENV, env)
                continue
            end

            for d in split(ENV[env], ';')
                if isdir(d) && isfile(joinpath(d, name))
                    push!(libnames, joinpath(d, name))
                end
            end
        end
    end

    return libnames
end

function check_cplex_in_default_paths()
    # Find CPLEX in the default installation locations, based on the platform.
    libnames = String[]
    for v in reverse(_CPX_VERS)
        name = library_name(v)
        for product in ["CPLEX_Studio$v", "CPLEX_Enterprise_Server$v/CPLEX_Studio"]
            path = default_installation_path(product)
            if isdir(path)
                guessed_file = joinpath(path, name)
                if isfile(guessed_file)
                    push!(libnames, guessed_file)
                end
            end
        end
    end
    return libnames
end

function try_local_installation()
    # Iterate through a series of places where CPLEX could be found: either 
    # from an environment variable, in the path (directly the callable library 
    # or the CPLEX executable), or in a default install location, in that 
    # order. Indeed, some software packages propose a version of CPLEX in the 
    # PATH that is not useable from Julia.
    for libnames in [check_cplex_in_environment_variables(), check_cplex_in_default_paths()]
        found_cplex_lib = check_cplex_in_libnames(libnames)
        if found_cplex_lib !== nothing
            write_depsfile(Libdl.dlpath(found_cplex_lib))
            @info("Using CPLEX found in location `$(found_cplex_lib)`")
            return
        end
    end
    
    error(get_error_message_if_not_found())
end

function try_ci_installation()
    CPLEX_VERSION = ENV["CPLEX_VERSION"]
    url = ENV["SECRET_CPLEX_URL_" * CPLEX_VERSION]
    local_filename = joinpath(@__DIR__, "libcplex.so")
    download(url, local_filename)
    write_depsfile(local_filename)
end

if get(ENV, "JULIA_REGISTRYCI_AUTOMERGE", "false") == "true"
    # We need to be able to install and load this package without error for
    # Julia's registry AutoMerge to work. Just write a fake libcplex path.
    write_depsfile("julia_registryci_automerge")
elseif get(ENV, "SECRET_CPLEX_URL_12100", "") != ""
    try_ci_installation()
else
    try_local_installation()
end
