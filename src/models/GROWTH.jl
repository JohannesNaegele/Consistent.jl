operators!([:<, :>, :≤, :<=, :≥, :>=, :exp, :log])

# Box 11.1: Aggregation equations
aggr = model(
    exos=@variables(Sk, p),
    eqs=@equations begin
        Yk = Skₑ + INkₑ - INk[-1] # 11.1: Real output
        Skₑ = β * Sk + (1.0 - β) * Sk[-1] * (1.0 + GRpr + RA) # 11.2: Expected real sales ??? RA
        INkₜ = σₜ * Skₑ # 11.3: Long-run inventory target
        INkₑ = INk[-1] + γ * (INkₜ - INk[-1]) # 11.4: Short-run inventory target
        INk = INk[-1] + Yk - Sk - NPL / UC # 11.5: Actual real inventories ??? - NPL / UC
        Kk = Kk[-1] * (1.0 + GRk) # 11.6: Real capital stock
        GRk = γ₀ + γᵤ * U[-1] - γᵣ * RRₗ # 11.7: Growth of real capital stock ??? [-1]
        U = Yk / Kk[-1] # 11.8: Capital utilization proxy
        RRₗ = ((1.0 + rₗ) / (1.0 + π)) - 1.0 # 11.9: Real interest rate on loans
        π = (p - p[-1]) / p[-1] # 11.10: Rate of price inflation
        Ik = (Kk - Kk[-1]) + δ * Kk[-1] # 11.11: Real gross investment ???
    end
)

# Box 11.2: Firms equations
firms₁ = model(
    exos=@variables(INk),
    eqs=@equations begin
        Sk = Ck + Gk + Ik # 11.12: Actual real sales
        S = Sk * p # 11.13: Value of realized sales
        IN = INk * UC # 11.14: Inventories valued at current cost
        INV = Ik * p # 11.15: Nominal gross investment
        K = Kk * p # 11.16: Nominal value of fixed capital
        Y = Sk * p + (INk - INk[-1]) * UC # 11.17: Nominal GDP
    end
)

# Box 11.3: Firms equations
firms₂ = model(
    exos=@variables(Nfe, p, Rln, ER, BANDb),
    verbose=true,
    eqs=@equations begin
        ωT = exp(ω₀ + ω₁ * log(PR) + ω₂ * log(ER + z₃ * (1.0 - ER) - z₄ * BANDₜ + z₅ * BANDb)) # 11.18: Real wage aspirations ???
        ER = N[-1] / Nfe[-1] # 11.19: Employment rate
        # 11.20: Switch variables
        z₃ = ((1.0 - BANDb) < ER <= (1.0 + BANDₜ)) ? 1.0 : 0.0 # Band activation
        z₄ = ER > (1.0 + BANDₜ) ? 1.0 : 0.0 # Upper band overshoot
        z₅ = ER < (1.0 - BANDb) ? 1.0 : 0.0 # Lower band undershoot
        W = W[-1] + Ω₃ * (ωT * p[-1] - W[-1]) # 11.21: Nominal wage
        PR = PR[-1] * (1.0 + GRpr) # 11.22: Labor productivity
        NT = Yk / PR # 11.23: Desired employment
        N = N[-1] + ηₙ * (NT - N[-1]) # 11.24: Actual employment --> ηₙ not in the book
        WB = N * W # 11.25: Nominal wage bill
        UC = WB / Yk # 11.26: Actual unit cost
        NUC = W / PR # 11.27: Normal unit cost
        NHUC = (1.0 - σₙ) * NUC + σₙ * (1.0 + Rln[-1]) * NUC[-1] # 11.28: Normal historic unit cost
    end
)

