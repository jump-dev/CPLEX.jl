using CPLEX

include(joinpath(Pkg.dir("MathProgBase"),"test","linprog.jl"))
linprogtest(CplexSolver(CPX_PARAM_PREIND=0, CPX_PARAM_LPMETHOD=2))

include(joinpath(Pkg.dir("MathProgBase"),"test","mixintprog.jl"))
mixintprogtest(CplexSolver())

include(joinpath(Pkg.dir("MathProgBase"),"test","quadprog.jl"))
quadprogtest(CplexSolver())
socptest(CplexSolver())

include(joinpath(Pkg.dir("MathProgBase"),"test","linproginterface.jl"))
linprogsolvertest(CplexSolver())

include(joinpath(Pkg.dir("MathProgBase"),"test","conicinterface.jl"))
coniclineartest(CplexSolver())
conicSOCtest(CplexSolver())
conicSOCRotatedtest(CplexSolver())
conicSOCINTtest(CplexSolver())
