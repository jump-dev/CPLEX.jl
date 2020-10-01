module TestMOIwrapper

using CPLEX
using MathOptInterface
using Test

const MOI  = MathOptInterface
const MOIT = MOI.Test
const MOIB = MOI.Bridges

const CONFIG = MOIT.TestConfig()

const OPTIMIZER = CPLEX.Optimizer()
MOI.set(OPTIMIZER, MOI.Silent(), true)
const BRIDGED_OPTIMIZER = MOI.Bridges.full_bridge_optimizer(OPTIMIZER, Float64)

const CERTIFICATE_OPTIMIZER = CPLEX.Optimizer()
MOI.set(CERTIFICATE_OPTIMIZER, MOI.Silent(), true)
MOI.set(CERTIFICATE_OPTIMIZER, MOI.RawParameter("CPX_PARAM_REDUCE"), 0)
MOI.set(CERTIFICATE_OPTIMIZER, MOI.RawParameter("CPX_PARAM_PRELINEAR"), 0)
const BRIDGED_CERTIFICATE_OPTIMIZER =
    MOI.Bridges.full_bridge_optimizer(CERTIFICATE_OPTIMIZER, Float64)

function test_basic_constraint_tests()
    MOIT.basic_constraint_tests(BRIDGED_OPTIMIZER, CONFIG; exclude = [
        (MOI.VectorOfVariables, MOI.SecondOrderCone),
        (MOI.VectorOfVariables, MOI.RotatedSecondOrderCone),
        (MOI.VectorOfVariables, MOI.GeometricMeanCone),
        (MOI.VectorAffineFunction{Float64}, MOI.SecondOrderCone),
        (MOI.VectorAffineFunction{Float64}, MOI.RotatedSecondOrderCone),
        (MOI.VectorAffineFunction{Float64}, MOI.GeometricMeanCone),
        (MOI.VectorQuadraticFunction{Float64}, MOI.SecondOrderCone),
        (MOI.VectorQuadraticFunction{Float64}, MOI.RotatedSecondOrderCone),
        (MOI.VectorQuadraticFunction{Float64}, MOI.GeometricMeanCone),
        (MOI.VectorAffineFunction{Float64}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.LessThan{Float64}}),
        (MOI.VectorAffineFunction{Float64}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE, MOI.GreaterThan{Float64}}),
    ])
    # TODO(odow): bugs deleting SOC variables. See also the
    # `delete_soc_variables` test.
    MOIT.basic_constraint_tests(
        BRIDGED_OPTIMIZER,
        CONFIG;
        include = [
            (MOI.VectorOfVariables, MOI.SecondOrderCone),
            (MOI.VectorOfVariables, MOI.RotatedSecondOrderCone),
            (MOI.VectorOfVariables, MOI.GeometricMeanCone),
            (MOI.VectorAffineFunction{Float64}, MOI.SecondOrderCone),
            (MOI.VectorAffineFunction{Float64}, MOI.RotatedSecondOrderCone),
            (MOI.VectorAffineFunction{Float64}, MOI.GeometricMeanCone),
            (MOI.VectorQuadraticFunction{Float64}, MOI.SecondOrderCone),
            (MOI.VectorQuadraticFunction{Float64}, MOI.RotatedSecondOrderCone),
            (MOI.VectorQuadraticFunction{Float64}, MOI.GeometricMeanCone),
            (MOI.VectorAffineFunction{Float64}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE,MOI.LessThan{Float64}}),
            (MOI.VectorAffineFunction{Float64}, MOI.IndicatorSet{MOI.ACTIVATE_ON_ONE,MOI.GreaterThan{Float64}}),
        ],
        delete = false
    )
end

function test_unittest()
    MOIT.unittest(BRIDGED_OPTIMIZER, CONFIG, [
        # TODO(odow): bug! We can't delete a vector of variables  if one is in
        # a second order cone.
        "delete_soc_variables",

        # CPLEX returns INFEASIBLE_OR_UNBOUNDED without extra parameters.
        # See below for the test.
        "solve_unbounded_model",
    ])
    MOIT.solve_unbounded_model(CERTIFICATE_OPTIMIZER, CONFIG)
