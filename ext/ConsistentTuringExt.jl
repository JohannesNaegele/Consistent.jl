module ConsistentTuringExt

# Turing extension: Bayesian estimation of probabilistic SFC models.
#
# STATUS: implemented and validated (ForwardDiff and Enzyme) — priors on
# parameters, latent (unobserved) endogenous variables, per-period stochastic
# shocks (`@random`, sampled as latent state-space variables), and a Gaussian
# observation model.
#
# For gradient-based samplers (NUTS) also load `SciMLSensitivity` (it registers the
# adjoints that make the per-period nonlinear solve differentiable) and pick an AD
# backend. ForwardDiff works out of the box (`NUTS(; adtype = AutoForwardDiff())`).
# Enzyme needs runtime activity enabled:
#     using Enzyme
#     adtype = AutoEnzyme(; mode = Enzyme.set_runtime_activity(Enzyme.Reverse))
#     sample(bm, NUTS(; adtype), n)

using Consistent
using Consistent: StochasticModel
using Turing
using NonlinearSolve
const FullSpecialize = NonlinearSolve.SciMLBase.FullSpecialize

# Differentiable single-period solves. Derivative-carrying inputs are routed
# through the problem parameter `p`, and the residual is fully specialized (no
# FunctionWrapper), so the implicit-function-theorem differentiation composes the
# chain rule across the recursive sequence of period solves. Two type-stable
# variants (rather than one branchy function) keep Enzyme happy:

# No shocks: `params` and `lags` go through `p`; the Float64 `exos` is captured.
function _solve_period(m, lags, exos, params, x0)
    nendo, nlag = size(lags)
    np = length(params)
    p = vcat(params, vec(lags))
    f!(F, x, p) = m.f!(F, x, reshape(view(p, np+1:lastindex(p)), nendo, nlag), exos, view(p, 1:np))
    nf = NonlinearFunction{true, FullSpecialize}(f!)
    return NonlinearSolve.solve(NonlinearProblem(nf, x0, p), NewtonRaphson(); abstol = 1e-10).u
end

# With shocks: `exos` also carries latent duals, so it is routed through `p` too.
function _solve_period_exos(m, lags, exos, params, x0)
    nendo, nlag = size(lags)
    nexo, nexc = size(exos)
    np = length(params)
    nl = nendo * nlag
    p = vcat(params, vec(lags), vec(exos))
    f!(F, x, p) = m.f!(
        F, x,
        reshape(view(p, np+1:np+nl), nendo, nlag),
        reshape(view(p, np+nl+1:lastindex(p)), nexo, nexc),
        view(p, 1:np),
    )
    nf = NonlinearFunction{true, FullSpecialize}(f!)
    return NonlinearSolve.solve(NonlinearProblem(nf, x0, p), NewtonRaphson(); abstol = 1e-10).u
end

