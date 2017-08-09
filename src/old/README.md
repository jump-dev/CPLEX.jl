Files in this folder related to the old version of CPLEX.jl.

They include the orignal wrapping done by @joehuchette, as well as the glue code
for MathProgBase.

Much of the functionality has been re-wrapped for MOI. Newly wrapped functions
now follow the convention `cpx_xxx` where `xxx`is the name of the C function.

Functions that modify the underlying model (as opposed to those that just query)
information contain the `!` suffix. For example, `cpx_setparam!` wraps the C
function `CPXsetparam`.

In addition, much of the helper functions surrounding the wrapped functions have
been removed in the new wrapping (for example, the multitude of ways to
`addvar!`).

We strongly encourage the use of the MathOptInterface over the low-level
interface. However, some of the functionality is not yet wrapped (callbacks are
the most noticeable example).
