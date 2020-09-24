# This file was used to create the list of deprecations when moving from v0.6.6
# to v0.7.0.

using CPLEX

io = open("deprecated_functions.jl", "w")
print(io, """
const _DEPRECATED_ERROR_MESSAGE = \"\"\"
The C API of CPLEX.jl has been rewritten to expose the complete C API, and
all old functions have been removed.

For example:

    is_point = CPLEX.cbcandidateispoint(cb_data)

is now

    is_point_P = Ref{Cint}()
    CPXcallbackcandidateispoint(cb_data, is_point_P)
    if ret != 0
        # Do something because the call failed
    end
    is_point = is_point_P[]

The new API is more verbose, but the names and function arguments are now
identical to the C API, documentation for which is available at:
https://www.ibm.com/support/knowledgecenter/SSSA5P_12.10.0/ilog.odms.cplex.help/refcallablelibrary/groups/homepagecallable.html

To revert to the old API, use:

    import Pkg
    Pkg.add(Pkg.PackageSpec(name = \"CPLEX\", version = v\"0.6\"))

Then restart Julia for the change to take effect.
\"\"\"
""")

exported_names = Base.names(CPLEX; all = false)
for name in Base.names(CPLEX; all = true)
    foo = getfield(CPLEX, name)
    if !(foo isa Function)
        continue
    elseif any(startswith.(Ref(string(foo)), ["#", "@", "_"]))
        continue
    end
    println(io, "$(foo)(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)")
    if name in exported_names
        println(io, "export $(foo)")
    end
    println(io)
end
close(io)
