@model begin
    @endogenous G Y T YD C_e C H_s H_h H
    @exogenous G_0 u_G u_T u_C
    @parameters θ α_1 α_2
    @equations begin
        G = G_0 + u_G
        Y = C + G
        T = θ * Y + u_T
        YD = Y - T
        C_e = α_1 * YD + α_2 * H[-1] + α_3 * C_e[-1]
        C = C_e + u_C
        H_s + H_s[-1] = G - T
        H_h + H_h[-1] = YD - C
        H = H_s + H_s[-1] + H[-1]
    end
end

values = Dict(
    :θ => 0.2, 
    :α_1 => 0.6,
    :α_2 => 0.4,
)

# possible extension: C = f(C_e) + U_e, C_e = f(..., C_e[-1]), where C_e is not observable. 
# Then the concept of likelihood might become helpful

# @random u_G, u_T, u_C
# @observable Y, T, YD, H_s, H  # part of endogenous variables since unknown endogenous variables are parameters

# two-fold idea: 
# (1) make models generally probabilistic and use estimated distribution to forecast 
#     (knowledge of distribution necessary, but given that the model should still be estimatable with OLS)
# (2) Use nonlinear models with unobservable variables, then parameters can not be estimated anymore with OLS since there is no linear rearrangement