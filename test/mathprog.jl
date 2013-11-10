using Cplex

include(joinpath(Pkg.dir("MathProgBase"),"test","linprog.jl"))
linprogtest(CplexSolver())

include(joinpath(Pkg.dir("MathProgBase"),"test","mixintprog.jl"))
mixintprogtest(CplexSolver())

include(joinpath(Pkg.dir("MathProgBase"),"test","linproginterface.jl"))
linprogsolvertest(CplexSolver())
