export CplexSolver

type CplexMathProgModel <: AbstractMathProgModel
  inner::CPXproblem
end

immutable CplexSolver <: AbstractMathProgSolver
  options
end

CplexSolver(;kwargs...) = CplexSolver(kwargs)

function CplexMathProgModel(options)
  env = make_env()
  for (name,value) in options
    setparam!(env, string(name), value)
  end
  m = CplexMathProgModel(make_problem(env))
  return m
end

model(s::CplexSolver) = CplexMathProgModel(s.options)

loadproblem!(m::CplexMathProgModel, filename::String) = read_file!(m.inner, filename)

function loadproblem!(m::CplexMathProgModel, A, collb, colub, obj, rowlb, rowub, sense)
  add_vars!(m.inner, float(obj), float(collb), float(colub))

  neginf = typemin(eltype(rowlb))
  posinf = typemax(eltype(rowub))

  rangeconstrs = any((rowlb .!= rowub) & (rowlb .> neginf) & (rowub .< posinf))
  if rangeconstrs
    warn("Julia Cplex interface doesn't properly support range (two-sided) constraints.")
    add_rangeconstrs!(m.inner, float(A), float(rowlb), float(rowub))
  else
    b = Array(Float64,length(rowlb))
    senses = Array(Cchar,length(rowlb))
    for i in 1:length(rowlb)
      if rowlb[i] == rowub[i]
        senses[i] = '='
        b[i] = rowlb[i]
      elseif rowlb[i] > neginf
        senses[i] = '>'
        b[i] = rowlb[i]
      else
        @assert rowub[i] < posinf
        senses[i] = '<'
        b[i] = rowub[i]
      end
    end
    add_constrs!(m.inner, float(A), senses, b)
  end

  set_sense!(m.inner, sense)
end

writeproblem(m::CplexMathProgModel, filename::String) = write_model(m.inner, filename)

getVarLB(m::CplexMathProgModel) = get_varLB(m.inner)
setVarLB!(m::CplexMathProgModel, l) = error("Not yet implemented.")
getVarUB(m::CplexMathProgModel) = get_varUB(m.inner)
setVarUB!(m::CplexMathProgModel, u) = error("Not yet implemented.")

getConstrLB(m::CplexMathProgModel) = error("Not yet implemented.")
setConstrLB!(m::CplexMathProgModel, lb) = error("Not yet implemented.")
getConstrUB(m::CplexMathProgModel) = error("Not yet implemented.")
setConstrUB!(m::CplexMathProgModel, ub) = error("Not yet implemented.")

getobj(m::CplexMathProgModel) = error("Not yet implemented.")
setobj!(m::CplexMathProgModel, c) = error("Not yet implemented.")

addvar!(m::CplexMathProgModel, constridx, constrcoef, l, u, coeff) = error("Not yet implemented.")
addvar!(m::CplexMathProgModel, l, u, coeff) = error("Not yet implemented.")

addconstr!(m::CplexMathProgModel, varidx, coef, lb, ub) = error("Not yet implemented.")

updatemodel!(m::CplexMathProgModel) = println("Model update not necessary for Cplex.")

setsense!(m::CplexMathProgModel, sense) = set_sense!(m.inner, sense)

getsense(m::CplexMathProgModel) = get_sense(m.inner)

numvar(m::CplexMathProgModel) = m.inner.nvars
numconstr(m::CplexMathProgModel) = m.inner.ncons

optimize!(m::CplexMathProgModel) = solve_lp!(m.inner)

status(m::CplexMathProgModel) = error("Not yet implemented.")

getobjval(m::CplexMathProgModel)   = get_solution(m.inner)[1]
getobjbound(m::CplexMathProgModel) = error("Not yet implemented.")
getsolution(m::CplexMathProgModel) = get_solution(m.inner)[2]
getconstrsolution(m::CplexMathProgModel) = error("Not yet implemented.")
getreducedcosts(m::CplexMathProgModel) = error("Not yet implemented.")
getconstrduals(m::CplexMathProgModel) = error("Not yet implemented.")

getrawsolver(m::CplexMathProgModel) = m.inner

setvartype!(m::CplexMathProgModel, v::Vector{Char}) = error("Not yet implemented.")
getvartype(m::CplexMathProgModel) = error("Not yet implemented.")


