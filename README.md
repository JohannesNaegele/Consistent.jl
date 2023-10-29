# Consistent

[![Build Status](https://github.com/JohannesNaegele/Consistent.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/JohannesNaegele/Consistent.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/JohannesNaegele/Consistent.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/JohannesNaegele/Consistent.jl)

This package provides solution and calibration methods for stock-flow consistent models.

## Basic usage

### Model definition

Consider SIM from Godley and Lavoie 2007:

```julia
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

# Define model
my_first_model = model(
    endos = endogenous,
    exos = exogenous,
    params = params_dict,
    equations = @equations begin
        Y = C + G
        T = θ * Y
        YD = Y - T
        C = α_1 * YD + α_2 * H[-1]
        H_s + H_s[-1] = G - T
        H_h + H_h[-1] = YD - C
        H = H_s + H_s[-1] + H[-1]
    end
)
```

The difference between parameters and exogenous parameters is that the latter *can change over time* which is especially important if they appear in lagged terms. In this case, we need to provide several values for one exogenous variable.

Note also that the model is not aware of any concrete values of parameters or exogenous variables. Instead, data is always supplied externaly to solution/calibration functions. Thus, `params_dict` is just syntactical sugar for `@variables [k for (k, v) in params_dict]`.

Lastly, the specification of endogenous variables is *optional* and might be omitted if is much effort for larger models. However, it enables easier debugging. If not endogenous variables are not specified, the package will assume the symbol farthest on the left hand side of each equation to be endogenous.

### Model solution
If we want to solve a model we need data on
1. exogenous variables (and their lags)
2. lags of endogenous variables
3. parameters

```julia
# data on exogenous parameter G
exos = [20.0][:, :]
# lagged values of endogenous variables are all 0.0
lags = fill(0.0, length(my_first_model.endogenous_variables), 1)
# get raw parameter values
param_values = map(x -> params_dict[x], my_first_model.parameters)
```



```julia
# Solve model for 59 periods
for i in 1:59
    solution = solve(my_first_model, lags, exos, param_values)
    lags = hcat(lags, solution)
end
```

### Data handling and plotting
`DataFrames` and `Pipe` give us functionality similar to R's `dplyr`; the package ```Gadfly``` is very similar to R's `ggplots2`:

```julia
using DataFrames
using Pipe
using Gadfly

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
```

An example with actual data can be found here.

## Advanced usage

### Probabilistic models

### Model calibration



## Syntax

There are plenty different syntax options for defining variables *outside the model function* enabled:

```julia
# As single variables (slurping)
endogenous = @variables Y T YD C H_s H_h H
# As tuple
endogenous = @variables Y, T, YD, C, H_s, H_h, H
# As array
endogenous = @variables [
    Y,
    T,
    YD,
    C,
    H_s,
    H_h,
    H
]
# As block
endogenous = @variables begin
    Y
    T
    YD
    C
    H_s
    H_h
    H
end
```

Inside the function we need parantheses and can not use whitespace seperation.

## Internals

Internally, we just generate a function `f!` for our model which can be used together with an arbitrary root finding solver:

```julia
function f!(diff, endos, lags, exos, params)
    diff[1] = endos[1] - (endos[4] + exos[1, end - 0])
    diff[2] = endos[2] - params[1] * endos[1]
    diff[3] = endos[3] - (endos[1] - endos[2])
    diff[4] = endos[4] - (params[2] * endos[3] + params[3] * lags[7, end - 0])
    diff[5] = (endos[5] + lags[5, end - 0]) - (exos[1, end - 0] - endos[2])
    diff[6] = (endos[6] + lags[6, end - 0]) - (endos[3] - endos[4])
    diff[7] = endos[7] - (endos[5] + lags[5, end - 0] + lags[7, end - 0])
end
```

## Remarks

Currently the model instantiation is not thread-safe.

Feel free to ask questions and report bugs via issues!
