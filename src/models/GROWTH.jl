@equations begin
    Yk = Ske + INke - INk[-1],          # 11.1 : Real output
    Ske = β * Sk + (1 - β) * Sk[-1] * (1 + GRpr + RA),  # 11.2 : Expenditure
    INke = INk[-1] + γ * (INkt - INk[-1]),  # 11.3 : Investment expenditure
    INkt = σₜ * Ske,  # 11.4 : Intended investment expenditure
    INk = INk[-1] + Yk - Sk - NPL / UC,  # 11.5 : Capital goods demand
    Kk = Kk[-1] * (1 + GRk),  # 11.6 : Capital stock
    GRk = γ₀ + γᵤ * U[-1] - γᵣ * RRl,  # 11.7 : Growth rate of capital stock
    U = Yk / Kk[-1],  # 11.8 : Capacity utilization
    RRl = ((1 + Rl) / (1 + PI)) - 1,  # 11.9 : Real rate of interest
    PI = (P - P[-1]) / P[-1],  # 11.10 : Inflation rate
    Sk = Ck + Gk + Ik,  # 11.11 : Aggregate supply
    S = Sk * P,  # 11.12 : Nominal supply
    IN = INk * UC,  # 11.13 : Nominal investment
    INV = Ik * P,  # 11.14 : Nominal inventory investment
    K = Kk * P,  # 11.15 : Nominal capital stock
    Y = Sk * P + (INk - INk[-1]) * UC,  # 11.16 : Nominal output
    ωₜ = exp(ω₀ + ω₁ * log(PR) + ω₂ * log(ER + z3 * (1 - ER) - z4 * BANDₜ + z5 * BANDᵦ)),  # 11.17 : Real exchange rate
    ER = N[-1] / Nfe[-1],  # 11.18 : Exchange rate
    z3a = ER > (1 - BANDᵦ) ? 1 : 0,  # 11.19a : Upper band activation
    z3b = ER <= (1 + BANDₜ) ? 1 : 0,  # 11.19b : Lower band activation
    z3 = z3a * z3b,  # 11.20 : Band activation
    z4 = ER > (1 + BANDₜ) ? 1 : 0,  # 11.21 : Upper band overshoot
    z5 = ER < (1 - BANDᵦ) ? 1 : 0,  # 11.22 : Lower band undershoot
    W = W[-1] + ω₃ * (ωₜ * P[-1] - W[-1]),  # 11.23 : Wage adjustment
    PR = PR[-1] * (1 + GRpr),  # 11.24 : Productivity
    Nt = Yk / PR,  # 11.25 : Employment target
    N = N[-1] + ηₙ * (Nt - N[-1]),  # 11.26 : Employment
    WB = N * W,  # 11.27 : Wage bill
    UC = WB / Yk,  # 11.28 : Unit labor costs
    NUC = W / PR,  # 11.29 : Normal unit costs
    NHUC = (1 - σₙ) * NUC + σₙ * (1 + Rln[-1]) * NUC[-1],  # 11.30 : Historical unit costs
    P = (1 + ϕ) * NHUC,  # 11.31 : Price level
    ϕ = ϕ[-1] + ε₂ * (ϕₜ[-1] - ϕ[-1]),  # 11.32 : Markup adjustment
    ϕₜ = (FUft + FDf + Rl[-1] * (Lfd[-1] - IN[-1])) / ((1 - σₛₑ) * S)  # 11.33 : Target markup
    Lfd = Lfd[-1] + FDf - P * INV / (1 + Rl),  # 11.34 : Funding need for firm debt
    FDf = ϵ₃ * (P * INV - Lfd[-1] * (1 + Rl)),  # 11.35 : Change in funding need
    Lft = Lf - FUft,  # 11.36 : Target for liquid assets of firms
    FUf = Lft - FUft,  # 11.37 : Funding need for liquid assets
    Lf = ϵ₄ * (P * S - W * N - T),  # 11.38 : Liquid assets of firms
    T = τ * Y,  # 11.39 : Taxes
    Ck = θ * (W * N + DIV - T + TR),  # 11.40 : Consumption out of income
    Ik = (1 - θ) * (W * N + DIV - T + TR),  # 11.41 : Investment out of income
    TR = TRt * Y,  # 11.42 : Transfers
    DIV = πt * Y,  # 11.43 : Dividends
    Gk = Gt * Y,  # 11.44 : Government consumption
    Rl = max(0, Rb + πt - θₑ * (πt - πtₑ)),  # 11.45 : Lending rate
    πtₑ = ϵ₅ * πt + (1 - ϵ₅) * πtₑ,  # 11.46 : Expected inflation
    Rb = Rbₜ * (1 + ψ * (D / Y - Dₜ / Y)),  # 11.47 : Base rate
    D = Lfd + Lh,  # 11.48 : Total debt
    Lh = Lh[-1] + Ch - Ph * IH / (1 + Rh),  # 11.49 : Funding need for household debt
    Ch = ϵ₆ * (Ph * IH - Lh[-1] * (1 + Rh)),  # 11.50 : Change in funding need for households
    Ht = H - FUht,  # 11.51 : Target for liquid assets of households
    FUh = Ht - FUht,  # 11.52 : Funding need for liquid assets of households
    H = ϵ₇ * (Ph * Ck + Ph * Gk - WB - T),  # 11.53 : Liquid assets of households
    Rh = max(0, Rb + πt - θₘ * (πt - πtₘ)),  # 11.54 : Household lending rate
    πtₘ = ϵ₈ * πt + (1 - ϵ₈) * πtₘ,  # 11.55 : Expected inflation for households
    IH = ι * H,  # 11.56 : Housing investment
    Ph = max(0, Ph[-1] + ϵ₉ * (UC * Yk - Ph[-1] * IH)),  # 11.57 : House price
    UC = α * (Ck + Gk) + β * IH + (1 - α - β) * Yk,  # 11.58 : Utilized capacity
    Yk = Ske + INke - INk[-1],  # 11.59 : Real output
    INk = δ * K,  # 11.60 : Capital depreciation
    Ske = min(Sk, Dk / P),  # 11.61 : Effective supply
    Sk = ξ * Yk,  # 11.62 : Supply
    Dk = Lfd + Ch + FUf + FUh + Ph * IH,  # 11.63 : Demand for credit
    K = K[-1] + Ik - INk,  # 11.64 : Capital stock
    WB = W * N,  # 11.65 : Wage bill
    W = Wp * P,  # 11.66 : Nominal wage
    Wp = Wp[-1] * (1 + λ * (πt - πtₑ)),  # 11.67 : Real wage target
    πt = (P - P[-1]) / P[-1],  # 11.68 : Inflation
    P = P[-1] * (1 + μ * (UC - 1)),  # 11.69 : Price level
    N = Ns,  # 11.70 : Employment
    Ns = Yk / A,  # 11.71 : Supply of labor
    A = A[-1] * (1 + g),  # 11.72 : Labor productivity
    g = gₜ * (1 + χ * (UC - 1)),  # 11.73 : Growth rate of productivity
    # Box 11.9 : Governments equations
    # ---------------------------------
    G = Gk * P,                                # 11.71 : Pure government expenditures
    Gk = Gk[-1] * (1 + GRg),                   # 11.72 : Real government expenditures
    PSBR = G + BLs[-1] + Rb[-1] * (Bbs[-1] + Bhs[-1]) - TX,  # 11.73 : Government deficit --> BLs[-1] missing in the book
    # 11.74 : New issues of bills
    Bs = Bs[-1] + G - TX - (BLs - BLs[-1]) * Pbl + Rb[-1] * (Bhs[-1] + Bbs[-1]) + BLs[-1],
    GD = Bbs + Bhs + BLs * Pbl + Hs,           # 11.75 : Government debt 

    # Box 11.10 : The Central banks equations
    # ----------------------------------------
    Fcb = Rb[-1] * Bcbd[-1],                   # 11.76 : Central bank profits
    BLs = BLd,                                 # 11.77 : Bonds are supplied on demand
    Bhs = Bhd,                                 # 11.78 : Household bills supplied on demand
    Hhs = Hhd,                                 # 11.79 : Cash supplied on demand
    Hbs = Hbd,                                 # 11.80 : Reserves supplied on demand
    Hs = Hbs + Hhs,                            # 11.81 : Total supply of cash
    Bcbd = Hs,                                 # 11.82 : Central bank
    Bcbs = Bcbd,                               # 11.83 : Supply of bills to Central bank
    Rb = Rb̄,                                  # 11.84 : Interest rate on bills set exogenously
    Rbl = Rb + ADDbl,                          # 11.85 : Long term interest rate
    Pbl = 1 / Rbl,                             # 11.86 : Price of long-term bonds

    # Box 11.11 : Commercial Banks equations
    # ---------------------------------------
    Ms = Mh,                                   # 11.87 : Bank deposits supplied on demand
    Lfs = Lfd,                                 # 11.88 : Loans to firms supplied on demand
    Lhs = Lhd,                                 # 11.89 : Personal loans supplied on demand
    Hbd = ρ * Ms,                              # 11.90 : Reserve requirements of banks
    # 11.91 : Bills supplied to banks
    Bbs = Bbs[-1] + (Bs - Bs[-1]) - (Bhs - Bhs[-1]) - (Bcbs - Bcbs[-1]),
    # 11.92 : Balance sheet constraint of banks
    Bbd = Ms + OFb - Lfs - Lhs - Hbd, 
    BLR = Bbd / Ms,                            # 11.93 : Bank liquidity ratio
    # 11.94 : Deposit interest rate
    Rm = Rm[-1] + z1a * xīm1 + z1b * xīm2 - z2a * xīm1 - z2b * xīm2,
    # 11.95-97 : Mechanism for determining changes to the interest rate on deposits
    z2a = if BLR[-1] > (top + .05) 1 else 0 end,
    z2b = if BLR[-1] > top 1 else 0 end,
    z1a = if BLR[-1] ≤ bot 1 else 0 end,
    z1b = if BLR[-1] ≤ (bot - .05) 1 else 0 end,

    # Box 11.12 : Commercial banks equations
    # ---------------------------------------
    Rl = Rm + ADDl,                            # 11.98 : Loan interest rate
    OFbt = NCAR * (Lfs[-1] + Lhs[-1]),         # 11.99 : Long-run own funds target
    OFbe = OFb[-1] + β * (OFbt - OFb[-1]),     # 11.100 : Short-run own funds target
    FUbt = OFbe - OFb[-1] + NPLke * Lfs[-1],   # 11.101 : Target retained earnings of banks
    NPLke = εb * NPLke[-1] + (1 - εb) * NPLk[-1],  # 11.102 : Expected proportion of non-performing loans
    FDb = Fb - FUb,                            # 11.103 : Dividends of banks
    Fbt = λb * Y[-1] + (OFbe - OFb[-1] + NPLke * Lfs[-1]),  # 11.104 : Target profits of banks
    # 11.105 : Actual profits of banks
    Fb = Rl[-1] * (Lfs[-1] + Lhs[-1] - NPL) + Rb[-1] * Bbd[-1] - Rm[-1] * Ms[-1],
    # 11.106 : Lending mark-up over deposit rate
    ADDl = (Fbt - Rb[-1] * Bbd[-1] + Rm[-1] * (Ms[-1] - (1 - NPLke) * Lfs[-1] - Lhs[-1])) / ((1 - NPLke) * Lfs[-1] + Lhs[-1]),
    FUb = Fb - λb * Y[-1],                      # 11.107 : Actual retained earnings
    OFb = OFb[-1] + FUb - NPL,                  # 11.108 : Own funds of banks
    CAR = OFb / (Lfs + Lhs),
    
    Vf = IN + K - Lfd - Ekd * Pe,               # Firm's wealth (memo for matrices)
    # Vg = -Bs - BLs * Pbl,                      # Government's wealth (memo for matrices)
    Ls = Lfs + Lhs,                             # Loans supply (memo for matrices)
end