# Box 11.4: Firms equations
firms₃ = model(
    exos=@variables(p, rₗ, Lfd, IN, UC, INk, INV, Ff),
    eqs=@equations begin
        p = (1.0 + ϕ) * NHUC # 11.29: Normal-cost pricing
        ϕ = ϕ[-1] + ε₂ * (ϕₜ[-1] - ϕ[-1]) # 11.30: Actual mark-up --> ε₂ not in the book
        # 11.32: Expected historical costs ???
        ϕₜ = (FUft + FDf + rₗ[-1] * (Lfd[-1] - IN[-1])) / ((1.0 - σₛₑ) * Skₑ * UC + (1.0 + rₗ[-1]) * σₛₑ * Skₑ * UC[-1])
        HCe = (1.0 - σₛₑ) * Skₑ * UC + (1.0 + rₗ[-1]) * σₛₑ * Skₑ * UC[-1] # 11.33: Opening inventories to expected sales ratio
        σₛₑ = INk[-1] / Skₑ # 11.34: Planned entrepeneurial profits of firms
        Fft = FUft + FDf + rₗ[-1] * (Lfd[-1] - IN[-1]) # 11.34: Planned entrepeneurial profits of firms
        FUft = ψᵤ * INV[-1] # 11.35: Planned rηined earnings of firms
        FDf = ψd * Ff[-1] # 11.36: Dividends of firms
    end
)

# Box 11.5: Firms equations
firms₄ = model(
    exos=@variables(rₗ, Lfd, IN, INV, Ff, Lfs, Pₑ, ed),
    eqs=@equations begin
        Ff = S - WB + (IN - IN[-1]) - rₗ[-1] * IN[-1] # 11.37: Realized entrepeneurial profits
        FUf = Ff - FDf - rₗ[-1] * (Lfd[-1] - IN[-1]) + rₗ[-1] * NPL # 11.38: Retained earnings of firms
        Lfd = Lfd[-1] + INV + (IN - IN[-1]) - FUf - (Eks - Eks[-1]) * Pₑ - NPL # 11.39: Demand for loans by firms
        NPL = NPLk * Lfs[-1] # 11.40: Defaulted loans ??? Lfd
        Eks = Eks[-1] + ((1.0 - ψᵤ) * INV[-1]) / Pₑ  # 11.41: Supply of equities issued by firms
        Rk = FDf / (Pₑ[-1] * ed[-1]) # 11.42: Dividend yield of firms
        PE = Pₑ / (Ff / Eks[-1])               # 11.43: Price earnings ratio
        Q = (Eks * Pₑ + Lfd) / (K + IN)        # 11.44: Tobins Q ratio
    end
)

# TODO: Δ operator
# Box 11.6: Households equations
hh₁ = model(
    exos=@variables(rₗ, Pₑ, ed, rₘ, Mₕ, rb, Bhd, BLs, Lhd, Pbl, BLd, OFb, p),
    eqs=@equations begin
        YP = WB + FDf + FDb + rₘ[-1] * Mₕ[-1] + rb[-1] * Bhd[-1] + BLs[-1] # 11.45: Personal income ???
        TX = θ * YP                       # 11.46: Income taxes
        YDᵣ = YP - TX - rₗ[-1] * Lhd[-1]      # 11.47: Regular disposable income
        YDhs = YDᵣ + CG                    # 11.48: Haig-Simons disposable income
        CG = (Pbl - Pbl[-1]) * BLd[-1] + (Pₑ - Pₑ[-1]) * ed[-1] + (OFb - OFb[-1]) # 11.49: Capital gains
        # 11.50: Wealth
        V = V[-1] + YDᵣ - CONS + (Pbl - Pbl[-1]) * BLd[-1] + (Pₑ - Pₑ[-1]) * ed[-1] + (OFb - OFb[-1]) # ???
        Vk = V / p                           # 11.51: Real stock of wealth
        CONS = Ck * p                        # 11.52: Consumption
        Ck = α₁ * (YDkre + NLk) + α₂ * Vk[-1]  # 11.53: Real consumption
        YDkre = ε * YDkr + (1.0 - ε) * (YDkr[-1] * (1.0 + GRpr)) # 11.54: Expected real regular disposable income
        YDkr = YDᵣ / p - ((p - p[-1]) * Vk[-1]) / p # 11.55: Real regular disposable income ???
    end
)

# Box 11.7: Households equations
hh₂ = model(
    exos=@variables(rₗ, YDᵣ),
    eqs=@equations begin
        GL = η * YDᵣ                       # 11.56: Gross amount of new personal loans ---> new η here
        η = η₀ - ηr * RRₗ              # 11.57: New loans to personal income ratio
        NL = GL - REP                      # 11.58: Net amount of new personal loans
        REP = δrep * Lhd[-1]             # 11.59: Personal loans repayments
        Lhd = Lhd[-1] + NL           # 11.60: Demand for personal loans
        NLk = NL / p                         # 11.61: Real amount of new personal loans
        BUR = (REP + rₗ[-1] * Lhd[-1]) / YDᵣ[-1] # 11.62: Burden of personal debt ??? [-1]
    end
)

