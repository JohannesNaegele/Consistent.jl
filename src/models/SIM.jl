function SIM()
    params = @parameters begin
        θ = 0.2
        α_1 = 0.6
        α_2 = 0.4
    end

    sim = model(
        endos=@variables(Y, T, YD, C, H_s, H_h, H),
        exos=@variables(G),
        params=params,
        eqs=@equations begin
            Y = C + G
            T = θ * Y
            YD = Y - T
            C = α_1 * YD + α_2 * H[-1]
            H_s + H_s[-1] = G - T
            H_h + H_h[-1] = YD - C
            H = H_s + H_s[-1] + H[-1]
        end
    )

    Dict(
        :params => params,
        :exos => [20.0][:, :],
        :lags => fill(0.0, length(sim.endogenous_variables), 1),
        :model => sim
    )
end