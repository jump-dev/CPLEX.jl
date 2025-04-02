# Copyright (c) 2013: Joey Huchette and contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

module TestMOIwrapper

using CPLEX
using MathOptInterface
using Test

const MOI = MathOptInterface

function runtests()
    for name in names(@__MODULE__; all = true)
        if startswith("$(name)", "test_")
            @testset "$(name)" begin
                getfield(@__MODULE__, name)()
            end
        end
    end
    return
end

function test_runtests()
    model = MOI.Bridges.full_bridge_optimizer(CPLEX.Optimizer(), Float64)
    MOI.set(model, MOI.Silent(), true)
    # Turn off presolve reductions so CPLEX will generate infeasibility
    # certificates.
    MOI.set(model, MOI.RawOptimizerAttribute("CPX_PARAM_REDUCE"), 0)
    MOI.Test.runtests(
        model,
        MOI.Test.Config(atol = 1e-3, rtol = 1e-3),
        exclude = String[
            # CPLEX doesn't support nonconvex QCPs
            "test_quadratic_nonconvex_",
            "test_conic_SecondOrderCone_negative_post_bound_3",
        ],
    )
    return
end

"""
Test setting CPXPARAM_OptimalityTarget because it changes the problem type.
"""
function test_CPXPARAM_OptimalityTarget()
    model = CPLEX.Optimizer()
    MOI.set(model, MOI.Silent(), true)
    x = MOI.add_variable(model)
    MOI.add_constraint(model, x, MOI.Interval(1.0, 4.0))
    MOI.set(
        model,
        MOI.ObjectiveFunction{MOI.ScalarQuadraticFunction{Float64}}(),
        MOI.ScalarQuadraticFunction(
            [MOI.ScalarQuadraticTerm(2.0, x, x)],
            MOI.ScalarAffineTerm{Float64}[],
            0.0,
        ),
    )
    MOI.set(model, MOI.ObjectiveSense(), MOI.MAX_SENSE)
    MOI.set(
        model,
        MOI.RawOptimizerAttribute("CPXPARAM_OptimalityTarget"),
        CPX_OPTIMALITYTARGET_OPTIMALGLOBAL,
    )
    MOI.optimize!(model)
    @test MOI.get(model, MOI.TerminationStatus()) == MOI.OPTIMAL
    @test MOI.get(model, MOI.PrimalStatus()) == MOI.FEASIBLE_POINT
    @test MOI.get(model, MOI.ObjectiveValue()) ≈ 16.0 atol = 1e-6
    @test MOI.get(model, MOI.VariablePrimal(), x) ≈ 4.0 atol = 1e-6
    return
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
    return
end

function test_automatic_env()
    model_1 = CPLEX.Optimizer()
    model_2 = CPLEX.Optimizer()
    @test model_1.env.ptr !== model_2.env.ptr
    return
end

function test_user_provided_env_empty()
    env = CPLEX.Env()
    model = CPLEX.Optimizer(env)
    @test model.env === env
    @test env.ptr != C_NULL
    MOI.empty!(model)
    @test model.env === env
    @test env.ptr != C_NULL
    return
end

function test_automatic_env_empty()
    model = CPLEX.Optimizer()
    env = model.env
    MOI.empty!(model)
    @test model.env === env
    @test env.ptr != C_NULL
    return
end

function test_manual_env()
    env = CPLEX.Env()
    model = CPLEX.Optimizer(env)
    finalize(env)
    @test env.finalize_called
    finalize(model)
    @test env.ptr == C_NULL
    return
end

function test_ZeroOne_NONE()
    model = CPLEX.Optimizer()
    x = MOI.add_variable(model)
    c = MOI.add_constraint(model, x, MOI.ZeroOne())
    tmp = Ref{Cdouble}()
    CPLEX.CPXgetlb(model.env, model.lp, tmp, 0, 0)
    @test tmp[] == 0.0
    CPLEX.CPXgetub(model.env, model.lp, tmp, 0, 0)
    @test tmp[] == 1.0
    MOI.delete(model, c)
    CPLEX.CPXgetlb(model.env, model.lp, tmp, 0, 0)
    @test tmp[] == -CPLEX.CPX_INFBOUND
    CPLEX.CPXgetub(model.env, model.lp, tmp, 0, 0)
    @test tmp[] == CPLEX.CPX_INFBOUND
    return
end

