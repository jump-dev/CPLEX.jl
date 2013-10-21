module Cplex

    # exported functions
    export makeenv, makeprob, readdata, solvelp,getsolution, writedata

    # Temporary: eventually will use BinDeps to find appropriate path
    const cplexlibpath = "/opt/cplex/cplex/bin/x86-64_sles10_4.1/libcplex124.so"

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
        env::Ptr{Void}
    end

    type CPXlp
        lp::Ptr{Void}
    end


    # to make environment, call CPXopenCLPEX
    function makeenv()
	status = Array(Cint, 1)
        tmp = @cpx_ccall(openCPLEX, Ptr{Void}, (Ptr{Cint},), status)
	println("env status = $(status)")
	if tmp == C_NULL
            error("CPLEX: Error creating environment")
        end
        return(CPXenv(tmp))
    end

    # to make problem, call CPXcreateprob
    function makeprob(env::CPXenv)
        @assert env.env != C_NULL 
	status = Array(Cint, 1)
	tmp = @cpx_ccall(createprob, Ptr{Void}, (Ptr{Void}, Ptr{Cint}, Ptr{Uint8}), env.env, status, "prob")
        if tmp == C_NULL
            error("CPLEX: Error creating problem, $(tmp)")
        end
        return CPXlp(tmp)
    end

    # to load data, call CPXreadcopyprob
    function readdata(env::CPXenv, lp::CPXlp, filename)
        ret = @cpx_ccall(readcopyprob, Cint, (Ptr{Void}, Ptr{Void}, Ptr{Uint8}, Ptr{Uint8}), env.env, lp.lp, filename, C_NULL)
        if ret != 0
            error("CPLEX: Error reading MPS file")
        end
    end

    function solvelp(env::CPXenv, lp::CPXlp)
        ret = @cpx_ccall(lpopt, Cint, (Ptr{Void}, Ptr{Void}), env.env, lp.lp)
        if ret != 0
            error("CPLEX: Error solving LP")
        end
    end

    function getsolution(env::CPXenv, lp::CPXlp)
        obj = [0.0]
	x   = Array(Ptr{Cdouble}, 1)
	status = Array(Cint, 1)
	ret = @cpx_ccall(solution,
                         Cint,
                         (Ptr{Void}, Ptr{Void}, Ptr{Cint}, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}),
                         env.env,
                         lp.lp,
                         status,
                         obj,
                         x,
                         C_NULL,
                         C_NULL,
                         C_NULL)
        if ret != 0
           error("CPLEX: Error getting solution")
       end
       return(obj[1])
    end

    # to write output, call CPXwriteprob
    function writedata(env::CPXenv, lp::CPXlp, filename)
        ret = @cpx_ccall(writeprob, Int32, (Ptr{Void}, Ptr{Void}, Ptr{Uint8}, Ptr{Uint8}), env.env, lp.lp, filename, C_NULL)
        if ret != 0
            error("CPLEX: Error writing problem data")
        end
    end
    # to free problem, call CPXfreeprob

    # to close env, call CPXcloseCPLEX


end
