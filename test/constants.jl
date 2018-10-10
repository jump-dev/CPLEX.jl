@testset "Checking value of constants from cpxconst.h" begin
    version_split = split(CPLEX.version(), '.')
    version = parse(Int, version_split[1])
    release = parse(Int, version_split[2])
    @test CPLEX.CPX_VERSION_VERSION == version
    @test CPLEX.CPX_VERSION_RELEASE == release
    @test div(CPLEX.CPX_VERSION, 10000) == version * 100 + release
end
