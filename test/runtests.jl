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
        # only binary infix calls are valid in a variable list
        @test_throws ErrorException Consistent.remove_expr(:(f(x)))

        # find_symbols collects variables, not operators or called functions
        @test Consistent.find_symbols(:(Y = log(X))) == Set([:Y, :X])
        @test Consistent.find_symbols(:(C = α_1 * YD + α_2 * H[-1])) ==
              Set([:C, :α_1, :YD, :α_2, :H])

        # equations print as readable strings, not quoted expressions
        let eqs = @equations begin
                Y = C + G
                H_s + H_s[-1] = G - T
            end
            str = sprint(show, MIME("text/plain"), eqs)
            @test occursin("Y = C + G", str)
            @test occursin("H_s + H_s[-1] = G - T", str)
            @test !occursin(":(", str)
        end

        test_eqs = quote
            z = y * (y[-1] + 0.5 * z) * θ + x[-1]
            y = z[-2] * x * b
        end
        replace_worked = @test_logs (:warn, "Symbols [:b] are not in variables or parameters") Consistent.replace_vars(
                test_eqs.args[[2, 4]], [:z, :y], Symbol[:x], [:θ]
            ) == [
                :(endos[1] = endos[2] * (lags[2, end - 0] + 0.5 * endos[1]) * params[1] + exos[1, end + -1]),
                :(endos[2] = lags[1, end - -1] * exos[1, end + 0] * b)
            ]
        @test replace_worked

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
            @test_logs (:warn, "Symbols [:C] are not in variables or parameters") model(
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
        @test sim isa Scenario
        @test sim.model.exogenous_variables.variables == [:G]
        @test occursin("SFC scenario", sprint(show, sim))
        for f in (Consistent.SIMStoch, Consistent.LP, Consistent.PC, Consistent.DIS, Consistent.BMW)
            @test f() isa Scenario
        end
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
        sol = solve(sim.model, sim.lags, sim.exos, param_values(sim))
        @test round(sol[1]) == 38.0
        # convenience method on a Scenario
        @test round(solve(sim)[1]) == 38.0
        # NonlinearSolve backend agrees with the NLsolve default
        @test round(solve(sim; method=:trust_region)[1]) == 38.0
    end

    @testset "Structural checks" begin
        # not square: 2 endogenous variables, 1 equation
        @test_throws ErrorException model(
            endos = @variables(Y, C),
            exos = @variables(G),
            eqs = @equations begin
                Y = C + G
            end
        )
        # square, but `Y` is determined twice and `Z` never
        @test_throws ErrorException model(
            endos = @variables(Y, Z),
            exos = @variables(G),
            eqs = @equations begin
                Y = G
                Y = G + Z
            end
        )
        # every predefined model is square
        for f in (Consistent.SIM, Consistent.SIMStoch, Consistent.LP,
                  Consistent.PC, Consistent.DIS, Consistent.BMW)
            m = f().model
            @test length(m.equations) == length(m.endogenous_variables)
        end
    end

    @testset "Structure / composition" begin
        sc = Consistent.SIM()
        m = sc.model

        # block decomposition partitions the endogenous variables ...
        blocks = block_decomposition(m)
        @test sort(reduce(vcat, blocks), by=string) ==
              sort(collect(m.endogenous_variables), by=string)
        # ... the simultaneous core {Y, T, YD, C} is a single block ...
        core = only(filter(b -> length(b) > 1, blocks))
        @test Set(core) == Set([:Y, :T, :YD, :C])
        # ... and recursive variables come after it
        @test findfirst(b -> :Y in b, blocks) < findfirst(b -> :H in b, blocks)

        # reorder gives an equal model that still solves to the same value
        rm = reorder(m)
        @test rm == m
        solr = solve(rm, sc.lags, sc.exos, param_values(sc))
        @test round(solr[findfirst(==(:Y), rm.endogenous_variables)]) == 38.0

        # composition is commutative (equal up to ordering)
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
        @test PC_gdp + PC_hh == PC_hh + PC_gdp
    end
end