# Copyright (c) 2013: Joey Huchette and contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

using CPLEX
using Test

@testset "MathOptInterface Tests" begin
    for file in readdir("MathOptInterface")
        include(joinpath("MathOptInterface", file))
    end
end