# Box 11.8: Households equations - portfolio decisions
hh₃ = model(
    exos=@variables(Pₑ, ed, rₘ, Mₕ, rb, Bhd, Lhd, Pbl, BLd, OFb, Rk, Rbl),
    eqs=@equations begin
        # 11.64: Demand for bills
        Bhd = Vfma[-1] * (λ₂₀ + λ₂₂ * rb[-1] - λ₂₁ * rₘ[-1] - λ₂₄ * Rk[-1] - λ₂₃ * Rbl[-1] - λ₂₅ * (YDᵣ / V)) # ??? Vfma = V
        # 11.65: Demand for bonds
        BLd = Vfma[-1] * (λ₃₀ - λ₃₂ * rb[-1] - λ₃₁ * rₘ[-1] - λ₃₄ * Rk[-1] + λ₃₃ * Rbl[-1] - λ₃₅ * (YDᵣ / V)) / Pbl
        # 11.66: Demand for equities - normalized to get the price of equitities
        Pₑ = Vfma[-1] * (λ₄₀ - λ₄₂ * rb[-1] - λ₄₁ * rₘ[-1] + λ₄₄ * Rk[-1] - λ₄₃ * Rbl[-1] - λ₄₅ * (YDᵣ / V)) / ed
        Mₕ = Vfma - Bhd - Pₑ * ed - Pbl * BLd + Lhd # 11.67: Money deposits - as a residual
        Vfma = V - Hhd - OFb # 11.68: Investible wealth
        VfmaA = Mₕ + Bhd + Pbl * BLd + Pₑ * ed
        Hhd = λc * CONS # 11.69: Households demand for cash
        ed = Eks # 11.70: Stock market equilibrium
    end
)

# Box 11.9: Governments equations
gov = model(
    exos=@variables(BLs, rb, Bbs, Bhs),
    eqs=@equations begin
        G = Gk * p                                # 11.71: Pure government expenditures
        Gk = Gk[-1] * (1.0 + GRg)                   # 11.72: Real government expenditures
        PSBR = G + BLs[-1] + rb[-1] * (Bbs[-1] + Bhs[-1]) - TX  # 11.73: Government deficit --> BLs[-1] missing in the book
        # 11.74: New issues of bills
        Bs = Bs[-1] + G - TX - (BLs - BLs[-1]) * Pbl + rb[-1] * (Bhs[-1] + Bbs[-1]) + BLs[-1]
        GD = Bbs + Bhs + BLs * Pbl + Hs           # 11.75: Government debt 
    end
)

# Box 11.10: The Central banks equations
cb = model(
    exos=@variables(BLs, rb, Bhs),
    eqs=@equations begin
        Fcb = rb[-1] * Bcbd[-1]                   # 11.76: Central bank profits
        BLs = BLd                                 # 11.77: Bonds are supplied on demand
        Bhs = Bhd                                 # 11.78: Household bills supplied on demand
        Hhs = Hhd                                 # 11.79: Cash supplied on demand
        Hbs = Hbd                                 # 11.80: Reserves supplied on demand
        Hs = Hbs + Hhs                            # 11.81: Total supply of cash
        Bcbd = Hs                                 # 11.82: Central bank
        Bcbs = Bcbd                               # 11.83: Supply of bills to Central bank
        rb = Rbbar                                  # 11.84: Interest rate on bills set exogenously
        Rbl = rb + ADDbl                          # 11.85: Long term interest rate
        Pbl = 1 / Rbl                             # 11.86: Price of long-term bonds
    end
)

