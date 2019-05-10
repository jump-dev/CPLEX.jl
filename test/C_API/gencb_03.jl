@testset "GenCB_03" begin
    env = CPLEX.Env()
    CPLEX.set_param!(env, "CPX_PARAM_THREADS", 1)
    model = CPLEX.Model(env, "LazyCB_test")
    #  max 0.5x + y
    # s.t. 0 <= x <= 2
    #      0 <= y <= 2
    CPLEX.add_var!(model, 0.5, 0, 2)
    CPLEX.add_var!(model, 1.0, 0, 2)
    CPLEX.set_sense!(model, :Max)
    CPLEX.set_vartype!(model, ['I', 'I'])
    function my_callback(cb_context::CPLEX.CallbackContext, context_id::Clong)
        if context_id == CPLEX.CPX_CALLBACKCONTEXT_CANDIDATE
            primal_sol = Vector{Float64}(undef, 2)
            objective = Ref{Float64}(0.0)
            CPLEX.cbgetcandidatepoint(cb_context, primal_sol, 1, 2, objective)
            @assert isapprox(
                0.5 * primal_sol[1] + primal_sol[2], objective[], atol=1e-6)
            if sum(primal_sol) > 3.0 + 1e-6
                CPLEX.cbrejectcandidate(
                    cb_context, 1, 2, 3.0, 'L', [1], [1, 2], [1.0, 1.0])
            end
        else
            error("Callback shold not be called from context_id $(context_id).")
        end
    end
    CPLEX.cbsetfunc(model, CPLEX.CPX_CALLBACKCONTEXT_CANDIDATE, my_callback)
    CPLEX.optimize!(model)
    sol = CPLEX.get_solution(model)
    @test sol ≈ [1, 2]
    @test CPLEX.get_objval(model) ≈ 2.5
    @test CPLEX.get_status(model) == :CPXMIP_OPTIMAL
end
