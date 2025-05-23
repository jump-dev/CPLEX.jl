# CPLEX.jl

[![Build Status](https://github.com/jump-dev/CPLEX.jl/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/jump-dev/CPLEX.jl/actions?query=workflow%3ACI)
[![codecov](https://codecov.io/gh/jump-dev/CPLEX.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/jump-dev/CPLEX.jl)

[CPLEX.jl](https://github.com/jump-dev/CPLEX.jl) is a wrapper for the
[IBM® ILOG® CPLEX® Optimization Studio](https://www.ibm.com/products/ilog-cplex-optimization-studio).

CPLEX.jl has two components:
 - a thin wrapper around the complete C API
 - an interface to [MathOptInterface](https://github.com/jump-dev/MathOptInterface.jl)

The C API can be accessed via `CPLEX.CPXxx` functions, where the names and
arguments are identical to the C API. See the [CPLEX documentation](https://www.ibm.com/docs/en/icos/22.1.0?topic=apis-callable-library)
for details.

## Affiliation

This wrapper is maintained by the JuMP community and is not officially supported
by IBM. However, we thank IBM for providing us with a CPLEX license to test
`CPLEX.jl` on GitHub. If you are a commercial customer interested in official
support for CPLEX in Julia, let them know.

## Getting help

If you need help, please ask a question on the [JuMP community forum](https://jump.dev/forum).

If you have a reproducible example of a bug, please [open a GitHub issue](https://github.com/jump-dev/CPLEX.jl/issues/new).

## License

`CPLEX.jl` is licensed under the [MIT License](https://github.com/jump-dev/CPLEX.jl/blob/master/LICENSE.md).

The underlying solver is a closed-source commercial product for which you must
[purchase a license](https://www.ibm.com/analytics/cplex-optimizer).

Free CPLEX licenses are available for [academics and students](http://ibm.biz/Bdzvqw).

## Installation

CPLEX.jl requires CPLEX version 12.10, 20.1, or 22.1.

First, obtain a license of CPLEX and install CPLEX solver, following the
instructions on [IBM's website](https://www.ibm.com/analytics/cplex-optimizer).

Once installed, set the `CPLEX_STUDIO_BINARIES` environment variable as
appropriate and run `Pkg.add("CPLEX")`. For example:
```julia
# On Windows, this might be:
ENV["CPLEX_STUDIO_BINARIES"] = "C:\\Program Files\\CPLEX_Studio1210\\cplex\\bin\\x86-64_win\\"
# On OSX, this might be:
ENV["CPLEX_STUDIO_BINARIES"] = "/Applications/CPLEX_Studio1210/cplex/bin/x86-64_osx/"
# On Unix, this might be:
ENV["CPLEX_STUDIO_BINARIES"] = "/opt/CPLEX_Studio1210/cplex/bin/x86-64_linux/"

import Pkg
Pkg.add("CPLEX")
```

!!! note
    The exact path may differ. Check which folder you installed CPLEX in, and
    update the path accordingly.

## Use with JuMP

Use `CPLEX.jl` with JuMP as follows:
```julia
using JuMP, CPLEX
model = Model(CPLEX.Optimizer)
set_attribute(model, "CPX_PARAM_EPINT", 1e-8)
```

## MathOptInterface API

The CPLEX optimizer supports the following constraints and attributes.

List of supported objective functions:

 * [`MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}`](@ref)
 * [`MOI.ObjectiveFunction{MOI.ScalarQuadraticFunction{Float64}}`](@ref)
 * [`MOI.ObjectiveFunction{MOI.VariableIndex}`](@ref)
 * [`MOI.ObjectiveFunction{MOI.VectorAffineFunction{Float64}}`](@ref)

List of supported variable types:

 * [`MOI.Reals`](@ref)

List of supported constraint types:

 * [`MOI.ScalarAffineFunction{Float64}`](@ref) in [`MOI.EqualTo{Float64}`](@ref)
 * [`MOI.ScalarAffineFunction{Float64}`](@ref) in [`MOI.GreaterThan{Float64}`](@ref)
 * [`MOI.ScalarAffineFunction{Float64}`](@ref) in [`MOI.LessThan{Float64}`](@ref)
 * [`MOI.ScalarQuadraticFunction{Float64}`](@ref) in [`MOI.GreaterThan{Float64}`](@ref)
 * [`MOI.ScalarQuadraticFunction{Float64}`](@ref) in [`MOI.LessThan{Float64}`](@ref)
 * [`MOI.VariableIndex`](@ref) in [`MOI.EqualTo{Float64}`](@ref)
 * [`MOI.VariableIndex`](@ref) in [`MOI.GreaterThan{Float64}`](@ref)
 * [`MOI.VariableIndex`](@ref) in [`MOI.Integer`](@ref)
 * [`MOI.VariableIndex`](@ref) in [`MOI.Interval{Float64}`](@ref)
 * [`MOI.VariableIndex`](@ref) in [`MOI.LessThan{Float64}`](@ref)
 * [`MOI.VariableIndex`](@ref) in [`MOI.Semicontinuous{Float64}`](@ref)
 * [`MOI.VariableIndex`](@ref) in [`MOI.Semiinteger{Float64}`](@ref)
 * [`MOI.VariableIndex`](@ref) in [`MOI.ZeroOne`](@ref)
 * [`MOI.VectorOfVariables`](@ref) in [`MOI.SOS1{Float64}`](@ref)
 * [`MOI.VectorOfVariables`](@ref) in [`MOI.SOS2{Float64}`](@ref)
 * [`MOI.VectorOfVariables`](@ref) in [`MOI.SecondOrderCone`](@ref)
 * [`MOI.VectorAffineFunction`](@ref) in [`MOI.Indicator`](@ref)

List of supported model attributes:

 * [`MOI.ConflictStatus()`](@ref)
 * [`MOI.HeuristicCallback()`](@ref)
 * [`MOI.LazyConstraintCallback()`](@ref)
 * [`MOI.Name()`](@ref)
 * [`MOI.ObjectiveSense()`](@ref)
 * [`MOI.UserCutCallback()`](@ref)

## Options

Options match those of the C API in the [CPLEX documentation](https://www.ibm.com/support/knowledgecenter/SSSA5P_12.10.0/ilog.odms.cplex.help/CPLEX/Parameters/topics/introListAlpha.html).

Set options using `JuMP.set_attribute`:
```julia
using JuMP, CPLEX
model = Model(CPLEX.Optimizer)
set_attribute(model, "CPX_PARAM_EPINT", 1e-8)
```

## Callbacks

CPLEX.jl provides a solver-specific callback to CPLEX:

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

## Annotations for automatic Benders' decomposition

Here is an example of using the annotation feature for automatic Benders'
decomposition:
```julia
using JuMP, CPLEX

function add_annotation(
    model::JuMP.Model,
    variable_classification::Dict;
    all_variables::Bool = true,
)
    num_variables = sum(length(it) for it in values(variable_classification))
    if all_variables
        @assert num_variables == JuMP.num_variables(model)
    end
    indices, annotations = CPXINT[], CPXLONG[]
    for (key, value) in variable_classification
        for variable_ref in value
            push!(indices, variable_ref.index.value - 1)
            push!(annotations, CPX_BENDERS_MASTERVALUE + key)
        end
    end
    cplex = backend(model)
    index_p = Ref{CPXINT}()
    CPXnewlongannotation(
        cplex.env,
        cplex.lp,
        CPX_BENDERS_ANNOTATION,
        CPX_BENDERS_MASTERVALUE,
    )
    CPXgetlongannotationindex(
        cplex.env,
        cplex.lp,
        CPX_BENDERS_ANNOTATION,
        index_p,
    )
    CPXsetlongannotations(
        cplex.env,
        cplex.lp,
        index_p[],
        CPX_ANNOTATIONOBJ_COL,
        length(indices),
        indices,
        annotations,
    )
    return
end

# Problem

function illustrate_full_annotation()
    c_1, c_2 = [1, 4], [2, 3]
    dim_x, dim_y = length(c_1), length(c_2)
    b = [-2; -3]
    A_1, A_2 = [1 -3; -1 -3], [1 -2; -1 -1]
    model = JuMP.direct_model(CPLEX.Optimizer())
    set_optimizer_attribute(model, "CPXPARAM_Benders_Strategy", 1)
    @variable(model, x[1:dim_x] >= 0, Bin)
    @variable(model, y[1:dim_y] >= 0)
    variable_classification = Dict(0 => [x[1], x[2]], 1 => [y[1], y[2]])
    @constraint(model, A_2 * y + A_1 * x .<= b)
    @objective(model, Min, c_1' * x + c_2' * y)
    add_annotation(model, variable_classification)
    optimize!(model)
    x_optimal = value.(x)
    y_optimal = value.(y)
    println("x: $(x_optimal), y: $(y_optimal)")
end

function illustrate_partial_annotation()
    c_1, c_2 = [1, 4], [2, 3]
    dim_x, dim_y = length(c_1), length(c_2)
    b = [-2; -3]
    A_1, A_2 = [1 -3; -1 -3], [1 -2; -1 -1]
    model = JuMP.direct_model(CPLEX.Optimizer())
    # Note that the "CPXPARAM_Benders_Strategy" has to be set to 2 if partial
    # annotation is provided. If "CPXPARAM_Benders_Strategy" is set to 1, then
    # the following error will be thrown:
    # `CPLEX Error  2002: Invalid Benders decomposition.`
    set_optimizer_attribute(model, "CPXPARAM_Benders_Strategy", 2)
    @variable(model, x[1:dim_x] >= 0, Bin)
    @variable(model, y[1:dim_y] >= 0)
    variable_classification = Dict(0 => [x[1]], 1 => [y[1], y[2]])
    @constraint(model, A_2 * y + A_1 * x .<= b)
    @objective(model, Min, c_1' * x + c_2' * y)
    add_annotation(model, variable_classification; all_variables = false)
    optimize!(model)
    x_optimal = value.(x)
    y_optimal = value.(y)
    println("x: $(x_optimal), y: $(y_optimal)")
end
```
