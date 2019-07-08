import MathProgBase

math_prog_base_test_dir = joinpath(dirname(pathof(MathProgBase)), "..", "test")

include(joinpath(math_prog_base_test_dir, "linprog.jl"))
linprogtest(CplexSolver(CPX_PARAM_PREIND=0, CPX_PARAM_LPMETHOD=2, CPX_PARAM_SCRIND=0))

include(joinpath(math_prog_base_test_dir, "mixintprog.jl"))
mixintprogtest(CplexSolver(CPX_PARAM_SCRIND=0))

include(joinpath(math_prog_base_test_dir, "quadprog.jl"))
quadprogtest(CplexSolver(CPX_PARAM_SCRIND=0))
socptest(CplexSolver(CPX_PARAM_SCRIND=0))

solver = CplexSolver(CPX_PARAM_SCRIND=0)
CPLEX.setparameters!(solver, Silent=true, TimeLimit=100.0)
include(joinpath(math_prog_base_test_dir, "linproginterface.jl"))
linprogsolvertest(solver)

include(joinpath(math_prog_base_test_dir, "conicinterface.jl"))
coniclineartest(CplexSolver(CPX_PARAM_SCRIND=0))
conicSOCtest(CplexSolver(CPX_PARAM_SCRIND=0))
conicSOCRotatedtest(CplexSolver(CPX_PARAM_SCRIND=0))
conicSOCINTtest(CplexSolver(CPX_PARAM_SCRIND=0))
