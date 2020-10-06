const _DEPRECATED_ERROR_MESSAGE = """
The C API of CPLEX.jl has been rewritten to expose the complete C API, and
all old functions have been removed. For more information, see the Discourse
announcement: https://discourse.julialang.org/t/ann-upcoming-breaking-changes-to-cplex-jl-and-gurobi-jl/47814

Here is a brief summary of the changes.

* Function names have changed. For example, `CPLEX.close_CPLEX(env)` is now 
    `CPXcloseCPLEX(env)`.
* For users of `CPLEX.Optimizer`, `model.inner` has been replaced by the fields
    `model.env` and `model.lp`, which correspond to the environment and problem
    pointers at the C API level. For example:
    ```julia
    stat = CPLEX.get_status(model.inner)
    ```
    is now:
    ```julia
    stat = CPXgetstat(model.env, model.lp)
    ```
* Querying functionality has changed. For example:
    ```julia
    is_point = CPLEX.cbcandidateispoint(cb_data)
    ```
    is now:
    ```julia
    is_point_P = Ref{Cint}()
    CPXcallbackcandidateispoint(cb_data, is_point_P)
    if ret != 0
        # Do something because the call failed
    end
    is_point = is_point_P[]
    ```

The new API is more verbose, but the names and function arguments are now
identical to the C API, documentation for which is available at:
https://www.ibm.com/support/knowledgecenter/SSSA5P_12.10.0/ilog.odms.cplex.help/refcallablelibrary/groups/homepagecallable.html

To revert to the old API, use:

    import Pkg
    Pkg.add(Pkg.PackageSpec(name = "CPLEX", version = v"0.6"))

Then restart Julia for the change to take effect.
"""

add_constr!(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

add_constrs!(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

add_constrs_t!(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

add_diag_qpterms!(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

add_indicator_constraint(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

add_qconstr!(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

add_qpterms!(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

add_rangeconstrs!(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

add_rangeconstrs_t!(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

add_sos!(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

add_var!(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

add_vars!(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

c_api_addrows(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

c_api_chgbds(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

c_api_chgcoef(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

c_api_chgctype(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

c_api_chgname(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

c_api_chgobj(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

c_api_chgobjoffset(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

c_api_chgobjsen(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

c_api_chgrhs(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

c_api_chgsense(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

c_api_delcols(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

c_api_delqconstrs(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

c_api_delrows(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

c_api_delsos(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

c_api_getax(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

c_api_getbaritcnt(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

c_api_getconflict(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

c_api_getdj(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

c_api_getitcnt(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

c_api_getlb(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

c_api_getnumcols(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

c_api_getnumrows(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

c_api_getobj(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

c_api_getobjoffset(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

c_api_getobjsen(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

c_api_getobjval(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

c_api_getpi(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

c_api_getqconstr(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

c_api_getqconstrslack(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

c_api_getquad(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

c_api_getrhs(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

c_api_getrows(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

c_api_getsos(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

c_api_getstat(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

c_api_getstatstring(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

c_api_getub(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

c_api_getx(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

c_api_getxqxax(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

c_api_solninfo(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

callback_wrapper(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

callbackgetcandidatepoint(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

callbackgetrelaxationpoint(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

cbabort(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

cbaddboundbranchdown!(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)
export cbaddboundbranchdown!

cbaddboundbranchup!(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)
export cbaddboundbranchup!

cbaddconstrbranch!(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

cbaddusercuts(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

cbbranch(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

cbbranchconstr(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

cbcandidateispoint(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

cbcut(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

cbcutlocal(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

cbgetcandidatepoint(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

cbgetdetstarttime(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)
export cbgetdetstarttime

cbgetdettimestamp(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)
export cbgetdettimestamp

cbgetfeasibility(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)
export cbgetfeasibility

cbgetgap(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)
export cbgetgap

cbgetintfeas(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)
export cbgetintfeas

cbgetmipiterations(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)
export cbgetmipiterations

cbgetnodelb(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)
export cbgetnodelb

cbgetnodeobjval(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)
export cbgetnodeobjval

cbgetnodesleft(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)
export cbgetnodesleft

cbgetnodeub(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)
export cbgetnodeub

cbgetrelaxationpoint(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

cbgetstarttime(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)
export cbgetstarttime

cbgettimestamp(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)
export cbgettimestamp

cblazy(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

cblazylocal(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

cbpostheursoln(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

cbprocessincumbent!(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

cbrejectcandidate(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

cbsetfunc(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

cchar(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

check_moi_callback_validity(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

close_CPLEX(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

compute_conflict(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

cplex_model(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

cvec(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

cvecx(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

default_moi_callback(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

eval(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

free_problem(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

fvec(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

fvecx(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

get_basis(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

get_best_bound(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

get_constrLB(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

get_constrUB(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

get_constr_duals(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

get_constr_matrix(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

get_constr_senses(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

get_constr_solution(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

get_error_msg(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

get_infeasibility_ray(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

get_nnz(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

get_node_count(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

get_num_cuts(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

get_num_sos(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

get_obj(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

get_objval(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

get_param(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

get_param_type(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

get_prob_type(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

get_reduced_costs(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

get_rel_gap(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

get_rhs(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

get_sense(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

get_solution(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

get_status(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

get_status_code(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

get_unbounded_ray(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

get_varLB(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

get_varUB(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

get_vartype(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

getdettime(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

include(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

intervalize(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

is_valid(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

ivec(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

masterbranchcallback(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

mastercallback(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

masterheuristiccallback(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

masterincumbentcallback(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

masterinfocallback(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

newlongannotation(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)
export newlongannotation

notify_freed_model(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

notify_new_model(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

num_constr(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

num_qconstr(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

num_var(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

optimize!(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

read_model(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

return_status_or_throw(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

set_branching_priority(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

set_constrLB!(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

set_constrUB!(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

set_constr_senses!(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

set_logfile(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

set_obj!(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

set_param!(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

set_prob_type!(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

set_rhs!(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

set_sense!(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

set_terminate(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

set_varLB!(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

set_varUB!(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

set_varname!(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

set_vartype!(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

set_warm_start!(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

setbranchcallback!(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

setcallbackcut(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

setcallbackcutlocal(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

setincumbentcallback!(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

setlongannotations(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)
export setlongannotations

setmathprogbranchcallback!(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)
export setmathprogbranchcallback!

setmathprogcutcallback!(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

setmathprogheuristiccallback!(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

setmathprogincumbentcallback!(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

setmathproginfocallback!(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

setmathproglazycallback!(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

terminate(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

toggleproblemtype!(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

tune_param(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

version(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

write_model(args...; kwargs...) = error(_DEPRECATED_ERROR_MESSAGE)