function test_ZeroOne_LESS_THAN()
    model = CPLEX.Optimizer()
    x = MOI.add_variable(model)
    MOI.add_constraint(model, x, MOI.LessThan(2.0))
    c = MOI.add_constraint(model, x, MOI.ZeroOne())
    tmp = Ref{Cdouble}()
    CPLEX.CPXgetlb(model.env, model.lp, tmp, 0, 0)
    @test tmp[] == 0.0
    CPLEX.CPXgetub(model.env, model.lp, tmp, 0, 0)
    @test tmp[] == 2.0
    MOI.delete(model, c)
    CPLEX.CPXgetlb(model.env, model.lp, tmp, 0, 0)
    @test tmp[] == -CPLEX.CPX_INFBOUND
    CPLEX.CPXgetub(model.env, model.lp, tmp, 0, 0)
    @test tmp[] == 2.0
    return
end

function test_ZeroOne_GREATER_THAN()
    model = CPLEX.Optimizer()
    x = MOI.add_variable(model)
    MOI.add_constraint(model, x, MOI.GreaterThan(-2.0))
    c = MOI.add_constraint(model, x, MOI.ZeroOne())
    tmp = Ref{Cdouble}()
    CPLEX.CPXgetlb(model.env, model.lp, tmp, 0, 0)
    @test tmp[] == -2.0
    CPLEX.CPXgetub(model.env, model.lp, tmp, 0, 0)
    @test tmp[] == 1.0
    MOI.delete(model, c)
    CPLEX.CPXgetlb(model.env, model.lp, tmp, 0, 0)
    @test tmp[] == -2.0
    CPLEX.CPXgetub(model.env, model.lp, tmp, 0, 0)
    @test tmp[] == CPLEX.CPX_INFBOUND
    return
end

function test_ZeroOne_INTERVAL()
    model = CPLEX.Optimizer()
    x = MOI.add_variable(model)
    MOI.add_constraint(model, x, MOI.Interval(-2.0, 2.0))
    c = MOI.add_constraint(model, x, MOI.ZeroOne())
    tmp = Ref{Cdouble}()
    CPLEX.CPXgetlb(model.env, model.lp, tmp, 0, 0)
    @test tmp[] == -2.0
    CPLEX.CPXgetub(model.env, model.lp, tmp, 0, 0)
    @test tmp[] == 2.0
    MOI.delete(model, c)
    CPLEX.CPXgetlb(model.env, model.lp, tmp, 0, 0)
    @test tmp[] == -2.0
    CPLEX.CPXgetub(model.env, model.lp, tmp, 0, 0)
    @test tmp[] == 2.0
    return
end

function test_fake_status()
    model = CPLEX.Optimizer()
    model.ret_optimize = CPLEX.CPXERR_NO_MEMORY
    @test MOI.get(model, MOI.TerminationStatus()) == MOI.MEMORY_LIMIT
    @test MOI.get(model, MOI.RawStatusString()) ==
          "CPLEX Error  1001: Out of memory.\n"
    return
end

function test_getlongparam()
    model = CPLEX.Optimizer()
    y = MOI.get(model, MOI.RawOptimizerAttribute("CPX_PARAM_INTSOLLIM"))
    # The default is a really big number, but not the typemax.
    @test y > 0.95 * typemax(y)
    return
end

function test_PassNames()
    model = CPLEX.Optimizer()
    @test model.pass_names == false
    MOI.set(model, CPLEX.PassNames(), true)
    @test model.pass_names == true
    return
end

function test_relative_gap_GetAttributeNotAllowed()
    model = CPLEX.Optimizer()
    x = MOI.add_variable(model)
    MOI.add_constraint(model, x, MOI.GreaterThan(1.0))
    MOI.optimize!(model)
    @test_throws MOI.GetAttributeNotAllowed MOI.get(model, MOI.RelativeGap())
    return
end

function test_multiobjective()
    model = CPLEX.Optimizer()
    MOI.set(model, MOI.Silent(), true)
    MOI.Utilities.loadfromstring!(
        model,
        """
variables: x, y
minobjective: [2x + y, x + 3 * y]
c1: x + y >= 1.0
c2: 0.5 * x + 1.0 * y >= 0.75
c3: x >= 0.0
c4: y >= 0.25
""",
    )
    MOI.optimize!(model)
    @test MOI.get(model, MOI.ObjectiveValue()) ≈ [1.5, 2.0]
    x = MOI.get(model, MOI.ListOfVariableIndices())
    @test MOI.get(model, MOI.VariablePrimal(), x) ≈ [0.5, 0.5]
    return
end

