@static if VERSION >= v"0.7.0-DEV.3382"
    using Libdl
end

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

base_env = "CPLEX_STUDIO_BINARIES"

cplex_path = try
    # Find the path to the CPLEX executable.
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

base_cpxvers = ["128", "129"]
cpxvers = [base_cpxvers; base_cpxvers .* "0"]

libnames = String["cplex"]
for v in reverse(cpxvers)
    if Sys.isapple()
        push!(libnames, "libcplex$v.dylib")
    elseif Sys.isunix()
        push!(libnames, "libcplex$v.so")
        if haskey(ENV, base_env)
            push!(libnames, joinpath(ENV[base_env], "libcplex$v.so"))
        end
        if cplex_path !== nothing
            push!(libnames, joinpath(cplex_path, "libcplex$v.so"))
        end
    end
end

base_wincpxvers = ["128", "129"]
wincpxvers = [base_wincpxvers; base_wincpxvers .* "0"]

@static if Sys.iswindows()
    for v in reverse(wincpxvers)
        env = base_env * v
        if haskey(ENV, env)
            for d in split(ENV[env], ';')
                occursin("cplex", d) || continue
                push!(libnames, joinpath(d, "cplex$(v)"))
            end
        end
        if cplex_path !== nothing
            push!(libnames, joinpath(cplex_path, "cplex$(v)"))
        end
    end
end

found = false

for l in libnames
    d = Libdl.dlopen_e(l)
    if d != C_NULL
        global found = true
        write_depsfile(Libdl.dlpath(d))
        break
    end
end

if !found
    error("Unable to locate CPLEX installation. Note this must be downloaded separately. See the CPLEX.jl README for further instructions.")
end