# Box 11.11: Commercial Banks equations
banks₁ = model(
    exos=@variables(Bhs, Bs, Bcbs),
    eqs=@equations begin
        Ms = Mₕ                                   # 11.87: Bank deposits supplied on demand
        Lfs = Lfd                                 # 11.88: Loans to firms supplied on demand
        Lhs = Lhd                                 # 11.89: Personal loans supplied on demand
        Hbd = ρ * Ms                              # 11.90: Reserve requirements of banks
        # 11.91: Bills supplied to banks
        Bbs = Bbs[-1] + (Bs - Bs[-1]) - (Bhs - Bhs[-1]) - (Bcbs - Bcbs[-1])
        # 11.92: Balance sheet constraint of banks
        Bbd = Ms + OFb - Lfs - Lhs - Hbd
        BLR = Bbd / Ms                            # 11.93: Bank liquidity ratio
        # 11.94: Deposit interest rate
        rₘ = rₘ[-1] + z1a * ξ₁ + z1b * ξ₂ - z2a * ξ₁ - z2b * ξ₂
        # 11.95-97: Mechanism for determining changes to the interest rate on deposits
        z2a = (BLR[-1] > (top + 0.05)) ? 1.0 : 0.0
        z2b = (BLR[-1] > top) ? 1.0 : 0.0
        z1a = (BLR[-1] ≤ bot) ? 1.0 : 0.0
        z1b = (BLR[-1] ≤ (bot - 0.05)) ? 1.0 : 0.0
    end
)

# Box 11.12: Commercial banks equations
banks₂ = model(
    exos=@variables(Lfs, Lhs, NPLk, Y, rb, Bbd, rₘ, Ms),
    eqs=@equations begin
        rₗ = rₘ + ADDl                            # 11.98: Loan interest rate
        OFbt = NCAR * (Lfs[-1] + Lhs[-1])         # 11.99: Long-run own funds target
        OFbe = OFb[-1] + βb * (OFbt - OFb[-1])     # 11.100: Short-run own funds target
        FUbt = OFbe - OFb[-1] + NPLke * Lfs[-1]   # 11.101: Target rηined earnings of banks
        NPLke = εb * NPLke[-1] + (1.0 - εb) * NPLk[-1]  # 11.102: Expected proportion of non-performing loans
        FDb = Fb - FUb                            # 11.103: Dividends of banks
        Fbt = λb * Y[-1] + (OFbe - OFb[-1] + NPLke * Lfs[-1])  # 11.104: Target profits of banks
        # 11.105: Actual profits of banks
        Fb = rₗ[-1] * (Lfs[-1] + Lhs[-1] - NPL) + rb[-1] * Bbd[-1] - rₘ[-1] * Ms[-1]
        # 11.106: Lending mark-up over deposit rate
        ADDl = (Fbt - rb[-1] * Bbd[-1] + rₘ[-1] * (Ms[-1] - (1.0 - NPLke) * Lfs[-1] - Lhs[-1])) / ((1.0 - NPLke) * Lfs[-1] + Lhs[-1])
        FUb = Fb - λb * Y[-1]                      # 11.107: Actual rηined earnings
        OFb = OFb[-1] + FUb - NPL                  # 11.108: Own funds of banks
        CAR = OFb / (Lfs + Lhs)
        Vf = IN + K - Lfd - ed * Pₑ               # Firm's wealth (memo for matrices)
        # Vg = -Bs - BLs * Pbl                      # Government's wealth (memo for matrices)
        Ls = Lfs + Lhs                             # Loans supply (memo for matrices)
    end
)

params_dict = @parameters begin
    α₁ = 0.75
    α₂ = 0.064
    β = 0.5
    βb = 0.4
    γ = 0.15
    γ₀ = 0.00122
    γᵣ = 0.1
    γᵤ = 0.05
    δ = 0.10667
    δrep = 0.1
    ε = 0.5
    ε₂ = 0.8
    εb = 0.25
    η₀ = 0.07416
    ηₙ = 0.6
    ηr = 0.4
    θ = 0.22844
    λ₂₀ = 0.25
    λ₂₁ = 2.2
    λ₂₂ = 6.6
    λ₂₃ = 2.2
    λ₂₄ = 2.2
    λ₂₅ = 0.1
    λ₃₀ = -0.04341
    λ₃₁ = 2.2
    λ₃₂ = 2.2
    λ₃₃ = 6.6
    λ₃₄ = 2.2
    λ₃₅ = 0.1
    λ₄₀ = 0.67132
    λ₄₁ = 2.2
    λ₄₂ = 2.2
    λ₄₃ = 2.2
    λ₄₄ = 6.6
    λ₄₅ = 0.1
    λb = 0.0153
    λc = 0.05
    ξ₁ = 0.0008
    ξ₂ = 0.0007
    ρ = 0.05
    σₙ = 0.1666
    σₜ = 0.2
    ψd = 0.15255
    ψᵤ = 0.92
    ω₀ = -0.20594
    ω₁ = 1
    ω₂ = 2
    Ω₃ = 0.45621
