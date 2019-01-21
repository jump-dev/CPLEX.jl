

@testset "GenCB_03" begin
    env=CPLEX.Env()
    model=CPLEX.Model(env,"LazyCB_test")
    CPLEX.set_sense!(model, :Max)

    CPLEX.add_var!(model, 0.5, 0, 2) #x
    CPLEX.add_var!(model, 1.0, 0, 2) #y
    CPLEX.set_vartype!(model, ['I', 'I'])

    model.has_int = true

    function my_callback(cb_context::CPLEX.CallbackContext, context_id::Clong)
        if (context_id == CPLEX.CPX_CALLBACKCONTEXT_CANDIDATE)
            CBval = Vector{Float64}(undef, 2)
            CBobj = 0.0
            status = CPLEX.cbgetcandidatepoint(cb_context, CBval, 1, 2, CBobj)

            if sum(CBval) > 3.0 + 1e-6
                status = CPLEX.cbrejectcandidate(cb_context, 1,  0, 3.0, 'L', [1], [1,2], [1.0, 1.0])
            end

        else
            println("ERROR: Callback called in an unexpected context_id.")
            return convert(Cint,1)
        end

        return status
    end

    context_id = CPLEX.CPX_CALLBACKCONTEXT_CANDIDATE

    CPLEX.cbsetfunc(model, context_id, my_callback)
    CPLEX.set_param!(env, "CPX_PARAM_THREADS", 1)
    CPLEX.optimize!(model)

    sol = CPLEX.get_solution(model)
    @test sol[1] ≈ 1
    @test sol[2] ≈ 2
    @test CPLEX.get_objval(model) ≈ 2.5
    @test CPLEX.get_status(model) == :CPXMIP_OPTIMAL
end
