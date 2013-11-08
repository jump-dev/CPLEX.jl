using Cplex

env = make_env()

prob = make_problem(env)

model_filename = "example.mps"

read_file!(prob, model_filename)

optimize!(prob)

obj, x = get_solution(prob)

println("Objective value = $(obj)")

output_filename = "out.lp"
write_problem(prob, output_filename)


# env = make_env()
# prob = make_problem(env)
# add_vars!(prob, [1,0], [0,-10], [10,5])
# A = [1 2; 3 4.5]
# lb = [-5, 2]
# ub = [5, 6]
# # A = [3 4.5]
# # lb = [2]
# # ub = [6]
# add_rangeconstrs!(prob, A, lb, ub)
# set_sense!(prob, :Max)
# output_filename = "out.lp"
# write_problem(prob, output_filename)
