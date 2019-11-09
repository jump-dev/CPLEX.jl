@testset "GenCB_02" begin
    env = CPLEX.Env()
    CPLEX.set_param!(env, "CPX_PARAM_THREADS", 1)
    # Change some settings to force CPLEX to call the callback.
    CPLEX.set_param!(env, "CPX_PARAM_PREIND", 0)
    CPLEX.set_param!(env, "CPX_PARAM_HEURFREQ", -1)
    model = CPLEX.Model(env, "GenCB_02")
    #  max 0.5x + y
    # s.t. 0 <= x <= 1
    #      0 <= y <= 1
    CPLEX.add_var!(model, 0.5, 0, 1)
    CPLEX.add_var!(model, 1.0, 0, 1)
    CPLEX.set_sense!(model, :Max)
    CPLEX.set_vartype!(model, ['B', 'B'])
    CPLEX.add_constr!(model, [1.0, 1.0], '<', 1.5)
    was_heuristic_called = false
    function my_round_down_heur(
            cb_context::CPLEX.CallbackContext, context_id::Clong)
        if context_id == CPLEX.CPX_CALLBACKCONTEXT_RELAXATION
            relaxed_solution = Vector{Float64}(undef, 2)
            relaxed_objective = Ref{Float64}(0.0)
            CPLEX.cbgetrelaxationpoint(
                cb_context,
                relaxed_solution,
                Cint(0),
                Cint(1),
                relaxed_objective
            )
            objective_value = relaxed_objective[]
            for j in 1:2
                frac = relaxed_solution[j] - floor(relaxed_solution[j])
                if frac > 1.0e-6
                    objective_value -= frac
                    relaxed_solution[j] -= frac
                end
            end
            was_heuristic_called = true
            return CPLEX.cbpostheursoln(
                cb_context,
                Cint(2),
                Cint[0, 1],
                relaxed_solution,
                objective_value,
                CPLEX.CPXCALLBACKSOLUTION_PROPAGATE
            )
        else
            error("Heuristic should not be called from $(context_id).")
        end
    end
    CPLEX.cbsetfunc(
        model, CPLEX.CPX_CALLBACKCONTEXT_RELAXATION, my_round_down_heur)
    CPLEX.optimize!(model)
    @test was_heuristic_called
    @test CPLEX.get_status(model) == :CPXMIP_OPTIMAL
    @test CPLEX.get_objval(model) ≈ 1.0
end
