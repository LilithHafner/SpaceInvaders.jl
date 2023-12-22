using SpaceInvaders
using Test
using Aqua

@testset "SpaceInvaders.jl" begin
    @testset "Code quality (Aqua.jl)" begin
        Aqua.test_all(SpaceInvaders)
    end
    # Write your tests here.
end
