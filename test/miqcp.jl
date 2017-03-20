# QCP example
#    minimize x^2
#
#    s.t.  x >= 0.1
#          x ∈ {0, 1}
#
#    solution: (0.1) objv = 0.01

using CPLEX
using Base.Test

# ===========================================

m = CPLEX.CplexMathProgModel()
CPLEX.loadproblem!(m, Array(Float64, (0,1)), [0.1], [Inf], [0], Float64[], Float64[], :Min)
@test CPLEX.get_prob_type(m.inner) == :LP
CPLEX.setquadobj!(m, reshape([2],(1,1)))
@test CPLEX.get_prob_type(m.inner) == :QP
CPLEX.optimize!(m)
@test isapprox(CPLEX.getobjval(m), 0.5*0.1*2*0.1)

# ===========================================

m2 = CPLEX.CplexMathProgModel()
CPLEX.loadproblem!(m2, Array(Float64, (0,1)), [0.1], [Inf], [0], Float64[], Float64[], :Min)
@test CPLEX.get_prob_type(m2.inner) == :LP
CPLEX.setvartype!(m2, [:Bin])
@test CPLEX.get_prob_type(m2.inner) == :MILP
CPLEX.setquadobj!(m2, reshape([2],(1,1)))
@test CPLEX.get_prob_type(m2.inner) == :MIQP
CPLEX.optimize!(m2)
@test isapprox(CPLEX.getobjval(m2), 0.5*1*2*1)

# ===========================================

m3 = CPLEX.CplexMathProgModel()
CPLEX.loadproblem!(m3, Array(Float64, (0,1)), [0.1], [Inf], [0], Float64[], Float64[], :Min)
@test CPLEX.get_prob_type(m3.inner) == :LP
CPLEX.setquadobj!(m3, reshape([2],(1,1)))
@test CPLEX.get_prob_type(m3.inner) == :QP
CPLEX.setvartype!(m3, [:Bin])
@test CPLEX.get_prob_type(m3.inner) == :MIQP
CPLEX.optimize!(m3)
@test isapprox(CPLEX.getobjval(m3), 0.5*1*2*1)
