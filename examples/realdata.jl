# Bayesian estimation on *real* data.
#
# Data is read from the vendored CSV `data/worldbank_us.csv` (World Bank, current
# US$). The example reads the committed snapshot, so it runs offline / in CI; run
# `refresh_data.jl` to update the snapshot from the keyless World Bank REST API.
#
# This is a deliberately stylised demonstration of the data → estimation pipeline:
# real government spending drives the SIM consumption function and we estimate the
# propensities to consume. A properly specified model on sectoral (flow-of-funds)
# data is tracked in issue #41.

using Consistent
using Turing
using SciMLSensitivity            # adjoints so the period solve is differentiable
using CSV, DataFrames

df = CSV.read(joinpath(@__DIR__, "data", "worldbank_us.csv"), DataFrame)
scale = 1e12                      # work in trillions of US$
G = df.G ./ scale                 # government final consumption  -> exogenous driver
C = df.C ./ scale                 # household consumption         -> observed
Tn = nrow(df)

m = Consistent.SIM().model
exos = reshape(G, 1, Tn)                                   # SIM's exogenous variable is G
lags = zeros(length(m.endogenous_variables), 1)
data = reshape(C, 1, Tn)                                   # one observed row: consumption

sm = StochasticModel(
    m;
    priors   = @parameters(begin α_1 = Beta(2, 2); α_2 = Beta(2, 2) end),
    observed = @observable(C),
)
bm = bayesian_model(sm, data; lags = lags, exos = exos,
                    fixed = Consistent.OrderedDict(:θ => 0.2),
                    obs_noise = truncated(Normal(0, 5); lower = 0))

# ForwardDiff is the simplest backend; Enzyme / Mooncake also work (see below)
chain = sample(bm, NUTS(0.65; adtype = AutoForwardDiff()), 500)

# Reverse-mode alternatives (need the respective package loaded):
#   using Enzyme;   adtype = AutoEnzyme(; mode = Enzyme.set_runtime_activity(Enzyme.Reverse))
#   using Mooncake; adtype = AutoMooncake(; config = nothing)

println(mean(chain))   # posterior over the consumption propensities α_1, α_2
