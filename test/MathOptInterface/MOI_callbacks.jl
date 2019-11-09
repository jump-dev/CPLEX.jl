using CPLEX
using Random
using Test

const MOI = CPLEX.MOI

function callback_simple_model()
    model = CPLEX.Optimizer()
    MOI.set(model, MOI.Silent(), true)
    MOI.set(model, MOI.NumberOfThreads(), 1)
    MOI.set(model, MOI.RawParameter("CPX_PARAM_PREIND"), 0)
    MOI.set(model, MOI.RawParameter("CPX_PARAM_HEURFREQ"), -1)

    MOI.Utilities.loadfromstring!(model, """
        variables: x, y
        maxobjective: y
        c1: x in Integer()
        c2: y in Integer()
        c3: x in Interval(0.0, 2.5)
        c4: y in Interval(0.0, 2.5)
    """)
    x = MOI.get(model, MOI.VariableIndex, "x")
    y = MOI.get(model, MOI.VariableIndex, "y")
    return model, x, y
end

function callback_knapsack_model()
    model = CPLEX.Optimizer()
    MOI.set(model, MOI.Silent(), true)
    MOI.set(model, MOI.NumberOfThreads(), 1)
    MOI.set(model, MOI.RawParameter("CPX_PARAM_PREIND"), 0)
    MOI.set(model, MOI.RawParameter("CPX_PARAM_HEURFREQ"), -1)

    N = 30
    x = MOI.add_variables(model, N)
    MOI.add_constraints(model, MOI.SingleVariable.(x), MOI.ZeroOne())
    MOI.set.(model, MOI.VariablePrimalStart(), x, 0.0)
    Random.seed!(1)
    item_weights, item_values = rand(N), rand(N)
    MOI.add_constraint(
        model,
        MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.(item_weights, x), 0.0),
        MOI.LessThan(10.0)
    )
    MOI.set(
        model,
        MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(),
        MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.(item_values, x), 0.0)
    )
    MOI.set(model, MOI.ObjectiveSense(), MOI.MAX_SENSE)
    return model, x, item_weights
end

@testset "LazyConstraintCallback" begin
    @testset "LazyConstraint" begin
        model, x, y = callback_simple_model()
        lazy_called = false
        MOI.set(model, MOI.LazyConstraintCallback(), cb_data -> begin
            lazy_called = true
            x_val = MOI.get(model, MOI.CallbackVariablePrimal(cb_data), x)
            y_val = MOI.get(model, MOI.CallbackVariablePrimal(cb_data), y)
            if y_val - x_val > 1 + 1e-6
                MOI.submit(
                    model,
                    MOI.LazyConstraint(cb_data),
                    MOI.ScalarAffineFunction{Float64}(
                        MOI.ScalarAffineTerm.([-1.0, 1.0], [x, y]),
                        0.0
                    ),
                    MOI.LessThan{Float64}(1.0)
                )
            elseif y_val + x_val > 3 + 1e-6
                MOI.submit(
                    model,
                    MOI.LazyConstraint(cb_data),
                    MOI.ScalarAffineFunction{Float64}(
                        MOI.ScalarAffineTerm.([1.0, 1.0], [x, y]),
                        0.0
                    ), MOI.LessThan{Float64}(3.0)
                )
            end
        end)
        MOI.optimize!(model)
        @test lazy_called
        @test MOI.get(model, MOI.VariablePrimal(), x) == 1
        @test MOI.get(model, MOI.VariablePrimal(), y) == 2
    end
    @testset "OptimizeInProgress" begin
        model, x, y = callback_simple_model()
        MOI.set(model, MOI.LazyConstraintCallback(), cb_data -> begin
            @test_throws(
                MOI.OptimizeInProgress(MOI.VariablePrimal()),
                MOI.get(model, MOI.VariablePrimal(), x)
            )
            @test_throws(
                MOI.OptimizeInProgress(MOI.ObjectiveValue()),
                MOI.get(model, MOI.ObjectiveValue())
            )
            @test_throws(
                MOI.OptimizeInProgress(MOI.ObjectiveBound()),
                MOI.get(model, MOI.ObjectiveBound())
            )
        end)
        MOI.optimize!(model)
    end
    @testset "UserCut" begin
        model, x, y = callback_simple_model()
        cb = nothing
        MOI.set(model, MOI.LazyConstraintCallback(), cb_data -> begin
            cb = cb_data
            MOI.submit(
                model,
                MOI.UserCut(cb_data),
                MOI.ScalarAffineFunction([MOI.ScalarAffineTerm(1.0, x)], 0.0),
                MOI.LessThan(2.0)
            )
        end)
        @test_throws(
            MOI.InvalidCallbackUsage(
                MOI.LazyConstraintCallback(),
                MOI.UserCut(cb)
            ),
            MOI.optimize!(model)
        )
    end
    @testset "HeuristicSolution" begin
        model, x, y = callback_simple_model()
        cb = nothing
        MOI.set(model, MOI.LazyConstraintCallback(), cb_data -> begin
            cb = cb_data
            MOI.submit(
                model,
                MOI.HeuristicSolution(cb_data),
                [x],
                [2.0]
            )
        end)
        @test_throws(
            MOI.InvalidCallbackUsage(
                MOI.LazyConstraintCallback(),
                MOI.HeuristicSolution(cb)
            ),
            MOI.optimize!(model)
        )
    end
