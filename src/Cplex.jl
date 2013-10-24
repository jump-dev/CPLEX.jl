module Cplex

    # exported functions
    export make_env, make_problem, read_file!, solve_lp!, get_solution, write_problem

    # to add: set sense, add row, add column

    # Temporary: eventually will use BinDeps to find appropriate path
    const cplexlibpath = "/opt/cplex/cplex/bin/x86-64_sles10_4.1/libcplex124.so"
    @osx_only begin
        const cplexlibpath = "/Users/huchette/Applications/IBM/ILOG/CPLEX_Studio_Preview1251/cplex/bin/x86-64_osx/libcplex1251.dylib"
    end

    # makes calling C functions a bit easier
    macro cpx_ccall(func, args...)
        f = "CPX$(func)"
        quote
            ccall(($f,cplexlibpath), $(args...))
        end
    end

    # -----
    # Types
    # -----
    type CPXenv
        ptr::Ptr{Void}
    end

    type CPXproblem
        env::CPXenv # Cplex environment
        lp::Ptr{Void} # Cplex problem (lp)
        nvars::Int # number of vars 
        ncons::Int # number of constraints

        function CPXproblem(env::CPXenv, lp::Ptr{Void})
            prob = new(env, lp, 0, 0)
            finalizer(prob, freeProblem)
            prob
        end
    end


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
        tmp = @cpx_ccall(createprob, Ptr{Void}, (Ptr{Void}, Ptr{Cint}, Ptr{Uint8}), env.ptr, status, "prob")
        if tmp == C_NULL
            error("CPLEX: Error creating problem, $(tmp)")
        end
        return CPXproblem(env, tmp)
    end



    # to load data, call CPXreadcopyprob
    function read_file!(prob::CPXproblem, filename)
        ret = @cpx_ccall(readcopyprob, Cint, (Ptr{Void}, Ptr{Void}, Ptr{Uint8}, Ptr{Uint8}), prob.env.ptr, prob.lp, filename, C_NULL)
        if ret != 0
            error("CPLEX: Error reading MPS file")
        end
        prob.n = @cpx_ccall(getnumcols, Cint, (Ptr{Void}, Ptr{Void}), prob.env.ptr, prob.lp)
        prob.m = @cpx_ccall(getnumrows, Cint, (Ptr{Void}, Ptr{Void}), prob.env.ptr, prob.lp)
    end

    function load_problem!(prob::CPXproblem, A, collb, colub, obj, rowlb, rowub)

        status = @cpx_ccall(addrows, 
                            Cint, 
                            (Ptr{Void}, Ptr{Void}, Cint, Cint, Cint, Prt{Float64}, Ptr{Uint8}, Ptr{Cint}, Ptr{Cint}, Ptr{Float64}, Ptr{Ptr{Uint8}}, Ptr{Ptr{Uint8}}), 
                            prob.env.ptr, 
                            prob.lp,
                            ccnt,
                            rcnt,
                            nzcnt,
                            rhs,
                            sense,
                            rmatbeg,
                            rmatind,
                            rmatval,
                            C_NULL,
                            C_NULL)
        if ret != 0   
            error("CPLEX: Error solving LP")
        end
    end

    function set_sense!(prob::CPXproblem, sense)
        if sense == :Min

        elseif sense == :Max

        else
            error("Unrecognized objective sense $sense")
        end
    end


    function solve_lp!(prob::CPXproblem)
        ret = @cpx_ccall(lpopt, Cint, (Ptr{Void}, Ptr{Void}), prob.env.ptr, prob.lp)
        if ret != 0
            error("CPLEX: Error solving LP")
        end
    end

    function get_solution(prob::CPXproblem)
        obj = [0.0]
        x   = Array(Float64, prob.n)
        status = Array(Cint, 1)
        ret = @cpx_ccall(solution,
                         Cint,
                         (Ptr{Void}, Ptr{Void}, Ptr{Cint}, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}),
                         prob.env.ptr,
                         prob.lp,
                         status,
                         obj,
                         x,
                         C_NULL,
                         C_NULL,
                         C_NULL)
        if ret != 0
           error("CPLEX: Error getting solution")
       end
       return(obj[1], x)
    end

    # to write output, call CPXwriteprob
    function write_problem(prob::CPXproblem, filename)
        ret = @cpx_ccall(writeprob, Int32, (Ptr{Void}, Ptr{Void}, Ptr{Uint8}, Ptr{Uint8}), prob.env.ptr, prob.lp, filename, C_NULL)
        if ret != 0
            error("CPLEX: Error writing problem data")
        end
    end

    # to free problem, call CPXfreeprob
    function free_Problem(prob::CPXproblem)
        status = @cpx_ccall(freeprob, Int32, (Ptr{Void}, Ptr{Void}), prob.env.ptr, prob.lp)
        if status != 0
            error("CPLEX: Error freeing problem")
        end
    end

    # to close env, call CPXcloseCPLEX
    function close_CPLEX(env::CPXenv)
        status = @cpx_ccall(closeCPLEX, Int32, (Ptr{Void},), env.ptr)
        if status != 0
            error("CPLEX: Error freeing environment")
        end
    end

end
