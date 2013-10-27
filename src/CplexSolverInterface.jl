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

getVarLB(m::CplexMathProgModel)
setVarLB!(m::CplexMathProgModel, l)

getVarUB(m::CplexMathProgModel)
setVarUB!(m::CplexMathProgModel, u)

getConstrLB(m::CplexMathProgModel)
setConstrLB!(m::CplexMathProgModel, lb)

getConstrUB(m::CplexMathProgModel)
setConstrUB!(m::CplexMathProgModel, ub)

getobj(m::CplexMathProgModel)
setobj!(m::CplexMathProgModel, c)

addvar!(m::CplexMathProgModel, constridx, constrcoef, l, u, coeff)
addvar!(m::CplexMathProgModel, l, u, coeff)

addconstr!(m::CplexMathProgModel, varidx, coef, lb, ub)

updatemodel!(m::CplexMathProgModel) = println("Model update not necessary for Cplex.")

function setsense!(m::CplexMathProgModel, sense)
   set_sense!(m.inner, sense)
end

getsense(m::CplexMathProgModel)

numvar(m::CplexMathProgModel) = m.inner.nvars
numconstr(m::CplexMathProgModel) = m.inner.ncons

optimize!(m::CplexMathProgModel) = solve_lp!(m.inner)

status(m::CplexMathProgModel)

getobjval(m::CplexMathProgModel)   = get_solution(m.inner)[1]
getobjbound(m::CplexMathProgModel)
getsolution(m::CplexMathProgModel) = get_solution(m.inner)[2]
getconstrsolution(m::CplexMathProgModel)
getreducedcosts(m::CplexMathProgModel)
getconstrduals(m::CplexMathProgModel)

getrawsolver(m::CplexMathProgModel) = m.inner

setvartype!(m::CplexMathProgModel, v::Vector{Char})
getvartype(m::CplexMathProgModel)


