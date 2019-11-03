using CPLEX
using MathOptInterface
using Test

const MOI  = MathOptInterface
const MOIT = MOI.Test
const MOIB = MOI.Bridges

const CONFIG = MOIT.TestConfig()

const OPTIMIZER = CPLEX.Optimizer()
MOI.set(OPTIMIZER, MOI.RawParameter("CPX_PARAM_SCRIND"), 0)
const SOLVER = MOI.Bridges.full_bridge_optimizer(OPTIMIZER, Float64)

@testset "Unit Tests" begin
    MOIT.basic_constraint_tests(SOLVER, CONFIG)
    MOIT.unittest(SOLVER, CONFIG)
    MOIT.modificationtest(SOLVER, CONFIG)
end

@testset "Linear tests" begin
    @testset "Default Solver"  begin
        MOIT.contlineartest(SOLVER, CONFIG)
    end
end

@testset "Linear Conic" begin
    MOIT.lintest(SOLVER, CONFIG)
end

@testset "Integer Linear tests" begin
    MOIT.intlineartest(SOLVER, CONFIG, [
        # Indicator sets not supported.
        "indicator1", "indicator2", "indicator3"
    ])
end

@testset "Quadratic tests" begin
    MOIT.contquadratictest(
        SOLVER,
        MOIT.TestConfig(atol=1e-3, rtol=1e-3, [
            "ncqcp"  # CPLEX doesn't support non-convex problems
        ])
    )
end

@testset "Conic tests" begin
    MOIT.lintest(SOLVER, CONFIG)
    MOIT.soctest(SOLVER, MOIT.TestConfig(duals = false, atol=1e-3), ["soc3"])
    MOIT.soc3test(
        SOLVER,
        MOIT.TestConfig(duals = false, infeas_certificates = false, atol = 1e-3)
    )
    MOIT.rsoctest(SOLVER, MOIT.TestConfig(duals = false, atol=5e-3))
    MOIT.geomeantest(SOLVER, MOIT.TestConfig(duals = false, atol=1e-3))
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
        MOIT.copytest(
            SOLVER,
            MOI.Bridges.full_bridge_optimizer(CPLEX.Optimizer(), Float64)
        )
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

    model = CPLEX.Optimizer()
    MOI.empty!(model)
    @test MOI.is_empty(model)
    # MOI.set(model, MOI.RawParameter("CPX_PARAM_SCRIND"), 3)
    MOI.set(model, MOI.RawParameter("CPXPARAM_ScreenOutput"), 1)

    # min -x
    # st   x + y <= 1.5   (x + y - 1.5 ∈ Nonpositives)
    #       x, y >= 0   (x, y ∈ Nonnegatives)

    v = MOI.add_variables(model, 2)
    @test MOI.get(model, MOI.NumberOfVariables()) == 2

    cf = MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1.0,1.0], v), 0.0)
    c = MOI.add_constraint(model, cf, MOI.LessThan(1.5))
    @test MOI.get(model, MOI.NumberOfConstraints{MOI.ScalarAffineFunction{Float64},MOI.LessThan{Float64}}()) == 1

    MOI.add_constraint.(model, MOI.SingleVariable.(v), MOI.GreaterThan(0.0))
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
    int = MOI.add_constraint.(model, MOI.SingleVariable.(v), MOI.Integer())
    MOI.optimize!(model)
    @test MOI.get(model, MOI.ObjectiveValue()) ≈ -1.0 atol=atol rtol=rtol

    # Remove integrality constraints
    MOI.delete.(model, int)
    MOI.optimize!(model)
    @test MOI.get(model, MOI.ObjectiveValue()) ≈ -1.5 atol=atol rtol=rtol
end

# TODO
# @testset "Conflict refiner" begin
#     @testset "Variable bounds (SingleVariable and LessThan/GreaterThan)" begin
#         # Test similar to ../C_API/iis.jl, but ported to MOI.
#         model = CPLEX.Optimizer()
#         x = MOI.add_variable(model)
#         c1 = MOI.add_constraint(model, MOI.SingleVariable(x), MOI.GreaterThan(2.0))
#         c2 = MOI.add_constraint(model, MOI.SingleVariable(x), MOI.LessThan(1.0))

#         # Getting the results before the conflict refiner has been called must return an error.
#         @test MOI.get(model, CPLEX.ConflictStatus()) == MOI.OPTIMIZE_NOT_CALLED
#         @test_throws ErrorException MOI.get(model, CPLEX.ConstraintConflictStatus(), c1)

#         # Once it's called, no problem.
#         CPLEX.compute_conflict(model)
#         @test MOI.get(model, CPLEX.ConflictStatus()) == MOI.OPTIMAL
#         @test MOI.get(model, CPLEX.ConstraintConflictStatus(), c1) == true
#         @test MOI.get(model, CPLEX.ConstraintConflictStatus(), c2) == true
#     end

