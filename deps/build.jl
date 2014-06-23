using BinDeps
@BinDeps.setup

@osx_only dlopen("libstdc++",RTLD_GLOBAL)

libcplex = library_dependency("libcplex",aliases=["libcplex124.so","cplex124","libcplex125.so","cplex125","cplex1251","libcplex1251.so", "libcplex125.dylib","libcplex1251.dylib","libcplex1251.jnilib","cplex1260","libcplex1260.dylib"])

@windows_only begin
    cpxvers = ["126"]
    for v in cpxvers
        env = "CPLEX_STUDIO_BINARIES$v"
        if haskey(ENV,env)
            for d in split(ENV[env],';')
                contains(d,"cplex") || continue
                provides(Binaries, d, libcplex)
            end
        end
    end
end


@BinDeps.install [ :libcplex => :libcplex ]
