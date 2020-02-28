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
4) Annotate your model using the wrapped function `setlongannotations` (https://www.ibm.com/support/knowledgecenter/SSSA5P_12.9.0/ilog.odms.cplex.help/refcallablelibrary/cpxapi/setlongannotations.html). NOTE: See example below to avoid issues with setlongannotations.
5) Set the `CPXPARAM_Benders_Strategy` using `MOI.RawParameter` as described in the previous section. For annotated models use either strategy 0, 1, or 2 (see CPLEX documentation). If you don't want to provide CPLEX with annotations, it can do the decomposition automatically by using strategy 3. If you take the automatic route, then ignore steps 1-4.

## Example
```Julia
using JuMP, MathOptInterface, CPLEX
const MOI = MathOptInterface
#=
Simple Example Model for Benders Decomposition with CPLEX
min  x + y + z
s.t. x + y     = 1
     x +     z = 1
     0<= x,y,z <= 1
=#

#Create Model
#Model must be declared as a direct model to allow for annotations
m = direct_model(CPLEX.Optimizer())
@variable(m, x, Bin)
@variable(m, 0 <= y <= 1)
@variable(m, 0 <= z <= 1)
@constraint(m, x + y == 1)
@constraint(m, x + z == 1)
@objective(m, Min, x + y + z)

#Access Inner Model for Annotations
m_inner = backend(m).inner

#Create Annotation Placeholder
newlongannotation(m_inner, "cpxBendersPartition", Int32(0))

#Annotate Model
#=
Ideally, this would be done using the setlongannotations function.
However, issues have been presented when sending annotations with this function
(see https://github.com/JuliaOpt/CPLEX.jl/issues/268#issuecomment-559231367)
Rather, you can create an annotation file (.ann) and feed that to CPLEX
=#

#Create annotation file. "filename" is the path + filename of the .ann file (i.e. "/home/benders.ann")
io = open(filename, "w") 
#Write .ann file header (required by CPLEX)
println(io, "<?xml version='1.0' encoding='utf-8'?>")
println(io, "<CPLEXAnnotations>")
println(io, "<CPLEXAnnotation name='cpxBendersPartition' type='long' default='0'>")
println(io, "<object type='1'>")
#Add annotations
var_name = "x" #variable name
var_column = 0 #x is the first variable (CPLEX uses index 0)
subproblem = 0 #x belongs to the master problem
println(io, string("<anno name='",var_name,"' index='",var_column,"' value='",subproblem,"'/>")) #print annotation to .ann file
var_name = "y" #variable name
var_column = 1 #y is the second variable (CPLEX uses index 0)
subproblem = 1 #y belongs to the first subproblem
println(io, string("<anno name='",var_name,"' index='",var_column,"' value='",subproblem,"'/>")) #print annotation to .ann file
var_name = "z" #variable name
var_column = 2 #z is the third variable (CPLEX uses index 0)
subproblem = 2 #z belongs to the second subproblem problem
println(io, string("<anno name='",var_name,"' index='",var_column,"' value='",subproblem,"'/>")) #print annotation to .ann file
#Write .ann file footer (required by CPLEX)
println(io, "</object>")
println(io, "</CPLEXAnnotation>")
println(io, "</CPLEXAnnotations>")
#Close .ann file
close(io)

#Transfer annotations to cplex
readcopyannotations(m_inner,filename)

#Set Benders decomposition strategy
#For annotated models use either strategy 0, 1, or 2 (see CPLEX documentation).
#If you want CPLEX to annotate your model automatically (benders_strategy = 3), you could just skip lines 27-66.
MOI.set(m, MOI.RawParameter("CPXPARAM_Benders_Strategy"), benders_strategy)
#Turn off presolve for this toy example so that you can see CPLEX applying 2 Benders cuts
MOI.set(m, MOI.RawParameter("CPXPARAM_Preprocessing_Presolve"), 0)
#Optimize model
optimize!(m)
```
