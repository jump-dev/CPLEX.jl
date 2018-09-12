@testset "SOS" begin
    @testset "SOS 01" begin
        m = CPLEX.CplexMathProgModel(CPX_PARAM_SCRIND=0)
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

        MathProgBase.optimize!(m)

        @test CPLEX.getobjval(m) ≈ 15.0
        sol = CPLEX.getsolution(m)
        @test sol[9] ≈  3.0
        @test sol[10] ≈ 12.0

        CPLEX.setvartype!(m, fill(:Cont, 10))
        @test CPLEX.get_prob_type(m.inner) == :MILP

        MathProgBase.optimize!(m)

        @test CPLEX.getobjval(m) ≈ 30.0
        sol = CPLEX.getsolution(m)
        @test sol[9] ≈ 6.0
        @test sol[10] ≈ 24.0
    end

    @testset "SOS 02" begin
        m = CPLEX.CplexMathProgModel(CPX_PARAM_SCRIND=0)
        CPLEX.loadproblem!(m, Matrix{Float64}(undef, 0,3), [-Inf, -Inf, -Inf], 
                           [1,1,2], [2,1,1], Float64[], Float64[], :Max)
        @test CPLEX.get_prob_type(m.inner) == :LP

        CPLEX.addsos1!(m, [1,2], [1.0,2.0])
        CPLEX.addsos1!(m, [1,3], [1.0,2.0])
        @test CPLEX.get_prob_type(m.inner) == :MILP

        MathProgBase.optimize!(m)
        @test CPLEX.getobjval(m) ≈ 3.0
    end
end
