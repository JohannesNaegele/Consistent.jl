# A predefined model bundled with the data needed to run it. Replaces the old,
# inconsistent `Dict(:model => ..., :params => ..., ...)` return values.

"""
A model together with everything needed to run it:

- `model`  — the [`Model`](@ref);
- `params` — a parameter calibration (`OrderedDict`; may be empty if the model
  ships without default values);
- `exos`   — exogenous data, one row per exogenous variable;
- `lags`   — initial lags, one row per endogenous variable.

This is what the built-in models (`SIM`, `PC`, …) return.
"""
struct Scenario{F}
    model::Model{F}
    params::OrderedDict{Symbol, Float64}
    exos::Matrix{Float64}
    lags::Matrix{Float64}
end

function Scenario(
    model::Model;
    params=OrderedDict{Symbol, Float64}(),
    exos=zeros(Float64, length(model.exogenous_variables), 1),
    lags=zeros(Float64, length(model.endogenous_variables), 1)
)
    return Scenario(
        model,
        OrderedDict{Symbol, Float64}(params),
        Matrix{Float64}(exos),
        Matrix{Float64}(lags)
    )
end

"""
    param_values(s::Scenario) -> Vector{Float64}

The calibrated parameter values in the order expected by the model's residual
function. Errors if the scenario carries no value for some model parameter.
"""
param_values(s::Scenario) = map(p -> s.params[p], s.model.parameters)

"""
    solve(s::Scenario; kwargs...)

Solve the bundled model for one period using its calibration, exogenous data and
lags. Keyword arguments are forwarded to [`solve`](@ref).
"""
CommonSolve.solve(s::Scenario; kwargs...) =
    CommonSolve.solve(s.model, s.lags, s.exos, param_values(s); kwargs...)

function Base.show(io::IO, s::Scenario)
    println(io, "SFC scenario")
    show(io, s.model)
    print(io, "\n\nCalibration: ", isempty(s.params) ? "(none)" : s.params)
end
