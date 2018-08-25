
using LinQuadOptInterface
const LQOI = LinQuadOptInterface
const MOI  = LQOI.MOI

const SUPPORTED_OBJECTIVES = [
    LQOI.Linear
    LQOI.SinVar
]

const SUPPORTED_CONSTRAINTS = [
    (LQOI.Linear, LQOI.EQ),
    (LQOI.Linear, LQOI.LE),
    (LQOI.Linear, LQOI.GE),
    (LQOI.SinVar, LQOI.EQ),
    (LQOI.SinVar, LQOI.LE),
    (LQOI.SinVar, LQOI.GE),
    (LQOI.SinVar, LQOI.IV),
    (LQOI.SinVar, MOI.ZeroOne),
    (LQOI.SinVar, MOI.Integer),
    (LQOI.VecVar, MOI.Nonnegatives),
    (LQOI.VecVar, MOI.Nonpositives),
    (LQOI.VecVar, MOI.Zeros),
    (LQOI.VecLin, MOI.Nonnegatives),
    (LQOI.VecLin, MOI.Nonpositives),
    (LQOI.VecLin, MOI.Zeros)
]

mutable struct Optimizer <: LQOI.LinQuadOptimizer
    LQOI.@LinQuadOptimizerBase    
    env::Env # Cplex environment
    Optimizer(::Void) = new()
end

function LQOI.LinearQuadraticModel(::Type{Optimizer},env)
    env = Env()
    return Model(env::Env)
end

function Optimizer(;kwargs...)        
    env = Env()
    for (name,value) in kwargs
        set_param!(env, string(name), value)
    end
    model = Optimizer(nothing)
    model.env = env
    return model
end

LQOI.supported_constraints(::Optimizer) = SUPPORTED_CONSTRAINTS
LQOI.supported_objectives(::Optimizer)  = SUPPORTED_OBJECTIVES

LQOI.backend_type(model::Optimizer, ::MOI.EqualTo{Float64})     = Cchar('E')
LQOI.backend_type(model::Optimizer, ::MOI.LessThan{Float64})    = Cchar('L')
LQOI.backend_type(model::Optimizer, ::MOI.GreaterThan{Float64}) = Cchar('G')

LQOI.backend_type(model::Optimizer, ::MOI.Zeros)                = Cchar('B')
LQOI.backend_type(model::Optimizer, ::MOI.Nonpositives)         = Cchar('L')
LQOI.backend_type(model::Optimizer, ::MOI.Nonnegatives)         = Cchar('E')

# TODO - improve single type
function LQOI.change_variable_bounds!(model::Optimizer, 
        columns::Vector{Int}, values::Vector{Float64}, senses::Vector{Cchar})
    
    c_api_chgbds(model.inner, ivec(columns), senses, values)
end

function LQOI.get_variable_lowerbound(model::Optimizer, column::Int)
    c_api_getlb(model.inner, Cint(column), Cint(column))[1]
end

function LQOI.get_variable_upperbound(model::Optimizer, column::Int)
    c_api_getub(model.inner, Cint(column), Cint(column))[1]
end

function LQOI.get_number_linear_constraints(model::Optimizer)
    c_api_getnumrows(model.inner)
end

function LQOI.add_linear_constraints!(model::Optimizer,
        A::LQOI.CSRMatrix{Float64}, sense::Vector{Cchar}, rhs::Vector{Float64})

    c_api_addrows(model.inner, ivec(A.row_pointers), ivec(A.columns), 
                  A.coefficients, sense, rhs)
end

function LQOI.get_rhs(model::Optimizer, row::Int)
    rhs = Vector{Cdouble}(1)
    c_api_getrhs(model.inner, rhs, Cint(row), Cint(row))
    return rhs[1]
end

function LQOI.get_linear_constraint(model::Optimizer, row::Int)
    (nzcnt, rmatbeg, rmatind, rmatval) = 
            c_api_getrows(model.inner, Cint(row), Cint(row))
    return rmatind[1:nzcnt], rmatval[1:nzcnt]
end

function LQOI.change_matrix_coefficient!(model::Optimizer, 
                                         row::Int, col::Int, coef::Float64)
                                         
    c_api_chgcoef(model.inner, Cint(row), Cint(col), coef)
end

function LQOI.change_objective_coefficient!(model::Optimizer, col::Int, 
                                            coef::Float64)
                                            
    c_api_chgobj(model.inner, [Cint(col)], [coef])
end

function LQOI.change_rhs_coefficient!(model::Optimizer, row::Int, 
                                      coef::Float64)
                                      
    c_api_chgrhs(model.inner, [Cint(row)], [coef])
end

function LQOI.delete_linear_constraints!(model::Optimizer, 
                                         first_row::Int, last_row::Int)
                                         
    c_api_delrows(model.inner, Cint(first_row), Cint(last_row))
end

function LQOI.change_variable_types!(model::Optimizer, 
        columns::Vector{Int}, vtypes::Vector{Cchar})
    
    c_api_chgctype(model.inner, ivec(columns), vtypes)
end

function LQOI.change_linear_constraint_sense!(model::Optimizer, 
        rows::Vector{Int}, senses::Vector{Cchar})
                                              
    c_api_chgsense(model.inner, ivec(rows), senses)
end

