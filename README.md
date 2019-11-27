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
appropriate environment variable and run `Pkg.add("CPLEX")`.

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
supports 12.8, 12.9, and 12.10 given recent changes to
[the API](https://www.ibm.com/support/knowledgecenter/en/SSSA5P_12.9.0/ilog.odms.studio.help/CPLEX/ReleaseNotes/topics/releasenotes1290/removed.html).

If you want to support newer versions of CPLEX not listed above, [file an
issue](https://github.com/JuliaOpt/CPLEX.jl/issues/new) with the version
number you'd like to support. Some steps need to be taken (like checking for
new or renamed parameters) before CPLEX.jl can support new versions.

## Use with JuMP

You can use CPLEX with JuMP via the `CPLEX.Optimizer()` solver.
Set solver parameters using `set_optimizer_attribute` from `JuMP`:

```julia
model = Model(CPLEX.Optimizer)
set_optimizer_attribute(model, "CPX_PARAM_EPINT", 1e-8)
```

Parameters match those of the C API in the [CPLEX documentation](https://www.ibm.com/support/knowledgecenter/SSSA5P_12.9.0/ilog.odms.cplex.help/CPLEX/Parameters/topics/introListAlpha.html).

## Annotating a model for Benders Decomposition

To use the built in Benders Decomposition in CPLEX, do the following:
1) Create a direct model in JuMP: `model = JuMP.direct_model(CPLEX.Optimizer())`. This allows the varialbes form your JuMP model to map to the CPLEX inner model.
2) Access the inner model: `model_inner = JuMP.backend(model).inner`
3) Create a new annotation (https://www.ibm.com/support/knowledgecenter/SSSA5P_12.9.0/ilog.odms.cplex.help/refcallablelibrary/cpxapi/newlongannotation.html): `newlongannotation(model_inner, "cpxBendersPartition", Int32(0))`
4) Annotate your model using the wrapped function `setlongannotations` (https://www.ibm.com/support/knowledgecenter/SSSA5P_12.9.0/ilog.odms.cplex.help/refcallablelibrary/cpxapi/setlongannotations.html).
5) Set the `CPXPARAM_Benders_Strategy` using `MOI.RawParameter` as described in the previous section. For annotated models use either strategy 0, 1, or 2 (see CPLEX documentation). If you don't want to provide CPLEX with annotations, it can do the decomposition automatically by using strategy 3. If you take the automatic route, then ignore steps 1-4.
