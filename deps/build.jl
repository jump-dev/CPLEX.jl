using BinDeps
@BinDeps.setup

libcplex = library_dependency("libcplex",aliases=["libcplex124.so","cplex124","cplex1251","libcplex1251.dylib","libcplex1251.jnilib"])
