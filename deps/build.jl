using BinDeps

@BinDeps.setup

cplexlibpath = library_dependency("libcplex",aliases=["libcplex124.so","cplex124","cplex1251","libcplex1251.dylib","libcplex1251.jnilib"])

# if haskey(ENV, "CPLEX_HOME")
#     @unix_only provides(Binaries, joinpath(ENV["CPLEX_HOME"],"bin/x86_64"), cplexlibpath)
# end
