module Cplex

    # exported functions
    export makeenv, makeprob, readdata!, solvelp!, getsolution, writedata

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
        n::Int # number of vars 
        m::Int # number of constraints

        function CPXproblem(env::CPXenv, lp::Ptr{Void})
            prob = new(env, lp, 0, 0)
            finalizer(prob, freeProblem)
            prob
        end
    end


    # to make environment, call CPXopenCLPEX
    function makeenv()
        status = Array(Cint, 1)
        tmp = @cpx_ccall(openCPLEX, Ptr{Void}, (Ptr{Cint},), status)
        if tmp == C_NULL
            error("CPLEX: Error creating environment")
        end
        return(CPXenv(tmp))
    end

    # to make problem, call CPXcreateprob
    function makeprob(env::CPXenv)
        @assert env.ptr != C_NULL 
        status = Array(Cint, 1)
        tmp = @cpx_ccall(createprob, Ptr{Void}, (Ptr{Void}, Ptr{Cint}, Ptr{Uint8}), env.ptr, status, "prob")
        if tmp == C_NULL
            error("CPLEX: Error creating problem, $(tmp)")
        end
        return CPXproblem(env, tmp)
    end



    # to load data, call CPXreadcopyprob
    function readdata!(prob::CPXproblem, filename)
        ret = @cpx_ccall(readcopyprob, Cint, (Ptr{Void}, Ptr{Void}, Ptr{Uint8}, Ptr{Uint8}), prob.env.ptr, prob.lp, filename, C_NULL)
        if ret != 0
            error("CPLEX: Error reading MPS file")
        end
        prob.n = @cpx_ccall(getnumcols, Cint, (Ptr{Void}, Ptr{Void}), prob.env.ptr, prob.lp)
        prob.m = @cpx_ccall(getnumrows, Cint, (Ptr{Void}, Ptr{Void}), prob.env.ptr, prob.lp)
    end

    function solvelp!(prob::CPXproblem)
        ret = @cpx_ccall(lpopt, Cint, (Ptr{Void}, Ptr{Void}), prob.env.ptr, prob.lp)
        if ret != 0
            error("CPLEX: Error solving LP")
        end
    end

    function getsolution(prob::CPXproblem)
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
    function writedata(prob::CPXproblem, filename)
        ret = @cpx_ccall(writeprob, Int32, (Ptr{Void}, Ptr{Void}, Ptr{Uint8}, Ptr{Uint8}), prob.env.ptr, prob.lp, filename, C_NULL)
        if ret != 0
            error("CPLEX: Error writing problem data")
        end
    end

    # to free problem, call CPXfreeprob
    function freeProblem(prob::CPXproblem)
        status = @cpx_ccall(freeprob, Int32, (Ptr{Void}, Ptr{Void}), prob.env.ptr, prob.lp)
        if status != 0
            error("CPLEX: Error freeing problem")
        end
    end

    # to close env, call CPXcloseCPLEX
    function closeCPLEX(env::CPXenv)
        status = @cpx_ccall(closeCPLEX, Int32, (Ptr{Void},), env.ptr)
        if status != 0
            error("CPLEX: Error freeing environment")
        end
    end

end
