using MathOptInterface, CPLEX, Test

const MOI  = MathOptInterface
const MOIT = MOI.Test
const MOIB = MOI.Bridges

const SOLVER = CPLEX.Optimizer(CPX_PARAM_SCRIND = 0)
const CONFIG = MOIT.TestConfig()

@testset "Unit Tests" begin
    MOIT.unittest(SOLVER, CONFIG, [
        "solve_affine_interval",  # not implemented
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
            # Requires interval
            "linear10", "linear10b",
            # Requires infeasiblity certificates
            "linear8a", "linear8b", "linear8c", "linear11", "linear12",
            # VariablePrimalStart not implemented.
            "partial_start"
        ])
    end
    @testset "linear10" begin
        MOIT.linear10test(MOIB.SplitInterval{Float64}(SOLVER), CONFIG)
        MOIT.linear10btest(MOIB.SplitInterval{Float64}(SOLVER), CONFIG)
    end
    @testset "No certificate" begin
        MOIT.linear12test(
            SOLVER, MOIT.TestConfig(infeas_certificates=false))
    end
end

@testset "Linear Conic" begin
    # TODO(odow): why no infeasiblity certificates here?
    MOIT.lintest(SOLVER, MOIT.TestConfig(infeas_certificates=false))
end

@testset "Integer Linear tests" begin
    MOIT.intlineartest(SOLVER, CONFIG, ["int3"])
    @testset "int3" begin
        MOIT.int3test(MOIB.SplitInterval{Float64}(SOLVER), CONFIG)
    end
end

@testset "Quadratic tests" begin
    MOIT.contquadratictest(
        SOLVER,
        MOIT.TestConfig(atol=1e-3, rtol=1e-3, duals=true, query=true)
    )
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

@testset "Env" begin
    @testset "User-provided" begin
        env = CPLEX.Env()
        model_1 = CPLEX.Optimizer(env)
        @test model_1.inner.env === env
        model_2 = CPLEX.Optimizer(env)
        @test model_2.inner.env === env
        # Check that finalizer doesn't touch env when manually provided.
        finalize(model_1.inner)
        @test CPLEX.is_valid(env)
    end
    @testset "Automatic" begin
        model_1 = CPLEX.Optimizer()
        model_2 = CPLEX.Optimizer()
        @test model_1.inner.env !== model_2.inner.env
    end
    @testset "Env when emptied" begin
        @testset "User-provided" begin
            env = CPLEX.Env()
            model = CPLEX.Optimizer(env)
            @test model.inner.env === env
            @test CPLEX.is_valid(env)
            MOI.empty!(model)
            @test model.inner.env === env
            @test CPLEX.is_valid(env)
        end
        @testset "Automatic" begin
            model = CPLEX.Optimizer()
            env = model.inner.env
            MOI.empty!(model)
            @test model.inner.env !== env
            @test CPLEX.is_valid(model.inner.env)
        end
    end
end

@testset "Continuous -> Integer -> Continuous" begin
    atol = 1e-5
    rtol = 1e-5

    model = CPLEX.Optimizer(CPX_PARAM_SCRIND = 0)
    MOI.empty!(model)
    @test MOI.is_empty(model)

    # min -x
    # st   x + y <= 1.5   (x + y - 1.5 ∈ Nonpositives)
    #       x, y >= 0   (x, y ∈ Nonnegatives)

    v = MOI.add_variables(model, 2)
    @test MOI.get(model, MOI.NumberOfVariables()) == 2

    cf = MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1.0,1.0], v), 0.0)
    c = MOI.add_constraint(model, cf, MOI.LessThan(1.5))
    @test MOI.get(model, MOI.NumberOfConstraints{MOI.ScalarAffineFunction{Float64},MOI.LessThan{Float64}}()) == 1

    vc1 = MOI.add_constraint(model, MOI.SingleVariable(v[1]), MOI.GreaterThan(0.0))
    vc2 = MOI.add_constraint(model, MOI.SingleVariable(v[2]), MOI.GreaterThan(0.0))
    @test MOI.get(model, MOI.NumberOfConstraints{MOI.SingleVariable,MOI.GreaterThan{Float64}}()) == 2

    objf = MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([-1.0,0.0], v), 0.0)
    MOI.set(model, MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), objf)
    MOI.set(model, MOI.ObjectiveSense(), MOI.MIN_SENSE)

    @test MOI.get(model, MOI.ObjectiveSense()) == MOI.MIN_SENSE
    @test MOI.get(model, MOI.TerminationStatus()) == MOI.OPTIMIZE_NOT_CALLED

    MOI.optimize!(model)

    @test MOI.get(model, MOI.TerminationStatus()) == MOI.OPTIMAL
    @test MOI.get(model, MOI.PrimalStatus()) == MOI.FEASIBLE_POINT
    @test MOI.get(model, MOI.ObjectiveValue()) ≈ -1.5 atol=atol rtol=rtol
    @test MOI.get(model, MOI.VariablePrimal(), v) ≈ [1.5, 0] atol=atol rtol=rtol
    @test MOI.get(model, MOI.ConstraintPrimal(), c) ≈ 1.5 atol=atol rtol=rtol

    # Add integrality constraints
    int1 = MOI.add_constraint(model, MOI.SingleVariable(v[1]), MOI.Integer())
    int2 = MOI.add_constraint(model, MOI.SingleVariable(v[2]), MOI.Integer())
    MOI.optimize!(model)
    @test MOI.get(model, MOI.ObjectiveValue()) ≈ -1.0 atol=atol rtol=rtol

    # Remove integrality constraints
    MOI.delete(model, int1)
    MOI.delete(model, int2)
    MOI.optimize!(model)
    @test MOI.get(model, MOI.ObjectiveValue()) ≈ -1.5 atol=atol rtol=rtol
end
