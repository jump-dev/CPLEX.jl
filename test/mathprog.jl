using Cplex

include(joinpath(Pkg.dir("MathProgBase"),"test","linprog.jl"))
linprogtest(GurobiSolver())

include(joinpath(Pkg.dir("MathProgBase"),"test","mixintprog.jl"))
mixintprogtest(GurobiSolver())
