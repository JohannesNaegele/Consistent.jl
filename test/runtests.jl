using Consistent
using Test

@testset "Consistent.jl" begin

    @testset "Internals" begin
        @test Consistent.remove_expr([:x :(a in b) :y]) == [:x, :a, :in, :b, :y]
        test_eqs = quote
            z = y * (y[-1] + 0.5 * z) * θ + x[-1]
            y = z[-2] * x * b
        end
        @test Consistent.replace_vars(test_eqs.args[[2, 4]], [:z, :y], Symbol[:x], [:θ]) == [
            :(z = endos[2] * (lags[2, end - 0] + 0.5 * endos[1]) * params[1] + exos[1, end - -1]),
            :(y = lags[1, end - -1] * exos[1, end - 0] * b)
        ]
    end

    @testset "Default models" begin
        sim = Consistent.SIM()
        @test sim.exogenous_variables.variables == [:G]
        # @test LP()
        # @test PC()
        # @test DIS()
        # @test BMW()
    end
end