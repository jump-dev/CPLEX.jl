**CPLEX.jl underwent a major rewrite between versions 0.6.6 and 0.7.0. Users of
JuMP should see no breaking changes, but if you used the lower-level C API
(e.g., for callbacks), you will need to update your code accordingly. For a full
description of the changes, read [this discourse post](https://discourse.julialang.org/t/ann-upcoming-breaking-changes-to-cplex-jl-and-gurobi-jl/47814).**

**To revert to the old API, use:**
```julia
import Pkg
Pkg.add(Pkg.PackageSpec(name = "CPLEX", version = v"0.6"))
```
**Then restart Julia for the change to take effect.**

# CPLEX.jl

CPLEX.jl is a wrapper for the [IBM® ILOG® CPLEX® Optimization
Studio](https://www.ibm.com/products/ilog-cplex-optimization-studio)

You cannot use CPLEX.jl without having purchased and installed a copy of CPLEX
Optimization Studio from [IBM](http://www.ibm.com/). However, CPLEX is
available for free to [academics and students](http://ibm.biz/Bdzvqw).

CPLEX.jl has two components:
 - a thin wrapper around the complete C API
 - an interface to [MathOptInterface](https://github.com/jump-dev/MathOptInterface.jl)

The C API can be accessed via `CPLEX.CPXxx` functions, where the names and
arguments are identical to the C API. See the [CPLEX documentation](https://www.ibm.com/support/knowledgecenter/SSSA5P_12.10.0/COS_KC_home.html)
for details.

*Note: This wrapper is maintained by the JuMP community and is not
officially supported by IBM. However, we thank IBM for providing us with a
CPLEX license to test `CPLEX.jl` on Travis. If you are a commercial customer
interested in official support for CPLEX in Julia, let them know!.*

## Installation

**Minimum version requirement:** CPLEX.jl requires CPLEX version 12.10 or 20.1.

First, obtain a license of CPLEX and install CPLEX solver, following the
instructions on [IBM's website](https://www.ibm.com/analytics/cplex-optimizer). Then, set the
`CPLEX_STUDIO_BINARIES` environment variable as appropriate and run
`Pkg.add("CPLEX")`, then `Pkg.build("CPLEX")`. For example:
```julia
# On Windows, this might be
ENV["CPLEX_STUDIO_BINARIES"] = "C:\\Program Files\\CPLEX_Studio1210\\cplex\\bin\\x86-64_win\\"
import Pkg
Pkg.add("CPLEX")
Pkg.build("CPLEX")

# On OSX, this might be
ENV["CPLEX_STUDIO_BINARIES"] = "/Applications/CPLEX_Studio1210/cplex/bin/x86-64_osx/"
import Pkg
Pkg.add("CPLEX")
Pkg.build("CPLEX")

# On Unix, this might be
ENV["CPLEX_STUDIO_BINARIES"] = "/opt/CPLEX_Studio1210/cplex/bin/x86-64_linux/"
import Pkg
Pkg.add("CPLEX")
Pkg.build("CPLEX")
```
**Note: your path may differ. Check which folder you installed CPLEX in, and
update the path accordingly.**

## Use with JuMP

We highly recommend that you use the *CPLEX.jl* package with higher level
packages such as [JuMP.jl](https://github.com/jump-dev/JuMP.jl).

This can be done using the ``CPLEX.Optimizer`` object. Here is how to create a
*JuMP* model that uses CPLEX as the solver.
```julia
using JuMP, CPLEX

model = Model(CPLEX.Optimizer)
set_optimizer_attribute(model, "CPX_PARAM_EPINT", 1e-8)
```

Parameters match those of the C API in the [CPLEX documentation](https://www.ibm.com/support/knowledgecenter/SSSA5P_12.10.0/ilog.odms.cplex.help/CPLEX/Parameters/topics/introListAlpha.html).

## Callbacks

Here is an example using CPLEX's solver-specific callbacks.

```julia
using JuMP, CPLEX, Test

model = direct_model(CPLEX.Optimizer())
set_silent(model)

# This is very, very important!!! Only use callbacks in single-threaded mode.
MOI.set(model, MOI.NumberOfThreads(), 1)

@variable(model, 0 <= x <= 2.5, Int)
@variable(model, 0 <= y <= 2.5, Int)
@objective(model, Max, y)
cb_calls = Clong[]
function my_callback_function(cb_data::CPLEX.CallbackContext, context_id::Clong)
    # You can reference variables outside the function as normal
    push!(cb_calls, context_id)
    # You can select where the callback is run
    if context_id != CPX_CALLBACKCONTEXT_CANDIDATE
        return
    end
    ispoint_p = Ref{Cint}()
    ret = CPXcallbackcandidateispoint(cb_data, ispoint_p)
    if ret != 0 || ispoint_p[] == 0
        return  # No candidate point available or error
    end
    # You can query CALLBACKINFO items
    valueP = Ref{Cdouble}()
    ret = CPXcallbackgetinfodbl(cb_data, CPXCALLBACKINFO_BEST_BND, valueP)
    @info "Best bound is currently: $(valueP[])"
    # As well as any other C API
    x_p = Vector{Cdouble}(undef, 2)
    obj_p = Ref{Cdouble}()
    ret = CPXcallbackgetincumbent(cb_data, x_p, 0, 1, obj_p)
    if ret == 0
        @info "Objective incumbent is: $(obj_p[])"
        @info "Incumbent solution is: $(x_p)"
        # Use CPLEX.column to map between variable references and the 1-based
        # column.
        x_col = CPLEX.column(cb_data, index(x))
        @info "x = $(x_p[x_col])"
    else
        # Unable to query incumbent.
    end

    # Before querying `callback_value`, you must call:
    CPLEX.load_callback_variable_primal(cb_data, context_id)
    x_val = callback_value(cb_data, x)
    y_val = callback_value(cb_data, y)
    # You can submit solver-independent MathOptInterface attributes such as
    # lazy constraints, user-cuts, and heuristic solutions.
    if y_val - x_val > 1 + 1e-6
        con = @build_constraint(y - x <= 1)
        MOI.submit(model, MOI.LazyConstraint(cb_data), con)
    elseif y_val + x_val > 3 + 1e-6
        con = @build_constraint(y + x <= 3)
        MOI.submit(model, MOI.LazyConstraint(cb_data), con)
    end
end
MOI.set(model, CPLEX.CallbackFunction(), my_callback_function)
optimize!(model)
@test termination_status(model) == MOI.OPTIMAL
@test primal_status(model) == MOI.FEASIBLE_POINT
@test value(x) == 1
@test value(y) == 2
```