end

function test_modificationtest()
    MOIT.modificationtest(BRIDGED_OPTIMIZER, CONFIG)
end

function test_contlineartest()
    MOIT.contlineartest(BRIDGED_OPTIMIZER, CONFIG, [
        # These tests require extra parameters to be set.
        "linear8a", "linear8b", "linear8c",

        # TODO(odow): This test requests the infeasibility certificate of a
        # variable bound.
        "linear12"
    ])

    MOIT.linear8atest(CERTIFICATE_OPTIMIZER, CONFIG)
    MOIT.linear8btest(CERTIFICATE_OPTIMIZER, CONFIG)
    MOIT.linear8ctest(CERTIFICATE_OPTIMIZER, CONFIG)

    MOIT.linear12test(OPTIMIZER, MOIT.TestConfig(infeas_certificates=false))
end

function test_intlineartest()
    # interval somehow needed for indicator tests
    interval_optimizer = MOIB.LazyBridgeOptimizer(OPTIMIZER)
    MOIB.add_bridge(interval_optimizer, MOIB.Constraint.SplitIntervalBridge{Float64})
    MOIT.intlineartest(BRIDGED_OPTIMIZER, CONFIG)
    MOIT.intlineartest(interval_optimizer, CONFIG)
end

function test_contquadratictest()
    MOIT.contquadratictest(
        BRIDGED_CERTIFICATE_OPTIMIZER,
        # TODO(odow): duals for quadratic problems.
        MOIT.TestConfig(duals = false, atol = 1e-3, rtol = 1e-3),
        ["ncqcp"], # CPLEX doesn't support non-convex problems
    )
end

function test_contconic()
    MOIT.lintest(BRIDGED_OPTIMIZER, CONFIG, [
        # These tests require extra parameters to be set.
        "lin3", "lin4"
    ])

    MOIT.lin3test(BRIDGED_CERTIFICATE_OPTIMIZER, CONFIG)
    MOIT.lin4test(BRIDGED_CERTIFICATE_OPTIMIZER, CONFIG)

    # TODO(odow): duals for SOC constraints.
    soc_config = MOIT.TestConfig(duals = false, atol=5e-3)

    MOIT.soctest(BRIDGED_OPTIMIZER, soc_config, [
        "soc3"
    ])

    MOIT.soc3test(
        BRIDGED_OPTIMIZER,
        MOIT.TestConfig(duals = false, infeas_certificates = false, atol = 1e-3)
    )

    MOIT.rsoctest(BRIDGED_OPTIMIZER, soc_config)

    MOIT.geomeantest(BRIDGED_OPTIMIZER, soc_config)
end

function test_solvername()
    @test MOI.get(BRIDGED_OPTIMIZER, MOI.SolverName()) == "CPLEX"
end

function test_default_objective_test()
    MOIT.default_objective_test(BRIDGED_OPTIMIZER)
end

function test_default_status_test()
    MOIT.default_status_test(BRIDGED_OPTIMIZER)
end

function test_nametest()
    MOIT.nametest(BRIDGED_OPTIMIZER)
end

function test_validtest()
    MOIT.validtest(BRIDGED_OPTIMIZER)
end

function test_emptytest()
    MOIT.emptytest(BRIDGED_OPTIMIZER)
end

function test_orderedindicestest()
    MOIT.orderedindicestest(BRIDGED_OPTIMIZER)
end

function test_copytest()
    MOIT.copytest(
        BRIDGED_OPTIMIZER,
        MOI.Bridges.full_bridge_optimizer(CPLEX.Optimizer(), Float64)
    )
end

function test_scalar_function_constant_not_zero()
    MOIT.scalar_function_constant_not_zero(OPTIMIZER)
end

