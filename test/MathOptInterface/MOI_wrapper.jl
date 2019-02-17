using MathOptInterface, CPLEX, Test

const MOI  = MathOptInterface
const MOIT = MOI.Test
const MOIB = MOI.Bridges

const SOLVER = CPLEX.Optimizer()
const CONFIG = MOIT.TestConfig()

@testset "Unit Tests" begin
    MOIT.unittest(SOLVER, CONFIG, [
        "solve_affine_interval",  # not implemented
        "solve_qp_edge_cases",    # not implemented
        "solve_qcp_edge_cases",   # not implemented
        "solve_objbound_edge_cases"
    ])
    @testset "solve_affine_interval" begin
        MOIT.solve_affine_interval(MOIB.SplitInterval{Float64}(SOLVER), CONFIG)
    end
    MOIT.modificationtest(SOLVER, CONFIG, [
        "solve_func_scalaraffine_lessthan"
    ])
end

@testset "Linear tests" begin
    @testset "Default Solver"  begin
        MOIT.contlineartest(SOLVER, CONFIG, [
            "linear10",  # Requires interval
            # Requires infeasiblity certificates
            "linear8a", "linear8b", "linear8c", "linear11", "linear12",
            # Exclude for now since hot-starts not implemented.
            "partial_start"
        ])
    end
    @testset "linear10" begin
        MOIT.linear10test(MOIB.SplitInterval{Float64}(SOLVER), CONFIG)
    end
    @testset "No certificate" begin
        MOIT.linear12test(
            SOLVER,
            MOIT.TestConfig(infeas_certificates=false)
        )
    end
end
@testset "Integer Linear tests" begin
    MOIT.intlineartest(SOLVER, CONFIG, [
        "int3"  # Requires Interval
    ])
    @testset "int3" begin
        MOIT.int3test(MOIB.SplitInterval{Float64}(SOLVER), CONFIG)
    end
end

@testset "ModelLike tests" begin
    @test MOI.get(SOLVER, MOI.SolverName()) == "CPLEX"
    @testset "default_objective_test" begin
         MOIT.default_objective_test(SOLVER)
     end
     @testset "default_status_test" begin
         MOIT.default_status_test(SOLVER)
     end
    @testset "nametest" begin
        MOIT.nametest(SOLVER)
    end
    @testset "validtest" begin
        MOIT.validtest(SOLVER)
    end
    @testset "emptytest" begin
        MOIT.emptytest(SOLVER)
    end
    @testset "orderedindicestest" begin
        MOIT.orderedindicestest(SOLVER)
    end
    @testset "copytest" begin
        MOIT.copytest(SOLVER, CPLEX.Optimizer())
    end
end
