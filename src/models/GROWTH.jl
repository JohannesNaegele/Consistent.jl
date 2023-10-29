# Box 11.1: Aggregation equations
aggr = @equations begin
    Yk = Ske + INke - INk[-1] # 11.1: Real output
    Ske = β * Sk + (1 - β) * Sk[-1] * (1 + GRpr + RA) # 11.2: Expected real sales
    INke = INk[-1] + γ * (INkt - INk[-1]) # 11.3: Long-run inventory target
    INkt = σₜ * Ske # 11.4: Short-run inventory target
    INk = INk[-1] + Yk - Sk - NPL / UC # 11.5: Actual real inventories
    Kk = Kk[-1] * (1 + GRk) # 11.6: Real capital stock
    GRk = γ₀ + γᵤ * U[-1] - γᵣ * RRl # 11.7: Growth of real capital stock
    U = Yk / Kk[-1] # 11.8: Capital utilization proxy
    RRl = ((1 + Rl) / (1 + PI)) - 1 # 11.9: Real interest rate on loans
    PI = (P - P[-1]) / P[-1] # 11.10: Rate of price inflation
    Ik = (Kk - Kk[-1]) + δ * Kk[-1] # 11.11: Real gross investment
end

# Box 11.2: Firms equations
firms1 = @equations begin
    Sk = Ck + Gk + Ik # 11.12: Actual real sales
    S = Sk * P # 11.13: Value of realized sales
    IN = INk * UC # 11.14: Inventories valued at current cost
    INV = Ik * P # 11.15: Nominal gross investment
    K = Kk * P # 11.16: Nominal value of fixed capital
    Y = Sk * P + (INk - INk[-1]) * UC # 11.17: Nominal GDP
end

# Box 11.3: Firms equations
firms2 = @equations begin
    ωₜ = exp(ω₀ + ω₁ * log(PR) + ω₂ * log(ER + z3 * (1 - ER) - z4 * BANDₜ + z5 * BANDᵦ)) # 11.18: Real wage aspirations
    ER = N[-1] / Nfe[-1] # 11.19: Employment rate
    # 11.20: Switch variables
    z3 = ((1 + BANDᵦ) < ER <= (1 + BANDₜ)) ? 1: 0 # Band activation
    z4 = ER > (1 + BANDₜ) ? 1: 0 # Upper band overshoot
    z5 = ER < (1 - BANDᵦ) ? 1: 0 # Lower band undershoot
    W = W[-1] + ω₃ * (ωₜ * P[-1] - W[-1]) # 11.21: Nominal wage
    PR = PR[-1] * (1 + GRpr) # 11.22: Labor productivity
    Nt = Yk / PR # 11.23: Desired employment
    N = N[-1] + ηₙ * (Nt - N[-1]) # 11.24: Actual employment --> etan not in the book
    WB = N * W # 11.25: Nominal wage bill
    UC = WB / Yk # 11.26: Actual unit cost
    NUC = W / PR # 11.27: Normal unit cost
    NHUC = (1 - σₙ) * NUC + σₙ * (1 + Rln[-1]) * NUC[-1] # 11.28: Normal historic unit cost
end

# Box 11.4: Firms equations
firms3 = @equations begin
    P = (1 + ϕ) * NHUC # 11.29: Normal-cost pricing
    ϕ = ϕ[-1] + ε₂ * (ϕₜ[-1] - ϕ[-1]) # 11.30: Actual mark-up --> ε₂ not in the book
    ϕₜ = (FUft + FDf + Rl[-1] * (Lfd[-1] - IN[-1])) / ((1 - σₛₑ) * S) # 11.32: Expected historical costs
    HCe = (1 - σₛₑ) * Ske * UC + (1 + Rl[-1]) * σₛₑ * Ske * UC[-1] # 11.33: Opening inventories to expected sales ratio
    σₛₑ = INk[-1] / Ske # 11.34: Planned entrepeneurial profits of firms
    Fft = FUft + FDf + Rl[-1] * (Lfd[-1] - IN[-1]) # 11.34: Planned entrepeneurial profits of firms
    FUft = ψᵤ * INV[-1] # 11.35: Planned retained earnings of firms
    FDf = ψd * Ff[-1] # 11.36: Dividends of firms
