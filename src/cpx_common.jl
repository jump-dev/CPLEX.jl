# makes calling C functions a bit easier
macro cpx_ccall(func, args...)
    f = "CPX$(func)"
    args = map(esc,args)
    @static if (VERSION >= v"0.7.0-DEV.3382" && Sys.isunix()) || (VERSION < v"0.7.0-DEV.3382" && is_unix())
        return quote
            ccall(($f,libcplex), $(args...))
        end
    end
    @static if (VERSION >= v"0.7.0-DEV.3382" && Sys.iswindows()) || (VERSION < v"0.7.0-DEV.3382" && is_windows())
        @static if VERSION < v"0.6.0-dev.1512" # probably julia PR #15850
            return quote
                ccall(($f,libcplex), stdcall, $(args...))
            end
        else
            return quote
                ccall(($f,libcplex), $(esc(:stdcall)), $(args...))
            end
        end
    end
end

macro cpx_ccall_intercept(model, func, args...)
    # TODO fix for 0.7 and above (using cpx_call instead temporarily)
    if VERSION < v"0.7.0-DEV.3382"
        args = map(esc,args)
        quote
            ccall(:jl_exit_on_sigint, Nothing, (Cint,), convert(Cint,0))
            ret = try
                $(Expr(:macrocall, Symbol("@cpx_ccall"), esc(func), args...))
            catch ex
                println("Caught exception")
                if !isinteractive()
                    ccall(:jl_exit_on_sigint, Nothing, (Cint,), convert(Cint,1))
                end
                if isa(ex, InterruptException)
                    model.terminator[1] = 1
                end
                rethrow(ex)
            end
            if !isinteractive()
                ccall(:jl_exit_on_sigint, Nothing, (Cint,), convert(Cint,1))
            end
            ret
        end
    end
end

const GChars = Union{Cchar, Char}
const IVec = Vector{Cint}
const FVec = Vector{Cdouble}
const CVec = Vector{Cchar}
const CoeffMat = Union{AbstractMatrix{Cdouble}, SparseMatrixCSC{Cdouble}}
Bounds{T<:Real} = Union{T, Vector{T}}

const GCharOrVec = Union{Cchar, Char, Vector{Cchar}, Vector{Char}}

# empty vector & matrix (for the purpose of supplying default arguments)
const emptyfvec = Vector{Float64}(undef, 0)
const emptyfmat = Matrix{Float64}(undef, 0, 0)

cchar(c::Cchar) = c
cchar(c::Char) = convert(Cchar, c)

ivec(v::IVec) = v
fvec(v::FVec) = v
cvec(v::CVec) = v

ivec(v::Vector) = convert(IVec, v)
fvec(v::Vector) = convert(FVec, v)
cvec(v::Vector) = convert(CVec, v)

# cvecx(v, n) and fvecx(v, n)
# converts v into a vector of Cchar or Float64 of length n,
# where v can be either a scalar or a vector of length n.

_chklen(v, n::Integer) = (length(v) == n || error("Inconsistent argument dimensions."))

cvecx(c::GChars, n::Integer) = fill(cchar(c), n)
cvecx(c::Vector{Cchar}, n::Integer) = (_chklen(c, n); c)
cvecx(c::Vector{Char}, n::Integer) = (_chklen(c, n); convert(Vector{Cchar}, c))

fvecx(v::Real, n::Integer) = fill(Float64(v), n)
fvecx(v::Vector{Float64}, n::Integer) = (_chklen(v, n); v)
fvecx(v::Vector{T}, n::Integer) where {T<:Real} = (_chklen(v, n); convert(Vector{Float64}, v))
