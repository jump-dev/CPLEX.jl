using BinDeps
@BinDeps.setup

@osx_only dlopen("libstdc++",RTLD_GLOBAL)

libcplex = library_dependency("libcplex",aliases=["libcplex124.so","cplex124","cplex1251","libcplex1251.so", "libcplex125.dylib","libcplex1251.dylib","libcplex1251.jnilib","libcplex1260.dylib"])

@BinDeps.install [ :libcplex => :libcplex ]
