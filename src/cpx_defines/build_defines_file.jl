#=
    This file can be used to build new parameter file for versions of CPLEX.
    Typically the cpxconst.h file is bound at
    %CPLEX_STUDIO_DIRXXXX%/cplex/include/ilcplex where XXXX is the version number.

    You will probably need to edit the cpx_defines file to remove the duplicate
    CPX_VERSIONSTRING entry to annoying warnings.
=#
const rINT_DEFINE = r"\#define\s+(CPX[a-zA-Z0-9\_]+)\s+([0-9\-]+)[\r\n]+"
const rDOUBLE_DEFINE = r"\#define\s+(CPX[a-zA-Z0-9\_]+)\s+([0-9\-]+\.[0-9]+E[\-\+][0-9]+)[\r\n]+"
const rCHAR_DEFINE = r"\#define\s+(CPX[a-zA-Z0-9\_]+)\s+(\'[A-Z0-9]+?\')[\r\n]+"
const rSTR_DEFINE = r"\#define\s+(CPX[a-zA-Z0-9\_]+)\s+(\".+?\")[\r\n]+"is
const rCPXPARAM = r"\#define\s+(CPXPARAM\_[a-zA-Z\_]+)\s+([0-9]+)[\r\n]+"
const rCPX_PARAM = r"\#define\s+(CPX\_PARAM\_[A-Z]+)\s+([0-9]+)[\r\n]+"

function build_defines_file(filename, defines_filename)
    cpx_const = readstring(filename)
    open(defines_filename, "w") do io
        for param in matchall(rSTR_DEFINE, cpx_const)
            m = match(rSTR_DEFINE, param)
            println(io, "const $(m[1]) = $(m[2])")
        end

        for param in matchall(rDOUBLE_DEFINE, cpx_const)
            m = match(rDOUBLE_DEFINE, param)
            println(io, "const $(m[1]) = Cdouble($(m[2]))")
        end

        for param in matchall(rINT_DEFINE, cpx_const)
            m = match(rINT_DEFINE, param)
            println(io, "const $(m[1]) = Cint($(m[2]))")
        end

        for param in matchall(rCHAR_DEFINE, cpx_const)
            m = match(rCHAR_DEFINE, param)
            println(io, "const $(m[1]) = Cchar($(m[2]))")
        end

    end
end


function build_params_file(filename, params_filename)
    cpx_const = readstring(filename)
    open(params_filename, "w") do io
        println(io, "const CPX_PARAMS = Dict{String, Cint}(")
        for param in matchall(rCPX_PARAM, cpx_const)
            m = match(rCPX_PARAM, param)
            println(io, "\"$(m[1])\" => Cint($(m[2])),")
        end

        for param in matchall(rCPXPARAM, cpx_const)
            m = match(rCPXPARAM, param)
            println(io, "\"$(m[1])\" => Cint($(m[2])),")
        end
        println(io, ")")
    end
end

# Example calls

build_defines_file("cpxconst.h", "cpx_defines_1270.jl")
build_params_file("cpxconst.h", "cpx_params_1270.jl")
