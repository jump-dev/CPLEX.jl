using Cplex

env = make_env()

prob = make_problem(env)

model_filename = "example.mps"

read_file!(prob, model_filename)

solve_lp!(prob)

obj, x = get_solution(prob)

println("Objective value = $(obj)")

output_filename = "out.lp"
write_problem(prob, output_filename)
