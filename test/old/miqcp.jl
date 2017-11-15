# QCP example
#    minimize x^2
#
#    s.t.  x >= 0.1
#          x ∈ {0, 1}
#
#    solution: (0.1) objv = 0.01

using CPLEX
using Base.Test

@testset "MIQCP" begin
    @testset "MIQCP 01" begin
        m = CPLEX.CplexMathProgModel(CPX_PARAM_SCRIND=0)
        CPLEX.loadproblem!(m, Matrix{Float64}(0,1), [0.1], [Inf], [0], Float64[], Float64[], :Min)
        @test CPLEX.get_prob_type(m.inner) == :LP
        CPLEX.setquadobj!(m, reshape([2],(1,1)))
        @test CPLEX.get_prob_type(m.inner) == :QP
        CPLEX.optimize!(m)
        @test isapprox(CPLEX.getobjval(m), 0.5*0.1*2*0.1)
    end

    @testset "MIQCP 02" begin
        m = CPLEX.CplexMathProgModel(CPX_PARAM_SCRIND=0)
        CPLEX.loadproblem!(m, Matrix{Float64}(0,1), [0.1], [Inf], [0], Float64[], Float64[], :Min)
        @test CPLEX.get_prob_type(m.inner) == :LP
        CPLEX.setvartype!(m, [:Bin])
        @test CPLEX.get_prob_type(m.inner) == :MILP
        CPLEX.setquadobj!(m, reshape([2],(1,1)))
        @test CPLEX.get_prob_type(m.inner) == :MIQP
        CPLEX.optimize!(m)
        @test isapprox(CPLEX.getobjval(m), 0.5*1*2*1)
    end

    @testset "MIQCP 03" begin
        m = CPLEX.CplexMathProgModel(CPX_PARAM_SCRIND=0)
        CPLEX.loadproblem!(m, Matrix{Float64}(0,1), [0.1], [Inf], [0], Float64[], Float64[], :Min)
        @test CPLEX.get_prob_type(m.inner) == :LP
        CPLEX.setquadobj!(m, reshape([2],(1,1)))
        @test CPLEX.get_prob_type(m.inner) == :QP
        CPLEX.setvartype!(m, [:Bin])
        @test CPLEX.get_prob_type(m.inner) == :MIQP
        CPLEX.optimize!(m)
        @test isapprox(CPLEX.getobjval(m), 0.5*1*2*1)
    end
end
