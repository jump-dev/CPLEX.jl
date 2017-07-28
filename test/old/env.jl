using CPLEX, MathProgBase, Base.Test

@testset "Use loadproblem! twice" begin
    solver = CplexSolver()
    # Check that the env for each model is the same
    m = MathProgBase.LinearQuadraticModel(solver)
    env = m.inner.env
    MathProgBase.loadproblem!(m, [1 0], [1, 1], [1, Inf], [1, 0], [0], [Inf], :Min)
    @test m.inner.env === env
    @test CPLEX.is_valid(env)
    MathProgBase.loadproblem!(m, [0 1], [-Inf, 1], [1, 1], [0, 1], [-Inf], [0], :Min)
    @test m.inner.env === env
    @test CPLEX.is_valid(env)
end
