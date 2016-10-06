using CPLEX

env = CPLEX.Env()
CPLEX.set_logfile(env, "cplex.log")
CPLEX.close_CPLEX(env)
