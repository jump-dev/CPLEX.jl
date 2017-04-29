using CPLEX, Base.Test

@testset "Low-level API" begin
    env = CPLEX.Env()
    CPLEX.set_logfile(env, "cplex.log")
    CPLEX.close_CPLEX(env)
end
