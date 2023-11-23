using Consistent
using DataFrames
using Pipe
using Gadfly
using NonlinearSolve

include("GROWTH_eqs.jl")

const T = 350
lags = map(x -> initial_dict[x] isa Number ? Float64(initial_dict[x]) : 0.0, growth.endogenous_variables)[:,:]
exos_const = map(x -> Float64(initial_dict[x]), growth.exogenous_variables)
exos = hcat(exos_const, exos_const)
param_values = map(x -> Float64(params_dict[x]), growth.parameters)

# Solve model for 59 periods
function progn(model, lags, exos, param_values; method=NonlinearSolve.TrustRegion())
    results = zeros(length(model.endogenous_variables), T)
    results[:, 1] = lags
    for i in 1:(T-1)
        solution = Consistent.solve_nonlinear(model, results[:, i], exos, param_values, initial=results[:, i], method=method)
        results[:, i + 1] = solution
    end
    return results
end

@time results = progn(growth, lags, exos, param_values)

# Convert results to DataFrame
df = DataFrame(results', growth.endogenous_variables)
# Add time column
df[!, :period] = 1:nrow(df)
# Select variables, convert to long format, and plot variables
@pipe df |> # Bs
    transform(_, [:Bbd, :Bbs, :Bs, :V] .=> (x -> x./_.K) .=> [:Bbd, :Bbs, :Bs, :V]) |>
    select(_, [:Bbs, :Bbd, :period]) |>
    # select(_, :V, :period) |>
    stack(_, Not(:period), variable_name=:variable) |>
    # subset(_, :period => ByRow(<(100))) |>
    plot(
        _,
        x=:period,
        y=:value,
        color=:variable,
        Geom.line
    )

# @report_opt Consistent.f!(a, lags, lags, exos, param_values)
# growth.equations[findfirst(==(:G), growth.endogenous_variables)]