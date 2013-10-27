# makes calling C functions a bit easier
macro cpx_ccall(func, args...)
    f = "CPX$(func)"
    quote
        ccall(($f,cplexlibpath), $(args...))
    end
end

typealias IVec Vector{Cint}
typealias FVec Vector{Float64}
typealias CVec Vector{Cchar}
typealias CoeffMat Union(Matrix{Float64}, SparseMatrixCSC{Float64})

ivec(v::IVec) = v
fvec(v::FVec) = v
cvec(v::CVec) = v

ivec{I<:Integer}(v::Vector{I}) = convert(IVec, v)
fvec{T<:Real}(v::Vector{T}) = convert(FVec, v)
cvec(v::Vector{Char}) = convert(CVec, v)

# -----
# Types
# -----
type CPXenv
    ptr::Ptr{Void}

    function CPXenv(ptr::Ptr{Void})
        env = new(ptr)
        # finalizer(env, close_CPLEX)
        env
    end
end

type CPXproblem
    env::CPXenv # Cplex environment
    lp::Ptr{Void} # Cplex problem (lp)
    nvars::Int # number of vars 
    ncons::Int # number of constraints

    function CPXproblem(env::CPXenv, lp::Ptr{Void})
        prob = new(env, lp, 0, 0)
        finalizer(prob, free_problem)
        prob
    end
end

# Temporary: eventually will use BinDeps to find appropriate path
# const cplexlibpath = "/opt/cplex/cplex/bin/x86-64_sles10_4.1/libcplex124.so"
# @osx_only begin
#     const cplexlibpath = "/Users/huchette/Applications/IBM/ILOG/CPLEX_Studio_Preview1251/cplex/bin/x86-64_osx/libcplex1251.dylib"
# end
