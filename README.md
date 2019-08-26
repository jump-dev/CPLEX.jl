CPLEX.jl
========

CPLEX.jl is an unofficial interface to the [IBM® ILOG® CPLEX® Optimization
Studio](https://www.ibm.com/products/ilog-cplex-optimization-studio). It
provides an interface to the low-level C API, as well as an implementation of
the solver-independent [`MathProgBase`](https://github.com/JuliaOpt/MathProgBase.jl)
and [`MathOptInterface`](https://github.com/JuliaOpt/MathOptInterface.jl) API's.

You cannot use CPLEX.jl without having purchased and installed a copy of CPLEX
Optimization Studio from [IBM](http://www.ibm.com/). This package is available
free of charge and in no way replaces or alters any functionality of IBM's CPLEX
Optimization Studio product.

*Note: This wrapper is maintained by the JuliaOpt community and is not
officially supported by IBM. If you are a commercial customer interested in
official support for CPLEX in Julia, let them know!.*

Setting up CPLEX on OS X and Linux
----------------------------------

1. First, you must obtain a copy of the CPLEX software and a license; trial versions and academic licenses are available [here](https://www.ibm.com/products/ilog-cplex-optimization-studio/pricing).

2. Once CPLEX is installed on your machine, point the `LD_LIBRARY_PATH` variable to the directory containing the CPLEX library by adding, for example, ``export LD_LIBRARY_PATH="/path/to/cplex/bin/x86-64_linux":$LD_LIBRARY_PATH`` to your start-up file (e.g. ``.bash_profile``, [adding library path on Ubuntu](http://stackoverflow.com/questions/13428910/how-to-set-the-environmental-variable-ld-library-path-in-linux for a)). On linux, make sure this directory contains ``libcplexXXX.so`` where ``XXX`` is stands for the version number; on OS-X the file should be named ``libcplexXXX.dylib``. Alternatively, you can also use the `CPLEX_STUDIO_BINARIES` environment variable as follows:
  ```
  $ CPLEX_STUDIO_BINARIES=/path/to/cplex/bin/x86-64_linux julia -e 'Pkg.add("CPLEX"); Pkg.build("CPLEX")'
  ```

3. At the Julia prompt, run
  ```
  julia> Pkg.add("CPLEX")
  ```
(or manually clone this module to your ``.julia`` directory).

4. Check that your version is included in ``deps/build.jl`` in the aliases for the library dependency; if not, open an issue.

Note for windows
----------------

Currently, CPLEX.jl is compatible only with 64-bit CPLEX and 64-bit Julia on Windows. CPLEX.jl attempts to automatically find the CPLEX library based on the `CPLEX_STUDIO_BINARIESXXX` environmental variable set by the CPLEX installer where `XXX` is the CPLEX version. For example:
```julia
julia> ENV["CPLEX_STUDIO_BINARIES128"] = "C:/IBM/CPLEX_Studio128/cplex/bin/x64_win64"

julia> Pkg.build("CPLEX")
```

Help! I got `LoadError: Unable to locate CPLEX installation`
----------------------------------

Which version of CPLEX are you trying to install? Currently, CPLEX.jl only supports 1280 and 1290 given recent changes [the API](https://www.ibm.com/support/knowledgecenter/en/SSSA5P_12.9.0/ilog.odms.studio.help/CPLEX/ReleaseNotes/topics/releasenotes1290/removed.html). If your CPLEX version is < 1280, you can add the last supported version of CPLEX.jl via `julia> ] add CPLEX@0.4`. However, we recommend that you upgrade your version of CPLEX. If you want to support newer versions of CPLEX not listed above, [file an issue](https://github.com/JuliaOpt/CPLEX.jl/issues/new) with the version number you'd like to support. Some steps need to be taken (like checking for new or renamed parameters) before CPLEX.jl can support new versions.

#### If you're on OS X or Linux

The most common problem is not setting `LD_LIBRARY_PATH` correctly. Open a terminal and check the output of
```
echo $LD_LIBRARY_PATH
```
is the path to the CPLEX installation. If it's not, did you follow step 2 above?

Hint: on OS X the path should probably be something like
`/Users/[username]/Applications/IBM/ILOG/CPLEX_Studio[version number]/cplex/bin/x86-64_osx/`

#### If you're on Linux

The most common problem is not setting `CPLEX_STUDIO_BINARIES` correctly. Open a Julia prompt and check that the output of
```julia
julia> ENV["CPLEX_STUDIO_BINARIES"]
```
is the path to the CPLEX installation. If you get a `key "CPLEX_STUDIO_BINARIES" not found` error, make sure the environment variable is set correctly, or just set it from within the Julia prompt
```julia
julia> ENV["CPLEX_STUDIO_BINARIES"] = "path/to/cplex/installation"
julia> Pkg.build("CPLEX")
```
Another alternative is to run
```
CPLEX_STUDIO_BINARIES="path/to/cplex/installation" julia -e 'Pkg.build("CPLEX")'
```
#### If you're on Windows

The environment variable needs to be `CPLEX_STUDIO_BINARIESXXX` where `XXX` is the version of CPLEX.

Parameters
----------

Solver parameters can be passed through the ``CplexSolver()`` object, e.g., ``CplexSolver(CPX_PARAM_EPINT=1e-8)``. Parameters match those of the CPLEX documentation. Additionally, the ``mipstart_effortlevel`` parameter can be used to tell CPLEX how much effort to put into turning warmstarts into feasible solutions, with possible values ``CPLEX.CPX_MIPSTART_AUTO``, ``CPLEX.CPX_MIPSTART_CHECKFEAS``, ``CPLEX.CPX_MIPSTART_SOLVEFIXED``, ``CPLEX.CPX_MIPSTART_SOLVEMIP``, ``CPLEX.CPX_MIPSTART_REPAIR``, and ``CPLEX.CPX_MIPSTART_NOCHECK``.
