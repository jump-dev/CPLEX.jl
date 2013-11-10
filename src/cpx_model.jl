# to make environment, call CPXopenCLPEX
function make_env()
    status = Array(Cint, 1)
    tmp = @cpx_ccall(openCPLEX, Ptr{Void}, (Ptr{Cint},), status)
    if tmp == C_NULL
        error("CPLEX: Error creating environment")
    end
    return(CPXenv(tmp))
end

# to make problem, call CPXcreateprob
function make_problem(env::CPXenv)
    @assert env.ptr != C_NULL 
    status = Array(Cint, 1)
    tmp = @cpx_ccall(createprob, Ptr{Void}, (Ptr{Void}, Ptr{Cint}, Ptr{Uint8}), env.ptr, status, "Cplex.jl")
    if tmp == C_NULL
        error("CPLEX: Error creating problem, $(tmp)")
    end
    return CPXproblem(env, tmp)
end

function read_file!(prob::CPXproblem, filename)
    ret = @cpx_ccall(readcopyprob, Cint, (Ptr{Void}, Ptr{Void}, Ptr{Uint8}, Ptr{Uint8}), prob.env.ptr, prob.lp, filename, C_NULL)
    if ret != 0
        error("CPLEX: Error reading MPS file")
    end
end

function get_sense(prob::CPXproblem)
    sense_int = @cpx_ccall(getobjsen, Cint, (
                           Ptr{Void},
                           Ptr{Void},
                           ),
                           prob.env.ptr, prob.lp)
    if sense_int == 1
        sense = :Min
    elseif sense_int == -1
        sense = :Max
    else
        error("CPLEX: Error grabbing problem sense")
    end
end      

function set_sense!(prob::CPXproblem, sense)
    if sense == :Min
        @cpx_ccall(chgobjsen, Void, (Ptr{Void}, Ptr{Void}, Cint), prob.env.ptr, prob.lp, 1)
    elseif sense == :Max
        @cpx_ccall(chgobjsen, Void, (Ptr{Void}, Ptr{Void}, Cint), prob.env.ptr, prob.lp, -1)
    else
        error("Unrecognized objective sense $sense")
    end
end

function get_obj(prob::CPXproblem)
    nvars = num_var(prob)
    obj = Array(Float64, nvars)
    status = @cpx_ccall(getobj, Cint, (
                        Ptr{Void},
                        Ptr{Void},
                        Ptr{Float64},
                        Cint,
                        Cint
                        ),
                        prob.env.ptr, prob.lp, obj, 0, nvars-1)
    if status != 0
        error("CPLEX: error getting objective function")
    end
    return obj
end

function set_obj!(prob::CPXproblem, c::Vector)
    nvars = num_var(prob)
    status = @cpx_ccall(chgobj, Cint, (
                        Ptr{Void},
                        Ptr{Void},
                        Cint,
                        Ptr{Cint},
                        Ptr{Float64}
                        ),
                        prob.env.ptr, prob.lp, nvars, Cint[0:nvars-1], float(c))                    
    if status != 0
        error("CPLEX: error setting objective function")
    end
end

function write_problem(prob::CPXproblem, filename)
    ret = @cpx_ccall(writeprob, Cint, (Ptr{Void}, Ptr{Void}, Ptr{Cchar}, Ptr{Cchar}), prob.env.ptr, prob.lp, filename, "LP")
    if ret != 0
        error("CPLEX: Error writing problem data, status = $ret")
    end
end

function free_problem(prob::CPXproblem)
    status = @cpx_ccall(freeprob, Cint, (Ptr{Void}, Ptr{Void}), prob.env.ptr, prob.lp)
    if status != 0
        error("CPLEX: Error freeing problem")
    end
end

function close_CPLEX(env::CPXenv)
    status = @cpx_ccall(closeCPLEX, Cint, (Ptr{Void},), env.ptr)
    if status != 0
        error("CPLEX: Error freeing environment")
    end
end