"""
    bayesian_model(sm, data; lags, exos, fixed = (), obs_noise = ...) -> Turing model

Build a Turing model for `sm` conditioned on `data` (one row per observed variable,
in the order of `sm.observed`; one column per period). Sample it with
`Turing.sample(model, NUTS(; adtype), n)`.

Keyword arguments:
- `lags`  — initial lags (endogenous × 1);
- `exos`  — exogenous data (exogenous × periods); shock rows are overwritten by the
  sampled latent shocks;
- `fixed` — values for parameters that have no prior;
- `obs_noise` — prior for the observation-noise scale `σ`.
"""
function Consistent.bayesian_model(
    sm::StochasticModel,
    data::AbstractMatrix;
    lags::AbstractMatrix,
    exos::AbstractMatrix,
    fixed = Consistent.OrderedDict{Symbol,Any}(),
    obs_noise = truncated(Normal(0, 1); lower = 0),
)
    isempty(sm.priors) && error("`bayesian_model` needs at least one parameter prior.")
    m = sm.model
    fixed = Consistent.OrderedDict{Symbol,Any}(fixed)
    for p in m.parameters
        (haskey(sm.priors, p) || haskey(fixed, p)) ||
            error("Parameter `$p` has neither a prior nor a fixed value.")
    end

    obs_idx = [findfirst(==(v), m.endogenous_variables) for v in sm.observed]
    prior_pos = [i for (i, p) in enumerate(m.parameters) if haskey(sm.priors, p)]
    # `identity.(...)` narrows the eltype from `Any` (the dict's value type) to the
    # concrete distribution type, which `product_distribution` requires.
    prior_dists = identity.([sm.priors[m.parameters[i]] for i in prior_pos])
    fixed_vals = Dict(i => fixed[m.parameters[i]]
                      for i in eachindex(m.parameters) if !haskey(sm.priors, m.parameters[i]))

    if isempty(sm.shocks)
        return _sfc(m, data, lags, exos, obs_idx, prior_pos, prior_dists, fixed_vals, obs_noise)
    else
        shock_pos = [findfirst(==(s), m.exogenous_variables) for s in keys(sm.shocks)]
        shock_dists = identity.(collect(values(sm.shocks)))
        return _sfc_shocks(m, data, lags, exos, obs_idx, prior_pos, prior_dists, fixed_vals,
                           obs_noise, shock_pos, shock_dists)
    end
end

# `params` assembles the full parameter vector (sampled priors + fixed values).
function _params(prior_pos, θ, fixed_vals, n)
    params = Vector{eltype(θ)}(undef, n)
    for (k, i) in enumerate(prior_pos)
        params[i] = θ[k]
    end
    for (i, v) in fixed_vals
        params[i] = v
    end
    return params
end

# No-shock model: deterministic dynamics given sampled parameters.
Turing.@model function _sfc(m, data, lags, exos, obs_idx, prior_pos, prior_dists, fixed_vals, obs_noise)
    T = size(data, 2)
    nendo = length(m.endogenous_variables)
    θ ~ product_distribution(prior_dists)
    σ ~ obs_noise
    params = _params(prior_pos, θ, fixed_vals, length(m.parameters))

    results = Matrix{eltype(θ)}(undef, nendo, T)
    results[:, 1] = lags[:, 1]
    for t in 2:T
        results[:, t] = _solve_period(m, results[:, 1:t-1], exos[:, 1:t], params, results[:, t-1])
    end
    for t in 1:T, (k, idx) in enumerate(obs_idx)
        data[k, t] ~ Normal(results[idx, t], σ)
    end
end

# State-space model: per-period shocks are latent and enter the exogenous inputs.
Turing.@model function _sfc_shocks(m, data, lags, exos, obs_idx, prior_pos, prior_dists,
                                   fixed_vals, obs_noise, shock_pos, shock_dists)
    T = size(data, 2)
    nendo = length(m.endogenous_variables)
    nshock = length(shock_pos)
    θ ~ product_distribution(prior_dists)
    σ ~ obs_noise
    params = _params(prior_pos, θ, fixed_vals, length(m.parameters))

    # exogenous data with one i.i.d. latent draw per shock per period
    exos_full = Matrix{eltype(θ)}(undef, size(exos)...)
    exos_full .= exos
    U ~ product_distribution(reduce(vcat, fill(shock_dists, T)))
    Umat = reshape(U, nshock, T)
    for t in 1:T, (j, row) in enumerate(shock_pos)
        exos_full[row, t] = Umat[j, t]
    end

    results = Matrix{eltype(θ)}(undef, nendo, T)
    results[:, 1] = lags[:, 1]
    for t in 2:T
        results[:, t] = _solve_period_exos(m, results[:, 1:t-1], exos_full[:, 1:t], params, results[:, t-1])
    end
    for t in 1:T, (k, idx) in enumerate(obs_idx)
        data[k, t] ~ Normal(results[idx, t], σ)
    end
end

end # module ConsistentTuringExt
