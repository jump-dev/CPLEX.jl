# CPLEX.jl

`CPLEX.jl` is an interface to the [IBM® ILOG® CPLEX® Optimization
Studio](https://www.ibm.com/products/ilog-cplex-optimization-studio). It
provides an interface to the low-level C API, as well as an implementation of
the solver-independent
[`MathProgBase`](https://github.com/JuliaOpt/MathProgBase.jl) and
[`MathOptInterface`](https://github.com/JuliaOpt/MathOptInterface.jl) API's.

You cannot use `CPLEX.jl` without having purchased and installed a copy of CPLEX
Optimization Studio from [IBM](http://www.ibm.com/). However, CPLEX is
available for free to [academics and students](http://ibm.biz/Bdzvqw).

This package is available free of charge and in no way replaces or alters any
functionality of IBM's CPLEX Optimization Studio product.

*Note: This wrapper is maintained by the JuliaOpt community and is not
officially supported by IBM. However, we thank IBM for providing us with a
CPLEX license to test `CPLEX.jl` on Travis. If you are a commercial customer
interested in official support for CPLEX in Julia, let them know!.*


## Installation

First, you must obtain a copy of the CPLEX software and a license. Then, set the
appropriate environment vairable and run `Pkg.add("CPLEX")`.

```julia
# Linux
ENV["CPLEX_STUDIO_BINARIES"] = "/path/to/cplex/bin/x86-64_linux"

# OSX
ENV["CPLEX_STUDIO_BINARIES"] = "/path/to/cplex/bin/x86-64_osx"

# Windows
ENV["CPLEX_STUDIO_BINARIES"] = "C:/IBM/CPLEX_Studio128/cplex/bin/x64_win64"

import Pkg
Pkg.add("CPLEX")
```

## Help! I got `LoadError: Unable to locate CPLEX installation`

Which version of CPLEX are you trying to install? Currently, CPLEX.jl only
supports 1280 and 1290 given recent changes to
[the API](https://www.ibm.com/support/knowledgecenter/en/SSSA5P_12.9.0/ilog.odms.studio.help/CPLEX/ReleaseNotes/topics/releasenotes1290/removed.html).

If you want to support newer versions of CPLEX not listed above, [file an
issue](https://github.com/JuliaOpt/CPLEX.jl/issues/new) with the version
number you'd like to support. Some steps need to be taken (like checking for
new or renamed parameters) before CPLEX.jl can support new versions.

## Use with JuMP

You can use CPLEX with JuMP via the `CPLEX.Optimizer()` solver.

Solver parameters can be set in the ``CPLEX.Optimizer()`` object using
`MOI.RawParameter`. For example,
```julia
MOI.set(model, MOI.RawParameter("CPX_PARAM_EPINT"), 1e-8)
```

Parameters match those of the C API in the [CPLEX documentation](https://www.ibm.com/support/knowledgecenter/SSSA5P_12.9.0/ilog.odms.cplex.help/CPLEX/Parameters/topics/introListAlpha.html).
