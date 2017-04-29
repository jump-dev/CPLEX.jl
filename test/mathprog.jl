using CPLEX

include(joinpath(Pkg.dir("MathProgBase"),"test","linprog.jl"))
linprogtest(CplexSolver(CPX_PARAM_PREIND=0, CPX_PARAM_LPMETHOD=2, CPX_PARAM_SCRIND=0))

include(joinpath(Pkg.dir("MathProgBase"),"test","mixintprog.jl"))
mixintprogtest(CplexSolver(CPX_PARAM_SCRIND=0))

include(joinpath(Pkg.dir("MathProgBase"),"test","quadprog.jl"))
quadprogtest(CplexSolver(CPX_PARAM_SCRIND=0))
socptest(CplexSolver(CPX_PARAM_SCRIND=0))

solver = CplexSolver(CPX_PARAM_SCRIND=0)
MathProgBase.setparameters!(solver, Silent=true, TimeLimit=100.0)
include(joinpath(Pkg.dir("MathProgBase"),"test","linproginterface.jl"))
linprogsolvertest(solver)

include(joinpath(Pkg.dir("MathProgBase"),"test","conicinterface.jl"))
coniclineartest(CplexSolver(CPX_PARAM_SCRIND=0))
conicSOCtest(CplexSolver(CPX_PARAM_SCRIND=0))
conicSOCRotatedtest(CplexSolver(CPX_PARAM_SCRIND=0))
conicSOCINTtest(CplexSolver(CPX_PARAM_SCRIND=0))
