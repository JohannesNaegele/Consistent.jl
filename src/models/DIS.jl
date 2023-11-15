function DIS()
    params = @parameters begin
        α_0 = 15.0
        α_1 = 0.8
        α_2 = 0.1
        σ_T = 0.15
        γ = 0.25
        β = 0.75
        pr = 1.0
        W = 0.75
        ϕ = 0.25
        r_l = 0.025
        add = 0.02
        ε = 0.75
    end
    Dict(
        :params => params,
        :model => model(
            params = params,
            eqs = @equations begin
                y = s_e + (in_e[0] - in[-1])
                in_T = σ_T * s_e
                in_e[0] = in[-1] + γ * (in_T - in[-1])
                in = in[-1] + (y - s)
                s_e = β * s[-1] + (1 - β) * s_e[-1]
                s = c
                N = y / (pr)
                WB = N * W
                UC = WB / y
                IN = in * UC
                S = p * s
                p = (1 + ϕ) * NHUC
                NHUC = (1 - σ_T) * UC + σ_T * (1 + r_l) * UC[-1]
                F = S - WB + (IN[0] - IN[-1]) - r_l * IN[-1]
                L_d = IN
                L_s = L_d
                M_s = L_s
                r_m = r_l - add
                F_b = r_l * L_s[-1] - r_m[-1] * M_h[-1]
                YD = WB + F + F_b + r_m[-1] * M_h[-1]
                M_h[0] - M_h[-1] = YD - C
                yd_hs = c + (m_h[0] - m_h[-1])
                C = c * p
                m_h = M_h / p
                c = α_0 + α_1 * yd_e_hs + α_2 * m_h[-1]
                yd_e_hs = ε * yd_hs[-1] + (1 - ε) * yd_e_hs[-1]
            end
        ),
    )
end