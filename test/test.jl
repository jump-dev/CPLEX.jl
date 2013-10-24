using Cplex

env = makeenv()

prob = makeprob(env)

model_filename = "example.mps"

readdata!(prob, model_filename)

solvelp!(prob)

obj, x = getsolution(prob)

println("Objective value = $(obj)")

output_filename = "out.lp"
writedata(prob, output_filename)