function test_start_values_test()
    model = CPLEX.Optimizer()
    x = MOI.add_variables(model, 2)
    @test MOI.supports(model, MOI.VariablePrimalStart(), MOI.VariableIndex)
    @test MOI.get(model, MOI.VariablePrimalStart(), x[1]) === nothing
    @test MOI.get(model, MOI.VariablePrimalStart(), x[2]) === nothing
    MOI.set(model, MOI.VariablePrimalStart(), x[1], 1.0)
    MOI.set(model, MOI.VariablePrimalStart(), x[2], nothing)
    @test MOI.get(model, MOI.VariablePrimalStart(), x[1]) == 1.0
    @test MOI.get(model, MOI.VariablePrimalStart(), x[2]) === nothing
    MOI.optimize!(model)
    @test MOI.get(model, MOI.ObjectiveValue()) == 0.0
end

function test_supports_constrainttest()
    # supports_constrainttest needs VectorOfVariables-in-Zeros,
    # MOIT.supports_constrainttest(CPLEX.Optimizer(), Float64, Float32)
    # but supports_constrainttest is broken via bridges:
    MOI.empty!(BRIDGED_OPTIMIZER)
    MOI.add_variable(BRIDGED_OPTIMIZER)
    @test  MOI.supports_constraint(BRIDGED_OPTIMIZER, MOI.SingleVariable, MOI.EqualTo{Float64})
    @test  MOI.supports_constraint(BRIDGED_OPTIMIZER, MOI.ScalarAffineFunction{Float64}, MOI.EqualTo{Float64})
    # This test is broken for some reason:
    @test_broken !MOI.supports_constraint(BRIDGED_OPTIMIZER, MOI.ScalarAffineFunction{Int}, MOI.EqualTo{Float64})
    @test !MOI.supports_constraint(BRIDGED_OPTIMIZER, MOI.ScalarAffineFunction{Int}, MOI.EqualTo{Int})
    @test !MOI.supports_constraint(BRIDGED_OPTIMIZER, MOI.SingleVariable, MOI.EqualTo{Int})
    @test  MOI.supports_constraint(BRIDGED_OPTIMIZER, MOI.VectorOfVariables, MOI.Zeros)
    @test !MOI.supports_constraint(BRIDGED_OPTIMIZER, MOI.VectorOfVariables, MOI.EqualTo{Float64})
    @test !MOI.supports_constraint(BRIDGED_OPTIMIZER, MOI.SingleVariable, MOI.Zeros)
    @test !MOI.supports_constraint(BRIDGED_OPTIMIZER, MOI.VectorOfVariables, MOIT.UnknownVectorSet)
end

function test_set_lower_bound_twice()
    MOIT.set_lower_bound_twice(OPTIMIZER, Float64)
end

function test_set_upper_bound_twice()
    MOIT.set_upper_bound_twice(OPTIMIZER, Float64)
end

function test_user_provided_env()
    env = CPLEX.Env()
    model_1 = CPLEX.Optimizer(env)
    @test model_1.env === env
    model_2 = CPLEX.Optimizer(env)
    @test model_2.env === env
    # Check that finalizer doesn't touch env when manually provided.
    finalize(model_1)
    @test env.ptr != C_NULL
end

function test_automatic_env()
    model_1 = CPLEX.Optimizer()
    model_2 = CPLEX.Optimizer()
    @test model_1.env.ptr !== model_2.env.ptr
end

function test_user_provided_env_empty()
    env = CPLEX.Env()
    model = CPLEX.Optimizer(env)
    @test model.env === env
    @test env.ptr != C_NULL
    MOI.empty!(model)
    @test model.env === env
    @test env.ptr != C_NULL
end

function test_automatic_env_empty()
    model = CPLEX.Optimizer()
    env = model.env
    MOI.empty!(model)
    @test model.env === env
    @test env.ptr != C_NULL
end

function test_manual_env()
    env = CPLEX.Env()
    model = CPLEX.Optimizer(env)
    finalize(env)
    @test env.finalize_called
    finalize(model)
    @test env.ptr == C_NULL
end

