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
	
@testset "Issue 229" begin
    model = CPLEX.Optimizer()
    @test haskey(model.params, "CPX_PARAM_SCRIND")
    @test model.params["CPX_PARAM_SCRIND"] == 1

    model = CPLEX.Optimizer(CPX_PARAM_SCRIND=0)
    @test haskey(model.params, "CPX_PARAM_SCRIND")
    @test model.params["CPX_PARAM_SCRIND"] == 0

    model = CPLEX.Optimizer(CPXPARAM_ScreenOutput=0)
    @test !haskey(model.params, "CPX_PARAM_SCRIND")
    @test haskey(model.params, "CPXPARAM_ScreenOutput")
end

@testset "Conflict refiner" begin
    @testset "Variable bounds (SingleVariable and LessThan/GreaterThan)" begin
        # Test similar to ../C_API/iis.jl, but ported to MOI.
        model = CPLEX.Optimizer()
        x = MOI.add_variable(model)
        c1 = MOI.add_constraint(model, MOI.SingleVariable(x), MOI.GreaterThan(2.0))
        c2 = MOI.add_constraint(model, MOI.SingleVariable(x), MOI.LessThan(1.0))

        # Getting the results before the conflict refiner has been called must return an error.
        @test MOI.get(model, CPLEX.ConflictStatus()) == MOI.OPTIMIZE_NOT_CALLED
        @test_throws ErrorException MOI.get(model, CPLEX.ConstraintConflictStatus(), c1)

        # Once it's called, no problem.
        CPLEX.compute_conflict(model)
        @test MOI.get(model, CPLEX.ConflictStatus()) == MOI.OPTIMAL
        @test MOI.get(model, CPLEX.ConstraintConflictStatus(), c1) == true
        @test MOI.get(model, CPLEX.ConstraintConflictStatus(), c2) == true
    end

    @testset "Variable bounds (ScalarAffine)" begin
        # Same test as ../C_API/iis.jl, but ported to MOI.
        model = CPLEX.Optimizer()
        x = MOI.add_variable(model)
        c1 = MOI.add_constraint(model, MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1.0], [x]), 0.0), MOI.GreaterThan(2.0))
        c2 = MOI.add_constraint(model, MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1.0], [x]), 0.0), MOI.LessThan(1.0))

        # Getting the results before the conflict refiner has been called must return an error.
        @test MOI.get(model, CPLEX.ConflictStatus()) == MOI.OPTIMIZE_NOT_CALLED
        @test_throws ErrorException MOI.get(model, CPLEX.ConstraintConflictStatus(), c1)

        # Once it's called, no problem.
        CPLEX.compute_conflict(model)
        @test MOI.get(model, CPLEX.ConflictStatus()) == MOI.OPTIMAL
        @test MOI.get(model, CPLEX.ConstraintConflictStatus(), c1) == true
        @test MOI.get(model, CPLEX.ConstraintConflictStatus(), c2) == true
    end

    @testset "Variable fixing (SingleVariable and EqualTo)" begin
        model = CPLEX.Optimizer()
        x = MOI.add_variable(model)
        c1 = MOI.add_constraint(model, MOI.SingleVariable(x), MOI.EqualTo(1.0))
        c2 = MOI.add_constraint(model, MOI.SingleVariable(x), MOI.GreaterThan(2.0))

        # Getting the results before the conflict refiner has been called must return an error. 
        @test MOI.get(model, CPLEX.ConflictStatus()) == MOI.OPTIMIZE_NOT_CALLED
        @test_throws ErrorException MOI.get(model, CPLEX.ConstraintConflictStatus(), c1)

        # Once it's called, no problem. 
        CPLEX.compute_conflict(model)
        @test MOI.get(model, CPLEX.ConflictStatus()) == MOI.OPTIMAL
        @test MOI.get(model, CPLEX.ConstraintConflictStatus(), c1) == true
        @test MOI.get(model, CPLEX.ConstraintConflictStatus(), c2) == true
    end

    @testset "Variable bounds (SingleVariable and Interval)" begin
        model = CPLEX.Optimizer()
        x = MOI.add_variable(model)
        c1 = MOI.add_constraint(model, MOI.SingleVariable(x), MOI.Interval(1.0, 3.0))
        c2 = MOI.add_constraint(model, MOI.SingleVariable(x), MOI.LessThan(0.0))

        # Getting the results before the conflict refiner has been called must return an error.
        @test MOI.get(model, CPLEX.ConflictStatus()) == MOI.OPTIMIZE_NOT_CALLED
        @test_throws ErrorException MOI.get(model, CPLEX.ConstraintConflictStatus(), c1)

        # Once it's called, no problem.
        CPLEX.compute_conflict(model)
        @test MOI.get(model, CPLEX.ConflictStatus()) == MOI.OPTIMAL
        @test MOI.get(model, CPLEX.ConstraintConflictStatus(), c1) == true
        @test MOI.get(model, CPLEX.ConstraintConflictStatus(), c2) == true
    end

    @testset "Two conflicting constraints (GreaterThan, LessThan)" begin
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
        @test MOI.get(model, CPLEX.ConflictStatus()) == MOI.OPTIMIZE_NOT_CALLED
        @test_throws ErrorException MOI.get(model, CPLEX.ConstraintConflictStatus(), c1)

        # Once it's called, no problem.
        CPLEX.compute_conflict(model)
        @test MOI.get(model, CPLEX.ConflictStatus()) == MOI.OPTIMAL
        @test MOI.get(model, CPLEX.ConstraintConflictStatus(), b1) == true
        @test MOI.get(model, CPLEX.ConstraintConflictStatus(), b2) == true
        @test MOI.get(model, CPLEX.ConstraintConflictStatus(), c1) == true
        @test MOI.get(model, CPLEX.ConstraintConflictStatus(), c2) == false
    end

    @testset "Two conflicting constraints (EqualTo)" begin
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
        @test MOI.get(model, CPLEX.ConflictStatus()) == MOI.OPTIMIZE_NOT_CALLED
        @test_throws ErrorException MOI.get(model, CPLEX.ConstraintConflictStatus(), c1)

        # Once it's called, no problem. 
        CPLEX.compute_conflict(model)
        @test MOI.get(model, CPLEX.ConflictStatus()) == MOI.OPTIMAL
        @test MOI.get(model, CPLEX.ConstraintConflictStatus(), b1) == true
        @test MOI.get(model, CPLEX.ConstraintConflictStatus(), b2) == true
        @test MOI.get(model, CPLEX.ConstraintConflictStatus(), c1) == true
        @test MOI.get(model, CPLEX.ConstraintConflictStatus(), c2) == false
    end

    @testset "Variables outside conflict" begin
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
        @test MOI.get(model, CPLEX.ConflictStatus()) == MOI.OPTIMIZE_NOT_CALLED
        @test_throws ErrorException MOI.get(model, CPLEX.ConstraintConflictStatus(), c1)

        # Once it's called, no problem.
        CPLEX.compute_conflict(model)
        @test MOI.get(model, CPLEX.ConflictStatus()) == MOI.OPTIMAL
        @test MOI.get(model, CPLEX.ConstraintConflictStatus(), b1) == true
        @test MOI.get(model, CPLEX.ConstraintConflictStatus(), b2) == true
        @test MOI.get(model, CPLEX.ConstraintConflictStatus(), b3) == false
        @test MOI.get(model, CPLEX.ConstraintConflictStatus(), c1) == true
        @test MOI.get(model, CPLEX.ConstraintConflictStatus(), c2) == false
    end

    @testset "No conflict" begin
        model = CPLEX.Optimizer()
        x = MOI.add_variable(model)
        c1 = MOI.add_constraint(model, MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1.0], [x]), 0.0), MOI.GreaterThan(1.0))
        c2 = MOI.add_constraint(model, MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1.0], [x]), 0.0), MOI.LessThan(2.0))

        # Getting the results before the conflict refiner has been called must return an error. 
        @test MOI.get(model, CPLEX.ConflictStatus()) == MOI.OPTIMIZE_NOT_CALLED
        @test_throws ErrorException MOI.get(model, CPLEX.ConstraintConflictStatus(), c1)

        # Once it's called, no problem. 
        CPLEX.compute_conflict(model)
        @test MOI.get(model, CPLEX.ConflictStatus()) == MOI.INFEASIBLE
        @test MOI.get(model, CPLEX.ConstraintConflictStatus(), c1) == false
        @test MOI.get(model, CPLEX.ConstraintConflictStatus(), c2) == false
    end
end
