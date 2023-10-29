using Consistent

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

# Note: Since the variables and equations are ordered this operation is not commutative!
PC_complete = PC_gdp + PC_hh