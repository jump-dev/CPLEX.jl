# strategy: take as input name of parameter. Map this to Int and query as to type of argument. Based on this answer (Int, Bool, Char, Num), call correct CPX function

const CPX_INFBOUND = 1e20
const CPX_STR_PARAM_MAX = 512

function get_param_type(model::Model, indx::Int)
  ptype = Array(Cint, 1)
  stat = @cpx_ccall(getparamtype, Cint, (
                    Ptr{Void},
                    Cint,
                    Ptr{Cint}
                    ),
                    model.env.ptr, indx, ptype)
  if stat != 0
    error("CPLEX: error grabbing parameter type")
  end
  if ptype[1] == 0
    ret = :None
  elseif ptype[1] == 1
    ret = :Int
  elseif ptype[1] == 2
    ret = :Double
  elseif ptype[1] == 3
    ret = :String
  else
    error("Parameter type not recognized")
  end

  return ret
end

get_param_type(model::Model, name::ASCIIString) = get_param_type(model, paramName2Indx[name])

function set_param!(model::Model, pindx::Int, val, ptype::Symbol)
  if ptype == :Int
    stat = @cpx_ccall(setintparam, Cint, (Ptr{Void}, Cint, Cint), model.env.ptr, pindx, int(val))
  elseif ptype == :Double
    stat = @cpx_ccall(setdblparam, Cint, (Ptr{Void}, Cint, Cdouble), model.env.ptr, pindx, float(val))
  elseif ptype == :String
    stat = @cpx_ccall(setstrparam, Cint, (Ptr{Void}, Cint, Ptr{Cchar}), model.env.ptr, pindx, Cchar[val...])
  elseif ptype == :None
    warn("Trying to set a parameter of type None; doing nothing")
  else
    error("Unrecognized parameter type")
  end
  if stat != 0
    throw(CplexError(model.env, stat))
  end
end

set_param!(model::Model, pindx::Int, val) = set_param!(model, pindx, val, get_param_type(model, pindx))

set_param!(model::Model, pname::ASCIIString, val) = set_param!(model, paramName2Indx[pname], val)

# set_params!(prob::Model, args...)
#   for (name, v) in args
#     set_param!(prob, string(name), v)
#   end
# end

function get_param(model::Model, pindx::Int, ptype::Symbol)
  if ptype == :Int
    val = Array(Cint, 1)
    stat = @cpx_ccall(getintparam, Cint, (Ptr{Void}, Cint, Cint), model.env.ptr, pindx, val)
    ret = val[1]
  elseif ptype == :Double
    val = Array(Cdouble, 1)
    stat = @cpx_ccall(getdblparam, Cint, (Ptr{Void}, Cint, Cdouble), model.env.ptr, pindx, val)
    ret = val[1]
  elseif ptype == :String
    buf = Array(Cchar, CPX_STR_PARAM_MAX) # max str param length is 512 in Cplex 12.51
    stat = @cpx_ccall(getstrparam, Cint, (Ptr{Void}, Cint, Ptr{Cchar}), model.env.ptr, pindx, buf)
    ret = bytestring(pointer(buf))
  elseif ptype == :None
    warn("Trying to set a parameter of type None; doing nothing")
  else
    error("Unrecognized parameter type")
  end
  if stat != 0
    throw(CplexError(model.env, stat))
  end
  return ret
end

get_param(model::Model, pindx::Int) = get_param(model, pindx, get_param_type(model, pindx))

get_param(model::Model, pname::ASCIIString) = get_param(model, paramName2Indx[pname])

