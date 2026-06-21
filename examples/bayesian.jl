# Bayesian estimation of a stock-flow consistent model with Turing.
#
# Needs the Turing extension. The default sampler uses ForwardDiff (no extra
# packages); for the reverse-mode backends, also load SciMLSensitivity (adjoints
# for the solve) and Enzyme or Mooncake — see the sampling section below.
using Consistent
using Turing
using Random
Random.seed!(1)

# --- deterministic model ---------------------------------------------------
m = Consistent.SIM().model

# --- synthetic "observed" data from known parameters -----------------------
T = 30
lags = zeros(length(m.endogenous_variables), 1)
exos = fill(20.0, 1, T)
true_params = [0.2, 0.6, 0.4]   # θ, α_1, α_2 (model parameter order)

results = zeros(length(m.endogenous_variables), T)
results[:, 1] = lags[:, 1]
for t in 2:T
    results[:, t] = solve(m, results[:, 1:t-1], exos[:, 1:t], true_params)
end
observed = @observable(Y, C)
obs_idx = [findfirst(==(v), m.endogenous_variables) for v in observed]
data = results[obs_idx, :] .+ 0.5 .* randn(length(observed), T)

# --- probabilistic layer: priors on α_1, α_2 (θ fixed), observe Y and C -----
sm = StochasticModel(
    m;
    priors = (@parameters begin
        α_1 = Normal(0.6, 0.1)
        α_2 = Normal(0.4, 0.1)
    end),
    observed = observed,
)

bm = bayesian_model(sm, data; lags = lags, exos = exos,
                    fixed = Consistent.OrderedDict(:θ => 0.2))

# --- sample the posterior --------------------------------------------------
# ForwardDiff works out of the box and is fast for this small model. Reverse-mode
# backends also work (load the package + SciMLSensitivity first):
#   using SciMLSensitivity, Enzyme;   adtype = AutoEnzyme(; mode = Enzyme.set_runtime_activity(Enzyme.Reverse))
#   using SciMLSensitivity, Mooncake; adtype = AutoMooncake(; config = nothing)
adtype = AutoForwardDiff()
chain = sample(bm, NUTS(0.65; adtype), 500)

# Posterior should concentrate near α_1 = 0.6, α_2 = 0.4
println(mean(chain))
