using SpaceInvaders
using Test
using Aqua

@testset "SpaceInvaders.jl" begin
    @testset "Code quality (Aqua.jl)" begin
        Aqua.test_all(SpaceInvaders, deps_compat=false)
        Aqua.test_deps_compat(SpaceInvaders, check_extras=false)
    end
    # Write your tests here.
end
