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

Lagged values are written `x[-1]`, `x[-2]`, …, and the difference operator `Δ` is available as sugar: `Δ(x)` expands to `x - x[-1]` and `Δ(x, n)` to `x - x[-n]`.

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

### Plotting
The package ships a [plot recipe](https://docs.juliaplots.org/stable/recipes/)
(defined with the lightweight `RecipesBase`, so `Plots` is not a dependency). Load
`Plots` and plot a solved trajectory directly — rows of the results matrix are the
endogenous variables, columns are periods:

```julia
using Plots

# `lags` here is the endogenous-variables × periods results matrix
plot(my_first_model, lags)                       # all endogenous variables
plot(my_first_model, lags; vars = [:Y, :C, :YD]) # a selection
```

For richer data wrangling, `DataFrames` works as usual
(`DataFrame(lags', my_first_model.endogenous_variables)`).

`solve` returns the vector of solved endogenous variable values (ordered as in
`model.endogenous_variables`). It is a method of `CommonSolve.solve` — the same
generic function used by `NonlinearSolve`/`DifferentialEquations` — so loading
both packages does not clash on the name. Pass `method` to pick the algorithm:
`:newton` (default, via NLsolve) or `:trust_region`, `:broyden`,
`:newton_raphson` (via NonlinearSolve).

## Predefined models

The built-in models (`SIM`, `SIMStoch`, `LP`, `DIS`, `PC`, `BMW`) each return a
`Scenario`: the model bundled with a parameter calibration and data to run it.

```julia
sim = Consistent.SIM()      # a Scenario
sim.model                   # the Model
sim.params                  # calibration (OrderedDict)
sim.exos                    # exogenous data
sim.lags                    # initial lags
param_values(sim)           # parameter values in model order

solve(sim)                  # solve one period using the bundled data
```

## Composition and structure

Models are values and compose with `+`. Composition is commutative up to
ordering — `a + b == b + a` — and `reorder` returns a canonical
block-triangular layout:

```julia
combined = PC_gdp + PC_hh
block_decomposition(combined)   # simultaneous blocks, in solvable order
reorder(combined)               # equivalent model, canonical ordering
```

`block_decomposition` ignores lagged terms (which are predetermined), so each
block is a set of variables that must be solved simultaneously, returned in an
order where every block depends only on itself and earlier blocks.

Model construction validates that the system is **square** (one equation per
endogenous variable) and that each endogenous variable is **determined by exactly
one equation** (appears on its left-hand side), erroring otherwise.

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

### The `solve` function and CommonSolve

[`CommonSolve.jl`](https://github.com/SciML/CommonSolve.jl) is a tiny package
whose only job is to *declare* the generic functions `solve`, `solve!`, and
`init` — it ships no methods of its own. Its purpose is to give the ecosystem one
shared `solve` function that many unrelated packages can add methods to without
depending on each other. `NonlinearSolve`, `DifferentialEquations`, `Optimization`,
`JuMP`, … all extend this same `CommonSolve.solve`.

`Consistent` does the same: instead of defining its own `solve`, it adds a method

```julia
function CommonSolve.solve(model::Model, lags, exos, params; method, initial)
    # ... wraps NLsolve / NonlinearSolve around model.f! ...
end
```

Because `Consistent.solve` and e.g. `NonlinearSolve.solve` are then *the same
function object* (just with different methods), Julia picks the right one by the
types of the arguments. So `using Consistent, NonlinearSolve` does **not** produce
an ambiguous-name warning, and you never have to write `Consistent.solve` to
disambiguate — the call `solve(model, lags, exos, params)` dispatches to our
method on `::Model`, while `solve(prob, alg)` dispatches to NonlinearSolve's.

## Remarks

The model residual function `f!` is compiled with
[`RuntimeGeneratedFunctions.jl`](https://github.com/SciML/RuntimeGeneratedFunctions.jl)
instead of `eval`, so model instantiation is thread-safe and free of world-age
issues (a freshly built model can be solved within the same function scope).

Feel free to ask questions and report bugs via issues!