#     @testset "Variable bounds (ScalarAffine)" begin
#         # Same test as ../C_API/iis.jl, but ported to MOI.
#         model = CPLEX.Optimizer()
#         x = MOI.add_variable(model)
#         c1 = MOI.add_constraint(model, MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1.0], [x]), 0.0), MOI.GreaterThan(2.0))
#         c2 = MOI.add_constraint(model, MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1.0], [x]), 0.0), MOI.LessThan(1.0))

#         # Getting the results before the conflict refiner has been called must return an error.
#         @test MOI.get(model, CPLEX.ConflictStatus()) == MOI.OPTIMIZE_NOT_CALLED
#         @test_throws ErrorException MOI.get(model, CPLEX.ConstraintConflictStatus(), c1)

#         # Once it's called, no problem.
#         CPLEX.compute_conflict(model)
#         @test MOI.get(model, CPLEX.ConflictStatus()) == MOI.OPTIMAL
#         @test MOI.get(model, CPLEX.ConstraintConflictStatus(), c1) == true
#         @test MOI.get(model, CPLEX.ConstraintConflictStatus(), c2) == true
#     end

#     @testset "Variable fixing (SingleVariable and EqualTo)" begin
#         model = CPLEX.Optimizer()
#         x = MOI.add_variable(model)
#         c1 = MOI.add_constraint(model, MOI.SingleVariable(x), MOI.EqualTo(1.0))
#         c2 = MOI.add_constraint(model, MOI.SingleVariable(x), MOI.GreaterThan(2.0))

#         # Getting the results before the conflict refiner has been called must return an error.
#         @test MOI.get(model, CPLEX.ConflictStatus()) == MOI.OPTIMIZE_NOT_CALLED
#         @test_throws ErrorException MOI.get(model, CPLEX.ConstraintConflictStatus(), c1)

#         # Once it's called, no problem.
#         CPLEX.compute_conflict(model)
#         @test MOI.get(model, CPLEX.ConflictStatus()) == MOI.OPTIMAL
#         @test MOI.get(model, CPLEX.ConstraintConflictStatus(), c1) == true
#         @test MOI.get(model, CPLEX.ConstraintConflictStatus(), c2) == true
#     end

#     @testset "Variable bounds (SingleVariable and Interval)" begin
#         model = CPLEX.Optimizer()
#         x = MOI.add_variable(model)
#         c1 = MOI.add_constraint(model, MOI.SingleVariable(x), MOI.Interval(1.0, 3.0))
#         c2 = MOI.add_constraint(model, MOI.SingleVariable(x), MOI.LessThan(0.0))

#         # Getting the results before the conflict refiner has been called must return an error.
#         @test MOI.get(model, CPLEX.ConflictStatus()) == MOI.OPTIMIZE_NOT_CALLED
#         @test_throws ErrorException MOI.get(model, CPLEX.ConstraintConflictStatus(), c1)

#         # Once it's called, no problem.
#         CPLEX.compute_conflict(model)
#         @test MOI.get(model, CPLEX.ConflictStatus()) == MOI.OPTIMAL
#         @test MOI.get(model, CPLEX.ConstraintConflictStatus(), c1) == true
#         @test MOI.get(model, CPLEX.ConstraintConflictStatus(), c2) == true
#     end

#     @testset "Two conflicting constraints (GreaterThan, LessThan)" begin
#         model = CPLEX.Optimizer()
#         x = MOI.add_variable(model)
#         y = MOI.add_variable(model)
#         b1 = MOI.add_constraint(model, MOI.SingleVariable(x), MOI.GreaterThan(0.0))
#         b2 = MOI.add_constraint(model, MOI.SingleVariable(y), MOI.GreaterThan(0.0))
#         cf1 = MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1.0, 1.0], [x, y]), 0.0)
#         c1 = MOI.add_constraint(model, cf1, MOI.LessThan(-1.0))
#         cf2 = MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1.0, -1.0], [x, y]), 0.0)
#         c2 = MOI.add_constraint(model, cf2, MOI.GreaterThan(1.0))

#         # Getting the results before the conflict refiner has been called must return an error.
#         @test MOI.get(model, CPLEX.ConflictStatus()) == MOI.OPTIMIZE_NOT_CALLED
#         @test_throws ErrorException MOI.get(model, CPLEX.ConstraintConflictStatus(), c1)

#         # Once it's called, no problem.
#         CPLEX.compute_conflict(model)
#         @test MOI.get(model, CPLEX.ConflictStatus()) == MOI.OPTIMAL
#         @test MOI.get(model, CPLEX.ConstraintConflictStatus(), b1) == true
#         @test MOI.get(model, CPLEX.ConstraintConflictStatus(), b2) == true
#         @test MOI.get(model, CPLEX.ConstraintConflictStatus(), c1) == true
#         @test MOI.get(model, CPLEX.ConstraintConflictStatus(), c2) == false
#     end

