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
            # TODO(odow): new tests
            "test_unbounded_",
            "test_infeasible_",
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

end  # module TestMOIwrapper

TestMOIwrapper.runtests()
