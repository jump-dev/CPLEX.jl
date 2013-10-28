export CplexSolver

type CplexMathProgModel <: AbstractMathProgModel
   inner::CPXproblem
end

immutable CplexSolver <: AbstractMathProgSolver
   options
end

loadproblem!(m::CplexMathProgModel, filename::String) = read_file!(m.inner, filename)

function loadproblem!(m::CplexMathProgModel, A, collb, colub, obj, rowlb, rowub, sense)
   add_vars!(m.inner, float(obj), float(collb), float(colub))
   add_rangeconstrs!(m.inner, A, float(rowlb), float(rowub))
end

writeproblem(m::CplexMathProgModel, filename::String) = write_model(m.inner, filename)

getVarLB(m::CplexMathProgModel) = error("Not yet implemented.")
setVarLB!(m::CplexMathProgModel, l) = error("Not yet implemented.")

getVarUB(m::CplexMathProgModel) = error("Not yet implemented.")
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

getsense(m::CplexMathProgModel) = error("Not yet implemented.")

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