end

initial_dict = @parameters begin
    ADDbl = 0.02
    BANDₜ = 0.01
    BANDb = 0.01
    Rbbar = 0.035
    bot = 0.05
    top = 0.12
    GRg = 0.03
    GRpr = 0.03
    Nfe = 87.181
    NCAR = 0.1
    NPLk = 0.02
    Rbbar = 0.035
    Rln = 0.07
    RA = 0

    ϕ = 0.26417
    ϕₜ = 0.26417
    σₛₑ = 0.16667
    η = 0.04918

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
    N = 87.181 # ???
    NT = 87.181
    NHUC = 5.6735
    NL = 683593
    NLk = 95311
    NPL = 309158
    NPLke = 0.02
    NUC = 5.6106
    ωT = 112852
    p = 7.1723
    Pbl = 18.182
    Pₑ = 17937
    PE = 5.07185
    π = 0.0026
    PR = 138659
    PSBR = 1894780
    Q = 0.77443
    rb = 0.035
    Rbl = 0.055
    Rk = 0.03008
    rₗ = 0.06522
    rₘ = 0.0193
    REP = 2092310
    RRₗ = 0.06246
    S = 86270300
    Sk = 12028300
    Skₑ = 12028300
    TX = 17024100
    U = 0.70073
    UC = 5.6106
    W = 777968
    WB = 67824000
    Y = 86607700
    Yk = 12088400
    YDᵣ = 56446400
    YDkr = 7813270
    YDkre = 7813290
    YP = 73158700
    z1a = 0
    z1b = 0
    z2a = 0
    z2b = 0

    Bbd = 4389790
    Bbs = 4389790
    Bcbd = 4655690
    Bcbs = 4655690
    Bhd = 33439320
    Bhs = 33439320
    Bs = 42484800
    BLd = 840742
    BLs = 840742
    GD = 57728700
    ed = 5112.6001
    Eks = 5112.6001
    Hbd = 2025540
    Hbs = 2025540
    Hhd = 2630150
    Hhs = 2630150
    Hs = 4655690
    IN = 11585400
    INk = 2064890
    INkₑ = 2405660
    INkₜ = 2064890
    K = 127486471
    Kk = 17774838
    Lfd = 15962900
    Lfs = 15962900
    Lhd = 21606600
    Lhs = 21606600
    Ls = 37569500 # ???
    Mₕ = 40510800
    Ms = 40510800
    OFb = 3474030
    OFbe = 3474030
    OFbt = 3638100
    V = 165438779
    Vfma = 159334599
    Vk = 23066350
    Vf = 31361792 # ???

    z₃ = missing
    z₄ = missing
    z₅ = missing
    HCe = missing
    YDhs = missing
    CG = missing
    VfmaA = missing
    Fcb = missing
    FUbt = missing
end

growth = aggr + firms₁ + firms₂ + firms₃ + firms₄ + hh₁ + hh₂ + hh₃ + gov + cb + banks₁ + banks₂
growth = add_params(growth, Consistent.Variables(params_dict))
growth = add_exos(growth, @variables(RA, GRpr, GRg, BANDb, BANDₜ, ER, NCAR, Rbbar, ADDbl, bot, top), true)

using BenchmarkTools
using DataFrames
using Pipe
using Gadfly

const T = 350
lags = map(x -> initial_dict[x] isa Number ? Float64(initial_dict[x]) : 0.0, growth.endogenous_variables)[:,:]
exos_const = map(x -> Float64(initial_dict[x]), growth.exogenous_variables)
exos = hcat(exos_const, exos_const)
param_values = map(x -> Float64(params_dict[x]), growth.parameters)

# @report_opt solve(growth, lags, exos, param_values, initial=lags[:, 1], method=:broyden)
# a = similar(lags)
# @report_opt Consistent.f!(a, lags, lags, exos, param_values)
# growth.equations[findfirst(==(:G), growth.endogenous_variables)]

