function LP()
    params = @parameters begin
        θ = 0.194
        α_1 = 0.8
        α_2 = 0.2
        λ_20 = 0.442
        λ_22 = 1.1
        λ_23 = -1
        λ_24 = -0.03
        λ_30 = 0.4
        λ_32 = -1.
        λ_33 = 1.1
        λ_34 = -0.03
        χ = 0.1
        r_b_exo = 0.03
        p_bL_exo = 20.
    end
    Dict(
        :params => params,
        :model => model(
            exos = @variables(G),
            params = params,
            eqs = @equations begin
                Y = C + G
                YD_r = Y - T + r_b[-1] * B_h[-1] + BL_h[-1]
                T = θ * (Y + r_b[-1] + BL_h[-1])
                V = V[-1] + (YD_r - C) + CG
                CG = (p_bL - p_bL[-1]) * BL_h[-1]
                C = α_1 * YD_r_e + α_2 * V[-1]
                V_e = V[-1] + (YD_r_e - C) + CG
                H_h = V - B_h - p_bL * BL_h
                H_d = V_e - B_h - p_bL * BL_h
                B_d = (λ_20 + λ_22 * r_b + λ_23 * ERr_bL + λ_24 * (YD_r_e / V_e)) * V_e
                BL_d = (λ_30 + λ_32 * r_b + λ_33 * ERr_bL + λ_34 * (YD_r_e / V_e)) * (V_e / p_bL)
                B_h = B_d
                BL_h = BL_d
                B_s = (G + r_b[-1] * B_s[-1] + BL_s[-1]) - (T + r_b[-1] * B_cb[-1]) - ((BL_s - BL_s[-1]) * p_bL) + B_s[-1]
                H_s = B_cb - B_cb[-1] + H_s[-1]
                B_cb = B_s - B_h
                BL_s = BL_h
                ERr_bL = r_bL + χ * ((p_bL_e - p_bL) / p_bL)
                r_bL = 1 / p_bL
                p_bL_e = p_bL
                CG_e = χ * (p_bL_e - p_bL) * BL_h
                YD_r_e = YD_r[-1]
                r_b = r_b_exo
                p_bL = p_bL_exo
            end
        )
    )
end

# G = 20.