# grep "#define" cpxconst.h | grep "CPX_PARAM_" | awk '{ printf("\"%s\" => %s,\n",$2,$3) }'
const paramName2Indx = [
"CPX_PARAM_ADVIND" => 1001,
"CPX_PARAM_AGGFILL" => 1002,
"CPX_PARAM_AGGIND" => 1003,
"CPX_PARAM_BASINTERVAL" => 1004,
"CPX_PARAM_CFILEMUL" => 1005,
"CPX_PARAM_CLOCKTYPE" => 1006,
"CPX_PARAM_CRAIND" => 1007,
"CPX_PARAM_DEPIND" => 1008,
"CPX_PARAM_DPRIIND" => 1009,
"CPX_PARAM_PRICELIM" => 1010,
"CPX_PARAM_EPMRK" => 1013,
"CPX_PARAM_EPOPT" => 1014,
"CPX_PARAM_EPPER" => 1015,
"CPX_PARAM_EPRHS" => 1016,
"CPX_PARAM_FASTMIP" => 1017,
"CPX_PARAM_SIMDISPLAY" => 1019,
"CPX_PARAM_ITLIM" => 1020,
"CPX_PARAM_ROWREADLIM" => 1021,
"CPX_PARAM_NETFIND" => 1022,
"CPX_PARAM_COLREADLIM" => 1023,
"CPX_PARAM_NZREADLIM" => 1024,
"CPX_PARAM_OBJLLIM" => 1025,
"CPX_PARAM_OBJULIM" => 1026,
"CPX_PARAM_PERIND" => 1027,
"CPX_PARAM_PERLIM" => 1028,
"CPX_PARAM_PPRIIND" => 1029,
"CPX_PARAM_PREIND" => 1030,
"CPX_PARAM_REINV" => 1031,
"CPX_PARAM_REVERSEIND" => 1032,
"CPX_PARAM_RFILEMUL" => 1033,
"CPX_PARAM_SCAIND" => 1034,
"CPX_PARAM_SCRIND" => 1035,
"CPX_PARAM_SINGLIM" => 1037,
"CPX_PARAM_SINGTOL" => 1038,
"CPX_PARAM_TILIM" => 1039,
"CPX_PARAM_XXXIND" => 1041,
"CPX_PARAM_PREDUAL" => 1044,
"CPX_PARAM_EPOPT_H" => 1049,
"CPX_PARAM_EPRHS_H" => 1050,
"CPX_PARAM_PREPASS" => 1052,
"CPX_PARAM_DATACHECK" => 1056,
"CPX_PARAM_REDUCE" => 1057,
"CPX_PARAM_PRELINEAR" => 1058,
"CPX_PARAM_LPMETHOD" => 1062,
"CPX_PARAM_QPMETHOD" => 1063,
"CPX_PARAM_WORKDIR" => 1064,
"CPX_PARAM_WORKMEM" => 1065,
"CPX_PARAM_THREADS" => 1067,
"CPX_PARAM_CONFLICTDISPLAY" => 1074,
"CPX_PARAM_SIFTDISPLAY" => 1076,
"CPX_PARAM_SIFTALG" => 1077,
"CPX_PARAM_SIFTITLIM" => 1078,
"CPX_PARAM_MPSLONGNUM" => 1081,
"CPX_PARAM_MEMORYEMPHASIS" => 1082,
"CPX_PARAM_NUMERICALEMPHASIS" => 1083,
"CPX_PARAM_FEASOPTMODE" => 1084,
"CPX_PARAM_PARALLELMODE" => 1109,
"CPX_PARAM_TUNINGMEASURE" => 1110,
"CPX_PARAM_TUNINGREPEAT" => 1111,
"CPX_PARAM_TUNINGTILIM" => 1112,
"CPX_PARAM_TUNINGDISPLAY" => 1113,
"CPX_PARAM_WRITELEVEL" => 1114,
"CPX_PARAM_RANDOMSEED" => 1124,
"CPX_PARAM_DETTILIM" => 1127,
"CPX_PARAM_FILEENCODING" => 1129,
"CPX_PARAM_APIENCODING" => 1130,
"CPX_PARAM_SOLUTIONTARGET" => 1131,
"CPX_PARAM_CLONELOG" => 1132,
"CPX_PARAM_TUNINGDETTILIM" => 1139,
"CPX_PARAM_ALL_MIN" => 1000,
"CPX_PARAM_ALL_MAX" => 6000,
"CPX_PARAM_BARDSTART" => 3001,
"CPX_PARAM_BAREPCOMP" => 3002,
"CPX_PARAM_BARGROWTH" => 3003,
"CPX_PARAM_BAROBJRNG" => 3004,
"CPX_PARAM_BARPSTART" => 3005,
"CPX_PARAM_BARALG" => 3007,
"CPX_PARAM_BARCOLNZ" => 3009,
"CPX_PARAM_BARDISPLAY" => 3010,
"CPX_PARAM_BARITLIM" => 3012,
"CPX_PARAM_BARMAXCOR" => 3013,
"CPX_PARAM_BARORDER" => 3014,
"CPX_PARAM_BARSTARTALG" => 3017,
"CPX_PARAM_BARCROSSALG" => 3018,
"CPX_PARAM_BARQCPEPCOMP" => 3020,
"CPX_PARAM_BRDIR" => 2001,
"CPX_PARAM_BTTOL" => 2002,
"CPX_PARAM_CLIQUES" => 2003,
"CPX_PARAM_COEREDIND" => 2004,
"CPX_PARAM_COVERS" => 2005,
"CPX_PARAM_CUTLO" => 2006,
"CPX_PARAM_CUTUP" => 2007,
"CPX_PARAM_EPAGAP" => 2008,
"CPX_PARAM_EPGAP" => 2009,
"CPX_PARAM_EPINT" => 2010,
"CPX_PARAM_MIPDISPLAY" => 2012,
"CPX_PARAM_MIPINTERVAL" => 2013,
"CPX_PARAM_INTSOLLIM" => 2015,
"CPX_PARAM_NODEFILEIND" => 2016,
"CPX_PARAM_NODELIM" => 2017,
"CPX_PARAM_NODESEL" => 2018,
"CPX_PARAM_OBJDIF" => 2019,
"CPX_PARAM_MIPORDIND" => 2020,
"CPX_PARAM_RELOBJDIF" => 2022,
"CPX_PARAM_STARTALG" => 2025,
"CPX_PARAM_SUBALG" => 2026,
"CPX_PARAM_TRELIM" => 2027,
"CPX_PARAM_VARSEL" => 2028,
"CPX_PARAM_BNDSTRENIND" => 2029,
"CPX_PARAM_HEURFREQ" => 2031,
"CPX_PARAM_MIPORDTYPE" => 2032,
"CPX_PARAM_CUTSFACTOR" => 2033,
"CPX_PARAM_RELAXPREIND" => 2034,
"CPX_PARAM_PRESLVND" => 2037,
"CPX_PARAM_BBINTERVAL" => 2039,
"CPX_PARAM_FLOWCOVERS" => 2040,
"CPX_PARAM_IMPLBD" => 2041,
"CPX_PARAM_PROBE" => 2042,
"CPX_PARAM_GUBCOVERS" => 2044,
"CPX_PARAM_STRONGCANDLIM" => 2045,
"CPX_PARAM_STRONGITLIM" => 2046,
"CPX_PARAM_FRACCAND" => 2048,
"CPX_PARAM_FRACCUTS" => 2049,
"CPX_PARAM_FRACPASS" => 2050,
"CPX_PARAM_FLOWPATHS" => 2051,
"CPX_PARAM_MIRCUTS" => 2052,
"CPX_PARAM_DISJCUTS" => 2053,
"CPX_PARAM_AGGCUTLIM" => 2054,
"CPX_PARAM_MIPCBREDLP" => 2055,
"CPX_PARAM_CUTPASS" => 2056,
"CPX_PARAM_MIPEMPHASIS" => 2058,
"CPX_PARAM_SYMMETRY" => 2059,
"CPX_PARAM_DIVETYPE" => 2060,
"CPX_PARAM_RINSHEUR" => 2061,
"CPX_PARAM_SUBMIPNODELIM" => 2062,
"CPX_PARAM_LBHEUR" => 2063,
"CPX_PARAM_REPEATPRESOLVE" => 2064,
"CPX_PARAM_PROBETIME" => 2065,
"CPX_PARAM_POLISHTIME" => 2066,
"CPX_PARAM_REPAIRTRIES" => 2067,
"CPX_PARAM_EPLIN" => 2068,
"CPX_PARAM_EPRELAX" => 2073,
"CPX_PARAM_FPHEUR" => 2098,
"CPX_PARAM_EACHCUTLIM" => 2102,
"CPX_PARAM_SOLNPOOLCAPACITY" => 2103,
"CPX_PARAM_SOLNPOOLREPLACE" => 2104,
"CPX_PARAM_SOLNPOOLGAP" => 2105,
"CPX_PARAM_SOLNPOOLAGAP" => 2106,
"CPX_PARAM_SOLNPOOLINTENSITY" => 2107,
"CPX_PARAM_POPULATELIM" => 2108,
"CPX_PARAM_MIPSEARCH" => 2109,
"CPX_PARAM_MIQCPSTRAT" => 2110,
"CPX_PARAM_ZEROHALFCUTS" => 2111,
"CPX_PARAM_POLISHAFTEREPAGAP" => 2126,
"CPX_PARAM_POLISHAFTEREPGAP" => 2127,
"CPX_PARAM_POLISHAFTERNODE" => 2128,
"CPX_PARAM_POLISHAFTERINTSOL" => 2129,
"CPX_PARAM_POLISHAFTERTIME" => 2130,
"CPX_PARAM_MCFCUTS" => 2134,
"CPX_PARAM_MIPKAPPASTATS" => 2137,
"CPX_PARAM_AUXROOTTHREADS" => 2139,
"CPX_PARAM_INTSOLFILEPREFIX" => 2143,
"CPX_PARAM_PROBEDETTIME" => 2150,
"CPX_PARAM_POLISHAFTERDETTIME" => 2151,
"CPX_PARAM_LANDPCUTS" => 2152,
"CPX_PARAM_NETITLIM" => 5001,
"CPX_PARAM_NETEPOPT" => 5002,
"CPX_PARAM_NETEPRHS" => 5003,
"CPX_PARAM_NETPPRIIND" => 5004,
"CPX_PARAM_NETDISPLAY" => 5005,
"CPX_PARAM_QPNZREADLIM" => 4001,
"CPX_PARAM_CALCQCPDUALS" => 4003,
"CPX_PARAM_QPMAKEPSDIND" => 4010
]
