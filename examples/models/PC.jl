@model begin
    @endogenous Y YD T V C H_h B_h B_s H_s B_cb r G
    @exogenous r_exo
    @parameters α_1 α_2 λ_0 λ_1 λ_2 θ
    @equations begin
        Y = C + G
        YD = Y - T + r[-1] * B_h[-1]
        T = θ * (Y + r[-1] * B_h[-1])
        V = V[-1] + (YD - C)
        C = α_1 * YD + α_2 * V[-1]
        H_h = V - B_h
        B_h = (λ_0 + λ_1 * r - λ_2 * (YD / V)) * V
        B_s = (G + r[-1] * B_s[-1]) - (T + r[-1] * B_cb[-1]) + B_s[-1]
        H_s = B_cb - B_cb[-1] + H_s[-1]
        B_cb = B_s - B_h
        r = r_exo
    end
end