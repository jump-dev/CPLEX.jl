export CplexSolver

type CplexMathProgModel <: AbstractMathProgModel
   inner::CPXproblem
end

immutable CplexSolver <: AbstractMathProgSolver
   options
end

function loadproblem!(m::CplexMathProgModel, A, collb, colub, obj, rowlb, rowub, sense)
   add_vars!(m.inner, float(obj), float(collb), float(colub))
   add_rangeconstrs!(m.inner, A, float(rowlb), float(rowub))
end

function writeproblem(m::CplexMathProgModel, filename::String)
   write_model(m.inner, filename)
end

function setsense!(m::CplexMathProgModel, sense)
   set_sense!(m.inner, sense)
end

numvar(m::CplexMathProgModel) = m.inner.nvars
numvar(m::CplexMathProgModel) = m.inner.ncons

optimize!(m::CplexMathProgModel) = solve_lp!(m.inner)

getobjval(m::CplexMathProgModel)   = get_solution(m.inner)[1]
getsolution(m::CplexMathProgModel) = get_solution(m.inner)[2]

getrawsolver(m::CplexMathProgModel) = m.inner


