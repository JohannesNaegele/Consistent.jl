"""
Note: This is some old model where I don't know the origin anymore.
It is probably related to some Peter Bofinger textbook.
"""
BMW() = @model begin
    @endogenous C_s C_d I_s I_d N_s N_d L_s L_d r_l r_m K K_T DA
    @exogenous r_exo
    @parameters α_0 α_1_w α_1_r α_2
    @equations begin
        C_s = C_d
        I_s = I_d
        N_s = N_d
        L_s = L_d - L_d[-1] + L_s[-1]
        Y = C_s + I_s
        WB_d = Y - r_l[-1] * L_d[-1] - AF
        AF = delta * K[-1]
        L_d = I_d - AF + L_d[-1]
        YD = WB_s + r_m[-1] * M_d[-1]
        M_h = YD - C_d + M_h[-1]
        M_s = L_s - L_s[-1] - M_s[-1]
        r_m = r_l
        WB_s = W * N_s
        N_d = Y / pr
        W = WB_d / N_d
        C_d = α_0 + α_1_w * WB_s + α_1_r * r_m[-1] * M_h[-1] + α_2 * M_h
        K = I_d - DA - K[-1]
        DA = delta * K[-1]
        K_T = kappa * Y[-1]
        I_d = gamma * (K_T - K[-1]) + DA
        r_l = r_exo
    end
end