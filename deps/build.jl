using Libdl

depsfile = joinpath(dirname(@__FILE__), "deps.jl")
if isfile(depsfile)
    rm(depsfile)
end

function write_depsfile(path)
    open(depsfile, "w") do f
        print(f, "const libcplex = ")
        show(f, path) # print with backslashes excaped on windows
        println(f)
    end
end

@static if Sys.isapple()
    Libdl.dlopen("libstdc++", Libdl.RTLD_GLOBAL)
end

base_cpxvers = ["128", "129"]
cpxvers = [base_cpxvers; base_cpxvers .* "0"]
base_env = "CPLEX_STUDIO_BINARIES"

# Find the path to the CPLEX executable.
cplex_path = try
    @static if Sys.isapple() || Sys.isunix()
        read(`which cplex`, String)
    elseif Sys.iswindows()
        read(`where cplex`, String)
    end
catch
    nothing
end
if cplex_path !== nothing
    # Extract the path to the folder containing the CPLEX executable.
    cplex_path = dirname(strip(cplex_path))
end

# Iterate through a series of places where CPLEX could be found: either in the path (directly the callable library or
# the CPLEX executable) or from an environment variable.
cpx_prefix = Sys.iswindows() ? "" : "lib"

libnames = String["cplex"]
for v in reverse(cpxvers)
    push!(libnames, "$(cpx_prefix)cplex$(v).$(Libdl.dlext)")
    if cplex_path !== nothing
        push!(libnames, joinpath(cplex_path, "$(cpx_prefix)cplex$(v).$(Libdl.dlext)"))
    end

    for env in [base_env, base_env * v]
        if haskey(ENV, env)
            for d in split(ENV[env], ';')
                occursin("cplex", d) || continue
                push!(libnames, joinpath(d, "$(cpx_prefix)cplex$(v).$(Libdl.dlext)"))
            end
        end
    end
end

# Perform the actual search in the potential places.
found = false
for l in libnames
    d = Libdl.dlopen_e(l)
    if d != C_NULL
        global found = true
        write_depsfile(Libdl.dlpath(d))
        @info("Using CPLEX found in location `$(libname)`")
        break
    end
end

if !found
    error("Unable to locate CPLEX installation. Note this must be downloaded separately. See the CPLEX.jl README for further instructions.")
end
