using Consistent
using DataFrames
using Zygote
using Optimization
using OptimizationOptimJL

function calibrate!(data, model, parameters=Dict(), initial_parameters=Dict())
    exos = data...
    lags = ...
    F = similar(...)
    function g!(F, x)
        return model.f!(F, x, lags, exos, params)
    end
    function loss(params)
        sol = solve(model, lags, exos, params; initial=fill(1.0, length(model.endogenous_variables)), method=:newton)
    end
    deriv = x -> ForwardDiff.derivative(loss, x)
    initial = ...
    prob = OptimizationProblem(loss, deriv, initial, p)
    solve(prob, BFGS())
end

# Given data for exogenous variables
df = DataFrame(:G => 20 .+ 10 * rand(60))

# Define model
sim = Consistent.SIM()[:model]
exos = permutedims(Matrix(df[!, sim.exogenous_variables]))
lags = Consistent.SIM()[:lags]
params_dict = Consistent.SIM()[:params]
param_values = map(x -> params_dict[x], sim.parameters)

# Solve model for 59 periods
for i in 1:59
    # assume we have some randomness in our parameters
    solution = Consistent.solve(sim, lags, exos[:, begin:i], param_values + 0.1 * rand(3))
    lags = hcat(lags, solution)
end

# Convert results to DataFrame
df = hcat(df, DataFrame(lags', sim.endogenous_variables))