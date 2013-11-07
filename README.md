Cplex.jl
========

Julia interface for the CPLEX optimization software

Note: if on OS-X, need to add ``LD_LIBRARY_PATH="/path/to/Cplex/library":$LD_LIBRARY_PATH`` to your ``.bash_profile``.

On my install, must run ``dlopen("libstdc++",RTLD_GLOBAL)`` before loading the Cplex module to avoid C++ linking issues.