end

# Box 11.5: Firms equations
firms4 = @equations begin
    Ff = S - WB + (IN - IN[-1]) - Rl[-1]*IN[-1] # 11.37: Realized entrepeneurial profits
    FUf = Ff - FDf - Rl[-1]*(Lfd[-1] - IN[-1]) + Rl[-1]*NPL # 11.38: Retained earnings of firms
    Lfd = Lfd[-1] + INV + (IN - IN[-1]) - FUf - (Eks - Eks[-1])*Pe - NPL # 11.39: Demand for loans by firms
    NPL = NPLk * Lfs[-1] # 11.40: Defaulted loans

end

@equations begin
    # 11.64: Demand for bills
    Bhd = Vfma[-1] * (λ20 + λ22 * Rb[-1] - λ21 * Rm[-1] - λ24 * Rk[-1] - λ23 * Rbl[-1] - λ25 * (YDr / V))
    # 11.65: Demand for bonds
    BLd = Vfma[-1] * (λ30 - λ32 * Rb[-1] - λ31 * Rm[-1] - λ34 * Rk[-1] + λ33 * Rbl[-1] - λ35 * (YDr / V)) / Pbl
    # 11.66: Demand for equities - normalized to get the price of equitities
    Pe = Vfma[-1] * (λ40 - λ42 * Rb[-1] - λ41 * Rm[-1] + λ44 * Rk[-1] - λ43 * Rbl[-1] - λ45 * (YDr / V)) / Ekd
    Mh = Vfma - Bhd - Pe * Ekd - Pbl * BLd + Lhd # 11.67: Money deposits - as a residual
    Vfma = V - Hhd - OFb # 11.68: Investible wealth
    VfmaA = Mh + Bhd + Pbl * BLd + Pe * Ekd 
    Hhd = λc * CONS # 11.69: Households demand for cash
    Ekd = Eks # 11.70: Stock market equilibrium
end

# Box 11.9: Governments equations
gov = @equations begin
    G = Gk * P                                # 11.71: Pure government expenditures
    Gk = Gk[-1] * (1 + GRg)                   # 11.72: Real government expenditures
    PSBR = G + BLs[-1] + Rb[-1] * (Bbs[-1] + Bhs[-1]) - TX  # 11.73: Government deficit --> BLs[-1] missing in the book
    # 11.74: New issues of bills
    Bs = Bs[-1] + G - TX - (BLs - BLs[-1]) * Pbl + Rb[-1] * (Bhs[-1] + Bbs[-1]) + BLs[-1]
    GD = Bbs + Bhs + BLs * Pbl + Hs           # 11.75: Government debt 
end

# Box 11.10: The Central banks equations
cb = @equations begin
    # ----------------------------------------
    Fcb = Rb[-1] * Bcbd[-1]                   # 11.76: Central bank profits
    BLs = BLd                                 # 11.77: Bonds are supplied on demand
    Bhs = Bhd                                 # 11.78: Household bills supplied on demand
    Hhs = Hhd                                 # 11.79: Cash supplied on demand
    Hbs = Hbd                                 # 11.80: Reserves supplied on demand
    Hs = Hbs + Hhs                            # 11.81: Total supply of cash
    Bcbd = Hs                                 # 11.82: Central bank
    Bcbs = Bcbd                               # 11.83: Supply of bills to Central bank
    Rb = Rb̄                                  # 11.84: Interest rate on bills set exogenously
    Rbl = Rb + ADDbl                          # 11.85: Long term interest rate
    Pbl = 1 / Rbl                             # 11.86: Price of long-term bonds
end