function test_multiobjective_attributes()
    model = CPLEX.Optimizer()
    MOI.set(model, MOI.Silent(), true)
    MOI.Utilities.loadfromstring!(
        model,
        """
variables: x, y
minobjective: [-2 * x + -1 * y, x + 3 * y]
c1: x + y >= 1.0
c2: 0.5 * x + 1.0 * y >= 0.75
c3: x >= 0.0
c4: y >= 0.25
""",
    )
    MOI.set(model, CPLEX.MultiObjectiveAttribute(1, "reltol"), 0.0)
    MOI.set(model, CPLEX.MultiObjectiveAttribute(1, "abstol"), 0.0)
    MOI.set(model, CPLEX.MultiObjectiveAttribute(1, "weight"), -1.0)
    MOI.set(model, CPLEX.MultiObjectiveAttribute(1, "priority"), 1)
    MOI.set(model, CPLEX.MultiObjectiveAttribute(2, "priority"), 2)
    MOI.optimize!(model)
    @test MOI.get(model, MOI.ObjectiveValue()) ≈ [-2.25, 1.75]
    x = MOI.get(model, MOI.ListOfVariableIndices())
    @test MOI.get(model, MOI.VariablePrimal(), x) ≈ [1.0, 0.25]
    MOI.set(model, CPLEX.MultiObjectiveAttribute(1, "priority"), 2)
    MOI.set(model, CPLEX.MultiObjectiveAttribute(2, "priority"), 1)
    MOI.optimize!(model)
    @test MOI.get(model, MOI.ObjectiveValue()) ≈ [-1.0, 3.0]
    x = MOI.get(model, MOI.ListOfVariableIndices())
    @test MOI.get(model, MOI.VariablePrimal(), x) ≈ [0.0, 1.0]
    @test_throws(
        MOI.UnsupportedAttribute,
        MOI.set(model, CPLEX.MultiObjectiveAttribute(1, "bad_attr"), 0.0),
    )
    return
end

function test_example_biobjective_knapsack()
    p1 = [77.0, 94, 71, 63, 96, 82, 85, 75, 72, 91, 99, 63, 84, 87, 79, 94, 90]
    p2 = [65.0, 90, 90, 77, 95, 84, 70, 94, 66, 92, 74, 97, 60, 60, 65, 97, 93]
    w = [80.0, 87, 68, 72, 66, 77, 99, 85, 70, 93, 98, 72, 100, 89, 67, 86, 91]
    model = CPLEX.Optimizer()
    x = MOI.add_variables(model, length(w))
    MOI.add_constraint.(model, x, MOI.ZeroOne())
    MOI.add_constraint(model, w' * x, MOI.LessThan(900.0))
    obj_f = MOI.Utilities.operate(vcat, Float64, p1' * x, p2' * x)
    MOI.set(model, MOI.ObjectiveSense(), MOI.MAX_SENSE)
    MOI.set(model, MOI.ObjectiveFunction{typeof(obj_f)}(), obj_f)
    MOI.optimize!(model)
    results = Dict(
        [955.0, 906.0] => [2, 3, 5, 6, 9, 10, 11, 14, 15, 16, 17],
        [948.0, 939.0] => [1, 2, 3, 5, 6, 8, 10, 11, 15, 16, 17],
        [934.0, 971.0] => [2, 3, 5, 6, 8, 10, 11, 12, 15, 16, 17],
        [918.0, 983.0] => [2, 3, 4, 5, 6, 8, 10, 11, 12, 16, 17],
    )
    found_non_dominated_point = false
    for i in 1:MOI.get(model, MOI.ResultCount())
        X = findall(elt -> elt > 0.9, MOI.get.(model, MOI.VariablePrimal(i), x))
        Y = MOI.get(model, MOI.ObjectiveValue(i))
        if haskey(results, Y)
            @test results[Y] == X
            found_non_dominated_point = true
        end
    end
    @test found_non_dominated_point
    return
end

function test_ListOfConstraintTypesPresent_indicator()
    model = CPLEX.Optimizer()
    x = MOI.add_variable(model)
    z = MOI.add_variable(model)
    MOI.add_constraint(model, z, MOI.ZeroOne())
    c = MOI.add_constraint(
        model,
        MOI.Utilities.operate(vcat, Float64, 1.0 * z, 1.0 * x),
        MOI.Indicator{MOI.ACTIVATE_ON_ONE}(MOI.EqualTo(1.0)),
    )
    F = MOI.VectorAffineFunction{Float64}
    S = MOI.Indicator{MOI.ACTIVATE_ON_ONE,MOI.EqualTo{Float64}}
    @test (F, S) in MOI.get(model, MOI.ListOfConstraintTypesPresent())
    return
end

end  # module TestMOIwrapper

TestMOIwrapper.runtests()
