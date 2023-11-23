using Consistent
using Distributions
using DataFrames
using Pipe
using Gadfly
using Random
# using Zygote
# using Optimization
# using OptimizationOptimJL
# using SciMLSensitivity

# Given data for exogenous variables
df = DataFrame(:G => fill(20, 60))

# Define model
sim = Consistent.SIM()[:model]
exos = permutedims(Matrix(df[!, sim.exogenous_variables]))
lags = Consistent.SIM()[:lags]
params_dict = @parameters begin
    θ = 0.2
    α_1 = Normal(0.6, 0.01)
    α_2 = Normal(0.4, 0.01)
end
priors_dict = @parameters begin
    α_1 = Uniform()
    α_2 = Uniform()
end

# let's say we know that some kind of variables is prone to measurement error
# if it is just a constant, we can introduce some bias variable

function solve(
    model, lags, exos, params_dict::AbstractDict;
    rng=Random.default_rng(),
    initial=fill(1.0, length(model.endogenous_variables))
)
    function sample_param(x)
        if x isa Number
            return x
        else
            return rand(rng, x)
        end
    end
param_values = map(x -> sample_param(params_dict[x]), sim.parameters)
    return Consistent.solve(
        sim, lags, exos, param_values, initial=initial
    )
end

# Solve model for 59 periods
for i in 1:59
    solution = solve(
        sim,
        lags,
        exos[:, begin:i],
        params_dict
    )
    lags = hcat(lags, solution)
end

# Convert results to DataFrame
df = DataFrame(lags', sim.endogenous_variables)
# Add time column
df[!, :period] = 1:nrow(df)
# Select variables, convert to long format, and plot variables
@pipe df |>
    select(_, [:Y, :C, :YD, :period]) |>
    stack(_, Not(:period), variable_name=:variable) |>
    plot(
        _,
        x=:period,
        y=:value,
        color=:variable,
        Geom.line
    )