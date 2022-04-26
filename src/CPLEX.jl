# Copyright (c) 2013: Joey Huchette and contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

module CPLEX

const _DEPS_FILE = joinpath(dirname(@__DIR__), "deps", "deps.jl")
if isfile(_DEPS_FILE)
    include(_DEPS_FILE)
else
    error("CPLEX not properly installed. Please run Pkg.build(\"CPLEX\")")
end

using CEnum
import SparseArrays

function _get_version_number()
    if libcplex == "julia_registryci_automerge"
        return VersionNumber(12, 10, 0)  # Fake a valid version for AutoMerge.
    end
    stat = Ref{Cint}()
    env = ccall((:CPXopenCPLEX, libcplex), Ptr{Cvoid}, (Ptr{Cint},), stat)
    p = ccall((:CPXversion, libcplex), Cstring, (Ptr{Cvoid},), env)
    version_string = unsafe_string(p)
    ccall((:CPXcloseCPLEX, libcplex), Cint, (Ptr{Ptr{Cvoid}},), Ref(env))
    return VersionNumber(parse.(Int, split(version_string, ".")[1:3])...)
end

const _CPLEX_VERSION = _get_version_number()

if _CPLEX_VERSION == v"12.10.0"
    include("gen1210/libcpx_common.jl")
    include("gen1210/libcpx_api.jl")
elseif _CPLEX_VERSION == v"20.1.0"
    include("gen2010/libcpx_common.jl")
    include("gen2010/libcpx_api.jl")
elseif _CPLEX_VERSION == v"22.1.0"
    include("gen2210/ctypes.jl")
    include("gen2210/libcpx_common.jl")
    include("gen2210/libcpx_api.jl")
else
    error("""
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
https://github.com/jump-dev/CPLEX.jl.""")
end

include("MOI/MOI_wrapper.jl")
include("MOI/MOI_callbacks.jl")
include("MOI/conflicts.jl")
include("MOI/indicator_constraint.jl")

# CPLEX exports all `CPXxxx` symbols. If you don't want all of these symbols in
# your environment, then use `import CPLEX` instead of `using CPLEX`.

for sym in filter(s -> startswith("$s", "CPX"), names(@__MODULE__, all = true))
    @eval export $sym
end

end
