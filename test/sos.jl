using CPLEX, Base.Test

m = CPLEX.CplexMathProgModel()
CPLEX.loadproblem!(m,
    [1 2 3 0 0 0 0 0 -1 0; 0 0 0 5 4 7 2 1 0 -1], # constraint matrix
    [0, 0, 0, 0, 0, 0, 0, 0, -Inf, -Inf], # variable lb
    [2, 2, 2, 2, 2, 2, 2, 2, Inf, Inf], # variable ub
    vcat(zeros(8), ones(2)), # objective vector
    [0, 0], # constraint lb
    [0, 0], # constraint ub
    :Max)
@test CPLEX.get_prob_type(m.inner) == :LP

CPLEX.setvartype!(m, vcat(fill(:Bin, 8), fill(:Cont, 2)))
@test CPLEX.get_prob_type(m.inner) == :MILP

CPLEX.addsos1!(m, [1,2,3], [1.0,2.0,3.0])
CPLEX.addsos2!(m, [4,5,6,7,8], [5.0, 4.0, 7.0, 2.0, 1.0])
@test CPLEX.get_prob_type(m.inner) == :MILP

CPLEX.optimize!(m)

@test isapprox(CPLEX.getobjval(m), 15.0)
sol = CPLEX.getsolution(m)
@test isapprox(sol[9],  3.0)
@test isapprox(sol[10], 12.0)

CPLEX.setvartype!(m, fill(:Cont, 10))
@test CPLEX.get_prob_type(m.inner) == :MILP

CPLEX.optimize!(m)

@test isapprox(CPLEX.getobjval(m), 30.0)
sol = CPLEX.getsolution(m)
@test isapprox(sol[9],  6.0)
@test isapprox(sol[10], 24.0)

# ======================================

m2 = CPLEX.CplexMathProgModel()
CPLEX.loadproblem!(m2, Matrix{Float64}(0,3), [-Inf, -Inf, -Inf], [1,1,2], [2,1,1], Float64[], Float64[], :Max)
@test CPLEX.get_prob_type(m2.inner) == :LP

CPLEX.addsos1!(m2, [1,2], [1.0,2.0])
CPLEX.addsos1!(m2, [1,3], [1.0,2.0])
@test CPLEX.get_prob_type(m2.inner) == :MILP

CPLEX.optimize!(m2)
@test isapprox(CPLEX.getobjval(m2), 3.0)
