using Consistent
using DataFrames
using Gadfly
using Pipe
using BenchmarkTools
Gadfly.push_theme(:dark)

# Define parameter values
params_dict = @parameters begin
    θ = 0.2
    α_1 = 0.6
    α_2 = 0.4
end

# Define endogenous variables
endogenous = @variables Y, T, YD, C, H_s, H_h, H
# Define exogenous variables
exogenous = @variables G

# Define model equations
equations = @equations begin
    Y = C + G
    T = θ * Y
    YD = Y - T
    C = α_1 * YD + α_2 * H[-1]
    H_s + H_s[-1] = G - T
    H_h + H_h[-1] = YD - C
    H = H_s + H_s[-1] + H[-1]
end

# Define model
my_first_model = model(
    endos = endogenous,
    exos = exogenous,
    params = params_dict,
    eqs = equations
)

# Data on exogenous parameter G
exos = [20.0][:, :]
# Lagged values of endogenous variables are all 0.0
lags = fill(0.0, length(my_first_model.endogenous_variables), 1)
# Get raw parameter values
param_values = map(x -> params_dict[x], my_first_model.parameters)

# Solve model for 59 periods
for i in 1:59
    solution = solve(my_first_model, lags, exos, param_values)
    lags = hcat(lags, solution)
end

# Convert results to DataFrame
df = DataFrame(lags', my_first_model.endogenous_variables)
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