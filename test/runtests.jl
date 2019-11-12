if get(ENV, "GITHUB_ACTIONS", "false") == "true"
    # We're being run as part of a Github action. The most likely case is that
    # this is the auto-merge action as part of the General registry.
    # For now, we're going to silently skip the tests.
    #
    # TODO(odow): remove this once we distribute the community edition.
    exit(0)
end

using Test
import Pkg
using MathProgBase
using CPLEX

@testset "$folder" for folder in ["C_API", "MathProgBase", "MathOptInterface"]
    @testset "$(file)" for file in readdir(folder)
        include(joinpath(folder, file))
    end
end
