using Cplex

env = makeenv()

lp = makeprob(env)

model_filename = "/Users/huchette/Applications/IBM/ILOG/CPLEX_Studio_Preview1251/cplex/examples/data/example.mps"

readdata(env, lp, model_filename)

solvelp(env, lp)

output_filename = "/Users/huchette/Documents/out.txt"

writedata(env, lp, output_filename)

