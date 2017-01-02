tests = ["low_level_api",
         "lp_01",
#        "lp_01a",
#        "lp_01b",
         "lp_02",
         "lp_03",
         "mip_01",
         "qp_01",
         "qp_02",
         "qcqp_01",
         "env",
         "mathprog"]

for t in tests
    fp = "$(t).jl"
    println("running $(fp) ...")
    evalfile(fp)
end