#     @testset "Two conflicting constraints (EqualTo)" begin
#         model = CPLEX.Optimizer()
#         x = MOI.add_variable(model)
#         y = MOI.add_variable(model)
#         b1 = MOI.add_constraint(model, MOI.SingleVariable(x), MOI.GreaterThan(0.0))
#         b2 = MOI.add_constraint(model, MOI.SingleVariable(y), MOI.GreaterThan(0.0))
#         cf1 = MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1.0, 1.0], [x, y]), 0.0)
#         c1 = MOI.add_constraint(model, cf1, MOI.EqualTo(-1.0))
#         cf2 = MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1.0, -1.0], [x, y]), 0.0)
#         c2 = MOI.add_constraint(model, cf2, MOI.GreaterThan(1.0))

#         # Getting the results before the conflict refiner has been called must return an error.
#         @test MOI.get(model, CPLEX.ConflictStatus()) == MOI.OPTIMIZE_NOT_CALLED
#         @test_throws ErrorException MOI.get(model, CPLEX.ConstraintConflictStatus(), c1)

#         # Once it's called, no problem.
#         CPLEX.compute_conflict(model)
#         @test MOI.get(model, CPLEX.ConflictStatus()) == MOI.OPTIMAL
#         @test MOI.get(model, CPLEX.ConstraintConflictStatus(), b1) == true
#         @test MOI.get(model, CPLEX.ConstraintConflictStatus(), b2) == true
#         @test MOI.get(model, CPLEX.ConstraintConflictStatus(), c1) == true
#         @test MOI.get(model, CPLEX.ConstraintConflictStatus(), c2) == false
#     end

#     @testset "Variables outside conflict" begin
#         model = CPLEX.Optimizer()
#         x = MOI.add_variable(model)
#         y = MOI.add_variable(model)
#         z = MOI.add_variable(model)
#         b1 = MOI.add_constraint(model, MOI.SingleVariable(x), MOI.GreaterThan(0.0))
#         b2 = MOI.add_constraint(model, MOI.SingleVariable(y), MOI.GreaterThan(0.0))
#         b3 = MOI.add_constraint(model, MOI.SingleVariable(z), MOI.GreaterThan(0.0))
#         cf1 = MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1.0, 1.0], [x, y]), 0.0)
#         c1 = MOI.add_constraint(model, cf1, MOI.LessThan(-1.0))
#         cf2 = MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1.0, -1.0, 1.0], [x, y, z]), 0.0)
#         c2 = MOI.add_constraint(model, cf2, MOI.GreaterThan(1.0))

#         # Getting the results before the conflict refiner has been called must return an error.
#         @test MOI.get(model, CPLEX.ConflictStatus()) == MOI.OPTIMIZE_NOT_CALLED
#         @test_throws ErrorException MOI.get(model, CPLEX.ConstraintConflictStatus(), c1)

#         # Once it's called, no problem.
#         CPLEX.compute_conflict(model)
#         @test MOI.get(model, CPLEX.ConflictStatus()) == MOI.OPTIMAL
#         @test MOI.get(model, CPLEX.ConstraintConflictStatus(), b1) == true
#         @test MOI.get(model, CPLEX.ConstraintConflictStatus(), b2) == true
#         @test MOI.get(model, CPLEX.ConstraintConflictStatus(), b3) == false
#         @test MOI.get(model, CPLEX.ConstraintConflictStatus(), c1) == true
#         @test MOI.get(model, CPLEX.ConstraintConflictStatus(), c2) == false
#     end

#     @testset "No conflict" begin
#         model = CPLEX.Optimizer()
#         x = MOI.add_variable(model)
#         c1 = MOI.add_constraint(model, MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1.0], [x]), 0.0), MOI.GreaterThan(1.0))
#         c2 = MOI.add_constraint(model, MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1.0], [x]), 0.0), MOI.LessThan(2.0))

#         # Getting the results before the conflict refiner has been called must return an error.
#         @test MOI.get(model, CPLEX.ConflictStatus()) == MOI.OPTIMIZE_NOT_CALLED
#         @test_throws ErrorException MOI.get(model, CPLEX.ConstraintConflictStatus(), c1)

#         # Once it's called, no problem.
#         CPLEX.compute_conflict(model)
#         @test MOI.get(model, CPLEX.ConflictStatus()) == MOI.INFEASIBLE
#         @test MOI.get(model, CPLEX.ConstraintConflictStatus(), c1) == false
#         @test MOI.get(model, CPLEX.ConstraintConflictStatus(), c2) == false
#     end
# end