function test_cont_int_cont()
    atol = 1e-5
    rtol = 1e-5

    model = CPLEX.Optimizer()
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
    @test MOI.get(model, MOI.DualStatus()) == MOI.FEASIBLE_POINT
    @test MOI.get(model, MOI.ConstraintDual(), c) ≈ -1.0 atol=atol rtol=rtol

    # Add integrality constraints
    int = MOI.add_constraint.(model, MOI.SingleVariable.(v), MOI.Integer())
    MOI.optimize!(model)
    @test MOI.get(model, MOI.TerminationStatus()) == MOI.OPTIMAL
    @test MOI.get(model, MOI.PrimalStatus()) == MOI.FEASIBLE_POINT
    @test MOI.get(model, MOI.ObjectiveValue()) ≈ -1.0 atol=atol rtol=rtol
    @test MOI.get(model, MOI.VariablePrimal(), v) ≈ [1.0, 0] atol=atol rtol=rtol
    @test MOI.get(model, MOI.ConstraintPrimal(), c) ≈ 1.0 atol=atol rtol=rtol
    @test MOI.get(model, MOI.DualStatus()) == MOI.NO_SOLUTION

    # Remove integrality constraints
    MOI.delete.(model, int)
    MOI.optimize!(model)
    @test MOI.get(model, MOI.TerminationStatus()) == MOI.OPTIMAL
    @test MOI.get(model, MOI.PrimalStatus()) == MOI.FEASIBLE_POINT
    @test MOI.get(model, MOI.ObjectiveValue()) ≈ -1.5 atol=atol rtol=rtol
    @test MOI.get(model, MOI.VariablePrimal(), v) ≈ [1.5, 0] atol=atol rtol=rtol
    @test MOI.get(model, MOI.ConstraintPrimal(), c) ≈ 1.5 atol=atol rtol=rtol
    @test MOI.get(model, MOI.DualStatus()) == MOI.FEASIBLE_POINT
    @test MOI.get(model, MOI.ConstraintDual(), c) ≈ -1.0 atol=atol rtol=rtol
end

function test_conflict_bounds()
    # @testset "Variable bounds (SingleVariable and LessThan/GreaterThan)" begin
    # Test similar to ../C_API/iis.jl, but ported to MOI.
    model = CPLEX.Optimizer()
    x = MOI.add_variable(model)
    c1 = MOI.add_constraint(model, MOI.SingleVariable(x), MOI.GreaterThan(2.0))
    c2 = MOI.add_constraint(model, MOI.SingleVariable(x), MOI.LessThan(1.0))

    # Getting the results before the conflict refiner has been called must return an error.
    @test MOI.get(model, CPLEX.ConflictStatus()) === nothing
    @test MOI.get(model, MOI.ConflictStatus()) == MOI.COMPUTE_CONFLICT_NOT_CALLED
    @test_throws ErrorException MOI.get(model, MOI.ConstraintConflictStatus(), c1)

    # Once it's called, no problem.
    MOI.compute_conflict!(model)
    @test MOI.get(model, CPLEX.ConflictStatus()) == CPLEX.CPX_STAT_CONFLICT_MINIMAL
    @test MOI.get(model, MOI.ConflictStatus()) == MOI.CONFLICT_FOUND
    @test MOI.get(model, MOI.ConstraintConflictStatus(), c1) == MOI.IN_CONFLICT
    @test MOI.get(model, MOI.ConstraintConflictStatus(), c2) == MOI.IN_CONFLICT
end