# Solve model for 59 periods
function progn(model, lags, exos, param_values; method=:broyden)
    results = zeros(length(model.endogenous_variables), T)
    results[:, 1] = lags
    for i in 1:(T-1)
        solution = Consistent.solve(model, results[:, i], exos, param_values, initial=results[:, i], method=method)
        results[:, i + 1] = solution
    end
    return results
end

@time results = progn(growth, lags, exos, param_values, method=:broyden)
@profview progn(growth, lags, exos, param_values)
# res = @report_opt progn(growth, lags, exos, param_values)
# res_2 = @report_opt solve(growth, zeros(length(growth.endogenous_variables), T), exos, param_values, initial=zeros(length(growth.endogenous_variables), T), method=:broyden)
# res_3 = @report_call solve(growth, zeros(length(growth.endogenous_variables), T), exos, param_values, initial=zeros(length(growth.endogenous_variables), T), method=:broyden)

# Convert results to DataFrame
df = DataFrame(results', growth.endogenous_variables)
# Add time column
df[!, :period] = 1:nrow(df)
# Select variables, convert to long format, and plot variables
@pipe df |> # Bs
    transform(_, [:Bbd, :Bbs, :Bs, :V] .=> (x -> x./_.K) .=> [:Bbd, :Bbs, :Bs, :V]) |>
    select(_, [:Bbs, :Bbd, :period]) |>
    # select(_, :V, :period) |>
    stack(_, Not(:period), variable_name=:variable) |>
    # subset(_, :period => ByRow(<(100))) |>
    plot(
        _,
        x=:period,
        y=:value,
        color=:variable,
        Geom.line
    )

# import Optimization
# import Optim
# using OptimizationOptimJL
# using ForwardDiff
# preacc = similar(lags)
# f = (x, y) -> (growth.f!(x, y, lags, exos, params); return x)
# fct = Optimization.OptimizationFunction(
#     (y, p) -> (a = f(preacc, y); max(norm(a) + abs(a[1] - a[1]))),
#     Optimization.AutoForwardDiff()
# )
# prob = Optimization.OptimizationProblem(
#     fct,
#     lags,
#     [0.0]
# )
# sol = Optimization.solve(prob, BFGS())

trick = [12460224.9860725,12398017.9476432,2127097.0384293,2479603.58952865,2061456.84176233,18310339.3067494,0.0301269303691746,0.70100357517028,0.0612956963082538,0.00259172659092623,2431543.27620936,12406886.8952865,89216542.0408732,11592779.7909174,17484956.9240895,131667610.92695,89197235.3803454,116237.612987599,1,1,1,1,0,0,803389.404260357,142818.77,87.245009784586,87.2194058707516,70071146.5224455,5.62358597864547,5.62523682468598,5.6882291468933,7.1908886406281,0.26417,0.26405136720981,70450096.7049297,0.166550008938527,18602444.355,15558672,2758271.805,18397175.5213452,15374225.1731052,16408825.5419017,319258,5186.55622019386,0.0300777557155461,5.08383255337631,0.776836589582287,76947492.7774455,17577885.2500797,57960425.0753658,59940613.2083165,1980188.13295065,170950845.490423,23773257.2473117,54428546.7178933,7569098.81907713,8024149.99562342,8000631.89124685,2877255.27826236,0.0496417214766985,716595.278262361,2160660,22323195.2782624,99653.2298127439,0.0632430491935713,34648785.3532165,876772.054654456,18293.6584078994,41450511.0061155,164598498.971289,186921694.249551,2721427.33589466,5186.55622019386,17303038.3988904,2406244.8,1889913.99881079,43719622.0960025,59660932.180629,162949.15,876772.054654456,34648785.3532165,2721427.33589466,2072525.55030577,4793952.88620044,4793952.88620044,4793952.88620044,0.035,0.055,18.1818181818182,41450511.0061155,16408825.5419017,22323195.2782624,2072525.55030577,4276883.85658557,4276883.81888558,0.103180484753362,0.0193,0,0,0,0,0.0640462845852116,3756950,3587198,432426,0.02,1325097.81,1757523.81,1801244.99324,0.0447462845852116,476147.18324,3630919.18324,0.0937446357394738,31970477.3703734,38732020.8201641,0.75,0.064,0.5,0.4,0.15,0.00122,0.1,0.05,0.10667,0.1,0.5,0.8,0.25,0.9,0.07416,0.6,0.4,0.22844,0.25,2.2,6.6,2.2,2.2,0.1,-0.04341,2.2,2.2,6.6,2.2,0.1,0.67132,2.2,2.2,2.2,6.6,0.1,0.0153,0.05,8e-04,7e-04,0.05,0.1666,0.2,0.15255,0.92,-0.20594,1,2,0.45621,0.02,0.01,0.01,0.05,0.03,0.03,87.181,0.1,0.02,0.035,0.07,0,0.12]
# trick = [12847139.6056919,12773163.234909,2135433.21254525,2554632.6469818,2083143.88137755,18863017.845508,0.0301839594285881,0.701633071373853,0.060862193299259,0.0025224867867597,2505842.43260956,12767232.9676729,92039334.3570995,11742418.5207003,18064687.1632355,135984015.55471,92161581.4557822,119724.741377227,1.00044053028471,1,1,1,0,0,829638.759815988,147103.3331,87.334116331399,87.28823214714,72417700.6650833,5.63687348995558,5.63983658515748,5.70300577691242,7.20902756220914,0.264075093767848,0.26405681412294,72715788.0642565,0.161389688979185,19201099.3326865,16086160.3701624,2806489.12578121,19028797.9481763,15934877.4718595,16961300.8982954,328176.510838035,5261.64950550768,0.0295790150670657,5.07716390433231,0.778279285336612,79478381.8966188,18156041.5604636,59892622.6185124,61740286.2991206,1847663.68060818,176583570.232841,24494783.6180457,56107561.5567029,7782958.39106339,8244418.50426299,8248186.16054174,2983558.34338589,0.0498151226802964,751238.815559653,2232319.52782624,23074434.093822,104208.065384264,0.0631816837213899,35792190.4356194,905667.436927023,18627.4518165163,42835287.9184401,170030847.570879,193105281.664701,2805378.07783515,5261.64950550768,17867085.6371611,2478432.144,1950214.55369503,45144466.0629236,61611146.734324,167788.351017015,905667.436927023,35792190.4356194,2805378.07783515,2141764.39592201,4947142.47375715,4947142.47375715,4947142.47375715,0.035,0.055,18.1818181818182,42835287.9184401,16961300.8982954,23074434.093822,2141764.39592201,4405133.15354705,4405133.11452758,0.102838881879704,0.0193,0,0,0,0,0.0635382041644293,3873202.08201641,3727832.34275056,425089.6703486,0.02,1364717.70131928,1789807.37166788,1809319.61304422,0.0442382041644293,444601.911724938,3747344.5841269,0.0935999947263291,32754010.5378738,40035734.9921174,0.75,0.064,0.5,0.4,0.15,0.00122,0.1,0.05,0.10667,0.1,0.5,0.8,0.25,0.9,0.07416,0.6,0.4,0.22844,0.25,2.2,6.6,2.2,2.2,0.1,-0.04341,2.2,2.2,6.6,2.2,0.1,0.67132,2.2,2.2,2.2,6.6,0.1,0.0153,0.05,8e-04,7e-04,0.05,0.1666,0.2,0.15255,0.92,-0.20594,1,2,0.45621,0.02,0.01,0.01,0.05,0.03,0.03,87.181,0.1,0.02,0.035,0.07,0,0.12]
trick_neu = trick[vcat([1, 2, 4, 3], 5:19, 22:114+2)]
Consistent.solve(growth, results[:, i], exos, param_values, initial=results[:, i], method=method)
argmax(abs.(Vector(df[2, 1:20]) - trick[1:20]))
argmax(abs.(Vector(df[2, 1:114]) - trick_neu))
(df[2, 22 .+ findall(x -> abs(x) > 0.00000000000001, (Vector(df[2, 23:end-1]) - trick[25:115+25-23-1]) ./ max.(0.00000000001, Vector(df[2, 23:end-1])))])
(df[3, findall(x -> abs(x) > 10000, (Vector(df[3, :]) - trick[1:115]))])
