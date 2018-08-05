export CplexOptimizer

using LinQuadOptInterface
const LQOI = LinQuadOptInterface
const MOI  = LQOI.MOI

const SUPPORTED_OBJECTIVES = [
    LQOI.Linear
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

mutable struct CplexOptimizer <: LQOI.LinQuadOptimizer
    LQOI.@LinQuadOptimizerBase    
    env::Env # Cplex environment
    CplexOptimizer(::Void) = new()
end

function LQOI.LinearQuadraticModel(::Type{CplexOptimizer},env)
    env = Env()
    return Model(env::Env)
end

function CplexOptimizer(;kwargs...)        
    env = Env()
    for (name,value) in kwargs
        set_param!(env, string(name), value)
    end
    m = CplexOptimizer(nothing)
    m.env = env
    return m
end

LQOI.supported_constraints(s::CplexOptimizer) = SUPPORTED_CONSTRAINTS
LQOI.supported_objectives(s::CplexOptimizer)  = SUPPORTED_OBJECTIVES

LQOI.backend_type(m::CplexOptimizer, ::MOI.EqualTo{Float64})     = Cchar('E')
LQOI.backend_type(m::CplexOptimizer, ::MOI.LessThan{Float64})    = Cchar('L')
LQOI.backend_type(m::CplexOptimizer, ::MOI.GreaterThan{Float64}) = Cchar('G')

LQOI.backend_type(m::CplexOptimizer, ::MOI.Zeros)                = Cchar('B')
LQOI.backend_type(m::CplexOptimizer, ::MOI.Nonpositives)         = Cchar('L')
LQOI.backend_type(m::CplexOptimizer, ::MOI.Nonnegatives)         = Cchar('E')

# TODO - improve single type
function LQOI.change_variable_bounds!(instance::CplexOptimizer, 
        colvec::Vector{Int}, valvec::Vector{Float64}, sensevec::Vector{Cchar})
    
    chgbds(instance.inner, ivec(colvec .- 1), sensevec, valvec)
end

function LQOI.get_variable_lowerbound(instance::CplexOptimizer, column::Int)
    get_varLB(instance.inner, Cint(column))[1]
end

function LQOI.get_variable_upperbound(instance::CplexOptimizer, column::Int)
    get_varUB(instance.inner, Cint(column))[1]
end

function LQOI.get_number_linear_constraints(instance::CplexOptimizer)
    num_constr(instance.inner)
end

function LQOI.add_linear_constraints!(instance::CplexOptimizer,
        A::LQOI.CSRMatrix{Float64}, sense::Vector{Cchar}, rhs::Vector{Float64})

    add_rows!(instance.inner, ivec(A.row_pointers), ivec(A.columns), 
              A.coefficients, sense, rhs)
end

function LQOI.get_rhs(instance::CplexOptimizer, row::Int)
    get_rhs(instance.inner, Cint(row))
end

function LQOI.get_linear_constraint(instance::CplexOptimizer, row::Int)
    (nzcnt, rmatbeg, rmatind, rmatval) = 
            get_rows(instance.inner, Cint(row), Cint(row))
    return rmatind[1:nzcnt] .+ 1, rmatval[1:nzcnt]
end

function LQOI.change_matrix_coefficient!(instance::CplexOptimizer, 
                                         row::Int, col::Int, coef::Float64)
                                         
    chg_coef!(instance.inner, Cint(row), Cint(col), coef)
end

function LQOI.change_objective_coefficient!(instance::CplexOptimizer, col::Int, 
                                            coef::Float64)
                                            
    set_obj!(instance.inner, [Cint(col)], [coef])
end

function LQOI.change_rhs_coefficient!(instance::CplexOptimizer, row::Int, 
                                      coef::Float64)
                                      
    chg_rhs(instance.inner, [Cint(row)], [coef])
end

function LQOI.delete_linear_constraints!(instance::CplexOptimizer, 
                                         first_row::Int, last_row::Int)
                                         
    del_rows!(instance.inner, Cint(first_row), Cint(last_row))
end

function LQOI.change_variable_types!(instance::CplexOptimizer, 
        columns::Vector{Int}, vtypes::Vector{Cchar})
    
    chg_ctype!(instance.inner, ivec(columns), vtypes)
end

function LQOI.change_linear_constraint_sense!(instance::CplexOptimizer, 
        rows::Vector{Int}, senses::Vector{Cchar})
                                              
    chg_sense!(ivec(rows), senses)
end

function LQOI.set_linear_objective!(instance::CplexOptimizer, 
        columns::Vector{Int}, coefficients::Vector{Float64})
    
    n = num_var(instance.inner)    
    all_coefs = zeros(Float64, n)    
    for (col, coef) in zip(columns, coefficients)
        all_coefs[col] = coef
    end 
    set_obj!(instance.inner, all_coefs) 
end

function LQOI.change_objective_sense!(instance::CplexOptimizer, symbol)
    if symbol == :min
        set_sense!(instance.inner, :Min)
    else
        set_sense!(instance.inner, :Max)
    end  
end

function LQOI.get_linear_objective!(instance::CplexOptimizer, x)
    get_obj(instance.inner, x)
end

function LQOI.get_objectivesense(instance::CplexOptimizer)
    s = get_sense(instance.inner)
    if s == :Max
        return MOI.MaxSense
    else
        return MOI.MinSense
    end
end

function LQOI.get_number_variables(instance::CplexOptimizer)  
    num_var(instance.inner)
end

function LQOI.add_variables!(instance::CplexOptimizer, N::Int)
    add_vars!(instance.inner, zeros(Float64, N), fill(-Inf, N), fill(Inf, N))
end

function LQOI.delete_variables!(instance::CplexOptimizer, 
                                first_col::Int, last_col::Int)
    del_cols!(instance.inner, Cint(first_col), Cint(last_col))
end

function LQOI.solve_mip_problem!(instance::CplexOptimizer)
    instance.inner.has_int = true
    LQOI.solve_linear_problem!(instance)
end

function LQOI.solve_linear_problem!(instance::CplexOptimizer)  
    optimize!(instance.inner)
end

function LQOI.get_termination_status(instance::CplexOptimizer)
    stat = get_status_code(instance.inner) 
               
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

function LQOI.get_primal_status(instance::CplexOptimizer)
    stat = get_solution_info(instance.inner)[3]
    if stat == 1
        return MOI.FeasiblePoint
    else
        return MOI.UnknownResultStatus
    end
end

function LQOI.get_dual_status(instance::CplexOptimizer)
    if instance.inner.has_int 
        return MOI.UnknownResultStatus
    end
    stat = get_solution_info(instance.inner)[4]
    if stat == 1
        return MOI.FeasiblePoint
    else
        return MOI.UnknownResultStatus
    end
end

function LQOI.get_variable_primal_solution!(instance::CplexOptimizer, result)
    fill_solution(instance.inner, result)
end
 
function LQOI.get_linear_primal_solution!(instance::CplexOptimizer, result)
    fill_constr_solution(instance.inner, result)
end
 
function LQOI.get_variable_dual_solution!(instance::CplexOptimizer, place)
    fill_reduced_costs(instance.inner, place)
end

function LQOI.get_linear_dual_solution!(instance::CplexOptimizer, place)
    fill_constr_duals(instance.inner, place)
end

function LQOI.get_objective_value(instance::CplexOptimizer)
    get_objval(instance.inner)
end

function LQOI.get_relative_mip_gap(instance::CplexOptimizer)
    L = get_objval(instance.inner)
    U = get_objbound(instance.inner)
    return abs(U-L)/U
end

function MOI.free!(m::CplexOptimizer)
    # close_CPLEX(instance.inner)   
end

MOI.canget(m::CplexOptimizer, ::MOI.ObjectiveBound) = false
MOI.canget(m::CplexOptimizer, ::MOI.RelativeGap) = false
MOI.canget(m::CplexOptimizer, ::MOI.SolveTime) = false
MOI.canget(m::CplexOptimizer, ::MOI.SimplexIterations) = false
MOI.canget(m::CplexOptimizer, ::MOI.BarrierIterations) = false
MOI.canget(m::CplexOptimizer, ::MOI.NodeCount) = false