function test_conflict_scalaraffine()
    # @testset "Variable bounds (ScalarAffine)" begin
    # Same test as ../C_API/iis.jl, but ported to MOI.
    model = CPLEX.Optimizer()
    x = MOI.add_variable(model)
    c1 = MOI.add_constraint(model, MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1.0], [x]), 0.0), MOI.GreaterThan(2.0))
    c2 = MOI.add_constraint(model, MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1.0], [x]), 0.0), MOI.LessThan(1.0))

    # Getting the results before the conflict refiner has been called must return an error.
    @test MOI.get(model, CPLEX.ConflictStatus()) === nothing
    @test MOI.get(model, MOI.ConflictStatus()) == MOI.COMPUTE_CONFLICT_NOT_CALLED
    @test_throws ErrorException MOI.get(model, MOI.ConstraintConflictStatus(), c1)

    # Once it's called, no problem.
    MOI.compute_conflict!(model)
    @test MOI.get(model, CPLEX.ConflictStatus()) == CPLEX.CPX_STAT_CONFLICT_MINIMAL
    @test MOI.get(model, MOI.ConflictStatus()) == MOI.CONFLICT_FOUND
    @test MOI.get(model, MOI.ConstraintConflictStatus(), c1) == MOI.IN_CONFLICT
    @test MOI.get(model, MOI.ConstraintConflictStatus(), c2) == MOI.IN_CONFLICT
end

function test_conflict_two_bound()
    model = CPLEX.Optimizer()
    x = MOI.add_variable(model)
    y = MOI.add_variable(model)
    b1 = MOI.add_constraint(model, MOI.SingleVariable(x), MOI.GreaterThan(0.0))
    b2 = MOI.add_constraint(model, MOI.SingleVariable(y), MOI.GreaterThan(0.0))
    cf1 = MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1.0, 1.0], [x, y]), 0.0)
    c1 = MOI.add_constraint(model, cf1, MOI.LessThan(-1.0))
    cf2 = MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1.0, -1.0], [x, y]), 0.0)
    c2 = MOI.add_constraint(model, cf2, MOI.GreaterThan(1.0))

    # Getting the results before the conflict refiner has been called must return an error.
    @test MOI.get(model, CPLEX.ConflictStatus()) === nothing
    @test MOI.get(model, MOI.ConflictStatus()) == MOI.COMPUTE_CONFLICT_NOT_CALLED
    @test_throws ErrorException MOI.get(model, MOI.ConstraintConflictStatus(), c1)

    # Once it's called, no problem.
    MOI.compute_conflict!(model)
    @test MOI.get(model, CPLEX.ConflictStatus()) == CPLEX.CPX_STAT_CONFLICT_MINIMAL
    @test MOI.get(model, MOI.ConflictStatus()) == MOI.CONFLICT_FOUND
    @test MOI.get(model, MOI.ConstraintConflictStatus(), b1) == MOI.IN_CONFLICT
    @test MOI.get(model, MOI.ConstraintConflictStatus(), b2) == MOI.IN_CONFLICT
    @test MOI.get(model, MOI.ConstraintConflictStatus(), c1) == MOI.IN_CONFLICT
    @test MOI.get(model, MOI.ConstraintConflictStatus(), c2) == MOI.NOT_IN_CONFLICT
end

function test_conflict_two_equalto()
    model = CPLEX.Optimizer()
    x = MOI.add_variable(model)
    y = MOI.add_variable(model)
    b1 = MOI.add_constraint(model, MOI.SingleVariable(x), MOI.GreaterThan(0.0))
    b2 = MOI.add_constraint(model, MOI.SingleVariable(y), MOI.GreaterThan(0.0))
    cf1 = MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1.0, 1.0], [x, y]), 0.0)
    c1 = MOI.add_constraint(model, cf1, MOI.EqualTo(-1.0))
    cf2 = MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1.0, -1.0], [x, y]), 0.0)
    c2 = MOI.add_constraint(model, cf2, MOI.GreaterThan(1.0))

    # Getting the results before the conflict refiner has been called must return an error.
    @test MOI.get(model, CPLEX.ConflictStatus()) === nothing
    @test MOI.get(model, MOI.ConflictStatus()) == MOI.COMPUTE_CONFLICT_NOT_CALLED
    @test_throws ErrorException MOI.get(model, MOI.ConstraintConflictStatus(), c1)

    # Once it's called, no problem.
    MOI.compute_conflict!(model)
    @test MOI.get(model, CPLEX.ConflictStatus()) == CPLEX.CPX_STAT_CONFLICT_MINIMAL
    @test MOI.get(model, MOI.ConflictStatus()) == MOI.CONFLICT_FOUND
    @test MOI.get(model, MOI.ConstraintConflictStatus(), b1) == MOI.IN_CONFLICT
    @test MOI.get(model, MOI.ConstraintConflictStatus(), b2) == MOI.IN_CONFLICT
    @test MOI.get(model, MOI.ConstraintConflictStatus(), c1) == MOI.IN_CONFLICT
    @test MOI.get(model, MOI.ConstraintConflictStatus(), c2) == MOI.NOT_IN_CONFLICT
