using CPLEX

include(joinpath(Pkg.dir("MathProgBase"),"test","linprog.jl"))
linprogtest(CplexMPBSolver(CPX_PARAM_PREIND=0, CPX_PARAM_LPMETHOD=2, CPX_PARAM_SCRIND=0))

include(joinpath(Pkg.dir("MathProgBase"),"test","mixintprog.jl"))
mixintprogtest(CplexMPBSolver(CPX_PARAM_SCRIND=0))

include(joinpath(Pkg.dir("MathProgBase"),"test","quadprog.jl"))
quadprogtest(CplexMPBSolver(CPX_PARAM_SCRIND=0))
socptest(CplexMPBSolver(CPX_PARAM_SCRIND=0))

solver = CplexMPBSolver(CPX_PARAM_SCRIND=0)
MathProgBase.setparameters!(solver, Silent=true, TimeLimit=100.0)
include(joinpath(Pkg.dir("MathProgBase"),"test","linproginterface.jl"))
linprogsolvertest(solver)

include(joinpath(Pkg.dir("MathProgBase"),"test","conicinterface.jl"))
coniclineartest(CplexMPBSolver(CPX_PARAM_SCRIND=0))
conicSOCtest(CplexMPBSolver(CPX_PARAM_SCRIND=0))
conicSOCRotatedtest(CplexMPBSolver(CPX_PARAM_SCRIND=0))
conicSOCINTtest(CplexMPBSolver(CPX_PARAM_SCRIND=0))
