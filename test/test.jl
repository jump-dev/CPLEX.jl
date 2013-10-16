using Cplex

env = makeenv()

lp = makeprob(env)

model_filename = "/opt/cplex/cplex/examples/data/example.mps"

readdata(env, lp, model_filename)

solvelp(env, lp)

output_filename = "out.lp"

writedata(env, lp, output_filename)