end

function test_conflict_variables_outside()
    model = CPLEX.Optimizer()
    x = MOI.add_variable(model)
    y = MOI.add_variable(model)
    z = MOI.add_variable(model)
    b1 = MOI.add_constraint(model, MOI.SingleVariable(x), MOI.GreaterThan(0.0))
    b2 = MOI.add_constraint(model, MOI.SingleVariable(y), MOI.GreaterThan(0.0))
    b3 = MOI.add_constraint(model, MOI.SingleVariable(z), MOI.GreaterThan(0.0))
    cf1 = MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1.0, 1.0], [x, y]), 0.0)
    c1 = MOI.add_constraint(model, cf1, MOI.LessThan(-1.0))
    cf2 = MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1.0, -1.0, 1.0], [x, y, z]), 0.0)
    c2 = MOI.add_constraint(model, cf2, MOI.GreaterThan(1.0))

    # Getting the results before the conflict refiner has been called must return an error.
    @test MOI.get(model, CPLEX.ConflictStatus()) === nothing
    @test MOI.get(model, MOI.ConflictStatus()) == MOI.COMPUTE_CONFLICT_NOT_CALLED
    @test_throws ErrorException MOI.get(model, MOI.ConstraintConflictStatus(), c1)

    # Once it's called, no problem.
    MOI.compute_conflict!(model)
    @test MOI.get(model, CPLEX.ConflictStatus()) == CPLEX.CPX_STAT_CONFLICT_MINIMAL
    @test MOI.get(model, MOI.ConflictStatus()) == MOI.CONFLICT_FOUND
    @test MOI.get(model, MOI.ConstraintConflictStatus(), b1) == MOI.IN_CONFLICT
    @test MOI.get(model, MOI.ConstraintConflictStatus(), b2) == MOI.IN_CONFLICT
    @test MOI.get(model, MOI.ConstraintConflictStatus(), b3) == MOI.NOT_IN_CONFLICT
    @test MOI.get(model, MOI.ConstraintConflictStatus(), c1) == MOI.IN_CONFLICT
    @test MOI.get(model, MOI.ConstraintConflictStatus(), c2) == MOI.NOT_IN_CONFLICT
end

function test_conflict_no_conflict()
    model = CPLEX.Optimizer()
    x = MOI.add_variable(model)
    c1 = MOI.add_constraint(model, MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1.0], [x]), 0.0), MOI.GreaterThan(1.0))
    c2 = MOI.add_constraint(model, MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1.0], [x]), 0.0), MOI.LessThan(2.0))

    # Getting the results before the conflict refiner has been called must return an error.
    @test MOI.get(model, CPLEX.ConflictStatus()) === nothing
    @test MOI.get(model, MOI.ConflictStatus()) == MOI.COMPUTE_CONFLICT_NOT_CALLED
    @test_throws ErrorException MOI.get(model, MOI.ConstraintConflictStatus(), c1)

    # Once it's called, no problem.
    MOI.compute_conflict!(model)
    @test MOI.get(model, CPLEX.ConflictStatus()) == CPLEX.CPX_STAT_CONFLICT_FEASIBLE
    @test MOI.get(model, MOI.ConflictStatus()) == MOI.NO_CONFLICT_EXISTS
    @test MOI.get(model, MOI.ConstraintConflictStatus(), c1) == MOI.NOT_IN_CONFLICT
    @test MOI.get(model, MOI.ConstraintConflictStatus(), c2) == MOI.NOT_IN_CONFLICT
end

end  # module TestMOIwrapper

runtests(TestMOIwrapper)
