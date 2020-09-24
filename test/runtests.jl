using Test

include("MathOptInterface/MOI_wrapper.jl")
include("MathOptInterface/MOI_callbacks.jl")

using CPLEX
@testset "Deprecated functions" begin
    err = ErrorException(CPLEX._DEPRECATED_ERROR_MESSAGE)
    @test_throws err newlongannotation()
    @test_throws err CPLEX.get_status()
    model = CPLEX.Optimizer()
    @test_throws err model.inner
    @test model.lp isa Ptr{Cvoid}
end
