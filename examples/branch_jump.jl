using CPLEX, JuMP, MathProgBase

mod = Model(solver=CplexSolver(CPX_PARAM_PRELINEAR=0, CPX_PARAM_PREIND=0, CPX_PARAM_ADVIND=0, CPX_PARAM_MIPSEARCH=1, CPX_PARAM_MIPCBREDLP=0, CPX_PARAM_CUTSFACTOR=1))
m_internal = MathProgBase.LinearQuadraticModel(CplexSolver())

MathProgBase.loadproblem!(m_internal, "location.lp")

# grab MathProgBase data
c = MathProgBase.getobj(m_internal)
A = MathProgBase.getconstrmatrix(m_internal)
m, n = size(A)
xlb = MathProgBase.getvarLB(m_internal)
xub = MathProgBase.getvarUB(m_internal)
l = MathProgBase.getconstrLB(m_internal)
u = MathProgBase.getconstrUB(m_internal)
vtypes = MathProgBase.getvartype(m_internal)

# populate JuMP model with data from internal model
@variable(mod, x[1:n])
for i in 1:n
    setlower(x[i], xlb[i])
    setupper(x[i], xub[i])
    (vtypes[i] == :Bin || vtypes[i] == :Int) ? mod.colCat[x[i].col] = :Int : nothing # change vartype to integer when appropriate
end
At = A' # transpose to get useful row-wise sparse representation
for i in 1:At.n
    @constraint( mod, l[i] <= sum( At.nzval[idx]*x[At.rowval[idx]] for idx = At.colptr[i]:(At.colptr[i+1]-1) ) <= u[i] )
end
@objective(mod, Min, sum( c[i]*x[i] for i=1:n ))

function callback(cb)
    xval = MathProgBase.cbgetlpsolution(cb)
    objval = cbgetnodeobjval(cb)
    best = MathProgBase.cbgetobj(cb)
    feas = cbgetintfeas(cb)

    if  MathProgBase.cbgetexplorednodes(cb) < 2
        maxinf = maxobj = bestj = -Inf
        for j in 1:MathProgBase.numvar(mod)
            if feas[j] == 1
                xj_inf = xval[j] - floor(xval[j])
                if xj_inf > 0.5
                    xj_inf = 1.0 - xj_inf
                end
                if (xj_inf >= maxinf) && (xj_inf > maxinf || abs(c[j]) >= maxobj)
                    bestj = j
                    maxinf = xj_inf
                    maxobj = abs(c[j])
                end
            end
        end
        if bestj >= 1
            xj_lo = floor(xval[bestj])
            #println("branching on $bestj")
            addbranch(cb, x[bestj] >= xj_lo + 1, objval)
            addbranch(cb, x[bestj] <= xj_lo,     objval)
        end
    end
end

solve(mod; load_model_only=true)
setbranchcallback(mod, callback)
solve(mod)
