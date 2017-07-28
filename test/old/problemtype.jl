using CPLEX
using Base.Test

@testset "Changing variable type" begin
    # linear -> mixed integer -> linear
    m = CPLEX.CplexMathProgModel(CPX_PARAM_SCRIND=0)
    CPLEX.loadproblem!(m, [1 1; 1 0], [0, 0], [Inf, 1], [1, 2], [1.33, -Inf], [Inf, 0.5], :Min)

    @test CPLEX.get_prob_type(m.inner) == :LP
    CPLEX.optimize!(m)
    @test CPLEX.getsolution(m) ≈ [0.5, 0.83]

    CPLEX.setvartype!(m, [:Cont, :Bin])

    @test CPLEX.get_prob_type(m.inner) == :MILP
    CPLEX.optimize!(m)
    @test CPLEX.getsolution(m) ≈ [0.33, 1]

    CPLEX.setvartype!(m, [:Cont, :Cont])

    @test CPLEX.get_prob_type(m.inner) == :LP
    CPLEX.optimize!(m)
    @test CPLEX.getsolution(m) ≈ [0.5, 0.83]
end
