using BenchmarkTools

struct VarRef
    x::UInt64
end
function f(A, B)
    s = 0
    for y in Y
        s += X[y]
    end
    s
end

m = 100_000_000
n = 100_000

X = rand(Int, n);
Y = mod.(rand(Int, m), n) .+ 1;
Z = VarRef.(Y);
U = Dict{VarRef, Int}();
for i in 1:length(X)
    U[VarRef(i)] = X[i]
end

display(@benchmark f($X, $Y))
display(@benchmark f($U, $Z))