end

@testset "UserCutCallback" begin
    @testset "UserCut" begin
        model, x, item_weights = callback_knapsack_model()
        user_cut_submitted = false
        MOI.set(model, MOI.UserCutCallback(), cb_data -> begin
            terms = MOI.ScalarAffineTerm{Float64}[]
            accumulated = 0.0
            for (i, xi) in enumerate(x)
                if MOI.get(model, MOI.CallbackVariablePrimal(cb_data), xi) > 0.0
                    push!(terms, MOI.ScalarAffineTerm(1.0, xi))
                    accumulated += item_weights[i]
                end
            end
            if accumulated > 10.0
                MOI.submit(
                    model,
                    MOI.UserCut(cb_data),
                    MOI.ScalarAffineFunction{Float64}(terms, 0.0),
                    MOI.LessThan{Float64}(length(terms) - 1)
                )
                user_cut_submitted = true
            end
        end)
        MOI.optimize!(model)
        @test user_cut_submitted
    end
    @testset "LazyConstraint" begin
        model, x, item_weights = callback_knapsack_model()
        cb = nothing
        MOI.set(model, MOI.UserCutCallback(), cb_data -> begin
            cb = cb_data
            MOI.submit(
                model,
                MOI.LazyConstraint(cb_data),
                MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.(1.0, x), 0.0),
                MOI.LessThan(5.0)
            )
        end)
        @test_throws(
            MOI.InvalidCallbackUsage(
                MOI.UserCutCallback(),
                MOI.LazyConstraint(cb)
            ),
            MOI.optimize!(model)
        )
    end
    @testset "HeuristicSolution" begin
        model, x, item_weights = callback_knapsack_model()
        cb = nothing
        MOI.set(model, MOI.UserCutCallback(), cb_data -> begin
            cb = cb_data
            MOI.submit(
                model,
                MOI.HeuristicSolution(cb_data),
                [x[1]],
                [0.0]
            )
        end)
        @test_throws(
            MOI.InvalidCallbackUsage(
                MOI.UserCutCallback(),
                MOI.HeuristicSolution(cb)
            ),
            MOI.optimize!(model)
        )
    end
end

@testset "HeuristicCallback" begin
    @testset "HeuristicSolution" begin
        model, x, item_weights = callback_knapsack_model()
        callback_called = false
        MOI.set(model, MOI.HeuristicCallback(), cb_data -> begin
            x_vals = MOI.get.(model, MOI.CallbackVariablePrimal(cb_data), x)
            @test MOI.submit(
                model,
                MOI.HeuristicSolution(cb_data),
                x,
                floor.(x_vals)
            ) == MOI.HEURISTIC_SOLUTION_UNKNOWN
            callback_called = true
        end)
        MOI.optimize!(model)
        @test callback_called
    end
    @testset "LazyConstraint" begin
        model, x, item_weights = callback_knapsack_model()
        cb = nothing
        MOI.set(model, MOI.HeuristicCallback(), cb_data -> begin
            cb = cb_data
            MOI.submit(
                model,
                MOI.LazyConstraint(cb_data),
                MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.(1.0, x), 0.0),
                MOI.LessThan(5.0)
            )
        end)
        @test_throws(
            MOI.InvalidCallbackUsage(
                MOI.HeuristicCallback(),
                MOI.LazyConstraint(cb)
            ),
            MOI.optimize!(model)
        )
    end
    @testset "UserCut" begin
        model, x, item_weights = callback_knapsack_model()
        cb = nothing
        MOI.set(model, MOI.HeuristicCallback(), cb_data -> begin
            cb = cb_data
            MOI.submit(
                model,
                MOI.UserCut(cb_data),
                MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.(1.0, x), 0.0),
                MOI.LessThan(5.0)
            )
        end)
        @test_throws(
            MOI.InvalidCallbackUsage(
                MOI.HeuristicCallback(),
                MOI.UserCut(cb)
            ),
            MOI.optimize!(model)
        )
    end
