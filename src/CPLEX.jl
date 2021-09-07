module CPLEX

const _DEPS_FILE = joinpath(dirname(@__DIR__), "deps", "deps.jl")
if isfile(_DEPS_FILE)
    include(_DEPS_FILE)
else
    error("CPLEX not properly installed. Please run Pkg.build(\"CPLEX\")")
end

using CEnum
import SparseArrays

const _CPLEX_VERSION = if libcplex == "julia_registryci_automerge"
    VersionNumber(12, 10, 0)  # Fake a valid version for AutoMerge.
else
    let
        status_p = Ref{Cint}()
        env = ccall(
            (:CPXopenCPLEX, libcplex),
            Ptr{Cvoid},
            (Ptr{Cint},),
            status_p,
        )
        p = ccall((:CPXversion, libcplex), Cstring, (Ptr{Cvoid},), env)
        version_string = unsafe_string(p)
        ccall((:CPXcloseCPLEX, libcplex), Cint, (Ptr{Ptr{Cvoid}},), Ref(env))
        VersionNumber(parse.(Int, split(version_string, ".")[1:3])...)
    end
end

if _CPLEX_VERSION == v"12.10.0"
    include("gen1210/ctypes.jl")
    include("gen1210/libcpx_common.jl")
    include("gen1210/libcpx_api.jl")
elseif _CPLEX_VERSION == v"20.1.0"
    include("gen2010/ctypes.jl")
    include("gen2010/libcpx_common.jl")
    include("gen2010/libcpx_api.jl")
else
    error(
        """
  You have installed version $_CPLEX_VERSION of CPLEX, which is not supported
  by CPLEX.jl. We require CPLEX version 12.10 or 20.1.

  After installing CPLEX, run:

      import Pkg
      Pkg.rm("CPLEX")
      Pkg.add("CPLEX")

  Make sure you set the environment variable `CPLEX_STUDIO_BINARIES` following
  the instructions in the CPLEX.jl README, which is available at
  https://github.com/jump-dev/CPLEX.jl.

  If you have a newer version of CPLEX installed, changes may need to be made
  to the Julia code. Please open an issue at
  https://github.com/jump-dev/CPLEX.jl.
  """,
    )
end

include("MOI/MOI_wrapper.jl")
include("MOI/MOI_callbacks.jl")
include("MOI/conflicts.jl")
include("MOI/indicator_constraint.jl")

# CPLEX exports all `CPXxxx` symbols. If you don't want all of these symbols in
# your environment, then use `import CPLEX` instead of `using CPLEX`.

for sym in names(@__MODULE__, all = true)
    sym_string = string(sym)
    if startswith(sym_string, "CPX")
        @eval export $sym
    end
end

include("deprecated_functions.jl")

# Special overload to deprecate the `model.inner` field access.
function Base.getproperty(opt::Optimizer, key::Symbol)
    if key == :inner
        error(_DEPRECATED_ERROR_MESSAGE)
    end
    return getfield(opt, key)
end

end
