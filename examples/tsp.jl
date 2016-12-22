# TSP

using JuMP
using CPLEX

m = Model(solver=CplexSolver(CPX_PARAM_MIPDISPLAY=1, CPX_PARAM_MIPINTERVAL=1))

n = 6
cities = [ 50 200;
          100 100;
          100 300;
          500 100;
          500 300;
          550 200]
dist = zeros(n, n)
for i = 1:n
  for j = i:n
    d = norm(cities[i,1:2]-cities[j,1:2])
    dist[i,j] = d
    dist[j,i] = d
  end
end
#println(dist)

@variable(m, x[1:n,1:n], Bin)

@objective(m, Min, sum(dist[i,j]*x[i,j] for i=1:n,j=i:n))


# Make symmetric
for i = 1:n
  @constraint(m, x[i,i] == 0)
  for j = (i+1):n
    @constraint(m, x[i,j] == x[j,i])
  end
end

# Sum in to city = 1
for i = 1:n
  @constraint(m, sum(x[i,j] for j=1:n) == 2)
end

# Sum out of city = 1
for j = 1:n
  @constraint(m, sum(x[i,j] for i=1:n) == 2)
end

function subtour(cb)
  println("In subtour")
  cur_sol = getvalue(x)
  # println(cur_sol)

  # Find any subtour
  in_subtour = fill(false,n)
  cur_node = 1
  in_subtour[cur_node] = true
  subtour_length = 1
  while true
    # Find next unvisited node
    found_node = false
    for j = 1:n
      if !in_subtour[j]
        if cur_sol[cur_node,j] >= 0.9
          # Arc to unvisited node
          cur_node = j
          in_subtour[j] = true
          found_node = true
          subtour_length += 1
          break
        end
      end
    end
    if !found_node
      println("Done exploring")
      # Completely explored this subtour
      if subtour_length == n
        println("found tour!")
        # Done!
        break
      else
        # Add lazy constraint
        expr = AffExpr()
        for i = 1:n
          if !in_subtour[i]
            continue
          end
          # i is in S
          for j = 1:n
            if i == j
              continue
            end
            if in_subtour[j]
              # Both ends in subtour, bad
            else
              # j isn't in subtour
              expr += x[i,j]
            end
          end
        end
        println(expr)
        readline(STDIN)
        @addlazyconstraint(cb, expr >= 2)
        break
      end
    end
  end

end

addlazycallback(m, subtour)
stat = solve(m)

println(getvalue(x))
println(stat)
println(getobjectivevalue(m))
