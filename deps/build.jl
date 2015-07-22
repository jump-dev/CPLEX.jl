using BinDeps, Compat
@BinDeps.setup

@osx_only Libdl.dlopen("libstdc++",Libdl.RTLD_GLOBAL)

cpxvers = ["124","125","1251","1260","1261","1262"]

libnames = String["cplex"]
for v in cpxvers
    push!(libnames, "cplex$v")
    push!(libnames, "libcplex$v.so")
    # push!(libnames, "libcplex$v.dylib")
end

libcplex = library_dependency("libcplex",aliases=libnames)

@windows_only begin
    wincpxvers = ["126"]
    for v in wincpxvers
        env = "CPLEX_STUDIO_BINARIES$v"
        if haskey(ENV,env)
            for d in split(ENV[env],';')
                contains(d,"cplex") || continue
                provides(Binaries, d, libcplex)
            end
        end
    end
end


@BinDeps.install @Compat.Dict(:libcplex => :libcplex)
