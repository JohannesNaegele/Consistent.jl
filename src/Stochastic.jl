# Probabilistic layer on top of a deterministic `Model`. The Bayesian inference
# itself lives in the Turing package extension (ext/ConsistentTuringExt.jl); this
# file only defines the (Turing-free) specification and validation.

"""
A probabilistic stock-flow consistent model: a deterministic [`Model`](@ref)
augmented with

- `priors`   — prior distributions for (a subset of) the model's parameters;
- `shocks`   — distributions for (a subset of) the model's exogenous variables,
  drawn afresh each period (the `@random` shocks);
- `observed` — the endogenous variables for which data exists; the rest are latent.

Construct the deterministic part with `model(...)`, then attach the probabilistic
layer:

```julia
sm = StochasticModel(
    m;
    priors   = @parameters(begin α_1 = Normal(0.6, 0.01); α_2 = Normal(0.4, 0.01) end),
    shocks   = @random(begin u_G = Normal(0, 1) end),
    observed = @observable(Y, T, YD),
)
```

Bayesian inference (`bayesian_model`, then `Turing.sample`) becomes available once
the Turing extension is loaded (`using Turing`).
"""
struct StochasticModel{F}
    model::Model{F}
    priors::OrderedDict{Symbol, Any}
    shocks::OrderedDict{Symbol, Any}
    observed::Variables
end

function _check_subset(names, allowed, what, kind)
    extra = setdiff(Set(names), Set(allowed))
    isempty(extra) || error("$(collect(extra)) declared as $what but $(length(extra) == 1 ? "is not a" : "are not") model $kind(s): $(collect(allowed)).")
end

function StochasticModel(
    model::Model;
    priors = OrderedDict{Symbol, Any}(),
    shocks = OrderedDict{Symbol, Any}(),
    observed = model.endogenous_variables,
)
    priors = OrderedDict{Symbol, Any}(priors)
    shocks = OrderedDict{Symbol, Any}(shocks)
    observed = Variables(observed)

    _check_subset(keys(priors), model.parameters, "prior", "parameter")
    _check_subset(keys(shocks), model.exogenous_variables, "shock", "exogenous variable")
    _check_subset(observed, model.endogenous_variables, "observed", "endogenous variable")

    return StochasticModel(model, priors, shocks, observed)
end

"""
The endogenous variables of `sm` that are *not* observed (i.e. latent).
"""
latent(sm::StochasticModel) = filter(v -> !(v in sm.observed), sm.model.endogenous_variables)

function Base.show(io::IO, sm::StochasticModel)
    println(io, "Probabilistic stock-flow consistent model")
    show(io, sm.model)
    print(io, "\n\nPriors:    ", isempty(sm.priors) ? "(none)" : sm.priors)
    print(io, "\nShocks:    ", isempty(sm.shocks) ? "(none)" : sm.shocks)
    print(io, "\nObserved:  ", collect(sm.observed))
end

"""
    bayesian_model(sm::StochasticModel, data; kwargs...)

Build a Turing model for the probabilistic SFC model `sm` given observed `data`
(a matrix with one row per observed variable and one column per period). Sample
its posterior with `Turing.sample`.

This method is provided by the Turing extension; load `Turing` (and, for
gradient-based samplers, `SciMLSensitivity` + your AD backend) to enable it.
"""
function bayesian_model(::StochasticModel, args...; kwargs...)
    error("`bayesian_model` requires the Turing extension — run `using Turing` " *
          "(and `SciMLSensitivity` for gradient-based samplers) first.")
end
