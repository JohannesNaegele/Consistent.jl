using Consistent
using DataFrames
using Zygote
using Optimization
using OptimizationOptimJL
using SciMLSensitivity

function calibrate!(data, model, parameters=Dict(), initial_parameters=Dict())
    exos = permutedims(Matrix(data[!, model.exogenous_variables]))
    results = similar(Matrix(data[!, model.endogenous_variables])') # lags in
    results[:, 1] = Matrix(data[1, model.exogenous_variables])'
    function loss(params)
        sol = prognose!(results, horizon, model, exos, param_values; method=:broyden)
        if sol == ReturnCode.Failure
            return Inf
        else
            return ...
        end
    end
    initial = ...
    adtype = Optimization.AutoZygote()
    optf = Optimization.OptimizationFunction((x, p) -> loss(x), adtype)
    optprob = Optimization.OptimizationProblem(optf, initial)
    res = Optimization.solve(optprob, ADAM(), maxiters = 1000)
    return res
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
calibrate!(df, sim, Dict(:θ => 0.2), Dict(:α_1 => 0.5, :α_2 => 0.5))