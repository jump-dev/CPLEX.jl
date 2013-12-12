CPLEX.jl
========

CPLEX.jl is a Julia interface for the CPLEX optimization software. CPLEX functionality is extensive, so coverage is incomplete, but the basic functionality for solving linear and mixed-integer programs is provided.

CPLEX.jl is intended for use with the [MathProgBase](https://github.com/JuliaOpt/MathProgBase.jl) solver interface; an internal API, while present, is not documented.

Setting up CPLEX
----------------

NOTE: CPLEX [does not officially support linking to their dynamic C library](https://www.ibm.com/developerworks/community/forums/html/topic?id=ca96447c-fe2d-4e8a-900e-cfe358a9bcec&ps=25), which is necessary for use from Julia. However, the steps outlined below have worked for OS-X, Windows, and Linux machines. 

1. First, you must obtain a copy of the CPLEX software and a license; trial versions and academic licenses are available [here](http://www-01.ibm.com/software/websphere/products/optimization/cplex-studio-preview-edition/).

2. Once CPLEX is installed on your machine, point the LD_LIBRARY_PATH variable to the CPLEX library by adding ``LD_LIBRARY_PATH="/path/to/CPLEX/library":$LD_LIBRARY_PATH`` to your start-up file (e.g. ``.bash_profile``). On OS-X, there may not be a .dylib shared C library available; in this case, create a symlink with the .dylib extension pointing to the .jnilib dynamic Java library that is available.

3. At the Julia prompt, run 
  ```
  julia> Pkg.add("CPLEX")
  ```
(or manually clone this module to your ``.julia`` directory).

4. Check that your version is included in in ``deps/build.jl`` in the aliases for the library dependency; if not, simply add the name of your CPLEX dynamic library.

5. Open a Julia prompt and run ``julia> Pkg.build("CPLEX")``. The module should now be ready for use!

Troubleshooting
---------------
* There is a potential conflict between the C++ library used by CPLEX and that which is used by newer Julia installs. If ``Pkg.build("CPLEX")`` fails, this might be to blame: you must enter ``dlopen("libstdc++",RTLD_GLOBAL)`` before loading the CPLEX module to avoid C++ linking issues (This statement is currently included for OS-X by default, as it's unclear the issue exists on other platforms). 
* If you have any install problems, find any bugs, or want any features added, feel free to open an issue.
