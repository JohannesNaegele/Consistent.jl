using Consistent

PC_gdp = @model begin
    @endogenous Y YD T V C
    @exogenous r G B_h
    @parameters α_1 α_2 θ
    @equations begin
        Y = C + G
        YD = Y - T + r[-1] * B_h[-1]
        T = θ * (Y + r[-1] * B_h[-1])
        V = V[-1] + (YD - C)
        C = α_1 * YD + α_2 * V[-1]
    end
end

PC_hh = @model begin
    @endogenous H_h B_h B_s H_s B_cb r
    @exogenous r_exo G V YD T
    @parameters λ_0 λ_1 λ_2
    @equations begin
        H_h = V - B_h
        B_h = (λ_0 + λ_1 * r - λ_2 * (YD / V)) * V
        B_s = (G + r[-1] * B_s[-1]) - (T + r[-1] * B_cb[-1]) + B_s[-1]
        H_s = B_cb - B_cb[-1] + H_s[-1]
        B_cb = B_s - B_h
        r = r_exo
    end
end

PC_complete = PC_gdp + PC_hh