# Box 11.11: Commercial Banks equations
banks1 = @equations begin
    # ---------------------------------------
    Ms = Mh                                   # 11.87: Bank deposits supplied on demand
    Lfs = Lfd                                 # 11.88: Loans to firms supplied on demand
    Lhs = Lhd                                 # 11.89: Personal loans supplied on demand
    Hbd = ρ * Ms                              # 11.90: Reserve requirements of banks
    # 11.91: Bills supplied to banks
    Bbs = Bbs[-1] + (Bs - Bs[-1]) - (Bhs - Bhs[-1]) - (Bcbs - Bcbs[-1])
    # 11.92: Balance sheet constraint of banks
    Bbd = Ms + OFb - Lfs - Lhs - Hbd
    BLR = Bbd / Ms                            # 11.93: Bank liquidity ratio
    # 11.94: Deposit interest rate
    Rm = Rm[-1] + z1a * xīm1 + z1b * xīm2 - z2a * xīm1 - z2b * xīm2
    # 11.95-97: Mechanism for determining changes to the interest rate on deposits
    z2a = if BLR[-1] > (top + 0.05)
        1
    else
        0
    end
    z2b = if BLR[-1] > top
        1
    else
        0
    end
    z1a = if BLR[-1] ≤ bot
        1
    else
        0
    end
    z1b = if BLR[-1] ≤ (bot - 0.05)
        1
    else
        0
    end
end

# Box 11.12: Commercial banks equations
banks2 = @equations begin
    # ---------------------------------------
    Rl = Rm + ADDl                            # 11.98: Loan interest rate
    OFbt = NCAR * (Lfs[-1] + Lhs[-1])         # 11.99: Long-run own funds target
    OFbe = OFb[-1] + β * (OFbt - OFb[-1])     # 11.100: Short-run own funds target
    FUbt = OFbe - OFb[-1] + NPLke * Lfs[-1]   # 11.101: Target retained earnings of banks
    NPLke = εb * NPLke[-1] + (1 - εb) * NPLk[-1]  # 11.102: Expected proportion of non-performing loans
    FDb = Fb - FUb                            # 11.103: Dividends of banks
    Fbt = λb * Y[-1] + (OFbe - OFb[-1] + NPLke * Lfs[-1])  # 11.104: Target profits of banks
    # 11.105: Actual profits of banks
    Fb = Rl[-1] * (Lfs[-1] + Lhs[-1] - NPL) + Rb[-1] * Bbd[-1] - Rm[-1] * Ms[-1]
    # 11.106: Lending mark-up over deposit rate
    ADDl = (Fbt - Rb[-1] * Bbd[-1] + Rm[-1] * (Ms[-1] - (1 - NPLke) * Lfs[-1] - Lhs[-1])) / ((1 - NPLke) * Lfs[-1] + Lhs[-1])
    FUb = Fb - λb * Y[-1]                      # 11.107: Actual retained earnings
    OFb = OFb[-1] + FUb - NPL                  # 11.108: Own funds of banks
    CAR = OFb / (Lfs + Lhs)

    Vf = IN + K - Lfd - Ekd * Pe               # Firm's wealth (memo for matrices)
    # Vg = -Bs - BLs * Pbl                      # Government's wealth (memo for matrices)
    Ls = Lfs + Lhs                             # Loans supply (memo for matrices)
end

param_dict = @parameters begin
    alpha1 = 0.75
    alpha2 = 0.064
    beta = 0.5
    betab = 0.4
    gamma = 0.15
    gamma0 = 0.00122
    gammar = 0.1
    gammau = 0.05
    delta = 0.10667
    deltarep = 0.1
    eps = 0.5
    eps2 = 0.8
    epsb = 0.25
    epsrb = 0.9
    eta0 = 0.07416
    etan = 0.6
    etar = 0.4
    theta = 0.22844
    # λ10 = -0.17071
    # λ11 = 0
    # λ12 = 0
    # λ13 = 0
    # λ14 = 0
    # λ15 = 0.18
    λ20 = 0.25
    λ21 = 2.2
    λ22 = 6.6
    λ23 = 2.2
    λ24 = 2.2
    λ25 = 0.1
    λ30 = -0.04341
    λ31 = 2.2
    λ32 = 2.2
    λ33 = 6.6
    λ34 = 2.2
    λ35 = 0.1
    λ40 = 0.67132
    λ41 = 2.2
    λ42 = 2.2
    λ43 = 2.2
    λ44 = 6.6
    λ45 = 0.1
    λb = 0.0153
    λc = 0.05
    xim1 = 0.0008
    xim2 = 0.0007
    ro = 0.05
    σn = 0.1666
    σt = 0.2
    psid = 0.15255
    psiu = 0.92
    omega0 = -0.20594
    omega1 = 1
    omega2 = 2
    omega3 = 0.45621
