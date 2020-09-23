# TODO(odow):
#
# This script can be used to build the C interface to Gurobi. However, it requires
# you to manually do the following steps first:
#
# 1) Copy cplex.h from CPLEX into this /scripts directory
# 2) Copy cpxconst.h from CPLEX into this /scripts directory

import Clang

const LIBCPX_HEADERS = [
    joinpath(@__DIR__, "cplex.h"),
    joinpath(@__DIR__, "cpxconst.h"),
]

const GEN_DIR = joinpath(dirname(@__DIR__), "src", "gen")

wc = Clang.init(
    headers = LIBCPX_HEADERS,
    output_file = joinpath(GEN_DIR, "libcpx_api.jl"),
    common_file = joinpath(GEN_DIR, "libcpx_common.jl"),
    clang_args = String[
        "-I" * header for header in Clang.find_std_headers()
    ],
    header_wrapped = (root, current) -> root == current,
    header_library = x -> "libcplex",
    clang_diagnostics = true,
)

run(wc)

function manual_corrections_common()
    filename = joinpath(GEN_DIR, "libcpx_common.jl")
    lines = readlines(filename; keep = true)
    for (i, line) in enumerate(lines)
        if occursin("CPXINT_MAX", line)
            lines[i] = replace(line, "= INT_MAX" => "= $(typemax(Cint))")
        elseif occursin("CPXINT_MIN", line)
            lines[i] = replace(line, "= INT_MIN" => "= $(typemin(Cint))")
        elseif occursin("= version", line)
            lines[i] = replace(line, "= version" => "= nothing")
        elseif occursin("= NAN", line)
            lines[i] = replace(line, "= NAN" => "= NaN")
        elseif occursin("# Skipping Typedef: CXType_FunctionProto ", line)
            lines[i] = replace(
                replace(
                    line,
                    "# Skipping Typedef: CXType_FunctionProto " => "const "
                ),
                '\n' => " = Ptr{Cvoid}\n"
            )
        end
    end
    open(filename, "w") do io
        print.(Ref(io), lines)
    end
end
manual_corrections_common()

function manual_corrections_api()
    filename = joinpath(GEN_DIR, "libcpx_api.jl")
    lines = readlines(filename; keep = true)
    for (i, line) in enumerate(lines)
        if occursin("Cstring", line)
            lines[i] = replace(line, "Cstring" => "Ptr{Cchar}")
        end
    end
    open(filename, "w") do io
        print.(Ref(io), lines)
    end
end
manual_corrections_api()

rm(joinpath(GEN_DIR, "LibTemplate.jl"))