function LQOI.set_linear_objective!(model::Optimizer, 
        columns::Vector{Int}, coefficients::Vector{Float64})
        
    n = num_var(model.inner)    
    all_coefs = zeros(Float64, n)    
    for (col, coef) in zip(columns, coefficients)
        all_coefs[col] = coef
    end 
    c_api_chgobj(model.inner, Cint[1:n;], all_coefs) 
end

function LQOI.change_objective_sense!(model::Optimizer, symbol)
    if symbol == :min
        c_api_chgobjsen(model.inner, Cint(1))
    else
        c_api_chgobjsen(model.inner, Cint(-1))
    end  
end

function LQOI.get_linear_objective!(model::Optimizer, x)
    c_api_getobj(model.inner, x, Cint(1), c_api_getnumcols(model.inner))
end

function LQOI.get_objectivesense(model::Optimizer)
    s = c_api_getobjsen(model.inner)
    if s == 1
        return MOI.MinSense
    else
        return MOI.MaxSense
    end
end

function LQOI.get_number_variables(model::Optimizer)  
    c_api_getnumcols(model.inner)
end

function LQOI.add_variables!(model::Optimizer, N::Int)
    add_vars!(model.inner, zeros(Float64, N), fill(-Inf, N), fill(Inf, N))
end

function LQOI.delete_variables!(model::Optimizer, 
                                first_col::Int, last_col::Int)
                                
    c_api_delcols(model.inner, Cint(first_col), Cint(last_col))
end

function LQOI.solve_mip_problem!(model::Optimizer)
    model.inner.has_int = true
    LQOI.solve_linear_problem!(model)
end

function LQOI.solve_linear_problem!(model::Optimizer)  
    optimize!(model.inner)
end

function LQOI.get_termination_status(model::Optimizer)
    stat = c_api_getstat(model.inner) 
               
    if stat == 1 # CPX_STAT_OPTIMAL
        return MOI.Success
    elseif stat == 3 # CPX_STAT_INFEASIBLE
        return MOI.InfeasibleNoResult
    elseif stat == 4 # CPX_STAT_INForUNBD
        return MOI.InfeasibleOrUnbounded
    elseif stat == 2 # CPX_STAT_UNBOUNDED
        return MOI.UnboundedNoResult
    elseif stat in [12, 21, 22, 36] # CPX_STAT_*ABORT*_OBJ_LIM 
        return MOI.ObjectiveLimit
    elseif stat in [10,34] # CPX_STAT_*ABORT_IT_LIM
        return MOI.IterationLimit
    elseif stat == 53 # CPX_STAT_CONFLICT_ABORT_NODE_LIM
        return MOI.NodeLimit 
    elseif stat in [11, 25, 33, 39] # CPX_STAT_*ABORT*TIME_LIM
        return MOI.TimeLimit
    elseif stat == 5 # CPX_STAT_OPTIMAL_INFEAS
        return MOI.NumericalError
    
    # MIP STATUS
    elseif stat in [101, 102] # CPXMIP_OPTIMAL, CPXMIP_OPTIMAL_TOL
        return MOI.Success
    elseif stat == 103 # CPXMIP_INFEASIBLE
        return MOI.InfeasibleNoResult
    elseif stat == 119 # CPXMIP_INForUNBD
        return MOI.InfeasibleOrUnbounded
    elseif stat == 118 # CPXMIP_UNBOUNDED
        return MOI.UnboundedNoResult
    elseif stat == [105, 106] # CPXMIP_NODE_LIM*
        return MOI.NodeLimit 
    elseif stat in [107, 108, 131, 132] # CPXMIP_*TIME_LIM*
        return MOI.TimeLimit               
    else        
        return MOI.OtherError
    end
end

function LQOI.get_primal_status(model::Optimizer)
    stat = c_api_solninfo(model.inner)[3]
    if stat == 1
        return MOI.FeasiblePoint
    else
        return MOI.UnknownResultStatus
    end
end

function LQOI.get_dual_status(model::Optimizer)
    if model.inner.has_int 
        return MOI.UnknownResultStatus
    end
    stat = c_api_solninfo(model.inner)[4]
    if stat == 1
        return MOI.FeasiblePoint
    else
        return MOI.UnknownResultStatus
    end
end

function LQOI.get_variable_primal_solution!(model::Optimizer, result)
    return c_api_getx(model.inner, result)
end
 
function LQOI.get_linear_primal_solution!(model::Optimizer, result)
    return c_api_getax(model.inner, result)
end
 
function LQOI.get_variable_dual_solution!(model::Optimizer, place)
    return c_api_getdj(model.inner, place)
end

function LQOI.get_linear_dual_solution!(model::Optimizer, place)
    return c_api_getpi(model.inner, place)
end

function LQOI.get_objective_value(model::Optimizer)
    return c_api_getobjval(model.inner)
end

MOI.canget(m::Optimizer, ::MOI.ObjectiveBound) = false
MOI.canget(m::Optimizer, ::MOI.RelativeGap) = false
MOI.canget(m::Optimizer, ::MOI.SolveTime) = false
MOI.canget(m::Optimizer, ::MOI.SimplexIterations) = false
MOI.canget(m::Optimizer, ::MOI.BarrierIterations) = false
MOI.canget(m::Optimizer, ::MOI.NodeCount) = false