end

initial = @equations begin
    σse = 0.16667
    eta = 0.04918
    phi = 0.26417
    phit = 0.26417

    ADDbl = 0.02
    BANDt = 0.01
    BANDb = 0.01
    bot = 0.05
    GRg = 0.03
    GRpr = 0.03
    Nfe = 87.181
    NCAR = 0.1
    NPLk = 0.02
    Rbbar = 0.035
    Rln = 0.07
    RA = 0
    top = 0.12

    ADDl = 0.04592
    BLR = 0.1091
    BUR = 0.06324
    Ck = 7334240
    CAR = 0.09245
    CONS = 52603100
    ER = 1
    Fb = 1744130
    Fbt = 1744140
    Ff = 18081100
    Fft = 18013600
    FDb = 1325090
    FDf = 2670970
    FUb = 419039
    FUf = 15153800
    FUft = 15066200
    G = 16755600
    Gk = 2336160
    GL = 2775900
    GRk = 0.03001
    INV = 16911600
    Ik = 2357910
    N = 87.181
    Nt = 87.181
    NHUC = 5.6735
    NL = 683593
    NLk = 95311
    NPL = 309158
    NPLke = 0.02
    NUC = 5.6106
    omegat = 112852
    P = 7.1723
    Pbl = 18.182
    Pe = 17937
    PE = 5.07185
    PI = 0.0026
    PR = 138659
    PSBR = 1894780
    Q = 0.77443
    Rb = 0.035
    Rbl = 0.055
    Rk = 0.03008
    Rl = 0.06522
    Rm = 0.0193
    REP = 2092310
    #RRb = 0.03232
    RRl = 0.06246
    S = 86270300
    Sk = 12028300
    Ske = 12028300
    TX = 17024100
    U = 0.70073
    UC = 5.6106
    W = 777968
    WB = 67824000
    Y = 86607700
    Yk = 12088400
    YDr = 56446400
    YDkr = 7813270
    YDkre = 7813290
    YP = 73158700
    z1a = 0
    z1b = 0
    z2a = 0
    z2b = 0

    #Bbd = 4388930
    #Bbs = 4388930
    Bbd = 4389790
    Bbs = 4389790
    Bcbd = 4655690
    Bcbs = 4655690
    Bhd = 33439320
    Bhs = 33439320
    #Bhd = 33396900
    #Bhs = 33396900
    Bs = 42484800
    #Bs = 42441520
    BLd = 840742
    BLs = 840742
    GD = 57728700
    Ekd = 5112.6001
    Eks = 5112.6001
    Hbd = 2025540
    Hbs = 2025540
    Hhd = 2630150
    Hhs = 2630150
    Hs = 4655690
    IN = 11585400
    INk = 2064890
    INke = 2405660
    INkt = 2064890
    #K = 127444000
    K = 127486471
    #Kk = 17768900
    Kk = 17774838
    Lfd = 15962900
    Lfs = 15962900
    Lhd = 21606600
    Lhs = 21606600
    Ls = 37569500
    #Md = 40510800
    Mh = 40510800
    Ms = 40510800
    OFb = 3474030
    OFbe = 3474030
    #OFb = 3473280
    #OFbe = 3782430
    OFbt = 3638100
    #V = 165395000
    V = 165438779
    #Vfma = 159291000
    Vfma = 159334599
    Vk = 23066350
    Vf = 31361792
end