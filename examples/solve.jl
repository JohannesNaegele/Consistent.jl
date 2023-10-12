using Consistent
using NLsolve
using Plots

function solve(model, lags, exos, params)
    nlsolve(
        (x, y) -> model.f!(x, y, lags, exos, params),
        fill(1.0, length(model.endogenous_variables)),
        autodiff = :forward,
    ).zero
end

# Setup SIM
model = Consistent.SIM() # load predefined SIM model
params_dict = Consistent.SIM(defaults=true) # load default parameters
exos = [20.0] # this is only G
exos = exos[:, :] # bring in matrix format
lags = fill(0.0, length(model.endogenous_variables)) # lagged values of endogenous variables are all 0.0
lags = lags[:, :] # bring in matrix format
param_values = map(x -> params_dict[x], model.parameters) # get raw parameter values
solution = solve(model, lags, exos, param_values) # solve first period

# Solve model for 50 periods
for i in 1:50
    solution = solve(model, lags, exos, param_values) # solve first period
    lags = hcat(solution, lags)
end

# Plot Y over time
plot(
    1:size(lags, 2),
    reverse(lags[1, :])
)