Module Cplex

    # exported functions
    export makeenv, maketask, readdata, optimize, writedata

    # Temporary: eventually will use BinDeps to find appropriate path
    const cplexlibpath = "/Users/huchette/Applications/IBM/ILOG/CPLEX_Studio_Preview125/cplex/lib/x86-64_darwin/static_pic/libilocplex.a"

    # makes calling C functions a bit easier
    macro cplex_ccall(func, args...)
        f = "CPX$(func)"
        quote
            ccall(($f,cplexlibpath), $(args...))
        end
    end

    # to make environment, call CPXopenCLPEX

    # to make problem, call CPXcreateprob

    # to solve problem, call CPXlpopt (for lp)

    # to get solution, call CPXsolution

    # to free problem, call CPXfreeprob

    # to close env, call CPXcloseCPLEX


end
