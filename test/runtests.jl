using Consistent
using Test

@testset "Consistent.jl" begin

    @testset "Types" begin
        let vars = @variables Y, C, G
            @test Consistent.Variables(vars) == vars
        end

        @test Consistent.Variables([:a, :b]) == @variables [a, b]
    end

    @testset "Internals" begin
        @test Consistent.left_symbol(:(Y - C = G)) == :Y
        @test isnothing(Consistent.left_symbol(:(1 = 1)))

        @test Consistent.remove_expr([:x :(a in b) :y]) == [:x, :a, :in, :b, :y]
        test_eqs = quote
            z = y * (y[-1] + 0.5 * z) * θ + x[-1]
            y = z[-2] * x * b
        end
        @test Consistent.replace_vars(test_eqs.args[[2, 4]], [:z, :y], Symbol[:x], [:θ]) == [
            :(endos[1] = endos[2] * (lags[2, end - 0] + 0.5 * endos[1]) * params[1] + exos[1, end + -1]),
            :(endos[2] = lags[1, end - -1] * exos[1, end + 0] * b)
        ]

        # test non-equation
        let eqs = @equations begin
                Y = C + G
                a + b
            end
            @test_throws ErrorException model(
                endos = @variables(Y),
                exos = @variables(),
                params = @variables(),
                eqs = eqs
            )
        end
        
        # test missing variables
        let eqs = @equations begin
                Y = C
            end
            @test_warn "Symbols [:C] are not in variables or parameters" model(
                endos = @variables(Y),
                exos = @variables(),
                params = @variables(),
                eqs = eqs
            )
        end

        # test unused variables
        let eqs = @equations begin
                Y = C
            end
            @test_throws ErrorException model(
                endos = @variables(Y, C, G),
                exos = @variables(),
                params = @variables(),
                eqs = eqs
            )
        end

        # test future indices
        @test_throws ErrorException model(
            eqs = @equations begin
                Y = Y[1]
            end
        )
        @test_throws ErrorException model(
            exos = @variables(G),
            eqs = @equations begin
                Y = G[1]
            end
        )
    end

    @testset "Verbose" begin
        let eqs = @equations begin
                Y = C + G
            end
            model(
                endos = @variables(Y),
                exos = @variables(C, G),
                params = @variables(),
                eqs = eqs,
                verbose = true
            )
        end
    end

    @testset "Default models" begin
        sim = Consistent.SIM()
        @test sim[:model].exogenous_variables.variables == [:G]
        show(sim)
        Consistent.SIMStoch()
        Consistent.LP()
        Consistent.PC()
        Consistent.DIS()
        Consistent.BMW()
    end

    @testset "Combine models" begin
        PC_gdp = model(
            endos = @variables(Y, YD, T, V, C),
            exos = @variables(r, G, B_h),
            params = @variables(α_1, α_2, θ),
            eqs = @equations begin
                Y = C + G
                YD = Y - T + r[-1] * B_h[-1]
                T = θ * (Y + r[-1] * B_h[-1])
                V = V[-1] + (YD - C)
                C = α_1 * YD + α_2 * V[-1]
            end
        )

        PC_hh = model(
            endos = @variables(H_h, B_h, B_s, H_s, B_cb, r),
            exos = @variables(r_exo, G, V, YD, T),
            params = @variables(λ_0, λ_1, λ_2),
            eqs = @equations begin
                H_h = V - B_h
                B_h = (λ_0 + λ_1 * r - λ_2 * (YD / V)) * V
                B_s = (G + r[-1] * B_s[-1]) - (T + r[-1] * B_cb[-1]) + B_s[-1]
                H_s = B_cb - B_cb[-1] + H_s[-1]
                B_cb = B_s - B_h
                r = r_exo
            end
        )

        PC_complete = PC_gdp + PC_hh
    end

    @testset "Solve" begin
        sim = Consistent.SIM()
        let sol = solve(
                sim[:model],
                sim[:lags],
                sim[:exos],
                map(x -> sim[:params][x], sim[:model].parameters)
            )
            @test round(sol[1]) == 38.0
        end
    end
end