end

@testset "CPLEX.CallbackFunction" begin
    @testset "OptimizeInProgress" begin
        model, x, y = callback_simple_model()
        MOI.set(model, CPLEX.CallbackFunction(), (cb_data, cb_where) -> begin
            @test_throws(
                MOI.OptimizeInProgress(MOI.VariablePrimal()),
                MOI.get(model, MOI.VariablePrimal(), x)
            )
            @test_throws(
                MOI.OptimizeInProgress(MOI.ObjectiveValue()),
                MOI.get(model, MOI.ObjectiveValue())
            )
            @test_throws(
                MOI.OptimizeInProgress(MOI.ObjectiveBound()),
                MOI.get(model, MOI.ObjectiveBound())
            )
        end)
        MOI.optimize!(model)
    end
    @testset "LazyConstraint" begin
        model, x, y = callback_simple_model()
        cb_calls = Int32[]
        function callback_function(cb_data::CPLEX.CallbackContext, cb_where)
            push!(cb_calls, cb_where)
            if cb_where != CPLEX.CPX_CALLBACKCONTEXT_CANDIDATE
                return
            end
            CPLEX.callbackgetcandidatepoint(model, cb_data, cb_where)
            x_val = MOI.get(model, MOI.CallbackVariablePrimal(cb_data), x)
            y_val = MOI.get(model, MOI.CallbackVariablePrimal(cb_data), y)
            if y_val - x_val > 1 + 1e-6
                MOI.submit(model, MOI.LazyConstraint(cb_data),
                    MOI.ScalarAffineFunction{Float64}(
                        MOI.ScalarAffineTerm.([-1.0, 1.0], [x, y]),
                        0.0
                    ),
                    MOI.LessThan{Float64}(1.0)
                )
            elseif y_val + x_val > 3 + 1e-6
                MOI.submit(model, MOI.LazyConstraint(cb_data),
                    MOI.ScalarAffineFunction{Float64}(
                        MOI.ScalarAffineTerm.([1.0, 1.0], [x, y]),
                        0.0
                    ),
                    MOI.LessThan{Float64}(3.0)
                )
            end
        end
        MOI.set(model, CPLEX.CallbackFunction(), callback_function)
        MOI.optimize!(model)
        @test MOI.get(model, MOI.VariablePrimal(), x) == 1
        @test MOI.get(model, MOI.VariablePrimal(), y) == 2
        @test length(cb_calls) > 0
    end
    @testset "UserCut" begin
        model, x, item_weights = callback_knapsack_model()
        user_cut_submitted = false
        cb_calls = Int32[]
        MOI.set(model, CPLEX.CallbackFunction(), (cb_data, cb_where) -> begin
            push!(cb_calls, cb_where)
            if cb_where != CPLEX.CPX_CALLBACKCONTEXT_RELAXATION
                return
            end
            CPLEX.callbackgetrelaxationpoint(model, cb_data, cb_where)
            terms = MOI.ScalarAffineTerm{Float64}[]
            accumulated = 0.0
            for (i, xi) in enumerate(x)
                if MOI.get(model, MOI.CallbackVariablePrimal(cb_data), xi) > 0.0
                    push!(terms, MOI.ScalarAffineTerm(1.0, xi))
                    accumulated += item_weights[i]
                end
            end
            if accumulated > 10.0
                MOI.submit(
                    model,
                    MOI.UserCut(cb_data),
                    MOI.ScalarAffineFunction{Float64}(terms, 0.0),
                    MOI.LessThan{Float64}(length(terms) - 1)
                )
                user_cut_submitted = true
            end
        end)
        MOI.optimize!(model)
        @test user_cut_submitted
    end
    @testset "HeuristicSolution" begin
        model, x, item_weights = callback_knapsack_model()
        callback_called = false
        cb_calls = Int32[]
        MOI.set(model, CPLEX.CallbackFunction(), (cb_data, cb_where) -> begin
            push!(cb_calls, cb_where)
            if cb_where != CPLEX.CPX_CALLBACKCONTEXT_RELAXATION
                return
            end
            CPLEX.callbackgetrelaxationpoint(model, cb_data, cb_where)
            x_vals = MOI.get.(model, MOI.CallbackVariablePrimal(cb_data), x)
            @test MOI.submit(
                model,
                MOI.HeuristicSolution(cb_data),
                x,
                floor.(x_vals)
            ) == MOI.HEURISTIC_SOLUTION_UNKNOWN
            callback_called = true
        end)
        MOI.optimize!(model)
        @test callback_called
    end
end
