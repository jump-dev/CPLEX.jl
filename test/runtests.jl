if get(ENV, "GITHUB_ACTIONS", "") == "true"
    import Pkg
    Pkg.add(Pkg.PackageSpec(name = "MathOptInterface", rev = "master"))
end

using CPLEX
using Test

function runtests(mod)
    for name in filter(s -> startswith("$(s)", "test_"), names(mod; all = true))
        @testset "$(name)" begin
            getfield(mod, name)()
        end
    end
end

@testset "MathOptInterface Tests" begin
    for file in readdir("MathOptInterface")
        include(joinpath("MathOptInterface", file))
    end
end

@testset "Deprecated functions" begin
    err = ErrorException(CPLEX._DEPRECATED_ERROR_MESSAGE)
    @test_throws err newlongannotation()
    @test_throws err CPLEX.get_status()
    model = CPLEX.Optimizer()
    @test_throws err model.inner
    @test model.lp isa Ptr{Cvoid}
end
